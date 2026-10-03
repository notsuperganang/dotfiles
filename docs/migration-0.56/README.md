# Migration: Hyprland 0.54.3 → 0.56 (Lua config) + full system upgrade

Planning docs for getting this machine off the pinned Hyprland 0.54.3 and back onto a
normal `pacman -Syu` cadence. Written 2026-10-03, before any implementation.

| Doc | What it holds |
|---|---|
| [PRD.md](PRD.md) | Goals, scope, non-goals, decision log, work breakdown, acceptance criteria |
| [INVENTORY.md](INVENTORY.md) | Frozen snapshot of the current system and every custom behaviour, mapped old → new |
| [RUNBOOK.md](RUNBOOK.md) | Day-H procedure: preflight, upgrade, install, restore, verify, rollback |
| [adr/](adr/) | Records for decisions that are hard to reverse |

## TL;DR

- Hyprland 0.55 replaced hyprlang (`hyprland.conf`) with Lua (`hyprland.lua`). 0.56 has no
  breaking changes and still loads hyprlang, but hyprlang is slated for removal 1–2 releases
  after 0.55, so **0.57 (expected ~Oct–Nov 2026) is the real deadline**.
- end-4/dots-hyprland moved to Lua in `6c041b95`; its Quickshell config now issues
  Lua-syntax dispatches, so the dots, Quickshell, hypridle and our custom scripts must move
  together.
- Strategy: **two phases**. Prepare everything on branches/worktrees while still on 0.54.3,
  then do a single day-H upgrade + install + restore, with a tested rollback path.
