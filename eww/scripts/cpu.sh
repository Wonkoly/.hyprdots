#!/usr/bin/env bash
set -euo pipefail

cpu=$(awk '/^cpu /{u=$2+$4; t=$2+$4+$5; printf("%.0f", u*100/t)}' /proc/stat)
echo "󰍛 ${cpu}%"
