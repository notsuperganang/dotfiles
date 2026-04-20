#!/usr/bin/env bash
# ws12-mode.sh — Toggle & handle WS-lock 1–2
# usage:
#   ws12-mode.sh toggle   → ON/OFF mode + notifikasi
#   ws12-mode.sh next     → saat ON: 1↔2, saat OFF: fallback (r+1 atau ws-cycle.sh)

set -euo pipefail

LOCK_FILE="${HOME}/.cache/ws12.lock"
CMD="${1:-toggle}"

#notify() {
#  # butuh libnotify + daemon (swaync/dunst/gnome notif)
#  command -v notify-send >/dev/null && notify-send "$@"
#}

notify() {
  # libnotify CLI: -t dalam ms (30.000 = 30s)
  command -v notify-send >/dev/null && notify-send -t 10000 "$@"
}

toggle_mode() {
  if [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE"
    notify "Mode memasak nonaktif"
  else
    mkdir -p "$(dirname "$LOCK_FILE")"
    printf 'on' > "$LOCK_FILE"
    notify "Mode memasak aktif"
  fi
}

ws_next() {
  # Jika mode aktif → bolak-balik 1 <-> 2
  if [ -f "$LOCK_FILE" ]; then
    curr="$(hyprctl -j activeworkspace | jq -r '.id')"
    if [ "$curr" = "1" ]; then
      hyprctl dispatch workspace 2
    elif [ "$curr" = "2" ]; then
      hyprctl dispatch workspace 1
    else
      # di luar 1/2? lompat ke 1 dulu
      hyprctl dispatch workspace 1
    fi
  else
    # Mode OFF → perilaku normal. Panggil ws-cycle.sh jika ada, kalau tidak: r+1.
    if [ -x "${HOME}/.config/hypr/custom/scripts/ws-cycle.sh" ]; then
      "${HOME}/.config/hypr/custom/scripts/ws-cycle.sh" next
    else
      hyprctl dispatch workspace r+1
    fi
  fi
}

case "$CMD" in
  toggle) toggle_mode ;;
  next)   ws_next ;;
  *)      echo "usage: $0 {toggle|next}" >&2; exit 2 ;;
esac
