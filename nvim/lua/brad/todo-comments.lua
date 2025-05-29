return {
  'folke/todo-comments.nvim',
  lazy = 'BufReadPre',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    signs = true,
    keywords = {
      FIX = {
        icon = ' ',
        color = 'error',
        alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' },
      },
      TODO = { color = 'info' },
      HACK = { color = 'warning' },
      WARN = { color = 'warning', alt = { 'WARNING', 'XXX' } },
      PERF = { alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
      NOTE = { color = 'hint', alt = { 'INFO' } },
      TEST = { color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
    },
  },
}
