#!/bin/bash

# Check current mute status of default input (source)
is_muted=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')

if [ "$is_muted" = "yes" ]; then
  # Unmute mic
  pactl set-source-mute @DEFAULT_SOURCE@ 0
  notify-send "Microphone" "Microphone unmuted"
  echo "true"   # swaync toggle ON (mic active)
else
  # Mute mic
  pactl set-source-mute @DEFAULT_SOURCE@ 1
  notify-send "Microphone" "Microphone muted"
  echo "false"  # swaync toggle OFF (mic muted)
fi

