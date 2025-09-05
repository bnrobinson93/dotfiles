return {
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "allaman/emoji.nvim", "saghen/blink.compat" },
    opts = function(_, opts)
      opts.keymap = {
        preset = "super-tab",
        ["<Tab>"] = {
          require("blink.cmp.keymap.presets").get("super-tab")["<Tab>"][1],
          require("lazyvim.util.cmp").map({ "snippet_forward", "ai_accept" }),
          "fallback",
        },
      }
      opts.sources.compat = { "emoji" }
      table.insert(opts.sources.default, "emoji")
    end,
  },
}
