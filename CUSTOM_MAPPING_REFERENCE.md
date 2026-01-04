# CUSTOM MAPPING REFERENCE: What Your 51 Games Need

## The Two-Tier Analysis

Your arcade button mapping challenge breaks into two tiers:

### Tier 1: BUTTON COUNT MISMATCH (61% of games - 31 games)
Most arcade panels: 1-2 buttons per player  
Many games need: 3-6+ buttons

**These games are effectively unplayable without button remapping strategies:**
- Using shift/modifier keys to create multiple button combinations
- Using joystick direction+button combinations
- Creating complex key mappings in RetroArch INI files

**Severity: HIGH** - Without solving this, ~60% of your games won't work properly

### Tier 2: DUAL-PURPOSE BUTTONS (4-8% of games - 2-4 games)
Same physical button triggers multiple game functions

**Examples:**
- Button during gameplay = attack/movement
- Same button during menu = select/start

**Severity: MEDIUM** - These games work, but have awkward control conflicts

---

## Games by Control Category

### ✅ STANDARD 1-2 BUTTON GAMES (~20 games)
These work great on basic arcade panels:

```
pacman           dkong            invaders
galaga           digdug           frogger
galaxian         penngo           centiped
milliped         btime            junglek
```

No special mapping needed - use default controls.

---

### ⚠️ MULTI-BUTTON GAMES (31 games - NEED CUSTOM MAPPING)

#### Fighting Games (6 buttons)
```
sf              Street Fighter (light/medium/hard × punch/kick)
sf2             Street Fighter II
mk              Mortal Kombat (punch/kick/block × light/medium/heavy)
superbug        Super Bug variant
```
**Challenge:** Most complex to remap - consider using direction keys as modifiers

#### Arcade Shooters & Action (4-5 buttons)
```
starwars        Star Wars (4 buttons + stick)
defender        Defender (5 buttons)
asteroid        Asteroids (5 buttons)
astdelux        Asteroid Deluxe (5 buttons)
spyhunt         Spy Hunter (5 buttons)
sprint1         Sprint 1 (5 buttons + dial)
crusnusa        Cruis'n USA (8 buttons + paddle + pedal)
```

#### Sports/Control Games (3-4 buttons)
```
missile         Missile Command (3 buttons + trackball)
trackfld        Track & Field (3 buttons)
gravitar        Gravitar (3 buttons)
llander         Lunar Lander (3 buttons)
spacduel        Space Duel (3 buttons)
punchout        Mike Tyson's Punch-Out (3 buttons)
```

---

### 🔴 DUAL-PURPOSE BUTTON GAMES (4-5 games - EXTRACTED FROM MAME)

These have specific conflicts extracted from MAME 0.276 source code:

#### 1. **indytemp** - Indiana Jones and the Temple of Doom
```
Button 1 = "Left Whip" (gameplay) + "Player 1 Start" (menu)
Button 2 = "Right Whip" (gameplay) + "Player 2 Start" (menu)
Issue: Attacking during gameplay can accidentally trigger menus
```

#### 2. **marble** - Marble Madness
```
Button 1 = "Left" (movement) + "Player 1 Start" (menu)
Button 2 = "Right" (movement) + "Player 2 Start" (menu)
Issue: Movement controls trigger menu selections
```

#### 3. **peterpak** - Peter Pack Rat
```
3-button game (unusual complexity):
Button 1 = "Left Throw" + "Player 1 Start"
Button 2 = "Jump"
Button 3 = "Right Throw" + "Player 2 Start"
Issue: 3-button requirement PLUS dual-purpose conflicts
```

#### 4. **roadrunn** - Road Runner
```
4-button game (maximum complexity):
Button 1 = "Left Hop" + "Player 1 Start"
Button 2 = "Right Hop" + "Player 2 Start"
Button 3 = "Special Weapon"
Button 4 = "Lasers"
Issue: 4-button requirement PLUS dual-purpose conflicts
```

---

### 🎮 NON-JOYSTICK CONTROL GAMES (~10 games)

These require special hardware or emulation features:

#### Trackball Games
```
marble          Marble Madness (also dual-purpose buttons)
missile         Missile Command (also 3 buttons)
```
**Need:** Trackball controller OR mouse emulation in RetroArch

#### Paddle Games
```
breakout        Breakout
crusnusa        Cruis'n USA (paddle + pedal combination)
outrun          Out Run (paddle + pedal combination)
polepos         Pole Position (dial + pedal combination)
```
**Need:** Analog paddle control OR mouse/analog emulation

#### Stick/Joystick Games
```
redbaron        Red Baron (joystick stick)
robotron        Robotron: 2084 (dual-joystick)
```
**Need:** Special stick controller OR keyboard mapping for complex movement

---

## Impact Assessment

### Games You Can Play TODAY (with default MAME mapping):
~20 games - Standard joystick + 1-2 buttons

### Games That Need Button Remapping Work:
31 games - 3+ buttons requiring creative mapping

**Time estimate to remap one game:** 15-30 minutes  
**Time to remap all 31:** 8-15 hours of testing/tweaking

### Games That Need Special Hardware/Features:
~10 games - Trackball, paddle, or dual-stick support

---

## The Tool: analyze_controls

**Location:** `/home/danc/IvarArcade/analyze_games/analyze_controls`

**What it does:**
- Analyzes all 51 games from your gamelist
- Checks button requirements from MAME
- Identifies dual-purpose button conflicts (from MAME source)
- Categorizes all special controls
- Generates detailed report

**Run it:**
```bash
cd /home/danc/IvarArcade/analyze_games
./analyze_controls
```

**Output:** `/opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt`

---

## Strategy for Success

### Phase 1: Accept Limitations
- ~20 games work perfectly on your panel
- ~10 games might not be playable (trackball/paddle only)
- 31 games need creative remapping solutions

### Phase 2: Pick a Strategy
**Option A - Single Modifier Button:**
- Use one key as "shift" to double button functionality
- Button 1 + Shift = Button 3
- Limits you to 2 physical buttons → 4 virtual buttons max

**Option B - Direction Keys as Modifiers:**
- Up+Button = Button 3
- Down+Button = Button 4
- Left+Button = Button 5
- Right+Button = Button 6
- Best for fighting games

**Option C - Multiple Physical Buttons (if panel supports it):**
- Add 3-4 more buttons to your panel
- Map game 3+ buttons directly
- Most expensive but cleanest solution

### Phase 3: Test Systematically
1. Start with easy games (3-button requirement)
2. Work up to complex games (6-button fighting games)
3. Save successful INI/CFG files as templates
4. Document what works for reuse

---

## Files and Documentation

| File | Purpose |
|------|---------|
| analyze_controls.cpp | Source code - identified both issues |
| analyze_controls | Binary - generates the report |
| CONTROL_MAPPING_REPORT.txt | Generated report with full details |
| BUTTON_ANALYSIS_EXPANDED.md | Detailed analysis explanation |
| IMPLEMENTATION_SUMMARY.md | What changed and why |
| HONEST_ASSESSMENT.md | Scope realization document |

---

## Summary

**You were right:** The dual-purpose button thing is important, but **button COUNT mismatch is the real problem**.

**31 of your 51 games (61%)** have a fundamental mismatch between what buttons they need and what your arcade panel provides.

The analyze_controls tool now identifies both:
1. **Primary issue:** Multi-button games needing remapping
2. **Secondary issue:** Dual-purpose button conflicts

This gives you a complete picture of the customization work needed.
