-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local autocmd = vim.api.nvim_create_autocmd

-- Spell checking for text files + PencilSoft
if not vim.g.vscode then
  vim.cmd([[
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd,text
                            \   call pencil#init({'wrap': 'soft'})
                            \ | setl spell spl=en_us fdl=4 
                            \ | setl fdo+=search
  autocmd Filetype git,gitsendemail,*commit*,*COMMIT*
                            \   call pencil#init({'wrap': 'hard', 'textwidth': 72})
  autocmd Filetype mail         call pencil#init({'wrap': 'hard', 'textwidth': 60})
  autocmd Filetype html,xml     call pencil#init({'wrap': 'soft'})
augroup END
]])

  -- YAML - buffer-specific timer tracking to prevent leaks
  local yaml_timers = {} -- Track timers per buffer
  local yaml_group = vim.api.nvim_create_augroup("YAMLTrailingWhitespace", { clear = true })

  autocmd({ "BufRead", "BufNewFile" }, {
    group = yaml_group,
    pattern = { "*.yaml", "*.yml" },
    desc = "Highlight trailing whitespace in YAML files",
    callback = function()
      -- check linters for github
      local bufnr = vim.api.nvim_get_current_buf()

      -- Skip if already initialized for this buffer
      if vim.b[bufnr].yaml_whitespace_initialized then
        return
      end
      vim.b[bufnr].yaml_whitespace_initialized = true

      if vim.b[bufnr].normalized_path == nil then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        vim.b[bufnr].normalized_path = bufname:gsub("\\", "/")
      end
      local normalized_path = vim.b[bufnr].normalized_path
      if normalized_path and normalized_path:match("/.github/workflows/") then
        vim.b.lint_linters = { "actionlint", "zizmor" }
      else
        vim.b.lint_linters = {}
      end

      -- alert on trailing whitespace
      local ns = vim.api.nvim_create_namespace("YAML")

      vim.opt_local.list = true
      vim.opt_local.listchars:append("trail:·")
      vim.cmd("hi def link ExtraWhitespace RedrawDebugRecompose")
      vim.fn.matchadd("ExtraWhitespace", "\\s\\+$")

      local update_diagnostics
      update_diagnostics = function()
        local diagnostics = {}
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        for i, line in ipairs(lines) do
          local trailing = line:match("%s+$")
          if trailing then
            table.insert(diagnostics, {
              bufnr = bufnr,
              lnum = i - 1,
              col = #line - #trailing,
              end_lnum = i - 1,
              end_col = #line,
              severity = vim.diagnostic.severity.HINT,
              message = "Trailing whitespace detected",
              source = "YAML",
            })
          end
        end

        vim.diagnostic.set(ns, bufnr, diagnostics)
      end

      update_diagnostics()

      autocmd("TextChanged", {
        buffer = bufnr,
        callback = function()
          -- Stop previous timer for this buffer to prevent leak
          if yaml_timers[bufnr] then
            vim.fn.timer_stop(yaml_timers[bufnr])
            yaml_timers[bufnr] = nil
          end
          yaml_timers[bufnr] = vim.fn.timer_start(
            500,
            vim.schedule_wrap(function()
              if vim.api.nvim_buf_is_valid(bufnr) then
                update_diagnostics()
              end
              yaml_timers[bufnr] = nil
            end)
          )
        end,
      })

      autocmd("BufDelete", {
        buffer = bufnr,
        callback = function()
          -- Clean up timer and flag
          if yaml_timers[bufnr] then
            vim.fn.timer_stop(yaml_timers[bufnr])
            yaml_timers[bufnr] = nil
          end
          vim.b[bufnr].yaml_whitespace_initialized = nil
        end,
      })
    end,
  })
end

-- Command alias
vim.cmd([[ command W write ]])

autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.ts", "*.js", "*.tsx", "*.jsx" },
  desc = "Help javascript aliases find the right path",
  callback = function()
    vim.cmd([[set includeexpr=tr(v:fname,'@','.') ]])
  end,
})
