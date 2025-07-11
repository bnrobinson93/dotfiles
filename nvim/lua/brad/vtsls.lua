return {
  'yioneko/nvim-vtsls',
  dependencies = { 'nvim-lspconfig' },
  cond = function()
    return not vim.g.vscode
  end,
  ft = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
}
