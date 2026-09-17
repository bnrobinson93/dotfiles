---
name: load-engineering-context
description: Where issues, specs, drafts, and domain docs live, and how work routes between scratch, Obsidian, and Jira. Use before QA, issue filing, refactor planning, domain modeling, spec drafting, or any Matt Pocock skill that needs engineering context.
---

# Load engineering context

These settings are global and stay in dotfiles. A tracked repository gets no per-repository
setup and no agent-only configuration from them.

Derive `<repo>` from the `origin` remote's repository name without `.git`; fall back to the
workspace-root directory name. Read whatever already exists under
`~/Documents/Vault/2-Areas/Coding/<repo>/Agents/` before drafting anything new.

## Work routing

| Size | Home |
| --- | --- |
| Small personal task | `.scratch/<feature>/` |
| Larger personal effort | `~/Documents/Vault/2-Areas/Coding/<repo>/Issues/<effort>/` |
| Shared team work | Jira |

Group related drafts and issues under one human-readable `<effort>` folder, such as
`Upload/download workspace files`. When every item in an effort is completed or dismissed, move
that folder from `2-Areas/` to `4-Archive/`, preserving the structure underneath it.

Ask when the task size or the Jira project cannot be inferred safely.

## Readiness

Local drafts carry one of two labels, and no others:

- `needs-triage` — needs validation or changes
- `ready` — approved for implementation or Jira publication

Never add triage labels to Jira. Once published, Jira owns workflow state. Local drafts may stay
`ready`; nothing needs manual status synchronization.

## Jira

Use the Atlassian MCP or `acli`. Draft new Jira work in Obsidian first and publish only after
Brad validates it. Follow PEP-5183's shape:

- Scoped summary
- `Problem`
- `What to Build`
- `Acceptance Criteria`
- Explicit exclusions, dependencies, migration behavior, errors, and tests where relevant

Use native Jira links for dependencies. Preserve project workflow fields. Do not invent missing
field values, tracker fields, workflow values, labels, or domain terms.

## Domain docs

Personal domain context stays outside tracked repositories. Create these lazily:

- Glossary: `~/Documents/Vault/2-Areas/Coding/<repo>/Agents/CONTEXT.md`
- Decisions: `~/Documents/Vault/2-Areas/Coding/<repo>/Agents/ADRs/`
