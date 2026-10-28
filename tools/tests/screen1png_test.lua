local plugin_path = "McAtariPi5/opt/retropie/emulators/mame/plugins/screen1png/init.lua"
local state_path = "/tmp/dmarquees_panel_state"
local callbacks, messages, errors, opens, textures, draws
local rom, state, screen_count, image_width, image_height
local missing_state, missing_image, bad_image, read_error, close_error
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

local function mock_bitmap(width, height, data)
    local bitmap = { width = width, height = height, data = data }
    function bitmap:resample(dest)
        dest.source = self
    end
    return bitmap
end

local function file_stub(content, should_error, fail_close)
    return {
        read = function ()
            if should_error then return nil, "read failed" end
            return content
        end,
        close = function ()
            if fail_close then return nil, "close failed" end
            return true
        end
    }
end

local function setup(panel_output_enabled)
    callbacks, messages, errors, opens, textures, draws = {}, {}, {}, {}, {}, {}
    rom, state, screen_count = "___empty", "GUI|1", 0
    image_width, image_height = 800, 200
    missing_state, missing_image, bad_image, read_error, close_error = false, false, false, false, false
    local targets = { output(true, false), output(false, true), output(false, false) }

    emu = {
        print_error = function (message)
            table.insert(messages, message)
            table.insert(errors, message)
        end,
        print_info = function (message) table.insert(messages, message) end,
        romname = function () return rom end,
        register_before_load_settings = function (cb) callbacks.before_settings = cb end,
        register_frame_done = function (cb) callbacks.frame = cb end,
        add_machine_stop_notifier = function (cb) callbacks.stop = cb; return {} end,
        bitmap_argb32 = setmetatable({
            load = function (data)
                assert(not bad_image, "invalid PNG")
                return mock_bitmap(image_width, image_height, data)
            end
        }, { __call = function (_, width, height) return mock_bitmap(width, height) end })
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
        table.insert(opens, path)
        if path == state_path then
            check(mode == "r", "panel state must be read as text")
            if missing_state then return nil, "not found" end
            return file_stub(state, read_error, close_error)
        end
        check(mode == "rb", "panel artwork must be read as binary")
        if missing_image then return nil, "not found" end
        return file_stub("PNG data", read_error, close_error)
    end
    os.getenv = function (key)
        if key == "MAME_PANEL_OUTPUT" and panel_output_enabled ~= false then return "1" end
        return nil
    end

    local plugin = dofile(plugin_path)
    plugin.startplugin()
    manager.machine.screens = {}
    for i = 1, screen_count do manager.machine.screens[i] = {} end
    return targets
end

local function start_session(targets)
    local open_count = #opens
    callbacks.before_settings()
    check(#opens == open_count, "defer image and state access until the first presentation frame")
    manager.machine.screens = {}
    for i = 1, screen_count do manager.machine.screens[i] = {} end
    callbacks.frame()
end

local targets = setup()
start_session(targets)
check(opens[1] == state_path and opens[2] == "/home/danc/IvarArcade/images/MAMELogoR.png",
    "MAME GUI should load the banner when the daemon publishes GUI state")
check(#draws == 2 and draws[1].kind == "box" and draws[2].kind == "quad", "draw background before artwork")
check(draws[1].args[5] == 0xff000000 and draws[1].args[6] == 0xff000000, "background must be opaque black")
check(draws[2].target == targets[3], "skip hidden targets and never draw on output 0")
local bounds = draws[2].args
check(near(bounds[2], 0) and near(bounds[3], 5 / 18) and near(bounds[4], 1) and near(bounds[5], 13 / 18),
    "wide image must fit and center")
callbacks.frame()
check(#textures == 1, "frames must reuse loaded bitmap and texture")
targets[3].width, targets[3].height, targets[3].pixel_aspect = 400, 800, 2
callbacks.frame()
bounds = draws[#draws].args
check(near(bounds[3], 0.375) and near(bounds[5], 0.625), "resize and pixel aspect must affect bounds")
callbacks.stop()
check(textures[1].frees == 1, "stop must release texture")
local draw_count = #draws
callbacks.frame()
check(#draws == draw_count, "must not draw after stop")

targets = setup()
rom, state, screen_count = "spyhunt", "PANEL|spyhunt|MK|1", 1
targets[3] = output(false, false)
start_session(targets)
check(opens[2] == "/tmp/dmarquees_mkwheel.png", "MK panel state must load the dynamically rendered wheel image")
check(draws[#draws].target == targets[3], "new MAME session must reacquire output 1")
callbacks.stop()

targets = setup()
rom, state, screen_count = "sf", "DEFAULT|sf|1", 1
start_session(targets)
check(opens[2] == "/home/danc/IvarArcade/images/MAMELogoR.png", "no selected panel must use splash banner")
local opens_before_panel_change = #opens
state = "PANEL|sf|MC|2"
for _ = 1, 29 do callbacks.frame() end
check(#opens == opens_before_panel_change, "panel state polling must be rate-limited")
callbacks.frame()
check(opens[#opens] == "/tmp/dmarquees_mcpanel.png", "panel changes must reload the selected panel image")
check(textures[1].frees == 1, "replacing artwork must release the old texture")
state = "OFF|3"
for _ = 1, 30 do callbacks.frame() end
check(textures[2].frees == 1, "OFF state must release panel artwork")
draw_count = #draws
callbacks.frame()
check(#draws == draw_count, "OFF state must leave MAME's output untouched")

for _, game in ipairs({ "punchout", "spnchout" }) do
    targets = setup()
    rom, state, screen_count = game, "OFF|1", 2
    start_session(targets)
    callbacks.frame()
    check(#opens == 0 and #draws == 0, game .. " gameplay screens must be left to MAME")
end

targets = setup()
targets[3] = nil
screen_count = 1
start_session(targets)
check(#opens == 0 and errors[1] and errors[1]:match("second visible output unavailable"),
    "missing output must be diagnosed without opening an image")

targets = setup()
rom, state, screen_count = "sf", "PANEL|sf|XX|1", 1
start_session(targets)
check(#opens == 1 and errors[1] and errors[1]:match("unknown panel code"), "unknown panel code must be diagnosed")

targets = setup()
rom, state, screen_count = "sf", "PANEL|sf|DC|1", 1
missing_image = true
start_session(targets)
check(errors[1] and errors[1]:match("cannot open"), "missing panel image must be diagnosed")
check(#textures == 0, "missing image must not create a texture")

targets = setup()
rom, state, screen_count = "sf", "PANEL|sf|DC|1", 1
bad_image = true
start_session(targets)
check(errors[1] and errors[1]:match("cannot decode"), "corrupt panel image must be diagnosed")

targets = setup()
rom, state, screen_count = "___empty", "GUI|1", 0
missing_state = true
start_session(targets)
check(errors[1] and errors[1]:match("cannot open panel state"), "missing panel state must be diagnosed")
check(#draws == 0, "missing state must not draw stale artwork")

targets = setup()
rom, state, screen_count = "sf", "PANEL|sf|DC|1", 1
read_error = true
start_session(targets)
check(errors[1] and errors[1]:match("read failed"), "state and artwork read failures must be diagnosed")

targets = setup()
rom, state, screen_count = "sf", "PANEL|sf|DC|1", 1
close_error = true
start_session(targets)
check(errors[1] and errors[1]:match("close failed"), "state and artwork close failures must be diagnosed")

targets = setup(false)
rom, state, screen_count = "sf", "PANEL|sf|DC|1", 1
start_session(targets)
check(#opens == 0 and #draws == 0, "output must stay disabled outside Pi5 panel mode")

targets = setup()
rom, state, screen_count = "sf", "PANEL|sf|DC|1", 1
image_width, image_height = 4500, 1500
targets[3].width, targets[3].height = 1600, 1200
start_session(targets)
check(textures[1].bitmap.width == 1600 and textures[1].bitmap.height == 533,
    "oversized texture must shrink to fit the output")
check(textures[1].bitmap.source and textures[1].bitmap.source.width == 4500,
    "oversized bitmap must be resampled")
callbacks.stop()

io.open, os.getenv = real_open, real_getenv
print(string.format("screen1png: %d checks passed", passed))
