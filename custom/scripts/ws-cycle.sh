#!/usr/bin/env bash
# ws-cycle.sh  — cycle workspaces limited to (used on active monitor) + 1
# usage: ws-cycle.sh next|prev

set -euo pipefail
DIR="${HOME}/.config/hypr/custom/scripts"
cmd="${1:-next}"

# butuh jq
command -v jq >/dev/null || { notify-send "ws-cycle: install jq"; exit 1; }

# workspace & monitor aktif sekarang
aw_json="$(hyprctl -j activeworkspace)"
curr_id="$(printf '%s' "$aw_json" | jq -r '.id')"
curr_mon="$(printf '%s' "$aw_json" | jq -r '.monitor')"

# kumpulkan workspace yang ada di monitor aktif (id > 0) — hanya yang berisi jendela
used_ids=($(hyprctl -j workspaces | jq -r --arg mon "$curr_mon" \
  '[.[] | select(.monitor == $mon and .id > 0 and .windows > 0) | .id] | unique | sort | .[]'))

# jika belum ada apa pun, anggap hanya WS 1
if [ "${#used_ids[@]}" -eq 0 ]; then
  allowed=(1)
else
  max_used="${used_ids[-1]}"
  allowed=("${used_ids[@]}" "$((max_used+1))")  # +1 kosong di ujung
fi

# cari target next/prev dengan wrap
next_id="$curr_id"
if [ "$cmd" = "next" ]; then
  for id in "${allowed[@]}"; do
    if [ "$id" -gt "$curr_id" ]; then next_id="$id"; break; fi
  done
  # kalau tidak ada yang lebih besar → wrap ke awal
  [ "$next_id" = "$curr_id" ] && next_id="${allowed[0]}"
else
  # prev: cari yang < curr; kalau tidak ada → wrap ke terakhir
  prev="$curr_id"
  for ((i=${#allowed[@]}-1; i>=0; i--)); do
    id="${allowed[$i]}"
    if [ "$id" -lt "$curr_id" ]; then prev="$id"; break; fi
  done
  [ "$prev" = "$curr_id" ] && prev="${allowed[-1]}"
  next_id="$prev"
fi

hyprctl dispatch workspace "$next_id"
