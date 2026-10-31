---
name: think-like-brad
description: >-
  Brad's cross-project judgment and working preferences outside the `AGENTS.md` code bar. Use before
  putting a solution to paper when choosing among valid approaches, reviewing someone else's PR,
  architecting or scoping a solution, planning workflow or issue content, or asking for a subjective
  preference.
---

# Think Like Brad

Apply every preference that matches the task.

## Before putting a solution to paper

Settle the relevant scope, approach, and workflow before implementation. Keep the decision stable
through the change; revisit it only when new facts invalidate it.

## General judgment

- Explain reasoning when useful, ask only when a tradeoff is genuinely unclear, and change course
  when new facts change the answer.
- Keep scope tight and call out scope creep when it appears.
- When a PR spans independent configuration areas, split the JJ changes when practical; if one PR is intentional, organize the description by area.
- Keep public-facing docs focused on caller-visible behavior and contract. Do not publish internal
  tickets, staging evidence, endpoint topology, backend implementation, or review/process notes;
  put implementation mechanics and operational history in internal docs or ADRs.
- For public SDKs, keep one-off decision evidence out of shipped benchmark tests when the benchmark
  exists only to justify a removal. Run it privately and record concise, caveated results in the
  ADR instead; the benchmark is process evidence, not part of the public contract.
- Keep always-loaded agent entrypoints thin: put stable repository maps, commands, and area
  conventions in README/reference docs, leaving AGENTS files for agent-specific guardrails and
  routing.
- Default to boring, maintainable solutions. Propose a bold solution when it meaningfully wins;
  boring is the default, not the ceiling.
- When one shared UI behavior serves containers with materially different rendered widths, prefer a
  centralized overflow-aware solution over a single character threshold when the extra complexity
  buys correctness across those callers.
- When an enhancement depends on a control being usable, omit the enhancement while that control is
  disabled or loading rather than wrapping the disabled control just to preserve the enhancement.
- Keep shared workflow setup, but split tests when one test asserts distinct behaviors and a failure
  would otherwise be hard to localize.
- When code has committed and pending versions of the same state, name those sources explicitly so
  a reader cannot mistake which UI behavior each one drives.
- For design-driven UI, use Figma for visual truth and the live prototype for user-facing wording;
  do not infer either source from the other. Prefer a design-system size variant when it is close
  enough to the design rather than hardcoding local width, height, and padding.

## Workflow and environment

- Preserve a fast project switcher and parent-folder project finder in editor and terminal workflows; a two-project hotkey and the ability to open an unseen repo matter more than replacing them with a slower recent-project picker.
- Let Obsidian manage frontmatter timestamps for vault notes; do not manually update them when editing note content.
- Keep personal environment and workflow overrides in dotfiles or ignored local config. Machine-generated
  tool output belongs in ignored include files, not stowed tracked config. Shared repository behavior
  should be shaped by team needs, not one machine.
- Put confirmation before destructive close actions when a persistent background session is the recovery path.
- On macOS work machines, preserve the paid-model quality target for AI-assisted developer
  workflows; prefer the configured default paid model and do not upgrade to a newer or more
  expensive model without a task-specific reason. When a paid model fails, switch to another paid
  model rather than falling back to a free model.
- When a workflow names a provider and model to preserve, do not silently substitute another model
  because the named route fails; surface the routing problem and get approval for a fallback.
- For local visual testing, use Helium. Prefer an already-open Helium window; otherwise launch
  the isolated Helium profile and ask for authentication before continuing. Zen is the daily
  browser, but Helium is the Chromium QA target.
- In JJ worktrees, snapshot the source worktree with `jj`, `jj status`, or `jj diff -s` before
  handing it to another workspace. In the target workspace, use `jj new <source-workspace>@` to
  jump on top of that snapshot. The snapshot and the workspace handoff are separate steps.
- Keep local JJ bookmarks aligned with their GitHub refs when rebasing; use the remote bookmark as
  the destination so the resulting stack matches the published base and any merged main history.
- In a stacked effort, stabilize the upstream bookmark before iterating on downstream bookmarks;
  downstream work may change while the earlier PR is still moving.
- Treat pushing, replying to review comments, and resolving threads as a hard publication gate:
  wait for Brad's explicit approval after the final review, even when the work appears ready.
- Treat schema and migration changes as architectural scope, not routine cleanup. Do not add one to
  close a low-severity edge case without first surfacing the tradeoff and getting approval; prefer
  the smallest local fix or document the residual risk.
- Name JJ bookmarks and branches with `<type>/<ticket>-<short-kebab-summary>` (for example,
  `feat/PEP-6057-add-copy-links`). Create or rename that bookmark before pushing. Never let a
  ticketed effort ship under an auto-generated `temp/...` name.
- Keep issue tickets focused on the problem, fix, and acceptance criteria. Use brief implementation
  hints when useful; omit QA history, background, and explicit exclusions because unlisted work is
  already out of scope.

## Reviewing someone else's PR

Default to Sara's frontend expertise on refactors, cleanup, readability, design-system fit, and
user-facing wording. Don't question her copy or branding choices just because the ticket text
differs; she usually has product context the ticket lacks.
Adopt her concrete recommendations unless product requirements, design evidence, or an external
contract gives a specific reason not to; do not push back with generic implementation arguments.
Treat a quick SME or author draft as design evidence, not a drop-in patch. Review its behavioral
tradeoffs against the current contract before applying it wholesale.

Frame each item as a clarifying question, then offer a concrete fix when one exists. The
question leaves room for context the author has; the fix makes the comment actionable. Name a
real tradeoff when the right answer depends on product or architecture context.

Prefer explicit intermediate style or state variables over nested ternaries when deriving UI
props; keep conditional composition readable at a glance.

Keep posted comments short and conversational. A one-line question is enough when the cost is
obvious, such as a type alias or wrapper that only adds maintenance. Use "just calling it out"
for a valid concern that should not block. Non-blocking comments can accompany an approval.

Calibrate severity to practical product behavior. Distinguish a caller-visible product regression
from an API correctness cleanup with no current product caller; keep the latter non-blocking unless
an external contract makes it release-critical. Keep a valid but domain-inapplicable edge case
separate from a release blocker. Defer hypothetical edge-case fixes until they occur or product
requirements make them worth the added complexity. Do not inflate small test gaps when the
implementation appears correct. A unit test that mocks a collaborator and asserts the call
contract is fine at the unit level; proving the rendered end-to-end outcome is integration
coverage, so don't flag the unit test for not doing it. When cleanup is already planned in a separate bookmark, do not duplicate it in the
current PR unless leaving it out would make current behavior unsafe or broken.

When drafting feedback for Brad to post, write each item as plain text. Start with the location
heading, put the comment body below it, and separate items with `---`. The heading is for Brad;
post only the body:

PR > Issue #n > file/location (blocking/non-blocking/nit)
Clarifying question and evidence.

Possible fix: concrete change.

Number issues within each PR. Use the file and line where the comment should be posted. Mark
each item blocking, non-blocking, or nit.
