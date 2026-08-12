# AI Entry Point

Shared instructions for Claude, Codex, and OpenCode.

## Communication

- Terse like caveman; keep technical substance exact
- Drop articles, filler, pleasantries, and hedging
- Fragments and short synonyms are fine
- Leave code, commits, and PR prose normal
- Pattern: `[thing] [action] [reason]. [next step].`
- Stay terse until the user says `stop caveman` or `normal mode`

## Code

- When writing, refactoring, or reviewing code, follow `CodeQuality.md` from the active agent root

## Runtime

- Development servers usually already run with `pnpm` or `go`; ask for output when needed

## Version control

- Assume JJ by default; follow `VCS.md` from the active agent root
- Before file mutations, use existing evidence or run `jj workspace root`
- If JJ detection fails, run `git rev-parse --show-toplevel` separately
- Never combine VCS detection commands; compound commands defeat allowlists

## Matt Pocock Skills

Use these settings globally. Do not run per-repository setup or add agent-only configuration to tracked repositories.

### Work routing

- Small personal tasks: `.scratch/<feature>/`
- Larger personal efforts: `~/Documents/Vault/2-Areas/Coding/<repo>/Issues/<effort>/`
- Shared team work: Jira
- Derive `<repo>` from `origin`; fall back to workspace directory name
- Ask when task size or Jira project cannot be inferred safely
- Group related drafts and issues into one human-readable `<effort>` folder, such as `Upload/download workspace files`
- When every item in an effort is completed or dismissed, move its folder from `2-Areas/` to `4-Archive/`, preserving the remaining folder structure

### Readiness

Local drafts use only:

- `needs-triage` — needs validation or changes
- `ready` — approved for implementation or Jira publication

Do not add triage labels to Jira. After publication, Jira owns workflow state. Local drafts may remain `ready`; no manual status synchronization required.

### Jira

Use Atlassian MCP or `acli`.

Draft new Jira work in Obsidian first. Publish only after user validation. Follow PEP-5183's shape:

- Scoped summary
- `Problem`
- `What to Build`
- `Acceptance Criteria`
- Explicit exclusions, dependencies, migration behavior, errors, and tests where relevant

Use native Jira links for dependencies. Preserve project workflow fields. Do not invent missing field values.

### Domain docs

Keep personal domain context outside tracked repositories:

- Glossary: `~/Documents/Vault/2-Areas/Coding/<repo>/Agents/CONTEXT.md`
- Decisions: `~/Documents/Vault/2-Areas/Coding/<repo>/Agents/ADRs/`

Create them lazily.
