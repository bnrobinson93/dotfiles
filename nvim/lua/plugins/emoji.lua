return {
  "allaman/emoji.nvim",
  version = "5.0.0",
  ft = "markdown",
  opts = {
    enable_cmp_integration = true,
    ui_select = true,
  },
  keys = {
    "<leader>se",
    "<cmd>Emoji insert<cr>",
    mode = { "v", "x", "n" },
    desc = "Search & Insert Emoji",
  },
}
