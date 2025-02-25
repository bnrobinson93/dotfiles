autoload -Uz compinit
if [[ -n $HOME/.cache/zsh/zcompdump-$ZSH_VERSION(#qN.mh+24) ]]; then
  compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
else
  compinit -C;
fi;

# Autostart tmux
# export TERM=xterm-256color
#if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ] && ! pstree -s $$ | grep -wqE 'code|language-server'; then
#  exec tmux
#fi

# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && \
  source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" || \
  zsh <(curl -s https://raw.githubusercontent.com/zap-zsh/zap/master/install.zsh) --branch release-v1
plug "zsh-users/zsh-autosuggestions"
#plug "zap-zsh/supercharge"
#plug "zap-zsh/zap-prompt"
plug "zsh-users/zsh-syntax-highlighting"
plug 'none9632/zsh-sudo'
plug 'lukechilds/zsh-nvm'
export NVM_LAZY_LOAD_EXTRA_COMMANDS=('tmux')
export NVM_LAZY_LOAD=true
export NVM_COMPLETION=true
export NVM_AUTO_USE=true

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Tab autocomplete is case-insensitive
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
ZSH_HIGHLIGHT_MAXLENGTH=300
setopt histignoredups
SAVEHIST=10000 # Number of entries
HISTSIZE=10000
HISTFILE=~/.history # File
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
setopt histignoredups
setopt APPEND_HISTORY # Don't erase history
setopt EXTENDED_HISTORY # Add additional data to history like timestamp
setopt INC_APPEND_HISTORY # Add immediately
setopt HIST_FIND_NO_DUPS # Don't show duplicates in search
setopt HIST_IGNORE_SPACE # Don't preserve spaces. You may want to turn it off
setopt NO_HIST_BEEP # Don't beep
setopt SHARE_HISTORY # Share history between session/terminals

# This speeds up pasting w/ autosuggest
# https://github.com/zsh-users/zsh-autosuggestions/issues/238
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

eval "$(starship init zsh)"

# User configuration
export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
 export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
   export EDITOR='nvim'
fi

prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
  fi
}

export ANDROID_SDK=$HOME/Android/Sdk
export PATH="~/.npm-global/bin:$ANDROID_SDK/platform-tools:$PATH"

grep="grep --color"
alias vi=$EDITOR

#unalias la
function la {
  if type "eza" >/dev/null 2>&1; then
    eza -la -h -smod $*
  else
    ls -larth $*
  fi
}

#unalias ll
function ll {
  if type "eza" >/dev/null 2>&1; then
    eza -l -h -smod $*
  else
    ls -lrth $*
  fi
}

function lt {
  if type "eza" >/dev/null 2>&1; then
    eza -l -h -smod $* | tail -15
  else
    ls -larth $*
  fi
}

function lss {
  if type "eza" >/dev/null 2>&1; then
    eza -l -h -smod $* | less -reXF
  else
    ls -lrth $* | less -erXF
  fi
}

function l {
  if type "eza" >/dev/null 2>&1; then
    eza -lah -smod --icons --git $*
  else
    ls -ltrha $*
  fi
}

if type "eza" >/dev/null 2>&1; then
  alias ls="eza"
else
  ls="ls --color=tty"
fi

if type "bat" >/dev/null 2>&1; then
  alias cat="bat"
fi
if type "nala" >/dev/null 2>&1; then
  alias sudo='sudo '
  alias apt="nala"
fi
if type "pacstall" >/dev/null 2>&1; then
  autoload bashcompinit
  bashcompinit
  source /usr/share/bash-completion/completions/pacstall
fi

if type "kubectl" >/dev/null 2>&1; then
  kubectl () {
      command kubectl $*
      if [[ -z $KUBECTL_COMPLETE ]]
      then
          source <(command kubectl completion zsh)
          KUBECTL_COMPLETE=1 
      fi
  }
  alias k=kubectl
  alias kgp="kubectl get pods"
fi

# Homebrew
if test -d /home/linuxbrew >/dev/null 2>&1; then
  brew () {
      if [[ -z $BREW_COMPLETE ]]
      then
        test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)" 
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        BREW_COMPLETE=1 
      fi
      command brew $*
  }
  export HOMEBREW_AUTO_UPDATE_SECS=$((60 * 60 * 24))
fi

# Fix issue with apt <thing>* not working
unsetopt no_match

# pnpm
export PNPM_HOME="/home/brad/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# add Pulumi to the PATH
export PATH="$HOME/.pulumi/bin:$PATH"

# bun completions
[ -s "/home/brad/.bun/_bun" ] && source "/home/brad/.bun/_bun"

export ZETTELKASTEN=$HOME/Documents/Vault

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Flatpak
export PATH="$HOME/.local/bin:$PATH"

# auto-cpufreq
which auto-cpufreq >/dev/null && eval "$(_AUTO_CPUFREQ_COMPLETE=zsh_source auto-cpufreq)"

# The following lines were added by compinstall
zstyle :compinstall filename '/home/brad/.zshrc'
# End of lines added by compinstall

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/home/brad/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

if [[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh ]]; then
  source ${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh
fi
