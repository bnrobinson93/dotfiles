# Abbreviations (Better than aliases - they expand in the command line!)
# Use 'abbr' command to add more interactively, they persist automatically

# Editor
abbr -a vi $EDITOR

# Kubectl (if installed)
if type -q kubectl
    abbr -a k kubectl
    abbr -a kgp 'kubectl get pods'
end

# Git abbreviations (optional - you might prefer typing these out)
# Uncomment if you want them:
# abbr -a gs 'git status'
# abbr -a ga 'git add'
# abbr -a gc 'git commit'
# abbr -a gp 'git push'
# abbr -a gl 'git pull'
# abbr -a gd 'git diff'
# abbr -a gco 'git checkout'

# Nala (better apt frontend)
if type -q nala
    abbr -a apt nala
    # Note: 'sudo ' alias not needed - fish handles this better
end

# Tmux sessionizer (if you use it)
# abbr -a tms tmux-sessionizer

# Common typos (QoL feature)
abbr -a clera clear
abbr -a cler clear
abbr -a claer clear

# Quick navigation (optional)
# abbr -a .. 'cd ..'
# abbr -a ... 'cd ../..'
# abbr -a .... 'cd ../../..'
