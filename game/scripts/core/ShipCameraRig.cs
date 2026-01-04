using Godot;
using Remnant.Autoloads;

namespace Remnant.Core;

/// <summary>
/// Camera rig that follows the pilot's POV (not the ship orientation).
/// Works with FlyByWire to show where the pilot WANTS to go.
/// </summary>
public partial class ShipCameraRig : Node3D
{
    #region Enums

    public enum CameraMode
    {
        ThirdPerson,
        FirstPerson
    }

    #endregion

    #region Exports

    [ExportGroup("Camera Setup")]
    [Export] public Node3D? TargetShip { get; set; }

    [ExportGroup("Third Person")]
    [Export] public float FollowDistance { get; set; } = 15.0f;
    [Export] public float FollowHeight { get; set; } = 5.0f;
    [Export] public float PositionSmoothing { get; set; } = 12.0f;

    [ExportGroup("First Person")]
    [Export] public Vector3 CockpitPosition { get; set; } = new(0, 0.5f, -2.0f);

    [ExportGroup("Field of View")]
    [Export] public float BaseFov { get; set; } = 75.0f;
    [Export] public float SpeedFovFactor { get; set; } = 5.0f;
    [Export] public float MaxFov { get; set; } = 100.0f;

    #endregion

    #region State

    public CameraMode CurrentCameraMode { get; private set; } = CameraMode.ThirdPerson;
    public Basis PovBasis { get; set; } = Basis.Identity;

    private Camera3D? _camera;

    #endregion

    public override void _Ready()
    {
        _camera = new Camera3D
        {
            Fov = BaseFov,
            Near = 0.1f,
            Far = 100000.0f
        };
        AddChild(_camera);

        if (TargetShip == null)
        {
            GD.PushError("ShipCameraRig: No TargetShip assigned!");
            return;
        }

        GlobalPosition = TargetShip.GlobalPosition;
        GlobalRotation = TargetShip.GlobalRotation;
    }

    public override void _Process(double delta)
    {
        if (TargetShip == null) return;

        switch (CurrentCameraMode)
        {
            case CameraMode.ThirdPerson:
                UpdateThirdPerson((float)delta);
                break;
            case CameraMode.FirstPerson:
                UpdateFirstPerson();
                break;
        }

        UpdateDynamicFov((float)delta);
    }

    #region Camera Modes

    private void UpdateThirdPerson(float delta)
    {
        if (TargetShip == null) return;

        // Camera follows POV orientation, not ship orientation
        var povBack = PovBasis.Z.Normalized();
        var povUp = PovBasis.Y.Normalized();

        // Offset from ship position using POV orientation
        var offset = povBack * FollowDistance + povUp * FollowHeight;
        var idealPosition = TargetShip.GlobalPosition + offset;

        // Smooth position following
        GlobalPosition = GlobalPosition.Lerp(idealPosition, delta * PositionSmoothing);

        // Camera looks in POV direction (instant - no lag for responsiveness)
        GlobalTransform = new Transform3D(PovBasis, GlobalPosition);
    }

    private void UpdateFirstPerson()
    {
        if (TargetShip == null) return;

        // Position fixed at cockpit in ship's local space (moves with ship)
        // But camera looks in POV direction (where pilot wants to go)
        GlobalPosition = TargetShip.GlobalPosition + TargetShip.GlobalTransform.Basis * CockpitPosition;

        // Look in POV direction
        GlobalTransform = new Transform3D(PovBasis, GlobalPosition);
    }

    private void UpdateDynamicFov(float delta)
    {
        if (TargetShip == null || _camera == null) return;

        // Get ship speed
        var speed = 0f;
        if (TargetShip is RigidBody3D rigidBody)
            speed = rigidBody.LinearVelocity.Length();

        // Calculate FOV based on speed
        var targetFov = BaseFov + (speed / 100.0f) * SpeedFovFactor;
        targetFov = Mathf.Min(targetFov, MaxFov);

        // Smooth FOV transition
        _camera.Fov = Mathf.Lerp(_camera.Fov, targetFov, delta * 5.0f);
    }

    #endregion

    #region Public Interface

    public void SetCameraMode(CameraMode mode)
    {
        CurrentCameraMode = mode;
        Events.Instance.EmitSignal(Events.SignalName.CameraModeChanged, (int)mode);
    }

    public void CycleCameraMode()
    {
        var nextMode = (CameraMode)(((int)CurrentCameraMode + 1) % 2);
        SetCameraMode(nextMode);
    }

    public Camera3D? GetCamera() => _camera;

    public void SetTarget(Node3D ship)
    {
        TargetShip = ship;
        if (ship != null)
        {
            GlobalPosition = ship.GlobalPosition;
            PovBasis = ship.GlobalTransform.Basis;
        }
    }

    public void SetPov(Basis basis)
    {
        PovBasis = basis;
    }

    #endregion
}
