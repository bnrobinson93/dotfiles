return {
  {
    "nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },

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
    opts = function(_, opts)
      opts.image = {
        enabled = true,
        doc = { enabled = true, inline = true },
        resolve = function(path, src)
          if require("obsidian.api").path_is_note(path) then
            return require("obsidian.api").resolve_image_path(src)
          end
        end,
      }

      opts.picker.matcher = { frecency = true }

      opts.scroll = { enabled = false }

      table.insert(opts.dashboard.preset.keys, 3, {
        icon = "󰃭 ",
        key = "o",
        desc = "Today's Note",
        action = "ObsidianTodayAuto",
      })

      return opts
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
