# mkdir and then cd to it
function mkcd --argument dir
    mkdir -p -- $dir
    and cd -- $dir
end
