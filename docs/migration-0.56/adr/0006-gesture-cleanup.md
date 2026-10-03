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
- `action = "unset"` must match the original gesture exactly. Upstream's 4-finger up/down use
  Lua lambdas, so they may not be unsettable (INVENTORY V5). The fallback is to redefine them as
  no-ops, or as a last resort patch `hyprland/general.lua` and accept re-patching after each
  dots update.
