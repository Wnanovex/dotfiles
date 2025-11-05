#!/bin/bash
CONFIG="$HOME/.config/eww/player"
WINDOW="music-player"

if eww -c "$CONFIG" active-windows | grep -q "$WINDOW"; then
  eww -c "$CONFIG" close "$WINDOW"
else
  eww -c "$CONFIG" open "$WINDOW"
fi
