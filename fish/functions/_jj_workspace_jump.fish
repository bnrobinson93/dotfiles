function _jj_workspace_jump --argument-names suffix
    set -l root (jj workspace root 2>/dev/null)
    or begin
        echo "Not in a jj repository" >&2
        return 1
    end

    set -l base (basename $root)
    set -l change_id (jj log -r @ --no-graph -T 'change_id')
    set -l workspace_suffix_re '-(ai[0-9]*|exp|explore)$'

    if string match -qr -- "$workspace_suffix_re" $base
        set base (string replace -r -- "$workspace_suffix_re" '' $base)
    end

    set -l target_dir (dirname $root)/$base-$suffix

    if test "$target_dir" = "$root"
        echo "Already in $suffix workspace" >&2
        return 0
    end

    set -l original_dir "$PWD"

    if not test -d $target_dir
        jj workspace add $target_dir -r @
        or return 1
    else
        cd $target_dir
        jj edit $change_id
        or begin
            if set -q TMUX
                cd "$original_dir"
            end
            return 1
        end
    end

    if set -q TMUX
        cd "$original_dir"
        tmux new-window -c $target_dir -n $suffix "mise trust 2>/dev/null; $SHELL"
    else
        cd $target_dir
        mise trust 2>/dev/null
    end
end
