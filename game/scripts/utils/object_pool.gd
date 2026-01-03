## Generic object pool for efficient instantiation of frequently used nodes.
## Use for projectiles, particles, debris, etc.
class_name ObjectPool
extends Node

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------

signal pool_exhausted
signal object_returned(obj: Node)

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

## Scene to instantiate for pool objects
var _scene: PackedScene

## Maximum pool size (0 = unlimited)
var _max_size: int = 0

## Whether to grow the pool when exhausted
var _auto_grow: bool = true

## Pre-warm count (objects created on initialization)
var _prewarm_count: int = 0

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------

var _available: Array[Node] = []
var _in_use: Array[Node] = []
var _total_created: int = 0

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

## Create a new object pool
## scene: The PackedScene to instantiate
## prewarm: Number of objects to create immediately
## max_size: Maximum pool size (0 = unlimited)
## auto_grow: Whether to create new objects when pool is empty
static func create(
	scene: PackedScene,
	prewarm: int = 0,
	max_size: int = 0,
	auto_grow: bool = true
) -> ObjectPool:
	var pool := ObjectPool.new()
	pool._scene = scene
	pool._max_size = max_size
	pool._auto_grow = auto_grow
	pool._prewarm_count = prewarm
	return pool


func _ready() -> void:
	# Pre-warm the pool
	for i in _prewarm_count:
		var obj := _create_object()
		if obj:
			_available.append(obj)

# -----------------------------------------------------------------------------
# Pool Operations
# -----------------------------------------------------------------------------

## Get an object from the pool
func acquire() -> Node:
	var obj: Node

	if _available.size() > 0:
		obj = _available.pop_back()
	elif _auto_grow and (_max_size == 0 or _total_created < _max_size):
		obj = _create_object()
	else:
		pool_exhausted.emit()
		return null

	if obj:
		_in_use.append(obj)
		_activate_object(obj)

	return obj


## Return an object to the pool
func release(obj: Node) -> void:
	if not obj:
		return

	var idx := _in_use.find(obj)
	if idx == -1:
		push_warning("ObjectPool: Tried to release object not from this pool")
		return

	_in_use.remove_at(idx)
	_deactivate_object(obj)
	_available.append(obj)

	object_returned.emit(obj)


## Release all objects back to the pool
func release_all() -> void:
	for obj in _in_use.duplicate():
		release(obj)

# -----------------------------------------------------------------------------
# Internal
# -----------------------------------------------------------------------------

func _create_object() -> Node:
	if not _scene:
		push_error("ObjectPool: No scene configured")
		return null

	var obj := _scene.instantiate()
	add_child(obj)
	_deactivate_object(obj)
	_total_created += 1

	return obj


func _activate_object(obj: Node) -> void:
	obj.process_mode = Node.PROCESS_MODE_INHERIT
	obj.visible = true if obj is Node3D or obj is Node2D else true

	# Call custom activation if available
	if obj.has_method("on_pool_acquire"):
		obj.call("on_pool_acquire")


func _deactivate_object(obj: Node) -> void:
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	if obj is Node3D:
		obj.visible = false
	elif obj is Node2D:
		obj.visible = false

	# Call custom deactivation if available
	if obj.has_method("on_pool_release"):
		obj.call("on_pool_release")

# -----------------------------------------------------------------------------
# Queries
# -----------------------------------------------------------------------------

## Get number of available objects
func get_available_count() -> int:
	return _available.size()


## Get number of objects currently in use
func get_in_use_count() -> int:
	return _in_use.size()


## Get total objects created
func get_total_count() -> int:
	return _total_created


## Check if pool has available objects
func has_available() -> bool:
	return _available.size() > 0 or (_auto_grow and (_max_size == 0 or _total_created < _max_size))

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

## Clear the entire pool
func clear() -> void:
	for obj in _available:
		obj.queue_free()
	for obj in _in_use:
		obj.queue_free()

	_available.clear()
	_in_use.clear()
	_total_created = 0


func _exit_tree() -> void:
	clear()
