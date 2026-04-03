# PATH Configuration
# Fish uses fish_add_path which automatically deduplicates and handles PATH correctly

# Find all bin directories - optimized to avoid 200ms+ glob scanning
# Only scan common locations instead of using expensive wildcards

set -l common_bin_dirs \
    $HOME/go/bin \
    $HOME/.cargo/bin \
    $HOME/.docker/bin \
    $HOME/.rd/bin \
    $HOME/.rvm/bin \
    $HOME/.yarn/bin

for dir in $common_bin_dirs
    test -d $dir && fish_add_path $dir
end

# Essential paths
fish_add_path $PNPM_HOME
fish_add_path $HOME/.bun/bin
fish_add_path $HOME/.local/bin

# Homebrew paths
fish_add_path /opt/homebrew/bin
fish_add_path /home/linuxbrew/.linuxbrew/bin

# opencode
fish_add_path /home/brad/.opencode/bin
