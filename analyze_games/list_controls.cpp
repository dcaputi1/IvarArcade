// List all control inputs for every game in favorites
// Includes DETAILED BUTTON LABELS extracted from MAME 0.276 source code
// For each game, displays:
// - Short name and full game name
// - All input control types from MAME (buttons, joysticks, wheels, pedals, etc.)
// - INDIVIDUAL BUTTON NAMES/LABELS from MAME source code
// - Button counts and directional information
// - Recommended hardware mappings
//
// This tool shows EVERYTHING input-related you might need to map to your hardware:
// Joysticks, buttons, wheels, pedals, knobs, light guns, trackballs, flight yokes, etc.
// WITH FULL BUTTON LABEL DATA FROM MAME SOURCE CODE
//
#include <iostream>
#include <fstream>
#include <sstream>
#include <map>
#include <vector>
#include <string>
#include <filesystem>
#include <cstdlib>
#include <algorithm>
#include <regex>
#include <iterator>
#include <tinyxml2.h>

using namespace std;
using namespace tinyxml2;
namespace fs = std::filesystem;

// Constants
const string GAME_LIST_PATH = "/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml";
const string TEMP_XML_PATH = "/tmp/mame_listxml_temp.xml";
// Write report to project workspace instead of system-wide RetroPie config
const string CONTROL_LIST_OUTPUT = "./CONTROL_LIST.txt";
const string MAME_BASE_URL = "https://raw.githubusercontent.com/mamedev/mame/mame0276/src/mame/";

struct ControlInput
{
    string name;          // PORT_NAME or button/key identifier
    string type;          // BUTTON, SWITCH, JOY, etc.
    string defaultKey;    // The key/button it maps to (e.g., "Button 1", "D-Pad Up", "P")
    int player = 1;       // Player number
};

struct GameInputInfo
{
    string shortName;
    string fullName;
    string sourceFile;
    string cloneOf;
    string romOf;
    int declaredButtonCount = 0; // Number of buttons declared in control summary
    vector<ControlInput> inputs;
    vector<string> buttonLabels;  // Individual button labels parsed from MAME source
    string labelDiagnostic;       // Error/diagnostic message explaining label lookup result
};

// Download MAME source file if not already cached
string downloadSourceFile(const string& sourceFile)
{
    fs::path cacheDir = "/tmp/mame_sources";
    fs::path dest = cacheDir / fs::path(sourceFile);
    fs::create_directories(dest.parent_path());

    if (!fs::exists(dest) || fs::file_size(dest) == 0)
    {
        string cmd = "curl -s \"" + MAME_BASE_URL + sourceFile + "\" -o \"" + dest.string() + "\"";
        system(cmd.c_str());
    }
    return dest.string();
}

// Extract PORT_NAME labels from MAME source INPUT_PORTS blocks, trying multiple base names
vector<string> parseButtonLabelsFromSource(const string& sourcePath, const vector<string>& baseNames)
{
    vector<string> labels;
    if (!fs::exists(sourcePath)) return labels;

    ifstream in(sourcePath);
    if (!in.is_open()) return labels;

    string fileContent((istreambuf_iterator<char>(in)), istreambuf_iterator<char>());

    // Match both "INPUT_PORTS_START" and "static INPUT_PORTS_START"
    regex startRegex("(?:static\\s+)?INPUT_PORTS_START\\(\\s*([^)\\s]+)\\s*\\)");
    regex portNameRegex("PORT_NAME\\(\\\"([^\\\"]+)\\\"\\)");

    map<string, vector<string>> blockLabels;
    auto startBegin = sregex_iterator(fileContent.begin(), fileContent.end(), startRegex);
    auto startEnd = sregex_iterator();

    for (auto it = startBegin; it != startEnd; ++it)
    {
        string blockName = (*it)[1];
        size_t blockStart = (*it).position();
        size_t searchStart = blockStart + (*it).length();
        size_t blockEnd = fileContent.find("INPUT_PORTS_END", searchStart);
        if (blockEnd == string::npos)
            continue;

        string block = fileContent.substr(blockStart, blockEnd - blockStart);
        vector<string> blockPorts;
        auto portBegin = sregex_iterator(block.begin(), block.end(), portNameRegex);
        auto portEnd = sregex_iterator();
        for (auto pit = portBegin; pit != portEnd; ++pit)
        {
            blockPorts.push_back((*pit)[1]);
        }

        if (!blockPorts.empty())
        {
            blockLabels[blockName] = blockPorts;
        }
    }

    auto chooseForCandidate = [&](const string& candidate) -> bool
    {
        auto it = blockLabels.find(candidate);
        if (it != blockLabels.end())
        {
            labels = it->second;
            return true;
        }
        return false;
    };

    for (const auto& name : baseNames)
    {
        if (!name.empty() && chooseForCandidate(name))
            return labels;
    }

    // Fallback: choose the block with the most labels if no candidate matched
    size_t maxCount = 0;
    for (const auto& entry : blockLabels)
    {
        const auto& blockPorts = entry.second;
        if (blockPorts.size() > maxCount)
        {
            maxCount = blockPorts.size();
            labels = blockPorts;
        }
    }

    return labels;
}

// Fetch button labels by downloading the driver source and trying likely INPUT_PORTS names
// Also builds diagnostic message explaining the lookup process and result
pair<vector<string>, string> fetchButtonLabelsWithDiagnostics(const GameInputInfo& info)
{
    stringstream diag;
    vector<string> labels;

    if (info.sourceFile.empty())
    {
        diag << "No source file found in MAME metadata";
        return {labels, diag.str()};
    }

    diag << "Source: " << info.sourceFile << " | ";

    string sourcePath = downloadSourceFile(info.sourceFile);
    
    if (!fs::exists(sourcePath) || fs::file_size(sourcePath) == 0)
    {
        diag << "Download/parse failed (file empty or missing)";
        return {labels, diag.str()};
    }

    diag << "Downloaded | ";

    vector<string> candidates;
    candidates.push_back(info.shortName);
    if (!info.cloneOf.empty())
        candidates.push_back(info.cloneOf);
    if (!info.romOf.empty())
        candidates.push_back(info.romOf);

    string driverBase = fs::path(info.sourceFile).stem().string();
    if (!driverBase.empty())
        candidates.push_back(driverBase);

    diag << "Trying: [";
    for (size_t i = 0; i < candidates.size(); i++)
    {
        diag << candidates[i];
        if (i < candidates.size() - 1) diag << ", ";
    }
    diag << "] | ";

    labels = parseButtonLabelsFromSource(sourcePath, candidates);

    if (!labels.empty())
    {
        diag << "Found " << labels.size() << " labels";
        // Check if number of labels matches declared buttons
        if (info.declaredButtonCount > 0 && (int)labels.size() != info.declaredButtonCount)
        {
            diag << " (⚠ expected " << info.declaredButtonCount << " for " << info.declaredButtonCount 
                 << " declared buttons)";
        }
    }
    else
    {
        diag << "No INPUT_PORTS blocks matched (check driver structure)";
    }

    return {labels, diag.str()};
}

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
        return false;
    }

    return doc.LoadFile(TEMP_XML_PATH.c_str()) == XML_SUCCESS;
}

// Parse MAME INPUT and PORT elements to get ALL input mappings
GameInputInfo parseGameInputs(const string& shortName, const string& fullName)
{
    GameInputInfo info;
    info.shortName = shortName;
    info.fullName = fullName;

    XMLDocument doc;
    if (!getMameXmlForGame(shortName, doc))
    {
        return info;
    }

    XMLElement* root = doc.RootElement();
    if (!root)
    {
        return info;
    }

    XMLElement* gameElement = root->FirstChildElement("machine");
    if (!gameElement)
    {
        return info;
    }

    const char* sourceAttr = gameElement->Attribute("sourcefile");
    if (sourceAttr)
    {
        info.sourceFile = sourceAttr;
    }

    const char* cloneAttr = gameElement->Attribute("cloneof");
    if (cloneAttr)
    {
        info.cloneOf = cloneAttr;
    }

    const char* romOfAttr = gameElement->Attribute("romof");
    if (romOfAttr)
    {
        info.romOf = romOfAttr;
    }

    // First, get high-level control summary from INPUT element
    XMLElement* inputElement = gameElement->FirstChildElement("input");
    if (inputElement)
    {
        // Iterate through all CONTROL elements to show control summary
        for (XMLElement* control = inputElement->FirstChildElement("control");
             control != nullptr;
             control = control->NextSiblingElement("control"))
        {
            const char* typeAttr = control->Attribute("type");
            const char* buttonsAttr = control->Attribute("buttons");
            const char* playerAttr = control->Attribute("player");
            const char* waysAttr = control->Attribute("ways");
            
            if (!typeAttr)
                continue;

            int player = playerAttr ? atoi(playerAttr) : 1;
            string controlType = typeAttr;
            string controlName = controlType;
            
            if (buttonsAttr)
            {
                controlName += " (";
                controlName += buttonsAttr;
                controlName += " buttons)";
                // Track total button count across all controls
                info.declaredButtonCount += atoi(buttonsAttr);
            }
            
            if (controlType == "joy" && waysAttr)
            {
                controlName += " ";
                controlName += waysAttr;
                controlName += "-way";
            }

            ControlInput input;
            input.name = controlName;
            input.type = controlType;
            input.player = player;
            
            if (controlType == "joy")
            {
                input.defaultKey = waysAttr ? string("Joystick (") + waysAttr + "-way, 8 directions)" : "Joystick (8-way)";
            }
            else if (controlType == "button")
            {
                if (buttonsAttr)
                {
                    int btnCount = atoi(buttonsAttr);
                    input.defaultKey = to_string(btnCount) + " buttons";
                }
                else
                {
                    input.defaultKey = "Button controls";
                }
            }
            else if (controlType == "paddle" || controlType == "paddle_h" || controlType == "paddle_v")
            {
                input.defaultKey = "Paddle/Potentiometer (analog horizontal)";
            }
            else if (controlType == "dial" || controlType == "dial_h" || controlType == "dial_v")
            {
                input.defaultKey = "Dial/Spinner (analog rotary)";
            }
            else if (controlType == "trackball" || controlType == "trackball_h" || controlType == "trackball_v")
            {
                input.defaultKey = "Trackball (X/Y positioning, analog)";
                if (buttonsAttr)
                {
                    input.defaultKey += " + " + string(buttonsAttr) + " buttons";
                }
            }
            else if (controlType == "lightgun" || controlType == "lightgun_h" || controlType == "lightgun_v")
            {
                input.defaultKey = "Light gun (X/Y targeting + trigger)";
                if (buttonsAttr)
                {
                    input.defaultKey += " + " + string(buttonsAttr) + " additional buttons";
                }
            }
            else if (controlType == "pedal" || controlType == "pedal_h" || controlType == "pedal_v")
            {
                input.defaultKey = "Pedal/Throttle (analog axis)";
            }
            else if (controlType == "stick")
            {
                input.defaultKey = "Stick/Joystick (4-way or 8-way movement)";
            }
            else if (controlType == "doublejoy")
            {
                input.defaultKey = "Dual joysticks (movement + firing, 2 × 8-way)";
            }
            else if (controlType == "wheel" || controlType == "wheel_h" || controlType == "wheel_v")
            {
                input.defaultKey = "Steering wheel (analog rotary)";
                if (buttonsAttr)
                {
                    input.defaultKey += " + " + string(buttonsAttr) + " buttons";
                }
            }
            else
            {
                input.defaultKey = "Hardware: " + controlType;
            }
            
            input.name = "[Control] " + input.name;
            info.inputs.push_back(input);
        }
    }

    // Now get ALL port-level input definitions
    for (XMLElement* port = gameElement->FirstChildElement("port");
         port != nullptr;
         port = port->NextSiblingElement("port"))
    {
        const char* portTag = port->Attribute("tag");
        if (!portTag)
            continue;

        string tag = portTag;
        
        // Determine player from port tag
        int player = 1;
        if (tag.find(":P2") != string::npos || tag.find("p2") != string::npos)
            player = 2;
        else if (tag.find(":P3") != string::npos || tag.find("p3") != string::npos)
            player = 3;
        else if (tag.find(":P4") != string::npos || tag.find("p4") != string::npos)
            player = 4;

        // Extract all input definitions from this port
        // Iterate through all elements in the port
        for (XMLElement* elem = port->FirstChildElement();
             elem != nullptr;
             elem = elem->NextSiblingElement())
        {
            string elemName = elem->Name();
            
            // Skip comment elements
            if (elemName[0] == '#')
                continue;

            // Parse each input element type
            if (elemName == "newseq" || elemName == "seq")
            {
                const char* seqType = elem->Attribute("type");
                if (!seqType)
                    continue;

                string inputType = seqType;
                const char* keySeq = elem->GetText();
                string keyAssignment = keySeq ? keySeq : "";
                
                // Clean whitespace
                if (!keyAssignment.empty())
                {
                    keyAssignment.erase(0, keyAssignment.find_first_not_of(" \t\n\r"));
                    keyAssignment.erase(keyAssignment.find_last_not_of(" \t\n\r") + 1);
                }

                ControlInput input;
                input.name = tag;
                input.type = inputType;
                input.player = player;
                input.defaultKey = keyAssignment;
                info.inputs.push_back(input);
            }
        }
    }

    return info;
}

int main(int argc, char* argv[])
{
    // Check for custom gamelist path argument
    string gamelistPath = GAME_LIST_PATH;
    if (argc > 1)
    {
        gamelistPath = argv[1];
    }

    // Load the gamelist
    XMLDocument gamelistDoc;
    if (gamelistDoc.LoadFile(gamelistPath.c_str()) != XML_SUCCESS)
    {
        cerr << "Error loading gamelist from: " << gamelistPath << endl;
        return 1;
    }

    XMLElement* root = gamelistDoc.RootElement();
    if (!root)
    {
        cerr << "Invalid gamelist XML" << endl;
        return 1;
    }

    // Output file
    ofstream outFile(CONTROL_LIST_OUTPUT);
    if (!outFile.is_open())
    {
        cerr << "Cannot open output file: " << CONTROL_LIST_OUTPUT << endl;
        return 1;
    }

    outFile << "╔════════════════════════════════════════════════════════════════════╗" << endl;
    outFile << "║           COMPREHENSIVE INPUT DEVICE LISTING                      ║" << endl;
    outFile << "║   ALL Control Types: Joysticks, Buttons, Wheels, Pedals, etc.    ║" << endl;
    outFile << "╚════════════════════════════════════════════════════════════════════╝" << endl;
    outFile << endl;
    outFile << "Generated from MAME 0.276 machine definitions" << endl;
    outFile << "This file shows EVERY input device each game requires:" << endl;
    outFile << "  - Joysticks (with direction ways)" << endl;
    outFile << "  - All buttons and their counts" << endl;
    outFile << "  - Analog controls (pedals, paddles, dials, wheels)" << endl;
    outFile << "  - Specialized input (trackballs, light guns, flight yokes)" << endl;
    outFile << "Use this to understand your hardware mapping requirements." << endl;
    outFile << endl << endl;

    cout << "Processing games..." << endl;
    int gameCount = 0;

    // Iterate through all games
    for (XMLElement* game = root->FirstChildElement("game");
         game != nullptr;
         game = game->NextSiblingElement("game"))
    {
        const char* path = game->FirstChildElement("path")->GetText();
        const char* name = game->FirstChildElement("name")->GetText();
        
        if (!path || !name)
            continue;

        string shortName = getShortName(path);
        gameCount++;

        cout << "  [" << gameCount << "] " << shortName << " - " << name << endl;

        // Parse inputs for this game
        GameInputInfo gameInfo = parseGameInputs(shortName, name);
        auto [labels, diagnostic] = fetchButtonLabelsWithDiagnostics(gameInfo);
        gameInfo.buttonLabels = labels;
        gameInfo.labelDiagnostic = diagnostic;

        // Write to file
        outFile << "═══════════════════════════════════════════════════════════════════" << endl;
        outFile << shortName << " - " << gameInfo.fullName << endl;
        outFile << "═══════════════════════════════════════════════════════════════════" << endl;

        if (gameInfo.inputs.empty())
        {
            outFile << "  [No input ports found]" << endl;
        }
        else
        {
            // Separate control summaries from detailed port mappings
            vector<ControlInput> controlSummary;
            vector<ControlInput> portMappings;
            
            for (const auto& input : gameInfo.inputs)
            {
                if (input.name.find("[Control]") != string::npos)
                {
                    controlSummary.push_back(input);
                }
                else
                {
                    portMappings.push_back(input);
                }
            }

            // Show control summary first
            if (!controlSummary.empty())
            {
                outFile << endl << "  ▼ CONTROL SUMMARY:" << endl;
                map<int, vector<ControlInput>> ctrlByPlayer;
                for (const auto& input : controlSummary)
                {
                    ctrlByPlayer[input.player].push_back(input);
                }
                
                for (const auto& [player, inputs] : ctrlByPlayer)
                {
                    outFile << "    Player " << player << ":" << endl;
                    for (const auto& input : inputs)
                    {
                        // Strip the [Control] tag for cleaner display
                        string cleanName = input.name;
                        size_t pos = cleanName.find("[Control] ");
                        if (pos != string::npos)
                        {
                            cleanName.erase(pos, 10);
                        }
                        outFile << "      • " << cleanName << endl;
                        if (!input.defaultKey.empty())
                        {
                            outFile << "        → " << input.defaultKey << endl;
                        }
                    }
                }
            }
            
            // Show button labels if available
            if (!gameInfo.buttonLabels.empty())
            {
                outFile << endl << "  ▼ BUTTON LABELS (from MAME source code):" << endl;
                int btnNum = 1;
                for (const auto& label : gameInfo.buttonLabels)
                {
                    outFile << "    Button " << btnNum << ": " << label << endl;
                    btnNum++;
                }
            }
            
            // Always show diagnostic if there's a count mismatch or no labels found
            bool hasCountMismatch = (gameInfo.declaredButtonCount > 0 && 
                                    (int)gameInfo.buttonLabels.size() != gameInfo.declaredButtonCount);
            if (gameInfo.buttonLabels.empty() || hasCountMismatch)
            {
                if (!gameInfo.buttonLabels.empty())
                {
                    outFile << endl << "  ⚠ INCOMPLETE LABEL DATA:" << endl;
                }
                else
                {
                    outFile << endl << "  ⚠ BUTTON LABEL LOOKUP FAILED:" << endl;
                }
                outFile << "    " << gameInfo.labelDiagnostic << endl;
            }

            // Show detailed port mappings
            if (!portMappings.empty())
            {
                outFile << endl << "  ▼ DETAILED INPUT PORTS:" << endl;
                map<int, vector<ControlInput>> portsByPlayer;
                for (const auto& input : portMappings)
                {
                    portsByPlayer[input.player].push_back(input);
                }
                
                for (const auto& [player, inputs] : portsByPlayer)
                {
                    outFile << "    Player " << player << ":" << endl;
                    for (const auto& input : inputs)
                    {
                        outFile << "      ◆ " << input.name << endl;
                        outFile << "          Type: " << input.type << endl;
                        if (!input.defaultKey.empty())
                        {
                            outFile << "          Maps to: " << input.defaultKey << endl;
                        }
                    }
                }
            }
        }

        outFile << endl;
    }

    outFile << endl;
    outFile << "═══════════════════════════════════════════════════════════════════" << endl;
    outFile << "SUMMARY" << endl;
    outFile << "═══════════════════════════════════════════════════════════════════" << endl;
    outFile << "Total games processed: " << gameCount << endl;

    outFile.close();

    cout << endl;
    cout << "Complete! Processed " << gameCount << " games." << endl;
    cout << "Output written to: " << CONTROL_LIST_OUTPUT << endl;

    // Clean up temp file
    fs::remove(TEMP_XML_PATH);

    return 0;
}
