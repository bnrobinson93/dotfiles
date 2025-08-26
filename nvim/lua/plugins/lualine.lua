return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      section_separators = { left = "", right = "" },
      component_separators = "|",
    },
    extensions = { "nvim-dap-ui", "quickfix", "trouble" },
    sections = {
      lualine_b = {
        "branch",
        LazyVim.lualine.root_dir(),
        "filename",
        { "diagnostics", sources = { "nvim_diagnostic", "nvim_workspace_diagnostic" }, update_in_insert = false },
        "nvim-dap-ui",
        "quickfix",
      },
      lualine_c = {
        {
          "filetype",
          separator = "",
          color = { fg = "#585b70" },
          padding = { left = 2, right = 0 },
          colored = false,
          icon_only = true,
        },
        {
          "lsp_status",
          separator = "",
          color = function()
            return { fg = Snacks.util.color("NonText") }
          end,
          padding = { left = 0, right = 1 },
          icon = "",
          symbols = {
            spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
            done = "",
            separator = ", ",
          },
          ignore_lsp = { "GitHub Copilot", "copilot" },
        },
      },
      lualine_z = {},
    },
  },
}
