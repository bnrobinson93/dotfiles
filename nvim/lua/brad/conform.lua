return {
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  keys = {
    {
      '<leader>f',
      function()
        vim.notify 'Formatting with conform'
        require('conform').format {
          lsp_callback = true,
          async = false,
          timeout_ms = 500,
        }
      end,
      mode = { 'n', 'v' },
      desc = 'Format on file or range',
    },
  },
  opts = {
    formatters_by_ft = {
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      css = { 'prettierd', 'prettier', stop_after_first = true },
      html = { 'prettierd', 'prettier', stop_after_first = true },
      json = { 'prettierd', 'prettier', stop_after_first = true },
      graphql = { 'prettierd', 'prettier', stop_after_first = true },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
      lua = { 'stylua' },
    },
    default_format_opts = {
      lsp_format = 'fallback',
    },
    -- format_on_save = {
    --   lsp_callback = true,
    --   timeout_ms = 500,
    --   async = false,
    -- },
    formatters = {
      prettierd = {
        env = {
          PRETTIERD_DEFAULT_CONFIG = vim.fn.stdpath 'config' .. '/utils/linter-config/prettier.json',
        },
      },
    },
  },
}
