# List files with pager
function lss
    if type -q eza
        eza -l -h --color=always -smod $argv | less -reXF
    else
        ls -lrth --color=always $argv | less -erXF
    end
end
