# Regenerate a cached script only when the tool's binary is newer than the
# cache (i.e. after an upgrade). Avoids re-spawning every tool each shell
# start — `X init | source` for starship/mise/zoxide/jj cost ~125ms combined.
# __cache_gen <cache-file> <tool-or-path> <command to generate it...>
function __cache_gen
    set -l cache $argv[1]
    set -l bin (command -v $argv[2]); or return 1
    if not test -f $cache; or test $bin -nt $cache
        mkdir -p (path dirname $cache)
        $argv[3..] >$cache 2>/dev/null
    end
end
