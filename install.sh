#!/bin/bash
echo Installing programs...
sudo apt install -y git zsh fish fzf ripgrep tmux stow curl wget

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

echo "Installing atuin (history replacement)"
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

echo Installing brew libraries...
brew install carapace lazygit asciinema agg jj mise gh dlvhdr/formulae/diffnav

echo "Installing neovim via brew (you will likely want to change this)"
brew install neovim

mkdir -p ~/.local ~/.config ~/.ssh
pushd "$HOME/.dotfiles" || exit

echo Clearing install files to avoid stow conflicts...
rm -rf "$HOME/.config/atuin" "$HOME/.config/fish"

echo Populating config and local scripts...
stow -v2 .
stow -v2 -t ~/.local -S dot-local --dotfiles
stow -v2 -t ~ -S zsh gitmux ai --dotfiles
stow -v2 -t ~/.ssh -S dot-ssh --dotfiles

echo "Installing tools configured in mise (e.g., Node.js)..."
if command -v mise >/dev/null 2>&1; then
  mise install
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
