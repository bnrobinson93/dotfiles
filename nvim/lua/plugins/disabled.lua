-- Only plugins with no file of their own; the rest disable themselves next to
-- the opts you'd flip back on.
return {
  { "nvimdev/dashboard-nvim", enabled = false },
  { "folke/flash.nvim", enabled = false },
  { "akinsho/bufferline.nvim", enabled = false },
}
