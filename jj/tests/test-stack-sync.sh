#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export JJ_CONFIG="$root/jj/config.toml:$root/jj/conf.d"

show_log() {
  [ -n "${TRACE:-}" ] || return 0
  printf '\n== %s ==\n' "$1"
  jj log -r 'trunk() | (::@ & descendants(trunk())) | bookmarks()' --no-pager
}

git init --bare --initial-branch=main "$tmp/remote.git" >/dev/null
git init --initial-branch=main "$tmp/upstream" >/dev/null
git -C "$tmp/upstream" config user.name Test
git -C "$tmp/upstream" config user.email test@example.com
git -C "$tmp/upstream" config commit.gpgsign false
git -C "$tmp/upstream" remote add origin "$tmp/remote.git"
git -C "$tmp/upstream" commit --allow-empty -m root >/dev/null
git -C "$tmp/upstream" push -u origin main >/dev/null

jj --config signing.behavior=drop --config commit.sign=false git clone "$tmp/remote.git" "$tmp/client" >/dev/null
cd "$tmp/client"
jj config set --repo signing.behavior drop
jj config set --repo commit.sign false
jj config set --repo git.sign-on-push false

printf 'one A\n' >one.txt
jj describe -m 'one A' >/dev/null
jj new -m 'one B' >/dev/null
printf 'one A\none B\n' >one.txt
jj bookmark create feat/one -r @ >/dev/null
jj new -m 'two A' >/dev/null
printf 'two A\n' >two.txt
jj new -m 'two B' >/dev/null
printf 'two A\ntwo B\n' >two.txt
jj bookmark create feat/two -r @ >/dev/null
jj new -m three >/dev/null
printf 'three\n' >three.txt
jj bookmark create feat/three -r @ >/dev/null
jj new -m four >/dev/null
printf 'four\n' >four.txt
jj bookmark create feat/four -r @ >/dev/null
jj new >/dev/null
jj git push -b feat/one -b feat/two -b feat/three -b feat/four >/dev/null
show_log 'initial: main - PR1 - PR2 - PR3 - PR4'

git -C "$tmp/upstream" fetch origin >/dev/null
git -C "$tmp/upstream" checkout origin/feat/one -- .
git -C "$tmp/upstream" commit -m 'squash one' >/dev/null
git -C "$tmp/upstream" push origin main >/dev/null
git -C "$tmp/upstream" checkout -B feat/two origin/feat/two >/dev/null
git -C "$tmp/upstream" merge main -m 'merge main into two' >/dev/null
git -C "$tmp/upstream" push origin feat/two >/dev/null
git -C "$tmp/upstream" checkout main >/dev/null
git -C "$tmp/upstream" merge --squash feat/two >/dev/null
git -C "$tmp/upstream" commit -m 'squash two' >/dev/null
git -C "$tmp/upstream" push origin main >/dev/null
git -C "$tmp/upstream" push origin --delete feat/one feat/two >/dev/null

show_log 'before first sync: local stack still contains PR1 and PR2'
jj sync >/dev/null
show_log 'after first sync: main - PR3 - PR4'

test -z "$(jj log -r 'conflicts() & ::@' -T '"x"' --no-graph)"
test -z "$(jj log -r 'description(glob:"one *") | description(glob:"two *")' -T '"x"' --no-graph)"
test -n "$(jj log -r '::@ & descendants(trunk()) & description(glob:"three*")' -T '"x"' --no-graph)"
test -n "$(jj log -r '::@ & descendants(trunk()) & description(glob:"four*")' -T '"x"' --no-graph)"

jj new feat/three -m 'three follow-up' >/dev/null
printf 'three follow-up\n' >>three.txt
jj bookmark set feat/three -r @ >/dev/null
jj rebase -s feat/four -o @ >/dev/null
jj new feat/four >/dev/null
jj git push -b feat/three >/dev/null
jj describe -r feat/three -m 'three follow-up rewritten locally' >/dev/null
show_log 'after PR3 follow-up: main - PR3 - new change - PR4'

git -C "$tmp/upstream" fetch origin >/dev/null
git -C "$tmp/upstream" checkout main >/dev/null
git -C "$tmp/upstream" merge --squash origin/feat/three >/dev/null
git -C "$tmp/upstream" commit -m 'squash three' >/dev/null
git -C "$tmp/upstream" push origin main >/dev/null
git -C "$tmp/upstream" push origin --delete feat/three >/dev/null

show_log 'before second sync: PR3 squash is remote; local stack unchanged'
jj sync >/dev/null
show_log 'after second sync: main (PR3 squash) - PR4'

test -z "$(jj log -r 'conflicts() & ::@' -T '"x"' --no-graph)"
test -z "$(jj bookmark list -T 'if(!remote && name == "feat/three" && conflict, "x", "")' --no-pager)"
test -z "$(jj log -r '::@ & ~::trunk() & description(glob:"three*")' -T '"x"' --no-graph)"
test -n "$(jj log -r '::@ & descendants(trunk()) & description(glob:"four*")' -T '"x"' --no-graph)"
test "$(<one.txt)" = $'one A\none B'
test "$(<two.txt)" = $'two A\ntwo B'
test "$(<three.txt)" = $'three\nthree follow-up'
test "$(<four.txt)" = four
jj git push -b feat/four >/dev/null

git -C "$tmp/upstream" checkout main >/dev/null
printf 'main advanced\n' >"$tmp/upstream/main.txt"
git -C "$tmp/upstream" add main.txt
git -C "$tmp/upstream" commit -m 'advance main' >/dev/null
git -C "$tmp/upstream" push origin main >/dev/null
jj sync >/dev/null

git -C "$tmp/upstream" fetch origin >/dev/null
git -C "$tmp/upstream" checkout -B feat/four origin/feat/four >/dev/null
git -C "$tmp/upstream" merge main -m 'merge main into four' >/dev/null
git -C "$tmp/upstream" push origin feat/four >/dev/null
jj sync >/dev/null

test -z "$(jj bookmark list -T 'if(!remote && name == "feat/four" && conflict, "x", "")' --no-pager)"
test -z "$(jj diff --from feat/four --to feat/four@origin --summary)"

printf 'unmerged\n' >unmerged.txt
jj describe -m unmerged >/dev/null
jj bookmark create feat/unmerged -r @ >/dev/null
jj new >/dev/null
jj git push -b feat/unmerged >/dev/null
git -C "$tmp/upstream" push origin --delete feat/unmerged >/dev/null

jj sync >/dev/null

test -z "$(jj log -r 'conflicts() & ::@' -T '"x"' --no-graph)"
test "$(<unmerged.txt)" = unmerged

echo 'stack-sync integration passed'
