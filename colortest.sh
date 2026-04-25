#!/usr/bin/env bash

# single colors
echo -e "\e[35mmagenta\e[0m"
echo -e "\e[36mcyan\e[0m"
echo -e "\e[95mpink\e[0m" # bright magenta as "pink"
echo -e "\e[90mdarkgray\e[0m"

# list a set of common named colors (with names)
colors=(
  "black:\e[30m"
  "red:\e[31m"
  "green:\e[32m"
  "yellow:\e[33m"
  "blue:\e[34m"
  "magenta:\e[35m"
  "cyan:\e[36m"
  "white:\e[37m"
  "bright_black(darkgray):\e[90m"
  "bright_red:\e[91m"
  "bright_green:\e[92m"
  "bright_yellow:\e[93m"
  "bright_blue:\e[94m"
  "bright_magenta(pink):\e[95m"
  "bright_cyan:\e[96m"
  "bright_white:\e[97m"
)

for entry in "${colors[@]}"; do
  name="${entry%%:*}"
  code="${entry#*:}"
  echo -e "${code}${name}\e[0m"
done
