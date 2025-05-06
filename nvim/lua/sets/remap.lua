vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('v', '<c-j>', ":m '>+1<CR>==gv=gv")
vim.keymap.set('v', '<c-k>', ':m .-2<CR>==gv=gv')

vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines and keep cursor in place' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up half a page and center' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down half a page and center' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Search next and center in screen' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Search previous and center in screen' })

-- greatest remap ever
vim.keymap.set('x', '<leader>p', [["_dP]], { desc = 'Paste without yanking' })
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]], { desc = 'Delete without yanking' })

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]], { desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>Y', [["+Y]], { desc = 'Yank entire line to system clipboard' })

vim.keymap.set('i', '<C-c>', '<Esc>', { desc = 'Esc from insert mode (similar to quit in bash)' })

vim.keymap.set('n', 'Q', '<nop>', { desc = 'nop' })
vim.keymap.set('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer<CR>', { desc = 'Open tmux sessionizer' })
vim.keymap.set('n', '<C-b>', '<cmd>Telescope buffers<CR>', { desc = 'View open buffers within telescope' })
vim.keymap.set('n', '<leader>f', function()
  vim.lsp.buf.format()
end, { desc = 'Format current buffer with LSP' })

vim.keymap.set('n', '<C-t>', '<cmd>tabnew<CR>', { desc = 'Open new tab' })

-- vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]]
vim.cmd [[ command W write ]]

vim.keymap.set("n", "<leader>k", "<cmd>cnext<CR>zz", { desc = 'Go to next quickfix location'})
vim.keymap.set("n", "<leader>j", "<cmd>cprev<CR>zz", { desc = 'Go to previous quickfix location'})
-- vim.keymap.set('n', '<leader>K', '<cmd>lnext<CR>zz', { desc = 'Jump to next location' })
-- vim.keymap.set('n', '<leader>J', '<cmd>lprev<CR>zz', { desc = 'Jump to previous location' })

vim.keymap.set('n', '<leader>w', '<cmd>set wrap!<CR>', { desc = 'Toggle word wrap' })
vim.keymap.set('n', '<leader>l', '<cmd>set relativenumber!<CR>', { desc = 'Toggle relative line numbers' })

vim.keymap.set('n', '<leader>s', [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word under cursor' })
vim.keymap.set('n', '<leader>S', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace all instances of word under cursor' })
