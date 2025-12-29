# IvarArcade

Arcade automation suite for Raspberry Pi / RetroPie systems.

## Overview

IvarArcade is a collection of tools designed to enhance your RetroPie arcade experience:

- **dmarquees** - Display daemon for arcade marquee images on a secondary monitor
- **analyze_games** - Automated MAME game analyzer and configuration generator

## Components

### dmarquees
A lightweight DRM-based daemon that displays game-specific marquee images on a dedicated display. Responds to commands via FIFO to switch marquees dynamically based on the currently playing game.

See [dmarquees/README.md](dmarquees/README.md) for details.

### analyze_games
Analyzes your MAME game collection and automatically generates:
- RetroArch shader presets based on game orientation
- MAME joystick configuration files for 4-way games

See [analyze_games/README.md](analyze_games/README.md) for details.

## Quick Start

### Build Everything
```bash
make
```

### Install Everything
```bash
make install
```

This installs executables to `$HOME/marquees/bin/` and copies shared resources (images, plugins, scripts).

### Build Individual Components
```bash
make dmarquees      # Build only the marquee daemon
make analyze_games  # Build only the game analyzer
```

### Clean Build Artifacts
```bash
make clean
```

## Dependencies

### For dmarquees:
```bash
sudo apt install libdrm-dev libpng-dev pkg-config
```

### For analyze_games:
```bash
sudo apt install libtinyxml2-dev
```

## Project Structure

```
IvarArcade/
├── dmarquees/        # Marquee display daemon
├── analyze_games/    # Game analyzer and config generator
├── images/           # Shared marquee images
├── plugins/          # EmulationStation plugins
└── scripts/          # Utility scripts and backups
```

## License

See [LICENSE](LICENSE) file for details.
