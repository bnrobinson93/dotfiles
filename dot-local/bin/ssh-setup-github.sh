#!/usr/bin/env bash
set -euo pipefail

# Configure OpenSSH agent and add a key to GitHub
# Requires: openssh, gh (GitHub CLI)

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-t title] [-e email] [-f keyfile] [--no-add]

Creates/loads an SSH key for GitHub and uploads the public key to your account.

Options:
  -t  Title/label for GitHub key (default: Hostname + date)
  -e  Email/comment to append to public key
  -f  Existing private key path to use (default: ~/.ssh/id_ed25519_GitHub)
  --no-add  Do not call ssh-add (only writes files)
USAGE
}

title="$(hostname)-$(date +%Y%m%d)"
email=""
keyfile="$HOME/.ssh/id_ed25519_GitHub"
do_add=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t) title="$2"; shift 2;;
    -e) email="$2"; shift 2;;
    -f) keyfile="$2"; shift 2;;
    --no-add) do_add=0; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

ssh_dir="$HOME/.ssh"
mkdir -p "$ssh_dir"; chmod 700 "$ssh_dir"

# Respect 1Password if explicitly enabled, else prefer system agent
if [[ -z "${USE_1PASSWORD_SSH:-}" ]]; then
  # macOS: auto-start ssh-agent via Keychain
  if [[ "$(uname)" == "Darwin" ]]; then
    # Launchctl-managed agent is default on macOS; use ~/.ssh/config to persist passphrases
    if ! grep -q "AddKeysToAgent" "$ssh_dir/config" 2>/dev/null; then
      {
        echo "Host *"
        echo "  AddKeysToAgent yes"
        echo "  UseKeychain yes"
        echo "  IdentityFile ~/.ssh/id_ed25519_GitHub"
        echo "  IdentityFile ~/.ssh/id_ed25519_GitHubSigning"
      } >> "$ssh_dir/config"
    fi
  fi
fi

if [[ ! -f "$keyfile" ]]; then
  echo "Generating new ed25519 key at $keyfile"
  read -rsp "Enter passphrase (empty for none): " pass; echo
  ssh-keygen -t ed25519 -a 100 -f "$keyfile" -N "$pass" -C "${email:-$USER@$(hostname)}"
fi

chmod 600 "$keyfile"; chmod 644 "${keyfile}.pub"

if [[ $do_add -eq 1 ]]; then
  # Add to agent, try Keychain helper on macOS
  if [[ "$(uname)" == "Darwin" ]]; then
    ssh-add --apple-use-keychain "$keyfile" 2>/dev/null || ssh-add "$keyfile"
  else
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    ssh-add "$keyfile"
  fi
fi

pubkey=$(cat "${keyfile}.pub")
if [[ -n "$email" ]]; then
  pubkey="$pubkey $email"
fi

if command -v gh >/dev/null 2>&1; then
  echo "Uploading public key to GitHub via gh with title: $title"
  echo "$pubkey" | gh ssh-key add -t "$title" -
else
  echo "gh not found. To upload manually, paste this to GitHub SSH keys:\n$pubkey"
fi

echo "Done. Test with: ssh -T git@github.com"
