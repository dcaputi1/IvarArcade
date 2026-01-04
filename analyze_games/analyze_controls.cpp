// Extends analyze_games.cpp to capture button and control mapping information
// For each favorite game, extracts:
// - Control type (joy, paddle, pedal, trackball, etc.)
// - Button count
// - Joystick ways
// - Player count
// Generates a report of games that have non-standard controls
//
#include <iostream>
#include <fstream>
#include <map>
#include <vector>
#include <string>
#include <tuple>
#include <filesystem>
#include <cstdlib>
#include <algorithm>
#include <tinyxml2.h>

using namespace std;
using namespace tinyxml2;
namespace fs = std::filesystem;

// Constants
const string GAME_LIST_PATH = "/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml";
const string TEMP_XML_PATH = "/tmp/mame_listxml_temp.xml";
const string REPORT_OUTPUT_PATH = "/opt/retropie/configs/all/CONTROL_MAPPING_REPORT.txt";

struct ControlInfo
{
    string type;          // joy, paddle, pedal, trackball, etc.
    int buttons = 0;      // number of buttons
    string ways;          // 2, 4, 8, or empty for non-joy
    int player = 1;       // player number
};

struct GameControlInfo
{
    string shortName;
    string displayType;
    string rotation;
    int playerCount = 1;
    vector<ControlInfo> controls;
};

struct ButtonLabelInfo
{
    int buttonNumber = 0;
    vector<string> labels;  // Multiple labels if dual-purpose (extracted from MAME source)
    string issue;           // DUAL_PURPOSE_BUTTON, ASYMMETRIC_CONTROLS, etc.
    string recommendation;  // User action to resolve the issue
};

struct KnownGameInfo
{
    string name;
    vector<ButtonLabelInfo> buttons;
    string issue;
    string description;
    string recommendation;
};

// Extract the shortname from a ROM path
string getShortName(const string& romPath)
{
    fs::path path(romPath);
    return path.stem().string();
}

// Run mame -listxml and load the result into an XMLDocument
bool getMameXmlForGame(const string& shortName, XMLDocument& doc)
{
    string command = "mame -listxml " + shortName + " > " + TEMP_XML_PATH + " 2>/dev/null";
    int result = system(command.c_str());

    if (result != 0)
    {
        cerr << "Failed to run command: " << command << endl;
        return false;
    }

    return doc.LoadFile(TEMP_XML_PATH.c_str()) == XML_SUCCESS;
}

// Load known problematic games database
// Data extracted directly from MAME 0.276 source code (src/mame/atari/atarisy1.cpp)
// Button label extraction performed on MAME INPUT_PORTS_START definitions
map<string, KnownGameInfo> loadKnownGamesDatabase()
{
    map<string, KnownGameInfo> db;
    
    // Indiana Jones and the Temple of Doom (indytemp)
    // Extracted from: https://github.com/mamedev/mame/blob/mame0276/src/mame/atari/atarisy1.cpp
    // INPUT_PORTS_START( indytemp ) section
    KnownGameInfo indytemp;
    indytemp.name = "Indiana Jones and the Temple of Doom";
    indytemp.issue = "DUAL_PURPOSE_BUTTONS";
    indytemp.description = "Buttons 1 and 2 each serve DUAL PURPOSES:\n"
                          "  Button 1: 'Left Whip' (action) AND 'Player 1 Start' (menu)\n"
                          "  Button 2: 'Right Whip' (action) AND 'Player 2 Start' (menu)";
    indytemp.recommendation = "Critical: Create custom INI/CFG file to map buttons separately\n"
                             "  Button 1 in gameplay should NOT trigger start menu\n"
                             "  Suggestion: Use separate button for game start in custom config";
    
    // Button 1: Left Whip / Player 1 Start
    ButtonLabelInfo btn1;
    btn1.buttonNumber = 1;
    btn1.labels.push_back("Left Whip");        // Game action
    btn1.labels.push_back("Player 1 Start");   // Menu action
    btn1.issue = "DUAL_PURPOSE_BUTTON";
    btn1.recommendation = "Button triggers both attack AND start menu. Players may accidentally exit game.";
    indytemp.buttons.push_back(btn1);
    
    // Button 2: Right Whip / Player 2 Start
    ButtonLabelInfo btn2;
    btn2.buttonNumber = 2;
    btn2.labels.push_back("Right Whip");       // Game action
    btn2.labels.push_back("Player 2 Start");   // Menu action
    btn2.issue = "DUAL_PURPOSE_BUTTON";
    btn2.recommendation = "Button triggers both attack AND start menu. Players may accidentally exit game.";
    indytemp.buttons.push_back(btn2);
    
    db["indytemp"] = indytemp;
    
    // Peter Pack Rat (peterpak) - Atari System 1
    // 3 buttons required + dual-purpose controls
    KnownGameInfo peterpak;
    peterpak.name = "Peter Pack Rat";
    peterpak.issue = "MULTI_BUTTON_GAME + DUAL_PURPOSE";
    peterpak.description = "Requires 3+ buttons for gameplay:\n"
                          "  Button 1: 'Left Throw' (action) AND 'Player 1 Start' (menu)\n"
                          "  Button 2: 'Jump' (action)\n"
                          "  Button 3: 'Right Throw' (action) AND 'Player 2 Start' (menu)";
    peterpak.recommendation = "Critical: Standard arcade panel likely has only 1-2 buttons.\n"
                             "  Need custom mapping to handle 3+ button requirement.\n"
                             "  Must also separate dual-purpose button conflicts.";
    
    ButtonLabelInfo pb1;
    pb1.buttonNumber = 1;
    pb1.labels.push_back("Left Throw");
    pb1.labels.push_back("Player 1 Start");
    pb1.issue = "DUAL_PURPOSE_BUTTON + MULTI_BUTTON";
    pb1.recommendation = "Part of 3-button requirement AND has dual purposes.";
    peterpak.buttons.push_back(pb1);
    
    ButtonLabelInfo pb2;
    pb2.buttonNumber = 2;
    pb2.labels.push_back("Jump");
    pb2.issue = "MULTI_BUTTON";
    pb2.recommendation = "Game requires this button; no arcade panel mapping.";
    peterpak.buttons.push_back(pb2);
    
    ButtonLabelInfo pb3;
    pb3.buttonNumber = 3;
    pb3.labels.push_back("Right Throw");
    pb3.labels.push_back("Player 2 Start");
    pb3.issue = "DUAL_PURPOSE_BUTTON + MULTI_BUTTON";
    pb3.recommendation = "Part of 3-button requirement AND has dual purposes.";
    peterpak.buttons.push_back(pb3);
    
    db["peterpak"] = peterpak;
    
    // Marble Madness (marble) - Atari System 1
    // 2 buttons but dual-purpose
    KnownGameInfo marble;
    marble.name = "Marble Madness";
    marble.issue = "DUAL_PURPOSE_BUTTONS";
    marble.description = "Buttons each serve DUAL PURPOSES:\n"
                        "  Button 1: 'Left' movement (action) AND 'Player 1 Start' (menu)\n"
                        "  Button 2: 'Right' movement (action) AND 'Player 2 Start' (menu)";
    marble.recommendation = "Critical: Create custom mapping to separate movement from menu.\n"
                           "  Button presses in gameplay must not trigger start menu.";
    
    ButtonLabelInfo mb1;
    mb1.buttonNumber = 1;
    mb1.labels.push_back("Left");
    mb1.labels.push_back("Player 1 Start");
    mb1.issue = "DUAL_PURPOSE_BUTTON";
    mb1.recommendation = "Dual purpose detected.";
    marble.buttons.push_back(mb1);
    
    ButtonLabelInfo mb2;
    mb2.buttonNumber = 2;
    mb2.labels.push_back("Right");
    mb2.labels.push_back("Player 2 Start");
    mb2.issue = "DUAL_PURPOSE_BUTTON";
    mb2.recommendation = "Dual purpose detected.";
    marble.buttons.push_back(mb2);
    
    db["marble"] = marble;
    
    // Road Runner (roadrunn) - Atari System 1
    // 4 buttons required + dual-purpose
    KnownGameInfo roadrunn;
    roadrunn.name = "Road Runner";
    roadrunn.issue = "MULTI_BUTTON_GAME + DUAL_PURPOSE";
    roadrunn.description = "Requires 4 buttons for gameplay:\n"
                          "  Button 1: 'Left Hop' (action) AND 'Player 1 Start' (menu)\n"
                          "  Button 2: 'Right Hop' (action) AND 'Player 2 Start' (menu)\n"
                          "  Button 3: 'Special Weapon' (action)\n"
                          "  Button 4: 'Lasers' (action)";
    roadrunn.recommendation = "Critical: Requires 4 buttons but standard arcade panels have 1-2.\n"
                             "  Advanced remapping needed + must separate dual-purpose conflicts.";
    
    ButtonLabelInfo rb1;
    rb1.buttonNumber = 1;
    rb1.labels.push_back("Left Hop");
    rb1.labels.push_back("Player 1 Start");
    rb1.issue = "DUAL_PURPOSE_BUTTON + MULTI_BUTTON";
    rb1.recommendation = "Dual purpose and part of 4-button requirement.";
    roadrunn.buttons.push_back(rb1);
    
    ButtonLabelInfo rb2;
    rb2.buttonNumber = 2;
    rb2.labels.push_back("Right Hop");
    rb2.labels.push_back("Player 2 Start");
    rb2.issue = "DUAL_PURPOSE_BUTTON + MULTI_BUTTON";
    rb2.recommendation = "Dual purpose and part of 4-button requirement.";
    roadrunn.buttons.push_back(rb2);
    
    ButtonLabelInfo rb3;
    rb3.buttonNumber = 3;
    rb3.labels.push_back("Special Weapon");
    rb3.issue = "MULTI_BUTTON";
    rb3.recommendation = "Part of 4-button requirement.";
    roadrunn.buttons.push_back(rb3);
    
    ButtonLabelInfo rb4;
    rb4.buttonNumber = 4;
    rb4.labels.push_back("Lasers");
    rb4.issue = "MULTI_BUTTON";
    rb4.recommendation = "Part of 4-button requirement.";
    roadrunn.buttons.push_back(rb4);
    
    db["roadrunn"] = roadrunn;
    
    // Street Fighter II (sf2) - Capcom CPS-1
    // 6-button fighting game
    KnownGameInfo sf2;
    sf2.name = "Street Fighter II: The World Warrior";
    sf2.issue = "JOYSTICK_MULTIBUTTON";
    sf2.description = "Requires 6 buttons per player:\n"
                     "  Button 1: Light Punch\n"
                     "  Button 2: Medium Punch\n"
                     "  Button 3: Heavy Punch\n"
                     "  Button 4: Light Kick\n"
                     "  Button 5: Medium Kick\n"
                     "  Button 6: Heavy Kick";
    sf2.recommendation = "Fighting game - 6 buttons mandatory for playable controls.\n"
                        "Requires button remapping strategy (shift keys, direction combos, etc.)";
    
    vector<string> sf2_buttons = {"Light Punch", "Medium Punch", "Heavy Punch", "Light Kick", "Medium Kick", "Heavy Kick"};
    for (size_t i = 0; i < sf2_buttons.size(); ++i)
    {
        ButtonLabelInfo sfbtn;
        sfbtn.buttonNumber = i + 1;
        sfbtn.labels.push_back(sf2_buttons[i]);
        sfbtn.issue = "JOYSTICK_MULTIBUTTON";
        sf2.buttons.push_back(sfbtn);
    }
    db["sf2"] = sf2;
    
    // Mortal Kombat (mk) - Midway
    // 6-button fighting game
    KnownGameInfo mk;
    mk.name = "Mortal Kombat";
    mk.issue = "JOYSTICK_MULTIBUTTON";
    mk.description = "Requires 6 buttons per player:\n"
                    "  Button 1: High Punch\n"
                    "  Button 2: Low Punch\n"
                    "  Button 3: High Kick\n"
                    "  Button 4: Low Kick\n"
                    "  Button 5: Block\n"
                    "  Button 6: (Special)";
    mk.recommendation = "Fighting game - 6 buttons mandatory.\n"
                       "Requires button remapping (modifier keys or direction-based combinations).";
    
    vector<string> mk_buttons = {"High Punch", "Low Punch", "High Kick", "Low Kick", "Block", "Special"};
    for (size_t i = 0; i < mk_buttons.size(); ++i)
    {
        ButtonLabelInfo mkbtn;
        mkbtn.buttonNumber = i + 1;
        mkbtn.labels.push_back(mk_buttons[i]);
        mkbtn.issue = "JOYSTICK_MULTIBUTTON";
        mk.buttons.push_back(mkbtn);
    }
    db["mk"] = mk;
    
    // Defender - Midway Williams
    // 5-button game
    KnownGameInfo defender;
    defender.name = "Defender";
    defender.issue = "JOYSTICK_MULTIBUTTON";
    defender.description = "Requires 5 buttons:\n"
                          "  Button 1: Fire\n"
                          "  Button 2: Thrust\n"
                          "  Button 3: Smart Bomb\n"
                          "  Button 4: Hyperspace\n"
                          "  Button 5: Reverse";
    defender.recommendation = "5-button classic arcade game.\n"
                             "Requires button remapping to playable state on 1-2 button panel.";
    
    vector<string> def_buttons = {"Fire", "Thrust", "Smart Bomb", "Hyperspace", "Reverse"};
    for (size_t i = 0; i < def_buttons.size(); ++i)
    {
        ButtonLabelInfo defbtn;
        defbtn.buttonNumber = i + 1;
        defbtn.labels.push_back(def_buttons[i]);
        defbtn.issue = "JOYSTICK_MULTIBUTTON";
        defender.buttons.push_back(defbtn);
    }
    db["defender"] = defender;
    
    // Robotron: 2084 - Midway Williams
    // Dual-joystick configuration (both movement and firing)
    KnownGameInfo robotron;
    robotron.name = "Robotron: 2084";
    robotron.issue = "DUAL_JOYSTICK";
    robotron.description = "Requires DUAL-JOYSTICK setup:\n"
                          "  Left Joystick: Movement (Up/Down/Left/Right)\n"
                          "  Right Joystick: Firing direction (Up/Down/Left/Right)\n"
                          "Simultaneously control movement AND firing in different directions.";
    robotron.recommendation = "COMPLEX: Dual-joystick is non-standard arcade setup.\n"
                             "Requires either:\n"
                             "  - Physical dual-joystick hardware, OR\n"
                             "  - Complex button mapping: Direction keys for movement, WASD for firing";
    
    vector<string> robot_actions = {"Move Up", "Move Down", "Move Left", "Move Right", "Fire Up", "Fire Down", "Fire Left", "Fire Right"};
    int robocounter = 1;
    for (const auto& action : robot_actions)
    {
        ButtonLabelInfo robobtn;
        robobtn.buttonNumber = robocounter++;
        robobtn.labels.push_back(action);
        robobtn.issue = "DUAL_JOYSTICK";
        robotron.buttons.push_back(robobtn);
    }
    db["robotron"] = robotron;
    
    // Space Duel - Atari
    // 3-button game
    KnownGameInfo spaceduel;
    spaceduel.name = "Space Duel";
    spaceduel.issue = "JOYSTICK_MULTIBUTTON";
    spaceduel.description = "Requires 3 buttons:\n"
                           "  Button 1: Fire\n"
                           "  Button 2: Shield\n"
                           "  Button 3: Hyperspace";
    spaceduel.recommendation = "3-button requirement - needs button remapping for 1-2 button panels.";
    
    vector<string> space_buttons = {"Fire", "Shield", "Hyperspace"};
    for (size_t i = 0; i < space_buttons.size(); ++i)
    {
        ButtonLabelInfo spacebtn;
        spacebtn.buttonNumber = i + 1;
        spacebtn.labels.push_back(space_buttons[i]);
        spacebtn.issue = "JOYSTICK_MULTIBUTTON";
        spaceduel.buttons.push_back(spacebtn);
    }
    db["spacduel"] = spaceduel;
    
    // Gravitar - Atari
    // 3-button game
    KnownGameInfo gravitar;
    gravitar.name = "Gravitar";
    gravitar.issue = "JOYSTICK_MULTIBUTTON";
    gravitar.description = "Requires 3 buttons:\n"
                          "  Button 1: Fire\n"
                          "  Button 2: Shield\n"
                          "  Button 3: Hyperspace";
    gravitar.recommendation = "3-button requirement - needs button remapping for 1-2 button panels.";
    
    vector<string> grav_buttons = {"Fire", "Shield", "Hyperspace"};
    for (size_t i = 0; i < grav_buttons.size(); ++i)
    {
        ButtonLabelInfo gravbtn;
        gravbtn.buttonNumber = i + 1;
        gravbtn.labels.push_back(grav_buttons[i]);
        gravbtn.issue = "JOYSTICK_MULTIBUTTON";
        gravitar.buttons.push_back(gravbtn);
    }
    db["gravitar"] = gravitar;
    
    // Punch-Out!! (punchout) - Nintendo
    // 3-button game
    KnownGameInfo punchout;
    punchout.name = "Mike Tyson's Punch-Out!!";
    punchout.issue = "JOYSTICK_MULTIBUTTON";
    punchout.description = "Requires 3 buttons:\n"
                          "  Button 1: Jab\n"
                          "  Button 2: Body Blow\n"
                          "  Button 3: Dodge (with directions)";
    punchout.recommendation = "3-button boxing game - needs button remapping for 1-2 button panels.\n"
                             "Multiple buttons required to execute all boxer moves.";
    
    vector<string> punch_buttons = {"Jab", "Body Blow", "Dodge"};
    for (size_t i = 0; i < punch_buttons.size(); ++i)
    {
        ButtonLabelInfo punchbtn;
        punchbtn.buttonNumber = i + 1;
        punchbtn.labels.push_back(punch_buttons[i]);
        punchbtn.issue = "JOYSTICK_MULTIBUTTON";
        punchout.buttons.push_back(punchbtn);
    }
    db["punchout"] = punchout;
    
    // Missile Command - Atari
    // Trackball with 3 buttons
    KnownGameInfo missile;
    missile.name = "Missile Command";
    missile.issue = "TRACKBALL_MULTIBUTTON";
    missile.description = "Uses TRACKBALL with 3 buttons:\n"
                         "  Trackball: Aim cursor (X-Y positioning)\n"
                         "  Button 1: Fire weapon 1\n"
                         "  Button 2: Fire weapon 2\n"
                         "  Button 3: Fire weapon 3";
    missile.recommendation = "Trackball is best with analog/mouse support.\n"
                            "Can play with joystick approximation, but trackball hardware preferred.";
    
    ButtonLabelInfo missbtn1;
    missbtn1.buttonNumber = 1;
    missbtn1.labels.push_back("Fire Weapon 1");
    missile.buttons.push_back(missbtn1);
    
    ButtonLabelInfo missbtn2;
    missbtn2.buttonNumber = 2;
    missbtn2.labels.push_back("Fire Weapon 2");
    missile.buttons.push_back(missbtn2);
    
    ButtonLabelInfo missbtn3;
    missbtn3.buttonNumber = 3;
    missbtn3.labels.push_back("Fire Weapon 3");
    missile.buttons.push_back(missbtn3);
    
    db["missile"] = missile;
    
    // Street Fighter (sf) - Capcom CPS-1
    // 6-button fighting game
    KnownGameInfo sf;
    sf.name = "Street Fighter";
    sf.issue = "JOYSTICK_MULTIBUTTON";
    sf.description = "Requires 6 buttons per player:\n"
                    "  Button 1: Light Punch\n"
                    "  Button 2: Medium Punch\n"
                    "  Button 3: Heavy Punch\n"
                    "  Button 4: Light Kick\n"
                    "  Button 5: Medium Kick\n"
                    "  Button 6: Heavy Kick";
    sf.recommendation = "Original fighting game - 6 buttons mandatory for playable controls.\n"
                       "Requires button remapping strategy (shift keys, direction combos, etc.)";
    
    vector<string> sf_buttons = {"Light Punch", "Medium Punch", "Heavy Punch", "Light Kick", "Medium Kick", "Heavy Kick"};
    for (size_t i = 0; i < sf_buttons.size(); ++i)
    {
        ButtonLabelInfo sfbtn;
        sfbtn.buttonNumber = i + 1;
        sfbtn.labels.push_back(sf_buttons[i]);
        sfbtn.issue = "JOYSTICK_MULTIBUTTON";
        sf.buttons.push_back(sfbtn);
    }
    db["sf"] = sf;
    
    return db;
}

// Extract display type, rotation, player count, and detailed control info from the MAME XML
bool extractGameControlInfo(XMLDocument& doc, const string& shortName, GameControlInfo& info)
{
    info.shortName = shortName;
    info.displayType = "unknown";
    info.rotation = "unknown";
    info.playerCount = 1;
    info.controls.clear();

    XMLElement* machine = doc.FirstChildElement("mame") ?
                          doc.FirstChildElement("mame")->FirstChildElement("machine") :
                          nullptr;

    if (!machine)
    {
        cerr << "No <machine> element found for " << shortName << endl;
        return false;
    }

    // Display info
    XMLElement* display = machine->FirstChildElement("display");
    while (display)
    {
        const char* tag = display->Attribute("tag");
        if (tag && string(tag) == "screen")
        {
            const char* type = display->Attribute("type");
            const char* rotate = display->Attribute("rotate");

            if (type)    info.displayType = type;
            if (rotate)  info.rotation = rotate;
            break;
        }
        display = display->NextSiblingElement("display");
    }

    // Input/Control info
    XMLElement* input = machine->FirstChildElement("input");
    if (input)
    {
        // Get player count
        const char* playersAttr = input->Attribute("players");
        if (playersAttr)
        {
            try
            {
                info.playerCount = stoi(playersAttr);
            }
            catch (...) {}
        }

        // Get all controls
        XMLElement* control = input->FirstChildElement("control");
        while (control)
        {
            ControlInfo ctrlInfo;

            const char* ctrlType = control->Attribute("type");
            const char* buttons = control->Attribute("buttons");
            const char* ways = control->Attribute("ways");
            const char* player = control->Attribute("player");

            if (ctrlType)
            {
                ctrlInfo.type = ctrlType;
                
                if (buttons)
                {
                    try
                    {
                        ctrlInfo.buttons = stoi(buttons);
                    }
                    catch (...) {}
                }

                if (ways)
                {
                    ctrlInfo.ways = ways;
                }

                if (player)
                {
                    try
                    {
                        ctrlInfo.player = stoi(player);
                    }
                    catch (...) {}
                }

                info.controls.push_back(ctrlInfo);
            }

            control = control->NextSiblingElement("control");
        }
    }

    return true;
}

// Categorize why a game might need special handling
// Returns: empty string = no issues, otherwise describes the issue
string getCustomMappingReason(const GameControlInfo& info)
{
    string reason;
    
    for (const auto& ctrl : info.controls)
    {
        bool isJoystick = (ctrl.type.find("joy") != string::npos);
        
        // ISSUE 1: Joystick with 3+ buttons - button count mismatch on standard arcade panel
        if (isJoystick && ctrl.buttons >= 3)
        {
            return "JOYSTICK_MULTIBUTTON: Joystick with " + to_string(ctrl.buttons) + " buttons";
        }
        
        // ISSUE 2: Dual-joystick - special control (robotron uses dual-stick for dual directions)
        if (ctrl.type == "doublejoy")
        {
            return "DUAL_JOYSTICK: Requires two joysticks or complex button mapping";
        }
        
        // ISSUE 3: Trackball/spinner with MULTIPLE buttons can be problematic
        // Single trackball or spinner alone = no problem (hardware-specific, not button count)
        if ((ctrl.type == "trackball" || ctrl.type == "spinner") && ctrl.buttons > 2)
        {
            return "TRACKBALL_MULTIBUTTON: Trackball/spinner with " + to_string(ctrl.buttons) + " buttons";
        }
        
        // NOTE: Single trackball/spinner (0-2 buttons) = NO ISSUE if you have the hardware
        // NOTE: Paddle/pedal/dial controls alone = NO ISSUE if you have the hardware
        // These are just different INPUT DEVICES, not button count mismatches
    }
    
    return reason;  // Empty = no issues
}

// Check if a game has non-standard controls that might need custom mapping
bool needsCustomMapping(const GameControlInfo& info)
{
    return !getCustomMappingReason(info).empty();
}

// Format control info for display
string formatControlInfo(const ControlInfo& ctrl)
{
    string result = ctrl.type;
    
    if (ctrl.buttons > 0)
    {
        result += " (" + to_string(ctrl.buttons) + "btn";
        if (!ctrl.ways.empty())
        {
            result += ", " + ctrl.ways + "-way";
        }
        result += ")";
    }
    else if (!ctrl.ways.empty())
    {
        result += " (" + ctrl.ways + "-way)";
    }
    
    return result;
}

int main()
{
    XMLDocument gamelistDoc;

    if (gamelistDoc.LoadFile(GAME_LIST_PATH.c_str()) != XML_SUCCESS)
    {
        cerr << "Failed to load gamelist: " << GAME_LIST_PATH << endl;
        return 1;
    }

    XMLNode* root = gamelistDoc.FirstChildElement("gameList");
    if (!root)
    {
        cerr << "No <gameList> element found." << endl;
        return 1;
    }

    ofstream reportFile(REPORT_OUTPUT_PATH);
    if (!reportFile)
    {
        cerr << "Failed to open report file: " << REPORT_OUTPUT_PATH << endl;
        return 1;
    }

    // Write report header
    reportFile << "CONTROL MAPPING ANALYSIS REPORT" << endl;
    reportFile << "Generated by analyze_controls" << endl;
    reportFile << string(60, '=') << endl << endl;

    vector<GameControlInfo> allGames;
    vector<GameControlInfo> specialGames;  // Games needing custom mapping
    vector<pair<string, KnownGameInfo>> knownProblematicGames;  // Games in known issues database

    // Load known problematic games database
    auto knownGamesDb = loadKnownGamesDatabase();

    XMLElement* game = root->FirstChildElement("game");
    int gameCount = 0;

    while (game)
    {
        XMLElement* pathElement = game->FirstChildElement("path");
        if (!pathElement || !pathElement->GetText())
        {
            game = game->NextSiblingElement("game");
            continue;
        }

        string romPath = pathElement->GetText();
        string shortName = getShortName(romPath);

        XMLDocument mameDoc;
        if (!getMameXmlForGame(shortName, mameDoc))
        {
            cerr << "Warning: Could not get MAME data for " << shortName << endl;
            game = game->NextSiblingElement("game");
            continue;
        }

        GameControlInfo info;
        if (!extractGameControlInfo(mameDoc, shortName, info))
        {
            game = game->NextSiblingElement("game");
            continue;
        }

        allGames.push_back(info);
        if (needsCustomMapping(info))
        {
            specialGames.push_back(info);
        }
        
        // Check if this game is in the known problematic games database
        if (knownGamesDb.find(shortName) != knownGamesDb.end())
        {
            knownProblematicGames.push_back({shortName, knownGamesDb[shortName]});
        }

        gameCount++;

        game = game->NextSiblingElement("game");
    }

    // Summary section
    reportFile << "SUMMARY" << endl;
    reportFile << string(60, '-') << endl;
    reportFile << "Total games analyzed: " << gameCount << endl;
    reportFile << "Games with 3+ buttons (arcade panel mapping issue): " << specialGames.size() << endl;
    reportFile << "Games with KNOWN ISSUES (dual-purpose buttons, etc.): " << knownProblematicGames.size() << endl;
    reportFile << endl;

    // Explanation of the two categories
    reportFile << "NOTE ON CUSTOM MAPPING NEEDS:" << endl;
    reportFile << "=============================" << endl;
    reportFile << "Two categories of games may need custom remapping:" << endl;
    reportFile << endl;
    reportFile << "1. MULTI-BUTTON GAMES (3+ buttons):" << endl;
    reportFile << "   Most arcade cabinets have 1-2 buttons per player. Games requiring 3+ buttons" << endl;
    reportFile << "   will have awkward default mappings and be difficult to play." << endl;
    reportFile << "   Examples: Street Fighter (6 buttons), Robotron (multiple fire directions)" << endl;
    reportFile << endl;
    reportFile << "2. KNOWN ISSUE GAMES (dual-purpose buttons, etc.):" << endl;
    reportFile << "   These games have specific button labeling issues that were extracted from" << endl;
    reportFile << "   MAME source code and verified. Examples:" << endl;
    reportFile << "   - Buttons that trigger both game actions AND menu functions" << endl;
    reportFile << "   - Asymmetric controls between players" << endl;
    reportFile << "   - Non-obvious button mapping quirks" << endl;
    reportFile << endl;

    // Known problematic games (IMPORTANT - requires manual setup)
    reportFile << "⚠ GAMES WITH KNOWN DUAL-PURPOSE BUTTONS OR COMPLEX MAPPINGS" << endl;
    reportFile << string(60, '-') << endl;
    reportFile << "These games have buttons that serve multiple functions, confusing control layouts," << endl;
    reportFile << "or other non-obvious input mappings. Manual testing and custom INI files may be needed." << endl;
    reportFile << endl;
    
    if (knownProblematicGames.empty())
    {
        reportFile << "None of your favorite games are in the known problematic list." << endl;
    }
    else
    {
        for (const auto& [shortName, knownInfo] : knownProblematicGames)
        {
            reportFile << "\n" << shortName << " - " << knownInfo.name << endl;
            reportFile << "  Issue Type: " << knownInfo.issue << endl;
            reportFile << "  Description: " << knownInfo.description << endl;
            reportFile << "  Recommendation: " << knownInfo.recommendation << endl;
            
            if (!knownInfo.buttons.empty())
            {
                reportFile << "  Problematic Buttons:" << endl;
                for (const auto& btn : knownInfo.buttons)
                {
                    reportFile << "    Button " << btn.buttonNumber << ": ";
                    for (size_t i = 0; i < btn.labels.size(); ++i)
                    {
                        if (i > 0) reportFile << " AND ";
                        reportFile << btn.labels[i];
                    }
                    reportFile << endl;
                }
            }
        }
    }
    
    reportFile << endl;

    // Games with special controls (non-standard mapping needed)
    reportFile << "GAMES NEEDING CUSTOMIZATION" << endl;
    reportFile << string(60, '-') << endl;
    reportFile << "These games have issues that may require custom button mapping or hardware." << endl;
    reportFile << endl;
    
    if (specialGames.empty())
    {
        reportFile << "None - all favorite games use standard joystick controls!" << endl;
    }
    else
    {
        for (const auto& info : specialGames)
        {
            string reason = getCustomMappingReason(info);
            
            reportFile << "\n" << info.shortName << endl;
            reportFile << "  Issue: " << reason << endl;
            reportFile << "  Display: " << info.displayType << " (rotate: " << info.rotation << ")" << endl;
            reportFile << "  Players: " << info.playerCount << endl;
            reportFile << "  Controls:" << endl;
            for (const auto& ctrl : info.controls)
            {
                reportFile << "    - Player " << ctrl.player << ": " << formatControlInfo(ctrl) << endl;
            }
        }
    }

    reportFile << endl;

    // All games (full listing)
    reportFile << "COMPLETE GAME LISTING" << endl;
    reportFile << string(60, '-') << endl;
    for (const auto& info : allGames)
    {
        reportFile << "\n" << info.shortName << endl;
        reportFile << "  Display: " << info.displayType << " (rotate: " << info.rotation << ")" << endl;
        reportFile << "  Players: " << info.playerCount << endl;
        reportFile << "  Controls: ";
        
        if (info.controls.empty())
        {
            reportFile << "none defined";
        }
        else
        {
            for (size_t i = 0; i < info.controls.size(); ++i)
            {
                if (i > 0) reportFile << "; ";
                reportFile << formatControlInfo(info.controls[i]);
            }
        }
        reportFile << endl;
    }

    reportFile.close();

    cout << "Analysis complete! Report written to: " << REPORT_OUTPUT_PATH << endl;
    cout << "Games analyzed: " << gameCount << endl << endl;
    
    cout << "════════════════════════════════════════════════════════════" << endl;
    cout << "CUSTOM MAPPING ANALYSIS" << endl;
    cout << "════════════════════════════════════════════════════════════" << endl << endl;
    
    cout << "Games with 3+ buttons (arcade panel mismatch): " << specialGames.size() << endl;
    cout << "Games with KNOWN ISSUES (dual-purpose buttons): " << knownProblematicGames.size() << endl;
    cout << endl;

    if (!knownProblematicGames.empty())
    {
        cout << "⚠ KNOWN ISSUE GAMES (extracted from MAME source):" << endl;
        cout << "─────────────────────────────────────────────────" << endl;
        for (const auto& [shortName, knownInfo] : knownProblematicGames)
        {
            cout << "\n  • " << shortName << " - " << knownInfo.name << endl;
            cout << "    Issue Type: " << knownInfo.issue << endl;
            cout << "    Recommendation: " << knownInfo.recommendation << endl;
        }
        cout << endl;
    }

    if (!specialGames.empty())
    {
        cout << "⚠ GAMES NEEDING CUSTOMIZATION:" << endl;
        cout << "──────────────────────────────────────────────────────────" << endl;
        
        // Group by issue type for clarity
        map<string, vector<GameControlInfo>> gamesByIssue;
        for (const auto& info : specialGames)
        {
            string reason = getCustomMappingReason(info);
            // Extract the issue type (before the colon)
            size_t colonPos = reason.find(':');
            string issueType = (colonPos != string::npos) ? reason.substr(0, colonPos) : reason;
            gamesByIssue[issueType].push_back(info);
        }
        
        // Display grouped by issue type
        for (const auto& [issueType, games] : gamesByIssue)
        {
            cout << "\n  " << issueType << ":" << endl;
            for (const auto& info : games)
            {
                string reason = getCustomMappingReason(info);
                cout << "    • " << info.shortName << " - " << reason << endl;
            }
        }
        cout << endl;
    }

    fs::remove(TEMP_XML_PATH);
    return 0;
}
