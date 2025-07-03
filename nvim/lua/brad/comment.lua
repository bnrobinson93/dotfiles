return {
  {
    {
      'folke/ts-comments.nvim',
      opts = {},
      event = 'BufReadPost',
      enabled = vim.fn.has 'nvim-0.10.0' == 1,
      ft = {
        'javascript',
        'typescript',
        'javascriptreact',
        'typescriptreact',
        'vue',
        'svelte',
        'astro',
        'css',
        'scss',
        'less',
        'html',
      },
    },
  },
  {
    'numToStr/Comment.nvim',
    event = 'BufReadPost',
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
