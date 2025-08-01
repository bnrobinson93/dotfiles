local vault_path = vim.fn.expand("~") .. "/Documents/Vault"

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    event = function()
      local cwd = vim.fn.getcwd()
      if cwd:find(vault_path, 1, true) == 1 then
        return "VimEnter"
      else
        return {
          "BufReadPre " .. vault_path .. "/*.md",
          "BufNewFile " .. vault_path .. "/*.md",
        }
      end
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        { name = "personal", path = vault_path },
      },
      completion = {
        blink = true,
        min_chars = 2,
      },
      daily_notes = {
        folder = "Periodic/Daily",
        date_format = "%Y-%m-%d",
        template = "resources/templates/daily.md",
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
      new_notes_location = "0-Inbox",
      note_id_func = function(title)
        local titleToUse = ""
        if title ~= nil then
          titleToUse = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          for _ = 1, 4 do
            titleToUse = tostring(os.time()) .. "-" .. string.char(math.random(65, 90))
          end
        end
        return titleToUse
      end,
      note_frontmatter_func = function(note)
        local now = os.date("%Y-%m-%dT%H:%M")
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
        img_folder = vault_path .. "/resources/attachments",
      },
      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        ["<leader>x"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true },
        },
        ["<cr>"] = {
          action = function()
            return require("obsidian").util.smart_action()
          end,
          opts = { buffer = true, expr = true },
        },
      },
    },
    keys = {
      {
        "<C-n>",
        function()
          local obsidian = require("obsidian").get_client()
          local utils = require("obsidian.util")
          local location = vim.fn.getcwd()

          local note
          local title = utils.input("Enter title or path (optional): ")
          if not title then
            return
          elseif title == "" then
            title = nil
          end

          note = obsidian:create_note({ title = title, no_write = true })

          if not note then
            return
          end

          local datetime = os.time()
          local dailyNote = obsidian:daily_note_path(datetime)

          if location ~= vault_path then
            vim.cmd("cd " .. vault_path)
            obsidian:today()
            vim.cmd("cd " .. location)
          end

          if note.filename ~= dailyNote.filename then
            local file = io.open(dailyNote.filename, "a")
            if not file then
              vim.notify("Failed to open daily note: " .. dailyNote.filename, vim.log.levels.ERROR)
              return
            end
            file:write("\n\n[[" .. title .. "]]\n")
            file:close()
          end

          obsidian:open_note(note, { sync = true })
          obsidian:write_note_to_buffer(note, { template = "zettle" })
        end,
        desc = "New Obsidian Note",
        ft = "markdown",
        mode = "n",
      },
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
