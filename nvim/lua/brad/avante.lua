return {
  'yetone/avante.nvim',
  enabled = true,
  event = 'VeryLazy',
  cond = function()
    return not vim.g.vscode
  end,
  lazy = false,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    provider = 'copilot',
    auto_suggstion_provider = 'copilot',
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = 'make',
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'hrsh7th/nvim-cmp', -- autocompletion for avante commands and mentions
    'zbirenbaum/copilot.lua',
  },
}
