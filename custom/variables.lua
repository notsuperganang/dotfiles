-- Override variables from hyprland/variables.lua here (terminal, browser, qsConfig, ...).

-- Terminal: kitty first (zsh + Dracula, see ~/.config/kitty/kitty.conf). Upstream dots
-- moved foot to the front, and its foot.ini launches fish.
terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
