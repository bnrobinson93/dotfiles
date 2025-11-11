# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository managing a complete Linux development environment using **GNU Stow** for symlink management. The configuration supports Neovim (LazyVim-based), Wezterm, Tmux, Zsh with extensive tooling integration.

## Common Commands

### Deployment & Installation

```bash
# Deploy configs to ~/.config
stow -v2 .

# Deploy local scripts to ~/.local
stow -v2 -t ~/.local -S dot-local --dotfiles

# Deploy home directory configs (zsh, gitmux)
stow -v2 -t ~ -S zsh gitmux --dotfiles

# Set zsh as default shell
chsh -s /bin/zsh

# Reload tmux config
tmux source-file ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf

# Rebuild bat cache (needed after theme changes)
bat cache --build

# Run automated setup script
./install.sh
```

### Testing Changes

```bash
# Test a specific stow package (dry-run)
stow -v2 -n <package-name>

# Restow (update symlinks after changes)
stow -v2 -R <package-name>

# Remove symlinks
stow -v2 -D <package-name>
```

### Neovim

```bash
# Launch Neovim
nvim

# Check LazyVim health
nvim +checkhealth

# Update plugins
nvim +Lazy

# Sync LazyVim extras
nvim +LazyExtras
```

### Recording Demos

```bash
# Record terminal session and convert to GIF
asciinema rec demo.cast
agg --theme nord --font-size 16 --font-family "DankMono Nerd Font" demo.cast ~/Pictures/demo.gif && rm demo.cast
```

## Architecture & Key Concepts

### Stow Package Structure

Each top-level directory (except special cases) is a **stow package** that gets symlinked:

- **Target: `~/.config/`** (default via `.stowrc`): alacritty, atuin, bat, git, jj, k9s, kitty, lazygit, nvim, tmux, wezterm, etc.
- **Target: `~/.local/`**: dot-local package (contains bin/ with custom scripts)
- **Target: `~/`**: zsh, gitmux (use `--dotfiles` flag to convert `dot-*` to `.*)

The `.stowrc` file defines:
- Default target: `~/.config`
- `--dotfiles` mode (dot-prefixed files become hidden)
- Ignore patterns: `dot-local`, `nvim.lazy`, `resources`

### Neovim Plugin Architecture

**Base**: LazyVim framework with modular plugin system

**Structure**:
- `init.lua` - Entry point that loads `lua/config/lazy.lua`
- `lua/config/` - Core configuration
  - `lazy.lua` - Plugin manager setup
  - `keymaps.lua` - Custom keybindings
  - `options.lua` - Editor options
  - `autocmds.lua` - Autocommands
- `lua/plugins/` - **18 individual plugin files**, each returns a plugin spec table
  - Plugins are lazy-loaded by default
  - Custom configs override LazyVim defaults
  - Use `enabled = false` to disable LazyVim plugins
- `snippets/` - LuaSnip snippets (all.json, markdown.json)
- `utils/` - External tool configs (.eslintrc.json, .markdownlint.json, .zizmor.yaml)

**Key Plugin Categories**:
- **Completion**: blink.cmp with emoji integration
- **Linting**: nvim-lint (ESLint, markdownlint-cli2, actionlint, zizmor)
- **UI**: Noice, which-key, Catppuccin colorscheme
- **Version Control**: hunk.nvim for interactive diff editing
- **Note-taking**: obsidian.nvim (vault at `~/Documents/Vault`)
- **AI**: Copilot + Copilot Chat
- **Markdown**: render-markdown.nvim with checkbox support

### Wezterm Configuration

Modular Lua config split into 4 files:
- `wezterm.lua` - Main config (Catppuccin Mocha theme, Ctrl+A leader key)
- `sessionizer.lua` - Project picker using fzf (Ctrl+A f)
- `workspace_manager.lua` - Tmux-like workspace switching
- `tabbar.lua` - Custom tab bar with workspace indicators

### Shell Configuration (Zsh)

**Lazy Loading Pattern**: Heavy tools are deferred to avoid slow shell startup
- `dot-zshrc` - Main config with lazy-load functions for:
  - nvm (Node.js version manager)
  - cargo (Rust toolchain)
  - rbenv (Ruby version manager)
  - kubectl (Kubernetes CLI)
  - go (Go toolchain)
- `dot-zshenv` - Environment variables
- Integrations: Atuin (history), carapace (completions), Starship (prompt), zap (plugin manager)

### Version Control Dual Setup

**Git** (primary):
- GPG signing enabled by default
- Auto-redirect HTTPS → SSH for git URLs
- Aliases: `l` (log), `s` (status), `c` (commit), `ac` (add+commit), `acp` (add+commit+push)

**Jujutsu** (secondary):
- Modern VCS alternative with advanced revset queries
- SSH signing via custom wrapper (`ssh-sign-wrapper.sh`)
- Complex bookmark and push logic in config/config.toml

### Tmux Integration

- **Prefix**: Ctrl+A (screen-like, matches Wezterm)
- **Vi-mode**: hjkl navigation
- **Plugins** (via TPM):
  - catppuccin/tmux (theme)
  - tmux-yank (clipboard integration)
  - tmux-resurrect (session persistence)
  - tmux-continuum (auto-restore)
  - tmux-battery (status bar)
- **Sessionizer binding**: Ctrl+A f (runs tmux-sessionizer script)

### Custom Scripts (`dot-local/bin/`)

When modifying or adding scripts:
- Use absolute paths where possible
- Mark shell scripts executable: `chmod +x <script>`
- After changes, restow: `stow -v2 -R -t ~/.local dot-local --dotfiles`

Key scripts:
- `tmux-sessionizer` - Project picker with fzf (integrated into Wezterm & Tmux)
- `ssh-sign-wrapper.sh` - SSH signing for git/jj commits
- `fix-jj-signing.sh` - Jujutsu signing key management
- `battery_check.sh` - Battery monitoring

## Theme Consistency

**Primary Theme**: Catppuccin Mocha
- Applied across: Neovim, Starship, Tmux, K9s, Lazygit, Alacritty, Wezterm
- Secondary: Tokyo Night (available in Neovim, experimental)

When adding new tools, prefer Catppuccin Mocha theme for consistency.

## Obsidian Integration

- Vault location: `~/Documents/Vault`
- Neovim keybinding: `<C-n>` to create new note
- Template system for daily notes (see nvim/lua/plugins/obsidian.lua:52)
- Markdown checkboxes rendered in Neovim via render-markdown.nvim

## WSL Considerations

When working on WSL, ensure locale is set:
```bash
sudo apt-get install language-pack-en language-pack-en-base manpages
sudo update-locale LANG=en_US.UTF8
# Restart terminal after
```

## Security & Signing

- **Git commits**: GPG-signed by default
- **Jujutsu commits**: SSH-signed via `ssh-sign-wrapper.sh`
- **1Password integration**: SSH agent socket at `~/.1password/agent.sock`
- **GitHub signing**: Configured in git config

## File Editing Conventions

### Neovim Plugins
- Each plugin goes in a separate file under `lua/plugins/`
- Return a table with plugin spec (compatible with lazy.nvim)
- Use `opts = {}` for simple config, `config = function()` for complex setup
- Add `event`, `ft`, or `cmd` for lazy loading

### Stow Packages
- Keep package-specific files in subdirectories
- Use `dot-*` prefix for files that should become `.filename` in home directory
- Update `.stowrc` if adding new ignore patterns
- Test with `stow -n` (dry-run) before actual deployment

### Shell Scripts
- Use `#!/usr/bin/env bash` for portability
- Add descriptive comments for non-obvious logic
- Test interactively before committing

## LazyVim Extras Installed

The following LazyVim extras are enabled (see Lazyvim.json):
- coding.luasnip, coding.mini-surround
- dap.core (debugging)
- editor.harpoon2, editor.leap
- formatting.prettier
- lang.ansible, lang.docker, lang.git, lang.go, lang.json, lang.markdown, lang.python, lang.terraform, lang.toml, lang.typescript, lang.yaml
- linting.eslint
- ui.alpha (startup screen)
- util.dot, util.mini-hipatterns
