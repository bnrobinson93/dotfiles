# List last 15 files
function lt
    if type -q eza
        eza -l -h --color=always -smod $argv | tail -15
    else
        ls -larth --color=always $argv | tail -15
    end
end
