# Record terminal session and convert to GIF
function rec
    if not type -q asciinema; or not type -q agg
        echo "Error: asciinema and agg required"
        return 1
    end

    asciinema rec /tmp/demo.cast
    agg --theme nord --font-size 16 \
        --font-family "MesloLGL Nerd Font,FiraCode Nerd Font,DankMono Nerd Font" \
        /tmp/demo.cast ~/Pictures/demo.gif

    if test -f ~/Pictures/demo.gif
        rm /tmp/demo.cast
        echo "Saved to ~/Pictures/demo.gif"
    end
end
