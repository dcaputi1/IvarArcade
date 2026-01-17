#!/bin/bash
# cp_opt.sh - Copy configs and MAME installation from ExtremeSSD backup
# Run this from: /media/danc/ExtremeSSD/Backup_RetroPie/
# This copies the full MAME installation (binaries, tools, configs) from ExtremeSSD

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run with sudo or as root." >&2
    exit 1
fi

log() {
    set +x
    printf "%s\n" "$@"
    set -x
}

set -x

# Copy MAME installation and configs from ExtremeSSD backup
cp -vrf /media/danc/ExtremeSSD/Backup_RetroPie/opt/retropie/ /opt/
cp -vrf /media/danc/ExtremeSSD/Backup_RetroPie/home/danc/ /home/

# Set ownership
chown -R danc /opt/retropie
chown -R danc /home/danc

# Make scripts executable
### chmod +x /home/danc/scripts/*    (TBD where are all my scripts?)

# Create MAME home directory symlink
# note: -sfn replaces RetroArch mame package configs link (TBD hope that's ok)
ln -sfn /opt/retropie/emulators/mame/ /home/danc/.mame

log "get rid of lr-mame's ini and plugins and replace with symlink to canonical copies"
rm -r /home/danc/RetroPie/BIOS/mame/ini
ln -s /opt/retropie/emulators/mame/ini/ /home/danc/RetroPie/BIOS/mame/ini

rm -r /home/danc/RetroPie/BIOS/mame/plugins
ln -s /opt/retropie/emulators/mame/plugins/ /home/danc/RetroPie/BIOS/mame/plugins

log "cfg and ini files should all be rw 666"
find /opt/retropie/emulators/mame/ -type f \( -name "*.cfg" -o -name "*.ini" \) -exec chmod 666 {} \;

# Protect default config from MAME writes (TBD - omit?)
## chmod 444 /opt/retropie/emulators/mame/cfg_sa/default.cfg
## 1/17/2026 - must allow writes for xinmo controller swapping