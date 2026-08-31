#!/usr/bin/env bash
set -u

# source[@ref][#skill]|ownership(default: managed)|harnesses(default: shared)
# shared = Claude Code, Codex, and OpenCode. manual entries are inventory-only.
# Pi is not a target: it reads ~/.agents/skills itself, where the CLI already installs.
# caveman is installed as a Claude Code plugin (JuliusBrussee/caveman), not here,
# so it is not duplicated across ~/.agents and the plugin cache.
# ponytail lives in the code-quality skill; ryan-review/sara-review carry their own self-contained instincts.
SKILLS=(
  "vercel-labs/skills#find-skills||shared"
  "modem-dev/hunk#hunk-review||shared"
  "openai/skills#figma||shared"
  "mattpocock/skills||shared"
)

PI_PACKAGES=(
  "npm:@mjakl/pi-subagent"
)

# Claude Code plugins. Claude-only, so no harness column. Anything installed but
# absent here (or excluded by profile) is uninstalled, same contract as SKILLS.
# `claude plugin details <name>` prints a plugin's always-on token cost.
#
# name=repo|profile  and  plugin@marketplace|profile
# profile defaults to "all"; other values install only when that profile is
# active. Profile comes from $DOTFILES_PROFILE, else ~/.config/dotfiles/profile,
# else "personal".
MARKETPLACES=(
  "caveman=JuliusBrussee/caveman"
  "claude-plugins-official=anthropics/claude-plugins-official"
  "datadog-pup=datadog-labs/pup|work"
)
PLUGINS=(
  "caveman@caveman"
  "gopls-lsp@claude-plugins-official"
  # ~3.1k always-on (11 skills, 50 agents), so it ships disabled. Reconcile does
  # not touch enabledPlugins in settings.json, so the toggle survives a re-run:
  #   claude plugin enable pup    # before Datadog work
  #   claude plugin disable pup   # after
  "pup@datadog-pup|work"
)

failures=0
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
claude_home="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
codex_home="${CODEX_HOME:-$HOME/.codex}"
xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
opencode_home="$xdg_config_home/opencode"
pi_agent_home="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
managed_skills_state="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/managed-skills.tsv"
# Mirrors the skills CLI: XDG_STATE_HOME wins, else ~/.agents.
skill_lock="${XDG_STATE_HOME:+$XDG_STATE_HOME/skills}"
skill_lock="${skill_lock:-$HOME/.agents}/.skill-lock.json"
known_marketplaces="$claude_home/plugins/known_marketplaces.json"
installed_plugins="$claude_home/plugins/installed_plugins.json"
profile_marker="$xdg_config_home/dotfiles/profile"

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
  # Pi reads ~/.pi/agent/AGENTS.md and ~/.pi/agent/skills, so it takes the same
  # shared payload as the others; its agents then need no cross-harness paths.
  local roots=("$claude_home" "$codex_home" "$opencode_home" "$pi_agent_home")
  local shared_stow_args=(
    --ignore=dot-codex
    --ignore=dot-claude
    --ignore=dot-config
    --ignore=dot-pi
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
  try stow -R -d "$script_dir/ai" -t "$pi_agent_home" dot-pi || true
}

install_pi_packages() {
  if ! have pi; then
    warn "pi not found; skipping Pi package install"
    return 1
  fi

  local package
  for package in "${PI_PACKAGES[@]}"; do
    try pi install "$package" </dev/null || true
  done
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
  # </dev/null: this runs inside a `while read` over previous_state; without it
  # npx consumes the remaining lines and every skill after the first is skipped.
  npx -y skills remove "$skill" -g -a "$target" -y </dev/null
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

active_profile() {
  local profile="${DOTFILES_PROFILE:-}"
  if [[ -z "$profile" && -f "$profile_marker" ]]; then
    profile=$(tr -d '[:space:]' <"$profile_marker")
  fi
  printf '%s\n' "${profile:-personal}"
}

# Strip the trailing |profile column and keep entries valid for this machine.
select_for_profile() {
  local profile="$1"
  shift
  local entry entry_profile
  selected=()
  for entry in "$@"; do
    entry_profile=all
    if [[ "$entry" == *"|"* ]]; then
      entry_profile="${entry##*|}"
      entry="${entry%|*}"
    fi
    if [[ "$entry_profile" == all || "$entry_profile" == "$profile" ]]; then
      selected+=("$entry")
    fi
  done
}

# installed_plugins.json is the state, so no separate state file is needed.
reconcile_plugins() {
  if ! have claude; then
    warn "claude not found; skipping plugin reconcile"
    return 1
  fi

  local entry name repo installed desired profile
  local -a wanted_marketplaces wanted_plugins

  profile=$(active_profile)
  step "plugin profile: $profile"

  # bash 3.2 errors on "${empty[@]}" under `set -u`, hence the ${x[@]+...} guards.
  select_for_profile "$profile" ${MARKETPLACES[@]+"${MARKETPLACES[@]}"}
  wanted_marketplaces=(${selected[@]+"${selected[@]}"})
  select_for_profile "$profile" ${PLUGINS[@]+"${PLUGINS[@]}"}
  wanted_plugins=(${selected[@]+"${selected[@]}"})

  for entry in ${wanted_marketplaces[@]+"${wanted_marketplaces[@]}"}; do
    name="${entry%%=*}"
    repo="${entry#*=}"
    if [[ -f "$known_marketplaces" ]] &&
      jq -e --arg n "$name" 'has($n)' "$known_marketplaces" >/dev/null 2>&1; then
      continue
    fi
    try claude plugin marketplace add "$repo" </dev/null || true
  done

  installed=""
  if [[ -f "$installed_plugins" ]]; then
    installed=$(jq -r '.plugins // {} | keys[]' "$installed_plugins" 2>/dev/null)
  fi

  for entry in ${wanted_plugins[@]+"${wanted_plugins[@]}"}; do
    if grep -Fqx -- "$entry" <<<"$installed"; then
      try claude plugin update "$entry" </dev/null || true
    else
      try claude plugin install "$entry" --scope user </dev/null || true
    fi
  done

  # Uninstall anything installed that this profile no longer declares.
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    for desired in ${wanted_plugins[@]+"${wanted_plugins[@]}"}; do
      [[ "$desired" == "$entry" ]] && continue 2
    done
    try claude plugin uninstall "$entry" --scope user -y </dev/null || true
  done <<<"$installed"

  # Drop marketplaces no longer declared, so their caches do not linger.
  [[ -f "$known_marketplaces" ]] || return 0
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    for entry in ${wanted_marketplaces[@]+"${wanted_marketplaces[@]}"}; do
      [[ "${entry%%=*}" == "$name" ]] && continue 2
    done
    try claude plugin marketplace remove "$name" </dev/null || true
  done < <(jq -r 'keys[]' "$known_marketplaces" 2>/dev/null)
}

main() {
  verify_prerequisites || return 1
  deploy_local_ai
  merge_claude_settings || true
  reconcile_skills
  install_pi_packages || true
  reconcile_plugins || true

  if [[ "$failures" -gt 0 ]]; then
    printf '\nDone with %s warning(s). Restart agents after resolving them.\n' "$failures" >&2
    return 1
  fi

  printf '\nDone. Restart agents to pick up skill changes.\n'
}

main "$@"
