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

# Homebrew auto-update (4 hours)
set -gx HOMEBREW_AUTO_UPDATE_SECS (math 4 \* 60 \* 60)

# SSH agent (1Password)
set -gx SSH_AUTH_SOCK ~/.1password/agent.sock

# Fix jj pager for unicode
set -gx LESSUTFCHARDEF "E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p"

# Colors - Fish handles LS_COLORS well, but vivid provides better themes
if type -q vivid
    set -gx LS_COLORS (vivid generate catppuccin-mocha)
    set -gx EZA_COLORS $LS_COLORS
end
