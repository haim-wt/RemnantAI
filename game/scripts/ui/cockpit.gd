## 2D cockpit HUD overlay - always visible on screen.
class_name Cockpit
extends CanvasLayer

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("References")
## The ship this cockpit belongs to (for getting FBW data)
@export var target_ship: RigidBody3D

@export_group("Colors")
## Primary display color (cyan/blue)
@export var display_color: Color = Color(0.2, 0.9, 1.0)

## Warning color
@export var warning_color: Color = Color(1.0, 0.8, 0.2)

## Critical color
@export var critical_color: Color = Color(1.0, 0.3, 0.2)

## On-target color
@export var on_target_color: Color = Color(0.2, 1.0, 0.4)

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _current_data: Dictionary = {}
var _is_first_person: bool = false

# Display elements (2D Labels)
var _speed_display: Label
var _target_speed_display: Label
var _status_display: Label

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	Events.hud_update_requested.connect(_on_hud_update_requested)
	Events.camera_mode_changed.connect(_on_camera_mode_changed)
	_build_cockpit()
	# Start hidden (third person is default)
	visible = false


func _process(_delta: float) -> void:
	_update_displays()

# -----------------------------------------------------------------------------
# Cockpit Construction
# -----------------------------------------------------------------------------

func _build_cockpit() -> void:
	# Create a Control node to hold 2D HUD elements
	var hud_container := Control.new()
	hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hud_container)

	# Create bottom panel for dashboard
	var bottom_panel := Panel.new()
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -80
	bottom_panel.offset_bottom = 0
	bottom_panel.offset_left = 100
	bottom_panel.offset_right = -100

	# Style the panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	panel_style.border_color = Color(0.2, 0.3, 0.4)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	bottom_panel.add_theme_stylebox_override("panel", panel_style)
	hud_container.add_child(bottom_panel)

	# Create HBoxContainer for layout
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 20
	hbox.offset_right = -20
	hbox.offset_top = 10
	hbox.offset_bottom = -10
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 80)
	bottom_panel.add_child(hbox)

	# Speed display (left)
	var speed_container := VBoxContainer.new()
	speed_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(speed_container)

	_speed_display = Label.new()
	_speed_display.text = "000"
	_speed_display.add_theme_font_size_override("font_size", 48)
	_speed_display.add_theme_color_override("font_color", display_color)
	_speed_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_container.add_child(_speed_display)

	var speed_label := Label.new()
	speed_label.text = "M/S"
	speed_label.add_theme_font_size_override("font_size", 14)
	speed_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_container.add_child(speed_label)

	# Target speed display (center)
	var target_container := VBoxContainer.new()
	target_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(target_container)

	_target_speed_display = Label.new()
	_target_speed_display.text = "TGT 000"
	_target_speed_display.add_theme_font_size_override("font_size", 32)
	_target_speed_display.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9))
	_target_speed_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_container.add_child(_target_speed_display)

	var target_label := Label.new()
	target_label.text = "TARGET"
	target_label.add_theme_font_size_override("font_size", 12)
	target_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_container.add_child(target_label)

	# Status display (right)
	var status_container := VBoxContainer.new()
	status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(status_container)

	_status_display = Label.new()
	_status_display.text = "LOCK"
	_status_display.add_theme_font_size_override("font_size", 32)
	_status_display.add_theme_color_override("font_color", on_target_color)
	_status_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(_status_display)

	var status_label := Label.new()
	status_label.text = "STATUS"
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_container.add_child(status_label)

# -----------------------------------------------------------------------------
# Display Updates
# -----------------------------------------------------------------------------

func _on_hud_update_requested(data: Dictionary) -> void:
	_current_data = data


func _on_camera_mode_changed(mode: int) -> void:
	# 0 = THIRD_PERSON, 1 = FIRST_PERSON
	_is_first_person = (mode == 1)
	visible = _is_first_person


func _update_displays() -> void:
	if _current_data.is_empty():
		return

	# Update speed
	var speed: float = _current_data.get("speed", 0.0)
	_speed_display.text = "%03d" % int(speed)

	if speed > 250:
		_speed_display.add_theme_color_override("font_color", critical_color)
	elif speed > 150:
		_speed_display.add_theme_color_override("font_color", warning_color)
	else:
		_speed_display.add_theme_color_override("font_color", display_color)

	# Update target speed
	var target_speed: float = _current_data.get("target_speed", 0.0)
	_target_speed_display.text = "TGT %03d" % int(target_speed)

	# Update status
	var is_maneuvering: bool = _current_data.get("is_maneuvering", false)
	if is_maneuvering:
		_status_display.text = "MNVR"
		_status_display.add_theme_color_override("font_color", warning_color)
	else:
		_status_display.text = "LOCK"
		_status_display.add_theme_color_override("font_color", on_target_color)
