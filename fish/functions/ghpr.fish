#!/usr/bin/env fish
# Create GitHub PR with conventional commit format and AI-generated body

function ghpr --description "Create GitHub PR with conventional commit format"
    # Parse arguments
    set -l draft_flag ""
    set -l dry_run false
    set -l custom_base ""
    set -l custom_title ""
    
    argparse 'd/draft' 'dry-run' 'b/base=' 't/title=' -- $argv
    or return 1
    
    if set -q _flag_draft
        set draft_flag "--draft"
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
    
    # Check dependencies
    if not type -q gh
        echo "Error: gh (GitHub CLI) not installed"
        return 1
    end
    
    # Detect VCS type using proper checks
    set -l is_jj false
    if jj workspace root >/dev/null 2>&1
        set is_jj true
        echo "✓ Jujutsu repository detected"
    else if git rev-parse --git-dir >/dev/null 2>&1
        echo "✓ Git repository detected"
    else
        echo "Error: Not in a git or jj repository"
        return 1
    end
    
    # Get current branch/bookmark name
    set -l current_branch ""
    if test "$is_jj" = true
        set current_branch (jj log -r 'closest_bookmark(@)' -T 'bookmarks.join(" ")' --no-graph 2>/dev/null | string trim | awk '{print $1}' | string replace -r '^\*' '')
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
    
    echo "✓ Current "(test "$is_jj" = true; and echo "bookmark"; or echo "branch")": $current_branch"
    
    # Determine base branch
    set -l base_branch ""
    if test -n "$custom_base"
        set base_branch $custom_base
    else if test "$is_jj" = true
        # Extract base from trunk() - results in "main@origin" or "master@origin", extract just the branch name
        set base_branch (jj log -r 'trunk()' -T 'bookmarks.join(" ")' --no-graph 2>/dev/null | string trim | string replace -r '@.*$' '' | head -n1)
        if test -z "$base_branch"
            set base_branch "main"
        end
    else
        # Git: try main, then master
        if git show-ref --verify --quiet refs/heads/main
            set base_branch "main"
        else if git show-ref --verify --quiet refs/heads/master
            set base_branch "master"
        else
            # Use repo default
            set base_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
            if test -z "$base_branch"
                set base_branch "main" # final fallback
            end
        end
    end
    
    echo "✓ Base branch: $base_branch"
    
    # Parse branch/bookmark name to conventional commit format
    set -l pr_title ""
    if test -n "$custom_title"
        set pr_title $custom_title
    else
        # Extract type and description from branch name
        # Handle separators: /, -, _
        set -l branch_parts (string split -m 1 "/" $current_branch)
        if test (count $branch_parts) -eq 2
            set -l type $branch_parts[1]
            set -l desc (string replace -a "-" " " $branch_parts[2] | string replace -a "_" " ")
            
            # Validate type is conventional commit type
            if string match -qr '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)$' $type
                set pr_title "$type: $desc"
            else
                echo "⚠ Warning: '$type' is not a standard conventional commit type"
                set pr_title (string replace -a "-" " " $current_branch | string replace -a "_" " ")
            end
        else
            # Try splitting on - or _
            set branch_parts (string split -m 1 "-" $current_branch)
            if test (count $branch_parts) -eq 1
                set branch_parts (string split -m 1 "_" $current_branch)
            end
            
            if test (count $branch_parts) -eq 2
                set -l type $branch_parts[1]
                set -l desc (string replace -a "-" " " $branch_parts[2] | string replace -a "_" " ")
                
                if string match -qr '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)$' $type
                    set pr_title "$type: $desc"
                else
                    echo "⚠ Warning: '$type' is not a standard conventional commit type"
                    set pr_title (string replace -a "-" " " $current_branch | string replace -a "_" " ")
                end
            else
                # No conventional format detected, use as-is with spaces
                echo "⚠ Warning: Branch name doesn't follow conventional commit format"
                set pr_title (string replace -a "-" " " $current_branch | string replace -a "_" " ")
            end
        end
    end
    
    echo "✓ Parsed title: $pr_title"
    
    # Gather context for PR body
    set -l diff_content ""
    set -l commit_messages ""
    
    if test "$is_jj" = true
        set diff_content (jj diff -r "trunk()..@" 2>/dev/null)
        set commit_messages (jj log -r "trunk()..@" -T 'description' --no-graph 2>/dev/null)
    else
        set diff_content (git diff "$base_branch"...HEAD 2>/dev/null)
        set commit_messages (git log "$base_branch"..HEAD --pretty=format:"%s%n%b" 2>/dev/null)
    end
    
    if test -z "$diff_content"
        echo "⚠ Warning: No changes detected between current branch and $base_branch"
    end
    
    # Check for PR template
    set -l template_path ""
    set -l template_content ""
    for path in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md
        if test -f $path
            set template_path $path
            set template_content (cat $path)
            break
        end
    end
    
    # Generate PR body
    set -l pr_body ""
    set -l use_fill false
    
    if type -q opencode
        echo "✓ Generating PR body with OpenCode..."
        
        # Create prompt
        set -l prompt "Generate a concise GitHub PR description for these changes."
        
        if test -n "$template_content"
            set prompt "$prompt

Template (use as a loose guide, not strict requirement):
$template_content"
        end
        
        set prompt "$prompt

## Changes
$diff_content

## Commit Messages
$commit_messages"
        
        # Run OpenCode and capture output
        set pr_body (echo $prompt | opencode run --format default 2>/dev/null | string collect)
        
        if test -z "$pr_body"
            echo "⚠ OpenCode failed to generate body, will use --fill"
            set use_fill true
        end
    else
        echo "⚠ opencode not found, will use --fill for body"
        set use_fill true
    end
    
    # Validation hold - show preview
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Pull Request Preview"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Title: $pr_title"
    echo "Base:  $base_branch"
    
    if test "$is_jj" = true
        set -l gh_user (gh config get user -h github.com 2>/dev/null)
        echo "Head:  $gh_user:$current_branch"
    else
        echo "Head:  $current_branch"
    end
    
    if test -n "$draft_flag"
        echo "Draft: Yes"
    end
    
    echo ""
    
    if test "$use_fill" = true
        echo "Body: (will use --fill, gh will open editor)"
    else
        echo "Body:"
        echo "────────────────────────────────────────────────────"
        echo "$pr_body"
        echo "────────────────────────────────────────────────────"
    end
    
    echo ""
    
    # Dry run exits here
    if test "$dry_run" = true
        echo "Dry run - no PR created"
        return 0
    end
    
    # Prompt for confirmation with edit option
    while true
        read -P "Create this PR? [Y/n/e(dit)]: " -l confirm
        
        switch $confirm
            case "" Y y
                break
            case e E
                if test "$use_fill" = true
                    echo "Cannot edit when using --fill mode"
                    continue
                end
                
                # Open in $EDITOR
                set -l temp_file (mktemp)
                echo "$pr_body" > $temp_file
                
                if test -n "$EDITOR"
                    $EDITOR $temp_file
                else
                    vim $temp_file
                end
                
                set pr_body (cat $temp_file)
                rm $temp_file
                
                # Show updated preview
                echo ""
                echo "Updated Body:"
                echo "────────────────────────────────────────────────────"
                echo "$pr_body"
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
    
    set -l gh_cmd gh pr create --base $base_branch --title "$pr_title"
    
    # Add head flag for JJ repos
    if test "$is_jj" = true
        set -l gh_user (gh config get user -h github.com 2>/dev/null)
        set gh_cmd $gh_cmd -H "$gh_user:$current_branch"
    end
    
    # Add body or fill flag
    if test "$use_fill" = true
        set gh_cmd $gh_cmd --fill
    else
        set gh_cmd $gh_cmd --body "$pr_body"
    end
    
    # Add draft flag if set
    if test -n "$draft_flag"
        set gh_cmd $gh_cmd $draft_flag
    end
    
    # Add template if found
    if test -n "$template_path"
        set gh_cmd $gh_cmd --template "$template_path"
    end
    
    # Execute gh command
    eval $gh_cmd
    
    if test $status -eq 0
        echo "✓ PR created successfully!"
    else
        echo "✗ Failed to create PR"
        return 1
    end
end
