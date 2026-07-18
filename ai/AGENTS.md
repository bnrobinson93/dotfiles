# AI Entry Point

Shared instruction entry point for Claude, Codex, and OpenCode.

## Communication Style

- Terse like caveman. Technical substance exact. Only fluff die.
- Drop: articles, filler (just/really/basically), pleasantries, hedging.
- Fragments OK. Short synonyms.
- Code unchanged.
- Pattern: [thing] [action] [reason]. [next step].
- ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift.
- Code/commits/PRs: normal.
- Off: "stop caveman" / "normal mode".

## Running Development Servers

Dev server already running with `pnpm` or `go`. Can provide output if needed.

## Shared Memory

For durable project/user memory, read: `~/.claude/projects/-Users-brad-robinson--dotfiles/memory/MEMORY.md`

Note that "-Users-brad-robinson--dotfiles" is taken from `ls -1d ~/.dotfiles | sed 's/\./-/g; s/\//-/g'` so it may differ between machines

Follow links from that MEMORY.md when relevant.

When user asks to remember a decision, code nuance, workflow, or location:

- Add/update a focused file in that `memory/` dir.
- Add one bullet to `MEMORY.md` linking it.
- Capture Why, Applies to, and Failure mode when useful.

## VCS - Version Control

I generally work in JJ VCS, as such, assume that you're in a JJ workspace by default. Before starting work that would mutate files, unless I already stated that it's git vs jj, detect whether in a JJ or git repo, so that you're grounded in reality. Refer to VCS.md (at root, e.g. ~/.claude or ~/.codex) for details.

To detect the VCS, prefer evidence already in context (a `.jj` directory in a listing means JJ, even when `.git` also exists — colocated). Otherwise run `jj workspace root`; if it succeeds, JJ. If it fails, run `git rev-parse --show-toplevel`; if it succeeds, git; otherwise no VCS. Run these as two separate plain commands — never wrap them in subshells, `&&`/`||` chains, or redirects, because compound commands defeat command allowlists and force approval prompts.

## Writing Voice

Before writing or editing long-form prose, documentation, decision docs, READMEs, or publishable code comments, MUST read WritingVoice.md (at root, e.g. ~/.claude or ~/.codex). Applies when prose matters or user will share the artifact. Does not apply to caveman-mode chat, terse status updates, or routine code.

## Code Quality

When coding, consider CodeQuality.md (at root, e.g. ~/.claude or ~/.codex)

## Skills

skills/<name>/SKILL.md (at root, e.g. ~/.dotfiles/ai/skills) for named or clearly applicable local skills. Read the specific skill only when needed.

Codex sandbox note: `hunk session` commands talk to a local daemon on 127.0.0.1, which the sandbox blocks. In Codex, request escalated permissions upfront for `hunk session` commands (with a one-line justification) instead of running sandboxed first, failing, and retrying.

## Caveman

caveman.md (at root, e.g. ~/.claude or ~/.codex) for explicit caveman mode usage.
