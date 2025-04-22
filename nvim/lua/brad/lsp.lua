local created_temp_file = false

local function get_vite_aliases()
  local possible_configs = {
    '/vite.config.js',
    '/vite.config.ts',
    '/vite.config.mjs',
  }

  local config_path
  for _, path in ipairs(possible_configs) do
    local full_path = vim.fn.getcwd() .. path
    if vim.fn.filereadable(full_path) == 1 then
      config_path = full_path
      break
    end
  end

  if not config_path then
    vim.notify('No vite config found', vim.log.levels.WARN)
    return nil
  end

  -- For TypeScript configs, we need to use ts-node
  local is_typescript = config_path:match '%.ts$'
  local node_command = is_typescript and 'ts-node --esm' or 'node'

  local cmd = string.format(
    [[
    %s --input-type=module -e "
      import { fileURLToPath } from 'url';
      import { dirname, relative } from 'path';
      
      (async () => {
        try {
          const path = '%s';
          global.__dirname = dirname(fileURLToPath(import.meta.url));
          const config = await import(path);
          const resolvedConfig = typeof config.default === 'function' 
            ? await config.default({ 
                mode: 'development',
                command: 'serve'
              }) 
            : config.default;
          const aliases = resolvedConfig?.resolve?.alias || {};
          // Convert absolute paths to relative
          const relativePaths = {};
          for (const [key, value] of Object.entries(aliases)) {
            relativePaths[key] = value.replace('%s/', '');
          }
          process.stdout.write(JSON.stringify(relativePaths));
        } catch (error) {
          console.error(error);
          process.exit(1);
        }
      })();
    "
  ]],
    node_command,
    config_path:gsub('\\', '/'),
    vim.fn.getcwd():gsub('\\', '/')
  )

  local handle = io.popen(cmd)
  if not handle then
    vim.notify('Failed to execute node command', vim.log.levels.WARN)
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  if result and result ~= '' then
    local ok, aliases = pcall(vim.json.decode, result)
    if ok then
      return aliases
    end
    vim.notify('Failed to parse JSON: ' .. result, vim.log.levels.WARN)
  else
    vim.notify('No output from vite config', vim.log.levels.WARN)
  end

  return nil
end

local function create_temp_jsconfig(aliases)
  if not aliases then
    return
  end

  local jsconfig = {
    compilerOptions = {
      baseUrl = '.',
      jsx = 'react',
      paths = vim.empty_dict(),
    },
  }

  -- Convert Vite aliases to jsconfig paths format
  for alias, path in pairs(aliases) do
    local clean_alias = alias .. (alias:match '/%*$' and '' or '/*')
    local clean_path = path .. (path:match '/%*$' and '' or '/*')
    jsconfig.compilerOptions.paths[clean_alias] = { clean_path }
  end

  -- Write temporary jsconfig
  local temp_jsconfig = vim.fn.getcwd() .. '/jsconfig.json'

  -- Use vim.json.encode with indent
  local content = vim.fn.json_encode(jsconfig)

  local file = io.open(temp_jsconfig, 'w')
  if file then
    file:write(content)
    file:close()
    created_temp_file = true
    return temp_jsconfig
  else
    vim.notify('Failed to create temp jsconfig', vim.log.levels.ERROR)
  end

  return nil
end

vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    if created_temp_file then
      local temp_jsconfig = vim.fn.getcwd() .. '/jsconfig.json'
      if vim.fn.filereadable(temp_jsconfig) == 1 then
        vim.fn.delete(temp_jsconfig)
      end
    end
  end,
})

return {
  'williamboman/mason-lspconfig.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'williamboman/mason.nvim',
    'neovim/nvim-lspconfig',
    'j-hui/fidget.nvim',
  },
  config = function()
    require('fidget').setup {
      notification = { window = { winblend = 0 } },
    }
    require('mason').setup {
      ui = {
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    }
    require('mason-lspconfig').setup {
      automatic_install = true,
      ensure_installed = { 'vtsls', 'bashls', 'cssls', 'lua_ls', 'tailwindcss' },
      handlers = {
        function(name)
          require('lspconfig')[name].setup {}
        end,

        --[[ ['tsserver'] = function()
          local lspconfig = require 'lspconfig'
          local util = require 'lspconfig.util'
          lspconfig.tsserver.setup {
            root_dir = util.root_pattern '.git',
            path = '$HOME/.local/share/pnpm/tsc',
            on_attach = function(client)
              client.server_capabilities.semanticTokensProvider = nil
              client.capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
            end,
          }
        end, ]]

        ['vtsls'] = function()
          local lspconfig = require 'lspconfig'
          lspconfig.configs = require('vtsls').lspconfig

          local has_jsconfig = vim.fn.filereadable(vim.fn.getcwd() .. '/jsconfig.json') == 1
          local has_tsconfig = vim.fn.filereadable(vim.fn.getcwd() .. '/tsconfig.json') == 1

          local temp_jsconfig = nil
          if not has_jsconfig and not has_tsconfig then
            local aliases = get_vite_aliases()
            temp_jsconfig = create_temp_jsconfig(aliases)
          end

          lspconfig.vtsls.setup {
            refactor_auto_rename = true,
            experimental = {
              completion = { enableServerSideFuzzyMatch = false, entriesLimit = 10, includePackageJsonAutoImports = 'off' },
            },
            init_options = temp_jsconfig and {
              preferences = {
                importModuleSpecifierPreference = 'relative',
              },
            } or nil,
            settings = temp_jsconfig and {
              typescript = {
                tsserver = {
                  configFile = temp_jsconfig,
                },
              },
              javascript = {
                tsserver = {
                  configFile = temp_jsconfig,
                },
              },
            } or nil,
            typescript = {
              inlayHints = {
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          }
        end,

        ['cssls'] = function()
          local lspconfig = require 'lspconfig'
          lspconfig.cssls.setup {
            settings = {
              css = { validate = true },
              scss = { validate = true },
              less = { validate = true },
            },
          }
        end,

        ['tailwindcss'] = function()
          local lspconfig = require 'lspconfig'
          local util = require 'lspconfig.util'
          lspconfig.tailwindcss.setup {
            validate = true,
            root_dir = util.root_pattern('tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts'),
          }
        end,

        ['lua_ls'] = function()
          local lspconfig = require 'lspconfig'
          lspconfig.lua_ls.setup {
            settings = {
              Lua = { diagnostics = { globals = { 'vim' } } },
            },
          }
        end,
      },
    }

    local signs = { Error = ' ', Warning = ' ', Warn = ' ', Hint = ' ', Info = ' ', Information = ' ' }
    for type, icon in pairs(signs) do
      local hl = 'DiagnosticSign' .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
    end

    vim.diagnostic.config {
      virtual_text = true,
      underline = true,
      update_in_insert = true,
      check_current_line = true,
      severity_sort = true,
      signs = true,
      float = {
        style = 'minimal',
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
      },
    }

    -- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
    -- Also hides the text at the bottom, see https://github.com/neovim/neovim/issues/20457#issuecomment-1266782345
    vim.lsp.handlers['textDocument/hover'] = function(_, result, ctx, config)
      config = config or {}
      config.focus_id = ctx.method
      config.border = 'rounded'
      if not (result and result.contents) then
        return
      end
      local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        return
      end
      return vim.lsp.util.open_floating_preview(markdown_lines, 'markdown', config)
    end
  end,
  keys = {
    {
      'gd',
      function()
        vim.lsp.buf.definition()
      end,
      desc = '[G]oto [D]efinition',
    },
    {
      'gr',
      function()
        vim.lsp.buf.references()
      end,
      desc = '[G]oto [R]eferences',
    },
    {
      'K',
      function()
        vim.lsp.buf.hover { float = { border = 'rounded' } }
      end,
    },
    {
      '[d',
      function()
        vim.diagnostic.goto_prev()
      end,
    },
    {
      ']d',
      function()
        vim.diagnostic.goto_next()
      end,
    },
    {
      '<F1>',
      function()
        vim.lsp.buf.signature_help()
      end,
      desc = 'Signature [H]elp',
    },
    {
      '<leader>vws',
      --function()
      --  vim.lsp.buf.workspace_symbol()
      --end,
      '<cmd>Telescope lsp_workspace_symbols<CR>',
      desc = '[V]iew [W]orkspace [S]ymbol',
    },
    {
      '<leader>vd',
      function()
        vim.diagnostic.open_float(0, { scope = 'cursor' })
      end,
      desc = '[V]iew [D]iagnostic',
    },
    {
      '<C-Space>',
      function()
        vim.lsp.buf.code_action()
      end,
      desc = 'Code actions (VSCode)',
    },
    {
      '<leader>vca',
      function()
        vim.lsp.buf.code_action()
      end,
      desc = '[V]im [C]ode [A]ction',
    },
    {
      '<leader>vr',
      function()
        vim.lsp.buf.references()
      end,
      desc = '[Vim] [R]efrences',
    },
    {
      '<leader>vrn',
      function()
        vim.lsp.buf.rename()
      end,
      desc = '[Vim] [R]e[N]ame',
    },
  },
}
