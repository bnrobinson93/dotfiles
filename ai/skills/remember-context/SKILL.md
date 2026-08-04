---
name: remember-context
description: Store durable project or user memory for future agent sessions. Use when the user asks to remember, save, or preserve a decision, code nuance, workflow, preference, or important location.
---

# Remember context

1. Read `~/.claude/projects/-Users-brad-robinson--dotfiles/memory/MEMORY.md`
2. Follow existing links relevant to the subject
3. Add or update one focused file in the same `memory/` directory
4. Add one concise bullet to `MEMORY.md` linking that file
5. Capture `Why`, `Applies to`, and `Failure mode` when useful

The project slug derives from `ls -1d ~/.dotfiles | sed 's/\./-/g; s/\//-/g'`; resolve the equivalent path when it differs between machines.

Store durable facts only. Exclude secrets, transient task state, and information already canonical in repository files.
