#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=""
for candidate in /boot/firmware/config.txt /boot/config.txt; do
  if [[ -f "$candidate" ]]; then
    CONFIG_FILE="$candidate"
    break
  fi
done

if [[ -z "$CONFIG_FILE" ]]; then
  echo "[ERROR] Raspberry Pi config.txt not found under /boot or /boot/firmware." >&2
  exit 1
fi

if grep -Eq '^[[:space:]]*dtoverlay=vc4-kms-v3d([^,[:alnum:]_]|$)' "$CONFIG_FILE"; then
  sudo sed -i -E 's|^[[:space:]]*dtoverlay=vc4-kms-v3d[[:space:]]*$|dtoverlay=vc4-kms-v3d,noaudio|' "$CONFIG_FILE"
elif ! grep -Eq '^[[:space:]]*dtoverlay=vc4-kms-v3d,noaudio([[:space:]]*#.*)?$' "$CONFIG_FILE"; then
  printf '\n# Disable HDMI audio; retain the VC4 display driver.\ndtoverlay=vc4-kms-v3d,noaudio\n' | sudo tee -a "$CONFIG_FILE" >/dev/null
fi

echo "[OK] HDMI audio disabled in $CONFIG_FILE."
echo "[INFO] Reboot, then run: aplay -l"
echo "[INFO] The USB audio device should then be the remaining ALSA card, normally card 0."
