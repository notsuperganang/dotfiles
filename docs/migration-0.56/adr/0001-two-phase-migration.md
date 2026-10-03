# ADR-0001: Two-phase migration (prep offline, then one day-H cutover)

Status: Accepted · 2026-10-03

## Context
Hyprland 0.55 moved the config to Lua, and end-4/dots-hyprland, its Quickshell config and
hypridle all moved with it. The machine is pinned at 0.54.3 and can't take any system update.
0.56 still loads hyprlang, but that support is expected to go in 0.57.

## Options
- **Big bang**: upgrade and migrate everything in one sitting, writing Lua under pressure.
- **Two phases**: write and review all Lua, the ported scripts and the Quickshell rebase on
  branches while still on 0.54.3, then do the upgrade + install + restore in one session.
- **Compat first**: upgrade to 0.56 on the old hyprlang dots and migrate later. That runs
  old Quickshell against new Hyprland/Qt, and the pin returns if 0.57 lands first.

## Decision
Two phases. Compat-first is kept only as the Level-2 emergency fallback (RUNBOOK §8).

## Consequences
- Day H is mostly mechanical. The remaining unknowns are listed as verification items
  (INVENTORY §7).
- The Lua config can't be run before day H. Validation is `luac -p` + review against the
  0.56.0 wiki, then `Hyprland --verify-config` on day H.
