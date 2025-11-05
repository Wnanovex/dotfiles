#!/bin/bash
# Outputs: title\nartist\nartPath\nstatus\nplayerName

PREV_TRACK="$HOME/.cache/eww-prev-track"

player="spotify"

title=$(playerctl -p "$player" metadata xesam:title 2>/dev/null)
artist=$(playerctl -p "$player" metadata xesam:artist 2>/dev/null)
artUrl=$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null)
status=$(playerctl -p "$player" status 2>/dev/null)

# Get position and length (in seconds)
position=$(playerctl -p "$player" position 2>/dev/null || echo "0")

# Get length in microseconds and convert to seconds
length_micro=$(playerctl -p "$player" metadata mpris:length 2>/dev/null || echo "0")
if [[ "$length_micro" =~ ^[0-9]+$ ]] && [ "$length_micro" -gt 0 ]; then
  length=$((length_micro / 1000000))
else
  length="0"
fi

title=${title:-Unknown}
artist=${artist:-Unknown}
status=${status:-Stopped}
position=${position:-0}
length=${length:-0}

# Combine title+artist as track ID
track_id="${title} - ${artist} - ${player}"

COVER_FILE="$HOME/.cache/eww-cover-$player.png"

# Only update cover if track changed
if [ "$(cat "$PREV_TRACK" 2>/dev/null)" != "$track_id" ]; then
  echo "$track_id" >"$PREV_TRACK"

  curl -sL "$artUrl" -o "$COVER_FILE"
  artPath="$COVER_FILE"
else
  # Track same as before, reuse existing cover
  artPath="$COVER_FILE"
fi

# Print each field on a separate line
echo -e "$title\n$artist\n$artPath\n$status\n$player\n$position\n$length"
