# analyze_games

MAME game analyzer and configuration generator for RetroPie arcade setups.

## Overview

`analyze_games` analyzes MAME games from EmulationStation's gamelist.xml and automatically generates appropriate configuration files for optimal gameplay:

- **Shader presets** - CRT shader configurations based on display orientation (horizontal/vertical)
- **Joystick INI files** - 4-way joystick mappings for games requiring restricted diagonal movement

## Features

- Parses EmulationStation gamelist.xml
- Queries MAME metadata via `mame -listxml`
- Detects display type (raster/vector) and rotation
- Identifies joystick control schemes (4-way, 8-way, etc.)
- Generates per-game RetroArch shader presets
- Creates per-game MAME INI files for 4-way joystick control

## Dependencies

```bash
sudo apt-get install libtinyxml2-dev
```

## Building

From the parent IvarArcade directory:
```bash
make analyze_games
```

Or from this directory:
```bash
make
```

## Usage

Simply run the executable:
```bash
./analyze_games
```

The program will:
1. Read `/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml`
2. Query MAME for each game's metadata
3. Generate shader files in `/opt/retropie/configs/all/retroarch/config/MAME/`
4. Generate joystick INI files in `/opt/retropie/emulators/mame/ini/`

## Output

For each game, the program generates:
- `<shortname>.glslp` - Shader preset referencing appropriate CRT shader
- `<shortname>.ini` - MAME INI with joystick mapping (for 4-way games only)

Example console output:
```
Game: pacman, Type: raster, Rotation: 90, Ways: 4
Game: sf2, Type: raster, Rotation: 0, Ways: 8
```

## Notes

- Vector games do not receive shader files (CRT shaders are for raster displays only)
- 8-way joystick games don't need INI files
- Special handling for qbert (physically rotated 45° joystick)
