return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- obsidian.nvim now ships its own in-process LSP
      marksman = {
        root_dir = function(bufnr, on_dir)
          local vault = vim.fs.normalize(os.getenv("ZETTELKASTEN") or os.getenv("HOME") .. "/Documents/Vault")
          local path = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
          if path == vault or vim.startswith(path, vault .. "/") then
            return
          end
          on_dir(vim.fs.root(bufnr, { ".marksman.toml", ".git" }))
        end,
      },
      bashls = {
        handlers = {
          ["textDocument/publishDiagnostics"] = function(err, res, ...)
            -- Fallback to default handler if the payload is missing or malformed
            if err or not res or not res.uri then
              return vim.lsp.diagnostic.on_publish_diagnostics(err, res, ...)
            end

            local file_name = vim.fn.fnamemodify(vim.uri_to_fname(res.uri), ":t")
            if string.match(file_name, "^%.env.*") then
              return
            end

            return vim.lsp.diagnostic.on_publish_diagnostics(err, res, ...)
          end,
        },
      },
      harper_ls = {
        filetypes = { "markdown", "text" },
        on_init = function(client, _)
          -- Only show WARN+ inline; INFO still visible on hover
          local ns = vim.lsp.diagnostic.get_namespace(client.id)
          vim.diagnostic.config({
            virtual_text = {
              severity = { min = vim.diagnostic.severity.WARN },
            },
            signs = {
              severity = { min = vim.diagnostic.severity.WARN },
            },
          }, ns)
        end,
        settings = {
          ["harper-ls"] = {
            userDictPath = vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
            -- Inherit rule tuning from the Obsidian Harper plugin so both
            -- editors share one tuning surface. Falls back to just the
            -- nvim-only overrides when $ZETTELKASTEN / the file is missing.
            linters = (function()
              local out = {}
              local vault = vim.env.ZETTELKASTEN
              if vault and vault ~= "" then
                local p = vault .. "/.obsidian/plugins/harper/data.json"
                -- luanil drops JSON nulls (harper defaults) so only real
                -- true/false toggles survive the copy.
                local ok, data = pcall(function()
                  return vim.json.decode(table.concat(vim.fn.readfile(p), "\n"), { luanil = { object = true } })
                end)
                if ok and type(data) == "table" and type(data.lintSettings) == "table" then
                  out = vim.tbl_extend("force", out, data.lintSettings)
                end
              end
              -- nvim-only overrides win
              out.SpellCheck = false
              out.ExpandMemoryShorthands = false
              return out
            end)(),
          },
        },
      },
    },
  },
}
