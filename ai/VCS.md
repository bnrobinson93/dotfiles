# Version Control Systems

Repo may use Git or Jujutsu (`jj`). When `.jj` directory exists in current or parent directory, treat as **JJ-first repository** — use `jj` instead of `git` for all repo inspection and mutation.

If unsure whether inside JJ repo, run:

    jj workspace root

If succeeds, use JJ.

## JJ-first rules

In JJ repository:

- Do **not** use `git commit`, `git checkout`, `git switch`, `git rebase`, `git cherry-pick`, `git stash`, or branch
  creation/deletion.
- Do **not** use Git as source of truth when JJ available.
- Human manages commit graph, bookmark placement, publication flow.
- Default job: correct file edits **within current JJ change/workspace**.
- No history rewriting unless explicitly asked.
- No bookmark create/move/delete/publish unless explicitly asked.
- No push/publish/PR unless explicitly asked.
- If task needs history surgery or multiple changes, stop and explain recommended split — don't auto-execute.

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

Prefer multiple small local JJ changes over one large mixed change unless explicitly told otherwise.

When in doubt, bias toward additional local change rather than combining unrelated concerns.

In JJ repos, create local commit/change when:

1. Coherent subtask complete, or
2. Work diverges into separate concern, or
3. Checkpoint useful before next risky/independent step.

If creating local milestone commit/change:

- Keep narrow and descriptive.
- Candidate history, not final published history.
- No bookmark create/move as part of that step.
- No rewriting earlier commits unless explicitly asked.

## Workspace Policy

JJ workspaces = task sandboxes.

- One workspace = one active task.
- No `jj edit <rev>` to repoint workspace unless explicitly asked.
- No additional workspaces unless explicitly asked.
- If task should happen in different workspace/change, say so — don't auto-execute.

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
- If instruction suggests Git ops but in JJ repo, prefer JJ semantics.

## Task-Local Overrides

Task prompt may override default JJ behavior for session. Human may instruct to:

- Stay in single-change mode
- Create milestone commits for coherent subtasks
- Draft PR text after implementation
- Inspect or move to specific revision
- Prepare work for bookmark-based PR flow

Task-local instructions override defaults here.
