#!/usr/bin/env bash
set -euo pipefail

sink="$(pactl get-default-sink 2>/dev/null || echo '')"
if [ -z "$sink" ]; then
  echo "vol?"
  exit 0
fi

vol=$(pactl get-sink-volume "$sink" | awk '{print $5}' | head -n1 | tr -d '%')
mute=$(pactl get-sink-mute "$sink" | awk '{print $2}')
icon="󰕾"
[ "$mute" = "yes" ] && icon="󰖁"
echo "$icon ${vol}%"
