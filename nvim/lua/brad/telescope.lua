return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.3',
  dependencies = { 'nvim-lua/plenary.nvim', 'folke/trouble.nvim' },
  cond = require('telescope.utils').get_os_command_output { 'git', 'rev-parse', '--is-inside-work-tree' },
  config = function()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'
    telescope.setup {
      defaults = {
        path_display = { 'smart' },
        mappings = {
          i = {
            ['<C-t>'] = require('trouble.sources.telescope').open,
          },
        },
      },
    }
  end,
  cmd = 'Telescope',
  keys = {
    { '<C-b>', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
    { '<C-p>', '<cmd>Telescope git_files<cr>', desc = 'Git files' },
    { '<C-s>', '<cmd>Telescope git_status<cr>', desc = 'Git status' },
    { '<leader>pf', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
    { '<leader>phf', '<cmd>Telescope find_files hidden=true<cr>', desc = 'Find files (hidden)' },
    { '<leader>ps', '<cmd>Telescope live_grep<cr>', desc = 'live_grep' },
    { '<leader>phs', '<cmd>Telescope live_grep hidden=true<cr>', desc = 'live_grep (hidden)' },
    {
      '<leader>pws',
      '<cmd>Telescope grep_string<cr>',
      desc = 'grep_string',
    },
    {
      '<leader>pwhs',
      '<cmd>Telescope grep_string hidden=true<cr>',
      desc = 'grep_string (hidden)',
    },
    {
      '<leader>pWs',
      function()
        local word = vim.fn.expand '<cWORD>'
        require('telescope.builtin').grep_string { search = word }
      end,
      desc = 'grep full string under the cursor',
    },
    {
      '<leader>pWhs',
      function()
        local word = vim.fn.expand '<cWORD>'
        require('telescope.builtin').grep_string { search = word, hidden = true }
      end,
      desc = 'grep full string under the cursor (hidden)',
    },
  },
}
