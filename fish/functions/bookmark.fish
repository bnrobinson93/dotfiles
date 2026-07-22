# Show jj bookmarks
function bookmark
    if not type -q jj
        echo "Error: jj not installed"
        return 1
    end

    if jj workspace root >/dev/null 2>&1
        jj ghbranch
    end
end
