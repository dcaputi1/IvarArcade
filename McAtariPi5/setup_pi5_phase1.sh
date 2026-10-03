#!/usr/bin/env bash
set -Eeuo pipefail

readonly LOG_FILE="$HOME/setup_pi5.log"
exec > >(tee -a "$LOG_FILE") 2>&1
printf '\n[%s] Starting %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "${0##*/}"

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

echo "Configuring the IvarArcade autostart sudo rules..."
sudoers_tmp="$(mktemp)"
cat > "$sudoers_tmp" <<'SUDOERS'
danc ALL=(ALL) NOPASSWD: /usr/bin/tee
danc ALL=(ALL) NOPASSWD: /bin/pkill
danc ALL=(ALL) NOPASSWD: /usr/bin/stdbuf
danc ALL=(ALL) NOPASSWD: /bin/systemctl
danc ALL=(ALL) NOPASSWD: /usr/local/bin/ultrastikcmd
SUDOERS
sudo visudo -cf "$sudoers_tmp"
sudo install -o root -g root -m 0440 "$sudoers_tmp" /etc/sudoers.d/autostart-nopass
rm -f "$sudoers_tmp"
sudo sed -i 's/^[[:space:]]*#user_allow_other/user_allow_other/' /etc/fuse.conf

(
  while sleep 60; do
    sudo -n -v || exit
  done
) &
readonly SUDO_KEEPALIVE_PID=$!

cleanup_sudo_keepalive() {
  kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
}
trap cleanup_sudo_keepalive EXIT

echo "Installing local developer and controller-debugging tools..."
sudo -n apt-get update
sudo -n apt-get install -y meld jstest-gtk code fuse-zip librsvg2-bin

echo "Taking ownership of the RetroPie installation..."
sudo -n chown -R danc /opt/retropie

echo "Copying ROMs and assets from ExtremeSSD..."
bash "$SCRIPT_DIR/cp_roms.sh"

echo "Installing game-analyzer dependencies and USB controller rule..."
sudo -n bash "$SCRIPT_DIR/analyze_games.sh"

echo "Preparing RetroArch MAME config directory..."
mkdir -p /opt/retropie/configs/all/retroarch/config/MAME

echo "Adding RetroPie emulator binaries to the system PATH..."
if ! grep -Fq '# IvarArcade Pi 5 PATH' /etc/profile; then
  printf '%s\n' \
    '# IvarArcade Pi 5 PATH' \
    'export PATH="$PATH:/opt/retropie/emulators/mame:/opt/retropie/emulators/retroarch/bin"' \
    | sudo -n tee -a /etc/profile >/dev/null
fi

echo "Building and installing IvarArcade components..."
make -C "$REPO_ROOT" install-force

echo
echo "Phase 1 complete. Reboot the Pi 5, then run:"
echo "  bash ~/IvarArcade/McAtariPi5/setup_pi5_phase2.sh"
