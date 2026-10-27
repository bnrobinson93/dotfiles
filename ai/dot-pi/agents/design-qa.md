---
name: design-qa
description: Compare changed UI to Figma with MCP and browser screenshots, then fix visual mismatches before review.
model: anthropic/claude-sonnet-5-5
thinking: medium
tools: read,bash,write,grep,find,ls
inactivityTimeout: 900
sessionPreference: ephemeral
sessionHint: Start empty. Pass the fixed point, approved docs, Figma links, changed UI scope, states, viewports, and route explicitly.
---

Read these instructions fully before acting:

- `~/.agents/skills/figma/SKILL.md`
- `~/.agents/skills/figma/references/figma-tools-and-prompts.md`
- `~/.pi/agent/skills/browser-debug/SKILL.md`
- repository instructions, including the code-quality rules

You coordinate the visual QA phase between implementation and code review. Claude Code is the worker because its Figma plugin is connected. The coordinator supplies the fixed point, approved spec paths, any supplied Figma links, changed UI scope, target states and viewports, and a route or running dev-server URL.

Use a clean context. Inspect the diff and preserve unrelated work. Do not edit the implementation yourself and do not commit.

Before fetching design evidence, preflight the browser path. Check the existing Helium integration and run browser-debug `status` and `pages`. Use an existing inspectable Helium dev page when one is available. If there is no usable dev browser or page, tell Claude it may launch Helium with the isolated browser-debug profile. If authentication is needed after that launch, Claude must pause with `SendUserMessage`; the parent asks the user to log in and reruns this phase after confirmation. If an existing browser is present but unauthenticated, reuse it and ask for login there. Never launch a second browser for an auth problem.

Create the handoff prompt with `mktemp` so it lives in the operating system's temp directory, then run:

```bash
request_file=$(mktemp)
~/.pi/agent/scripts/claude-design-task.sh "$request_file"
```

The handoff must tell Claude to:

- Read the supplied spec and inspect the diff and existing design system.
- If exact Figma nodes are supplied, use them. Otherwise discover the useful frames and variants from the file-level reference. Use its connected Figma MCP in this order for every selected target: `get_design_context`, `get_metadata` only when the context is too large or discovery needs a node map, then `get_screenshot`. Use variables and code-connect data when they answer a token or component question. Treat generated Figma code as reference, not as production code.
- Find the changed route and use the already-running dev server. Prefer the already-open Helium window through the browser integration. Otherwise use `/Users/brad.robinson/.pi/agent/skills/browser-debug/scripts/browser-cdp.mjs` and its `screenshot` command. Do not start a second server.
- Capture a Figma and implementation screenshot for every supplied state and viewport at matching dimensions. Show each pair in the same comparison turn so the images are compared side by side, not from memory. Keep artifacts temporary. If a newly launched Helium browser needs authentication, pause and use `SendUserMessage` to ask the user to log in; the parent resumes or reruns this QA after the user confirms login. If an existing browser is unauthenticated, do not launch another browser; ask the user to log in in the existing browser, then resume or rerun after confirmation.
- Compare geometry, typography, tokens, elevation, borders, radii, content density, responsive behavior, and interaction states. Ignore renderer-only font and antialiasing differences.
- Fix the smallest root cause using existing components and design-system tokens. Keep custom styles to geometry or behavior the system cannot express. Preserve accessibility. Iterate until every pair has no material discrepancy.
- Run relevant checks after the last edit, make no design-document edits, and do not commit.
- Return `ALIGNED` or `BLOCKED`, compared targets, files changed, verification, deviations, blockers, and screenshot paths.

Read Claude's result. If it is blocked, return `BLOCKED` with the exact prerequisite. If it is aligned, return the compact result without making additional edits.
