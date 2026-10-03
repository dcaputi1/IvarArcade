#!/usr/bin/env bash
set -Eeuo pipefail

readonly LOG_FILE="$HOME/setup_pi5.log"
exec > >(tee -a "$LOG_FILE") 2>&1
printf '\n[%s] Starting %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "${0##*/}"

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly SSD_MOUNT="/media/danc/ExtremeSSD"
readonly ULTRASTIK_DIR="$HOME/IvarArcade/tools/linux/UltrastikCmd"

fail() {
  echo "Error: $*" >&2
  exit 1
}

usage() {
  echo "Usage: $0 [--with-pi3]" >&2
  exit 2
}

configure_pi3_network=false
if [[ $# -gt 1 ]]; then
  usage
elif [[ $# -eq 1 ]]; then
  [[ "$1" == "--with-pi3" ]] || usage
  configure_pi3_network=true
fi

[[ "$(id -un)" == "danc" ]] || fail "Run this script as danc, not as root or with sudo."
mountpoint -q "$SSD_MOUNT" || fail "Mount the backup drive at $SSD_MOUNT before continuing."
[[ -x "$REPO_ROOT/analyze_games/analyze_games" ]] || fail "Run setup_pi5_phase1.sh first; analyze_games is not installed."
[[ -f "$HOME/scripts/disable_hdmi_audio.sh" ]] || fail "disable_hdmi_audio.sh is missing; run make install-force first."

sudo -v

echo "Building UltrastikCmd..."
mkdir -p "$HOME/IvarArcade/tools/linux"
if [[ ! -d "$ULTRASTIK_DIR" ]]; then
  git clone https://github.com/dcaputi1/UltrastikCmd.git "$ULTRASTIK_DIR"
fi
[[ -f "$ULTRASTIK_DIR/build.sh" ]] || fail "UltrastikCmd checkout is missing build.sh: $ULTRASTIK_DIR"
bash "$ULTRASTIK_DIR/build.sh"
sudo ldconfig
ldconfig -p | grep 'libhid\.so\.0' >/dev/null || fail "libhid.so.0 is not registered with ldconfig."
[[ -x /usr/local/bin/ultrastikcmd ]] || fail "Expected /usr/local/bin/ultrastikcmd after building UltrastikCmd."

echo "Restoring RetroArch and EmulationStation assets..."
bash "$SCRIPT_DIR/ra_final.sh"

echo "Generating game analysis files..."
"$REPO_ROOT/analyze_games/analyze_games"

echo "Disabling HDMI audio..."
bash "$HOME/scripts/disable_hdmi_audio.sh"

if [[ "$configure_pi3_network" == true ]]; then
  echo "Configuring the Pi 5 wired link for the Pi 3 marquee node..."
  if nmcli -t -f NAME connection show | grep -Fx eth0-static >/dev/null; then
    sudo nmcli connection modify eth0-static \
      connection.interface-name eth0 \
      ipv4.method manual \
      ipv4.addresses 10.77.77.5/24
  else
    sudo nmcli connection add type ethernet ifname eth0 con-name eth0-static \
      ipv4.method manual ipv4.addresses 10.77.77.5/24
  fi
  sudo nmcli connection up eth0-static
fi

echo
echo "Phase 2 complete. Reboot the Pi 5, then run:"
echo "  bash ~/IvarArcade/McAtariPi5/setup_pi5_phase3.sh"
if [[ "$configure_pi3_network" == true ]]; then
  echo "Configure the Pi 3 wired connection as 10.77.77.3/24, then verify with:"
  echo "  ping -c2 10.77.77.3"
  echo "Run ssh-copy-id danc@10.77.77.3 if this is a fresh Pi 3 baseline."
fi
