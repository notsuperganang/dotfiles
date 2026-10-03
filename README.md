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
├── hyprland.lua         # entry point (Hyprland 0.55+ Lua config), requires everything
├── hyprland/            # base config from end-4/dots-hyprland — don't touch
├── custom/              # your playground ← edit here or stay basic
│   ├── keybinds.lua
│   ├── general.lua
│   ├── env.lua
│   ├── rules.lua
│   └── scripts/
├── monitors.lua         # monitor layout (hand-written, toggle by comment)
├── workspaces.lua       # workspace → monitor mapping
├── hyprlock.conf        # hyprlock/hypridle still use hyprlang
├── hypridle.conf
└── docs/migration-0.56/ # Lua migration plan, runbook and config check
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
| `Super + Shift + S` | region screenshot (clipboard + `~/Pictures/Screenshots`) |
| `Super + A` | toggle dock |
| `Super + grave` | toggle cook mode 🍳 |

## customizing

Put your stuff in `custom/` — it loads after the base config and wins. To override an upstream bind, `hl.unbind()` it first with the exact key string upstream uses. Run `docs/migration-0.56/harness/check.sh` after edits. editing `hyprland/` directly means you've given up on having a clean git history. your choice.
