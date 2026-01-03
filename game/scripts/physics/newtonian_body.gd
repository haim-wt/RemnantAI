## A pure Newtonian physics body for space simulation.
## Provides helper methods for force application and state queries.
## Extend this for objects that need accurate space physics.
class_name NewtonianBody
extends RigidBody3D

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------

signal velocity_changed(new_velocity: Vector3)
signal collision_detected(collision: KinematicCollision3D)

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Physics")
## Mass in kilograms
@export var body_mass: float = 1000.0:
	set(value):
		body_mass = value
		mass = value

## Maximum velocity magnitude (0 = unlimited)
@export var max_velocity: float = 0.0

@export_group("Simulation")
## Enable detailed physics logging
@export var debug_physics: bool = false

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _prev_velocity: Vector3 = Vector3.ZERO
var _accumulated_impulse: Vector3 = Vector3.ZERO

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	# Configure for space physics
	mass = body_mass
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0
	continuous_cd = true  # Better collision detection at high speeds


func _physics_process(delta: float) -> void:
	# Apply any accumulated impulse
	if not _accumulated_impulse.is_zero_approx():
		apply_central_impulse(_accumulated_impulse)
		_accumulated_impulse = Vector3.ZERO

	# Clamp velocity if max is set
	if max_velocity > 0 and linear_velocity.length() > max_velocity:
		linear_velocity = linear_velocity.normalized() * max_velocity

	# Emit velocity change signal
	if not linear_velocity.is_equal_approx(_prev_velocity):
		velocity_changed.emit(linear_velocity)

	_prev_velocity = linear_velocity

	if debug_physics:
		_debug_output()

# -----------------------------------------------------------------------------
# Force Application
# -----------------------------------------------------------------------------

## Apply thrust in local space direction
func apply_local_force(local_force: Vector3) -> void:
	var world_force := global_transform.basis * local_force
	apply_central_force(world_force)


## Apply thrust in local space direction as impulse
func apply_local_impulse(local_impulse: Vector3) -> void:
	var world_impulse := global_transform.basis * local_impulse
	apply_central_impulse(world_impulse)


## Apply torque in local space
func apply_local_torque(local_torque: Vector3) -> void:
	var world_torque := global_transform.basis * local_torque
	apply_torque(world_torque)


## Queue an impulse to be applied next physics frame
## Useful for applying forces from _process or signals
func queue_impulse(impulse: Vector3) -> void:
	_accumulated_impulse += impulse

# -----------------------------------------------------------------------------
# Orbital Mechanics Helpers
# -----------------------------------------------------------------------------

## Calculate velocity needed to orbit a point at current distance
func calculate_orbital_velocity(center: Vector3, orbital_mass: float) -> Vector3:
	const G := 6.674e-11  # Gravitational constant

	var to_center := center - global_position
	var distance := to_center.length()

	if distance < 0.001:
		return Vector3.ZERO

	# v = sqrt(GM/r)
	var orbital_speed := sqrt(G * orbital_mass / distance)

	# Perpendicular to radius in the current orbital plane
	var radial := to_center.normalized()
	var tangent := radial.cross(Vector3.UP).normalized()

	if tangent.is_zero_approx():
		tangent = radial.cross(Vector3.RIGHT).normalized()

	return tangent * orbital_speed


## Calculate gravitational force from a massive body
func calculate_gravitational_force(
	attractor_position: Vector3,
	attractor_mass: float
) -> Vector3:
	const G := 6.674e-11

	var to_attractor := attractor_position - global_position
	var distance_sq := to_attractor.length_squared()

	if distance_sq < 1.0:  # Prevent division by near-zero
		return Vector3.ZERO

	# F = G * m1 * m2 / r^2
	var force_magnitude := G * body_mass * attractor_mass / distance_sq

	return to_attractor.normalized() * force_magnitude

# -----------------------------------------------------------------------------
# State Queries
# -----------------------------------------------------------------------------

## Get velocity in local space
func get_local_velocity() -> Vector3:
	return global_transform.basis.inverse() * linear_velocity


## Get speed in m/s
func get_speed() -> float:
	return linear_velocity.length()


## Get acceleration since last frame
func get_acceleration() -> Vector3:
	var delta := get_physics_process_delta_time()
	if delta <= 0:
		return Vector3.ZERO
	return (linear_velocity - _prev_velocity) / delta


## Get kinetic energy in Joules
func get_kinetic_energy() -> float:
	# KE = 0.5 * m * v^2
	return 0.5 * body_mass * linear_velocity.length_squared()


## Get momentum
func get_momentum() -> Vector3:
	return linear_velocity * body_mass

# -----------------------------------------------------------------------------
# Debug
# -----------------------------------------------------------------------------

func _debug_output() -> void:
	print("NewtonianBody [%s]:" % name)
	print("  Position: %s" % global_position)
	print("  Velocity: %s (%.1f m/s)" % [linear_velocity, get_speed()])
	print("  Angular:  %s" % angular_velocity)
