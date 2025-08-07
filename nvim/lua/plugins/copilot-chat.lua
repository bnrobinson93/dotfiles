return {
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
      return require("CopilotChat.select").visual(source) or require("CopilotChat.select").line(source)
    end,
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
        > - Timeline: [Deadlines and constraints]

        > **AUDIENCE**: 
        > **LIMITATIONS**: 
        > **EXPECTED OUTCOME**: 
      ]],
      },
    },
  },
}
