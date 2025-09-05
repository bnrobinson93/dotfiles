return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown", "Avante", "vimwiki", "help", "copilot-chat" },
    opts = {
      file_types = { "markdown", "Avante" },
      render_modes = { "n", "c", "t" },
      checkbox = {
        enabled = true,
        unchecked = { icon = " " },
        checked = { icon = "󰄳 ", scope_highlight = "@markup.strikethrough" },
        custom = {
          todo = { raw = "[-]", rendered = " ", highlight = "DiagnosticSignError" },
          partial = { raw = "[/]", rendered = " ", highlight = "DiagnosticSignHint" },
          partial_2 = { raw = "[~]", rendered = " ", highlight = "DiagnosticSignHint" },
          priority = { raw = "[!]", rendered = "󰓏 ", highlight = "DiagnosticSignWarn" },
          priority_2 = { raw = "[*]", rendered = "󰓏 ", highlight = "DiagnosticSignWarn" },
          migrated = { raw = "[>]", rendered = " ", highlight = "DiagnosticSignWarn" },
          scheduled = { raw = "[<]", rendered = "󰥔 ", highlight = "DiagnosticSignWarn" },
          partial_parent = {
            raw = "[+]",
            rendered = "󰁊 ",
            highlight = "DiagnosticDepricated",
            scope_highlight = "@markup.strikethrough",
          },
        },
      },
      pipe_table = {
        enabled = true,
        cell = "trimmed",
        preset = "round",
      },
    },
  },
}
