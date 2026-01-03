# Remnant Project Conventions

This document defines coding standards and best practices for the Remnant project. Following these conventions ensures consistency across AI-assisted development.

---

## Project Structure

```
game/
├── project.godot           # Project configuration
├── addons/                  # GDExtension plugins and third-party addons
├── assets/
│   ├── models/             # 3D models (.glb, .gltf)
│   ├── textures/           # Images and textures
│   ├── audio/              # Sound effects and music
│   ├── fonts/              # Font files
│   └── shaders/            # Shader files (.gdshader)
├── scenes/
│   ├── main/               # Main game scenes
│   ├── ships/              # Ship scenes and prefabs
│   ├── arenas/             # Arena/level scenes
│   └── ui/                 # UI scenes
├── scripts/
│   ├── autoloads/          # Singleton scripts (Events, GameState, etc.)
│   ├── core/               # Base classes and core systems
│   ├── ships/              # Ship-specific scripts
│   ├── physics/            # Physics-related scripts
│   ├── ui/                 # UI scripts
│   └── utils/              # Utility classes
└── resources/              # .tres resource files
```

---

## Naming Conventions

### Files

| Type | Convention | Example |
|------|------------|---------|
| Scenes | `snake_case.tscn` | `player_ship.tscn` |
| Scripts | `snake_case.gd` | `ship_base.gd` |
| Resources | `snake_case.tres` | `ship_stats.tres` |
| Shaders | `snake_case.gdshader` | `asteroid_sdf.gdshader` |
| Classes | `PascalCase` | `class_name ShipBase` |

### Code

```gdscript
# Classes: PascalCase
class_name PlayerShip

# Constants: SCREAMING_SNAKE_CASE
const MAX_SPEED := 500.0
const GRAVITY_CONSTANT := 6.674e-11

# Variables: snake_case
var current_velocity: Vector3
var _private_variable: float  # Prefix with underscore

# Functions: snake_case
func calculate_thrust() -> Vector3:
    pass

# Signals: snake_case (past tense for events)
signal ship_destroyed(ship: Node3D)
signal velocity_changed(new_velocity: Vector3)

# Enums: PascalCase for type, SCREAMING_SNAKE_CASE for values
enum FlightAssistLevel {
    OFF = 0,
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
}
```

---

## GDScript Style Guide

### Type Hints

Always use static typing for better AI code generation and error catching:

```gdscript
# Good
var speed: float = 0.0
var velocity: Vector3 = Vector3.ZERO
func get_thrust() -> Vector3:
    return Vector3.ZERO

# Avoid
var speed = 0.0
func get_thrust():
    return Vector3.ZERO
```

### Exports

Group related exports together:

```gdscript
@export_group("Movement")
@export var max_speed: float = 500.0
@export var acceleration: float = 50.0

@export_group("Combat")
@export var health: float = 100.0
@export var shield: float = 50.0
```

### Documentation

Use `##` for documentation comments:

```gdscript
## Base class for all spacecraft in the game.
## Implements Newtonian physics with optional flight assist.
class_name ShipBase
extends RigidBody3D

## Maximum thrust in Newtons
@export var thrust_max: float = 50000.0

## Calculate the required thrust vector to reach target velocity.
## Returns Vector3.ZERO if already at target.
func calculate_thrust_to_target(target_velocity: Vector3) -> Vector3:
    pass
```

### Script Organization

Follow this order in scripts:

```gdscript
class_name ClassName
extends ParentClass

# 1. Signals
signal something_happened

# 2. Enums
enum State { IDLE, ACTIVE }

# 3. Constants
const MAX_VALUE := 100

# 4. Exports
@export var exported_var: float = 0.0

# 5. Public variables
var public_var: int = 0

# 6. Private variables (underscore prefix)
var _private_var: String = ""

# 7. Onready variables
@onready var _cached_node: Node = $Child

# 8. Lifecycle methods (_ready, _process, etc.)
func _ready() -> void:
    pass

# 9. Public methods
func do_something() -> void:
    pass

# 10. Private methods
func _internal_helper() -> void:
    pass
```

---

## Architecture Patterns

### Event Bus

Use the global `Events` autoload for decoupled communication:

```gdscript
# Emitting events
Events.ship_destroyed.emit(self, attacker)

# Listening to events
func _ready() -> void:
    Events.ship_destroyed.connect(_on_ship_destroyed)

func _on_ship_destroyed(ship: Node3D, attacker: Node3D) -> void:
    pass
```

### State Management

Use `GameState` for global game state:

```gdscript
# Check state
if GameState.is_match_active():
    pass

# Modify state (through methods, not direct assignment)
GameState.start_match(GameState.GameMode.RACING, config)
```

### Settings

Access settings through the `Settings` autoload:

```gdscript
var sensitivity: float = Settings.get_value("gameplay", "mouse_sensitivity")
Settings.set_value("audio", "master_volume", 0.8)
```

---

## Physics Conventions

### Units

| Quantity | Unit | Notes |
|----------|------|-------|
| Distance | meters (m) | 1 unit = 1 meter |
| Velocity | m/s | |
| Acceleration | m/s² | |
| Mass | kilograms (kg) | |
| Force | Newtons (N) | |
| Time | seconds (s) | |

### Space Physics

```gdscript
# No gravity in space
gravity_scale = 0.0

# No atmospheric drag
linear_damp = 0.0
angular_damp = 0.0

# Apply forces in world space
var world_force := global_transform.basis * local_force
apply_central_force(world_force)
```

---

## Scene Conventions

### Node Naming

- Use PascalCase for node names
- Be descriptive: `ThrusterParticles` not `Particles`
- Use consistent prefixes for types:
  - `UI_` for UI elements
  - `SFX_` for audio players
  - `VFX_` for visual effects

### Scene Inheritance

Prefer scene inheritance over script inheritance for visual elements:

```
ships/
├── ship_base.tscn          # Base ship with common nodes
├── racer_a.tscn            # Inherits from ship_base
└── combat_heavy.tscn       # Inherits from ship_base
```

---

## Performance Guidelines

### Object Pooling

Use `ObjectPool` for frequently spawned objects:

```gdscript
var projectile_pool: ObjectPool

func _ready() -> void:
    var scene := preload("res://scenes/projectile.tscn")
    projectile_pool = ObjectPool.create(scene, 50, 200)
    add_child(projectile_pool)

func fire() -> void:
    var projectile := projectile_pool.acquire()
    if projectile:
        projectile.global_position = muzzle.global_position
```

### Avoid in Hot Paths

```gdscript
# Avoid in _physics_process:
# - String operations
# - Node path lookups (use @onready)
# - Resource loading
# - Creating new objects (use pools)

# Good: Cache references
@onready var _target: Node3D = $Target

# Bad: Lookup every frame
func _physics_process(delta: float) -> void:
    var target := get_node("Target")  # Don't do this
```

---

## Git Conventions

### Commit Messages

```
<type>: <short description>

<optional body>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `docs`: Documentation
- `style`: Formatting, no code change
- `test`: Adding tests
- `chore`: Maintenance tasks

### Branch Naming

- Feature: `feature/ship-combat`
- Fix: `fix/physics-collision`
- Refactor: `refactor/event-system`

---

## AI Development Notes

### Writing Prompts for AI

When requesting AI to write code:

1. Reference existing patterns: "Follow the pattern in ship_base.gd"
2. Specify types: "The function should return Vector3"
3. Mention conventions: "Use the Events autoload for signals"

### Code Review Checklist

- [ ] Static typing on all variables and functions
- [ ] Documentation comments on public API
- [ ] Events used instead of direct coupling
- [ ] No magic numbers (use constants)
- [ ] Follows script organization order
- [ ] Performance-sensitive code avoids allocations
