# Add paths to .gitignore
function ignore
    if test (count $argv) -eq 0
        echo "Usage: ignore <path> [<path2> ...]"
        return 1
    end

    for dir in $argv
        if not test -e $dir
            echo "WARN: $dir not a valid path"
            continue
        end

        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        or set -l root $HOME

        echo "Adding ignore to $root/.gitignore"
        echo $dir >> $root/.gitignore
    end
end
