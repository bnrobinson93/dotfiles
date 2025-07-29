return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      background = {
        light = "latte",
        dark = "mocha",
      },
      custom_highlights = function(colors)
        return {
          ["@function"] = { fg = colors.blue, style = { "italic" } },
          ["@function.call"] = { fg = colors.blue, style = { "italic" } },
          ["@lsp.mod.declaration"] = { fg = colors.blue, style = { "italic" } },
          ["@variable.builtin"] = { fg = colors.teal, style = { "italic" } },
          ["@variable.member"] = { fg = colors.yellow, style = { "italic" } },
          ["String"] = { fg = colors.flamingo },
        }
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
