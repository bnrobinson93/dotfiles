#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: design-task.sh PROMPT_FILE\n'
  printf '  Run a Codex (Luna) design task with Figma MCP and browser QA access.\n'
}

if [[ $# -eq 1 && ( "$1" == '-h' || "$1" == '--help' ) ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

prompt_file=$1
[[ -f "$prompt_file" ]] || {
  printf 'prompt file not found: %s\n' "$prompt_file" >&2
  exit 1
}

repo_root=$(jj workspace root 2>/dev/null || pwd -P)
design_system_link="$repo_root/web/node_modules/@virtru-private/design-system"
design_system_dir=''
if [[ -e "$design_system_link" ]]; then
  design_system_dir=$(realpath "$design_system_link")
fi

codex_args=(
  -m gpt-6-luna
  -c 'model_reasoning_effort="xhigh"'
  --ephemeral
  --skip-git-repo-check
  --dangerously-bypass-approvals-and-sandbox
  -C "$repo_root"
)
if [[ -n "$design_system_dir" ]]; then
  exec codex exec "${codex_args[@]}" - < <(
    cat "$prompt_file"
    printf '\n\nTreat %s as read-only: inspect it for design-system components and tokens, but never edit or write files there.\n' "$design_system_dir"
  )
fi

exec codex exec "${codex_args[@]}" - <"$prompt_file"
