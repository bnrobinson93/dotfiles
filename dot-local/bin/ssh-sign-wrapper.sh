#!/usr/bin/env bash

set -euo pipefail

# Configuration
SSH_DIR="$HOME/.ssh"
SAVE_KEYS_SCRIPT="$HOME/.local/bin/save-ssh-keys.sh"
LOG_FILE="/tmp/ssh-sign-wrapper.log"
AGENT_ENV_FILE="$HOME/.ssh/agent.env"

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

# Prepare args and support literal public key strings for -f.
# Additionally, if possible, resolve the matching private key file and ensure it's loaded into an agent.
args=("$@")
resolved_priv=""
f_idx=-1
op=""
# Detect ssh-keygen operation after -Y if present (sign/verify/find-principals/etc.)
for ((i=0; i<${#args[@]}; i++)); do
  if [[ "${args[i]}" == "-Y" && $((i+1)) -lt ${#args[@]} ]]; then
    op="${args[i+1]}"
    break
  fi
done
for ((i=0; i<${#args[@]}; i++)); do
  if [[ "${args[i]}" == "-f" && $((i+1)) -lt ${#args[@]} ]]; then
    f_idx=$i
    val="${args[i+1]}"
    # Expand ~ and environment variables
    val_expanded="${val/#\~/$HOME}"
    pub_source="$val_expanded"
    # If value looks like a key string (starts with ssh- and has a space), write to temp file
    if [[ "$val" =~ ^ssh-.*\ .* ]]; then
      tmp_pub="${TMPDIR:-/tmp}/ssh-sign-pub-$$.pub"
      printf '%s\n' "$val" > "$tmp_pub"
      pub_source="$tmp_pub"
      log "Converted inline pubkey to temp file: $tmp_pub"
    fi

    # Only resolve/alter -f when performing a sign operation
    if [[ "$op" == "sign" ]]; then
      # Try to resolve a matching private key under ~/.ssh by comparing base64 blob of .pub files
      if [[ -f "$pub_source" ]]; then
        key_blob=$(awk '{print $2}' "$pub_source" 2>/dev/null || true)
        if [[ -n "$key_blob" ]]; then
          match_pub=$(awk -v kb="$key_blob" '$2==kb {print FILENAME}' "$SSH_DIR"/*.pub 2>/dev/null | head -n1 || true)
          if [[ -n "$match_pub" ]]; then
            priv_candidate="${match_pub%.pub}"
            if [[ -f "$priv_candidate" ]]; then
              resolved_priv="$priv_candidate"
              log "Resolved signing key to private key file: $priv_candidate"
            fi
          fi
        fi
      else
        # If -f already points to a private key file, keep as is
        args[i+1]="$pub_source"
      fi

      # Fallback: default to dedicated signing key if present
      if [[ -z "$resolved_priv" && -f "$HOME/.ssh/id_ed25519_GitHubSigning" ]]; then
        resolved_priv="$HOME/.ssh/id_ed25519_GitHubSigning"
        log "Defaulted to signing private key: $HOME/.ssh/id_ed25519_GitHubSigning"
      fi
    fi
    break
  fi
done

# Helper: add one key into current agent and confirm present
ensure_loaded() {
  local keyfile="$1"
  # Add expected keys (macOS uses Keychain)
  local add_cmd=(ssh-add)
  if [[ "${OSTYPE}" == darwin* ]]; then
    add_cmd=(ssh-add --apple-use-keychain)
  fi
  # If key is PKCS#8, try converting via helper or inline Python
  if grep -q "BEGIN PRIVATE KEY" "$keyfile" 2>/dev/null; then
    if [[ -x "$HOME/.local/bin/ssh-convert-openssh.sh" ]]; then
      "$HOME/.local/bin/ssh-convert-openssh.sh" "$keyfile" >/dev/null 2>>"$LOG_FILE" || true
    elif command -v python3 >/dev/null 2>&1 && python3 -c 'import cryptography' >/dev/null 2>&1; then
      python3 - "$keyfile" <<'PY' 2>>"$LOG_FILE"
import sys
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
src = sys.argv[1]
with open(src, 'rb') as f:
    key = serialization.load_pem_private_key(f.read(), password=None, backend=default_backend())
data = key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.OpenSSH,
    encryption_algorithm=serialization.NoEncryption(),
)
with open(src, 'wb') as f:
    f.write(data)
PY
      chmod 600 "$keyfile" 2>/dev/null || true
      log "Inline conversion to OpenSSH format attempted for $keyfile"
    else
      log "No converter available for PKCS#8 (missing ~/.local/bin/ssh-convert-openssh.sh and python cryptography)"
    fi
  fi
  local want_pub
  want_pub=$(ssh-keygen -y -f "$keyfile" 2>/dev/null || true)
  "${add_cmd[@]}" "$keyfile" >/dev/null 2>&1 || true
  if [[ -n "$want_pub" ]] && ssh-add -L 2>/dev/null | grep -Fq "$want_pub"; then
    log "Key loaded in agent: $keyfile"
    return 0
  fi
  ssh-add -L >/dev/null 2>&1 || true
  log "Failed to confirm key loaded: $keyfile"
  return 1
}

# Helper: ensure an SSH agent is available (does not guarantee keys are loaded)
ensure_agent_and_keys() {
  # If using 1Password explicitly, do nothing here
  [[ -n "${USE_1PASSWORD_SSH:-}" ]] && return 0

  # If a 1Password socket is present but not opted in, ignore it
  if [[ "${SSH_AUTH_SOCK:-}" == *"/.1password/agent.sock" ]]; then
    unset SSH_AUTH_SOCK
  fi

  # If SSH_AUTH_SOCK already works, done
  if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]] && ssh-add -l >/dev/null 2>&1; then
    return 0
  fi

  # macOS: try launchd-provided socket
  if [[ "${OSTYPE}" == darwin* ]]; then
    lsock=$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null || true)
    # Ignore 1Password socket from launchd unless opted in
    if [[ -n "$lsock" && -S "$lsock" && "$lsock" != *"/.1password/agent.sock"* ]]; then
      export SSH_AUTH_SOCK="$lsock"
      if ssh-add -l >/dev/null 2>&1; then
        return 0
      fi
    fi
  fi

  # Try env file if present
  if [[ -f "$AGENT_ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    . "$AGENT_ENV_FILE" 2>/dev/null || true
    if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]] && ssh-add -l >/dev/null 2>&1; then
      return 0
    fi
  fi

  # Start a new agent and persist env for future calls
  log "Starting new ssh-agent"
  ssh-agent -s >"$AGENT_ENV_FILE"
  awk 'BEGIN{print "# env from ssh-agent"} !/^echo / {print}' "$AGENT_ENV_FILE" > "${AGENT_ENV_FILE}.clean"
  mv "${AGENT_ENV_FILE}.clean" "$AGENT_ENV_FILE"
  # shellcheck disable=SC1090
  . "$AGENT_ENV_FILE"
}

# Choose signer: default to system ssh-keygen (agent-backed), 1Password only if requested
if [[ -n "${USE_1PASSWORD_SSH:-}" ]]; then
  log "Using 1Password SSH agent (op-ssh-sign)"
  exec "$OPSIGN" "${args[@]}"
else
  # Ensure an agent is available. For sign, ensure the resolved private key is loaded
  ensure_agent_and_keys
  if [[ "$op" == "sign" && -n "$resolved_priv" ]]; then
    ensure_loaded "$resolved_priv" >/dev/null 2>&1 || true
    # Replace -f value with a pubkey derived from the resolved private key
    if [[ $f_idx -ge 0 ]]; then
      tmp_pub_out="${TMPDIR:-/tmp}/ssh-sign-pub-derived-$$.pub"
      if ssh-keygen -y -f "$resolved_priv" > "$tmp_pub_out" 2>>"$LOG_FILE"; then
        args[$((f_idx+1))]="$tmp_pub_out"
        log "Substituted -f with derived pub: $tmp_pub_out"
      else
        log "Failed to derive pub from $resolved_priv"
      fi
    fi
  fi
  log "Using system ssh-keygen (ssh-agent)"
  exec ssh-keygen "${args[@]}"
fi
