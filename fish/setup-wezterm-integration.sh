#!/usr/bin/env bash
# Download Wezterm shell integration for Fish

set -e

INTEGRATION_DIR="$HOME/.local/bin"
INTEGRATION_FILE="$INTEGRATION_DIR/wezterm-shell-integration.fish"

echo "Downloading Wezterm shell integration for Fish..."

mkdir -p "$INTEGRATION_DIR"

curl -fsSL \
    https://raw.githubusercontent.com/wezterm/wezterm/main/assets/shell-integration/wezterm.sh \
    -o "$INTEGRATION_FILE"

chmod +x "$INTEGRATION_FILE"

echo "✓ Wezterm shell integration installed to $INTEGRATION_FILE"
echo "It will be automatically loaded when using Wezterm terminal"
