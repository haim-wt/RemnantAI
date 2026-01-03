# Flight Demo Testing Guide

**Phase 1.2 - Playable Flight Demo**

---

## Pre-Flight Checklist

Before running the demo, ensure you have:
- [x] Godot 4.5 or later installed
- [x] Project opened in Godot
- [x] All scripts loaded without errors

---

## Starting the Flight Demo

1. **Open Godot** and load the Remnant project
2. **Press F5** or click the "Play" button
3. The flight test scene will automatically load
4. Your mouse will be captured for flight control

---

## Test Scenarios

### 1. Basic Flight Controls ✈️

**Objective:** Verify all thrust inputs work correctly

**Steps:**
1. Press **W** - Ship should thrust forward
2. Press **S** - Ship should thrust backward
3. Press **A** - Ship should thrust left
4. Press **D** - Ship should thrust right
5. Press **Space** - Ship should thrust up
6. Press **Ctrl** - Ship should thrust down

**Expected Result:** Ship accelerates smoothly in each direction in Newtonian fashion (velocity continues after releasing key)

**Pass/Fail:** ___________

---

### 2. Rotation Controls 🔄

**Objective:** Test pitch, yaw, and roll

**Steps:**
1. **Move mouse up/down** - Ship should pitch
2. **Move mouse left/right** - Ship should yaw
3. **Press Q** - Ship should roll left
4. **Press E** - Ship should roll right

**Expected Result:** Smooth rotation control, ship continues rotating slightly after input stops (Newtonian angular momentum)

**Pass/Fail:** ___________

---

### 3. Flight Assist System 🤖

**Objective:** Verify all assist levels work and provide progressive help

**Steps:**
1. Build up some speed with **W**
2. Press **T** to cycle assist level (watch HUD for level indicator)
3. Try turning while moving at each level:
   - **OFF** - Pure drift, difficult to control
   - **LOW** - Rotation dampens, still drifts
   - **MEDIUM** - Tries to maintain heading
   - **HIGH** - Ship velocity follows nose direction

**Expected Result:**
- OFF: Ship drifts like a spaceship should, very hard to control
- HIGH: Ship is much easier to fly, velocity follows where you point
- Colors change on HUD: OFF=Red, LOW=Yellow, MEDIUM=Light Blue, HIGH=Green

**Pass/Fail:** ___________

---

### 4. Boost System ⚡

**Objective:** Test boost activation and fuel management

**Steps:**
1. Hold **Shift** while pressing **W**
2. Watch the boost bar deplete
3. Release **Shift** and observe regeneration
4. Try to deplete boost completely

**Expected Result:**
- Ship accelerates faster when boosting (1.5x multiplier)
- Boost bar turns cyan when active
- Bar depletes while boosting
- Bar regenerates slowly when not boosting
- Cannot boost when fuel is empty

**Pass/Fail:** ___________

---

### 5. Camera System 📷

**Objective:** Test both camera modes

**Steps:**
1. Start in third-person view (default)
2. Fly around, observe camera follows smoothly
3. Press **C** to switch to first-person
4. Look around, camera should be locked to ship
5. Press **C** to switch back
6. Accelerate to high speed, observe FOV increases

**Expected Result:**
- Third-person: Camera follows at distance, smooth lag
- First-person: Cockpit view, instant rotation tracking
- FOV widens at high speeds (speed blur effect)
- HUD updates to show current camera mode

**Pass/Fail:** ___________

---

### 6. HUD Information 📊

**Objective:** Verify all HUD elements display correctly

**Steps:**
1. Fly around and watch HUD update
2. Check each element:
   - **Speed** - Shows m/s, changes color at high speed
   - **Velocity** - Shows F/R/U components
   - **Assist Level** - Updates when pressing T
   - **Camera Mode** - Updates when pressing C
   - **G-Force** - Shows acceleration forces
   - **Boost Bar** - Depletes and refills

**Expected Result:**
- All values update in real-time
- Speed turns yellow >300 m/s, red >450 m/s
- Values are readable and make sense

**Pass/Fail:** ___________

---

### 7. Collision Detection 💥

**Objective:** Test asteroid collision

**Steps:**
1. Locate nearest asteroid (brown/gray sphere)
2. Fly directly at it at moderate speed
3. Observe collision behavior
4. Try grazing an asteroid at high speed

**Expected Result:**
- Ship bounces off asteroids realistically
- Physics feels solid
- No clipping through asteroids
- High-speed collisions are dramatic

**Pass/Fail:** ___________

---

### 8. Debug Visualization 🔍

**Objective:** Verify debug vectors display correctly

**Steps:**
1. Debug visualization should be active by default
2. Observe colored vectors from ship:
   - **Cyan arrow** - Velocity vector (where you're going)
   - **Orange arrow** - Thrust vector (where you're pushing)
   - **Green line** - Trajectory prediction
   - **RGB axes** - Ship orientation (Red=Right, Green=Up, Blue=Back)

**Expected Result:**
- All vectors visible and color-coded
- Vectors scale appropriately
- Trajectory shows predicted path
- Can toggle visibility (if implemented)

**Pass/Fail:** ___________

---

### 9. Performance Test 🚀

**Objective:** Ensure smooth performance

**Steps:**
1. Enable FPS counter in Godot (Debug → Visible FPS)
2. Fly around the arena at various speeds
3. Fly close to multiple asteroids
4. Make rapid maneuvers

**Expected Result:**
- Maintains 60+ FPS on target hardware
- No stuttering or hitching
- Smooth camera movement
- Responsive controls (<100ms latency)

**Current FPS:** ___________

**Pass/Fail:** ___________

---

### 10. Edge Cases & Stress Tests 🔬

**Objective:** Find bugs or issues

**Steps:**
1. **High Speed Test:** Accelerate to max speed (500+ m/s)
   - Ship should handle correctly
   - Collision detection still works

2. **Rapid Rotation:** Spin as fast as possible
   - No camera glitches
   - Physics stays stable

3. **Multi-Input Test:** Press many keys at once
   - No conflicts
   - Ship responds correctly

4. **Mouse Release Test:** Press **ESC**
   - Mouse releases
   - Controls pause appropriately
   - Press ESC again to recapture

**Issues Found:**
_________________________________
_________________________________
_________________________________

---

## Known Issues (Expected)

The following are **known limitations** in this prototype:

1. ⚠️ **Placeholder Asteroids** - Simple sphere meshes (SDF rendering in Phase 2)
2. ⚠️ **No Damage System** - Collisions don't damage ship yet
3. ⚠️ **No Audio** - Silent flight (audio in later phase)
4. ⚠️ **Simple Ship Model** - Box mesh placeholder
5. ⚠️ **No Other Ships** - Single player test only

---

## Controls Reference

| Input | Action |
|-------|--------|
| **W** | Thrust Forward |
| **S** | Thrust Backward |
| **A** | Thrust Left |
| **D** | Thrust Right |
| **Space** | Thrust Up |
| **Ctrl** | Thrust Down |
| **Mouse** | Pitch & Yaw |
| **Q** | Roll Left |
| **E** | Roll Right |
| **Shift** | Boost |
| **T** | Cycle Flight Assist |
| **C** | Toggle Camera Mode |
| **ESC** | Pause / Release Mouse |

---

## Troubleshooting

### Issue: Mouse not captured
**Solution:** Click in game window, or press ESC twice

### Issue: Ship not visible
**Solution:** Camera might be inside ship - press C to switch views

### Issue: Controls not responding
**Solution:** Ensure game window has focus

### Issue: Low FPS
**Solution:** Check Debug output for errors, verify graphics settings

### Issue: Ship spinning uncontrollably
**Solution:** This is expected with Assist OFF - press T to cycle to HIGH

---

## Success Criteria

For Phase 1.2 to be considered complete, the demo must:

- ✅ All thrust inputs work (6DOF)
- ✅ Flight assist noticeably improves control
- ✅ Both camera modes functional
- ✅ HUD displays accurate real-time data
- ✅ Collision detection works correctly
- ✅ Runs at 60+ FPS
- ✅ Controls feel responsive

---

## Feedback Template

After testing, provide feedback on:

**What worked well:**
_________________________________
_________________________________

**What needs improvement:**
_________________________________
_________________________________

**Flight feel (1-10):** _____

**Control responsiveness (1-10):** _____

**Visual clarity (1-10):** _____

**Overall impression (1-10):** _____

**Ready for Phase 2?** YES / NO

---

## Next Steps After Testing

Based on test results:

1. **If all tests pass:** Proceed to Phase 2 (SDF Asteroid Rendering)
2. **If minor issues:** Note them and proceed, fix in polish phase
3. **If major issues:** Debug and retest before continuing

**Testing completed by:** _______________

**Date:** _______________

**Result:** PASS / FAIL / NEEDS WORK
