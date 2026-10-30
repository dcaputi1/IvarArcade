local plugin_path = "McAtariPi5/opt/retropie/emulators/mame/plugins/marquee/init.lua"
local map_source = "McAtariPi5/opt/retropie/configs/all/mame_ctrlr_map.txt"
local map_path = "/opt/retropie/configs/all/mame_ctrlr_map.txt"
local panel_path, ctrlr_path = "/testhome/.panel", "/testhome/.ctrlr"
local fifo_path = "/tmp/dmarquees_cmd"
local real_open, real_getenv = io.open, os.getenv
local files, callbacks, errors, commands, writes, reads, failures
local rom, active_ctrlr
local passed = 0

local function check(condition, message)
    assert(condition, message)
    passed = passed + 1
end

local source = assert(real_open(map_source, "r"))
local deployed_map = assert(source:read("*a"))
assert(source:close())

local function setup(map)
    files = {
        [map_path] = map or deployed_map,
        [panel_path] = "DC\n",
        [ctrlr_path] = "dcpanel1.cfg\n"
    }
    callbacks, errors, commands, writes, reads, failures = {}, {}, {}, {}, {}, {}
    rom, active_ctrlr = "___empty", "dcpanel1"
    os.getenv = function(key)
        if key == "HOME" then return "/testhome" end
        return real_getenv(key)
    end
    io.open = function(path, mode)
        if failures[path] == "open" then return nil, "permission denied", 13 end
        if mode == "r" then
            reads[path] = (reads[path] or 0) + 1
            if not files[path] then return nil, "not found", 2 end
            return {
                read = function(_, format)
                    if failures[path] == "read" then return nil, "read failed" end
                    if format == "*l" then return files[path]:match("([^\r\n]*)") end
                    assert(format == "*a", "unexpected read format")
                    return files[path]
                end,
                close = function()
                    if failures[path] == "close" then return nil, "close failed" end
                    return true
                end
            }
        end
        assert(mode == "w", "unexpected open mode")
        return {
            write = function(self, content)
                if failures[path] == "write" then return nil, "write failed" end
                table.insert(writes, path)
                if path == fifo_path then
                    table.insert(commands, {
                        command = content,
                        panel = files[panel_path],
                        ctrlr = files[ctrlr_path],
                        active = active_ctrlr
                    })
                else
                    files[path] = content
                end
                return self
            end,
            close = function()
                if failures[path] == "close" then return nil, "close failed" end
                return true
            end
        }
    end
    emu = {
        romname = function() return rom end,
        print_error = function(message) table.insert(errors, message) end,
        register_before_load_settings = function(cb) callbacks.before_settings = cb end,
        add_machine_reset_notifier = function(cb) callbacks.reset = cb; return {} end,
        add_machine_stop_notifier = function(cb) callbacks.stop = cb; return {} end,
        remove_notifier = function() end,
        register_menu = function(cb, populate)
            callbacks.menu, callbacks.populate = cb, populate
        end
    }
    manager = { machine = { options = { entries = { ctrlr = {
        value = function(_, value) active_ctrlr = value end
    } } } } }
    dofile(plugin_path).startplugin()
end

local function start_game(name, expected_ctrlr, expected_panel)
    rom = name
    local command_count = #commands
    callbacks.before_settings()
    check(#commands == command_count, "do not request artwork before settings load")
    check(active_ctrlr == expected_ctrlr, name .. ": controller must be set before settings load")
    callbacks.reset()
    local command = commands[#commands]
    check(command.command == "MAME:" .. name .. "\n", "send game to local daemon")
    check(command.panel == expected_panel .. "\n", "panel must be saved before artwork request")
    check(command.active == expected_ctrlr, "artwork and live controller must agree")
    check(#errors == 0, "valid selection must not report errors")
    check(callbacks.populate()[2][2] == ({
        DC = "DC Panel 1", MC = "MC Atari", MK = "MK Wheel", NA = "NONE"
    })[expected_panel], "menu must reflect selected panel")
end

setup()
callbacks.before_settings()
check(#writes == 0 and not reads[map_path], "empty GUI must not apply a profile")
rom = ""
callbacks.before_settings()
check(#writes == 0 and not reads[map_path], "blank ROM must not apply a profile")

for _, name in ipairs({ "sf", "sf2", "mk", "mk2", "mk3", "mk4",
    "marble", "missile", "centiped", "milliped", "robotron", "joust", "gtg2" }) do
    setup()
    start_game(name, "atarifs", "MC")
    check(files[ctrlr_path] == "atarifs\n", "save mapped controller for usbmap")
end

setup()
start_game("mk4", "atarifs", "MC")
callbacks.stop()
check(commands[#commands].command == "MAME:___empty\n", "stop restores GUI artwork")
start_game("qbert", "dcpanel1", "DC")
start_game("spyhunt", "mkwheel", "MK")
local write_count = #writes
start_game("asteroid", "mkwheel", "MK")
check(#writes == write_count + 1, "unlisted game must not rewrite selections")

-- A soft reset must not override a panel changed during this game.
files[panel_path], files[map_path] = "DC\n", "asteroid=atarifs\n"
local map_reads = reads[map_path]
callbacks.reset()
check(reads[map_path] == map_reads and files[panel_path] == "DC\n",
    "soft reset must not reapply per-game requirements")

-- Re-read both the map and manual selection on the next machine launch.
files[map_path] = "# no requirements\n"
files[ctrlr_path] = "atarifs.cfg\n"
files[panel_path] = "MC\n"
start_game("defender", "atarifs", "MC")

setup("# comment\n\n Sf2 = /profiles/atarifs.cfg \r\nsf2=dcpanel1\n"
    .. "invalid line\nmk4= # empty ignored\nmk4 = mkwheel")
start_game("SF2", "atarifs", "MC")
check(files[ctrlr_path] == "/profiles/atarifs.cfg\n", "preserve selected profile spelling")
start_game("mk4", "mkwheel", "MK")

setup("asteroid=custom.cfg\n")
start_game("asteroid", "custom", "DC")
check(files[panel_path] == "DC\n", "unknown profile must leave panel unchanged")

setup()
files[map_path] = nil
start_game("mk4", "dcpanel1", "DC")
check(files[ctrlr_path] == "dcpanel1.cfg\n", "missing optional map preserves selection")

setup()
files[map_path] = nil
files[ctrlr_path] = nil
rom = "asteroid"
callbacks.before_settings()
check(active_ctrlr == "dcpanel1" and #writes == 0, "missing selections preserve launch options")

for _, failure in ipairs({ "open", "read", "close" }) do
    setup()
    failures[map_path] = failure
    rom = "mk4"
    callbacks.before_settings()
    check(#errors == 1 and errors[1]:find(map_path, 1, true), "report map " .. failure .. " failure")
    check(#writes == 0 and active_ctrlr == "dcpanel1", "map failure must not change profile")
end

for _, path in ipairs({ ctrlr_path, panel_path }) do
    for _, failure in ipairs({ "open", "write", "close" }) do
        setup()
        failures[path] = failure
        rom = "mk4"
        callbacks.before_settings()
        check(#errors == 1 and errors[1]:find(path, 1, true), "report selection " .. failure .. " failure")
        check(active_ctrlr == "dcpanel1", "do not activate profile after persistence failure")
    end
end

setup("mk4=/profiles/.cfg\n")
rom = "mk4"
callbacks.before_settings()
check(#errors == 1 and #writes == 0, "reject empty controller name explicitly")

io.open, os.getenv = real_open, real_getenv
print(string.format("marquee: %d checks passed", passed))
