function findport --argument-names port --description "Show processes listening on a port"
    lsof -nP -iTCP:$port -sTCP:LISTEN
end
