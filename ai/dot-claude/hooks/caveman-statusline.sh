#!/bin/bash
# statusline for Claude Code
# Renders caveman mode, repo, PR, branch, context, and worktree.

input=$(cat)

# Catppuccin Mocha palette (truecolor, matches terminal theme)
PEACH=$'\033[38;2;250;179;135m'
BLUE=$'\033[38;2;137;180;250m'
LAVENDER=$'\033[38;2;180;190;254m'
GREEN=$'\033[38;2;166;227;161m'
PINK=$'\033[38;2;245;194;231m'
TEAL=$'\033[38;2;148;226;213m'
YELLOW=$'\033[38;2;249;226;175m'
TEXT=$'\033[38;2;205;214;244m'
OVERLAY=$'\033[38;2;108;112;134m'
OFF=$'\033[0m'

# caveman mode
FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
if [ ! -L "$FLAG" ] && [ -f "$FLAG" ]; then
  MODE=$(head -c 64 "$FLAG" 2>/dev/null | tr -d '\n\r' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
  case "$MODE" in
    off|lite|full|ultra|wenyan-lite|wenyan|wenyan-full|wenyan-ultra|commit|review|compress)
      if [ -z "$MODE" ] || [ "$MODE" = "full" ]; then
        printf '%s[CAVEMAN]%s ' "$PEACH" "$OFF"
      else
        SUFFIX=$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')
        printf '%s[CAVEMAN:%s]%s ' "$PEACH" "$SUFFIX" "$OFF"
      fi

      # caveman savings suffix
      if [ "${CAVEMAN_STATUSLINE_SAVINGS:-1}" != "0" ]; then
        SAVINGS_FILE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-statusline-suffix"
        if [ -f "$SAVINGS_FILE" ] && [ ! -L "$SAVINGS_FILE" ]; then
          SAVINGS=$(head -c 64 "$SAVINGS_FILE" 2>/dev/null | tr -d '\000-\037')
          [ -n "$SAVINGS" ] && printf '%s%s%s ' "$PEACH" "$SAVINGS" "$OFF"
        fi
      fi
      ;;
  esac
fi

# repo owner/name
repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')
[ -n "$repo" ] && printf '%s%s%s ' "$BLUE" "$repo" "$OFF"

# worktree (jj workspace)
wt=$(echo "$input" | jq -r '.worktree.name // empty')
[ -n "$wt" ] && printf '%s[wt:%s]%s ' "$LAVENDER" "$wt" "$OFF"

# jj workspace / bookmark / desc, else git branch
if type jj >/dev/null 2>&1 && jj --ignore-working-copy workspace root >/dev/null 2>&1; then
  # ws<US>change-id<US>description — \x1f is non-whitespace, so empty fields survive `read`
  IFS=$'\x1f' read -r ws cid desc < <(jj --ignore-working-copy log -r @ --no-graph \
    -T 'working_copies.map(|w| w.name()).join(",") ++ "\x1f" ++ change_id.shortest(8) ++ "\x1f" ++ description.first_line()' 2>/dev/null)
  bm=$(jj --ignore-working-copy log -r 'closest_bookmark(@)' --no-graph \
    -T 'bookmarks.map(|b| b.name()).join(" ")' 2>/dev/null | awk '{print $1}')

  # desc, else Claude's suggested session name, else change id
  if [ -z "$desc" ]; then
    desc=$(echo "$input" | jq -r '.session_name // empty' | tr -d '\000-\037')
    [ ${#desc} -gt 40 ] && desc="${desc:0:39}…"
  fi

  # join present segments with a slash — no leading/dangling separators
  sep=''
  if [ -n "$ws" ]; then
    printf '%s%s%s' "$GREEN" "$ws" "$OFF"
    sep="$OVERLAY/$OFF"
  fi
  if [ -n "$bm" ]; then
    printf '%s%s%s%s' "$sep" "$PINK" "$bm" "$OFF"
    sep="$OVERLAY/$OFF"
  fi
  printf '%s%s%s%s ' "$sep" "$TEXT" "${desc:-$cid}" "$OFF"
elif type git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
  branch=$(git -c advice.detachedHead=false symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && printf '%s%s%s ' "$PEACH" "$branch" "$OFF"
fi

# PR badge
pr=$(echo "$input" | jq -r '.pr.number // empty')
if [ -n "$pr" ]; then
  state=$(echo "$input" | jq -r '.pr.review_state // "open"')
  printf '%sPR#%s(%s)%s ' "$TEAL" "$pr" "$state" "$OFF"
fi

# context used: "12.3k (34%)" — tokens yellow, parens dim
ctx=$(echo "$input" | jq -r '
  .context_window // empty
  | (.total_input_tokens // empty) as $t
  | (.used_percentage // (if .remaining_percentage then 100 - .remaining_percentage else empty end)) as $p
  | if $t then (if $t >= 1000 then ((($t/100)|floor)/10|tostring) + "k" else ($t|tostring) end) else "" end
    + " " + (if $p then (($p|floor)|tostring) else "" end)')
tok=${ctx% *}
pct=${ctx#* }
[ -n "$tok" ] && printf '%s%s%s' "$YELLOW" "$tok" "$OFF"
[ -n "$pct" ] && printf '%s (%s%%)%s' "$OVERLAY" "$pct" "$OFF"

exit 0
