# Tool Integrations - Optimized for Fast Startup
# Only load in interactive shells
if not status is-interactive
    exit
end

# Regenerate a cached script only when the tool's binary is newer than the
# cache (i.e. after an upgrade). Avoids re-spawning every tool each shell
# start — `X init | source` for starship/mise/zoxide/jj cost ~125ms combined.
function __cache_gen
    # __cache_gen <cache-file> <tool-or-path> <command to generate it...>
    set -l cache $argv[1]
    set -l bin (command -v $argv[2]); or return 1
    if not test -f $cache; or test $bin -nt $cache
        mkdir -p (dirname $cache)
        $argv[3..] >$cache 2>/dev/null
    end
end

set -l cache_dir $HOME/.cache/fish

# Starship prompt
__cache_gen $cache_dir/starship.fish starship starship init fish
and source $cache_dir/starship.fish

# Mise - shims instead of `activate`: activate runs `mise hook-env` at startup
# AND every prompt (~17ms spawn each time); shims resolve tools at exec time
# with zero shell overhead. We use no mise [env] blocks, so nothing is lost.
# Revert if needed: mise activate fish | source
fish_add_path $HOME/.local/share/mise/shims

# Zoxide - smart directory jumping (replaces cd)
__cache_gen $cache_dir/zoxide.fish zoxide zoxide init fish
and source $cache_dir/zoxide.fish

# Completions (jj, mise): generated into a dir on fish_complete_path so fish
# autoloads them on first tab-complete instead of parsing them at startup.
set -g fish_complete_path $cache_dir/completions $fish_complete_path
# jj: the dynamic shim (not `jj util completion`) — completes aliases,
# revsets, and bookmarks by invoking jj at tab time.
__cache_gen $cache_dir/completions/jj.fish jj env COMPLETE=fish jj
__cache_gen $cache_dir/completions/mise.fish mise mise completion fish

# 1Password SSH signing setup
if set -q USE_1PASSWORD_SSH
    if type -q op; and not test -f $HOME/.ssh/allowed_signers
        op item get --vault Private "GitHub Signing" --fields email,public_key | sed 's/,/ /' >$HOME/.ssh/allowed_signers
    end
end

# Homebrew - shellenv output is static, cache it like the rest
# Supports macOS Apple Silicon and Linux
if test -d /opt/homebrew
    __cache_gen $cache_dir/brew.fish /opt/homebrew/bin/brew /opt/homebrew/bin/brew shellenv
    and source $cache_dir/brew.fish
else if test -d /home/linuxbrew/.linuxbrew
    __cache_gen $cache_dir/brew.fish /home/linuxbrew/.linuxbrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew shellenv
    and source $cache_dir/brew.fish
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
set -gx FZF_DEFAULT_OPTS "\
--height=50% \
--tmux bottom,40% \
--layout=reverse \
--border top \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
