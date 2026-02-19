return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      harper_ls = {
        filetypes = { "markdown", "text" },
        settings = {
          ["harper-ls"] = {
            userDictPath = vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
          },
        },
      },
    },
  },
}
