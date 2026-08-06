#!/usr/bin/env bash
set -u

failures=0
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

have() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  printf '\n==> %s\n' "$*"
}

try() {
  step "$*"
  if "$@"; then
    return 0
  fi

  failures=$((failures + 1))
  printf 'warn: failed: %s\n' "$*" >&2
  return 1
}

try_quiet() {
  "$@" >/dev/null 2>&1
}

backup_conflicting_path() {
  local target="$1"
  local source="${2:-}"
  if [[ ! -e "$target" && ! -L "$target" ]] || [[ -L "$target" ]]; then
    return 0
  fi

  if [[ -n "$source" ]] && cmp -s "$target" "$source"; then
    rm -- "$target"
    return 0
  fi

  local backup_target="${target}.pre-dotfiles.$(date +%Y%m%d%H%M%S).bak"
  printf 'Backing up existing %s to %s\n' "$(basename "$target")" "$backup_target"
  mv "$target" "$backup_target"
}

deploy_local_ai() {
  local shared_stow_args=(
    --ignore=dot-codex
    --ignore=dot-claude
    --ignore=dot-config
    --ignore='^skills/(teach|hunk-review)$'
  )

  try mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.config/opencode" "$HOME/.config"
  backup_conflicting_path "$HOME/.claude/AGENTS.md"
  backup_conflicting_path "$HOME/.claude/CLAUDE.md"
  backup_conflicting_path \
    "$HOME/.config/ponytail/config.json" \
    "$script_dir/ai/dot-config/ponytail/config.json"

  # Remove legacy Codex stow links; Codex and Herdr own these mutable files now.
  try_quiet stow -D -d "$script_dir/ai" -t "$HOME/.codex" dot-codex || true

  try stow -S -d "$script_dir" "${shared_stow_args[@]}" -t "$HOME/.claude" ai || true
  try stow -S -d "$script_dir" "${shared_stow_args[@]}" -t "$HOME/.codex" ai || true
  try stow -S -d "$script_dir" "${shared_stow_args[@]}" -t "$HOME/.config/opencode" ai || true
  try stow -S -d "$script_dir/ai" -t "$HOME/.claude" dot-claude || true
  try stow -S -d "$script_dir/ai" -t "$HOME/.config" dot-config || true
}

# settings.json is mutable/plugin-managed (not stowed). Merge in the statusLine
# key idempotently so it survives across machines without clobbering plugin edits.
merge_claude_settings() {
  local settings="$HOME/.claude/settings.json"
  local statusline_cmd="bash '$HOME/.claude/hooks/caveman-statusline.sh'"

  if ! have jq; then
    failures=$((failures + 1))
    printf 'warn: jq not found; skipping settings.json statusLine merge\n' >&2
    return 1
  fi

  [[ -f "$settings" ]] || printf '{}\n' >"$settings"

  local desired
  desired=$(jq -n --arg cmd "$statusline_cmd" '{type: "command", command: $cmd}')

  if [[ "$(jq -c '.statusLine // empty' "$settings" 2>/dev/null)" == "$(jq -c '.' <<<"$desired")" ]]; then
    step "settings.json statusLine already current"
    return 0
  fi

  step "merge statusLine into settings.json"
  local tmp
  tmp=$(mktemp)
  if jq --argjson sl "$desired" '.statusLine = $sl' "$settings" >"$tmp"; then
    mv "$tmp" "$settings"
  else
    rm -f "$tmp"
    failures=$((failures + 1))
    printf 'warn: failed to merge statusLine into settings.json\n' >&2
    return 1
  fi
}

install_ponytail() {
  local marketplace="${PONYTAIL_MARKETPLACE:-DietrichGebert/ponytail}"

  if have claude; then
    try_quiet claude plugin marketplace add "$marketplace" || true
    try claude plugin marketplace update ponytail || true
    if claude plugin list 2>/dev/null | grep -q 'ponytail@ponytail'; then
      try claude plugin update ponytail@ponytail || true
    else
      try claude plugin install ponytail@ponytail || true
    fi
  fi

  if have codex; then
    try_quiet codex plugin marketplace add "$marketplace" || true
    try codex plugin marketplace upgrade ponytail || true
    if codex plugin list 2>/dev/null | grep -q 'ponytail@ponytail.*installed'; then
      step "codex ponytail already installed"
    else
      try codex plugin add ponytail@ponytail || true
    fi
  fi

  if have opencode; then
    try opencode plugin --global --force @dietrichgebert/ponytail || true
  fi
}

install_hunk() {
  local source="${HUNK_SKILL_SOURCE:-modem-dev/hunk}"

  if have npx; then
    try npx -y skills add "$source" --skill hunk-review -g -a claude-code -a codex -a opencode -y || true
  else
    failures=$((failures + 1))
    printf 'warn: npx not found; cannot install hunk skill from %s\n' "$source" >&2
  fi
}

install_figma() {
  local source="${FIGMA_SKILL_SOURCE:-openai/skills}"

  if have npx; then
    try npx -y skills add "$source" --skill figma -g -a codex -y || true
  else
    failures=$((failures + 1))
    printf 'warn: npx not found; cannot install figma skill from %s\n' "$source" >&2
  fi
}

install_teach() {
  local source="${TEACH_SKILL_SOURCE:-mattpocock/skills}"

  if have npx; then
    try npx -y skills add "$source" --skill teach -g -a claude-code -a codex -a opencode -y || true
  else
    failures=$((failures + 1))
    printf 'warn: npx not found; cannot install teach skill from %s\n' "$source" >&2
  fi
}

install_fabric() {
  if have fabric; then
    return 0
  fi

  try bash -c "curl -fsSL https://raw.githubusercontent.com/danielmiessler/fabric/main/scripts/installer/install.sh | bash" || return
  printf 'note: run `fabric --setup` once to configure providers\n'
}

deploy_local_ai
merge_claude_settings
install_ponytail
install_hunk
install_figma
install_teach
install_fabric

if [[ "$failures" -gt 0 ]]; then
  printf '\nDone with %s warning(s). Restart agents to pick up skill/plugin changes.\n' "$failures" >&2
  exit 1
fi

printf '\nDone. Restart agents to pick up skill/plugin changes.\n'
