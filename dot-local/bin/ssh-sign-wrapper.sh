#!/bin/bash
# Enhanced ssh-sign-wrapper - Handles local keys with 1Password fallback

# Function to save SSH keys from 1Password
save_ssh_keys() {
  local save_script="$HOME/.local/bin/save-ssh-keys.sh"

  # Check if save script exists and is executable
  if [[ -x "$save_script" ]]; then
    echo "Attempting to save SSH keys from 1Password..." >>log.txt
    "$save_script"
    return $?
  else
    echo "Warning: save-ssh-keys.sh not found or not executable at $save_script" >>log.txt
    return 1
  fi
}

# Function to find local SSH key file by reading key content from file
find_local_key_from_file() {
  local key_file="$1"

  echo "DEBUG: Checking temp file: $key_file" >>log.txt

  # Read the public key content from the file
  if [[ -f "$key_file" ]]; then
    local key_content
    key_content=$(cat "$key_file" 2>/dev/null | head -n1 | tr -d '\n\r%' | sed 's/[[:space:]]*$//')

    echo "DEBUG: Temp file contains (cleaned): '$key_content'" >>log.txt

    if [[ "$key_content" == ssh-* ]]; then
      local key_type=$(echo "$key_content" | awk '{print $1}')
      local key_data=$(echo "$key_content" | awk '{print $2}')

      echo "DEBUG: Looking for key_type='$key_type' key_data='$key_data'" >>log.txt

      # Look for matching key in ~/.ssh/ - check all files, not just id_*
      for local_key_file in "$HOME"/.ssh/*; do
        if [[ -f "$local_key_file.pub" ]]; then
          local file_key_content=$(cat "$local_key_file.pub" 2>/dev/null | head -n1 | tr -d '\n\r%' | sed 's/[[:space:]]*$//')
          local file_key_type=$(echo "$file_key_content" | awk '{print $1}')
          local file_key_data=$(echo "$file_key_content" | awk '{print $2}')

          echo "DEBUG: Checking $local_key_file.pub: type='$file_key_type' data='${file_key_data:0:20}...'" >>log.txt

          if [[ "$key_type" == "$file_key_type" && "$key_data" == "$file_key_data" ]]; then
            echo "DEBUG: MATCH FOUND: $local_key_file" >>log.txt
            echo "$local_key_file"
            return 0
          fi
        elif [[ -f "$local_key_file" && "$local_key_file" == *.pub ]]; then
          # This is a .pub file itself
          local file_key_content=$(cat "$local_key_file" 2>/dev/null | head -n1 | tr -d '\n\r%' | sed 's/[[:space:]]*$//')
          local file_key_type=$(echo "$file_key_content" | awk '{print $1}')
          local file_key_data=$(echo "$file_key_content" | awk '{print $2}')
          local base_key_file="${local_key_file%.pub}"

          echo "DEBUG: Checking $local_key_file: type='$file_key_type' data='${file_key_data:0:20}...'" >>log.txt

          if [[ "$key_type" == "$file_key_type" && "$key_data" == "$file_key_data" && -f "$base_key_file" ]]; then
            echo "DEBUG: MATCH FOUND: $base_key_file" >>log.txt
            echo "$base_key_file"
            return 0
          fi
        fi
      done
    fi
  fi

  echo "DEBUG: No local key match found" >>log.txt
  return 1
}

# Function to find local SSH key file by key content string
find_local_key_from_content() {
  local key_content="$1"

  # Extract the key type and key data
  if [[ "$key_content" == ssh-* ]]; then
    local key_type=$(echo "$key_content" | awk '{print $1}')
    local key_data=$(echo "$key_content" | awk '{print $2}')

    # Look for matching key in ~/.ssh/
    for key_file in "$HOME"/.ssh/id_*; do
      if [[ -f "$key_file.pub" ]]; then
        local file_key_type=$(awk '{print $1}' "$key_file.pub" 2>/dev/null)
        local file_key_data=$(awk '{print $2}' "$key_file.pub" 2>/dev/null)

        if [[ "$key_type" == "$file_key_type" && "$key_data" == "$file_key_data" ]]; then
          echo "$key_file"
          return 0
        fi
      fi
    done
  fi

  return 1
}

# Function to use local SSH signing
sign_with_local_key() {
  local mode="$1"
  local namespace="$2"
  local key_file="$3"

  # Use ssh-keygen for signing
  case "$mode" in
  sign)
    ssh-keygen -Y sign -n "$namespace" -f "$key_file" </dev/stdin
    ;;
  verify)
    ssh-keygen -Y verify -n "$namespace" -f "$key_file" </dev/stdin
    ;;
  *)
    echo "Error: Unsupported mode '$mode'" >>log.txt
    return 1
    ;;
  esac
}

# Function to use 1Password for signing
sign_with_1password() {
  local mode="$1"
  local namespace="$2"
  local key_file="$3"

  # Determine 1Password binary path
  local opsign=""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    opsign="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    opsign="/opt/1Password/op-ssh-sign"
  else
    echo "Error: Unsupported OS: $OSTYPE" >>log.txt
    return 1
  fi

  # Check if 1Password signing binary exists
  if [[ ! -x "$opsign" ]]; then
    echo "Error: 1Password SSH signing binary not found at $opsign" >>log.txt
    return 1
  fi

  "$opsign" -Y "$mode" -n "$namespace" -f "$key_file"
}

# Main script logic
main() {
  # Parse arguments
  local mode=""
  local namespace=""
  local key_arg=""
  local temp_key=""
  local cleanup_temp=false

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
      shift 2
      ;;
    *)
      # Skip unknown arguments
      shift
      ;;
    esac
  done

  # Validate required arguments
  if [[ -z "$mode" || -z "$namespace" || -z "$key_arg" ]]; then
    echo "Error: Missing required arguments" >>log.txt
    echo "Usage: $0 -Y <mode> -n <namespace> -f <key>" >>log.txt
    return 1
  fi

  local key_file=""
  local use_1password=false

  # Determine key file path and whether to use 1Password
  echo "DEBUG: Processing key_arg: '$key_arg'" >>log.txt
  echo "DEBUG: File exists: $(test -f "$key_arg" && echo "YES" || echo "NO")" >>log.txt
  echo "DEBUG: Pattern match test: $(echo "$key_arg" | grep -q "/tmp/jj-signing-key-" && echo "MATCHES" || echo "NO MATCH")" >>log.txt

  if [[ "$key_arg" == ssh-* ]]; then
    echo "DEBUG: Taking ssh-* branch" >>log.txt
    # Key content provided directly - try to find local match first
    echo "DEBUG: Key content provided directly: $key_arg" >>log.txt
    local local_key
    if local_key=$(find_local_key_from_content "$key_arg"); then
      echo "Found matching local key for provided content: $local_key" >>log.txt
      key_file="$local_key"
      use_1password=false
    else
      echo "No matching local key found for provided content, will use 1Password" >>log.txt
      # Create temporary key file for 1Password
      temp_key=$(mktemp)
      echo "$key_arg 31802085+bnrobinson93@users.noreply.github.com" >"$temp_key"
      key_file="$temp_key"
      cleanup_temp=true
      use_1password=true
    fi
  elif [[ -f "$key_arg" && "$key_arg" == /tmp/jj-signing-key-* ]]; then
    echo "DEBUG: Taking jj temp file branch" >>log.txt
    # This is a jj temporary key file - check if we have a local match
    echo "DEBUG: Detected jj temporary key file: $key_arg" >>log.txt
    echo "DEBUG: File exists check: $(test -f "$key_arg" && echo "YES" || echo "NO")" >>log.txt
    echo "DEBUG: Pattern match check: $(echo "$key_arg" | grep -q "/tmp/jj-signing-key-" && echo "YES" || echo "NO")" >>log.txt
    local local_key
    if local_key=$(find_local_key_from_file "$key_arg"); then
      echo "Found matching local key for jj temp file: $local_key" >>log.txt
      key_file="$local_key"
      use_1password=false
    else
      echo "No matching local key found, will use 1Password with temp file" >>log.txt
      key_file="$key_arg"
      use_1password=true
    fi
  elif [[ -f "$HOME/.ssh/$key_arg" ]]; then
    # File exists in ~/.ssh
    echo "Using local key file: $HOME/.ssh/$key_arg" >>log.txt
    key_file="$HOME/.ssh/$key_arg"
    use_1password=false
  elif [[ -f "$key_arg" ]]; then
    # Direct file path exists - could be temp file or regular file
    echo "Using key file: $key_arg" >>log.txt
    key_file="$key_arg"
    # For any other temp files that might contain key content, try 1Password fallback
    if [[ "$key_arg" == /tmp/* ]]; then
      use_1password=true
    else
      use_1password=false
    fi
  else
    echo "Key file not found locally, will try 1Password fallback" >>log.txt
    key_file="$key_arg"
    use_1password=true
  fi

  local result=""
  local exit_code=0

  # Perform signing operation
  if [[ "$use_1password" == true ]]; then
    echo "Using 1Password for signing..." >>log.txt
    result=$(sign_with_1password "$mode" "$namespace" "$key_file")
    exit_code=$?

    # Optional: Save keys after successful 1Password operation
    if [[ $exit_code -eq 0 && "$mode" == "sign" ]]; then
      echo "Saving SSH keys for future local use..." >>log.txt
      save_ssh_keys || echo "Warning: Failed to save SSH keys" >>log.txt
    fi
  else
    echo "Using local SSH key for signing..." >>log.txt
    echo "Key file being used: $key_file" >>log.txt
    result=$(sign_with_local_key "$mode" "$namespace" "$key_file")
    exit_code=$?
  fi

  # Cleanup temporary file
  if [[ "$cleanup_temp" == true && -n "$temp_key" ]]; then
    rm -f "$temp_key"
  fi

  # Output result
  echo "$result"
  return $exit_code
}

# Run main function with all arguments
main "$@"
