return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
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
