## Manages audio playback with pooling and spatial audio support.
## Provides convenient API for playing sounds without managing AudioStreamPlayer nodes.
class_name AudioManagerNode
extends Node

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

const POOL_SIZE_2D := 16
const POOL_SIZE_3D := 32

# -----------------------------------------------------------------------------
# Audio Pools
# -----------------------------------------------------------------------------

var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _music_player: AudioStreamPlayer

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	_init_pools()
	_init_music_player()


func _init_pools() -> void:
	# 2D audio pool for UI and non-spatial sounds
	for i in POOL_SIZE_2D:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool_2d.append(player)

	# 3D audio pool for spatial sounds
	for i in POOL_SIZE_3D:
		var player := AudioStreamPlayer3D.new()
		player.bus = "SFX"
		player.max_distance = 1000.0
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(player)
		_pool_3d.append(player)


func _init_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

# -----------------------------------------------------------------------------
# 2D Audio (Non-Spatial)
# -----------------------------------------------------------------------------

## Play a 2D sound effect (UI, ambient, etc.)
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var player := _get_available_2d_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch
		player.play()


## Play a UI sound
func play_ui(stream: AudioStream, volume_db: float = 0.0) -> void:
	var player := _get_available_2d_player()
	if player:
		player.bus = "UI"
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = 1.0
		player.play()


func _get_available_2d_player() -> AudioStreamPlayer:
	for player in _pool_2d:
		if not player.playing:
			player.bus = "SFX"  # Reset bus
			return player

	# All players busy, steal the first one
	push_warning("AudioManager: 2D pool exhausted, reusing player")
	return _pool_2d[0]

# -----------------------------------------------------------------------------
# 3D Audio (Spatial)
# -----------------------------------------------------------------------------

## Play a 3D sound at a position
func play_sfx_3d(
	stream: AudioStream,
	position: Vector3,
	volume_db: float = 0.0,
	pitch: float = 1.0,
	max_distance: float = 1000.0
) -> void:
	var player := _get_available_3d_player()
	if player:
		player.stream = stream
		player.global_position = position
		player.volume_db = volume_db
		player.pitch_scale = pitch
		player.max_distance = max_distance
		player.play()


## Play a 3D sound attached to a node (follows the node)
func play_sfx_attached(
	stream: AudioStream,
	target: Node3D,
	volume_db: float = 0.0,
	pitch: float = 1.0
) -> void:
	# For attached sounds, we create a temporary player as a child
	var player := AudioStreamPlayer3D.new()
	player.bus = "SFX"
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.max_distance = 1000.0

	target.add_child(player)
	player.play()

	# Auto-cleanup when finished
	player.finished.connect(player.queue_free)


func _get_available_3d_player() -> AudioStreamPlayer3D:
	for player in _pool_3d:
		if not player.playing:
			return player

	push_warning("AudioManager: 3D pool exhausted, reusing player")
	return _pool_3d[0]

# -----------------------------------------------------------------------------
# Music
# -----------------------------------------------------------------------------

## Play background music (crossfades if something is already playing)
func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if _music_player.playing and fade_duration > 0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_start_new_music.bind(stream, fade_duration))
	else:
		_start_new_music(stream, fade_duration)


func _start_new_music(stream: AudioStream, fade_duration: float) -> void:
	_music_player.stream = stream
	_music_player.volume_db = -80.0 if fade_duration > 0 else 0.0
	_music_player.play()

	if fade_duration > 0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", 0.0, fade_duration)


## Stop music with optional fade out
func stop_music(fade_duration: float = 1.0) -> void:
	if fade_duration > 0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()


## Check if music is playing
func is_music_playing() -> bool:
	return _music_player.playing
