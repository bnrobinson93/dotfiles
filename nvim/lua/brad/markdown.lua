return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = { 'markdown', 'Avante' },
  opts = {
    render_modes = { 'n' },
    checkbox = {
      unchecked = { icon = ' ' },
      checked = { icon = '󰄳 ', scope_highlight = '@markup.strikethrough' },
      custom = {
        todo = { raw = '[-]', rendered = '󰍷 ', highlight = 'DiagnosticError' },
        important = { raw = '[!]', rendered = ' ', highlight = 'DiagnosticWarn' },
        partial = { raw = '[~]', rendered = ' ', highlight = 'DiagnosticInfo' },
        delayed = { raw = '[>]', rendered = '󰥔 ', highlight = 'DiagnosticWarn' },
        partial_parent = { raw = '[/]', rendered = '󰁊 ', highlight = 'SpecialKey', scope_highlight = '@markup.strikethrough' },
      },
    },
    pipe_table = {
      enabled = true,
      cell = 'trimmed',
    },
  },
}
