# Inventory: system state and custom behaviour (frozen 2026-10-03)

This is the source of truth for "what must still work after migration". Each mapping row
names the source of its new syntax:

- **W56**: Hyprland wiki 0.56.0 (`wiki.hypr.land/0.56.0/...`)
- **UP**: upstream dots-hyprland `547836f1` (planning pin; day-H pin is `33f31a08`, see PRD D14)
- **src**: confirmed in the Hyprland v0.56.2 source (§7)

## 1. Machine

| Item | Value |
|---|---|
| Laptop GPUs | AMD Cezanne iGPU (`amdgpu`, card2): **eDP-2 laptop panel**, DP-3, DP-4 · NVIDIA RTX 3050 Ti (`nvidia`, card1): **DP-1 (external monitor)**, DP-2, eDP-1 |
| NVIDIA driver | `nvidia-open-dkms` 595.71.05 → 615.71.09; `/etc/modprobe.d/nvidia.conf`: `nvidia_drm modeset=1 fbdev=1`; mkinitcpio `MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)` |
| Kernels | `linux` 7.0.10 → 7.2.8 · `linux-lts` 6.18.33 → 6.18.54 (**running lts**) |
| Root FS | ext4, `/dev/nvme0n1p2` |
| ESP | `/boot/efi` = `/dev/nvme1n1p1`, **shared with Windows Boot Manager**. Entries: `EFI/GRUB/grubx64.efi` (Boot0001, BootCurrent), `EFI/Microsoft` |
| Bootloader | GRUB 2.14 → 2.16; `GRUB_DEFAULT=0` (currently lts), `GRUB_TIMEOUT=30`, os-prober enabled |
| Timeshift | rsync mode, target = root disk (nvme0n1p2), no schedule; home dirs excluded (V8). Dry-run snapshot `2026-10-03_22-08-23`: 554 s, ~39 GB (`/` 229 → 268 GB used, 162 GB free) |
| `/etc/pacman.conf` | `IgnorePkg = hyprland` (line 25) |
| logind | `HandleLidSwitch*` all at defaults (suspend; docked = ignore) |

### Notable pending updates (795 total)

`hyprland` 0.54.3 → 0.56.2 · `aquamarine` 0.11 → 0.15 · `hyprutils` 0.13 → 0.14 ·
`hyprlang` 0.6.8-5 · `xdg-desktop-portal-hyprland` 1.3.12 → 1.4.1 · `hyprpolkitagent` 0.2.0 ·
`hyprsunset` 0.4.0 · `hypridle` 0.1.8 · `hyprlock` 0.9.6 · `glibc` 2.43 → 2.44 ·
`systemd` 260 → 262 · `mesa` 26.1 → 26.2 · `qt6-base` 6.11.1 → 6.11.2 (Quickshell must be
rebuilt) · `wayland` 1.26 · `xdg-desktop-portal` 1.22 · `python` 3.14.7 · `lua` 5.5.1.

### Foreign (AUR / local) packages: 122

The relevant ones are the `illogical-impulse-*` metapackages (built by `./setup install`),
including `illogical-impulse-quickshell-git` 0.1.0.r1-7. Leftovers to clean up later
(non-goal): `aylurs-gtk-shell`, `libastal-*`, `libastal-meta`, assorted `-debug` packages.

## 2. Config layout (current → target)

| Current (0.54, hyprlang) | Target (0.56, Lua) | Owner |
|---|---|---|
| `hyprland.conf` | `hyprland.lua` (setup renames the old file to `hyprland.conf.old`) | upstream |
| `hyprland/*.conf` | `hyprland/*.lua`, `hyprland/lib/`, `hyprland/services/` (rsync `--delete`) | upstream |
| `custom/env.conf` | `custom/env.lua` | **us** |
| `custom/general.conf` | `custom/general.lua` | **us** |
| `custom/keybinds.conf` | `custom/keybinds.lua` | **us** |
| `custom/rules.conf` (empty) | `custom/rules.lua` (empty) | **us** |
| — | `custom/variables.lua`, `custom/execs.lua` (only if needed; upstream's `create_custom_config` service creates placeholders) | **us** |
| `monitors.conf` | `monitors.lua` | **us** |
| `workspaces.conf` | `workspaces.lua` | **us** |
| `hypridle.conf` | `hypridle.conf` (still hyprlang, but with Lua-syntax dispatches). **Committed on our branch**, since setup only writes `hypridle.conf.new` on non-first runs | upstream, carried by us |
| `hyprlock.conf`, `hyprlock/` | unchanged format; same `.new` behaviour | upstream, carried by us |
| `custom/scripts/*.sh` | ported (see §3.3) | **us** |

Base file drift: the only local edit in `hyprland/` was `env.conf` setting
`ILLOGICAL_IMPULSE_VIRTUAL_ENV` to an absolute path. Upstream Lua now does
`hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")`
(absolute), so **no carry-over is needed** (UP).

## 3. Behaviour parity table

### 3.1 Keybinds (`custom/keybinds.conf`)

| # | Old (hyprlang) | Behaviour | New (Lua) | Src |
|---|---|---|---|---|
| K1 | `bind = Ctrl+Super, Slash, exec, xdg-open ~/.config/illogical-impulse/config.json` | Edit shell config | `hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"))`. Check whether upstream already binds it | UP |
| K2 | `bind = Ctrl+Super+Alt, Slash, exec, xdg-open …/custom/keybinds.conf` | Edit custom keybinds | Upstream template already binds it to `custom/keybinds.lua` | UP |
| K3 | `unbind = Super, Tab` + `bind = Super, Tab, exec, ws12-mode.sh next` | Next WS (cook-mode aware) | `hl.unbind("SUPER + Tab")` + `hl.bind("SUPER + Tab", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/ws12-mode.sh next"))`. Upstream binds SUPER+Tab to the overview | W56/UP |
| K4 | `bind = Super+Shift, Tab, exec, ws-cycle.sh prev` | Prev WS | `hl.bind("SUPER + SHIFT + Tab", hl.dsp.exec_cmd("…/ws-cycle.sh prev"))` | W56 |
| K5 | `bind = Alt, Tab, cyclenext` | Next window | `hl.bind("ALT + Tab", hl.dsp.window.cycle_next())` | W56 |
| K6 | `bind = Alt+Shift, Tab, cyclenext, prev` | Prev window | `hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))` | W56 + src (V7) |
| K7 | `unbind = Super, grave` + `bind = Super, grave, exec, ws12-mode.sh toggle` | Toggle cook mode (WS 1↔2 lock) | `hl.unbind("SUPER + grave")` + `hl.bind(…, exec_cmd("…/ws12-mode.sh toggle"))` | W56 |
| K8 | `unbind = Super, Super_L` / `Super_R` | Disable tap-Super search toggle | `hl.unbind("SUPER + SUPER_L")` and `hl.unbind("SUPER + SUPER_R")`. Upstream has **two** binds per key (global + fuzzel fallback), so check that both go. Keep the `SUPER_L` workspaceNumber binds | UP + src (V1) |
| K9 | `unbind = Super+Shift, S` + `bind = …, global, quickshell:regionScreenshotSave` (clipboard-only variant commented) | Region screenshot → clipboard + `~/Pictures/Screenshots` | `hl.unbind("SUPER + SHIFT + S")` + `hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshotSave"))`. Keep the commented clipboard-only alternative. Upstream binds SUPER+SHIFT+S **twice** (lines 68–69), so check that the unbind removes both | UP + src (V1) |
| K10 | `unbind = Super, A` + `bind = Super, A, exec, qs -c $qsConfig ipc call dock toggle` | Toggle dock (replaces left sidebar) | `hl.unbind("SUPER + A")` + `hl.bind("SUPER + A", hl.dsp.exec_cmd("qs -c $qsConfig ipc call dock toggle"))`. `qsConfig` is now set via `hl.env` | UP |
| K11 | `bind = Super+Ctrl, F, fullscreen, 1` | Maximize | `hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))` | W56/UP |
| K12 | `unbind = Super, D` + `bind = Super, D, global, quickshell:overviewWorkspacesToggle` | Overview (upstream uses SUPER+D for maximize) | `hl.unbind("SUPER + D")` + `hl.bind("SUPER + D", hl.dsp.global("quickshell:overviewWorkspacesToggle"))` | UP |
| K13 | `bindl = , switch:on:Lid Switch, exec, hyprctl keyword monitor "eDP-2, disable"` | Lid closed → turn off laptop panel | `hl.bind("switch:on:Lid Switch", <fn: hl.monitor({ output = "eDP-2", disabled = true })>, { locked = true })`. `hyprctl keyword` is hyprlang-only. 0.55.1 fixed re-enabling monitors from Lua | W56 + src (V6) |
| K14 | `bindl = , switch:off:Lid Switch, exec, hyprctl reload` | Lid open → reload (restores the monitors.lua position) | `hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl reload"), { locked = true })`. Reload is a full Lua re-evaluation, but startup commands live in `hl.on("hyprland.start")`, which fires once per session (`static bool once` in `src/render/Renderer.cpp`), so Quickshell etc. are not respawned | W56 + src |

Cheatsheet: the old `#!` / `##!` comment markers and trailing `# description` don't exist
in Lua. Use `{ description = "…" }` on each bind (UP).

### 3.2 General / gestures / input (`custom/general.conf`)

Agreed target behaviour (ADR-0006):

| # | Gesture | Old effective state | New behaviour | New (Lua) |
|---|---|---|---|---|
| G1 | 3-finger horizontal | workspace | **workspace** | `hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })` |
| G2 | 3-finger up | overview toggle | **overview toggle** | `action = function() hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle")) end` (UP style) |
| G3 | 3-finger down | overview toggle | **overview toggle** | same as G2 with `direction = "down"` |
| G4 | 3-finger swipe → move (base) | `unset` attempted | **off** | `hl.gesture({ fingers = 3, direction = "swipe", action = "unset" })`. Must match the base exactly |
| G5 | 3-finger pinch (base: float, UP now: fullscreen) | active | **off** | `unset` matching UP `{ fingers = 3, direction = "pinch" }` |
| G6 | 4-finger horizontal → workspace (base) | `unset` | **off** | `unset` matching UP |
| G7 | 4-finger up/down → overview (base) | `unset` | **off** | `unset` with `{ fingers = 4, direction = "up"/"down" }`. UP uses Lua lambdas, but unset ignores the action (V5) |

Other settings to carry over:

| # | Old | New (Lua) | Src |
|---|---|---|---|
| S1 | `misc { on_focus_under_fullscreen = 1 }` | `hl.config({ misc = { on_focus_under_fullscreen = 1 } })` | W56 (V4) |
| S2 | `input.touchpad.clickfinger_behavior = false` | `hl.config({ input = { touchpad = { clickfinger_behavior = false, … } } })` | W56 |
| S3 | `input.touchpad.tap-to-click = true` | same block, key `tap_to_click` | W56 (V4) |
| S4 | `input.touchpad.tap_button_map = lrm` | same block | W56 |
| S5 | `custom/env.conf`: `env = QT_SCALE_FACTOR, 1` | `hl.env("QT_SCALE_FACTOR", "1")` | W56 |
| S6 | (implicit) old upstream `$terminal` started with `"kitty -1"` | `custom/variables.lua` sets `terminal` with kitty first; upstream Lua puts foot first and dots' `foot.ini` runs fish (found on day H) | UP |

### 3.3 Scripts (`custom/scripts/`)

| Script | Hyprland calls | Action |
|---|---|---|
| `ws12-mode.sh` | `hyprctl -j activeworkspace`, `hyprctl dispatch workspace {1,2,r+1}` | Port dispatches to `hyprctl dispatch 'hl.dsp.focus({ workspace = "N" })'` (W56). JSON reads: verify shape (V3) |
| `ws-cycle.sh` | `hyprctl -j activeworkspace`, `hyprctl -j workspaces`, `hyprctl dispatch workspace N` | Same as above |
| `alt-tab.sh` | — | **Delete** (unused; Alt+Tab binds `cyclenext` directly) |
| `__restore_video_wallpaper.sh` | — | Generated by `switchwall.sh`; leave alone |

Optional (decide in P1.4): replace both scripts with Lua functions using
`hl.get_active_workspace()` and friends, dropping the `jq` dependency.

### 3.4 Monitors and workspaces

`monitors.conf` today (hand-written, Indonesian comments, toggle by commenting):

- `$ext = desc:SKYDATA S.P.A. F24G41F 0x01010101`
- Layout A (commented): ext on top at `320x0`, eDP-2 at `0x1080`
- **Layout B (active)**: `eDP-2, 2560x1440@165, 0x0, 1.33` and `$ext, 1920x1080@240, 1925x2, 1`
- Alternatives (commented): mirror `$ext … mirror, eDP-2`; ext on the left `-1920x0`

Target `monitors.lua`: `local ext = "desc:SKYDATA S.P.A. F24G41F 0x01010101"` and
`hl.monitor({ output = …, mode = …, position = …, scale = … })` per line, with the same
commented alternatives (W56).

`workspaces.conf` today: WS 1–3 → `monitor:DP-1` (1 default), WS 4–5 → `monitor:eDP-2`
(single-monitor line commented). Target (done in Phase 1): `hl.workspace_rule({ workspace = "1",
monitor = ext, default = true })` etc. External monitor now matched by `desc:` instead of `DP-1`
for consistency with monitors (V6/§7 constraints).

### 3.5 hypridle (accept upstream)

Same thresholds as today: lock 300 s, DPMS 600 s, suspend 900 s; `inhibit_sleep = 3`. Upstream
`547836f1` uses `hl.dsp.dpms({ action = "disable" / "enable" })` (correct, see V2). Our branch
carries it verbatim, so setup's `hypridle.conf.new` will be identical.

## 4. Quickshell fork (`shell-qml`, `~/.config/quickshell/ii`)

- Repo `git@github.com:notsuperganang/shell-qml.git`, HEAD `461bf57`, 18 commits since
  2026-04-20. **No shared history with upstream**: it was created from a copy of
  `dots/.config/quickshell/ii` at dots `a2c16410`.
- Also contains `.claude/` (keep it).

| Commit | Change | Files | Re-apply? |
|---|---|---|---|
| `2934bc9` | `quickshell:regionScreenshotSave` global shortcut (save to `~/Pictures/Screenshots`) | `modules/ii/regionSelector/RegionSelection.qml`, `RegionSelector.qml` | **Yes** |
| `6ce88c2` | Sequential crop+copy instead of process substitution for save mode | `modules/common/utils/ScreenshotAction.qml` | **Yes** |
| `6c9a376` | `dock toggle` IPC to force-reveal the dock | `modules/ii/dock/Dock.qml` | **Yes** |
| `e19b959`, `4a682a5`, `461bf57` | Notification polish loop / app icon fixes | `NotificationItem.qml`, `NotificationAppIcon.qml` | **No** (upstream `c58bb07a`) |

Re-baseline plan (P1.6), done in a standalone clone `~/dev/shell-qml` (not a worktree; see
PRD D10): new branch `rebase/upstream` whose first commit is
"vendor upstream quickshell/ii @ 547836f1", followed by the three re-applied commits, then
"re-vendor upstream quickshell/ii @ 33f31a08" (2026-10-04; only `services/SystemInfo.qml` changed).
Future updates then become "re-vendor + rebase".

## 5. Non-hypr files that `./setup install` will clobber

| Path | Our change | Restore action |
|---|---|---|
| `~/.config/kitty/kitty.conf` | `font_size 14.0`; `background_opacity 0.85`; `shell zsh` (upstream: fish); `include current-theme.conf` (Dracula) block | Re-apply the diff |
| `~/.config/kitty/current-theme.conf` | User-only file, **deleted** by `--delete` | Restore from backup |
| `~/.config/kitty/kitty.conf.bak` | User-only, deleted | Ignore |
| `~/.config/mpv/mpv.conf` | `+hwdec=auto`, `+gpu-context=wayland` | Re-apply |
| `~/.config/fuzzel/fuzzel_theme.ini`, `~/.config/kdeglobals`, `~/.config/fish/fish_variables` | Generated colours only | None (regenerated) |
| `~/.config/fish/completions`, `~/.config/fish/functions` | User-only, deleted (fish is unused; shell is zsh) | None |
| `~/.config/quickshell/` | Whole fork incl. `.git` | RUNBOOK §6 |
| `~/.config/hypr/hypridle.conf`, `hyprlock.conf` | None | Not overwritten (non-first run → `*.new`). Our branch already carries the upstream versions; diff and delete the `*.new` files |

## 6. Repos and refs to tag before day H

| Repo | Path | Tag |
|---|---|---|
| `notsuperganang/dotfiles` | `~/.config/hypr` | `pre-lua-migration` @ current `main` |
| `notsuperganang/shell-qml` | `~/.config/quickshell/ii` | `pre-lua-migration` @ `461bf57` |
| end-4/dots-hyprland | `~/.cache/dots-hyprland` | pin target `33f31a08` (moved from `547836f1` on 2026-10-04, PRD D14) |

## 7. Verification items

Resolved during Phase 1 (2026-10-03) by reading the Hyprland **v0.56.2** source (`hyprwm/Hyprland`
tag `v0.56.2`) and the 0.56.0 wiki. Paths below are relative to that source tree.

| ID | Question | Result |
|---|---|---|
| V1 | Does `hl.unbind` remove all binds on a key? | **Yes.** `CKeybindManager::removeKeybind(displayKeys)` (`src/managers/KeybindManager.cpp`) `erase_if`s every bind whose display key matches after stripping spaces and lowercasing. **Modifier order is not normalised**, so use upstream's exact string (`"SUPER + SHIFT + S"`, not `"SHIFT + SUPER + S"`). Unbinding a key nobody bound is a silent no-op |
| V2 | `dpms(false)` vs `dpms({ action })` | `hlDpms` (`src/config/lua/bindings/LuaBindingsDispatchers.cpp`) reads `action` from a table and defaults to **toggle** for anything else, so `dpms(false)` would toggle. Upstream dots fixed this in `f5b2b754`; `547836f1` already uses `{ action = "disable" / "enable" }`. Our `hypridle.conf` is identical to upstream |
| V3 | `hyprctl -j` workspace JSON shape | Unchanged: `CHyprCtl::getWorkspaceData` (`src/debug/HyprCtl.cpp`) still emits `id`, `name`, `monitor`, `windows`, … |
| V4 | Lua option keys | From the 0.56.0 variables page: `input.touchpad.tap_to_click` (underscore), `tap_button_map` string, `clickfinger_behavior` bool, `misc.on_focus_under_fullscreen` int |
| V5 | Can lambda gestures be unset? | **Yes.** `CTrackpadGestures::removeGesture` (`src/managers/input/trackpad/TrackpadGestures.cpp`) matches fingers, direction, mods, scale and disableInhibit, **not the action** |
| V6 | Function binds on `switch:` with `locked` | Supported (0.56.0 Binds page: function dispatchers, switches, `locked` flag). `hl.monitor()` called at runtime replaces the rule with the same `output` (`CMonitorRuleManager::add` erases by name) and schedules a monitor refresh, so it applies immediately |
| V7 | `cycle_next({ next = false })` | `next` is a bool field read by the `cycle_next` dispatcher builder; `false` cycles backwards |
| V8 | Does Timeshift include `/home`? | **No.** Checked in the Timeshift GUI on 2026-10-03: Users tab = *Exclude All Files* for `root` and `notsuperganang`; Filters = `- /root/**`, `- /home/notsuperganang/**`. (`/etc/timeshift/timeshift.json` shows `exclude: []` because these are Timeshift's built-in defaults.) A snapshot is system-only, ≈ 60 GB (229 GB used on `/` minus ~168 GB home); 201 GB free. A restore does **not** roll back `~/.config`, so config rollback relies on the git tags and the tarball |

### Constraints learned from the source

- **Gesture shadowing:** `CTrackpadGestures::addGesture` rejects a gesture shadowed by an earlier one
  with the same fingers and mods (e.g. `3 swipe` shadows `3 horizontal/up/down`), so **unset the
  defaults before adding ours**. An `unset` that matches nothing is also an error.
- Both kinds of error show up in the error banner but don't abort the rest of the file. The
  config still loads, just without that gesture.
- **Reload is a full reset:** the Lua config manager clears gestures, keybinds, monitor rules and
  workspace rules before re-evaluating (`src/config/lua/ConfigManager.cpp`), so `hyprctl reload`
  and autoreload don't cause duplicate or shadow errors.
- `hl.monitor` fields `mode`, `position`, `scale` and `mirror` are **strings** (`"1925x2"`, `"1.33"`).
  `hl.workspace_rule` takes `workspace` as a string plus `monitor`/`default`; `desc:` selectors work
  (`CMonitor::matchesStaticSelector`).
- Upstream's `quickshell/ii/modules/common/widgets/shapes` is a **git submodule**
  (`end-4/rounded-polygon-qmljs` @ `e31ec4cb`). `git archive` skips it, so vendoring must inline it.

### Automated check

`docs/migration-0.56/harness/check.sh [dots-sha]` loads upstream dots plus our layer against a strict
stub of the 0.56.2 Lua API (names taken from the `setFn` registrations; gesture, unbind and monitor
logic copied from the C++). It exits non-zero on unknown API names, shadowed or missing gestures,
and unknown rule fields, and prints the final gesture and bind tables. Re-run it whenever the dots
pin or `custom/` changes.
