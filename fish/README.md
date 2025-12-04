# Fish Shell Configuration

Modern, optimized fish shell configuration converted from zsh with native fish features and QoL improvements.

## Installation

### 1. Deploy the config
```bash
cd ~/.dotfiles
stow -v2 fish
```

### 2. Set fish as your default shell
```bash
# Add fish to valid shells (if not already there)
command -v fish | sudo tee -a /etc/shells

# Set as default shell
chsh -s $(command -v fish)
```

### 3. Install optional dependencies

#### Essential (recommended)
```bash
# Fisher - Plugin manager
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# NVM for Node.js version management (replaces bash nvm)
fisher install jorgebucaran/nvm.fish

# fzf.fish - Better fzf integration with preview windows
fisher install PatrickF1/fzf.fish
```

#### Optional QoL plugins
```bash
# Colored man pages
fisher install decors/fish-colored-man

# Puffer - Text expansion (like zsh's autosuggestions++)
fisher install nickeb96/puffer-fish

# Autopair - Auto-close brackets and quotes
fisher install jorgebucaran/autopair.fish

# Sponge - Remove failed commands from history
fisher install meaningful-ooo/sponge
```

## Key Differences from Zsh

### What Fish Handles Natively (removed from config)
- ✅ **Syntax highlighting** - Built-in, no plugin needed
- ✅ **Autosuggestions** - Native and better than zsh
- ✅ **Completions** - Excellent built-in system
- ✅ **Command history** - Better history search (Ctrl+R with atuin)
- ✅ **Mouse support** - Alt+click to position cursor (works in Wezterm)
- ✅ **Web config** - Run `fish_config` for GUI configuration

### Fish Optimizations Applied
- **Abbreviations instead of aliases** - Expand in command line, saved in history
- **Modular config** - `conf.d/` files load automatically in order
- **Lazy loading simplified** - Fish is fast, but still lazy-loads heavy tools
- **fish_add_path** - Automatically deduplicates PATH entries
- **Better function syntax** - Cleaner than zsh functions

## Configuration Structure

```
fish/
├── config.fish              # Main config (minimal, loads conf.d/)
├── conf.d/
│   ├── 00-env.fish         # Environment variables
│   ├── 01-paths.fish       # PATH configuration
│   ├── 02-tools.fish       # Tool integrations (atuin, starship, etc.)
│   └── 03-abbreviations.fish # Abbreviations (better aliases)
└── functions/              # Individual functions (auto-loaded)
    ├── la.fish            # List all files
    ├── ll.fish            # List long format
    ├── l.fish             # List with icons
    ├── rec.fish           # Record terminal to GIF
    ├── ignore.fish        # Add to .gitignore
    └── bookmark.fish      # Show jj bookmarks
```

## Quality of Life Features

### 1. **Mouse Support (Already enabled!)**
- Alt+click to position cursor in Wezterm
- Works with shell integration automatically
- No configuration needed

### 2. **Abbreviations (Better than aliases)**
```fish
# Add abbreviations interactively (they persist automatically)
abbr -a gs 'git status'
abbr -a gco 'git checkout'

# They expand when you press space, so you see what you're running!
# Example: Type "gs<space>" → expands to "git status"
```

### 3. **Universal Variables (Persist across sessions)**
```fish
# Set variables that persist without editing config files
set -U my_var "value"  # Universal (saved to disk)
set -g my_var "value"  # Global (this session)
set -l my_var "value"  # Local (this function/block)
```

### 4. **Better History**
- Ctrl+R - Atuin search (same as zsh config)
- Up/Down - Context-aware history (already configured)
- History is deduplicated automatically

### 5. **Fish Config GUI**
```fish
fish_config  # Opens web UI for colors, prompts, functions, variables
```

## Tool Integrations

All your zsh tools are configured:
- ✅ Starship prompt (cached for speed)
- ✅ Atuin history (Ctrl+R)
- ✅ Zoxide (smart cd)
- ✅ Eza (modern ls)
- ✅ Carapace completions
- ✅ NVM (lazy-loaded)
- ✅ Homebrew (lazy-loaded)
- ✅ Go, Cargo, Rbenv (lazy-loaded)
- ✅ 1Password SSH agent
- ✅ Wezterm shell integration
- ✅ JJ (Jujutsu) completions

## Customization

### Adding abbreviations
```fish
abbr -a shortcut 'full command here'
```

### Adding functions
Create a new file in `functions/` directory:
```fish
# functions/my_function.fish
function my_function
    echo "Hello from my function"
end
```

### Modifying PATH
Edit `conf.d/01-paths.fish` and add:
```fish
fish_add_path /your/new/path
```

## Performance

Fish is generally **faster than zsh** out of the box:
- No compinit delays
- No plugin manager overhead
- Lazy loading still implemented for heavy tools (nvm, brew, etc.)
- Startup time should be <50ms

## Troubleshooting

### NVM not working
Install bass: `fisher install edc/bass`
Then update `conf.d/02-tools.fish` to use bass for nvm loading.

### Completions not working
Try: `fisher update` or `carapace --list | xargs -I{} touch ~/.config/fish/completions/{}.fish`

### Slow startup
Check startup time: `time fish -c exit`
If slow (>100ms), disable heavy integrations in `02-tools.fish`

### Missing features from zsh
Most zsh features have fish equivalents. Ask if you need specific functionality!

## Migration Notes

### Removed (handled by fish natively or fisher plugins)
- zsh-syntax-highlighting → Built-in
- zsh-autosuggestions → Built-in
- compinit → Not needed
- zle/bindkey → fish's vi mode
- Complex prompt caching → fish handles with psub
- Manual nvm wrapper → fisher nvm.fish plugin
- Carapace completion file generation → carapace init handles it

### Kept and optimized
- Lazy loading (simplified)
- Tool integrations (all working)
- Custom functions (cleaner syntax)
- Vi mode with emacs bindings in insert mode
- Color scheme (vivid + catppuccin)

## Recommended Next Steps

1. **Install fisher** and essential plugins
2. **Try `fish_config`** to explore settings
3. **Add abbreviations** for your common commands
4. **Install fzf.fish** for amazing fuzzy search
5. **Customize prompt** with `fish_config` or keep starship

Enjoy your fish! 🐟
