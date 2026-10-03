#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly SSD_MOUNT="/media/danc/ExtremeSSD"

fail() {
  echo "Error: $*" >&2
  exit 1
}

[[ "$(id -un)" == "danc" ]] || fail "Run this script as danc, not as root or with sudo."
command -v sudo >/dev/null || fail "sudo is required."
[[ -d /opt/retropie ]] || fail "/opt/retropie is missing; install RetroPie packages first."
mountpoint -q "$SSD_MOUNT" || fail "Mount the backup drive at $SSD_MOUNT before continuing."
[[ -d "$REPO_ROOT/.git" ]] || fail "IvarArcade repository not found at $REPO_ROOT."

sudo -v

echo "Installing local developer and controller-debugging tools..."
sudo apt-get update
sudo apt-get install -y meld jstest-gtk code

echo "Taking ownership of the RetroPie installation..."
sudo chown -R danc /opt/retropie

echo "Copying ROMs and assets from ExtremeSSD..."
bash "$SCRIPT_DIR/cp_roms.sh"

echo "Installing game-analyzer dependencies and USB controller rule..."
sudo bash "$SCRIPT_DIR/analyze_games.sh"

echo "Preparing RetroArch MAME config directory..."
mkdir -p /opt/retropie/configs/all/retroarch/config/MAME

echo "Adding RetroPie emulator binaries to the system PATH..."
if ! grep -Fq '# IvarArcade Pi 5 PATH' /etc/profile; then
  printf '%s\n' \
    '# IvarArcade Pi 5 PATH' \
    'export PATH="$PATH:/opt/retropie/emulators/mame:/opt/retropie/emulators/retroarch/bin"' \
    | sudo tee -a /etc/profile >/dev/null
fi

echo "Building and installing IvarArcade components..."
make -C "$REPO_ROOT" install-force

echo
echo "Phase 1 complete. Reboot the Pi 5, then run:"
echo "  bash ~/IvarArcade/McAtariPi5/setup_pi5_phase2.sh"
