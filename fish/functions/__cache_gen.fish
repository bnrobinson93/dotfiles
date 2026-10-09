# Regenerate a cached script only when the tool's binary is newer than the
# cache (i.e. after an upgrade). Avoids re-spawning every tool each shell
# start — `X init | source` for starship/mise/zoxide/jj cost ~125ms combined.
# __cache_gen <cache-file> <tool-or-path> <command to generate it...>
function __cache_gen
    set -l cache $argv[1]
    set -l stamp (command -v $argv[2]); or return 1
    # `command -v` on a mise-managed tool is a shim symlinked to the mise binary,
    # so -nt against it reads mise's mtime and the cache never regenerates.
    set -l installs $HOME/.local/share/mise/installs/$argv[2]
    test -d $installs; and set stamp $installs
    if not test -s $cache; or test $stamp -nt $cache
        mkdir -p (path dirname $cache)
        $argv[3..] >$cache 2>/dev/null
    end
end
