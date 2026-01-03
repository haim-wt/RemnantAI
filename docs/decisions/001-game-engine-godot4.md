# Decision Record: Game Engine Selection

**Decision:** Godot 4 with GDExtension for custom rendering

**Date:** 2026-01-03

**Status:** Accepted

---

## Context

Remnant requires a game engine capable of:
- Hybrid rendering (SDF for asteroids + traditional meshes for ships)
- Massive scale environments (10-50 km arenas)
- Full Newtonian physics simulation
- High-speed gameplay (hundreds of m/s)
- Multiplayer networking
- Potential voxel-based destruction

Additionally, development will primarily use AI-assisted coding (agentic AI), which introduces unique requirements around code generation reliability and workflow compatibility.

---

## Options Considered

### 1. Unreal Engine 5
- **Pros:** Industry-leading graphics, Nanite LOD, robust multiplayer, Chaos physics
- **Cons:** Complex C++ with macros/conventions that AI struggles with, Blueprint-heavy workflows incompatible with AI, 5% royalty after $1M, heavy engine overhead

### 2. Unity (HDRP)
- **Pros:** Flexible rendering pipeline, C# excellent for AI, large training corpus, multiple multiplayer solutions
- **Cons:** Licensing uncertainty, requires significant custom work for AAA visuals, more complex API than needed

### 3. Godot 4
- **Pros:** 100% open source (AI trained on engine internals), GDScript is Python-like and trivial for AI, code-first philosophy, GDExtension for performance-critical custom code, no licensing fees
- **Cons:** Smaller ecosystem, requires custom work for high-end visuals

### 4. Custom Engine (Rust/C++)
- **Pros:** Full control, no licensing, optimal performance
- **Cons:** Massive development overhead, need to build everything from scratch

---

## Decision

**Godot 4** is selected as the game engine for Remnant.

### Rationale

#### 1. AI-Assisted Development Compatibility
- GDScript's Python-like syntax produces reliable AI-generated code
- 100% open source means AI models are trained on engine internals, not just user code
- Code-first philosophy eliminates dependency on visual editors AI cannot use
- Simple, consistent API reduces AI errors

#### 2. Technical Flexibility
- GDExtension allows custom C++/Rust modules for performance-critical systems:
  - SDF asteroid rendering pipeline
  - Physics optimizations for Newtonian simulation
  - Custom networking if needed
- Full source access enables deep customization if required

#### 3. Business Considerations
- No licensing fees at any revenue level
- No runtime fees
- MIT license provides complete freedom

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GDScript Layer                       │
│  • Game logic (events, scoring, progression)            │
│  • UI systems (menus, HUD, spectator views)             │
│  • High-level networking (game state, matchmaking)      │
│  • Ship controls and assist system                      │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│              GDExtension Layer (Rust/C++)               │
│  • SDF asteroid rendering pipeline                      │
│  • Distance field generation and LOD                    │
│  • Physics engine optimizations                         │
│  • Collision detection (high-speed SDF queries)         │
│  • Voxel destruction system (if implemented)            │
└─────────────────────────────────────────────────────────┘
```

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Visual quality below expectations | Medium | High | Custom shaders, SDF rendering is custom anyway, PC-focused allows pushing hardware |
| Smaller community/fewer resources | Medium | Medium | AI-assisted development reduces dependency on community solutions |
| Multiplayer maturity | Medium | Medium | Godot 4's networking is improved; can use GDExtension for custom netcode if needed |
| GDExtension complexity | Low | Medium | Rust ecosystem has good Godot bindings (gdext) |

---

## Implementation Notes

### Immediate Next Steps
1. Set up Godot 4 project structure
2. Prototype SDF rendering via GDExtension (Rust preferred)
3. Implement basic Newtonian flight model in GDScript
4. Establish multiplayer architecture

### Technology Stack
- **Engine:** Godot 4.x (latest stable)
- **Gameplay Code:** GDScript
- **Performance-Critical Systems:** Rust via gdext
- **Shaders:** Godot Shading Language (GLSL-like)
- **Build System:** SCons (Godot native) + Cargo (Rust)

---

## References

- [Godot Engine](https://godotengine.org/)
- [gdext - Rust bindings for Godot 4](https://github.com/godot-rust/gdext)
- [Godot GDExtension Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html)
