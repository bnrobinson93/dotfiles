set -U fish_greeting

if status is-interactive
    fish_vi_key_bindings

    bind -M insert \ca beginning-of-line
    bind -M insert \ce end-of-line
    bind -M insert \cf forward-char
    bind -M insert \cb backward-char

    if test -f ~/.local/try.rb
        set -gx TRY_CLI_DIR ~/Documents/code/tries
        eval (~/.local/try.rb init $TRY_CLI_DIR | string collect)
    end
end

set -gx GOPRIVATE "github.com/virtru-corp/*"
