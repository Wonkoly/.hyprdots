#!/usr/bin/env bash
set -euo pipefail

mem=$(free -m | awk '/^Mem:/ {printf("%.0f", $3/$2*100)}')
echo "󰘚 ${mem}%"
