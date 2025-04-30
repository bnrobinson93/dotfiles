local lazy_status = require 'lazy.status'

return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    options = {
      icons_enabled = true,
      theme = 'catppuccin',
      always_divide_middle = false,
      section_separators = { left = '', right = '' },
      component_separators = '|',
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'filename', 'branch', 'diff', 'diagnostics' },
      lualine_c = {
        {
          'lsp_status',
          separator = '',
          color = { fg = '#585b70' },
          padding = { left = 0, right = 1 },
          icon = '',
          symbols = {
            spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
            done = '✓',
            separator = ', ',
          },
          ignore_lsp = {'GitHub Copilot'},
        },
        {
          'filetype',
          separator = '',
          color = { fg = '#585b70' },
          padding = { left = 0, right = 0 },
          colored = false,
          icon_only = true,
        },
      },
      lualine_x = {
        {
          lazy_status.updates,
          cond = lazy_status.has_updates,
          color = { fg = 'orange' },
          left_padding = 1,
        },
      },
      lualine_y = {
        'encoding',
        'fileformat',
      },
    },
  },
}
