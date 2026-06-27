local exeExists = vim.fn.executable("jj") ~= 0

function JJ_exists()
  if not exeExists then
    return false
  end

  local root = vim.fn.system({ "jj", "root" })
  if vim.v.shell_error ~= 0 or root == "" then
    return false
  end
  return true
end

return {
  {
    "bnrobinson93/jj-signs.nvim",
    event = "LazyFile",
    opts = {},
  },

  -- Prevent gitsigns from attaching in JJ repos — jj-signs handles signs there.
  -- Wraps LazyVim's on_attach so keymaps still apply for pure-git repos.
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local lazyvim_on_attach = opts.on_attach
      opts.on_attach = function(bufnr)
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        if filepath ~= "" then
          local dir = vim.fn.fnamemodify(filepath, ":h")
          local result = vim.system({ "jj", "root" }, { cwd = dir }):wait()
          if result.code == 0 then
            return false -- JJ repo: let jj-signs handle it
          end
        end
        -- Pure git repo: run LazyVim's on_attach (sets keymaps etc.)
        if lazyvim_on_attach then
          return lazyvim_on_attach(bufnr)
        end
      end
    end,
  },

  {
    "JulianNymark/neojjit",
    keys = {
      {
        "<leader>jj",
        function()
          require("neojjit").open()
        end,
        desc = "Neojjit",
      },
    },
  },

  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      if not JJ_exists() then
        return
      end
      opts.spec = opts.spec or {}
      vim.list_extend(opts.spec, {
        { "<leader>j", group = "JJ VCS", icon = "" },
        { "<leader>jl", icon = { icon = "", color = "azure" } },
        { "<leader>jL", icon = { icon = "", color = "blue" } },
        { "<leader>jt", icon = { icon = "󰓂", color = "cyan" } },
        { "<leader>jT", icon = { icon = "󰓂", color = "cyan" } },
        { "<leader>js", icon = { icon = "󱖫", color = "green" } },
        { "<leader>jf", icon = { icon = "", color = "blue" } },
        { "<leader>jd", icon = { icon = "", color = "orange" } },
        { "<leader>jD", icon = { icon = "", color = "red" } },
      })
    end,
  },

  {
    "NicolasGB/jj.nvim",
    branch = "main",
    -- version = "*",
    cond = JJ_exists,
    opts = {
      cmd = {
        describe = {
          editor = {
            type = "buffer",
            keymaps = { close = { "<Esc>", "<C-c>", "q" } },
          },
        },
      },
      editor = {
        auto_insert = true,
      },
      highlights = {
        modified = "DiffChange",
        added = "DiffAdd",
        deleted = "DiffDelete",
      },
    },
  },

  {
    "julienvincent/hunk.nvim",
    cmd = { "DiffEditor" },
    config = function(_, opts)
      require("hunk").setup(opts)
    end,
    opts = {
      keys = {
        global = {
          quit = { "q" },
          accept = { "<leader><Cr>" },
        },

        tree = {
          expand_node = { "l", "<Right>" },
          collapse_node = { "h", "<Left>" },

          open_file = { "<Cr>" },

          toggle_file = { "a" },
        },

        diff = {
          toggle_hunk = { "A" },
          toggle_line = { "a" },
          toggle_line_pair = { "s" },

          prev_hunk = { "[h" },
          next_hunk = { "]h" },

          toggle_focus = { "<Tab>" },
        },
      },

      ui = {
        tree = {
          mode = "nested",
          width = 40,
        },
        layout = "vertical",
      },

      icons = {
        enable_file_icons = true,
        selected = "●",
        deselected = "○",
        partially_selected = "",

        folder_open = "",
        folder_closed = "",

        expanded = "",
        collapsed = "",
      },
    },
  },

  {
    "rafikdraoui/jj-diffconflicts",
    cmd = { "JJDiffConflicts" },
  },
}
