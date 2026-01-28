local exeExists = false

function JjExists()
  if exeExists or vim.fn.executable("jj") == 0 then
    exeExists = true
    return false
  end

  local root = vim.fn.system({ "jj", "root" })
  if vim.v.shell_error ~= 0 or root == "" then
    return false
  end
  return true
end

return {
  {
    "folke/which-key.nvim",
    cond = JjExists,
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)

      wk.add({
        { "<leader>j", group = "JJ VCS", icon = "" },
        { "<leader>jj", icon = { icon = "", color = "azure" } },
        { "<leader>jL", icon = { icon = "", color = "blue" } },
        { "<leader>jt", icon = { icon = "󰓂", color = "cyan" } },
        { "<leader>jT", icon = { icon = "󰓂", color = "cyan" } },
        { "<leader>js", icon = { icon = "󱖫", color = "green" } },
        { "<leader>jf", icon = { icon = "", color = "blue" } },
        { "<leader>jd", icon = { icon = "", color = "orange" } },
        { "<leader>jD", icon = { icon = "", color = "red" } },
      })
    end,
  },

  {
    "NicolasGB/jj.nvim",
    version = "*",
    cond = JjExists,
    opts = {
      cmd = {
        describe = {
          editor = {
            type = "buffer",
            keymaps = { close = { "<Esc>", "<C-c>", "q" } },
          },
        },
      },
      highlights = {
        modified = "DiffChange",
        added = "DiffAdd",
        deleted = "DiffDelete",
      },
    },
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
