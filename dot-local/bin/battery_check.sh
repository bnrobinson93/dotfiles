#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    if [[ $(pmset -g ps | head -1) =~ "Battery Power" ]]; then
        echo "battery"
    else
        echo "AC"
    fi
elif [[ "$(uname)" == "Linux" ]]; then
    if [[ $(cat /sys/class/power_supply/BAT*/status 2>/dev/null) == "Discharging" ]]; then
        echo "battery"
    else
        echo "AC"
    fi
else
    echo "unknown"
fi

