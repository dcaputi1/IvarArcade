#!/bin/bash
# IvarArcade Configuration Migration - Implementation Guide
# This script provides step-by-step instructions for moving configs to version control

echo "================================================================================
IVARARCADE CONFIGURATION MIGRATION - STEP-BY-STEP GUIDE
================================================================================"

echo "
PREREQUISITES:
  • Working in IvarArcade repository root
  • Backup_RetroPie/ directory present with all backup files
  • Current git status is clean (no uncommitted changes)
  • Have access to reference Pi5 system for testing
"

echo "
PHASE 1: Create Directory Structure
================================================================================"
cat << 'EOF'

Run these commands from the IvarArcade repository root:

  mkdir -p scripts
  mkdir -p config/retropie/all/emulationstation
  mkdir -p config/mame/ctrlr
  mkdir -p config/mame/categories
  mkdir -p config/mame/ini
  mkdir -p config/mame/ini_horz_ror

Verification:
  tree -L 3 config/ scripts/   # Should show all new directories created

EOF

echo "
PHASE 2: Move Script Files
================================================================================"
cat << 'EOF'

Scripts to migrate (8 files):
  • leds_off.py              - LED control utility
  • set_leds.py              - LED configuration
  • swap_banner_art.sh       - Banner art management
  • xinmo-swap.py            - Xinmotek device swapping
  • xinmo-swapcheck.py       - Xinmotek device checking
  • mnt-marquees.sh          - Mount marquees utility
  • unmnt-marquees.sh        - Unmount marquees utility
  • run_mame.sh              - MAME launcher

Commands:
  cp Backup_RetroPie/home/danc/scripts/leds_off.py scripts/
  cp Backup_RetroPie/home/danc/scripts/set_leds.py scripts/
  cp Backup_RetroPie/home/danc/scripts/swap_banner_art.sh scripts/
  cp Backup_RetroPie/home/danc/scripts/xinmo-swap.py scripts/
  cp Backup_RetroPie/home/danc/scripts/xinmo-swapcheck.py scripts/
  cp Backup_RetroPie/home/danc/scripts/mnt-marquees.sh scripts/
  cp Backup_RetroPie/home/danc/scripts/unmnt-marquees.sh scripts/
  cp Backup_RetroPie/home/danc/scripts/run_mame.sh scripts/

Verification:
  ls -la scripts/
  # Should list 8 scripts with correct ownership and timestamps

EOF

echo "
PHASE 3: Move RetroEmulationStation Global Configs
================================================================================"
cat << 'EOF'

Configs to migrate (6 files + 1 subdirectory):
  • autostart.sh                  - Critical startup script
  • emulators.cfg                 - Emulator definitions
  • retroarch.cfg                 - RetroArch configuration
  • retroarch-core-options.cfg    - RetroArch core settings
  • runcommand-onlaunch.sh        - Pre-launch hooks
  • runcommand-onend.sh           - Post-launch hooks
  • emulationstation/es_input.cfg - Input configuration

Commands:
  cp Backup_RetroPie/opt/retropie/configs/all/autostart.sh config/retropie/all/
  cp Backup_RetroPie/opt/retropie/configs/all/emulators.cfg config/retropie/all/
  cp Backup_RetroPie/opt/retropie/configs/all/retroarch.cfg config/retropie/all/
  cp Backup_RetroPie/opt/retropie/configs/all/retroarch-core-options.cfg config/retropie/all/
  cp Backup_RetroPie/opt/retropie/configs/all/runcommand-onlaunch.sh config/retropie/all/
  cp Backup_RetroPie/opt/retropie/configs/all/runcommand-onend.sh config/retropie/all/
  cp Backup_RetroPie/opt/retropie/configs/all/emulationstation/es_input.cfg config/retropie/all/emulationstation/

Verification:
  ls -la config/retropie/all/
  ls -la config/retropie/all/emulationstation/

EOF

echo "
PHASE 4: Move MAME Device Mapping (Critical)
================================================================================"
cat << 'EOF'

File: allctrlrs.cfg - Contains unified device order mapping
  JOYCODE_1 = js0 (Trooper V2)
  JOYCODE_2 = js1 (Xinmotek Player 1)
  JOYCODE_3 = js2 (Xinmotek Player 2)
  JOYCODE_4 = js3 (Ultrastik)
  JOYCODE_5 = js4 (Racing Wheel)

Command:
  cp Backup_RetroPie/opt/retropie/emulators/mame/ctrlr/allctrlrs.cfg config/mame/ctrlr/

Verification:
  grep -E "mapdevice|JOYCODE" config/mame/ctrlr/allctrlrs.cfg
  # Should show 5 mapdevice entries matching above

Important: This file was just documented in updated docs/ - validate consistency

EOF

echo "
PHASE 5: Move Game Categories
================================================================================"
cat << 'EOF'

Category files (game groupings and favorites):
  • Atari_FS.ini    - Atari 5200 game list
  • B_list.ini      - B-series games
  • favorite_DC.ini - Favorite games (Dreamcast related)
  • FGT_wheel.ini   - Fighting game wheel categorization
  • Panel1.ini      - Panel layout grouping

Commands:
  cp Backup_RetroPie/opt/retropie/emulators/mame/categories/*.ini config/mame/categories/

Verification:
  ls -la config/mame/categories/
  # Should show 5 .ini files

EOF

echo "
PHASE 6: Move Display Rotation Configs
================================================================================"
cat << 'EOF'

File: horizont.ini - Display rotation configuration for arcade cabinet orientation

Command:
  cp Backup_RetroPie/opt/retropie/emulators/mame/ini_horz_ror/horizont.ini config/mame/ini_horz_ror/

Verification:
  ls -la config/mame/ini_horz_ror/
  wc -l config/mame/ini_horz_ror/horizont.ini

EOF

echo "
PHASE 7: Handle MAME INI Files (Selective)
================================================================================"
cat << 'EOF'

CRITICAL: Only migrate CUSTOM INI files, not standard MAME distribution files

Standard MAME INI files to EXCLUDE from git:
  • Default MAME distributed INI files
  • Large auto-generated config files
  • Files that change between MAME versions

Custom INI files to INCLUDE:
  • mame.ini (with custom paths/overrides)
  • ui.ini (custom UI settings)
  • Game-specific INI overrides
  • Plugin configurations

RECOMMENDED APPROACH:
  1. Examine Backup_RetroPie/opt/retropie/emulators/mame/ini/
  2. Identify which files are custom modifications
  3. Copy only custom files to config/mame/ini/
  4. Create config/mame/ini/README.md explaining:
     - Which files are included and why
     - Which files are excluded and why
     - How to restore standard MAME INI files

Example README.md content:
  ╔════════════════════════════════════════════════════════════════╗
  ║ MAME INI Configuration Files                                   ║
  ║                                                                ║
  ║ This directory contains CUSTOM INI file overrides only.       ║
  ║                                                                ║
  ║ CUSTOM FILES (in version control):                            ║
  ║   • mame.ini - Custom MAME configuration                     ║
  ║   • ui.ini - Custom UI settings                              ║
  ║   • [game-specific overrides]                                ║
  ║                                                                ║
  ║ STANDARD FILES (from MAME installation):                      ║
  ║   • plugin.ini - Standard plugin configuration               ║
  ║   • [other MAME distributed files]                           ║
  ║                                                                ║
  ║ To restore standard MAME INI files:                           ║
  ║   1. Uninstall MAME: sudo apt remove mame                    ║
  ║   2. Reinstall from source via RetroPie setup                ║
  ║   3. Custom INI overrides will be reapplied by 'make install'║
  ╚════════════════════════════════════════════════════════════════╝

Command (example - adjust based on your custom files):
  cp Backup_RetroPie/opt/retropie/emulators/mame/ini/mame.ini config/mame/ini/
  cp Backup_RetroPie/opt/retropie/emulators/mame/ini/ui.ini config/mame/ini/
  # Add additional custom INI files as needed

Verification:
  ls -la config/mame/ini/
  file config/mame/ini/*  # Check file types

EOF

echo "
PHASE 8: Create Configuration Documentation
================================================================================"
cat << 'EOF'

Add README.md files to each config section explaining purpose:

1. config/retropie/all/README.md
   - Description of each config file
   - What system features they control
   - Key settings to verify

2. config/mame/ctrlr/README.md
   - Device mapping explanation
   - JOYCODE assignments
   - How to verify device IDs

3. config/mame/categories/README.md
   - Game categorization system
   - How to add/modify categories

4. config/mame/ini/README.md
   - Custom vs standard files
   - Restoration instructions
   - Custom overrides documentation

5. config/mame/ini_horz_ror/README.md
   - Display rotation configuration
   - How to adjust for different orientations

Templates can be based on existing docs/ documentation.

EOF

echo "
PHASE 9: Update Makefile
================================================================================"
cat << 'EOF'

The Makefile needs new targets to install configurations:

Key additions:

1. Define configuration file lists:
   RETROPIE_CONFIGS = autostart.sh emulators.cfg retroarch.cfg ...
   MAME_CTRLR_CONFIGS = allctrlrs.cfg
   MAME_CATEGORIES = *.ini (from config/mame/categories/)
   etc.

2. Create install targets:
   install-scripts
   install-retropie-configs
   install-mame-configs
   install-mame-categories
   install-mame-display-configs

3. Update main install target:
   install: all install-scripts install-retropie-configs install-mame-configs ...

4. Example target structure:
   install-scripts:
     @mkdir -p /home/danc/scripts
     @for script in $(SCRIPTS_TO_INSTALL); do \\
         src="scripts/$$script"; \\
         dest="/home/danc/scripts/$$script"; \\
         if [ -f \"$$src\" ]; then \\
             if [ ! -f \"$$dest\" ] || [ \"$$src\" -nt \"$$dest\" ]; then \\
                 cp \"$$src\" \"$$dest\" && echo \"Updated: $$dest\"; \\
             else \\
                 echo \"Skipped: $$dest (up to date)\"; \\
             fi; \\
         fi; \\
     done

See Makefile.example section in CLEANUP_PROPOSAL.md for complete examples.

EOF

echo "
PHASE 10: Update Backup_RetroPie/readme.txt
================================================================================"
cat << 'EOF'

Update Step 7 in readme.txt:

OLD:
  7. run sudo ./analyze_games.sh to install tinyxml2 and python3-hid packages
  8. mkdir /opt/retropie/configs/all/retroarch/config/MAME (a.mkdir ...config, b.MAME)
  9. clone, build and install IvarArcade project:
  > cd ~
  > git clone https://github.com/dcaputi1/IvarArcade.git
  > cd IvarArcade
  > make all
  > make install # deploys binaries, scripts, plugins, etc...

NEW:
  7. clone, build and install IvarArcade project (includes all custom configs):
  > cd ~
  > git clone https://github.com/dcaputi1/IvarArcade.git
  > cd IvarArcade
  > make all
  > make install    # Deploys:
                     # - Custom scripts to /home/danc/scripts/
                     # - RetroEmulationStation global configs
                     # - MAME device mappings (allctrlrs.cfg)
                     # - Game categories and lists
                     # - Display configuration
                     # - Binaries and plugins

Add notes section:

IMPORTANT NOTES:
  • Large files NOT in repository (provided via backup SSD):
    - Game ROM archives (~/MAME_0.256_ROMset/)
    - MAME binary and standard INI files (from RetroPie installation)
    - MAME extras directory (~/MAME_0.256_EXTRAs/)
  • Custom INI file overrides tracked in config/mame/ini/
  • Standard MAME INI files restored from RetroPie MAME installation
  • Directory structure now matches: IvarArcade/config/

EOF

echo "
PHASE 11: Testing on Fresh Pi5 Rebaseline
================================================================================"
cat << 'EOF'

Before committing, test on fresh Pi5 SD card:

1. Follow preliminary setup steps a-i from readme.txt
2. Mount backup SSD to expected location
3. Run new rebaseline steps 1-7:
   • cp_roms.sh
   • cp_opt.sh
   • IvarArcade clone and make install
4. Verify all installations:
   ls -la /home/danc/scripts/
   ls -la /opt/retropie/configs/all/
   ls -la /opt/retropie/emulators/mame/ctrlr/
   ls -la /opt/retropie/emulators/mame/categories/
   
5. Test functionality:
   • Boot into EmulationStation
   • Verify controller mappings
   • Test a few games (especially ones in categories)
   • Check marquee display
   • Test LED control scripts

6. Compare with reference system:
   diff /opt/retropie/configs/all/autostart.sh reference_system:/opt/retropie/configs/all/autostart.sh
   # Should be identical

EOF

echo "
PHASE 12: Git Commit
================================================================================"
cat << 'EOF'

When ready to commit:

1. Review changes:
   git status
   git diff --stat

2. Create comprehensive commit message:
   git add config/ scripts/ docs/ Makefile
   
   git commit -m "Consolidate IvarArcade configs to version control
   
   - Migrate custom scripts from Backup_RetroPie/home/danc/scripts/ to scripts/
   - Migrate RetroEmulationStation configs to config/retropie/all/
   - Migrate MAME device mapping (allctrlrs.cfg) to config/mame/ctrlr/
   - Migrate game categories to config/mame/categories/
   - Migrate display configs to config/mame/ini_horz_ror/
   - Migrate custom MAME INI overrides to config/mame/ini/
   - Update Makefile with explicit installation targets
   - Update Backup_RetroPie/readme.txt with new process documentation
   
   Benefits:
   - All custom configs now in version control
   - Single 'make install' deploys complete environment
   - Easy to maintain, test, and collaborate on configurations
   - Backup_RetroPie maintained for reference only
   
   Related: See CLEANUP_PROPOSAL.md for comprehensive details"

3. Push:
   git push origin main

EOF

echo "
SUMMARY
================================================================================"
cat << 'EOF'

This migration accomplishes:

✓ Consolidates scattered configs into organized structure
✓ Enables version control of all custom configurations
✓ Simplifies Pi5 rebaseline process
✓ Provides clear documentation of what's deployed
✓ Makes Makefile self-documenting
✓ Reduces reliance on Backup_RetroPie_ for configuration
✓ Maintains backward compatibility (Backup_RetroPie still available)

Estimated effort:
  • File migrations: 5 minutes
  • Makefile updates: 30 minutes
  • Documentation: 20 minutes
  • Testing on reference Pi5: 30-60 minutes
  • Total: 1.5-2 hours

Next steps:
  1. Review this guide and CLEANUP_PROPOSAL.md
  2. Confirm directory structure and file selections
  3. Execute phases 1-7
  4. Update Makefile and documentation
  5. Test on reference system
  6. Commit and push

================================================================================"

EOF
