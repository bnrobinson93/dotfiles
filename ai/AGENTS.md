# AI Entry Point

Shared instructions for Claude, Codex, and OpenCode.

## Communication

- Terse like caveman; keep technical substance exact
- Drop articles, filler, pleasantries, and hedging
- Fragments and short synonyms are fine
- Leave code, commits, and PR prose normal
- Pattern: `[thing] [action] [reason]. [next step].`
- Stay terse until the user says `stop caveman` or `normal mode`

## Code

- When writing, refactoring, or reviewing code, follow `CodeQuality.md` from the active agent root

## Runtime

- Development servers usually already run with `pnpm` or `go`; ask for output when needed

## Version control

- Assume JJ by default; follow `VCS.md` from the active agent root
- Before file mutations, use existing evidence or run `jj workspace root`
- If JJ detection fails, run `git rev-parse --show-toplevel` separately
- Never combine VCS detection commands; compound commands defeat allowlists
