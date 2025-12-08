#!/usr/bin/env fish
# Cleanup unused completion blocking files
# This removes empty .fish files for tools that aren't installed

set -l count 0
set -l kept 0

cd ~/.dotfiles/fish/completions

for file in *.fish
    # Skip non-empty files (fisher, nvm, fzf, etc.)
    if test -s $file
        echo "✓ Keeping non-empty: $file"
        set kept (math $kept + 1)
        continue
    end

    # Extract tool name
    set -l tool (string replace -r '\.fish$' '' $file)

    # Check if tool is installed
    if type -q $tool
        echo "✓ Keeping (installed): $file"
        set kept (math $kept + 1)
    else
        echo "✗ Removing (not installed): $file"
        rm $file
        set count (math $count + 1)
    end
end

echo ""
echo "Summary:"
echo "  Removed: $count files"
echo "  Kept: $kept files"
echo ""
echo "Run 'cd ~/.dotfiles && stow -R fish' to update symlinks"
