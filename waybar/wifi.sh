#!/usr/bin/env bash
set -euo pipefail

# --- Listado Wi‑Fi
mapfile -t nets < <(nmcli -t -f SSID,SECURITY,SIGNAL,IN-USE dev wifi list |
  awk -F: 'length($1)>0 {print $1 "|" $2 "|" $3 "|" $4}' |
  awk '!seen[$1]++')

format_line() {
  local ssid="$1" sec="$2" sig="$3" used="$4"
  local wifi=""
  local mark=""
  [[ "$used" == "*" ]] && mark="✓ "
  [[ -z "$sig" ]] && sig=0
  local bars="▱▱▱▱"
  ((sig >= 80)) && bars="▰▰▰▰" ||
    ((sig >= 60)) && bars="▰▰▰▱" ||
    ((sig >= 40)) && bars="▰▰▱▱" ||
    ((sig >= 20)) && bars="▰▱▱▱"
  local lock=""
  [[ "$sec" != "--" ]] && lock=""
  echo -e "${mark}${wifi}  ${ssid}  ${lock}  ${bars}"
}

menu=""
declare -A map
for n in "${nets[@]}"; do
  ssid="${n%%|*}"
  rest="${n#*|}"
  sec="${rest%%|*}"
  rest2="${rest#*|}"
  sig="${rest2%%|*}"
  used="${rest2##*|}"
  line=$(format_line "$ssid" "$sec" "$sig" "$used")
  menu+="$line"$'\n'
  map["$line"]="$ssid|$sec"
done

choice=$(printf "%s" "$menu" | wofi --dmenu -p "Wi‑Fi" -H 400 -W 500)
[[ -z "${choice:-}" ]] && exit 0

sel="${map[$choice]}"
ssid="${sel%%|*}"
sec="${sel##*|}"

# --- ¿La red requiere password?
needs_pass=0
if [[ "$sec" != "--" ]]; then
  needs_pass=1
fi

connect_simple() {
  if ((needs_pass)); then
    pass=$(wofi --dmenu -P -p "Contraseña para ${ssid}")
    [[ -z "${pass:-}" ]] && exit 1
    nmcli -w 15 device wifi connect "$ssid" password "$pass" && return 0
  else
    nmcli -w 15 device wifi connect "$ssid" && return 0
  fi
  return 1
}

# 1) Intento simple (NM autodetecta key-mgmt)
if connect_simple; then
  notify-send "Wi‑Fi" "Conectado a $ssid"
  exit 0
fi

# 2) Si falla, probamos forzar key-mgmt según SECURITY
#    - WPA3/SAE
if grep -Eiq 'SAE|WPA3' <<<"$sec"; then
  if ((needs_pass)); then
    [[ -z "${pass:-}" ]] && pass=$(wofi --dmenu -P -p "Contraseña para ${ssid}")
    # borramos perfil previo roto si existe
    nmcli -g NAME c show | grep -Fx "$ssid" && nmcli c delete id "$ssid" || true
    nmcli c add type wifi ifname "*" con-name "$ssid" ssid "$ssid" \
      wifi-sec.key-mgmt sae wifi-sec.psk "$pass"
    nmcli c up "$ssid" && notify-send "Wi‑Fi" "Conectado a $ssid (SAE)" && exit 0
  fi
fi

#    - WPA/WPA2 PSK
if grep -Eiq 'WPA|RSN' <<<"$sec"; then
  if ((needs_pass)); then
    [[ -z "${pass:-}" ]] && pass=$(wofi --dmenu -P -p "Contraseña para ${ssid}")
    nmcli -g NAME c show | grep -Fx "$ssid" && nmcli c delete id "$ssid" || true
    nmcli c add type wifi ifname "*" con-name "$ssid" ssid "$ssid" \
      wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$pass"
    nmcli c up "$ssid" && notify-send "Wi‑Fi" "Conectado a $ssid (WPA-PSK)" && exit 0
  fi
fi

#    - Red abierta (sin pass)
if [[ "$sec" == "--" ]]; then
  nmcli -w 15 dev wifi connect "$ssid" && notify-send "Wi‑Fi" "Conectado a $ssid (abierta)" && exit 0
fi

# 3) Último recurso: diálogo nativo (pide todo y setea key-mgmt)
nmcli --ask -w 30 dev wifi connect "$ssid" && notify-send "Wi‑Fi" "Conectado a $ssid" && exit 0

notify-send "Wi‑Fi" "No se pudo conectar a $ssid"
exit 1
