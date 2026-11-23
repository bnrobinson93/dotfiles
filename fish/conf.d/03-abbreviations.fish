abbr -a vi $EDITOR

command -v kubectl >/dev/null 2>&1 && begin
    abbr -a k kubectl
    abbr -a kgp 'kubectl get pods'
end

command -v nala >/dev/null 2>&1 && abbr -a apt nala

abbr -a clera clear
abbr -a cler clear
abbr -a claer clear

abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'
