-- Personal keybinding overrides. Anything Omarchy's defaults already cover is
-- deliberately absent here -- app launchers, web apps, media and brightness
-- keys, notifications, capture, dictation, and the touchpad toggle all live in
-- /usr/share/omarchy/default/hypr/bindings/.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Web apps Omarchy points somewhere else.
hl.unbind("SUPER + SHIFT + ALT + A") -- was: Grok
o.bind("SUPER + SHIFT + ALT + A", "Claude", { webapp = "https://claude.ai" })

hl.unbind("SUPER + SHIFT + C") -- was: Hey Calendar
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.google.com/" })

hl.unbind("SUPER + SHIFT + E") -- was: Hey Email
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://app.shortwave.com" })

-- Quick task capture. The launcher prompt walker used to own, now the menu's
-- own input mode -- see ~/.local/bin/ticktick-add-launch. Ctrl+Shift+A is free
-- in the defaults, which reach for SUPER for everything.
o.bind("CTRL + SHIFT + A", "Add TickTick task", "ticktick-add-launch")

-- ASUS Zenbook function keys. The firmware emits a chord rather than a plain
-- keysym for each of these, so reaching the use printed on the key means taking
-- the chord back from whichever Omarchy default holds it.

-- F8 (display/present key), was: Pseudo window.
hl.unbind("SUPER + P")
o.bind("SUPER + P", "Toggle display mirroring", "omarchy-hyprland-monitor-internal-mirror toggle")

-- F9 (lock key), was: Toggle workspace layout.
hl.unbind("F9")
o.bind("SUPER + L", "Lock system", "omarchy-system-lock")

-- F11 (screenshot key), was: Google Maps.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- F10 and F12 (MyAsus) have no Omarchy default, so they need no unbind.
-- Omarchy has no camera kill switch of its own; toggle-camera.sh unloads the
-- uvcvideo module. Spelled out because ~/.local/bin is not on Hyprland's PATH.
o.bind("XF86WebCam", "Toggle camera", os.getenv("HOME") .. "/.local/bin/toggle-camera.sh")

-- Screen annotation. Harmless while wayscriber is uninstalled -- pkill simply
-- matches nothing.
o.bind("XF86Launch1", "Toggle screen annotation", "wayscriber --daemon-toggle")
o.bind("SUPER + D", "Toggle screen annotation", "wayscriber --daemon-toggle")
o.bind("SUPER + ALT + L", "Toogle annotation on working screen", "wayscriber --light-toggle")
o.bind("SUPER + ALT + D", "Temporary annotation tools in light mode", "wayscriber --light-draw-toggle")

-- Tablet mode. The hinge switch is a real input device -- `hyprctl devices`
-- lists it under Switches -- so Hyprland can bind it the same way Omarchy binds
-- the lid. A udev rule already rebinds the touchpad and touchscreen when the
-- mode flips (see setup-zenbook.sh); this only says so out loud. `locked` so it
-- still fires with the screen locked, matching the lid binds.
o.bind("switch:on:Intel HID switches", nil, o.notify("Tablet mode on"), { locked = true })
o.bind("switch:off:Intel HID switches", nil, o.notify("Tablet mode off"), { locked = true })
