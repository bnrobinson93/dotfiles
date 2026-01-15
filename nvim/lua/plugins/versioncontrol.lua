return {
  {
    "NicolasGB/jj.nvim",
    version = "*",
    cond = function()
      if vim.fn.executable("jj") == 0 then
        return false
      end
      local root = vim.fn.system({ "jj", "root" })
      if vim.v.shell_error ~= 0 or root == "" then
        return false
      end
      return true
    end,
    opts = {},
  },
  {
    "julienvincent/hunk.nvim",
    cmd = { "DiffEditor" },
    opts = {
      keys = {
        global = {
          quit = { "q" },
          accept = { "<leader><Cr>" },
        },

        tree = {
          expand_node = { "l", "<Right>" },
          collapse_node = { "h", "<Left>" },

          open_file = { "<Cr>" },

          toggle_file = { "a" },
        },

        diff = {
          toggle_hunk = { "A" },
          toggle_line = { "a" },
          toggle_line_pair = { "s" },

          prev_hunk = { "[h" },
          next_hunk = { "]h" },

          toggle_focus = { "<Tab>" },
        },
      },

      ui = {
        tree = {
          mode = "nested",
          width = 40,
        },
        layout = "vertical",
      },

      icons = {
        enable_file_icons = true,
        selected = "●",
        deselected = "○",
        partially_selected = "",

        folder_open = "",
        folder_closed = "",

        expanded = "",
        collapsed = "",
      },
    },
  },
}
