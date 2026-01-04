using Godot;

namespace Remnant.Utils;

/// <summary>
/// Debug visualization for ship physics.
/// Shows velocity vectors, thrust vectors, trajectory prediction, etc.
/// </summary>
public partial class ShipDebugVisualizer : Node3D
{
    #region Exports

    [ExportGroup("Target")]
    [Export] public RigidBody3D? TargetShip { get; set; }

    [ExportGroup("Visualization Options")]
    [Export] public bool ShowVelocity { get; set; } = true;
    [Export] public bool ShowThrust { get; set; } = true;
    [Export] public bool ShowTrajectory { get; set; } = true;
    [Export] public bool ShowAxes { get; set; } = true;
    [Export] public bool ShowCollision { get; set; } = false;

    [ExportGroup("Vector Scales")]
    [Export] public float VelocityScale { get; set; } = 0.1f;
    [Export] public float ThrustScale { get; set; } = 0.001f;
    [Export] public float AxesLength { get; set; } = 5.0f;

    [ExportGroup("Trajectory Prediction")]
    [Export] public int TrajectoryPoints { get; set; } = 50;
    [Export] public float TrajectoryStep { get; set; } = 0.2f;

    [ExportGroup("Colors")]
    [Export] public Color VelocityColor { get; set; } = Colors.Cyan;
    [Export] public Color ThrustColor { get; set; } = Colors.Orange;
    [Export] public Color TrajectoryColor { get; set; } = Colors.Green;
    [Export] public Color AxisXColor { get; set; } = Colors.Red;
    [Export] public Color AxisYColor { get; set; } = Colors.Green;
    [Export] public Color AxisZColor { get; set; } = Colors.Blue;

    #endregion

    #region State

    private ImmediateMesh? _immediateMesh;
    private StandardMaterial3D? _material;

    #endregion

    public override void _Ready()
    {
        SetupVisualization();
    }

    public override void _Process(double delta)
    {
        if (TargetShip == null || _immediateMesh == null) return;

        _immediateMesh.ClearSurfaces();

        if (ShowVelocity)
            DrawVelocityVector();

        if (ShowTrajectory)
            DrawTrajectoryPrediction();

        if (ShowAxes)
            DrawOrientationAxes();
    }

    #region Setup

    private void SetupVisualization()
    {
        _material = new StandardMaterial3D
        {
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
            VertexColorUseAsAlbedo = true
        };

        _immediateMesh = new ImmediateMesh();

        var meshInstance = new MeshInstance3D
        {
            Mesh = _immediateMesh,
            MaterialOverride = _material,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off
        };
        AddChild(meshInstance);
    }

    #endregion

    #region Drawing Functions

    private void DrawVelocityVector()
    {
        if (TargetShip == null || _immediateMesh == null) return;

        var velocity = TargetShip.LinearVelocity;
        if (velocity.LengthSquared() < 0.1f) return;

        var start = TargetShip.GlobalPosition;
        var end = start + velocity * VelocityScale;

        DrawArrow(start, end, VelocityColor);
    }

    private void DrawTrajectoryPrediction()
    {
        if (TargetShip == null || _immediateMesh == null) return;

        var pos = TargetShip.GlobalPosition;
        var vel = TargetShip.LinearVelocity;

        _immediateMesh.SurfaceBegin(Mesh.PrimitiveType.LineStrip);
        _immediateMesh.SurfaceSetColor(TrajectoryColor);

        for (var i = 0; i < TrajectoryPoints; i++)
        {
            _immediateMesh.SurfaceAddVertex(pos);
            pos += vel * TrajectoryStep;
        }

        _immediateMesh.SurfaceEnd();
    }

    private void DrawOrientationAxes()
    {
        if (TargetShip == null || _immediateMesh == null) return;

        var origin = TargetShip.GlobalPosition;
        var basis = TargetShip.GlobalTransform.Basis;

        // X axis (right) - Red
        DrawLine(origin, origin + basis.X * AxesLength, AxisXColor);

        // Y axis (up) - Green
        DrawLine(origin, origin + basis.Y * AxesLength, AxisYColor);

        // Z axis (back) - Blue (forward is -Z)
        DrawLine(origin, origin + basis.Z * AxesLength, AxisZColor);
    }

    #endregion

    #region Primitive Drawing

    private void DrawLine(Vector3 from, Vector3 to, Color color)
    {
        if (_immediateMesh == null) return;

        _immediateMesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
        _immediateMesh.SurfaceSetColor(color);
        _immediateMesh.SurfaceAddVertex(from);
        _immediateMesh.SurfaceAddVertex(to);
        _immediateMesh.SurfaceEnd();
    }

    private void DrawArrow(Vector3 from, Vector3 to, Color color)
    {
        if (_immediateMesh == null) return;

        _immediateMesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
        _immediateMesh.SurfaceSetColor(color);

        // Main line
        _immediateMesh.SurfaceAddVertex(from);
        _immediateMesh.SurfaceAddVertex(to);

        // Arrowhead
        var direction = (to - from).Normalized();
        var perpendicular = Vector3.Up.Cross(direction).Normalized();
        if (perpendicular.LengthSquared() < 0.1f)
            perpendicular = Vector3.Right.Cross(direction).Normalized();

        var arrowSize = (to - from).Length() * 0.1f;
        var arrowBase = to - direction * arrowSize;

        var side1 = arrowBase + perpendicular * arrowSize * 0.5f;
        var side2 = arrowBase - perpendicular * arrowSize * 0.5f;

        _immediateMesh.SurfaceAddVertex(to);
        _immediateMesh.SurfaceAddVertex(side1);
        _immediateMesh.SurfaceAddVertex(to);
        _immediateMesh.SurfaceAddVertex(side2);

        _immediateMesh.SurfaceEnd();
    }

    #endregion

    #region Public Interface

    public void SetVisualizationEnabled(bool enabled)
    {
        Visible = enabled;
    }

    public void SetOptions(bool velocity, bool thrust, bool trajectory, bool axes)
    {
        ShowVelocity = velocity;
        ShowThrust = thrust;
        ShowTrajectory = trajectory;
        ShowAxes = axes;
    }

    #endregion
}
