# uutils (Rust coreutils) replacements for the GNU tools that measured faster.
#
# Benchmarked against GNU coreutils 9.11 on 2M/26M/129M/296M text plus a 230M
# binary, best-of-3 in tmpfs:
#
#   cut -c    4.7-6.1x    uniq    2.5-2.9x
#   tac       3.4x        base64  2.0-2.2x
#
# uniq, tac and base64 produce byte-identical output to GNU on every input
# tested, including multibyte text and binary. cut does not: its -c counts
# bytes where GNU counts characters, so multibyte input truncates differently.
# That is accepted deliberately - it matches how Go indexes strings.
#
# NOT aliased: sort. It is 4x slower than GNU here, and its collation differs
# under en_US.UTF-8, which silently changes the output of sort | uniq pipelines.
#
# No interactive guard, unlike the zsh side: agent tooling runs bash/zsh, so
# nothing but a human reaches this file.

for _uu in uniq tac base64 cut
    if type -q uu-$_uu
        alias $_uu "uu-$_uu"
    end
end
set -e _uu
