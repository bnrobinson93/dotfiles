#!/usr/bin/env bash
set -euo pipefail

# Configure OpenSSH agent and add a key to GitHub
# Requires: openssh, gh (GitHub CLI)

ensure_agent() {
  # Respect 1Password if explicitly enabled
  if [[ -n "${USE_1PASSWORD_SSH:-}" ]]; then
    return 0
  fi

  # If SSH_AUTH_SOCK already works, done
  if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]]; then
    if ssh-add -l >/dev/null 2>&1; then
      return 0
    fi
  fi

  # macOS: try launchd-provided socket
  if [[ "$(uname)" == "Darwin" ]]; then
    lsock=$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null || true)
    if [[ -n "$lsock" && -S "$lsock" && "$lsock" != *"/.1password/agent.sock"* ]]; then
      export SSH_AUTH_SOCK="$lsock"
      if ssh-add -l >/dev/null 2>&1; then
        return 0
      fi
    fi
  fi

  # Start a fresh agent for this shell
  eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
}

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-t title] [-e email] [-f keyfile] [--force] [--no-add] [--no-allowed-signers]

Creates/loads an SSH key for GitHub and uploads the public key to your account.

Options:
  -t  Title/label for GitHub key (default: Hostname + date)
  -e  Email/comment to append to public key
  -f  Existing private key path to use (default: ~/.ssh/id_ed25519_GitHub)
  --force    Regenerate even if files already exist (overwrite)
  --no-add   Do not call ssh-add (only writes files)
  --no-allowed-signers  Do not update ~/.ssh/allowed_signers
USAGE
}

title="$(hostname)-$(date +%Y%m%d)"
email=""
keyfile="$HOME/.ssh/id_ed25519_GitHub"
do_add=1
force=0
update_allowed=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t) title="$2"; shift 2;;
    -e) email="$2"; shift 2;;
    -f) keyfile="$2"; shift 2;;
    --force) force=1; shift;;
    --no-add) do_add=0; shift;;
    --no-allowed-signers) update_allowed=0; shift;;
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

createKey() {
  input_keyfile="$1"
  keytype="${2:-authentication}"

  if [[ $force -eq 1 ]]; then
    rm -f "$input_keyfile" "${input_keyfile}.pub"
  fi

  if [[ ! -f "$input_keyfile" ]]; then
    echo "Generating new ed25519 key at $input_keyfile"
    read -rsp "Enter passphrase (empty for none): " pass; echo
    ssh-keygen -t ed25519 -a 100 -f "$input_keyfile" -N "$pass" -C "${email:-$USER@$(hostname)}"
  fi

  chmod 600 "$input_keyfile"; chmod 644 "${input_keyfile}.pub"

  if [[ $do_add -eq 1 ]]; then
    ensure_agent
    # Add to agent, try Keychain helper on macOS
    if [[ "$(uname)" == "Darwin" ]]; then
      ssh-add --apple-use-keychain "$input_keyfile" 2>/dev/null || ssh-add "$input_keyfile"
    else
      ssh-add "$input_keyfile"
    fi
  fi

  pubkey=$(cat "${input_keyfile}.pub")
  if [[ -n "$email" ]]; then
    pubkey="$pubkey $email"
  fi

  if command -v gh >/dev/null 2>&1; then
    echo "Uploading public key to GitHub via gh with title: $title"
    echo "$pubkey" | gh ssh-key add -t "$title" - --type "$keytype"
  else
    echo "gh not found. To upload manually, paste this to GitHub SSH keys:\n$pubkey"
  fi

  if [[ $update_allowed -eq 1 && -n "$email" ]]; then
    as_file="$HOME/.ssh/allowed_signers"
    touch "$as_file"; chmod 644 "$as_file"
    # remove old entries for this email then append
    if command -v gsed >/dev/null 2>&1; then sed_bin=gsed; else sed_bin=sed; fi
    $sed_bin -i.bak "/^$email /d" "$as_file"
    echo "$email $(cat "${input_keyfile}.pub")" >> "$as_file"
  fi

  echo "Done. Test with: ssh -T git@github.com"
}

createKey "$keyfile" authentication
createKey "${keyfile}Signing" signing

