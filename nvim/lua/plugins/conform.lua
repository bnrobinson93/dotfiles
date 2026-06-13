local prettier_config_files = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.yml",
  ".prettierrc.yaml",
  ".prettierrc.json5",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.toml",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
}

local function find_prettier_config(dirname)
  return vim.fs.root(dirname, function(name, path)
    if name == "package.json" then
      local file = io.open(vim.fs.joinpath(path, name), "r")
      if not file then
        return false
      end
      local ok, pkg = pcall(vim.json.decode, file:read("*all"))
      file:close()
      return ok and pkg and pkg.prettier ~= nil
    end
    return vim.tbl_contains(prettier_config_files, name)
  end)
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        biome = {
          condition = function(_, ctx)
            return vim.fs.root(ctx.dirname, { "biome.json", "biome.jsonc" }) ~= nil
          end,
        },
        prettier = {
          condition = function(_, ctx)
            return find_prettier_config(ctx.dirname) ~= nil
          end,
          prepend_args = {},
        },
      },
      formatters_by_ft = {
        javascript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
      },
    },
  },
}
