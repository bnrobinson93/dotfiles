vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('v', '<c-j>', ":m '>+1<CR>==gv=gv")
vim.keymap.set('v', '<c-k>', ':m .-2<CR>==gv=gv')

vim.keymap.set('n', 'J', 'mzJ`z')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- greatest remap ever
vim.keymap.set('x', '<leader>p', [["_dP]])
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

vim.keymap.set('i', '<C-c>', '<Esc>')

vim.keymap.set('n', 'Q', '<nop>')
vim.keymap.set('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer<CR>')
vim.keymap.set('n', '<C-b>', '<cmd>Telescope buffers<CR>')
vim.keymap.set('n', '<leader>f', function()
  vim.lsp.buf.format()
end)

vim.keymap.set('n', '<C-t>', '<cmd>tabnew<CR>')

-- vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]]
vim.cmd [[ command W write ]]

--vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
--vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz')

vim.keymap.set('n', '<leader>w', '<cmd>set wrap!<CR>')
vim.keymap.set('n', '<leader>l', '<cmd>set relativenumber!<CR>')

vim.keymap.set('n', '<leader>s', [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set('n', '<leader>S', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
