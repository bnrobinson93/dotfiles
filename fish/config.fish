set -U fish_greeting

fish_vi_key_bindings

bind -M insert \ca beginning-of-line
bind -M insert \ce end-of-line
bind -M insert \cf forward-char
bind -M insert \cb backward-char

if status is-interactive
    if test -f ~/.local/try.rb
        set -gx TRY_CLI_DIR ~/Documents/code/tries
        eval (~/.local/try.rb init $TRY_CLI_DIR | string collect)
    end
end

set -gx GOPRIVATE "github.com/virtru-corp/*"
set -gx GONOPROXY "github.com/virtru-corp/*"
set -gx GONOSUMDB "github.com/virtru-corp/*"
