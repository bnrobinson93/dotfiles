local lsp_names = function()
  local bufnr = vim.api.nvim_get_current_buf()

  local clients = vim.lsp.buf_get_clients(bufnr)
  if next(clients) == nil then
    return ''
  end

  local c = {}
  for _, client in pairs(clients) do
    table.insert(c, client.name)
  end
  return '[' .. table.concat(c, ',') .. ']'
end

return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'catppuccin/nvim' },
  config = function()
    local lualine = require 'lualine'
    local lazy_status = require 'lazy.status'
    lualine.setup {
      options = {
        icons_enabled = true,
        theme = 'catppuccin',
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'filename', 'branch', 'diff', 'diagnostics' },
        lualine_c = { lsp_names },
        lualine_x = {
          { lazy_status.updates, cond = lazy_status.has_updates, color = { fg = 'orange' } },
          'encoding',
          'fileformat',
          'filetype',
        },
      },
    }
  end,
}
