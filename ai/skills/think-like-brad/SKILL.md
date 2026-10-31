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
- Keep public-facing docs focused on caller-visible behavior and contract; put implementation
  mechanics in internal docs or ADRs.
- Keep always-loaded agent entrypoints thin: put stable repository maps, commands, and area
  conventions in README/reference docs, leaving AGENTS files for agent-specific guardrails and
  routing.
- Default to boring, maintainable solutions. Propose a bold solution when it meaningfully wins;
  boring is the default, not the ceiling.
- For design-driven UI, use Figma for visual truth and the live prototype for user-facing wording;
  do not infer either source from the other. Prefer a design-system size variant when it is close
  enough to the design rather than hardcoding local width, height, and padding.

## Workflow and environment

- Keep personal environment and workflow overrides in dotfiles or ignored local config. Shared
  repository behavior should be shaped by team needs, not one machine.
- For local visual testing, use Helium. Prefer an already-open Helium window; otherwise launch
  the isolated Helium profile and ask for authentication before continuing. Zen is the daily
  browser, but Helium is the Chromium QA target.
- Keep local JJ bookmarks aligned with their GitHub refs when rebasing; use the remote bookmark as
  the destination so the resulting stack matches the published base and any merged main history.
- Name JJ bookmarks and branches with `<type>/<ticket>-<short-kebab-summary>` (for example,
  `feat/PEP-6057-add-copy-links`) instead of relying on auto-generated `temp/...` names.
- Keep issue tickets focused on the problem, fix, and acceptance criteria. Use brief implementation
  hints when useful; omit QA history, background, and explicit exclusions because unlisted work is
  already out of scope.

## Reviewing someone else's PR

Default to Sara's frontend expertise on refactors, cleanup, readability, and design-system fit.
Adopt her concrete recommendations unless product requirements, design evidence, or an external
contract gives a specific reason not to; do not push back with generic implementation arguments.
Treat a quick SME or author draft as design evidence, not a drop-in patch. Review its behavioral
tradeoffs against the current contract before applying it wholesale.

Frame each item as a clarifying question, then offer a concrete fix when one exists. The
question leaves room for context the author has; the fix makes the comment actionable. Name a
real tradeoff when the right answer depends on product or architecture context.

Keep posted comments short and conversational. A one-line question is enough when the cost is
obvious, such as a type alias or wrapper that only adds maintenance. Use "just calling it out"
for a valid concern that should not block. Non-blocking comments can accompany an approval.

Calibrate severity to practical product behavior. Distinguish a caller-visible product regression
from an API correctness cleanup with no current product caller; keep the latter non-blocking unless
an external contract makes it release-critical. Keep a valid but domain-inapplicable edge case
separate from a release blocker. Defer hypothetical edge-case fixes until they occur or product
requirements make them worth the added complexity. Do not inflate small test gaps when the
implementation appears correct. When cleanup is already planned in a separate bookmark, do not duplicate it in the
current PR unless leaving it out would make current behavior unsafe or broken.

When drafting feedback for Brad to post, write each item as plain text. Start with the location
heading, put the comment body below it, and separate items with `---`. The heading is for Brad;
post only the body:

PR > Issue #n > file/location (blocking/non-blocking/nit)
Clarifying question and evidence.

Possible fix: concrete change.

Number issues within each PR. Use the file and line where the comment should be posted. Mark
each item blocking, non-blocking, or nit.
