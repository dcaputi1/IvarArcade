local VERSION = "1.3.1"

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
local SWAP_BANNER_SCRIPT = "/home/danc/scripts/swap_banner_art.sh"

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
local player_buttons = {}  -- Table to hold player button references
local credits = 0

local last_coins1 = 0
local last_start1 = 0
local last_start2 = 0

-- Simultaneous button press detection
local SIMULTANEOUS_WINDOW = 0.15  -- 150ms window to detect simultaneous press
local start1_press_time = 0
local start2_press_time = 0
local swap_triggered = false

-- Attract mode and LED flashing
local ATTRACT_MODE_TIMEOUT = 30.0  -- Return to attract mode after 30 seconds of inactivity
local COIN_FLASH_INTERVAL = 0.5    -- Flash coin LED every 0.5 seconds
local last_button_press_time = 0
local starts_found = false

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
            -- Collect player button fields (P1_BUTTON1, P1_BUTTON2, etc.)
            if field_name:lower():find("p1_button") or field_name:lower():find("button") then
                table.insert(player_buttons, { port = port, field = field, name = field_name })
            end
        end
    end

    if not (coins1 and start1 and start2) then
        print("LEDS Plugin: Failed to find all required input ports.")
        print("LEDS Plugin: Available input ports:")
        local ioports = manager.machine.ioport.ports
        for tag, port in pairs(ioports) do
            for field_name, field in pairs(port.fields) do
                print("  - " .. field_name)
            end
        end
        starts_found = false
        return false
    end

    last_coins1 = coins1.port:read()
    last_start1 = start1.port:read()
    last_start2 = start2.port:read()

    starts_found = true
    return true
end

local function is_pressed(current, field)
    return ((current & field.mask) ~ field.defvalue) ~= 0
end

local function trigger_swap_banner_art()
    print("LEDS Plugin: Simultaneous start button press detected! Swapping banner art...")
    local result = os.execute(SWAP_BANNER_SCRIPT)
    if result then
        print("LEDS Plugin: Banner art swap completed successfully.")
    else
        print("LEDS Plugin: Banner art swap failed.")
    end
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
    
    local current_time = os.clock()
    
    local s1_currently_pressed = is_pressed(s1_now, start1.field)
    local s2_currently_pressed = is_pressed(s2_now, start2.field)
    
    -- Track player button activity for attract mode
    local any_player_button_pressed = false
    for _, button_ref in ipairs(player_buttons) do
        local button_now = button_ref.port:read()
        if is_pressed(button_now, button_ref.field) then
            any_player_button_pressed = true
            break
        end
    end
    
    -- Update last button press time only when player buttons are active
    if any_player_button_pressed then
        last_button_press_time = current_time
        attract_on = false
    end
    
    -- Return to attract mode after player inactivity timeout
    if (current_time - last_button_press_time) > ATTRACT_MODE_TIMEOUT then
        attract_on = true
    end
    
    -- Detect rising edge on Start 1
    local s1_edge = s1_currently_pressed and s1_now ~= last_start1
    -- Detect rising edge on Start 2
    local s2_edge = s2_currently_pressed and s2_now ~= last_start2

    -- Update press times on rising edges
    if s1_edge then
        start1_press_time = current_time
    end
    if s2_edge then
        start2_press_time = current_time
    end
    
    -- Check for simultaneous press (both buttons pressed within time window)
    local is_simultaneous = false
    if s1_currently_pressed and s2_currently_pressed then
        local time_diff = math.abs(start1_press_time - start2_press_time)
        if time_diff <= SIMULTANEOUS_WINDOW then
            is_simultaneous = true
            if not swap_triggered then
                swap_triggered = true
                trigger_swap_banner_art()
            end
        end
    end
    
    -- Reset swap trigger when both buttons are released
    if not s1_currently_pressed and not s2_currently_pressed then
        swap_triggered = false
    end

    -- Detect rising edge on Coin 1
    if is_pressed(coin_now, coins1.field) and coin_now ~= last_coins1 then
        credits = credits + 1
    end

    -- Normal Start 1 behavior (only if not a simultaneous press)
    if s1_edge and not is_simultaneous then
        if credits >= 1 then
            credits = credits - 1
            attract_on = false
        end
    end

    -- Normal Start 2 behavior (only if not a simultaneous press)
    if s2_edge and not is_simultaneous then
        if credits >= 2 then
            credits = credits - 2
            attract_on = false
        end
    end

    last_coins1 = coin_now
    last_start1 = s1_now
    last_start2 = s2_now

    -- Update LED mask based on credits
    local mask_now = 0
    if attract_on then
        -- Flash coin LED every 0.5 seconds in attract mode
        local flash_phase = (current_time % COIN_FLASH_INTERVAL) < (COIN_FLASH_INTERVAL / 2)
        if flash_phase then
            mask_now = 1      -- + Coin
        end
    end

    -- If we couldn't find standard start buttons, light both start LEDs
    if not starts_found then
        mask_now = mask_now + 6     -- + P1 + P2
    elseif credits >= 2 then
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
    player_buttons = {}
    last_coins1 = 0
    last_start1 = 0
    last_start2 = 0
    credits = 0
    start1_press_time = 0
    start2_press_time = 0
    swap_triggered = false
    last_button_press_time = 0
    starts_found = false
    
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
