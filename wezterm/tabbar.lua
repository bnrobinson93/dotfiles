local wezterm = require("wezterm")

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
	if not pane then
		return "New Session"
	end

	local mux_window = tab.window
	if mux_window then
		local workspace_name = mux_window:active_workspace()
		if workspace_name then
			return workspace_name
		end
	end

	return "New Session"
end)

wezterm.on("update-right-status", function(window, _)
	local workspace = window:active_workspace()
	local pane = window:active_pane()
	local cwd_str = ""

	if pane then
		local cwd_uri = pane:get_current_working_dir()
		if cwd_uri then
			local cwd_path = cwd_uri.file_path or tostring(cwd_uri)
			local path = cwd_path:gsub(os.getenv("HOME"), "~"):gsub("/$", "")
			cwd_str = path:match("[^/]+$") or path
		end
	end

	local leader_active = window:leader_is_active()

	-- Left status: corner + icon highlighted, text normal
	local bg_color = leader_active and ACCENT_RED or ACCENT_GREEN

	-- Show workspace name, or fallback to "default" if none set
	local display_workspace = workspace or "default"
	if display_workspace == "default" then
		display_workspace = cwd_str ~= "" and cwd_str or "default"
	end

	window:set_left_status(wezterm.format({
		{ Background = { Color = TEXT_COLOR } },
		{ Foreground = { AnsiColor = bg_color } },
		{ Text = ROUND_LEFT },
		{ Background = { AnsiColor = bg_color } },
		{ Foreground = { Color = TEXT_COLOR } },
		{ Text = CMD_ICON .. " " },
		{ Foreground = { AnsiColor = bg_color } },
		{ Background = { Color = BG_COLOR } },
		{ Text = " " .. display_workspace },
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
