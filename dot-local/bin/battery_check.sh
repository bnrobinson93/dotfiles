#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    if [[ $(pmset -g ps | head -1) =~ "Battery Power" ]]; then
        echo "🔋"
    else
        echo "🔌"
    fi
elif [[ "$(uname)" == "Linux" ]]; then
    if [[ $(cat /sys/class/power_supply/BAT*/status 2>/dev/null) == "Discharging" ]]; then
        echo "🔋"
    else
        echo "🔌"
    fi
else
    echo "?"
fi

