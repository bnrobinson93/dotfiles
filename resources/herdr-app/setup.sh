#!/usr/bin/env bash
# Installs the Herdr app mods this setup borrows, at pinned commits, with the jj patches
# beside this script, then writes the main-jj layout. Only the patches live in the repo:
# the mods are other people's, and Herdr rewrites layout files on its own.
#
# Copies, not stow links: Herdr refuses a mod's `./views/*.js` import through a symlink.
# Rerunning replaces these mod folders whole and rebuilds main-jj from the shipped main.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
home=${HERDR_APP_HOME:-$HOME/.config/herdr-app}

JJ_REPO=https://github.com/sebcbi1/herdr-app-jj.git
JJ_REV=1ffdc17f5f36b50f3ee502fadf5abf3f4742c1fd
MODS_REPO=https://github.com/munza/herdr-mods.git
MODS_REV=860626068cb7e32a1db96b2f66baadc271d5667a

[ -f "$home/layouts/main.json" ] || {
  echo "No $home/layouts/main.json: start Herdr once first." >&2
  exit 1
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fetch() {
  git init -q "$work/$1"
  git -C "$work/$1" fetch -q --depth 1 "$2" "$3"
  git -C "$work/$1" checkout -q FETCH_HEAD
}
fetch jj "$JJ_REPO" "$JJ_REV"
fetch better "$MODS_REPO" "$MODS_REV"

stage="$work/stage"
mkdir "$stage"
for m in jj-menu jj-status jj-workspace; do cp -R "$work/jj/mods/$m" "$stage/"; done
for m in better-sidebar better-changes better-files better-icons; do
  cp -R "$work/better/$m/mods/$m" "$stage/"
done
for p in "$here"/*.patch; do patch -s -d "$stage" -p1 <"$p"; done

mkdir -p "$home/mods"
for dir in "$stage"/*/; do
  m=$(basename "$dir")
  rm -rf "${home:?}/mods/$m"
  cp -R "$dir" "$home/mods/$m"
  if command -v herdr-app >/dev/null; then herdr-app check "$home/mods/$m"; fi
done

python3 "$here/layout.py" "$home"
# Shows it in a running window; with none, pick it later with ctrl-shift-l.
herdr-app do layout.switch --name main-jj >/dev/null 2>&1 || true
