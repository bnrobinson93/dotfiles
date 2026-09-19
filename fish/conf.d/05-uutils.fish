# uu-cut's -c counts bytes where GNU counts characters, so multibyte input
# truncates differently - accepted, it matches how Go indexes strings. sort is
# excluded: slower than GNU, and its collation changes sort | uniq output.
#
# No interactive guard, unlike the zsh side: agent tooling runs bash/zsh, so
# nothing but a human reaches this file.

for _uu in uniq tac base64 cut
    if type -q uu-$_uu
        alias $_uu "uu-$_uu"
    end
end
set -e _uu
