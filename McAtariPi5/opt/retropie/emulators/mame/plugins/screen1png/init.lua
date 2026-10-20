local exports = {
    name = "screen1png",
    version = "0.1.0",
    description = "Opt-in second-output PNG proof of concept",
    license = "MIT",
    author = { name = "Dan Caputi" }
}

local stop_subscriber

function exports.startplugin()
    local target
    local bitmap
    local texture
    local game_png = os.getenv("MAME_SCREEN1_GAME_PNG") or "/home/danc/IvarArcade/images/RetroPieMarquee.png"
    local banner_png = os.getenv("MAME_SCREEN1_BANNER_PNG") or "/home/danc/IvarArcade/images/MAMELogoR.png"

    local function report_error(message)
        emu.print_error("screen1png: " .. message)
    end

    local function release()
        target = nil
        if texture then
            texture:free()
            texture = nil
        end
        bitmap = nil
    end

    local function prepare()
        release()

        local screens = 0
        for _ in pairs(manager.machine.screens) do
            screens = screens + 1
        end
        if screens > 1 then
            emu.print_info("screen1png: leaving multi-screen system " .. emu.romname() .. " untouched")
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
            report_error("second visible output unavailable or used by the GUI; launch with -numscreens 2 and keep the GUI on output 0")
            return
        end

        local rom = emu.romname()
        local path = (rom == "___empty" or rom == "") and banner_png or game_png
        local file, open_error = io.open(path, "rb")
        if not file then
            report_error("cannot open " .. path .. ": " .. tostring(open_error))
            target = nil
            return
        end
        local data, read_error = file:read("*a")
        local closed, close_error = file:close()
        if not data or not closed then
            report_error("cannot read/close " .. path .. ": " .. tostring(read_error or close_error))
            target = nil
            return
        end

        local decoded, result = pcall(emu.bitmap_argb32.load, data)
        if not decoded then
            report_error("cannot decode " .. path .. ": " .. tostring(result))
            target = nil
            return
        end
        bitmap = result
        texture = manager.machine.render:texture_alloc(bitmap)
        emu.print_info("screen1png: " .. rom .. " -> " .. path)
    end

    emu.register_before_startup_screens(prepare)
    stop_subscriber = emu.add_machine_stop_notifier(release)
    emu.register_frame_done(function ()
        if not target or not texture or target.is_ui_target then
            return
        end
        local container = target.ui_container
        if target.width <= 0 or target.height <= 0 then
            return
        end

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
