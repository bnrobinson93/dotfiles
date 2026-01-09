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

# Prepare args and support literal public key strings for -f
args=("$@")
for ((i=0; i<${#args[@]}; i++)); do
  if [[ "${args[i]}" == "-f" && $((i+1)) -lt ${#args[@]} ]]; then
    val="${args[i+1]}"
    # Expand ~ and environment variables
    val_expanded="${val/#\~/$HOME}"
    # If value looks like a key string (starts with ssh- and has a space), write to temp file
    if [[ "$val" =~ ^ssh-.*\ .* ]]; then
      tmp_pub="${TMPDIR:-/tmp}/ssh-sign-pub-$$.pub"
      printf '%s\n' "$val" > "$tmp_pub"
      args[i+1]="$tmp_pub"
      log "Converted inline pubkey to temp file: $tmp_pub"
    else
      args[i+1]="$val_expanded"
    fi
    break
  fi
done

# Choose signer: default to system ssh-keygen (agent-backed), 1Password only if requested
if [[ -n "${USE_1PASSWORD_SSH:-}" ]]; then
  log "Using 1Password SSH agent (op-ssh-sign)"
  exec "$OPSIGN" "${args[@]}"
else
  log "Using system ssh-keygen (ssh-agent)"
  exec ssh-keygen "${args[@]}"
fi
