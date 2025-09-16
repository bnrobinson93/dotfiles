# dotfiles

Contains all the dotfiles that I use in my development environment.

## Install Tools - Requirements

- git - `sudo apt install git`
- zsh - `sudo apt install zsh`
- carapace - `brew install carapace`
- bat - `brew install bat`
- starship - `curl -sS https://starship.rs/install.sh | sh`
- neovim - [See more](https://github.com/neovim/neovim/blob/master/INSTALL.md)
- fzf - `sudo apt install fzf`
- Atuin - `curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh`
- ripgrep - `sudo apt install ripgrep`
- lazygit - `brew install lazygit`
- tmux - `sudo apt install tmux`
- tpm - `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`
- stow - `sudo apt install stow`
- Gitmux - `brew tap arl/arl && brew install gitmux`
- Asciinema - `brew install asciinema agg`
- Zoxide - `brew install zoxide`

## Other niceties

<details>
  <summary>Click here...</summary>

### Pacstall

`sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install)"`

- noisetorch-bin
- pacup
- zen-browser-bin

### Snap

```sh
sudo snap install nvim
sudo snap install raindrop
sudo snap install ticktick
```

### Flatpak

The following are Flatpak application names. You can install them using the `flatpak install` command. For example:

```sh
flatpak install flathub com.discordapp.DiscordCanary
flatpak install flathub org.tlpui.TLPUI
flatpak install flathub com.github.GradienceTeam.Touché
flatpak install flathub com.github.tchx84.Flatseal
flatpak install flathub com.spotify.Client
flatpak install flathub com.transmissionbt.Transmission
flatpak install flathub com.visualstudio.code
flatpak install flathub bibletime.BibleTime
flatpak install flathub io.github.seadve.Kooha
flatpak install flathub com.github.smile
flatpak install flathub org.blender.Blender
flatpak install flathub org.darktable.Darktable
flatpak install flathub org.gimp.GIMP
flatpak install flathub org.gtk.Gtk3theme.WhiteSur-dark
flatpak install flathub org.gtk.Gtk3theme.WhiteSur-dark-solid
flatpak install flathub org.kde.kdenlive
flatpak install flathub org.kde.krita
flatpak install flathub us.zoom.Zoom
### Brew

```sh
brew install dust fd eza dua-cli ripgrep
brew install python
brew install unzip
brew install glow
brew install jj lazygit
brew install zizmor
brew install pandoc
brew install sqlite
brew install k9s helm age agg
```

</details>

## Usage

```sh
stow -v2 .
stow -v2 -t ~/.local -S dot-local --dotfiles
stow -v2 -t ~ -S zsh gitmux --dotfiles
chsh -s /bin/zsh
tmux source-file ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf
bat cache --build
```

## Note for WSL

In WSL, the locale is not updated by default. Ensure it's updated to use UTF-8 and English.

Run the below, then restart the terminal/tmux session.

```sh
sudo apt-get install language-pack-en language-pack-en-base manpages
sudo update-locale LANG=en_US.UTF8
```

# Recording

```sh
asciinema rec demo.cast
agg --theme nord --font-size 16 --font-family "DankMono Nerd Font" demo.cast ~/Pictures/demo.gif && rm demo.cast
```

![demo](./resources/record-demo.gif)
