#!/bin/bash

options=(
    "blocks"
    "grayblocks"
    "material"
    "shades"
    "shapes"
)

rofi_cmd() {
	rofi -dmenu \
		-theme "$HOME"/.config/rofi/scripts/polybar-themes/polybar-themes.rasi 
}

chosen=$(printf "%s\n" "${options[@]}" | rofi_cmd)

case $chosen in
    "blocks")
         ~/.config/polybar/blocks/./launch.sh
        ;;
    "grayblocks")
         ~/.config/polybar/grayblocks/./launch.sh
        ;;
    "material")
         ~/.config/polybar/material/./launch.sh
        ;;
    "shades")
         ~/.config/polybar/shades/./launch.sh
        ;;
    "shapes")
         ~/.config/polybar/shapes/./launch.sh
        ;;
esac

