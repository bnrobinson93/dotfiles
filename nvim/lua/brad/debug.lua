local js_based_languages = {
  'javascript',
  'typescript',
  'typescriptreact',
  'javascriptreact',
  'vue',
}

function start_chrome_debugging()
  local url = vim.fn.input('Enter URL: ', 'http://localhost:3000')
  local debug_port = 9222
  local profile_dir = vim.fn.expand '~/.chrome-debug-profile'

  -- Create profile directory if needed
  if vim.fn.isdirectory(profile_dir) == 0 then
    vim.fn.mkdir(profile_dir, 'p')
  end

  -- Close any existing Chrome instances (optional - remove if you want to keep your main Chrome running)
  local kill_cmd = vim.fn.has 'mac' == 1 and 'pkill -f "Google Chrome"'
    or vim.fn.has 'unix' == 1 and 'pkill -f chrome'
    or vim.fn.has 'win32' == 1 and 'taskkill /F /IM chrome.exe'
    or ''

  if kill_cmd ~= '' then
    vim.fn.system(kill_cmd)
    -- Wait a moment for Chrome to fully close
    vim.fn.system 'sleep 1'
  end

  -- Build the chrome command
  local chrome_cmd = ''
  if vim.fn.has 'mac' == 1 then
    chrome_cmd = string.format(
      '"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=%d --user-data-dir="%s" "%s" &',
      debug_port,
      profile_dir,
      url
    )
  elseif vim.fn.has 'unix' == 1 then
    chrome_cmd = string.format('google-chrome --remote-debugging-port=%d --user-data-dir="%s" "%s" &', debug_port, profile_dir, url)
  elseif vim.fn.has 'win32' == 1 then
    chrome_cmd = string.format('start chrome --remote-debugging-port=%d --user-data-dir="%s" "%s"', debug_port, profile_dir:gsub('/', '\\'), url)
  end

  -- Execute the command
  print('Running command: ' .. chrome_cmd)
  vim.fn.system(chrome_cmd)

  -- Wait a moment for Chrome to start
  vim.fn.system 'sleep 2'

  -- Check if debugging is active
  local check_cmd = 'curl -s http://localhost:' .. debug_port .. '/json/version'
  local result = vim.fn.system(check_cmd)

  if result:match 'Chrome' then
    print('Chrome debug port ' .. debug_port .. ' is active! You can now attach the debugger.')
  else
    print 'Warning: Chrome debug port could not be verified. Check if Chrome started properly.'
  end
end

vim.api.nvim_create_user_command('StartChromeDebug', start_chrome_debugging, {})

return {
  -- dap
  {
    'mfussenegger/nvim-dap',
    lazy = true,
    cond = function()
      return not vim.g.vscode
    end,
    recommended = true,
    desc = 'Debugging support. Requires language specific adapters to be configured. (see lang extras)',

    dependencies = {
      'rcarriga/nvim-dap-ui',
      { 'microsoft/vscode-js-debug', build = 'pnpm install && pnpx gulp vsDebugServerBundle && mv dist out && git checkout -- OPTIONS.md' },
      {
        'mxsdev/nvim-dap-vscode-js',
        config = function()
          require('dap-vscode-js').setup {
            debugger_path = vim.fn.resolve(vim.fn.stdpath 'data' .. '/lazy/vscode-js-debug'),
            adapaters = {
              'chrome',
              'firefox',
              'pwa-node',
              'pwa-chrome',
              'pwa-msedge',
              'pwa-extensionHost',
              'node-terminal',
              'node',
            },
          }
        end,
      },
      {
        'Joakker/lua-json5',
        build = './install.sh',
        ft = { 'json', 'jsonc' },
        lazy = true,
      },
    },

  -- stylua: ignore
  keys = {
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
    { "<leader>dA", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dj", function() require("dap").down() end, desc = "Down" },
    { "<leader>dk", function() require("dap").up() end, desc = "Up" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>ds", function() require("dap").session() end, desc = "Session" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
  },

    config = function()
      local dap = require 'dap'

      vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })

      vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DiagnosticSignError', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped', { text = '', texthl = 'DiagnosticSignWarn', linehl = '', numhl = '' })

      -- Register adapters first
      dap.adapters.chrome = {
        type = 'executable',
        command = 'node',
        args = { vim.fn.stdpath 'data' .. '/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js' },
      }

      dap.adapters.firefox = {
        type = 'executable',
        command = 'node',
        args = { vim.fn.stdpath 'data' .. '/mason/packages/firefox-debug-adapter/dist/adapter.bundle.js' },
      }

      -- setup dap config by VsCode launch.json file
      local vscode = require 'dap.ext.vscode'
      local json = require 'plenary.json'
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end

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
            name = 'Attach to node process',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
            sourceMaps = true,
          },
          -- Debug web apps (client side)
          {
            type = 'chrome', -- Use standard chrome adapter (not pwa-chrome)
            request = 'attach',
            name = 'Attach to Chrome',
            port = 9222,
            webRoot = '${workspaceFolder}',
            timeout = 30000, -- Increased timeout (30 seconds)
            sourceMaps = true,
          },
          -- Firefox debugging option
          {
            type = 'firefox',
            request = 'launch',
            name = 'Debug with Firefox',
            reAttach = true,
            url = function()
              return vim.fn.input('Enter URL: ', 'http://localhost:3000')
            end,
            webRoot = '${workspaceFolder}',
            firefoxExecutable = '/usr/bin/firefox',
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
  },
  -- virtual text
  {
    'theHamsta/nvim-dap-virtual-text',
    lazy = true,
    opts = {},
  },
  -- nvim dap ui
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'nvim-neotest/nvim-nio' },
    -- stylua: ignore
    keys = {
      { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
    },
    opts = {},
    config = function(_, opts)
      local dap = require 'dap'
      local dapui = require 'dapui'
      dapui.setup(opts)
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open {}
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close {}
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close {}
      end
    end,
  },
  { 'nvim-neotest/nvim-nio' },
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = 'mason.nvim',
    lazy = true,
    cmd = { 'DapInstall', 'DapUninstall' },
    opts = {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
      },
    },
    -- mason-nvim-dap is loaded when nvim-dap loads
    config = function() end,
  },

  -- mason
  {
    'jay-babu/mason-nvim-dap.nvim',
    lazy = true,
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-dap',
    },
    config = function()
      require('mason-nvim-dap').setup {
        -- Automatically install these adapters
        ensure_installed = {
          'python', -- For Python debugging
          'node2', -- For JavaScript/TypeScript
          'codelldb', -- For C, C++, Rust
          'delve', -- For Go
          'firefox',
          'chrome',
          'chrome-debug-adapter',
          'firefox-debug-adapter',
        },
        -- Automatically set up adapter configurations
        automatic_setup = true,
      }
    end,
  },
}
