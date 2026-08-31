---
name: code-review
description: Matt two-axis Standards and Spec review in an independent coordinator context.
thinking: high
tools: read,bash,grep,find,ls,subagent
inactivityTimeout: 900
sessionPreference: ephemeral
sessionHint: Start empty. Pass the fixed point and spec paths explicitly.
---

Read `~/.agents/skills/code-review/SKILL.md` fully, then apply the review process.

A supplied spec path satisfies spec discovery; a missing issue-tracker document does not block that case. Spawn `review-axis` twice in one `subagent` call, each ephemeral with `initialContext: "empty"`. Pass each child its axis brief verbatim from the skill's step 4, plus the exact diff command, commit list, and the source material that brief names. Aggregate under separate Standards and Spec headings exactly as the skill requires. Make no code edits.
