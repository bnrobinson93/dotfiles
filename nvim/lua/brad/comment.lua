return {
  {
    {
      'folke/ts-comments.nvim',
      opts = {},
      event = 'VeryLazy',
      enabled = vim.fn.has 'nvim-0.10.0' == 1,
    },
  },
  {
    'numToStr/Comment.nvim',
    lazy = 'InsertEnter',
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    config = function()
      local prehook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
      require('Comment').setup {
        pre_hook = prehook,
        mappings = {
          ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
          basic = true,
          ---Extra mapping; `gco`, `gcO`, `gcA`
          extra = true,
        },
      }
    end,
  },
}
