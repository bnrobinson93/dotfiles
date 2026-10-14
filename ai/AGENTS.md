# AI Entry Point

Shared by Claude, Codex, OpenCode, and Pi. Hooks only. Pull the thread a task needs and leave
the rest unread.

## Always on

- Answer short, in Brad's voice. No preamble, no recap of what he just said, no narrating tool
  calls. `unslop` runs over every reply; `writing-voice` when the prose is his to publish.
- Text no human reads is a different budget. Compress subagent prompts and their reports hard,
  and on Claude reach for the `cavecrew` agents, which return findings already compressed.
- Dev servers already run under `pnpm` or `go`. Ask for their output instead of starting a
  second one.
- Repos are JJ-first. Before mutating files, run `jj workspace root`; if that fails, run
  `git rev-parse --show-toplevel` as its own command. Chaining the two defeats allowlists.
- Personal environment and workflow setup lives in dotfiles, never in a repository Brad does
  not own.

## Threads

| Task | Pull |
| --- | --- |
| Writing or changing code | `code-quality` |
| Code finished, before handback | `simplify` (gate, not optional) |
| Inspecting or mutating a repo | `vcs` |
| Committing, pushing, filing a PR | `commit-and-pr` |
| Reviewing a diff | `ryan-review` (backend), `sara-review` (frontend) |
| Reading or writing review comments | `tuicr`, `hunk-review` |
| Brad states a reusable rule or corrects code | `learn-preferences` |
| Brad says remember this | `remember-context` |
| Issues, specs, Jira, domain docs | `load-engineering-context` |
| Prose Brad will publish or share | `writing-voice`, then `unslop` |
| Any other human-facing text | `unslop` |
| GitHub API calls | `gh-api` |
| Datadog | `dd` |
| Reproducing a browser bug | `browser-debug` |

Reference material these skills point at lives under `~/.dotfiles/ai/`.
