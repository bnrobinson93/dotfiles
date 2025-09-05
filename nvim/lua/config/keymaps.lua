-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
vim.keymap.del("n", "H")
vim.keymap.del("n", "L")

local map = vim.keymap.set

-- Your core keymaps from sets/remap.lua
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open file explorer" })

-- Move selected lines up/down
map("v", "<c-j>", ":m '>+1<CR>==gv=gv", { desc = "Move selection down" })
map("v", "<c-k>", ":m .-2<CR>==gv=gv", { desc = "Move selection up" })

-- Better line joining and scrolling
map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor in place" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half page and center" })
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half page and center" })
map("n", "n", "nzzzv", { desc = "Search next and center" })
map("n", "N", "Nzzzv", { desc = "Search previous and center" })

-- Paste/delete without yanking
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- System clipboard
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank entire line to system clipboard" })

-- Better escape
map("i", "<C-c>", "<Esc>", { desc = "Escape from insert mode" })

-- Disable Q
map("n", "Q", "<nop>")

-- Tmux sessionizer (if you use tmux)
map("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Open tmux sessionizer" })

-- Quickfix navigation
map("n", "<leader>k", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
map("n", "<leader>j", "<cmd>cprev<CR>zz", { desc = "Previous quickfix" })

-- Toggle options
map("n", "<leader>w", "<cmd>set wrap!<CR>", { desc = "Toggle word wrap" })
map("n", "<leader>l", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative line numbers" })

-- Search and replace
-- map("n", "<leader>s", [[:s/\<<C-r><C-w>\>//gI<Left><Left><Left>]], { desc = "Replace word under cursor" })
-- map(
--   "n",
--   "<leader>S",
--   [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]],
--   { desc = "Replace all instances of word under cursor" }
-- )

-- GitHub browse (if you use gh CLI)
map({ "n", "v" }, "<F5>", function()
  local file_name = vim.fn.expand("%")
  local start_line, end_line

  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    start_line = vim.fn.line("'<")
    end_line = vim.fn.line("'>")
  else
    start_line = vim.fn.line(".")
    end_line = start_line
  end

  local gh_cmd
  if start_line == end_line then
    gh_cmd = string.format("gh browse %s:%d", vim.fn.shellescape(file_name), start_line)
  else
    gh_cmd = string.format("gh browse %s:%d-%d", vim.fn.shellescape(file_name), start_line, end_line)
  end

  local result = vim.fn.system(gh_cmd)
  if vim.v.shell_error ~= 0 then
    print("Error opening in GitHub: " .. result)
  else
    print(
      string.format("Opened %s:%d%s in GitHub", file_name, start_line, start_line == end_line and "" or "-" .. end_line)
    )
  end
end, { desc = "Open selection in GitHub" })

-- New note in Obsidian
map("n", "<C-n>", function()
  require("lazy").load({ plugins = { "obsidian.nvim" } })

  local note_name = vim.fn.input("Enter title or path (optional): ")
  if note_name == "" or note_name == nil then
    return
  end

  -- Multiple cleaning attempts
  local clean_name = note_name
  clean_name = clean_name:gsub("^'", ""):gsub("'$", "") -- Remove single quotes
  clean_name = clean_name:gsub('^"', ""):gsub('"$', "") -- Remove double quotes
  clean_name = clean_name:gsub("^%s*", ""):gsub("%s*$", "") -- Remove leading/trailing whitespace

  -- Create the new note first
  if clean_name:match("%s") then
    vim.cmd('ObsidianNew "' .. clean_name .. '"')
  else
    vim.cmd("ObsidianNew " .. clean_name)
  end

  vim.defer_fn(function()
    -- Use the cleaned name for the link
    local note_title = clean_name

    -- Handle daily note
    vim.cmd("split")
    vim.cmd("ObsidianToday")

    vim.defer_fn(function()
      local daily_buf = vim.api.nvim_get_current_buf()
      local daily_lines = vim.api.nvim_buf_get_lines(daily_buf, 0, -1, false)
      local note_link = string.format("[[%s]]", note_title)

      table.insert(daily_lines, note_link)
      vim.api.nvim_buf_set_lines(daily_buf, 0, -1, false, daily_lines)
      vim.cmd("write")
      vim.cmd("close")

      vim.notify("Created note and linked to daily: " .. note_title)
    end, 300)
  end, 500)
end, { desc = "New Obsidian Note" })
