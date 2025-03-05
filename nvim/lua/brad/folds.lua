return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async', 'nvim-treesitter/nvim-treesitter' },
  event = 'BufReadPost',
  opts = {
    provider_selector = function()
      return { 'treesitter', 'indent' }
    end,
  },
  keys = {
    { 'zR', "lua=require('ufo').openAllFolds", desc = 'Open All Folds' },
    { 'zM', "lua=require('ufo').closeAllFolds", desc = 'Close All Folds' },
  },
}
