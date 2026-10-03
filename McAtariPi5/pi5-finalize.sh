#!/usr/bin/env bash
set -Eeuo pipefail

readonly LOG_FILE="$HOME/setup_pi5.log"
exec > >(tee -a "$LOG_FILE") 2>&1
printf '\n[%s] Starting %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "${0##*/}"

readonly AUDIO_SCRIPT="$HOME/scripts/set_asound.sh"

if [[ "$(id -un)" != "danc" ]]; then
  echo "Error: Run this script as danc, not as root or with sudo." >&2
  exit 1
fi

if [[ ! -f "$AUDIO_SCRIPT" ]]; then
  echo "Error: $AUDIO_SCRIPT is missing; run pi5-setup.sh first." >&2
  exit 1
fi

bash "$AUDIO_SCRIPT"

echo
echo "Pi 5 setup finalized."
