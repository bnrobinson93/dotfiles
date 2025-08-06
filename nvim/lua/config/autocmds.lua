-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local autocmd = vim.api.nvim_create_autocmd

-- Spell checking for text files
autocmd("FileType", {
  pattern = { "markdown", "mkd", "text", "COMMIT_EDITMSG" },
  callback = function()
    vim.opt_local.spell = true

    vim.cmd([[
      augroup pencil
      autocmd!
      autocmd FileType markdown,mkd call pencil#init()
      autocmd FileType text         call pencil#init()
      augroup END
    ]])
  end,
})

-- YAML trailing whitespace highlighting (from your config)
autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.yaml", "*.yml" },
  desc = "Highlight trailing whitespace in YAML files",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
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

    local timer = vim.loop.new_timer()
    autocmd("TextChanged", {
      buffer = bufnr,
      callback = function()
        timer:start(
          500,
          0,
          vim.schedule_wrap(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              update_diagnostics()
            end
          end)
        )
      end,
    })

    autocmd("BufDelete", {
      buffer = bufnr,
      callback = function()
        timer:close()
      end,
    })
  end,
})

-- Command alias
vim.cmd([[ command W write ]])
