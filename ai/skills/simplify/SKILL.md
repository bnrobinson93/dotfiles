---
name: simplify
description: >-
  Last gate before handback: enforce the house code-quality bar over the finished diff, comments
  first. Run it after the final edit of a coding task, before saying the work is done, before
  filing a PR, and whenever Brad asks to simplify, tidy, or clean up a change. Skipping it is a
  defect, not a judgment call.
---

# Simplify

The last pass before handback, and the whole house bar in one place. Work first; this pass makes
the finished diff meet the bar, then reports.

## Steps

1. **Scope.** The boundary is the code this task touched; a violation elsewhere is one line in
   the report. Made every edit this session: read the diff from context. Otherwise run
   `jj diff` (`git diff` in a git repo). Complete when you have read every hunk.
2. **Comments first.** Hold each comment against the closed list below. Complete when every
   comment in the diff is on it.
3. **The rest of the bar**, below, plus `references/tests.md` where the diff touches tests.
   Fix each offender inside the boundary. Complete when each offender is fixed or named in the
   report with its reason for staying.
4. **Report** what you deleted and why in a line or two.

## The bar

## Laziness

Lazy means efficient, not careless: the diff's best outcome is getting shorter. After reading
the task and tracing the real flow end to end, stop at the first rung that holds:

1. Does this need to be built at all?
2. Does a helper, type, or pattern already in this codebase cover it? Reuse it.
3. Does the standard library, a native platform feature, or an installed dependency cover it?
4. Can it be one line?
5. Only then write the minimum code that works.

- **Bug fix means root cause.** A report names a symptom. Grep every caller of the function you
  are about to touch: one guard in the shared function beats a guard in every caller, and
  patching only the ticket's path leaves the sibling callers broken.
- Build the abstraction when it was asked for. Delete placeholder knobs, future-facing APIs, and
  CLI flags nobody asked for; a flag arrives when a caller needs to vary that input.
- Deletion over addition, boring over clever, fewest files possible. Between two same-size
  stdlib approaches take the edge-case-correct one.
- Mark an intentional simplification with a `ponytail:` comment naming its ceiling (global lock,
  O(n²) scan, naive heuristic) and the upgrade path.
- Compute values from data already in scope instead of passing a redundant argument. One concept
  gets one authoritative home that consumers reuse.
- Laziness stops at trust-boundary validation, error handling that prevents data loss,
  security, accessibility, hardware calibration, and anything explicitly requested.
- Non-trivial logic leaves ONE runnable check behind: the smallest thing that fails if the logic
  breaks. No frameworks, no fixtures; a trivial one-liner needs none.

## Naming and shape

- Names carry the meaning. Booleans read as states (`isConfigured`, `lastWasDash`), never
  `complete` or `dash`. Shared abstractions and specialized adapters get names that show which
  one callers use.
- Extend the existing test fake or type (`Omit`, a union) rather than hand-rolling a parallel one.
- Flatten ternaries to one level, then use an `if` or a lookup. Compute once and keep the
  result; two near-identical functions become one.
- Take O(n²) to O(1) when one simple function does it, and stop short of over-engineering.
- Derive an external string (a URL value) from an already-imported generated enum; the generated
  contract stays the source of truth.
- Group related settings in one object and derive aggregate predicates from its values, so a new
  setting needs no parallel edit to every condition.
- Keep a one-caller predicate or one-use visual wrapper in its owning module until a real second
  consumer or a need for isolation justifies extracting it. Express presentational responsive
  behavior in CSS media queries; keep `matchMedia` state in JavaScript only when CSS cannot.
- Wrapping a design-system component: intersect its props instead of duplicating them, let its
  documented defaults do the work, and keep only behavior-specific props and overrides.
- A generic helper takes the enum or configuration that fixes its concrete type at the call
  site, never an unsafe-cast default.
- Revert formatting-only changes when the reviewed behavior is unchanged.
- A function that accepts several equivalent input forms keeps a thin dispatcher and one named
  helper per form.
- Task wrappers declare and forward child-command options directly, so callers skip the `--`.
- Security fixes stay on the requested behavior: no logger injection or logging-only tests
  unless logging is part of the contract.
- Merge overlapping types, functions, constants, and prompt instructions. In generated prompts,
  put the authoritative guidance after the bulky source material.
- Route UI colors through the design system's theme tokens (`useTheme`, theme callbacks,
  exported token APIs). A literal hex needs Brad's explicit request. Let themed components
  supply their defaults and add local styling only for behavior or geometry the theme cannot
  express.

## Comments

Say it in the code: rename, or extract the confusing expression into a named chunk. A comment
is the last resort and explains *why*; the code explains *what*. This list is closed, and a
comment outside it gets deleted:

- **Gotchas**: non-obvious code that breaks core behavior if changed. Name the consequence, not
  the mechanics.
- **Public interfaces**, one or two lines, where the language expects it (Go doc comments).
- **Constraints code cannot hold**: ordering rationale, a security constraint, an external
  contract, a thread-safety or long-running warning.
- **A regex**, decoded in plain words.
- **Canonical tags**: `TODO`, `NOTE`, `INFO`, `WARN`, `HACK`, `PERF`, `FIX`, `ponytail`.
- **Copyright headers** the repo requires.

When the same *why* lives at its real home (the function, an ADR, a spec), the call site stays
quiet. Delete on sight: restatement of code or types, mumbling and author's notes, changelog
entries, long javadoc where types would do, block quotes around one line, position markers,
closing-brace labels, commented-out code, and comments about code elsewhere.
