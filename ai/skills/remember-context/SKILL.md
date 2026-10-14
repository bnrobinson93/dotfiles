---
name: remember-context
description: Store durable project or user memory for future sessions. Use when Brad asks you to remember a decision, a code nuance, a workflow, a preference, or where something lives.
---

# Remember context

1. Resolve the memory directory. When the harness names one in its own instructions, that is
   the one. Otherwise derive `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/<slug>/memory/`,
   where `<slug>` is the workspace root with every `/` and `.` replaced by `-`
   (`pwd | sed 's#[./]#-#g'`, so `/home/brad/.dotfiles` becomes `-home-brad--dotfiles`)
2. Read `MEMORY.md` there
3. Follow existing links relevant to the subject
4. Add or update one focused file in the same `memory/` directory
5. Add one concise bullet to `MEMORY.md` linking that file
6. Capture `Why`, `Applies to`, and `Failure mode` when useful

Store durable facts: a decision and its reason, a constraint, a workflow, where something
lives. Secrets, transient task state, and anything the repository files already say stay out.
