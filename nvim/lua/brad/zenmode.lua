return {
  'folke/zen-mode.nvim',
  cond = function()
    return not vim.g.vscode
  end,
  opts = {
    window = {
      backdrop = 0.95,
      options = { signcolumn = 'no' },
    },
    plugins = {
      options = { enabled = true, laststatus = 0 },
      alacritty = { enabled = true, font = '17' },
      kitty = { enabled = true, font = '+3' },
      wezterm = { enabled = true, font = '+3' },
      gitsgns = { enabled = true },
      tmux = { enabled = true },
    },
  },
  keys = {
    { '<leader>z', '<CMD>ZenMode<CR>', mode = { 'n' }, desc = 'Toggle [Z]en mode' },
  },
}
