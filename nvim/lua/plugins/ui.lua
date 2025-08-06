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

  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      table.insert(opts.dashboard.preset.keys, 3, {
        icon = "󰃭 ",
        key = "o",
        desc = "Today's Note",
        action = function()
          require("lazy").load({ plugins = { "obsidian.nvim" } })
          vim.cmd("Obsidian today")
        end,
      })
    end,
  },

  { "smjonas/inc-rename.nvim", opts = {
    input_buffer_type = "noice",
  } },

  {
    "preservim/vim-pencil",
    ft = { "text", "markdown" },
  },
}
