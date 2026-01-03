# Remnant

**A multiplayer space sport simulation game set in the asteroid belt**

[![Godot 4.5](https://img.shields.io/badge/Godot-4.5-blue.svg)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Overview

**Remnant** is a realistic spaceship simulator featuring Newtonian physics-based flight, set in a unique region of the asteroid belt called "The Remnant." Players pilot fusion-thrust spacecraft in high-speed racing and tactical combat disciplines.

### Key Features

- **Authentic Newtonian Physics** - Pure physics simulation with optional flight assist
- **6 Degrees of Freedom** - Full 3D movement and rotation control
- **Skill-Based Progression** - Graduated flight assist system for learning curve
- **Multiplayer Focus** - Competitive racing and combat (planned)
- **Professional Sport Atmosphere** - Career mode with sponsorships and leagues (planned)

---

## Current Status

**Phase 1.2 - Flight Model Implementation** ✅ **COMPLETE**

The playable flight demo is ready for testing!

### What's Implemented

- ✅ Full 6DOF ship controls (keyboard + mouse)
- ✅ Flight assist system (4 levels: OFF/LOW/MEDIUM/HIGH)
- ✅ Camera system (third-person & first-person)
- ✅ Ship HUD with real-time telemetry
- ✅ Test arena with procedural asteroids
- ✅ Debug visualization (vectors, trajectory)
- ✅ Newtonian physics simulation
- ✅ Collision detection

### What's Next (Phase 2)

- 🔨 SDF asteroid rendering (GDExtension in Rust)
- 🔨 LOD system for massive-scale environments
- 🔨 Improved ship visuals
- 🔨 Audio system

---

## Quick Start

### Prerequisites

- **Godot 4.5+** ([Download](https://godotengine.org/download))
- **Rust** (for Phase 2+ GDExtension development)
- **Git**

### Running the Flight Demo

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/RemnantAI.git
   cd RemnantAI
   ```

2. **Open in Godot:**
   - Launch Godot 4.5+
   - Click "Import"
   - Navigate to `RemnantAI/game/project.godot`
   - Click "Import & Edit"

3. **Run the demo:**
   - Press **F5** or click the Play button
   - The flight test scene loads automatically

4. **Start flying!**
   - See [QUICK_CONTROLS.md](QUICK_CONTROLS.md) for controls
   - See [TESTING_GUIDE.md](TESTING_GUIDE.md) for full test scenarios

---

## Controls

| Input | Action |
|-------|--------|
| **WASD** | Thrust (Forward/Left/Back/Right) |
| **Space/Ctrl** | Thrust Up/Down |
| **Mouse** | Pitch & Yaw |
| **Q/E** | Roll Left/Right |
| **Shift** | Boost |
| **T** | Toggle Flight Assist |
| **C** | Toggle Camera |
| **ESC** | Pause / Release Mouse |

For detailed controls and tips, see [QUICK_CONTROLS.md](QUICK_CONTROLS.md).

---

## Documentation

### For Players/Testers
- [**QUICK_CONTROLS.md**](QUICK_CONTROLS.md) - Quick reference card for controls
- [**TESTING_GUIDE.md**](TESTING_GUIDE.md) - Comprehensive testing scenarios
- [**PRE_FLIGHT_CHECKLIST.md**](PRE_FLIGHT_CHECKLIST.md) - Pre-testing validation

### For Developers
- [**remnant-gdd.md**](remnant-gdd.md) - Game Design Document
- [**DEVELOPMENT_PLAN.md**](DEVELOPMENT_PLAN.md) - Full development roadmap
- [**PHASE_1.2_IMPLEMENTATION.md**](PHASE_1.2_IMPLEMENTATION.md) - Current phase details
- [**game/CONVENTIONS.md**](game/CONVENTIONS.md) - Coding standards

### Design Decisions
- [**docs/decisions/001-game-engine-godot4.md**](docs/decisions/001-game-engine-godot4.md) - Engine selection rationale

---

## Project Structure

```
RemnantAI/
├── game/                      # Godot project root
│   ├── project.godot         # Project configuration
│   ├── scenes/               # Scene files
│   ├── scripts/              # GDScript code
│   │   ├── autoloads/       # Singleton scripts
│   │   ├── core/            # Core gameplay systems
│   │   ├── physics/         # Physics utilities
│   │   ├── ui/              # UI controllers
│   │   └── utils/           # Helper utilities
│   └── assets/              # Art, audio, models (TBD)
├── docs/                     # Documentation
│   └── decisions/           # Architecture decision records
├── remnant-gdd.md           # Game Design Document
├── DEVELOPMENT_PLAN.md      # Development roadmap
└── README.md                # This file
```

---

## Development Roadmap

### ✅ Phase 1: Core Flight Experience (COMPLETE)
- Newtonian flight model with assist system
- Ship controls and camera
- HUD and debug visualization
- Test arena

### 🔨 Phase 2: Arena Environments (Next)
- SDF asteroid rendering (Rust GDExtension)
- Procedural and manual arena generation
- Environmental effects

### 📋 Phase 3: Racing Discipline
- Checkpoint system
- Race controller and timing
- AI opponents

### 📋 Phase 4: Combat Discipline
- Damage system
- Weapons and targeting
- Combat arenas

### 📋 Phase 5: Progression & Meta
- Career mode
- Ship customization
- Economy system

### 📋 Phase 6: Multiplayer
- Networking architecture
- Matchmaking
- Leaderboards

### 📋 Phase 7: Polish & Content
- Visual/audio polish
- Tutorial system
- Content expansion

### 📋 Phase 8: Advanced Features
- Voxel destruction
- Sponsorships
- Esports features

See [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) for details.

---

## Technology Stack

- **Engine:** Godot 4.5+ (MIT License)
- **Gameplay Code:** GDScript
- **Performance-Critical Systems:** Rust via [gdext](https://github.com/godot-rust/gdext)
- **Rendering:** Forward+ renderer
- **Physics:** Godot Physics 3D (120 Hz tick rate)
- **Future:** Custom SDF rendering, multiplayer netcode

---

## Contributing

This project is currently in early development. Contributions welcome once Phase 2 is complete!

### Development Setup

1. Install Godot 4.5+
2. Install Rust (for GDExtension work)
3. Read [game/CONVENTIONS.md](game/CONVENTIONS.md)
4. Follow coding standards and architecture patterns

---

## Design Pillars

### 1. Authentic Spaceship Simulation
- Realistic Newtonian physics
- Deep skill-based mastery curve
- High skill ceiling with long-term progression

### 2. Professional Sport Atmosphere
- Compelling competitive framework
- Career progression and sponsorships
- Two distinct disciplines (racing vs combat)

---

## Testing

To test the current flight demo:

1. Follow **Quick Start** instructions above
2. Review [PRE_FLIGHT_CHECKLIST.md](PRE_FLIGHT_CHECKLIST.md)
3. Test with [TESTING_GUIDE.md](TESTING_GUIDE.md)
4. Report issues via GitHub Issues

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Acknowledgments

- **Godot Engine** - Open-source game engine
- **gdext** - Rust bindings for Godot 4
- Inspired by realistic space flight sims and professional racing games

---

## Contact

- **Project Lead:** [Your Name]
- **Repository:** https://github.com/yourusername/RemnantAI
- **Issues:** https://github.com/yourusername/RemnantAI/issues

---

## Status Badge Legend

- ✅ Complete
- 🔨 In Progress
- 📋 Planned
- ⚠️ Known Issues

---

**Current Version:** 0.1.0 (Phase 1.2 - Flight Demo)

**Last Updated:** 2026-01-03

---

*"In the void between asteroids, only skill and physics matter."*
