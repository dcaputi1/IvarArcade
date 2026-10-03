#!/usr/bin/env bash
set -Eeuo pipefail

readonly AUDIO_SCRIPT="$HOME/scripts/set_asound.sh"

if [[ "$(id -un)" != "danc" ]]; then
  echo "Error: Run this script as danc, not as root or with sudo." >&2
  exit 1
fi

if [[ ! -f "$AUDIO_SCRIPT" ]]; then
  echo "Error: $AUDIO_SCRIPT is missing; run setup_pi5_phase2.sh first." >&2
  exit 1
fi

bash "$AUDIO_SCRIPT"

echo
echo "Phase 3 complete. Pi 5 setup is finished."
