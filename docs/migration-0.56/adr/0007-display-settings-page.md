# ADR-0007: Display settings page generates monitors.lua (supersedes ADR-0005)

Status: Accepted · 2026-10-04

## Context
After the migration the user wanted to stop hand-editing monitor layouts and manage displays from
a GUI, similar to Windows' display settings. ADR-0005 had kept `monitors.lua` hand-written with
layouts toggled by commenting lines out.

## Decision
- A **Display** page in the Quickshell settings app (fork `shell-qml`: `services/Displays.qml`,
  `modules/settings/DisplayConfig.qml`) manages **named profiles**: drag-and-drop arrangement with
  edge snapping, mode/refresh, scale (only whole-pixel scales), rotation, mirror, enable/disable,
  and workspace → display pinning.
- Profiles are stored in `~/.config/hypr/displays/profiles.json` (the GUI's source of truth).
  Applying a profile **overwrites** `monitors.lua` and `workspaces.lua` with generated Lua for that
  profile. They are still plain, valid Lua that Hyprland reads directly, without a loader. The
  generated files remain local runtime state and are ignored by Git; `profiles.json` is tracked.
- Apply → atomic write → `hyprctl reload` → "Keep changes?" with a 15 s countdown. A detached
  watchdog restores the previous files unless the change is kept, even if the settings window closes.
- Identity: built-in panels by connector name (`eDP-2`, which the lid bind uses), externals by `desc:`.
- Generated `monitors.lua` keeps the built-in panel off when the lid is closed and an external
  display is connected. Before this, any reload with the lid closed turned eDP-2 back on behind the
  lid. The check is only emitted for profiles that also enable a non-mirrored external display.

## Consequences
- **Don't hand-edit or commit `monitors.lua` / `workspaces.lua`.** Use Settings → Display (or edit
  `profiles.json`); generated files carry a header saying so. A fresh checkout must apply a
  profile locally before Hyprland can load the display and workspace configuration.
- The old comment-toggle layouts became profiles: Kiri-kanan (active), Atas-bawah, Presentasi
  (mirror), Extended kiri, Laptop saja. "Atas-bawah" carried the old, uncentred offset (x=320 was
  computed for a 2560-wide panel; at scale 1.33 it is 1920 logical px wide); the user re-centred it to
  x=0 from the Display page on 2026-10-04.
- nwg-displays stays unused (ADR-0005's reasoning still holds); the package was uninstalled on 2026-10-06.
- The fork now carries 4 more commits to re-apply on every re-vendor (INVENTORY §4).
- Tests: `~/dev/display-tests/` (copy into the fork root and run with `QS_DISPLAYS_HYPR_DIR` pointing at a
  scratch copy of the hypr dir). They cover snapping, generators, UI controls, apply/keep/revert and the watchdog.
