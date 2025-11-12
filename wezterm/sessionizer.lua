local wezterm = require("wezterm")
local act = wezterm.action

-- =============== Sessionizer ===============
local sessionizer = {}

-- Find fd command in common locations
local function find_fd_command()
	local possible_paths = {
		"fd",  -- Try PATH first
		"/home/linuxbrew/.linuxbrew/bin/fd",  -- Linux Homebrew
		"/opt/homebrew/bin/fd",  -- macOS Apple Silicon
		"/usr/local/bin/fd",  -- macOS Intel / other Linux
	}

	for _, cmd in ipairs(possible_paths) do
		local ok, success = pcall(wezterm.run_child_process, { cmd, "--version" })
		if ok and success then
			return cmd
		end
	end

	return nil  -- fd not found
end

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

	-- Add ~/.dotfiles as a direct option (not its children)
	local dotfiles_path = os.getenv("HOME") .. "/.dotfiles"
	table.insert(projects, { label = dotfiles_path, id = "dotfiles" })

	-- Find fd command once
	local fd_cmd = find_fd_command()

	-- Search for child directories in all paths
	for _, search_path in ipairs(search_paths) do
		local success, stdout, stderr

		-- Try fd first if available
		if fd_cmd then
			success, stdout, stderr = wezterm.run_child_process({
				fd_cmd,
				"-t",
				"d",
				"",
				search_path,
				"-Hi",
				"--prune",
			})
		end

		-- fall back to find
		if not success then
			success, stdout = wezterm.run_child_process({
				"find",
				search_path,
				"-maxdepth",
				"1",
				"-type",
				"d",
			})
		end

		if success then
			for line in stdout:gmatch("[^\n]+") do
				if line ~= "" and line ~= search_path and line ~= dotfiles_path then
					-- Extract directory name from path
					local id = line:match("([^/]+)/?$")
					if not id or id == "" then
						id = "unnamed"  -- fallback
					end
					table.insert(projects, { label = line, id = id })
				end
			end
		end
	end

	window:perform_action(
		act.InputSelector({
			action = wezterm.action_callback(function(win, _, id, label)
				if not id and not label then
					-- Selection cancelled
				else
					win:perform_action(act.SwitchToWorkspace({ 
						name = id, 
						spawn = { 
							cwd = label
						} 
					}), pane)
				end
			end),
			fuzzy = true,
			title = "Select project",
			choices = projects,
		}),
		pane
	)
end

return sessionizer
