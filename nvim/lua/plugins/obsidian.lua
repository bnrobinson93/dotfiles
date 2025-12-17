local vault_path = vim.fn.expand(os.getenv("ZETTELKASTEN") or "~/Documents/Vault")

local function wrap_selection(before, after)
  local mode = vim.api.nvim_get_mode().mode
  local bufnr = 0

  if mode == "v" or mode == "V" then
    -- Visual mode: wrap the currently selected text or unwrap if already wrapped
    -- Get current visual selection bounds
    local start_row = vim.fn.line("v") - 1
    local start_col = vim.fn.col("v") - 1
    local end_row = vim.fn.line(".") - 1
    local end_col = vim.fn.col(".")

    -- Ensure start comes before end (in case selection was made backwards)
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
      start_row, end_row = end_row, start_row
      start_col, end_col = end_col, start_col
    end

    -- Get the text around the selection to check for existing markers
    local line_start = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
    local line_end = start_row == end_row and line_start
      or (vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or "")

    local before_len = #before
    local after_len = #after
    local has_before = start_col >= before_len and line_start:sub(start_col - before_len + 1, start_col) == before
    local has_after = end_col + after_len <= #line_end and line_end:sub(end_col + 1, end_col + after_len) == after

    -- Exit visual mode first
    vim.cmd("normal! \27") -- ESC to exit visual mode

    if has_before and has_after then
      -- Remove existing markers
      vim.api.nvim_buf_set_text(bufnr, end_row, end_col, end_row, end_col + after_len, {})
      vim.api.nvim_buf_set_text(bufnr, start_row, start_col - before_len, start_row, start_col, {})
    else
      -- Add markers
      vim.api.nvim_buf_set_text(bufnr, end_row, end_col, end_row, end_col, { after })
      vim.api.nvim_buf_set_text(bufnr, start_row, start_col, start_row, start_col, { before })
    end
  elseif mode == "n" then
    -- Normal mode: wrap the current WORD (cWORD equivalent) or unwrap if already wrapped
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local row = cursor_pos[1] - 1
    local col = cursor_pos[2]

    -- Get the current line
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    if #line == 0 then
      return
    end

    -- Ensure cursor is within line bounds
    col = math.min(col, #line - 1)

    -- Find the actual WORD boundaries (all non-whitespace)
    local word_start = col + 1 -- Convert to 1-based for string operations
    local word_end = col + 1

    -- If we're on whitespace, find the next word
    if line:sub(word_start, word_start):match("%s") then
      while word_start <= #line and line:sub(word_start, word_start):match("%s") do
        word_start = word_start + 1
      end
      if word_start > #line then
        return
      end -- No word found
      word_end = word_start
    end

    -- Find start of WORD (move left while non-whitespace)
    while word_start > 1 and line:sub(word_start - 1, word_start - 1):match("%S") do
      word_start = word_start - 1
    end

    -- Find end of WORD (move right while non-whitespace)
    while word_end <= #line and line:sub(word_end, word_end):match("%S") do
      word_end = word_end + 1
    end
    word_end = word_end - 1 -- Back to last non-whitespace character

    -- Validate boundaries
    if word_start > word_end or word_start < 1 or word_end > #line then
      return -- Invalid word boundaries
    end

    -- Convert to 0-based for buffer operations
    local word_start_0 = word_start - 1
    local word_end_0 = word_end -- This is now the position after the last character

    -- Extract the current WORD
    local current_word = line:sub(word_start, word_end)
    local before_len = #before
    local after_len = #after

    -- Check if the word already has the markers
    local has_markers = #current_word >= before_len + after_len
      and current_word:sub(1, before_len) == before
      and current_word:sub(-after_len) == after

    if has_markers then
      -- Remove the markers from within the word
      local inner_text = current_word:sub(before_len + 1, -after_len - 1)
      vim.api.nvim_buf_set_text(bufnr, row, word_start_0, row, word_end_0, { inner_text })
    else
      -- Add markers around the entire word
      local wrapped_text = before .. current_word .. after
      vim.api.nvim_buf_set_text(bufnr, row, word_start_0, row, word_end_0, { wrapped_text })
    end
  elseif mode == "i" then
    -- Insert mode: insert wrapper and position cursor in the middle
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local row = cursor_pos[1] - 1
    local col = cursor_pos[2]

    -- Insert the wrapper text
    local text = before .. after
    vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { text })

    -- Move cursor to the middle (after the 'before' text)
    vim.api.nvim_win_set_cursor(0, { row + 1, col + #before })
  end
end

local bold = function()
  wrap_selection("**", "**")
end

local italics = function()
  wrap_selection("_", "_")
end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    priority = 100,
    ft = "markdown",
    opts = {
      attachments = {
        confirm_img_paste = true,
        img_folder = "resources/attachments",
      },
      workspaces = {
        {
          name = "primary",
          path = vault_path,
          overrides = {
            notes_subdir = "0-Inbox",
          },
        },
      },
      completion = {
        blink = true,
        nvim_cmp = false,
        min_chars = 2,
        create_new = false,
      },
      checkbox = {
        order = { " ", "x", "-", "/", "~", "!", "*", ">", "<", "+" },
      },
      daily_notes = {
        folder = "Periodic/Daily",
        date_format = "%Y-%m-%d",
        template = "Daily-nvim Template.md",
      },
      footer = { enabled = false },
      new_notes_location = "notes_subdir",
      note_frontmatter_func = function(note)
        local now = os.date("%Y-%m-%dT%H:%M")
        -- NOTE: the `note.metadata` object contains ONLY:
        -- created, updated, and author

        -- Start by cloning that object
        local out = vim.tbl_deep_extend("force", {}, note.metadata or {})

        -- Add things I may want
        if note.url then
          out.url = note.url
        end

        -- Update the modified time
        out.updated = now

        -- More things I may want
        if note.tags then
          out.tags = note.tags
        end
        if note.aliases then
          out.aliases = note.aliases
        end

        -- return the final result
        return out
      end,
      note_id_func = function(title)
        if title ~= nil then
          -- Remove quotes and only problematic filesystem characters, keep spaces
          local cleaned = title:gsub("^['\"]", ""):gsub("['\"]$", "") -- Remove surrounding quotes
          cleaned = cleaned:gsub('[<>:"/\\|?*]', "") -- Remove filesystem-unsafe chars
          cleaned = cleaned:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
          return cleaned
        else
          -- Fallback for notes without titles
          return tostring(os.time())
        end
      end,
      templates = {
        folder = "resources/templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        substitutions = {
          datetime = function()
            return os.date("%Y%m%d%H%M%S", os.time())
          end,
        },
      },
      ui = { enable = false },
      wiki_link_func = "use_alias_only",
    },
    keys = {
      { "<leader>cb", bold, desc = "Bold", mode = { "n", "v" }, buffer = true },
      { "<leader>ci", italics, desc = "Italics", mode = { "n", "v" }, buffer = true },
      {
        "<F1>",
        function()
          -- Your footnote logic here (from your obsidian config)
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local max_footnote = 0

          for _, line in ipairs(lines) do
            for num in line:gmatch("%[%^(%d+)%]") do
              max_footnote = math.max(max_footnote, tonumber(num))
            end
          end

          local next_footnote = max_footnote + 1
          local footnote_text = "[^" .. next_footnote .. "]"
          vim.api.nvim_put({ footnote_text }, "c", false, true)

          vim.cmd("normal! m'")

          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local para_start = cursor_pos[1]
          local para_end = cursor_pos[1]

          while para_start > 1 and lines[para_start - 1] ~= "" do
            para_start = para_start - 1
          end

          while para_end < #lines and lines[para_end + 1] ~= "" do
            para_end = para_end + 1
          end

          local footnote_end = para_end

          while
            footnote_end + 2 <= #lines
            and lines[footnote_end + 1] == ""
            and lines[footnote_end + 2]:match("^%[%^%d+%]:")
          do
            footnote_end = footnote_end + 2
          end

          local insertion_line = footnote_end
          local reftext = "[^" .. next_footnote .. "]: "
          vim.api.nvim_buf_set_lines(0, insertion_line, insertion_line, false, { "", reftext })
          insertion_line = insertion_line + 2

          vim.api.nvim_win_set_cursor(0, { insertion_line, string.len(reftext) + #tostring(next_footnote) })
          vim.cmd("startinsert")
        end,
        desc = "Insert footnote",
        ft = "markdown",
        mode = "i",
      },
    },
  },
}
