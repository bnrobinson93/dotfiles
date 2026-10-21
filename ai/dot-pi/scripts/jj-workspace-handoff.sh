#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: jj-workspace-handoff.sh SOURCE_WORKSPACE TARGET_WORKSPACE [REVISION]\n'
  printf '  workspace values may be JJ workspace names or paths; REVISION defaults to SOURCE_WORKSPACE@\n'
  printf '  the target must be clean and both workspaces must belong to the same JJ repository\n'
}

if [[ $# -eq 1 && ( "$1" == '-h' || "$1" == '--help' ) ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

source_input=$1
target_input=$2
revision_input=${3-}

workspace_rows() {
  local repo_root=$1
  jj --no-pager -R "$repo_root" workspace list \
    -T 'self.name() ++ "\t" ++ if(self.root(), self.root(), "") ++ "\n"'
}

workspace_info() {
  local input=$1
  local repo_root
  local requested_root=''

  if [[ -d "$input" ]]; then
    requested_root=$(cd "$input" && pwd -P)
    repo_root=$(cd "$input" && jj workspace root 2>/dev/null) || {
      printf 'not a JJ workspace: %s\n' "$input" >&2
      return 1
    }
  else
    repo_root=$(jj workspace root 2>/dev/null) || {
      printf 'workspace name requires running inside a JJ repository: %s\n' "$input" >&2
      return 1
    }
  fi

  local repo_identity repo_path
  repo_path="$repo_root/.jj/repo"
  if [[ -f "$repo_path" ]]; then
    repo_identity=$(cd "$repo_root/.jj" && realpath "$(<"$repo_path")")
  else
    repo_identity=$(realpath "$repo_path")
  fi
  [[ -n "$repo_identity" ]] || {
    printf 'JJ repository identity not found: %s\n' "$repo_root" >&2
    return 1
  }

  local name root
  while IFS=$'\t' read -r name root; do
    [[ -n "$name" ]] || continue
    if [[ "$input" == "$name" || ( -n "$requested_root" && "$requested_root" == "$root" ) ]]; then
      printf '%s\t%s\t%s\n' "$name" "$root" "$repo_identity"
      return 0
    fi
  done < <(workspace_rows "$repo_root")

  printf 'JJ workspace not found: %s\n' "$input" >&2
  return 1
}

source_info=$(workspace_info "$source_input")
target_info=$(workspace_info "$target_input")

IFS=$'\t' read -r source_name source_root source_repo <<<"$source_info"
IFS=$'\t' read -r target_name target_root target_repo <<<"$target_info"

if [[ "$source_repo" != "$target_repo" ]]; then
  printf 'source and target must belong to the same JJ repository\n' >&2
  exit 1
fi

if [[ "$source_root" == "$target_root" ]]; then
  target_commit=$(jj --no-pager -R "$target_root" log -r @ --no-graph -T 'self.commit_id()')
  printf 'No-op: source and target are the same workspace (%s).\n' "$source_name"
  printf 'Target: %s\nRevision: %s\n' "$target_root" "$target_commit"
  exit 0
fi

if [[ -n "$revision_input" ]]; then
  revision_commits=$(jj --no-pager -R "$source_root" log -r "$revision_input" --no-graph -T 'self.commit_id() ++ "\n"')
  mapfile -t revision_ids <<<"$revision_commits"
  if [[ ${#revision_ids[@]} -ne 1 || -z "${revision_ids[0]}" ]]; then
    printf 'revision must resolve to exactly one commit in the source workspace: %s\n' "$revision_input" >&2
    exit 1
  fi
  source_commit=${revision_ids[0]}
else
  source_commit=$(jj --no-pager -R "$source_root" log -r @ --no-graph -T 'self.commit_id()')
fi

if [[ -n "$(jj --no-pager -R "$target_root" diff --summary)" ]]; then
  printf 'target workspace has uncommitted changes; refusing handoff: %s\n' "$target_root" >&2
  exit 1
fi

printf 'Handoff: %s (%s) -> %s (%s)\n' "$source_name" "$source_root" "$target_name" "$target_root"
printf 'Source revision: %s\n' "$source_commit"
jj --no-pager -R "$target_root" edit "$source_commit"

target_commit=$(jj --no-pager -R "$target_root" log -r @ --no-graph -T 'self.commit_id()')
if [[ "$target_commit" != "$source_commit" ]]; then
  printf 'handoff verification failed: target=%s source=%s\n' "$target_commit" "$source_commit" >&2
  exit 1
fi

printf 'Verified target %s now points at %s.\n' "$target_name" "$target_commit"
printf 'No jj commit performed; the handoff remains uncommitted.\n'
