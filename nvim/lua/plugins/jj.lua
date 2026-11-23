local exeExists = vim.fn.executable("jj") ~= 0

local function start_path()
  local arg = vim.fn.argv(0)
  if type(arg) == "string" and arg ~= "" then
    return vim.fn.fnamemodify(arg, ":p")
  end
  return vim.fn.getcwd()
end

local function detect_vcs(path)
  if exeExists and vim.fs.root(path, ".jj") then
    return "jj"
  end
  if vim.fs.root(path, ".git") then
    return "git"
  end
  return nil
end

function JJ_exists()
  return detect_vcs(start_path()) == "jj"
end

return {
  {
    "bnrobinson93/jj-signs.nvim",
    event = "LazyFile",
    cond = JJ_exists,
    opts = {},
  },

  {
    "lewis6991/gitsigns.nvim",
    cond = function()
      return detect_vcs(start_path()) == "git"
    end,
    opts = function(_, opts)
      local lazyvim_on_attach = opts.on_attach
      opts.on_attach = function(bufnr)
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        if filepath ~= "" and detect_vcs(filepath) ~= "git" then
          return false
        end
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
        { "<leader>jh", icon = { icon = "󰈙", color = "orange" } },
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
