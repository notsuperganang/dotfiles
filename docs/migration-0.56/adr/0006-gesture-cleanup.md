# ADR-0006: Trackpad gesture cleanup

Status: Accepted · 2026-10-03

## Context
The old config mixed base gestures with partial `unset`s. 3-finger swipe→move and
horizontal→workspace overlapped, 4-finger gestures were unset, and 3-finger pinch→float stayed
active (upstream Lua now maps it to fullscreen).

## Decision
Final gesture set:
- 3-finger horizontal → workspace
- 3-finger up / down → toggle the Quickshell workspace overview
- everything else that upstream defines (3-finger swipe→move, 3-finger pinch, 4-finger
  horizontal/up/down) → **off**

## Consequences
- In Hyprland 0.56, a gesture shadowed by an earlier one with the same fingers and mods is rejected,
  so the five `unset`s must come **before** our three adds (`custom/general.lua`).
- `unset` matches on fingers, direction, mods and scale but not on the action, so upstream's
  lambda-based 4-finger gestures can be removed too (verified in the v0.56.2 source, INVENTORY V5).
- An `unset` that matches nothing is an error. If upstream drops one of these defaults, remove the
  matching `unset` (`harness/check.sh` flags it).
