## Fly-by-wire flight controller that decouples pilot POV from ship orientation.
## The pilot controls where they WANT to go (POV), and the FBW system
## computes the maneuvers needed to achieve that in Newtonian physics.
class_name FlyByWire
extends Node

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------

signal pov_changed(pov_basis: Basis)
signal maneuver_status_changed(is_maneuvering: bool)

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Response")
## How quickly the ship can change velocity (m/s² effective acceleration)
@export var maneuver_acceleration: float = 20.0

## How quickly the ship rotates to match required thrust direction (deg/s)
@export var rotation_rate: float = 180.0

## Threshold for considering velocity "matched" (m/s)
@export var velocity_match_threshold: float = 0.5

## Threshold for considering orientation "matched" (degrees)
@export var orientation_match_threshold: float = 2.0

@export_group("Thrust Limits")
## Maximum thrust force available (Newtons)
@export var max_thrust: float = 100000.0

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

## The pilot's point-of-view orientation (where they want to go)
var pov_basis: Basis = Basis.IDENTITY

## The target speed the pilot wants to maintain
var target_speed: float = 0.0

## Reference to the ship we're controlling
var _ship: RigidBody3D

## Is the FBW currently executing a maneuver?
var _is_maneuvering: bool = false

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	set_physics_process(false)  # Enabled when ship is set


func _physics_process(delta: float) -> void:
	if not _ship:
		return

	_execute_fbw(delta)

# -----------------------------------------------------------------------------
# Public Interface
# -----------------------------------------------------------------------------

## Initialize the FBW with a ship to control
func initialize(ship: RigidBody3D) -> void:
	_ship = ship
	pov_basis = ship.global_transform.basis
	target_speed = ship.linear_velocity.length()
	set_physics_process(true)


## Rotate the POV by the given euler angles (in radians)
func rotate_pov(pitch: float, yaw: float, roll: float) -> void:
	# Apply all rotations in local space for consistent feel regardless of orientation
	# Order: pitch first, then yaw, then roll
	var local_x := pov_basis.x
	var local_y := pov_basis.y
	var local_z := pov_basis.z

	# Pitch around local X (look up/down)
	if pitch != 0.0:
		pov_basis = pov_basis.rotated(local_x, pitch)

	# Yaw around local Y (turn left/right) - recalculate after pitch
	if yaw != 0.0:
		local_y = pov_basis.y
		pov_basis = pov_basis.rotated(local_y, -yaw)

	# Roll around local Z (bank left/right) - recalculate after yaw
	if roll != 0.0:
		local_z = pov_basis.z
		pov_basis = pov_basis.rotated(local_z, roll)

	pov_basis = pov_basis.orthonormalized()
	pov_changed.emit(pov_basis)


## Set the target speed (what speed to maintain during maneuvers)
func set_target_speed(speed: float) -> void:
	target_speed = maxf(0.0, speed)


## Increase/decrease target speed
func adjust_speed(delta_speed: float) -> void:
	target_speed = maxf(0.0, target_speed + delta_speed)


## Get the POV forward direction (where pilot wants to go)
func get_pov_forward() -> Vector3:
	return -pov_basis.z


## Get the current target velocity
func get_target_velocity() -> Vector3:
	return get_pov_forward() * target_speed


## Check if currently maneuvering (velocity doesn't match target)
func is_maneuvering() -> bool:
	return _is_maneuvering

# -----------------------------------------------------------------------------
# Fly-By-Wire Core
# -----------------------------------------------------------------------------

func _execute_fbw(delta: float) -> void:
	var current_velocity := _ship.linear_velocity
	var current_speed := current_velocity.length()

	# Calculate target velocity: POV direction * target speed
	var target_velocity := get_target_velocity()

	# Calculate the velocity delta we need to achieve
	var velocity_delta := target_velocity - current_velocity
	var delta_magnitude := velocity_delta.length()

	# Check if we're close enough to target
	var was_maneuvering := _is_maneuvering
	_is_maneuvering = delta_magnitude > velocity_match_threshold

	if was_maneuvering != _is_maneuvering:
		maneuver_status_changed.emit(_is_maneuvering)

	if _is_maneuvering:
		# We need to maneuver - apply thrust in the direction of velocity_delta
		_apply_corrective_thrust(velocity_delta, delta)
	else:
		# Velocity matched - align ship orientation with POV
		_align_ship_to_pov(delta)


func _apply_corrective_thrust(velocity_delta: Vector3, delta: float) -> void:
	var delta_magnitude := velocity_delta.length()
	var thrust_direction := velocity_delta.normalized()

	# Calculate how much thrust we need
	# F = m * a, we want acceleration that would achieve velocity_delta
	var desired_acceleration := minf(delta_magnitude / delta, maneuver_acceleration)
	var thrust_force := desired_acceleration * _ship.mass
	thrust_force = minf(thrust_force, max_thrust)

	# First, rotate the ship to point in the thrust direction
	var current_forward := -_ship.global_transform.basis.z
	var angle_to_thrust := current_forward.angle_to(thrust_direction)

	if angle_to_thrust > deg_to_rad(orientation_match_threshold):
		# Need to rotate ship to face thrust direction
		_rotate_ship_toward(thrust_direction, delta)

		# Only apply partial thrust if not aligned (efficiency loss)
		var alignment := current_forward.dot(thrust_direction)
		if alignment > 0.5:  # At least 60 degrees aligned
			var effective_thrust := thrust_force * alignment
			_ship.apply_central_force(current_forward * effective_thrust)
	else:
		# Well aligned - apply full thrust
		_ship.apply_central_force(thrust_direction * thrust_force)


func _rotate_ship_toward(target_direction: Vector3, delta: float) -> void:
	var current_basis := _ship.global_transform.basis
	var current_forward := -current_basis.z

	# Calculate rotation axis and angle
	var rotation_axis := current_forward.cross(target_direction)
	if rotation_axis.length_squared() < 0.0001:
		# Vectors are parallel or anti-parallel
		if current_forward.dot(target_direction) < 0:
			# Need to flip 180 - use any perpendicular axis
			rotation_axis = current_basis.x
		else:
			return  # Already aligned

	rotation_axis = rotation_axis.normalized()
	var angle := current_forward.angle_to(target_direction)

	# Limit rotation speed
	var max_rotation := deg_to_rad(rotation_rate) * delta
	angle = minf(angle, max_rotation)

	# Apply rotation
	var rotation := Basis(rotation_axis, angle)
	var new_basis := rotation * current_basis
	_ship.global_transform.basis = new_basis.orthonormalized()

	# Zero out angular velocity - FBW controls rotation directly
	_ship.angular_velocity = Vector3.ZERO


func _align_ship_to_pov(delta: float) -> void:
	# When not maneuvering, smoothly align ship orientation to match POV
	var current_basis := _ship.global_transform.basis
	var target_basis := pov_basis

	# Interpolate toward POV orientation
	var current_quat := Quaternion(current_basis)
	var target_quat := Quaternion(target_basis)

	var max_rotation := deg_to_rad(rotation_rate) * delta
	var angle := current_quat.angle_to(target_quat)

	if angle > deg_to_rad(orientation_match_threshold):
		var t := minf(1.0, max_rotation / angle)
		var new_quat := current_quat.slerp(target_quat, t)
		_ship.global_transform.basis = Basis(new_quat)
	else:
		_ship.global_transform.basis = target_basis

	# Zero angular velocity
	_ship.angular_velocity = Vector3.ZERO

# -----------------------------------------------------------------------------
# Debug
# -----------------------------------------------------------------------------

func get_debug_info() -> Dictionary:
	if not _ship:
		return {}

	return {
		"pov_forward": get_pov_forward(),
		"target_velocity": get_target_velocity(),
		"target_speed": target_speed,
		"current_velocity": _ship.linear_velocity,
		"current_speed": _ship.linear_velocity.length(),
		"velocity_delta": get_target_velocity() - _ship.linear_velocity,
		"is_maneuvering": _is_maneuvering,
		"ship_forward": -_ship.global_transform.basis.z,
	}
