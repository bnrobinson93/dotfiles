#!/bin/bash

TOUCHPAD="elan1206:00-04f3:30f1-touchpad"
STATE_FILE="/tmp/touchpad-enabled"

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "true" > "$STATE_FILE"
fi

# Read current state
ENABLED=$(cat "$STATE_FILE")

if [ "$ENABLED" = "true" ]; then
    hyprctl keyword "device[$TOUCHPAD]:enabled" false
    echo "false" > "$STATE_FILE"
    notify-send "Touchpad" "Disabled" -t 2000
else
    hyprctl keyword "device[$TOUCHPAD]:enabled" true
    echo "true" > "$STATE_FILE"
    notify-send "Touchpad" "Enabled" -t 2000
fi
