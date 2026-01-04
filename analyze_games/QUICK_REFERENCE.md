# Quick Reference: Control Analysis Tools

## Building

```bash
cd /home/danc/IvarArcade/analyze_games
make clean && make
```

## Running

```bash
# Generate control mapping report for all favorite games
./analyze_controls

# View the report
cat /opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt
```

## What analyze_controls Does

1. Loads your favorite games from EmulationStation gamelist
2. Queries MAME for each game's control specifications
3. Identifies games with special controls (paddle, pedal, trackball, etc.)
4. Generates a report showing:
   - Total games analyzed
   - Games needing special mapping
   - Complete control specs for each game

## Control Types You'll See

| Type | Example | Your Options |
|------|---------|--------------|
| `joy` | Pacman, Donkey Kong | Use JOYCODE_1-4 (auto) |
| `joy2way` | Asteroid | Use JOYCODE_1-4 (auto) |
| `joy4way` | Pac-Man, most games | Use JOYCODE_1-4 (auto) |
| `joy8way` | Street Fighter, Gallaga | Use JOYCODE_4 (ultrastik) preferred |
| `paddle` | Breakout, Pong | Use JOYCODE_5 (wheel) |
| `pedal` | Spy Hunter, racing | Use buttons since pedal unavailable |
| `trackball` | Centipede, Marble Madness | No hardware - needs mouse or skip |
| `lightgun` | Point Blank | No hardware - cannot play |

## Understanding the Report

### Section 1: Summary
```
Total games analyzed: 47
Games with special controls: 3
```

### Section 2: Games With Special Controls
```
spyhunt
  Display: raster (rotate: 270)
  Players: 1
  Controls:
    - Player 1: paddle (5btn, 40-180 sensitivity)
    - Player 1: pedal (48-255 sensitivity)
```

### Section 3: Complete Game Listing
Reference list of all games and their exact control specs.

## Your JOYCODE Assignments

```
JOYCODE_1  → trooper      (standard 4-way joystick)
JOYCODE_2  → xinmo-1      (standard 4-way joystick)
JOYCODE_3  → xinmo-2      (standard 4-way joystick)
JOYCODE_4  → ultrastik    (8-way joystick - best for 8-way games)
JOYCODE_5  → wheel        (steering/analog - best for paddle games)
```

## File Locations

**Input**: `/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml`
**Output**: `/opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt`
**Executables**: `/home/danc/IvarArcade/analyze_games/`

## Quick Decision Tree for Special Controls

```
Game has special controls?
  ├─ Paddle (Breakout, Pong)?
  │  └─ Can use JOYCODE_5 (wheel) for analog input ✓
  │
  ├─ Pedal (Spy Hunter, racing)?
  │  ├─ Has wheel (JOYCODE_5) ✓
  │  └─ Pedal unavailable → map to button or skip
  │
  ├─ Trackball (Centipede)?
  │  ├─ No trackball hardware ✗
  │  └─ Could try mouse emulation (experimental)
  │
  ├─ Light Gun (Point Blank)?
  │  ├─ No light gun hardware ✗
  │  └─ Game cannot be properly played
  │
  └─ Standard joy (4-way, 8-way)?
     └─ Auto-mapped via JOYCODE ✓
```

## Extending for INI File Generation

See [EXTENSION_EXAMPLES.cpp](./EXTENSION_EXAMPLES.cpp) for reference code showing how to:
- Auto-generate game-specific INI files
- Create mapping database (CSV)
- Suggest optimal controller per game
- Validate control configurations

Key pattern:
```cpp
void writeGameControlIni(const GameControlInfo& info)
{
    // Decision tree: what to do with paddle, pedal, trackball, etc.
    if (info.controls[0].type == "paddle") {
        // Write INI for paddle mapping
    }
    // ... etc
}
```

## Common Queries

**Q: I want a CSV database of all control types**
A: See EXTENSION_EXAMPLES.cpp - `generateMappingDatabase()` function

**Q: How do I auto-generate INI files?**
A: See EXTENSION_EXAMPLES.cpp - `writeGameControlIni()` function

**Q: What if I add new games to favorites?**
A: Just run `./analyze_controls` again - it reanalyzes everything

**Q: Can I analyze a single game?**
A: Not directly - tool analyzes all favorites. See EXTENSION_EXAMPLES.cpp for filtering

**Q: Performance - how long does analysis take?**
A: ~2-3 minutes for 40-50 games (each game ≈ 3-4 seconds for MAME query)

## Files & Documentation

| File | Purpose |
|------|---------|
| [analyze_controls.cpp](./analyze_controls.cpp) | Main tool source code |
| [ANALYZE_CONTROLS_README.md](./ANALYZE_CONTROLS_README.md) | Complete user guide |
| [CONTROL_ANALYSIS_EXTENSION.md](./CONTROL_ANALYSIS_EXTENSION.md) | Technical architecture |
| [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) | What was created and why |
| [EXTENSION_EXAMPLES.cpp](./EXTENSION_EXAMPLES.cpp) | Reference code for extensions |
| [Makefile](./Makefile) | Build system (compiles both tools) |

## See Also

- [analyze_games.cpp](./analyze_games.cpp) - Companion tool for display/shader analysis
- [../../docs/MAPPING_README.txt](../../docs/MAPPING_README.txt) - Button mapping guide
- [../../docs/custom_game_mappings.txt](../../docs/custom_game_mappings.txt) - Custom mapping examples

---

**TL;DR**: Run `./analyze_controls` → Review report → Identify games needing custom mapping → Use EXTENSION_EXAMPLES.cpp patterns to auto-generate INI files if needed.
