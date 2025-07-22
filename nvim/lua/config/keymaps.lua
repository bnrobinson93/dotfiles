-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

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
map("n", "<leader>s", [[:s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })
map(
  "n",
  "<leader>S",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace all instances of word under cursor" }
)

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

map("n", "<C-n>", function()
  -- Make sure obsidian is available
  local ok, obsidian = pcall(require, "obsidian")
  if not ok then
    -- Fall back to normal down motion if obsidian isn't loaded
    vim.notify("Obsidian plugin not loaded", vim.log.levels.INFO)
    vim.cmd("normal! j")
    return
  end

  local client = obsidian.get_client()
  local utils = require("obsidian.util")
  local location = vim.fn.getcwd()
  local vault_path = client.current_workspace.path.filename

  local title = utils.input("Enter note's title or path (optional): ")
  if not title then
    return
  elseif title == "" then
    title = nil
  end

  local note = client:create_note({ title = title, no_write = true })
  if not note then
    vim.notify("Failed to create note", vim.log.levels.ERROR)
    return
  end

  -- Handle daily note linking
  local datetime = os.time()
  local dailyNote = client:daily_note_path(datetime)

  -- Switch to vault directory if needed for daily note operations
  if location ~= vault_path then
    vim.cmd("cd " .. vault_path)
    client:today()
    vim.cmd("cd " .. location)
  end

  -- Add link to daily note if this isn't the daily note itself
  if note.filename ~= dailyNote.filename then
    local file = io.open(dailyNote.filename, "a")
    if file then
      file:write("\n\n[[" .. (title or "Untitled") .. "]]\n")
      file:close()
    else
      vim.notify("Failed to update daily note: " .. dailyNote.filename, vim.log.levels.WARN)
    end
  end

  -- Open and setup the new note
  client:open_note(note, { sync = true })
  client:write_note_to_buffer(note, { template = "zettle" })
end, { desc = "New Obsidian Note" })
