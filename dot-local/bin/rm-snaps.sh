#!/bin/sh
# shamelessly stolen from:
# https://ashrafur.medium.com/how-to-clean-up-old-snap-revisions-and-remove-loop-devices-93e38f1ad1f8

set -eu

LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
  while read -r snapname revision; do
    snap remove "$snapname" --revision="$revision"
  done
