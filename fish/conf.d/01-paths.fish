# Keep the managed path list in one place. Incremental `fish_add_path` calls write the
# universal $fish_user_paths, so removed entries and old ordering otherwise survive.
# Rebuild it on startup to keep the order deterministic and remove duplicate paths.
#
# Static list instead of globbing $HOME for bin dirs - that scan costs 200ms+ on every
# shell start.
set -l bin_dirs \
    $HOME/.local/share/mise/shims \
    $PNPM_HOME/bin \
    $HOME/.local/share/nvim/mason/bin \
    $HOME/.local/bin \
    /opt/homebrew/bin \
    /home/linuxbrew/.linuxbrew/bin \
    $PNPM_HOME \
    $HOME/.yarn/bin \
    $HOME/.rvm/bin \
    $HOME/.rd/bin \
    $HOME/.docker/bin \
    $HOME/.cargo/bin \
    $HOME/.atuin/bin \
    $HOME/go/bin \
    $HOME/.bun/bin \
    $HOME/.opencode/bin

set -l clean_bin_dirs
for dir in $bin_dirs
    if test -d $dir; and not contains -- $dir $clean_bin_dirs
        set -a clean_bin_dirs $dir
    end
end

set --universal fish_user_paths $clean_bin_dirs

# Drop stale inherited entries and mise's direct install directories. The shims are the
# single entry point, so redundant install paths cannot shadow anything else.
set -l clean_path
for dir in $PATH
    if not test -d $dir
        continue
    end
    if string match -q "$HOME/.local/share/mise/installs/*" -- $dir
        continue
    end
    if not contains -- $dir $clean_path
        set -a clean_path $dir
    end
end
set --global --export PATH $clean_path
