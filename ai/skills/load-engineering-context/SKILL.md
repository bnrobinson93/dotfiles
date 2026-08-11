---
name: load-engineering-context
description: Load global issue routing, readiness, domain docs, and draft locations for engineering workflows. Use before QA, issue filing, refactor planning, domain modeling, spec drafting, or any Matt Pocock skill requiring engineering context.
---

# Load engineering context

1. Apply the global `Matt Pocock Skills` policy from agent instructions
2. Derive `<repo>` from the `origin` remote repository name without `.git`; fall back to the workspace-root directory name
3. Read existing context from `~/Documents/Vault/2-Areas/Coding/<repo>/Agents/`
4. Route drafts and completed efforts using the global policy

Do not invent tracker fields, workflow values, labels, or domain terms.
