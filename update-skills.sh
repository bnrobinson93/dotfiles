#!/usr/bin/env bash
set -u

# source[@ref][#skill]|ownership(default: managed)|harnesses(default: shared)
# shared = Claude Code, Codex, and OpenCode. manual entries are inventory-only.
SKILLS=(
  "JuliusBrussee/caveman||shared"
  "vercel-labs/skills#find-skills||shared"
  "DietrichGebert/ponytail||shared"
  "modem-dev/hunk#hunk-review||shared"
  "mattpocock/skills||shared"
)

failures=0
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
codex_home="${CODEX_HOME:-$HOME/.codex}"
xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
opencode_home="$xdg_config_home/opencode"
managed_skills_state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/managed-skills.tsv"
skill_lock="$HOME/.agents/.skill-lock.json"

have() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  printf '\n==> %s\n' "$*"
}

warn() {
  failures=$((failures + 1))
  printf 'warn: %s\n' "$*" >&2
}

try() {
  step "$*"
  if "$@"; then
    return 0
  fi

  warn "failed: $*"
  return 1
}

try_quiet() {
  "$@" >/dev/null 2>&1
}

backup_conflicting_path() {
  local target="$1"
  if [[ ! -e "$target" && ! -L "$target" ]] || [[ -L "$target" ]]; then
    return 0
  fi

  local backup_target="${target}.pre-dotfiles.$(date +%Y%m%d%H%M%S).bak"
  printf 'Backing up existing %s to %s\n' "$(basename "$target")" "$backup_target"
  mv "$target" "$backup_target"
}

verify_prerequisites() {
  local tool
  for tool in stow jq npx; do
    if ! have "$tool"; then
      warn "$tool not found; run install.sh first"
    fi
  done

  [[ "$failures" -eq 0 ]]
}

deploy_local_ai() {
  local roots=("$claude_home" "$codex_home" "$opencode_home")
  local shared_stow_args=(
    --ignore=dot-codex
    --ignore=dot-claude
    --ignore=dot-config
  )
  local root

  try mkdir -p "${roots[@]}" || true
  for root in "${roots[@]}"; do
    backup_conflicting_path "$root/AGENTS.md"
    backup_conflicting_path "$root/CLAUDE.md"
  done

  # Codex and Herdr own these mutable files; remove legacy Stow links only.
  try_quiet stow -D -d "$script_dir/ai" -t "$codex_home" dot-codex || true

  for root in "${roots[@]}"; do
    try stow -R -d "$script_dir" "${shared_stow_args[@]}" -t "$root" ai || true
  done
  try stow -R -d "$script_dir/ai" -t "$claude_home" dot-claude || true
}

# settings.json is mutable/plugin-managed. Merge one owned key without replacing it.
merge_claude_settings() {
  local settings="$claude_home/settings.json"
  local statusline_cmd="bash '$claude_home/hooks/caveman-statusline.sh'"
  local desired tmp

  [[ -f "$settings" ]] || printf '{}\n' >"$settings"
  desired=$(jq -n --arg cmd "$statusline_cmd" '{type: "command", command: $cmd}')

  if [[ "$(jq -c '.statusLine // empty' "$settings" 2>/dev/null)" == "$(jq -c '.' <<<"$desired")" ]]; then
    step "Claude status line already current"
    return 0
  fi

  step "merge Claude status line"
  tmp=$(mktemp)
  if jq --argjson sl "$desired" '.statusLine = $sl' "$settings" >"$tmp"; then
    mv "$tmp" "$settings"
  else
    rm -f "$tmp"
    warn "failed to merge Claude status line"
    return 1
  fi
}

parse_skill_spec() {
  local spec="$1"
  local extra
  IFS='|' read -r parsed_identity parsed_ownership parsed_harnesses extra <<<"$spec"
  parsed_ownership="${parsed_ownership:-managed}"
  parsed_harnesses="${parsed_harnesses:-shared}"

  if [[ -z "$parsed_identity" || -n "${extra:-}" ]]; then
    printf 'invalid skill entry: %s\n' "$spec" >&2
    return 1
  fi
  if [[ "$parsed_ownership" != managed && "$parsed_ownership" != manual ]]; then
    printf 'invalid ownership in skill entry: %s\n' "$spec" >&2
    return 1
  fi
}

resolve_targets() {
  local requested="$1"
  local target
  resolved_targets=()

  if [[ "$requested" == shared ]]; then
    requested="claude,codex,opencode"
  fi

  local old_ifs="$IFS"
  IFS=',' read -ra requested_targets <<<"$requested"
  IFS="$old_ifs"
  for target in "${requested_targets[@]}"; do
    case "$target" in
      claude | claude-code) resolved_targets+=("claude-code") ;;
      codex | opencode) resolved_targets+=("$target") ;;
      *)
        printf 'invalid harness: %s\n' "$target" >&2
        return 1
        ;;
    esac
  done
}

skill_source() {
  local identity="$1"
  local source="${identity%%#*}"
  printf '%s\n' "${source%@*}"
}

skill_selector() {
  local identity="$1"
  if [[ "$identity" == *#* ]]; then
    printf '%s\n' "${identity#*#}"
  fi
}

install_skill() {
  local identity="$1"
  shift
  local source="${identity%%#*}"
  local selector
  selector=$(skill_selector "$identity")
  local command=(npx -y skills add "$source" -g)
  local target

  if [[ -n "$selector" ]]; then
    command+=(--skill "$selector")
  fi
  for target in "$@"; do
    command+=(-a "$target")
  done
  command+=(-y)

  step "install/update $identity"
  "${command[@]}"
}

installed_skills_for() {
  local identity="$1"
  local source selector
  source=$(skill_source "$identity")
  selector=$(skill_selector "$identity")

  [[ -f "$skill_lock" ]] || return 0
  jq -r --arg source "$source" --arg selector "$selector" '
    .skills // {}
    | to_entries[]
    | select(.value.source == $source)
    | select($selector == "" or .key == $selector)
    | .key
  ' "$skill_lock" | sort -u
}

join_targets() {
  local joined=""
  local target
  for target in "$@"; do
    joined="${joined:+$joined,}$target"
  done
  printf '%s\n' "$joined"
}

pair_is_desired() {
  local pairs_file="$1"
  local target="$2"
  local skill="$3"
  grep -Fqx -- "$target"$'\t'"$skill" "$pairs_file"
}

remove_skill() {
  local skill="$1"
  local target="$2"
  step "remove $skill from $target"
  npx -y skills remove "$skill" -g -a "$target" -y
}

reconcile_skills() {
  local runtime_dir desired_state desired_pairs previous_state
  runtime_dir=$(mktemp -d)
  desired_state="$runtime_dir/state"
  desired_pairs="$runtime_dir/pairs"
  previous_state="$runtime_dir/previous"
  : >"$desired_state"
  : >"$desired_pairs"
  if [[ -f "$managed_skills_state" ]]; then
    sort -u "$managed_skills_state" >"$previous_state"
  else
    : >"$previous_state"
  fi

  local spec identity ownership harnesses targets_csv skill target
  local reconcile_failed=0
  for spec in "${SKILLS[@]}"; do
    if ! parse_skill_spec "$spec" || ! resolve_targets "$parsed_harnesses"; then
      warn "cannot reconcile $spec"
      reconcile_failed=1
      continue
    fi

    identity="$parsed_identity"
    ownership="$parsed_ownership"
    harnesses="$parsed_harnesses"
    targets_csv=$(join_targets "${resolved_targets[@]}")

    if [[ "$ownership" == manual ]]; then
      step "inventory only: $identity ($harnesses)"
    elif ! install_skill "$identity" "${resolved_targets[@]}"; then
      warn "failed to install/update $identity"
      reconcile_failed=1
      continue
    fi

    local resolved_count=0
    while IFS= read -r skill; do
      [[ -n "$skill" ]] || continue
      resolved_count=$((resolved_count + 1))
      for target in "${resolved_targets[@]}"; do
        printf '%s\t%s\n' "$target" "$skill" >>"$desired_pairs"
      done
      if [[ "$ownership" == managed ]]; then
        printf '%s\t%s\t%s\n' "$spec" "$targets_csv" "$skill" >>"$desired_state"
      fi
    done < <(installed_skills_for "$identity")

    if [[ "$ownership" == managed && "$resolved_count" -eq 0 ]]; then
      warn "installed $identity but found no matching entry in $skill_lock"
      reconcile_failed=1
    fi
  done

  sort -u -o "$desired_pairs" "$desired_pairs"
  sort -u -o "$desired_state" "$desired_state"

  if [[ "$reconcile_failed" -eq 0 && -s "$previous_state" ]]; then
    local old_spec old_targets old_skill old_target
    while IFS=$'\t' read -r old_spec old_targets old_skill; do
      [[ -n "$old_skill" ]] || continue
      local old_ifs="$IFS"
      IFS=',' read -ra old_target_list <<<"$old_targets"
      IFS="$old_ifs"
      for old_target in "${old_target_list[@]}"; do
        if ! pair_is_desired "$desired_pairs" "$old_target" "$old_skill"; then
          if ! remove_skill "$old_skill" "$old_target"; then
            warn "failed to remove $old_skill from $old_target"
            reconcile_failed=1
          fi
        fi
      done
    done <"$previous_state"
  fi

  if [[ "$reconcile_failed" -eq 0 ]]; then
    mkdir -p "$(dirname "$managed_skills_state")"
    mv "$desired_state" "$managed_skills_state"
  else
    warn "skill state unchanged because reconciliation failed"
  fi
  rm -rf "$runtime_dir"
}

main() {
  verify_prerequisites || return 1
  deploy_local_ai
  merge_claude_settings || true
  reconcile_skills

  if [[ "$failures" -gt 0 ]]; then
    printf '\nDone with %s warning(s). Restart agents after resolving them.\n' "$failures" >&2
    return 1
  fi

  printf '\nDone. Restart agents to pick up skill changes.\n'
}

main "$@"
