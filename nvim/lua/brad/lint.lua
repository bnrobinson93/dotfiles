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

    -- ESLint fix command with Trouble integration
    local function eslint_fix_trouble()
      local trouble_ok, trouble = pcall(require, 'trouble')
      if not trouble_ok then
        vim.notify('Trouble plugin not available', vim.log.levels.ERROR)
        return
      end

      vim.notify('Running eslint --fix ...', vim.log.levels.INFO)

      -- Run eslint --fix and capture output, separating stderr and stdout
      local cmd = 'eslint --fix . --format json 2>/tmp/eslint_stderr'
      local handle = io.popen(cmd)
      local result = handle:read '*a'
      handle:close()

      -- Read any stderr messages
      local stderr_handle = io.open('/tmp/eslint_stderr', 'r')
      local stderr_content = ''
      if stderr_handle then
        stderr_content = stderr_handle:read '*a'
        stderr_handle:close()
        os.remove '/tmp/eslint_stderr'
      end

      -- Show any warnings/errors from stderr
      if stderr_content and stderr_content:match '%S' then
        vim.notify('ESLint warnings:\n' .. stderr_content, vim.log.levels.WARN)
      end

      -- Handle empty or whitespace-only result
      if not result or result:match '^%s*$' then
        vim.notify('ESLint --fix completed successfully! No issues found.', vim.log.levels.INFO)
        trouble.close()
        return
      end

      -- Try to find JSON in the output (in case there's non-JSON text mixed in)
      local json_start = result:find '%['
      if json_start then
        result = result:sub(json_start)
      end

      -- Parse JSON output
      local ok, eslint_output = pcall(vim.json.decode, result)

      if not ok then
        vim.notify('Could not parse ESLint JSON output. Raw output:\n' .. result, vim.log.levels.ERROR)
        return
      end

      -- Convert ESLint results to quickfix format
      local qf_items = {}

      for _, file_result in ipairs(eslint_output) do
        local filepath = file_result.filePath

        for _, message in ipairs(file_result.messages or {}) do
          table.insert(qf_items, {
            filename = filepath,
            lnum = message.line or 1,
            col = message.column or 1,
            text = message.message,
            type = message.severity == 2 and 'E' or 'W',
            nr = message.ruleId and string.format('[%s]', message.ruleId) or nil,
          })
        end
      end

      -- Close any existing trouble windows and set quickfix
      trouble.close()
      vim.fn.setqflist(qf_items, 'r')

      if #qf_items > 0 then
        trouble.open 'qflist'
        vim.notify(string.format('ESLint --fix completed. %d issues found.', #qf_items), vim.log.levels.INFO)
      else
        vim.notify('ESLint --fix completed successfully! No issues found.', vim.log.levels.INFO)
      end
    end

    -- Toggle version that works with existing Trouble qflist
    local function eslint_fix_trouble_toggle()
      local trouble_ok, trouble = pcall(require, 'trouble')
      if not trouble_ok then
        eslint_fix_trouble()
        return
      end

      local is_open = trouble.is_open 'qflist'

      if is_open then
        -- If trouble qflist is open, refresh it with new eslint results
        eslint_fix_trouble()
      else
        -- If not open, run eslint and open trouble
        eslint_fix_trouble()
      end
    end

    -- Create user commands
    vim.api.nvim_create_user_command('EslintFix', function()
      -- Simple version that just runs eslint --fix without opening anything
      vim.notify('Running eslint --fix ...', vim.log.levels.INFO)
      local handle = io.popen 'eslint --fix . 2>&1'
      local result = handle:read '*a'
      handle:close()

      if result and result:match '%S' then
        vim.notify('ESLint output:\n' .. result, vim.log.levels.INFO)
      else
        vim.notify('ESLint --fix completed successfully!', vim.log.levels.INFO)
      end
    end, {
      desc = 'Run eslint --fix',
    })

    vim.api.nvim_create_user_command('EslintFixTrouble', eslint_fix_trouble, {
      desc = 'Run eslint --fix and show remaining errors in Trouble',
    })

    vim.api.nvim_create_user_command('EslintFixTroubleToggle', eslint_fix_trouble_toggle, {
      desc = 'Run eslint --fix and toggle Trouble qflist',
    })

    -- Optional keybinding
    vim.keymap.set('n', '<leader>ef', eslint_fix_trouble, {
      desc = 'ESLint fix and show in Trouble',
    })
  end,
}
