return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier = {
          prepend_args = {
            "--config",
            vim.fn.stdpath("config") .. "/utils/linter-config/prettier.json",
            "--config-precedence",
            "prefer-file",
          },
        },
      },
    },
  },
}
