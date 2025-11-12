#!/usr/bin/env bash

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

# Extract the key file path from arguments (should be after -f flag)
key_file=""
for ((i=1; i<=$#; i++)); do
  if [[ "${!i}" == "-f" ]]; then
    ((i++))
    key_file="${!i}"
    # Expand tilde to home directory
    key_file="${key_file/#\~/$HOME}"
    break
  fi
done

# If no key file specified in args, try to find the default signing key
if [[ -z "$key_file" ]]; then
  log "No key file in arguments, searching for default key"
  target_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIidIqt1fDMmhx1KUyCyKduIJCcJMhQk+f5vd6JEjsO"

  for private_key in "$SSH_DIR"/id_*; do
    [ ! -f "$private_key" ] && continue
    [[ "$private_key" == *.pub ]] && continue
    [[ "$private_key" == *.bak ]] && continue

    pub_key="${private_key}.pub"
    if [[ -f "$pub_key" ]]; then
      stored_key=$(awk '{print $1" "$2}' "$pub_key" 2>/dev/null)
      if [[ "$stored_key" == "$target_key" ]]; then
        key_file="$private_key"
        log "Found default local key: $key_file"
        break
      fi
    fi
  done
fi

# Check if the key file exists locally
if [[ -n "$key_file" && -f "$key_file" ]]; then
  log "Attempting to sign with local key: $key_file"

  # Try to sign with ssh-keygen using the local key
  if ssh-keygen "$@" 2>>"$LOG_FILE"; then
    log "Successfully signed with local key"
    exit 0
  else
    log "Local key signing failed, falling back to 1Password"
  fi
else
  log "Local key not found: $key_file"

  # If no local key, try to sync from 1Password
  if [[ -x "$SAVE_KEYS_SCRIPT" ]]; then
    log "Syncing keys from 1Password"
    "$SAVE_KEYS_SCRIPT" >/dev/null 2>&1 || log "Sync failed"

    # Retry with local key after sync
    if [[ -n "$key_file" && -f "$key_file" ]]; then
      log "Retrying with synced local key"
      if ssh-keygen "$@" 2>>"$LOG_FILE"; then
        log "Successfully signed with synced local key"
        exit 0
      fi
    fi
  fi

  log "Falling back to 1Password for signing"
fi

# Fallback to 1Password for signing
log "Using 1Password SSH agent"
exec "$OPSIGN" "$@"
