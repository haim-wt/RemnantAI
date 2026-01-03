## Base class for game arenas (racing tracks and combat zones).
## Handles spawn points, checkpoints, boundaries, and arena-specific logic.
class_name ArenaBase
extends Node3D

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------

signal arena_ready
signal boundary_violated(ship: Node3D)

# -----------------------------------------------------------------------------
# Exports
# -----------------------------------------------------------------------------

@export_group("Arena Info")
## Display name of this arena
@export var arena_name: String = "Unnamed Arena"

## Brief description
@export var description: String = ""

## Arena type (racing, combat, training)
@export_enum("racing", "combat", "training", "freeplay") var arena_type: String = "racing"

@export_group("Dimensions")
## Approximate arena radius in meters (for boundary checks)
@export var arena_radius: float = 25000.0

## Soft boundary distance (warning zone)
@export var warning_boundary: float = 20000.0

@export_group("Racing")
## Number of laps for racing mode
@export var lap_count: int = 3

@export_group("Node Paths")
## Container for spawn point markers
@export var spawn_points_path: NodePath

## Container for checkpoint markers
@export var checkpoints_path: NodePath

## Container for asteroid meshes
@export var asteroids_path: NodePath

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var spawn_points: Array[Marker3D] = []
var checkpoints: Array[Area3D] = []
var _is_initialized: bool = false

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	_initialize_arena()


func _initialize_arena() -> void:
	if _is_initialized:
		return

	_gather_spawn_points()
	_gather_checkpoints()
	_setup_checkpoints()

	_is_initialized = true
	arena_ready.emit()


func _gather_spawn_points() -> void:
	spawn_points.clear()

	if spawn_points_path.is_empty():
		push_warning("Arena: No spawn points path configured")
		return

	var container := get_node_or_null(spawn_points_path)
	if not container:
		return

	for child in container.get_children():
		if child is Marker3D:
			spawn_points.append(child)


func _gather_checkpoints() -> void:
	checkpoints.clear()

	if checkpoints_path.is_empty():
		return

	var container := get_node_or_null(checkpoints_path)
	if not container:
		return

	for child in container.get_children():
		if child is Area3D:
			checkpoints.append(child)


func _setup_checkpoints() -> void:
	for i in checkpoints.size():
		var checkpoint := checkpoints[i]
		# Store checkpoint index in metadata
		checkpoint.set_meta("checkpoint_id", i)

		# Connect signal if not already connected
		if not checkpoint.body_entered.is_connected(_on_checkpoint_entered):
			checkpoint.body_entered.connect(_on_checkpoint_entered.bind(i))

# -----------------------------------------------------------------------------
# Spawn Management
# -----------------------------------------------------------------------------

## Get a spawn point by index
func get_spawn_point(index: int) -> Transform3D:
	if spawn_points.is_empty():
		push_warning("Arena: No spawn points available")
		return Transform3D.IDENTITY

	index = index % spawn_points.size()
	return spawn_points[index].global_transform


## Get a random spawn point
func get_random_spawn_point() -> Transform3D:
	if spawn_points.is_empty():
		return Transform3D.IDENTITY

	return spawn_points.pick_random().global_transform


## Get all spawn points
func get_all_spawn_points() -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	for point in spawn_points:
		transforms.append(point.global_transform)
	return transforms

# -----------------------------------------------------------------------------
# Checkpoints
# -----------------------------------------------------------------------------

## Get checkpoint count
func get_checkpoint_count() -> int:
	return checkpoints.size()


## Get checkpoint by index
func get_checkpoint(index: int) -> Area3D:
	if index < 0 or index >= checkpoints.size():
		return null
	return checkpoints[index]


func _on_checkpoint_entered(body: Node3D, checkpoint_id: int) -> void:
	if body is ShipBase:
		Events.checkpoint_crossed.emit(body, checkpoint_id)

# -----------------------------------------------------------------------------
# Boundary Checking
# -----------------------------------------------------------------------------

## Check if a position is within arena bounds
func is_within_bounds(position: Vector3) -> bool:
	return position.length() < arena_radius


## Check if a position is in the warning zone
func is_in_warning_zone(position: Vector3) -> bool:
	var distance := position.length()
	return distance > warning_boundary and distance < arena_radius


## Get distance to boundary (negative if outside)
func get_boundary_distance(position: Vector3) -> float:
	return arena_radius - position.length()

# -----------------------------------------------------------------------------
# Utility
# -----------------------------------------------------------------------------

## Get arena info as dictionary
func get_arena_info() -> Dictionary:
	return {
		"name": arena_name,
		"description": description,
		"type": arena_type,
		"radius": arena_radius,
		"spawn_count": spawn_points.size(),
		"checkpoint_count": checkpoints.size(),
		"lap_count": lap_count,
	}
