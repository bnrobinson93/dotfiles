#!/bin/bash

# Enhanced SSH key saver with better error handling and logging

set -euo pipefail

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Function to create SSH directory structure
setup_ssh_directory() {
  local ssh_dir="$HOME/.ssh"

  if [[ ! -d "$ssh_dir" ]]; then
    log "Creating SSH directory: $ssh_dir"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
  fi

  # Create authorized_keys if it doesn't exist
  if [[ ! -f "$ssh_dir/authorized_keys" ]]; then
    touch "$ssh_dir/authorized_keys"
    chmod 600 "$ssh_dir/authorized_keys"
  fi

  # Create allowed_signers if it doesn't exist (for SSH signing)
  if [[ ! -f "$ssh_dir/allowed_signers" ]]; then
    touch "$ssh_dir/allowed_signers"
    chmod 644 "$ssh_dir/allowed_signers"
  fi
}

# Function to derive key filename from public key
get_key_filename() {
  local public_key="$1"
  local title="$2"

  # Extract key type (ssh-ed25519, ssh-rsa, etc.)
  local key_type=$(echo "$public_key" | awk '{print $1}')

  # Create a filename based on key type and title
  case "$key_type" in
  ssh-ed25519)
    echo "id_ed25519_${title// /_}"
    ;;
  ssh-rsa)
    echo "id_rsa_${title// /_}"
    ;;
  ssh-ecdsa)
    echo "id_ecdsa_${title// /_}"
    ;;
  *)
    echo "id_unknown_${title// /_}"
    ;;
  esac
}

# Function to add key to authorized_keys
add_to_authorized_keys() {
  local email="$1"
  local public_key="$2"
  local authorized_keys_file="$HOME/.ssh/authorized_keys"

  if [[ -n "$email" ]]; then
    local key_entry="$public_key $email"
    if ! grep -Fq "$public_key" "$authorized_keys_file"; then
      log "Adding key for $email to authorized_keys"
      echo "$key_entry" >>"$authorized_keys_file"
    else
      log "Key for $email already exists in authorized_keys"
    fi
  fi
}

# Function to add key to allowed_signers
add_to_allowed_signers() {
  local email="$1"
  local public_key="$2"
  local allowed_signers_file="$HOME/.ssh/allowed_signers"

  if [[ -n "$email" ]]; then
    local signer_entry="$email $public_key"
    if ! grep -Fq "$public_key" "$allowed_signers_file"; then
      log "Adding key for $email to allowed_signers"
      echo "$signer_entry" >>"$allowed_signers_file"
    else
      log "Key for $email already exists in allowed_signers"
    fi
  fi
}

# Function to save a single SSH key
save_ssh_key() {
  local item_id="$1"

  log "Processing SSH key with ID: $item_id"

  # Get item details from 1Password
  local item_details
  if ! item_details=$(op item get "$item_id" --reveal --format=json >>log.txt); then
    log "Error: Failed to retrieve item details for $item_id"
    return 1
  fi

  # Extract fields
  local title=$(echo "$item_details" | jq -r '.title // "unknown"')
  local email=$(echo "$item_details" | jq -r '.fields[]? | select(.label == "email") | .value // empty')
  local public_key=$(echo "$item_details" | jq -r '.fields[]? | select(.id == "public_key") | .value // empty')
  local private_key=$(echo "$item_details" | jq -r '.fields[]? | select(.id == "private_key") | .value // empty')

  # Validate required fields
  if [[ -z "$public_key" || -z "$private_key" ]]; then
    log "Warning: Missing public or private key for item '$title', skipping"
    return 1
  fi

  log "Processing key: $title"

  # Generate filename
  local base_filename
  base_filename=$(get_key_filename "$public_key" "$title")
  local private_key_file="$HOME/.ssh/$base_filename"
  local public_key_file="${private_key_file}.pub"

  # Check if files already exist
  if [[ -f "$private_key_file" && -f "$public_key_file" ]]; then
    log "SSH key files for '$title' already exist, skipping"
    return 0
  fi

  # Write key files
  log "Saving private key to: $private_key_file"
  echo "$private_key" >"$private_key_file"
  chmod 600 "$private_key_file"

  log "Saving public key to: $public_key_file"
  echo "$public_key" >"$public_key_file"
  chmod 644 "$public_key_file"

  # Add to authorized_keys and allowed_signers
  if [[ -n "$email" ]]; then
    add_to_authorized_keys "$email" "$public_key"
    add_to_allowed_signers "$email" "$public_key"
  else
    log "Warning: No email found for key '$title'"
  fi

  log "Successfully saved SSH key: $title"
}

# Main function
main() {
  # Check if 1Password CLI is installed
  if ! command -v op >/dev/null 2>&1; then
    log "Error: 1Password CLI not found"
    log "Install it here: https://developer.1password.com/docs/cli/get-started/"
    exit 1
  fi

  # Check if user is signed in to 1Password
  if ! op account list >/dev/null 2>&1; then
    log "Error: Not signed in to 1Password CLI"
    log "Run 'op signin' first"
    exit 1
  fi

  # Setup SSH directory structure
  setup_ssh_directory

  # Check if we have any SSH keys to process
  local ssh_items
  if ! ssh_items=$(op item list --vault Private --categories "SSH Key" --format=json >>log.txt); then
    log "Error: Failed to list SSH keys from 1Password"
    exit 1
  fi

  local item_count
  item_count=$(echo "$ssh_items" | jq length)

  if [[ "$item_count" -eq 0 ]]; then
    log "No SSH keys found in 1Password Private vault"
    exit 0
  fi

  log "Found $item_count SSH key(s) in 1Password"

  # Process each SSH key
  local success_count=0
  local error_count=0

  echo "$ssh_items" | jq -c '.[]' | while read -r item; do
    local item_id
    item_id=$(echo "$item" | jq -r '.id')

    if save_ssh_key "$item_id"; then
      ((success_count++))
    else
      ((error_count++))
    fi
  done

  log "SSH key synchronization complete"
  log "Note: Due to subshell limitations, detailed counts aren't available"
  log "Check the logs above for individual key processing results"
}

# Run main function
main "$@"
