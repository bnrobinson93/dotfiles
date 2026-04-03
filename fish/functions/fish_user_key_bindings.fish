function fish_user_key_bindings
    fzf_configure_bindings
    bind \cR _fzf_search_history
    bind -M insert \cR _fzf_search_history
end
