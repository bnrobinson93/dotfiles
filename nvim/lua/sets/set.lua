vim.loader.enable()

-- For Obsidian
vim.opt.conceallevel = 1

vim.opt.guicursor = 'n-v-c-sm:block-Cursor,i-ci-ve:ver35-Cursor,r-cr-o:hor30-Cursor'
vim.opt.cursorline = true
vim.opt.mouse = 'nv'

vim.opt.nu = true
vim.opt.rnu = true

vim.g.netrw_banner = 0
vim.g.netrw_keepdir = 0

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.smarttab = true

-- Highlight trailing spaces in YAML files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { '*.yaml', '*.yml' },
  desc = 'Highlight trailing whitespace in YAML files',
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ns = vim.api.nvim_create_namespace 'YAML'

    -- Set these options once
    vim.opt_local.list = true
    vim.opt_local.listchars:append 'trail:·'
    vim.cmd 'hi def link ExtraWhitespace RedrawDebugRecompose'
    vim.fn.matchadd('ExtraWhitespace', '\\s\\+$')

    -- Store reference to update_diagnostics in buffer scope
    local update_diagnostics
    update_diagnostics = function()
      local diagnostics = {}
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      for i, line in ipairs(lines) do
        local trailing = line:match '%s+$'
        if trailing then
          table.insert(diagnostics, {
            bufnr = bufnr,
            lnum = i - 1,
            col = #line - #trailing,
            end_lnum = i - 1,
            end_col = #line,
            severity = vim.diagnostic.severity.HINT,
            message = 'Trailing whitespace detected',
            source = 'YAML',
          })
        end
      end

      vim.diagnostic.set(ns, bufnr, diagnostics)
    end

    -- Initial check
    update_diagnostics()

    -- Update diagnostics with debouncing
    local timer = vim.loop.new_timer()
    vim.api.nvim_create_autocmd('TextChanged', {
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

    -- Clean up timer when buffer is deleted
    vim.api.nvim_create_autocmd('BufDelete', {
      buffer = bufnr,
      callback = function()
        timer:close()
      end,
    })
  end,
})

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME' .. '/.vim/undodir')
vim.opt.undofile = true

vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append '@-@'

vim.opt.updatetime = 50

vim.opt.colorcolumn = '80,120'
vim.opt.textwidth = 120

vim.g.mapleader = ' '

-- for javascript, set the @ alias to .
vim.cmd [[ set includeexpr=tr(v:fname,'@','.') ]]

if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.smoothscroll = true
  vim.opt.foldtext = ''
end

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

vim.opt.spelllang = 'en_us'
vim.cmd [[ autocmd FileType markdown,mkd,text,COMMIT_EDITMSG setlocal spell ]]
