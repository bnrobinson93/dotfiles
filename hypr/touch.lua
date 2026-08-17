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

	-- Swipe up from the bottom edge to toggle the on-screen keyboard. wvkbd
	-- listens for SIGUSR2; autostart.lua starts it hidden.
	hg.bind({
		pattern = { kind = "edge", origin = "down", direction = "up" },
		action = hl.dsp.exec_cmd("pkill -34 -x wvkbd-mobintl"),
	})
end
