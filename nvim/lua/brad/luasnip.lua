local function get_subdirectories(path)
  local subdirs = {}
  local files = vim.fn.readdir(path)
  for _, file in ipairs(files) do
    if vim.fn.isdirectory(path .. "/" .. file) == 1 then
      table.insert(subdirs, path .. "/" .. file)
      local subsubdirs = get_subdirectories(path .. "/" .. file)
      for _, subsubdir in ipairs(subsubdirs) do
        table.insert(subdirs, subsubdir)
      end
    end
  end
  return subdirs
end

local snippet_paths = { vim.fn.stdpath("config") .. "/snippets" }

local subdirs = get_subdirectories(vim.fn.stdpath("config") .. "/snippets")
for _, subdir in ipairs(subdirs) do
  table.insert(snippet_paths, subdir)
end

return {
  'L3MON4D3/LuaSnip',
  event = 'InsertEnter',
  dependencies = { 'rafamadriz/friendly-snippets' },
  build = 'make install_jsregexp',
  config = function()
    require('luasnip').filetype_extend('lua', { 'lua', 'luadoc' })
    require('luasnip').filetype_extend('javascript', { 'javascript' })
    require('luasnip').filetype_extend('typescript', { 'typescript' })
    require('luasnip').filetype_extend('javascriptreact', { 'javascript', 'react', 'jsdoc', 'react-es7', 'next' })
    require('luasnip').filetype_extend('typescriptreact', { 'typescript', 'react-ts', 'tsdoc', 'next-ts' })
    require('luasnip.loaders.from_vscode').lazy_load()
    require('luasnip.loaders.from_vscode').lazy_load { paths = snippet_paths }
  end,
}
