using Godot;
using Godot.Collections;
using Remnant.Autoloads;
using Remnant.Core;

namespace Remnant.Debug;

/// <summary>
/// Debug overlay for flight testing.
/// Shows velocity vectors, thrust vectors, trajectory prediction, and physics data.
/// Toggle with F3 key.
/// </summary>
public partial class FlightDebugOverlay : CanvasLayer
{
    #region Exports

    [ExportGroup("Visualization")]
    [Export] public bool ShowVelocityVector { get; set; } = true;
    [Export] public bool ShowThrustVector { get; set; } = true;
    [Export] public bool ShowTrajectoryPrediction { get; set; } = true;
    [Export] public bool ShowPhysicsData { get; set; } = true;

    [ExportGroup("Colors")]
    [Export] public Color VelocityColor { get; set; } = new(0.2f, 0.8f, 0.2f);
    [Export] public Color ThrustColor { get; set; } = new(1.0f, 0.6f, 0.2f);
    [Export] public Color RcsColor { get; set; } = new(0.2f, 0.6f, 1.0f);
    [Export] public Color TrajectoryColor { get; set; } = new(0.8f, 0.8f, 0.2f, 0.5f);

    [ExportGroup("Trajectory")]
    [Export] public float TrajectoryDuration { get; set; } = 5.0f;
    [Export] public int TrajectoryPoints { get; set; } = 50;

    #endregion

    #region State

    private PlayerShip? _ship;
    private Camera3D? _camera;
    private bool _isVisible = true;

    // 3D visualization
    private ImmediateMesh? _vectorMesh;
    private MeshInstance3D? _vectorMeshInstance;

    // 2D overlay
    private Control? _overlay;
    private Label? _physicsLabel;

    // Cached HUD data
    private Dictionary _currentData = new();

    #endregion

    public override void _Ready()
    {
        Layer = 100; // On top of everything

        // Listen for ship spawn
        Events.Instance.ShipSpawned += OnShipSpawned;
        Events.Instance.HudUpdateRequested += OnHudUpdate;

        Build3DVisualization();
        Build2DOverlay();
    }

    public override void _ExitTree()
    {
        Events.Instance.ShipSpawned -= OnShipSpawned;
        Events.Instance.HudUpdateRequested -= OnHudUpdate;
    }

    public override void _Input(InputEvent @event)
    {
        // Toggle debug overlay with F3
        if (@event is InputEventKey key && key.Pressed && key.Keycode == Key.F3)
        {
            _isVisible = !_isVisible;
            if (_overlay != null)
                _overlay.Visible = _isVisible;
            if (_vectorMeshInstance != null)
                _vectorMeshInstance.Visible = _isVisible;

            GD.Print($"Debug overlay: {(_isVisible ? "ON" : "OFF")}");
        }
    }

    public override void _Process(double delta)
    {
        if (!_isVisible || _ship == null) return;

        UpdateCamera();
        Update3DVectors();
        Update2DOverlay();
    }

    #region Setup

    private void OnShipSpawned(Node ship)
    {
        if (ship is PlayerShip playerShip)
            _ship = playerShip;
    }

    private void OnHudUpdate(Dictionary data)
    {
        _currentData = data;
    }

    private void UpdateCamera()
    {
        _camera = GetViewport().GetCamera3D();
    }

    private void Build3DVisualization()
    {
        _vectorMesh = new ImmediateMesh();

        _vectorMeshInstance = new MeshInstance3D
        {
            Mesh = _vectorMesh,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off
        };

        var material = new StandardMaterial3D
        {
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
            VertexColorUseAsAlbedo = true,
            Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
            CullMode = BaseMaterial3D.CullModeEnum.Disabled
        };
        _vectorMeshInstance.MaterialOverride = material;

        // Add to scene root so it's in world space
        CallDeferred(MethodName.AddVectorMeshToScene);
    }

    private void AddVectorMeshToScene()
    {
        if (_vectorMeshInstance != null)
            GetTree().Root.AddChild(_vectorMeshInstance);
    }

    private void Build2DOverlay()
    {
        _overlay = new Control();
        _overlay.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        AddChild(_overlay);

        // Physics data panel (top-left)
        var panel = new PanelContainer();
        panel.SetAnchorsPreset(Control.LayoutPreset.TopLeft);
        panel.Position = new Vector2(10, 10);

        var panelStyle = new StyleBoxFlat
        {
            BgColor = new Color(0, 0, 0, 0.7f),
            ContentMarginLeft = 10,
            ContentMarginRight = 10,
            ContentMarginTop = 5,
            ContentMarginBottom = 5
        };
        panel.AddThemeStyleboxOverride("panel", panelStyle);
        _overlay.AddChild(panel);

        var vbox = new VBoxContainer();
        panel.AddChild(vbox);

        var titleLabel = new Label { Text = "FLIGHT DEBUG (F3 to toggle)" };
        titleLabel.AddThemeFontSizeOverride("font_size", 14);
        titleLabel.AddThemeColorOverride("font_color", new Color(1, 1, 0));
        vbox.AddChild(titleLabel);

        _physicsLabel = new Label { Text = "Waiting for data..." };
        _physicsLabel.AddThemeFontSizeOverride("font_size", 12);
        _physicsLabel.AddThemeColorOverride("font_color", new Color(0.8f, 0.8f, 0.8f));
        vbox.AddChild(_physicsLabel);

        // Legend
        var legendLabel = new Label
        {
            Text = "\n[Legend]\n" +
                   "GREEN: Velocity\n" +
                   "ORANGE: Thrust\n" +
                   "BLUE: RCS\n" +
                   "YELLOW: Trajectory"
        };
        legendLabel.AddThemeFontSizeOverride("font_size", 11);
        legendLabel.AddThemeColorOverride("font_color", new Color(0.6f, 0.6f, 0.6f));
        vbox.AddChild(legendLabel);
    }

    #endregion

    #region 3D Visualization

    private void Update3DVectors()
    {
        if (_vectorMesh == null || _ship == null) return;

        _vectorMesh.ClearSurfaces();

        var shipPos = _ship.GlobalPosition;

        // Velocity vector (green)
        if (ShowVelocityVector)
        {
            var velocity = _ship.LinearVelocity;
            if (velocity.Length() > 0.5f)
            {
                DrawVector3D(shipPos, velocity * 0.1f, VelocityColor, 2.0f);
            }
        }

        // Thrust velocity vector (orange) - from FBW
        if (ShowThrustVector && _currentData.TryGetValue("thrust_velocity", out var tvVar))
        {
            var thrustVel = tvVar.AsVector3();
            if (thrustVel.Length() > 0.5f)
            {
                DrawVector3D(shipPos, thrustVel * 0.1f, ThrustColor, 1.5f);
            }
        }

        // RCS velocity vector (blue) - from FBW
        if (ShowThrustVector && _currentData.TryGetValue("rcs_velocity", out var rcsVar))
        {
            var rcsVel = rcsVar.AsVector3();
            if (rcsVel.Length() > 0.1f)
            {
                DrawVector3D(shipPos, rcsVel * 0.1f, RcsColor, 1.5f);
            }
        }

        // Trajectory prediction (yellow dotted)
        if (ShowTrajectoryPrediction)
        {
            DrawTrajectoryPrediction(shipPos, _ship.LinearVelocity);
        }
    }

    private void DrawVector3D(Vector3 origin, Vector3 direction, Color color, float thickness = 1.0f)
    {
        if (_vectorMesh == null || direction.LengthSquared() < 0.01f) return;

        var end = origin + direction;

        // Main line
        _vectorMesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
        _vectorMesh.SurfaceSetColor(color);
        _vectorMesh.SurfaceAddVertex(origin);
        _vectorMesh.SurfaceAddVertex(end);
        _vectorMesh.SurfaceEnd();

        // Arrow head
        var arrowSize = direction.Length() * 0.1f;
        arrowSize = Mathf.Clamp(arrowSize, 0.5f, 5.0f);

        var forward = direction.Normalized();
        var right = forward.Cross(Vector3.Up).Normalized();
        if (right.IsZeroApprox())
            right = forward.Cross(Vector3.Right).Normalized();
        var up = right.Cross(forward).Normalized();

        var arrowBack = -forward * arrowSize;
        var arrowRight = right * arrowSize * 0.3f;
        var arrowUp = up * arrowSize * 0.3f;

        _vectorMesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
        _vectorMesh.SurfaceSetColor(color);
        _vectorMesh.SurfaceAddVertex(end);
        _vectorMesh.SurfaceAddVertex(end + arrowBack + arrowRight);
        _vectorMesh.SurfaceAddVertex(end);
        _vectorMesh.SurfaceAddVertex(end + arrowBack - arrowRight);
        _vectorMesh.SurfaceAddVertex(end);
        _vectorMesh.SurfaceAddVertex(end + arrowBack + arrowUp);
        _vectorMesh.SurfaceAddVertex(end);
        _vectorMesh.SurfaceAddVertex(end + arrowBack - arrowUp);
        _vectorMesh.SurfaceEnd();
    }

    private void DrawTrajectoryPrediction(Vector3 startPos, Vector3 velocity)
    {
        if (_vectorMesh == null) return;

        var timeStep = TrajectoryDuration / TrajectoryPoints;
        var currentPos = startPos;
        var currentVel = velocity;

        _vectorMesh.SurfaceBegin(Mesh.PrimitiveType.LineStrip);
        _vectorMesh.SurfaceSetColor(TrajectoryColor);
        _vectorMesh.SurfaceAddVertex(currentPos);

        for (var i = 0; i < TrajectoryPoints; i++)
        {
            // Simple ballistic prediction (no thrust, no gravity in space)
            currentPos += currentVel * timeStep;
            _vectorMesh.SurfaceAddVertex(currentPos);
        }

        _vectorMesh.SurfaceEnd();

        // Draw time markers along trajectory
        currentPos = startPos;
        for (var t = 1; t <= (int)TrajectoryDuration; t++)
        {
            var markerPos = startPos + velocity * t;
            DrawTimeMarker(markerPos, t);
        }
    }

    private void DrawTimeMarker(Vector3 position, int seconds)
    {
        if (_vectorMesh == null) return;

        var size = 1.0f;
        var color = TrajectoryColor with { A = 0.8f };

        _vectorMesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
        _vectorMesh.SurfaceSetColor(color);

        // Cross marker
        _vectorMesh.SurfaceAddVertex(position + new Vector3(-size, 0, 0));
        _vectorMesh.SurfaceAddVertex(position + new Vector3(size, 0, 0));
        _vectorMesh.SurfaceAddVertex(position + new Vector3(0, -size, 0));
        _vectorMesh.SurfaceAddVertex(position + new Vector3(0, size, 0));
        _vectorMesh.SurfaceAddVertex(position + new Vector3(0, 0, -size));
        _vectorMesh.SurfaceAddVertex(position + new Vector3(0, 0, size));

        _vectorMesh.SurfaceEnd();
    }

    #endregion

    #region 2D Overlay

    private void Update2DOverlay()
    {
        if (_physicsLabel == null || _ship == null) return;

        if (!ShowPhysicsData)
        {
            _physicsLabel.Text = "(Physics data hidden)";
            return;
        }

        var velocity = _ship.LinearVelocity;
        var speed = velocity.Length();
        var targetSpeed = _currentData.TryGetValue("target_speed", out var ts) ? ts.AsSingle() : 0f;

        var thrustVel = _currentData.TryGetValue("thrust_velocity", out var tv) ? tv.AsVector3() : Vector3.Zero;
        var rcsVel = _currentData.TryGetValue("rcs_velocity", out var rv) ? rv.AsVector3() : Vector3.Zero;
        var isManeuvering = _currentData.TryGetValue("is_maneuvering", out var im) && im.AsBool();

        var povForward = _currentData.TryGetValue("pov_forward", out var pf) ? pf.AsVector3() : Vector3.Forward;
        var shipForward = _currentData.TryGetValue("ship_forward", out var sf) ? sf.AsVector3() : Vector3.Forward;

        var alignmentAngle = Mathf.RadToDeg(povForward.AngleTo(shipForward));

        _physicsLabel.Text =
            $"Position:     {FormatVector(_ship.GlobalPosition)}\n" +
            $"Velocity:     {FormatVector(velocity)} ({speed:F1} m/s)\n" +
            $"Target Speed: {targetSpeed:F1} m/s\n" +
            $"Thrust Vel:   {FormatVector(thrustVel)} ({thrustVel.Length():F1} m/s)\n" +
            $"RCS Vel:      {FormatVector(rcsVel)} ({rcsVel.Length():F1} m/s)\n" +
            $"Alignment:    {alignmentAngle:F1}°\n" +
            $"Status:       {(isManeuvering ? "MANEUVERING" : "CRUISE")}\n" +
            $"Mass:         {_ship.Mass:F0} kg";
    }

    private static string FormatVector(Vector3 v)
    {
        return $"({v.X:F1}, {v.Y:F1}, {v.Z:F1})";
    }

    #endregion
}
