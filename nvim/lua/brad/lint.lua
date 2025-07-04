return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre' },
  config = function()
    local lint = require 'lint'

    lint.linters_by_ft = {
      typescript = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
      javascript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      yaml = { 'yamllint' },
      ['yaml.ghaction'] = { 'yamllint', 'actionlint', 'zizmor' },
      ['yaml.githubactions'] = { 'yamllint', 'actionlint', 'zizmor' },
    }

    local lint_augroup = vim.api.nvim_create_augroup('Lint', { clear = true })

    -- Can also add TextChanged
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      -- pattern = { '*' },
      group = lint_augroup,
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

  keys = {
    {
      '<leader>li',
      function()
        require('lint').try_lint()
      end,
      mode = { 'n', 'v' },
      desc = 'Lint current file',
    },
  },
}
