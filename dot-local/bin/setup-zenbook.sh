#!/usr/bin/env bash
set -euo pipefail

echo "==> ZenBook Q528E hardware setup"

# --- Systemd service ---
echo "==> Creating touchpad_monitor.service"
sudo tee /etc/systemd/system/touchpad_monitor.service > /dev/null << 'EOF'
[Unit]
Description=Touchpad Monitor Service
After=systemd-udev-settle.service

[Service]
ExecStart=/home/brad/.local/bin/touchpad_monitor.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# --- Tablet mode switch script ---
echo "==> Creating /usr/local/bin/tablet-mode-switch.sh"
sudo tee /usr/local/bin/tablet-mode-switch.sh > /dev/null << 'EOF'
#!/bin/bash
TOUCHPAD_DEVICE="i2c-ELAN1206:00"
TOUCHSCREEN_DEVICE="i2c-ELAN9009:00"

if [ -f /sys/bus/platform/devices/intel-hid/tablet_mode ]; then
    TABLET_MODE=$(cat /sys/bus/platform/devices/intel-hid/tablet_mode)
elif [ -f /sys/devices/platform/intel-hid/tablet_mode ]; then
    TABLET_MODE=$(cat /sys/devices/platform/intel-hid/tablet_mode)
else
    TABLET_MODE=0
fi

logger "tablet-mode-switch: mode=$TABLET_MODE"

if [ "$TABLET_MODE" = "1" ]; then
    systemctl stop touchpad_monitor.service
    [ -e "/sys/bus/i2c/drivers/i2c_hid_acpi/$TOUCHPAD_DEVICE" ] && \
        echo "$TOUCHPAD_DEVICE" > /sys/bus/i2c/drivers/i2c_hid_acpi/unbind 2>/dev/null
    [ ! -e "/sys/bus/i2c/drivers/i2c_hid_acpi/$TOUCHSCREEN_DEVICE" ] && \
        echo "$TOUCHSCREEN_DEVICE" > /sys/bus/i2c/drivers/i2c_hid_acpi/bind 2>/dev/null
else
    [ ! -e "/sys/bus/i2c/drivers/i2c_hid_acpi/$TOUCHPAD_DEVICE" ] && \
        echo "$TOUCHPAD_DEVICE" > /sys/bus/i2c/drivers/i2c_hid_acpi/bind 2>/dev/null
    [ -e "/sys/bus/i2c/drivers/i2c_hid_acpi/$TOUCHSCREEN_DEVICE" ] && \
        echo "$TOUCHSCREEN_DEVICE" > /sys/bus/i2c/drivers/i2c_hid_acpi/unbind 2>/dev/null
    systemctl start touchpad_monitor.service
fi
EOF
sudo chmod +x /usr/local/bin/tablet-mode-switch.sh

# --- udev rule ---
echo "==> Creating udev rule for tablet mode"
sudo tee /etc/udev/rules.d/95-tablet-mode.rules > /dev/null << 'EOF'
ACTION=="change", SUBSYSTEM=="platform", KERNEL=="intel-hid", RUN+="/usr/local/bin/tablet-mode-switch.sh"
EOF

# --- Sudoers ---
echo "==> Creating /etc/sudoers.d/brad-hardware"
sudo tee /etc/sudoers.d/brad-hardware > /dev/null << 'EOF'
brad ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/idma64/unbind
brad ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/idma64/bind
brad ALL=(ALL) NOPASSWD: /usr/local/bin/tablet-mode-switch.sh
brad ALL=(ALL) NOPASSWD: /usr/bin/systemctl start touchpad_monitor.service
brad ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop touchpad_monitor.service
brad ALL=(ALL) NOPASSWD: /usr/bin/modprobe -r uvcvideo
brad ALL=(ALL) NOPASSWD: /usr/bin/modprobe uvcvideo
EOF
sudo chmod 440 /etc/sudoers.d/brad-hardware

# --- Packages ---
echo "==> Installing packages"
sudo pacman -S --needed --noconfirm evtest
yay -S --needed --noconfirm grimblast-git

# --- Enable service + reload udev ---
echo "==> Enabling touchpad_monitor service"
sudo systemctl daemon-reload
sudo systemctl enable --now touchpad_monitor.service

echo "==> Reloading udev rules"
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "==> Done"
