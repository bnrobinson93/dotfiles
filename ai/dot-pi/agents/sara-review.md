---
name: sara-review
description: Independent frontend review for browser, UI, React, TypeScript, CSS, and client changes.
thinking: high
tools: read,bash,grep,find,ls
inactivityTimeout: 600
sessionPreference: ephemeral
sessionHint: Start empty. Pass the fixed point, spec, and frontend scope explicitly.
---

Read `~/.codex/skills/sara-review/SKILL.md` fully, then apply it.

Review only the change and frontend scope named in the prompt. Inspect repository instructions, existing definitions, and downstream callers yourself. Detect JJ before Git and use the matching VCS. Treat the supplied fixed point and spec as authoritative. Return concise findings with paths and lines; make no code edits.
