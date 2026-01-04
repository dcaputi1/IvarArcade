# IvarArcade Configuration Cleanup Proposal

## Overview
This proposal outlines a comprehensive cleanup pass to move miscellaneous config files and custom overrides from the backup directory structure into the IvarArcade repository under version control. This will streamline the SD card rebaseline process and ensure all custom configurations are easily maintainable and distributable.

## Current State Analysis

### Backup Directory Contents
The `Backup_RetroPie/` directory contains:
- **Scripts** (`home/danc/scripts/`): 8 custom utility scripts
- **Config files** (`opt/retropie/configs/all/`): 6 core config files + 1 subdirectory
- **MAME directories** (`opt/retropie/emulators/mame/`): Categories, configs, controls, INI files

### Files Currently NOT Suitable for Git
(Large archives to be excluded from version control):
- `MAME_0.256_EXTRAs/` - Several GB of extra MAME data
- `mame/cfg_ra/`, `mame/cfg_sa/` - Game-specific .cfg files that grow dynamically
- `mame/ini/` - Large standard MAME INI files and plugin system
- ROM archives (`.zip` files)

## Proposed Reorganization

### Phase 1: Scripts Directory
**Move:** `Backup_RetroPie/home/danc/scripts/` → `scripts/`

Current scripts to move:
- `leds_off.py` - LED control utility
- `set_leds.py` - LED configuration
- `swap_banner_art.sh` - Banner art management
- `xinmo-swap.py` - Xinmotek device swapping
- `xinmo-swapcheck.py` - Xinmotek device checking
- `mnt-marquees.sh` - Mount marquees utility
- `unmnt-marquees.sh` - Unmount marquees utility
- `run_mame.sh` - MAME launcher

**Rationale:** These are custom, actively maintained tools that should be in version control.

### Phase 2: Global Configuration Files
**Move:** `Backup_RetroPie/opt/retropie/configs/all/` → `config/retropie/all/`

Files to move:
- `autostart.sh` - Custom startup script (critical - fully maintained)
- `emulators.cfg` - Emulator configuration
- `retroarch.cfg` - RetroArch configuration
- `retroarch-core-options.cfg` - RetroArch core options
- `runcommand-onlaunch.sh` - Launch hooks
- `runcommand-onend.sh` - End hooks
- `emulationstation/es_input.cfg` - Input configuration

**Rationale:** These are custom overrides that define system behavior and input mappings.

### Phase 3: MAME Controller Configuration
**Move:** `Backup_RetroPie/opt/retropie/emulators/mame/ctrlr/allctrlrs.cfg` → `config/mame/ctrlr/allctrlrs.cfg`

**Rationale:** This is a critical custom device mapping file that implements the unified device order (trooper, xinmo-1, xinmo-2, ultrastik, wheel).

### Phase 4: MAME Categories and Game Lists
**Move:** `Backup_RetroPie/opt/retropie/emulators/mame/categories/` → `config/mame/categories/`

Contains game categorization lists (Atari_FS.ini, etc.)

**Rationale:** Custom game groupings and favorites management.

### Phase 5: MAME INI - Selective Migration
**Move:** `Backup_RetroPie/opt/retropie/emulators/mame/ini/` (custom overrides only)

**Strategy:** 
- Create `config/mame/ini/` for custom overrides only
- Standard MAME INI files should come from MAME installation
- Keep only game-specific and customization INI files
- Document which INI files are custom vs standard

**Examples of custom INI files to include:**
- `mame.ini` - With custom paths/settings
- `ui.ini` - Custom UI settings
- Game-specific INI files (if any)

**Exclude from Git:**
- Standard MAME distributed INI files
- Large auto-generated files
- Files that grow dynamically

### Phase 6: MAME Display Configuration
**Move:** `Backup_RetroPie/opt/retropie/emulators/mame/ini_horz_ror/` → `config/mame/ini_horz_ror/`

**Rationale:** Custom display rotation configurations.

## Proposed Directory Structure

```
IvarArcade/
├── scripts/                          # [NEW] Utility scripts
│   ├── leds_off.py
│   ├── set_leds.py
│   ├── swap_banner_art.sh
│   ├── xinmo-swap.py
│   ├── xinmo-swapcheck.py
│   ├── mnt-marquees.sh
│   ├── unmnt-marquees.sh
│   └── run_mame.sh
│
├── config/                           # [NEW] Configuration files for rebaseline
│   ├── retropie/                     # RetroEmulationStation configs
│   │   ├── all/                      # Global configs (all systems)
│   │   │   ├── autostart.sh          # Custom startup script
│   │   │   ├── emulators.cfg
│   │   │   ├── retroarch.cfg
│   │   │   ├── retroarch-core-options.cfg
│   │   │   ├── runcommand-onlaunch.sh
│   │   │   ├── runcommand-onend.sh
│   │   │   └── emulationstation/
│   │   │       └── es_input.cfg
│   │   └── INSTALL_PATH.txt          # [NEW] Document where files install
│   │
│   └── mame/                         # MAME-specific configs
│       ├── ctrlr/
│       │   └── allctrlrs.cfg         # Device mapping configuration
│       ├── categories/               # Game categorization lists
│       │   ├── Atari_FS.ini
│       │   ├── B_list.ini
│       │   ├── favorite_DC.ini
│       │   └── ...
│       ├── ini/                      # Custom MAME INI files only
│       │   ├── README.md             # Document custom vs standard
│       │   ├── mame.ini
│       │   └── ui.ini
│       ├── ini_horz_ror/             # Display rotation configs
│       │   └── horizont.ini
│       └── INSTALL_PATH.txt          # [NEW] Document where files install
│
├── Backup_RetroPie/                  # [DEPRECATED] Keep for reference only
│   └── [archive of original backups]
│
├── plugins/                          # [EXISTING]
├── images/                           # [EXISTING]
├── docs/                             # [EXISTING]
│
└── Makefile                          # [UPDATED]
```

## Makefile Updates

### New Installation Targets

Expand the Makefile to handle the new config directory structure:

```makefile
# Configuration installation targets
install: install-scripts install-retropie-configs install-mame-configs install-plugins
```

### Detailed Implementation

1. **Script Installation:**
   - Copy scripts from `scripts/` to `/home/danc/scripts/`
   - Set executable permissions
   - Maintain backward compatibility

2. **RetroEmulationStation Config Installation:**
   - Install all files from `config/retropie/all/` to `/opt/retropie/configs/all/`
   - Handle subdirectories properly
   - Set appropriate permissions

3. **MAME Config Installation:**
   - Install controller mapping: `config/mame/ctrlr/allctrlrs.cfg` to `/opt/retropie/emulators/mame/ctrlr/`
   - Install categories: `config/mame/categories/` to `/opt/retropie/emulators/mame/categories/`
   - Install custom INI files: `config/mame/ini/` to `/opt/retropie/emulators/mame/ini/` (careful not to overwrite standard MAME INI)
   - Install display configs: `config/mame/ini_horz_ror/` to `/opt/retropie/emulators/mame/ini_horz_ror/`

4. **Conditional Installation:**
   - Only update files if newer (timestamp-based)
   - Don't overwrite user modifications
   - Create backup of existing files if needed

## Updated Rebaseline Documentation

The updated `Backup_RetroPie/readme.txt` should reference the new structure:

### Changes to Step 7:
```
7. Install IvarArcade project and all custom configurations:
> cd ~
> git clone https://github.com/dcaputi1/IvarArcade.git
> cd IvarArcade
> make all
> make install    # Deploys binaries, scripts, configs, plugins
                  # - Installs custom scripts to /home/danc/scripts/
                  # - Installs RetroEmulationStation configs
                  # - Installs MAME device mapping and categories
                  # - Deploys all custom configurations
```

### Add note about large file locations:
```
Important: The following large files are NOT part of the repository:
  - MAME binary and standard INI files (from RetroPie installation)
  - Game ROM archives
  - MAME_0.256_EXTRAs/ directory (mounted separately)
  - Dynamically generated game-specific configs
```

## Benefits

1. **Version Control**: All custom configurations tracked in git
2. **Reproducibility**: New Pi5 SD cards get identical setup
3. **Maintainability**: Changes to configs can be tracked and reviewed
4. **Documentation**: Clear mapping between git repo and installation paths
5. **Automation**: Single `make install` handles all custom setup
6. **Flexibility**: Easy to adjust configs without manual file management

## Migration Strategy

1. **Backward Compatibility**: Keep `Backup_RetroPie/` for reference during transition
2. **Parallel Existence**: Both old and new paths can coexist initially
3. **Deprecation Notice**: Mark `Backup_RetroPie/` as deprecated in README
4. **Testing**: Validate all paths and permissions on fresh Pi5 install
5. **Documentation**: Update all build and setup documentation

## Notes on Excluded Items

### Why MAME Standard INI Files Stay Outside Git
- MAME provides standard `.ini` files as part of its distribution
- These files are large and change with MAME version updates
- Storing in git would create version conflicts
- Instead: Keep only custom overrides and game-specific configs
- Standard MAME INI files come from the RetroPie MAME installation

### Why cfg_ra/ and cfg_sa/ Stay Outside Git
- These directories contain dynamically generated game-specific configs
- Users can modify these directly in MAME UI
- Size grows over time as new games are played
- Should be user's responsibility to backup/manage
- Version control would create merge conflicts

### Why Large Archives Stay Outside Git
- MAME_0.256_EXTRAs can be several GB
- Game ROM archives are typically not distributed via git
- These are sourced from external archives or backups
- Keep Backup_RetroPie as reference pointing to mount location

## Implementation Checklist

- [ ] Create `scripts/` directory with scripts
- [ ] Create `config/retropie/all/` with config files
- [ ] Create `config/mame/ctrlr/` with allctrlrs.cfg
- [ ] Create `config/mame/categories/` with INI lists
- [ ] Create `config/mame/ini/` with custom INI files only
- [ ] Create `config/mame/ini_horz_ror/` with display configs
- [ ] Update Makefile with new installation targets
- [ ] Add README.md files documenting each config section
- [ ] Update `Backup_RetroPie/readme.txt` with references to new structure
- [ ] Update main README.md with installation information
- [ ] Test `make install` on reference system
- [ ] Mark `Backup_RetroPie/` as deprecated in comments

## Estimated Impact

- **Repository size increase**: ~2-5 MB (small scripts and configs)
- **Installation time**: ~1-2 seconds additional for config copying
- **Complexity reduction**: Eliminates manual config management
- **Maintenance overhead**: Reduced - changes tracked in git
