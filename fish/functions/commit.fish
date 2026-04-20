# AI-generated commit message using opencode, then commits via git or jj

function commit --description "AI-generated commit message"
    argparse d/dry-run 'm/message=' -- $argv
    or return 1

    set -l dry_run false
    if set -q _flag_dry_run
        set dry_run true
    end

    set -l custom_message ""
    if set -q _flag_message
        set custom_message $_flag_message
    end

    # Detect VCS
    set -l is_jj false
    if type -q jj; and jj workspace root >/dev/null 2>&1
        set is_jj true
    else if not type -q git; or not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git or jj repository"
        return 1
    end

    # Gather diff
    set -l diff_content ""
    if test "$is_jj" = true
        set diff_content (jj diff 2>/dev/null | string collect)
    else
        set diff_content (git diff --staged 2>/dev/null | string collect)
    end

    if test -z "$diff_content"
        if test "$is_jj" = true
            echo "Error: No changes in working copy"
        else
            echo "Error: No staged changes. Stage files with: git add <files>"
        end
        return 1
    end

    # Generate message
    set -l commit_message ""

    if test -n "$custom_message"
        set commit_message $custom_message
    else if type -q opencode
        echo "✓ Generating commit message..."

        set -l max_diff_bytes 20000
        set -l truncated_diff $diff_content
        if test -n "$diff_content"
            set -l diff_bytes (printf "%s" "$diff_content" | wc -c | string trim)
            if test "$diff_bytes" -gt "$max_diff_bytes"
                set truncated_diff (printf "%s" "$diff_content" | head -c $max_diff_bytes | string collect)
                set truncated_diff "$truncated_diff

[... diff truncated ...]"
            end
        end

        set -l prompt "Generate a git commit message for these changes.

Rules:
- Conventional commit format: <type>(<scope>): <description>
- Scope is optional — omit unless changes are clearly scoped to one area
- Subject line: imperative mood, max 72 chars, no period
- No body unless the change genuinely needs explanation
- Output ONLY the commit message, nothing else. No code fences, no preamble.

## Diff
$truncated_diff"

        set -l oc_in (mktemp)
        set -l oc_out (mktemp)
        set -l oc_err (mktemp)
        printf "%s" $prompt >$oc_in
        _ai_run (_ai_model) $oc_in $oc_out $oc_err
        set -l oc_status $status
        set -l raw (string collect <$oc_out)
        set -l err_text (string collect <$oc_err)
        rm -f $oc_in $oc_out $oc_err

        if test $oc_status -ne 0
            echo "⚠ opencode exit=$oc_status"
            test -n "$err_text"; and printf "%s\n" $err_text | string replace -r '^' '   '
        end

        set commit_message (printf "%s" $raw | _ai_strip_fences | string trim | string collect)
    end

    if test -z "$commit_message"
        echo "Error: Failed to generate commit message"
        return 1
    end

    # Preview
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Commit message:"
    echo "────────────────────────────────────────────────────"
    printf "%s\n" $commit_message
    echo "────────────────────────────────────────────────────"
    echo ""

    if test "$dry_run" = true
        echo "Dry run — no commit created"
        return 0
    end

    # Confirm with edit option
    while true
        read -P "Commit? [Y/n/e(dit)]: " -l confirm
        switch $confirm
            case "" Y y
                break
            case e E
                set -l temp_file (mktemp)
                printf "%s\n" $commit_message >$temp_file

                set -l editor_cmd
                if test -n "$VISUAL"
                    set editor_cmd (string split ' ' -- $VISUAL)
                else if test -n "$EDITOR"
                    set editor_cmd (string split ' ' -- $EDITOR)
                else
                    set editor_cmd vim
                end

                $editor_cmd -- $temp_file
                set commit_message (string trim (string collect <$temp_file))
                rm $temp_file

                echo ""
                echo "────────────────────────────────────────────────────"
                printf "%s\n" $commit_message
                echo "────────────────────────────────────────────────────"
                echo ""
            case '*'
                echo "Cancelled."
                return 0
        end
    end

    # Commit
    if test "$is_jj" = true
        jj commit -m "$commit_message"
    else
        git commit -m "$commit_message"
    end
end
