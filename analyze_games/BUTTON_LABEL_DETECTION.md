# Button Label Detection: Identifying Dual-Purpose Controls

## Overview

The enhanced `analyze_controls` tool now identifies games with **dual-purpose buttons** and other non-obvious control mappings. These are games where:

- A single button serves multiple functions (e.g., "Left Whip" AND "Player 1 Start")
- Control layouts are confusing or non-standard
- The same physical button does different things in different contexts
- Button assignments don't match player expectations

This feature addresses a critical gap: detecting games that appear to have standard controls in MAME's XML output but actually have complex, confusing button assignments.

## The Problem It Solves

### Example: Indiana Jones and the Temple of Doom (indytemp)

**What MAME's XML says:**
```
Players: 1
Controls: 1 button, 8-way joystick
```

**What this means in-game:**
```
Button 1: "Left Whip" (attack button)
Button 1: "Player 1 Start" (game start - same button!)
```

**The User Experience Problem:**
A player presses the button to attack. After dying, they try to start a new game but don't realize the attack button ALSO starts the game. They might think the game is broken or unresponsive.

## How It Works

### Dual-Purpose Button Detection

The tool maintains a **Known Games Database** (`KNOWN_DUAL_BUTTON_GAMES.yml`) that documents games with known problematic button mappings.

The enhanced analyze_controls tool:

1. **Loads the known games database**
   - Contains games with documented button issues
   - Each game entry includes:
     - Button labels and assignments
     - Issue type (DUAL_PURPOSE_BUTTON, ASYMMETRIC_CONTROLS, etc.)
     - Recommendations for fixing

2. **Checks each favorite game** against the database
   - If a match is found, flags it as problematic
   - Includes specific button details in the report

3. **Generates enhanced report** with three sections:
   - Known dual-purpose/complex buttons (highest priority)
   - Games with special controls (paddle, pedal, trackball)
   - Complete game listing

## Report Output

### Console Output
```
Analysis complete! Report written to: /opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt
Games analyzed: 47
Games with special controls: 3
Games with KNOWN DUAL-PURPOSE/COMPLEX BUTTONS: 1

⚠ GAMES WITH KNOWN DUAL-PURPOSE BUTTONS:
  - indytemp (Indiana Jones and the Temple of Doom)
    Issue: DUAL_PURPOSE_BUTTON
    Recommendation: Create custom INI file to separate start button from attack if possible

Games needing custom mapping (special controls):
  - spyhunt
  - breakout
  - asteroid
```

### Report File Sections

#### Section 1: Known Problematic Games

```
⚠ GAMES WITH KNOWN DUAL-PURPOSE BUTTONS OR COMPLEX MAPPINGS
============================================================
These games have buttons that serve multiple functions, confusing control layouts,
or other non-obvious input mappings. Manual testing and custom INI files may be needed.

indytemp - Indiana Jones and the Temple of Doom
  Issue Type: DUAL_PURPOSE_BUTTON
  Description: Button 1 serves both as the attack button and game start
  Recommendation: Create custom INI file to separate start button from attack if possible
  Problematic Buttons:
    Button 1: Left Whip AND Player 1 Start
```

#### Section 2: Special Controls
(Paddle, pedal, trackball games - same as before)

#### Section 3: Complete Listing
(All games analyzed - same as before)

## How to Verify Button Labels

If you want to manually verify button assignments for a game:

1. **Run the game**:
   ```bash
   mame <gamename>
   ```

2. **Access MAME menu**: Press `[I]` during gameplay

3. **Navigate to Input settings**: 
   - Look for "Input (this game)" or "Input (general)"

4. **Check button definitions**:
   - You'll see entries like:
     - "Left Whip"
     - "Player 1 Start"
     - If both labels appear for the same button, that's a dual-purpose button

5. **Document the findings**:
   - Note the exact button number
   - List all labels
   - Check if this affects gameplay

6. **Update the database**:
   - Add to `KNOWN_DUAL_BUTTON_GAMES.yml`
   - Include verified date and MAME version

## The Database: KNOWN_DUAL_BUTTON_GAMES.yml

### Format

```yaml
games:
  gamename:
    name: "Full Game Title"
    buttons:
      button1:
        - "Label 1"
        - "Label 2"
    issue: "DUAL_PURPOSE_BUTTON" | "ASYMMETRIC_CONTROLS" | ...
    description: "What makes this game special or confusing"
    recommendation: "What the user should do about it"
    verified: true
    verified_date: "2025-01-04"
    mame_version: "0.256+"
    notes: "Any additional notes"
```

### Issue Categories

| Category | Meaning | Example |
|----------|---------|---------|
| `DUAL_PURPOSE_BUTTON` | Same button for 2+ distinct actions | Button 1: "Fire" AND "Start" |
| `ASYMMETRIC_CONTROLS` | Different buttons available per player | Player 1 has 5 buttons, Player 2 has 3 |
| `HIDDEN_BUTTONS` | Game has buttons not reported in control count | Control says 1 button, has 3 in-game |
| `UNUSUAL_MAPPING` | Non-standard arcade control layout | Action buttons arranged differently |
| `MULTI_FUNCTION` | Buttons change behavior based on game state | Button mode switching |
| `PLATFORM_SPECIFIC` | Control layout varies by hardware version | TTL vs LSI motherboard differences |

### Current Database

As of 2025-01-04:

- **indytemp**: Button 1 = "Left Whip" AND "Player 1 Start"

More games will be discovered as you test your collection.

## How to Contribute

When you discover a new dual-purpose button game:

1. **Verify in MAME**
   - Run the game
   - Press [I] to open menu
   - Check Input settings
   - Document button labels

2. **Update the database**
   ```yaml
   newgame:
     name: "Game Full Title"
     buttons:
       button1:
         - "Label from MAME menu"
         - "Another label if dual-purpose"
     issue: "DUAL_PURPOSE_BUTTON"  # or appropriate category
     description: "Brief explanation of the issue"
     recommendation: "What should be done"
     verified: true
     verified_date: "2025-01-04"
     mame_version: "0.256+"
   ```

3. **Test your fix** (if creating custom INI)
   - Note which approaches work
   - Add to recommendations

4. **Share findings**
   - Document for other users
   - Helps community maintain the database

## Integration with Custom INI Files

Once a problematic game is identified, you can create a custom INI file:

### Example: indytemp custom INI

**Location**: `/opt/retropie/emulators/mame/ini/indytemp.ini`

**Content**:
```ini
; Custom mapping for Indiana Jones and the Temple of Doom
; Button 1 normally: Left Whip AND Player 1 Start (confusing!)

; Option 1: Keep default, document in system
; players know button 1 does both functions

; Option 2: Try to separate via RetroArch core options
; (if MAME core supports input remapping)

; Option 3: Custom key mapping in standalone MAME
; This would require MAME configuration
```

The exact solution depends on:
- Whether you're using RetroArch MAME core or standalone MAME
- What flexibility the MAME version provides
- Whether you have physical buttons to spare

See [EXTENSION_EXAMPLES.cpp](./EXTENSION_EXAMPLES.cpp) for code patterns to auto-generate these INI files.

## Future Enhancements

### Automatic Detection Heuristics

The tool can be enhanced to automatically flag games likely to have issues:

```cpp
bool hasComplexControls(const GameControlInfo& info)
{
    // Flag games with suspicious patterns
    
    // Pattern 1: Very few buttons with multiple functions
    if (info.controls[0].buttons <= 2) {
        // Likely dual-purpose - flag for manual review
        return true;
    }
    
    // Pattern 2: Players with asymmetric button counts
    if (info.playerCount > 1) {
        int btn1 = info.controls[0].buttons;
        int btn2 = info.controls[1].buttons;
        if (btn1 != btn2) {
            // Different button counts - asymmetric
            return true;
        }
    }
    
    // Pattern 3: Button + Start both possible
    // (harder to detect without semantic info)
    
    return false;
}
```

### YAML Database Parsing

Currently the database is hardcoded. Could be enhanced to:
- Parse actual YAML/JSON file
- Support more games in database
- Make community contributions easier

### Analysis Recommendations

Could expand to automatically suggest:
- Which controller to use (wheel for paddle, etc.)
- Whether to remap or skip the game
- Difficulty level for getting controls right

## Technical Implementation

### Code Changes to analyze_controls.cpp

1. **New data structures**:
   ```cpp
   struct ButtonLabelInfo  // Single button's labels/issues
   struct KnownGameInfo    // All info about a known problematic game
   ```

2. **Database loading**:
   ```cpp
   map<string, KnownGameInfo> loadKnownGamesDatabase()
   // Loads known problematic games
   ```

3. **Report generation**:
   - New section: "GAMES WITH KNOWN DUAL-PURPOSE BUTTONS"
   - Enhanced console output
   - Matches flagged games against database

### Database File

**Location**: `KNOWN_DUAL_BUTTON_GAMES.yml`
**Format**: YAML (human-readable, easy to edit)
**Updates**: Add new entries as games are discovered

## Files Modified/Created

| File | Status | Purpose |
|------|--------|---------|
| `analyze_controls.cpp` | ✅ Updated | Added button label detection |
| `KNOWN_DUAL_BUTTON_GAMES.yml` | ✅ Created | Database of known problematic games |
| `BUTTON_LABELS_ANALYSIS.md` | ✅ Created | Technical analysis of limitations |

## Summary

The enhanced analyze_controls tool now:
- ✅ Identifies games with known dual-purpose button issues
- ✅ Maintains a database of problematic games
- ✅ Flags these in the report with specific button details
- ✅ Provides recommendations for each issue
- ✅ Makes it clear which games need manual review

This addresses the limitation where games like indytemp appeared "normal" in the analysis but actually had confusing, dual-purpose button mappings that needed special attention.

**Result**: Users now get a complete picture of which games need custom button mapping due to non-obvious control assignments.
