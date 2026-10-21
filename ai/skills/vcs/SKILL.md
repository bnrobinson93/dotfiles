---
name: vcs
description: >
  Use for any repository inspection or mutation: commits, diffs, status, bookmarks, history.
  A repo with a .jj directory is JJ-first, where git is read-only and every mutation goes
  through jj. Carries the JJ workflow and command reference.
---

# Version Control Systems

Repo may use Git or Jujutsu (`jj`). Detect first (run these as separate commands):

- Run `jj workspace root`. If it succeeds, this is a **JJ-first repository** — use `jj`, not `git`.
- Otherwise fall back to `git rev-parse --show-toplevel`.

## JJ-first rules

**In a JJ repo, `git` is read-only.** Inspect with it if you like; every mutation goes through
`jj`. That covers commit, checkout, switch, rebase, cherry-pick, stash, and branch
creation or deletion, and it makes JJ the source of truth. Use `jj status`, `jj diff`, and
`jj log` for working-copy state; `git status` or `git diff` can show a stale or different view.
Git revision inspection such as `git show <revision>:<path>` is fine when the revision is explicit.

The human owns the commit graph, bookmark placement, and publication. So:

- Default job: correct file edits **within the current JJ change and workspace**.
- History rewriting, bookmark create/move/delete, and push/publish/PR each wait for an
  explicit ask.
- When a task needs history surgery or several changes, stop and explain the split you
  recommend rather than executing it.
- Make changes granular. Change IDs are cheap, and squashing or moving them later is easy.

## Default JJ workflow for agents

Start of work in a JJ repo, run:

```
jj workspace root
jj status
```

`jj status` intentionally snapshots the current filesystem into the current workspace. For
repository metadata without taking that snapshot, use `--ignore-working-copy`, for example:

```
jj workspace list --ignore-working-copy
jj log --ignore-working-copy -r 'divergent()' --no-pager
```

During work:

- Stay within the current workspace and task scope unless explicitly told otherwise.
- Prefer small, scoped edits and small JJ changes.
- Multiple coherent concerns → separate local JJ changes, not mixed together.
- Unsure if two edits belong in the same change → bias toward separating.
- No unrelated cleanup or opportunistic refactors outside the current task.

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

A JJ workspace is a task sandbox: one workspace, one active task. `jj workspace root` identifies
the workspace for the current shell; it does not identify the repository's `default` workspace.
Before handing code to a dev server or another agent, run:

```
jj workspace list --ignore-working-copy
```

Treat the listed paths and names as authoritative. A directory that looks like a sibling but is
not listed is an orphan, not a workspace. Name both source and target explicitly, then check
`jj status` and `jj log -r '@'` in each. If the target is dirty, stop rather than overwrite or
repoint it. A dev server started in `default` will not see edits made in a feature workspace
until the server's workspace is explicitly updated or restarted.

`jj edit <rev>` and `jj new [<rev>...]` affect only the current workspace and move its `@`;
they are not read-only ways to inspect another change. Repointing the current workspace with
`jj edit`, adding another workspace, or handing a revision to a different workspace waits for
an explicit ask. When the work belongs in a different workspace or change, say so instead of
moving there yourself.

## Before stack surgery

Before rebasing, duplicating, abandoning, moving bookmarks, or force-pushing a stack:

1. Run `jj workspace list --ignore-working-copy` and verify every registered workspace path exists.
2. Run `jj status` in the workspace you will mutate, then inspect the explicit stack with `jj bookmark list` and `jj log -r 'divergent()' --no-pager`. Compare affected bookmarks with their `name@origin` counterparts. A working copy with no commit, a concurrent-checkout error, or unexpected divergence is a state to resolve first, not a reason to continue.
3. Run `jj op log -n 5` so a recovery point is visible before history surgery.

`divergent()` means one JJ change ID has multiple commit IDs. A common cause is rebasing or
duplicating a local stack while a bookmark's `@origin` still points to the old copy. Do not
repair it with an arbitrary merge or by rebasing every old commit. Map the local and remote
copies first; a stale `@origin` shown by a broad stack alias may be the only remaining side.

A squash-merged stacked PR is a new commit with no ancestry link to its local changes. After fetching the new base, rebase only the still-unmerged root and abandon local copies already represented by the squash. Rebasing every old commit recreates duplicate content and divergent change IDs.

If a rebase goes wrong, use `jj op restore <operation>` before reconstructing hidden commits by hand. After surgery, verify `divergent()` is empty for the active stack, bookmarks point at the intended commits, and working copies are clean.

## Common JJ Commands

- Check current state and snapshot files: `jj status`
- Show current diff: `jj diff`
- Show diff summary: `jj diff --summary`
- Compare all diffs since trunk: `jj diff -f 'trunk()'`
- Show the explicit stack, avoiding a broad custom alias: `jj log -r 'trunk()::@' --no-pager`
- Show log: `jj log`
- List workspaces without snapshotting: `jj workspace list --ignore-working-copy`
- List bookmarks and targets: `jj bookmark list`
- Create a new change in the current workspace: `jj new`
- Describe current change: `jj desc -m "<message>"`
- Create a milestone commit and advance to a new change: `jj ci -m "<message>"`
- Edit a specific revision in the current workspace: `jj edit <rev>`
- Move bookmark to current change: `jj tug`
- Move bookmark to previous change: `jj tug-`
- Merge two commits in the current workspace: `jj new <commit_a> <commit_b>`

## Notes

- `trunk()` resolves to repo's configured trunk bookmark/reference.
- In JJ repos, `gh` commands may need explicit bookmark/revision — JJ often operates headlessly.
