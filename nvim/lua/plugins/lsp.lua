return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      bashls = {
        handlers = {
          ["textDocument/publishDiagnostics"] = function(err, res, ...)
            local file_name = vim.fn.fnamemodify(vim.uri_to_fname(res.uri), ":t")
            if string.match(file_name, "^%.env.*") then
              return
            end
            vim.lsp.diagnostic.on_publish_diagnostics(err, res, ...)
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
          },
        },
      },
    },
  },
}
