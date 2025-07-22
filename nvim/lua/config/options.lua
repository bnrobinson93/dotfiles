-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.g.snacks_animate = false
vim.opt.clipboard = ""

local opt = vim.opt

-- Your custom options from sets/set.lua
opt.conceallevel = 1 -- For Obsidian
opt.guicursor = "n-v-c-sm:block-Cursor,i-ci-ve:ver35-Cursor,r-cr-o:hor30-Cursor"
opt.cursorline = true
opt.mouse = "nv"

opt.nu = true
opt.rnu = true

-- Netrw settings
vim.g.netrw_banner = 0
vim.g.netrw_keepdir = 0

-- Indentation (your preferred settings)
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.autoindent = true
opt.expandtab = true
opt.smarttab = true

opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

opt.incsearch = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.isfname:append("@-@")
opt.updatetime = 50
opt.colorcolumn = "80,120"
opt.textwidth = 120

-- JavaScript alias settings
vim.cmd([[ set includeexpr=tr(v:fname,'@','.') ]])

if vim.fn.has("nvim-0.10") == 1 then
  opt.smoothscroll = true
  opt.foldtext = ""
end

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
opt.spelllang = "en_us"
