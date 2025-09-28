#!/usr/bin/env bash
# ssh-sign-wrapper.sh - Simplified wrapper for Git and JJ

set -euo pipefail

# Configuration
SSH_DIR="$HOME/.ssh"
SAVE_KEYS_SCRIPT="$HOME/.local/bin/save-ssh-keys.sh"
LOG_FILE="/tmp/ssh-sign-wrapper.log"

# Detect OS and set 1Password path
if [[ "$OSTYPE" == "darwin"* ]]; then
  OPSIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OPSIGN="/opt/1Password/op-ssh-sign"
else
  echo "Unsupported OS: $OSTYPE" >&2
  exit 1
fi

# Simple logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE"
}

log "Called with args: $*"

# Check if we have local keys (just for caching, not for signing)
target_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIidIqt1fDMmhx1KUyCyKduIJCcJMhQk+f5vd6JEjsO"
found_local_key=false

for private_key in "$SSH_DIR"/id_*; do
  [[ ! -f "$private_key" ]] && continue
  [[ "$private_key" == *.pub ]] && continue
  [[ "$private_key" == *.bak ]] && continue

  pub_key="${private_key}.pub"
  if [[ -f "$pub_key" ]]; then
    stored_key=$(awk '{print $1" "$2}' "$pub_key" 2>/dev/null)
    if [[ "$stored_key" == "$target_key" ]]; then
      found_local_key=true
      log "Found cached local key: $private_key"
      break
    fi
  fi
done

# If no local key, sync from 1Password
if [[ "$found_local_key" == "false" ]]; then
  log "No local key found, syncing from 1Password"
  if [[ -x "$SAVE_KEYS_SCRIPT" ]]; then
    "$SAVE_KEYS_SCRIPT" >/dev/null 2>&1 || log "Sync failed"
  fi
fi

# Always use 1Password for signing (since keys are PKCS#8)
log "Using 1Password for signing"
exec "$OPSIGN" "$@"
