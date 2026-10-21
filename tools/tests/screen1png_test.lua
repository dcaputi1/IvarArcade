local plugin_path = "McAtariPi5/opt/retropie/emulators/mame/plugins/screen1png/init.lua"
local callbacks, messages, opens, textures, draws
local rom, targets, screen_count, bad_data, missing_file
local real_open, real_getenv = io.open, os.getenv
local passed = 0

local function check(condition, message)
    assert(condition, message)
    passed = passed + 1
end

local function near(actual, expected)
    return math.abs(actual - expected) < 0.000001
end

local function output(hidden, ui, width, height)
    local result = {
        hidden = hidden,
        is_ui_target = ui,
        width = width or 1920,
        height = height or 1080,
        pixel_aspect = 1
    }
    result.ui_container = {
        draw_box = function (_, ...)
            table.insert(draws, { target = result, kind = "box", args = { ... } })
        end,
        draw_quad = function (_, ...)
            table.insert(draws, { target = result, kind = "quad", args = { ... } })
        end
    }
    return result
end

local function setup()
    callbacks, messages, opens, textures, draws = {}, {}, {}, {}, {}
    rom, screen_count, bad_data, missing_file = "___empty", 1, false, false
    targets = { output(true, false), output(false, true), output(false, false) }
    emu = {
        print_error = function (message) table.insert(messages, message) end,
        print_info = function (message) table.insert(messages, message) end,
        romname = function () return rom end,
        register_before_load_settings = function (cb) callbacks.before_settings = cb end,
        add_machine_stop_notifier = function (cb) callbacks.stop = cb; return {} end,
        register_frame_done = function (cb) callbacks.frame = cb end,
        bitmap_argb32 = {
            load = function (data)
                assert(not bad_data, "invalid PNG")
                return { width = 800, height = 200, data = data }
            end
        }
    }
    manager = { machine = { render = {
        targets = targets,
        texture_alloc = function (_, bitmap)
            local texture = { bitmap = bitmap, frees = 0 }
            function texture:free() self.frees = self.frees + 1 end
            table.insert(textures, texture)
            return texture
        end
    } } }
    io.open = function (path, mode)
        check(mode == "rb", "image must be read as binary")
        table.insert(opens, path)
        if missing_file then return nil, "not found" end
        return {
            read = function () return "PNG data" end,
            close = function () return true end
        }
    end
    os.getenv = function () return nil end
    local plugin = dofile(plugin_path)
    plugin.startplugin()
end

local function prepare()
    manager.machine.screens = {}
    for i = 1, screen_count do manager.machine.screens[i] = {} end
    local open_count = #opens
    callbacks.before_settings()
    check(#opens == open_count, "must defer image loading until the first presentation frame")
    callbacks.frame()
    draws = {}
end

setup()
manager.machine.screens = {}
callbacks.before_settings()
check(#opens == 0 and #draws == 0, "pre-settings callback must not access uninitialized UI targets")
callbacks.frame()
check(#opens == 1 and #draws == 2, "first GUI frame must load and draw without waiting for reset")
callbacks.stop()
callbacks.frame()
check(#opens == 1 and #draws == 2, "stopped session must wait for the next pre-settings callback")

setup()
prepare()
check(opens[1]:match("/MAMELogoR%.png$"), "GUI must load MAME banner")
callbacks.frame()
check(#draws == 2 and draws[1].kind == "box" and draws[2].kind == "quad", "draw opaque background before image")
check(draws[1].args[5] == 0xff000000 and draws[1].args[6] == 0xff000000, "background must be opaque black")
check(draws[2].target == targets[3], "skip hidden targets and never draw on output 0")
local bounds = draws[2].args
check(near(bounds[2], 0) and near(bounds[3], 5 / 18) and near(bounds[4], 1) and near(bounds[5], 13 / 18), "wide image must fit and center")
callbacks.frame()
check(#opens == 1 and #textures == 1, "frames must reuse bitmap/texture")
targets[3].width, targets[3].height, targets[3].pixel_aspect = 400, 800, 2
callbacks.frame()
bounds = draws[#draws].args
check(near(bounds[3], 0.375) and near(bounds[5], 0.625), "resize and pixel aspect must affect bounds")
textures[1].bitmap.width, textures[1].bitmap.height = 100, 400
callbacks.frame()
bounds = draws[#draws].args
check(near(bounds[2], 0.375) and near(bounds[4], 0.625) and near(bounds[3], 0) and near(bounds[5], 1), "tall image must fit and center")
callbacks.stop()
check(textures[1].frees == 1, "stop must release texture")
local count = #draws
callbacks.frame()
check(#draws == count, "must not draw after stop")
targets[3] = output(false, false)
rom = "sf"
prepare()
check(opens[2]:match("/RetroPieMarquee%.png$"), "game must load test PNG")
callbacks.frame()
check(draws[#draws].target == targets[3], "new session must reacquire its output")
targets[3].is_ui_target = true
count = #draws
callbacks.frame()
check(#draws == count, "must not cover GUI moved to output 1 at runtime")
targets[3].is_ui_target = false
prepare()
check(textures[2].frees == 1, "reprepare must release previous texture")
callbacks.stop()
rom = "___empty"
prepare()
check(opens[#opens]:match("/MAMELogoR%.png$"), "returning to GUI must restore banner")
check(textures[1].frees == 1, "old session must not be freed twice")
callbacks.stop()
callbacks.stop()
check(textures[#textures].frees == 1, "stop must be idempotent")

setup()
rom, screen_count = "punchout", 2
prepare()
callbacks.frame()
check(#opens == 0 and #draws == 0, "multi-screen games must be untouched")

setup()
targets[3] = nil
prepare()
callbacks.frame()
check(#opens == 0 and #draws == 0 and messages[1]:match("second visible output unavailable"), "missing output must be diagnosed")
check(#messages == 1, "unavailable output must not be retried every frame")

setup()
targets[3].is_ui_target = true
prepare()
callbacks.frame()
check(#draws == 0 and #opens == 0, "must not cover GUI if UI target moved")

setup()
missing_file = true
prepare()
callbacks.frame()
check(#draws == 0 and messages[1]:match("cannot open"), "missing image must be diagnosed")
check(#opens == 1, "failed image must not be reopened every frame")

setup()
bad_data = true
prepare()
callbacks.frame()
check(#draws == 0 and messages[1]:match("cannot decode"), "corrupt image must be diagnosed")

setup()
io.open = function ()
    return {
        read = function () return nil, "read failed" end,
        close = function () return true end
    }
end
prepare()
callbacks.frame()
check(#draws == 0 and messages[1]:match("read failed"), "read failure must be diagnosed")

setup()
io.open = function ()
    return {
        read = function () return "PNG data" end,
        close = function () return nil, "close failed" end
    }
end
prepare()
callbacks.frame()
check(#draws == 0 and messages[1]:match("close failed"), "close failure must be diagnosed")

setup()
os.getenv = function (key)
    if key == "MAME_SCREEN1_GAME_PNG" then return "custom-game.png" end
    if key == "MAME_SCREEN1_BANNER_PNG" then return "custom-banner.png" end
end
dofile(plugin_path).startplugin()
prepare()
check(opens[1] == "custom-banner.png", "banner path override")
callbacks.stop()
rom = "sf"
prepare()
check(opens[2] == "custom-game.png", "game path override")
targets[3].width = 0
callbacks.frame()
check(#draws == 0, "zero-sized output must not draw")
callbacks.stop()

io.open, os.getenv = real_open, real_getenv
print(string.format("screen1png: %d checks passed", passed))
