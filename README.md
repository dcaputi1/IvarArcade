# IvarArcade

Arcade automation suite for Raspberry Pi / RetroPie systems.


## Project Structure

This repository contains both source code and deployment assets:

- **Source code** lives in the top-level directories (`dmarquees/`, `analyze_games/`, etc.) and is built in-place.
- **McAtariPi5/** mirrors the Pi 5 filesystem at exact target paths. These are the deployment assets — scripts, configs, shaders, and data files used at runtime.

To deploy everything to the Pi, clone this repo and follow the readme.txt under the McAtari5 folder.

## Overview

IvarArcade is a collection of tools designed to enhance your RetroPie arcade experience:

- **dmarquees** - Display daemon for arcade marquee images on a secondary monitor
- **analyze_games** - Automated MAME game analyzer and configuration generator

## Display and Pi3 Presence Configuration

The system now uses two booleans for display and network configuration:

- `PI5_DUAL_DISPLAY` (true/false): Enables dual display (marquee + main) when true, single display when false.
- `PI3_PRESENT` (true/false): Indicates if a networked Pi3 is present.

You can toggle these options interactively from the Advanced Menu in the main arcade menu. Changes are persisted to the autostart.sh file.

All legacy dual monitor and transport logic has been removed. Use these booleans for all related configuration.

## Components

### dmarquees
A lightweight DRM-based daemon that displays game-specific marquee images on a dedicated display. Responds to commands via FIFO to switch marquees dynamically based on the currently playing game.

On a dual-display Pi 5, the daemon leaves the spare monitor alone for any game whose MAME `ini/<rom>.ini` sets `numscreens` above 1, so MAME can drive it. Punch-Out uses this for its native second screen. Tempest uses it as a kludge: `ini/tempest.ini` opens a second output with the `Dual Spinners` view from `artwork/tempest/default.lay`, which shows `dcpanel-1-labels.png`. That PNG is rendered ahead of time from `images/dcpanel-1-labels.svg` at exactly 1600x433, because MAME's SVG renderer cannot draw the embedded photo or the text labels. The labels are the template defaults, not per-game mappings. `cfg/tempest.cfg` counter-rotates MAME target 1 so the secondary display stays upright when the vertical game is auto-rotated. All that is because Tempest is the only game (?) in my original 58 game favorite list that grabs the DRM master lock ahead of dmarquees and blocks the screen1 panel image blit.

### analyze_games
Analyzes your MAME game collection and automatically generates:
- RetroArch shader presets based on game orientation
- MAME joystick configuration files for 4-way games

## Quick Start

### Build Everything

**Linux (Make):**
```bash
make
```

**Cross-platform (CMake):**
```bash
mkdir build && cd build
cmake ..
cmake --build .

### Install Everything
```bash
make install  # Make build system
# or
cmake --install build  # CMake build system
```

This installs executables to `$HOME/marquees/bin/` and copies shared resources (images, plugins, scripts). All scripts are placed in `~/scripts` and made executable automatically (Linux only). By default, scripts like `dmarquees-netbridge.py` are run directly from `~/scripts` unless you use a systemd installer.

### Build Individual Components
```bash
make dmarquees      # Build only the marquee daemon
make analyze_games  # Build only the game analyzer
```

### Linux (RetroPie/Raspberry Pi)
```bash
sudo apt install libdrm-dev libpng-dev libtinyxml2-dev pkg-config cmake
```

## Dev Notes

Here's a list of stuff I keep forgetting about:

- vector games in lr-mame look like crap. To work-around this, I use mame standalone as the emulator. Unfortunately, that requires some special config handling. Off hand I don't remember how it hooks in (used AI to get it working - go figure) but look in emulators.cfg and run_mame.sh
- much more stuff TBD

How to add a game to the "favorites"
1. run ~/scripts/romscrape.sh <newgame.zip>
2. copy new <game>...</game> section from ~/RetroPie/roms/arcade/gamelist*.xml to ~/IvarArcade/McAtariPie/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml (source path is dumb - TBD: fix)
3. add <favorite>true</favorite> to new <game>
4. make install (to rsync gamelist.xml)
5. copy new media from ~/RetroPie/roms/arcade/media/... to /media/danc/ExtremeSSD/McAtariPie/home/danc/RetroPie/roms/arcade/media/...
6. run ~/IvarArcade/analyze_games/analyze_games to create shader file and optional Ultrastik joystick_map ini file
7. a vector game will need runcommand menu option set to mame (default is lr-mame)
8. map conroller buttons in ES and MAME GUI

How to use ultrastikcmd
- to reset the stick (temporarily) to analog:
~/scripts/set_ultrastik_analog.cmd
or:
> ultrastikcmd -v -u /home/danc/IvarArcade/tools/UltraStikMaps/Analog.um
Note: add -f to flash/save the map (runcommand start/end scripts overwrite the active map). Also note, the current default/flashed map seems to be 8-way digital

### Per-game controller profiles in EmulationStation

The arcade system's standalone `mame` emulator entry launches through
`~/scripts/run_mame.sh`. To select a MAME `ctrlr` profile for particular ROMs,
add `ROM shortname=profile name` entries to
`/opt/retropie/configs/all/mame_ctrlr_map.txt` (the deployment source is
`McAtariPi5/opt/retropie/configs/all/mame_ctrlr_map.txt`). For example:

```text
qbert=dcpanel1
sf2=dcpanel1
```

Profile names correspond to files under
`/opt/retropie/emulators/mame/ctrlr`, without the `.cfg` extension. Matching is
case-insensitive; blank lines and lines starting with `#` are ignored. A match
updates `~/.ctrlr` to the selected profile. `dcpanel1` also sets `~/.panel` to
`DC`, and `atarifs` sets it to `MC` (the panel tokens are not the ctrlr names).
Other profiles leave `~/.panel` unchanged. A ROM not listed keeps the current
`~/.ctrlr` and `~/.panel` values. This lookup applies to the EmulationStation
standalone-MAME launch path, not games launched from the standalone MAME GUI.
