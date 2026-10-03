#!/usr/bin/env bash
set -Eeuo pipefail

if ! mountpoint -q /media/danc/ExtremeSSD; then
	echo "Error: backup drive is not mounted at /media/danc/ExtremeSSD." >&2
	exit 1
fi

step() {
	echo
	echo "$1"
}

run() {
	echo "$ $*"
	"$@"
}

# Copy RetroArch/EmulationStation media assets ExtremeSSD backup
step "Copying RetroArch/EmulationStation media assets from ExtremeSSD backup"
run cp -vrf /media/danc/ExtremeSSD/McAtariPi5/home/danc/ /home/
run cp -vrf /media/danc/ExtremeSSD/McAtariPi5/opt/retropie/ /opt/

# Create MAME home directory symlink
# note: -sfn replaces RetroArch mame package configs link
step "Creating/refreshing ~/.mame symlink"
run ln -sfn /opt/retropie/emulators/mame/ /home/danc/.mame

step "Replacing lr-mame ini and plugins with symlinks to canonical copies"
replace_link() {
	local target="$1"
	local link="$2"
	if [ -e "$link" ] || [ -L "$link" ]; then
		run rm -rf -- "$link"
	fi
	run ln -s "$target" "$link"
}

mkdir -p /home/danc/RetroPie/BIOS/mame
replace_link /opt/retropie/emulators/mame/ini/ /home/danc/RetroPie/BIOS/mame/ini
replace_link /opt/retropie/emulators/mame/plugins/ /home/danc/RetroPie/BIOS/mame/plugins
