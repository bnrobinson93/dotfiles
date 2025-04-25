local wezterm = require 'wezterm'
local sessionizer = require 'sessionizer'
local tabbar = require 'tabbar'
local act = wezterm.action

wezterm.on('user-var-changed', function(window, pane, name, value)
  local overrides = window:get_config_overrides() or {}
  if name == 'ZEN_MODE' then
    local incremental = value:find '+'
    local number_value = tonumber(value)
    if incremental ~= nil then
      while number_value > 0 do
        window:perform_action(wezterm.action.IncreaseFontSize, pane)
        number_value = number_value - 1
      end
      overrides.enable_tab_bar = false
    elseif number_value < 0 then
      window:perform_action(wezterm.action.ResetFontSize, pane)
      overrides.font_size = nil
      overrides.enable_tab_bar = true
    else
      overrides.font_size = number_value
      overrides.enable_tab_bar = false
    end
  end
  window:set_config_overrides(overrides)
end)

return {
  enable_wayland = true,
  window_background_opacity = 0.90,
  macos_window_background_blur = 50,
  initial_cols = 120,
  initial_rows = 30,
  color_scheme = 'Catppuccin Mocha',
  allow_square_glyphs_to_overflow_width = 'Always',
  warn_about_missing_glyphs = false,
  font = wezterm.font_with_fallback { 'DankMono Nerd Font', 'Fira Code', 'JetBrains Mono' },
  font_size = 17,
  hide_tab_bar_if_only_one_tab = true,
  -- window_decorations = 'INTEGRATED_BUTTONS|RESIZE',
  window_decorations = 'TITLE|RESIZE',

  -- TMUX replacement
  -- Leader is the same as my old tmux prefix
  use_fancy_tab_bar = false,
  leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 2000 },
  keys = {
    { mods = 'LEADER', key = 'c', action = act.SpawnTab 'CurrentPaneDomain' },
    { mods = 'LEADER', key = 'x', action = act.CloseCurrentPane { confirm = true } },
    { mods = 'LEADER', key = 'b', action = act.ActivateTabRelative(-1) },
    { mods = 'LEADER', key = 'n', action = act.ActivateTabRelative(1) },
    { mods = 'LEADER', key = '|', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { mods = 'LEADER', key = '-', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { mods = 'LEADER', key = 'h', action = act.ActivatePaneDirection 'Left' },
    { mods = 'LEADER', key = 'j', action = act.ActivatePaneDirection 'Down' },
    { mods = 'LEADER', key = 'k', action = act.ActivatePaneDirection 'Up' },
    { mods = 'LEADER', key = 'l', action = act.ActivatePaneDirection 'Right' },
    { mods = 'LEADER', key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 5 } },
    { mods = 'LEADER', key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 5 } },
    { mods = 'LEADER', key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 5 } },
    { mods = 'LEADER', key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 5 } },
    { mods = 'LEADER', key = 'f', action = wezterm.action_callback(sessionizer.toggle) },
    { key = 'F11', action = wezterm.action.ToggleFullScreen },
  },
  -- search_mode = {
  -- 	{ key = "Escape", mods = "NONE", action = act({ CopyMode = "Close" }) },
  -- 	-- Go back to copy mode when pressing enter, so that we can use unmodified keys like "n"
  -- 	-- to navigate search results without conflicting with typing into the search area.
  -- 	{ key = "Enter", mods = "NONE", action = "ActivateCopyMode" },
  -- 	{ key = "c", mods = "CTRL", action = "ActivateCopyMode" },
  -- 	{ key = "n", mods = "CTRL", action = act({ CopyMode = "NextMatch" }) },
  -- 	{ key = "p", mods = "CTRL", action = act({ CopyMode = "PriorMatch" }) },
  -- 	{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
  -- 	{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
  -- },
}
