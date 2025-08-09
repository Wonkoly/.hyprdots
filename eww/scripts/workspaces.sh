#!/usr/bin/env bash
set -euo pipefail

# Obtiene workspaces y el activo
active_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')
hyprctl workspaces -j 2>/dev/null | jq -c --argjson active "$active_ws" '
  map({
    id: .id,
    name: (if .name == "" then (.id|tostring) else .name end),
    active: (.id == $active)
  })'
