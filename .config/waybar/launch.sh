#!/bin/bash

CONFIG_DIR="$HOME/.config/waybar"
CURRENT_THEME_FILE="$CONFIG_DIR/current_theme"
THEMES_DIR="$CONFIG_DIR/themes"
MODULES="$CONFIG_DIR/modules.jsonc"

# Get theme: from argument or file
if [[ -n "$1" ]]; then
  THEME="$1"
  echo "$THEME" > "$CURRENT_THEME_FILE"
elif [[ -f "$CURRENT_THEME_FILE" ]]; then
  THEME=$(<"$CURRENT_THEME_FILE")
else
  echo "No theme specified and no current theme set."
  exit 1
fi

THEME_DIR="$THEMES_DIR/$THEME"
GLOBAL_CONFIG="$THEME_DIR/config.jsonc"
STYLE_FILE="$THEME_DIR/style.css"

# Check existence
if [[ ! -f "$GLOBAL_CONFIG" || ! -f "$STYLE_FILE" ]]; then
  echo "Theme '$THEME' not found or missing files."
  exit 1
fi

# Kill existing Waybar
pkill waybar

# Launch Waybar with in-memory merged config
waybar -c "$GLOBAL_CONFIG" -s "$STYLE_FILE" &

