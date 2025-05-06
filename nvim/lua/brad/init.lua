return {
  'mbbill/undotree', -- tre view of history
  'stevearc/dressing.nvim', -- Better select and insert boxes
  {
    'preservim/vim-pencil', -- For writing
    ft = { 'markdown', 'mkd', 'text' },
    config = function()
      vim.g['pincel#wrapModeDefault'] = 'soft'
      vim.fn['pencil#init']()
    end,
  },
  {
    'lervag/vimtex', -- LaTeX support
    ft = { 'tex' },
    config = function()
      require 'plugins.vimtex'
    end,
  },
  {
    'iamcco/markdown-preview.nvim', -- Markdown preview
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = 'cd app && yarn install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
  },
}
