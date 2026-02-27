return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      harper_ls = {
        filetypes = { "markdown", "text" },
        on_init = function(client, _)
          -- Hide INFO diagnostics for this server only (can still hover)
          local ns = vim.api.nvim_create_namespace("vim_lsp_diagnostics_" .. client.id)
          vim.diagnostic.config({
            virtual_text = {
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
