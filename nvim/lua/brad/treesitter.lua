vim.g.skip_ts_context_commentstring_module = true

return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  cond = function()
    return not vim.g.vscode
  end,
  branch = 'master',
  version = false,
  build = ':TSUpdate',
  init = function(plugin)
    -- https://www.lazyvim.org/plugins/treesitter
    -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
    -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
    -- no longer trigger the **nvim-treeitter** module to be loaded in time.
    -- Luckily, the only things that those plugins need are the custom queries, which we make available
    -- during startup.
    require('lazy.core.loader').add_to_rtp(plugin)
    require 'nvim-treesitter.query_predicates'
  end,
  config = function(_, opts)
    require('nvim-treesitter.configs').setup(opts)
    vim.keymap.set('n', '<F12>', '<cmd>Inspect<CR>', { desc = 'Show Treesitter Captures Under Cursor', silent = true })
  end,
  opts = {
    sync_install = false,
    auto_install = false,
    indent = { enable = true },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    ensure_installed = {
      'bash',
      'diff',
      'html',
      'javascript',
      'json',
      'lua',
      'luadoc',
      'luap',
      'markdown',
      'markdown_inline',
      'python',
      'query',
      'regex',
      'tsx',
      'typescript',
      'vim',
      'vimdoc',
      'yaml',
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<C-h>',
        node_incremental = '<C-h>',
        scope_incremental = false,
        node_decremental = '<bs>',
      },
    },
  },
}
