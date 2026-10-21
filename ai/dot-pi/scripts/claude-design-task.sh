#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  printf 'usage: claude-design-task.sh PROMPT_FILE\n' >&2
  exit 2
fi

prompt_file=$1
[[ -f "$prompt_file" ]] || {
  printf 'prompt file not found: %s\n' "$prompt_file" >&2
  exit 1
}

exec claude \
  --print \
  --input-format text \
  --no-session-persistence \
  --chrome \
  --permission-mode acceptEdits \
  --permission-prompts none \
  --allowed-tools 'Read,Edit,Write,Glob,Grep,Bash(jj *),Bash(node *),Bash(pnpm *),Bash(npm *),Bash(mise *),Bash(ls *),Bash(find *),Bash(rg *),Bash(grep *),mcp__plugin_figma_figma__*' \
  <"$prompt_file"
