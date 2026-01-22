function killport --argument-names port --description "Kill processes listening on a port"
    set -l pids (lsof -tiTCP:$port -sTCP:LISTEN)
    if set -q pids[1]
        kill $pids
    end
end
