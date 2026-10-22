#!/bin/bash
# Does this machine have a battery? tmux.conf gates the battery widget on this
# through `if-shell`, which runs once at config load — so the answer has to be
# presence, not charge state, or the widget vanishes for the life of any tmux
# server started while plugged in.

case "$(uname)" in
Darwin)
  pmset -g batt | grep -q InternalBattery
  ;;
Linux)
  grep -qxs Battery /sys/class/power_supply/*/type
  ;;
*)
  exit 2
  ;;
esac
