#!/bin/bash

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

cp -vrf ./opt/retropie/ /opt/
cp -vrf ./home/danc/ /home/

ln -s /opt/retropie/emulators/mame/ /home/danc/.mame

chown -R danc /opt/retropie
chown -R danc /home/danc
chmod +x /home/danc/scripts/*
chmod 444 /opt/retropie/emulators/mame/cfg_sa/default.cfg

log "get rid of lr-mame's ini and plugins and replace with symlink to canonical copies"
rm -r /home/danc/RetroPie/BIOS/mame/ini
ln -s /opt/retropie/emulators/mame/ini/ /home/danc/RetroPie/BIOS/mame/ini

rm -r /home/danc/RetroPie/BIOS/mame/plugins
ln -s /opt/retropie/emulators/mame/plugins/ /home/danc/RetroPie/BIOS/mame/plugins

log "cfg and ini files should all be rw 666"
find /opt/retropie/emulators/mame/ -type f \( -name "*.cfg" -o -name "*.ini" \) -exec chmod 666 {} \;
