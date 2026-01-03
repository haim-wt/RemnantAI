## Ship HUD displaying flight information and status.
## Receives updates via Events.hud_update_requested signal.
class_name ShipHUD
extends Control

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("References")
## Label for speed display
@export var speed_label: Label

## Label for velocity vector
@export var velocity_label: Label

## Label for assist level
@export var assist_label: Label

## Progress bar for boost fuel
@export var boost_bar: ProgressBar

## Label for G-force
@export var gforce_label: Label

## Panel for orientation indicator
@export var orientation_panel: Control

## Label for camera mode
@export var camera_mode_label: Label

@export_group("Visuals")
## Color for normal speed
@export var normal_color: Color = Color.WHITE

## Color for high speed warning
@export var warning_color: Color = Color.YELLOW

## Color for critical speed
@export var critical_color: Color = Color.RED

## Speed threshold for warning (m/s)
@export var warning_speed: float = 300.0

## Speed threshold for critical (m/s)
@export var critical_speed: float = 450.0

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _current_data: Dictionary = {}
var _velocity_history: Array[Vector3] = []
const VELOCITY_HISTORY_SIZE := 10

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	Events.hud_update_requested.connect(_on_hud_update_requested)
	Events.camera_mode_changed.connect(_on_camera_mode_changed)

	# Initial state
	_update_display()


func _process(_delta: float) -> void:
	# Could add animations or effects here
	pass

# -----------------------------------------------------------------------------
# Update Handling
# -----------------------------------------------------------------------------

func _on_hud_update_requested(data: Dictionary) -> void:
	_current_data = data
	_update_display()


func _on_camera_mode_changed(mode: int) -> void:
	if camera_mode_label:
		match mode:
			0:  # THIRD_PERSON
				camera_mode_label.text = "[C] Camera: Third Person"
			1:  # FIRST_PERSON
				camera_mode_label.text = "[C] Camera: First Person"

# -----------------------------------------------------------------------------
# Display Updates
# -----------------------------------------------------------------------------

func _update_display() -> void:
	if _current_data.is_empty():
		return

	_update_speed_display()
	_update_maneuver_display()
	_update_boost_display()
	_update_gforce_display()


func _update_speed_display() -> void:
	if not speed_label:
		return

	var speed: float = _current_data.get("speed", 0.0)
	var target_speed: float = _current_data.get("target_speed", 0.0)

	# Show current and target speed
	speed_label.text = "Speed: %d / %d m/s" % [int(speed), int(target_speed)]

	# Color based on speed
	if speed >= critical_speed:
		speed_label.modulate = critical_color
	elif speed >= warning_speed:
		speed_label.modulate = warning_color
	else:
		speed_label.modulate = normal_color


func _update_maneuver_display() -> void:
	# Show maneuvering status instead of old assist label
	if not assist_label:
		return

	var is_maneuvering: bool = _current_data.get("is_maneuvering", false)

	if is_maneuvering:
		assist_label.text = "MANEUVERING"
		assist_label.modulate = Color.YELLOW
	else:
		assist_label.text = "ON TARGET"
		assist_label.modulate = Color.GREEN

	# Update velocity label if present
	if velocity_label:
		var velocity: Vector3 = _current_data.get("velocity", Vector3.ZERO)
		var speed := velocity.length()
		velocity_label.text = "Velocity: %.1f m/s" % speed


func _update_boost_display() -> void:
	if not boost_bar:
		return

	# Show target speed as a progress bar (0 to max)
	var target_speed: float = _current_data.get("target_speed", 0.0)
	var max_speed: float = 200.0  # Should match PlayerShip.max_speed

	boost_bar.max_value = max_speed
	boost_bar.value = target_speed
	boost_bar.modulate = Color.CYAN


func _update_gforce_display() -> void:
	if not gforce_label:
		return

	var g_force: float = _current_data.get("g_force", 0.0)
	gforce_label.text = "G-Force: %.1fG" % g_force

	# Color based on G-force
	if g_force > 6.0:
		gforce_label.modulate = critical_color
	elif g_force > 4.0:
		gforce_label.modulate = warning_color
	else:
		gforce_label.modulate = normal_color

# -----------------------------------------------------------------------------
# Utility
# -----------------------------------------------------------------------------

## Show or hide the entire HUD
func set_visible_hud(visible: bool) -> void:
	visible = visible


## Reset HUD to default state
func reset() -> void:
	_current_data.clear()
	_velocity_history.clear()
	_update_display()
