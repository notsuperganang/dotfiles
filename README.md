# hypr dotfiles

> Hyprland config with Quickshell-based shell — personal tweaks on top of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

## stack

| role | tool |
|------|------|
| compositor | Hyprland |
| shell / bar | Quickshell (`ii` config) |
| lock screen | Hyprlock |
| idle daemon | Hypridle |
| audio fx | EasyEffects |
| clipboard | cliphist |
| screenshot | Hyprshot |

## layout

```
~/.config/hypr/
├── hyprland.conf        # entry point, sources everything
├── hyprland/            # base config (upstream)
├── custom/              # personal overrides ← edit here
│   ├── keybinds.conf
│   ├── general.conf
│   ├── env.conf
│   ├── rules.conf
│   └── scripts/
├── monitors.conf        # monitor layout (nwg-displays)
├── workspaces.conf      # workspace → monitor mapping
├── hyprlock.conf
└── hypridle.conf
```

## key bindings (custom)

| keys | action |
|------|--------|
| `Super + Tab` | next workspace |
| `Super + Shift + Tab` | prev workspace |
| `Alt + Tab` | next window |
| `Alt + Shift + Tab` | prev window |
| `Super + Ctrl + F` | maximize window |
| `Super + D` | overview |
| `Super + Shift + S` | region screenshot |
| `Super + grave` | toggle cook mode |

## customizing

Drop overrides into `custom/` — files there are sourced after the base config and take precedence. The base `hyprland/` files are not meant to be edited directly.
