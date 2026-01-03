## Mathematical utilities for space physics and gameplay calculations.
class_name MathUtils
extends RefCounted

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

const G := 6.674e-11          ## Gravitational constant (m³/kg/s²)
const C := 299792458.0        ## Speed of light (m/s)
const AU := 149597870700.0    ## Astronomical unit (m)

# -----------------------------------------------------------------------------
# Vector Operations
# -----------------------------------------------------------------------------

## Clamp a vector's magnitude
static func clamp_magnitude(v: Vector3, max_length: float) -> Vector3:
	var length := v.length()
	if length > max_length and length > 0:
		return v * (max_length / length)
	return v


## Get the component of vector A in the direction of vector B
static func project_onto(a: Vector3, b: Vector3) -> Vector3:
	var b_normalized := b.normalized()
	return b_normalized * a.dot(b_normalized)


## Get the component of vector A perpendicular to vector B
static func reject_from(a: Vector3, b: Vector3) -> Vector3:
	return a - project_onto(a, b)


## Smoothly interpolate between two vectors with variable speed
static func smooth_damp_vector(
	current: Vector3,
	target: Vector3,
	velocity: Vector3,
	smooth_time: float,
	max_speed: float,
	delta: float
) -> Dictionary:
	smooth_time = maxf(0.0001, smooth_time)
	var omega := 2.0 / smooth_time
	var x := omega * delta
	var exp_factor := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)

	var change := current - target
	var max_change := max_speed * smooth_time
	change = clamp_magnitude(change, max_change)

	var temp := (velocity + omega * change) * delta
	var new_velocity := (velocity - omega * temp) * exp_factor
	var new_value := target + (change + temp) * exp_factor

	# Prevent overshoot
	if (target - current).dot(new_value - target) > 0:
		new_value = target
		new_velocity = (new_value - current) / delta

	return {"value": new_value, "velocity": new_velocity}

# -----------------------------------------------------------------------------
# Angle Operations
# -----------------------------------------------------------------------------

## Get signed angle between two vectors around an axis
static func signed_angle(from: Vector3, to: Vector3, axis: Vector3) -> float:
	var cross := from.cross(to)
	var angle := atan2(cross.length(), from.dot(to))
	return angle if cross.dot(axis) >= 0 else -angle


## Wrap angle to -PI to PI range
static func wrap_angle(angle: float) -> float:
	while angle > PI:
		angle -= TAU
	while angle < -PI:
		angle += TAU
	return angle

# -----------------------------------------------------------------------------
# Space Physics
# -----------------------------------------------------------------------------

## Calculate gravitational acceleration at a distance from a mass
static func gravitational_acceleration(mass: float, distance: float) -> float:
	if distance <= 0:
		return 0.0
	return G * mass / (distance * distance)


## Calculate escape velocity from a body
static func escape_velocity(mass: float, radius: float) -> float:
	if radius <= 0:
		return 0.0
	return sqrt(2.0 * G * mass / radius)


## Calculate orbital velocity for circular orbit
static func circular_orbital_velocity(central_mass: float, radius: float) -> float:
	if radius <= 0:
		return 0.0
	return sqrt(G * central_mass / radius)


## Calculate orbital period
static func orbital_period(central_mass: float, semi_major_axis: float) -> float:
	if semi_major_axis <= 0 or central_mass <= 0:
		return 0.0
	return TAU * sqrt(pow(semi_major_axis, 3) / (G * central_mass))


## Calculate time to reach a velocity with constant acceleration
static func time_to_velocity(
	current_velocity: float,
	target_velocity: float,
	acceleration: float
) -> float:
	if acceleration <= 0:
		return INF
	return absf(target_velocity - current_velocity) / acceleration


## Calculate distance traveled during acceleration
static func distance_during_acceleration(
	initial_velocity: float,
	final_velocity: float,
	acceleration: float
) -> float:
	if acceleration <= 0:
		return INF
	# v² = u² + 2as → s = (v² - u²) / 2a
	return (final_velocity * final_velocity - initial_velocity * initial_velocity) / (2.0 * acceleration)

# -----------------------------------------------------------------------------
# Interpolation
# -----------------------------------------------------------------------------

## Exponential decay interpolation (frame-rate independent)
static func exp_decay(current: float, target: float, decay: float, delta: float) -> float:
	return target + (current - target) * exp(-decay * delta)


## Vector version of exp_decay
static func exp_decay_v3(current: Vector3, target: Vector3, decay: float, delta: float) -> Vector3:
	return target + (current - target) * exp(-decay * delta)


## Critically damped spring interpolation
static func spring_damp(
	current: float,
	target: float,
	velocity: float,
	frequency: float,
	delta: float
) -> Dictionary:
	var omega := frequency * TAU
	var x := current - target
	var exp_term := exp(-omega * delta)

	var new_pos := target + (x + (velocity + omega * x) * delta) * exp_term
	var new_vel := (velocity - omega * (velocity + omega * x) * delta) * exp_term

	return {"position": new_pos, "velocity": new_vel}

# -----------------------------------------------------------------------------
# Utility
# -----------------------------------------------------------------------------

## Convert m/s to km/h
static func mps_to_kmh(mps: float) -> float:
	return mps * 3.6


## Convert km/h to m/s
static func kmh_to_mps(kmh: float) -> float:
	return kmh / 3.6


## Format velocity for display
static func format_velocity(mps: float, use_metric: bool = true) -> String:
	if use_metric:
		if mps >= 1000:
			return "%.1f km/s" % (mps / 1000.0)
		else:
			return "%.0f m/s" % mps
	else:
		var mph := mps * 2.237
		return "%.0f mph" % mph


## Format distance for display
static func format_distance(meters: float, use_metric: bool = true) -> String:
	if use_metric:
		if meters >= 1000:
			return "%.2f km" % (meters / 1000.0)
		else:
			return "%.0f m" % meters
	else:
		var feet := meters * 3.281
		if feet >= 5280:
			return "%.2f mi" % (feet / 5280.0)
		else:
			return "%.0f ft" % feet
