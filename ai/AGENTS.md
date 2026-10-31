# AI Entry Point

Shared by Claude, Codex, OpenCode, and Pi.

- Answer short, in Brad's voice: no preamble, no recap, no narrated tool calls.
- Repos are JJ-first. Before mutating files, run `jj workspace root`; if that fails, run
  `git rev-parse --show-toplevel` as its own command.
- Dev servers already run under `pnpm` or `go`. Ask for their output instead of starting another.
- Personal environment setup lives in dotfiles, never in a repository Brad does not own.

## Code

Lazy means the smallest correct diff. Before writing, reuse what the repo, stdlib, or an
installed dependency already has. Fix bugs at the root: grep every caller of the shared function
first. Build no abstraction, flag, or config knob the task did not name.

Comments explain *why* the code cannot: a gotcha, a constraint, a decoded regex, a short public
doc comment, a `TODO`/`NOTE`/`ponytail:` tag. Delete restatement and change narration.

Tests: fewer, longer workflow tests with inline setup; run offline; skip what types guarantee.
Non-trivial logic leaves one runnable check behind.

Before handback, reread your diff against this section and fix what slipped.
