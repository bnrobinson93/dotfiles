return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.3',
  dependencies = { 'nvim-lua/plenary.nvim', 'folke/trouble.nvim' },
  cond = require('telescope.utils').get_os_command_output { 'git', 'rev-parse', '--is-inside-work-tree' },
  cmd = 'Telescope',
  keys = {
    { '<C-t>', '<cmd>Trouble telescope<cr>', desc = '[T]rouble' },
    { '<C-b>', '<cmd>Telescope buffers<cr>', desc = '[B]uffers' },
    { '<C-p>', '<cmd>Telescope git_files<cr>', desc = '[P]roject' },
    { '<C-s>', '<cmd>Telescope git_status<cr>', desc = 'Git [S]tatus' },
    { '<leader>pf', '<cmd>Telescope find_files<cr>', desc = '[P]roject-wide: [F]iles' },
    { '<leader>phf', '<cmd>Telescope find_files hidden=true<cr>', desc = '[P]roject-wide: [H]idden Files' },
    { '<leader>ps', '<cmd>Telescope live_grep<cr>', desc = '[P]roject-wide: File [S]earch' },
    {
      '<leader>phs',
      '<cmd>lua require("telescope.builtin").live_grep({ additional_args = { "--hidden" } })<CR>',
      desc = '[P]roject-wide: [H]idden File [S]earch',
    },
    {
      '<leader>pws',
      '<cmd>Telescope grep_string<cr>',
      desc = '[P]roject-wide: Search [w]ord under cursor (between special chars)',
    },
    {
      '<leader>pwhs',
      '<cmd>Telescope grep_string hidden=true<cr>',
      desc = '[P]roject-wide: Search [w]ord under cursor (between special chars) in [H]idden Files',
    },
    {
      '<leader>pWs',
      function()
        local word = vim.fn.expand '<cWORD>'
        require('telescope.builtin').grep_string { search = word }
      end,
      desc = '[P]roject-wide: Search [W]ord under cursor (between whitespace)',
    },
    {
      '<leader>pWhs',
      function()
        local word = vim.fn.expand '<cWORD>'
        require('telescope.builtin').grep_string { search = word, hidden = true }
      end,
      desc = '[P]roject-wide: Search [w]ord under cursor (between whitespace) in [H]idden Files',
    },
    {
      '<leader>pcs',
      function()
        local git_files = vim.fn.systemlist 'git ls-files --modified --others --exclude-standard'
        require('telescope.builtin').live_grep {
          search_dirs = git_files,
          prompt_title = 'Grep Changed Files',
        }
      end,
      desc = '[P]roject-wide: [C]hanged File [S]earch (grep)',
    },
  },
}
