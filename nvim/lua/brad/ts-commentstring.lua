return {
  'JoosepAlviste/nvim-ts-context-commentstring',
  event = 'BufRead',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  opts = { enable_autocmd = false },
}
