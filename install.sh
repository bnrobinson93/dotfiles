#!/bin/bash

echo Installing programs...
sudo apt install git zsh fzf ripgrep tmux stow curl wget nodejs
curl -sS https://starship.rs/install.sh | sh

echo Installing TPM for tmux...
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

echo Installing homebrew...
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Instlaling atuin (history replacement)"
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

echo Installing brew libraries...
brew install carapace lazygit asciinema agg

echo "Installing neovim via brew (you will likely want to change this)"
brew install neovim

pushd "$HOME/.dotfiles" || exit
mkdir ~/.local ~/.config

echo Populating config and local scripts...
stow -v2 .
stow -v2 -t ~/.local -S dot-local --dotfiles
stow -v2 -t ~ -S zsh gitmux --dotfiles
chsh -s "$(which zsh)"

if uname -a | grep -q "WSL"; then
  echo "Detected WSL, installing additional dependencies..."
  sudo apt install build-essential libssl-dev libffi-dev python3-dev
  sudo apt install python3-pip
  pip3 install --user neovim
fi

popd || exit

echo "Done. Please restart your terminal or run 'source ~/.zshrc' to apply changes."
