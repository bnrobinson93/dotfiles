#!/bin/bash
# ~/.local/bin/gitmux_conditional.sh
# Show gitmux only when in a git repository with catppuccin theming

# Get the current pane's path from tmux
PANE_PATH="${1:-$(tmux display-message -p "#{pane_current_path}")}"

# Quick git repo check
if cd "$PANE_PATH" 2>/dev/null && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # We're in a git repo, show gitmux with catppuccin styling
  if command -v gitmux >/dev/null 2>&1; then
    # Use gitmux if available
    output=$(gitmux -cfg ~/.config/gitmux/gitmux.conf "$PANE_PATH" 2>/dev/null)
    if [[ -n "$output" ]]; then
      # Apply catppuccin-style formatting
      echo "#[fg=#cba6f7,bg=#313244,nobold,nounderscore,noitalics]#[fg=#11111b,bg=#cba6f7,nobold,nounderscore,noitalics] $output #[fg=#cba6f7,bg=#313244,nobold,nounderscore,noitalics]"
    fi
  else
    # Fallback to simple git status with catppuccin styling
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
      # Check for uncommitted changes
      if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        status="*"
      else
        status=""
      fi
      # Apply catppuccin-style formatting
      echo "#[fg=#cba6f7,bg=#313244,nobold,nounderscore,noitalics]#[fg=#11111b,bg=#cba6f7,nobold,nounderscore,noitalics]  $branch$status #[fg=#cba6f7,bg=#313244,nobold,nounderscore,noitalics]"
    fi
  fi
fi
