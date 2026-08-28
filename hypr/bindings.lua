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

-- Quick task capture. The launcher prompt walker used to own, now the TickTick
-- plugin's panel -- its quick-add field takes focus when the panel opens, so
-- one chord still lands a task. Ctrl+Shift+A is free in the defaults, which
-- reach for SUPER for everything. The IPC target belongs to the plugin, so the
-- binding is dead exactly when the plugin is not installed, which is right.
o.bind(
	"CTRL + SHIFT + A",
	"Add TickTick task",
	"omarchy-shell io.github.sotoaugusto.ticktick toggle"
)

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
-- the lid, and this is now the only thing on the machine that reacts to the
-- fold: the old udev rule matched a platform device (`intel-hid`) this kernel
-- no longer creates. `locked` so it still fires with the screen locked,
-- matching the lid binds. Spelled out because ~/.local/bin is not on the PATH
-- Hyprland hands a bind.
local tablet_mode = (os.getenv("HOME") or "") .. "/.local/bin/tablet-mode"
o.bind("switch:on:Intel HID switches", nil, tablet_mode .. " on", { locked = true })
o.bind("switch:off:Intel HID switches", nil, tablet_mode .. " off", { locked = true })

-- Caps Lock as a leader modifier. hypr/input.lua puts Hyper_L on Caps Lock,
-- which xkb maps to Mod3, so Hyprland sees it as MOD3. These mirror the
-- SUPER + SHIFT app launchers onto the same letters, one key instead of three.
-- Additive: the SUPER + SHIFT chords still work. The specs are duplicated
-- rather than derived because Omarchy's defaults are the source of truth for
-- them, and a helper here would silently drift when they change.
o.bind("MOD3 + RETURN", "Terminal", { omarchy = "terminal" })
o.bind("MOD3 + T", "Terminal", { omarchy = "terminal" })
o.bind("MOD3 + B", "Browser", { omarchy = "browser" })
o.bind("MOD3 + F", "File manager", { omarchy = "nautilus" })
o.bind("MOD3 + N", "Editor", { omarchy = "editor" })
o.bind("MOD3 + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind("MOD3 + SLASH", "Passwords", { omarchy = "1password" })

-- Web apps, matching the overrides above rather than Omarchy's defaults.
o.bind("MOD3 + A", "Claude", { webapp = "https://claude.ai" })
o.bind("MOD3 + C", "Calendar", { webapp = "https://calendar.google.com/" })
o.bind("MOD3 + E", "Email", { webapp = "https://app.shortwave.com" })

-- Dictation on SUPER + CTRL + SPACE, for the same muscle memory as the
-- <mod> + SPACE dictation and launcher chords on macOS. The background
-- switcher that held the chord is dropped -- it is still one row down in the
-- Omarchy menu -- and F9 push-to-talk is untouched.
hl.unbind("SUPER + CTRL + SPACE") -- was: Background switcher
hl.unbind("SUPER + CTRL + X") -- was: Toggle dictation
o.bind("SUPER + CTRL + SPACE", "Toggle dictation", "voxtype record toggle")

-- Windows-style ALT+TAB, from the `altswitch` plugin. The plugin owns the keys
-- as well as the panel -- its Lua half unbinds Omarchy's four cyclenext and
-- bring_to_top defaults itself -- so this is a load, not a binding. Spelled out
-- as a path for the same reason as the TickTick capture above: the switcher is
-- dead exactly when the plugin is not installed.
dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.pablo-merino.altswitch/altswitch.lua")
