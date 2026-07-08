local vault_path = os.getenv("ZETTELKASTEN") or os.getenv("HOME") .. "/Documents/Vault"
local sprint_anchor_date = { year = 2026, month = 4, day = 2 }
local sprint_anchor_number = 4
local sprint_duration_days = 28
local sprint_overrides = {}

local function in_date_range(now, range_start, range_end)
  return now >= range_start and now <= range_end
end

local function current_sprint_number(now)
  now = now or os.time()

  for _, override in ipairs(sprint_overrides) do
    local range_start = os.time(override.start)
    local range_end = os.time(override.finish)
    if in_date_range(now, range_start, range_end) then
      return override.number
    end
  end

  local anchor = os.time(sprint_anchor_date)
  local days_since_anchor = math.floor((now - anchor) / 86400)
  local sprint_offset = math.floor(days_since_anchor / sprint_duration_days)
  return sprint_anchor_number + sprint_offset
end

local function template_title(ctx)
  if ctx and ctx.partial_note then
    local title = ctx.partial_note:display_name()
    if title and title ~= "" then
      return title
    end
  end
  return ""
end

local function yaml_string(value)
  return '"' .. tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function person_aliases(ctx)
  local title = template_title(ctx)
  local first, last = title:match("^(%S+)%s+(%S+)")

  if first and last then
    return "[" .. yaml_string(first) .. ", " .. yaml_string(first .. " " .. last:sub(1, 1)) .. "]"
  end

  first = title:match("^(%S+)")
  if first then
    return "[" .. yaml_string(first) .. "]"
  end

  return "[]"
end

local function month_ts(ctx, offset)
  local year, month = template_title(ctx):match("(%d%d%d%d)%-(%d%d)")
  return os.time({
    year = tonumber(year) or tonumber(os.date("%Y")),
    month = (tonumber(month) or tonumber(os.date("%m"))) + offset,
    day = 1,
    hour = 12,
  })
end

local function year_ts(ctx, offset)
  local year = template_title(ctx):match("(%d%d%d%d)")
  return os.time({
    year = (tonumber(year) or tonumber(os.date("%Y"))) + offset,
    month = 1,
    day = 1,
    hour = 12,
  })
end

local function day_ts(ctx, offset)
  local year, month, day = template_title(ctx):match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if not year or not month or not day then
    return os.time() + offset * 86400
  end

  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day) + offset,
    hour = 12,
  })
end

local function week_ts(ctx, offset)
  local year, week = template_title(ctx):match("(%d%d%d%d)%-W(%d%d)")
  if not year or not week then
    return os.time() + offset * 7 * 86400
  end

  local jan4 = os.time({ year = tonumber(year), month = 1, day = 4, hour = 12 })
  local days_since_monday = (tonumber(os.date("%w", jan4)) + 6) % 7
  local week1_monday = jan4 - days_since_monday * 86400
  return week1_monday + (tonumber(week) - 1 + offset) * 7 * 86400
end

local function jump_to_template_cursor(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local marker = "__CURSOR__"
  for row, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local col = line:find(marker, 1, true)
    if col then
      vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { line:gsub(marker, "", 1) })
      pcall(vim.api.nvim_win_set_cursor, 0, { row, col - 1 })
      return
    end
  end
end

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

local internalLink = function()
  wrap_selection("[[", "]]")
end
local function insert_footnote()
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

  while footnote_end + 2 <= #lines and lines[footnote_end + 1] == "" and lines[footnote_end + 2]:match("^%[%^%d+%]:") do
    footnote_end = footnote_end + 2
  end

  local insertion_line = footnote_end
  local reftext = "[^" .. next_footnote .. "]: "
  vim.api.nvim_buf_set_lines(0, insertion_line, insertion_line, false, { "", reftext })
  insertion_line = insertion_line + 2

  vim.api.nvim_win_set_cursor(0, { insertion_line, string.len(reftext) + #tostring(next_footnote) })
  vim.cmd("startinsert")
end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    priority = 100,
    ft = "markdown",
    init = function()
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        pattern = "*.md",
        callback = function(args)
          jump_to_template_cursor(args.buf)
        end,
      })
    end,
    opts = {
      attachments = {
        confirm_img_paste = true,
        folder = "resources/attachments",
      },
      legacy_commands = false,
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
        min_chars = 2,
        create_new = false,
      },
      checkbox = {
        order = { " ", "x", "-", "/", "~", "!", "*", ">", "<", "+" },
        create_new = false,
      },
      daily_notes = {
        folder = "Periodic/Daily",
        date_format = "%Y-%m-%d",
        template = "Daily nvim Template.md",
      },
      footer = { enabled = false },
      new_notes_location = "notes_subdir",
      frontmatter = {
        func = function(note)
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
      },
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
        folder = "resources/templates/nvim",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        customizations = {
          ["bible insight nvim template"] = {
            notes_subdir = "2-Areas/Bible/Topics",
          },
          ["bible study note nvim template"] = {
            notes_subdir = "2-Areas/Bible/Topics",
          },
          ["bible study nvim template"] = {
            notes_subdir = "2-Areas/Bible/Teaching",
          },
          ["highlands nvim template"] = {
            notes_subdir = "2-Areas/Bible/Learning",
          },
          ["meeting nvim template"] = {
            notes_subdir = "0-Inbox",
          },
          ["monthly nvim template"] = {
            notes_subdir = "Periodic/Monthly",
          },
          ["person nvim template"] = {
            notes_subdir = "3-Resources",
          },
          ["sermon nvim template"] = {
            notes_subdir = "2-Areas/Bible/Learning",
          },
          ["weekly nvim template"] = {
            notes_subdir = "Periodic/Weekly",
          },
          ["yearly nvim template"] = {
            notes_subdir = "Periodic",
          },
        },
        substitutions = {
          alias_title = function(ctx)
            return template_title(ctx):gsub("^%d%d%d%d%-%d%d%-%d%d%s+", "")
          end,
          person_aliases = person_aliases,
          body = function(ctx, name)
            local path = vault_path .. "/resources/templates/bodies/" .. name .. " Body.md"
            local file = io.open(path, "r")
            if not file then
              return ""
            end
            local body = file:read("*a")
            file:close()
            body = body:gsub("{{cursor}}", "__CURSOR__")
            body = body:gsub("{{month}}", os.date("%Y-%m", week_ts(ctx, 0)))
            body = body:gsub("{{year}}", os.date("%Y", year_ts(ctx, 0)))
            if ctx and ctx.location then
              local bufnr = ctx.location[1]
              vim.schedule(function()
                jump_to_template_cursor(bufnr)
              end)
            end
            return body
          end,
          content = function()
            return ""
          end,
          cursor = function(ctx)
            if ctx and ctx.location then
              local bufnr = ctx.location[1]
              vim.schedule(function()
                jump_to_template_cursor(bufnr)
              end)
            end
            return "__CURSOR__"
          end,
          datetime = function()
            return os.date("%Y%m%d%H%M%S", os.time())
          end,
          current_month = function(ctx)
            return os.date("%Y-%m", day_ts(ctx, 0))
          end,
          last_week = function(ctx)
            return os.date("%G-W%V", week_ts(ctx, -1))
          end,
          month = function(ctx)
            return os.date("%Y-%m", week_ts(ctx, 0))
          end,
          next_month = function(ctx)
            return os.date("%Y-%m", month_ts(ctx, 1))
          end,
          next_week = function(ctx)
            return os.date("%G-W%V", week_ts(ctx, 1))
          end,
          next_year = function(ctx)
            return os.date("%Y", year_ts(ctx, 1))
          end,
          prev_month = function(ctx)
            return os.date("%Y-%m", month_ts(ctx, -1))
          end,
          prev_week = function(ctx)
            return os.date("%G-W%V", week_ts(ctx, -1))
          end,
          prev_year = function(ctx)
            return os.date("%Y", year_ts(ctx, -1))
          end,
          sprint = function()
            return tostring(current_sprint_number())
          end,
          tomorrow = function(ctx)
            return os.date("%Y-%m-%d", day_ts(ctx, 1))
          end,
          week = function(ctx)
            return os.date("%G-W%V", day_ts(ctx, 0))
          end,
          year = function(ctx)
            return os.date("%Y", year_ts(ctx, 0))
          end,
          yesterday = function(ctx)
            return os.date("%Y-%m-%d", day_ts(ctx, -1))
          end,
        },
      },
      ui = { enable = false },
      link = { style = "wiki", format = "shortest" },
    },
    keys = {
      {
        "<M-S-d>",
        "<cmd>Obsidian today<cr>",
        desc = "Open Daily Note",
        mode = { "n" },
        buffer = true,
      },
      {
        "<M-S-t>",
        "<cmd>Obsidian template<cr>",
        desc = "Insert template",
        mode = { "n", "i" },
        buffer = true,
      },
      {
        "<M-n>",
        "<cmd>Obsidian new_from_template<cr>",
        desc = "New from template",
        mode = { "n" },
        buffer = true,
      },
      {
        "<M-S-l>",
        internalLink,
        desc = "Create Internal Link",
        mode = { "n", "v" },
        buffer = true,
      },
      {
        "<leader>cb",
        bold,
        desc = "Bold",
        mode = { "n", "v" },
        buffer = true,
      },
      {
        "<leader>ci",
        italics,
        desc = "Italics",
        mode = { "n", "v" },
        buffer = true,
      },
      {
        "<F1>",
        insert_footnote,
        desc = "Insert footnote",
        mode = "i",
        buffer = true,
      },
    },
  },
}
