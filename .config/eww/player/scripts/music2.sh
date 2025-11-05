#!/bin/bash
# Outputs: title\nartist\nartPath\nstatus\nplayerName

STATE_FILE="$HOME/.cache/eww-current-player"
#COVER_FILE="$HOME/.cache/eww-cover.png"
PREV_TRACK="$HOME/.cache/eww-prev-track"

players=$(playerctl -l 2>/dev/null)

if [ -z "$players" ]; then
  echo -e "No Players\n \n \nStopped\nnone\n0\n0"
  exit 0
fi

# Read selected player or default to first
if [ -f "$STATE_FILE" ]; then
  current=$(cat "$STATE_FILE")
else
  current=$(echo "$players" | head -n 1)
  #echo "$current" >"$STATE_FILE"
  echo "spotify" >"$STATE_FILE"
fi

# Validate current player still exists
if ! echo "$players" | grep -q "$current"; then
  current=$(echo "$players" | head -n 1)
  echo "$current" >"$STATE_FILE"
fi

title=$(playerctl -p "$current" metadata xesam:title 2>/dev/null)
artist=$(playerctl -p "$current" metadata xesam:artist 2>/dev/null)
artUrl=$(playerctl -p "$current" metadata mpris:artUrl 2>/dev/null)
status=$(playerctl -p "$current" status 2>/dev/null)

# Get position and length (in seconds)
position=$(playerctl -p "$current" position 2>/dev/null || echo "0")

# Get length in microseconds and convert to seconds
length_micro=$(playerctl -p "$current" metadata mpris:length 2>/dev/null || echo "0")
if [[ "$length_micro" =~ ^[0-9]+$ ]] && [ "$length_micro" -gt 0 ]; then
  length=$((length_micro / 1000000))
else
  length="0"
fi

# Function to truncate a string to N characters and add …
truncate_string() {
  local str="$1"
  local len="$2"
  if [ ${#str} -gt "$len" ]; then
    echo "${str:0:len}…"
  else
    echo "$str"
  fi
}

# Truncate to 30 characters
title=$(truncate_string "$title" 30)
artist=$(truncate_string "$artist" 30)

title=${title:-Unknown}
artist=${artist:-Unknown}
status=${status:-Stopped}
position=${position:-0}
length=${length:-0}

# Combine title+artist as track ID
track_id="${title} - ${artist} - ${current}"

COVER_FILE="$HOME/.cache/eww-cover-$current.png"

# Only update cover if track changed
if [ "$(cat "$PREV_TRACK" 2>/dev/null)" != "$track_id" ]; then
  echo "$track_id" >"$PREV_TRACK"

  if [[ "$artUrl" == https* ]]; then
    curl -sL "$artUrl" -o "$COVER_FILE"

    artPath="$COVER_FILE"

  elif [[ "$artUrl" == file://* ]]; then
    local_path="${artUrl#file://}"
    cp "$local_path" "$COVER_FILE"
    sleep 1
    artPath="$COVER_FILE"
  else
    artPath=""
  fi

  # 🔧 Normalize cover size
  #if [ -f "$COVER_FILE" ]; then
  #  ffmpeg -y -i "$COVER_FILE" -vf "scale='min(335,iw)':'min(190,ih)'" "$COVER_FILE" &>/dev/null
  #  sleep 2
  #fi

else
  # Track same as before, reuse existing cover
  artPath="$COVER_FILE"
fi

# Print each field on a separate line
echo -e "$title\n$artist\n$artPath\n$status\n$current\n$position\n$length"
