return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      filetypes = {
        markdown = false,
      },
      server_opts_overrides = {
        -- Connection management to prevent GitHub handle leaks
        settings = {
          advanced = {
            timeout = 10000, -- 10 seconds instead of indefinite
          },
        },
        flags = {
          debounce_text_changes = 500, -- Reduce API calls
          allow_incremental_sync = false, -- Force clean syncs
        },
        on_attach = function(client, bufnr)
          -- Check file handle count every 30 minutes and restart if excessive
          local timer = vim.uv.new_timer()
          if timer then
            timer:start(
              1800000, -- 30 minutes
              1800000, -- repeat every 30 minutes
              vim.schedule_wrap(function()
                -- Get handle count for copilot process
                local handle = io.popen("lsof -p " .. client.rpc.pid .. " 2>/dev/null | wc -l")
                if handle then
                  local count = tonumber(handle:read("*a"):match("%d+")) or 0
                  handle:close()
                  -- If > 100 handles, restart the language server
                  if count > 100 then
                    vim.notify(
                      "Copilot: Restarting language server (handle leak detected: " .. count .. ")",
                      vim.log.levels.WARN
                    )
                    vim.lsp.stop_client(client.id)
                    timer:stop()
                    timer:close()
                  end
                end
              end)
            )
          end
        end,
      },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = {
      -- For markdown rendering
      highlight_headers = false,
      separator = "---",
      error_header = "> [!ERROR] Error",
      -- because I generally want this context
      sticky = {
        "#buffer",
        "#system:`fd --full-path $(git rev-parse --show-toplevel) --type f --exclude .git --exclude node_modules`",
      },
      selection = function(source)
        return require("CopilotChat#selection").visual(source) or require("CopilotChat#selection").line(source)
      end,
      insert_at_end = false,
      prompts = {
        Help = {
          description = "Talk with me like a senior developer",
          system_prompt = "You are now my senior developer partner. I have some problems that are holding me up.Think through this and before responding with a fix, ask me some questions to better understand how to solve the issue. Unless you have full context of the issue, you should ask clarifying questions before attempting to answer or providing any suggesetions. While being respectful, treat me with some level of hesitency and assume I have no idea what I am talking about unless I tell you otherwise. That is, feel free to tell me I am wrong if you find that I am wrong.",
          prompt = [[
        > **BLUF:**
        > __INSERT OVERALL GOAL__
        > Think through this and before responding with a fix, ask me some questions to better understand how to solve the issue

        > **CURRENT SITUATION**:
        > - What I'm trying to achieve: [Specific goal]
        > - What I've already tried: [Previous attempts]
        > - What's blocking me: [Specific problem]
        > - Success criteria: [What good looks like]

        > **PROJECT CONTEXT**:
        > - What I'm building: [Specific description]
        > - Tech stack: [Exact versions]
        > - User base: [Who uses this]
        > - Timeline: [Deadines and constraints]

        > **AUDIENCE**: 
        > **LIMITATIONS**: 
        > **EXPECTED OUTCOME**: 
      ]],
        },
      },
    },
  },
}
