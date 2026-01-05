# Dan C. - custom launch script (invoked by runcommand.sh $3=ROM filename)
# With the marquees daemon running, send the command to load the artwork
# Also configures UltraStik to 4-way mode for games that need it

echo "runcommand-onlaunch started $date" > /tmp/rc.out

#SYSTEM="$1"
#EMULATOR="$2"
ROM="$3"
#CMD="$4"

# send ROM name to marquee daemon
echo "checking rom $ROM" >> /tmp/rc.out
if [[ -n "$ROM" ]]; then
    romzip="$(basename "$ROM")"
    command="${romzip%.zip}"
	echo "input $romzip : writing command $command" >> /tmp/rc.out
    # Write the ROM filename (without path) to the marquee command file
    echo "$command" > /tmp/dmarquees_cmd
    
    # Check if game needs special joystick configuration
    # Q*bert uses a 45° rotated joystick (diagonal-primary)
    if [[ "$command" == "qbert" ]]; then
        echo "Q*bert detected - using diagonal joystick config" >> /tmp/rc.out
        # TODO: Configure UltraStik for Q*bert's 45° rotated control
        # When on Pi5, this would call: ultramarc /path/to/qbert.um
        echo "Would execute: ultramarc qbert.um (45° rotated)" >> /tmp/rc.out
    else
        # Check if game needs 4-way joystick configuration
        INI_FILE="/opt/retropie/emulators/mame/ini/${command}.ini"
        if [[ -f "$INI_FILE" ]]; then
            # Check if the INI file contains joystick_map (indicating 4-way game)
            if grep -q "^joystick_map" "$INI_FILE"; then
                echo "4-way game detected: $command" >> /tmp/rc.out
                # TODO: Configure UltraStik for 4-way mode with sticky diagonals
                # When on Pi5, this would call: ultramarc /path/to/4-way.um
                # Stubbed for now since we're on Windows
                echo "Would execute: ultramarc 4-way.um (sticky diagonals)" >> /tmp/rc.out
            else
                echo "8-way game (has INI but no joystick_map): $command" >> /tmp/rc.out
            fi
        else
            echo "No custom INI file found, assuming 8-way: $command" >> /tmp/rc.out
        fi
    fi
fi

echo "runcommand-onlauch exit $date" >> /tmp/rc.out
