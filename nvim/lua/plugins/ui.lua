return {
  -- Disable the bufferline completely
  { "akinsho/bufferline.nvim", enabled = false },

  -- Configure noice to use traditional command line
  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline", -- Use traditional bottom command line instead of popup
      },
      popupmenu = {
        enabled = true,
        backend = "cmp", -- Use cmp for completion instead of noice popup
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      animate = {
        scroll = false,
        duration = 1,
        easing = "ease-out",
      },
      zen = {
        minimal = true,
        show = {
          statusline = false,
          tabline = false,
        },
      },
    },
  },
}
