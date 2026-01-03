local VERSION = "1.2.7"

local exports = {
    name = "leds",
    version = VERSION,
    description = "LED control plugin",
    license = "MIT",
    author = { name = "DanC ChatGPT" }
}

local leds = exports

-----------------------------------------------------------
-- Constants
-----------------------------------------------------------

local SCRIPT_PATH = "/home/danc/scripts/"
local SCRIPT_FILE = "set_leds.py"

-----------------------------------------------------------
-- Internal State
-----------------------------------------------------------

local last_mask = -1
local reset_subscriber
local stop_subscriber
local frame_subscriber
local machine_ok = true
local attract_on = true    -- coin1 lit in attract mode (currently only on game launch)

local coins1 = nil
local start1 = nil
local start2 = nil
local credits = 0

local last_coins1 = 0
local last_start1 = 0
local last_start2 = 0

-----------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------

local function set_led_mask(mask)
    if mask == last_mask then return end
    last_mask = mask

    local cmd = string.format("python3 %s%s %02x", SCRIPT_PATH, SCRIPT_FILE, mask)
    local result = os.execute(cmd)
    if result then
        print(string.format("LED mask 0x%02x sent successfully.", mask))
    else
        print(string.format("Failed to send LED mask 0x%02x.", mask))
    end
end

local function match_field_name(name, substr1, substr2)
    local lname = name:lower()
    return lname:find(substr1) and lname:find(substr2)
end

local function initialize_ports()
    local ioports = manager.machine.ioport.ports

    for tag, port in pairs(ioports) do
        for field_name, field in pairs(port.fields) do
            if not coins1 and match_field_name(field_name, "coin", "1") then
                print("coin 1 found")
                coins1 = { port = port, field = field }
            elseif not start1 and match_field_name(field_name, "start", "1") then
                print("start 1 found")
                start1 = { port = port, field = field }
            elseif not start2 and match_field_name(field_name, "start", "2") then
                print("start 2 found")
                start2 = { port = port, field = field }
            end
        end
    end

    if not (coins1 and start1 and start2) then
        print("LEDS Plugin: Failed to find all required input ports.")
        return false
    end

    last_coins1 = coins1.port:read()
    last_start1 = start1.port:read()
    last_start2 = start2.port:read()

    return true
end

local function is_pressed(current, field)
    return ((current & field.mask) ~ field.defvalue) ~= 0
end

local function cleanup_notifiers()
    if reset_subscriber then
        emu.remove_notifier(reset_subscriber)
    end
    if stop_subscriber then
        emu.remove_notifier(stop_subscriber)
    end
    if frame_subscriber then
        emu.remove_notifier(frame_subscriber)
    end
    
    reset_subscriber = nil
    stop_subscriber = nil
    frame_subscriber = nil
end

-----------------------------------------------------------
-- Event Callbacks
-----------------------------------------------------------

local function on_frame()
    if not machine_ok then
        return
    end

    local coin_now = coins1.port:read()
    local s1_now = start1.port:read()
    local s2_now = start2.port:read()

    -- Detect rising edge on Coin 1
    if is_pressed(coin_now, coins1.field) and coin_now ~= last_coins1 then
        credits = credits + 1
    end

    -- Detect rising edge on Start 1
    if is_pressed(s1_now, start1.field) and s1_now ~= last_start1 then
        if credits >= 1 then
            credits = credits - 1
        end
        attract_on = false
        set_led_mask(0x00)
    end

    -- Detect rising edge on Start 2
    if is_pressed(s2_now, start2.field) and s2_now ~= last_start2 then
        if credits >= 2 then
            credits = credits - 2
        end
        attract_on = false
        set_led_mask(0x00)
    end

    last_coins1 = coin_now
    last_start1 = s1_now
    last_start2 = s2_now

    -- Update LED mask based on credits
    local mask_now = 0
    if attract_on then
        mask_now = 1      -- + Coin
    end

    if credits >= 2 then
        mask_now = mask_now + 6     -- + P1 + P2
    elseif credits == 1 then
        mask_now = mask_now + 2     -- + P1
    end

    set_led_mask(mask_now)
end

local function on_game_start()
    machine_ok = false
    coins1 = nil
    start1 = nil
    start2 = nil
    last_coins1 = 0
    last_start1 = 0
    last_start2 = 0
    credits = 0
    
    local gamename = emu.romname()
    if gamename == "___empty" then return end

    print("LEDS Plugin: " .. gamename .. " started")

    if not initialize_ports() then return end

    machine_ok = true
    attract_on = true
end

local function on_game_stop()
    print("LEDS Plugin: Game stopped, turning off all LEDs")
    set_led_mask(0x00)
    machine_ok = false
end

-----------------------------------------------------------
-- Plugin Entry Point
-----------------------------------------------------------

function leds.startplugin()
    print("LEDS Plugin: Initialized (v" .. VERSION .. ")")
    set_led_mask(0x00)

    cleanup_notifiers()
    reset_subscriber = emu.add_machine_reset_notifier(on_game_start)
    stop_subscriber = emu.add_machine_stop_notifier(on_game_stop)
    frame_subscriber = emu.add_machine_frame_notifier(on_frame)
end

return exports
