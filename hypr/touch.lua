-- Touchscreen gestures, via the hyprgrass plugin. Hyprland's own hl.gesture is
-- trackpad-only, and Omarchy configures nothing touchscreen at all, so this is
-- the only route to edge gestures. autostart.lua runs `hyprpm reload -n`.
--
-- The guard is load-bearing, not defensive noise: hl.plugin.hyprgrass does not
-- exist during the cold-start parse, because the per-plugin namespace table is
-- created only when the plugin loads, and that happens from autostart -- after
-- the config has been read. Loading a plugin schedules a full config reload, so
-- the second parse sees the namespace and registers everything below. A bare
-- call would instead throw "attempt to index a nil value" on every cold start.
local hg = hl.plugin.hyprgrass

if hg then
	-- Long-press with two fingers to drag a window, three to resize it. These
	-- were `hyprgrass-bindm` under v3; there is no bindm any more, `mouse = true`
	-- replaced it, and it only works with longpress -- which is what both were.
	hg.bind({
		pattern = { kind = "longpress", fingers = 2 },
		action = hl.dsp.window.drag(),
		mouse = true,
	})

	hg.bind({
		pattern = { kind = "longpress", fingers = 3 },
		action = hl.dsp.window.resize(),
		mouse = true,
	})

	-- Swipe down from the top edge for the scratchpad, where the TickTick and
	-- Messages web apps live (see hyprland.lua).
	hg.gesture({
		pattern = { kind = "edge", origin = "up", direction = "down" },
		action = "special",
		workspace_name = "scratchpad",
	})

	-- Swipe down with four fingers to close the focused window. Hyprland has no
	-- server-side decorations -- no titlebar, no close button, and hyprbars is
	-- the only plugin that adds one -- so this is the finger-reachable twin of
	-- SUPER + W. Four fingers because two and three are taken above, and because
	-- a whole-hand swipe is hard to fire by accident on something destructive.
	hg.bind({
		pattern = { kind = "swipe", fingers = 4, direction = "down" },
		action = hl.dsp.window.close(),
	})

	-- Swipe sideways with four fingers to carry the focused window to the next
	-- or previous workspace, following it there. The window travels the way the
	-- fingers push it. No hold first: hyprgrass fires a gesture once on
	-- recognition, so there is no dragging a held window onto a workspace and no
	-- repeat while a swipe is held. Four fingers on the glass does not fight
	-- input.lua's four-finger workspace swipe -- Hyprland's own hl.gesture is
	-- trackpad-only.
	--
	-- "+1"/"-1", not "e+1"/"e-1": the e-prefix walks only workspaces that already
	-- exist and wraps around at the end of them, so an empty workspace was
	-- unreachable. Plain relative selectors reach empty ones and clamp at 1.
	hg.bind({
		pattern = { kind = "swipe", fingers = 4, direction = "right" },
		action = hl.dsp.window.move({ workspace = "+1" }),
	})

	hg.bind({
		pattern = { kind = "swipe", fingers = 4, direction = "left" },
		action = hl.dsp.window.move({ workspace = "-1" }),
	})

	-- Swipe up with four fingers to toggle full screen on the focused window --
	-- the same dispatcher as SUPER + F, so a second swipe up puts it back. Pairs
	-- with the four-finger swipe down that closes it. This is a free-form swipe,
	-- not an edge one, so it does not collide with the bottom-edge swipe below.
	hg.bind({
		pattern = { kind = "swipe", fingers = 4, direction = "up" },
		action = hl.dsp.window.fullscreen({ mode = "fullscreen" }),
	})

	-- Swipe up from the bottom edge to toggle the on-screen keyboard. wvkbd
	-- listens for SIGUSR2; autostart.lua starts it hidden.
	hg.bind({
		pattern = { kind = "edge", origin = "down", direction = "up" },
		action = hl.dsp.exec_cmd("pkill -34 -x wvkbd-mobintl"),
	})
end
