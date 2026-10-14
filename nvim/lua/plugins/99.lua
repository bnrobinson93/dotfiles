return {
  "ThePrimeagen/99",
  config = function()
    local _99 = require("99")
    local cwd = vim.uv.cwd()
    local basename = vim.fs.basename(cwd)

    _99.setup({
      logger = {
        level = _99.INFO,
        path = "/tmp/" .. basename .. ".99.debug",
        print_on_error = true,
      },
      completion = {
        source = "blink",
      },
      md_files = {
        "AGENTS.md",
        "AGENT.md",
      },
    })

    vim.keymap.set("x", "<leader>rA", _99.visual, {
      desc = "AI refactor selection",
    })
    vim.keymap.set("n", "<leader>sA", _99.search, {
      desc = "AI search codebase",
    })
    vim.keymap.set({ "n", "x" }, "<leader>rX", _99.stop_all_requests, {
      desc = "Cancel AI request",
    })
  end,
}
