local js_based_languages = {
  'javascript',
  'typescript',
  'typescriptreact',
  'javascriptreact',
  'vue',
}

return {
  {
    'mfussenegger/nvim-dap',
    config = function()
      local dap = require 'dap'

      for _, language in ipairs(js_based_languages) do
        dap.configurations[language] = {
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
            sourceMaps = true,
          },
          -- Make sure to add NODE_OPTIONS="--inspect"
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to process',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
            sourceMaps = true,
          },
          -- Debug web apps (client side)
          {
            type = 'pwa-chrome',
            request = 'launch',
            name = 'Launch Chrome',
            url = function()
              local co = coroutine.running()
              return coroutine.create(function()
                vim.ui.input({
                  prompt = 'Enter URL: ',
                  default = 'http://localhost:3000',
                }, function(url)
                  if url == nil or url == '' then
                    return
                  else
                    coroutine.resume(co, url)
                  end
                end)
              end)
            end,
            webRoot = '${workspaceFolder}',
            skipFiles = { '<node_internals>/**' },
            protocol = 'inspector',
            sourceMaps = true,
            userDataDir = false,
          },

          -- Devider for launch.json derived configs
          {
            name = ' ----- launch.json configs ----- ',
            type = '',
            request = 'launch',
          },
        }
      end
    end,
    keys = {
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = '[D]ebug [B]reakpoint',
      },
      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = '[D]ebug [C]ontinue',
      },
      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = '[D]ebug [I]nto',
      },
      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        desc = '[D]ebug [O]ver',
      },
      {
        '<leader>dO',
        function()
          require('dap').step_out()
        end,
        desc = '[D]ebug Step [O]ut',
      },
      {
        '<leader>dA',
        function()
          if vim.fn.filereadable '.vscode/launch.json' then
            local dap_vscode = require 'dap.ext.vscode'
            dap_vscode.load_launchjs(nil, {
              ['pwa-node'] = js_based_languages,
              ['node'] = js_based_languages,
              ['chrome'] = js_based_languages,
              ['pwa-chrome'] = js_based_languages,
            })
          else
            vim.notify 'No launch.json found'
          end
          require('dap').continue()
        end,
        desc = '[D]ebug with [A]rguments',
      },
    },
    dependencies = {
      { 'microsoft/vscode-js-debug', build = 'npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out' },
      {
        'mxsdev/nvim-dap-vscode-js',
        opts = {
          debugger_path = vim.fn.resolve(vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug'),
          adapaters = {
            'chrome',
            'pwa-node',
            'pwa-chrome',
            'pwa-msedge',
            'pwa-extensionHost',
            'node-terminal',
            'node',
          },
        },
      },
      {
        'Joakker/lua-json5',
        build = './install.sh',
      },
    },
  },
}
