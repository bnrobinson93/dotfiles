return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = false,
        debounce = 75,
        keymap = {
          accept = "<M-a>",
          accept_word = false,
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ["."] = false,
      },
    },
  },

  -- Alternative: Supermaven (if you prefer it)
  {
    "supermaven-inc/supermaven-nvim",
    enabled = false, -- Set to true if you want to use this instead of Copilot
    opts = {
      keymaps = {
        accept_suggestion = "<A-a>",
        clear_suggestion = "<A-c>",
        next_suggestion = "<A-j>",
      },
    },
  },
}
