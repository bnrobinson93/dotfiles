# Create stacked GitHub PRs: push the whole stack once, then run ghpr per
# bookmark bottom-to-top. Reuses ghpr for each PR (AI title/body, auto base
# detection, existing-PR skip). jj-only — in git repos just use ghpr.
#
# All ghpr flags are forwarded to every PR in the stack, except:
#   -B/--base <ref>         → base for the BOTTOM PR only; the rest stack on
#                             their parent bookmark as usual
# -t/--title, -r/--revision, and -b/--bookmark are rejected: they're per-PR and
# would clobber the whole stack (title should be AI-generated per PR).

function ghprs --description "Create stacked GitHub PRs with AI bodies via ghpr"
    if not type -q jj; or not jj workspace root >/dev/null 2>&1
        echo "Error: ghprs is jj-only. Use ghpr in git repos."
        return 1
    end

    set -l common
    set -l bottom_base
    set -l has_bottom_base false
    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        switch $arg
            case --
                set -a common $argv[$i..-1]
                break
            case -t --title -b --bookmark -r --revision '-t?*' '--title=*' '-b?*' '--bookmark=*' '-r?*' '--revision=*'
                echo "Error: -t/--title, -r/--revision, -b/--bookmark are per-PR and break a stack."
                echo "  Titles are AI-generated per PR. Base the bottom PR with -B; the rest auto-stack."
                return 1
            case -B --base
                if test $i -eq (count $argv)
                    echo "Error: $arg requires a value."
                    return 1
                end
                set i (math $i + 1)
                set bottom_base $argv[$i]
                set has_bottom_base true
            case '-B?*'
                set bottom_base (string sub --start 3 -- $arg)
                set has_bottom_base true
            case '--base=*'
                set bottom_base (string replace --regex '^--base=' '' -- $arg)
                set has_bottom_base true
            case -l --label
                set -a common $arg
                if test $i -eq (count $argv)
                    echo "Error: $arg requires a value."
                    return 1
                end
                set i (math $i + 1)
                set -a common $argv[$i]
            case '*'
                set -a common $arg
        end
        set i (math $i + 1)
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

    echo "✓ "(count $bookmarks)" bookmark(s) in stack"
    for i in (seq (count $bookmarks))
        set -l bm $bookmarks[$i]
        echo ""
        echo "━━━ PR for $bm ━━━"
        set -l args -b $bm $common
        # -B overrides the bottom PR's base only; upper PRs auto-detect parent
        if test $i -eq 1; and test "$has_bottom_base" = true
            set args $args -B $bottom_base
        end
        ghpr $args
    end
end
