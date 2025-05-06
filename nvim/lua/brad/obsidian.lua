local Vault = vim.fn.expand '~' .. '/Documents/Vault'

local function createNoteWithDefaultTemplate()
  local TEMPLATE_FILENAME = 'zettle'
  local obsidian = require('obsidian').get_client()
  local utils = require 'obsidian.util'

  -- prevent Obsidian.nvim from injecting it's own frontmatter table
  -- obsidian.opts.disable_frontmatter = true

  -- prompt for note title
  -- @see: borrowed from obsidian.command.new
  local note
  local title = utils.input 'Enter title or path (optional): '
  if not title then
    return
  elseif title == '' then
    title = nil
  end

  note = obsidian:create_note { title = title, no_write = true }

  if not note then
    return
  end
  -- open new note in a buffer
  obsidian:open_note(note, { sync = true })
  -- NOTE: make sure the template folder is configured in Obsidian.nvim opts
  obsidian:write_note_to_buffer(note, { template = TEMPLATE_FILENAME })
end

return {
  'epwalsh/obsidian.nvim',
  ft = 'markdown',
  event = {
    'BufReadPre ' .. Vault .. '/*.md',
    'BufNewFile ' .. Vault .. '/*.md',
  },
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    workspaces = {
      { name = 'personal', path = Vault },
    },
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },
    daily_notes = {
      folder = 'Periodic/Daily',
      date_format = '%Y-%m-%d',
      template = 'resources/templates/daily.md',
    },
    templates = {
      folder = 'resources/templates',
      date_format = '%Y%m%d',
      time_format = '%H%M',
    },
    new_notes_location = '0-Inbox',
    note_id_func = function(title)
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
      local suffix = ''
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. '-' .. suffix
    end,
    note_frontmatter_func = function(note)
      local now = os.date '%Y-%m-%dT%H:%M'
      local out = { updated = now, created = now }

      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end

      return out
    end,
    ui = { enable = false },
    attachments = {
      img_folder = 'resources/attachments',
    },
    mappings = {
      -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
      ['gf'] = {
        action = function()
          return require('obsidian').util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle check-boxes.
      ['<leader>x'] = {
        action = function()
          return require('obsidian').util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- Smart action depending on context, either follow link or toggle checkbox.
      ['<cr>'] = {
        action = function()
          return require('obsidian').util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },
    vim.keymap.set('n', '<C-n>', createNoteWithDefaultTemplate, { desc = '[N]ew Note' }),
    vim.keymap.set('i', '<F1>', function()
      -- Get all lines in the current buffer
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local max_footnote = 0

      -- Find the maximum footnote number in the entire file
      for _, line in ipairs(lines) do
        for num in line:gmatch '%[%^(%d+)%]' do
          max_footnote = math.max(max_footnote, tonumber(num))
        end
      end

      -- Generate the next footnote number
      local next_footnote = max_footnote + 1

      -- Insert the footnote at cursor position
      local footnote_text = '[^' .. next_footnote .. ']'
      vim.api.nvim_put({ footnote_text }, 'c', false, true)

      -- Save current position to jump list before making changes
      vim.cmd "normal! m'"

      -- Get current cursor position
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local para_start = cursor_pos[1]
      local para_end = cursor_pos[1]

      -- Find start of paragraph (empty line or BOF)
      while para_start > 1 and lines[para_start - 1] ~= '' do
        para_start = para_start - 1
      end

      -- Find end of paragraph (empty line or EOF)
      while para_end < #lines and lines[para_end + 1] ~= '' do
        para_end = para_end + 1
      end

      -- Find the last footnote reference for this paragraph
      local footnote_end = para_end
      local line_after_para = para_end + 1

      -- If next line is empty and followed by a footnote reference, keep looking
      while footnote_end + 2 <= #lines and lines[footnote_end + 1] == '' and lines[footnote_end + 2]:match '^%[%^%d+%]:' do
        footnote_end = footnote_end + 2
      end

      -- Determine insertion point - after the last footnote or at paragraph end
      local insertion_line = footnote_end

      -- Insert the reference at the determined position
      local reftext = '[^' .. next_footnote .. ']: '
      vim.api.nvim_buf_set_lines(0, insertion_line, insertion_line, false, { '', reftext })
      insertion_line = insertion_line + 2

      -- Move cursor to the reference line
      vim.api.nvim_win_set_cursor(0, { insertion_line, string.len(reftext) + #tostring(next_footnote) })

      -- Return to insert mode at the end
      vim.cmd 'startinsert'
    end, { buffer = true }),
  },
}
