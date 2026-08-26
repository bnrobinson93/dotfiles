-- Personal input overrides. Omarchy's defaults already set kb_layout,
-- repeat_rate, numlock, clickfinger_behavior, and a 0.4 touchpad scroll
-- factor, so only the genuine differences are listed here. kb_options is
-- replaced outright rather than extended -- Hyprland takes the last value, and
-- the point is to drop Compose off Caps Lock.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
	input = {
		-- Caps Lock is a leader modifier, not Compose. Omarchy's default puts
		-- Compose on Caps Lock, which swallows the following keystrokes until the
		-- sequence resolves or times out -- indistinguishable from a stuck key.
		-- caps:hyper emits Hyper_L, which xkb maps to Mod3, so it collides with
		-- nothing (Super is Mod4) and Hyprland can bind it as MOD3. Compose moves
		-- to Right Alt, which this layout otherwise wastes. Both Shifts together
		-- still toggles a real Caps Lock, and a lone Shift cancels a misfire.
		kb_options = "caps:hyper,compose:ralt,shift:both_capslock_cancel",

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

-- Change workspaces by swiping in from the left or right edge of the
-- touchscreen. This is the one touchscreen gesture Hyprland owns itself, so it
-- replaces the two v3 hyprgrass workspace binds and keeps working if the plugin
-- is ever dropped. hypr/touch.lua owns the four gestures it cannot express;
-- adding hyprgrass edge binds here as well would fight this one.
hl.config({ gestures = { workspace_swipe_touch = true } })
