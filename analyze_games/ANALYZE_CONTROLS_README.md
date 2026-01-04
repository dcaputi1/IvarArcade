# analyze_controls: Control Mapping Analysis Tool

## Overview

`analyze_controls.cpp` extends the game analysis framework from `analyze_games.cpp` to systematically discover which of your favorite arcade games use non-standard controls that might require custom button/joystick mapping.

This tool parses MAME's XML output to extract detailed control information for each game, generating a comprehensive report identifying games with:
- Non-joystick controls (paddle, pedal, trackball, etc.)
- Unusual button configurations
- Multi-player controls that differ between players

## What the Tool Does

1. **Iterates through favorite games** from your EmulationStation gamelist.xml (same as analyze_games)
2. **Queries MAME XML** for each game using `mame -listxml <shortname>`
3. **Parses control information** from the `<input><control>` elements:
   - Control type (joy, paddle, pedal, trackball, etc.)
   - Button count
   - Joystick ways (2, 4, 8)
   - Player assignments
4. **Identifies "special" games** that need custom mapping consideration
5. **Generates two reports**:
   - Summary of games with special controls
   - Complete listing of all analyzed games and their controls

## Understanding Control Types

### Standard Joystick Variants
- `joy` - Generic joystick (most common)
- `joy2way` - Horizontal or vertical only
- `joy4way` - 4-direction (up, down, left, right)
- `joy8way` - 8-direction (includes diagonals)

### Special Controllers
- `paddle` - Rotary control (e.g., Breakout, Pong)
- `pedal` - Foot pedal (e.g., racing games)
- `trackball` - Roller ball input
- `lightgun` - Light gun aiming
- `dial` - Rotary dial with different sensitivity
- `positional` - Directional pad
- `button` - Just button inputs, no directional

### Example MAME XML

```xml
<!-- Standard 4-way joystick with 1 button -->
<input players="1" coins="2">
    <control type="joy" player="1" buttons="1" ways="4"/>
</input>

<!-- Joystick with 5 buttons (like Street Fighter) -->
<input players="2" coins="2">
    <control type="joy" player="1" buttons="5" ways="8"/>
    <control type="joy" player="2" buttons="5" ways="8"/>
</input>

<!-- Paddle game (Breakout) -->
<input players="1">
    <control type="paddle" buttons="1" minimum="52" maximum="180" sensitivity="40" keydelta="10"/>
</input>

<!-- Racing game with steering wheel and pedal -->
<input players="1" coins="2" tilt="yes">
    <control type="paddle" buttons="5" minimum="52" maximum="180" sensitivity="40" keydelta="10"/>
    <control type="pedal" minimum="48" maximum="255" sensitivity="100" keydelta="10"/>
</input>
```

## Building the Tool

```bash
cd /home/danc/IvarArcade/analyze_games
make clean
make
```

This compiles both `analyze_games` and the new `analyze_controls` executable.

## Running the Tool

```bash
./analyze_controls
```

The tool will:
1. Load your favorite games from `/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml`
2. Query MAME for each game's control info
3. Generate a report at `/opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt`
4. Print a summary to stdout

### Example Output

```
Analysis complete! Report written to: /opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt
Games analyzed: 47
Games with special controls: 3

Games needing custom mapping:
  - spyhunt
  - breakout
  - asteroid
```

## Understanding the Report

The generated report has three sections:

### 1. SUMMARY
```
Total games analyzed: 47
Games with special controls: 3
```

### 2. GAMES WITH SPECIAL CONTROLS
Lists only the games that need custom mapping consideration:

```
spyhunt
  Display: raster (rotate: 270)
  Players: 1
  Controls:
    - Player 1: paddle (5btn, 40-180 sensitivity)
    - Player 1: pedal (48-255 sensitivity)
```

### 3. COMPLETE GAME LISTING
Lists all analyzed games with their control configurations for reference.

## How This Helps Your IvarArcade System

### Identifying Custom Mapping Needs

Your IvarArcade system has standardized JOYCODE device assignments:
- JOYCODE_1: trooper
- JOYCODE_2: xinmo-1
- JOYCODE_3: xinmo-2
- JOYCODE_4: ultrastik
- JOYCODE_5: wheel

Games that use standard 4-way or 8-way joysticks automatically map to these JOYCODE assignments via `allctrlrs.cfg`.

However, games with special controls (paddle, pedal, trackball, etc.) or unusual button counts may need game-specific `.ini` files to properly configure the control mapping.

### Workflow

1. **Run analyze_controls** to generate the report
2. **Review games with special controls**
3. **For each special game, decide**:
   - Can it use a standard joystick mapping? (yes → no action needed)
   - Does it need the specific controller? (yes → create game-specific INI)
   - Should we skip/remap it? (decide based on your hardware)
4. **Update game-specific INI files** as needed

### Example: Spy Hunter (spyhunt)

From the report, we see spyhunt has:
- Paddle control (steering wheel simulation)
- 5 buttons (including acceleration/deceleration)
- Pedal input (not present in standard arcade)

Since your IvarArcade has a wheel controller (JOYCODE_5), you might:
- Map the paddle to JOYCODE_5 (wheel)
- Map buttons 1-4 to standard buttons
- Emulate the pedal as buttons if not available

## Integration with analyze_games

Both tools follow the same pattern:

```cpp
// Shared pattern in both tools:
1. Load gamelist.xml (favorite games)
2. For each game:
   - Extract shortName from ROM path
   - Run: mame -listxml <shortName>
   - Parse <machine><input><control> elements
   - Extract specific attributes (display/rotation vs buttons/ways)
   - Generate output (shader files/INI vs control report)
```

You can run both tools together:

```bash
cd /home/danc/IvarArcade/analyze_games
./analyze_games      # Generate shader files and joystick INI configs
./analyze_controls   # Generate control mapping analysis report
```

## Performance Considerations

The tool runs `mame -listxml <game>` for each favorite game:
- Each query takes ~2-3 seconds
- With 40-50 favorite games, expect 2-3 minutes total
- Output is written to a single text file (~50KB typical)

To run against a specific subset, you could modify the tool to accept command-line arguments, or manually edit gamelist.xml to comment out games you want to skip.

## Understanding Special Control Cases

### Paddle Games (Breakout, Pong, etc.)
```
Control type: paddle
Buttons: 1
Sensitivity range: typically 40-100
Minimum/Maximum: define analog range
```

**Mapping consideration**: Paddle games need an analog input. Your wheel controller or a joystick in analog mode could work.

### Trackball Games (Marble Madness, Centipede)
```
Control type: trackball
Buttons: 1-2
```

**Mapping consideration**: Trackball requires analog X/Y input. Can be emulated with joystick in analog mode or mapped to mouse movement.

### Racing Games (Pole Position, Spy Hunter)
```
Control type: paddle (for steering) + pedal (for acceleration)
```

**Mapping consideration**: Ideal for wheel + pedals. Can be partially emulated with joystick + buttons.

### Multi-Player with Different Controls
```
Player 1: joy (8-way, 5 buttons)
Player 2: joy (4-way, 2 buttons)
```

**Mapping consideration**: Some games have asymmetrical control requirements between players.

## Extending the Tool

The tool can be extended to:

1. **Generate game-specific INI files** for special controls
2. **Create a mapping database** linking games to required controllers
3. **Cross-reference with hardware** to suggest optimal controller per game
4. **Validate existing INI files** against MAME's actual control requirements
5. **Generate shell scripts** to automatically configure games

See the analyze_games.cpp source for the pattern to follow.

## Troubleshooting

### No games analyzed / blank report
- Check that gamelist.xml exists at `/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml`
- Verify MAME is installed and `mame -listxml` works from command line

### "Failed to run command" errors
- Ensure MAME binary is in your PATH
- Check that your favorite games list in ES has valid ROM paths

### Report shows "controls: none defined"
- Some older MAME games may not have input XML data
- This is accurate per MAME's understanding of those games

## Files Generated/Used

**Input Files:**
- `/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml` - Your favorite games list

**Output Files:**
- `/opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt` - The analysis report

**Temporary Files:**
- `/tmp/mame_listxml_temp.xml` - Cleaned up after execution

## See Also

- [analyze_games](./analyze_games.cpp) - Original tool for shader and joystick INI generation
- [MAPPING_README.txt](../docs/MAPPING_README.txt) - Complete button mapping guide
- [custom_game_mappings.txt](../docs/custom_game_mappings.txt) - Custom mapping examples
