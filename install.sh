#!/bin/bash
echo Installing programs...
if type apt >/dev/null; then
  sudo apt install -y git zsh fish ripgrep tmux stow curl wget pipx jq
elif type pacman >/dev/null; then
  sudo pacman -S --noconfirm --needed git zsh fish ripgrep tmux stow curl wget python-pipx jq
else
  echo "Couldn't detect package manager"
  echo "Please install \`git zsh fish ripgrep tmux stow curl wget pipx jq\` manually and re-run this script."
fi

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
brew install lazygit asciinema agg jj mise gh pipx jq dlvhdr/formulae/diffnav

echo "Installing neovim via brew (you will likely want to change this)"
brew install neovim

mkdir -p ~/.local ~/.config ~/.ssh ~/.config/hypr ~/.claude ~/.codex ~/.config/opencode
pushd "$(dirname -- "$0")" || exit

find_superclaude_bin() {
  if command -v superclaude >/dev/null 2>&1; then
    command -v superclaude
    return 0
  fi

  local pipx_bin_dir="${PIPX_BIN_DIR:-}"
  if [[ -z "$pipx_bin_dir" ]] && command -v pipx >/dev/null 2>&1; then
    pipx_bin_dir="$(pipx environment --value PIPX_BIN_DIR 2>/dev/null || true)"
  fi

  local candidate_dir=""
  for candidate_dir in "$pipx_bin_dir" "$HOME/.local/bin"; do
    if [[ -n "$candidate_dir" && -x "$candidate_dir/superclaude" ]]; then
      printf '%s\n' "$candidate_dir/superclaude"
      return 0
    fi
  done

  return 1
}

backup_conflicting_ai_entrypoint() {
  local target="$1"
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return 0
  fi

  local backup_target="${target}.pre-dotfiles.$(date +%Y%m%d%H%M%S).bak"
  echo "Backing up existing $(basename "$target") to $backup_target"
  mv "$target" "$backup_target"
}

if superclaude_bin="$(find_superclaude_bin)"; then
  :
else
  echo "Installing SuperClaude CLI with pipx..."
  pipx ensurepath || true
  if pipx install superclaude || pipx upgrade superclaude; then
    superclaude_bin="$(find_superclaude_bin || true)"
  else
    superclaude_bin=""
    echo "Warning: SuperClaude CLI install failed; continuing with dotfiles setup."
  fi
fi

if [[ -n "${superclaude_bin:-}" ]]; then
  echo "Installing SuperClaude into ~/.claude..."
  if ! "$superclaude_bin" install; then
    echo "Warning: SuperClaude install failed; continuing with dotfiles setup."
  fi

  echo "Verifying SuperClaude installation..."
  "$superclaude_bin" install --list || true
  "$superclaude_bin" doctor || true

  if [[ -t 0 ]]; then
    echo "Install SuperClaude MCP servers? [y/N] "
    read -r superclaude_mcp_choice
    shopt -s nocasematch
    if [[ "${superclaude_mcp_choice}" == "y" ]]; then
      "$superclaude_bin" mcp --list || true
      "$superclaude_bin" mcp || true
    fi
    shopt -u nocasematch
  else
    echo "Non-interactive shell detected; skipping optional SuperClaude MCP setup."
  fi
else
  echo "SuperClaude CLI not found after pipx step; skipping SuperClaude setup."
fi

echo Clearing install files to avoid stow conflicts...
for path in alacritty fish ghostty git kitty nvim mise tmux starship.toml; do
  rm -rf "$HOME/.config/$path"
done

echo "Removing previously stowed AI instruction links..."
stow -D -t ~/.claude ai 2>/dev/null || true
stow -D -t ~/.codex ai 2>/dev/null || true
stow -D -t ~/.config/opencode ai 2>/dev/null || true

echo "Backing up conflicting Claude entrypoints before restowing..."
backup_conflicting_ai_entrypoint "$HOME/.claude/AGENTS.md"
backup_conflicting_ai_entrypoint "$HOME/.claude/CLAUDE.md"

echo Populating config and local scripts...
stow -v2 .
stow -v2 starship
stow -v2 -t ~/.local -S dot-local --dotfiles
stow -v2 -t ~ -S zsh gitmux --dotfiles
stow -v2 -t ~/.claude ai
stow -v2 -t ~/.codex ai
stow -v2 -t ~/.config/opencode ai
stow -v2 -t ~/.ssh -S dot-ssh --dotfiles

cp -pR hypr/* ~/.config/hypr/

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

echo Installing Herdr...
curl -fsSL https://herdr.dev/install.sh | sh

if command -v herdr >/dev/null 2>&1; then
  herdr integration install claude
  herdr integration install codex
  herdr plugin install NathanFlurry/herdr-plugin-jj-workspace --yes
  herdr plugin install rjyo/herdr-window-title-sync --yes
  herdr plugin install third774/herdr-last-workspace --yes
  herdr plugin install Newt6611/herdr-tab-title --yes
  herdr plugin install scott306lr/herdr-plugin-hunk-autodiff --yes
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

echo "Set up Fabric? [Y/n] "
read -r choice
shopt -s nocasematch
if [[ "${choice}" != "n" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  fabric --setup
fi
shopt -u nocasematch
