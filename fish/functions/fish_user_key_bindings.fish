function fish_user_key_bindings
    if functions --query fzf_configure_bindings
        fzf_configure_bindings
    end

    if functions --query _fzf_search_history
        bind \cR _fzf_search_history
        bind -M insert \cR _fzf_search_history
    end
end
