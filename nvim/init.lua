require 'sets.set'
require 'sets.remap'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('lazy').setup {
  install = { colorscheme = { 'night-owl', 'catppuccin' } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  spec = { import = 'brad' },
  performance = {
    cache = {
      enabled = true,
    },
  },
  diff = { cmd = 'git' },
}
