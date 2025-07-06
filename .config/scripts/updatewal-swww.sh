#!/bin/bash
#  _____ _                           ______        ____        ____        __ 
# |_   _| |__   ___ _ __ ___   ___  / ___\ \      / /\ \      / /\ \      / / 
#   | | | '_ \ / _ \ '_ ` _ \ / _ \ \___ \\ \ /\ / /  \ \ /\ / /  \ \ /\ / /  
#   | | | | | |  __/ | | | | |  __/  ___) |\ V  V /    \ V  V /    \ V  V /   
#   |_| |_| |_|\___|_| |_| |_|\___| |____/  \_/\_/      \_/\_/      \_/\_/    
#                                                                                
# ----------------------------------------------------- 

# ----------------------------------------------------- 
# Select random wallpaper and create color scheme
# ----------------------------------------------------- 
wal -i ~/Pictures/wallpapers/ -e

# ----------------------------------------------------- 
# Copy color file to waybar folder
# ----------------------------------------------------- 
#cp ~/.cache/wal/colors-waybar.css ~/dotfiles/waybar/

# ----------------------------------------------------- 
# get wallpaper image name
# ----------------------------------------------------- 
wallpaper=$(<~/.cache/wal/wal)
newwall=$(basename "$wallpaper")
#newwall=$(echo $wallpaper | sed "s|$HOME/Pictures/wallpapers/||g")

# ----------------------------------------------------- 
# Set the new wallpaper
# ----------------------------------------------------- 
swww img $wallpaper --transition-step 20 --transition-fps=20 --transition-type any
pywalfox update
#killall waybar && waybar &
~/.config/waybar/launch.sh

# ----------------------------------------------------- 
# Send notification
# ----------------------------------------------------- 
notify-send "Theme and Wallpaper updated" "With image $newwall"

echo "DONE!"

