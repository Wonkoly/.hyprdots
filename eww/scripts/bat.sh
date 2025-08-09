#!/usr/bin/env bash
set -euo pipefail

BAT="${BAT:-BAT0}"
path="/sys/class/power_supply/$BAT"
if [ ! -d "$path" ]; then
  echo "bat?"
  exit 0
fi

cap=$(cat "$path/capacity")
stat=$(cat "$path/status")
icon="󰁹"
[ "$cap" -ge 90 ] && icon="󰁹" ||
  [ "$cap" -ge 75 ] && icon="󰂂" ||
  [ "$cap" -ge 50 ] && icon="󰂀" ||
  [ "$cap" -ge 25 ] && icon="󰁿" || icon="󰁺"

[ "$stat" = "Charging" ] && icon="󰂄"
echo "$icon ${cap}%"
