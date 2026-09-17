# Laziness

Lazy means efficient, not careless. The best code is the code never written. This is the
ponytail senior dev's instinct: the diff's best outcome is getting shorter.

## The ladder

Before writing any code, stop at the first rung that holds:

1. Does this need to be built at all? (YAGNI)
2. Does a helper, util, type, or pattern already in this codebase cover it? Reuse it.
   Re-implementing what lives a few files over is the most common slop.
3. Does the standard library already do this? Use it.
4. Does a native platform feature cover it? Use it.
5. Does an already-installed dependency solve it? Use it.
6. Can this be one line? Make it one line.
7. Only then: write the minimum code that works.

The ladder runs *after* you understand the problem, not instead of it. Read the task and the
code it touches, trace the real flow end to end, then climb. The smallest change in the wrong
place isn't lazy, it's a second bug.

## Bug fix means root cause

A report names a symptom. Before editing, grep every caller of the function you are about to
touch. One guard in the shared function is a smaller diff than a guard in every caller, and
patching only the path the ticket names leaves every sibling caller broken.

## Rules

- Build the abstraction when it was asked for, and not before.
- Solve it with what the project already depends on.
- Deletion over addition. Boring over clever. Fewest files possible.
- Question a complex request: "Do you actually need X, or does Y cover it?"
- When two stdlib approaches are the same size, take the edge-case-correct one. Lazy means less
  code, not the flimsier algorithm.
- Mark an intentional simplification with a `ponytail:` comment. When the shortcut has a known
  ceiling (global lock, O(n²) scan, naive heuristic), the comment names the ceiling and the
  upgrade path.
- Delete unused configuration and future-facing APIs until concrete behavior needs them.
  Placeholder knobs create compatibility debt and invite callers to depend on no-ops.
- Compute values from data already in scope rather than passing a redundant prop or argument.
  Redundant inputs increase coupling.
- One concept, one authoritative home. Consumers reuse or inject it rather than copy it.

## Where laziness stops

Input validation at trust boundaries, error handling that prevents data loss, security,
accessibility, the calibration real hardware needs (the platform is never the spec ideal, a
clock drifts, a sensor reads off), and anything explicitly requested.

Lazy code without its check is unfinished. Non-trivial logic leaves ONE runnable check behind:
the smallest thing that fails if the logic breaks, an assert-based demo or one small test file.
No frameworks, no fixtures. Trivial one-liners need no test.
