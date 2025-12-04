# Add paths to global ~/.gitignore
function ignore-g
    if test (count $argv) -eq 0
        echo "Usage: ignore-g <path> [<path2> ...]"
        return 1
    end

    for dir in $argv
        if not test -e $dir
            echo "WARN: $dir not a valid path"
            continue
        end

        echo $dir >> ~/.gitignore
    end
end
