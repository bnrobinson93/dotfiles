return {
  'kevinhwang91/nvim-ufo',
  dependencies = {'kevinhwang91/promise-async'},
  opts = {},
  keys = {
    {'zR', "lua=require('ufo').openAllFolds", desc = 'Open All Folds'},
    {'zM', "lua=require('ufo').closeAllFolds", desc = 'Close All Folds'}
  }
}
