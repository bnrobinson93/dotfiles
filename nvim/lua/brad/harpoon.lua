return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = function()
    local harpoon = require 'harpoon'
    harpoon:setup()

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Add current file to Harpoon' })
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Toggle Harpoon list'})

    vim.keymap.set('n', '<leader>1', function()
      harpoon:list():select(1)
    end, { desc = 'Select Harpoon file 1' })
    vim.keymap.set('n', '<leader>2', function()
      harpoon:list():select(2)
    end, { desc = 'Select Harpoon file 2' })
    vim.keymap.set('n', '<leader>3', function()
      harpoon:list():select(3)
    end, { desc = 'Select Harpoon file 3' })
    vim.keymap.set('n', '<leader>4', function()
      harpoon:list():select(4)
    end, { desc = 'Select Harpoon file 4' })
    vim.keymap.set('n', '<leader>5', function()
      harpoon:list():select(5)
    end, { desc = 'Select Harpoon file 5' })
    vim.keymap.set('n', '<leader>6', function()
      harpoon:list():select(6)
    end, { desc = 'Select Harpoon file 6' })
    vim.keymap.set('n', '<leader>7', function()
      harpoon:list():select(7)
    end, { desc = 'Select Harpoon file 7' })
    vim.keymap.set('n', '<leader>8', function()
      harpoon:list():select(8)
    end, { desc = 'Select Harpoon file 8' })
    vim.keymap.set('n', '<leader>9', function()
      harpoon:list():select(9)
    end, { desc = 'Select Harpoon file 9' })
    vim.keymap.set('n', '<leader>0', function()
      harpoon:list():select(10)
    end, { desc = 'Select Harpoon file 10' })

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<C-S-P>', function()
      harpoon:list():prev()
    end, {desc = 'Go to previous file in Harpoon list'})
    vim.keymap.set('n', '<C-S-N>', function()
      harpoon:list():next()
    end, {desc = 'Go to next file in Harpoon list'})
  end,
}
