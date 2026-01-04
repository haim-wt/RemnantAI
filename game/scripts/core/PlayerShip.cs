using Godot;
using Godot.Collections;
using Remnant.Autoloads;

namespace Remnant.Core;

/// <summary>
/// Player-controlled ship with fly-by-wire flight system.
/// Pilot controls POV (where they want to go), FBW handles the physics.
/// </summary>
public partial class PlayerShip : RigidBody3D
{
    #region Exports

    [ExportGroup("Camera")]
    [Export] public NodePath CameraRigPath { get; set; } = new();

    [ExportGroup("Input")]
    [Export] public float MouseSensitivity { get; set; } = 0.5f;
    [Export] public float MouseSmoothing { get; set; } = 0.15f;
    [Export] public float RollRate { get; set; } = 90.0f;

    [ExportGroup("Speed Control")]
    [Export] public float ThrottleRate { get; set; } = 20.0f;
    [Export] public float MaxSpeed { get; set; } = 200.0f;

    #endregion

    #region State

    public ShipCameraRig? CameraRig { get; set; }

    private FlyByWire? _fbw;
    private Vector2 _mouseDelta;
    private Vector2 _smoothedMouseDelta;
    private bool _isMouseCaptured;

    #endregion

    public override void _Ready()
    {
        // Configure RigidBody for space
        GravityScale = 0f;
        LinearDamp = 0f;
        AngularDamp = 0f;

        // Create and initialize FBW system
        _fbw = new FlyByWire { Name = "FlyByWire" };
        AddChild(_fbw);
        _fbw.Initialize(this);

        // Connect FBW signals
        _fbw.PovChanged += OnPovChanged;

        // Get camera rig
        if (!CameraRigPath.IsEmpty)
        {
            CameraRig = GetNode<ShipCameraRig>(CameraRigPath);
            if (CameraRig != null)
                CameraRig.PovBasis = GlobalTransform.Basis;
        }

        // Capture mouse
        CaptureMouse();

        // Load sensitivity from settings
        var savedSens = Settings.Instance.GetValue("gameplay", "mouse_sensitivity");
        if (savedSens.VariantType != Variant.Type.Nil && savedSens.AsSingle() > 0)
            MouseSensitivity = savedSens.AsSingle() * 0.5f;

        Events.Instance.SettingChanged += OnSettingChanged;
        Events.Instance.EmitSignal(Events.SignalName.ShipSpawned, this);
    }

    public override void _ExitTree()
    {
        ReleaseMouse();
    }

    public override void _Input(InputEvent @event)
    {
        // Toggle mouse capture
        if (@event.IsActionPressed("pause"))
        {
            if (_isMouseCaptured)
                ReleaseMouse();
            else
                CaptureMouse();
            return;
        }

        // Accumulate mouse movement
        if (@event is InputEventMouseMotion motion && _isMouseCaptured)
        {
            _mouseDelta += motion.Relative;
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        ProcessPovInput((float)delta);
        ProcessSpeedInput((float)delta);
        ProcessStrafeInput();
        ProcessOtherInput();
        UpdateCamera();
        UpdateHud();
    }

    #region Input Processing

    private void ProcessPovInput(float delta)
    {
        if (_fbw == null) return;

        var pitch = 0f;
        var yaw = 0f;
        var roll = 0f;

        if (_isMouseCaptured)
        {
            // Smooth the mouse input
            var smoothFactor = 1f - Mathf.Pow(MouseSmoothing, delta * 60f);
            _smoothedMouseDelta = _smoothedMouseDelta.Lerp(_mouseDelta, smoothFactor);

            var invertY = Settings.Instance.GetValue("gameplay", "invert_y").AsBool() ? 1f : -1f;
            pitch = Mathf.DegToRad(_smoothedMouseDelta.Y * MouseSensitivity * invertY);
            yaw = Mathf.DegToRad(_smoothedMouseDelta.X * MouseSensitivity);
            _mouseDelta = Vector2.Zero;
        }

        // Keyboard roll (inverted: Q rolls right, E rolls left)
        roll = Mathf.DegToRad(-Input.GetAxis("roll_left", "roll_right") * RollRate * delta);

        // Apply POV rotation
        if (pitch != 0f || yaw != 0f || roll != 0f)
            _fbw.RotatePov(pitch, yaw, roll);
    }

    private void ProcessSpeedInput(float delta)
    {
        if (_fbw == null) return;

        // W/S control target speed
        var throttle = Input.GetActionStrength("thrust_forward") - Input.GetActionStrength("thrust_backward");

        if (throttle != 0f)
        {
            var speedChange = throttle * ThrottleRate * delta;
            var newSpeed = Mathf.Clamp(_fbw.TargetSpeed + speedChange, 0f, MaxSpeed);
            _fbw.SetTargetSpeed(newSpeed);
        }

        // Shift for boost (temporary speed increase)
        if (Input.IsActionPressed("boost"))
        {
            var boostSpeed = _fbw.TargetSpeed * 1.5f;
            _fbw.SetTargetSpeed(Mathf.Min(boostSpeed, MaxSpeed * 1.5f));
        }
    }

    private void ProcessStrafeInput()
    {
        if (_fbw == null) return;

        // A/D for left/right strafe
        var strafeX = Input.GetActionStrength("thrust_right") - Input.GetActionStrength("thrust_left");

        // Space/Ctrl for up/down strafe
        var strafeY = Input.GetActionStrength("thrust_up") - Input.GetActionStrength("thrust_down");

        _fbw.SetStrafeInput(new Vector3(strafeX, strafeY, 0f));
    }

    private void ProcessOtherInput()
    {
        // Camera mode toggle
        if (Input.IsActionJustPressed("toggle_camera"))
        {
            CameraRig?.CycleCameraMode();
        }
    }

    #endregion

    #region Camera Integration

    private void UpdateCamera()
    {
        if (CameraRig != null && _fbw != null)
            CameraRig.PovBasis = _fbw.PovBasis;
    }

    private void OnPovChanged(Basis povBasis)
    {
        CameraRig?.SetPov(povBasis);
    }

    #endregion

    #region Mouse Handling

    private void CaptureMouse()
    {
        Input.MouseMode = Input.MouseModeEnum.Captured;
        _isMouseCaptured = true;
    }

    private void ReleaseMouse()
    {
        Input.MouseMode = Input.MouseModeEnum.Visible;
        _isMouseCaptured = false;
    }

    #endregion

    #region HUD Integration

    private void UpdateHud()
    {
        var fbwInfo = _fbw?.GetDebugInfo() ?? new Dictionary();

        var povBasis = _fbw?.PovBasis ?? Basis.Identity;
        var shipBasis = GlobalTransform.Basis;
        var hudData = new Dictionary
        {
            ["speed"] = LinearVelocity.Length(),
            ["target_speed"] = _fbw?.TargetSpeed ?? 0f,
            ["velocity"] = LinearVelocity,
            ["local_velocity"] = GlobalTransform.Basis.Inverse() * LinearVelocity,
            ["g_force"] = 0f, // TODO: Calculate from acceleration
            ["is_maneuvering"] = fbwInfo.TryGetValue("is_maneuvering", out var m) && m.AsBool(),
            ["pov_forward"] = -povBasis.Z,
            ["pov_right"] = povBasis.X,
            ["pov_up"] = povBasis.Y,
            ["pov_basis"] = povBasis,
            ["ship_forward"] = -shipBasis.Z,
            ["ship_basis"] = shipBasis,
            // Debug data from FBW
            ["thrust_velocity"] = fbwInfo.TryGetValue("thrust_velocity", out var tv) ? tv : Vector3.Zero,
            ["rcs_velocity"] = fbwInfo.TryGetValue("rcs_velocity", out var rv) ? rv : Vector3.Zero
        };

        Events.Instance.EmitSignal(Events.SignalName.HudUpdateRequested, hudData);
    }

    #endregion

    #region Settings

    private void OnSettingChanged(string category, string key, Variant value)
    {
        if (category != "gameplay") return;

        if (key == "mouse_sensitivity")
            MouseSensitivity = value.AsSingle() * 0.5f;
    }

    #endregion
}
