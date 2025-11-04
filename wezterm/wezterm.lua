local wezterm = require("wezterm")
local act = wezterm.action

require("tabbar")
local sessionizer = require("sessionizer")
local workspace_manager = require("workspace_manager")

local BG_COLOR = "#1e1e2e"

-- =============== Config ===============
local config = {
	-- Display
	enable_wayland = true,
	window_background_opacity = 0.99,
	macos_window_background_blur = 50,
	initial_cols = 120,
	initial_rows = 50,
	color_scheme = "Catppuccin Mocha",
	allow_square_glyphs_to_overflow_width = "Always",
	warn_about_missing_glyphs = false,

	default_cursor_style = "BlinkingBar",
	mouse_bindings = {
		{
			event = { Down = { streak = 3, button = "Left" } },
			action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
			mods = "NONE",
		},
	},
	window_content_alignment = {
		horizontal = "Center",
		vertical = "Center",
	},
	window_padding = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	},

	-- Font
	font = wezterm.font_with_fallback({ "Dank Mono Nerd Font Propo", "Fira Code", "JetBrains Mono" }),
	font_size = 18,

	-- Tab bar
	hide_tab_bar_if_only_one_tab = false,
	colors = { tab_bar = { background = BG_COLOR } },
	use_fancy_tab_bar = false,
	window_decorations = "TITLE|RESIZE",

	-- =============== Keybindings (tmux-style) ===============
	leader = { mods = "CTRL", key = "a", timeout_milliseconds = 1000 },
	keys = {
		-- New tab/window (like tmux 'c')
		{ mods = "LEADER", key = "c", action = act.SpawnTab("CurrentPaneDomain") },

		-- Close pane (like tmux 'x')
		{ mods = "LEADER", key = "x", action = act.CloseCurrentPane({ confirm = true }) },

		-- Show all active workspaces (like tmux 's')
		{ mods = "LEADER", key = "s", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },

		-- Switch to previous workspace (like tmux last-window)
		{ mods = "LEADER|SHIFT", key = "L", action = wezterm.action_callback(workspace_manager.switch_to_previous) },

		-- Sessionizer/project picker (like tmux sessionizer)
		{ mods = "LEADER", key = "f", action = wezterm.action_callback(sessionizer.toggle) },
		{ mods = "CTRL", key = "f", action = wezterm.action_callback(sessionizer.toggle) },

		-- Tab navigation (like tmux 'n' and 'b' for next/prev)
		{ mods = "LEADER", key = "n", action = act.ActivateTabRelative(1) },
		{ mods = "LEADER", key = "b", action = act.ActivateTabRelative(-1) },

		-- Quick tab numbers (like tmux 1-9)
		{ mods = "LEADER", key = "1", action = act.ActivateTab(0) },
		{ mods = "LEADER", key = "2", action = act.ActivateTab(1) },
		{ mods = "LEADER", key = "3", action = act.ActivateTab(2) },
		{ mods = "LEADER", key = "4", action = act.ActivateTab(3) },
		{ mods = "LEADER", key = "5", action = act.ActivateTab(4) },
		{ mods = "LEADER", key = "6", action = act.ActivateTab(5) },
		{ mods = "LEADER", key = "7", action = act.ActivateTab(6) },
		{ mods = "LEADER", key = "8", action = act.ActivateTab(7) },
		{ mods = "LEADER", key = "9", action = act.ActivateTab(8) },

		-- Quick places
		{
			mods = "LEADER|SHIFT",
			key = "C",
			action = act.SwitchToWorkspace({
				name = "Code",
				spawn = { cwd = os.getenv("HOME") .. "/Documents/code" },
			}),
		},
		{
			mods = "LEADER|SHIFT",
			key = "V",
			action = act.SwitchToWorkspace({
				name = "Vault",
				spawn = { cwd = os.getenv("HOME") .. "/Documents/Vault" },
			}),
		},

		-- Splits (like tmux)
		{ mods = "LEADER|SHIFT", key = "|", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ mods = "LEADER", key = "-", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

		-- Pane navigation (vim-like, like tmux)
		{ mods = "ALT", key = "h", action = act.ActivatePaneDirection("Left") },
		{ mods = "ALT", key = "j", action = act.ActivatePaneDirection("Down") },
		{ mods = "ALT", key = "k", action = act.ActivatePaneDirection("Up") },
		{ mods = "ALT", key = "l", action = act.ActivatePaneDirection("Right") },
		{ mods = "LEADER", key = "h", action = act.ActivatePaneDirection("Left") },
		{ mods = "LEADER", key = "j", action = act.ActivatePaneDirection("Down") },
		{ mods = "LEADER", key = "k", action = act.ActivatePaneDirection("Up") },
		{ mods = "LEADER", key = "l", action = act.ActivatePaneDirection("Right") },

		-- Pane resizing
		{ mods = "LEADER|ALT", key = "RightArrow", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ mods = "LEADER|ALT", key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ mods = "LEADER|ALT", key = "DownArrow", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ mods = "LEADER|ALT", key = "UpArrow", action = act.AdjustPaneSize({ "Up", 5 }) },

		-- Misc
		{ key = "F11", action = act.ToggleFullScreen },
		-- Jump to previous prompt (scroll backward through command history)
		{
			key = "UpArrow",
			mods = "SHIFT",
			action = wezterm.action.ScrollToPrompt(-1),
		},

		-- Jump to next prompt (scroll forward through command history)
		{
			key = "DownArrow",
			mods = "SHIFT",
			action = wezterm.action.ScrollToPrompt(1),
		},
	},
}

return config
