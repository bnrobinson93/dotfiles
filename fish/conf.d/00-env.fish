set -gx LANG en_US.UTF-8

if set -q SSH_CONNECTION
    if type -q vim
        set -gx EDITOR vim
    else
        set -gx EDITOR vi
    end
else
    set -gx EDITOR nvim
end

set -gx ZETTELKASTEN $HOME/Documents/Vault
set -gx BUN_INSTALL $HOME/.bun
set -gx PNPM_HOME $HOME/.local/share/pnpm
set -gx ANDROID_SDK $HOME/Android/sdk
set -gx KUBECONFIG $HOME/.kube/config
set -gx MISE_LOCKED 0

set -gx TRY_PATH $HOME/Documents/code/tries

set -gx HOMEBREW_AUTO_UPDATE_SECS (math 4 \* 60 \* 60)

# SSH signing (1Password); SSH auth stays scoped by ~/.ssh/config.
if test (uname) = Darwin; and not set -q USE_1PASSWORD_SSH
    set -gx USE_1PASSWORD_SSH 1
end
if test "$USE_1PASSWORD_SSH" = 1
    set -l onepassword_ssh_sock (ls -1 "$HOME/.1password/agent.sock" "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" 2>/dev/null | head -1)
    if test -S "$onepassword_ssh_sock"
        set -gx SSH_AUTH_SOCK "$onepassword_ssh_sock"
    end

    if type -q op; and not test -f $HOME/.ssh/allowed_signers
        op item get --vault Private "GitHub Signing" --fields email,public_key | sed 's/,/ /' >$HOME/.ssh/allowed_signers
    end
else
    # A socket inherited from a universal or parent var would defeat the opt-out.
    if set -q SSH_AUTH_SOCK; and string match -q '*/.1password/agent.sock' -- $SSH_AUTH_SOCK
        set -e SSH_AUTH_SOCK
    end
    if test (uname) = Darwin; and not set -q SSH_AUTH_SOCK
        set -l lsock (launchctl getenv SSH_AUTH_SOCK 2>/dev/null)
        if test -n "$lsock"
            set -gx SSH_AUTH_SOCK $lsock
        end
    end
end

# Nerd-font glyphs sit in private-use ranges; less escapes them without this.
set -gx LESSUTFCHARDEF "E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p"

set -gx BAT_THEME "Catppuccin Mocha"

# Uncached, `vivid generate` costs ~900ms per shell start. `read` rather than
# `cat` keeps the warm path fork-free.
set -l vivid_cache $HOME/.cache/fish/vivid-catppuccin-mocha.txt
__cache_gen $vivid_cache vivid vivid generate catppuccin-mocha
and read -gx LS_COLORS <$vivid_cache
and set -gx EZA_COLORS $LS_COLORS
