return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      local markdownlint_config_files = {
        ".markdownlint.json",
        ".markdownlint.jsonc",
        ".markdownlint.yaml",
        ".markdownlint.yml",
        ".markdownlint-cli2.jsonc",
        ".markdownlint-cli2.yaml",
        ".markdownlint-cli2.yml",
      }

      local function markdownlint_config(dirname)
        local config_root = vim.fs.root(dirname, function(name)
          return vim.tbl_contains(markdownlint_config_files, name)
        end)

        if config_root then
          for _, name in ipairs(markdownlint_config_files) do
            local candidate = vim.fs.joinpath(config_root, name)
            if vim.uv.fs_stat(candidate) then
              return candidate
            end
          end
        end

        return vim.fn.stdpath("config") .. "/lua/plugins/fallback-config/markdownlint-cli2.jsonc"
      end

      local function prettier_config_root(dirname)
        return vim.fs.root(dirname, function(name, path)
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
      end

      local prettier_dotfiles_config = vim.fn.stdpath("config") .. "/lua/plugins/fallback-config/prettier.json"

      opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
        prettier = {
          prepend_args = function(_, ctx)
            if prettier_config_root(ctx.dirname) then
              return {}
            end

            if vim.uv.fs_stat(prettier_dotfiles_config) then
              return { "--config", prettier_dotfiles_config }
            end

            return {}
          end,
          condition = function(_, ctx)
            if prettier_config_root(ctx.dirname) then
              return true
            end

            return vim.fs.root(ctx.dirname, { ".git", ".jj" }) == nil
          end,
        },
        ["markdownlint-cli2"] = {
          args = function(_, ctx)
            return { "$FILENAME", "--config", markdownlint_config(ctx.dirname), "--fix" }
          end,
          condition = function()
            return true
          end,
        },
      })
    end,
  },
}
