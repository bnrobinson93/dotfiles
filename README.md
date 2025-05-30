# dotfiles

Contains all the dotfiles that I use in my development environment.

## Requirements

- git - `sudo apt install git`
- zsh - `sudo apt install zsh`
- starship - `curl -sS https://starship.rs/install.sh | sh `
- neovim - [See more](https://github.com/neovim/neovim/blob/master/INSTALL.md)
- fzf - `sudo apt install fzf`
- ripgrep - `sudo apt install ripgrep`
- lazygit - `brew install lazygit`
- tmux - `sudo apt install tmux`
- tpm - `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm `
- stow - `sudo apt install stow`
- Gitmux - `brew tap arl/arl && brew install gitmux`

## Usage

```sh
stow .
stow -t ~/.local -S dot-local --dotfiles
ln -s ./zsh/dot-zshrc ~/.zshrc
ln -s ./zsh/dot-zshenv ~/.zshenv
ln -s ./gitmux/dot-gitmux.conf ~/.gitmux.conf
tmux source-file ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf
chsh -s /bin/zsh
```

## Note for WSL

In WSL, the locale is not updated by default. Ensure it's updated to use UTF-8 and English.

Run the below, then restart the terminal/tmux session.

```sh
sudo apt-get install language-pack-en language-pack-en-base manpages
sudo update-locale LANG=en_US.UTF8
```
