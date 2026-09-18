# Fast-path reimplementation of jj-agent's _jj_workspace_sync_git_env: that
# plugin function shells out to `jj workspace root` unconditionally, which
# cost ~40ms per fork+exec on the zsh side (see dot-zshrc's own copy of this
# function) and runs here on every shell start AND every cd. Walk up for the
# nearest .jj marker with builtins instead, mirroring dot-zshrc's fix.
function __jj_workspace_sync_git_env_fast
    set -l dir $PWD
    while test "$dir" != /; and not test -e "$dir/.jj"
        set dir (path dirname $dir)
    end
    if not test -e "$dir/.jj"
        set -e GIT_DIR
        return 0
    end

    set -l workspace_root $dir
    set -l workspace_base (path basename $workspace_root)
    if not string match -qr -- '-(ai[0-9]*|exp|explore)$' $workspace_base
        set -e GIT_DIR
        return 0
    end

    set -l main_base (string replace -r -- '-(ai[0-9]+|exp|explore)$' '' $workspace_base)
    set -l main_root (path dirname $workspace_root)/$main_base
    set -l git_dir $main_root/.git
    if test -e $git_dir
        set -gx GIT_DIR $git_dir
    else
        set -e GIT_DIR
    end
end

if status is-interactive
    function __jj_workspace_sync_git_env_on_pwd --on-variable PWD
        __jj_workspace_sync_git_env_fast
    end

    __jj_workspace_sync_git_env_fast
end
