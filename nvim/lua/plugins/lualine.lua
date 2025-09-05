return {
  "nvim-lualine/lualine.nvim",
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  opts = function()
    local cache = {
      cwd = nil,
      is_jj = nil,
      branch_info = nil,
      last_check = 0,
    }

    -- Cache duration in seconds
    local CACHE_DURATION = 2

    local function is_jujutsu_repo()
      -- Check if .jj directory exists in current working directory or parents
      local current_dir = vim.fn.getcwd()

      -- If we've cached this recently for the same directory, use cache
      local now = os.time()
      if cache.cwd == current_dir and cache.last_check and (now - cache.last_check) < CACHE_DURATION then
        return cache.is_jj
      end

      -- Check for .jj directory walking up the tree
      local dir = current_dir
      while dir and dir ~= "/" do
        if vim.fn.isdirectory(dir .. "/.jj") == 1 then
          cache.cwd = current_dir
          cache.is_jj = true
          cache.last_check = now
          return true
        end
        dir = vim.fn.fnamemodify(dir, ":h")
      end

      cache.cwd = current_dir
      cache.is_jj = false
      cache.last_check = now
      return false
    end

    local function get_jj_bookmark()
      -- Get the current jj bookmark using jj log command
      local handle = io.popen("jj log -r @ --no-graph -T bookmarks 2>/dev/null")
      if not handle then
        return nil
      end

      local result = handle:read("*a")
      handle:close()

      if result and result ~= "" then
        -- Clean up the result and get the first bookmark if multiple exist
        local bookmark = result:gsub("%s+", " "):gsub("^%s*", ""):gsub("%s*$", "")
        if bookmark ~= "" and bookmark ~= "(empty)" then
          -- If there are multiple bookmarks, take the first one
          local first_bookmark = bookmark:match("^([^%s]+)")
          return first_bookmark or bookmark
        end
      end

      -- If no bookmark, show the description
      handle = io.popen("jj log -r @ -T 'description' --no-graph 2>/dev/null")
      if not handle then
        return "jj"
      end

      result = handle:read("*a")
      handle:close()

      if result and result ~= "" then
        local change_id = result:gsub("%s+", " "):gsub("^%s*", ""):gsub("%s*$", "")
        return change_id ~= "" and change_id or "jj"
      end

      return "jj"
    end

    local function get_git_branch()
      -- Use git symbolic-ref for current branch, fallback to describe for detached HEAD
      local handle = io.popen(
        "git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null"
      )
      if not handle then
        return nil
      end

      local result = handle:read("*a")
      handle:close()

      if result and result ~= "" then
        return result:gsub("%s+", ""):gsub("^%s*", ""):gsub("%s*$", "")
      end

      return nil
    end

    local function branch_component()
      local current_dir = vim.fn.getcwd()
      local now = os.time()

      -- Use cached branch info if recent
      if
        cache.cwd == current_dir
        and cache.branch_info
        and cache.last_check
        and (now - cache.last_check) < CACHE_DURATION
      then
        return cache.branch_info
      end

      local branch_info = ""

      if is_jujutsu_repo() then
        local bookmark = get_jj_bookmark()
        if bookmark then
          branch_info = bookmark
        else
          branch_info = "jj"
        end
      else
        local git_branch = get_git_branch()
        if git_branch then
          branch_info = git_branch
        end
      end

      -- Cache the result
      cache.cwd = current_dir
      cache.branch_info = branch_info
      cache.last_check = now

      return branch_info
    end

    -- Clear cache when changing directories
    vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, {
      callback = function()
        cache.cwd = nil
        cache.is_jj = nil
        cache.branch_info = nil
        cache.last_check = 0
      end,
    })

    return {
      options = {
        section_separators = { left = "", right = "" },
        component_separators = "|",
      },
      extensions = { "nvim-dap-ui", "quickfix", "trouble" },
      sections = {
        lualine_b = {
          {
            branch_component,
            icon = "",
            separator = "|",
          },
          LazyVim.lualine.root_dir(),
          "filename",
          { "diagnostics", sources = { "nvim_diagnostic", "nvim_workspace_diagnostic" }, update_in_insert = false },
          "nvim-dap-ui",
          "quickfix",
        },
        lualine_c = {
          {
            "filetype",
            separator = "",
            color = { fg = "#585b70" },
            padding = { left = 2, right = 0 },
            colored = false,
            icon_only = true,
          },
          {
            "lsp_status",
            separator = "",
            color = function()
              return { fg = Snacks.util.color("NonText") }
            end,
            padding = { left = 0, right = 1 },
            icon = "",
            symbols = {
              spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
              done = "",
              separator = ", ",
            },
            ignore_lsp = { "GitHub Copilot", "copilot" },
          },
        },
        lualine_z = {},
      },
    }
  end,
}
