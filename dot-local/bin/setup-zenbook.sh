#!/usr/bin/env bash
set -euo pipefail

# Tablet mode is NOT here: the udev-level answer this script used to provision
# matched a platform device (`intel-hid`) the kernel no longer creates, so it had
# stopped firing. Hyprland binds the hinge switch directly now -- see
# hypr/bindings.lua and ~/.local/bin/tablet-mode.

echo "==> ZenBook Q528E hardware setup"

# --- Touchpad monitor ---
echo "==> Building touchpad_monitor"
gcc -O2 -o "$HOME/.local/bin/touchpad_monitor" "$HOME/.local/src/touchpad_monitor.c"

# --- Systemd service ---
echo "==> Creating touchpad_monitor.service"
sudo tee /etc/systemd/system/touchpad_monitor.service > /dev/null << 'EOF'
[Unit]
Description=Touchpad Monitor Service
After=systemd-udev-settle.service

[Service]
ExecStart=/home/brad/.local/bin/touchpad_monitor
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# --- Sudoers ---
echo "==> Creating /etc/sudoers.d/brad-hardware"
sudo tee /etc/sudoers.d/brad-hardware > /dev/null << 'EOF'
brad ALL=(ALL) NOPASSWD: /usr/bin/modprobe -r uvcvideo
brad ALL=(ALL) NOPASSWD: /usr/bin/modprobe uvcvideo
EOF
sudo chmod 440 /etc/sudoers.d/brad-hardware

# --- Packages ---
echo "==> Installing packages"
yay -S --needed --noconfirm grimblast-git

# --- Enable service ---
echo "==> Enabling touchpad_monitor service"
sudo systemctl daemon-reload
sudo systemctl enable --now touchpad_monitor.service

echo "==> Done"
