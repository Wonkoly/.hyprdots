#!/usr/bin/env bash
# volume.sh — PipeWire (wpctl) helpers
# Uso:
#   volume.sh percent  -> imprime 0..100
#   volume.sh muted    -> imprime true|false
#   volume.sh set N    -> fija volumen a N% (0..100)
#   volume.sh mute     -> toggle mute

SINK='@DEFAULT_AUDIO_SINK@'

percent() {
  line="$(wpctl get-volume "$SINK" 2>/dev/null || true)"
  if [ -z "$line" ]; then
    echo 0
    exit 0
  fi
  vol=$(awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9]*\.[0-9]+$/) {print $i; exit}}' <<<"$line")
  awk -v v="$vol" 'BEGIN{printf "%d\n", (v*100)+0.5}'
}

muted() {
  line="$(wpctl get-volume '@DEFAULT_AUDIO_SINK@' 2>/dev/null || true)"
  grep -q '\[MUTED\]' <<<"$line" && echo 1 || echo 0
}

setvol() {
  n="$1"
  [ -z "$n" ] && exit 1
  [ "$n" -lt 0 ] && n=0
  [ "$n" -gt 100 ] && n=100
  val=$(awk -v p="$n" 'BEGIN{printf "%.2f", p/100}')
  wpctl set-volume "$SINK" "$val" >/dev/null
}

togglemute() { wpctl set-mute "$SINK" toggle >/dev/null; }

case "$1" in
percent) percent ;;
muted) muted ;;
set) setvol "$2" ;;
mute) togglemute ;;
*)
  echo "usage: $0 {percent|muted|set <0-100>|mute}" >&2
  exit 2
  ;;
esac
