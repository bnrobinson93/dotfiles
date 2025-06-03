return {
  'catppuccin/nvim',
  enabled = false,
  lazy = false,
  name = 'catppuccin',
  priority = 1000,
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha',
      transparent_background = true,
      background = {
        light = 'latte',
        dark = 'mocha',
      },

      integrations = {
        cmp = true,
        gitsigns = true,
        harpoon = true,
        telescope = { enabled = true },
        treesitter = true,

        indent_blankline = { enabled = true },
        lsp_trouble = true,
        mason = true,
        markdown = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { 'undercurl' },
            hints = { 'undercurl' },
            warnings = { 'undercurl' },
            information = { 'undercurl' },
          },
        },
        navic = { enabled = true, custom_bg = 'lualine' },
        semantic_tokens = true,
        treesitter_context = true,
        which_key = true,
      },
      custom_highlights = function(colors)
        return {
          ['@function'] = { fg = colors.blue, style = { 'italic' } },
          -- If you also want to style function calls:
          ['@function.call'] = { fg = colors.blue, style = { 'italic' } },
        }
      end,
    }

    vim.cmd.colorscheme 'night-owl'
    require('lualine').setup {
      options = {
        theme = 'night-owl',
      },
    }
  end,
}
