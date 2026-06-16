local project = require("utils.project")

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
  return project.find_config(dirname, prettier_config_files, "prettier")
end

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters = vim.tbl_deep_extend("force", opts.formatters or {}, {
        biome = {
          -- biome.json present, or no prettier config (biome is the default)
          condition = function(_, ctx)
            return project.find_biome_config(ctx.dirname) ~= nil or find_prettier_config(ctx.dirname) == nil
          end,
        },
        prettier = {
          condition = function(_, ctx)
            return find_prettier_config(ctx.dirname) ~= nil
          end,
          prepend_args = {},
        },
        ["markdownlint-cli2"] = {
          args = function(_, ctx)
            return { "$FILENAME", "--config", project.find_markdownlint_config(ctx.dirname), "--fix" }
          end,
          condition = function()
            return true
          end,
        },
      })

      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        javascript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
      })
    end,
  },
}
