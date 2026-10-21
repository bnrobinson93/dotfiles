#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: claude-design-task.sh PROMPT_FILE\n'
  printf '  Run a Claude design task with Figma MCP and browser QA access.\n'
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
tmp_dir=$(node -e 'process.stdout.write(require("node:os").tmpdir())')

claude_args=(
  --print
  --brief
  --input-format text
  --no-session-persistence
  --chrome
  --permission-mode acceptEdits
  --permission-prompts none
  --add-dir "$repo_root"
  --add-dir "$tmp_dir"
  --allowed-tools
  'Read,Edit,Write,Glob,Grep,Bash(jj *),Bash(node *),Bash(BROWSER_DEBUG_BINARY=/Applications/Helium.app/Contents/MacOS/Helium node /Users/brad.robinson/.pi/agent/skills/browser-debug/scripts/browser-cdp.mjs launch *),Bash(BROWSER_DEBUG_BINARY=helium node /Users/brad.robinson/.pi/agent/skills/browser-debug/scripts/browser-cdp.mjs launch *),Bash(pnpm *),Bash(npm *),Bash(mise *),Bash(ls *),Bash(find *),Bash(rg *),Bash(grep *),Bash(mkdir *),Bash(mktemp *),Bash(rm *),Bash(realpath *),Bash(readlink *),Bash(pwd *),Bash(ps *),Bash(pgrep *),Bash(lsof *),Bash(sleep *),Bash(/Users/brad.robinson/.pi/agent/scripts/jj-workspace-handoff.sh *),mcp__plugin_figma_figma__*'
)
if [[ -n "$design_system_dir" ]]; then
  claude_args+=(
    --add-dir "$design_system_dir"
    --append-system-prompt "Treat $design_system_dir as read-only: inspect it for design-system components and tokens, but never edit or write files there."
  )
fi

exec claude "${claude_args[@]}" <"$prompt_file"
