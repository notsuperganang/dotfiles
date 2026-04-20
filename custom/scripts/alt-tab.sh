#!/bin/bash
# Exit fullscreen before cycling focus, to prevent black screen glitch.
DIRECTION="${1:-next}"

WIN_JSON=$(hyprctl activewindow -j 2>/dev/null)

if [ -n "$WIN_JSON" ] && [ "$WIN_JSON" != "{}" ]; then
    FULLSCREEN=$(echo "$WIN_JSON" | jq -r '.fullscreen // 0')
    FULLSCREEN_MODE=$(echo "$WIN_JSON" | jq -r '.fullscreenMode // 1')

    if [ "$FULLSCREEN" != "0" ] && [ "$FULLSCREEN" != "false" ]; then
        hyprctl dispatch fullscreen "$FULLSCREEN_MODE"
    fi
fi

if [ "$DIRECTION" = "prev" ]; then
    hyprctl dispatch cyclenext prev
else
    hyprctl dispatch cyclenext
fi
