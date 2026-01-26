# Tool Integrations
# Sets up modern CLI tools and their configurations
# Tool Integrations - Optimized for Fast Startup
# Only load in interactive shells
if not status is-interactive
    exit
end

# Starship prompt (fish handles this efficiently with psub)
if type -q starship
    starship init fish | source
end

# Mise - for managing versions
if type -q mise
    mise activate fish | source
end

# Atuin - better shell history (fish integration is excellent)
if type -q atuin
    # Add atuin bin to PATH (fish equivalent of sourcing env file)
    fish_add_path $HOME/.atuin/bin

    # Initialize atuin (disable up-arrow binding to match zsh config)
    atuin init fish --disable-up-arrow | source
end

# Zoxide - smart directory jumping (replaces cd)
if type -q zoxide
    zoxide init fish | source
end

# Carapace - universal completion engine (replaces custom completions)
if type -q carapace
    carapace _carapace fish | source
end

# JJ (Jujutsu) completion
if type -q jj
    jj util completion fish | source
end

# 1Password SSH signing setup
if set -q USE_1PASSWORD_SSH
    if type -q op; and not test -f $HOME/.ssh/allowed_signers
        op item get --vault Private "GitHub Signing" --fields email,public_key | sed 's/,/ /' >$HOME/.ssh/allowed_signers
    end
end

# NVM - use fisher plugin (cleanest approach)
# Install with: fisher install jorgebucaran/nvm.fish
# This plugin handles lazy loading and .nvmrc detection automatically
# No manual configuration needed!

# Homebrew - load immediately (only ~15ms overhead, worth having available)
# Supports macOS Apple Silicon and Linux
if test -d /opt/homebrew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# Go lazy PATH addition
function go
    if not set -q GO_ADDED
        fish_add_path (command go env GOPATH)/bin
        set -gx GO_ADDED 1
    end
    command go $argv
end

# Rbenv - lazy load with official init
if test -d $HOME/.rbenv
    function rbenv
        if not set -q RBENV_LOADED
            command rbenv init - fish | source
            set -gx RBENV_LOADED 1
        end
        command rbenv $argv
    end
end

# Wezterm shell integration (enables Alt+click, semantic zones, etc.)
# Starship prompt - Load immediately (required for prompt)
# No type check - if missing, fish will show error and use default prompt
command -v starship >/dev/null 2>&1 && starship init fish | source

# Wezterm shell integration (fast, load immediately)
if test "$TERM_PROGRAM" = WezTerm
    set -l wezterm_integration $HOME/.local/bin/wezterm-shell-integration.sh
    if test -f $wezterm_integration
        source $wezterm_integration
    end
end

# Envman (if you use it)
if test -s $HOME/.config/envman/load.fish
    source $HOME/.config/envman/load.fish
end

# Lazy-load heavy tools on first use (saves 2+ seconds on startup!)
# Wrapper functions that load the real tool only when first called

# Zoxide - lazy load on first 'z' or 'zi' command
function z --description "zoxide lazy loader"
    functions --erase z zi
    command zoxide init fish | source
    z $argv
end

function zi --description "zoxide interactive lazy loader"
    functions --erase z zi
    command zoxide init fish | source
    zi $argv
end

# Carapace - load after first command (for completions)
function __carapace_delayed_load --on-event fish_postexec
    functions --erase __carapace_delayed_load
    command -v carapace >/dev/null 2>&1 && carapace _carapace fish | source
end

# fzf - Catppuccin Mocha colors with layout matching fzf.fish plugin defaults
set -gx fzf_preview_dir_cmd eza --all --color=always
set -Ux FZF_DEFAULT_OPTS "\
--height=50% \
--tmux bottom,40% \
--layout=reverse \
--border top \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
