# CLAUDE.md

Linux dotfiles deployed with GNU Stow. Deploy with `mise run stow` (configs, `~/.local`, zsh,
ssh) and `mise run skills` (AI config, skills, plugins); `mise tasks` lists the rest.

## Stow

- Default target is `~/.config` (`.stowrc`); `dot-local` targets `~/.local`, `zsh` targets
  `~`, both with `--dotfiles`. Dry-run with `stow -v2 -n <pkg>`.
- `.stowrc` is a denylist and `stow .` walks the whole repo root, so anything new at the root
  that is not a config package lands in `~/.config` until it gets an `--ignore` line. Each
  pattern must match a single basename and must never match `CLAUDE.md` or `AGENTS.md`:
  `update-skills.sh` stows `ai/` with the repo root as cwd, so these ignores reach that run too.
- Persistent fish functions live in `fish/functions/`. `install.sh` deletes `~/.config/fish`
  before restowing, so a file only there is lost.

## Omarchy desktop (v4)

Arch + Hyprland. Bar, menu, notifications, lock, OSD, polkit, and idle all run in one
Quickshell process (`omarchy-shell`). Apply the `omarchy` skill for any `hypr/` or `omarchy/`
edit.

- `hypr/`: only `.lua` files are live (plus `hyprsunset.conf`, `xdph.conf`). They hold only
  what differs from `/usr/share/omarchy/default/hypr/`; read that first.
- `omarchy/` holds `extensions/omarchy-menu.jsonc` only. Deploy with `stow -v2 .`, never
  `stow omarchy`, which folds the directory and pulls Omarchy's generated state into the repo.
- `~/.config/omarchy/shell.json` is the shell's own state: the shell, `omarchy bar`,
  `omarchy plugin`, and upstream migrations all write it. Change the bar through the CLI or
  the bar's right-click menu; a tracked copy or generator would fight them.
- Never edit `/usr/share/omarchy/`. Prefer an extension point (a `type: command` bar module, a
  menu row, an `omarchy toggle` flag, a small `qs.Ui` plugin) over `omarchy plugin clone`.
- Personal plugins come from `github.com/bnrobinson93/omarchy-<id>` via
  `mise run omarchy-plugins`, which only a fresh machine needs.

## Shared AI config (`ai/`)

`update-skills.sh` stows `ai/` into `~/.claude`, `~/.codex`, `~/.config/opencode`, and
`~/.pi/agent`, so everything here must work without harness-specific paths. Apply the
`writing-for-agents` skill for any edit under `ai/`.

- `ai/AGENTS.md` (`CLAUDE.md` links to it) loads on every prompt, coding or not, so it holds
  only the short inline bar and a pointer to `simplify`. Eval: that plus one end-of-task
  `simplify` skill matched a 16-row skill routing table on quality and speed.
- A skill's frontmatter `name` equals its directory name; Claude keys off the directory, the
  others off the frontmatter.
- Point at reference material as `~/.dotfiles/ai/...`, the one path every harness resolves.
- One rule, one home: `simplify` owns the full bar and every learned code preference,
  `think-like-brad` owns judgment outside code, project memory owns repo facts.
  `learn-preferences` routes new rules.
- A skill its upstream publishes goes in `SKILLS` in `update-skills.sh`, not `ai/skills/`.
- `ai` stows with `--no-folding`; folded, every skill the skills CLI installs lands in this repo.
- `ai/dot-codex/` files are hand-copied seeds; Codex and Herdr rewrite them in place.

## Shell startup

Baseline on the aarch64 Pi: fish ~28ms, zsh ~34ms, idle (2026-10-31). A reading near 35 is a
regression. Keep it that way:

- Never `tool init | source` on the startup path. Cache generated init with `__cache_gen`
  (same name in `fish/functions/` and `dot-zshrc`), and cache the init a tool *runs*, not a
  stub that re-invokes it (starship needs `--print-full-init`).
- Nothing on the startup path may exec a tool: the cheapest still costs 2-9ms against a 28ms
  budget (a mise shim itself is free since mise 2026.10.8). `__cache_gen` stamps against mise's
  shims directory, not the shim, because a shim stops moving when the tool is upgraded.
- Benchmark a candidate under a scratch `XDG_CONFIG_HOME`; copying over `~/.config/fish`
  writes through the stow symlinks into this repo. Profile fish with
  `fish --profile-startup <file>`, zsh with `zmodload zsh/zprof` under a scratch `ZDOTDIR`.
- Nightly cron readings run under `hyperfine`; a wide σ means disk churn, not drift.
  Re-measure on an idle box before acting on one.

## Signing

Git and JJ commits are SSH-signed with `~/.ssh/id_ed25519_GitHubSigning`; per-machine
overrides (1Password `op-ssh-sign`) go in `~/.gitlocal` and `~/.config/jj/conf.d/z-local.toml`.

Unresolved: on Linux zsh opts into the 1Password agent (`dot-zshenv`, `dot-zshrc`) while fish
opts out (`fish/conf.d/00-env.fish`). Which shell moves is Brad's decision, not a cleanup.
