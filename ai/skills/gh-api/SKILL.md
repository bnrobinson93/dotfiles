---
name: gh-api
description: Use when calling GitHub through `gh api`, especially from Codex where sandbox/network approval differs from Claude.
---

# GitHub API

Use the GitHub CLI directly:

```bash
gh api ...
```

Codex note: `gh api` may need sandbox escalation even when the command is already authenticated locally. If a `gh api` call fails with a sandbox/network/auth-looking error, retry the same command with escalation and use prefix rule:

```text
["gh", "api"]
```

Prefer `gh api` over ad hoc `curl` for GitHub when local auth should be reused. Keep raw token handling out of prompts, logs, and committed files.

## Read endpoints with params

`gh api` defaults to `GET` only when no body fields are provided. Passing `-f/--field`, `-F/--raw-field`, or `--input` can switch the request to `POST`. For read endpoints that need query params, force the method:

```bash
gh api -X GET repos/OWNER/REPO/pulls/123/files -f per_page=100
```

Use this for pagination, filters, search params, and any other read-only request where fields are query params, not request body.
