local CACHE_DURATION = 5 -- Increased from 2 seconds

local cache = {
  cwd = nil,
  is_jj = nil,
  branch_info = nil,
  last_check = 0,
  job_generation = 0,
}

-- Debounce timer to prevent rapid updates
local update_timer = nil
local UPDATE_DELAY = 500 -- milliseconds

local uv = vim.uv or vim.loop

local function is_jujutsu_repo()
  local current_dir = vim.fn.getcwd()
  local now = uv.now() / 1000

  -- Use cache if valid
  if cache.cwd == current_dir and cache.last_check and (now - cache.last_check) < CACHE_DURATION then
    return cache.is_jj
  end

  -- Use vim.fn.finddir for better performance
  local jj_dir = vim.fn.finddir(".jj", current_dir .. ";")

  cache.cwd = current_dir
  cache.is_jj = (jj_dir ~= "")
  cache.last_check = now

  return cache.is_jj
end

-- JJ change label from jj-signs' buffer var — no subprocess. Prefer the bookmark,
-- then the change description (truncated), then the short change_id. The dict is
-- buffer-local and only set on attached file buffers, so cache the last non-empty
-- label to keep showing it in unattached buffers (file explorer, dashboard).
local last_jj_label = ""
local function nonempty(s)
  return s ~= nil and s ~= "" and s or nil
end
local function jj_label()
  local d = vim.b.jjsigns_status_dict
  if not d then
    return last_jj_label
  end

  -- nil-safe: an older jj-signs (or a dict written before these fields existed)
  -- has no bookmark/description keys, so guard for nil, not just "".
  local label = nonempty(d.bookmark) or nonempty(d.description) or nonempty(d.head)
  if not label then
    return last_jj_label
  end

  if #label > 20 then
    label = label:sub(1, 17) .. "..."
  end
  last_jj_label = label
  return label
end

-- Async function to get Git branch
local function get_git_branch_async(callback)
  -- Try fugitive first (synchronous but fast)
  if vim.fn.exists("*FugitiveHead") == 1 then
    local branch = vim.fn.FugitiveHead()
    if branch and branch ~= "" then
      callback(branch)
      return
    end
  end

  -- If we have a pending job, don't start another one
  if cache.pending_job then
    callback(cache.branch_info or "")
    return
  end

  local output = {}
  local function on_stdout(_, data)
    if data then
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(output, line)
        end
      end
    end
  end

  cache.pending_job = vim.fn.jobstart("git symbolic-ref --short HEAD 2>/dev/null", {
    stdout_buffered = true,
    on_stdout = on_stdout,
    on_exit = function(_, exit_code)
      cache.pending_job = nil
      if exit_code == 0 then
        local result = table.concat(output, "\n")
        if result and result ~= "" then
          callback(result:gsub("%s+", ""):gsub("^%s*", ""):gsub("%s*$", ""))
          return
        end
      end

      -- Try for detached HEAD
      output = {}
      vim.fn.jobstart("git rev-parse --short HEAD 2>/dev/null", {
        stdout_buffered = true,
        on_stdout = on_stdout,
        on_exit = function(_, code)
          if code == 0 then
            local rev = table.concat(output, "\n")
            if rev and rev ~= "" then
              callback(rev:gsub("%s+", ""):gsub("^%s*", ""):gsub("%s*$", ""))
              return
            end
          end
          callback("")
        end,
      })
    end,
  })
end

-- Update branch info asynchronously
local function update_branch_async()
  local current_dir = vim.fn.getcwd()
  cache.job_generation = cache.job_generation + 1
  local this_generation = cache.job_generation

  -- jj label is read synchronously from the buffer var in branch_component; no job.
  if is_jujutsu_repo() then
    return
  end

  get_git_branch_async(function(branch)
    if this_generation ~= cache.job_generation then
      return
    end
    cache.branch_info = branch or ""
    cache.cwd = current_dir
    cache.last_check = uv.now() / 1000
    vim.cmd("redrawstatus!")
  end)
end

local function cleanup_update_timer()
  if update_timer ~= nil then
    if update_timer.stop then
      pcall(function()
        update_timer:stop()
      end)
    end
    if update_timer.close then
      pcall(function()
        update_timer:close()
      end)
    end
    update_timer = nil
  end
end

local function debounce_update()
  cleanup_update_timer()
  update_timer = uv.new_timer()
  if update_timer == nil then
    update_branch_async()
    return
  end
  update_timer:start(
    UPDATE_DELAY,
    0,
    vim.schedule_wrap(function()
      update_branch_async()
      cleanup_update_timer()
    end)
  )
end

-- Main component function
local function branch_component()
  -- jj repos: read jj-signs' buffer var synchronously (no job, no cache).
  if is_jujutsu_repo() then
    return jj_label()
  end

  local current_dir = vim.fn.getcwd()
  local now = uv.now() / 1000

  -- Check if we need to update
  if
    not cache.branch_info
    or cache.cwd ~= current_dir
    or not cache.last_check
    or (now - cache.last_check) >= CACHE_DURATION
  then
    -- Start async update if not already pending
    if not cache.pending_job then
      debounce_update()
    end

    -- Return cached value or placeholder
    return cache.branch_info or (is_jujutsu_repo() and "jj" or "")
  end

  return cache.branch_info or ""
end

local function expire_cache()
  cache.cwd = nil
  cache.is_jj = nil
  cache.branch_info = nil
  cache.last_check = 0
end

-- Clear cache when changing directories
vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, {
  callback = function()
    -- Cancel any pending job
    if cache.pending_job then
      vim.fn.jobstop(cache.pending_job)
      cache.pending_job = nil
    end

    expire_cache()

    debounce_update()
  end,
})

-- Update on focus/resume
vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
  callback = function()
    -- Just expire the cache, next render will update
    cache.last_check = 0
  end,
})

return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      component_separators = "|",
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
      },
      section_separators = { left = "", right = "" },
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
  },
}
