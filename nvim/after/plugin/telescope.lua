local status_ok, builtin = pcall(require, 'telescope.builtin')
if not status_ok then
  vim.notify 'Unable to load telescope'
  return
end

vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<leader>ps', function()
  builtin.grep_string { search = vim.fn.input 'Grep > ' }
end)
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
