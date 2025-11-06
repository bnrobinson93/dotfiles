return {
  {
    "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      custom_highlights = function(colors)
        return {
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
    style = "storm",
    opts = {
      cache = true,
      transparent = true,
      on_highlights = function(hl, c)
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
      colorscheme = "catppuccin",
    },
  },
}
