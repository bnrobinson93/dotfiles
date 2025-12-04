# Tool Integrations
# Sets up modern CLI tools and their configurations

# Starship prompt (fish handles this efficiently with psub)
if type -q starship
    starship init fish | source
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
if type -q op; and not test -f $HOME/.ssh/allowed_signers
    op item get --vault Private "GitHub Signing" --fields email,public_key | sed 's/,/ /' > $HOME/.ssh/allowed_signers
end

# NVM - use fisher plugin (cleanest approach)
# Install with: fisher install jorgebucaran/nvm.fish
# This plugin handles lazy loading and .nvmrc detection automatically
# No manual configuration needed!

# Homebrew - lazy load with official shellenv
function brew
    if not set -q BREW_LOADED
        if test -d /opt/homebrew
            eval (/opt/homebrew/bin/brew shellenv)
        else if test -d /home/linuxbrew/.linuxbrew
            eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
        end
        set -gx BREW_LOADED 1
    end
    command brew $argv
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
if test "$TERM_PROGRAM" = "WezTerm"
    set -l wezterm_integration $HOME/.local/bin/wezterm-shell-integration.fish
    if test -f $wezterm_integration
        source $wezterm_integration
    end
end

# Envman (if you use it)
if test -s $HOME/.config/envman/load.fish
    source $HOME/.config/envman/load.fish
end
