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

-- Templates get applied on top of existing notes at least as often as they
-- create one: 0-Inbox auto-applies Zettel, and imported notes get their real
-- template later. These helpers let a template skip whatever the note already
-- has, so a second template never doubles the H1, sections or date footer.
local drop_marker = "__DROP_LINE__"

-- Frontmatter keys that really are lists. Everything else is a scalar, and a
-- list value there is merge damage rather than intent.
local list_metadata_keys = {
  attendies = true,
  author = true,
  categories = true,
  consulted = true,
  deciders = true,
  driver = true,
  format = true,
  informed = true,
  location = true,
  type = true,
}

local function normalize_metadata(out)
  for key, value in pairs(out) do
    -- Heal a list key that got flattened to a scalar somewhere upstream, so a
    -- `categories: "[[Journal]]"` note goes back to being a list on next write.
    if list_metadata_keys[key] and type(value) == "string" and value ~= "" then
      out[key] = { value }
      value = out[key]
    end

    if type(value) == "table" and vim.islist(value) then
      local seen, deduped = {}, {}
      for _, item in ipairs(value) do
        if not seen[item] then
          seen[item] = true
          deduped[#deduped + 1] = item
        end
      end
      -- Existing value wins: the note's own value is merged in first.
      out[key] = list_metadata_keys[key] and deduped or deduped[1]
    end
  end
  return out
end

local function ctx_buf(ctx)
  return ctx and ctx.location and ctx.location[1] or nil
end

-- Buffer lines with the frontmatter block removed.
local function note_body_lines(bufnr)
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
    return {}
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if lines[1] ~= "---" then
    return lines
  end

  for i = 2, #lines do
    if lines[i] == "---" then
      return vim.list_slice(lines, i + 1)
    end
  end

  return lines
end

-- "## Links:" and "## Links" are the same section; legacy notes use both.
local function heading_key(text)
  return (vim.trim(text):gsub("[:%s]+$", ""):lower())
end

local function existing_headings(bufnr)
  local seen = {}
  for _, line in ipairs(note_body_lines(bufnr)) do
    local heading = line:match("^#+%s+(.+)$")
    if heading then
      seen[heading_key(heading)] = true
    end
  end
  return seen
end

local function buffer_has(bufnr, pattern)
  for _, line in ipairs(note_body_lines(bufnr)) do
    if line:match(pattern) then
      return true
    end
  end
  return false
end

-- Skip any heading block the note already carries. Only H1/H2 open a new
-- block, so a "###" inside a kept section rides along with it. A body H1
-- (Just Processing) is dropped whenever the note already has one, whatever it
-- says, because MD025 allows exactly one.
local function drop_known_sections(body, seen, has_h1)
  local kept, skipping = {}, false
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    local hashes, heading = line:match("^(#+)%s+(.+)$")
    if hashes and #hashes <= 2 then
      local key = heading_key(heading)
      skipping = seen[key] or (#hashes == 1 and has_h1) or false
      seen[key] = true
    end
    if not skipping then
      kept[#kept + 1] = line
    end
  end
  return table.concat(kept, "\n")
end

-- A substitution can only blank a line, not delete it, so it leaves a marker
-- and this sweeps the marker plus its trailing blank line after the insert.
local function strip_dropped_lines(bufnr)
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local kept, i, dropped = {}, 1, false
  while i <= #lines do
    if vim.trim(lines[i]) == drop_marker then
      dropped = true
      if lines[i + 1] and lines[i + 1]:match("^%s*$") then
        i = i + 1
      end
    else
      kept[#kept + 1] = lines[i]
    end
    i = i + 1
  end

  if dropped then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, kept)
  end
end

local function yaml_string(value)
  return '"' .. tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

-- Meeting is "YYYY-MM-DD Name", Sermon/Highlands are "Name YYYY-MM-DD"; the
-- undated title is the alias. Periodic notes are nothing but a date, so fall
-- back to the full title rather than returning an empty string.
local function alias_title(ctx)
  local title = template_title(ctx)
  local stripped = vim.trim((title:gsub("^%d%d%d%d%-%d%d%-%d%d%s+", ""):gsub("%s+%d%d%d%d%-%d%d%-%d%d$", "")))
  if stripped == "" then
    return title
  end
  return stripped
end

local function person_aliases(ctx)
  local title = template_title(ctx)
  local first, last = title:match("^(%S+)%s+(%S+)")
  first = first or title:match("^(%S+)")

  if not first then
    return "[]"
  end

  -- Possessive form so "[[Christy's]]" style links resolve.
  local aliases = { first, first .. "'s" }
  if last then
    aliases[#aliases + 1] = first .. " " .. last:sub(1, 1)
  end

  return "[" .. table.concat(vim.tbl_map(yaml_string, aliases), ", ") .. "]"
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
      local replacement = line:gsub(marker, "", 1)
      vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { replacement })
      vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
            pcall(vim.api.nvim_set_current_win, win)
            pcall(vim.api.nvim_win_set_cursor, win, { row, col - 1 })
            vim.cmd("startinsert")
            return
          end
        end
      end, 20)
      return
    end
  end
end

local function schedule_template_cleanup(ctx)
  local bufnr = ctx_buf(ctx)
  if not bufnr then
    return
  end

  vim.schedule(function()
    strip_dropped_lines(bufnr)
    jump_to_template_cursor(bufnr)
  end)
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

-- For hover preview doc
local function resolve_embed()
  local util = require("obsidian.util")
  local search = require("obsidian.search")

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local embed, pos = nil, 1
  while pos <= #line do
    local s, e = line:find("!%[%[.-%]%]", pos)
    if not s then
      break
    end
    if col >= s and col <= e then
      embed = line:sub(s + 1, e)
      break
    end
    pos = e + 1
  end
  if not embed then
    return nil
  end

  local location = util.parse_link(embed)
  if not location then
    return nil
  end
  location = vim.uri_decode(location)

  -- A "#^id" suffix is a block reference, not a header anchor. strip_anchor_links
  -- would mangle it into a header anchor that never resolves, so peel it first.
  local bare, anchor, block_id
  block_id = location:match("#(%^[%w%-]+)$")
  if block_id then
    bare = location:sub(1, #location - #block_id - 1)
  else
    bare, anchor = util.strip_anchor_links(location)
  end

  local notes = search.resolve_note(bare, {
    notes = { collect_anchor_links = true, collect_blocks = true, load_contents = true },
  })
  if vim.tbl_isempty(notes) then
    return nil
  end

  -- Case-insensitive filesystems (macOS) resolve the linked note via direct
  -- path lookup, so notes[1] is always the right note. Case-sensitive ones
  -- (Linux) fall back to fuzzy ripgrep matching when the link case differs
  -- from the filename, and notes[1] may be the wrong candidate. Try each note
  -- and keep the first that actually yields a section.
  local function build_section(note)
    local lines = note.contents
    if not lines then
      return nil
    end
    local section = {}
    local start_row = 1
    if block_id then
      local block = note:resolve_block(block_id)
      if not block then
        return nil
      end
      local sec = block.section
      local from, to
      if sec and sec.content_range then
        from = sec.content_range.start_row + 1
        to = sec.content_range.end_row
      else
        from, to = block.line, block.line
      end
      start_row = from
      for i = from, to do
        -- Drop the trailing "^id" marker from the block's own lines.
        section[#section + 1] = (util.strip_block_links(lines[i]))
      end
    elseif anchor then
      local anchor_obj = note:resolve_anchor_link(anchor)
      if not anchor_obj then
        return nil
      end
      local header_level = anchor_obj.level
      start_row = anchor_obj.line + 1
      for i = anchor_obj.line + 1, #lines do
        local parsed = util.parse_header(lines[i])
        if parsed and parsed.level <= header_level then
          break
        end
        section[#section + 1] = lines[i]
      end
    else
      start_row = 2
      for i = 2, #lines do
        section[#section + 1] = lines[i]
      end
    end

    -- Peel only while every non-blank line is quoted, so a nested quote keeps
    -- its own marker.
    local function all_quoted()
      local any = false
      for _, line in ipairs(section) do
        if not line:match("^%s*$") then
          if not line:match("^%s*>") then
            return false
          end
          any = true
        end
      end
      return any
    end

    while all_quoted() do
      for i, line in ipairs(section) do
        section[i] = (line:gsub("^%s*>%s?", ""))
      end
    end

    while #section > 0 and section[#section]:match("^%s*$") do
      section[#section] = nil
    end
    if #section == 0 then
      return nil
    end
    return section, start_row
  end

  for _, note in ipairs(notes) do
    local section, start_row = build_section(note)
    if section then
      local title = " " .. bare .. (anchor or (block_id and "#" .. block_id) or "") .. " "
      return section, title, tostring(note.path), start_row
    end
  end

  return nil
end

local embed_hover_win = nil
local embed_hover_buf = nil

local function hover_config(section, title)
  local width = math.min(80, vim.o.columns - 4)
  local height = 0
  for _, line in ipairs(section) do
    height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / width))
  end
  return {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = math.min(math.max(height, 1), 20),
    style = "minimal",
    border = "rounded",
    title = title,
    focusable = false,
  }
end

local function enable_wrapping(win)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = true
end

local function close_embed_hover()
  if embed_hover_win and vim.api.nvim_win_is_valid(embed_hover_win) then
    vim.api.nvim_win_close(embed_hover_win, true)
  end
  if embed_hover_buf and vim.api.nvim_buf_is_valid(embed_hover_buf) then
    vim.api.nvim_buf_delete(embed_hover_buf, { force = true })
  end
  embed_hover_win = nil
  embed_hover_buf = nil
end

-- Opens the linked note's own buffer, so `:w` and `:q` behave normally.
local function edit_embed()
  local name = vim.api.nvim_buf_get_name(0)
  local section, title, path, start_row
  if vim.startswith(name, vault_path) and name:match("%.md$") then
    section, title, path, start_row = resolve_embed()
  end
  if not path then
    return vim.lsp.buf.hover()
  end

  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)

  local win = embed_hover_win
  if win and vim.api.nvim_win_is_valid(win) then
    local scratch = embed_hover_buf
    -- Drop the handles before swapping: close_embed_hover force-deletes
    -- embed_hover_buf, and that is the note's own buffer from here on.
    embed_hover_win, embed_hover_buf = nil, nil
    vim.api.nvim_win_set_buf(win, buf)
    if scratch and vim.api.nvim_buf_is_valid(scratch) then
      vim.api.nvim_buf_delete(scratch, { force = true })
    end
  else
    win = vim.api.nvim_open_win(buf, false, hover_config(section, title))
  end

  enable_wrapping(win)
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { math.min(start_row, vim.api.nvim_buf_line_count(buf)), 0 })
  vim.cmd("normal! zt")
end

return {
  {
    -- LazyVim binds K on LSP attach, after any autocmd of ours can, so take
    -- over its keymap entry rather than racing it.
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "K", edit_embed, desc = "Hover" },
          },
        },
      },
    },
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    priority = 100,
    ft = "markdown",
    init = function()
      vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = vault_path .. "/**/*.md",
        callback = function(args)
          jump_to_template_cursor(args.buf)
        end,
      })

      vim.api.nvim_create_autocmd("CursorHold", {
        pattern = vault_path .. "/**/*.md",
        callback = function()
          close_embed_hover()
          local section, title = resolve_embed()
          if not section then
            return
          end

          embed_hover_buf = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_lines(embed_hover_buf, 0, -1, false, section)

          embed_hover_win = vim.api.nvim_open_win(embed_hover_buf, false, hover_config(section, title))
          enable_wrapping(embed_hover_win)

          -- Must follow nvim_open_win: render-markdown attaches on FileType and
          -- only decorates windows already showing the buffer.
          vim.bo[embed_hover_buf].filetype = "markdown"
          vim.treesitter.start(embed_hover_buf, "markdown")
        end,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
        pattern = vault_path .. "/**/*.md",
        callback = close_embed_hover,
      })
    end,
    opts = {
      attachments = {
        confirm_img_paste = true,
        folder = "99-System/attachments",
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
        template = "Daily.md",
        default_tags = {}, -- plugin default is { "daily-notes" }; folder already says it
      },
      footer = { enabled = false },
      -- Parity with the app, where Templater has a folder template on 0-Inbox:
      -- every new note starts as a Zettel and the real template gets applied on
      -- top later. The substitutions below make that second apply idempotent.
      note = { template = "Zettel.md" },
      new_notes_location = "notes_subdir",
      frontmatter = {
        enabled = function(path)
          return not vim.startswith(tostring(path), "99-System/templates/")
        end,
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

          -- More things I may want (skip empties: no `tags: []` noise)
          if note.tags and #note.tags > 0 then
            out.tags = note.tags
          end
          if note.aliases and #note.aliases > 0 then
            out.aliases = note.aliases
          end

          -- Applying a template over an existing note runs obsidian.nvim's
          -- Note:merge, which list-extends every metadata key present in both.
          -- That turns scalars into two-item lists (`created: [old, new]`), so
          -- collapse anything that is not genuinely a list back to the value
          -- the note already had.
          return normalize_metadata(out)
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
        folder = "99-System/templates/nvim",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        customizations = {
          ["adr"] = {
            notes_subdir = "2-Areas/Virtru",
          },
          ["bible insight"] = {
            notes_subdir = "2-Areas/Bible/Topics",
          },
          ["book"] = {
            notes_subdir = "3-Resources",
          },
          ["just processing"] = {
            notes_subdir = "0-Inbox",
          },
          ["place"] = {
            notes_subdir = "3-Resources",
          },
          ["recipe"] = {
            notes_subdir = "3-Resources/Recipes",
          },
          ["spike"] = {
            notes_subdir = "2-Areas/Virtru",
          },
          ["sprint review"] = {
            notes_subdir = "2-Areas/Virtru",
          },
          ["bible study note"] = {
            notes_subdir = "2-Areas/Bible/Topics",
          },
          ["bible brad"] = {
            notes_subdir = "2-Areas/Bible/Teaching",
          },
          ["highlands"] = {
            notes_subdir = "2-Areas/Bible/Learning",
          },
          ["meeting"] = {
            notes_subdir = "0-Inbox",
          },
          ["monthly"] = {
            notes_subdir = "Periodic/Monthly",
          },
          ["person"] = {
            notes_subdir = "3-Resources",
          },
          ["sermon"] = {
            notes_subdir = "2-Areas/Bible/Learning",
          },
          ["weekly"] = {
            notes_subdir = "Periodic/Weekly",
          },
          ["yearly"] = {
            notes_subdir = "Periodic",
          },
        },
        substitutions = {
          alias_title = alias_title,
          person_aliases = person_aliases,
          -- One H1 per note (MD025) — obsidian.nvim `gd` breaks otherwise.
          h1 = function(ctx)
            schedule_template_cleanup(ctx)
            if buffer_has(ctx_buf(ctx), "^#%s+") then
              return drop_marker
            end
            return "# " .. alias_title(ctx)
          end,
          links = function(ctx)
            schedule_template_cleanup(ctx)
            if existing_headings(ctx_buf(ctx))["links"] then
              return drop_marker
            end
            return "## Links"
          end,
          date_footer = function(ctx)
            schedule_template_cleanup(ctx)
            if buffer_has(ctx_buf(ctx), "%[%[%d%d%d%d%-%d%d%-%d%d%]%]") then
              return drop_marker
            end
            return "[[" .. os.date("%Y-%m-%d") .. "]]"
          end,
          body = function(ctx, name)
            local path = vault_path .. "/99-System/templates/bodies/" .. name .. " Body.md"
            local file = io.open(path, "r")
            if not file then
              return ""
            end
            local body = file:read("*a")
            file:close()
            body = body:gsub("{{cursor}}", "__CURSOR__")
            body = body:gsub("{{month}}", os.date("%Y-%m", week_ts(ctx, 0)))
            body = body:gsub("{{week}}", os.date("%G-W%V", day_ts(ctx, 0)))
            body = body:gsub("{{year}}", os.date("%Y", year_ts(ctx, 0)))
            local bufnr = ctx_buf(ctx)
            body = drop_known_sections(body, existing_headings(bufnr), buffer_has(bufnr, "^#%s+"))
            schedule_template_cleanup(ctx)
            return body
          end,
          content = function()
            return ""
          end,
          cursor = function(ctx)
            schedule_template_cleanup(ctx)
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
        "<M-S-e>",
        "<cmd>Obsidian template Evergreen<cr>",
        desc = "Open Daily Note",
        mode = { "n" },
        buffer = true,
      },
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
      {
        "<leader>xt",
        "<cmd>Obsidian tags todo<cr>",
        desc = "Obsidian #todo tags",
        mode = { "n" },
        buffer = true,
      },
    },
  },
}
