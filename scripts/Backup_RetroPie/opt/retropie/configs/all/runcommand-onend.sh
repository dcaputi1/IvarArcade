# Dan C. - custom game end script (invoked by runcommand.sh)
# With the marquees daemon running, send "NA" to load the RA marquee

echo "RA" > /tmp/dmarquees_cmd
