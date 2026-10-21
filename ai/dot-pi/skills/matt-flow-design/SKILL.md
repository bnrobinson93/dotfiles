---
name: matt-flow-design
description: Run the Matt workflow with Figma-assisted planning and browser screenshot QA. Use when a task has a Figma frame or layer link and the implemented UI must be visually checked before code review.
---

# Matt flow with design QA

Read `../matt-workflow/SKILL.md`, `~/.agents/skills/figma/SKILL.md`, `~/.pi/agent/skills/browser-debug/SKILL.md`, and `~/.pi/agent/skills/simplify/SKILL.md` before starting. The existing Matt workflow is the baseline. Keep it unchanged and add the design phase below.

`$@` contains the effort name and, ideally, the exact Figma frame or layer URL. Do not start implementation without an exact design target. Ask for the URL and target states or viewports when they are missing.

## 1. Pin the work

Record the effort name and pre-work fixed point before dispatching a child. In this JJ repo, use `jj workspace root`, `jj status`, and the fixed point required by `matt-workflow`.

Completion criterion: the fixed point, effort, Figma target, and requested UI scope are explicit.

## 2. Add Figma evidence to the grill

Use Claude Code for this phase. Its installed Figma plugin is already connected, while Pi's separate Figma server may use a different authentication setup.

1. Create a temporary request file containing the exact Figma frame or layer links, target states, viewport sizes, and the request for a design brief. Run `~/.pi/agent/scripts/claude-design-task.sh` with that file. Ask Claude to leave the brief in a second temporary file and make no repository edits.
2. Claude must follow the Figma skill's required order: call `get_design_context` for the exact node first, use `get_metadata` only when the context is too large, then call `get_screenshot` for every target state or variant. It should use `get_variable_defs` and `get_code_connect_map` when token or component decisions affect the work.
3. Read the design brief and pass it to `grill-me-with-docs`: exact links and node IDs, states, viewport sizes, relevant tokens, existing component mappings, behavior, visual acceptance criteria, and any screenshot observations. Treat Figma output as design evidence, not production code.
4. Start `grill-me-with-docs` in a fresh named session exactly as `matt-workflow` does. Include the design brief in its initial handoff. Relay one question at a time. If a question needs more Figma evidence, run another focused Claude request before answering and add the decision to the routed docs.

If Claude Code or its Figma plugin fails, stop with the command output. Do not silently fall back to guessed design values or Pi's unauthenticated Figma server.

Completion criterion: the user has approved ready document paths, and those documents contain the Figma target, visual acceptance criteria, token and component decisions, responsive states, and any intentional deviations.

## 3. Implement normally

Run the existing `matt-workflow` implementation handoff with the approved documents, fixed point, acceptance criteria, exclusions, and design decisions. Use a fresh ephemeral `implement` context. Do not run `code-review` yet.

Completion criterion: implementation and normal verification are complete, with the changed routes or UI entry points identified for visual QA.

## 4. Run visual QA before review

Dispatch the `design-qa` agent ephemerally with `initialContext: "empty"`. Pass it the fixed point, approved document paths, exact Figma links, target states and viewports, changed UI scope, route or dev-server URL, and the design acceptance criteria. It delegates the Figma and browser work to Claude Code, which may edit the implementation. It must not edit the design documents or commit.

The agent must:

- Delegate to Claude Code through `~/.pi/agent/scripts/claude-design-task.sh`. Claude re-fetches the Figma context and reference screenshots through its connected Figma MCP.
- Have Claude open the running implementation in a browser. Prefer the already-open Arc window through Claude's Chrome integration. Otherwise use the browser-debug CDP fallback and its `screenshot` command.
- Capture a Figma and implementation screenshot for every target state and viewport. Compare each pair at the same dimensions and in the same browser state.
- Iterate on the implementation until material differences are gone. Prefer existing components and design-system tokens. Keep custom CSS to geometry or behavior the system cannot express. Preserve accessibility and responsive behavior.
- Leave screenshots in a temporary directory, never in the repository, and report the paths or observations needed to reproduce the comparison.

Treat browser font rendering, antialiasing, and other renderer-only differences as noise. Do not add one-off styles or brittle pixel hacks to erase them. If Claude Code, its Figma plugin, the browser, the dev server, or a required state is unavailable, return `BLOCKED` with the exact missing prerequisite instead of guessing.

Completion criterion: every requested state and viewport has been captured and compared, no material visual discrepancy remains, and any unavoidable or intentional deviation is named.

After `design-qa` returns aligned, run `simplify` over the final diff. If it edits the visual scope, run the affected screenshot comparisons again and repeat `simplify` until it is clean. Do not advance to review while either the visual check or the simplify gate is unresolved.

## 5. Continue with Matt review

Run the existing `code-review` phase ephemerally with the original fixed point and approved spec paths. Include the visual QA result and any intentional deviations in the handoff. It performs the normal Standards and Spec axes and makes no edits.

Return implementation verification, visual QA status and evidence, the two review axes, and every unresolved finding. Keep the Figma or browser setup blocker explicit if the flow could not complete.
