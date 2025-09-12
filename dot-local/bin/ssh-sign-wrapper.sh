#!/usr/bin/env bash
# ssh-sign-wrapper.sh - Simple wrapper: try local, fall back to 1Password, cache for next time

set -euo pipefail

# Configuration
SSH_DIR="$HOME/.ssh"
SAVE_KEYS_SCRIPT="$HOME/.local/bin/save-ssh-keys.sh"
LOG_FILE="/tmp/ssh-sign-wrapper.log"
OPSIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

# Always log for debugging
exec 2>>"$LOG_FILE"
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Parse arguments
mode=""
namespace="git"
key_input=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  -Y)
    mode="$2"
    shift 2
    ;;
  -n)
    namespace="$2"
    shift 2
    ;;
  -f)
    key_input="$2"
    shift 2
    ;;
  *) shift ;;
  esac
done

log "Mode: $mode, Namespace: $namespace, Key: $key_input"

# Get the key fingerprint we're looking for
target_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIidIqt1fDMmhx1KUyCyKduIJCcJMhQk+f5vd6JEjsO"

# Check if we have this key locally (in any format)
for private_key in "$SSH_DIR"/id_*; do
  [[ ! -f "$private_key" ]] && continue
  [[ "$private_key" == *.pub ]] && continue

  pub_key="${private_key}.pub"
  if [[ -f "$pub_key" ]]; then
    stored_key=$(awk '{print $1" "$2}' "$pub_key" 2>/dev/null)
    if [[ "$stored_key" == "$target_key" ]]; then
      log "Found matching local key: $private_key"

      # Key exists locally - use 1Password to sign (since it handles PKCS#8)
      # Create temp key file if needed
      temp_key=""
      if [[ ! -f "$key_input" ]]; then
        temp_key=$(mktemp)
        echo "$target_key 31802085+bnrobinson93@users.noreply.github.com" >"$temp_key"
        key_input="$temp_key"
      fi

      # Use 1Password with the local key (it can handle PKCS#8)
      log "Using 1Password to sign with locally cached key"

      # Buffer stdin to avoid issues
      input_data=$(mktemp)
      cat >"$input_data"

      "$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_input" <"$input_data"
      exit_code=$?

      rm -f "$input_data"
      [[ -n "$temp_key" ]] && rm -f "$temp_key"

      exit $exit_code
    fi
  fi
done

# Key not found locally - sync from 1Password and try again
log "Key not found locally, syncing from 1Password"

if [[ -x "$SAVE_KEYS_SCRIPT" ]]; then
  "$SAVE_KEYS_SCRIPT" >/dev/null 2>&1 || log "Sync failed"
fi

# Now use 1Password (key should be cached for next time)
log "Using 1Password for signing"

temp_key=""
if [[ ! -f "$key_input" ]]; then
  temp_key=$(mktemp)
  echo "$target_key 31802085+bnrobinson93@users.noreply.github.com" >"$temp_key"
  key_input="$temp_key"
fi

# Buffer stdin
input_data=$(mktemp)
cat >"$input_data"

"$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_input" <"$input_data"
exit_code=$?

rm -f "$input_data"
[[ -n "$temp_key" ]] && rm -f "$temp_key"

exit $exit_code
