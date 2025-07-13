#!/bin/bash
# op-ssh-sign-wrapper - Converts jj signing calls to 1Password format

# Check if we're on macOS or Linux and set the 1Password binary path
if [[ "$OSTYPE" == "darwin"* ]]; then
  OPSIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OPSIGN="/opt/1Password/op-ssh-sign"
else
  echo "Unsupported OS: $OSTYPE" >&2
  exit 1
fi

# Parse arguments properly - jj can reorder them
mode=""
namespace=""
key_file=""
temp_key=""

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
      # Check if it's a key content (starts with ssh-) or a file path
      if [[ "$key_arg" == ssh-* ]]; then
        # It's key content, create a temporary file
        temp_key=$(mktemp)
        echo "$key_arg github@biblebrad.com" > "$temp_key"
        key_file="$temp_key"
      else
        # It's already a file path, use as-is
        key_file="$key_arg"
      fi
      shift 2
      ;;
    *)
      # Skip unknown arguments
      shift
      ;;
  esac
done

# Ensure we have all required arguments
if [[ -z "$mode" || -z "$namespace" || -z "$key_file" ]]; then
  echo "Error: Missing required arguments" >&2
  echo "Got: mode='$mode', namespace='$namespace', key_file='$key_file'" >&2
  exit 1
fi

# Call 1Password with the correct argument order
result=$("$OPSIGN" -Y "$mode" -n "$namespace" -f "$key_file")
exit_code=$?

# Clean up temporary file if we created one
if [[ -n "$temp_key" ]]; then
  rm -f "$temp_key"
fi

echo "$result"
exit $exit_code
