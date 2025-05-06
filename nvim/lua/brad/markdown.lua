return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = { 'markdown', 'Avante', 'vimwiki', 'help' },
  opts = {
    render_modes = { 'n', 'c', 't' },
    checkbox = {
      unchecked = { icon = ' ' },
      checked = { icon = '󰄳 ', scope_highlight = '@markup.strikethrough' },
      custom = {
        todo = { raw = '[-]', rendered = '󰍷 ', highlight = 'DiagnosticSignError' },
        important = { raw = '[!]', rendered = ' ', highlight = 'DiagnosticSignWarn' },
        partial = { raw = '[~]', rendered = ' ', highlight = 'DiagnosticSignHint' },
        delayed = { raw = '[>]', rendered = '󰥔 ', highlight = 'DiagnosticSignWarn' },
        partial_parent = { raw = '[/]', rendered = '󰁊 ', highlight = 'DiagnosticDepricated', scope_highlight = '@markup.strikethrough' },
      },
    },
    pipe_table = {
      enabled = true,
      cell = 'trimmed',
      preset = 'round',
    },
  },
}
