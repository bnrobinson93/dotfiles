# PERF: this runs on every shell start AND every cd, so the workspace root is a
# builtin walk-up to the nearest .jj marker rather than `jj workspace root` —
# that fork+exec cost ~40ms a call. dot-zshrc carries the same logic; a fix here
# needs the same fix there.
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
