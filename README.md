# hypr dotfiles

> yes, it's another hyprland rice. no, your i3 setup doesn't compare.
> personal tweaks on top of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — AGS is dead, we use Quickshell now.

## stack

| role | tool |
|------|------|
| compositor | Hyprland |
| shell / bar | Quickshell (`ii` config) — not AGS, keep up |
| lock screen | Hyprlock |
| idle daemon | Hypridle |
| audio fx | EasyEffects |
| clipboard | cliphist |
| screenshot | Hyprshot |

## layout

```
~/.config/hypr/
├── hyprland.conf        # entry point, sources everything
├── hyprland/            # base config — don't touch
├── custom/              # your playground ← edit here or stay basic
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
| `Alt + Tab` | next window (actually works, unlike your setup) |
| `Alt + Shift + Tab` | prev window |
| `Super + Ctrl + F` | maximize |
| `Super + D` | overview |
| `Super + Shift + S` | region screenshot |
| `Super + grave` | toggle cook mode 🍳 |

## customizing

Put your stuff in `custom/` — it loads after the base config and wins. editing `hyprland/` directly means you've given up on having a clean git history. your choice.
