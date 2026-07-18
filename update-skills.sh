#!/usr/bin/env bash
set -u

failures=0

have() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  printf '\n==> %s\n' "$*"
}

try() {
  step "$*"
  if "$@"; then
    return 0
  fi

  failures=$((failures + 1))
  printf 'warn: failed: %s\n' "$*" >&2
  return 1
}

try_quiet() {
  "$@" >/dev/null 2>&1
}

install_ponytail() {
  local marketplace="${PONYTAIL_MARKETPLACE:-DietrichGebert/ponytail}"

  if have claude; then
    try_quiet claude plugin marketplace add "$marketplace" || true
    try claude plugin marketplace update ponytail || true
    if claude plugin list 2>/dev/null | grep -q 'ponytail@ponytail'; then
      try claude plugin update ponytail@ponytail || true
    else
      try claude plugin install ponytail@ponytail || true
    fi
  fi

  if have codex; then
    try_quiet codex plugin marketplace add "$marketplace" || true
    try codex plugin marketplace upgrade ponytail || true
    if codex plugin list 2>/dev/null | grep -q 'ponytail@ponytail.*installed'; then
      step "codex ponytail already installed"
    else
      try codex plugin add ponytail@ponytail || true
    fi
  fi

  if have opencode; then
    try opencode plugin --global --force @dietrichgebert/ponytail || true
  fi
}

install_hunk() {
  local source="${HUNK_SKILL_SOURCE:-modem-dev/hunk}"

  if have npx; then
    try npx -y skills add "$source" --skill hunk-review -g -a claude-code -a codex -a opencode -y || true
  else
    failures=$((failures + 1))
    printf 'warn: npx not found; cannot install hunk skill from %s\n' "$source" >&2
  fi
}

install_teach() {
  local source="${TEACH_SKILL_SOURCE:-mattpocock/skills}"

  if have npx; then
    try npx -y skills add "$source" --skill teach -g -a claude-code -a codex -a opencode -y || true
  else
    failures=$((failures + 1))
    printf 'warn: npx not found; cannot install teach skill from %s\n' "$source" >&2
  fi
}

install_fabric() {
  if have fabric; then
    return 0
  fi

  try bash -c "curl -fsSL https://raw.githubusercontent.com/danielmiessler/fabric/main/scripts/installer/install.sh | bash" || return
  printf 'note: run `fabric --setup` once to configure providers\n'
}

install_ponytail
install_hunk
install_teach
install_fabric

if [[ "$failures" -gt 0 ]]; then
  printf '\nDone with %s warning(s). Restart agents to pick up skill/plugin changes.\n' "$failures" >&2
  exit 1
fi

printf '\nDone. Restart agents to pick up skill/plugin changes.\n'
