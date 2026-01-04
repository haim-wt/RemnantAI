using Godot;
using Godot.Collections;

namespace Remnant.Autoloads;

/// <summary>
/// Global event bus for decoupled communication between systems.
/// Use signals here to avoid tight coupling between game components.
/// </summary>
public partial class Events : Node
{
    public static Events Instance { get; private set; } = null!;

    public override void _Ready()
    {
        Instance = this;
    }

    #region Game Flow Events

    [Signal] public delegate void MatchStartedEventHandler(Dictionary matchData);
    [Signal] public delegate void MatchEndedEventHandler(Dictionary results);
    [Signal] public delegate void PauseToggledEventHandler(bool isPaused);
    [Signal] public delegate void ReturnToMenuRequestedEventHandler();

    #endregion

    #region Ship Events

    [Signal] public delegate void ShipSpawnedEventHandler(Node3D ship);
    [Signal] public delegate void ShipDestroyedEventHandler(Node3D ship, Node3D destroyer);
    [Signal] public delegate void ShipDamagedEventHandler(Node3D ship, float damage, Node3D source);
    [Signal] public delegate void ShipVelocityChangedEventHandler(Node3D ship, Vector3 velocity);
    [Signal] public delegate void FlightAssistChangedEventHandler(Node3D ship, int assistLevel);
    [Signal] public delegate void CheckpointCrossedEventHandler(Node3D ship, int checkpointId);
    [Signal] public delegate void LapCompletedEventHandler(Node3D ship, int lapNumber, float lapTime);

    #endregion

    #region Combat Events

    [Signal] public delegate void WeaponFiredEventHandler(Node3D ship, string weaponType);
    [Signal] public delegate void ProjectileHitEventHandler(Node3D projectile, Node3D target, Vector3 position);
    [Signal] public delegate void ShipIncapacitatedEventHandler(Node3D ship);

    #endregion

    #region UI Events

    [Signal] public delegate void NotificationRequestedEventHandler(string message, float duration);
    [Signal] public delegate void HudUpdateRequestedEventHandler(Dictionary data);
    [Signal] public delegate void LoadingScreenToggledEventHandler(bool visible, string message);
    [Signal] public delegate void CameraModeChangedEventHandler(int mode);

    #endregion

    #region Network Events

    [Signal] public delegate void ServerConnectedEventHandler();
    [Signal] public delegate void ServerDisconnectedEventHandler(string reason);
    [Signal] public delegate void PlayerJoinedEventHandler(int playerId, Dictionary playerData);
    [Signal] public delegate void PlayerLeftEventHandler(int playerId);

    #endregion

    #region Settings Events

    [Signal] public delegate void SettingChangedEventHandler(string category, string key, Variant value);
    [Signal] public delegate void SettingsSavedEventHandler();
    [Signal] public delegate void SettingsLoadedEventHandler();

    #endregion
}
