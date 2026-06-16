local M = {}

function M.find_config(dirname, files, package_key)
  return dirname and vim.fs.root(dirname, function(name, path)
    if package_key and name == "package.json" then
      local file = io.open(vim.fs.joinpath(path, name), "r")
      if not file then
        return false
      end
      local ok, pkg = pcall(vim.json.decode, file:read("*all"))
      file:close()
      return ok and pkg and pkg[package_key] ~= nil
    end
    return vim.tbl_contains(files, name)
  end)
end

function M.current_dirname()
  local filename = vim.api.nvim_buf_get_name(0)
  return filename ~= "" and vim.fs.dirname(filename) or vim.fn.getcwd()
end

M.biome_config_files = { "biome.json", "biome.jsonc" }

function M.find_biome_config(dirname)
  return M.find_config(dirname, M.biome_config_files)
end

M.markdownlint_config_files = {
  ".markdownlint.json",
  ".markdownlint.jsonc",
  ".markdownlint.yaml",
  ".markdownlint.yml",
  ".markdownlint-cli2.jsonc",
  ".markdownlint-cli2.yaml",
  ".markdownlint-cli2.yml",
}

function M.find_markdownlint_config(dirname)
  local config_root = vim.fs.root(dirname, function(name)
    return vim.tbl_contains(M.markdownlint_config_files, name)
  end)

  if config_root then
    for _, name in ipairs(M.markdownlint_config_files) do
      local candidate = vim.fs.joinpath(config_root, name)
      if vim.uv.fs_stat(candidate) then
        return candidate
      end
    end
  end

  return vim.fn.stdpath("config") .. "/lua/plugins/fallback-config/markdownlint-cli2.jsonc"
end

return M
