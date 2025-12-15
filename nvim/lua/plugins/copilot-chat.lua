-- Track timers per client to prevent leaks on restart
local copilot_timers = {}

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
          local TIMER_VALUE = 30 * 60 * 1000 -- 30 minutes in milliseconds
          local MAX_FILE_HANDLES = 100

          -- Clean up any existing timer for this client
          if copilot_timers[client.id] then
            local old_timer = copilot_timers[client.id]
            if not old_timer:is_closing() then
              old_timer:stop()
              old_timer:close()
            end
            copilot_timers[client.id] = nil
          end

          -- Create new timer
          local timer = vim.uv.new_timer()
          if timer then
            copilot_timers[client.id] = timer

            timer:start(
              TIMER_VALUE,
              TIMER_VALUE,
              vim.schedule_wrap(function()
                -- Verify client is still valid
                if not vim.lsp.get_client_by_id(client.id) then
                  if timer and not timer:is_closing() then
                    timer:stop()
                    timer:close()
                  end
                  copilot_timers[client.id] = nil
                  return
                end

                -- Get handle count for copilot process
                local handle = io.popen("lsof -p " .. client.rpc.pid .. " 2>/dev/null | wc -l")
                if handle then
                  local count = tonumber(handle:read("*a"):match("%d+")) or 0
                  handle:close()
                  -- If too many handles, restart the language server
                  if count > MAX_FILE_HANDLES then
                    vim.notify(
                      "Copilot: Restarting language server (handle leak detected: " .. count .. ")",
                      vim.log.levels.WARN
                    )
                    -- Clean up timer before stopping client
                    if timer and not timer:is_closing() then
                      timer:stop()
                      timer:close()
                    end
                    copilot_timers[client.id] = nil
                    vim.lsp.stop_client(client.id)
                  end
                end
              end)
            )

            -- Store autocmd IDs for cleanup
            local autocmd_ids = {}

            -- Clean up timer when LSP client detaches
            local cleanup_timer = function()
              -- Clean up timer
              if copilot_timers[client.id] then
                local t = copilot_timers[client.id]
                if not t:is_closing() then
                  t:stop()
                  t:close()
                end
                copilot_timers[client.id] = nil
              end

              -- Clean up autocmds to prevent accumulation
              for _, id in ipairs(autocmd_ids) do
                pcall(vim.api.nvim_del_autocmd, id)
              end
              autocmd_ids = {}
            end

            -- Register cleanup on client detach
            local detach_id = vim.api.nvim_create_autocmd("LspDetach", {
              buffer = bufnr,
              callback = function(args)
                if args.data and args.data.client_id == client.id then
                  cleanup_timer()
                end
              end,
            })
            table.insert(autocmd_ids, detach_id)

            -- Also cleanup on buffer delete
            local buf_delete_id = vim.api.nvim_create_autocmd("BufDelete", {
              buffer = bufnr,
              callback = cleanup_timer,
              once = true,
            })
            table.insert(autocmd_ids, buf_delete_id)
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
        return require("CopilotChat.selection").visual(source) or require("CopilotChat.selection").line(source)
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
