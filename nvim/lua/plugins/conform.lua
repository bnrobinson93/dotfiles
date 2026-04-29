return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        prettier = {
          prepend_args = function(_, ctx)
            local has_local_config = vim.fs.root(ctx.dirname, function(name, path)
              if name == "package.json" then
                local file = io.open(vim.fs.joinpath(path, name), "r")
                if not file then
                  return false
                end

                local ok, package_json = pcall(vim.json.decode, file:read("*all"))
                file:close()
                return ok and package_json and package_json.prettier ~= nil
              end

              return vim.tbl_contains({
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
              }, name)
            end)

            if has_local_config then
              return {}
            end

            return {
              "--config",
              vim.fn.stdpath("config") .. "/utils/linter-config/prettier.json",
            }
          end,
        },
      },
    },
  },
}
