# Dan C. - custom launch script (invoked by runcommand.sh $3=ROM filename)
# With the marquees daemon running, send the command to load the artwork
# Also configures UltraStik to 4-way mode for games that need it

echo "runcommand-onlaunch started $date" > /tmp/rc.out

SENDER_SCRIPT="$HOME/scripts/dmarquees-send.sh"
CMD_FIFO="/tmp/dmarquees_cmd"

SYSTEM="${1:-}"
EMULATOR="${2:-}"
ROM="${3:-}"
#CMD="$4"

# process per ROM customizations and send name to dmarquees FIFO
echo "checking rom $ROM system=${SYSTEM:-unknown} emulator=${EMULATOR:-unknown}" >> /tmp/rc.out

if [[ -n "$ROM" ]]; then
    romzip="$(basename "$ROM")"
    command="${romzip%.zip}"

    # Prefer a system-level splash image for known console systems so the
    # secondary monitor shows the console + controller art instead of the ROM.
    display_name="$command"
    case "$SYSTEM" in
        atari2600|atari5200|atari7800|atari800)
            display_name="$SYSTEM"
            ;;
        *)
            case "$EMULATOR" in
                lr-stella2014)
                    display_name="atari2600"
                    ;;
                lr-prosystem)
                    display_name="atari7800"
                    ;;
                lr-atari800)
                    if [[ "$SYSTEM" == "atari5200" ]]; then
                        display_name="atari5200"
                    else
                        display_name="atari800"
                    fi
                    ;;
            esac
            ;;
    esac
    
    # Check if game needs special joystick configuration
    # Q*bert uses a 45° rotated joystick (diagonal-primary)
    if [[ "$command" == "qbert" ]]; then
        echo "Q*bert detected - using diagonal joystick config" >> /tmp/rc.out
        # Configure UltraStik for Q*bert's 45° rotated control
        sudo ultrastikcmd -c 1 -u "/home/danc/IvarArcade/tools/UltraStikMaps/4-WayQBert.um" >> /tmp/rc.out 2>&1
    else
        # Check if game needs 4-way joystick configuration
        INI_FILE="/opt/retropie/emulators/mame/ini/${command}.ini"
        if [[ -f "$INI_FILE" ]]; then
            # Check if the INI file contains joystick_map (indicating 4-way game)
            if grep -q "^joystick_map" "$INI_FILE"; then
                echo "4-way game detected: $command" >> /tmp/rc.out
                # Configure UltraStik for 4-way mode with sticky diagonals
                sudo ultrastikcmd -c 1 -u "/home/danc/IvarArcade/tools/UltraStikMaps/4-Way.um" >> /tmp/rc.out 2>&1
            else
                echo "8-way game (has INI but no joystick_map): $command" >> /tmp/rc.out
                # Configure UltraStik for 8-way with easy diagonals
                sudo ultrastikcmd -c 1 -u "/home/danc/IvarArcade/tools/UltraStikMaps/8-WayEasyDiagonals.um" >> /tmp/rc.out 2>&1
            fi
        else
            echo "No custom INI file found, assuming 8-way: $command" >> /tmp/rc.out
            # Configure UltraStik for 8-way with easy diagonals
            sudo ultrastikcmd -c 1 -u "/home/danc/IvarArcade/tools/UltraStikMaps/8-WayEasyDiagonals.um" >> /tmp/rc.out 2>&1
        fi
    fi

    if [[ "$EMULATOR" == "mame" ]]; then
        # Apply the per-ROM profile before rendering panel art, then give the
        # daemon time to finish its DRM update before MAME starts.
        MAME_WRAPPER="$HOME/scripts/run_mame.sh"
        if [[ -x "$MAME_WRAPPER" ]] && "$MAME_WRAPPER" --prepare "$ROM" >> /tmp/rc.out 2>&1; then
            mame_rom_name="${romzip%.*}"
            echo "input $romzip : sending $mame_rom_name to dmarquees before MAME" >> /tmp/rc.out

            if [[ -p "$CMD_FIFO" ]]; then
                printf '%s\n' "$mame_rom_name" > "$CMD_FIFO"
            else
                echo "dmarquees FIFO unavailable: $CMD_FIFO" >> /tmp/rc.out
            fi

            if [[ -x "$SENDER_SCRIPT" ]]; then
                "$SENDER_SCRIPT" "$mame_rom_name" >/dev/null 2>&1 &
            fi

            sleep 0.75
        else
            echo "Failed to prepare MAME profile; skipping early marquee command" >> /tmp/rc.out
        fi
    else
        # Send either the game name or the console art name to dmarquees.
        echo "input $romzip : sending $display_name to dmarquees" >> /tmp/rc.out

        if [[ -x "$SENDER_SCRIPT" ]]; then
            "$SENDER_SCRIPT" "$display_name"
        fi

        echo "$display_name" > "$CMD_FIFO"
    fi
fi
