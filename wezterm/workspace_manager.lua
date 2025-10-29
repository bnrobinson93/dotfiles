local wezterm = require("wezterm")

-- =============== Workspace Manager ===============
local workspace_manager = {}

-- State to track previous workspace (using a global table for persistence)
local state = {
	previous_workspace = nil,
	current_workspace = nil,
}

-- Update workspace tracking when workspace changes
workspace_manager.update_workspace_tracking = function(window, pane)
	local current = window:active_workspace()

	-- Only update if the workspace actually changed
	if current ~= state.current_workspace then
		state.previous_workspace = state.current_workspace
		state.current_workspace = current
	end
end

-- Switch to the previous workspace (Ctrl+A L functionality)
workspace_manager.switch_to_previous = function(window, pane)
	-- Always update tracking first to get the current state
	workspace_manager.update_workspace_tracking(window, pane)

	if state.previous_workspace and state.previous_workspace ~= state.current_workspace then
		-- Switch to the previous workspace
		window:perform_action(
			wezterm.action.SwitchToWorkspace({
				name = state.previous_workspace,
			}),
			pane
		)

		-- Swap the workspaces in our tracking
		local temp = state.current_workspace
		state.current_workspace = state.previous_workspace
		state.previous_workspace = temp
	else
		-- No previous workspace available or it's the same as current
		local message = state.previous_workspace and "Already in the previous workspace"
			or "No previous workspace available"
		window:toast_notification("WezTerm", message, nil, 2000)
	end
end

-- Initialize workspace tracking on first load
workspace_manager.initialize = function(window, pane)
	state.current_workspace = window:active_workspace()
	-- Don't set previous_workspace on initialization to avoid confusion
end

-- =============== Event Handlers ===============
-- Set up event handlers when the module is loaded
wezterm.on("window-focus-changed", function(window, pane)
	workspace_manager.update_workspace_tracking(window, pane)
end)

wezterm.on("window-config-reloaded", function(window, pane)
	workspace_manager.initialize(window, pane)
end)

return workspace_manager

