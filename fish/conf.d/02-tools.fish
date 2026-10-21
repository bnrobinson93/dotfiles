if not status is-interactive
    exit
end

# WARN: with no agent socket, ssh-add still forks and fails — 5.5ms of every start.
if type -q ssh-add; and test -S "$SSH_AUTH_SOCK"
    ssh-add -q ~/.ssh/id_ed25519_GitHub ~/.ssh/id_ed25519_GitHubSigning 2>/dev/null
end

# `read`, not `cat`: the fork costs 1.1ms, the builtin 0.04ms.
if test -f ~/.config/gh/auth_token
    read -gx GH_TOKEN <~/.config/gh/auth_token
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

# atuin's init mints the session id with `atuin uuid`, which goes through a mise
# shim: 28ms against 4ms for the installed binary. atuin treats the id as an opaque
# string and skips minting when one is set for this SHLVL, so mirror its condition
# and hand it the kernel's. Darwin has no /proc and keeps the shim call.
if not set -q ATUIN_SESSION; or test "$ATUIN_SHLVL" != "$SHLVL"
    if test -r /proc/sys/kernel/random/uuid
        set -gx ATUIN_SESSION (string replace -a - "" </proc/sys/kernel/random/uuid)
        set -gx ATUIN_SHLVL $SHLVL
    end
end

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
# WARN: fzf exits 2 on a missing FZF_DEFAULT_OPTS_FILE, so unguarded this loses
# fzf itself on an unstowed machine, not just its theme.
test -f $HOME/.config/fzf/opts && set -gx FZF_DEFAULT_OPTS_FILE $HOME/.config/fzf/opts
