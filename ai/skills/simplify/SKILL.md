---
name: simplify
description: >-
  Last gate before handback: enforce the house bar over the finished diff, comments first. Run
  it after the final edit of a coding task, before saying the work is done, before filing a PR,
  and whenever Brad asks to simplify, tidy, or clean up a change. Skipping it is a defect, not
  a judgment call.
---

# Simplify

The last pass before handback. Everything checked here should already be true when the code was
written; it usually is not. Fix it, then report what you fixed.

## 1. Fix the scope

Read the whole change before editing any of it.

- JJ repo: `jj diff --summary`, then `jj diff` for the files it names. When the work spans
  several changes, use `jj diff -f 'trunk()'`.
- Git repo: `git diff` and `git diff --cached`, or diff against the parent branch when the work
  spans commits.
- "Staged" is not the boundary. The boundary is the code this task touched.
- Keep every edit inside that boundary. A violation in an untouched file is one line in the
  report.

Complete when you have read every hunk in the diff.

## 2. Comments

This is where the bar slips most, so it goes first. Read
`~/.dotfiles/ai/skills/code-quality/references/comments.md` and hold each comment in the diff
against its closed list. What survives is a gotcha, a one-or-two-line public interface note
where the language expects one, a constraint code cannot hold, a decoded regex, or a canonical
tag. Everything else goes, restatement and change narration first.

Complete when every comment in the diff is on that list.

## 3. The rest of the bar

Check the diff against `~/.dotfiles/ai/skills/code-quality/references/laziness.md`, and against
`~/.dotfiles/ai/skills/code-quality/references/tests.md` where it touches tests. The frequent
offenders: code that reimplements a helper already in the repo, an abstraction nobody asked
for, a config knob with no caller, an argument the callee could compute.

Complete when each offender is fixed or named in the report with its reason for staying.

## 4. Learned preferences

Apply every rule below to the diff.

- Use relevant, precise names. Prefer `isConfigured` over `complete`; boolean names should read
  as states, not commands.

- Combine overlapping types, functions, constants, or behavioral instructions. In generated
  prompts, place authoritative guidance after bulky source material so examples cannot drown it
  out.

- Task wrappers should declare and forward child-command options directly, so callers reach the
  child's flags without a `--` separator.

- Keep personal environment and workflow overrides in dotfiles or ignored local config. A
  shared repository's tracked behavior stays shaped by the team, not by one machine.

Complete when every rule has been applied or is inapplicable to this diff.

## 5. Report

Name what you deleted and why, in a line or two.

Keep this list to rules that hold across unrelated repositories. SDK, service, API, schema,
architecture, and business decisions belong in project memory, and `learn-preferences` routes
them there.
