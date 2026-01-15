# Fish Shell Configuration
# This is the main config file - most settings are in conf.d/ for modularity

# Suppress fish greeting (use -U for universal/persistent)
set -U fish_greeting

# Vi mode (fish's native vi mode is excellent)
fish_vi_key_bindings

# But keep some emacs-style bindings in insert mode for convenience
bind -M insert \ca beginning-of-line
bind -M insert \ce end-of-line
bind -M insert \cf forward-char
bind -M insert \cb backward-char

# Enable transient prompt (cleaner history - optional QoL feature)
# Uncomment if you want past prompts to be simplified
# function fish_prompt_transient
#     echo -n '> '
# end

# Mouse support is built-in to fish/modern terminals!
# Alt+click to position cursor (works in Wezterm with shell integration)

# Load conf.d files (loaded automatically, but being explicit)
# Order: 00-env.fish → 01-paths.fish → 02-tools.fish → 03-abbreviations.fish
if status is-interactive
    # Commands to run in interactive sessions can go here

    # If try-cli exists, set the dir for it and initialize
    if test -f ~/.local/try.rb
        set -gx TRY_CLI_DIR ~/Documents/code/tries
        eval (~/.local/try.rb init $TRY_CLI_DIR | string collect)
        atuin init fish | source
    end
end

set -g fish_color_autosuggestion brblack

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
set --export --prepend PATH "$HOME/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Go private module configuration for virtru-corp repos
set -gx GOPRIVATE "github.com/virtru-corp/*"
set -gx GONOPROXY "github.com/virtru-corp/*"
set -gx GONOSUMDB "github.com/virtru-corp/*"
