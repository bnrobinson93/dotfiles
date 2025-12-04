# Fish Shell Quick Start

**TL;DR**: Fish is now configured and mirrors your zsh setup. Read this if you hit issues.

## Deploy

```bash
cd ~/.dotfiles && stow .
```

## Essential Setup

```bash
# 1. Install fisher (plugin manager)
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# 2. Install NVM plugin
fisher install jorgebucaran/nvm.fish

# 3. Set as default shell (optional)
chsh -s $(which fish)
# Then logout/login
```

## Quick Fixes

### Atuin shows full interface instead of compact
```bash
# Edit ~/.config/atuin/config.toml, change:
style = "compact"
```

### Fish greeting appears
```fish
set -U fish_greeting
```

### $SHELL shows zsh
Normal! `$SHELL` = login shell, not current shell.
```fish
echo $0  # Shows current shell (should be 'fish')
```

### NVM not working
```fish
fisher install jorgebucaran/nvm.fish
```

## Key Bindings

- **Ctrl+R**: Atuin search (same as zsh)
- **Ctrl+A**: Beginning of line
- **Ctrl+E**: End of line
- **Esc**: Vi normal mode
- **Alt+Click**: Position cursor (mouse support!)

## Testing Everything Works

```fish
# Run in fish shell:
starship --version    # Prompt working
atuin search         # Ctrl+R - compact interface
z ~/Documents        # Smart cd
la                   # Eza listing
nvm use              # NVM (with .nvmrc file)
```

## Performance

```bash
time fish -c exit  # Should be ~30-50ms
time zsh -c exit   # Was ~200-500ms
```

**4-10x faster!** 🚀

## Full Documentation

- `fish/README.md` - Comprehensive guide
- `fish/MIGRATION_LOG.md` - Complete migration details with all fixes
- `fish_config` - Web UI for customization

## Rollback to Zsh

```bash
chsh -s $(which zsh)
# Logout/login
# Your zsh config is untouched
```
