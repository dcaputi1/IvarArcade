# IvarArcade Restructuring Guide

## What Changed

The repository has been restructured from a single-executable project (`dmarquees`) to a multi-executable arcade suite called **IvarArcade**.

### Old Structure
```
marquees/
├── dmarquees.c
├── helpers.c
├── helpers.h
├── Makefile
├── images/
├── plugins/
└── scripts/
```

### New Structure
```
marquees/ (IvarArcade)
├── dmarquees/              # Marquee daemon source
│   ├── dmarquees.c
│   ├── helpers.c
│   ├── helpers.h
│   ├── Makefile
│   └── README.md
├── analyze_games/          # Game analyzer source
│   ├── analyze_games.cpp
│   ├── Makefile
│   └── README.md
├── Makefile               # Parent build system
├── README.md              # Project overview
├── images/                # Shared marquee images
├── plugins/               # Shared plugins
└── scripts/               # Shared scripts
```

## Key Changes

### 1. Source Files Relocated
- C source files moved to `dmarquees/`
- New C++ project added in `analyze_games/`

### 2. Build System
- **Top-level Makefile** builds both projects
- Each subdirectory has its own Makefile
- Individual projects can be built independently

### 3. Installation Paths
- Executables now install to: `$HOME/marquees/bin/`
- Previously: `$HOME/marquees/dmarquees`
- Now: `$HOME/marquees/bin/dmarquees` and `$HOME/marquees/bin/analyze_games`

### 4. Script Updates
The [autostart.sh](Backup_RetroPie/opt/retropie/configs/all/autostart.sh) script has been updated to reference the new binary location.

## Build Commands

### Build Everything
```bash
make                 # Build both executables
make dmarquees       # Build only dmarquees
make analyze_games   # Build only analyze_games
```

### Install
```bash
make install         # Install both executables and resources
```

### Clean
```bash
make clean           # Clean all build artifacts
```

## Benefits of This Structure

1. **Separation of Concerns** - Each executable has its own directory
2. **Independent Development** - Projects can be built separately
3. **Shared Resources** - Images, plugins, and scripts at top level
4. **Scalable** - Easy to add more tools in the future
5. **Standard Pattern** - Similar to Visual Studio solutions or CMake projects

## Migration Steps (Already Complete)

✅ Created subdirectories for each executable  
✅ Moved source files to appropriate locations  
✅ Created individual Makefiles  
✅ Created parent Makefile  
✅ Updated README files  
✅ Updated installation paths in scripts  
✅ Updated .gitignore  
✅ Verified builds work correctly

## Notes

- The old executable location `/home/danc/marquees/dmarquees` is no longer used
- Update any custom scripts to reference `/home/danc/marquees/bin/dmarquees`
- VS Code tasks continue to work without modification
- Git history is preserved
