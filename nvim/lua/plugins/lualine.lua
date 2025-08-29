local function is_jj_repo()
  local handle = io.popen("git rev-parse --show-toplevel 2>/dev/null")
  if handle then
    local git_root = handle:read("*a"):gsub("\n", "")
    handle:close()
    if git_root and git_root ~= "" then
      local jj_dir = git_root .. "/.jj"
      local f = io.open(jj_dir, "r")
      if f then
        f:close()
        return true
      end
    end
  end
  return false
end

return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      section_separators = { left = "", right = "" },
      component_separators = "|",
    },
    extensions = { "nvim-dap-ui", "quickfix", "trouble" },
    sections = {
      lualine_b = {
        {
          function()
            if is_jj_repo() then
              local handle = io.popen("jj log -r '@- & bookmarks()' -T 'bookmarks' -n1 --no-graph 2>/dev/null")
              if handle then
                local result = handle:read("*a"):gsub("\n", "")
                handle:close()
                return result ~= "" and result or "no-bookmark"
              end
              return "jj-error"
            else
              local branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
              return branch ~= "" and branch or ""
            end
          end,
          icon = "",
          separator = "|",
        },
        LazyVim.lualine.root_dir(),
        "filename",
        { "diagnostics", sources = { "nvim_diagnostic", "nvim_workspace_diagnostic" }, update_in_insert = false },
        "nvim-dap-ui",
        "quickfix",
      },
      lualine_c = {
        {
          "filetype",
          separator = "",
          color = { fg = "#585b70" },
          padding = { left = 2, right = 0 },
          colored = false,
          icon_only = true,
        },
        {
          "lsp_status",
          separator = "",
          color = function()
            return { fg = Snacks.util.color("NonText") }
          end,
          padding = { left = 0, right = 1 },
          icon = "",
          symbols = {
            spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
            done = "",
            separator = ", ",
          },
          ignore_lsp = { "GitHub Copilot", "copilot" },
        },
      },
      lualine_z = {},
    },
  },
}
