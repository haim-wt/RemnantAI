# Remnant Development Plan

**Version:** 1.0
**Date:** 2026-01-03
**Status:** Active

---

## Executive Summary

This development plan outlines the roadmap for building **Remnant**, a multiplayer space sport simulation game featuring Newtonian physics-based racing and combat in asteroid arenas. The plan is structured in phases, building from core systems through to polished multiplayer gameplay.

**Current State:** Foundation established with Godot 4.5, basic autoloads, ship base classes, and project structure.

---

## Phase 1: Core Flight Experience ✓ In Progress

**Goal:** Create a playable prototype demonstrating the Newtonian flight model with basic ship controls.

### 1.1 Foundation Systems ✓ COMPLETED
- [x] Project structure setup
- [x] Autoload singletons (Events, GameState, Settings, SceneManager, AudioManager)
- [x] Ship base classes (ShipBase, PlayerShip)
- [x] Newtonian physics foundation (NewtonianBody)
- [x] Utility systems (MathUtils, DebugUtils, ObjectPool)
- [x] Conventions document

### 1.2 Flight Model Implementation 🔄 CURRENT FOCUS
- [ ] **Ship Controls**
  - [ ] Input mapping system (keyboard + gamepad)
  - [ ] Thrust vector control (6DOF: forward/back, up/down, left/right, pitch/yaw/roll)
  - [ ] Throttle management system
  - [ ] RCS thruster positioning and simulation

- [ ] **Flight Assist System**
  - [ ] Design assist levels (OFF, LOW, MEDIUM, HIGH)
  - [ ] Velocity matching algorithm (maintain speed in nose direction)
  - [ ] Graduated assistance implementation
  - [ ] Visual feedback for assist level
  - [ ] Efficiency penalty system (if applicable)

- [ ] **Camera System**
  - [ ] Third-person camera with dynamic follow
  - [ ] First-person cockpit view
  - [ ] Camera smoothing for high-speed movement
  - [ ] Look-around capability

- [ ] **Ship HUD**
  - [ ] Velocity indicator (vector and magnitude)
  - [ ] Orientation reference
  - [ ] Thrust output display
  - [ ] Assist level indicator
  - [ ] Basic targeting reticle

### 1.3 Test Environment
- [ ] Simple test arena scene
  - [ ] Basic asteroid placement (manual, 5-10 large asteroids)
  - [ ] Collision detection setup
  - [ ] Boundary markers (10km test space)
- [ ] Debug visualization
  - [ ] Velocity vectors
  - [ ] Thrust vectors
  - [ ] Trajectory prediction lines
  - [ ] Physics data overlay

### 1.4 Milestone: Playable Flight Demo
**Success Criteria:**
- Player can pilot a ship with full 6DOF control
- Flight assist demonstrably helps with maneuvering
- Ship collides correctly with asteroids
- Flight feels responsive and skill-based
- HUD provides clear feedback on ship state

---

## Phase 2: Arena Environments

**Goal:** Create compelling 3D asteroid environments that support both racing and combat gameplay.

### 2.1 Asteroid Rendering System
- [ ] **GDExtension Setup (Rust)**
  - [ ] Rust + gdext project configuration
  - [ ] Build pipeline integration
  - [ ] Basic GDExtension module loaded in Godot

- [ ] **SDF Implementation**
  - [ ] Distance field generation for asteroid meshes
  - [ ] Octree spatial optimization
  - [ ] LOD system based on distance
  - [ ] SDF-based collision queries
  - [ ] Performance profiling and optimization

- [ ] **Visual Rendering**
  - [ ] SDF raymarching shader
  - [ ] Surface detail (normal mapping, PBR materials)
  - [ ] Lighting integration
  - [ ] Shadow casting
  - [ ] Performance testing at scale (50+ asteroids)

### 2.2 Arena Generation
- [ ] **Manual Design Tools**
  - [ ] Editor tooling for asteroid placement
  - [ ] Visualization of racing lines
  - [ ] Scale guidelines (spacing requirements)
  - [ ] Export/import system for arena layouts

- [ ] **Procedural Generation (Future)**
  - [ ] Seed-based generation algorithm
  - [ ] Density distribution parameters
  - [ ] Size variation system
  - [ ] Flow validation (racing lines)
  - [ ] Combat space requirements

### 2.3 Environmental Effects
- [ ] Dust clouds (particle systems)
- [ ] Debris fields
- [ ] Lighting atmosphere (distant stars, belt ambient)
- [ ] Audio ambience

### 2.4 Milestone: Complete Test Arena
**Success Criteria:**
- 20+ asteroids rendered with SDF system
- Smooth LOD transitions from kilometers to meters
- Performant collision detection at high speed (>300 m/s)
- Visually compelling environment
- At least one hand-crafted racing circuit layout

---

## Phase 3: Racing Discipline

**Goal:** Implement the racing game mode with checkpoints, timing, and competitive structure.

### 3.1 Race Infrastructure
- [ ] **Checkpoint System**
  - [ ] Checkpoint gates (visual + collision)
  - [ ] Sequence validation
  - [ ] Lap counting
  - [ ] Split time tracking
  - [ ] Invalid lap detection (shortcuts, collisions)

- [ ] **Race Controller**
  - [ ] Starting grid positioning
  - [ ] Countdown system
  - [ ] Race timer (lap times, total time)
  - [ ] Position tracking (1st, 2nd, etc.)
  - [ ] Finish line detection
  - [ ] Post-race results

- [ ] **Racing HUD**
  - [ ] Lap counter and current lap time
  - [ ] Best lap display
  - [ ] Position indicator
  - [ ] Next checkpoint arrow/marker
  - [ ] Speedometer
  - [ ] Track map (optional)

### 3.2 Racing AI (Opponents)
- [ ] Basic pathfinding through checkpoints
- [ ] Speed management around obstacles
- [ ] Difficulty levels (varies skill/aggression)
- [ ] Collision avoidance
- [ ] Rubberbanding (optional balancing)

### 3.3 Race Tracks
- [ ] Design 3 unique racing circuits
  - [ ] Technical track (tight turns, obstacles)
  - [ ] Speed track (long straights, high-speed)
  - [ ] Mixed track (balanced)
- [ ] Optimal racing line identification
- [ ] Track difficulty ratings

### 3.4 Milestone: Racing Alpha
**Success Criteria:**
- Complete race from start to finish with 3+ AI opponents
- Accurate timing and position tracking
- Clear checkpoint navigation
- Race feels competitive and challenging
- HUD provides all necessary race information

---

## Phase 4: Combat Discipline

**Goal:** Implement non-lethal combat with ship damage, weapons, and tactical gameplay.

### 4.1 Damage System
- [ ] **Ship Health**
  - [ ] Component-based damage model (hull, thrusters, weapons)
  - [ ] Visual damage feedback (sparks, smoke, debris)
  - [ ] Performance degradation (damaged thrusters reduce output)
  - [ ] Incapacitation state (ship disabled, not destroyed)
  - [ ] Respawn/repair mechanics

- [ ] **Shield System (Optional)**
  - [ ] Shield health pool
  - [ ] Recharge mechanics
  - [ ] Visual shield effect on impact
  - [ ] Power management (shields vs thrust)

### 4.2 Weapons
- [ ] **Projectile Weapons**
  - [ ] Kinetic cannon (ballistic projectiles)
  - [ ] Projectile physics (inherit ship velocity)
  - [ ] Leading/prediction targeting
  - [ ] Object pooling for projectiles
  - [ ] Impact effects (hit markers, damage numbers)

- [ ] **Targeting System**
  - [ ] Target lock-on
  - [ ] Lead indicator for moving targets
  - [ ] Targeting HUD elements
  - [ ] Lock-on range limits

### 4.3 Combat Arenas
- [ ] Design 2 combat arena layouts
  - [ ] Open arena (dogfighting)
  - [ ] Dense asteroid field (cover-based)
- [ ] Tactical positioning considerations
- [ ] Sight line analysis

### 4.4 Combat Game Modes
- [ ] **Deathmatch**
  - [ ] Kill counting
  - [ ] Respawn system
  - [ ] Time limit or kill target
  - [ ] Scoreboard

- [ ] **Team Deathmatch (Future)**
  - [ ] Team assignment
  - [ ] Team scoring
  - [ ] Friendly fire rules

### 4.5 Milestone: Combat Alpha
**Success Criteria:**
- Players can damage and disable opponent ships
- Weapons feel impactful and skill-based
- Combat arenas support tactical gameplay
- Deathmatch mode is playable and fun
- Visual feedback clearly shows damage state

---

## Phase 5: Progression & Meta Systems

**Goal:** Add career progression, ship customization, and the sport ecosystem.

### 5.1 Career Mode
- [ ] **Event System**
  - [ ] Event types (races, combat matches, training)
  - [ ] Difficulty tiers (Novice, Amateur, Pro, Elite)
  - [ ] Entry requirements (skill rating, equipment)
  - [ ] Reward structure (prize money, reputation)

- [ ] **Progression**
  - [ ] Skill rating system (ELO-based)
  - [ ] League/tier advancement
  - [ ] Career statistics tracking
  - [ ] Achievement system

### 5.2 Economy
- [ ] Currency system (credits)
- [ ] Event payouts
- [ ] Side mission rewards
- [ ] Sponsor contracts (passive income based on performance)

### 5.3 Ship Customization
- [ ] **Ship Stats**
  - [ ] Thrust power
  - [ ] Mass / agility
  - [ ] Armor / durability
  - [ ] Weapon hardpoints

- [ ] **Upgrade System**
  - [ ] Engine upgrades (thrust tiers)
  - [ ] Armor plating (mass vs protection tradeoff)
  - [ ] Weapon upgrades (damage, fire rate, accuracy)
  - [ ] Visual customization (paint jobs, decals)

- [ ] **Ship Hangar UI**
  - [ ] Ship selection screen
  - [ ] Upgrade shop interface
  - [ ] Ship stats comparison
  - [ ] Visual preview of customization

### 5.4 Side Missions
- [ ] Delivery missions (navigation skill)
- [ ] Time trials (racing skill)
- [ ] Target practice (combat skill)
- [ ] Exploration missions

### 5.5 Milestone: Career Mode Beta
**Success Criteria:**
- Players can progress through career tiers
- Ship upgrades provide meaningful improvements
- Economy feels balanced and rewarding
- Side missions provide variety
- Sense of progression and achievement

---

## Phase 6: Multiplayer

**Goal:** Enable online multiplayer for both racing and combat disciplines.

### 6.1 Networking Architecture
- [ ] **Server-Client Model**
  - [ ] Dedicated server setup (Godot headless)
  - [ ] Client connection handling
  - [ ] Authentication (basic account system)
  - [ ] Server browser or matchmaking queue

- [ ] **State Synchronization**
  - [ ] Ship position/velocity sync
  - [ ] Input prediction & reconciliation
  - [ ] Lag compensation
  - [ ] Interpolation for smooth remote players

### 6.2 Multiplayer Game Modes
- [ ] **Multiplayer Racing**
  - [ ] Synchronized race starts
  - [ ] Position tracking for all players
  - [ ] Collision handling between players
  - [ ] Ghost/replay system for best laps

- [ ] **Multiplayer Combat**
  - [ ] Projectile synchronization
  - [ ] Damage replication
  - [ ] Kill attribution
  - [ ] Team assignment (if team modes)

### 6.3 Matchmaking
- [ ] Skill-based matchmaking
- [ ] Party/squad system
- [ ] Custom lobbies
- [ ] Server region selection

### 6.4 Social Features
- [ ] Friends list
- [ ] Player profiles
- [ ] Leaderboards (global, friends)
- [ ] Replay sharing

### 6.5 Milestone: Multiplayer Beta
**Success Criteria:**
- 8+ players can race simultaneously with stable performance
- Combat feels responsive at typical latencies (<100ms)
- Matchmaking finds appropriate skill-matched games
- No critical desync issues
- Leaderboards accurately track top performers

---

## Phase 7: Polish & Content

**Goal:** Refine all systems, add content variety, and prepare for release.

### 7.1 Visual Polish
- [ ] Ship models (multiple racing and combat variants)
- [ ] High-quality asteroid models
- [ ] VFX improvements
  - [ ] Engine thrust effects
  - [ ] Weapon fire effects
  - [ ] Impact and damage effects
  - [ ] Environmental atmosphere
- [ ] Lighting and post-processing
- [ ] UI/UX polish pass

### 7.2 Audio
- [ ] Engine sound design (thrust variations)
- [ ] Weapon sound effects
- [ ] Impact sounds (collisions, weapon hits)
- [ ] Ambient space audio
- [ ] Music (menu, racing, combat)
- [ ] Positional 3D audio

### 7.3 Content Expansion
- [ ] 5+ racing tracks (varied difficulty)
- [ ] 3+ combat arenas
- [ ] 6+ ship variants (3 racing focused, 3 combat focused)
- [ ] 20+ career events
- [ ] 10+ side mission types

### 7.4 Spectator Mode
- [ ] Free camera
- [ ] Follow specific players
- [ ] Cinematic camera angles
- [ ] HUD for spectators (race positions, stats)

### 7.5 Tutorial & Onboarding
- [ ] Flight school tutorial (basic controls)
- [ ] Advanced maneuvers tutorial (drift turns, precision flying)
- [ ] Combat training (targeting, weapons)
- [ ] Assist system explanation
- [ ] Progressive tutorial missions

### 7.6 Performance Optimization
- [ ] Profiling and bottleneck identification
- [ ] Draw call optimization
- [ ] Physics optimization
- [ ] Network bandwidth optimization
- [ ] Loading time improvements
- [ ] Memory usage optimization

### 7.7 Milestone: Release Candidate
**Success Criteria:**
- Game runs at 60+ FPS on target hardware
- No critical bugs or crashes
- Full content suite (tracks, ships, modes)
- Polished presentation (visuals, audio, UI)
- Tutorial effectively teaches core mechanics
- Multiplayer stable with 100+ concurrent players

---

## Phase 8: Advanced Features (Post-Launch)

**Goal:** Expand the game with advanced systems identified in the GDD.

### 8.1 Voxel Destruction System
- [ ] GDExtension voxel implementation
- [ ] Real-time boolean operations on asteroids
- [ ] Weapon impact creates craters/debris
- [ ] Physics for destroyed chunks
- [ ] Network synchronization of destruction
- [ ] Performance testing and optimization

### 8.2 Advanced Arena Features
- [ ] Dynamic hazards (moving asteroids, debris storms)
- [ ] Environmental damage (radiation zones, etc.)
- [ ] Interactive elements (gates, boost pads for arcade feel - optional)

### 8.3 Expanded Progression
- [ ] Sponsorship system (multiple sponsor tiers)
- [ ] Team/organization membership
- [ ] Seasonal competitions
- [ ] Championship series

### 8.4 Spectator & Esports
- [ ] Improved spectator tools (replay system, director mode)
- [ ] Tournament bracket system
- [ ] Streaming integration (Twitch, etc.)
- [ ] Match recording and highlights

### 8.5 Additional Disciplines/Modes
- [ ] Exploration mode (free-roam asteroid belt)
- [ ] Capture the flag or objective-based modes
- [ ] Co-op PvE missions
- [ ] Racing+Combat hybrid modes

---

## Technical Debt & Infrastructure

**Ongoing tasks that support all phases:**

### Code Quality
- [ ] Comprehensive unit tests for physics systems
- [ ] Integration tests for game modes
- [ ] Code review process for major systems
- [ ] Performance benchmarking suite
- [ ] Automated CI/CD pipeline

### Documentation
- [ ] API documentation for all public systems
- [ ] Architecture decision records (like 001-game-engine-godot4.md)
- [ ] Developer onboarding guide
- [ ] Modding documentation (if supporting mods)

### Tools
- [ ] Level design tools (arena editor)
- [ ] Ship design tools (stat balancing)
- [ ] Event creation tools (career mode designer)
- [ ] Debug console and cheat commands

---

## Dependencies & Risk Management

### Critical Path Items
1. **SDF Rendering System** (Phase 2.1) - Core technical differentiator
   - Risk: Performance may not meet requirements
   - Mitigation: Early prototype, fallback to traditional mesh LOD if needed

2. **Networking** (Phase 6) - Required for multiplayer focus
   - Risk: Synchronization issues with fast-moving physics
   - Mitigation: Research Godot 4's multiplayer early, consider GDExtension for netcode

3. **Flight Assist System** (Phase 1.2) - Core to accessibility
   - Risk: Difficult to balance help vs skill
   - Mitigation: Extensive playtesting, adjustable levels

### External Dependencies
- **Godot 4.x Updates:** Monitor for breaking changes or new features
- **gdext (Rust bindings):** Track compatibility with Godot versions
- **Multiplayer Infrastructure:** May need dedicated server hosting solution

---

## Success Metrics

### Phase 1-2 (Prototype)
- Flight feels responsive within 100ms input latency
- Players can navigate complex asteroid field without frustration
- 60 FPS with 50+ asteroids on mid-range hardware

### Phase 3-4 (Alpha)
- Racing lap times improve with practice (skill curve evident)
- Combat engagements last 30-120 seconds (good pacing)
- 80%+ playtest satisfaction rating

### Phase 5 (Beta)
- Average career session length: 30+ minutes
- Ship upgrade progression feels meaningful in playtests
- Retention rate: 60%+ return for second session

### Phase 6-7 (Release)
- Multiplayer matches fill within 2 minutes
- Average match latency: <80ms
- Crash rate: <1% of sessions
- Player retention: 40%+ active after 1 week

---

## Current Priorities

**Immediate Next Steps (Phase 1.2 - Flight Model Implementation):**

1. Implement ship input system
   - Map keyboard/gamepad inputs
   - Implement 6DOF thrust control
   - Add throttle management

2. Design and implement flight assist levels
   - Start with basic velocity matching (HIGH assist)
   - Add OFF mode (pure Newtonian)
   - Create graduated levels (LOW, MEDIUM)

3. Build basic HUD
   - Velocity vector display
   - Assist level indicator
   - Orientation reference

4. Create test arena scene
   - Place 5-10 asteroids manually
   - Add collision detection
   - Set up boundaries

5. Add debug visualization
   - Velocity vectors
   - Thrust vectors
   - Trajectory prediction

**Target:** Playable flight demo within 2-3 weeks of focused development.

---

## Appendix: Feature Priorities

### Must Have (MVP)
- Newtonian flight model with assist system
- SDF asteroid rendering
- Racing mode with checkpoints
- Combat mode with weapons/damage
- Single-player career mode
- Multiplayer (racing & combat)
- 3+ racing tracks, 2+ combat arenas

### Should Have (Release)
- Ship customization and upgrades
- Spectator mode
- Tutorial system
- 5+ ships, 5+ tracks, 3+ arenas
- Leaderboards and rankings

### Nice to Have (Post-Launch)
- Voxel destruction
- Advanced progression (sponsorships, teams)
- Replay system
- Additional game modes
- Modding support

### Won't Have (Out of Scope)
- Single-player story campaign
- Open-world exploration (outside arena context)
- Space station management/building
- Non-sport gameplay loops

---

## Conclusion

This development plan provides a structured roadmap from current foundation to polished multiplayer space sport simulation. The phased approach ensures core mechanics are solid before building on top, while maintaining flexibility to adjust based on playtesting feedback and technical discoveries.

**Next Review:** After Phase 1.2 completion (Playable Flight Demo milestone)
