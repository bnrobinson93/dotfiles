# Omarchy AI and mise

Checked upstream `omacom/omarchy`, branch `quattro`, on 2026-09-15.

## Findings

Omarchy uses mise-backed lazy launchers for its AI command-line tools. Its AI manual lists `claude`, `codex`, `opencode`, `agy`, `copilot`, `crush`, `pi`, and others as mise-managed launchers in `~/.local/bin/`. The launcher is created by `omarchy-mise-install`; it writes a wrapper that runs `mise use -g` and then `mise x`.

Omarchy updates those tools through `omarchy-update-mise`, which runs `mise up` with the release-age cooldown disabled. Omarchy's upstream tree contains no pnpm references and no pnpm mise tool declaration.

Therefore, pnpm is separate from Omarchy's mise-managed AI setup. On this macOS machine, pnpm is Homebrew-managed at `/opt/homebrew/bin/pnpm`; `~/.local/share/pnpm/bin` is pnpm's global package-binary directory, not the pnpm executable location or a mise shim.

## Sources

- [Omarchy AI manual](https://github.com/omacom/omarchy/blob/quattro/manual/17-ai.md)
- [`omarchy-mise-install`](https://github.com/omacom/omarchy/blob/quattro/bin/omarchy-mise-install)
- [`omarchy-update-mise`](https://github.com/omacom/omarchy/blob/quattro/bin/omarchy-update-mise)
- [`install/user/mise.sh`](https://github.com/omacom/omarchy/blob/quattro/install/user/mise.sh)
- [Omarchy `quattro` tree search](https://github.com/omacom/omarchy/tree/quattro)
