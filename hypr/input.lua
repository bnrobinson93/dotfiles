-- Personal input overrides. Omarchy's defaults already set kb_layout,
-- kb_options, repeat_rate, numlock, clickfinger_behavior, and a 0.4 touchpad
-- scroll factor, so only the genuine differences are listed here.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
	input = {
		-- Wait longer before a held key starts repeating.
		repeat_delay = 600,

		touchpad = {
			-- Use natural (inverse) scrolling.
			natural_scroll = true,
		},
	},
})

-- Change workspaces by swiping with four fingers rather than Omarchy's three.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
