function fish_user_key_bindings
    if functions --query fzf_configure_bindings
        if functions --query _atuin_search
            fzf_configure_bindings --history=
        else
            fzf_configure_bindings
        end
    end

    if functions --query _atuin_search
        bind \cR _atuin_search
        bind -M insert \cR _atuin_search
    else if functions --query _fzf_search_history
        bind \cR _fzf_search_history
        bind -M insert \cR _fzf_search_history
    end
end
