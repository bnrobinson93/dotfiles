if not status is-interactive
    exit
end

set -l cache_dir $HOME/.cache/fish

# `starship init fish` emits a stub that re-runs starship through psub on every
# start. Without --print-full-init the cache holds that stub and buys nothing.
__cache_gen $cache_dir/starship-full-init.fish starship starship init fish --print-full-init
and source $cache_dir/starship-full-init.fish

# Shims instead of `activate`: activate runs `mise hook-env` at startup and on
# every prompt (~17ms a spawn). We use no mise [env] blocks, so nothing is lost.
fish_add_path $HOME/.local/share/mise/shims

__cache_gen $cache_dir/zoxide.fish zoxide zoxide init fish
and source $cache_dir/zoxide.fish

# Up-arrow stays fish's own history; atuin owns ctrl-r (see
# fish_user_key_bindings.fish).
__cache_gen $cache_dir/atuin.fish atuin atuin init fish --disable-up-arrow
and source $cache_dir/atuin.fish

# Generated onto fish_complete_path so fish autoloads them on first
# tab-complete instead of parsing them at startup.
set -g fish_complete_path $cache_dir/completions $fish_complete_path
# jj's dynamic shim (not `jj util completion`) completes aliases, revsets and
# bookmarks by invoking jj at tab time.
__cache_gen $cache_dir/completions/jj.fish jj env COMPLETE=fish jj
__cache_gen $cache_dir/completions/mise.fish mise mise completion fish

if test -d /opt/homebrew
    __cache_gen $cache_dir/brew.fish /opt/homebrew/bin/brew /opt/homebrew/bin/brew shellenv
    and source $cache_dir/brew.fish
else if test -d /home/linuxbrew/.linuxbrew
    __cache_gen $cache_dir/brew.fish /home/linuxbrew/.linuxbrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew shellenv
    and source $cache_dir/brew.fish
end

if test "$TERM_PROGRAM" = WezTerm
    set -l wezterm_integration $HOME/.local/bin/wezterm-shell-integration.sh
    if test -f $wezterm_integration
        source $wezterm_integration
    end
end

if test -s $HOME/.config/envman/load.fish
    source $HOME/.config/envman/load.fish
end

set -gx fzf_preview_dir_cmd eza --all --color=always
set -gx FZF_DEFAULT_OPTS "\
--height=50% \
--layout=reverse \
--border top \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
