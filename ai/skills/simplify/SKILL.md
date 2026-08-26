---
name: simplify
description: Review finished code against Brad's cross-project coding style, simplifying and streamlining before handback. Use automatically whenever coding is done and ready for user review. Repository and domain decisions belong in project memory, not this skill.
---

# Simplify

Review changes in the current branch or jj bookmark, or in the state the user specifies.
Only touch code in the staged diff. Apply every preference below and correct violations
before handback. Keep only rules that remain useful across unrelated repositories. Store SDK,
service, API, schema, architecture, business, and other repository-specific decisions in
project memory.

## Learned cross-project preferences

- Use relevant, precise names. Prefer `isConfigured` over `complete`; boolean names should
  read as states, not commands.

- Combine overlapping types, functions, constants, or behavioral instructions. One concept
  should have one authoritative home; consumers should reuse or inject it rather than copy it.
  In generated prompts, place authoritative guidance after bulky source material so examples
  cannot drown it out.

- Compute values from data already in scope instead of passing redundant props or arguments;
  redundant inputs increase coupling.

- In tests and fixtures, derive values through the same production helper the code under test
  uses, then pass them in; do not reimplement that logic in hand-written SQL or string
  concatenation. Duplicated derivation silently drifts from production (format, canonicalization),
  so the test passes against the wrong shape.

- Delete comments that restate what the code or a type signature already says; they are clutter
  that must be kept in sync for no gain. Keep only the non-obvious why (security constraints,
  ordering rationale, external contracts). When the same why is already documented at its real
  home (the function it describes, an ADR, a spec), do not duplicate it at the call site.

- Task wrappers should declare and forward child-command options directly so callers do not need
  a `--` separator between the wrapper and its arguments.

- Keep personal environment and workflow overrides in dotfiles or ignored local config. Do not
  change a shared repository's tracked behavior to accommodate one developer's machine.
