#!/usr/bin/env bash
set -euo pipefail

# Target ALSA device
# Prefer the USB audio device by name instead of assuming a card number.
CARD_NUM="${CARD_NUM:-}"
DEV_NUM="${DEV_NUM:-0}"

ASOUND_CONF="/etc/asound.conf"
TMP_FILE="$(mktemp)"

detect_usb_audio_card() {
  local line card

  while IFS= read -r line; do
    if [[ "$line" =~ ^card[[:space:]]+([0-9]+):[[:space:]].*(USB.*Audio|Audio\s*\[USB Audio\]).*$ ]]; then
      echo "${BASH_REMATCH[1]}"
      return 0
    fi
  done < <(aplay -l 2>/dev/null || true)

  return 1
}

if detected_card="$(detect_usb_audio_card)"; then
  CARD_NUM="$detected_card"
  echo "[INFO] Detected USB audio card: ${CARD_NUM}"
elif [[ -z "$CARD_NUM" ]]; then
  echo "[ERROR] USB audio device was not detected; refusing to configure a guessed ALSA card." >&2
  exit 1
fi

cleanup() {
  rm -f "$TMP_FILE"
}
trap cleanup EXIT

# Build desired config
cat > "$TMP_FILE" <<EOF
# /etc/asound.conf
# Force ALSA default device to card ${CARD_NUM}, device ${DEV_NUM} (hw:${CARD_NUM},${DEV_NUM})

pcm.!default {
    type plug
    slave.pcm "hw:${CARD_NUM},${DEV_NUM}"
}

ctl.!default {
    type hw
    card ${CARD_NUM}
}
EOF

# Install only if changed
if [[ -f "$ASOUND_CONF" ]] && sudo cmp -s "$TMP_FILE" "$ASOUND_CONF"; then
  echo "[OK] $ASOUND_CONF already up to date."
else
  echo "[INFO] Updating $ASOUND_CONF ..."
  sudo install -m 0644 -o root -g root "$TMP_FILE" "$ASOUND_CONF"
  echo "[OK] Wrote $ASOUND_CONF"
fi

# Optional: restart modern audio services if present (no error if absent)
sudo systemctl restart pipewire pipewire-pulse wireplumber 2>/dev/null || true

echo "[DONE] ALSA default set to hw:${CARD_NUM},${DEV_NUM}"
