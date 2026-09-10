return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      custom_highlights = function(colors)
        return {
          Comment = { style = { "italic" } },
          ["@comment"] = { style = { "italic" } },
          ["@comment.documentation"] = { style = { "italic" } },
          ["@function"] = { fg = colors.blue, style = { "italic" } },
          ["@function.call"] = { fg = colors.blue, style = { "italic" } },
          ["@lsp.mod.declaration"] = { fg = colors.blue, style = { "italic" } },
          ["@variable.builtin"] = { fg = colors.teal, style = { "italic" } },
          ["@variable.member"] = { fg = colors.yellow, style = { "italic" } },
          String = { fg = colors.flamingo },
        }
      end,
    },
  },

  {
    "tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "storm",
      cache = true,
      transparent = true,
      on_highlights = function(hl, c)
        hl.Comment = { italic = true }
        hl["@comment"] = { italic = true }
        hl["@comment.documentation"] = { italic = true }
        hl["@function"] = { fg = c.blue, italic = true }
        hl["@function.call"] = { fg = c.blue, italic = true }
        hl["@lsp.mod.declaration"] = { fg = c.blue, italic = true }
        hl["@variable.builtin"] = { fg = c.teal, italic = true }
        hl["@variable.member"] = { fg = c.yellow, italic = true }
        hl.String = { fg = c.blue1 }
      end,
    },
  },

  -- Configure LazyVim to use catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-nvim",
    },
  },
}
