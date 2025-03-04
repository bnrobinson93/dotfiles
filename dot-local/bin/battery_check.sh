#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    if [[ $(pmset -g ps | head -1) =~ "Battery Power" ]]; then
        exit 0
    else
        exit 1
    fi
elif [[ "$(uname)" == "Linux" ]]; then
    if [[ $(cat /sys/class/power_supply/BAT*/status 2>/dev/null) == "Discharging" ]]; then
        exit 0
    else
        exit 1
    fi
else
    exit 2
fi
