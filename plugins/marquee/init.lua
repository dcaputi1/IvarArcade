-----------------------------------------------------------
-- Marquee Plugin v1.3.0
--  - Sends marquee display commands to dmarquees daemon
-----------------------------------------------------------

local VERSION = "1.3.0"

local exports = {
    name = "marquee",
    version = VERSION,
    description = "Marquee display plugin",
    license = "MIT",
    author = { name = "DanC ChatGPT" }
}

local marquee = exports

-----------------------------------------------------------
-- Constants
-----------------------------------------------------------

local MARQUEE_FIFO = "/tmp/dmarquees_cmd"

-----------------------------------------------------------
-- Internal State
-----------------------------------------------------------

local reset_subscriber
local stop_subscriber

-----------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------

local function send_marquee_command(text)
    local f = io.open(MARQUEE_FIFO, "w")
    if f then
        f:write(text .. "\n")
        f:close()
        print(string.format("[Marquee plugin] Sent marquee command: '%s'", text))
    else
        print(string.format("[Marquee plugin] Failed to open FIFO %s", MARQUEE_FIFO))
    end
end

local function cleanup_notifiers()
    if reset_subscriber then emu.remove_notifier(reset_subscriber) end
    if stop_subscriber then emu.remove_notifier(stop_subscriber) end
    reset_subscriber, stop_subscriber = nil, nil
end

-----------------------------------------------------------
-- Event Callbacks
-----------------------------------------------------------

local function on_game_start()
    local gamename = emu.romname()
    if gamename == "___empty" then return end

    print("[Marquee plugin] " .. gamename .. " started")
    send_marquee_command(gamename)  -- show corresponding marquee
end

local function on_game_stop()
    print("[Marquee plugin] Game stopped, reset marquee")
    send_marquee_command("CLEAR")
end

-----------------------------------------------------------
-- Plugin Entry Point
-----------------------------------------------------------

function marquee.startplugin()
    print("Marquee Plugin: Initialized (v" .. VERSION .. ")")

    cleanup_notifiers()
    reset_subscriber = emu.add_machine_reset_notifier(on_game_start)
    stop_subscriber = emu.add_machine_stop_notifier(on_game_stop)
end

return exports
