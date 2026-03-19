function _jj_workspace_jump --argument-names suffix
    if not jj workspace root >/dev/null 2>&1
        echo "Not in a jj repository" >&2
        return 1
    end

    set -l base (basename $PWD)

    # If already in a suffixed workspace, strip the suffix to get the original base
    if string match -qr -- '-(ai[0-9]*|exp|explore)$' $base
        set base (string replace -r -- '-(ai[0-9]*|exp|explore)$' '' $base)
    end

    set -l target_dir (dirname $PWD)/{$base}-{$suffix}

    if test "$target_dir" = "$PWD"
        echo "Already in $suffix workspace" >&2
        return 0
    end

    set -l change_id (jj log -r @ --no-graph -T 'change_id.shortest(8)')

    if not test -d $target_dir
        jj workspace add $target_dir
        or return 1
    end

    if set -q TMUX
        tmux new-window -c $target_dir -n $suffix "jj edit $change_id; mise trust 2>/dev/null; $SHELL"
    else
        cd $target_dir
        jj edit $change_id
        mise trust 2>/dev/null
    end
end
