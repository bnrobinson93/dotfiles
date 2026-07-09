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

Before starting work that would mutate files, unless I already stated that it's git vs jj, detected whether a JJ or git folder exist. Refer to VCS.md (at root, e.g. ~/.claude or ~/.codex) for details. To check, you can use `(jj workspace root 2&>/dev/null && echo JJ) || (git rev-parse --show-toplevel 2&>/dev/null && echo GIT) || echo NEITHER` in bash

## Writing Voice

WritingVoice.md (at root, e.g. ~/.claude or ~/.codex) for long-form prose, documentation, or code comments where prose matters, decision docs, READMEs, anything user will publish or share. Does not apply to caveman-mode chat, terse status updates, or routine code.

## Code Quality

When coding, consider CodeQuality.md (at root, e.g. ~/.claude or ~/.codex)

## Skills

skills/<name>/SKILL.md (at root, e.g. ~/.dotfiles/ai/skills) for named or clearly applicable local skills. Read the specific skill only when needed.

## Caveman

caveman.md (at root, e.g. ~/.claude or ~/.codex) for explicit caveman mode usage.
