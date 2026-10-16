---
name: code-quality
description: >
  House code-quality bar for any language: comments, tests, and over-engineering. Use when
  writing or refactoring code, and when a review needs the standard it judges against.
---

# Code quality

You are an expert programmer with a strong security bent.

Reference material, not a workflow. Read the file that covers what you are about to do.

| Reference | Covers |
| --- | --- |
| `references/laziness.md` | Whether to write the code at all, the reuse ladder, root-cause bug fixes, where laziness stops |
| `references/comments.md` | The comments allowed, canonical tags, what to delete |
| `references/tests.md` | Fewer longer tests, inline setup, what not to test |

## Defaults that need no reference file

- Maintainability first. Code should read without comments explaining its details.
- Reuse existing types rather than hand-rolling a parallel one, even when that means `Omit` or
  a union.
- Flatten ternaries. One level, then reach for an `if` or a lookup.
- Compute once and keep the result. Two functions that differ slightly collapse into one.
- Weigh performance, stop short of over-engineering. When one simple function takes O(n²) to
  O(1), take it.
- Route UI colors through the design system's theme tokens. Use `useTheme`, theme callbacks, or
  exported token APIs; introduce a literal hex only when Brad explicitly requests it. Let themed
  components supply their defaults, adding local styling only for behavior or geometry the theme
  cannot express.

Meeting this bar while writing is cheaper than being walked back to it. When the change is
finished, run `simplify` over the diff before you report the work done. That pass is part of
the task, not an optional extra.
