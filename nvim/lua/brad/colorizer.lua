return {
  'NvChad/nvim-colorizer.lua',
  event = 'BufReadPre',
  opts = {
    filetypes = { '*', '!vim', '!prompt', '!popup' },
    user_default_options = {
      css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
      css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
      rgb_fn = true,
      hsl_fn = true,
      mode = 'virtualtext', --- Available modes for `mode`: foreground, background, virtualtext
      tailwind = true,
      sass = { enable = false, parsers = { 'css' } },
      virtualtext = '■',
    },
  },
}
