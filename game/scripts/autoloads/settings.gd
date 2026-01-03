## Manages user settings with persistence.
## Handles graphics, audio, controls, and gameplay preferences.
class_name SettingsManager
extends Node

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SETTINGS := {
	"graphics": {
		"fullscreen": true,
		"vsync": true,
		"msaa": 2,  # 0=Off, 1=2x, 2=4x, 3=8x
		"render_scale": 1.0,
		"fov": 90.0,
		"max_fps": 0,  # 0 = unlimited
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ui_volume": 0.7,
		"voice_volume": 1.0,
	},
	"gameplay": {
		"flight_assist_default": 2,  # 0=Off, 1=Low, 2=Medium, 3=High
		"invert_y": false,
		"mouse_sensitivity": 1.0,
		"controller_sensitivity": 1.0,
		"show_velocity_vector": true,
		"show_trajectory_prediction": true,
		"units": "metric",  # "metric" or "imperial"
	},
	"accessibility": {
		"colorblind_mode": 0,  # 0=Off, 1=Deuteranopia, 2=Protanopia, 3=Tritanopia
		"screen_shake": 1.0,
		"motion_blur": true,
		"subtitles": true,
	}
}

# -----------------------------------------------------------------------------
# Properties
# -----------------------------------------------------------------------------

## Current settings (mirrors DEFAULT_SETTINGS structure)
var _settings: Dictionary = {}

## Config file handler
var _config := ConfigFile.new()

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------

func _ready() -> void:
	_load_settings()
	_apply_all_settings()


## Access settings via Settings.get_value("graphics", "fullscreen")
func get_value(category: String, key: String) -> Variant:
	if _settings.has(category) and _settings[category].has(key):
		return _settings[category][key]

	# Return default if not found
	if DEFAULT_SETTINGS.has(category) and DEFAULT_SETTINGS[category].has(key):
		return DEFAULT_SETTINGS[category][key]

	push_warning("Settings: Unknown setting %s/%s" % [category, key])
	return null


## Set a setting value
func set_value(category: String, key: String, value: Variant) -> void:
	if not _settings.has(category):
		_settings[category] = {}

	var old_value = _settings[category].get(key)
	_settings[category][key] = value

	if old_value != value:
		_apply_setting(category, key, value)
		Events.setting_changed.emit(category, key, value)

# -----------------------------------------------------------------------------
# Persistence
# -----------------------------------------------------------------------------

## Load settings from disk
func _load_settings() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)

	if _config.load(SETTINGS_PATH) == OK:
		for category in DEFAULT_SETTINGS.keys():
			for key in DEFAULT_SETTINGS[category].keys():
				if _config.has_section_key(category, key):
					_settings[category][key] = _config.get_value(category, key)

		Events.settings_loaded.emit()


## Save settings to disk
func save_settings() -> void:
	for category in _settings.keys():
		for key in _settings[category].keys():
			_config.set_value(category, key, _settings[category][key])

	var err := _config.save(SETTINGS_PATH)
	if err == OK:
		Events.settings_saved.emit()
	else:
		push_error("Settings: Failed to save settings: %s" % error_string(err))


## Reset all settings to defaults
func reset_to_defaults() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	_apply_all_settings()
	save_settings()


## Reset a category to defaults
func reset_category(category: String) -> void:
	if DEFAULT_SETTINGS.has(category):
		_settings[category] = DEFAULT_SETTINGS[category].duplicate(true)
		_apply_category(category)
		save_settings()

# -----------------------------------------------------------------------------
# Application
# -----------------------------------------------------------------------------

## Apply all settings
func _apply_all_settings() -> void:
	for category in _settings.keys():
		_apply_category(category)


## Apply all settings in a category
func _apply_category(category: String) -> void:
	if not _settings.has(category):
		return

	for key in _settings[category].keys():
		_apply_setting(category, key, _settings[category][key])


## Apply a single setting
func _apply_setting(category: String, key: String, value: Variant) -> void:
	match category:
		"graphics":
			_apply_graphics_setting(key, value)
		"audio":
			_apply_audio_setting(key, value)
		# Gameplay/accessibility settings are read on-demand


func _apply_graphics_setting(key: String, value: Variant) -> void:
	match key:
		"fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
			)
		"max_fps":
			Engine.max_fps = value
		"fov":
			# Applied by cameras when they read the setting
			pass
		"msaa":
			var viewport := get_viewport()
			if viewport:
				viewport.msaa_3d = value as Viewport.MSAA
		"render_scale":
			var viewport := get_viewport()
			if viewport:
				viewport.scaling_3d_scale = value


func _apply_audio_setting(key: String, value: Variant) -> void:
	var bus_name: String
	match key:
		"master_volume":
			bus_name = "Master"
		"music_volume":
			bus_name = "Music"
		"sfx_volume":
			bus_name = "SFX"
		"ui_volume":
			bus_name = "UI"
		"voice_volume":
			bus_name = "Voice"
		_:
			return

	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
