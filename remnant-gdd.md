# Remnant: Game Design Document

## Overview

**Remnant** is a multiplayer space sport simulation game set in the near future asteroid belt. Players pilot fusion-thrust spacecraft through challenging arena environments, competing in both high-speed racing and tactical combat disciplines.

---

## Setting and World

### Timeline
- Near future solar system civilization
- Key technological breakthrough: fusion thrust engines enabling efficient interplanetary travel
- Asteroid belt has become a major economic hub with extensive mining operations
- Period of resource wars ended approximately 100 years before game's present day

### The Remnant
The game takes place in a unique region of the asteroid belt known as **The Remnant** — the site of an ancient collision between two massive asteroids (approximately 1,000 kilometer scale). This catastrophic event created an area uncharacteristically dense with asteroids of varying sizes, forming natural clusters that serve as arenas for the sport.

### Society
- Large population travels and works in the belt
- Mining operations drive the economy
- Business centers have developed around major mining zones
- The sport emerged organically from this industrial frontier culture

---

## The Sport

### Two Disciplines

**Racing**
- Formula One atmosphere: professional, clinical, precision-focused
- Pure speed and navigation skill through asteroid courses
- High-tech, clean presentation

**Combat**
- NASCAR atmosphere: rugged, popular, crowd-pleasing
- Non-lethal but destructive engagements
- Goal: incapacitate opponent ships, not kill pilots
- More accessible, broader appeal

### Sport Culture
- Professional sponsorship ecosystem
- Spectator crowds (implementation TBD)
- Competitive leagues and events
- Career progression through rankings

---

## Core Gameplay

### Game Loop
1. Start with basic ship
2. Compete in events (racing, combat, training)
3. Complete side missions for additional income
4. Earn money and attract sponsors
5. Upgrade ship and equipment
6. Progress to higher-tier competitions

### Progression System
- Skill-based advancement
- Performance in events determines progression
- Ship improvements complement but don't replace pilot skill
- Multiplayer-focused experience

---

## Flight Model

### Design Philosophy
Position in genre spectrum: between sim racing (Forza) and hardcore flight simulation (DCS). This is a **realistic spaceship simulator** — a new simulation category alongside car sims, flight sims, and naval sims.

### Newtonian Physics
- Full Newtonian motion model
- No atmospheric friction or drag
- Ships drift like speedboats on water
- Thrust is the only means of control
- Momentum must be actively managed

### Skill Considerations
The Newtonian model creates natural complexity:
- Turning requires calculating thrust vectors
- Speed changes require planning ahead
- Stopping or changing direction demands thrust in opposition to current momentum
- Extremely high skill ceiling
- Unnatural for Earth-trained intuitions

### Assist System (In Development)
**Concept:** Reduce one degree of freedom by having the ship automatically maintain speed in the direction the nose is pointing during turns.

**Challenge identified:** Full assist may be too helpful. Need to design a system that:
- Helps with impossible manual calculations
- Still rewards skilled manual control
- Provides meaningful advantage for reducing assistance
- Creates graduated skill progression

**Potential approaches to explore:**
- Graduated assist levels (full to manual)
- Assist limitations at extreme maneuvers
- Efficiency penalties for assisted flight
- Toggle system for advanced players

---

## Arena Architecture

### Environment Composition
- Large asteroid meshes (50 meters to several kilometers)
- Environmental particle effects:
  - Dust clouds
  - Debris fragments
  - Atmospheric effects around certain bodies
- 3D spatial positioning throughout arena volume

### Scale Parameters
Based on ship acceleration capabilities (1G to 6G):
- Ships can reach several hundred meters per second
- Minimum asteroid spacing: hundreds of meters
- Overall arena dimensions: 10-50 kilometers
- Individual asteroid sizes: 50 meters to several kilometers

### Generation Approach
**Decision pending:** Manual design vs. procedural generation vs. hybrid

Considerations:
- Hand-crafted arenas for quality racing lines
- Procedural systems for variety and scale
- Design language must support both racing flow and combat tactics

---

## Technical Architecture

### Rendering Strategy: Hybrid Approach

**Distance Fields for Asteroids**
- Smooth LOD transitions across massive scale (kilometers to meters)
- Efficient collision detection at high speeds
- Potential for real-time boolean operations (destruction)
- Well-suited for octree-based optimization
- Handles the scale requirements efficiently

**Traditional Meshes for Ships and Details**
- High-fidelity ship models
- Detailed cockpit environments
- Close-range visual quality

### Target Platform
- PC gaming systems
- Simulation game performance expectations
- Can assume capable hardware from target audience

### Destruction System (Under Consideration)
Voxel-based destruction remains in the design space:
- Weapon impacts affecting asteroid geometry
- Tactical implications of environmental destruction
- Visual spectacle for combat encounters
- Performance implications need evaluation

---

## Design Pillars

### 1. Authentic Spaceship Simulation
- Realistic Newtonian physics
- Deep skill-based mastery curve
- Genuine piloting skill development
- High skill ceiling with long-term progression

### 2. Professional Sport Atmosphere
- Compelling competitive framework
- Sponsorship and career systems
- Spectator-friendly presentation
- Two distinct discipline cultures (racing vs combat)

---

## Open Questions for Further Development

### Flight Model
- Exact parameters for assist system graduation
- Manual control advantage mechanics
- Controller/input device considerations

### Arena Design
- Manual vs procedural generation balance
- Racing line design principles for 3D space
- Combat zone layout requirements
- Sight line and flow pattern guidelines

### Technical
- Distance field implementation specifics
- Destruction system scope and performance
- Multiplayer networking architecture
- LOD transition distances and quality

### Game Systems
- Sponsorship mechanics
- Ship customization depth
- Matchmaking and competitive structure
- Spectator/crowd implementation

---

## Summary

Remnant aims to establish a new simulation genre — the realistic space racing/combat simulator. By combining authentic Newtonian physics with professional sport atmosphere in the unique setting of the asteroid belt, the game offers both deep skill-based gameplay and compelling world-building. The technical architecture leverages distance fields for massive-scale asteroid environments while maintaining high visual fidelity for ships and close-range details.
