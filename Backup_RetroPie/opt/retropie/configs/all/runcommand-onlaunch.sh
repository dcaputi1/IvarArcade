# Dan C. - custom launch script (invoked by runcommand.sh $3=ROM filename)
# With the marquees daemon running, send the command to load the artwork

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
fi

echo "runcommand-onlauch exit $date" >> /tmp/rc.out
