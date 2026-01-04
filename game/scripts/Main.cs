using Godot;
using Remnant.Autoloads;
using Remnant.Core;
using Remnant.Debug;
using Remnant.UI;
using Remnant.Utils;

namespace Remnant;

/// <summary>
/// Main entry point for the game.
/// Handles initial setup and scene orchestration.
/// </summary>
public partial class Main : Node3D
{
    public override void _Ready()
    {
        InitializeGame();
        SetupDebug();

        // Start at main menu or load into test scene
        if (OS.IsDebugBuild() && OS.HasFeature("editor"))
            LoadDebugScene();
        else
            LoadMainMenu();
    }

    private void InitializeGame()
    {
        var version = ProjectSettings.GetSetting("application/config/version", "0.1.0").AsString();
        GD.Print($"Remnant v{version} initializing...");

        GetWindow().Title = "Remnant";
    }

    private void SetupDebug()
    {
        if (!OS.IsDebugBuild()) return;

        var debugNode = new Node3D { Name = "DebugDraw" };
        AddChild(debugNode);
        DebugUtils.Initialize(debugNode);
    }

    private void LoadMainMenu()
    {
        GD.Print("Main menu not yet implemented");
        LoadDebugScene();
    }

    private void LoadDebugScene()
    {
        GD.Print("Loading debug scene...");
        CreateTestEnvironment();
    }

    private void CreateTestEnvironment()
    {
        GD.Print("Setting up flight test scene...");

        SetupEnvironment();
        SetupArena();
        SetupPlayerShip();
        SetupCamera();
        SetupHud();
        SetupDebugVisualization();

        GD.Print("Flight test scene ready!");
        GD.Print("Controls: Mouse - Steer, W/S - Throttle Up/Down, Q/E - Roll");
        GD.Print("Shift - Boost, C - Toggle Camera, ESC - Pause");
    }

    private void SetupEnvironment()
    {
        var environmentNode = new WorldEnvironment();
        var env = new Godot.Environment
        {
            BackgroundMode = Godot.Environment.BGMode.Color,
            BackgroundColor = new Color(0.02f, 0.02f, 0.05f),
            AmbientLightSource = Godot.Environment.AmbientSource.Color,
            AmbientLightColor = new Color(0.15f, 0.15f, 0.2f),
            AmbientLightEnergy = 0.5f,
            FogEnabled = true,
            FogLightColor = new Color(0.1f, 0.1f, 0.15f),
            FogDensity = 0.0001f,
            FogAerialPerspective = 0.3f
        };

        environmentNode.Environment = env;
        AddChild(environmentNode);

        // Add directional light (sun)
        var sun = new DirectionalLight3D
        {
            Name = "Sun",
            LightEnergy = 1.2f,
            LightColor = new Color(1.0f, 0.95f, 0.9f),
            ShadowEnabled = true,
            ShadowBlur = 1.0f,
            RotationDegrees = new Vector3(-45, 45, 0)
        };
        AddChild(sun);

        // Add secondary fill light to reduce harsh shadows
        var fillLight = new DirectionalLight3D
        {
            Name = "FillLight",
            LightEnergy = 0.3f,
            LightColor = new Color(0.6f, 0.7f, 1.0f),
            ShadowEnabled = false,
            RotationDegrees = new Vector3(30, -135, 0)
        };
        AddChild(fillLight);
    }

    private void SetupArena()
    {
        var arena = new TestArenaGenerator
        {
            Name = "Arena",
            ArenaSize = 5000.0f,  // 5km radius (10km diameter test space)
            AsteroidCount = 50,
            MinAsteroidSize = 20.0f,
            MaxAsteroidSize = 300.0f,
            MinSpacing = 150.0f,
            ShowBoundary = true,
            BoundaryColor = new Color(0.2f, 0.5f, 1.0f, 0.3f)
        };
        AddChild(arena);
    }

    private void SetupPlayerShip()
    {
        var playerShip = new PlayerShip
        {
            Name = "PlayerShip",
            Mass = 5000.0f,
            GlobalPosition = new Vector3(0, 0, -100)
        };

        // Create ship visual
        var meshInstance = new MeshInstance3D();
        var boxMesh = new BoxMesh { Size = new Vector3(3, 1.5f, 6) };
        meshInstance.Mesh = boxMesh;

        var material = new StandardMaterial3D
        {
            AlbedoColor = new Color(0.2f, 0.3f, 0.6f),
            Metallic = 0.8f,
            Roughness = 0.3f
        };
        meshInstance.MaterialOverride = material;
        playerShip.AddChild(meshInstance);

        // Create collision shape
        var collisionShape = new CollisionShape3D();
        var boxShape = new BoxShape3D { Size = new Vector3(3, 1.5f, 6) };
        collisionShape.Shape = boxShape;
        playerShip.AddChild(collisionShape);

        playerShip.CollisionLayer = 1;
        playerShip.CollisionMask = 2 | 4;

        AddChild(playerShip);
    }

    private void SetupCamera()
    {
        var playerShip = GetNodeOrNull<PlayerShip>("PlayerShip");
        if (playerShip == null) return;

        var cameraRig = new ShipCameraRig
        {
            Name = "CameraRig",
            TargetShip = playerShip,
            FollowDistance = 20.0f,
            FollowHeight = 8.0f
        };
        AddChild(cameraRig);

        playerShip.CameraRigPath = cameraRig.GetPath();
        playerShip.CameraRig = cameraRig;
    }

    private void SetupHud()
    {
        var playerShip = GetNodeOrNull<PlayerShip>("PlayerShip");
        if (playerShip == null) return;

        // Create 2D cockpit HUD overlay
        var cockpit = new Cockpit
        {
            Name = "Cockpit",
            TargetShip = playerShip
        };
        AddChild(cockpit);
    }

    private void SetupDebugVisualization()
    {
        if (!OS.IsDebugBuild()) return;

        // Add flight debug overlay (toggle with F3)
        var debugOverlay = new FlightDebugOverlay
        {
            Name = "FlightDebugOverlay"
        };
        AddChild(debugOverlay);

        GD.Print("Debug overlay enabled (press F3 to toggle)");
    }

    private MeshInstance3D CreateDebugMarker(Vector3 pos, Color color)
    {
        var mesh = new SphereMesh { Radius = 0.5f, Height = 1.0f };

        var material = new StandardMaterial3D
        {
            AlbedoColor = color,
            EmissionEnabled = true,
            Emission = color,
            EmissionEnergyMultiplier = 0.5f
        };

        var instance = new MeshInstance3D
        {
            Mesh = mesh,
            MaterialOverride = material,
            Position = pos
        };

        return instance;
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
        {
            if (GameState.Instance.IsInMatch())
                GameState.Instance.IsPaused = !GameState.Instance.IsPaused;
        }
    }
}
