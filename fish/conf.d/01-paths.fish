# Static list instead of globbing $HOME for bin dirs - that scan cost 200ms+
# on every shell start.
set -l common_bin_dirs \
    $HOME/go/bin \
    $HOME/.cargo/bin \
    $HOME/.docker/bin \
    $HOME/.rd/bin \
    $HOME/.yarn/bin

for dir in $common_bin_dirs
    test -d $dir && fish_add_path $dir
end

fish_add_path $PNPM_HOME/bin
fish_add_path $PNPM_HOME
fish_add_path $HOME/.bun/bin
fish_add_path $HOME/.local/bin

fish_add_path /opt/homebrew/bin
fish_add_path /home/linuxbrew/.linuxbrew/bin

fish_add_path $HOME/.opencode/bin
