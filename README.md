# IvarArcade

Arcade automation suite for Raspberry Pi / RetroPie systems.

## Overview

IvarArcade is a collection of tools designed to enhance your RetroPie arcade experience:

- **dmarquees** - Display daemon for arcade marquee images on a secondary monitor
- **analyze_games** - Automated MAME game analyzer and configuration generator

## Components

### dmarquees
A lightweight DRM-based daemon that displays game-specific marquee images on a dedicated display. Responds to commands via FIFO to switch marquees dynamically based on the currently playing game.

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

This installs executables to `$HOME/marquees/bin/` and copies shared resources (images, plugins, scripts).

### Build Individual Components
```bash
make dmarquees      # Build only the marquee daemon
make analyze_games  # Build only the game analyzer
```

### Linux (RetroPie/Raspberry Pi)
```bash
sudo apt install libdrm-dev libpng-dev libtinyxml2-dev pkg-config cmake
```
