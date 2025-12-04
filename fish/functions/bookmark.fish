# Show jj bookmarks
function bookmark
    if not type -q jj
        echo "Error: jj not installed"
        return 1
    end

    if jj workspace root >/dev/null 2>&1
        jj log -r 'closest_bookmark(@)' -T 'bookmarks.map(|b| b.name())' -G
    end
end
