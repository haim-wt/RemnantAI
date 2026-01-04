using Godot;
using Godot.Collections;

namespace Remnant.Autoloads;

/// <summary>
/// Manages global game state and session data.
/// Central authority for match state, player data, and progression.
/// </summary>
public partial class GameState : Node
{
    public static GameState Instance { get; private set; } = null!;

    #region Enums

    public enum GameMode
    {
        None,
        Menu,
        Racing,
        Combat,
        Training,
        Freeplay
    }

    public enum MatchPhase
    {
        None,
        Lobby,
        Countdown,
        Active,
        Finished,
        PostMatch
    }

    #endregion

    #region State Properties

    public GameMode CurrentMode { get; set; } = GameMode.Menu;
    public MatchPhase CurrentMatchPhase { get; set; } = MatchPhase.None;
    public bool IsMultiplayer { get; set; }
    public int LocalPlayerId { get; set; } = 1;
    public Dictionary Players { get; } = new();
    public Dictionary MatchData { get; private set; } = new();
    public float MatchTime { get; private set; }

    private bool _isPaused;
    public bool IsPaused
    {
        get => _isPaused;
        set
        {
            if (_isPaused == value) return;
            _isPaused = value;
            GetTree().Paused = value;
            Events.Instance.EmitSignal(Events.SignalName.PauseToggled, value);
        }
    }

    #endregion

    public override void _Ready()
    {
        Instance = this;
        ProcessMode = ProcessModeEnum.Always;
    }

    public override void _Process(double delta)
    {
        if (CurrentMatchPhase == MatchPhase.Active && !IsPaused)
        {
            MatchTime += (float)delta;
        }
    }

    #region Session Management

    public void StartMatch(GameMode mode, Dictionary? config = null)
    {
        CurrentMode = mode;
        CurrentMatchPhase = MatchPhase.Countdown;
        MatchTime = 0f;
        MatchData = config?.Duplicate() as Dictionary ?? new Dictionary();

        Events.Instance.EmitSignal(Events.SignalName.MatchStarted, MatchData);
    }

    public void BeginActivePhase()
    {
        CurrentMatchPhase = MatchPhase.Active;
    }

    public void EndMatch(Dictionary? results = null)
    {
        CurrentMatchPhase = MatchPhase.Finished;
        Events.Instance.EmitSignal(Events.SignalName.MatchEnded, results ?? new Dictionary());
    }

    public void ReturnToMenu()
    {
        CurrentMode = GameMode.Menu;
        CurrentMatchPhase = MatchPhase.None;
        MatchData.Clear();
        Players.Clear();
        IsPaused = false;

        Events.Instance.EmitSignal(Events.SignalName.ReturnToMenuRequested);
    }

    #endregion

    #region Player Management

    public void RegisterPlayer(int playerId, Dictionary data)
    {
        Players[playerId] = data;
        Events.Instance.EmitSignal(Events.SignalName.PlayerJoined, playerId, data);
    }

    public void UnregisterPlayer(int playerId)
    {
        if (!Players.ContainsKey(playerId)) return;
        Players.Remove(playerId);
        Events.Instance.EmitSignal(Events.SignalName.PlayerLeft, playerId);
    }

    public Dictionary GetPlayerData(int playerId)
    {
        return Players.TryGetValue(playerId, out var data) ? data.AsGodotDictionary() : new Dictionary();
    }

    public Dictionary GetLocalPlayerData() => GetPlayerData(LocalPlayerId);

    #endregion

    #region State Queries

    public bool IsInMatch() =>
        CurrentMatchPhase is MatchPhase.Countdown or MatchPhase.Active;

    public bool IsMatchActive() =>
        CurrentMatchPhase == MatchPhase.Active && !IsPaused;

    public string GetMatchTimeString()
    {
        var minutes = (int)(MatchTime / 60f);
        var seconds = (int)(MatchTime % 60f);
        var millis = (int)((MatchTime * 1000f) % 1000f);
        return $"{minutes:D2}:{seconds:D2}.{millis:D3}";
    }

    #endregion
}
