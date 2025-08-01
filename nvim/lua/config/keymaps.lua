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
map("n", "<leader>s", [[:s/\<<C-r><C-w>\>//gI<Left><Left><Left>]], { desc = "Replace word under cursor" })
map(
  "n",
  "<leader>S",
  [[:%s/\<<C-r><C-w>\>//gI<Left><Left><Left>]],
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
  require("lazy").load({ plugins = { "obsidian.nvim" } })

  local note_name = vim.fn.input("Enter title or path (optional): ")
  if note_name == "" or note_name == nil then
    note_name = os.date("%Y-%m-%d_%H-%M-%S")
  end

  local function create_note_with_daily_link()
    -- Step 1: Create/open daily note first (this applies template if needed)
    vim.cmd("Obsidian today")

    -- Wait for the command to complete before capturing buffer
    vim.defer_fn(function()
      local daily_buf = vim.api.nvim_get_current_buf()
      local daily_path = vim.api.nvim_buf_get_name(daily_buf)

      -- Verify we're actually in a daily note
      if not daily_path:match("daily") and not daily_path:match("Daily") then
        vim.notify("Error: Could not open daily note", vim.log.levels.ERROR)
        return
      end

      -- Step 2: Create the new note
      vim.cmd("Obsidian new " .. vim.fn.shellescape(note_name))
      local new_note_buf = vim.api.nvim_get_current_buf()
      local note_path = vim.api.nvim_buf_get_name(new_note_buf)
      local note_title = vim.fn.fnamemodify(note_path, ":t:r")

      -- Step 3: Go back to daily note and append the link
      vim.schedule(function()
        vim.api.nvim_set_current_buf(daily_buf)

        -- Get current lines and append the new note link
        local daily_lines = vim.api.nvim_buf_get_lines(daily_buf, 0, -1, false)
        local note_link = string.format("- [[%s]]", note_title)
        table.insert(daily_lines, note_link)

        -- Update and save the daily note
        vim.api.nvim_buf_set_lines(daily_buf, 0, -1, false, daily_lines)
        vim.cmd("write")

        -- Step 4: Switch back to the new note
        vim.api.nvim_set_current_buf(new_note_buf)

        vim.notify("Created note: " .. note_title)
      end)
    end, 200) -- 200ms delay to let Obsidian today complete
  end

  create_note_with_daily_link()
end, { desc = "New Obsidian Note" })
