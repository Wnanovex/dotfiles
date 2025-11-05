#!/bin/bash

# Check current mute status of default output (sink)
is_muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

if [ "$is_muted" = "yes" ]; then
  # Unmute
  pactl set-sink-mute @DEFAULT_SINK@ 0
  notify-send "Audio" "Volume unmuted"
  echo "true"   # swaync toggle ON (audio active)
else
  # Mute
  pactl set-sink-mute @DEFAULT_SINK@ 1
  notify-send "Audio" "Volume muted"
  echo "false"  # swaync toggle OFF (muted)
fi

