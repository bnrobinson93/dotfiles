---
name: load-engineering-context
description: Load repository-specific issue tracking, triage labels, domain docs, and draft locations for engineering workflows. Use before QA, issue filing, refactor planning, domain modeling, spec drafting, or any skill requiring per-repository configuration.
---

# Load engineering context

1. Derive `<repo>` from the `origin` remote repository name without `.git`; fall back to the workspace-root directory name
2. Read `~/Documents/Vault/2-Areas/Coding/<repo>/Agents/`
3. Follow `Issue Tracker.md`, `Triage Labels.md`, and `Domain Docs.md`
4. Save issue and spec drafts under sibling `Issues/`
5. Run `setup-matt-pocock-skills` with this vault layout when configuration is missing

Do not invent tracker fields, labels, or domain terms when repository configuration exists.
