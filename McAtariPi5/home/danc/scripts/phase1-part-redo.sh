tmp=$(mktemp)
cat > "$tmp" <<'SUDOERS'
danc ALL=(ALL) NOPASSWD: /usr/bin/tee
danc ALL=(ALL) NOPASSWD: /bin/pkill
danc ALL=(ALL) NOPASSWD: /usr/bin/stdbuf
danc ALL=(ALL) NOPASSWD: /bin/systemctl
danc ALL=(ALL) NOPASSWD: /usr/local/bin/ultrastikcmd
SUDOERS
sudo visudo -cf "$tmp" &&
sudo install -o root -g root -m 0440 "$tmp" /etc/sudoers.d/autostart-nopass
result=$?
rm -f "$tmp"
[ "$result" -eq 0 ] || exit "$result"
sudo sed -i 's/^[[:space:]]*#user_allow_other/user_allow_other/' /etc/fuse.conf