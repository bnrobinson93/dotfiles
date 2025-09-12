#!/usr/bin/env bash
# ssh-sign-wrapper.sh - Smart wrapper that prefers local keys, falls back to 1Password
# Compatible with both git and jj signing requirements

set -euo pipefail

# Configuration
SSH_DIR="$HOME/.ssh"
SAVE_KEYS_SCRIPT="$HOME/.local/bin/save-ssh-keys.sh" # Adjust path as needed
LOG_FILE="/tmp/ssh-sign-wrapper.log"

# Enable debug logging if needed
DEBUG=${DEBUG:-0}
[[ "$DEBUG" -eq 1 ]] && exec 2>>"$LOG_FILE"

log() {
  [[ "$DEBUG" -eq 1 ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Detect OS and set 1Password binary path
if [[ "$OSTYPE" == "darwin"* ]]; then
  OPSIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OPSIGN="/opt/1Password/op-ssh-sign"
else
  echo "Unsupported OS: $OSTYPE" >&2
  exit 1
fi

# Parse arguments - handle both git and jj calling conventions
mode=""
namespace="git" # Default namespace
key_file=""
temp_key=""
input_file="" # For the data to be signed

# JJ calls this differently than git, so we need to handle both
# JJ format: ssh-sign-wrapper.sh -Y sign -n git -f /path/to/key < data
# Git format: similar but might pass filename as last arg

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
    key_arg="$2"
    # Check if it's key content or a file path
    if [[ "$key_arg" == ssh-* ]]; then
      # It's key content, create a temporary file
      temp_key=$(mktemp)
      echo "$key_arg 31802085+bnrobinson93@users.noreply.github.com" >"$temp_key"
      key_file="$temp_key"
    else
      key_file="$key_arg"
    fi
    shift 2
    ;;
  *)
    # Remaining argument might be input file
    if [[ -f "$1" ]]; then
      input_file="$1"
    fi
    shift
    ;;
  esac
done

log "Mode: $mode, Namespace: $namespace, Key: $key_file, Input: $input_file"

# Function to find matching local private key
find_local_private_key() {
  local pub_key_file="$1"

  # Read the public key content
  local pub_key_content
  if [[ -f "$pub_key_file" ]]; then
    pub_key_content=$(cat "$pub_key_file")
  else
    log "Public key file not found: $pub_key_file"
    return 1
  fi

  # Extract just the key part (remove email if present)
  local key_only=$(echo "$pub_key_content" | awk '{print $1" "$2}')

  log "Looking for private key matching: ${key_only:0:50}..."

  # Search for matching private key
  for private_key in "$SSH_DIR"/id_*; do
    # Skip public keys and non-existent files
    [[ ! -f "$private_key" ]] && continue
    [[ "$private_key" == *.pub ]] && continue

    # Check if corresponding public key exists and matches
    local pub_key="${private_key}.pub"
    if [[ -f "$pub_key" ]]; then
      local stored_key=$(awk '{print $1" "$2}' "$pub_key")
      if [[ "$stored_key" == "$key_only" ]]; then
        log "Found matching local key: $private_key"
        echo "$private_key"
        return 0
      fi
    fi
  done

  log "No matching local private key found"
  return 1
}

# Function to attempt signing with local SSH key
sign_with_local_key() {
  local private_key="$1"

  log "Attempting to sign with local key: $private_key"

  # For signing operations, jj expects the signature on stdout
  if [[ "$mode" == "sign" ]]; then
    # Read from stdin and sign
    ssh-keygen -Y sign -f "$private_key" -n "$namespace"
    return $?
  elif [[ "$mode" == "verify" ]]; then
    # For verification, we need the public key
    ssh-keygen -Y verify -f "${private_key}.pub" -n "$namespace" -s "-"
    return $?
  fi

  return 1
}

# Function to sync keys from 1Password
sync_keys_from_1password() {
  if [[ -x "$SAVE_KEYS_SCRIPT" ]]; then
    log "Running key sync script"
    "$SAVE_KEYS_SCRIPT" >/dev/null 2>&1 || {
      log "Key sync script failed"
      return 1
    }
    return 0
  else
    log "Key sync script not found or not executable: $SAVE_KEYS_SCRIPT"
    return 1
  fi
}

# Main logic
main() {
  # Ensure we have required arguments
  if [[ -z "$mode" || -z "$key_file" ]]; then
    log "Error: Missing required arguments (mode=$mode, key_file=$key_file)"
    echo "Error: Missing required arguments" >&2
    exit 1
  fi

  # Try to find and use local key first
  if local_private_key=$(find_local_private_key "$key_file"); then
    if sign_with_local_key "$local_private_key"; then
      log "Successfully signed with local key"
      [[ -n "$temp_key" ]] && rm -f "$temp_key"
      exit 0
    else
      log "Failed to sign with local key, falling back to 1Password"
    fi
  else
    log "No matching local key found, attempting to sync from 1Password"

    # Try to sync keys from 1Password
    if sync_keys_from_1password; then
      # Try again with potentially new keys
      if local_private_key=$(find_local_private_key "$key_file"); then
        if sign_with_local_key "$local_private_key"; then
          log "Successfully signed with newly synced key"
          [[ -n "$temp_key" ]] && rm -f "$temp_key"
          exit 0
        fi
      fi
    fi
  fi

  # Fall back to 1Password
  log "Falling back to 1Password signing"

  # For 1Password, we need to pass stdin through
  "$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_file"
  exit_code=$?

  # Clean up temporary file if we created one
  [[ -n "$temp_key" ]] && rm -f "$temp_key"

  exit $exit_code
}

# Run main function
main
