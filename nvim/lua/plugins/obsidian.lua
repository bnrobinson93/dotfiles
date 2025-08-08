local vault_path = vim.fn.expand("~") .. "/Documents/Vault"

return {
  {
    -- old: epwalsh/obsidian.nvim
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        { name = "primary", path = vault_path },
      },
      completion = {
        blink = true,
        min_chars = 2,
      },
      daily_notes = {
        folder = "Periodic/Daily",
        date_format = "%Y-%m-%d",
        template = "daily.md",
      },
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
      new_notes_location = "notes_subdir",
      notes_subdir = "0-Inbox",
      note_id_func = function(title)
        local titleToUse = ""
        if title ~= nil then
          titleToUse = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          titleToUse = tostring(os.time()) .. "-"
          for _ = 1, 4 do
            titleToUse = titleToUse .. "-" .. string.char(math.random(65, 90))
          end
        end
        return titleToUse
      end,
      note_frontmatter_func = function(note)
        local now = os.date("%Y-%m-%dT%H:%M")
        -- NOTE: the `note.metadata` object contains ONLY:
        -- created, updated, and author

        -- Start by cloning that object
        local out = vim.tbl_deep_extend("force", {}, note.metadata or {})

        -- Add things I may want
        if note.title then
          out.title = note.title
        end
        if note.url then
          out.url = note.url
        end

        -- Update the modified time
        out.updated = now

        -- More things I may want
        if note.tags then
          out.tags = note.tags
        end
        if note.aliases and note.aliases.len > 0 then
          out.aliases = note.aliases
        end

        -- return the final result
        return out
      end,
      ui = { enable = false },
      attachments = {
        img_folder = "resources/attachments",
      },
    },
    config = function()
      local function wrap_selection(before, after)
        local mode = vim.api.nvim_get_mode().mode
        local bufnr = 0

        if mode == "v" or mode == "V" then
          -- Visual mode: wrap the currently selected text
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

          -- Exit visual mode first
          vim.cmd("normal! \27") -- ESC to exit visual mode

          -- Insert the wrapper text (end first to preserve positions)
          vim.api.nvim_buf_set_text(bufnr, end_row, end_col, end_row, end_col, { after })
          vim.api.nvim_buf_set_text(bufnr, start_row, start_col, start_row, start_col, { before })
        elseif mode == "n" then
          -- Normal mode: wrap the current WORD (cWORD equivalent)
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local row = cursor_pos[1] - 1
          local col = cursor_pos[2]

          -- Get the current line
          local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]

          -- Find word boundaries (WORD = non-whitespace sequence)
          local word_start = col
          local word_end = col

          -- Find start of word
          while word_start > 0 and line:sub(word_start, word_start):match("%S") do
            word_start = word_start - 1
          end
          if word_start == 0 or line:sub(word_start, word_start):match("%s") then
            word_start = word_start + 1
          end

          -- Find end of word
          while word_end <= #line and line:sub(word_end + 1, word_end + 1):match("%S") do
            word_end = word_end + 1
          end

          -- Adjust for 0-based indexing
          word_start = word_start - 1

          -- Insert wrapper text
          vim.api.nvim_buf_set_text(bufnr, row, word_end, row, word_end, { after })
          vim.api.nvim_buf_set_text(bufnr, row, word_start, row, word_start, { before })
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
        wrap_selection("__", "__")
      end

      vim.keymap.set({ "n", "v", "i" }, "<C-b>", bold, { desc = "Bold", buffer = true })
      vim.keymap.set({ "n", "v", "i" }, "<C-i>", italics, { desc = "Italics", buffer = true })
    end,
    keys = {
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
