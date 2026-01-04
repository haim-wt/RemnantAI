## Main entry point for the game.
## Handles initial setup and scene orchestration.
extends Node3D

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
	print("Setting up flight test scene...")

	_setup_environment()
	_setup_arena()
	_setup_player_ship()
	_setup_camera()
	_setup_hud()
	_setup_debug_visualization()

	print("Flight test scene ready!")
	print("Controls: Mouse - Steer, W/S - Throttle Up/Down, Q/E - Roll")
	print("Shift - Boost, C - Toggle Camera, ESC - Pause")


func _setup_environment() -> void:
	# Create environment for space rendering
	var environment_node := WorldEnvironment.new()
	var env := Environment.new()

	# Space-like settings with better ambient lighting
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)  # Very dark blue instead of pure black
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.15, 0.15, 0.2)  # Stronger ambient to soften shadows
	env.ambient_light_energy = 0.5

	# Add subtle fog for depth perception
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.1, 0.15)
	env.fog_density = 0.0001  # Very subtle
	env.fog_aerial_perspective = 0.3

	environment_node.environment = env
	add_child(environment_node)

	# Add directional light (sun)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.95, 0.9)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.0
	sun.rotation_degrees = Vector3(-45, 45, 0)
	add_child(sun)

	# Add secondary fill light to reduce harsh shadows
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_energy = 0.3
	fill_light.light_color = Color(0.6, 0.7, 1.0)  # Cool blue fill
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(30, -135, 0)  # Opposite side from sun
	add_child(fill_light)


func _setup_arena() -> void:
	var arena := TestArenaGenerator.new()
	arena.name = "Arena"
	arena.arena_size = 2000.0  # 2km radius, 4km diameter - more room to fly
	arena.asteroid_count = 50  # More asteroids
	arena.min_asteroid_size = 10.0  # Small rocks for variety
	arena.max_asteroid_size = 200.0  # Some large ones to fly around
	arena.min_spacing = 100.0
	add_child(arena)


func _setup_player_ship() -> void:
	var player_ship := PlayerShip.new()
	player_ship.name = "PlayerShip"
	player_ship.mass = 5000.0  # 5 tons

	# Start near asteroids
	player_ship.global_position = Vector3(0, 0, -100)

	# Create ship visual
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(3, 1.5, 6)
	mesh_instance.mesh = box_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.3, 0.6)
	material.metallic = 0.8
	material.roughness = 0.3
	mesh_instance.material_override = material
	player_ship.add_child(mesh_instance)

	# Create collision shape
	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(3, 1.5, 6)
	collision_shape.shape = box_shape
	player_ship.add_child(collision_shape)

	player_ship.collision_layer = 1
	player_ship.collision_mask = 2 | 4

	add_child(player_ship)


func _setup_camera() -> void:
	var player_ship := get_node_or_null("PlayerShip")
	if not player_ship:
		return

	var camera_rig := ShipCameraRig.new()
	camera_rig.name = "CameraRig"
	camera_rig.target_ship = player_ship
	camera_rig.follow_distance = 20.0
	camera_rig.follow_height = 8.0
	add_child(camera_rig)

	player_ship.camera_rig_path = camera_rig.get_path()
	player_ship._camera_rig = camera_rig


func _setup_hud() -> void:
	var player_ship := get_node_or_null("PlayerShip")
	if not player_ship:
		return

	# Create 2D cockpit HUD overlay
	var CockpitScript: GDScript = load("res://scripts/ui/cockpit.gd")
	var cockpit: CanvasLayer = CockpitScript.new()
	cockpit.name = "Cockpit"
	cockpit.set("target_ship", player_ship)
	add_child(cockpit)

	# Also keep a minimal 2D overlay for instructions
	var hud_root := CanvasLayer.new()
	hud_root.name = "HUD"

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	hud_root.add_child(margin)

	var instructions := Label.new()
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.text = "Mouse - Steer | W/S - Speed | Q/E - Roll | Shift - Boost | C - Camera"
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margin.add_child(instructions)

	add_child(hud_root)


func _setup_debug_visualization() -> void:
	var player_ship := get_node_or_null("PlayerShip")
	if not player_ship:
		return

	var debug_visualizer := ShipDebugVisualizer.new()
	debug_visualizer.name = "DebugVisualizer"
	debug_visualizer.target_ship = player_ship
	add_child(debug_visualizer)


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
