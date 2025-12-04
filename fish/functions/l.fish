# List with icons and git status
function l
    if type -q eza
        eza -lah --color=always --icons --git $argv
    else
        ls -lrha --color=always $argv
    end
end
