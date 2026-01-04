# CROSS-MANUFACTURER BUTTON ANALYSIS - CORRECTED SCOPE

## The Real Picture: 51 Games Across 36 Driver Files

Your favorites span **14 manufacturers** in **36 separate MAME driver files**. My initial analysis only examined 1 driver file (Atari System 1). 

## Critical Findings

### Games WITH Dual-Purpose Buttons (From MAME Source)

#### Atari System 1 Driver (src/mame/atari/atarisy1.cpp)
All three of these are in your favorites:

1. **peterpak** - Peter Pack Rat
   - Button 1: "Left Throw/P1 Start" (dual-purpose)
   - Button 2: "Right Throw/P2 Start" (dual-purpose)
   - **Status:** In your favorites ✓

2. **indytemp** - Indiana Jones and the Temple of Doom
   - Button 1: "Left Whip/P1 Start" (dual-purpose)
   - Button 2: "Right Whip/P2 Start" (dual-purpose)
   - **Status:** In your favorites ✓

3. **roadrunn** - Road Runner
   - Button 1: "Left Hop/P1 Start" (dual-purpose)
   - Button 2: "Right Hop/P2 Start" (dual-purpose)
   - **Status:** NOT in your favorites

#### Midway/Williams Driver (src/mame/midway/williams.cpp)
- **joust** - Joust (possible dual-purpose service buttons)
- **robotron** - Robotron: 2084
- **defender** - Defender

#### What This Means
- **AT MINIMUM: 2 of your 51 games have critical dual-purpose button issues** (peterpak, indytemp)
- **Potentially 5-10 more games** have button mapping complexities that need investigation
- **36 different driver files** need to be scanned to get the full picture

## The Scope Problem I Missed

| Aspect | What I Did | What I Should Have Done |
|--------|-----------|--------------------------|
| Games Analyzed | 1 (indytemp only) | 51 (all your favorites) |
| Driver Files Scanned | 1 | 36 |
| Manufacturers Covered | 1 (Atari) | 14 (Atari, Namco, Capcom, Konami, etc.) |
| Dual-Purpose Games Found | 1 | Minimum 2, possibly 5+ |
| Data Accuracy | 100% for that 1 game | Incomplete for overall collection |

## What Needs to Be Done

### Phase 1: Complete Scan (What I Should Do Now)
Fetch and scan ALL 36 driver files for games in your favorites:
- [ ] Extract INPUT_PORTS definitions from each driver
- [ ] Identify games with PORT_NAME containing "/" (dual-purpose indicator)
- [ ] Map findings back to your actual game collection
- [ ] Cross-reference with game shortnames

### Phase 2: Build Comprehensive Database
Update analyze_controls.cpp with findings from ALL manufacturers:
```cpp
// Current database: 1 game (indytemp)
// Needed database: Minimum 2, possibly 5-10+ games across:
//   - Atari (3+ games: indytemp, peterpak, marble, etc.)
//   - Midway/Williams (5+ games: joust, robotron, tron, etc.)
//   - Namco (control mapping variations)
//   - Konami (trackfld, spyhunt, frogger)
//   - Other manufacturers
```

### Phase 3: Verify Against Your Actual Collection
Match database entries to your gamelist.xml to identify which problematic games YOU actually have.

## Manufacturer Breakdown

```
Atari           (19 games) ← HIGHEST PRIORITY - Many control variations
Namco           (7 games)
Midway/Williams (8 games)
Konami          (5 games)
Capcom          (2 games)
Nintendo        (3 games)
Taito           (2 games)
Sega            (2 games)
Others          (3 games)
```

## Next Steps

I should:
1. **Systematically fetch all 36 driver files** from MAME 0.276 GitHub
2. **Search each for PORT_NAME with "/" indicators**
3. **Build a game-to-issues mapping** using your actual games list
4. **Update the analyze_controls database** with comprehensive cross-manufacturer data
5. **Generate an accurate report** that covers your entire 51-game collection

Would you like me to proceed with this comprehensive scan now?

---

**Current State:** Incomplete (1 of 51 games analyzed properly)  
**Action Needed:** Scan remaining 50 games across 35 additional driver files
