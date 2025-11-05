#!/bin/bash

STATE_FILE="$HOME/.cache/eww-current-player"
PREV_TRACK="$HOME/.cache/eww-prev-track"

# Start watching metadata changes for all players
playerctl -a metadata --format '{{playerName}}|{{xesam:title}}|{{xesam:artist}}|{{mpris:artUrl}}' -F | while IFS='|' read -r player title artist artUrl; do
  if [ -z "$title" ]; then
    continue
  fi

  track_id="${title} - ${artist} - ${player}"
  COVER_FILE="$HOME/.cache/eww-cover-$player.png"

  # Only update if track changed
  if [ "$(cat "$PREV_TRACK" 2>/dev/null)" != "$track_id" ]; then
    echo "$track_id" > "$PREV_TRACK"

    # Download or copy cover
    if [[ "$artUrl" == https* ]]; then
      curl -sL "$artUrl" -o "$COVER_FILE"
    elif [[ "$artUrl" == file://* ]]; then
      local_path="${artUrl#file://}"
      cp "$local_path" "$COVER_FILE"
    else
      continue
    fi

    # Normalize image size
    if [ -f "$COVER_FILE" ]; then
      ffmpeg -y -i "$COVER_FILE" -vf "scale='min(335,iw)':'min(190,ih)'" "$COVER_FILE" &>/dev/null
    fi

    # Force Eww to reload (optional)
    eww update music-art="$COVER_FILE" 2>/dev/null
  fi
done

