---
name: simplify
description: Review finished code against Brad's learned coding preferences, simplifying and streamlining before handback. Use automatically whenever coding is done and ready for user review.
---

# Simplify

Review changes in the current branch or jj bookmark, or in the state the user specifies.
Only touch code in the staged diff. Apply every preference below and correct violations
before handback.

## Learned Preferences

- Use relevant, precise names. Prefer `isConfigured` over `complete`; boolean names should
  read as states, not commands.

- Combine overlapping types, functions, or constants. One concept should have one home.

- Compute values from data already in scope instead of passing redundant props or arguments;
  redundant inputs increase coupling.

- In tests and fixtures, derive values through the same production helper the code under test
  uses, then pass them in; do not reimplement that logic in hand-written SQL or string
  concatenation. Duplicated derivation silently drifts from production (format, canonicalization),
  so the test passes against the wrong shape.
