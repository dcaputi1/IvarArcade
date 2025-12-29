// loads gamelist.xml, for each game entry (favorite)
// - generate shader file for raster games based on vert/horz orientation
// - generate game.ini files for 4-way (sticky diagonal) control
// 
#include <iostream>
#include <fstream>
#include <map>
#include <string>
#include <tuple>
#include <filesystem>
#include <cstdlib>
#include <tinyxml2.h>

using namespace std;
using namespace tinyxml2;
namespace fs = std::filesystem;

// Constants
const string GAME_LIST_PATH = "/opt/retropie/configs/all/emulationstation/gamelists/arcade/gamelist.xml";
const string TEMP_XML_PATH = "/tmp/mame_listxml_temp.xml";
const string SHADER_OUTPUT_DIR = "/opt/retropie/configs/all/retroarch/config/MAME/";
const string INI_OUTPUT_DIR = "/opt/retropie/emulators/mame/ini/";

struct GameInfo
{
    string shortName;
    string displayType;
    string rotation;
    int ways;
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
    string command = "mame -listxml " + shortName + " > " + TEMP_XML_PATH;
    int result = system(command.c_str());

    if (result != 0)
    {
        cerr << "Failed to run command: " << command << endl;
        return false;
    }

    return doc.LoadFile(TEMP_XML_PATH.c_str()) == XML_SUCCESS;
}

// Extract display type, rotation, and joystick ways from the MAME XML
bool extractGameInfo(XMLDocument& doc, const string& shortName, GameInfo& info)
{
    info.shortName = shortName;
    info.displayType = "unknown";
    info.rotation = "unknown";
    info.ways = -1;

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

    // Joystick info
    XMLElement* input = machine->FirstChildElement("input");
    if (input)
    {
        XMLElement* control = input->FirstChildElement("control");
        while (control)
        {
            const char* ctrlType = control->Attribute("type");
            const char* waysAttr = control->Attribute("ways");

            if (ctrlType && string(ctrlType) == "joy" && waysAttr)
            {
                try
                {
                    info.ways = stoi(waysAttr);
                }
                catch (...)
                {
                    cerr << "Invalid 'ways' value for " << shortName << endl;
                }
                break;
            }

            control = control->NextSiblingElement("control");
        }
    }

    return true;
}

// Write shader preset file based on display type and rotation
void writeShaderFile(const GameInfo& info)
{
    if (info.displayType != "raster")
    {
        return;
    }

    string filePath = SHADER_OUTPUT_DIR + info.shortName + ".glslp";
    string line = (info.rotation == "0")
                  ? "#reference \"../../shaders/crt-pi.glslp\""
                  : "#reference \"../../shaders/crt-pi-vertical.glslp\"";

    ofstream out(filePath);
    if (!out)
    {
        cerr << "Failed to write shader file: " << filePath << endl;
        return;
    }

    out << line << endl;
    out.close();
}

// Write .ini file for joystick mapping if needed
void writeJoystickIni(const GameInfo& info)
{
    // Special case: qbert's joystick is physically rotated 45°,
    // so we treat it as an 8-way joystick even though it's defined as 4-way.
    if (info.shortName == "qbert")
    {
        return;
    }

    if (info.ways == 8 || info.ways == -1)
    {
        // 8-way joystick or no joystick: no .ini file needed
        return;
    }

    string filePath = INI_OUTPUT_DIR + info.shortName + ".ini";

    ofstream out(filePath);
    if (!out)
    {
        cerr << "Failed to write INI file: " << filePath << endl;
        return;
    }

    out << "joystick_map s8.4s8.44s8.4445" << endl;
    out.close();
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

    XMLElement* game = root->FirstChildElement("game");

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
            game = game->NextSiblingElement("game");
            continue;
        }

        GameInfo info;
        if (!extractGameInfo(mameDoc, shortName, info))
        {
            game = game->NextSiblingElement("game");
            continue;
        }

        writeShaderFile(info);
        writeJoystickIni(info);

        // Optional summary output
        cout << "Game: " << info.shortName
             << ", Type: " << info.displayType
             << ", Rotation: " << info.rotation
             << ", Ways: " << (info.ways >= 0 ? to_string(info.ways) : "n/a")
             << endl;

        game = game->NextSiblingElement("game");
    }

    fs::remove(TEMP_XML_PATH);
    return 0;
}
