# WARN: this list does not control $PATH. Bare `fish_add_path` writes the
# *universal* $fish_user_paths, so deleting a line here leaves the path on $PATH
# forever, and the order is whatever the machine's history produced.
#
# Static list instead of globbing $HOME for bin dirs - that scan cost 200ms+
# on every shell start. Later entries land ahead of earlier ones, and
# fish_add_path drops a directory that does not exist.
set -l bin_dirs \
    $HOME/go/bin \
    $HOME/.cargo/bin \
    $HOME/.docker/bin \
    $HOME/.rd/bin \
    $HOME/.yarn/bin \
    $PNPM_HOME/bin \
    $PNPM_HOME \
    $HOME/.bun/bin \
    $HOME/.local/bin \
    /opt/homebrew/bin \
    /home/linuxbrew/.linuxbrew/bin \
    $HOME/.opencode/bin

for dir in $bin_dirs
    fish_add_path $dir
end
