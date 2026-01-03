## Manages scene transitions with loading screens and fade effects.
## Provides async scene loading for smooth transitions.
class_name SceneManagerNode
extends Node

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------

signal scene_load_started(scene_path: String)
signal scene_load_progress(progress: float)
signal scene_load_completed(scene_path: String)
signal transition_completed

# -----------------------------------------------------------------------------
# Properties
# -----------------------------------------------------------------------------

var _current_scene: Node
var _loading_scene_path: String = ""
var _loader_status: ResourceLoader.ThreadLoadStatus

# Transition overlay
var _transition_overlay: ColorRect
var _is_transitioning: bool = false

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_current_scene = get_tree().current_scene
	_create_transition_overlay()


func _process(_delta: float) -> void:
	if _loading_scene_path.is_empty():
		return

	var progress: Array = []
	_loader_status = ResourceLoader.load_threaded_get_status(_loading_scene_path, progress)

	match _loader_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			scene_load_progress.emit(progress[0] if progress.size() > 0 else 0.0)

		ResourceLoader.THREAD_LOAD_LOADED:
			_on_scene_loaded()

		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("SceneManager: Failed to load scene: %s" % _loading_scene_path)
			_loading_scene_path = ""
			_end_transition()

# -----------------------------------------------------------------------------
# Scene Transitions
# -----------------------------------------------------------------------------

## Change to a new scene with optional transition
func change_scene(
	scene_path: String,
	transition_type: String = "fade",
	transition_duration: float = 0.5
) -> void:
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring request")
		return

	_is_transitioning = true
	Events.loading_screen_toggled.emit(true, "Loading...")
	scene_load_started.emit(scene_path)

	# Fade out
	await _transition_out(transition_type, transition_duration)

	# Start async loading
	var err := ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		push_error("SceneManager: Failed to start loading scene: %s" % scene_path)
		_end_transition()
		return

	_loading_scene_path = scene_path


## Change to a scene that's already loaded (PackedScene resource)
func change_scene_to_packed(
	packed_scene: PackedScene,
	transition_type: String = "fade",
	transition_duration: float = 0.5
) -> void:
	if _is_transitioning:
		push_warning("SceneManager: Already transitioning, ignoring request")
		return

	_is_transitioning = true

	await _transition_out(transition_type, transition_duration)

	_replace_scene(packed_scene.instantiate())

	await _transition_in(transition_type, transition_duration)

	_end_transition()


## Reload the current scene
func reload_current_scene(transition_duration: float = 0.3) -> void:
	var current_path := get_tree().current_scene.scene_file_path
	if not current_path.is_empty():
		change_scene(current_path, "fade", transition_duration)

# -----------------------------------------------------------------------------
# Internal
# -----------------------------------------------------------------------------

func _on_scene_loaded() -> void:
	var packed_scene: PackedScene = ResourceLoader.load_threaded_get(_loading_scene_path)
	_loading_scene_path = ""

	if packed_scene:
		_replace_scene(packed_scene.instantiate())
		scene_load_completed.emit(_loading_scene_path)

		await _transition_in("fade", 0.5)

	_end_transition()


func _replace_scene(new_scene: Node) -> void:
	if _current_scene:
		_current_scene.queue_free()

	_current_scene = new_scene
	get_tree().root.add_child(_current_scene)
	get_tree().current_scene = _current_scene


func _end_transition() -> void:
	_is_transitioning = false
	Events.loading_screen_toggled.emit(false, "")
	transition_completed.emit()

# -----------------------------------------------------------------------------
# Transition Effects
# -----------------------------------------------------------------------------

func _create_transition_overlay() -> void:
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color.BLACK
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.modulate.a = 0.0

	# Create a CanvasLayer to ensure overlay is always on top
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.add_child(_transition_overlay)
	add_child(layer)


func _transition_out(type: String, duration: float) -> void:
	match type:
		"fade":
			var tween := create_tween()
			tween.tween_property(_transition_overlay, "modulate:a", 1.0, duration)
			await tween.finished
		"instant":
			_transition_overlay.modulate.a = 1.0
		_:
			push_warning("SceneManager: Unknown transition type: %s" % type)
			_transition_overlay.modulate.a = 1.0


func _transition_in(type: String, duration: float) -> void:
	match type:
		"fade":
			var tween := create_tween()
			tween.tween_property(_transition_overlay, "modulate:a", 0.0, duration)
			await tween.finished
		"instant":
			_transition_overlay.modulate.a = 0.0
		_:
			_transition_overlay.modulate.a = 0.0


## Check if currently in a transition
func is_transitioning() -> bool:
	return _is_transitioning
