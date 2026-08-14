---
name: file-pr
description: file a concise pull request. Use when the user asks to file, open, or create a PR or create a PR description.
---

# File PR

Before filing, check whether a PR for the branch already exists. Review the diff locally against the parent branch or main to ensure its contents match the goal.

PRs are squashed so the title becomes the commit message, so follow the repositories title conventions.
Look at recently merged PRs and Git history for example if needed.

Prefer a concise, human-readable title that explains why the change matters. Include the ticket ID when one is available. Use a scope only when the changes stay within one area and recent PR titles use scopes; infer it from the changed paths.

❌ BAD
> perf(server): negotiate permessage-default on the websocket

✅ GOOD
> perf(server): cut websocket frame size by 70%+ with gzip

Use the repository PR template as the body skeleton when one exists. Preserve its required headings and checklists, replacing placeholder prose with the real description.

In the template's summary or proposed-changes section:

1. Open with a simple explanation of the problem based on the user's original prompt or spec
2. Briefly explain the solution
3. Follow with a short implementation bullet list covering the material behavior changes

Keep implementation bullets at the behavior or module-seam level. Do not lead with them or turn them into a file inventory.

❌ BAD
> Removed implicit workspace carry-over from every "new thread" entry point (cmd fn / cmd+shift+o, sidebar v1/v2 buttons, command palette). New threads inherit only the project from context; branch, worktree, and env mode always come from the configured defaults. Deleted buildContextualThreadOptions, startNewThreadInProjectFromContext, and the v1 sidebar's seed-context machinery

✅ GOOD
> My "new worktree" default was ignored when starting new threads on existing worktrees. Super unintuitive. Now your preferences always apply.

Automated-test content stops at the repository template's test checkbox. After the implementation bullets, continue directly to the remaining template sections. Leave test files, cases, commands, coverage, and pass status to CI, including new regression and integration coverage.

Add an evidence section only for results CI cannot establish, such as before/after performance metrics, screenshots, rollout notes, or manual production verification. Name the section for that evidence, such as `Metrics Before/After` or `Post-deploy Verification`.
