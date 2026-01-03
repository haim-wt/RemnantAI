## Player-controlled ship with input handling and camera integration.
class_name PlayerShip
extends ShipBase

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Camera")
## Path to the camera rig node
@export var camera_rig_path: NodePath

@export_group("Input")
## Mouse sensitivity for rotation
@export var mouse_sensitivity: float = 0.002

## Whether to use mouse for rotation (vs keyboard only)
@export var use_mouse_rotation: bool = true

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _camera_rig: Node3D
var _mouse_delta: Vector2 = Vector2.ZERO
var _is_mouse_captured: bool = false

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	super._ready()

	if not camera_rig_path.is_empty():
		_camera_rig = get_node(camera_rig_path)

	# Capture mouse for flight control
	_capture_mouse()

	# Load sensitivity from settings
	mouse_sensitivity = Settings.get_value("gameplay", "mouse_sensitivity") * 0.002

	# Connect to settings changes
	Events.setting_changed.connect(_on_setting_changed)


func _exit_tree() -> void:
	_release_mouse()


func _input(event: InputEvent) -> void:
	# Handle mouse capture toggle
	if event.is_action_pressed("pause"):
		if _is_mouse_captured:
			_release_mouse()
		else:
			_capture_mouse()
		return

	# Capture mouse rotation
	if event is InputEventMouseMotion and _is_mouse_captured and use_mouse_rotation:
		_mouse_delta += event.relative


func _physics_process(delta: float) -> void:
	_process_input()
	super._physics_process(delta)
	_update_hud()

# -----------------------------------------------------------------------------
# Input Processing
# -----------------------------------------------------------------------------

func _process_input() -> void:
	# Thrust input
	var thrust := Vector3.ZERO
	thrust.z -= Input.get_action_strength("thrust_forward")
	thrust.z += Input.get_action_strength("thrust_backward")
	thrust.x += Input.get_action_strength("thrust_right")
	thrust.x -= Input.get_action_strength("thrust_left")
	thrust.y += Input.get_action_strength("thrust_up")
	thrust.y -= Input.get_action_strength("thrust_down")
	set_thrust_input(thrust)

	# Rotation input from mouse
	var rot := Vector3.ZERO
	if use_mouse_rotation and _is_mouse_captured:
		var invert_y := -1.0 if Settings.get_value("gameplay", "invert_y") else 1.0
		rot.x = _mouse_delta.y * mouse_sensitivity * invert_y * 60.0  # Pitch
		rot.y = _mouse_delta.x * mouse_sensitivity * 60.0             # Yaw
		_mouse_delta = Vector2.ZERO

	# Roll from keyboard (if implemented)
	# rot.z = Input.get_axis("roll_left", "roll_right")

	set_rotation_input(rot)

	# Boost
	set_boosting(Input.is_action_pressed("boost"))

	# Flight assist toggle
	if Input.is_action_just_pressed("toggle_assist"):
		cycle_assist_level()

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
	var hud_data := {
		"speed": get_speed(),
		"velocity": linear_velocity,
		"local_velocity": get_local_velocity(),
		"g_force": get_g_force(),
		"boost_fuel": boost_fuel,
		"boost_capacity": boost_capacity,
		"assist_level": assist_level,
		"is_boosting": is_boosting,
		"rotation": global_rotation_degrees,
	}
	Events.hud_update_requested.emit(hud_data)

# -----------------------------------------------------------------------------
# Settings
# -----------------------------------------------------------------------------

func _on_setting_changed(category: String, key: String, value: Variant) -> void:
	if category == "gameplay":
		match key:
			"mouse_sensitivity":
				mouse_sensitivity = value * 0.002
