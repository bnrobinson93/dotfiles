return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre' },
  config = function()
    local lint = require 'lint'

    lint.linters_by_ft = {
      markdown = { 'vale', 'cspell' },
      plaintext = { 'cspell' },
      typescript = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
      javascript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      yaml = { 'actionlint', 'zizmor' },
      ['yaml.ghaction'] = { 'actionlint', 'zizmor' },
    }

    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'TextChanged' }, {
      callback = function()
        lint.try_lint()
      end,
    })

    vim.api.nvim_create_user_command('LintInfo', function()
      local filetype = vim.bo.filetype
      local linters = lint.linters_by_ft[filetype]
      if linters then
        print('Linters for ' .. filetype .. ': ' .. table.concat(linters, ', '))
      else
        print('No linters configured for filetype: ' .. filetype)
      end
    end, {})
  end,
}
