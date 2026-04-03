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

# Zoxide - smart directory jumping (replaces cd)
if type -q zoxide
    zoxide init fish | source
end

# JJ (Jujutsu) completion
if type -q jj
    jj util completion fish | source
end

# Mise completions (requires usage CLI)
if type -q mise
    mise completion fish | source
end

# 1Password SSH signing setup
if set -q USE_1PASSWORD_SSH
    if type -q op; and not test -f $HOME/.ssh/allowed_signers
        op item get --vault Private "GitHub Signing" --fields email,public_key | sed 's/,/ /' >$HOME/.ssh/allowed_signers
    end
end

# Homebrew - load immediately (only ~15ms overhead, worth having available)
# Supports macOS Apple Silicon and Linux
if test -d /opt/homebrew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -d /home/linuxbrew/.linuxbrew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

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
