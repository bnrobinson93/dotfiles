-- ~/.config/wezterm/wezterm.lua
local wezterm = require("wezterm")
local act = wezterm.action

-- =============== Sessionizer ===============
local sessionizer = {}

sessionizer.toggle = function(window, pane)
	local projects = {}

	local search_paths = {
		os.getenv("HOME"),
		os.getenv("HOME") .. "/Documents",
		os.getenv("HOME") .. "/Downloads",
		os.getenv("HOME") .. "/Documents/code",
		os.getenv("HOME") .. "/Documents/code/integrations-monorepo/integrations",
		os.getenv("HOME") .. "/Documents/code/js-lib-monorepo/libraries",
	}

	for _, search_path in ipairs(search_paths) do
		local success, stdout = wezterm.run_child_process({
			"find",
			search_path,
			"-maxdepth",
			"1",
			"-type",
			"d",
			"-not",
			"-name",
			".*",
			"-o",
			"-name",
			".dotfiles",
		})

		if success then
			for line in stdout:gmatch("[^\n]+") do
				if line ~= "" and line ~= search_path then
					local id = line:gsub(".*/", "")
					table.insert(projects, { label = line, id = id })
				end
			end
		end
	end

	window:perform_action(
		act.InputSelector({
			action = wezterm.action_callback(function(win, _, id, label)
				if not id and not label then
					wezterm.log_info("Cancelled")
				else
					wezterm.log_info("Selected " .. label)
					win:perform_action(act.SwitchToWorkspace({ name = id, spawn = { cwd = label } }), pane)
				end
			end),
			fuzzy = true,
			title = "Select project",
			choices = projects,
		}),
		pane
	)
end

-- =============== Theme Variables ===============
local TEXT_COLOR = "#262626"
local BG_COLOR = "#1e1e2e"
local PILL_BG_COLOR = "#313244"
local ACTIVE_PILL_BG_COLOR = "#45475a"
local ACCENT_GREEN = "Green"
local ACCENT_YELLOW = "Yellow"
local ACCENT_RED = "Red"
local ACCENT_BLUE = "Blue"
local ACCENT_GREY = "Grey"
local ACCENT_FUCHSIA = "Fuchsia"
local ACCENT_SILVER = "Silver"
local ACCENT_WHITE = "White"

-- =============== Icons ===============
local ROUND_LEFT = utf8.char(0xe0b6)
local ROUND_RIGHT = utf8.char(0xe0b4)
local CMD_ICON = utf8.char(0xe795)
local DIR_ICON = utf8.char(0xe5ff)
local CAL_ICON = utf8.char(0xf00f0)
local BAT_0_ICON = utf8.char(0xf0083)
local BAT_10_ICON = utf8.char(0xf007a)
local BAT_20_ICON = utf8.char(0xf007b)
local BAT_30_ICON = utf8.char(0xf007c)
local BAT_40_ICON = utf8.char(0xf007d)
local BAT_50_ICON = utf8.char(0xf007e)
local BAT_60_ICON = utf8.char(0xf007f)
local BAT_70_ICON = utf8.char(0xf0080)
local BAT_80_ICON = utf8.char(0xf0081)
local BAT_90_ICON = utf8.char(0xf0082)
local BAT_100_ICON = utf8.char(0xf0079)
local BAT_CHARGING_ICON = utf8.char(0xf0084)

-- =============== Status Bar ===============
-- Update window title to show workspace name only
wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	local workspace = pane:get_current_working_dir()
	if workspace then
		workspace = workspace.file_path:match("([^/]+)$") or workspace.file_path
	end

	local mux_window = tab.window
	if mux_window then
		local workspace_name = mux_window:active_workspace()
		if workspace_name then
			return workspace_name
		end
	end

	return "WezTerm"
end)

wezterm.on("update-right-status", function(window, _)
	local workspace = window:active_workspace()
	local pane = window:active_pane()
	local cwd = pane:get_current_working_dir()
	local cwd_str = ""
	if cwd then
		cwd_str = cwd.file_path:gsub(os.getenv("HOME"), "~")
	end

	local leader_active = window:leader_is_active()

	-- Left status: corner + icon highlighted, text normal
	local bg_color = leader_active and ACCENT_RED or ACCENT_GREEN

	window:set_left_status(wezterm.format({
		{ Background = { Color = TEXT_COLOR } },
		{ Foreground = { AnsiColor = bg_color } },
		{ Text = ROUND_LEFT },
		{ Background = { AnsiColor = bg_color } },
		{ Foreground = { Color = TEXT_COLOR } },
		{ Text = CMD_ICON .. " " },
		{ Foreground = { AnsiColor = bg_color } },
		{ Background = { Color = BG_COLOR } },
		{ Text = " " .. workspace },
	}))

	-- Right status: corner + icon highlighted for each section, text normal
	local time = os.date("%m/%d %H:%M")
	local battery_widget = {}

	for _, b in ipairs(wezterm.battery_info()) do
		local bat_icon = BAT_0_ICON
		local value = b.state_of_charge * 100
		if b.state == "Charging" then
			bat_icon = BAT_CHARGING_ICON
		elseif value < 10 then
			bat_icon = BAT_0_ICON
		elseif value < 20 then
			bat_icon = BAT_10_ICON
		elseif value < 30 then
			bat_icon = BAT_20_ICON
		elseif value < 40 then
			bat_icon = BAT_30_ICON
		elseif value < 50 then
			bat_icon = BAT_40_ICON
		elseif value < 60 then
			bat_icon = BAT_50_ICON
		elseif value < 70 then
			bat_icon = BAT_60_ICON
		elseif value < 80 then
			bat_icon = BAT_70_ICON
		elseif value < 90 then
			bat_icon = BAT_80_ICON
		elseif value < 100 then
			bat_icon = BAT_90_ICON
		else
			bat_icon = BAT_100_ICON
		end
		if b.state == "Discharging" then
			battery_widget = {
				{ Background = { Color = TEXT_COLOR } },
				{ Foreground = { AnsiColor = ACCENT_RED } },
				{ Text = ROUND_LEFT },
				{ Background = { AnsiColor = ACCENT_RED } },
				{ Foreground = { Color = TEXT_COLOR } },
				{ Text = bat_icon .. " " },
				{ Foreground = { AnsiColor = ACCENT_RED } },
				{ Background = { Color = BG_COLOR } },
				{ Text = " " .. string.format("%.0f%%", value) },
			}
		end
	end
	window:set_right_status(wezterm.format({
		{ Background = { Color = TEXT_COLOR } },
		{ Foreground = { AnsiColor = ACCENT_YELLOW } },
		{ Text = ROUND_LEFT },
		{ Background = { AnsiColor = ACCENT_YELLOW } },
		{ Foreground = { Color = TEXT_COLOR } },
		{ Text = DIR_ICON .. " " },
		{ Foreground = { AnsiColor = ACCENT_YELLOW } },
		{ Background = { Color = BG_COLOR } },
		{ Text = " " .. cwd_str .. " " },
		{ Background = { Color = TEXT_COLOR } },
		{ Foreground = { AnsiColor = ACCENT_BLUE } },
		{ Text = ROUND_LEFT },
		{ Background = { AnsiColor = ACCENT_BLUE } },
		{ Foreground = { Color = TEXT_COLOR } },
		{ Text = CAL_ICON .. " " },
		{ Foreground = { AnsiColor = ACCENT_BLUE } },
		{ Background = { Color = BG_COLOR } },
		{ Text = " " .. time .. " " },
		table.unpack(battery_widget),
	}))
end)

-- =============== Tab Bar ===============
local function tab_title(tab_info)
	local title = tab_info.tab_title
	if title and #title > 0 then
		return title
	end
	return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs)
	local title = tab_title(tab)
	local id = tab.tab_id
	local FORMATTED_ROUND_LEFT = ROUND_LEFT
	if id == tabs[1].tab_id then
		FORMATTED_ROUND_LEFT = " " .. ROUND_LEFT
	end

	if tab.is_active then
		return {
			"ResetAttributes",
			{ Foreground = { Color = ACTIVE_PILL_BG_COLOR } },
			{ Background = { Color = BG_COLOR } },
			{ Text = FORMATTED_ROUND_LEFT },
			{ Background = { Color = ACTIVE_PILL_BG_COLOR } },
			{ Foreground = { AnsiColor = ACCENT_SILVER } },
			{ Text = title .. " " },
			{ Foreground = { Color = TEXT_COLOR } },
			{ Background = { AnsiColor = ACCENT_FUCHSIA } },
			{ Text = " " .. id },
			{ Background = { Color = BG_COLOR } },
			{ Foreground = { AnsiColor = ACCENT_FUCHSIA } },
			{ Text = ROUND_RIGHT .. " " },
		}
	end
	return {
		"ResetAttributes",
		{ Foreground = { Color = PILL_BG_COLOR } },
		{ Background = { Color = BG_COLOR } },
		{ Text = FORMATTED_ROUND_LEFT },
		{ Background = { Color = PILL_BG_COLOR } },
		{ Foreground = { AnsiColor = ACCENT_SILVER } },
		{ Text = title .. " " },
		{ Foreground = { Color = TEXT_COLOR } },
		{ Background = { AnsiColor = ACCENT_SILVER } },
		{ Text = " " .. id },
		{ Background = { Color = BG_COLOR } },
		{ Foreground = { AnsiColor = ACCENT_SILVER } },
		{ Text = ROUND_RIGHT .. " " },
	}
end)

-- =============== Config ===============
return {
	-- Display
	enable_wayland = true,
	window_background_opacity = 0.99,
	macos_window_background_blur = 50,
	initial_cols = 200,
	initial_rows = 50,
	color_scheme = "Catppuccin Mocha",
	allow_square_glyphs_to_overflow_width = "Always",
	warn_about_missing_glyphs = false,

	-- Font
	font = wezterm.font_with_fallback({ "DankMono Nerd Font Propo", "Fira Code", "JetBrains Mono" }),
	font_size = 18,

	-- Tab bar
	hide_tab_bar_if_only_one_tab = false,
	colors = { tab_bar = { background = BG_COLOR } },
	use_fancy_tab_bar = false,
	window_decorations = "TITLE|RESIZE",

	-- =============== Keybindings (tmux-style) ===============
	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 },
	keys = {
		-- New tab/window (like tmux 'c')
		{ mods = "LEADER", key = "c", action = act.SpawnTab("CurrentPaneDomain") },

		-- Close pane (like tmux 'x')
		{ mods = "LEADER", key = "x", action = act.CloseCurrentPane({ confirm = true }) },

		-- Show all active workspaces (like tmux 's')
		{ mods = "LEADER", key = "s", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },

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
		{ mods = "LEADER", key = "RightArrow", action = act.AdjustPaneSize({ "Right", 5 }) },
		{ mods = "LEADER", key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ mods = "LEADER", key = "DownArrow", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ mods = "LEADER", key = "UpArrow", action = act.AdjustPaneSize({ "Up", 5 }) },

		-- Misc
		{ key = "F11", action = act.ToggleFullScreen },
	},
}
