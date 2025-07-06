#!/bin/bash

# Set paths
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
ROFI_THEME="$HOME/.config/rofi/scripts/wallpaper/wallpaper.rasi"

# Verify wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpaper Selector" "Directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Build Rofi input with icons
rofi_input=""
while IFS= read -r -d '' img; do
    name="$(basename "$img")"
    rofi_input+="$name\0icon\x1f$img\n"
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -print0)

# Show Rofi menu
selected=$(printf "%b" "$rofi_input" | rofi -dmenu -i -p "Select Wallpaper" \
    -show-icons -theme "$ROFI_THEME")

# Cancelled?
[ -z "$selected" ] && {
    notify-send "Wallpaper Selector" "No wallpaper selected."
    exit 0
}

# Full path to selected wallpaper
wallpaper_path="$WALLPAPER_DIR/$selected"

# Check if file exists
if [ ! -f "$wallpaper_path" ]; then
    notify-send "Wallpaper Selector" "File not found: $wallpaper_path"
    exit 1
fi

# Apply wallpaper and colors
wal -i "$wallpaper_path" -e
swww img "$wallpaper_path" --transition-type any --transition-fps 60 --transition-step 90
pywalfox update
#pkill waybar && waybar &
~/.config/waybar/launch.sh

notify-send "Wallpaper Changed" "$selected"

