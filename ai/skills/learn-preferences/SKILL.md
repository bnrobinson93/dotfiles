---
name: learn-preferences
description: >-
  Route Brad's coding feedback to one durable home. Always invoke when he asks you to read his
  review comments in tuicr or hunk, corrects a coding choice in chat, or states a reusable rule
  ("that should not...", "we should...", "always...", "never...", "I prefer...").
---

# Learn Preferences

Turn user-authored coding feedback into one durable lesson with its rationale. Each lesson
lands in exactly one of three homes:

| Home | Holds |
| --- | --- |
| `~/.dotfiles/ai/skills/code-quality/references/` | The standing bar: comments, tests, laziness |
| `~/.dotfiles/ai/skills/simplify/SKILL.md` | Learned cross-project preferences |
| Project memory, via `remember-context` | Repository and domain knowledge |

This skill owns capture and routing. The preference list itself lives in those homes.

## Workflow

1. Collect the exact feedback and relevant code context.
   - For tuicr, apply the `tuicr` skill and read fresh user comments.
   - For hunk, apply the `hunk-review` skill and read fresh user comments.
   - Filter by displayed author or provenance. Count only Brad-authored feedback. Exclude
     comments marked AI, agent, or auto, including Ryan and Sara/Sarah review responses.
   - Treat praise or questions as preferences only when they state a reusable choice.
   - If no review tool is named, use the established review session or the chat statement.
   - Ask only when competing interpretations would produce materially different rules.

   Complete when every available user-authored feedback item is accounted for.

2. Handle the immediate feedback within the current task's authority. Learning supplements
   the requested fix, explanation, or review response; it does not replace it.

   Complete when each item is addressed or explicitly reported as out of scope.

3. Classify and distill durable lessons.
   - Apply the portability test: a style preference remains useful and true across unrelated
     repositories after replacing the current product, SDK, service, and domain nouns.
   - Cross-project style includes naming, code shape, abstraction, readability, comments,
     testing style, and complexity choices.
   - Repository or domain knowledge includes SDK and API contracts, schemas, architecture,
     authentication behavior, business rules, deployment constraints, and local conventions.
     Route it to the originating project's memory with the `remember-context` skill.
   - Keep task-specific defects in the current task unless they reveal a durable lesson.
   - Generalize style beyond the current file, symbol, or implementation without broadening
     past the evidence. Preserve repository and domain knowledge at its real scope.
   - Phrase the desired behavior positively. Include scope and rationale or failure mode.
   - Preserve qualifiers. Use `always` or `never` only when Brad did.
   - Merge multiple comments when one rule explains them. Skip one-off facts that cannot
     support a reusable rule.

   Example: "That should not be another helper" becomes "Keep single-use straight-line
   logic at its call site; extracting it adds navigation without reuse or isolation value."

   Counterexample: credential forwarding rules tied to a particular SDK and authentication
   contract belong in that SDK repository's memory, not the shared style checklist.

   Complete when every reusable lesson is a standalone rule with a reason.

4. Update each lesson's canonical home once.
   - For cross-project style, read simplify and the matching `code-quality` reference file,
     then search both for equivalent or conflicting guidance. Comment, test, and
     over-engineering rules belong in the reference file; everything else goes in simplify's
     learned preferences. Strengthen an existing rule before adding another, and replace
     superseded guidance when newer explicit feedback conflicts, so the rule keeps one home.
   - For repository or domain knowledge, resolve the originating project from the review
     session, working directory, or code context, then apply `remember-context`. Ask only when
     multiple projects remain plausible.
   - Preserve unrelated edits and repository-local conventions.

   Complete when each lesson has one authoritative home and no semantic duplicate.

5. Verify the result. Confirm each style edit passes the portability test and each memory keeps
   its repository or domain scope. Report every learned lesson and its canonical home.
