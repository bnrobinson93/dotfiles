vim.loader.enable()

-- For Obsidian
vim.opt.conceallevel = 1

vim.opt.guicursor = ''
vim.opt.cursorline = true
vim.opt.mouse = 'nv'

vim.opt.foldmethod = 'manual'
vim.opt.foldcolumn = '1'
vim.opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}

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
    vim.opt.list = true
    vim.opt.listchars:append 'trail:·'
    vim.cmd 'highlight ExtraWhitespace ctermbg=red guibg=red'
    vim.fn.matchadd('ExtraWhitespace', '\\s\\+$')
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

-- Remember folds
vim.opt.foldmethod = 'manual'
vim.api.nvim_create_autocmd({ 'BufWinLeave' }, {
  pattern = { '*.*' },
  desc = 'save view (folds), when closing file',
  command = 'mkview',
})
vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  pattern = { '*.*' },
  desc = 'load view (folds), when opening file',
  command = 'silent! loadview',
})

if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.smoothscroll = true
  vim.opt.foldtext = ''
end

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
