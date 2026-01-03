## Manages global game state and session data.
## Central authority for match state, player data, and progression.
class_name GameStateManager
extends Node

# -----------------------------------------------------------------------------
# Enums
# -----------------------------------------------------------------------------

enum GameMode {
	NONE,
	MENU,
	RACING,
	COMBAT,
	TRAINING,
	FREEPLAY
}

enum MatchPhase {
	NONE,
	LOBBY,
	COUNTDOWN,
	ACTIVE,
	FINISHED,
	POST_MATCH
}

# -----------------------------------------------------------------------------
# State Properties
# -----------------------------------------------------------------------------

## Current game mode
var current_mode: GameMode = GameMode.MENU

## Current match phase
var match_phase: MatchPhase = MatchPhase.NONE

## Is this a multiplayer session?
var is_multiplayer: bool = false

## Local player's ID (1 for singleplayer, assigned by server in multiplayer)
var local_player_id: int = 1

## All players in current session: { player_id: PlayerData }
var players: Dictionary = {}

## Current match data
var match_data: Dictionary = {}

## Match timer (seconds elapsed)
var match_time: float = 0.0

## Is the game currently paused?
var is_paused: bool = false:
	set(value):
		if is_paused != value:
			is_paused = value
			get_tree().paused = value
			Events.pause_toggled.emit(value)

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Run even when paused


func _process(delta: float) -> void:
	if match_phase == MatchPhase.ACTIVE and not is_paused:
		match_time += delta

# -----------------------------------------------------------------------------
# Session Management
# -----------------------------------------------------------------------------

## Start a new match with the given configuration
func start_match(mode: GameMode, config: Dictionary = {}) -> void:
	current_mode = mode
	match_phase = MatchPhase.COUNTDOWN
	match_time = 0.0
	match_data = config.duplicate()

	Events.match_started.emit(match_data)

	# TODO: Implement countdown timer, then transition to ACTIVE


## Begin the active phase of the match (after countdown)
func begin_active_phase() -> void:
	match_phase = MatchPhase.ACTIVE


## End the current match
func end_match(results: Dictionary = {}) -> void:
	match_phase = MatchPhase.FINISHED
	Events.match_ended.emit(results)


## Return to menu state
func return_to_menu() -> void:
	current_mode = GameMode.MENU
	match_phase = MatchPhase.NONE
	match_data.clear()
	players.clear()
	is_paused = false

	Events.return_to_menu_requested.emit()

# -----------------------------------------------------------------------------
# Player Management
# -----------------------------------------------------------------------------

## Register a player in the current session
func register_player(player_id: int, data: Dictionary) -> void:
	players[player_id] = data
	Events.player_joined.emit(player_id, data)


## Remove a player from the current session
func unregister_player(player_id: int) -> void:
	if players.has(player_id):
		players.erase(player_id)
		Events.player_left.emit(player_id)


## Get data for a specific player
func get_player_data(player_id: int) -> Dictionary:
	return players.get(player_id, {})


## Get the local player's data
func get_local_player_data() -> Dictionary:
	return get_player_data(local_player_id)

# -----------------------------------------------------------------------------
# State Queries
# -----------------------------------------------------------------------------

## Check if we're in an active match
func is_in_match() -> bool:
	return match_phase in [MatchPhase.COUNTDOWN, MatchPhase.ACTIVE]


## Check if the match is actively running (not paused, not in countdown)
func is_match_active() -> bool:
	return match_phase == MatchPhase.ACTIVE and not is_paused


## Get formatted match time string (MM:SS.mmm)
func get_match_time_string() -> String:
	var minutes := int(match_time / 60.0)
	var seconds := int(fmod(match_time, 60.0))
	var millis := int(fmod(match_time * 1000.0, 1000.0))
	return "%02d:%02d.%03d" % [minutes, seconds, millis]
