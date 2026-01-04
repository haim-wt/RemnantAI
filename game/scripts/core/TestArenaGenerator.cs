using Godot;
using System.Collections.Generic;

namespace Remnant.Core;

/// <summary>
/// Generates a simple test arena with placeholder asteroids.
/// This is a temporary system until full SDF asteroid rendering is implemented.
/// </summary>
[Tool]
public partial class TestArenaGenerator : Node3D
{
    #region Exports

    [ExportGroup("Arena Parameters")]
    [Export] public float ArenaSize { get; set; } = 5000.0f;
    [Export] public int AsteroidCount { get; set; } = 10;
    [Export] public float MinAsteroidSize { get; set; } = 50.0f;
    [Export] public float MaxAsteroidSize { get; set; } = 300.0f;
    [Export] public float MinSpacing { get; set; } = 200.0f;

    [ExportGroup("Boundary")]
    [Export] public bool ShowBoundary { get; set; } = true;
    [Export] public Color BoundaryColor { get; set; } = new Color(0.2f, 0.4f, 0.8f, 0.3f);
    [Export] public int BoundarySegments { get; set; } = 32;

    [ExportGroup("Generation")]
    [Export] public int RandomSeed { get; set; } = 12345;

    private bool _generateInEditor;
    [Export]
    public bool GenerateInEditor
    {
        get => _generateInEditor;
        set
        {
            if (value && Engine.IsEditorHint())
                GenerateArena();
            _generateInEditor = false;
        }
    }

    private bool _clearArena;
    [Export]
    public bool ClearArena
    {
        get => _clearArena;
        set
        {
            if (value && Engine.IsEditorHint())
                ClearAsteroids();
            _clearArena = false;
        }
    }

    #endregion

    #region State

    private readonly List<Node3D> _asteroids = new();
    private readonly RandomNumberGenerator _rng = new();
    private MeshInstance3D? _boundaryMesh;

    #endregion

    public override void _Ready()
    {
        if (!Engine.IsEditorHint())
        {
            GenerateArena();
            if (ShowBoundary)
                CreateBoundaryMarkers();
        }
    }

    #region Generation

    public void GenerateArena()
    {
        ClearAsteroids();

        _rng.Seed = (ulong)RandomSeed;
        var positions = new List<Vector3>();

        for (var i = 0; i < AsteroidCount; i++)
        {
            var attempts = 0;
            var position = Vector3.Zero;
            var valid = false;

            while (!valid && attempts < 100)
            {
                position = RandomPositionInSphere(ArenaSize);

                valid = true;
                foreach (var existingPos in positions)
                {
                    if (position.DistanceTo(existingPos) < MinSpacing)
                    {
                        valid = false;
                        break;
                    }
                }

                attempts++;
            }

            if (valid)
            {
                positions.Add(position);
                var size = _rng.RandfRange(MinAsteroidSize, MaxAsteroidSize);
                CreatePlaceholderAsteroid(position, size);
            }
        }

        GD.Print($"Generated {_asteroids.Count} asteroids in test arena");
    }

    private void CreatePlaceholderAsteroid(Vector3 position, float radius)
    {
        var asteroid = new StaticBody3D
        {
            Name = $"Asteroid_{_asteroids.Count + 1}",
            GlobalPosition = position
        };

        // Create visual mesh
        var meshInstance = new MeshInstance3D();
        var sphereMesh = new SphereMesh
        {
            Radius = radius,
            Height = radius * 2,
            RadialSegments = 16,
            Rings = 8
        };
        meshInstance.Mesh = sphereMesh;
        meshInstance.CastShadow = GeometryInstance3D.ShadowCastingSetting.On;

        // Create simple material
        var material = new StandardMaterial3D
        {
            AlbedoColor = new Color(
                0.3f + _rng.Randf() * 0.2f,
                0.25f + _rng.Randf() * 0.15f,
                0.2f + _rng.Randf() * 0.1f),
            Roughness = 0.9f + _rng.Randf() * 0.1f,
            Metallic = 0.1f + _rng.Randf() * 0.1f
        };
        meshInstance.MaterialOverride = material;
        asteroid.AddChild(meshInstance);

        // Create collision shape
        var collisionShape = new CollisionShape3D();
        var sphereShape = new SphereShape3D { Radius = radius };
        collisionShape.Shape = sphereShape;
        asteroid.AddChild(collisionShape);

        // Set physics layers
        asteroid.CollisionLayer = 2; // Layer 2: asteroids
        asteroid.CollisionMask = 1 | 2 | 4; // Collide with ships, asteroids, projectiles

        AddChild(asteroid);
        if (Engine.IsEditorHint())
            asteroid.Owner = GetTree().EditedSceneRoot;

        _asteroids.Add(asteroid);
    }

    private void ClearAsteroids()
    {
        foreach (var asteroid in _asteroids)
        {
            if (IsInstanceValid(asteroid))
                asteroid.QueueFree();
        }
        _asteroids.Clear();

        // Also clear any existing children that are asteroids
        foreach (var child in GetChildren())
        {
            if (child.Name.ToString().StartsWith("Asteroid_"))
                child.QueueFree();
        }
    }

    private Vector3 RandomPositionInSphere(float radius)
    {
        var minDistance = radius * 0.1f;

        while (true)
        {
            var pos = new Vector3(
                _rng.RandfRange(-radius, radius),
                _rng.RandfRange(-radius * 0.5f, radius * 0.5f),
                _rng.RandfRange(-radius, radius));

            var lengthSq = pos.LengthSquared();
            if (lengthSq <= radius * radius && lengthSq >= minDistance * minDistance)
                return pos;
        }
    }

    #endregion

    #region Boundary

    private void CreateBoundaryMarkers()
    {
        // Create boundary sphere wireframe using ImmediateMesh
        var immediateMesh = new ImmediateMesh();

        // Draw circles at different orientations to form a sphere wireframe
        DrawBoundaryCircle(immediateMesh, Vector3.Up, ArenaSize);      // XZ plane (equator)
        DrawBoundaryCircle(immediateMesh, Vector3.Right, ArenaSize);   // YZ plane
        DrawBoundaryCircle(immediateMesh, Vector3.Forward, ArenaSize); // XY plane

        // Add more latitude circles for better visibility
        for (var i = 1; i < 4; i++)
        {
            var lat = i * 22.5f; // 22.5, 45, 67.5 degrees
            var radius = ArenaSize * Mathf.Cos(Mathf.DegToRad(lat));
            var height = ArenaSize * Mathf.Sin(Mathf.DegToRad(lat));

            DrawBoundaryCircle(immediateMesh, Vector3.Up, radius, new Vector3(0, height, 0));
            DrawBoundaryCircle(immediateMesh, Vector3.Up, radius, new Vector3(0, -height, 0));
        }

        // Create mesh instance
        _boundaryMesh = new MeshInstance3D
        {
            Name = "BoundaryMarkers",
            Mesh = immediateMesh,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off
        };

        // Create transparent material
        var material = new StandardMaterial3D
        {
            AlbedoColor = BoundaryColor,
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
            Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
            CullMode = BaseMaterial3D.CullModeEnum.Disabled
        };
        _boundaryMesh.MaterialOverride = material;

        AddChild(_boundaryMesh);

        // Also add corner markers at the boundary edges
        CreateCornerMarkers();
    }

    private void DrawBoundaryCircle(ImmediateMesh mesh, Vector3 normal, float radius, Vector3 offset = default)
    {
        mesh.SurfaceBegin(Mesh.PrimitiveType.LineStrip);

        // Find perpendicular vectors
        var tangent = normal.Cross(Vector3.Up).Normalized();
        if (tangent.IsZeroApprox())
            tangent = normal.Cross(Vector3.Right).Normalized();
        var bitangent = normal.Cross(tangent).Normalized();

        for (var i = 0; i <= BoundarySegments; i++)
        {
            var angle = (float)i / BoundarySegments * Mathf.Tau;
            var point = offset + (tangent * Mathf.Cos(angle) + bitangent * Mathf.Sin(angle)) * radius;
            mesh.SurfaceAddVertex(point);
        }

        mesh.SurfaceEnd();
    }

    private void CreateCornerMarkers()
    {
        // Create 8 corner markers at the boundary cube corners
        var corners = new Vector3[]
        {
            new(1, 1, 1), new(1, 1, -1), new(1, -1, 1), new(1, -1, -1),
            new(-1, 1, 1), new(-1, 1, -1), new(-1, -1, 1), new(-1, -1, -1)
        };

        foreach (var corner in corners)
        {
            var pos = corner.Normalized() * ArenaSize * 0.95f;
            var marker = CreateBoundaryMarker(pos);
            AddChild(marker);
        }
    }

    private MeshInstance3D CreateBoundaryMarker(Vector3 position)
    {
        var mesh = new SphereMesh
        {
            Radius = ArenaSize * 0.01f,
            Height = ArenaSize * 0.02f,
            RadialSegments = 8,
            Rings = 4
        };

        var material = new StandardMaterial3D
        {
            AlbedoColor = BoundaryColor with { A = 0.6f },
            EmissionEnabled = true,
            Emission = new Color(BoundaryColor.R, BoundaryColor.G, BoundaryColor.B),
            EmissionEnergyMultiplier = 0.5f,
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded
        };

        return new MeshInstance3D
        {
            Name = "BoundaryMarker",
            Mesh = mesh,
            MaterialOverride = material,
            Position = position,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off
        };
    }

    #endregion

    #region Public Interface

    public List<Node3D> GetAsteroids() => new(_asteroids);

    public float GetArenaBounds() => ArenaSize;

    #endregion
}
