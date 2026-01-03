# Pre-Flight Checklist ✈️

**Phase 1.2 - Flight Demo Validation**

Run through this checklist before testing to ensure everything is ready.

---

## File Integrity Check

### Core Scripts
- [x] `scripts/main.gd` - Main entry point (Node3D)
- [x] `scripts/core/ship_base.gd` - Base ship class with physics
- [x] `scripts/core/player_ship.gd` - Player input handling
- [x] `scripts/physics/newtonian_body.gd` - Newtonian physics helpers

### Phase 1.2 New Scripts
- [x] `scripts/core/ship_camera_rig.gd` - Camera system
- [x] `scripts/ui/ship_hud.gd` - HUD controller
- [x] `scripts/utils/ship_debug_visualizer.gd` - Debug visualization
- [x] `scripts/core/test_arena_generator.gd` - Arena generation

### Autoloads
- [x] `scripts/autoloads/events.gd` - Event bus
- [x] `scripts/autoloads/game_state.gd` - Game state manager
- [x] `scripts/autoloads/settings.gd` - Settings manager
- [x] `scripts/autoloads/audio_manager.gd` - Audio system
- [x] `scripts/autoloads/scene_manager.gd` - Scene management

### Scene Files
- [x] `scenes/main/main.tscn` - Main scene (updated to Node3D)

### Project Configuration
- [x] `project.godot` - Input mappings configured
  - [x] Roll controls (Q/E)
  - [x] Camera toggle (C)
  - [x] All thrust inputs (WASD/Space/Ctrl)
  - [x] Boost (Shift)
  - [x] Assist toggle (T)

---

## Expected Behavior on Launch

When you press **F5** in Godot, the following should happen automatically:

1. ✅ Main scene loads
2. ✅ `_create_test_environment()` is called
3. ✅ Space environment created (black background, sun light)
4. ✅ Arena generated with 15 asteroids
5. ✅ Player ship spawned at origin (0, 0, 0)
6. ✅ Camera rig created and attached
7. ✅ HUD created and connected
8. ✅ Debug visualizer enabled
9. ✅ Mouse captured for flight control
10. ✅ Console prints "Flight test scene ready!"

---

## System Specifications

### Physics Settings (from project.godot)
```
Physics tick rate: 120 Hz
Default gravity: 0.0 (space)
Linear damping: 0.0 (no drag)
Angular damping: 0.0 (no drag)
```

### Ship Configuration
```
Mass: 5000 kg
Main thrust: 50,000 N (forward/back)
Maneuver thrust: 20,000 N (lateral/vertical)
Torque: 10,000 N⋅m
Boost multiplier: 1.5x
```

### Arena Configuration
```
Radius: 5000 m (10 km diameter)
Asteroids: 15
Size range: 50-300 m radius
Min spacing: 400 m
```

### Rendering Settings
```
Renderer: Forward+
MSAA: 2x
Screen-space AA: FXAA
Shadow quality: High
Background: Pure black (space)
```

---

## Input Mappings Verification

Run this in Godot's console to verify inputs are mapped:

```gdscript
print(InputMap.get_actions())
```

Should include:
- `thrust_forward` (W)
- `thrust_backward` (S)
- `thrust_left` (A)
- `thrust_right` (D)
- `thrust_up` (Space)
- `thrust_down` (Ctrl)
- `roll_left` (Q)
- `roll_right` (E)
- `boost` (Shift)
- `toggle_assist` (T)
- `toggle_camera` (C)
- `pause` (ESC)

---

## Common Issues & Fixes

### Issue: "Class not found" errors
**Cause:** Scripts not registered with Godot
**Fix:**
1. Open each new script in Godot editor
2. Resave (Ctrl+S)
3. Restart Godot

### Issue: Mouse not captured
**Cause:** Mouse mode not set
**Fix:**
- Click in game window
- Or press ESC twice

### Issue: Ship not visible
**Cause:** Camera inside ship mesh
**Fix:**
- Press C to switch camera modes
- Or adjust `follow_distance` in main.gd

### Issue: No HUD visible
**Cause:** CanvasLayer not created or labels not assigned
**Fix:**
- Check console for errors
- Verify `_create_hud_elements()` runs

### Issue: Asteroids not generating
**Cause:** Arena generator not running
**Fix:**
- Check `_setup_arena()` is called
- Verify TestArenaGenerator class is loaded

---

## Performance Expectations

### Target Hardware
- **CPU:** Mid-range (4+ cores)
- **GPU:** Integrated graphics or better
- **RAM:** 4GB+

### Expected Performance
- **FPS:** 60+ (target 120 on good hardware)
- **Physics:** Stable at 120 Hz tick rate
- **Input latency:** <100ms
- **Load time:** <5 seconds

### Performance Monitoring
Enable in Godot: **Debug → Visible FPS**
Watch for:
- Frame time spikes
- Physics process time
- Render time

---

## Debug Console Commands

While testing, you can use the Godot debugger to:

1. **Check ship velocity:**
   ```gdscript
   var ship = get_node("/root/Main/PlayerShip")
   print(ship.linear_velocity)
   ```

2. **Check assist level:**
   ```gdscript
   var ship = get_node("/root/Main/PlayerShip")
   print(ship.assist_level)
   ```

3. **Teleport ship:**
   ```gdscript
   var ship = get_node("/root/Main/PlayerShip")
   ship.global_position = Vector3(1000, 0, 0)
   ```

4. **Toggle debug visualizer:**
   ```gdscript
   var debug = get_node("/root/Main/DebugVisualizer")
   debug.visible = !debug.visible
   ```

---

## Success Criteria

Before starting full testing (TESTING_GUIDE.md), verify:

- [ ] Project loads without errors
- [ ] Press F5, game starts
- [ ] Black space background visible
- [ ] Sun light casting shadows
- [ ] Asteroids visible in scene
- [ ] Ship visible (blue box)
- [ ] HUD visible in top-left
- [ ] Mouse captured (can't see cursor)
- [ ] Console shows "Flight test scene ready!"

If **all checks pass**, proceed to **TESTING_GUIDE.md**

If **any check fails**, investigate errors in console before testing.

---

## Emergency Commands

If something goes wrong during testing:

- **Stop game:** F8 or click Stop button
- **Restart game:** F5
- **Reload scripts:** Ctrl+Shift+R
- **Clear console:** Clear button in Output panel
- **Check errors:** Look for red text in Output

---

## What to Do After Testing

1. Fill out the test scenarios in **TESTING_GUIDE.md**
2. Document any bugs or issues found
3. Note performance metrics (FPS, etc.)
4. Provide feedback on flight feel

Based on results:
- ✅ **All Pass** → Proceed to Phase 2 (SDF Rendering)
- ⚠️ **Minor Issues** → Note and continue, fix in polish
- ❌ **Major Issues** → Debug and retest

---

## Ready to Launch? 🚀

If you've reviewed this checklist and everything looks good:

1. Open Godot
2. Load the Remnant project
3. Press **F5**
4. Start testing with **TESTING_GUIDE.md**

**Good luck, pilot!**

---

*Checklist completed: ____________*

*Tester: ____________*

*Ready for testing: YES / NO*
