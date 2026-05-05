function __ghpr_completion_in_jj_repo
    type -q jj; and jj workspace root >/dev/null 2>&1
end

function __ghpr_completion_bookmark_names
    if not __ghpr_completion_in_jj_repo
        return
    end

    jj bookmark list 2>/dev/null | string replace -r ':.*$' ''
end

function __ghpr_completion_recent_revisions
    if not __ghpr_completion_in_jj_repo
        return
    end

    jj log -r 'recent()' -T 'change_id.shortest(8) ++ "\t" ++ description.first_line() ++ "\n"' --no-graph 2>/dev/null | head -n 20
end

complete -c ghpr -f
complete -c ghpr -s d -l draft -d "Create draft PR"
complete -c ghpr -l dry-run -d "Preview PR without creating it"
complete -c ghpr -s B -l base -d "Override base branch" -r
complete -c ghpr -s t -l title -d "Override PR title" -r
complete -c ghpr -s b -l bookmark -x -d "Use JJ bookmark" -a '(__ghpr_completion_bookmark_names)'
complete -c ghpr -s r -l revision -x -d "Resolve bookmark from JJ revision" -a '(__ghpr_completion_recent_revisions)'
