#!/bin/bash
echo Installing programs...
sudo apt install -y git zsh fish ripgrep tmux stow curl wget

echo Ensuring we have the latest...
if type jj >/dev/null 2>&1; then
  jj git fetch
else
  git pull
fi

# Starship prompt
curl -sS https://starship.rs/install.sh | sh

# Fabric
curl -fsSL https://raw.githubusercontent.com/danielmiessler/fabric/main/scripts/installer/install.sh | bash

# tmux plugins
mkdir -p ~/.config/tmux/plugins
if [[ ! -d ~/.config/tmux/plugins/tpm ]]; then
  echo Installing TPM for tmux...
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi

echo Installing homebrew...
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Put brew on PATH for this session
if test -d /home/linuxbrew/.linuxbrew; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif test -d /opt/homebrew; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo Installing brew libraries...
brew install lazygit asciinema agg jj mise gh dlvhdr/formulae/diffnav

echo "Installing neovim via brew (you will likely want to change this)"
brew install neovim

mkdir -p ~/.local ~/.config ~/.ssh ~/.claude
pushd "$HOME/.dotfiles" || exit

echo Clearing install files to avoid stow conflicts...
rm -rf "$HOME/.config/fish"

echo Populating config and local scripts...
stow -v2 .
stow -v2 -t ~/.local -S dot-local --dotfiles
stow -v2 -t ~ -S zsh gitmux --dotfiles
# stow 2.3.1 bug: can't traverse dot-prefixed dirs that exist as real dirs at target
# Manually symlink ai package contents
ln -sf "$HOME/.dotfiles/ai/dot-claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$HOME/.dotfiles/ai/dot-codex" "$HOME/.codex"
mkdir -p "$HOME/.config/opencode"
ln -sf "$HOME/.dotfiles/ai/dot-config/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
stow -v2 -t ~/.ssh -S dot-ssh --dotfiles

echo "Converting any PKCS#8 SSH keys to OpenSSH format..."
if [[ -x "$HOME/.local/bin/ssh-convert-openssh.sh" ]]; then
  failed_conversions=0
  for k in "$HOME"/.ssh/id_*; do
    [[ -f "$k" && "$k" != *.pub && "$k" != *.bak* ]] || continue
    grep -q "BEGIN PRIVATE KEY" "$k" 2>/dev/null || continue
    if ! "$HOME/.local/bin/ssh-convert-openssh.sh" "$k"; then
      echo "  Warning: failed to convert SSH key '$k'; please convert it manually if needed."
      failed_conversions=$((failed_conversions + 1))
    fi
  done
  if [[ "$failed_conversions" -gt 0 ]]; then
    echo "  Finished converting SSH keys with $failed_conversions failure(s). See warnings above for keys needing manual intervention."
  fi
else
  echo "  Hint: ssh-convert-openssh.sh not found; run it manually if signing fails."
fi

echo "Installing fisher (fish plugin manager) and plugins..."
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fish -c "fisher install PatrickF1/fzf.fish edc/bass catppuccin/fish"

echo "Installing tools configured in mise (e.g., Node.js, fzf)..."
if command -v mise >/dev/null 2>&1; then
  mise install

  git_excludes_file="$(git config --global --get core.excludesfile 2>/dev/null || true)"
  if [[ -n "$git_excludes_file" ]]; then
    git_excludes_file="${git_excludes_file/#\~/$HOME}"
    mkdir -p "$(dirname "$git_excludes_file")"
    if [[ ! -f "$git_excludes_file" ]] || ! grep -Fxq "mise.toml" "$git_excludes_file"; then
      echo "mise.toml" >>"$git_excludes_file"
    fi
  else
    echo "Git global excludes file is not configured; skipping ignore entry for mise.toml."
  fi
else
  echo "mise not found on PATH; skipping 'mise install'."
fi

chsh -s "$(which fish)"

echo Getting the nice to haves...
brew install dust eza fd uutils-coreutils

if uname -a | grep -q "WSL"; then
  echo "Detected WSL, installing additional dependencies..."
  sudo apt install build-essential libssl-dev libffi-dev python3-dev
  sudo apt install python3-pip
  pip3 install --user neovim
fi

popd || exit

# Authenticate with GitHub (required for SSH key upload and future gh usage)
if [[ "$XDG_CURRENT_DESKTOP" != "" ]] || uname -s | grep -q Darwin; then
  echo "Logging into GitHub..."
  gh auth login
fi

# Default SSH setup (no 1Password). Requires GitHub CLI (gh) if you want upload.
if [[ -x "$HOME/.local/bin/ssh-setup-github.sh" ]]; then
  echo "Setting up SSH keys for GitHub (you can skip/ctrl-c if undesired)..."
  "$HOME/.local/bin/ssh-setup-github.sh" -t "$(hostname)-$(date +%Y%m%d)" -e "${GIT_COMMITTER_EMAIL:-${EMAIL:-}}" || true
else
  echo "Hint: Use ~/.local/bin/ssh-setup-github.sh to create/upload keys to GitHub."
fi

echo "Set up Fabric? [Y/n] "
read -r choice
shopt -s nocasematch
if [[ "${choice}" != "n" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  fabric --setup
fi
shopt -u nocasematch
