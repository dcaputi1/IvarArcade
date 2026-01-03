-- nvram_diff_plugin.lua - MAME Lua plugin to compare NVRAM files before and after gameplay

local VERSION = "1.0.8"

local exports = {
    name = "NVRAM Diff Plugin",
    version = VERSION,
    description = "Diff NVRAM files before/after play."
}

local nvdiff = exports

local pre_nvram = {}
local post_nvram = {}
local game_name = nil
local nvram_path = nil
local file_path = nil
local start_notifier = nil
local stop_notifier = nil

-- Helper: safely convert various option-entry shapes (userdata/table/function) into an ASCII string.
-- We try a sequence of common accessors used in MAME Lua bindings (entry:value(), entry:get(), entry:get_string(), etc.)
-- and fall back to tostring(). Booleans and numbers are converted to their ASCII representations.
local function option_to_ascii(opt)
    if opt == nil then return nil end
    local t = type(opt)
    if t == "string" then return opt end
    if t == "boolean" then return opt and "true" or "false" end
    if t == "number" then return tostring(opt) end

    -- attempt a series of known method calls exposed by MAME's option entry userdata
    local try_calls = {
        function(x) return x:value() end,
        function(x) return x:value(false) end,
        function(x) return x:value(true) end,
        function(x) return x:get() end,
        function(x) return x:get_string() end,
        function(x) return x.as_string and x:as_string() end,
--        function(x) return x:value and x:value end, -- field access if bound as field
    }

    for _, fn in ipairs(try_calls) do
        local ok, res = pcall(fn, opt)
        if ok and res ~= nil then
            local rt = type(res)
            if rt == "boolean" then return res and "true" or "false" end
            if rt == "number" then return tostring(res) end
            if rt == "string" and tostring(res) ~= "" then return res end
            -- if userdata/table/function returned, try tostring on it
            local s = tostring(res)
            if s and s ~= "" and not s:match("^%w+: 0x") then
                return s
            end
        end
    end

    -- If opt itself exposes a :value() as metamethod (common for userdata), try calling it directly
    local ok_direct, direct_res = pcall(function() return opt:value() end)
    if ok_direct and direct_res ~= nil then
        if type(direct_res) == "boolean" then return direct_res and "true" or "false" end
        if type(direct_res) == "number" then return tostring(direct_res) end
        if type(direct_res) == "string" and tostring(direct_res) ~= "" then return tostring(direct_res) end
        local s = tostring(direct_res)
        if s and s ~= "" and not s:match("^%w+: 0x") then return s end
    end

    -- last resort: tostring(opt) unless it looks like raw userdata/function/table pointer
    local s = tostring(opt)
    if s and s ~= "" and not s:match("^%w+: 0x") then
        return s
    end

    return nil
end

local function read_nvram_file(path)
    print("[NVDIFF] Attempting to read NVRAM file: " .. tostring(path))
    local file = io.open(path, "rb")
    if not file then
        print("[NVDIFF] Failed to open file: " .. tostring(path))
        return nil
    end
    local data = file:read("*all")
    file:close()
    print(string.format("[NVDIFF] Read %d bytes from %s", #data, tostring(path)))
    return data
end

local function diff_nvram(before, after)
    local changes = {}
    local start_offset = nil
    local chunk_before = {}
    local chunk_after = {}

    for i = 1, math.min(#before, #after) do
        local b_byte = string.byte(before, i)
        local a_byte = string.byte(after, i)

        if b_byte ~= a_byte then
            if not start_offset then
                start_offset = i - 1
            end
            table.insert(chunk_before, string.format("%02X", b_byte))
            table.insert(chunk_after, string.format("%02X", a_byte))
        elseif start_offset then
            table.insert(changes, string.format(
                "Offset 0x%X: %s -> %s",
                start_offset,
                table.concat(chunk_before, " "),
                table.concat(chunk_after, " ")
            ))
            start_offset = nil
            chunk_before = {}
            chunk_after = {}
        end
    end

    if start_offset then
        table.insert(changes, string.format(
            "Offset 0x%X: %s -> %s",
            start_offset,
            table.concat(chunk_before, " "),
            table.concat(chunk_after, " ")
        ))
    end

    return changes
end

local function dump_all_options()
    print("[NVDIFF] Dumping available MAME options (name -> ascii value):")
    local ok, entries = pcall(function()
        return manager and manager.machine and manager.machine.options and manager.machine.options.entries
    end)
    if not ok or not entries then
        print("[NVDIFF] manager.machine.options.entries not available")
        return
    end
    for k, v in pairs(entries) do
        local s = option_to_ascii(v)
        print(string.format("  %s = %s", tostring(k), tostring(s)))
    end
end

local function get_nvram_directory()
    -- Try the options method first (safe call)
    local ok, dir = pcall(function()
        if manager and manager.machine and manager.machine.options and type(manager.machine.options.nvram_directory) == "function" then
            return manager.machine.options:nvram_directory()
        end
        if manager and manager.machine and manager.machine.options and manager.machine.options.nvram_directory then
            return manager.machine.options.nvram_directory
        end
        return nil
    end)

    if ok and dir and tostring(dir) ~= "" then
        local s = option_to_ascii(dir) or tostring(dir)
        print("[NVDIFF] nvram_directory (from options) = " .. tostring(s))
        return s
    end

    -- Try looking in entries and convert via option_to_ascii
    local entry = nil
    local ok2, e = pcall(function()
        return manager and manager.machine and manager.machine.options and manager.machine.options.entries and manager.machine.options.entries["nvram_directory"]
    end)
    if ok2 then entry = e end

    if entry then
        local s = option_to_ascii(entry)
        print("[NVDIFF] Found options.entries[\"nvram_directory\"] -> " .. tostring(s))
        if s and tostring(s) ~= "" then return s end
    else
        print("[NVDIFF] No nvram_directory entry found in options.entries")
    end

    -- Last resort default
    print("[NVDIFF] nvram_directory not found, defaulting to /home/danc/RetroPie/roms/mame/nvram")
    return "/home/danc/RetroPie/roms/mame/nvram"
end

local function capture_nvram_before()
    game_name = emu.romname()
    print("[NVDIFF] Game romname: " .. tostring(game_name))

    dump_all_options()

    nvram_path = get_nvram_directory() or "/home/danc/RetroPie/roms/mame/nvram"
    print("[NVDIFF] nvram_path resolved to: " .. tostring(nvram_path) .. " (type=" .. type(nvram_path) .. ")")

    if type(nvram_path) ~= "string" or tostring(nvram_path) == "" then
        print("[NVDIFF] nvram_path invalid, using default path")
        nvram_path = "/home/danc/RetroPie/roms/mame/nvram"
    end

    local candidate1 = nvram_path .. "/" .. game_name .. ".nv"
    local candidate2 = nvram_path .. "/" .. game_name .. "/nvram"

    print("[NVDIFF] Trying candidate: " .. candidate1)
    local data = read_nvram_file(candidate1)
    if not data then
        print("[NVDIFF] candidate1 failed, trying: " .. candidate2)
        data = read_nvram_file(candidate2)
    end

    pre_nvram = data or ""
end

local function capture_nvram_after()
    if not pre_nvram or #pre_nvram == 0 then
        print("[NVDIFF] pre_nvram empty or not captured; attempting to resolve nvram_path again")
        nvram_path = get_nvram_directory()
    end

    local candidate1 = nvram_path .. "/" .. game_name .. ".nv"
    local candidate2 = nvram_path .. "/" .. game_name .. "/nvram"

    print("[NVDIFF] Checking after-file candidate: " .. candidate1)
    local data = read_nvram_file(candidate1)
    if not data then
        print("[NVDIFF] candidate1 failed, trying: " .. candidate2)
        data = read_nvram_file(candidate2)
    end

    post_nvram = data or ""

    if #pre_nvram == 0 and #post_nvram == 0 then
        print("[NVRAM] No NVRAM data found for " .. tostring(game_name))
        return
    end

    local changes = diff_nvram(pre_nvram, post_nvram)
    if #changes == 0 then
        print("[NVDIFF] No changes detected.")
    else
        print("[NVDIFF] Changes detected:")
        print(table.concat(changes, "\n"))
    end
end

function nvdiff.startplugin()
    print("[NVDIFF Plugin] Starting NVRAM diff plugin...")
    start_notifier = emu.add_machine_reset_notifier(capture_nvram_before)
    stop_notifier = emu.add_machine_stop_notifier(capture_nvram_after)
end

return exports
