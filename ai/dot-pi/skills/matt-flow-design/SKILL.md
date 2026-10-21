---
name: matt-flow-design
description: Run the Matt workflow with Figma-assisted planning and browser screenshot QA. Use when a task has a Figma design reference and the implemented UI must be visually checked before code review.
---

# Matt flow with design QA

Read `../matt-workflow/SKILL.md`, `~/.agents/skills/figma/SKILL.md`, `~/.pi/agent/skills/browser-debug/SKILL.md`, and `~/.pi/agent/skills/simplify/SKILL.md` before starting. The existing Matt workflow is the baseline. Keep it unchanged and add the design phase below.

`$@` contains the effort name and, when available, a Figma file, frame, or layer URL. Exact node links, states, and viewports are useful but not required: discover them through Figma MCP when they are absent. Do not treat a file-level URL as a blocker.

## 1. Pin the work

Record the effort name and pre-work fixed point before dispatching a child. In this JJ repo, use `jj workspace root`, `jj status`, and the fixed point required by `matt-workflow`.

Completion criterion: the fixed point, effort, available Figma URL, requested UI scope, and target discovery requirements are explicit.

## 2. Add Figma evidence to the grill

Use Claude Code for this phase. Its installed Figma plugin is already connected, while Pi's separate Figma server may use a different authentication setup.

1. Create a temporary request file containing any supplied Figma links, the requested states and viewport sizes, and the request for a design brief. Tell Claude to leave the brief in a second temporary file and make no repository edits. Run `~/.pi/agent/scripts/claude-design-task.sh` with that file.
2. Claude must follow the Figma skill's order: call `get_design_context` first for supplied nodes, or use the Figma MCP context/discovery request for a file-level URL. Use `get_metadata` only when context cannot identify the useful frames or is too large, then call `get_screenshot` for every selected state or variant. Use `get_variable_defs` and `get_code_connect_map` when token or component decisions affect the work. Record selected node IDs, states, and dimensions in the brief.
3. Read the design brief and pass it to `grill-me-with-docs`: supplied and selected links/node IDs, states, viewport sizes, relevant tokens, existing component mappings, behavior, visual acceptance criteria, and screenshot observations. Treat Figma output as design evidence, not production code.
4. Start `grill-me-with-docs` in a fresh named session exactly as `matt-workflow` does. Include the design brief in its initial handoff. Relay one question at a time. If a question needs more Figma evidence, run another focused Claude request before answering and add the decision to the routed docs.

If Claude Code or its Figma plugin fails, stop with the command output. Do not silently fall back to guessed design values or Pi's unauthenticated Figma server.

Completion criterion: the user has approved ready document paths, and those documents contain the Figma target, visual acceptance criteria, token and component decisions, responsive states, and any intentional deviations.

## 3. Implement normally

Run the existing `matt-workflow` implementation handoff with the approved documents, fixed point, acceptance criteria, exclusions, and design decisions. Use a fresh ephemeral `implement` context. Do not run `code-review` yet.

Completion criterion: implementation and the repository's canonical implementation gate are complete, with the changed routes or UI entry points identified for visual QA.

## 4. Run visual QA before review

Dispatch the `design-qa` agent ephemerally with `initialContext: "empty"`. Pass it the fixed point, approved document paths, supplied Figma links and/or selected node IDs, target states and viewports, changed UI scope, route or dev-server URL, and the design acceptance criteria. It delegates the Figma and browser work to Claude Code, which may edit the implementation. It must not edit the design documents or commit.

The agent must:

- Delegate to Claude Code through `~/.pi/agent/scripts/claude-design-task.sh`. Claude re-fetches Figma context and reference screenshots through its connected Figma MCP. Do not open Figma in the browser.
- Preflight the existing dev browser and endpoint before launching anything: inspect the Claude Chrome integration and run browser-debug `status` and `pages`, then use an existing inspectable dev page if one exists. If no usable dev browser/page exists, the browser-debug fallback may launch Helium with `BROWSER_DEBUG_BINARY=/Applications/Helium.app/Contents/MacOS/Helium`; it uses its isolated temporary profile. If newly launched Helium needs auth, pause the run and use `SendUserMessage` to ask the user to log in; the parent resumes or reruns the QA after the user confirms login. If an existing browser is present but unauthenticated, do not launch a second browser: pause and ask the user to log in in that browser, then resume or rerun after confirmation.
- Identify the implementation workspace and the workspace running the dev server from the process cwd or server handoff. Resolve both through `jj workspace list`. Call `~/.pi/agent/scripts/jj-workspace-handoff.sh IMPLEMENTATION_WORKSPACE DEV_SERVER_WORKSPACE [REVISION]` only when they are different. Do not assume the target is `default`; when they resolve to the same workspace, do not call the helper. Keep the handoff uncommitted.
- Use the browser-debug fallback at `/Users/brad.robinson/.pi/agent/skills/browser-debug/scripts/browser-cdp.mjs` when Chrome integration is unavailable. Capture Figma and implementation screenshots for every selected state and viewport at the same dimensions and in the same browser state.
- Leave screenshots in a temporary directory, never in the repository, and report the paths or observations needed to reproduce the comparison.
- Iterate on the implementation until material differences are gone. Prefer existing components and design-system tokens; inspect the resolved design-system package as read-only. Keep custom CSS to geometry or behavior the system cannot express. Preserve accessibility and responsive behavior.

Treat browser font rendering, antialiasing, and other renderer-only differences as noise. Do not add one-off styles or brittle pixel hacks to erase them. If Claude Code, its Figma plugin, the browser, the dev server, or a required state is unavailable, return `BLOCKED` with the exact missing prerequisite instead of guessing.

Completion criterion: every requested state and viewport has been captured and compared, no material visual discrepancy remains, and any unavoidable or intentional deviation is named.

After `design-qa` returns aligned, run `simplify` over the final diff. If it edits the visual scope, run the affected screenshot comparisons again and repeat `simplify` until it is clean. Then run the final repository gate: `make web-test` (the documented one-shot lint, typecheck, and frontend test target) and `pnpm --dir web build` (the documented frontend build). Do not advance to review while visual QA, simplify, or either check is unresolved.

## 5. Continue with Matt review

Run the existing `code-review` phase ephemerally with the original fixed point and approved spec paths. Include the visual QA result and any intentional deviations in the handoff. It performs the normal Standards and Spec axes and makes no edits.

Return implementation verification, visual QA status and evidence, the two review axes, and every unresolved finding. Keep the Figma or browser setup blocker explicit if the flow could not complete.
