# ASUS ZenBook Flip 15 (Q528E) Hardware Setup

Sets up trackpad firmware workaround, tablet mode switching, and function key bindings for Omarchy Linux (Arch + Hyprland).

## Hardware

- Trackpad: ELAN1206:00 04F3:30F1
- Touchscreen: ELAN9009:00 04F3:2C26
- Desktop: Hyprland (Wayland)
- User: brad

## What lives in the dotfiles repo

These are already managed by stow — no manual creation needed:

**`dot-local/bin/touchpad_monitor.sh`** — monitors trackpad events, cycles the `idma64.1` DMA controller to work around the firmware bug that reports finger-lift every ~100ms.

**`dot-local/bin/toggle-touchpad.sh`** — toggles touchpad via `hyprctl keyword`, state tracked in `/tmp/touchpad-enabled`.

**`dot-local/bin/toggle-camera.sh`** — uses `fuser -sk /dev/video*` (not `lsof` — too slow) to kill camera consumers, then `modprobe -r uvcvideo`.

**`dot-local/bin/setup-zenbook.sh`** — one-shot script that creates all system files below. Run with `! setup-zenbook.sh` (not sudo — yay can't run as root).

**`hypr/bindings.conf`** — function key bindings already included:
- F6 `XF86TouchpadToggle` → toggle-touchpad.sh
- F9 `SUPER+L` → hyprlock
- F10 `XF86WebCam` → toggle-camera.sh
- F11 `SUPER+SHIFT+S` → grimblast copy area
- F12 `XF86Launch1` → omarchy-menu

## System files (created by setup-zenbook.sh)

### `/etc/systemd/system/touchpad_monitor.service`

```ini
[Unit]
Description=Touchpad Monitor Service
After=systemd-udev-settle.service

[Service]
ExecStart=/home/brad/.local/bin/touchpad_monitor.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### `/usr/local/bin/tablet-mode-switch.sh`

Reads `intel-hid` tablet_mode sysfs node. In tablet mode: stops touchpad monitor, unbinds touchpad, binds touchscreen. In laptop mode: reverses and restarts touchpad monitor.

### `/etc/udev/rules.d/95-tablet-mode.rules`

```
ACTION=="change", SUBSYSTEM=="platform", KERNEL=="intel-hid", RUN+="/usr/local/bin/tablet-mode-switch.sh"
```

### `/etc/sudoers.d/brad-hardware` (chmod 440)

```
brad ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/idma64/unbind
brad ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/idma64/bind
brad ALL=(ALL) NOPASSWD: /usr/local/bin/tablet-mode-switch.sh
brad ALL=(ALL) NOPASSWD: /usr/bin/systemctl start touchpad_monitor.service
brad ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop touchpad_monitor.service
brad ALL=(ALL) NOPASSWD: /usr/bin/modprobe -r uvcvideo
brad ALL=(ALL) NOPASSWD: /usr/bin/modprobe uvcvideo
```

## Packages

- `evtest` — pacman
- `grimblast-git` — AUR via yay (both handled by setup-zenbook.sh)
- `psmisc` (provides `fuser`) — should already be present; install via pacman if not

## Setup

```bash
! setup-zenbook.sh
```

Run with `!` so it executes in your interactive terminal session. Do **not** prefix with `sudo` — yay cannot build AUR packages as root.
