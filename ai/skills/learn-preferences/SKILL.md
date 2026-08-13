---
name: learn-preferences
description: Learn Brad's durable coding preferences from feedback and update the simplify review checklist. Use automatically when Brad says he left review, comments, or feedback in tuicr or hunk; gives corrective coding feedback in chat; or uses a generalizing coding phrase such as "that should not...", "we should...", "always...", "never...", or "I prefer...".
---

# Learn Preferences

Turn user-authored coding feedback into one reusable review rule with its rationale. Keep
`../simplify/SKILL.md` canonical; this skill owns capture, not a second preference list.

## Workflow

1. Collect the exact feedback and relevant code context.
   - For tuicr, apply the `tuicr` skill and read fresh user comments.
   - For hunk, apply the `hunk-review` skill and read fresh user comments.
   - Exclude agent-authored comments. Treat praise or questions as preferences only when
     they state a reusable choice.
   - If no review tool is named, use the established review session or the chat statement.
   - Ask only when competing interpretations would produce materially different rules.

   Complete when every available user-authored feedback item is accounted for.

2. Handle the immediate feedback within the current task's authority. Learning supplements
   the requested fix, explanation, or review response; it does not replace it.

   Complete when each item is addressed or explicitly reported as out of scope.

3. Distill durable lessons.
   - Separate task-specific defects from preferences likely to recur.
   - Generalize beyond current file, symbol, or implementation without broadening past the
     evidence.
   - Phrase the desired behavior positively. Include scope and rationale or failure mode.
   - Preserve qualifiers. Use `always` or `never` only when Brad did.
   - Merge multiple comments when one rule explains them. Skip one-off facts that cannot
     support a reusable rule.

   Example: "That should not be another helper" becomes "Keep single-use straight-line
   logic at its call site; extracting it adds navigation without reuse or isolation value."

   Complete when every reusable lesson is a standalone rule with a reason.

4. Update the canonical rule once.
   - Read `../simplify/SKILL.md` and search for equivalent or conflicting guidance.
   - Strengthen an existing rule before adding another. Replace superseded guidance when
     newer explicit feedback conflicts.
   - Add new rules to its learned preferences.
   - Preserve unrelated edits and repository-local conventions.

   Complete when each lesson has one authoritative home and no semantic duplicate.

5. Verify the diff. Confirm each edit is generic, scoped, rationale-bearing, and faithful to
   the feedback. Report the learned rule and where it was stored.
