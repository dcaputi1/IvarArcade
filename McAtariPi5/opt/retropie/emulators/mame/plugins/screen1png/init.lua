local exports = {
    name = "screen1png",
    version = "0.2.0",
    description = "Dynamically displays the selected control panel on output 1",
    license = "MIT",
    author = { name = "Dan Caputi" }
}

local stop_subscriber
local MAX_TEXTURE = 4096
local STATE_POLL_FRAMES = 30

local function close_texture(texture)
    if texture then
        texture:free()
    end
end

function exports.startplugin()
    local pending = false
    local target
    local bitmap
    local texture
    local panel_container
    local original_orientation
    local frame_count = 0
    local last_state
    local state_error_reported = false
    local panel_output_enabled = os.getenv("MAME_PANEL_OUTPUT") == "1"
    local state_path = os.getenv("MAME_PANEL_STATE_FILE") or "/tmp/dmarquees_panel_state"
    local banner_png = os.getenv("MAME_PANEL_BANNER_PNG") or "/home/danc/IvarArcade/images/MAMELogoR.png"
    local panel_pngs = {
        DC = "/tmp/dmarquees_dcpanel.png",
        MC = "/tmp/dmarquees_mcpanel.png",
        MK = "/tmp/dmarquees_mkwheel.png"
    }

    local function report_error(message)
        emu.print_error("screen1png: " .. message)
    end

    local function release_image()
        if panel_container then
            panel_container.orientation = original_orientation
            panel_container = nil
            original_orientation = nil
        end
        close_texture(texture)
        texture = nil
        bitmap = nil
    end

    local function release()
        pending = false
        target = nil
        last_state = nil
        release_image()
    end

    local function read_state()
        local file, open_error = io.open(state_path, "r")
        if not file then
            if not state_error_reported then
                report_error("cannot open panel state " .. state_path .. ": " .. tostring(open_error))
                state_error_reported = true
            end
            return nil
        end

        local state, read_error = file:read("*l")
        local closed, close_error = file:close()
        if not state or not closed then
            report_error("cannot read panel state " .. state_path .. ": " .. tostring(read_error or close_error))
            return nil
        end
        state_error_reported = false
        return state
    end

    local function load_image(path)
        local file, open_error = io.open(path, "rb")
        if not file then
            report_error("cannot open " .. path .. ": " .. tostring(open_error))
            return false
        end

        local data, read_error = file:read("*a")
        local closed, close_error = file:close()
        if not data or not closed then
            report_error("cannot read/close " .. path .. ": " .. tostring(read_error or close_error))
            return false
        end

        local decoded, result = pcall(emu.bitmap_argb32.load, data)
        if not decoded then
            report_error("cannot decode " .. path .. ": " .. tostring(result))
            return false
        end
        local loaded_bitmap = result

        local scale = math.min(1, MAX_TEXTURE / loaded_bitmap.width, MAX_TEXTURE / loaded_bitmap.height)
        if target.width > 0 and target.height > 0 then
            scale = math.min(scale, target.width / loaded_bitmap.width, target.height / loaded_bitmap.height)
        end
        if scale < 1 then
            local width = math.max(1, math.floor(loaded_bitmap.width * scale + 0.5))
            local height = math.max(1, math.floor(loaded_bitmap.height * scale + 0.5))
            local scaled = emu.bitmap_argb32(width, height)
            loaded_bitmap:resample(scaled)
            emu.print_info(string.format("screen1png: scaled %dx%d -> %dx%d",
                loaded_bitmap.width, loaded_bitmap.height, width, height))
            loaded_bitmap = scaled
        end

        local loaded_texture = manager.machine.render:texture_alloc(loaded_bitmap)
        release_image()
        bitmap = loaded_bitmap
        texture = loaded_texture
        emu.print_info("screen1png: loaded " .. path)
        return true
    end

    local function refresh_image()
        local state = read_state()
        if not state or state == last_state then
            return
        end
        last_state = state
        release_image()

        if state:match("^OFF|%d+$") then
            return
        end

        local rom = emu.romname()
        local image_path
        if state:match("^GUI|%d+$") then
            if rom == "___empty" or rom == "" then
                image_path = banner_png
            end
        else
            local panel_rom, panel_code = state:match("^PANEL|([^|]+)|([^|]+)|%d+$")
            if panel_rom and panel_rom == rom then
                image_path = panel_pngs[panel_code]
                if not image_path then
                    report_error("unknown panel code in state: " .. panel_code)
                end
            else
                local default_rom = state:match("^DEFAULT|([^|]+)|%d+$")
                if default_rom and default_rom == rom then
                    image_path = banner_png
                elseif not default_rom then
                    report_error("invalid panel state: " .. state)
                end
            end
        end

        if image_path then
            load_image(image_path)
        end
    end

    local function prepare()
        release()

        if not panel_output_enabled then
            return
        end

        local screens = 0
        for _ in pairs(manager.machine.screens) do
            screens = screens + 1
        end
        if screens > 1 then
            emu.print_info("screen1png: leaving native multi-screen system " .. emu.romname() .. " untouched")
            return
        end

        local visible = 0
        for _, candidate in ipairs(manager.machine.render.targets) do
            if not candidate.hidden then
                visible = visible + 1
                if visible == 2 then
                    target = candidate
                    break
                end
            end
        end
        if not target or not target.ui_container or target.is_ui_target then
            target = nil
            report_error("second visible output unavailable or used by the GUI")
            return
        end

        pending = false
        refresh_image()
        emu.print_info("screen1png: panel output ready for " .. emu.romname())
    end

    emu.register_before_load_settings(function ()
        release()
        pending = true
    end)
    stop_subscriber = emu.add_machine_stop_notifier(release)
    emu.register_frame_done(function ()
        if pending then
            prepare()
        elseif target then
            frame_count = frame_count + 1
            if frame_count >= STATE_POLL_FRAMES then
                frame_count = 0
                refresh_image()
            end
        end

        if not target or not texture or target.is_ui_target then
            return
        end
        local container = target.ui_container
        if target.width <= 0 or target.height <= 0 then
            return
        end

        if not panel_container then
            panel_container = container
            original_orientation = container.orientation
        end
        -- Cancel the target's game rotation/flips for this UI overlay only.
        local orientation = target.orientation
        if (orientation & 4) ~= 0 then
            orientation = (orientation & 4) | ((orientation & 1) << 1) | ((orientation & 2) >> 1)
        end
        container.orientation = orientation

        local pixel_aspect = target.pixel_aspect
        local output_aspect = target.width * pixel_aspect / target.height
        local image_aspect = bitmap.width / bitmap.height
        local width, height = 1, 1
        if image_aspect > output_aspect then
            height = output_aspect / image_aspect
        else
            width = image_aspect / output_aspect
        end
        local left, top = (1 - width) / 2, (1 - height) / 2
        container:draw_box(0, 0, 1, 1, 0xff000000, 0xff000000)
        container:draw_quad(texture, left, top, left + width, top + height)
    end)
end

return exports
