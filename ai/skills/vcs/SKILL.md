---
name: vcs
description: >
  Use for any repository inspection or mutation: commits, diffs, status, bookmarks, history.
  A repo with a .jj directory is JJ-first, where git is read-only and every mutation goes
  through jj. Carries the JJ workflow and command reference.
---

# Version Control Systems

Repo may use Git or Jujutsu (`jj`). When `.jj` directory exists in current or parent directory, treat as **JJ-first repository** — use `jj` instead of `git` for all repo inspection and mutation.

Detect first (never combine detection commands — compound commands defeat allowlists):

- Run `jj workspace root`. If it succeeds, this is a JJ-first repo — use `jj`, not `git`.
- Otherwise fall back to `git rev-parse --show-toplevel`.

## JJ-first rules

**In a JJ repo, `git` is read-only.** Inspect with it if you like; every mutation goes through
`jj`. That covers commit, checkout, switch, rebase, cherry-pick, stash, and branch
creation or deletion, and it makes JJ the source of truth.

The human owns the commit graph, bookmark placement, and publication. So:

- Default job: correct file edits **within the current JJ change and workspace**.
- History rewriting, bookmark create/move/delete, and push/publish/PR each wait for an
  explicit ask.
- When a task needs history surgery or several changes, stop and explain the split you
  recommend rather than executing it.
- Make changes granular. Change IDs are cheap, and squashing or moving them later is easy.

## Default JJ workflow for agents

Start of work in JJ repo, run:

```
jj workspace root
jj status
```

During work:

- Stay within current workspace and task scope unless explicitly told otherwise.
- Prefer small, scoped edits and small JJ changes.
- Multiple coherent concerns → separate local JJ changes, not mixed together.
- Unsure if two edits belong in same change → bias toward separating.
- No unrelated cleanup or opportunistic refactors outside current task.

End of work, run:

```
jj status
jj diff --summary
```

Then summarize:

- what changed
- which files modified
- single change or multiple local milestone commits
- risks, follow-ups, suggested splits

## Milestone commit policy

Local changes are **candidate history, not published history**, so they are cheap and you
should make more of them. Cut one when a coherent subtask lands, when the work turns to a
separate concern, or before a risky step you may want to walk back. Keep each narrow and
described. When in doubt, split.

A milestone is the change alone. Bookmark moves and rewrites of earlier commits wait for an
explicit ask.

## Workspace policy

A JJ workspace is a task sandbox: one workspace, one active task. Repointing it with
`jj edit <rev>`, or adding another workspace, waits for an explicit ask. When the work belongs
in a different workspace or change, say so instead of moving there yourself.

## Before stack surgery

Before rebasing, duplicating, abandoning, or force-pushing a stack:

1. Run `jj workspace list --ignore-working-copy` and verify every registered workspace path exists. A directory that looks like a workspace but is absent from this list is an orphan, not a worktree to inspect.
2. Run `jj log -r 'divergent()' --no-pager` and inspect bookmarks plus their `@origin` counterparts. If a working copy has no commit, checkout reports a concurrent checkout, or unexpected divergence appears, resolve the workspace state first.
3. Run `jj op log -n 5` so a recovery point is visible before history surgery.

A squash-merged stacked PR is a new commit with no ancestry link to its local changes. After fetching the new base, rebase only the still-unmerged root and abandon local copies already represented by the squash. Rebasing every old commit recreates duplicate content and divergent change IDs.

If a rebase goes wrong, use `jj op restore <operation>` before reconstructing hidden commits by hand. After surgery, verify `divergent()` is empty for the active stack, bookmarks point at the intended commits, and working copies are clean.

## Common JJ Commands

- Check current state: `jj status`
- Show current diff: `jj diff`
- Show diff summary: `jj diff --summary`
- Compare all diffs since trunk: `jj diff -f 'trunk()'`
- Show log: `jj log`
- Create a new change: `jj new`
- Describe current change: `jj desc -m "<message>"`
- Create a milestone commit and advance to a new change: `jj ci -m "<message>"`
- Edit a specific revision: `jj edit <rev>`
- Move bookmark to current change: `jj tug`
- Move bookmark to previous change: `jj tug-`
- Merge two commits: `jj new <commit_a> <commit_b>`

## Notes

- `trunk()` resolves to repo's configured trunk bookmark/reference.
- In JJ repos, `gh` commands may need explicit bookmark/revision — JJ often operates headlessly.
