#!/usr/bin/env bash
set -u

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$test_root/foreign-cdp.mjs" <<'EOF'
globalThis.fetch = async () => new Response(JSON.stringify({
  Browser: "Foreign browser",
  webSocketDebuggerUrl: "ws://127.0.0.1/foreign",
}));
EOF

if TMPDIR="$test_root" BROWSER_DEBUG_PORT=19437 \
  node --import "$test_root/foreign-cdp.mjs" \
  "$repo_dir/ai/skills/browser-debug/scripts/browser-cdp.mjs" status \
  >"$test_root/output" 2>&1; then
  fail "browser debug accepted foreign CDP endpoint"
fi
grep -Fq "not owned by browser-debug" "$test_root/output" || \
  fail "browser debug returned wrong ownership error"

printf 'PASS: browser debug rejects foreign CDP endpoints\n'
