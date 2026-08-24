-- Window chrome for tablet mode: a border a finger can actually land on.
--
-- Not loaded by hyprland.lua. `tablet-mode on` copies this file into
-- ~/.local/state/omarchy/toggles/hypr/, which Hyprland sources on every reload,
-- and `tablet-mode off` deletes it again. That is Omarchy's own mechanism for
-- config that has to survive a reload (see default/hypr/toggles/), and it is
-- why this is not a `hyprctl eval` -- the next reload would wipe that silently.
hl.config({
	general = {
		-- Upstream is 2, sized for a mouse.
		border_size = 6,

		-- Upstream is 10. A wider outer gap keeps the border of a window at the
		-- screen edge reachable instead of flush against it.
		gaps_out = 16,
	},
})
