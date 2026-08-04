#!/bin/bash
# statusline for Claude Code
# Renders caveman mode, repo, PR, branch, context, and worktree.

input=$(cat)

# caveman mode
FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
if [ ! -L "$FLAG" ] && [ -f "$FLAG" ]; then
  MODE=$(head -c 64 "$FLAG" 2>/dev/null | tr -d '\n\r' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
  case "$MODE" in
    off|lite|full|ultra|wenyan-lite|wenyan|wenyan-full|wenyan-ultra|commit|review|compress)
      if [ -z "$MODE" ] || [ "$MODE" = "full" ]; then
        printf '\033[38;5;172m[CAVEMAN]\033[0m '
      else
        SUFFIX=$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')
        printf '\033[38;5;172m[CAVEMAN:%s]\033[0m ' "$SUFFIX"
      fi

      # caveman savings suffix
      if [ "${CAVEMAN_STATUSLINE_SAVINGS:-1}" != "0" ]; then
        SAVINGS_FILE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-statusline-suffix"
        if [ -f "$SAVINGS_FILE" ] && [ ! -L "$SAVINGS_FILE" ]; then
          SAVINGS=$(head -c 64 "$SAVINGS_FILE" 2>/dev/null | tr -d '\000-\037')
          [ -n "$SAVINGS" ] && printf '\033[38;5;172m%s\033[0m ' "$SAVINGS"
        fi
      fi
      ;;
  esac
fi

# repo owner/name
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
[ -n "$repo" ] && printf '\033[38;5;111m%s\033[0m ' "$repo"

# worktree (jj workspace)
wt=$(echo "$input" | jq -r '.worktree.name // empty')
[ -n "$wt" ] && printf '\033[38;5;183m[wt:%s]\033[0m ' "$wt"

# jj workspace / bookmark / desc, else git branch
if type jj >/dev/null 2>&1 && jj --ignore-working-copy workspace root >/dev/null 2>&1; then
  # ws<TAB>change-id<TAB>description
  IFS=$'\t' read -r ws cid desc < <(jj --ignore-working-copy log -r @ --no-graph \
    -T 'working_copies.map(|w| w.name()).join(",") ++ "\t" ++ change_id.shortest(8) ++ "\t" ++ description.first_line()' 2>/dev/null)
  bm=$(jj --ignore-working-copy log -r 'closest_bookmark(@)' --no-graph \
    -T 'bookmarks.map(|b| b.name()).join(" ")' 2>/dev/null | awk '{print $1}')

  [ -n "$ws" ] && printf '\033[38;5;78m%s\033[0m' "$ws"
  [ -n "$bm" ] && printf '\033[38;5;244m/\033[38;5;213m%s\033[0m' "$bm"
  printf '\033[38;5;244m/\033[0m\033[38;5;255m%s\033[0m ' "${desc:-$cid}"
elif type git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
  branch=$(git -c advice.detachedHead=false symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && printf '\033[38;5;214m%s\033[0m ' "$branch"
fi

# PR badge
pr=$(echo "$input" | jq -r '.pr.number // empty')
if [ -n "$pr" ]; then
  state=$(echo "$input" | jq -r '.pr.review_state // "open"')
  printf '\033[38;5;156mPR#%s(%s)\033[0m ' "$pr" "$state"
fi

# context used: "12.3k (34%)" — tokens yellow, parens gray
ctx=$(echo "$input" | jq -r '
  .context_window // empty
  | (.total_input_tokens // empty) as $t
  | (.used_percentage // (if .remaining_percentage then 100 - .remaining_percentage else empty end)) as $p
  | if $t then (if $t >= 1000 then ((($t/100)|floor)/10|tostring) + "k" else ($t|tostring) end) else "" end
    + " " + (if $p then (($p|floor)|tostring) else "" end)')
tok=${ctx% *}
pct=${ctx#* }
[ -n "$tok" ] && printf '\033[38;5;220m%s\033[0m' "$tok"
[ -n "$pct" ] && printf '\033[38;5;244m (%s%%)\033[0m' "$pct"
