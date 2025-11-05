#!/bin/bash
pos=$(bash ~/.config/eww/player/scripts/music.sh | sed -n 6p)
if [ -z "$pos" ]; then
    pos=0
fi
# Handle floating point numbers by converting to integer
pos_int=$(printf "%.0f" "$pos" 2>/dev/null || echo "0")
minutes=$((pos_int/60))
seconds=$((pos_int%60))
printf "%02d:%02d" $minutes $seconds
