## Camera rig that follows the pilot's POV (not the ship orientation).
## Works with FlyByWire to show where the pilot WANTS to go.
class_name ShipCameraRig
extends Node3D

# -----------------------------------------------------------------------------
# Enums
# -----------------------------------------------------------------------------

enum CameraMode {
	THIRD_PERSON,   ## Chase camera behind POV
	FIRST_PERSON,   ## Cockpit view following POV
}

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Camera Setup")
## The ship this camera follows (for position)
@export var target_ship: Node3D

@export_group("Third Person")
## Distance behind POV in meters
@export var follow_distance: float = 15.0

## Height above ship in meters
@export var follow_height: float = 5.0

## Camera position smoothing (higher = more responsive)
@export var position_smoothing: float = 12.0

@export_group("First Person")
## Position of cockpit camera in ship local space (negative Z is forward)
@export var cockpit_position: Vector3 = Vector3(0, 0.5, -2.0)

@export_group("Field of View")
## Base field of view
@export var base_fov: float = 75.0

## FOV increase based on speed (degrees per 100 m/s)
@export var speed_fov_factor: float = 5.0

## Maximum FOV
@export var max_fov: float = 100.0

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var camera_mode: CameraMode = CameraMode.THIRD_PERSON
var _camera: Camera3D

## The POV basis to follow (set by FlyByWire or player input)
var pov_basis: Basis = Basis.IDENTITY

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	_camera = Camera3D.new()
	_camera.fov = base_fov
	_camera.near = 0.1
	_camera.far = 100000.0  # 100km view distance
	add_child(_camera)

	if not target_ship:
		push_error("ShipCameraRig: No target_ship assigned!")
		return

	# Initialize position
	global_position = target_ship.global_position
	global_rotation = target_ship.global_rotation


func _process(delta: float) -> void:
	if not target_ship:
		return

	match camera_mode:
		CameraMode.THIRD_PERSON:
			_update_third_person(delta)
		CameraMode.FIRST_PERSON:
			_update_first_person(delta)

	_update_dynamic_fov(delta)

# -----------------------------------------------------------------------------
# Camera Modes
# -----------------------------------------------------------------------------

func _update_third_person(delta: float) -> void:
	# Camera follows POV orientation, not ship orientation
	# This shows where the pilot WANTS to go
	var pov_back := pov_basis.z.normalized()   # POV back direction
	var pov_up := pov_basis.y.normalized()     # POV up direction

	# Offset from ship position using POV orientation
	var offset := pov_back * follow_distance + pov_up * follow_height
	var ideal_position := target_ship.global_position + offset

	# Smooth position following
	global_position = global_position.lerp(ideal_position, delta * position_smoothing)

	# Camera looks in POV direction (instant - no lag for responsiveness)
	global_transform.basis = pov_basis


func _update_first_person(_delta: float) -> void:
	# Position fixed at cockpit in ship's local space (moves with ship)
	# But camera looks in POV direction (where pilot wants to go)
	global_position = target_ship.global_position + target_ship.global_transform.basis * cockpit_position

	# Look in POV direction (shows where pilot wants to go)
	global_transform.basis = pov_basis


func _update_dynamic_fov(delta: float) -> void:
	if not target_ship:
		return

	# Get ship speed
	var speed := 0.0
	if target_ship is RigidBody3D:
		speed = (target_ship as RigidBody3D).linear_velocity.length()

	# Calculate FOV based on speed
	var target_fov := base_fov + (speed / 100.0) * speed_fov_factor
	target_fov = minf(target_fov, max_fov)

	# Smooth FOV transition
	_camera.fov = lerpf(_camera.fov, target_fov, delta * 5.0)

# -----------------------------------------------------------------------------
# Public Interface
# -----------------------------------------------------------------------------

## Switch between camera modes
func set_camera_mode(mode: CameraMode) -> void:
	camera_mode = mode
	Events.camera_mode_changed.emit(mode)


## Cycle to next camera mode
func cycle_camera_mode() -> void:
	var next_mode := (camera_mode + 1) % (CameraMode.FIRST_PERSON + 1) as CameraMode
	set_camera_mode(next_mode)


## Get the camera node
func get_camera() -> Camera3D:
	return _camera


## Set the target ship to follow
func set_target(ship: Node3D) -> void:
	target_ship = ship
	if ship:
		global_position = ship.global_position
		pov_basis = ship.global_transform.basis


## Set the POV basis (called by FlyByWire or input handler)
func set_pov(basis: Basis) -> void:
	pov_basis = basis
