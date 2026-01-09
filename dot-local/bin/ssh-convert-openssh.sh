#!/usr/bin/env bash
set -euo pipefail

# Convert PKCS#8 "BEGIN PRIVATE KEY" SSH keys to OpenSSH "OPENSSH PRIVATE KEY"
# Usage: ssh-convert-openssh.sh <private_key_path> [more_keys...]

need_py() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "[error] python3 not found. Install Python 3 (brew install python or apt/pacman/yum)." >&2
    return 1
  fi
  if ! python3 -c 'import cryptography' >/dev/null 2>&1; then
    echo "[error] Python cryptography module missing." >&2
    echo "Install via one of:" >&2
    echo "  brew install python-cryptography   # macOS" >&2
    echo "  sudo apt-get install python3-cryptography   # Debian/Ubuntu" >&2
    echo "  sudo pacman -S python-cryptography          # Arch" >&2
    echo "  sudo dnf/yum install python3-cryptography   # Fedora/RHEL" >&2
    return 1
  fi
}

convert_one() {
  local key="$1"
  if [[ ! -f "$key" ]]; then
    echo "[warn] not a file: $key" >&2
    return 1
  fi
  if ! grep -q "BEGIN PRIVATE KEY" "$key" 2>/dev/null; then
    echo "[info] $key already looks like OpenSSH format; skipping"
    return 0
  fi
  local tmp="${key}.openssh.tmp"
  python3 - "$key" "$tmp" <<'PY'
import sys
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
src, dst = sys.argv[1], sys.argv[2]
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
  if [[ -s "$tmp" ]]; then
    cp "$key" "${key}.pkcs8.bak"
    mv "$tmp" "$key"
    chmod 600 "$key"
    echo "[ok] converted to OpenSSH: $key (backup: ${key}.pkcs8.bak)"
    return 0
  else
    echo "[error] conversion failed for $key" >&2
    return 1
  fi
}

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <private_key_path> [more_keys...]" >&2
  exit 2
fi

if ! need_py; then
  # Try to install cryptography automatically
  if [[ "$(uname)" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      echo "[info] installing python-cryptography via Homebrew..." >&2
      brew install python-cryptography || true
    fi
  elif [[ -f /etc/debian_version ]]; then
    sudo apt-get update && sudo apt-get install -y python3-cryptography || true
  elif [[ -f /etc/arch-release ]]; then
    sudo pacman -S --noconfirm python-cryptography || true
  elif [[ -f /etc/fedora-release ]] || [[ -f /etc/redhat-release ]]; then
    sudo dnf install -y python3-cryptography || sudo yum install -y python3-cryptography || true
  fi
  need_py || exit 1
fi

rc=0
for k in "$@"; do
  convert_one "$k" || rc=1
done
exit $rc
