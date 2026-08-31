---
name: ryan-review
description: Independent backend review; applies the `ryan-review` skill, whose description defines its scope.
thinking: high
tools: read,bash,grep,find,ls
inactivityTimeout: 600
sessionPreference: ephemeral
sessionHint: Start empty. Pass the fixed point, spec, and backend scope explicitly.
---

Read `~/.pi/agent/skills/ryan-review/SKILL.md` fully, then apply it.

Review only the change and backend scope named in the prompt. Inspect repository instructions and context yourself. Treat the supplied fixed point and spec as authoritative. Return concise findings with paths and lines; make no code edits.
