# Create GitHub PR with conventional commit format and AI-generated body

function ghpr --description "Create GitHub PR with conventional commit format"
    # Parse arguments
    set -l draft_flag ""
    set -l dry_run false
    set -l custom_base ""
    set -l custom_title ""

    argparse d/draft dry-run v/verbose 'B/base=' 't/title=' 'b/bookmark=' -- $argv
    or return 1

    set -l verbose false
    if set -q _flag_verbose
        set verbose true
    end

    if set -q _flag_draft
        set draft_flag --draft
    end

    if set -q _flag_dry_run
        set dry_run true
    end

    if set -q _flag_base
        set custom_base $_flag_base
    end

    if set -q _flag_title
        set custom_title $_flag_title
    end

    set -l target_bookmark ""
    if set -q _flag_bookmark
        set target_bookmark $_flag_bookmark
    end

    # Check dependencies
    if not type -q gh
        echo "Error: gh (GitHub CLI) not installed"
        return 1
    end

    # Detect VCS type using proper checks
    set -l is_jj false
    if type -q jj; and jj workspace root >/dev/null 2>&1
        set is_jj true
        echo "✓ Jujutsu repository detected"
    else if type -q git; and git rev-parse --git-dir >/dev/null 2>&1
        echo "✓ Git repository detected"
    else
        echo "Error: Not in a git or jj repository"
        return 1
    end

    # Self-heal GIT_DIR for gh in JJ workspaces (including secondary worktrees).
    # gh relies on git discovery; JJ secondary workspaces have no .git, and the
    # env var may be missing in stale/forked shells. Resolve via jj's own
    # pointer chain so we always land at the default workspace's git dir.
    if test "$is_jj" = true; and not set -q GIT_DIR
        set -l _ws_root (jj workspace root 2>/dev/null)
        set -l _repo_ptr "$_ws_root/.jj/repo"
        set -l _repo_dir ""
        if test -d "$_repo_ptr"
            set _repo_dir "$_repo_ptr"
        else if test -f "$_repo_ptr"
            set -l _ptr (string trim < "$_repo_ptr")
            if string match -q '/*' -- "$_ptr"
                set _repo_dir "$_ptr"
            else
                set _repo_dir (path resolve "$_ws_root/.jj/$_ptr")
            end
        end
        if test -n "$_repo_dir"; and test -f "$_repo_dir/store/git_target"
            set -l _tgt (string trim < "$_repo_dir/store/git_target")
            set -l _git_dir ""
            if string match -q '/*' -- "$_tgt"
                set _git_dir "$_tgt"
            else
                set _git_dir (path resolve "$_repo_dir/store/$_tgt")
            end
            if test -d "$_git_dir"
                set -x GIT_DIR "$_git_dir"
                echo "✓ Set GIT_DIR from jj default workspace: $GIT_DIR"
            end
        end
    end

    # Get current branch/bookmark name
    set -l current_branch ""
    if test -n "$target_bookmark"
        set current_branch $target_bookmark
    else if test "$is_jj" = true
        # Strip trailing * (indicates unpushed local changes in JJ output)
        set current_branch (jj log -r 'closest_bookmark(@)' -T 'bookmarks.join(" ")' --no-graph 2>/dev/null | string trim | awk '{print $1}' | string replace -r '\*$' '')
    else
        set current_branch (git branch --show-current 2>/dev/null)
    end

    if test -z "$current_branch"
        if test "$is_jj" = true
            echo "Error: No bookmark found. Create one with: jj bookmark create <name>"
        else
            echo "Error: No branch found"
        end
        return 1
    end

    set -l _ref_kind branch
    test "$is_jj" = true; and set _ref_kind bookmark
    echo "✓ Current $_ref_kind: $current_branch"

    # Ensure changes are pushed before creating a PR
    if test "$is_jj" = true
        # A bookmark is pushed only if its block contains "@origin:" without "not created yet"
        set -l escaped_branch (string escape --style=regex -- $current_branch)
        set -l bookmark_block (jj bookmark list --all-remotes 2>/dev/null | grep -A3 -- "^$escaped_branch:")
        set -l has_origin (echo $bookmark_block | string match -r '@origin:')
        set -l not_created (echo $bookmark_block | string match -r 'not created yet')
        if test -z "$has_origin"; or test -n "$not_created"
            echo "Error: Bookmark '$current_branch' has not been pushed to origin."
            echo "  Push with: jj git push -b $current_branch"
            return 1
        end
    else
        set -l upstream (git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
        if test -z "$upstream"
            echo "Error: Branch '$current_branch' has no upstream. Push with: git push -u origin $current_branch"
            return 1
        end
        if test (count (git log "@{u}..HEAD" --oneline 2>/dev/null)) -gt 0
            echo "Error: Branch '$current_branch' has unpushed commits. Run: git push"
            return 1
        end
    end

    # Determine base branch
    set -l base_branch ""
    if test -n "$custom_base"
        set base_branch $custom_base
    else if test "$is_jj" = true
        # Extract base from trunk() - results in "main@origin" or "master@origin", extract just the branch name
        set base_branch (jj log -r 'trunk()' -T 'bookmarks.join(" ")' --no-graph 2>/dev/null | string trim | string replace -r '@.*$' '' | head -n1)
        if test -z "$base_branch"
            set base_branch main
        end
    else
        # Git: try main, then master
        if git show-ref --verify --quiet refs/heads/main
            set base_branch main
        else if git show-ref --verify --quiet refs/heads/master
            set base_branch master
        else
            # Use repo default
            set base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
            if test -z "$base_branch"
                set base_branch main # final fallback
            end
        end
    end

    echo "✓ Base branch: $base_branch"

    # Detect parent bookmark for stacked PRs (JJ only) — only when no custom base was given
    set -l comparison_base ""
    if test "$is_jj" = true
        if test -n "$custom_base"
            set comparison_base "$custom_base"
        else
            # ancestors() excluding the bookmark commit itself gives us the parent layer
            set -l parent_bookmark (jj log -r "ancestors($current_branch) & bookmarks() & ~$current_branch" \
                -T 'bookmarks.join(",")' --no-graph --limit 1 2>/dev/null | \
                string replace -r '\*' '' | string trim | string split ',' | head -n1)

            set -l trunk_bookmark (jj log -r "trunk()" -T 'bookmarks.join(",")' \
                --no-graph 2>/dev/null | string trim)

            if test -n "$parent_bookmark"; and test "$parent_bookmark" != "$trunk_bookmark"
                set comparison_base "$parent_bookmark"
                set base_branch "$parent_bookmark"
            else
                set comparison_base "trunk()"
            end
        end
    else
        set comparison_base "$base_branch"
    end

    # Bail if a PR already exists for this bookmark — skip AI + gh create
    set -l existing_pr (gh pr list --head $current_branch --state open --json number,url --jq '.[0] // empty | "\(.number)\t\(.url)"' 2>/dev/null)
    if test -n "$existing_pr"
        set -l pr_parts (string split \t -- $existing_pr)
        echo "✓ PR #$pr_parts[1] already exists: $pr_parts[2]"
        return 0
    end

    # Extract raw branch context for AI prompt - type, ticket, and description hint
    # Title will be generated by AI; this is just context
    set -l branch_type ""
    set -l branch_ticket ""
    set -l branch_desc ""
    set -l branch_parts (string split -m 1 "/" $current_branch)
    if test (count $branch_parts) -eq 2
        set branch_type $branch_parts[1]
        set -l after_slash $branch_parts[2]
        # Extract ticket number pattern like PEP-1234, JIRA-567, etc.
        set branch_ticket (string match -r '[A-Z]+-[0-9]+' $after_slash)
        # Extract description: everything after the ticket number (strip leading - or _)
        if test -n "$branch_ticket"
            set branch_desc (string replace -r "^$branch_ticket\W?" "" $after_slash | string replace -a "-" " " | string replace -a "_" " ")
        else
            set branch_desc (string replace -a "-" " " $after_slash | string replace -a "_" " ")
        end
    end

    # Gather context for PR body
    set -l diff_content ""
    set -l commit_messages ""
    set -l changed_files ""

    if test "$is_jj" = true
        set diff_content (jj diff -r "$comparison_base..$current_branch" 2>/dev/null | string collect)
        set commit_messages (jj log -r "$comparison_base..$current_branch" -T 'description' --no-graph 2>/dev/null | string collect)
        set changed_files (jj diff -r "$comparison_base..$current_branch" --summary 2>/dev/null | string replace -r '^[A-Z] +' '')
    else
        set diff_content (git diff "$base_branch"...HEAD 2>/dev/null | string collect)
        set commit_messages (git log "$base_branch"..HEAD --pretty=format:"%s%n%b" 2>/dev/null | string collect)
        set changed_files (git diff "$base_branch"...HEAD --name-only 2>/dev/null)
    end

    if test -z "$diff_content"
        if test "$is_jj" = true
            echo "⚠ Warning: No changes detected between '$current_branch' and '$comparison_base'"
        else
            echo "⚠ Warning: No changes detected between current branch and $base_branch"
        end
    end

    # Check for PR template
    set -l template_path ""
    set -l template_content ""
    for path in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md
        if test -f $path
            set template_path $path
            set template_content (string collect <$path)
            break
        end
    end

    # Generate PR title and body via AI
    set -l pr_title ""
    set -l pr_body ""
    set -l use_fill false

    if test -n "$custom_title"
        set pr_title $custom_title
    end

    if type -q opencode
        echo "✓ Generating PR title and body with OpenCode..."

        set -l prompt "Generate a GitHub PR title and description for these changes.

Branch name: $current_branch"

        if test -n "$branch_type"
            set prompt "$prompt
Conventional commit type from branch: $branch_type"
        end

        if test -n "$branch_ticket"
            set prompt "$prompt
Ticket number: $branch_ticket (must appear in the title)"
        end

        if test -n "$branch_desc"
            set prompt "$prompt
Description hint from branch name: $branch_desc"
        end

        if set -q changed_files[1]
            set -l changed_files_str (printf "%s\n" $changed_files | string collect)
            set prompt "$prompt

Changed files (use to infer the conventional commit scope):
$changed_files_str"
        end

        # Recent PR titles show this repo's scope conventions (or lack thereof)
        set -l recent_titles (gh pr list --limit 5 --json title --jq '.[].title' 2>/dev/null | string collect)
        if test -n "$recent_titles"
            set prompt "$prompt

Recent PR titles from this repo (use as a guide for scope conventions):
$recent_titles"
        end

        set prompt "$prompt

Output format — STRICT:
TITLE: <conventional commit title>
BODY:
<PR description>

Output rules:
- Emit ONLY the two sections above. No preamble (\"Here's the PR...\"), no closing remarks (\"Feel free to modify...\", \"Let me know if...\"), no markdown headers around TITLE/BODY.
- Do NOT wrap the output in code fences.
- BODY content may contain markdown; it is the literal PR description.
- Stop immediately after the final line of the PR description.

Scope rules: scope is optional. Only include a scope if the changes are clearly focused in one area AND recent PR titles in this repo use scopes. Infer the scope from changed file paths. Omit scope entirely if this repo doesn't use them or changes span multiple areas."

        if test -n "$template_content"
            set prompt "$prompt

Use this as a loose guide for the body structure:
$template_content"
        end

        set -l max_diff_bytes 20000
        set -l max_commit_bytes 8000
        set -l truncated_diff $diff_content
        set -l truncated_commit_messages $commit_messages

        if test -n "$diff_content"
            set -l diff_bytes (printf "%s" "$diff_content" | wc -c | string trim)
            if test "$diff_bytes" -gt "$max_diff_bytes"
                set truncated_diff (printf "%s" "$diff_content" | head -c $max_diff_bytes | string collect)
                set truncated_diff "$truncated_diff

[... diff truncated ...]"
            end
        end

        if test -n "$commit_messages"
            set -l commit_bytes (printf "%s" "$commit_messages" | wc -c | string trim)
            if test "$commit_bytes" -gt "$max_commit_bytes"
                set truncated_commit_messages (printf "%s" "$commit_messages" | head -c $max_commit_bytes | string collect)
                set truncated_commit_messages "$truncated_commit_messages

[... commit messages truncated ...]"
            end
        end

        set prompt "$prompt

## Changes
$truncated_diff

## Commit Messages
$truncated_commit_messages"

        set -l oc_in (mktemp)
        set -l oc_out (mktemp)
        set -l oc_err (mktemp)
        printf "%s" $prompt >$oc_in
        _ai_run (_ai_model) $oc_in $oc_out $oc_err
        set -l oc_status $status
        set -l ai_output (string collect <$oc_out)
        set -l err_text (string collect <$oc_err)
        rm -f $oc_in $oc_err

        if test "$verbose" = true; and begin; test $oc_status -ne 0; or test -z "$ai_output"; end
            echo "⚠ opencode exit=$oc_status, stdout_len="(string length -- $ai_output)", stderr_len="(string length -- $err_text)
            if test -n "$err_text"
                echo "⚠ opencode stderr:"
                printf "%s\n" $err_text | string replace -r '^' '   '
            end
        end

        if test -n "$ai_output"
            set -l ai_title (_ai_extract_marker TITLE $oc_out | string collect)
            set -l ai_body (_ai_extract_marker BODY $oc_out | string collect)

            if test -n "$ai_title"; and test -z "$custom_title"
                set pr_title (string trim -- $ai_title)
            end
            if test -n "$ai_body"
                set ai_body (printf "%s" $ai_body | _ai_strip_trailer | string collect)
                set pr_body (string trim -- $ai_body)
            end
        end
        rm -f $oc_out

        if test -z "$pr_body"
            echo "⚠ OpenCode failed to generate output, will use --fill"
            if test "$verbose" = true; and test -n "$ai_output"
                echo "⚠ Raw ai_output (first 500 chars, no TITLE/BODY markers found):"
                printf "%s\n" (string sub -l 500 -- $ai_output) | string replace -r '^' '   '
            end
            set use_fill true
        end
    else
        echo "⚠ opencode not found, will use --fill for body"
        set use_fill true
    end

    # Fallback title from branch name if AI didn't produce one
    if test -z "$pr_title"
        if test -n "$branch_type"; and test -n "$branch_ticket"
            if test -n "$branch_desc"
                set pr_title "$branch_type: $branch_ticket $branch_desc"
            else
                set pr_title "$branch_type: $branch_ticket"
            end
        else
            set pr_title (string replace -a -- "-" " " $current_branch | string replace -a -- "_" " ")
        end
        echo "⚠ Using fallback title: $pr_title"
    end

    # Validation hold - show preview
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Pull Request Preview"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Title: $pr_title"
    echo "Base:  $base_branch"
    echo "Head:  $current_branch"

    if test -n "$draft_flag"
        echo "Draft: Yes"
    end

    echo ""

    if test "$use_fill" = true
        echo "Body: (will use --fill, gh will open editor)"
    else
        echo "Body:"
        echo "────────────────────────────────────────────────────"
        printf "%s\n" $pr_body
        echo "────────────────────────────────────────────────────"
    end

    echo ""

    # Dry run exits here
    if test "$dry_run" = true
        echo "Dry run - no PR created"
        return 0
    end

    # Prompt for confirmation with edit options
    while true
        read -P "Create this PR? [Y/n/e(dit body)/t(itle)]: " -l confirm

        switch $confirm
            case "" Y y
                break
            case t T
                read -P "Title: " -l new_title
                if test -n "$new_title"
                    set pr_title (string trim -- $new_title)
                end
                echo ""
                echo "Title: $pr_title"
                echo ""
            case e E
                if test "$use_fill" = true
                    echo "Cannot edit when using --fill mode"
                    continue
                end

                # Git-commit-style: first line = title, blank line, rest = body
                set -l temp_file (mktemp)
                printf "%s\n\n%s\n" $pr_title $pr_body >$temp_file

                # Split to handle editors with args (e.g. "code --wait")
                set -l editor_cmd
                if test -n "$VISUAL"
                    set editor_cmd (string split ' ' -- $VISUAL)
                else if test -n "$EDITOR"
                    set editor_cmd (string split ' ' -- $EDITOR)
                else
                    set editor_cmd vim
                end

                $editor_cmd -- $temp_file

                # Parse: line 1 = title, drop optional blank separator line, rest = body
                set -l new_title (awk 'NR==1{print; exit}' $temp_file | string trim)
                set -l new_body (awk 'NR==1{next} NR==2&&!NF{next} {print}' $temp_file | string collect)
                if test -n "$new_title"
                    set pr_title $new_title
                end
                set pr_body $new_body
                rm $temp_file

                # Show updated preview
                echo ""
                echo "Title: $pr_title"
                echo "Updated Body:"
                echo "────────────────────────────────────────────────────"
                printf "%s\n" $pr_body
                echo "────────────────────────────────────────────────────"
                echo ""
            case '*'
                echo "Cancelled."
                return 0
        end
    end

    # Create PR
    echo ""
    echo "✓ Creating PR..."

    set -l body_file ""
    if test "$use_fill" = false
        set body_file (mktemp)
        printf "%s\n" $pr_body >$body_file
    end

    set -l gh_status 0

    # Build gh args as a list so empty draft_flag doesn't sneak in as a blank argument
    set -l gh_args pr create --base $base_branch --title "$pr_title"

    # JJ doesn't update git HEAD to the current bookmark, so gh can't detect the branch
    # automatically - we must pass -H explicitly with the closest bookmark name
    if test "$is_jj" = true
        set gh_args $gh_args -H $current_branch
    end

    if test "$use_fill" = true
        set gh_args $gh_args --fill
    else
        set gh_args $gh_args --body-file $body_file
    end

    if test -n "$draft_flag"
        set gh_args $gh_args --draft
    end

    gh $gh_args
    set gh_status $status

    if test -n "$body_file"
        rm -f $body_file
    end

    if test $gh_status -eq 0
        echo "✓ PR created successfully!"
    else
        echo "✗ Failed to create PR"
        return 1
    end
end
