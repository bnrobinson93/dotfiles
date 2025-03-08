#!/bin/bash

if git rev-parse --is-inside-work-tree -C "$(pwd)" &>/dev/null; then
    exit 0
else
    exit 1
fi
