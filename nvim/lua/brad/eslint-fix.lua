local function eslint_fix_trouble()
  local trouble_ok, trouble = pcall(require, 'trouble')
  if not trouble_ok then
    vim.notify('Trouble plugin not available', vim.log.levels.ERROR)
    return
  end

  -- Spinner frames for the notification
  local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local spinner_index = 1
  local spinner_timer = nil
  local notification_id = nil

  -- Start spinner notification
  local function start_spinner()
    notification_id = vim.notify('⠋ Running eslint --fix...', vim.log.levels.INFO, {
      timeout = false, -- Don't auto-dismiss
      replace = notification_id,
    })

    spinner_timer = vim.loop.new_timer()
    spinner_timer:start(
      100,
      100,
      vim.schedule_wrap(function()
        spinner_index = (spinner_index % #spinner_frames) + 1
        notification_id = vim.notify(spinner_frames[spinner_index] .. ' Running eslint --fix...', vim.log.levels.INFO, {
          timeout = false,
          replace = notification_id,
        })
      end)
    )
  end

  -- Stop spinner and show final message
  local function stop_spinner(message, level)
    if spinner_timer then
      spinner_timer:stop()
      spinner_timer:close()
      spinner_timer = nil
    end

    vim.notify(message, level or vim.log.levels.INFO, {
      timeout = 3000,
      replace = notification_id,
    })
  end

  start_spinner()

  -- Run ESLint asynchronously
  local stdout_data = {}
  local stderr_data = {}

  local job_id = vim.fn.jobstart({
    'eslint',
    '--fix',
    './src',
    '--format',
    'json',
  }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_data, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_data, data)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        -- Join the output lines
        local stdout_result = table.concat(stdout_data, '\n')
        local stderr_result = table.concat(stderr_data, '\n')

        -- Show any warnings/errors from stderr
        if stderr_result and stderr_result:match '%S' then
          vim.notify('ESLint warnings:\n' .. stderr_result, vim.log.levels.WARN, { timeout = 5000 })
        end

        -- Handle empty or whitespace-only result
        if not stdout_result or stdout_result:match '^%s*$' then
          stop_spinner '✓ ESLint --fix completed successfully! No issues found.'
          trouble.close()
          return
        end

        -- Try to find JSON in the output
        local json_start = stdout_result:find '%['
        if json_start then
          stdout_result = stdout_result:sub(json_start)
        end

        -- Parse JSON output
        local ok, eslint_output = pcall(vim.json.decode, stdout_result)

        if not ok then
          stop_spinner('✗ Could not parse ESLint JSON output', vim.log.levels.ERROR)
          vim.notify('Raw output:\n' .. stdout_result, vim.log.levels.ERROR)
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
          stop_spinner(string.format('✓ ESLint --fix completed. %d issues found.', #qf_items))
        else
          stop_spinner '✓ ESLint --fix completed successfully! No issues found.'
        end
      end)
    end,
  })

  if job_id <= 0 then
    stop_spinner('✗ Failed to start ESLint job', vim.log.levels.ERROR)
  end
end

return {
  name = 'eslint-fix',
  dir = vim.fn.stdpath 'config',
  ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  config = function()
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
      -- Simple async version that just runs eslint --fix without opening anything
      local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
      local spinner_index = 1
      local spinner_timer = nil
      local notification_id = nil

      -- Start spinner
      notification_id = vim.notify('⠋ Running eslint --fix...', vim.log.levels.INFO, {
        timeout = false,
        replace = notification_id,
      })

      spinner_timer = vim.loop.new_timer()
      spinner_timer:start(
        100,
        100,
        vim.schedule_wrap(function()
          spinner_index = (spinner_index % #spinner_frames) + 1
          notification_id = vim.notify(spinner_frames[spinner_index] .. ' Running eslint --fix...', vim.log.levels.INFO, {
            timeout = false,
            replace = notification_id,
          })
        end)
      )

      local output_data = {}

      vim.fn.jobstart({
        'eslint',
        '--fix',
        '.',
      }, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data then
            vim.list_extend(output_data, data)
          end
        end,
        on_stderr = function(_, data)
          if data then
            vim.list_extend(output_data, data)
          end
        end,
        on_exit = function(_, exit_code)
          vim.schedule(function()
            if spinner_timer then
              spinner_timer:stop()
              spinner_timer:close()
            end

            local result = table.concat(output_data, '\n')

            if result and result:match '%S' then
              vim.notify('✓ ESLint --fix completed with output:\n' .. result, vim.log.levels.INFO, {
                timeout = 5000,
                replace = notification_id,
              })
            else
              vim.notify('✓ ESLint --fix completed successfully!', vim.log.levels.INFO, {
                timeout = 3000,
                replace = notification_id,
              })
            end
          end)
        end,
      })
    end, {
      desc = 'Run eslint --fix',
    })

    vim.api.nvim_create_user_command('EslintFixTrouble', eslint_fix_trouble, {
      desc = 'Run eslint --fix and show remaining errors in Trouble',
    })

    vim.api.nvim_create_user_command('EslintFixTroubleToggle', eslint_fix_trouble_toggle, {
      desc = 'Run eslint --fix and toggle Trouble qflist',
    })
  end,
  cmd = { 'EslintFix', 'EslintFixTrouble', 'EslintFixTroubleToggle' },
  keys = {
    {
      '<leader>ef',
      function()
        eslint_fix_trouble()
      end,
      desc = '[E]SLint [f]ix and show in Trouble',
    },
  },
}
