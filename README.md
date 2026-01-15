# dotfiles

Contains all the dotfiles that I use in my development environment.

## Install Tools - Requirements

- git - `sudo apt install git`
- **Shell** (choose one):
  - zsh - `sudo apt install zsh`
  - fish - `sudo apt install fish` (modern alternative, 4-10x faster startup)
- carapace - `brew install carapace`
- bat - `brew install bat`
- starship - `curl -sS https://starship.rs/install.sh | sh`
- neovim - [See more](https://github.com/neovim/neovim/blob/master/INSTALL.md)
  - Make sure to install tree sitter CLI: `brew install tree-sitter-cli`
  - Make sure you have a C compiler
  - Make sure that `npm` or similar is installed
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

## SSH, Signing, and 1Password

This repo defaults to OpenSSH agent + (on macOS) Keychain, with SSH commit signing for both Git and JJ.

- Default agent: system ssh-agent (macOS Keychain, Linux desktop keyring)
- Optional 1Password agent: set `USE_1PASSWORD_SSH=1` to route via 1Password

Files and scripts:

- dot-ssh/config — stowable SSH config enabling AddKeysToAgent, UseKeychain, and IdentityFile defaults
- git/config — enables SSH signing in Git with ssh-keygen + allowed_signers
- jj/config.toml — uses `ssh-sign-wrapper.sh` for signing; defaults to ssh-keygen unless `USE_1PASSWORD_SSH=1`
- dot-local/bin/ssh-setup-github.sh — create/load key and upload to GitHub via `gh`
- dot-local/bin/op-ssh-migrate.sh — migrate key(s) from 1Password to ~/.ssh and agent/keychain

macOS Keychain setup (recommended)

- ~/.ssh/config (stowed) contains:
  - AddKeysToAgent yes
  - UseKeychain yes
  - IdentityFile ~/.ssh/id_ed25519_GitHub
  - IdentityFile ~/.ssh/id_ed25519_GitHubSigning
- Remove any IdentityAgent pointing to 1Password if present in your personal ~/.ssh/config
- Add keys to Keychain once:
  - `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_GitHub`
  - `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_GitHubSigning`

Linux agent/keyring

- Ensure a user ssh-agent is running (desktop sessions do by default). The migration script adds to the agent.
- For persistence across logins without a desktop keyring, use a systemd user unit or a helper like `keychain`.

Signing trust (allowed_signers)

- Git/JJ verify signatures using `~/.ssh/allowed_signers`
- Format: `email@example.com ssh-ed25519 AAAA...`
- Populate automatically via migration script (using 1Password item’s email field) or manually append.

Using 1Password optionally

- Set `USE_1PASSWORD_SSH=1` to use 1Password agent and signing.
- Unset to use system agent/Keychain.

Verification

- SSH: `ssh -T git@github.com`
- Git: `git commit --allow-empty -m test && git log -1 --show-signature`
- JJ: `jj git push -c@` (see signature indicators in templates)

## Other niceties

<details>
  <summary>Click here...</summary>

```sh
brew install node
```

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

You can install these applications from [Flathub](https://flathub.org/). Example installation commands:

````sh
flatpak install flathub com.discordapp.DiscordCanary
flatpak install flathub com.github.d4nj1.tlpui
flatpak install flathub com.github.touchegg.touche
flatpak install flathub com.github.tchx84.Flatseal
flatpak install flathub com.spotify.Client
flatpak install flathub com.transmissionbt.Transmission
flatpak install flathub com.visualstudio.code
flatpak install flathub org.bibletime.BibleTime
flatpak install flathub io.github.seadve.Kooha
flatpak install flathub it.mijorus.smile
flatpak install flathub org.blender.Blender
flatpak install flathub org.darktable.Darktable
flatpak install flathub org.gimp.GIMP
flatpak install flathub org.kde.Kdenlive
flatpak install flathub org.kde.krita
flatpak install flathub us.zoom.Zoom
# For GTK themes:
flatpak install flathub org.gtk.Gtk3theme.WhiteSur-dark
flatpak install flathub org.gtk.Gtk3theme.WhiteSur-dark-solid
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
````

</details>

## Usage

````sh
# Deploy all configs to ~/.config (includes fish, nvim, tmux, wezterm, etc.)
stow -v2 .

# Starship prompt
stow -v2 starship

# Deploy local scripts to ~/.local/bin
stow -v2 -t ~/.local -S dot-local --dotfiles

# Deploy shell config (choose one):

# Option 1: Zsh (traditional)
stow -v2 -t ~ -S zsh gitmux --dotfiles
stow -v2 -t ~/.ssh -S dot-ssh --dotfiles
chsh -s /bin/zsh

# Option 2: Fish (modern, faster)
# Fish config already deployed via 'stow -v2 .' above
# Install fisher plugin manager:
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
# Install NVM for fish:
fisher install jorgebucaran/nvm.fish
# Set as default shell:
chsh -s $(which fish)

# Finalize setup (either shell)
stow -v2 -t ~ -S gitmux --dotfiles
tmux source-file ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf
bat cache --build

### Default SSH key setup (no 1Password)

Uses `ssh-setup-github.sh` to create or load a key and upload to GitHub (via gh):

```sh
~/.local/bin/ssh-setup-github.sh -t "$(hostname)-$(date +%Y%m%d)" -e "you@example.com"
````

If you already store keys in 1Password and want to migrate them locally and add to the agent/keychain:

```sh
~/.local/bin/op-ssh-migrate.sh "GitHub" "GitHub Signing"
```

Temporarily use 1Password agent for this shell session:

```sh
export USE_1PASSWORD_SSH=1  # zsh/bash
# or: set -Ux USE_1PASSWORD_SSH 1  # fish
```

````

## Note for WSL

In WSL, the locale is not updated by default. Ensure it's updated to use UTF-8 and English.

Run the below, then restart the terminal/tmux session.

```sh
sudo apt-get install language-pack-en language-pack-en-base manpages
sudo update-locale LANG=en_US.UTF8
````

# Recording

```sh
asciinema rec demo.cast
agg --theme nord --font-size 16 --font-family "DankMono Nerd Font" demo.cast ~/Pictures/demo.gif && rm demo.cast
```

![demo](./resources/record-demo.gif)

```

```
