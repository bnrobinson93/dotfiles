# dotfiles

Contains all the dotfiles that I use in my development environment.

## Install Tools - Requirements

- git - `sudo apt install git`
- **Shell** (choose one):
  - zsh - `sudo apt install zsh`
  - fish - `sudo apt install fish` (modern alternative, ~2x faster startup)
- bat - `brew install bat`
- starship - `curl -sS https://starship.rs/install.sh | sh`
- neovim - [See more](https://github.com/neovim/neovim/blob/master/INSTALL.md)
  - Make sure to install tree sitter CLI: `brew install tree-sitter-cli`
  - Make sure you have a C compiler
  - Make sure that `npm` or similar is installed
- fzf - `sudo apt install fzf`
- jq - `sudo apt install jq`
- ripgrep - `sudo apt install ripgrep`
- lazygit - `brew install lazygit`
- tmux - `sudo apt install tmux`
- tpm - `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`
- stow - `sudo apt install stow`
- Asciinema - `brew install asciinema agg`
- Zoxide - `brew install zoxide`
- mise - `brew install mise` (runtimes + task runner: `mise tasks`)
- topgrade - `brew install topgrade` (one-command updater for everything)
- sesh - `brew install joshmedeski/sesh/sesh`
- herdr - `brew install herdr`

## SSH & Commit Signing

Two modes, switched per machine. The repo default is plain on-disk keys.

**On-disk keys — default.** `~/.ssh/id_ed25519_GitHub` (auth) and
`~/.ssh/id_ed25519_GitHubSigning` (signing). Git and JJ sign directly with
stock `ssh-keygen` — no agent, no wrapper, no prompts. `~/.ssh/config` (stowed from
dot-ssh/) prefers the key files and disables the agent when they exist.

**1Password-managed keys — per-machine override.** `~/.ssh/config` routes
connections through the 1Password agent when no key files are present. Signing
overrides go in gitignored local files:

- Git — `~/.gitlocal`:

  ```ini
  [user]
    signingkey = ssh-ed25519 AAAA...   ; pubkey from 1Password
  [gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
  ```

- JJ — `~/.config/jj/conf.d/z-local.toml`:

  ```toml
  signing.key = "ssh-ed25519 AAAA..."
  signing.backends.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  ```

**New machine**: `ssh-setup-github.sh -t "$(hostname)" -e you@example.com` generates a
key, uploads it to GitHub via `gh`, and updates `~/.ssh/allowed_signers`
(format: `email ssh-ed25519 AAAA...` — both Git and JJ verify against it).

**Verify**: `ssh -T git@github.com` · `git log -1 --show-signature` ·
`jj log -r @ -T 'signature.status()'` (expect `good`)

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

Day-to-day, mise tasks cover the common operations from anywhere:

```sh
mise run stow     # deploy all symlinks (config, ~/.local, zsh, ai, ssh)
mise run skills   # install/update AI skills & plugins (update-skills.sh)
mise run update   # update everything via topgrade
```

Manual equivalents:

````sh
# Deploy all configs to ~/.config (includes fish, nvim, tmux, wezterm, etc.)
stow -v2 .

# Starship prompt
stow -v2 starship

# Deploy local scripts to ~/.local/bin
stow -v2 -t ~/.local -S dot-local --dotfiles

# Deploy shell config (choose one):

# Option 1: Zsh (traditional)
stow -v2 -t ~ -S zsh --dotfiles
stow -v2 -t ~/.ssh -S dot-ssh --dotfiles
chsh -s /bin/zsh

# Option 2: Fish (modern, faster)
# Fish config already deployed via 'stow -v2 .' above
# Install fisher plugin manager:
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
# Install fish plugins (node/go/etc come from mise, not nvm):
fisher install PatrickF1/fzf.fish edc/bass catppuccin/fish bnrobinson93/jj-agent
# Set as default shell:
chsh -s $(which fish)

# Finalize setup (either shell)
tmux source-file ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf
bat cache --build

# Shared AI instruction files (either shell)
# Remove previously stowed AI links before restowing
stow -D -t ~/.claude ai || true
stow -D -t ~/.codex ai || true
stow -D -t ~/.config/opencode ai || true

# Back up conflicting Claude entrypoints before restowing
mv ~/.claude/AGENTS.md ~/.claude/AGENTS.md.pre-dotfiles.$(date +%Y%m%d%H%M%S).bak 2>/dev/null || true
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.pre-dotfiles.$(date +%Y%m%d%H%M%S).bak 2>/dev/null || true

stow -v2 -t ~/.claude ai
stow -v2 -t ~/.codex ai
stow -v2 -t ~/.config/opencode ai

# Update agent skills/plugins
update-skills.sh
# Optional: TEACH_SKILL_SOURCE=owner/repo update-skills.sh

### Default SSH key setup (no 1Password)

Uses `ssh-setup-github.sh` to create or load a key and upload to GitHub (via gh):

```sh
~/.local/bin/ssh-setup-github.sh -t "$(hostname)-$(date +%Y%m%d)" -e "you@example.com"
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
