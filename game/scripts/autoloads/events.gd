## Global event bus for decoupled communication between systems.
## Use signals here to avoid tight coupling between game components.
class_name EventBus
extends Node

# -----------------------------------------------------------------------------
# Game Flow Events
# -----------------------------------------------------------------------------

## Emitted when a match starts
signal match_started(match_data: Dictionary)

## Emitted when a match ends
signal match_ended(results: Dictionary)

## Emitted when the game is paused/unpaused
signal pause_toggled(is_paused: bool)

## Emitted when returning to main menu
signal return_to_menu_requested

# -----------------------------------------------------------------------------
# Ship Events
# -----------------------------------------------------------------------------

## Emitted when a ship spawns into the game
signal ship_spawned(ship: Node3D)

## Emitted when a ship is destroyed/disabled
signal ship_destroyed(ship: Node3D, destroyer: Node3D)

## Emitted when a ship takes damage
signal ship_damaged(ship: Node3D, damage: float, source: Node3D)

## Emitted when a ship's velocity changes significantly
signal ship_velocity_changed(ship: Node3D, velocity: Vector3)

## Emitted when flight assist mode changes
signal flight_assist_changed(ship: Node3D, assist_level: int)

## Emitted when a ship crosses a checkpoint (racing)
signal checkpoint_crossed(ship: Node3D, checkpoint_id: int)

## Emitted when a ship finishes a lap
signal lap_completed(ship: Node3D, lap_number: int, lap_time: float)

# -----------------------------------------------------------------------------
# Combat Events
# -----------------------------------------------------------------------------

## Emitted when a weapon is fired
signal weapon_fired(ship: Node3D, weapon_type: String)

## Emitted when a projectile hits something
signal projectile_hit(projectile: Node3D, target: Node3D, position: Vector3)

## Emitted when a ship is incapacitated (combat mode)
signal ship_incapacitated(ship: Node3D)

# -----------------------------------------------------------------------------
# UI Events
# -----------------------------------------------------------------------------

## Emitted to show a notification to the player
signal notification_requested(message: String, duration: float)

## Emitted when HUD needs to update
signal hud_update_requested(data: Dictionary)

## Emitted to show/hide loading screen
signal loading_screen_toggled(visible: bool, message: String)

## Emitted when camera mode changes
signal camera_mode_changed(mode: int)

# -----------------------------------------------------------------------------
# Network Events
# -----------------------------------------------------------------------------

## Emitted when connected to a server
signal server_connected

## Emitted when disconnected from a server
signal server_disconnected(reason: String)

## Emitted when a player joins
signal player_joined(player_id: int, player_data: Dictionary)

## Emitted when a player leaves
signal player_left(player_id: int)

# -----------------------------------------------------------------------------
# Settings Events
# -----------------------------------------------------------------------------

## Emitted when any setting changes
signal setting_changed(category: String, key: String, value: Variant)

## Emitted when settings are saved
signal settings_saved

## Emitted when settings are loaded
signal settings_loaded
