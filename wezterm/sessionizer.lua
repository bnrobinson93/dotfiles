-- ~.config/wezterm/sessionizer.lua
local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

local fd = '/usr/local/bin/fd'

M.toggle = function(window, pane)
  local projects = {}

  local success, stdout, stderr = wezterm.run_child_process {
    fd,
    '-HI',
    '--max-depth=1',
    '--prune',
    os.getenv 'HOME',
    os.getenv 'HOME' .. '/Downloads',
    os.getenv 'HOME' .. '/Documents',
  }

  if not success then
    wezterm.log_error('Failed to run fd: ' .. stderr)
    return
  end

  for line in stdout:gmatch '([^\n]*)\n?' do
    local project = line:gsub('/.git.*$', '')
    local label = project
    local id = project:gsub('.*/', '')
    table.insert(projects, { label = tostring(label), id = tostring(id) })
  end

  window:perform_action(
    act.InputSelector {
      action = wezterm.action_callback(function(win, _, id, label)
        if not id and not label then
          wezterm.log_info 'Cancelled'
        else
          wezterm.log_info('Selected ' .. label)
          win:perform_action(act.SwitchToWorkspace { name = id, spawn = { cwd = label } }, pane)
        end
      end),
      fuzzy = true,
      title = 'Select project',
      choices = projects,
    },
    pane
  )
end

return M
