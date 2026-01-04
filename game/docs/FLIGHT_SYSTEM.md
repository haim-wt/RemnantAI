# Remnant Flight System Documentation

## Overview

Remnant uses a **Fly-by-Wire (FBW)** flight control system that decouples the pilot's point-of-view (POV) from the ship's physical orientation. This creates a more intuitive flight experience where the pilot controls *where they want to go*, and the FBW computer handles the Newtonian physics to achieve that.

## Core Concepts

### POV (Point of View) vs Ship Orientation

- **POV Basis**: Where the pilot is *looking* / where they *want to go*. Controlled directly by mouse/controller input.
- **Ship Basis**: The actual physical orientation of the ship in space. Controlled by the FBW system.

These are often different! When you look in a new direction, the ship must rotate and apply thrust to change course. During this maneuver, the ship may be pointing sideways or backwards relative to where you're looking.

### Velocity Separation Architecture

The flight system maintains **two completely independent velocity components**:

```
Actual Ship Velocity = Thrust Velocity + RCS Velocity
```

| Component | Managed By | Purpose |
|-----------|------------|---------|
| `_thrustVelocity` | Main thrust system | Forward movement along POV direction |
| `_rcsVelocity` | RCS (Reaction Control System) | Lateral movement (strafe) |

This separation is critical. Each system only manages its own velocity component and never interferes with the other. This prevents velocity "leaking" between systems when the POV rotates.

## Main Thrust System

### How It Works

1. Pilot sets `TargetSpeed` via W/S keys (throttle up/down)
2. Target thrust velocity = `POV Forward * TargetSpeed`
3. FBW calculates error between current and target thrust velocity
4. If error > threshold:
   - Rotate ship to point toward thrust direction
   - Apply thrust to correct velocity
5. If error < threshold:
   - Align ship orientation to match POV (so you're facing where you're going)

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ManeuverAcceleration` | 20 m/s² | Max acceleration for velocity corrections |
| `MaxThrust` | 100,000 N | Maximum thrust force |
| `RotationRate` | 180°/s | How fast the ship can rotate |
| `VelocityMatchThreshold` | 0.5 m/s | Error below which velocity is "matched" |
| `OrientationMatchThreshold` | 2° | Angle below which orientation is "matched" |

### Maneuvering State

The ship is considered "maneuvering" when thrust velocity error exceeds `VelocityMatchThreshold`. During maneuvering:
- Ship rotates toward the required thrust direction
- Thrust is applied (partial if not aligned, full if aligned)
- Ship orientation may differ significantly from POV

When not maneuvering:
- Ship smoothly aligns its orientation to match POV
- Pilot sees ship pointing where they're looking

## RCS (Reaction Control System)

### How It Works

1. Pilot provides strafe input via A/D (left/right) and Space/Ctrl (up/down)
2. Target RCS velocity = `(POV Right * StrafeX + POV Up * StrafeY) * MaxStrafeSpeed`
3. RCS smoothly corrects `_rcsVelocity` toward target
4. When input released, target becomes zero, RCS brings lateral velocity to zero

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `RcsThrust` | 30,000 N | RCS thruster force |
| `MaxStrafeSpeed` | 30 m/s | Maximum lateral velocity |

### Why Separate Tracking?

Previous implementations measured lateral velocity by projecting current velocity onto POV axes each frame. This caused problems:

1. When POV rotates, the same world-space velocity projects differently onto the new axes
2. What was "lateral" velocity becomes partially "forward" (and vice versa)
3. This caused phantom corrections and velocity drift

The solution: track `_rcsVelocity` as an absolute world-space vector. RCS corrects this vector toward the target, independent of POV rotation.

## Input Mapping

| Input | Action | System |
|-------|--------|--------|
| Mouse X/Y | Rotate POV (yaw/pitch) | POV |
| Q/E | Roll POV | POV |
| W | Increase target speed | Thrust |
| S | Decrease target speed | Thrust |
| A | Strafe left | RCS |
| D | Strafe right | RCS |
| Space | Strafe up | RCS |
| Ctrl | Strafe down | RCS |
| Shift | Boost (1.5x speed) | Thrust |
| C | Toggle camera mode | Camera |
| Esc | Pause / Release mouse | UI |

## Physics Implementation

### Direct Velocity Control

Rather than applying forces and letting physics integrate, the FBW directly sets `LinearVelocity`:

```csharp
_ship.LinearVelocity = _rcsVelocity + _thrustVelocity;
```

This is appropriate for a fly-by-wire system because:
- The FBW is the authority on velocity, not physics integration
- Prevents accumulation of floating-point errors
- Makes behavior deterministic and predictable
- Avoids fighting with Godot's physics solver

### Rotation Control

Ship rotation is also directly controlled:
- FBW calculates desired rotation
- Applies rotation directly via `GlobalTransform.Basis`
- Sets `AngularVelocity = Vector3.Zero` to prevent physics interference

## Camera System

The camera rig follows the ship but can operate in different modes:
- **Chase**: Behind the ship, aligned with POV
- **Cockpit**: First-person view from ship
- **Free**: (Future) Detached camera

Camera receives `PovBasis` from FBW to know where the pilot is looking, independent of ship orientation.

## HUD Integration

The cockpit HUD displays:
- **Speed**: Current velocity magnitude
- **Target Speed**: Commanded forward speed
- **Status**: CRUISE (matched) or MANEUVER (correcting)
- **Attitude Indicator**: 3D hologram showing ship orientation relative to POV
- **Thruster Indicator**: Shows ship forward direction relative to view center

### Data Flow

```
PlayerShip._PhysicsProcess()
    └─> UpdateHud()
        └─> Events.HudUpdateRequested signal
            └─> Cockpit.OnHudUpdateRequested()
                └─> Updates displays
```

## File Structure

| File | Purpose |
|------|---------|
| `FlyByWire.cs` | Core flight control logic |
| `PlayerShip.cs` | Input processing, HUD data emission |
| `ShipCameraRig.cs` | Camera following and modes |
| `Cockpit.cs` | HUD overlay rendering |

## Future Considerations

### Planned Features
- G-force calculation and display
- Fuel consumption
- Thrust vectoring for more efficient maneuvers
- Autopilot modes (velocity match, orbit, dock)

### Multiplayer Considerations
- FBW state must be synchronized
- Consider authority model (client-predicted, server-authoritative)
- Input compression for network efficiency
