return {
  'mbbill/undotree', -- tre view of history
  'stevearc/dressing.nvim', -- Better select and insert boxes
  {
    'preservim/vim-pencil', -- For writing
    ft = { 'markdown', 'mkd', 'text' },
    init = function()
      vim.g['pencil#wrapModeDefault'] = 'soft'
      vim.opt.linebreak = true
    end,
    config = function()
      vim.cmd [[ call pencil#init() ]]
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
      vim.g.mkdp_markdown_css = vim.fn.stdpath 'config' .. '/catppuccin-mermaid-markdown.css'
    end,
  },
}
