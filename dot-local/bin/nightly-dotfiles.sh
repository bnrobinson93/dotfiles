#!/usr/bin/env bash
# nightly-dotfiles.sh — unattended dotfiles upkeep, meant for cron on the always-on box.
#
#   1. jj sync                 (fetch + rebase the main checkout onto trunk)
#   2. mise run stow           (redeploy symlinks from $DOTFILES; failures logged, not fatal)
#   3. verify Claude settings  (read-only; alerts if a hook/statusLine target is missing)
#   4. shell startup benchmark (fish vs zsh; measured, not guessed, fed into the review)
#   5. claude -p               (review the tree in a throwaway workspace, make changes)
#   6. jj git push + gh pr     (only when step 5 actually changed something)
#
# This script is tracked in the dotfiles repo (dot-local/bin/) and stowed to
# ~/.local/bin, which is on cron's PATH ahead of the system dirs. That means it can
# improve itself like any other file: a proposed edit to this script lands in the
# same PR as everything else, a human merges it, and the next run's `jj sync` pulls
# the new version in before re-executing — no unreviewed self-modification.
#
# The review runs in a disposable `jj workspace` so a dirty or behind main checkout
# never blocks it; the workspace is forgotten and deleted on exit. Opens at most one
# PR at a time: if an `ai/nightly-*` PR is already open, the review is skipped.
#
# Any hard failure opens a deduplicated GitHub issue (label: nightly-failure) so a
# broken run is visible without reading the log.
#
# Logs to ~/opt/log/nightly-dotfiles.log. Scratch prototypes the review builds to
# validate a tool/alignment suggestion live in ~/opt/nightly-scratch and are NOT
# cleaned up here — see the prototype skill note in the review prompt below.

set -uo pipefail

export PATH="$HOME/.local/bin:$HOME/opt/bin:/usr/local/bin:/usr/bin:/bin"
export GH_REPO="${GH_REPO:-bnrobinson93/dotfiles}"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
LOG_DIR="$HOME/opt/log"
LOG="$LOG_DIR/nightly-dotfiles.log"
LOCK="/tmp/nightly-dotfiles.lock"
WORKTREE="$HOME/opt/nightly-worktree"
WORKTREE_NAME="$(basename "$WORKTREE")"
SCRATCH="$HOME/opt/nightly-scratch"
BRANCH="ai/nightly-$(date +%Y-%m-%d)"

mkdir -p "$LOG_DIR" "$SCRATCH"
exec >>"$LOG" 2>&1
echo "=== $(date -Is) start ==="

exec 9>"$LOCK"
flock -n 9 || { echo "another run holds the lock; exiting"; exit 0; }

cd "$DOTFILES" || exit 1

# One open issue per failure headline; a reopen or a second copy is just noise.
alert() {
  local title="nightly-dotfiles: $1"
  echo "ALERT: $title"
  command -v gh >/dev/null 2>&1 || return 0
  if [ -n "$(gh issue list --state open --search "$title in:title" --json number --jq '.[0].number' 2>/dev/null)" ]; then
    echo "issue already open; not filing another"
    return 0
  fi
  gh issue create --title "$title" --label nightly-failure --body \
    "$(printf 'Automated failure from nightly-dotfiles.sh on %s at %s.\n\nLast 40 log lines:\n\n```\n%s\n```\n' \
      "$(hostname)" "$(date -Is)" "$(tail -40 "$LOG")")" 2>&1 | tail -1
}

cleanup() {
  cd "$DOTFILES" || return
  if [ -e "$WORKTREE" ]; then
    jj workspace forget "$WORKTREE_NAME" 2>&1 | grep -v '^Hint:' || true
    rm -rf "$WORKTREE"
  fi
  echo "=== $(date -Is) done ==="
}
trap cleanup EXIT

echo "--- jj sync ---"
if ! jj sync 2>&1 | grep -v '^Hint:'; then
  alert "jj sync failed on the main checkout"
fi

echo "--- mise run stow ---"
if ! mise run stow 2>&1 | grep -viE '^\s+(level|LINK|UNLINK|.* does not need|.* did not exist)' | tail -20; then
  echo "stow reported a failure (see above); continuing"
fi

echo "--- verify Claude settings ---"
if ! "$DOTFILES/update-skills.sh" --verify-claude-settings 2>&1; then
  alert "Claude settings.json has a stale hook or statusLine entry"
fi

echo "--- shell startup benchmark ---"
# Measured, not guessed: CLAUDE.md records a baseline (fish ~35ms, zsh ~70ms, 2026-07-19)
# and the review below is told to flag drift against it rather than eyeball the configs.
bench_shell() {
  local bin="$1" n=7 total=0 start end
  command -v "$bin" >/dev/null 2>&1 || { echo "$bin: not installed"; return; }
  for _ in $(seq 1 "$n"); do
    start=$(date +%s%N)
    "$bin" -i -c exit >/dev/null 2>&1
    end=$(date +%s%N)
    total=$(( total + (end - start) ))
  done
  echo "$bin: $(( total / n / 1000000 ))ms avg (n=$n, interactive startup)"
}
BENCH_RESULTS="$(bench_shell fish; bench_shell zsh)"
echo "$BENCH_RESULTS"

open_pr=$(gh pr list --state open --json number,headRefName \
  --jq '[.[] | select(.headRefName | startswith("ai/nightly-"))] | first | .number' 2>/dev/null)
if [ -n "$open_pr" ] && [ "$open_pr" != "null" ]; then
  echo "PR #$open_pr from a previous night is still open; skipping review"
  exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude not installed; skipping review"
  exit 0
fi

echo "--- workspace ---"
rm -rf "$WORKTREE"
if ! jj workspace add "$WORKTREE" 2>&1 | grep -v '^Hint:'; then
  alert "could not create jj workspace"
  exit 1
fi
cd "$WORKTREE" || { alert "jj workspace vanished after creation"; exit 1; }

echo "--- claude review ---"
jj new 'trunk()' -m "ai: nightly dotfiles review" 2>&1 | grep -v '^Hint:'

PROMPT_TEMPLATE=$(cat <<'PROMPT'
You are doing an unattended nightly review of this dotfiles repository. Follow AGENTS.md
and CLAUDE.md. The working copy is a fresh commit on top of trunk; make your changes
directly in the tree.

Shell startup benchmark measured just before this run (interactive startup, avg of 7):
__BENCH_RESULTS__

Review the repo with these lenses:
  - bugs: shell quoting, unguarded commands, wrong paths, config that silently no-ops
  - cleanup: dead files, configs for tools no longer installed, duplicated settings
  - simplification: hand-rolled logic a tool already does, redundant layers of indirection
  - stale items: pinned versions long past, references to renamed or removed upstreams
  - visual bugs or hard-to-use tools and shortcuts; prefer ergonomics
  - performance: compare the benchmark above against the baseline noted in CLAUDE.md's
    Fish section. Meaningful drift (not run-to-run noise) is worth investigating — a
    newly-sourced tool init, a completion path added to fish_complete_path without
    caching, a lazy-load pattern in dot-zshrc that stopped being lazy. Update the noted
    baseline in CLAUDE.md only when you've also fixed or explained the drift, never just
    to make the number match.
  - fish/zsh alignment: this user drives fish day-to-day and keeps zsh maintained as a
    fallback, and prefers POSIX-compliant shell constructs where the two must share
    logic. Check that abbreviations/functions in fish/conf.d/03-abbreviations.fish and
    fish/functions/ have a matching alias or function in dot-zshrc (and vice versa) —
    flag drift, don't silently pick one side. Prefer expressing shared logic (an alias
    body, a small helper) in POSIX sh once and sourcing it from both, over maintaining
    two hand-written copies, when doing so doesn't fight either shell's idioms.
  - new tools: worth adopting, judged the way DevOps Toolbox (the YouTube channel) judges
    them — practical daily-driver CLI ergonomics, not novelty. Prefer tools that are
    already installed via mise or on the system over ones you'd need to add a curl|sh
    install step for.

Validating a tool or alignment idea: when a candidate is concrete enough to sanity-check
in a few lines but you're not confident enough to land it as a real diff, use the
prototype skill and write the throwaway test to __SCRATCH__ (a fixed scratch directory
that survives between nightly runs — NOT the repo, and NOT cleaned up automatically).
Name it with today's date and the question it answers, e.g.
__SCRATCH__/YYYY-MM-DD-fish-abbr-vs-zsh-alias.sh, so a human skimming that directory
later understands what it was for. If the prototype validates the idea, fold the real
change into this tree as a normal diff. If it doesn't, or you're validating something you
can't safely automate (installing an unseen binary), leave the idea out of the diff and
describe it plus what you tried in the PR body instead of silently dropping it.

Be conservative. This lands as a pull request that a human reviews, but it also lands on
machines that must keep booting: prefer a small number of changes you are confident in
over a broad sweep. Do not restructure the repo, do not mass-rename, do not bump pinned
versions you cannot verify, and do not add a dependency without wiring up its config.
If a machine-specific path or credential is involved, leave it alone.

If nothing meets that bar tonight, change nothing and say so. An empty night is a fine
outcome and is preferred over churn.

If multiple, completely different things are worth doing, create separate bookmarks and PRs against main.
PROMPT
)
PROMPT_TEMPLATE="${PROMPT_TEMPLATE//__BENCH_RESULTS__/$BENCH_RESULTS}"
PROMPT_TEMPLATE="${PROMPT_TEMPLATE//__SCRATCH__/$SCRATCH}"

printf '%s' "$PROMPT_TEMPLATE" | claude -p --permission-mode acceptEdits \
  --allowed-tools 'Read,Edit,Write,Grep,Glob,WebSearch,WebFetch,Bash(rg:*),Bash(fd:*),Bash(shellcheck:*),Bash(mise:*),Bash(stow -n:*),Bash(jj diff:*),Bash(jj log:*),Bash(jj st:*),Bash(fish -c:*),Bash(fish -i -c:*),Bash(zsh -c:*),Bash(zsh -i -c:*),Bash(command -v:*),Bash(hyperfine:*)'

if [ -z "$(jj diff --no-pager -s)" ]; then
  echo "no changes proposed; abandoning empty commit"
  jj abandon @ 2>&1 | grep -v '^Hint:'
  exit 0
fi

echo "--- changes ---"
jj diff --no-pager -s

echo "--- describe ---"
summary=$(jj diff --no-pager --git | head -c 60000 | claude -p \
  "Read this diff to a dotfiles repo. Reply with a commit message: a Conventional Commits
   subject line under 60 chars starting with 'ai: ', then a blank line, then 2-5 bullets
   saying what changed and why. No preamble, no code fences." 2>/dev/null)
if [ -z "$summary" ]; then
  summary="ai: nightly dotfiles review"
fi
jj describe -m "$summary" 2>&1 | grep -v '^Hint:'

echo "--- push ---"
jj bookmark create "$BRANCH" -r @ 2>&1 | grep -v '^Hint:'
if ! jj git push -b "$BRANCH" 2>&1 | grep -v '^Hint:'; then
  alert "jj git push failed for $BRANCH"
  exit 1
fi

echo "--- pr ---"
gh pr create --head "$BRANCH" --base main \
  --title "$(printf '%s' "$summary" | head -1)" \
  --body "$(printf '%s\n\n---\nOpened unattended by nightly-dotfiles.sh on %s. Nothing here has been run beyond the repo checks; review before merging.\n' "$(printf '%s' "$summary" | tail -n +2)" "$(hostname)")" \
  2>&1 | tail -3
