#!/usr/bin/env bash
# ssh-sign-wrapper.sh - Wrapper that works with both Git and JJ

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

# Always log for debugging
exec 2>>"$LOG_FILE"
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Parse arguments - Git passes: -Y sign -n git -f keyfile messagefile
# JJ passes: -Y sign -n git -f keyfile (message via stdin)
mode=""
namespace="git"
key_input=""
message_file=""

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
    # Check if there's a message file argument (Git style)
    if [[ $# -gt 0 && -f "$1" && "$1" != -* ]]; then
      message_file="$1"
      shift
    fi
    ;;
  *)
    # Any remaining file is likely the message file
    if [[ -f "$1" ]]; then
      message_file="$1"
    fi
    shift
    ;;
  esac
done

log "Mode: $mode, Namespace: $namespace, Key: $key_input, Message file: $message_file"

# Get the key fingerprint we're looking for
# Git creates a temp file with the public key, JJ uses our configured key
if [[ -f "$key_input" ]]; then
  # Read the key from the file
  target_key=$(cat "$key_input" | head -1 | awk '{print $1" "$2}')
  log "Read key from file: ${target_key:0:50}..."
else
  # Use the known key
  target_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIidIqt1fDMmhx1KUyCyKduIJCcJMhQk+f5vd6JEjsO"
  log "Using known key: ${target_key:0:50}..."
fi

# Check if we have this key locally
for private_key in "$SSH_DIR"/id_*; do
  [[ ! -f "$private_key" ]] && continue
  [[ "$private_key" == *.pub ]] && continue
  [[ "$private_key" == *.bak ]] && continue

  pub_key="${private_key}.pub"
  if [[ -f "$pub_key" ]]; then
    stored_key=$(awk '{print $1" "$2}' "$pub_key" 2>/dev/null)
    if [[ "$stored_key" == "$target_key" ]]; then
      log "Found matching local key: $private_key"

      # Check if it's OpenSSH format (can use ssh-keygen directly)
      if grep -q "BEGIN OPENSSH PRIVATE KEY" "$private_key" 2>/dev/null; then
        log "Key is in OpenSSH format, using ssh-keygen directly"

        # Determine input source
        if [[ -n "$message_file" && -f "$message_file" ]]; then
          # Git style - message is in a file
          log "Signing file content with ssh-keygen"
          ssh-keygen -Y sign -f "$private_key" -n "$namespace" <"$message_file"
        else
          # JJ style - message comes from stdin
          log "Signing stdin content with ssh-keygen"
          ssh-keygen -Y sign -f "$private_key" -n "$namespace"
        fi
        exit $?

      else
        # Key is PKCS#8 format, use 1Password
        log "Key is in PKCS#8 format, using 1Password"

        # Prepare key file for 1Password if needed
        if [[ ! -f "$key_input" ]]; then
          temp_key=$(mktemp)
          echo "$target_key 31802085+bnrobinson93@users.noreply.github.com" >"$temp_key"
          key_input="$temp_key"
        fi

        # Sign with 1Password
        if [[ -n "$message_file" && -f "$message_file" ]]; then
          log "Signing file with 1Password: $message_file"
          "$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_input" <"$message_file"
          exit_code=$?
        else
          log "Signing stdin with 1Password"
          input_data=$(mktemp)
          cat >"$input_data"
          "$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_input" <"$input_data"
          exit_code=$?
          rm -f "$input_data"
        fi

        [[ -n "${temp_key:-}" ]] && rm -f "$temp_key"
        exit $exit_code
      fi
    fi
  fi
done

# Key not found locally - sync from 1Password
log "Key not found locally, syncing from 1Password"

if [[ -x "$SAVE_KEYS_SCRIPT" ]]; then
  "$SAVE_KEYS_SCRIPT" >/dev/null 2>&1 || log "Sync failed"
fi

# Use 1Password for signing
log "Using 1Password for signing"

# Prepare key file if needed
if [[ ! -f "$key_input" ]]; then
  temp_key=$(mktemp)
  echo "$target_key 31802085+bnrobinson93@users.noreply.github.com" >"$temp_key"
  key_input="$temp_key"
fi

# Sign with 1Password
if [[ -n "$message_file" && -f "$message_file" ]]; then
  log "Final: Signing file with 1Password: $message_file"
  "$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_input" <"$message_file"
  exit_code=$?
else
  log "Final: Signing stdin with 1Password"
  input_data=$(mktemp)
  cat >"$input_data"
  "$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_input" <"$input_data"
  exit_code=$?
  rm -f "$input_data"
fi

[[ -n "${temp_key:-}" ]] && rm -f "$temp_key"
exit $exit_code
