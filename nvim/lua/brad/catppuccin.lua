return {
  'catppuccin/nvim',
  enabled = true,
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
          ['@function.call'] = { fg = colors.blue, style = { 'italic' } },
          ['@lsp.mod.declaration'] = { fg = colors.blue, style = { 'italic' } },
          ['@variable.builtin'] = { fg = colors.teal, style = { 'italic' } },
          ['@variable.member'] = { fg = colors.yellow, style = { 'italic' } },
          ['String'] = { fg = colors.flamingo },
        }
      end,
    }

    vim.cmd.colorscheme 'catppuccin'
    require('lualine').setup {
      options = {
        theme = 'catppuccin',
      },
    }
  end,
}
