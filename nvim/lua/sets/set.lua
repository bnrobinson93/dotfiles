vim.loader.enable()

-- For Obsidian
vim.opt.conceallevel = 1

vim.opt.guicursor = 'n-v-c-sm:block-Cursor,i-ci-ve:ver35-Cursor,r-cr-o:hor30-Cursor'
vim.opt.cursorline = true
vim.opt.mouse = 'nv'

vim.opt.nu = true
vim.opt.rnu = true

vim.g.netrw_banner = 0

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
    -- Add to diagnostics
    local bufnr = vim.api.nvim_get_current_buf()
    local diagnostics = {}

    vim.opt_local.list = true
    vim.opt_local.listchars:append 'trail:·'
    vim.cmd 'hi def link ExtraWhitespace DiffDelete'

    local pattern = '\\s\\+$'
    vim.fn.matchadd('ExtraWhitespace', pattern)

    -- Create a namespace for our diagnostics
    local ns = vim.api.nvim_create_namespace 'YAML'

    -- Find all instances of trailing whitespace
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
      local trailing = line:match '%s+$'
      if trailing then
        table.insert(diagnostics, {
          bufnr = bufnr,
          lnum = i - 1, -- 0-indexed
          col = #line - #trailing,
          end_lnum = i - 1,
          end_col = #line,
          severity = vim.diagnostic.severity.HINT,
          message = 'Trailing whitespace detected',
          source = 'YAML',
        })
      end
    end

    -- Set the diagnostics for this buffer
    vim.diagnostic.set(ns, bufnr, diagnostics)

    -- Optionally update diagnostics when buffer changes
    vim.api.nvim_create_autocmd('TextChanged', {
      buffer = bufnr,
      callback = function()
        -- This will re-run the diagnostic detection when text changes
        vim.schedule(function()
          vim.cmd 'doautocmd BufRead'
        end)
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

vim.opt.colorcolumn = '80'

vim.g.mapleader = ' '

-- for javascript, set the @ alias to .
vim.cmd [[ set includeexpr=tr(v:fname,'@','.') ]]

if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.smoothscroll = true
  vim.opt.foldtext = ''
end

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
