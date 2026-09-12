-----------------------------------------------------------
-- Marquee Plugin - Sends FIFO commands to dmarquees daemon
-----------------------------------------------------------

local VERSION = "1.4.0"

local exports = {
    name = "marquee",
    version = VERSION,
    description = "Marquee display plugin",
    license = "MIT",
    author = { name = "Dan Caputi" }
}

local marquee = exports

-----------------------------------------------------------
-- Constants
-----------------------------------------------------------

local MARQUEE_FIFO = "/tmp/dmarquees_cmd"
local SENDER_SCRIPT = "/home/danc/scripts/dmarquees-send.sh"
local SWAP_SCRIPT  = "/home/danc/scripts/swap_banner_art.sh"
local PANEL_FILE   = "/home/danc/.panel"
local CTRLR_FILE   = "/home/danc/.ctrlr"

local PANEL_NA = "NA"
local PANEL_DC = "DC"
local PANEL_MC = "MC"
local PANEL_MK = "MK"

-- Map panel modes to expected controller config file names
local PANEL_TO_CTRLR = {
    [PANEL_DC] = "dcpanel1",
    [PANEL_MC] = "atarifs",
    [PANEL_MK] = "mkwheel",
    [PANEL_NA] = nil,  -- no specific controller required
}

-----------------------------------------------------------
-- Internal State
-----------------------------------------------------------

local reset_subscriber
local stop_subscriber
local panel_mode = PANEL_NA
local in_panel_submenu = false

-----------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------

local function shell_quote(text)
    return "'" .. tostring(text):gsub("'", "'\\''") .. "'"
end

local function send_remote_command(text)
    -- Send to Pi3 via sender script (for main marquee display)
    local sender = io.open(SENDER_SCRIPT, "r")
    if sender then
        sender:close()
        local status = os.execute(string.format("%s %s >/dev/null 2>&1", SENDER_SCRIPT, shell_quote(text)))
        if status == true or status == 0 then
            print(string.format("Marquee plugin: Sent to Pi3 via sender: '%s'", text))
        else
            print(string.format("Marquee plugin: Sender failed for '%s'", text))
        end
    end
end

local function send_local_command(text)
    -- Write to local FIFO so Pi5 dmarquees can drive the spare monitor panel art
    local fifo = io.open(MARQUEE_FIFO, "w")
    if fifo then
        fifo:write(text .. "\n")
        fifo:close()
        print(string.format("Marquee plugin: Sent to local FIFO: '%s'", text))
    else
        print(string.format("Marquee plugin: Failed to write to local FIFO %s for '%s'", MARQUEE_FIFO, text))
    end
end

local function send_marquee_command(text)
    send_remote_command(text)
    send_local_command(text)
end

local function current_romname()
    local gamename = emu.romname()
    if gamename and gamename ~= "" and gamename ~= "___empty" then
        return gamename
    end
    return nil
end

local function sync_rom_for_panel()
    local gamename = current_romname()
    if not gamename then
        print("Marquee plugin: No active ROM to sync for panel")
        return false
    end

    -- Panel sync should only target the local Pi5 daemon.
    send_local_command(gamename)
    return true
end

local function cleanup_notifiers()
    if reset_subscriber then emu.remove_notifier(reset_subscriber) end
    if stop_subscriber then emu.remove_notifier(stop_subscriber) end
    reset_subscriber, stop_subscriber = nil, nil
end

local function panel_mode_label(mode)
    if mode == PANEL_DC then
        return "DC Panel 1"
    elseif mode == PANEL_MC then
        return "MC Atari"
    elseif mode == PANEL_MK then
        return "MK Wheel"
    end
    return "NONE"
end

local function panel_mode_file_code(mode)
    if mode == PANEL_DC then
        return "DC"
    elseif mode == PANEL_MC then
        return "MC"
    elseif mode == PANEL_MK then
        return "MK"
    end
    return "NA"
end

local function read_ctrlr_file()
    local f = io.open(CTRLR_FILE, "r")
    if not f then
        return nil
    end
    local value = f:read("*l") or ""
    f:close()
    return value ~= "" and value or nil
end

local function ctrlr_mode_label(ctrlr_name)
    if not ctrlr_name or ctrlr_name == "" then
        return "None/Default"
    end
    local lower = tostring(ctrlr_name):lower()
    if lower:find("dcpanel") then
        return "DC Panel 1"
    elseif lower:find("atarifs") then
        return "Atari FS"
    elseif lower:find("mkwheel") then
        return "MK Wheel"
    end
    return ctrlr_name
end

local function panel_ctrlr_mismatch(target_panel)
    local expected_ctrlr = PANEL_TO_CTRLR[target_panel]
    if not expected_ctrlr then
        return nil  -- no specific controller required
    end

    local current_ctrlr = read_ctrlr_file()
    if not current_ctrlr then
        current_ctrlr = "allctrlrs.cfg"  -- default
    end

    local expected_lower = tostring(expected_ctrlr):lower()
    local current_lower = tostring(current_ctrlr):lower()

    if not current_lower:find(expected_lower, 1, true) then
        return {
            expected = expected_ctrlr,
            expected_label = ctrlr_mode_label(expected_ctrlr),
            current = current_ctrlr,
            current_label = ctrlr_mode_label(current_ctrlr),
        }
    end

    return nil  -- no mismatch
end

local function load_panel_mode()
    local file = io.open(PANEL_FILE, "r")
    if not file then
        return PANEL_NA
    end

    local value = file:read("*l") or ""
    file:close()
    value = tostring(value):upper()

    if value == PANEL_DC or value == PANEL_MC or value == PANEL_MK then
        return value
    end
    return PANEL_NA
end

local function persist_panel_mode(mode)
    local file = io.open(PANEL_FILE, "w")
    if not file then
        print(string.format("Marquee plugin: Failed to persist panel mode to %s", PANEL_FILE))
        return false
    end

    file:write(panel_mode_file_code(mode) .. "\n")
    file:close()
    return true
end

local function apply_panel_mode(mode)
    if mode ~= PANEL_DC and mode ~= PANEL_MC and mode ~= PANEL_MK then
        mode = PANEL_NA
    end

    panel_mode = mode
    persist_panel_mode(panel_mode)
    sync_rom_for_panel()
    
    -- Check for controller/panel mismatch
    local mismatch = panel_ctrlr_mismatch(mode)
    if mismatch then
        local msg = string.format(
            "Panel %s needs %s\n(current: %s)\nRestart MAME required",
            panel_mode_label(mode), mismatch.expected_label, mismatch.current_label)
        manager.machine:popmessage(msg)
        print(string.format("Marquee plugin: Panel/Controller mismatch - panel=%s expected_ctrlr=%s current_ctrlr=%s",
            panel_mode_label(mode), mismatch.expected, mismatch.current))
    else
        print("Marquee plugin: Panel mode set to " .. panel_mode_label(panel_mode))
    end
end

-----------------------------------------------------------
-- Event Callbacks
-----------------------------------------------------------

local function on_game_start()
    local gamename = current_romname()
    if not gamename then return end

    print("Marquee plugin: " .. gamename .. " started")
    send_marquee_command(gamename)
end

local function on_game_stop()
    print("Marquee plugin: Game stopped, reset marquee")
    send_marquee_command("CLEAR")
end

local function menu_populate()
    if in_panel_submenu then
        return {
            { "UltraStick / Spinners", panel_mode == PANEL_DC and "ON" or "--", "" },
            { "Atari / FightStick", panel_mode == PANEL_MC and "ON" or "--", "" },
            { "MarioKart / Wheel", panel_mode == PANEL_MK and "ON" or "--", "" },
            { "No Panel Image", panel_mode == PANEL_NA and "ON" or "--", "" }
        }
    end

    return {
        { "Control Panel / Marquee", "SWAP", "" },
        { "Spare Monitor Panel", panel_mode_label(panel_mode), "" }
    }
end

local function menu_callback(index, event)
    if event ~= "select" then
        return false
    end

    if in_panel_submenu then
        if index == 1 then
            in_panel_submenu = false
            apply_panel_mode(PANEL_DC)
            return true
        elseif index == 2 then
            in_panel_submenu = false
            apply_panel_mode(PANEL_MC)
            return true
        elseif index == 3 then
            in_panel_submenu = false
            apply_panel_mode(PANEL_MK)
            return true
        elseif index == 4 then
            in_panel_submenu = false
            apply_panel_mode(PANEL_NA)
            return true
        end
        return false
    end

    if index == 1 then
        os.execute(SWAP_SCRIPT)
        print("Marquee plugin: SWAP index " .. tostring(index) .. " event " .. tostring(event))
        return false
    elseif index == 2 then
        in_panel_submenu = true
        return true
    end

    return false
end

-----------------------------------------------------------
-- Plugin Entry Point
-----------------------------------------------------------

function marquee.startplugin()
    print("Marquee Plugin: Initialized (v" .. VERSION .. ")")

    panel_mode = load_panel_mode()

    cleanup_notifiers()
    reset_subscriber = emu.add_machine_reset_notifier(on_game_start)
    stop_subscriber = emu.add_machine_stop_notifier(on_game_stop)
	emu.register_menu(menu_callback, menu_populate, "Marquee")

end

return exports
