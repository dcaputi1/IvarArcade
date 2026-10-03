#!/usr/bin/env bash
set -Eeuo pipefail

SSD_MOUNT="/media/danc/ExtremeSSD"
if ! mountpoint -q "$SSD_MOUNT"; then
    echo "Error: backup drive is not mounted at $SSD_MOUNT." >&2
    exit 1
fi

line_buffered() {
    stdbuf -oL -eL "$@"
}

# Copy the entire 0.256 internet archive backup
line_buffered cp -vf /media/danc/ExtremeSSD/Mame/mame-merged/mame-merged/*.zip /home/danc/RetroPie/roms/arcade/
line_buffered cp -vrf /media/danc/ExtremeSSD/Mame/MAME_0.256_EXTRAs/ /home/danc/

# Copy the MAME (bios-devices) archive from old MAME stuff - just in case? (shouldn't this be in BIOS/roms?)
line_buffered cp -vf /media/danc/ExtremeSSD/Mame/mame-merged/BIOS/roms/*.zip /home/danc/RetroPie/BIOS/mame/

# OMG! why is this not in the internet archive 0.256 rom set?
line_buffered cp -vf /media/danc/ExtremeSSD/Mame/roms_fav/pacman.zip /home/danc/RetroPie/roms/arcade/

# Copy Atari console binaries from MC Atari FightStick RetroPie console backup
rsync --outbuf=L -av --exclude='/roms/arcade/' /media/danc/ExtremeSSD/Atari/MicroCenter/RetroPie/ /home/danc/RetroPie/
# Overwrite XFormers modified Atari OS-B rom with the original (works with Caverns of Mars)
line_buffered cp -vf /home/danc/IvarArcade/McAtariPi5/home/danc/RetroPie/BIOS/ATARIOSB.ROM /home/danc/RetroPie/BIOS/
# Copy my Atari 800 Disks (renamed for RespeQt) to the roms folder
line_buffered cp -vrf /media/danc/ExtremeSSD/Atari/RetroPie/roms/atari800/ /home/danc/RetroPie/roms/