#!/bin/bash

CURRENT_THEME_FILE="$HOME/.config/waybar/current_theme"

current_theme=$(<"$CURRENT_THEME_FILE")

killall swaync

case $current_theme in
"style-1")
  swaync -c ~/.config/swaync/themes/theme1/config.json -s ~/.config/swaync/themes/theme1/style.css
  ;;
"style-2")
  swaync -c ~/.config/swaync/themes/theme3/config.json -s ~/.config/swaync/themes/theme3/style.css
  ;;
"style-3")
  swaync -c ~/.config/swaync/themes/theme4/config.json -s ~/.config/swaync/themes/theme4/style.css
  ;;
esac
