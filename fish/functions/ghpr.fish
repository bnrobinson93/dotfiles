function __ghpr_read_skill_body --argument-names skill_path
    awk 'BEGIN{fm=0} /^---[[:space:]]*$/{fm++; next} fm>=2{print}' $skill_path
end

function __ghpr_parse_args --no-scope-shadowing
    argparse d/draft dry-run desc-only 'B/base=' 't/title=' 'b/bookmark=' 'r/revision=' 'l/label=' -- $argv
    or return 1

    set -q _flag_draft; and set draft_flag --draft
    set -q _flag_dry_run; and set dry_run true
    set -q _flag_desc_only; and set desc_only true
    set -q _flag_base; and set custom_base $_flag_base
    set -q _flag_title; and set custom_title $_flag_title
    set -q _flag_bookmark; and set target_bookmark $_flag_bookmark
    set -q _flag_revision; and set target_revision $_flag_revision
    set -q _flag_label; and set labels $_flag_label

    if test -n "$target_bookmark" -a -n "$target_revision"
        echo "Error: Use either -b/--bookmark or -r/--revision, not both"
        return 1
    end

    return 0
end

function __ghpr_detect_vcs --no-scope-shadowing
    if set -q GIT_DIR
        if type -q git; and git rev-parse --git-dir >/dev/null 2>&1
            set is_jj false
            echo "✓ Git repository detected from GIT_DIR"
            return 0
        end

        echo "Error: GIT_DIR does not point to a git repository"
        return 1
    end

    if type -q jj; and jj workspace root >/dev/null 2>&1
        set is_jj true
        echo "✓ Jujutsu repository detected"
        return 0
    end

    if type -q git; and git rev-parse --git-dir >/dev/null 2>&1
        set is_jj false
        echo "✓ Git repository detected"
        return 0
    end

    echo "Error: Not in a git or jj repository"
    return 1
end

function __ghpr_resolve_range --no-scope-shadowing
    if test -n "$target_bookmark"
        set current_branch $target_bookmark
    else if test "$is_jj" = true
        if test -n "$target_revision"
            if not jj log -r "$target_revision" -T 'commit_id.short()' --no-graph >/dev/null 2>&1
                echo "Error: Revision '$target_revision' not found"
                return 1
            end

            set -l revision_bookmarks (jj log -r "$target_revision" -T 'local_bookmarks.map(|b| b.name()).join("\n")' --no-graph 2>/dev/null | string split '\n' | string trim | string match -rv '^$')
            if test (count $revision_bookmarks) -gt 1
                echo "Error: Revision '$target_revision' has multiple local bookmarks"
                echo "  Use -b/--bookmark with one of: "(string join ", " $revision_bookmarks)
                return 1
            end
            if test (count $revision_bookmarks) -eq 0
                echo "Error: Revision '$target_revision' has no local bookmark"
                echo "  Pass -b <bookmark> or create one with: jj bookmark create <name> -r '$target_revision'"
                return 1
            end

            set current_branch $revision_bookmarks[1]
        else
            set current_branch (jj log -r 'closest_bookmark(@)' -T 'bookmarks.join(" ")' --no-graph 2>/dev/null | string trim | awk '{print $1}' | string replace -r '\*$' '')
        end
    else
        if test -n "$target_revision"
            echo "Error: -r/--revision only works in jj repositories"
            return 1
        end
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

    if test -n "$custom_base"
        set base_branch $custom_base
        set ancestor_ref $custom_base
    else if test "$is_jj" = true
        set base_branch (jj log -r 'trunk()' -T 'bookmarks.join(" ")' --no-graph 2>/dev/null | string trim | string replace -r '@.*$' '' | head -n1)
        test -n "$base_branch"; or set base_branch main

        set -l parent_bookmark (jj log -r "ancestors($current_branch) & bookmarks() & ~$current_branch" \
            -T 'bookmarks.join(",")' --no-graph --limit 1 2>/dev/null | \
            string replace -r '\*' '' | string trim | string split ',' | head -n1)
        set -l trunk_bookmark (jj log -r 'trunk()' -T 'bookmarks.join(",")' --no-graph 2>/dev/null | string trim)

        if test -n "$parent_bookmark" -a "$parent_bookmark" != "$trunk_bookmark"
            set base_branch $parent_bookmark
            set ancestor_ref $parent_bookmark
            echo "✓ Stacked PR: ancestor '$parent_bookmark'"
        else
            set ancestor_ref 'trunk()'
        end
    else
        if git show-ref --verify --quiet refs/heads/main
            set base_branch main
        else if git show-ref --verify --quiet refs/heads/master
            set base_branch master
        else
            set base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
            test -n "$base_branch"; or set base_branch main
        end
        set ancestor_ref $base_branch
    end

    if test "$is_jj" = true
        set child_ref $current_branch
    else
        set child_ref HEAD
    end

    echo "✓ Current "(test "$is_jj" = true; and echo bookmark; or echo branch)": $current_branch"
    echo "✓ Range: $base_branch → $child_ref"
    return 0
end

function __ghpr_find_pr --no-scope-shadowing
    if not type -q gh
        echo "Error: gh (GitHub CLI) not installed"
        return 1
    end

    set -l current_repo ""
    set -l current_repo_owner ""
    set -l repo_view_command gh
    if test "$is_jj" = true
        set -l jj_git_dir (jj git root 2>/dev/null)
        if test -z "$jj_git_dir"
            echo "Error: Failed to resolve Git repository for JJ workspace"
            return 1
        end
        set repo_view_command env "GIT_DIR=$jj_git_dir" gh
    end

    set -l repo_fields ($repo_view_command repo view --json nameWithOwner,owner,parent --jq '.nameWithOwner, (.parent.nameWithOwner // .nameWithOwner), .owner.login' 2>/dev/null)
    if test (count $repo_fields) -ge 3
        set current_repo $repo_fields[1]
        set target_repo $repo_fields[2]
        set current_repo_owner $repo_fields[3]
        if test -n "$current_repo_owner" -a "$target_repo" != "$current_repo"
            set pr_head_selector "$current_repo_owner:$current_branch"
        end
    end

    set -l pr_args pr list --head "$pr_head_selector" --state open --limit 1 --json url --jq '.[0].url // empty'
    test -n "$target_repo"; and set pr_args $pr_args --repo $target_repo
    set pr_url (gh $pr_args 2>/dev/null)
    set -l list_status $status
    set pr_url (string trim -- "$pr_url")
    if test $list_status -ne 0
        echo "Error: Failed to check for an existing PR"
        return 1
    end

    if test -z "$pr_url" -o "$desc_only" = true
        set -l title_args pr list --limit 5 --json title --jq '.[].title'
        test -n "$target_repo"; and set title_args $title_args --repo $target_repo
        set recent_titles (gh $title_args 2>/dev/null | string collect)
    end

    return 0
end

function __ghpr_parse_ai_output --no-scope-shadowing --argument-names output
    set parsed_title ""
    set parsed_body ""
    set -l awk_parser '
        function is_separator(line) {
            return line ~ /^[[:space:]]*---[[:space:]]*$/
        }
        {
            if (!separated && is_separator($0)) {
                separated = 1
                next
            }
            if (want == "title" && !separated && $0 !~ /^[[:space:]]*$/) title = $0
            if (want == "body" && separated) {
                if (!started && $0 ~ /^[[:space:]]*$/) next
                started = 1
                print
            }
        }
        END {
            if (want == "title" && separated && title != "") print title
        }
    '

    set parsed_title (printf "%s\n" "$output" | awk -v want=title "$awk_parser" | string collect | string trim)
    set parsed_body (printf "%s\n" "$output" | awk -v want=body "$awk_parser" | string collect)

    test -n "$parsed_title" -a -n "$parsed_body"
end

function __ghpr_generate_description --no-scope-shadowing
    set -l branch_type ""
    set -l branch_ticket ""
    set -l branch_desc ""
    set -l branch_parts (string split -m 1 "/" $current_branch)
    if test (count $branch_parts) -eq 2
        set branch_type $branch_parts[1]
        set -l after_slash $branch_parts[2]
        set branch_ticket (string match -r '[A-Z]+-[0-9]+' $after_slash)
        set branch_desc (string replace -r '^[A-Z]+-[0-9]+\W?' '' $after_slash | string replace -a "-" " " | string replace -a "_" " ")
    end

    set -l diff_content ""
    set -l commit_messages ""
    set -l changed_files ""

    if test "$is_jj" = true
        set diff_content (jj diff -r "$ancestor_ref..$child_ref" 2>/dev/null | string collect)
        set commit_messages (jj log -r "$ancestor_ref..$child_ref" -T 'description' --no-graph 2>/dev/null | string collect)
        set changed_files (jj diff -r "$ancestor_ref..$child_ref" --summary 2>/dev/null | string replace -r '^[A-Z] +' '')
    else
        set diff_content (git diff "$ancestor_ref...$child_ref" 2>/dev/null | string collect)
        set commit_messages (git log "$ancestor_ref..$child_ref" --pretty=format:"%s%n%b" 2>/dev/null | string collect)
        set changed_files (git diff "$ancestor_ref...$child_ref" --name-only 2>/dev/null)
    end

    if test -z "$diff_content"
        echo "⚠ Warning: No changes detected between '$child_ref' and '$ancestor_ref'"
    end

    set -l template_content ""
    for path in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md
        if test -f $path
            set template_content (string collect <$path)
            break
        end
    end

    set -l pr_guidance ""
    set -l pr_skill ~/.config/opencode/skills/commit-and-pr/SKILL.md
    if not test -f $pr_skill
        echo "Error: commit-and-pr skill not found at $pr_skill"
        return 1
    end
    set pr_guidance (__ghpr_read_skill_body $pr_skill | string collect)

    set -l writing_voice ""
    set -l voice_skill ~/.config/opencode/skills/writing-voice/SKILL.md
    if test -f $voice_skill
        set writing_voice (__ghpr_read_skill_body $voice_skill | string collect)
    end

    set pr_title ""
    set pr_body ""
    set -l parsed_title ""
    set -l parsed_body ""
    set use_fill false

    set pr_title $custom_title

    if type -q opencode
        set -l oc_model opencode/big-pickle
        if test (uname -s) = Darwin
            set oc_model anthropic/claude-haiku-4-5
        end

        echo "✓ Generating PR title and body with OpenCode..."

        set -l max_diff_bytes 20000
        set -l max_commit_bytes 8000
        set -l truncated_diff $diff_content
        set -l truncated_commit_messages $commit_messages

        set -l diff_bytes (printf "%s" "$diff_content" | wc -c | string trim)
        if test "$diff_bytes" -gt "$max_diff_bytes"
            set truncated_diff (printf "%s" "$diff_content" | head -c $max_diff_bytes | string collect)
            set truncated_diff "$truncated_diff

[... diff truncated ...]"
        end

        set -l commit_bytes (printf "%s" "$commit_messages" | wc -c | string trim)
        if test "$commit_bytes" -gt "$max_commit_bytes"
            set truncated_commit_messages (printf "%s" "$commit_messages" | head -c $max_commit_bytes | string collect)
            set truncated_commit_messages "$truncated_commit_messages

[... commit messages truncated ...]"
        end

        set -l changed_files_str (printf "%s\n" $changed_files | string collect)
        set -l prompt "Generate a GitHub PR title and description from the source material below. Follow the authoritative guidance after the source material.

Branch context:
- Name: $current_branch
- Conventional commit type: $branch_type
- Ticket number: $branch_ticket
- Description hint: $branch_desc

Changed files:
$changed_files_str

Recent PR titles:
$recent_titles

Repository PR template:
$template_content

## Changes
$truncated_diff

## Commit Messages
$truncated_commit_messages

Writing guidance (apply its style to the description):
$writing_voice

PR guidance (authoritative for the title and description):
$pr_guidance

Output format (required - do not deviate):
<conventional commit title>
---
<PR description as Markdown>

Do not wrap the output in a code fence. The `---` line is the only separator."

        set -l ai_output (printf "%s" $prompt | opencode run --model $oc_model --format default 2>/dev/null | string collect)

        if test -n "$ai_output"
            __ghpr_parse_ai_output "$ai_output"
            if test -n "$parsed_title" -a -z "$custom_title"
                set pr_title $parsed_title
            end
            set pr_body "$parsed_body"
        end
    end

    if test -z "$pr_title"
        if test -n "$branch_ticket"
            set pr_title (string trim -- "$branch_type: $branch_ticket $branch_desc")
        else
            set pr_title (string replace -a -- "-" " " $current_branch | string replace -a -- "_" " ")
        end
        echo "⚠ Using fallback title: $pr_title"
    end

    test -n "$pr_body"
end

function __ghpr_render_body --argument-names body
    if type -q glow
        printf "%s\n" "$body" | glow -
    else
        printf "%s\n" "$body"
    end
end

function __ghpr_preview --no-scope-shadowing
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
        __ghpr_render_body "$pr_body"
        echo "────────────────────────────────────────────────────"
    end

    echo ""
end

function __ghpr_ensure_pushed --no-scope-shadowing
    if test "$is_jj" = true
        set -l escaped_branch (string escape --style=regex -- $current_branch | string replace -a '\-' -)
        set -l bookmark_block (jj bookmark list --all-remotes 2>/dev/null | grep -A3 -- "^$escaped_branch:")
        set -l has_origin (echo $bookmark_block | string match -r '@origin:')
        set -l not_created (echo $bookmark_block | string match -r 'not created yet')
        if test -z "$has_origin" -o -n "$not_created"
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

    return 0
end

function __ghpr_create_pr --no-scope-shadowing
    set -l parsed_title ""
    set -l parsed_body ""

    __ghpr_ensure_pushed
    or return 1

    if not __ghpr_generate_description
        echo "⚠ OpenCode did not return a complete PR description; will use --fill"
        set use_fill true
    end

    __ghpr_preview

    if test "$dry_run" = true
        echo "Dry run - no PR created"
        return 0
    end

    while true
        read -P "Create this PR? [Y/n/e(dit)]: " -l confirm

        switch $confirm
            case "" Y y
                break
            case e E
                set -l temp_file (mktemp)
                printf "%s\n\n---\n\n%s\n" "$pr_title" "$pr_body" >$temp_file

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

                set -l edited_output (string collect <$temp_file)
                __ghpr_parse_ai_output "$edited_output"
                rm $temp_file

                if test -n "$parsed_title"
                    set pr_title $parsed_title
                end

                if test -n "$parsed_body"
                    set pr_body $parsed_body
                    set use_fill false
                else
                    set pr_body ""
                    set use_fill true
                end

                echo ""
                echo "Updated Title: $pr_title"
                if test "$use_fill" = true
                    echo "Updated Body: (will use --fill, gh will open editor)"
                else
                    echo "Updated Body:"
                    echo "────────────────────────────────────────────────────"
                    __ghpr_render_body "$pr_body"
                    echo "────────────────────────────────────────────────────"
                end
                echo ""
            case '*'
                echo "Cancelled."
                return 0
        end
    end

    echo ""
    echo "✓ Creating PR..."

    set -l body_file ""
    if test "$use_fill" = false
        set body_file (mktemp)
        printf "%s\n" $pr_body >$body_file
    end

    set -l gh_args pr create --base $base_branch --title "$pr_title"
    test -n "$target_repo"; and set gh_args $gh_args --repo $target_repo
    if test "$is_jj" = true -o "$pr_head_selector" != "$current_branch"
        set gh_args $gh_args -H $pr_head_selector
    end
    if test "$use_fill" = true
        set gh_args $gh_args --fill
    else
        set gh_args $gh_args --body-file $body_file
    end
    test -n "$draft_flag"; and set gh_args $gh_args --draft
    test -n "$labels"; and set gh_args $gh_args --label $labels

    set -l create_output (gh $gh_args)
    set -l gh_status $status
    set pr_url (string trim -- "$create_output")
    test -n "$body_file"; and rm -f $body_file

    if test $gh_status -ne 0
        echo "✗ Failed to create PR"
        return 1
    end

    return 0
end

function __ghpr_print_url --no-scope-shadowing
    test -n "$pr_url"; and echo "✓ PR: $pr_url"
    return 0
end

function ghpr --description "Create GitHub PR with conventional commit format"
    set -l draft_flag ""
    set -l dry_run false
    set -l desc_only false
    set -l custom_base ""
    set -l custom_title ""
    set -l target_bookmark ""
    set -l target_revision ""
    set -l labels ""
    set -l is_jj false
    set -l current_branch ""
    set -l base_branch ""
    set -l ancestor_ref ""
    set -l child_ref ""
    set -l target_repo ""
    set -l pr_head_selector ""
    set -l recent_titles ""
    set -l pr_url ""
    set -l pr_title ""
    set -l pr_body ""
    set -l use_fill false

    __ghpr_parse_args $argv
    or return 1

    __ghpr_detect_vcs
    or return 1

    __ghpr_resolve_range
    or return 1
    set pr_head_selector $current_branch

    __ghpr_find_pr
    or return 1

    if test "$desc_only" = true
        if not __ghpr_generate_description
            __ghpr_print_url
            echo "Error: opencode is required and must generate a PR description with --desc-only"
            return 1
        end
        __ghpr_preview
        __ghpr_print_url
        return 0
    end

    if test -z "$pr_url"
        __ghpr_create_pr
        or return 1
    end

    __ghpr_print_url
end
