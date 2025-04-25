return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  event = 'BufReadPost',
  init = function()
    vim.o.foldenable = true
    vim.o.foldcolumn = 'auto:2'
    vim.o.foldlevelstart = 99
    vim.o.fillchars = 'eob: ,fold: ,foldopen:,foldsep:│,foldclose:'
    vim.o.foldtext = ''
  end,
  opts = {
    provider_selector = function()
      return { 'lsp', 'indent' }
    end,
  },
  keys = {
    {
      'zR',
      function()
        require('ufo').openAllFolds()
      end,
      mode = { 'n' },
      desc = 'Open All Folds',
    },
    {
      'zM',
      function()
        require('ufo').closeAllFolds()
      end,
      mode = { 'n' },
      desc = 'Close All Folds',
    },
    {
      'zK',
      function()
        local winid = require('ufo').peekFoldedLinesUnderCursor()
        if not winid then
          return vim.lsp.huf.hover()
        end
      end,
      mode = { 'n' },
      desc = 'Peek Folded Lines Under Cursor',
    },
  },
}
