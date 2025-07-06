#!/bin/bash


CURRENT_THEME_FILE="$HOME/.config/waybar/current_theme"

current_theme=$(<"$CURRENT_THEME_FILE")

case $current_theme in
    "style-1")
        rofi -show drun -theme ~/.config/rofi/scripts/hyprland-app-launcher/style-1.rasi
        ;;
    "style-2")
        rofi -show drun -theme ~/.config/rofi/scripts/hyprland-app-launcher/style-2.rasi
        ;;
    "style-3")
        rofi -show drun -theme ~/.config/rofi/scripts/hyprland-app-launcher/style-3.rasi
        ;;
esac
