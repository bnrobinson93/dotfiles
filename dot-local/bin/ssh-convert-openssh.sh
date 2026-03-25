#!/usr/bin/env bash
set -euo pipefail

# Convert PKCS#8 "BEGIN PRIVATE KEY" SSH keys to OpenSSH "OPENSSH PRIVATE KEY"
# Usage: ssh-convert-openssh.sh <private_key_path> [more_keys...]
#
# Strategy (in order):
#   1. openssl + python3 (stdlib only) — handles RFC 8410 OneAsymmetricKey format
#      that 1Password exports, which the `cryptography` library cannot parse.
#   2. python3 + cryptography — fallback for other PKCS#8 variants.

# Reconstruct an OpenSSH private key from raw ed25519 bytes via openssl + python3 (no extra deps)
_convert_via_openssl_python() {
  local src="$1" dst="$2"
  # openssl can read all PKCS#8 ed25519 variants including RFC 8410 with embedded pubkey
  local priv_hex pub_hex
  priv_hex=$(openssl asn1parse -in "$src" -strparse 12 2>/dev/null \
    | grep "OCTET STRING" | awk -F: '{print $NF}' | tr -d ' \n') || return 1
  pub_hex=$(openssl pkey -in "$src" -text -noout 2>/dev/null \
    | awk '/^pub:/{found=1; next} found && /^[0-9a-f: ]+$/{printf $0} !/^[0-9a-f: ]+$/ && found{exit}' \
    | tr -d ' :\n') || return 1
  [[ ${#priv_hex} -eq 64 && ${#pub_hex} -eq 64 ]] || return 1

  python3 - "$priv_hex" "$pub_hex" "$dst" <<'PY'
import sys, struct, base64, os, binascii

priv_bytes = binascii.unhexlify(sys.argv[1])
pub_bytes  = binascii.unhexlify(sys.argv[2])
dst        = sys.argv[3]

def enc(s):
    return struct.pack(">I", len(s)) + s

key_type = b"ssh-ed25519"
pub_blob = enc(key_type) + enc(pub_bytes)
check    = os.urandom(4)

private_section = (
    check + check +
    enc(key_type) + enc(pub_bytes) +
    enc(priv_bytes + pub_bytes) +  # ed25519 private = priv||pub (64 bytes)
    enc(b"")                        # comment
)
pad_len = (8 - len(private_section) % 8) % 8
private_section += bytes(range(1, pad_len + 1))

body = (
    enc(b"none") + enc(b"none") + enc(b"") +
    struct.pack(">I", 1) +
    enc(pub_blob) +
    enc(private_section)
)

result = b"openssh-key-v1\x00" + body
b64 = base64.b64encode(result).decode()
lines = [b64[i:i+70] for i in range(0, len(b64), 70)]
pem = "-----BEGIN OPENSSH PRIVATE KEY-----\n" + "\n".join(lines) + "\n-----END OPENSSH PRIVATE KEY-----\n"

with open(dst, "w") as f:
    f.write(pem)
os.chmod(dst, 0o600)
PY
}

# Fallback: python3 + cryptography library (works for standard PKCS#8, not RFC 8410)
_convert_via_cryptography() {
  local src="$1" dst="$2"
  python3 - "$src" "$dst" <<'PY' 2>/dev/null
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
}

convert_one() {
  local key="$1"
  if [[ ! -f "$key" ]]; then
    echo "[warn] not a file: $key" >&2
    return 1
  fi
  if ! grep -q "BEGIN PRIVATE KEY" "$key" 2>/dev/null; then
    echo "[info] $key already in OpenSSH format; skipping"
    return 0
  fi

  local tmp="${key}.openssh.tmp"
  local ok=0

  if command -v openssl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    _convert_via_openssl_python "$key" "$tmp" && ok=1
  fi

  if [[ $ok -eq 0 ]] && command -v python3 >/dev/null 2>&1 \
      && python3 -c 'import cryptography' >/dev/null 2>&1; then
    _convert_via_cryptography "$key" "$tmp" && ok=1
  fi

  if [[ $ok -eq 1 ]] && ssh-keygen -y -f "$tmp" >/dev/null 2>&1; then
    cp "$key" "${key}.pkcs8.bak"
    mv "$tmp" "$key"
    chmod 600 "$key"
    echo "[ok] converted to OpenSSH: $key (backup: ${key}.pkcs8.bak)"
    return 0
  fi

  rm -f "$tmp"
  echo "[error] conversion failed for $key — openssl and python3 required" >&2
  return 1
}

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <private_key_path> [more_keys...]" >&2
  exit 2
fi

rc=0
for k in "$@"; do
  convert_one "$k" || rc=1
done
exit $rc
