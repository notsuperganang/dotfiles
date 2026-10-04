#!/usr/bin/env bash
# Load the full Lua config (upstream dots + our layer) against a strict stub of the
# Hyprland 0.56.2 Lua API, and print the resulting gestures, key binds and rules.
#
# usage: check.sh [dots-sha] [hypr-config-dir]
#   dots-sha         end-4/dots-hyprland commit to take hyprland/ + hyprland.lua from (default: 33f31a08)
#   hypr-config-dir  dir holding our custom/, monitors.lua, workspaces.lua (default: repo root)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
sha="${1:-33f31a08}"
src="${2:-$(git -C "$here" rev-parse --show-toplevel)}"
dots="${DOTS_REPO:-$HOME/.cache/dots-hyprland}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -C "$dots" archive "$sha" dots/.config/hypr | tar -x -C "$tmp"
mkdir -p "$tmp/home/.config"
mv "$tmp/dots/.config/hypr" "$tmp/home/.config/hypr"
rm -rf "$tmp/home/.config/hypr/custom"
cp -r "$src/custom" "$src/monitors.lua" "$src/workspaces.lua" "$tmp/home/.config/hypr/"

HOME="$tmp/home" lua "$here/run.lua" "$here"
