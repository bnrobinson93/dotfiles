return {
  'oxfist/night-owl.nvim',
  enabled = false,
  lazy = false,
  name = 'night-owl',
  priority = 1000,
  config = function()
    require('night-owl').setup {
      transparent_background = false,
    }

    vim.cmd.colorscheme 'night-owl'
    require('lualine').setup {
      options = {
        theme = 'night-owl',
      },
    }
  end,
}
