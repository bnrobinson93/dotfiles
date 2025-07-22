return {
  'rafikdraoui/jj-diffconflicts',
  {
    'julienvincent/hunk.nvim',
    cmd = { 'DiffEditor' },
    cond = require('telescope.utils').get_os_command_output { 'git', 'rev-parse', '--is-inside-work-tree' },
    config = function()
      require('hunk').setup()
    end,
    keys = {
      { '<leader>gf', '<cmd>diffget //2<cr>', desc = 'Git diffget 2 (left hand)' },
      { '<leader>gj', '<cmd>diffget //3<cr>', desc = 'Git diffget 3 (right hand)' },
    },
  },
}
