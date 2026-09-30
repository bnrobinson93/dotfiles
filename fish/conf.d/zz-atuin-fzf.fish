# fzf.fish overwrites Atuin's history binding, so restore it after conf.d loads.
if status is-interactive
    fish_user_key_bindings
end
