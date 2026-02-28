return {
  {
    "nvim-mini/mini.surround",
    opts = {
      mappings = {
        add = "ys",
        delete = "ds",
        find = "gsf",
        find_left = "gsF",
        highlight = "gsh",
        replace = "cs",
        update_n_lines = "gsn",
      },
    },
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "ys", group = "surround > add" },
        { "ds", group = "surround > delete" },
        { "cs", group = "surround > change" },
      },
    },
  },
}
