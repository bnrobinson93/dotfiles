#!/usr/bin/env bash
set -u

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
fish_bin="$(command -v fish)"
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin"

cat >"$test_root/bin/jj" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == "git root" ]] || exit 1
printf '/fake/repo/.git\n'
EOF

cat >"$test_root/bin/gh" <<'EOF'
#!/usr/bin/env bash
if [[ "$1 $2" == "repo view" ]]; then
  [[ "${GIT_DIR:-}" == "/fake/repo/.git" ]] || exit 1
  printf '%s\n' org/repo org/repo org
  exit 0
fi

[[ "$1 $2" == "pr list" ]] || exit 1
[[ " $* " == *" --repo org/repo "* ]] || exit 1
EOF

chmod +x "$test_root/bin/gh" "$test_root/bin/jj"

cat >"$test_root/file-pr.md" <<'EOF'
---
name: file-pr
description: test fixture
---

Problem-first PR guidance.
EOF

# Fish expands this script.
# shellcheck disable=SC2016
PATH="$test_root/bin:/usr/bin:/bin" "$fish_bin" --no-config -c '
source $argv[1]

function test_read_skill_body --argument-names skill_path
    set -l body (__ghpr_read_skill_body $skill_path | string collect)

    string match -q "*Problem-first PR guidance.*" -- "$body"
    and not string match -q "*description: test fixture*" -- "$body"
end

function test_find_pr --no-scope-shadowing
    set -l is_jj true
    set -l current_branch feat/example
    set -l target_repo ""
    set -l pr_head_selector $current_branch
    set -l pr_url ""
    set -l desc_only false
    set -l recent_titles ""

    __ghpr_find_pr
    or return 1

    not set -q GIT_DIR
end

test_read_skill_body $argv[2]
or return 1

test_find_pr
' "$repo_dir/fish/functions/ghpr.fish" "$test_root/file-pr.md" || exit 1

commit_messages_line="$(grep -nF '## Commit Messages' "$repo_dir/fish/functions/ghpr.fish" | cut -d: -f1)"
pr_guidance_line="$(grep -nF 'PR guidance (authoritative' "$repo_dir/fish/functions/ghpr.fish" | cut -d: -f1)"
[[ "$pr_guidance_line" -gt "$commit_messages_line" ]] || exit 1

if grep -qF '## Test Evidence' "$repo_dir/ai/skills/commit-and-pr/SKILL.md"; then
    echo 'Error: file-pr skill cues the unwanted test-evidence section'
    exit 1
fi

printf 'PASS: ghpr resolves GitHub repository from JJ git root\n'
