using Godot;
using Godot.Collections;

namespace Remnant.Core;

/// <summary>
/// Fly-by-wire flight controller that decouples pilot POV from ship orientation.
/// The pilot controls where they WANT to go (POV), and the FBW system
/// computes the maneuvers needed to achieve that in Newtonian physics.
/// </summary>
public partial class FlyByWire : Node
{
    #region Signals

    [Signal] public delegate void PovChangedEventHandler(Basis povBasis);
    [Signal] public delegate void ManeuverStatusChangedEventHandler(bool isManeuvering);

    #endregion

    #region Exports

    [ExportGroup("Response")]
    [Export] public float ManeuverAcceleration { get; set; } = 20.0f;
    [Export] public float RotationRate { get; set; } = 180.0f;
    [Export] public float VelocityMatchThreshold { get; set; } = 0.5f;
    [Export] public float OrientationMatchThreshold { get; set; } = 2.0f;

    [ExportGroup("Thrust Limits")]
    [Export] public float MaxThrust { get; set; } = 100000.0f;
    [Export] public float RcsThrust { get; set; } = 30000.0f; // RCS lateral thrust

    #endregion

    #region State

    public Basis PovBasis { get; private set; } = Basis.Identity;
    public float TargetSpeed { get; private set; }
    public Vector3 StrafeInput { get; private set; } // Local space strafe input (-1 to 1)

    private RigidBody3D? _ship;
    private bool _isManeuvering;

    // Completely separate velocity tracking for RCS and thrust systems
    // Actual ship velocity = _rcsVelocity + _thrustVelocity
    private Vector3 _rcsVelocity = Vector3.Zero;      // Lateral velocity managed by RCS
    private Vector3 _thrustVelocity = Vector3.Zero;   // Forward velocity managed by main thrust
    private const float MaxStrafeSpeed = 30f;         // Max strafe velocity in m/s

    #endregion

    public override void _Ready()
    {
        SetPhysicsProcess(false);
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_ship == null) return;
        ExecuteFbw((float)delta);
    }

    #region Public Interface

    public void Initialize(RigidBody3D ship)
    {
        _ship = ship;
        PovBasis = ship.GlobalTransform.Basis;

        // Initialize thrust velocity to current forward velocity
        var currentVelocity = ship.LinearVelocity;
        var forward = -PovBasis.Z;
        var forwardSpeed = currentVelocity.Dot(forward);
        _thrustVelocity = forward * Mathf.Max(0f, forwardSpeed);
        TargetSpeed = Mathf.Max(0f, forwardSpeed);

        // Any remaining velocity is considered RCS velocity
        _rcsVelocity = currentVelocity - _thrustVelocity;

        SetPhysicsProcess(true);
    }

    public void RotatePov(float pitch, float yaw, float roll)
    {
        // All rotations in local space for consistent feel regardless of orientation
        var localX = PovBasis.X;
        var localY = PovBasis.Y;
        var localZ = PovBasis.Z;

        // Pitch around local X (look up/down)
        if (pitch != 0f)
            PovBasis = PovBasis.Rotated(localX, pitch);

        // Yaw around local Y (turn left/right) - recalculate after pitch
        if (yaw != 0f)
        {
            localY = PovBasis.Y;
            PovBasis = PovBasis.Rotated(localY, -yaw);
        }

        // Roll around local Z (bank left/right) - recalculate after yaw
        if (roll != 0f)
        {
            localZ = PovBasis.Z;
            PovBasis = PovBasis.Rotated(localZ, roll);
        }

        PovBasis = PovBasis.Orthonormalized();
        EmitSignal(SignalName.PovChanged, PovBasis);
    }

    public void SetTargetSpeed(float speed)
    {
        TargetSpeed = Mathf.Max(0f, speed);
    }

    public void AdjustSpeed(float deltaSpeed)
    {
        TargetSpeed = Mathf.Max(0f, TargetSpeed + deltaSpeed);
    }

    public void SetStrafeInput(Vector3 localStrafe)
    {
        StrafeInput = localStrafe;
    }

    public Vector3 GetPovForward() => -PovBasis.Z;
    public Vector3 GetPovRight() => PovBasis.X;
    public Vector3 GetPovUp() => PovBasis.Y;

    public Vector3 GetTargetVelocity()
    {
        // Base velocity from forward speed only
        // Strafe is handled separately via RCS
        return GetPovForward() * TargetSpeed;
    }

    public bool IsManeuvering() => _isManeuvering;

    #endregion

    #region FBW Core

    private void ExecuteFbw(float delta)
    {
        if (_ship == null) return;

        // Update RCS velocity (completely independent of thrust)
        UpdateRcsVelocity(delta);

        // Update thrust velocity (completely independent of RCS)
        UpdateThrustVelocity(delta);

        // Set actual ship velocity as the sum of both systems
        _ship.LinearVelocity = _rcsVelocity + _thrustVelocity;

        // Handle ship orientation (only when not maneuvering)
        var targetThrustVelocity = GetPovForward() * TargetSpeed;
        var thrustDelta = (targetThrustVelocity - _thrustVelocity).Length();

        var wasManeuvering = _isManeuvering;
        _isManeuvering = thrustDelta > VelocityMatchThreshold;

        if (wasManeuvering != _isManeuvering)
            EmitSignal(SignalName.ManeuverStatusChanged, _isManeuvering);

        if (!_isManeuvering)
            AlignShipToPov(delta);
    }

    private void UpdateRcsVelocity(float delta)
    {
        // Target RCS velocity based on strafe input (in current POV space)
        var targetRcs = GetPovRight() * StrafeInput.X * MaxStrafeSpeed
                      + GetPovUp() * StrafeInput.Y * MaxStrafeSpeed;

        // Smoothly move current RCS velocity toward target
        var rcsAccel = RcsThrust / _ship!.Mass;
        var maxChange = rcsAccel * delta;

        var rcsError = targetRcs - _rcsVelocity;
        if (rcsError.Length() <= maxChange)
        {
            _rcsVelocity = targetRcs;
        }
        else
        {
            _rcsVelocity += rcsError.Normalized() * maxChange;
        }
    }

    private void UpdateThrustVelocity(float delta)
    {
        // Target thrust velocity is forward at target speed
        var targetThrust = GetPovForward() * TargetSpeed;

        // Calculate error
        var thrustError = targetThrust - _thrustVelocity;
        if (thrustError.Length() < VelocityMatchThreshold)
        {
            _thrustVelocity = targetThrust;
            return;
        }

        // Apply corrective thrust with ship rotation
        var thrustAccel = MaxThrust / _ship!.Mass;
        var maxChange = Mathf.Min(thrustError.Length(), ManeuverAcceleration * delta);

        // Rotate ship toward thrust direction if needed
        var thrustDirection = thrustError.Normalized();
        var currentForward = -_ship.GlobalTransform.Basis.Z;
        var angleToThrust = currentForward.AngleTo(thrustDirection);

        if (angleToThrust > Mathf.DegToRad(OrientationMatchThreshold))
        {
            RotateShipToward(thrustDirection, delta);

            // Only apply partial thrust if not aligned
            var alignment = currentForward.Dot(thrustDirection);
            if (alignment > 0.5f)
            {
                _thrustVelocity += currentForward * maxChange * alignment;
            }
        }
        else
        {
            // Well aligned - apply full thrust correction
            _thrustVelocity += thrustDirection * maxChange;
        }
    }

    private void RotateShipToward(Vector3 targetDirection, float delta)
    {
        if (_ship == null) return;

        var currentBasis = _ship.GlobalTransform.Basis;
        var currentForward = -currentBasis.Z;

        // Calculate rotation axis and angle
        var rotationAxis = currentForward.Cross(targetDirection);
        if (rotationAxis.LengthSquared() < 0.0001f)
        {
            // Vectors are parallel or anti-parallel
            if (currentForward.Dot(targetDirection) < 0)
                rotationAxis = currentBasis.X; // Need to flip 180 - use any perpendicular axis
            else
                return; // Already aligned
        }

        rotationAxis = rotationAxis.Normalized();
        var angle = currentForward.AngleTo(targetDirection);

        // Limit rotation speed
        var maxRotation = Mathf.DegToRad(RotationRate) * delta;
        angle = Mathf.Min(angle, maxRotation);

        // Apply rotation
        var rotation = new Basis(rotationAxis, angle);
        var newBasis = rotation * currentBasis;
        _ship.GlobalTransform = new Transform3D(newBasis.Orthonormalized(), _ship.GlobalPosition);

        // Zero out angular velocity - FBW controls rotation directly
        _ship.AngularVelocity = Vector3.Zero;
    }

    private void AlignShipToPov(float delta)
    {
        if (_ship == null) return;

        // When not maneuvering, smoothly align ship orientation to match POV
        var currentBasis = _ship.GlobalTransform.Basis;

        var currentQuat = new Quaternion(currentBasis);
        var targetQuat = new Quaternion(PovBasis);

        var maxRotation = Mathf.DegToRad(RotationRate) * delta;
        var angle = currentQuat.AngleTo(targetQuat);

        if (angle > Mathf.DegToRad(OrientationMatchThreshold))
        {
            var t = Mathf.Min(1f, maxRotation / angle);
            var newQuat = currentQuat.Slerp(targetQuat, t);
            _ship.GlobalTransform = new Transform3D(new Basis(newQuat), _ship.GlobalPosition);
        }
        else
        {
            _ship.GlobalTransform = new Transform3D(PovBasis, _ship.GlobalPosition);
        }

        // Zero angular velocity
        _ship.AngularVelocity = Vector3.Zero;
    }

    #endregion

    #region Debug

    public Dictionary GetDebugInfo()
    {
        if (_ship == null) return new Dictionary();

        return new Dictionary
        {
            ["pov_forward"] = GetPovForward(),
            ["target_velocity"] = GetTargetVelocity(),
            ["target_speed"] = TargetSpeed,
            ["current_velocity"] = _ship.LinearVelocity,
            ["current_speed"] = _ship.LinearVelocity.Length(),
            ["thrust_velocity"] = _thrustVelocity,
            ["rcs_velocity"] = _rcsVelocity,
            ["is_maneuvering"] = _isManeuvering,
            ["ship_forward"] = -_ship.GlobalTransform.Basis.Z
        };
    }

    #endregion
}
