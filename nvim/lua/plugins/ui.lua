return {
  -- Disable the bufferline completely
  { "akinsho/bufferline.nvim", enabled = false },

  -- Configure noice to use traditional command line
  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline_popup", -- Use traditional: cmdline
      },
      presets = {
        inc_rename = true,
        lsp_doc_border = true,
        command_palette = false,
        bottom_search = false,
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      styles = { notification_history = { wo = { wrap = true } } },
      scroll = { enabled = false },
      zen = {
        minimal = true,
        show = {
          statusline = false,
          tabline = false,
        },
      },
    },
  },

  { "smjonas/inc-rename.nvim", opts = {
    input_buffer_type = "noice",
  } },
}
