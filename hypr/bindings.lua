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
o.bind("CTRL + SHIFT + A", "Add TickTick task", "omarchy-shell io.github.sotoaugusto.ticktick toggle")

-- ASUS Zenbook function keys. The firmware emits a chord rather than a plain
-- keysym for each of these, so reaching the use printed on the key means taking
-- the chord back from whichever Omarchy default holds it.

-- F8 (display/present key), was: Pseudo window.
hl.unbind("SUPER + P")
o.bind("SUPER + P", "Toggle display mirroring", "omarchy-hyprland-monitor-internal-mirror toggle")

-- F9 (lock key), was: Toggle workspace layout. The firmware sends SUPER + L
-- rather than a lock keysym, so the unbind has to name that chord: unbinding a
-- bare F9 removes nothing, and the stock layout toggle then fires alongside the
-- lock, quietly flipping the workspace to scrolling on every lock.
hl.unbind("SUPER + L")
o.bind("SUPER + L", "Lock system", "omarchy-system-lock")

-- The workspace layout toggle, rehomed after the lock took its chord. It lands
-- on SUPER + CTRL + L, which Omarchy ships as a second lock binding and which is
-- therefore redundant here. SUPER + SHIFT is reserved for launching apps.
-- Worth keeping bound: dwindle and scrolling suit different work, and the toggle
-- is per workspace, so it is a normal thing to reach for rather than a setting
-- to leave alone.
hl.unbind("SUPER + CTRL + L")
o.bind("SUPER + CTRL + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

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
o.bind("MOD3 + SPACE", "Emoji picker", "omarchy-shell shell toggle omarchy.emojis")
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

-- Omarchycast takes SUPER + SPACE, the chord the Omarchy menu held: it answers
-- the same "what now?" reflex and does more with it, indexing the menu's own
-- entries alongside apps, arithmetic and dates. The menu keeps its place one
-- modifier out, on SUPER + ALT + SPACE, displacing the Apps menu -- a filtered
-- view of a list Omarchycast already ranks better. The bar button and the
-- menu-button widget still summon the menu by id, so both are unaffected.
--
-- Bound here rather than with `omarchycastd hotkey`, which writes
-- ~/.config/hypr/omarchycast.lua and then appends a dofile to hyprland.lua
-- through an atomic rename. That rename replaces a symlink with a real file,
-- and hyprland.lua is a symlink into this repo. Same command it would have
-- written, minus the detached config. For the same reason, do not set the
-- hotkey from the launcher's own settings pane.
hl.unbind("SUPER + SPACE") -- was: Omarchy menu
hl.unbind("SUPER + ALT + SPACE") -- was: Apps menu
o.bind("SUPER + SPACE", "Omarchycast", "omarchy-shell shell toggle io.github.aditya-raj-tiwari.omarchycast")
o.bind("SUPER + ALT + SPACE", "Omarchy menu", "omarchy-menu toggle")

-- Window sizing on the Caps row of digits. Fullscreen is a toggle and works
-- from any layout, so it is bound straight through. The two fractional sizes
-- only mean anything for a floating window -- asking a tiled window to be 50%
-- of the screen just moves a split -- so they float the window first, then size
-- and centre it. Coming back to the tiling layout is SUPER + T, as always.
--
-- The fullscreen state is cleared before resizing because Hyprland refuses a
-- resize on a fullscreen window, warning "Window is fullscreen" and otherwise
-- doing nothing.
-- Where each window sat before a sizing binding moved it, keyed by address, so
-- MOD3 + 1 can put it back. Cleared when the window closes, which is the only
-- thing keeping this from growing for the life of the session.
local geometry_before_sizing = {}

hl.on("window.close", function(window)
	if window and window.address then
		geometry_before_sizing[window.address] = nil
	end
end)

local function remember(window)
	geometry_before_sizing[window.address] = {
		floating = window.floating,
		x = window.at.x,
		y = window.at.y,
		width = window.size.x,
		height = window.size.y,
	}
end

local function size_window(fraction)
	return function()
		local monitor = hl.get_active_monitor()
		local window = hl.get_active_window()
		if not monitor or not window then
			return
		end
		remember(window)
		local scale = monitor.scale or 1
		hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
		hl.dispatch(hl.dsp.window.float({ action = "on" }))
		hl.dispatch(hl.dsp.window.resize({
			x = math.floor(monitor.width / scale * fraction),
			y = math.floor(monitor.height / scale * fraction),
			exact = true,
		}))
		hl.dispatch(hl.dsp.window.center())
	end
end

-- Undo for the two sizing bindings. A window that was tiled goes back to the
-- layout rather than to its old rectangle: the tiled geometry it had is a
-- product of its neighbours, and forcing those exact numbers back would leave a
-- floating window that merely looks tiled until anything else moves.
local function restore_window()
	local window = hl.get_active_window()
	if not window then
		return
	end
	local previous = geometry_before_sizing[window.address]
	if not previous then
		return
	end
	geometry_before_sizing[window.address] = nil
	hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
	if not previous.floating then
		hl.dispatch(hl.dsp.window.float({ action = "off" }))
		return
	end
	hl.dispatch(hl.dsp.window.resize({ x = previous.width, y = previous.height, exact = true }))
	hl.dispatch(hl.dsp.window.move({ x = previous.x, y = previous.y, exact = true }))
end

o.bind("MOD3 + 0", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("MOD3 + 1", "Restore window size", restore_window)
o.bind("MOD3 + 5", "Float window at half screen", size_window(0.5))
o.bind("MOD3 + 9", "Float window at 85% screen", size_window(0.85))
