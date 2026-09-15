function fish_user_key_bindings
    # atuin owns ctrl-r when installed (cached init in conf.d/02-tools.fish);
    # leave its history binding out of fzf's so atuin isn't clobbered.
    if functions --query fzf_configure_bindings
        if type -q atuin
            fzf_configure_bindings --history=
        else
            fzf_configure_bindings
        end
    end

    if not type -q atuin; and functions --query _fzf_search_history
        bind \cR _fzf_search_history
        bind -M insert \cR _fzf_search_history
    end
end
