# Verifying Button Labels in MAME

## Quick Start: Find Button Labels for Any Game

### Step-by-Step Process

#### 1. Run the game
```bash
mame <gamename>
```

Example:
```bash
mame indytemp
```

#### 2. Start a game
- Move through menu screens
- Press coin/start buttons if needed
- Get the game running or to a playable state

#### 3. Open MAME menu
Press the **[I]** key (capital I) on your keyboard

You'll see the MAME menu overlay.

#### 4. Navigate to Input settings
Look for:
- "Input (this game)" - Game-specific input settings
- "Input (general)" - General MAME input settings

Choose **"Input (this game)"** to see this specific game's button definitions.

#### 5. View button definitions
You'll see a list of input actions:
```
Joystick Up
Joystick Down
Joystick Left
Joystick Right
Button 1
Button 2
Button 3
...
Player 1 Start
Player 2 Start
Coin Insert
...
```

#### 6. Look for dual-purpose buttons
Check if any entry has **multiple labels** on the same line, like:
```
Button 1: Left Whip / Player 1 Start
```

The "/" or "and" indicates that pressing that button does MULTIPLE things.

#### 7. Document findings
Write down:
- Game name
- Button number(s) that are dual-purpose
- All labels for each button
- Date and MAME version

### Example: Indiana Jones and the Temple of Doom

**Running the game:**
```bash
mame indytemp
```

**After starting a game, press [I]:**
```
MAME Menu
───────────────────────────
Input (this game)
Input (general)
Analog...
Network...
...
```

**Select "Input (this game)":**
```
Joystick Up/Down/Left/Right  [8-way joystick]
Button 1                     [Fire attack / Whip]
Player 1 Start               [Start game]
Coin Insert                  [Add credit]
```

**Discovery:** Button 1 appears in MAME's input menu but so does "Player 1 Start"
as a separate entry... HOWEVER, when you look at the actual ROM settings and
try to map them, both can map to the same physical input (button 1).

**Result:** In actual game play, Button 1 = "Left Whip/Player 1 Start"

This dual-purpose nature is the issue that needs to be documented.

## Why Button Labels Matter

### The Problem for Players

1. **First time playing indytemp:**
   - Player presses button to attack (Left Whip)
   - Game registers the action
   - Player dies and wants to start a new game
   - Player presses the button again, expecting to start
   - **But nothing happens!** (Or it attacks instead of starting)
   - Player thinks the game is broken or unresponsive

2. **The solution:**
   - Documentation needs to say: "Button 1 also starts the game"
   - OR a custom INI file needs to separate these functions
   - OR the control scheme documentation needs to be very clear

### Why MAME's XML Doesn't Capture This

MAME's `-listxml` output shows:
```xml
<input players="1" coins="3">
    <control type="joy" buttons="1" ways="8"/>
</input>
```

It says "1 button" but doesn't explain that this button does multiple things.
The semantic meaning comes from the ROM source code's PORT definitions, which
aren't easily exported in the XML format.

## Documenting Your Findings

### For Your Own Reference

Create a text file for each game with issues:

**File**: `docs/GAME_CONTROLS_VERIFIED.txt`

```
Game: Indiana Jones and the Temple of Doom (indytemp)
Verified Date: 2025-01-04
MAME Version: 0.256
Console: RetroPie / Pi5

Reported by analyze_controls:
  Players: 1
  Joystick: 8-way
  Buttons: 1

Manual verification (MAME [I] menu):
  Joystick: 8-way
  Button 1: "Left Whip" and "Player 1 Start" (DUAL PURPOSE)
  Coin Insert: Works as expected
  Service Mode: Available via DIP switch

Issue: Button 1 serves two distinct functions
       - During gameplay: attacks with left whip
       - At start screen: begins new game

Resolution: Game is working as designed. Controls are confusing
            but not broken. Players need clear documentation about
            this dual-purpose button.

Custom INI created: /opt/retropie/emulators/mame/ini/indytemp.ini
```

### For the Community Database

Update `KNOWN_DUAL_BUTTON_GAMES.yml`:

```yaml
  indytemp:
    name: "Indiana Jones and the Temple of Doom"
    buttons:
      button1:
        - "Left Whip"
        - "Player 1 Start"
    issue: "DUAL_PURPOSE_BUTTON"
    description: "Button 1 is used for both attacking (Left Whip) and starting the game (Player 1 Start). This can confuse new players who don't realize the attack button also starts the game."
    recommendation: "If possible, create a custom INI file to map 'Player 1 Start' to a different button. Otherwise, document this behavior clearly for players."
    verified: true
    verified_date: "2025-01-04"
    mame_version: "0.256+"
    notes: "Verified in MAME via [I] menu. Button assignment is intentional per MAME ROM definition."
```

## What to Look For

### Common Problem Patterns

#### Pattern 1: Dual-Purpose Buttons
```
Button 1: [Label1] / [Label2]
```
Example: "Fire / Coin Insert" - same button does attack AND adds credit

#### Pattern 2: Mode-Switching Buttons
```
Button 1: [Action] (toggles to different action in certain game states)
```
Example: Button changes function when in menu vs gameplay

#### Pattern 3: Asymmetric Controls
```
Player 1: Button 1, Button 2, Button 3
Player 2: Button 1, Button 2
```
Different players have different button counts available

#### Pattern 4: Hidden Buttons
Game's control count says "3 buttons" but menu shows 5 available

#### Pattern 5: Contextual Buttons
```
Button 1: [Action A] (during gameplay)
Button 1: [Action B] (during menu)
```

## How to Create a Workaround

### Option 1: Document It
Add to game notes:
```
CONTROLS: 
- Joystick: Move left/right
- Button 1: Attack / Start Game
  (Button 1 also starts the game - press to begin)
```

### Option 2: Create Custom INI
**File**: `/opt/retropie/emulators/mame/ini/indytemp.ini`

```ini
; Custom mapping for Indiana Jones Temple of Doom
; Button 1 is dual-purpose: Attack + Start Game

; Comment out to use default (dual-purpose):
; joystick_map s8.4s8.44s8.4445

; Try alternate button for start (if MAME core supports it):
; ui_select button1    ; OR another available button/key
```

### Option 3: Remap in RetroArch (if using RetroArch core)
- Load game in RetroArch
- Core menu → Input settings
- Try to create separate mappings for Start vs Attack
- (Success depends on core configuration options)

## Testing Your Workaround

After creating a custom INI or mapping:

1. **Run the game**
   ```bash
   mame indytemp
   ```

2. **Test attack button**
   - Verify Left Whip works
   - Verify attack action responds correctly

3. **Test start button**
   - Die and see if you can start a new game
   - Verify start button works independently if remapped

4. **Check for side effects**
   - Did remapping break something else?
   - Are controls still responsive?

5. **Document the result**
   - Success: describe what worked
   - Failure: describe what didn't work
   - This helps future troubleshooting

## Tools and Commands

### Quick Button Check Script

```bash
#!/bin/bash
# Check button definitions for a game

GAME=$1
if [ -z "$GAME" ]; then
  echo "Usage: $0 <gamename>"
  echo "Example: $0 indytemp"
  exit 1
fi

echo "=== Starting $GAME for input verification ==="
echo "After game starts, press [I] to open MAME menu"
echo "Navigate to Input (this game) to see button definitions"
echo "Look for entries with '/' or 'and' indicating dual-purpose buttons"
echo ""

mame "$GAME"
```

Save as `check_buttons.sh` and run:
```bash
chmod +x check_buttons.sh
./check_buttons.sh indytemp
```

### Batch Verification

To systematically check your favorite games:

```bash
#!/bin/bash
# Verify buttons for multiple games

GAMES="indytemp defender spyhunt pacman dkong"

for game in $GAMES; do
  echo "=============================="
  echo "Checking: $game"
  echo "=============================="
  echo "Starting game... (press [I] when ready)"
  mame "$game" 2>/dev/null
  echo ""
  echo "Did you find any dual-purpose buttons? (y/n)"
  read -r found_issues
  
  if [ "$found_issues" = "y" ]; then
    echo "Add to KNOWN_DUAL_BUTTON_GAMES.yml"
  fi
  echo ""
done
```

## Summary

### Quick Reference

| Task | Command | Notes |
|------|---------|-------|
| Check one game | `mame gamename` then [I] | Press I during gameplay |
| View Input menu | Navigate to "Input (this game)" | Look for "/" or "and" |
| Document findings | Edit `KNOWN_DUAL_BUTTON_GAMES.yml` | Include all details |
| Test workaround | Run game and test buttons | Verify each function works |
| Share findings | Update database file | Help other users |

### Checklist for Each Game

- [ ] Game starts successfully
- [ ] Pressed [I] to open MAME menu
- [ ] Found "Input (this game)" section
- [ ] Reviewed all button definitions
- [ ] Looked for "/" or "and" indicators
- [ ] Documented any dual-purpose buttons
- [ ] Noted MAME version and date
- [ ] Tested button functions work as expected
- [ ] Created custom INI if needed
- [ ] Tested workaround (if created)
- [ ] Updated community database
- [ ] Documented recommendations

## Troubleshooting

### Problem: Can't open MAME menu
- Confirm you pressed [I] (capital I), not [l] (lowercase L)
- Try different key: sometimes menu key varies by MAME build
- Check MAME configuration: `mame -cc` to create/edit config

### Problem: No "Input (this game)" section
- Menu structure varies by MAME version
- Look for "Input settings" or similar
- Try pressing [O] for general options instead of [I]

### Problem: Button labels don't match documentation
- MAME version might be different
- ROM version (set) might affect input definitions
- Check MAME's default key mappings: `mame -listkeys`

### Problem: Game has no obvious dual-purpose buttons
- Some issues are subtle - read each label carefully
- Some games have asymmetric controls (different per player)
- Some games have mode-switching (different in menu vs gameplay)
- Don't add to database if no real issue found

## More Information

See also:
- [BUTTON_LABEL_DETECTION.md](./BUTTON_LABEL_DETECTION.md) - How detection works
- [KNOWN_DUAL_BUTTON_GAMES.yml](./KNOWN_DUAL_BUTTON_GAMES.yml) - Database of known games
- [BUTTON_LABELS_ANALYSIS.md](./BUTTON_LABELS_ANALYSIS.md) - Technical limitations and solutions
