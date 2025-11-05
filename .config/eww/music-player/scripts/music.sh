#!/bin/bash

# Music player control script using playerctl
# Supports all MPRIS-compatible players

CACHE_DIR="$HOME/.cache/eww/music"
PLAYER_FILE="$CACHE_DIR/current_player"
DEFAULT_ART="$HOME/.config/eww/music-player/default-cover.png"
ART_CACHE="$CACHE_DIR/album_art.jpg"
LAST_TRACK_FILE="$CACHE_DIR/last_track"
POSITION_CACHE="$CACHE_DIR/last_position"

mkdir -p "$CACHE_DIR"

# Get current player or auto-select
get_player() {
  if [ -f "$PLAYER_FILE" ]; then
    SAVED_PLAYER=$(cat "$PLAYER_FILE")
    # Check if saved player still exists
    if playerctl -l 2>/dev/null | grep -q "$SAVED_PLAYER"; then
      echo "$SAVED_PLAYER"
      return
    fi
  fi

  # Auto-select first available player
  FIRST_PLAYER=$(playerctl -l 2>/dev/null | head -n1)
  if [ -n "$FIRST_PLAYER" ]; then
    echo "$FIRST_PLAYER" >"$PLAYER_FILE"
    echo "$FIRST_PLAYER"
  fi
}

# Download and cache album art
download_art() {
  local url="$1"
  local player="$2"

  if [ -z "$url" ] || [ "$url" = "" ]; then
    echo "$DEFAULT_ART"
    return
  fi

  # Get track ID to create unique filename
  local track_id=$(echo "$url" | md5sum | cut -d' ' -f1)
  local cached_file="$CACHE_DIR/art_${track_id}.jpg"

  # Return cached file if exists
  if [ -f "$cached_file" ]; then
    echo "$cached_file"
    return
  fi

  # Handle different URL types
  if [[ "$url" == file://* ]]; then
    # Local file (browsers)
    local local_path="${url#file://}"
    if [ -f "$local_path" ]; then
      cp "$local_path" "$cached_file" 2>/dev/null
      echo "$cached_file"
    else
      echo "$DEFAULT_ART"
    fi
  elif [[ "$url" == http://* ]] || [[ "$url" == https://* ]]; then
    # Remote file (Spotify, streaming services)
    curl -s -L "$url" -o "$cached_file" 2>/dev/null
    if [ -f "$cached_file" ] && [ -s "$cached_file" ]; then
      echo "$cached_file"
    else
      echo "$DEFAULT_ART"
    fi
  else
    echo "$DEFAULT_ART"
  fi
}

# Format time from microseconds
format_time() {
  local microseconds=$1
  local seconds=$((microseconds / 1000000))
  local minutes=$((seconds / 60))
  local remaining_seconds=$((seconds % 60))
  printf "%d:%02d" $minutes $remaining_seconds
}

# Get current track signature
get_track_signature() {
  local player="$1"
  local title=$(playerctl -p "$player" metadata title 2>/dev/null || echo "")
  local artist=$(playerctl -p "$player" metadata artist 2>/dev/null || echo "")
  echo "${player}:${title}:${artist}"
}

# Save last known good position
save_position() {
  local player="$1"
  local position="$2"
  echo "$position" >"$POSITION_CACHE"
}

# Get position with browser fix
get_position() {
  local player="$1"
  local position=$(playerctl -p "$player" position 2>/dev/null || echo "0")
  local status=$(playerctl -p "$player" status 2>/dev/null || echo "Stopped")

  # For browsers, verify position isn't jumping
  if [[ "$player" =~ (firefox|brave|chromium|chrome) ]]; then
    if [ -f "$POSITION_CACHE" ]; then
      local last_pos=$(cat "$POSITION_CACHE")
      local pos_sec=$(printf "%.0f" "$position" 2>/dev/null || echo "0")
      local last_pos_sec=$(printf "%.0f" "$last_pos" 2>/dev/null || echo "0")

      # If position jumped more than 5 seconds backwards or way forward (likely a bug)
      local diff=$((pos_sec - last_pos_sec))
      if [ "$diff" -lt -5 ] || [ "$diff" -gt 10 ]; then
        # Use last known position if status just changed to Playing
        if [ "$status" = "Playing" ] && [ "$diff" -gt 10 ]; then
          position="$last_pos"
        fi
      fi
    fi
    save_position "$player" "$position"
  fi

  echo "$position"
}

case "$1" in
status)
  PLAYER=$(get_player)
  if [ -z "$PLAYER" ]; then
    echo '{"status":"Stopped","title":"No player found","artist":"","art":"","position":0,"length":0,"volume":50,"player":"none"}'
    exit 0
  fi

  STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null || echo "Stopped")
  TITLE=$(playerctl -p "$PLAYER" metadata title 2>/dev/null || echo "Unknown")
  ARTIST=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null || echo "Unknown Artist")

  # Get album art and download it
  ART_URL=$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null)
  ART=$(download_art "$ART_URL" "$PLAYER")

  # Get position with browser fix
  POSITION=$(get_position "$PLAYER")
  LENGTH=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null || echo "0")

  # Convert to seconds for position
  POSITION_SEC=$(printf "%.0f" "$POSITION" 2>/dev/null || echo "0")
  LENGTH_SEC=$((LENGTH / 1000000))

  # Calculate percentage
  if [ "$LENGTH_SEC" -gt 0 ]; then
    PERCENT=$((POSITION_SEC * 100 / LENGTH_SEC))
  else
    PERCENT=0
  fi

  # Get volume
  VOLUME=$(playerctl -p "$PLAYER" volume 2>/dev/null | awk '{print int($1 * 100)}' || echo "50")

  # Save current track signature
  TRACK_SIG=$(get_track_signature "$PLAYER")
  echo "$TRACK_SIG" >"$LAST_TRACK_FILE"

  echo "{\"status\":\"$STATUS\",\"title\":\"$TITLE\",\"artist\":\"$ARTIST\",\"art\":\"$ART\",\"position\":$PERCENT,\"length\":$LENGTH_SEC,\"volume\":$VOLUME,\"player\":\"$PLAYER\"}"
  ;;

listen)
  # Real-time listening for changes
  WHAT="$2"

  case "$WHAT" in
  status)
    PLAYER=$(get_player)
    playerctl -p "$PLAYER" -F status 2>/dev/null || echo "Stopped"
    ;;
  title)
    PLAYER=$(get_player)
    LAST_TITLE=""
    playerctl -p "$PLAYER" -F metadata title 2>/dev/null | while read -r title; do
      if [ "$title" != "$LAST_TITLE" ]; then
        echo "$title"
        LAST_TITLE="$title"
        # Clear position cache on track change
        rm -f "$POSITION_CACHE"
      fi
    done
    ;;
  artist)
    PLAYER=$(get_player)
    playerctl -p "$PLAYER" -F metadata artist 2>/dev/null || echo ""
    ;;
  art)
    PLAYER=$(get_player)
    LAST_ART=""
    playerctl -p "$PLAYER" -F metadata mpris:artUrl 2>/dev/null | while read -r url; do
      if [ "$url" != "$LAST_ART" ]; then
        ART=$(download_art "$url" "$PLAYER")
        echo "$ART"
        LAST_ART="$url"
      fi
    done
    ;;
  position-percent)
    while true; do
      PLAYER=$(get_player)
      if [ -n "$PLAYER" ]; then
        POSITION=$(get_position "$PLAYER")
        LENGTH=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null || echo "0")
        POSITION_SEC=$(printf "%.0f" "$POSITION" 2>/dev/null || echo "0")
        LENGTH_SEC=$((LENGTH / 1000000))

        if [ "$LENGTH_SEC" -gt 0 ]; then
          PERCENT=$((POSITION_SEC * 100 / LENGTH_SEC))
        else
          PERCENT=0
        fi
        echo "$PERCENT"
      else
        echo "0"
      fi
      sleep 1
    done
    ;;
  position-time)
    while true; do
      PLAYER=$(get_player)
      if [ -n "$PLAYER" ]; then
        POSITION=$(get_position "$PLAYER")
        POSITION_SEC=$(printf "%.0f" "$POSITION" 2>/dev/null || echo "0")
        format_time $((POSITION_SEC * 1000000))
      else
        echo "0:00"
      fi
      sleep 1
    done
    ;;
  length-time)
    PLAYER=$(get_player)
    playerctl -p "$PLAYER" -F metadata mpris:length 2>/dev/null | while read -r length; do
      format_time "$length"
    done || echo "0:00"
    ;;
  volume)
    PLAYER=$(get_player)
    playerctl -p "$PLAYER" -F volume 2>/dev/null | awk '{print int($1 * 100)}' || echo "50"
    ;;
  current-player)
    LAST_PLAYER=""
    while true; do
      PLAYER=$(get_player)
      if [ "$PLAYER" != "$LAST_PLAYER" ]; then
        echo "$PLAYER"
        LAST_PLAYER="$PLAYER"
        # Clear caches on player change
        rm -f "$POSITION_CACHE"
      fi
      sleep 1
    done
    ;;
  players)
    while true; do
      PLAYERS=$(playerctl -l 2>/dev/null | tr '\n' ',' | sed 's/,$//' | awk '{print "[\"" $0 "\"]"}' | sed 's/,/","/g')
      if [ -z "$PLAYERS" ]; then
        echo "[]"
      else
        echo "$PLAYERS"
      fi
      sleep 2
    done
    ;;
  players-count)
    while true; do
      playerctl -l 2>/dev/null | wc -l
      sleep 2
    done
    ;;
  esac
  ;;

play-pause)
  PLAYER=$(get_player)
  [ -n "$PLAYER" ] && playerctl -p "$PLAYER" play-pause
  ;;

next)
  PLAYER=$(get_player)
  [ -n "$PLAYER" ] && playerctl -p "$PLAYER" next
  ;;

previous)
  PLAYER=$(get_player)
  [ -n "$PLAYER" ] && playerctl -p "$PLAYER" previous
  ;;

seek)
  PLAYER=$(get_player)
  if [ -n "$PLAYER" ]; then
    PERCENT="$2"
    LENGTH=$(playerctl -p "$PLAYER" metadata mpris:length 2>/dev/null || echo "0")
    LENGTH_SEC=$((LENGTH / 1000000))
    POSITION_SEC=$((LENGTH_SEC * PERCENT / 100))
    playerctl -p "$PLAYER" position "$POSITION_SEC"
  fi
  ;;

volume)
  PLAYER=$(get_player)
  if [ -n "$PLAYER" ]; then
    VOLUME="$2"
    VOLUME_DECIMAL=$(echo "scale=2; $VOLUME / 100" | bc)
    playerctl -p "$PLAYER" volume "$VOLUME_DECIMAL"
  fi
  ;;

switch)
  NEW_PLAYER="$2"
  echo "$NEW_PLAYER" >"$PLAYER_FILE"
  # Clear caches when switching players
  rm -f "$POSITION_CACHE" "$LAST_TRACK_FILE"
  # Trigger refresh by touching the player file
  touch "$PLAYER_FILE"
  ;;

*)
  echo "Usage: $0 {status|listen|play-pause|next|previous|seek|volume|switch}"
  exit 1
  ;;
esac
