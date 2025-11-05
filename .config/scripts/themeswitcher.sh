#!/bin/bash
#  _____ _                                       _ _       _                
# |_   _| |__   ___ _ __ ___   ___  _____      _(_) |_ ___| |__   ___ _ __  
#   | | | '_ \ / _ \ '_ ` _ \ / _ \/ __\ \ /\ / / | __/ __| '_ \ / _ \ '__| 
#   | | | | | |  __/ | | | | |  __/\__ \\ V  V /| | || (__| | | |  __/ |    
#   |_| |_| |_|\___|_| |_| |_|\___||___/ \_/\_/ |_|\__\___|_| |_|\___|_|    
#                                                                            
# ----------------------------------------------------- 
 
waybar_themes_launch_path="$HOME/.config/waybar/launch.sh"
swaync_themes_launch_path="$HOME/.config/swaync/launch.sh"

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
        $waybar_themes_launch_path style-1
				$swaync_themes_launch_path
        ;;
    "style-2")
        $waybar_themes_launch_path style-2
				$swaync_themes_launch_path
        ;;
    "style-3")
        $waybar_themes_launch_path style-3
				$swaync_themes_launch_path
        ;;
esac
