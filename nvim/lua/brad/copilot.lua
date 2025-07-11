return {
  'zbirenbaum/copilot.lua',
  ft = { 'go', 'lua', 'typescriptreact', 'javascriptreact', 'typescript', 'javascript', 'html', 'css' },
  cond = function()
    return not vim.g.vscode
  end,
  cmd = 'Copilot',
  opts = {
    workspace_folders = {
      vim.fn.expand '$HOME' .. '/Documents/code',
    },
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = '<M-a>',
      },
    },
  },
}
