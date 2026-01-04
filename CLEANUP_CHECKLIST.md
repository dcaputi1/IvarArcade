# IvarArcade Configuration Cleanup - Decision Checklist

## Overview
This checklist helps you decide what to include in the cleanup pass and proceed systematically.

---

## DECISION PHASE 1: Custom INI Files

### Question: Which MAME INI files should go into version control?

These should be included (custom modifications):
- [ ] `mame.ini` - Contains custom paths and settings specific to your system
- [ ] `ui.ini` - Custom UI preferences
- [ ] Game-specific INI files you've customized
- [ ] Plugin configuration files you've modified

These should be EXCLUDED (standard MAME distribution files):
- [ ] `plugin.ini` - Standard plugin config from MAME
- [ ] `plugin.all` - Standard all-plugins list
- [ ] `examples/` directory - Standard MAME examples
- [ ] Other MAME-provided reference files

**Action Required:** List specific custom INI files you want to include:
```
Custom INI files to include:
1. _________________
2. _________________
3. _________________
```

---

## DECISION PHASE 2: Game Category Files

### Question: Should all category INI files be included?

Current files in `config/mame/categories/`:
- [ ] Atari_FS.ini - Atari 5200 games (YES)
- [ ] B_list.ini - B-series games (YES)
- [ ] favorite_DC.ini - Dreamcast favorites (YES)
- [ ] FGT_wheel.ini - Fighting game wheel layout (YES)
- [ ] Panel1.ini - Panel 1 grouping (YES)

**Decision:** Include all category files? YES / NO

If NO, which ones to exclude?
```
Exclude:
1. _________________
2. _________________
```

---

## DECISION PHASE 3: Configuration Files

### Question: Are all RetroEmulationStation configs custom/needed?

Files in `config/retropie/all/`:
- [ ] `autostart.sh` - CRITICAL - Custom startup script (MUST INCLUDE)
- [ ] `emulators.cfg` - Emulator definitions (INCLUDE)
- [ ] `retroarch.cfg` - RetroArch settings (INCLUDE)
- [ ] `retroarch-core-options.cfg` - Core options (INCLUDE)
- [ ] `runcommand-onlaunch.sh` - Pre-launch hooks (INCLUDE)
- [ ] `runcommand-onend.sh` - Post-launch hooks (INCLUDE)
- [ ] `emulationstation/es_input.cfg` - Input mapping (INCLUDE)

**Decision:** Include all these files? YES / NO

If NO, which ones to exclude?
```
Exclude:
1. _________________
2. _________________
```

---

## DECISION PHASE 4: Script Files

### Question: Are all custom scripts needed for basic operation?

Scripts in `scripts/`:
- [ ] `leds_off.py` - Optional utility (LED control)
- [ ] `set_leds.py` - Optional utility (LED setup)
- [ ] `swap_banner_art.sh` - Optional utility
- [ ] `xinmo-swap.py` - Optional utility (device swapping)
- [ ] `xinmo-swapcheck.py` - Optional utility (device checking)
- [ ] `mnt-marquees.sh` - Important (marquee mounting)
- [ ] `unmnt-marquees.sh` - Important (marquee unmounting)
- [ ] `run_mame.sh` - Useful (MAME launcher)

**Decision:** Include all scripts? YES / NO (Recommended: YES, they're small)

If NO, which ones to exclude?
```
Exclude:
1. _________________
2. _________________
```

---

## DECISION PHASE 5: Size and Scope

### Question: Is the proposed scope acceptable?

Estimated repository additions:
- Scripts (8 files): ~50 KB
- Config files (~15 files): ~200 KB
- Documentation (new): ~100 KB
- Total: ~350 KB

**Acceptable?** YES / NO

If NO, what size limit?
```
Maximum acceptable: ___________ KB
```

---

## DECISION PHASE 6: Makefile Complexity

### Question: How detailed should the Makefile be?

Options:
1. **Minimal**: One `install-configs` target that copies everything
2. **Moderate**: Separate targets per section (scripts, retropie, mame)
3. **Detailed**: Individual targets for each config type (current proposal)

**Choose complexity level:** MINIMAL / MODERATE / DETAILED

---

## DECISION PHASE 7: Backup Directory Handling

### Question: What to do with `Backup_RetroPie/`?

Options:
1. **Keep as reference**: Leave with deprecation notice
2. **Archive**: Move to separate archive location
3. **Remove entirely**: Delete after migration complete

**Choose:** KEEP / ARCHIVE / REMOVE

If KEEP, deprecation notice level: BOLD / SUBTLE / NONE

---

## DECISION PHASE 8: Testing Requirements

### Question: What level of testing is required before commit?

Testing checklist:
- [ ] File migration scripts test (dry run)
- [ ] Fresh Pi5 SD card baseline test
- [ ] Verify all configs install to correct locations
- [ ] Test controller mappings work correctly
- [ ] Boot into EmulationStation and verify display
- [ ] Test marquee display functionality
- [ ] Run analyze_games and verify categories
- [ ] Compare output with reference system

**Minimum testing required:** BASIC / STANDARD / COMPREHENSIVE

---

## DECISION PHASE 9: Documentation Updates

### Question: Which documentation should be updated?

- [ ] `Backup_RetroPie/readme.txt` - Rebaseline process (MUST)
- [ ] `CLEANUP_SUMMARY.txt` - Already created
- [ ] `CLEANUP_PROPOSAL.md` - Already created
- [ ] `MIGRATION_GUIDE.sh` - Already created
- [ ] Main `README.md` - Add installation section (SHOULD)
- [ ] `BUILDING.md` - Add configuration details (NICE)
- [ ] New `config/*/README.md` - Document each section (NICE)

**What to update:** All / Most / Essential only

---

## DECISION PHASE 10: Timeline and Phasing

### Question: Single commit or phased approach?

Options:
1. **All-at-once**: One large commit with complete migration
2. **Phased**: Multiple commits in logical phases
3. **Branch-first**: Create feature branch, test, then merge

**Choose:** ALL_AT_ONCE / PHASED / BRANCH_FIRST

If PHASED, suggested phases:
```
Phase 1: Scripts and basic configs
Phase 2: MAME controller mapping
Phase 3: MAME categories and display
Phase 4: Makefile updates
Phase 5: Documentation
Phase 6: Testing and validation
```

---

## IMPLEMENTATION READINESS

### Before proceeding, confirm:

- [ ] All decision questions answered above
- [ ] Specific file selections documented
- [ ] Complexity level chosen
- [ ] Testing plan defined
- [ ] Documentation plan clear
- [ ] Team consensus obtained (if applicable)

### Ready to proceed? YES / NO

If YES, next step:
```
1. Review your answers to all decision questions
2. Create detailed implementation plan based on decisions
3. Execute MIGRATION_GUIDE.sh phases
4. Test thoroughly
5. Commit and document
```

If NO:
```
1. Review unclear decisions again
2. Ask clarifying questions
3. Consult with system maintainers
4. Re-review this checklist
```

---

## Notes Section

Use this space to document your specific decisions and any special considerations:

```
Decision Notes:
_______________________________________________________________________________
_______________________________________________________________________________
_______________________________________________________________________________

Custom INI files selected:
_______________________________________________________________________________
_______________________________________________________________________________

Testing plan details:
_______________________________________________________________________________
_______________________________________________________________________________

Timeline estimate:
_______________________________________________________________________________
_______________________________________________________________________________
```

---

## Sign-Off

**Reviewed by:** _____________________________ **Date:** __________

**Approved by:** _____________________________ **Date:** __________

**Completed by:** _____________________________ **Date:** __________

---
