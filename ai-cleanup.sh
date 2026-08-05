#!/usr/bin/env bash
set -u

claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
codex_home="${CODEX_HOME:-$HOME/.codex}"
xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
opencode_home="$xdg_config_home/opencode"

have() {
  command -v "$1" >/dev/null 2>&1
}

list_skill_tree() {
  local label="$1"
  local directory="$2"
  local names=""

  if [[ -d "$directory" ]]; then
    names=$(find -L "$directory" -type f -name SKILL.md -print 2>/dev/null \
      | awk -F/ '{print $(NF - 1)}' | sort -u)
  fi
  printf '%s:\n' "$label"
  if [[ -n "$names" ]]; then
    printf '%s\n' "$names" | sed 's/^/  /'
  else
    printf '  none\n'
  fi
}

list_skills() {
  list_skill_tree "Shared" "$HOME/.agents/skills"
  list_skill_tree "Claude" "$claude_home/skills"
  list_skill_tree "Codex" "$codex_home/skills"
  list_skill_tree "OpenCode" "$opencode_home/skills"
  list_skill_tree "Workspace shared" "$PWD/.agents/skills"
  list_skill_tree "Workspace Claude" "$PWD/.claude/skills"
  list_skill_tree "Workspace Codex" "$PWD/.codex/skills"
  list_skill_tree "Workspace OpenCode" "$PWD/.opencode/skills"
  list_skill_tree "Claude plugins" "$claude_home/plugins/cache"
  list_skill_tree "Codex plugins" "$codex_home/plugins/cache"
}

print_names() {
  local label="$1"
  local names="$2"
  if [[ -n "$names" ]]; then
    while IFS= read -r name; do
      printf '%s: %s\n' "$label" "$name"
    done <<<"$names"
  else
    printf '%s: none\n' "$label"
  fi
}

list_claude_mcps() {
  local config="$HOME/.claude.json"
  local workspace="$(pwd -P)"
  local workspace_config="$workspace/.mcp.json"
  local global_names="" workspace_names="" workspace_file_names="" resolved=""

  if have jq && [[ -f "$config" ]]; then
    global_names=$(jq -r '.mcpServers // {} | keys[]' "$config" 2>/dev/null | sort -u)
    workspace_names=$(jq -r --arg workspace "$workspace" \
      '.projects[$workspace].mcpServers // {} | keys[]' "$config" 2>/dev/null | sort -u)
  fi
  if have jq && [[ -f "$workspace_config" ]]; then
    workspace_file_names=$(jq -r '.mcpServers // {} | keys[]' "$workspace_config" 2>/dev/null | sort -u)
  fi
  print_names "Claude global" "$global_names"
  print_names "Claude workspace" "$workspace_names"
  print_names "Claude workspace file" "$workspace_file_names"

  if have claude; then
    resolved=$(claude mcp list 2>/dev/null || true)
  fi
  if [[ -n "$resolved" && "$resolved" != *"No MCP servers configured"* ]]; then
    while IFS= read -r line; do
      printf 'Claude resolved: %s\n' "$line"
    done <<<"$resolved"
  fi
}

list_codex_mcps() {
  local names=""
  if have codex && have jq; then
    names=$(codex mcp list --json 2>/dev/null | jq -r '.[].name' 2>/dev/null | sort -u)
  fi
  print_names "Codex" "$names"
}

list_opencode_mcps() {
  local output=""
  if have opencode; then
    output=$(opencode mcp list 2>/dev/null || true)
  fi
  if [[ -n "$output" ]]; then
    printf 'OpenCode:\n%s\n' "$output"
  else
    printf 'OpenCode: none\n'
  fi
}

list_mcps() {
  list_claude_mcps
  list_codex_mcps
  list_opencode_mcps
}

choose_agent() {
  local agents=() agent choice default
  have codex && agents+=(codex)
  have claude && agents+=(claude)
  if [[ "${#agents[@]}" -eq 0 ]]; then
    printf 'Neither Codex nor Claude is installed.\n' >&2
    return 1
  fi

  default="${agents[0]}"
  printf 'AI harness' >&2
  for agent in "${agents[@]}"; do
    printf ' [%s]' "$agent" >&2
  done
  printf ' (default: %s): ' "$default" >&2
  read -r choice
  choice="${choice:-$default}"
  for agent in "${agents[@]}"; do
    if [[ "$choice" == "$agent" ]]; then
      chosen_agent="$agent"
      return 0
    fi
  done
  printf 'Unknown harness: %s\n' "$choice" >&2
  return 1
}

launch_agent() {
  local prompt="$1"
  choose_agent || return 1
  "$chosen_agent" "$prompt"
}

convert_mcp() {
  local mcp prompt
  list_mcps
  printf 'MCP to replace with a skill: '
  read -r mcp
  [[ -n "$mcp" ]] || return 1

  prompt="Inspect MCP '$mcp' configured for this workspace. Use \$find-skills to prefer an existing skill. If none fits, use \$skill-creator and \$writing-for-agents to create a shared skill under this dotfiles repo's ai/skills directory. Preserve only useful workflows; avoid recreating native harness features. Validate the skill, then show the exact MCP removal command. Do not remove it until I approve."
  launch_agent "$prompt"
}

instruction_files() {
  local file
  for file in \
    "$PWD/AGENTS.md" \
    "$PWD/CLAUDE.md" \
    "$claude_home/CLAUDE.md" \
    "$codex_home/AGENTS.md"; do
    [[ -f "$file" ]] && printf '%s\n' "$file"
  done | awk '!seen[$0]++'
}

choose_instruction_file() {
  local files=() file index choice
  while IFS= read -r file; do
    files+=("$file")
  done < <(instruction_files)
  if [[ "${#files[@]}" -eq 0 ]]; then
    printf 'No AGENTS.md or CLAUDE.md found.\n' >&2
    return 1
  fi

  index=1
  for file in "${files[@]}"; do
    printf '%s) %s\n' "$index" "$file"
    index=$((index + 1))
  done
  printf 'Instructions file: '
  read -r choice
  [[ "$choice" =~ ^[0-9]+$ ]] || return 1
  [[ "$choice" -ge 1 && "$choice" -le "${#files[@]}" ]] || return 1
  chosen_file="${files[$((choice - 1))]}"
}

extract_instructions() {
  local prompt
  choose_instruction_file || return 1
  prompt="Read '$chosen_file'. Use \$skill-creator and \$writing-for-agents to identify reusable, on-demand workflows that should become shared skills under this dotfiles repo's ai/skills directory. Keep always-on project facts in the instructions file. Propose the split before editing; validate every created skill."
  launch_agent "$prompt"
}

usage() {
  printf '%s\n' \
    'Usage: ai-cleanup [command]' \
    '' \
    'Commands:' \
    '  list-mcps             List MCPs by harness for current workspace' \
    '  list-skills           List installed skills by harness' \
    '  convert-mcp           Launch AI session to replace one MCP' \
    '  extract-instructions  Launch AI session to extract reusable skills' \
    '  help                  Show this help'
}

menu() {
  local choice
  while true; do
    printf '\n1) List MCPs\n2) List skills\n3) Convert MCP to skill\n4) Extract instructions into skills\nq) Quit\nChoice: '
    read -r choice
    case "$choice" in
      1) list_mcps ;;
      2) list_skills ;;
      3) convert_mcp ;;
      4) extract_instructions ;;
      q | Q) return 0 ;;
      *) printf 'Unknown choice.\n' >&2 ;;
    esac
  done
}

case "${1:-}" in
  list-mcps) list_mcps ;;
  list-skills) list_skills ;;
  convert-mcp) convert_mcp ;;
  extract-instructions) extract_instructions ;;
  help | -h | --help) usage ;;
  '') menu ;;
  *) usage >&2; exit 2 ;;
esac
