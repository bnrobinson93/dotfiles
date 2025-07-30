-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.opt.clipboard = ""
vim.opt.confirm = false

local opt = vim.opt

-- Your custom options from sets/set.lua
opt.conceallevel = 1 -- For Obsidian
opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver35-Cursor,r-cr-o:hor30-Cursor"
opt.mouse = "nv"

-- Netrw settings
vim.g.netrw_banner = 0
vim.g.netrw_keepdir = 0

-- Indentation (your preferred settings)
opt.softtabstop = 2
opt.autoindent = true
opt.smarttab = true

opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

opt.incsearch = true
opt.isfname:append("@-@")
opt.colorcolumn = "80,120"
opt.textwidth = 120

-- JavaScript alias settings
vim.cmd([[ set includeexpr=tr(v:fname,'@','.') ]])
