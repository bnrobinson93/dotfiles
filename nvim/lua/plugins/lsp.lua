return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      harper_ls = {
        filetypes = { "markdown", "text" },
        on_init = function(client, _)
          -- Hide INFO diagnostics for this server only (can still hover)
          vim.diagnostic.config({
            virtual_text = {
              severity = { min = vim.diagnostic.severity.WARN },
            },
          }, vim.lsp.diagnostic.get_namespace(client.id))
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
