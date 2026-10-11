#!/usr/bin/env bash
set -Eeuo pipefail

readonly ATTEMPTS=30

if ! command -v wpctl >/dev/null 2>&1; then
  echo "Error: wpctl is missing; Raspberry Pi OS PipeWire volume control is unavailable." >&2
  exit 1
fi

for ((attempt = 1; attempt <= ATTEMPTS; attempt++)); do
  if wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.9 >/dev/null 2>&1; then
    echo "Default PipeWire audio sink volume set to 90% with wpctl."
    exit 0
  fi
  sleep 1
done

echo "Error: wpctl could not set the default PipeWire audio sink to 90% after $ATTEMPTS attempts." >&2
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.9
exit 1
