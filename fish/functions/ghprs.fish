# Create stacked GitHub PRs: push the whole stack once, then run ghpr per
# bookmark bottom-to-top. Reuses ghpr for each PR (AI title/body, auto base
# detection, existing-PR skip). jj-only — in git repos just use ghpr.
#
# Flags:
#   -d/--draft, -l/--label  → applied to every PR in the stack
#   -B/--base <ref>         → base for the BOTTOM PR only; the rest stack on
#                             their parent bookmark as usual
#   --dry-run               → preview every PR, create nothing
# -t/--title and -r/--revision are rejected: they're per-PR and would clobber
# the whole stack (title should be AI-generated per PR; -r conflicts with -b).

function ghprs --description "Create stacked GitHub PRs with AI bodies via ghpr"
    if not type -q jj; or not jj workspace root >/dev/null 2>&1
        echo "Error: ghprs is jj-only. Use ghpr in git repos."
        return 1
    end

    argparse d/draft dry-run 'B/base=' 't/title=' 'b/bookmark=' 'r/revision=' 'l/label=' -- $argv
    or return 1

    if set -q _flag_title; or set -q _flag_revision; or set -q _flag_bookmark
        echo "Error: -t/--title, -r/--revision, -b/--bookmark are per-PR and break a stack."
        echo "  Titles are AI-generated per PR. Base the bottom PR with -B; the rest auto-stack."
        return 1
    end

    # ghpr requires bookmarks already on origin — push the whole stack first
    echo "✓ Pushing stack..."
    if not jj ss
        echo "✗ Stack push failed"
        return 1
    end

    # Bottom-to-top so each PR's parent bookmark already exists as a base.
    # jj pr-stack emits bookmark names (its template); strip trailing * and trunk.
    set -l bookmarks (jj pr-stack --reversed --no-graph 2>/dev/null \
        | string replace -r '\*$' '' | string trim | string match -rv '^(main|master)?$')

    if test (count $bookmarks) -eq 0
        echo "Error: No stack bookmarks found. Create one with: jj create <name>"
        return 1
    end

    # Flags that apply to every PR
    set -l common
    set -q _flag_draft; and set -a common --draft
    set -q _flag_dry_run; and set -a common --dry-run
    set -q _flag_label; and set -a common --label $_flag_label

    echo "✓ "(count $bookmarks)" bookmark(s) in stack"
    for i in (seq (count $bookmarks))
        set -l bm $bookmarks[$i]
        echo ""
        echo "━━━ PR for $bm ━━━"
        set -l args -b $bm $common
        # -B overrides the bottom PR's base only; upper PRs auto-detect parent
        if test $i -eq 1; and set -q _flag_base
            set args $args -B $_flag_base
        end
        ghpr $args
    end
end
