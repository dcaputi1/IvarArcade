#!/usr/bin/env bash
set -Eeuo pipefail

# install XML package for game analyzer:
apt-get install -y libtinyxml2-dev

# install HID package for PacDrive LED controller:
apt-get install -y python3-hid

# create udev rule for user access to PacDrive:
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="d209", ATTRS{idProduct}=="1500", MODE="0666"' | tee /etc/udev/rules.d/99-pacdrive.rules
udevadm control --reload-rules
udevadm trigger
