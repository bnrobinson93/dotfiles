# Tool Integrations - Simplified
# Fish has excellent native support for most tools - use their official init methods

# Starship prompt
if type -q starship
    starship init fish | source
end

# Atuin - shell history with sync
if type -q atuin
    fish_add_path $HOME/.atuin/bin
    atuin init fish --disable-up-arrow | source
end

# Zoxide - smart directory jumping
if type -q zoxide
    zoxide init fish | source
end

# Carapace - universal completion engine
# Note: Provides completions for 1000+ tools
if type -q carapace
    carapace _carapace fish | source
end

# JJ (Jujutsu) - native fish completion
if type -q jj
    jj util completion fish | source
end

# Kubectl - native fish completion
if type -q kubectl
    kubectl completion fish | source
end

# Go - add GOPATH/bin to PATH (no lazy loading needed)
if type -q go
    fish_add_path (go env GOPATH)/bin
end

# Rbenv - initialize immediately (fish handles this efficiently)
if type -q rbenv
    rbenv init - fish | source
end

# Homebrew - essential tool, load immediately
# Supports both macOS Apple Silicon and Linux
if test -d /opt/homebrew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# 1Password SSH signing setup (run once if needed)
if type -q op; and not test -f $HOME/.ssh/allowed_signers
    op item get --vault Private "GitHub Signing" --fields email,public_key | sed 's/,/ /' > $HOME/.ssh/allowed_signers
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
