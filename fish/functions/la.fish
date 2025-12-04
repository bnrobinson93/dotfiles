# List all files with details
function la
    if type -q eza
        eza -la -h -smod $argv
    else
        ls -larth --color=always $argv
    end
end
