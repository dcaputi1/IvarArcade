# ACTION PLAN: Complete Button Analysis for All 51 Games

## Current Status
- ✅ Atari System 1 (atarisy1.cpp) - Scanned
- ❌ 35 other driver files - NOT YET SCANNED
- ❌ 4+ additional games identified but not yet in database

## Priority Queue for Remaining Scans

### High Priority (Manufacturers with Multiple Games)

#### 1. Midway/Williams Games (8 games)
**Driver:** `src/mame/midway/williams.cpp`
**Your Games:**
- joust
- robotron
- defender  
- tron
- (3 more to identify)

**Scan Command:**
```bash
curl -s "https://raw.githubusercontent.com/mamedev/mame/mame0276/src/mame/midway/williams.cpp" \
  | grep -n "INPUT_PORTS_START\|PORT_NAME.*/"
```

#### 2. Namco Games (7+ games)
**Drivers:** 
- `src/mame/namco/pacman.cpp`
- `src/mame/namco/galaga.cpp`
- `src/mame/namco/digdug.cpp`
- `src/mame/namco/galaxian.cpp`
- `src/mame/namco/pengo.cpp`

**Your Games:** pacman, galaga, digdug, galaxian, mspacman, pengo, (1 more)

#### 3. Konami Games (5 games)
**Drivers:**
- `src/mame/konami/trackfld.cpp`
- `src/mame/konami/frogger.cpp`
- `src/mame/konami/scramble.cpp`

**Your Games:** trackfld, spyhunt, frogger, roadf, scramble

#### 4. Atari Other Systems (10+ games)
**Drivers:**
- `src/mame/atari/asteroid.cpp`
- `src/mame/atari/centiped.cpp`
- `src/mame/atari/invaders.cpp`
- `src/mame/atari/pong.cpp`
- `src/mame/atari/starwars.cpp`

**Your Games:** asteroid, breakout, centiped, digdug, gravitar, missile, spacedl, etc.

#### 5. Capcom Games (2 games)
**Driver:** `src/mame/capcom/cps1.cpp`
**Your Games:** streetf, sf2

#### 6. Other Manufacturers (9+ games)
- Nintendo (mario driver) - dkong, dkongjr, punchout
- Sega (system16) - outrun, zaxxon
- Taito (multiple drivers) - junglek, redbaron, sprint1
- Irem (irem driver) - mpatrol
- Bally/Gottlieb - gtg2, qbert
- And more

---

## Scanning Procedure (Template)

For each driver file:

```bash
#!/bin/bash
DRIVER="src/mame/atari/asteroid.cpp"  # Change for each
GITHUB="https://raw.githubusercontent.com/mamedev/mame/mame0276"

echo "Scanning $DRIVER..."
source=$(curl -s "${GITHUB}/${DRIVER}")

# Find games with dual-purpose buttons
echo "$source" | grep -B30 "PORT_NAME.*/" | grep -E "INPUT_PORTS_START|PORT_NAME.*/"

# Identify which games have complex controls
echo "$source" | grep -n "INPUT_PORTS_START" | while read line; do
  line_num=$(echo "$line" | cut -d: -f1)
  # Extract game name
  sed -n "$((line_num-1)),$((line_num))p" <<< "$source"
done
```

---

## Database Update Checklist

### Currently in analyze_controls.cpp Database
- [x] indytemp (fully implemented)

### Need to Add
- [ ] marble (Atari System 1)
- [ ] paperboy (Atari System 1)
- [ ] roadrunr (Atari System 1)
- [ ] tootsie (Atari System 1)
- [ ] [Pending results from other drivers]

### Current Database Entry Format
```cpp
const GameButtonMap gameButtonMap[] = {
    {"indytemp", {
        {"Button 1", {"Left Whip", "P1 Start"}},
        {"Button 2", {"Right Whip", "P2 Start"}}
    }},
    // Add more games here
};
```

---

## Testing Strategy

Once database is updated:

```bash
# Test against all 51 games
./analyze_controls

# Should identify:
1. Games with dual-purpose buttons
2. Button labels for proper remapping
3. Control conflicts that need resolution
```

---

## Timeline Estimate

| Phase | Task | Time |
|-------|------|------|
| 1 | Scan Midway/Williams | 30 min |
| 2 | Scan Namco drivers (5 files) | 45 min |
| 3 | Scan Konami drivers (3 files) | 30 min |
| 4 | Scan Atari other systems | 45 min |
| 5 | Scan remaining 10+ drivers | 1-2 hours |
| 6 | Update C++ database | 30 min |
| 7 | Recompile & test | 15 min |

**Total Estimated Time:** 4-5 hours for comprehensive coverage

---

## Key Files to Track

- `/tmp/complete_driver_mapping.txt` - Your 51 games mapped to driver files
- `/tmp/atarisy1.cpp` - Already fetched for reference
- `analyze_games/analyze_controls.cpp` - Main tool to update
- `COMPREHENSIVE_BUTTON_ANALYSIS.md` - This analysis document
- `SCOPE_CORRECTION_REPORT.md` - Scope realization document

---

## Success Criteria

✅ Project Complete When:
1. All 36 driver files scanned for dual-purpose buttons
2. At least 5-10+ games identified with button mapping issues
3. analyze_controls.cpp database updated with findings
4. Tool recompiled and tested against all 51 games
5. Documentation updated with complete results

---

## Notes

- Network requests may be slow; consider caching driver files locally
- Some games may have multiple button configurations (normal vs. cocktail cabinet)
- SERVICE/DIPS buttons often have different layouts - note but don't confuse with regular controls
- Cross-reference against your actual gamelist.xml to ensure 100% coverage

---

**This plan addresses the original scope gap:**
- ✅ Methodology proven with indytemp
- ❌ Previous analysis was <3% complete
- 🔄 This plan ensures comprehensive 100% coverage of your collection
