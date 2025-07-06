#!/bin/bash
#  _____ _                                       _ _       _                
# |_   _| |__   ___ _ __ ___   ___  _____      _(_) |_ ___| |__   ___ _ __  
#   | | | '_ \ / _ \ '_ ` _ \ / _ \/ __\ \ /\ / / | __/ __| '_ \ / _ \ '__| 
#   | | | | | |  __/ | | | | |  __/\__ \\ V  V /| | || (__| | | |  __/ |    
#   |_| |_| |_|\___|_| |_| |_|\___||___/ \_/\_/ |_|\__\___|_| |_|\___|_|    
#                                                                            
# ----------------------------------------------------- 
 
themes_launch_path="$HOME/.config/waybar/launch.sh"

options=(
    "style-1"
    "style-2"
    "style-3"
)

rofi_cmd() {
	rofi -markup -dmenu \
		-p "themes" \
		-theme "$HOME"/.config/rofi/scripts/waybar-themes/config-themes.rasi 
}

chosen=$(printf "%s\n" "${options[@]}" | rofi_cmd)

case $chosen in
    "style-1")
        $themes_launch_path style-1
        ;;
    "style-2")
        $themes_launch_path style-2
        ;;
    "style-3")
        $themes_launch_path style-3
        ;;
esac
