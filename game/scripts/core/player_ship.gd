## Player-controlled ship with fly-by-wire flight system.
## Pilot controls POV (where they want to go), FBW handles the physics.
class_name PlayerShip
extends RigidBody3D

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Camera")
## Reference to the camera rig
@export var camera_rig_path: NodePath

@export_group("Input")
## Mouse sensitivity for POV rotation (degrees per pixel)
@export var mouse_sensitivity: float = 0.15

## Keyboard roll rate (degrees per second)
@export var roll_rate: float = 90.0

@export_group("Speed Control")
## Speed increase per second when holding throttle up
@export var throttle_rate: float = 20.0

## Maximum speed
@export var max_speed: float = 200.0

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _camera_rig: ShipCameraRig
var _fbw: FlyByWire
var _mouse_delta: Vector2 = Vector2.ZERO
var _is_mouse_captured: bool = false

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	# Configure RigidBody for space
	gravity_scale = 0.0
	linear_damp = 0.0
	angular_damp = 0.0

	# Create and initialize FBW system
	_fbw = FlyByWire.new()
	_fbw.name = "FlyByWire"
	add_child(_fbw)
	_fbw.initialize(self)

	# Connect FBW signals
	_fbw.pov_changed.connect(_on_pov_changed)

	# Get camera rig
	if not camera_rig_path.is_empty():
		_camera_rig = get_node(camera_rig_path)
		if _camera_rig:
			_camera_rig.pov_basis = global_transform.basis

	# Capture mouse
	_capture_mouse()

	# Load sensitivity from settings
	var saved_sens: float = Settings.get_value("gameplay", "mouse_sensitivity")
	if saved_sens > 0:
		mouse_sensitivity = saved_sens * 0.15

	Events.setting_changed.connect(_on_setting_changed)
	Events.ship_spawned.emit(self)


func _exit_tree() -> void:
	_release_mouse()


func _input(event: InputEvent) -> void:
	# Toggle mouse capture
	if event.is_action_pressed("pause"):
		if _is_mouse_captured:
			_release_mouse()
		else:
			_capture_mouse()
		return

	# Accumulate mouse movement
	if event is InputEventMouseMotion and _is_mouse_captured:
		_mouse_delta += event.relative


func _physics_process(delta: float) -> void:
	_process_pov_input(delta)
	_process_speed_input(delta)
	_process_other_input()
	_update_camera()
	_update_hud()

# -----------------------------------------------------------------------------
# Input Processing
# -----------------------------------------------------------------------------

func _process_pov_input(delta: float) -> void:
	# Mouse controls POV pitch and yaw
	var pitch := 0.0
	var yaw := 0.0
	var roll := 0.0

	if _is_mouse_captured:
		var invert_y := -1.0 if Settings.get_value("gameplay", "invert_y") else 1.0
		pitch = deg_to_rad(_mouse_delta.y * mouse_sensitivity * invert_y)
		yaw = deg_to_rad(_mouse_delta.x * mouse_sensitivity)
		_mouse_delta = Vector2.ZERO

	# Keyboard roll
	roll = deg_to_rad(Input.get_axis("roll_left", "roll_right") * roll_rate * delta)

	# Apply POV rotation
	if pitch != 0.0 or yaw != 0.0 or roll != 0.0:
		_fbw.rotate_pov(pitch, yaw, roll)


func _process_speed_input(delta: float) -> void:
	# W/S control target speed
	var throttle := 0.0
	throttle += Input.get_action_strength("thrust_forward")
	throttle -= Input.get_action_strength("thrust_backward")

	if throttle != 0.0:
		var speed_change := throttle * throttle_rate * delta
		var new_speed := clampf(_fbw.target_speed + speed_change, 0.0, max_speed)
		_fbw.set_target_speed(new_speed)

	# Shift for boost (temporary speed increase)
	if Input.is_action_pressed("boost"):
		# Boost allows exceeding max speed temporarily
		var boost_speed := _fbw.target_speed * 1.5
		_fbw.set_target_speed(minf(boost_speed, max_speed * 1.5))


func _process_other_input() -> void:
	# Camera mode toggle
	if Input.is_action_just_pressed("toggle_camera"):
		if _camera_rig:
			_camera_rig.cycle_camera_mode()

# -----------------------------------------------------------------------------
# Camera Integration
# -----------------------------------------------------------------------------

func _update_camera() -> void:
	if _camera_rig:
		_camera_rig.pov_basis = _fbw.pov_basis


func _on_pov_changed(pov_basis: Basis) -> void:
	if _camera_rig:
		_camera_rig.set_pov(pov_basis)

# -----------------------------------------------------------------------------
# Mouse Handling
# -----------------------------------------------------------------------------

func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_is_mouse_captured = true


func _release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_is_mouse_captured = false

# -----------------------------------------------------------------------------
# HUD Integration
# -----------------------------------------------------------------------------

func _update_hud() -> void:
	var fbw_info := _fbw.get_debug_info() if _fbw else {}

	var hud_data := {
		"speed": linear_velocity.length(),
		"target_speed": _fbw.target_speed if _fbw else 0.0,
		"velocity": linear_velocity,
		"local_velocity": global_transform.basis.inverse() * linear_velocity,
		"g_force": 0.0,  # TODO: Calculate from acceleration
		"is_maneuvering": fbw_info.get("is_maneuvering", false),
		"pov_forward": fbw_info.get("pov_forward", Vector3.FORWARD),
		"ship_forward": fbw_info.get("ship_forward", Vector3.FORWARD),
	}
	Events.hud_update_requested.emit(hud_data)

# -----------------------------------------------------------------------------
# Settings
# -----------------------------------------------------------------------------

func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	if category == "gameplay":
		match key:
			"mouse_sensitivity":
				mouse_sensitivity = value * 0.15
