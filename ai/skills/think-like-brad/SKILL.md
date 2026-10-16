---
name: think-like-brad
description: >-
  Brad's cross-project judgment and working preferences outside the code-quality bar. Use before
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
- Default to boring, maintainable solutions. Propose a bold solution when it meaningfully wins;
  boring is the default, not the ceiling.

## Workflow and environment

- Keep personal environment and workflow overrides in dotfiles or ignored local config. Shared
  repository behavior should be shaped by team needs, not one machine.
- Keep local JJ bookmarks aligned with their GitHub refs when rebasing; use the remote bookmark as
  the destination so the resulting stack matches the published base and any merged main history.
- Keep issue tickets focused on the problem, fix, and acceptance criteria. Use brief implementation
  hints when useful; omit QA history, background, and explicit exclusions because unlisted work is
  already out of scope.

## Reviewing someone else's PR

Frame each item as a clarifying question, then offer a concrete fix when one exists. The
question leaves room for context the author has; the fix makes the comment actionable. Name a
real tradeoff when the right answer depends on product or architecture context.

Keep posted comments short and conversational. A one-line question is enough when the cost is
obvious, such as a type alias or wrapper that only adds maintenance. Use "just calling it out"
for a valid concern that should not block. Non-blocking comments can accompany an approval.

When drafting feedback for Brad to post, write each item as plain text. Start with the location
heading, put the comment body below it, and separate items with `---`. The heading is for Brad;
post only the body:

PR > Issue #n > file/location (blocking/non-blocking/nit)
Clarifying question and evidence.

Possible fix: concrete change.

Number issues within each PR. Use the file and line where the comment should be posted. Mark
each item blocking, non-blocking, or nit.
