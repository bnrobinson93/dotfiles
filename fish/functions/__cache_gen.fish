# Regenerate a cached script only when the tool's binary is newer than the
# cache (i.e. after an upgrade). Avoids re-spawning every tool each shell
# start — `X init | source` for starship/mise/zoxide/jj cost ~125ms combined.
# __cache_gen <cache-file> <tool-or-path> <command to generate it...>
function __cache_gen
    set -l cache $argv[1]
    set -l bin (command -v $argv[2]); or return 1
    # A mise shim symlinks to the mise binary, so -nt follows it there and a tool
    # upgrade never invalidates the cache. mise reshims on every install, so its
    # shims directory is the stamp that actually moves.
    set -l shims $HOME/.local/share/mise/shims
    string match -q -- "$shims/*" $bin; and set bin $shims
    if not test -s $cache; or test $bin -nt $cache
        mkdir -p (path dirname $cache)
        $argv[3..] >$cache 2>/dev/null
    end
end
