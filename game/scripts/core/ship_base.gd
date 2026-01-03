## Base class for all spacecraft in the game.
## Implements Newtonian physics with optional flight assist.
class_name ShipBase
extends RigidBody3D

# -----------------------------------------------------------------------------
# Enums
# -----------------------------------------------------------------------------

enum FlightAssistLevel {
	OFF = 0,      ## Full manual control - pure Newtonian
	LOW = 1,      ## Minimal assistance - dampens rotation only
	MEDIUM = 2,   ## Moderate assistance - helps maintain heading
	HIGH = 3,     ## Full assistance - maintains velocity direction
}

# -----------------------------------------------------------------------------
# Exports - Ship Configuration
# -----------------------------------------------------------------------------

@export_group("Thrust")
## Maximum main engine thrust in Newtons
@export var thrust_main: float = 50000.0

## Maximum maneuvering thruster force in Newtons
@export var thrust_maneuver: float = 20000.0

## Maximum rotational torque in Newton-meters
@export var torque_max: float = 10000.0

@export_group("Performance")
## Ship mass in kilograms
@export var ship_mass: float = 5000.0

## Maximum structural velocity (m/s) before damage
@export var max_safe_velocity: float = 500.0

## Boost multiplier for thrust
@export var boost_multiplier: float = 1.5

## Boost fuel capacity (seconds of boost)
@export var boost_capacity: float = 5.0

## Boost fuel regeneration rate (per second)
@export var boost_regen_rate: float = 0.5

@export_group("Flight Assist")
## Default flight assist level
@export var default_assist_level: FlightAssistLevel = FlightAssistLevel.HIGH

## How aggressively assist corrects velocity (higher = snappier)
@export var assist_strength: float = 10.0

## How strongly rotation is dampened when no input (higher = stops faster)
@export var rotation_damping: float = 8.0

## Linear velocity damping when no thrust (acts like space brake)
@export var velocity_damping: float = 2.0

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

## Current flight assist level
var assist_level: FlightAssistLevel:
	set(value):
		if assist_level != value:
			assist_level = value
			Events.flight_assist_changed.emit(self, assist_level)

## Current boost fuel
var boost_fuel: float

## Is boost currently active?
var is_boosting: bool = false

## Current thrust input (normalized -1 to 1 for each axis)
var thrust_input: Vector3 = Vector3.ZERO

## Current rotation input (normalized -1 to 1 for pitch, yaw, roll)
var rotation_input: Vector3 = Vector3.ZERO

## Desired velocity direction for flight assist (world space)
var _assist_target_direction: Vector3 = Vector3.FORWARD

# -----------------------------------------------------------------------------
# Cached References
# -----------------------------------------------------------------------------

var _previous_velocity: Vector3 = Vector3.ZERO

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	# Configure RigidBody
	mass = ship_mass
	gravity_scale = 0.0  # Space has no gravity
	linear_damp = 0.0    # No atmospheric drag
	angular_damp = 0.0   # No atmospheric drag

	# Initialize state
	assist_level = default_assist_level
	boost_fuel = boost_capacity

	Events.ship_spawned.emit(self)


func _physics_process(delta: float) -> void:
	_process_boost(delta)
	_apply_thrust(delta)
	_apply_rotation(delta)
	_apply_flight_assist(delta)
	_check_velocity_warning()

	_previous_velocity = linear_velocity

# -----------------------------------------------------------------------------
# Input Interface (Override in derived classes or call from controller)
# -----------------------------------------------------------------------------

## Set thrust input vector (each component -1 to 1)
func set_thrust_input(input: Vector3) -> void:
	thrust_input = input.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))


## Set rotation input vector (pitch, yaw, roll, each -1 to 1)
func set_rotation_input(input: Vector3) -> void:
	rotation_input = input.clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))


## Toggle flight assist level
func cycle_assist_level() -> void:
	assist_level = (assist_level + 1) % (FlightAssistLevel.HIGH + 1) as FlightAssistLevel


## Set boost state
func set_boosting(active: bool) -> void:
	is_boosting = active and boost_fuel > 0

# -----------------------------------------------------------------------------
# Physics
# -----------------------------------------------------------------------------

func _apply_thrust(delta: float) -> void:
	if thrust_input.is_zero_approx():
		return

	var thrust_force := Vector3.ZERO

	# Main engine thrust (forward/backward)
	thrust_force.z = -thrust_input.z * thrust_main

	# Maneuvering thrusters (lateral and vertical)
	thrust_force.x = thrust_input.x * thrust_maneuver
	thrust_force.y = thrust_input.y * thrust_maneuver

	# Apply boost multiplier
	if is_boosting:
		thrust_force *= boost_multiplier

	# Transform to world space and apply
	var world_force := global_transform.basis * thrust_force
	apply_central_force(world_force)


func _apply_rotation(_delta: float) -> void:
	if rotation_input.is_zero_approx():
		return

	var torque := Vector3.ZERO
	torque.x = -rotation_input.x * torque_max  # Pitch
	torque.y = -rotation_input.y * torque_max  # Yaw
	torque.z = -rotation_input.z * torque_max  # Roll

	# Transform to world space and apply
	var world_torque := global_transform.basis * torque
	apply_torque(world_torque)


func _process_boost(delta: float) -> void:
	if is_boosting and boost_fuel > 0:
		boost_fuel -= delta
		if boost_fuel <= 0:
			boost_fuel = 0
			is_boosting = false
	elif not is_boosting and boost_fuel < boost_capacity:
		boost_fuel += boost_regen_rate * delta
		boost_fuel = minf(boost_fuel, boost_capacity)

# -----------------------------------------------------------------------------
# Flight Assist
# -----------------------------------------------------------------------------

func _apply_flight_assist(delta: float) -> void:
	if assist_level == FlightAssistLevel.OFF:
		return

	match assist_level:
		FlightAssistLevel.LOW:
			_assist_dampen_rotation(delta)
		FlightAssistLevel.MEDIUM:
			_assist_dampen_rotation(delta)
			_assist_maintain_heading(delta)
		FlightAssistLevel.HIGH:
			_assist_dampen_rotation(delta)
			_assist_maintain_velocity_direction(delta)


## Dampens unwanted rotation when no input - makes ship feel stable
func _assist_dampen_rotation(delta: float) -> void:
	# Always apply some damping, even with input (prevents spin-out)
	var damping_strength := rotation_damping
	if not rotation_input.is_zero_approx():
		damping_strength *= 0.3  # Less damping when actively rotating

	# Apply strong counter-torque to stop rotation quickly
	var damping_torque := -angular_velocity * torque_max * damping_strength
	apply_torque(damping_torque)


## Helps maintain the ship's current heading
func _assist_maintain_heading(delta: float) -> void:
	# Only assist when not actively rotating and moving
	if not rotation_input.is_zero_approx():
		return
	if linear_velocity.length_squared() < 1.0:
		return

	# Update target direction when thrusting forward
	if thrust_input.z < -0.1:  # Thrusting forward
		_assist_target_direction = -global_transform.basis.z


## Maintains velocity in the direction the ship is pointing
func _assist_maintain_velocity_direction(delta: float) -> void:
	var current_speed := linear_velocity.length()

	# Apply velocity damping when not thrusting (space brake effect)
	if thrust_input.is_zero_approx() and current_speed > 0.5:
		var brake_force := -linear_velocity * mass * velocity_damping
		apply_central_force(brake_force * delta)

	if current_speed < 0.5:
		# At very low speeds, just zero out velocity to prevent drift
		if current_speed > 0.01:
			linear_velocity = linear_velocity.lerp(Vector3.ZERO, delta * 5.0)
		return

	var current_direction := linear_velocity.normalized()
	var desired_direction := -global_transform.basis.z  # Ship's forward

	# Calculate the correction needed
	var correction := desired_direction - current_direction

	# Apply very strong corrective force - ship goes where it's pointing
	var correction_force := correction * current_speed * mass * assist_strength
	apply_central_force(correction_force * delta)

# -----------------------------------------------------------------------------
# State Queries
# -----------------------------------------------------------------------------

## Get current speed in m/s
func get_speed() -> float:
	return linear_velocity.length()


## Get current velocity relative to ship orientation
func get_local_velocity() -> Vector3:
	return global_transform.basis.inverse() * linear_velocity


## Get current acceleration (m/s²)
func get_acceleration() -> Vector3:
	# This is a rough estimate based on velocity change
	return (linear_velocity - _previous_velocity) / get_physics_process_delta_time()


## Get current G-force
func get_g_force() -> float:
	return get_acceleration().length() / 9.81


## Check if approaching dangerous velocity
func is_velocity_critical() -> bool:
	return linear_velocity.length() > max_safe_velocity * 0.9


func _check_velocity_warning() -> void:
	var speed := linear_velocity.length()
	if speed > max_safe_velocity:
		# TODO: Apply damage or warning
		pass
