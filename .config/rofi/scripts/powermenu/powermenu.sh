#!/bin/bash

options=(
    "󰍁"
    ""
    "󰗽"
    "󰜉"
    "󰐥"
)

rofi_cmd() {
	rofi -markup -dmenu \
		-p "Goodbye ${USER}" \
		-mesg "Uptime: $(uptime -p | sed -e 's/up //g')" \
		-theme "$HOME"/.config/rofi/scripts/powermenu/powermenu.rasi 
}

chosen=$(printf "%s\n" "${options[@]}" | rofi_cmd)

case $chosen in
    "󰐥")
        systemctl poweroff
        ;;
    "󰜉")
        systemctl reboot
        ;;
    "󰍁")
        betterlockscreen -l
        ;;
    "")
        mpc -q pause
        amixer set Master mute
        betterlockscreen -l ; systemctl suspend
        ;;
    "󰗽")
        bspc quit
        ;;
esac
