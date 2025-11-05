#!/bin/bash

# Set paths
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
ROFI_THEME="$HOME/.config/rofi/scripts/wallpaper/wallpaper.rasi"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
CACHE_FILE="$CACHE_DIR/wallpapers.cache"

# Verify wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
  notify-send "Wallpaper Selector" "Directory not found: $WALLPAPER_DIR"
  exit 1
fi

# Create cache directory
mkdir -p "$CACHE_DIR"

# Generate or update cache (only when wallpaper folder changes)
if [ ! -f "$CACHE_FILE" ] || [ "$WALLPAPER_DIR" -nt "$CACHE_FILE" ]; then
  rofi_input=""
  while IFS= read -r -d '' img; do
    name="$(basename "$img")"
    rofi_input+="$name\0icon\x1f$img\n"
  done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f -print0 | sort -z)
  printf "%b" "$rofi_input" >"$CACHE_FILE"
fi

# Show Rofi menu (reads from cache - much faster!)
selected=$(cat "$CACHE_FILE" | rofi -dmenu -i -p "Select Wallpaper" \
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

# Show notification immediately
notify-send "Wallpaper Changed" "$selected"

# Apply wallpaper in background (parallel execution)
{
  # Start swww and wal in parallel
  swww img "$wallpaper_path" --transition-type any --transition-fps 20 --transition-step 90 &
  wal -i "$wallpaper_path" -e -n -q &

  # Wait for both to finish
  wait

  # Then update UI components
  pywalfox update 2>/dev/null &
  ~/.config/waybar/launch.sh &

} >/dev/null 2>&1 &

# Exit immediately (background work continues)
exit 0
