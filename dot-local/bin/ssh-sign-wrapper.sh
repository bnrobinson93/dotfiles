#!/bin/bash
# op-ssh-sign-wrapper - Cross-platform 1Password SSH signing wrapper

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  exec /Applications/1Password.app/Contents/MacOS/op-ssh-sign "$@"

# Linux - adjust this path based on your 1Password installation
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [ -x "/opt/1Password/op-ssh-sign" ]; then
    exec /opt/1Password/op-ssh-sign "$@"
  elif [ -x "/usr/local/bin/op-ssh-sign" ]; then
    exec /usr/local/bin/op-ssh-sign "$@"
  else
    echo "Error: Could not find 1Password SSH signing program on Linux" >&2
    echo "Please update the path in ~/.local/bin/ssh-sign-wrapper" >&2
    exit 1
  fi

else
  echo "Unsupported OS: $OSTYPE" >&2
  exit 1
fi
