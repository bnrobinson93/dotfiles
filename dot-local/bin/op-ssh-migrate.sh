#!/usr/bin/env bash
set -euo pipefail

# Migrate SSH keys from 1Password into local ~/.ssh and load into the OS agent/keychain
# - macOS: stores passphrases in Keychain via ssh-add --apple-use-keychain
# - Linux: adds to the running ssh-agent; with GNOME/KDE keyrings, passphrases persist in the desktop keyring
#
# Requirements: 1Password CLI (op), OpenSSH (ssh-add/ssh-keygen). Optional: python3 + cryptography for PKCS#8->OpenSSH conversion.
#
# Usage examples:
#   op-ssh-migrate.sh "GitHub" "GitHub Signing"
#   op-ssh-migrate.sh --vault Private "Work GitHub" --dest id_ed25519_Work
#
# For each provided item NAME, this script expects fields in 1Password item:
#   - private_key (secret)   - retrieved with --reveal
#   - public_key             - ssh-ed25519 ...
#   - email (optional)       - appended to allowed_signers

VAULT="Private"
DEST_OVERRIDE=""
APPEND_ALLOWED_SIGNERS=1
ADD_TO_AGENT=1

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--vault NAME] [--dest BASENAME] [--no-agent] [--no-allowed-signers] ITEM [ITEM ...]

Options:
  --vault NAME           1Password vault (default: Private)
  --dest BASENAME        Override output base filename (applies when migrating a single item)
  --no-agent             Do not call ssh-add after writing files
  --no-allowed-signers   Do not append to ~/.ssh/allowed_signers

Notes:
  - Writes keys to ~/.ssh/<basename> and <basename>.pub with secure permissions.
  - Attempts PKCS#8 -> OpenSSH conversion if needed using python3+cryptography; falls back to agent if already usable.
  - On macOS, uses Keychain with ssh-add --apple-use-keychain; on Linux, adds to the current ssh-agent.
USAGE
}

ensure_dirs() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
}

have_cryptography() {
  python3 -c 'import cryptography' >/dev/null 2>&1
}

convert_pkcs8_to_openssh() {
  # Converts PKCS#8 ("BEGIN PRIVATE KEY") to OpenSSH "OPENSSH PRIVATE KEY" using python cryptography.
  # $1 = private key path
  local src="$1"
  if ! grep -q "BEGIN PRIVATE KEY" "$src" 2>/dev/null; then
    return 0
  fi
  if ! have_cryptography; then
    echo "[warn] python3-cryptography not available; skipping conversion for $src" >&2
    return 1
  fi
  local tmp="${src}.openssh.tmp"
  python3 <<'PY' 2>/dev/null
import sys
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
src = sys.argv[1]
dst = sys.argv[2]
with open(src, 'rb') as f:
    key = serialization.load_pem_private_key(f.read(), password=None, backend=default_backend())
data = key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.OpenSSH,
    encryption_algorithm=serialization.NoEncryption(),
)
with open(dst, 'wb') as f:
    f.write(data)
PY
  "$src" "$tmp"
  if [[ -s "$tmp" ]]; then
    cp "$src" "${src}.pkcs8.bak"
    mv "$tmp" "$src"
    chmod 600 "$src"
    echo "[info] Converted $src to OpenSSH format"
    return 0
  fi
  echo "[warn] Conversion failed for $src" >&2
  return 1
}

derive_basename() {
  # $1 public key content
  # $2 item name (default fallback)
  local pub="$1"; local name="$2"
  local type
  type=$(echo "$pub" | awk '{print $1}')
  local clean_name
  clean_name=$(echo "$name" | tr ' /' '__')
  case "$type" in
    ssh-ed25519) echo "id_ed25519_${clean_name}";;
    ssh-rsa) echo "id_rsa_${clean_name}";;
    ssh-ecdsa) echo "id_ecdsa_${clean_name}";;
    *) echo "id_unknown_${clean_name}";;
  esac
}

add_to_agent() {
  local key="$1"
  if [[ "$(uname)" == "Darwin" ]]; then
    ssh-add --apple-use-keychain "$key" 2>/dev/null || ssh-add "$key"
  else
    # Start a user agent if none present (non-destructive)
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
      eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    fi
    ssh-add "$key"
  fi
}

append_allowed_signers() {
  local email="$1"; shift
  local pub="$1"; shift
  [[ -z "$email" ]] && return 0
  local file="$HOME/.ssh/allowed_signers"
  touch "$file"; chmod 644 "$file"
  if ! grep -Fq "$pub" "$file"; then
    echo "$email $pub" >> "$file"
    echo "[info] added to allowed_signers: $email"
  fi
}

fetch_field() {
  # $1 = item name, $2 = field label
  op item get --vault "$VAULT" "$1" --fields "$2" 2>/dev/null || true
}

fetch_field_secret() {
  # $1 = item name, $2 = field label (reveal secret)
  op item get --vault "$VAULT" "$1" --fields "$2" --reveal 2>/dev/null || true
}

if ! command -v op >/dev/null 2>&1; then
  echo "[error] 1Password CLI (op) not found in PATH" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  usage; exit 2
fi

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault) VAULT="$2"; shift 2;;
    --dest) DEST_OVERRIDE="$2"; shift 2;;
    --no-agent) ADD_TO_AGENT=0; shift;;
    --no-allowed-signers) APPEND_ALLOWED_SIGNERS=0; shift;;
    -h|--help) usage; exit 0;;
    *) ARGS+=("$1"); shift;;
  esac
done

ensure_dirs

for item in "${ARGS[@]}"; do
  echo "[info] Migrating 1Password item: $item (vault: $VAULT)"
  pub=$(fetch_field "$item" public_key | tr -d '\r')
  priv=$(fetch_field_secret "$item" private_key | tr -d '\r')
  email=$(fetch_field "$item" email | tr -d '\r' || true)

  if [[ -z "$pub" || -z "$priv" ]]; then
    echo "[error] missing public_key or private_key in 1Password item: $item" >&2
    continue
  fi

  base="$DEST_OVERRIDE"
  if [[ -z "$base" ]]; then
    base=$(derive_basename "$pub" "$item")
  fi

  keyfile="$HOME/.ssh/$base"
  pubfile="$keyfile.pub"

  if [[ -e "$keyfile" || -e "$pubfile" ]]; then
    echo "[warn] target files exist, backing up to *.bak"
    [[ -e "$keyfile" ]] && cp "$keyfile" "${keyfile}.bak.$(date +%s)"
    [[ -e "$pubfile" ]] && cp "$pubfile" "${pubfile}.bak.$(date +%s)"
  fi

  printf '%s\n' "$priv" > "$keyfile"
  printf '%s\n' "$pub" > "$pubfile"
  chmod 600 "$keyfile"; chmod 644 "$pubfile"

  # Try conversion if needed
  convert_pkcs8_to_openssh "$keyfile" || true

  if [[ $ADD_TO_AGENT -eq 1 ]]; then
    add_to_agent "$keyfile"
  fi

  if [[ $APPEND_ALLOWED_SIGNERS -eq 1 ]]; then
    append_allowed_signers "$email" "$pub"
  fi

  echo "[ok] migrated to $keyfile"
done

echo "[done] Migration complete. Test: ssh -T git@github.com"

