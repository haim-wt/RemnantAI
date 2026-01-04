using Godot;
using Godot.Collections;

namespace Remnant.Autoloads;

/// <summary>
/// Manages user settings with persistence.
/// Handles graphics, audio, controls, and gameplay preferences.
/// </summary>
public partial class Settings : Node
{
    public static Settings Instance { get; private set; } = null!;

    private const string SettingsPath = "user://settings.cfg";

    private static readonly Dictionary DefaultSettings = new()
    {
        ["graphics"] = new Dictionary
        {
            ["fullscreen"] = true,
            ["vsync"] = true,
            ["msaa"] = 2,
            ["render_scale"] = 1.0f,
            ["fov"] = 90.0f,
            ["max_fps"] = 0
        },
        ["audio"] = new Dictionary
        {
            ["master_volume"] = 1.0f,
            ["music_volume"] = 0.8f,
            ["sfx_volume"] = 1.0f,
            ["ui_volume"] = 0.7f,
            ["voice_volume"] = 1.0f
        },
        ["gameplay"] = new Dictionary
        {
            ["flight_assist_default"] = 2,
            ["invert_y"] = false,
            ["mouse_sensitivity"] = 1.0f,
            ["controller_sensitivity"] = 1.0f,
            ["show_velocity_vector"] = true,
            ["show_trajectory_prediction"] = true,
            ["units"] = "metric"
        },
        ["accessibility"] = new Dictionary
        {
            ["colorblind_mode"] = 0,
            ["screen_shake"] = 1.0f,
            ["motion_blur"] = true,
            ["subtitles"] = true
        }
    };

    private Dictionary _settings = new();
    private readonly ConfigFile _config = new();

    public override void _Ready()
    {
        Instance = this;
        LoadSettings();
        ApplyAllSettings();
    }

    public Variant GetValue(string category, string key)
    {
        if (_settings.TryGetValue(category, out var categoryVar))
        {
            var categoryDict = categoryVar.AsGodotDictionary();
            if (categoryDict.TryGetValue(key, out var value))
                return value;
        }

        if (DefaultSettings.TryGetValue(category, out var defaultCategoryVar))
        {
            var defaultCategory = defaultCategoryVar.AsGodotDictionary();
            if (defaultCategory.TryGetValue(key, out var defaultValue))
                return defaultValue;
        }

        GD.PushWarning($"Settings: Unknown setting {category}/{key}");
        return default;
    }

    public void SetValue(string category, string key, Variant value)
    {
        if (!_settings.ContainsKey(category))
            _settings[category] = new Dictionary();

        var categoryDict = _settings[category].AsGodotDictionary();
        var oldValue = categoryDict.TryGetValue(key, out var existing) ? existing : default;
        categoryDict[key] = value;

        if (!oldValue.Equals(value))
        {
            ApplySetting(category, key, value);
            Events.Instance.EmitSignal(Events.SignalName.SettingChanged, category, key, value);
        }
    }

    #region Persistence

    private void LoadSettings()
    {
        _settings = DeepCopy(DefaultSettings);

        if (_config.Load(SettingsPath) != Error.Ok) return;

        foreach (var category in DefaultSettings.Keys)
        {
            var categoryStr = category.AsString();
            var defaultCategory = DefaultSettings[category].AsGodotDictionary();

            foreach (var key in defaultCategory.Keys)
            {
                var keyStr = key.AsString();
                if (_config.HasSectionKey(categoryStr, keyStr))
                {
                    var settingsCategory = _settings[category].AsGodotDictionary();
                    settingsCategory[key] = _config.GetValue(categoryStr, keyStr);
                }
            }
        }

        Events.Instance.EmitSignal(Events.SignalName.SettingsLoaded);
    }

    public void SaveSettings()
    {
        foreach (var category in _settings.Keys)
        {
            var categoryStr = category.AsString();
            var categoryDict = _settings[category].AsGodotDictionary();

            foreach (var key in categoryDict.Keys)
            {
                _config.SetValue(categoryStr, key.AsString(), categoryDict[key]);
            }
        }

        var err = _config.Save(SettingsPath);
        if (err == Error.Ok)
            Events.Instance.EmitSignal(Events.SignalName.SettingsSaved);
        else
            GD.PushError($"Settings: Failed to save settings: {err}");
    }

    public void ResetToDefaults()
    {
        _settings = DeepCopy(DefaultSettings);
        ApplyAllSettings();
        SaveSettings();
    }

    public void ResetCategory(string category)
    {
        if (!DefaultSettings.ContainsKey(category)) return;

        _settings[category] = DeepCopy(DefaultSettings[category].AsGodotDictionary());
        ApplyCategory(category);
        SaveSettings();
    }

    #endregion

    #region Application

    private void ApplyAllSettings()
    {
        foreach (var category in _settings.Keys)
        {
            ApplyCategory(category.AsString());
        }
    }

    private void ApplyCategory(string category)
    {
        if (!_settings.TryGetValue(category, out var categoryVar)) return;

        var categoryDict = categoryVar.AsGodotDictionary();
        foreach (var key in categoryDict.Keys)
        {
            ApplySetting(category, key.AsString(), categoryDict[key]);
        }
    }

    private void ApplySetting(string category, string key, Variant value)
    {
        switch (category)
        {
            case "graphics":
                ApplyGraphicsSetting(key, value);
                break;
            case "audio":
                ApplyAudioSetting(key, value);
                break;
        }
    }

    private void ApplyGraphicsSetting(string key, Variant value)
    {
        switch (key)
        {
            case "fullscreen":
                DisplayServer.WindowSetMode(value.AsBool()
                    ? DisplayServer.WindowMode.Fullscreen
                    : DisplayServer.WindowMode.Windowed);
                break;
            case "vsync":
                DisplayServer.WindowSetVsyncMode(value.AsBool()
                    ? DisplayServer.VSyncMode.Enabled
                    : DisplayServer.VSyncMode.Disabled);
                break;
            case "max_fps":
                Engine.MaxFps = value.AsInt32();
                break;
            case "msaa":
                GetViewport().Msaa3D = (Viewport.Msaa)value.AsInt32();
                break;
            case "render_scale":
                GetViewport().Scaling3DScale = value.AsSingle();
                break;
        }
    }

    private void ApplyAudioSetting(string key, Variant value)
    {
        var busName = key switch
        {
            "master_volume" => "Master",
            "music_volume" => "Music",
            "sfx_volume" => "SFX",
            "ui_volume" => "UI",
            "voice_volume" => "Voice",
            _ => null
        };

        if (busName == null) return;

        var busIdx = AudioServer.GetBusIndex(busName);
        if (busIdx >= 0)
            AudioServer.SetBusVolumeDb(busIdx, Mathf.LinearToDb(value.AsSingle()));
    }

    #endregion

    #region Helpers

    private static Dictionary DeepCopy(Dictionary source)
    {
        var copy = new Dictionary();
        foreach (var key in source.Keys)
        {
            var value = source[key];
            copy[key] = value.VariantType == Variant.Type.Dictionary
                ? DeepCopy(value.AsGodotDictionary())
                : value;
        }
        return copy;
    }

    #endregion
}
