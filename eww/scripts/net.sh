#!/usr/bin/env bash
set -euo pipefail

if command -v nmcli >/dev/null 2>&1; then
  ssid=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2}')
  if [ -n "${ssid:-}" ]; then
    echo "󰖩 ${ssid}"
  else
    state=$(nmcli -t -f STATE g)
    [ "$state" = "connected" ] && echo "󰈁 LAN" || echo "󰖪 sin red"
  fi
else
  echo "net?"
fi
