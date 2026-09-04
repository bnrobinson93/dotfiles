#!/usr/bin/env bash
set -u

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "$file missing: $expected"
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if grep -Fq -- "$unexpected" "$file"; then
    fail "$file unexpectedly contains: $unexpected"
  fi
}

make_fake_tools() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"

  for tool in stow claude codex opencode pi; do
    ln -s "$bin_dir/fake-tool" "$bin_dir/$tool"
  done

  cat >"$bin_dir/fake-tool" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >>"$COMMAND_LOG"
if [[ "$(basename "$0") $*" == "codex mcp list --json" ]]; then
  printf '[]\n'
fi
if [[ "$(basename "$0") $*" == "claude mcp list" ]]; then
  printf 'plugin-mcp: connected\n'
fi
EOF
  chmod +x "$bin_dir/fake-tool"

  cat >"$bin_dir/npx" <<'EOF'
#!/usr/bin/env bash
printf 'npx %s\n' "$*" >>"$COMMAND_LOG"
if [[ -n "${FAKE_NPX_FAIL_SOURCE:-}" && "$*" == *"$FAKE_NPX_FAIL_SOURCE"* ]]; then
  exit 1
fi
EOF
  chmod +x "$bin_dir/npx"
}

run_updater() {
  local case_dir="$1"
  local fail_source="${2:-}"
  mkdir -p "$case_dir/home/.agents" "$case_dir/state" "$case_dir/bin"
  make_fake_tools "$case_dir/bin"
  COMMAND_LOG="$case_dir/commands" \
    FAKE_NPX_FAIL_SOURCE="$fail_source" \
    HOME="$case_dir/home" \
    XDG_CONFIG_HOME="$case_dir/home/.config" \
    XDG_STATE_HOME="$case_dir/state" \
    PATH="$case_dir/bin:$PATH" \
    "$repo_dir/update-skills.sh" >"$case_dir/output" 2>&1
}

test_new_machine_installs_without_removing() {
  local case_dir="$test_root/new-machine"
  mkdir -p "$case_dir/state/skills"
  cat >"$case_dir/state/skills/.skill-lock.json" <<'EOF'
{
  "skills": {
    "caveman": {"source": "JuliusBrussee/caveman"},
    "find-skills": {"source": "vercel-labs/skills"},
    "figma": {"source": "openai/skills"},
    "ponytail": {"source": "DietrichGebert/ponytail"},
    "hunk-review": {"source": "modem-dev/hunk"},
    "teach": {"source": "mattpocock/skills"},
    "grilling": {"source": "mattpocock/skills"}
  }
}
EOF

  run_updater "$case_dir"

  assert_contains "$case_dir/commands" "claude plugin marketplace add JuliusBrussee/caveman"
  assert_contains "$case_dir/commands" "claude plugin install caveman@caveman --scope user"
  assert_contains "$case_dir/commands" "npx -y skills add mattpocock/skills"
  assert_contains "$case_dir/commands" "pi install npm:@mjakl/pi-subagent"
  assert_contains "$case_dir/commands" "stow -R -d $repo_dir/ai -t $case_dir/home/.pi/agent dot-pi"
  assert_not_contains "$case_dir/commands" "skills remove"
  assert_contains "$case_dir/state/dotfiles/managed-skills.tsv" $'mattpocock/skills||shared\tclaude-code,codex,opencode\tgrilling'
  assert_contains "$case_dir/state/dotfiles/managed-skills.tsv" $'mattpocock/skills||shared\tclaude-code,codex,opencode\tteach'
}

test_rerun_removes_only_stale_resolved_skills() {
  local case_dir="$test_root/rerun"
  mkdir -p "$case_dir/state/skills" "$case_dir/state/dotfiles"
  cat >"$case_dir/state/skills/.skill-lock.json" <<'EOF'
{
  "skills": {
    "caveman": {"source": "JuliusBrussee/caveman"},
    "find-skills": {"source": "vercel-labs/skills"},
    "figma": {"source": "openai/skills"},
    "ponytail": {"source": "DietrichGebert/ponytail"},
    "hunk-review": {"source": "modem-dev/hunk"},
    "teach": {"source": "mattpocock/skills"}
  }
}
EOF
  cat >"$case_dir/state/dotfiles/managed-skills.tsv" <<'EOF'
retired/skills||shared	claude-code,codex,opencode	retired-skill
mattpocock/skills||shared	claude-code,codex,opencode	teach
EOF

  run_updater "$case_dir"

  assert_contains "$case_dir/commands" "npx -y skills remove retired-skill -g -a claude-code -y"
  assert_contains "$case_dir/commands" "npx -y skills remove retired-skill -g -a codex -y"
  assert_contains "$case_dir/commands" "npx -y skills remove retired-skill -g -a opencode -y"
  assert_not_contains "$case_dir/commands" "skills remove teach"
  assert_not_contains "$case_dir/state/dotfiles/managed-skills.tsv" "retired-skill"
}

test_failed_update_preserves_snapshot_and_skips_removal() {
  local case_dir="$test_root/failed-update"
  mkdir -p "$case_dir/state/skills" "$case_dir/state/dotfiles"
  cat >"$case_dir/state/skills/.skill-lock.json" <<'EOF'
{"skills": {"teach": {"source": "mattpocock/skills"}}}
EOF
  cat >"$case_dir/state/dotfiles/managed-skills.tsv" <<'EOF'
retired/skills||shared	claude-code,codex,opencode	retired-skill
EOF
  cp "$case_dir/state/dotfiles/managed-skills.tsv" "$case_dir/before"

  if run_updater "$case_dir" "mattpocock/skills"; then
    fail "updater unexpectedly succeeded"
  fi

  cmp -s "$case_dir/before" "$case_dir/state/dotfiles/managed-skills.tsv" || \
    fail "failed reconciliation changed snapshot"
  assert_not_contains "$case_dir/commands" "skills remove retired-skill"
}

test_cleanup_lists_skills_and_mcps() {
  local case_dir="$test_root/cleanup"
  mkdir -p \
    "$case_dir/home/.agents/skills/shared-skill" \
    "$case_dir/home/.claude/skills/claude-skill" \
    "$case_dir/home/.codex/skills/codex-skill" \
    "$case_dir/home/.codex/skills/.system/system-skill" \
    "$case_dir/home/.claude/plugins/cache/example/1.0.0/skills/plugin-skill" \
    "$case_dir/home/.config/opencode/skills/opencode-skill" \
    "$case_dir/.agents/skills/workspace-skill" \
    "$case_dir/bin"
  for skill_file in \
    "$case_dir/home/.agents/skills/shared-skill/SKILL.md" \
    "$case_dir/home/.claude/skills/claude-skill/SKILL.md" \
    "$case_dir/home/.codex/skills/codex-skill/SKILL.md" \
    "$case_dir/home/.codex/skills/.system/system-skill/SKILL.md" \
    "$case_dir/home/.claude/plugins/cache/example/1.0.0/skills/plugin-skill/SKILL.md" \
    "$case_dir/home/.config/opencode/skills/opencode-skill/SKILL.md" \
    "$case_dir/.agents/skills/workspace-skill/SKILL.md"; do
    printf '%s\n' '---' >"$skill_file"
  done
  make_fake_tools "$case_dir/bin"
  cat >"$case_dir/home/.claude.json" <<EOF
{
  "mcpServers": {"global-mcp": {"command": "global"}},
  "projects": {
    "$repo_dir": {"mcpServers": {"workspace-mcp": {"command": "workspace"}}}
  }
}
EOF
  cat >"$case_dir/.mcp.json" <<'EOF'
{"mcpServers": {"workspace-file-mcp": {"command": "workspace-file"}}}
EOF

  (
    cd "$case_dir" || exit 1
    COMMAND_LOG="$case_dir/commands" \
      HOME="$case_dir/home" \
      XDG_CONFIG_HOME="$case_dir/home/.config" \
      PATH="$case_dir/bin:$PATH" \
      "$repo_dir/ai-cleanup.sh" list-skills >"$case_dir/skills"
    COMMAND_LOG="$case_dir/commands" \
      HOME="$case_dir/home" \
      XDG_CONFIG_HOME="$case_dir/home/.config" \
      PATH="$case_dir/bin:$PATH" \
      "$repo_dir/ai-cleanup.sh" list-mcps >"$case_dir/mcps"
  )

  assert_contains "$case_dir/skills" "shared-skill"
  assert_contains "$case_dir/skills" "claude-skill"
  assert_contains "$case_dir/skills" "codex-skill"
  assert_contains "$case_dir/skills" "opencode-skill"
  assert_contains "$case_dir/skills" "system-skill"
  assert_contains "$case_dir/skills" "plugin-skill"
  assert_contains "$case_dir/skills" "workspace-skill"
  assert_contains "$case_dir/mcps" "Claude global: global-mcp"
  assert_contains "$case_dir/mcps" "Claude workspace file: workspace-file-mcp"
  assert_contains "$case_dir/mcps" "Claude resolved: plugin-mcp: connected"
  assert_contains "$case_dir/mcps" "Codex: none"
}

test_verify_claude_settings_flags_broken_hooks() {
  local case_dir="$test_root/verify-settings"
  local settings="$case_dir/home/.claude/settings.json"
  mkdir -p "$case_dir/home/.claude/hooks"
  printf '#!/bin/sh\n' >"$case_dir/home/.claude/hooks/live.sh"

  local -a run=(
    env
    HOME="$case_dir/home"
    XDG_CONFIG_HOME="$case_dir/home/.config"
    "$repo_dir/update-skills.sh" --verify-claude-settings
  )

  cat >"$settings" <<EOF
{
  "statusLine": {"type": "command", "command": "bash '$case_dir/home/.claude/hooks/live.sh'"},
  "hooks": {"UserPromptSubmit": [{"hooks": [
    {"type": "command", "command": "bash '$case_dir/home/.claude/hooks/live.sh'"}
  ]}]}
}
EOF
  "${run[@]}" >"$case_dir/ok-out" 2>&1 || fail "verify rejected settings whose hooks all exist"

  cat >"$settings" <<EOF
{"hooks": {"UserPromptSubmit": [{"hooks": [
  {"type": "command", "command": "node \"$case_dir/home/.claude/hooks/gone.js\""}
]}]}}
EOF
  if "${run[@]}" >"$case_dir/missing-out" 2>&1; then
    fail "verify accepted a hook pointing at a missing file"
  fi
  assert_contains "$case_dir/missing-out" "missing file"

  cat >"$settings" <<'EOF'
{"PostToolUse": [{"hooks": [{"type": "command", "command": "true"}]}]}
EOF
  if "${run[@]}" >"$case_dir/stray-out" 2>&1; then
    fail "verify accepted a hook event at the top level"
  fi
  assert_contains "$case_dir/stray-out" "top level"
}

test_new_machine_installs_without_removing
printf 'PASS: updater installs desired state on new machine\n'
test_rerun_removes_only_stale_resolved_skills
printf 'PASS: updater removes stale managed skills\n'
test_failed_update_preserves_snapshot_and_skips_removal
printf 'PASS: failed update preserves managed snapshot\n'
test_cleanup_lists_skills_and_mcps
printf 'PASS: cleanup lists skills and MCPs\n'
test_verify_claude_settings_flags_broken_hooks
printf 'PASS: verify-claude-settings flags broken hooks\n'
