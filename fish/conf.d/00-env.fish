# Environment Variables
# Loaded first - sets up essential environment

# Locale
set -gx LANG en_US.UTF-8

# Editor
if set -q SSH_CONNECTION
    if type -q vim
        set -gx EDITOR vim
    else
        set -gx EDITOR vi
    end
else
    set -gx EDITOR nvim
end

# Essential exports
set -gx ZETTELKASTEN $HOME/Documents/Vault
set -gx BUN_INSTALL $HOME/.bun
set -gx PNPM_HOME $HOME/.local/share/pnpm
set -gx NVM_DIR $HOME/.nvm
set -gx ANDROID_SDK $HOME/Android/sdk

set -gx TRY_PATH $HOME/Documents/code/tries

# Homebrew auto-update (4 hours)
set -gx HOMEBREW_AUTO_UPDATE_SECS (math 4 \* 60 \* 60)

# SSH agent (1Password) - optional via USE_1PASSWORD_SSH
if set -q USE_1PASSWORD_SSH
    set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
end

# Fix jj pager for unicode
set -gx LESSUTFCHARDEF "E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p"

# Colors - Fish handles LS_COLORS well, but vivid provides better themes
# Cache vivid output to avoid 900ms startup delay on every shell
if type -q vivid
    set -l vivid_cache $HOME/.cache/fish/vivid-catppuccin-mocha.txt

    # Generate cache if missing or older than 7 days
    if not test -f $vivid_cache; or test (find $vivid_cache -mtime +7 2>/dev/null)
        mkdir -p (dirname $vivid_cache)
        vivid generate catppuccin-mocha >$vivid_cache
    end

    # Load from cache (instant)
    set -gx LS_COLORS (cat $vivid_cache)
    set -gx EZA_COLORS $LS_COLORS
end
