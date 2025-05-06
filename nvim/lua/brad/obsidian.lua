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
  },
}
