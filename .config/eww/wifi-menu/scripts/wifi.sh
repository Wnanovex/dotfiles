#!/bin/bash

# WiFi management script for eww
# Uses nmcli (NetworkManager)

CACHE_DIR="$HOME/.cache/eww/wifi"
SELECTED_FILE="$CACHE_DIR/selected_ssid"
PASSWORD_FILE="$CACHE_DIR/password"
EWW_CONFIG="-c $HOME/.config/eww/wifi-menu"

mkdir -p "$CACHE_DIR"

# Helper function to update eww variables (non-blocking)
eww_update() {
  eww $EWW_CONFIG update "$@" &
}

case "$1" in
list)
  # Get list of available networks
  nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE device wifi list |
    awk -F: '{
            if ($1 != "" && $1 != "--") {
                ssid = $1
                signal = $2
                security = ($3 == "" || $3 == "--") ? "no" : "yes"
                connected = ($4 == "yes") ? "yes" : "no"
                
                # Escape quotes in SSID
                gsub(/"/, "\\\"", ssid)
                
                printf "{\"ssid\":\"%s\",\"signal\":\"%s\",\"security\":\"%s\",\"connected\":\"%s\"},", ssid, signal, security, connected
            }
        }' | sed 's/,$//' | awk 'BEGIN{printf "["} {printf "%s", $0} END{printf "]"}'

  # If empty, return empty array
  if [ -z "$(nmcli -t -f SSID device wifi list 2>/dev/null)" ]; then
    echo "[]"
  fi
  ;;

scan)
  # Rescan for networks
  nmcli device wifi rescan 2>/dev/null
  sleep 1
  ;;

select)
  # Select a network to show action button
  SSID="$2"
  echo "$SSID" >"$SELECTED_FILE"

  # Check if currently connected to this network
  # Get active WiFi connection name
  CONNECTED=$(nmcli -t -f NAME,Device connection show --active | grep wlp0s20f3 | cut -d: -f1)

  if [ "$CONNECTED" = "$SSID" ]; then
    # Network is currently connected, show disconnect button
    eww_update selected-ssid="$SSID"
    eww_update show-action-section=true
    eww_update show-disconnect-button=true
    eww_update show-connect-button=false
    eww_update show-password-input=false
  else
    # Check if this network has saved credentials
    SAVED_CONNECTION=$(nmcli -t -f NAME connection show | grep "^$SSID$")

    if [ -n "$SAVED_CONNECTION" ]; then
      # Network has saved credentials, show connect button
      eww_update selected-ssid="$SSID"
      eww_update show-action-section=true
      eww_update show-connect-button=true
      eww_update show-disconnect-button=false
      eww_update show-password-input=false
    else
      # Check if network requires password
      # Get security info, handle special characters in SSID
      SECURITY=$(nmcli -t -f SSID,SECURITY device wifi list | grep -F "$SSID:" | head -n1 | cut -d: -f2)

      if [ -n "$SECURITY" ] && [ "$SECURITY" != "--" ] && [ "$SECURITY" != "" ]; then
        # Network is secured and new, show password input
        eww_update selected-ssid="$SSID"
        eww_update show-action-section=true
        eww_update show-password-input=true
        eww_update show-connect-button=false
        eww_update show-disconnect-button=false
        eww_update wifi-password=""
      else
        # Network is open, show connect button
        eww_update selected-ssid="$SSID"
        eww_update show-action-section=true
        eww_update show-connect-button=true
        eww_update show-disconnect-button=false
        eww_update show-password-input=false
      fi
    fi
  fi
  ;;

setpass)
  # Store password temporarily
  PASSWORD="$2"
  echo "$PASSWORD" >"$PASSWORD_FILE"
  eww_update wifi-password="$PASSWORD"
  ;;

connect)
  # Connect to selected network with password (for new networks)
  SSID="$2"
  PASSWORD="$3"

  if [ -z "$SSID" ]; then
    SSID=$(cat "$SELECTED_FILE" 2>/dev/null)
  fi

  if [ -z "$PASSWORD" ]; then
    PASSWORD=$(cat "$PASSWORD_FILE" 2>/dev/null)
  fi

  if [ -n "$SSID" ]; then
    # Try to connect
    if [ -n "$PASSWORD" ]; then
      nmcli device wifi connect "$SSID" password "$PASSWORD" >/dev/null 2>&1 &
    else
      nmcli device wifi connect "$SSID" >/dev/null 2>&1 &
    fi

    if [ $? -eq 0 ]; then
      notify-send "WiFi" "Connected to $SSID"
      eww_update show-action-section=false
      eww_update show-password-input=false
      eww_update show-connect-button=false
      eww_update show-disconnect-button=false
      eww_update wifi-password=""
      rm -f "$PASSWORD_FILE" "$SELECTED_FILE"
      sleep 0.5
      eww $EWW_CONFIG close wifi-menu &
    else
      notify-send "WiFi Error" "Failed to connect to $SSID\n$RESULT"
    fi
  else
    notify-send "WiFi Error" "SSID missing"
  fi
  ;;

connecttt)
  SSID="$2"
  PASSWORD="$3"

  if [ -z "$SSID" ]; then
    SSID=$(cat "$SELECTED_FILE" 2>/dev/null)
  fi

  if [ -z "$PASSWORD" ]; then
    PASSWORD=$(cat "$PASSWORD_FILE" 2>/dev/null)
  fi

  if [ -n "$SSID" ]; then
    # Show connecting notification immediately
    notify-send "WiFi" "Connecting to $SSID..." -t 5000

    # Run connection in background
    if [ -n "$PASSWORD" ]; then
      nmcli device wifi connect "$SSID" password "$PASSWORD" >/dev/null 2>&1 &
    else
      nmcli device wifi connect "$SSID" >/dev/null 2>&1 &
    fi
    CONNECT_PID=$!

    # Check connection status after delay
    (
      sleep 8
      if kill -0 $CONNECT_PID 2>/dev/null; then
        # Still running, might be hanging
        kill $CONNECT_PID 2>/dev/null
        notify-send "WiFi Error" "Connection timeout for $SSID"
      else
        # Check if we're actually connected
        if nmcli -t -f SSID device wifi | grep -q "^$SSID$"; then
          notify-send "WiFi" "Connected to $SSID"
          eww_update show-action-section=false
          eww_update show-password-input=false
          eww_update show-connect-button=false
          eww_update show-disconnect-button=false
          eww_update wifi-password=""
          rm -f "$PASSWORD_FILE" "$SELECTED_FILE"
          sleep 0.5
          eww $EWW_CONFIG close wifi-menu &
        else
          notify-send "WiFi Error" "Failed to connect to $SSID"
        fi
      fi
    ) &
  else
    notify-send "WiFi Error" "SSID missing"
  fi
  ;;

connect-saved)
  # Connect to a network with saved credentials
  SSID="$2"

  if [ -n "$SSID" ]; then
    # Connect using saved connection
    (nmcli connection up "$SSID" 2>&1 &)

    if [ $? -eq 0 ]; then
      notify-send "WiFi" "Connected to $SSID"
      eww_update show-action-section=false
      eww_update show-connect-button=false
      rm -f "$SELECTED_FILE"
      sleep 0.5
      eww $EWW_CONFIG close wifi-menu &
    else
      notify-send "WiFi Error" "Failed to connect to $SSID"
    fi
  fi
  ;;

cancel)
  # Cancel connection attempt
  eww_update show-action-section=false
  eww_update show-password-input=false
  eww_update show-connect-button=false
  eww_update show-disconnect-button=false
  eww_update selected-ssid=""
  eww_update wifi-password=""
  rm -f "$PASSWORD_FILE" "$SELECTED_FILE"
  ;;

forget)
  SSID="$2"
  nmcli connection delete "$SSID"
  eww_update show-action-section=false
  ;;

disconnect)
  # Disconnect from current network
  SSID="$2"

  # Get the connection name (might be different from SSID)
  CONNECTION=$(nmcli -t -f NAME,Device connection show --active | grep wlp0s20f3 | cut -d: -f1)

  if [ -n "$CONNECTION" ]; then
    (nmcli connection down "$CONNECTION" 2>&1 &)
    STATUS=$?

    if [ $STATUS -eq 0 ]; then
      notify-send "WiFi" "Disconnected from $SSID"
      eww_update show-action-section=false
      eww_update show-disconnect-button=false
      rm -f "$SELECTED_FILE"
    else
      notify-send "WiFi Error" "Failed to disconnect from $SSID"
    fi
  else
    notify-send "WiFi" "No active WiFi connection"
  fi
  ;;

*)
  echo "Usage: $0 {list|scan|select|setpass|connect|connect-saved|cancel|forget|disconnect}"
  exit 1
  ;;
esac
