return {
  'folke/trouble.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', 'nvim-telescope/telescope.nvim' },
  opts = {
    focus = true,
    multiline = true, -- render multi-line messages
    auto_open = false, -- automatically open the list when you have diagnostics
    auto_close = true, -- automatically close the list when you have no diagnostics
    warn_no_results = true,
  },
  keys = {
    { '<leader>td', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Toggle buffer diagnostics' },
    { '<leader>tD', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Toggle trouble' },
    { '<leader>tq', '<cmd>Trouble qflist toggle<cr>', desc = 'Toggle trouble quickfix' },
    { '<leader>tt', '<cmd>Trouble todo toggle<cr>', desc = 'Toggle trouble todo list' },
    -- { '[d', '<cmd>Trouble diagnostics next focus=false<cr><cmd>Trouble close<cr>', desc = 'Next trouble' },
    -- { ']d', '<cmd>Trouble diagnostics prev focus=false<cr><cmd>Trouble close<cr>', desc = 'Prev trouble' },
  },
}
