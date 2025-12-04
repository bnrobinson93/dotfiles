# List files long format
function ll
    if type -q eza
        eza -l -h -smod $argv
    else
        ls -lrth --color=always $argv
    end
end
