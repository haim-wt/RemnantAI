## Generates a simple test arena with placeholder asteroids.
## This is a temporary system until full SDF asteroid rendering is implemented.
@tool
class_name TestArenaGenerator
extends Node3D

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Arena Parameters")
## Size of the arena in meters (radius)
@export var arena_size: float = 5000.0

## Number of asteroids to generate
@export var asteroid_count: int = 10

## Minimum asteroid radius in meters
@export var min_asteroid_size: float = 50.0

## Maximum asteroid radius in meters
@export var max_asteroid_size: float = 300.0

## Minimum distance between asteroids
@export var min_spacing: float = 200.0

@export_group("Generation")
## Random seed for reproducible generation
@export var random_seed: int = 12345

## Generate arena in editor
@export var generate_in_editor: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			generate_arena()
		generate_in_editor = false

## Clear existing asteroids
@export var clear_arena: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_clear_asteroids()
		clear_arena = false

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _asteroids: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_arena()

# -----------------------------------------------------------------------------
# Generation
# -----------------------------------------------------------------------------

## Generate the test arena
func generate_arena() -> void:
	_clear_asteroids()

	_rng.seed = random_seed
	var positions: Array[Vector3] = []

	for i in asteroid_count:
		var attempts := 0
		var position := Vector3.ZERO
		var valid := false

		# Try to find a valid position with spacing
		while not valid and attempts < 100:
			position = _random_position_in_sphere(arena_size)

			# Check spacing from other asteroids
			valid = true
			for existing_pos in positions:
				if position.distance_to(existing_pos) < min_spacing:
					valid = false
					break

			attempts += 1

		if valid:
			positions.append(position)
			var size := _rng.randf_range(min_asteroid_size, max_asteroid_size)
			_create_placeholder_asteroid(position, size)

	print("Generated %d asteroids in test arena" % _asteroids.size())


func _create_placeholder_asteroid(position: Vector3, radius: float) -> void:
	# Create asteroid node
	var asteroid := StaticBody3D.new()
	asteroid.name = "Asteroid_%d" % (_asteroids.size() + 1)
	asteroid.global_position = position

	# Create visual mesh
	var mesh_instance := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8

	mesh_instance.mesh = sphere_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# Create simple material
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3 + _rng.randf() * 0.2, 0.25 + _rng.randf() * 0.15, 0.2 + _rng.randf() * 0.1)
	material.roughness = 0.9 + _rng.randf() * 0.1
	material.metallic = 0.1 + _rng.randf() * 0.1
	mesh_instance.material_override = material

	asteroid.add_child(mesh_instance)

	# Create collision shape
	var collision_shape := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = radius
	collision_shape.shape = sphere_shape
	asteroid.add_child(collision_shape)

	# Set physics layers
	asteroid.collision_layer = 2  # Layer 2: asteroids
	asteroid.collision_mask = 1 | 2 | 4  # Collide with ships, asteroids, projectiles

	# Add to scene
	add_child(asteroid)
	if Engine.is_editor_hint():
		asteroid.owner = get_tree().edited_scene_root

	_asteroids.append(asteroid)


func _clear_asteroids() -> void:
	for asteroid in _asteroids:
		if is_instance_valid(asteroid):
			asteroid.queue_free()
	_asteroids.clear()

	# Also clear any existing children that are asteroids
	for child in get_children():
		if child.name.begins_with("Asteroid_"):
			child.queue_free()


func _random_position_in_sphere(radius: float) -> Vector3:
	# Generate random point in sphere - asteroids can spawn anywhere including near center
	var pos := Vector3.ZERO

	# Use smaller min distance so asteroids can be close to player
	var min_distance := radius * 0.1

	while true:
		pos.x = _rng.randf_range(-radius, radius)
		pos.y = _rng.randf_range(-radius * 0.5, radius * 0.5)  # Less vertical spread
		pos.z = _rng.randf_range(-radius, radius)
		var length_sq := pos.length_squared()

		# Accept if within sphere
		if length_sq <= radius * radius and length_sq >= min_distance * min_distance:
			break

	return pos

# -----------------------------------------------------------------------------
# Public Interface
# -----------------------------------------------------------------------------

## Get all generated asteroids
func get_asteroids() -> Array[Node3D]:
	return _asteroids.duplicate()


## Get arena bounds
func get_arena_bounds() -> float:
	return arena_size
