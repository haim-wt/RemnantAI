## Main entry point for the game.
## Handles initial setup and scene orchestration.
extends Node

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	_initialize_game()
	_setup_debug()

	# Start at main menu or load into test scene
	if OS.is_debug_build() and OS.has_feature("editor"):
		_load_debug_scene()
	else:
		_load_main_menu()


func _initialize_game() -> void:
	# Ensure settings are applied
	print("Remnant v%s initializing..." % ProjectSettings.get_setting("application/config/version", "0.1.0"))

	# Set window title
	get_window().title = "Remnant"


func _setup_debug() -> void:
	if not OS.is_debug_build():
		return

	# Initialize debug drawing
	var debug_node := Node3D.new()
	debug_node.name = "DebugDraw"
	add_child(debug_node)
	DebugUtils.initialize(debug_node)


func _load_main_menu() -> void:
	# TODO: Implement main menu scene
	print("Main menu not yet implemented")
	_load_debug_scene()


func _load_debug_scene() -> void:
	# Load a test/debug scene for development
	print("Loading debug scene...")

	# Create a simple test environment
	_create_test_environment()


func _create_test_environment() -> void:
	# Add a camera
	var camera := Camera3D.new()
	camera.name = "DebugCamera"
	camera.position = Vector3(0, 5, 10)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	add_child(camera)

	# Add some visual reference points
	var origin_marker := _create_debug_marker(Vector3.ZERO, Color.WHITE)
	add_child(origin_marker)

	# Add axis indicators
	var x_marker := _create_debug_marker(Vector3(10, 0, 0), Color.RED)
	var y_marker := _create_debug_marker(Vector3(0, 10, 0), Color.GREEN)
	var z_marker := _create_debug_marker(Vector3(0, 0, 10), Color.BLUE)
	add_child(x_marker)
	add_child(y_marker)
	add_child(z_marker)

	print("Test environment created. Use this for development.")
	print("Press ESC to release mouse, ESC again to capture.")


func _create_debug_marker(pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.5

	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos

	return instance


# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	# Global shortcuts
	if event.is_action_pressed("ui_cancel"):
		if GameState.is_in_match():
			GameState.is_paused = not GameState.is_paused
