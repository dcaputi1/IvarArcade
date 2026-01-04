# Analysis: MAME Button Label Extraction Challenge

## The Problem

The current `analyze_controls` tool extracts:
- Button count: "1 button"
- Joystick type: "8-way"

But misses critical semantic information:
- **indytemp**: Button 1 is actually "Left Whip/Player 1 Start" - a dual-purpose input
- This causes games to be mis-diagnosed as "standard" when they actually need custom mapping
- Players see "Player 1 Start" and don't realize it's the same as "Left Whip" button

## Where This Information Exists

### 1. MAME's Input Definition System (Hidden in C++)
Location: MAME ROM source code (e.g., atarisy1.cpp)
Example:
```cpp
static INPUT_PORTS_START( indytemp )
    PORT_BIT( 0x01, IP_ACTIVE_HIGH, IPT_JOYSTICK_LEFT )
    PORT_BIT( 0x02, IP_ACTIVE_HIGH, IPT_JOYSTICK_RIGHT )
    PORT_BIT( 0x04, IP_ACTIVE_HIGH, IPT_JOYSTICK_UP )
    PORT_BIT( 0x08, IP_ACTIVE_HIGH, IPT_JOYSTICK_DOWN )
    PORT_BIT( 0x10, IP_ACTIVE_HIGH, IPT_BUTTON1 )
        PORT_NAME( "Left Whip" )
    PORT_BIT( 0x20, IP_ACTIVE_HIGH, IPT_START1 )
INPUT_PORTS_END
```

Issue: **Not exported in listxml output**

### 2. MAME In-Game Menu (Press I key while running)
Shows: "Left Whip/Player 1 Start" for button 1
Method: Run game and navigate to Input menu
Limitation: **Manual inspection only - not automatable**

### 3. MAME's Source Code (if available locally)
Location: `/opt/retropie/emulators/mame/` ROM driver files
Problem: **Not available in standard RetroPie MAME installation**

### 4. MAME's Lua Scripting Interface
Potential: Might expose input port information
Status: **Untested - may not export semantic labels**

### 5. Custom MAME Patches/Tools
Option: Modify MAME to export port labels in XML
Effort: **High - requires MAME recompilation**

## Current Limitations

The `-listxml` output provides:
- Machine name
- ROM information
- Display properties
- Input count and button counts
- DIP switches and configuration options

But NOT:
- Port type definitions (IPT_BUTTON1, IPT_JOYSTICK_LEFT, etc.)
- Port names ("Left Whip", "Player 1 Start")
- Port masks (which bits map to which functions)
- Input conflicts (same button mapped to multiple functions)

## Proposed Solutions

### Solution A: Manual Annotation Database (Lowest Effort)
Create a YAML/JSON database of known problematic games:

```yaml
indytemp:
  buttons_info:
    - number: 1
      labels: ["Left Whip", "Player 1 Start"]
      reason: "Dual-purpose button - needs manual mapping or custom INI"
      recommendation: "Create game-specific INI to separate functions"
  
  special_controls: true
  custom_mapping_required: true
  notes: "Button 1 serves as both weapon attack and game start"
```

**Pros**: Simple, accurate, maintainable
**Cons**: Manual maintenance required

### Solution B: Query MAME Plugin/Lua Interface (Medium Effort)
Create a MAME Lua script that exports port information:

```lua
-- Export input port information for analyze_controls
local ports = manager:machine():input():port_list()
for name, port in pairs(ports) do
    print(name .. ": " .. port:description())
end
```

**Pros**: Automated, comprehensive
**Cons**: Requires MAME Lua knowledge, may not expose labels

### Solution C: Custom MAME XML Patch (High Effort)
Modify MAME source to export port definitions in listxml:

```xml
<input players="1" coins="3">
    <control type="joy" buttons="1" ways="8"/>
    <port tag="IN0">
        <field name="Button1" label="Left Whip" aliases="Player 1 Start"/>
        <field name="Joystick" ways="8"/>
    </port>
</input>
```

**Pros**: Complete solution, reusable
**Cons**: Requires MAME recompilation, maintenance burden

### Solution D: Hybrid Approach (Recommended)
1. **Automatic detection** of anomalies:
   - Games with button+joystick combo
   - Games with unusual control configurations
   - Games with dual-function buttons (identified by pattern analysis)

2. **Manual annotation** for known problematic cases
   - Keep GAMES_WITH_DUAL_BUTTONS.yml
   - Update when discovering new cases
   - Share with community

3. **Output format** that highlights unknowns:
   ```
   game: indytemp
   control_complexity: HIGH  ← Flag for manual review
   buttons: 1
   joystick: 8-way
   button_usage: UNKNOWN (requires manual verification)
   custom_mapping_needed: POSSIBLY
   
   IMPORTANT: This game may have dual-purpose buttons.
   Run "mame indytemp" and press [I] to verify in-game input menu.
   ```

## Recommended Implementation

### Step 1: Enhance Detection Heuristics
```cpp
bool hasComplexControls(const GameControlInfo& info)
{
    // Flag games that likely have dual-purpose or complex buttons
    
    // Pattern 1: Any non-standard control type
    for (const auto& ctrl : info.controls) {
        if (ctrl.type != "joy" && ctrl.type != "joy4way" && 
            ctrl.type != "joy8way") {
            return true;  // Special control type
        }
    }
    
    // Pattern 2: Button + Joystick (suggests multi-function)
    bool hasButtons = false;
    bool hasJoystick = false;
    for (const auto& ctrl : info.controls) {
        if (ctrl.buttons > 0 && ctrl.type.find("joy") != string::npos) {
            hasButtons = true;
        }
        if (ctrl.type.find("joy") != string::npos) {
            hasJoystick = true;
        }
    }
    
    // If button count is suspiciously low (1) with joystick, 
    // it might be multi-function
    if (hasButtons && hasJoystick && 
        info.controls[0].buttons <= 2) {
        return true;  // Likely dual-purpose
    }
    
    return false;
}
```

### Step 2: Create Annotation Database
File: `KNOWN_DUAL_BUTTON_GAMES.yml`
```yaml
# Games with known dual-purpose or complex button mappings
# Discovered by manual testing in MAME in-game menu

indytemp:
  buttons:
    button1: "Left Whip / Player 1 Start"
  issue: "Same button for attack and start - confusing UX"
  needs_custom_ini: true
  notes: "In-game menu shows both labels"

defender:
  buttons:
    button1: "Fire"
    button2: "Hyperspace (Player 1 Only)"
    button3: "Reverse"
    button4: "Smart Bomb"
    button5: "Unused"
  issue: "More buttons declared than actually usable"
  needs_custom_ini: true

qbert:
  buttons:
    button1: "Jump"
    button2: "Stoop (Player 1 Only)"
  issue: "Asymmetrical player controls"
  notes: "Player 2 has fewer buttons available"
```

### Step 3: Enhanced Report Output
```
SPECIAL CONTROLS - GAMES REQUIRING MANUAL REVIEW
================================================

indytemp
  Status: DUAL-PURPOSE BUTTONS DETECTED
  Button 1: "Left Whip" AND "Player 1 Start"
  Impact: Players may not realize button starts the game
  Action Required: Create custom INI or update documentation
  Reference: KNOWN_DUAL_BUTTON_GAMES.yml
```

## Implementation in analyze_controls.cpp

Add to the tool:

```cpp
struct ButtonLabel {
    int number;
    vector<string> labels;  // "Left Whip", "Player 1 Start"
    string reason;          // Why they're combined
};

// Load from annotation file
bool loadKnownDualButtons(map<string, vector<ButtonLabel>>& db)
{
    // Parse KNOWN_DUAL_BUTTON_GAMES.yml
    // Return true if found, populate db
}

// Check if game has known issues
vector<ButtonLabel> getKnownButtonLabels(const string& gameName)
{
    // Returns button info if game is in annotation database
}

// Enhanced output
if (auto labels = getKnownButtonLabels(info.shortName)) {
    reportFile << "⚠ DUAL-PURPOSE BUTTONS DETECTED:\n";
    for (const auto& btn : labels) {
        reportFile << "  Button " << btn.number << ": ";
        for (size_t i = 0; i < btn.labels.size(); ++i) {
            if (i > 0) reportFile << " AND ";
            reportFile << btn.labels[i];
        }
        reportFile << "\n";
    }
}
```

## Immediate Action Plan

1. **Document current limitation** in ANALYZE_CONTROLS_README.md
   - Explain why button labels aren't extracted
   - Show workaround: manual MAME inspection

2. **Create KNOWN_DUAL_BUTTON_GAMES.yml**
   - Start with indytemp
   - Add other known problem cases
   - Community can contribute

3. **Enhance analyze_controls** to:
   - Flag games for manual review
   - Load and reference known cases
   - Suggest testing procedure

4. **Document workaround**
   ```
   To verify button assignments for a game:
   1. Run: mame <gamename>
   2. Press [I] during gameplay
   3. Navigate to Input settings
   4. View all button and control definitions
   5. Note any unusual combinations or aliases
   6. Create custom INI if needed
   ```

## Long-Term Solution

If MAME community adopts enhanced XML export (Port definitions in listxml), this limitation disappears.
Until then, maintain annotation database and flag problematic games for manual review.

## Files to Create/Modify

| File | Purpose |
|------|---------|
| KNOWN_DUAL_BUTTON_GAMES.yml | Annotation database |
| analyze_controls.cpp | Add heuristics + annotation loading |
| ANALYZE_CONTROLS_README.md | Document limitation + workaround |
| MAME_BUTTON_LABELS.md | How to manually discover button labels |

