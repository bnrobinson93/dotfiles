return {
  'JoosepAlviste/nvim-ts-context-commentstring',
  event = 'BufRead',
  cond = function()
    return not vim.g.vscode
  end,
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  opts = { enable_autocmd = false },
}
