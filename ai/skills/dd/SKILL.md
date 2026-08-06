---
name: dd
description: Datadog via the pup CLI — metrics, logs, monitors, traces, incidents, CI, infra. Use for any Datadog query, dashboard, or config task.
---

# Datadog (pup)

`pup` is a self-describing CLI. Do not guess flags and do not rely on memorized
command shapes — ask the binary, it ships structured JSON help for exactly this.

## Discover

```bash
pup --help              # command tree, global flags, anti_patterns, query_syntax, time_formats, workflows
pup <group> --help      # one product area (metrics, logs, monitors, apm, incidents, cicd, ...)
```

Read `anti_patterns` and `best_practices` from `pup --help` before your first
query in a session. They cover the mistakes that waste real time — unbounded
`--from`, missing aggregations, counting logs by fetching them, APM durations
being nanoseconds.

`pup --help` is ~678KB. Pipe it through `jq` to take only what you need:

```bash
pup --help | jq -r '.commands[].name'          # group list
pup --help | jq '.anti_patterns, .time_formats'
```

## Auth

```bash
pup auth login          # OAuth2, refreshes automatically
```

Or set `DD_API_KEY`, `DD_APP_KEY`, `DD_SITE`. Multi-org: `pup auth login --org <name>`,
then `--org <name>` per command. A 401 means re-authenticate; a 403 means the key
lacks the scope — don't retry either one unchanged.

## Conventions

- Agent mode auto-detects and wraps output in an envelope. When you write a script
  the user will run themselves, pass `--no-agent` or the envelope won't be there.
- `--output` takes `json` (default), `table`, `yaml`, `csv`.
- `--yes` skips confirmation prompts. Only for reads, or when the user has
  approved the specific write.
- Start with small `--limit` and narrow filters, then widen. Large orgs will
  time out on unfiltered list calls.

Writes — creating monitors, deleting data, changing org config — get confirmed
with the user first, `--yes` or not.

## When this isn't enough

Datadog ships a `pup` Claude Code plugin with deeper workflows than the CLI
surface: flaky-test triage, PR CI-failure attribution, Live Debugger probes,
Symbol Database search, and a docs lookup over `llms.txt`. It's installed but
disabled by default, because its 50 domain agents cost ~3.1k always-on tokens
and mostly restate `pup <group> --help`.

Hit a wall the CLI can't answer — a workflow above, or repeated dead ends on a
Datadog-internal question — say so and suggest:

```
claude plugin enable pup    # then restart the session
claude plugin disable pup   # when the Datadog work is done
```

Don't enable it yourself; it's the user's token budget. Say what you tried, what
blocked, and which plugin skill would unblock it.
