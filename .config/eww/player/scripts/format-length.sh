#!/bin/bash
len=$(bash ~/.config/eww/player/scripts/music.sh | sed -n 7p)
if [ -z "$len" ]; then
    len=0
fi
# Handle floating point numbers by converting to integer
len_int=$(printf "%.0f" "$len" 2>/dev/null || echo "0")
minutes=$((len_int/60))
seconds=$((len_int%60))
printf "%02d:%02d" $minutes $seconds
