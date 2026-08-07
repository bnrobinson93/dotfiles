#!/bin/bash
echo Installing programs...
if type apt >/dev/null; then
  sudo apt install -y git zsh fish ripgrep tmux stow curl wget jq
elif type pacman >/dev/null; then
  sudo pacman -S --noconfirm --needed git zsh fish ripgrep tmux stow curl wget jq
else
  echo "Couldn't detect package manager"
  echo "Please install \`git zsh fish ripgrep tmux stow curl wget jq\` manually and re-run this script."
fi

echo Ensuring we have the latest...
if type jj >/dev/null 2>&1; then
  jj git fetch
else
  git pull
fi

# Starship prompt
curl -sS https://starship.rs/install.sh | sh -s -- --yes

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
brew install lazygit asciinema agg jj mise gh jq topgrade dlvhdr/formulae/diffnav

echo "Installing neovim via brew (you will likely want to change this)"
brew install neovim

mkdir -p ~/.local ~/.config ~/.ssh ~/.config/hypr
pushd "$(dirname -- "$0")" || exit

echo Clearing install files to avoid stow conflicts...
for path in fish ghostty git kitty nvim mise tmux starship.toml; do
  rm -rf "$HOME/.config/$path"
done

echo Populating config and local scripts...
stow -v2 .
stow -v2 starship
stow -v2 -t ~/.local -S dot-local --dotfiles
stow -v2 -t ~ -S zsh --dotfiles
stow -v2 -t ~/.ssh -S dot-ssh --dotfiles

cp -pR hypr/* ~/.config/hypr/

echo "Installing fisher (fish plugin manager) and plugins..."
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fish -c "fisher install PatrickF1/fzf.fish edc/bass catppuccin/fish bnrobinson93/jj-agent"

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
brew install dust eza fd uutils-coreutils danielgatis/imgcat/imgcat hunk

echo "Deploying AI config and updating skills/plugins..."
"$PWD/update-skills.sh" || true

echo Installing Herdr...
curl -fsSL https://herdr.dev/install.sh | sh

if command -v herdr >/dev/null 2>&1; then
  herdr integration install claude
  herdr integration install codex
  herdr plugin install EzraCerpac/jj-waltz/plugins/herdr --yes # create/delete jj workspaces
  herdr plugin install mroth/herdr-jj-status                   # Show JJ branch
  herdr plugin install rjyo/herdr-window-title-sync --yes      # update term title to match location
  herdr plugin install third774/herdr-last-workspace --yes     # Go to previous workspace
  herdr plugin install aarsh21/herdr-tab-title                 # auto label tab by program
  herdr plugin install yuucu/herdr-hunk --yes                  # Open hunk for review
fi

if uname -a | grep -q "WSL"; then
  echo "Detected WSL, installing additional dependencies..."
  sudo apt install build-essential libssl-dev libffi-dev python3-dev
  sudo apt install python3-pip
  pip3 install --user neovim
fi

popd || true

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
