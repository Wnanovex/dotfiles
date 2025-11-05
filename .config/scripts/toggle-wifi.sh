#!/bin/bash

# Detect current Wi-Fi state
wifi_status=$(nmcli radio wifi)

if [ "$wifi_status" = "enabled" ]; then
  # Wi-Fi is ON → turn it OFF
  nmcli radio wifi off
  notify-send "Wi-Fi Disabled" "Wireless networking has been turned off"
  echo "false" # swaync expects this to set toggle state to off
else
  # Wi-Fi is OFF → turn it ON
  nmcli radio wifi on
  notify-send "Wi-Fi Enabled" "Wireless networking has been turned on"
  echo "true" # swaync expects this to set toggle state to on
fi
