#!/usr/bin/env bash
set -u

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

merge="$repo_dir/dot-local/bin/omarchy-shell-merge"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

run_merge() {
  OMARCHY_SHELL_DEFAULTS="$test_root/upstream.json" \
  OMARCHY_SHELL_OVERLAY="$test_root/overlay.json" \
  OMARCHY_SHELL_CONFIG="$test_root/live.json" \
    "$merge" "$@"
}

ids() {
  jq -r --arg path "$1" 'getpath($path | split("."))[] | .id' "$test_root/live.json"
}

cat >"$test_root/upstream.json" <<'EOF'
{
  "version": 1,
  "idle": { "screensaver": 150, "lock": 300 },
  "bar": {
    "position": "top",
    "transparent": false,
    "layout": {
      "left": [{ "id": "omarchy.menu" }, { "id": "omarchy.workspaces" }],
      "center": [{ "id": "omarchy.clock", "format": "dddd HH:mm", "formatAlt": "d MMMM yyyy" }],
      "right": [{ "id": "omarchy.power" }]
    }
  },
  "plugins": []
}
EOF

cat >"$test_root/overlay.json" <<'EOF'
{
  "version": 1,
  "remove": ["omarchy.menu"],
  "idle": { "lock": 900 },
  "bar": {
    "transparent": true,
    "layout": {
      "left": [{ "id": "menu-button" }, { "id": "omarchy.workspaces" }],
      "center": [{ "id": "omarchy.clock", "format": "ddd d MMM HH:mm" }],
      "right": [{ "id": "omarchy.power" }]
    }
  },
  "plugins": [{ "id": "idle-ladder" }]
}
EOF

output="$(run_merge 2>&1)" || fail "first merge exited non-zero: $output"

[ "$(ids bar.layout.left)" = "$(printf 'menu-button\nomarchy.workspaces')" ] \
  || fail "removed upstream widget or our ordering did not survive: $(ids bar.layout.left)"
[ "$(jq -r '.bar.layout.center[0].format' "$test_root/live.json")" = "ddd d MMM HH:mm" ] \
  || fail "our per-widget setting lost to upstream's"
[ "$(jq -r '.bar.layout.center[0].formatAlt' "$test_root/live.json")" = "d MMMM yyyy" ] \
  || fail "upstream setting we do not override was dropped"
[ "$(jq -r '.idle.screensaver' "$test_root/live.json")" = "150" ] \
  || fail "upstream idle default did not survive a partial override"
[ "$(jq -r '.idle.lock' "$test_root/live.json")" = "900" ] || fail "our idle override lost"
[ "$(jq -r '.bar.transparent' "$test_root/live.json")" = "true" ] || fail "our bar override lost"
[ "$(ids plugins)" = "idle-ladder" ] || fail "our plugin list lost: $(ids plugins)"

# The live file is generated state: the shell writes widget toggles and plugin
# enablement into it, and the next merge is expected to discard both.
jq '.bar.layout.right[0].showPercentage = true | .plugins += [{"id": "enabled-by-hand"}]' \
  "$test_root/live.json" >"$test_root/live.next" && mv "$test_root/live.next" "$test_root/live.json"
output="$(run_merge 2>&1)" || fail "merge over live drift exited non-zero: $output"
[ "$(jq -r '.bar.layout.right[0].showPercentage' "$test_root/live.json")" = "null" ] \
  || fail "live widget drift survived the merge"
[ "$(ids plugins)" = "idle-ladder" ] || fail "live plugin drift survived the merge"
case "$output" in
  *showPercentage*) ;;
  *) fail "merge did not print what it discarded" ;;
esac

# An upstream release adding a widget should reach the bar without us listing it.
jq '.bar.layout.right += [{ "id": "omarchy.brandnew" }]' "$test_root/upstream.json" \
  >"$test_root/upstream.next" && mv "$test_root/upstream.next" "$test_root/upstream.json"
output="$(run_merge 2>&1)" || fail "merge with a new upstream widget exited non-zero: $output"
[ "$(ids bar.layout.right)" = "$(printf 'omarchy.power\nomarchy.brandnew')" ] \
  || fail "new upstream widget was not appended: $(ids bar.layout.right)"
case "$output" in
  *"inherited new upstream entry 'omarchy.brandnew'"*) ;;
  *) fail "inheriting a widget was not logged" ;;
esac

output="$(run_merge 2>&1)" || fail "idempotent re-run exited non-zero: $output"
case "$output" in
  *"already matches the overlay"*) ;;
  *) fail "re-running the merge rewrote an unchanged file" ;;
esac

# A schema bump must stop rather than emit a hybrid file the shell may misread.
jq '.version = 2' "$test_root/upstream.json" >"$test_root/upstream.next" \
  && mv "$test_root/upstream.next" "$test_root/upstream.json"
before="$(cat "$test_root/live.json")"
if output="$(run_merge 2>&1)"; then
  fail "merge across a version bump succeeded: $output"
fi
[ "$before" = "$(cat "$test_root/live.json")" ] || fail "failed merge still wrote shell.json"

printf 'PASS: omarchy-shell-merge\n'
