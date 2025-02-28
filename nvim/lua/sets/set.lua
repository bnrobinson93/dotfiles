vim.loader.enable()

-- For Obsidian
vim.opt.conceallevel = 1

vim.opt.guicursor = ''
vim.opt.cursorline = true
vim.opt.mouse = 'nv'

-- Folds
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
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

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
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

if vim.fn.has 'nvim-0.10' == 1 then
  vim.opt.smoothscroll = true
  vim.opt.foldtext = ''
end

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
