# AI CLI for `ghpr`

Date: 2026-11-09

## Decision

Use Pi's non-interactive print mode with an explicit `anthropic/claude-sonnet-5-5` model for `ghpr`.

The model is pinned in `ghpr`, so this workflow does not follow Pi's global default or interfere with other Pi agents. The Pi Anthropic provider is configured against the Virtru Anthropic-compatible gateway at `https://developer-ai-gateway.virtru.com/anthropic`.

## Why Pi and Sonnet

- Pi's print mode writes only the final assistant response to stdout, which fits `ghpr`'s existing parser
- Pi writes errors to stderr and returns a nonzero status for failed print-mode responses
- Pi supports an ephemeral `--no-session` run and can disable tools, project context, skills, prompt templates, and extensions for a clean diff-to-description request
- `claude-sonnet-5-5` is the requested paid model and remains isolated to this workflow rather than changing Pi's global default
- The Anthropic gateway currently returns `402 Insufficient unified billing credits`; `ghpr` surfaces that failure instead of silently substituting another model or producing a partial description

The prompt remains the same: `ghpr` supplies the bounded diff, commit messages, changed files, repository guidance, and writing guidance, then requires a title/body separator.

## Sources

- Pi CLI integration docs: `~/.local/share/mise/installs/pi/1.5.0/pi/docs/cli-integration.md`
- Pi command-line docs: `~/.local/share/mise/installs/pi/1.5.0/pi/docs/cli.md`
- Local Pi model catalog: `~/.pi/agent/models-store.json`
- Virtru gateway configuration: `~/.config/opencode/opencode.json`
