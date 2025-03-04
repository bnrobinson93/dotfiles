#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    if [[ $(pmset -g ps | head -1) =~ "Battery Power" ]]; then
        echo -n "battery"
    else
        echo -n "AC"
    fi
elif [[ "$(uname)" == "Linux" ]]; then
    if [[ $(cat /sys/class/power_supply/BAT*/status 2>/dev/null) == "Discharging" ]]; then
        echo -n "battery"
    else
        echo -n "AC"
    fi
else
    echo -n "unknown"
fi
