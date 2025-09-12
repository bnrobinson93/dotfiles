#!/bin/bash
# fix-jj-signing.sh - Fix the JJ signing setup

set -euo pipefail

echo "Fixing JJ signing configuration..."

# Create directories
mkdir -p "$HOME/.local/bin"

# Path to wrapper script
WRAPPER_SCRIPT="$HOME/.local/bin/ssh-sign-wrapper.sh"

# Make sure the wrapper script exists and is executable
if [[ ! -f "$WRAPPER_SCRIPT" ]]; then
  echo "Error: Wrapper script not found at $WRAPPER_SCRIPT"
  echo "Please save the ssh-sign-wrapper.sh script to that location first"
  exit 1
fi

# Ensure it's executable
chmod +x "$WRAPPER_SCRIPT"
echo "✓ Made wrapper script executable"

# Verify the shebang is correct
if ! head -n1 "$WRAPPER_SCRIPT" | grep -q "^#!/"; then
  echo "Error: Script missing shebang line"
  echo "First line should be: #!/usr/bin/env bash"
  exit 1
fi
echo "✓ Shebang line verified"

# Test that the script can be executed
if ! "$WRAPPER_SCRIPT" -Y sign -n git -f /dev/null </dev/null 2>/dev/null; then
  echo "⚠ Script test failed (this is expected if no key provided)"
fi

# Check if script is in PATH (optional but helpful)
if command -v ssh-sign-wrapper.sh >/dev/null 2>&1; then
  echo "✓ Script is in PATH"
else
  echo "ℹ Script is not in PATH. Add this to your shell config:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Update jj config to use the full path
JJ_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/jj/config.toml"
if [[ -f "$JJ_CONFIG" ]]; then
  echo ""
  echo "Current JJ config signing program:"
  grep "program =" "$JJ_CONFIG" | grep -v "^#" || echo "  (not found)"

  echo ""
  echo "Please ensure your jj config has this exact line in [signing.backends.ssh]:"
  echo "  program = \"$WRAPPER_SCRIPT\""
  echo ""
  echo "You can update it with:"
  echo "  sed -i 's|program = .*ssh-sign.*|program = \"$WRAPPER_SCRIPT\"|' \"$JJ_CONFIG\""
fi

# Test with DEBUG mode
echo ""
echo "Testing signing with debug mode..."
DEBUG=1 "$WRAPPER_SCRIPT" -Y sign -n git -f "$HOME/.ssh/id_ed25519.pub" </dev/null 2>/tmp/ssh-sign-wrapper.log || true

if [[ -f /tmp/ssh-sign-wrapper.log ]]; then
  echo "Debug log (last 10 lines):"
  tail -10 /tmp/ssh-sign-wrapper.log
fi

echo ""
echo "Setup complete! Try running:"
echo "  DEBUG=1 jj git push -c@"
echo ""
echo "Check /tmp/ssh-sign-wrapper.log for debug output"
