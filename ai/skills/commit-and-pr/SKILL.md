---
name: file-pr
description: file a concise pull request. Use when the user asks to file, open, or create a PR or create a PR description.
---

# File PR

Before filing, check whether a PR for the branch already exists. Review the diff locally against the parent branch or main to ensure its contents match the goal.

PRs are squashed so the title becomes the commit message, so follow the repositories title conventions.
Look at recently merged PRs and Git history for example if needed.

Prefer a concise, human=readable title that explains why the change matters.

❌ BAD
> perf(server): negotiate permessage-default on the websocket

✅ GOOD
> perf(server): cut websocket frame size by 70%+ with gzip

Open the description with a simple explanation of the problem based on the user's original prompt or spec, then briefly explain the solution. Do not lead an implementation inventory.

❌ BAD
> Removed implicit workspace carry-over from every "new thread" entry point (cmd fn / cmd+shift+o, sidebar v1/v2 buttons, command palette). New threads inherit only the project from context; branch, worktree, and env mode always come from the configured defaults. Deleted buildContextualThreadOptions, startNewThreadInProjectFromContext, and the v1 sidebar's seed-context machinery

✅ GOOD
> My "new worktree" default was ignored when starting new threads on existing worktrees. Super unintuitive. Now your preferences always apply.

