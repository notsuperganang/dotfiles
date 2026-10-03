# ADR-0002: Use full `./setup install`, then restore our layer

Status: Accepted · 2026-10-03

## Context
`./setup install` rsyncs with `--delete` into `~/.config/quickshell`, `~/.config/hypr/hyprland`
and every other `dots/.config/*` dir (except fish's `conf.d` and fontconfig special cases). It
renames `hyprland.conf` to `.old`, and always overwrites `hyprland.lua`. On a non-first run it
does **not** overwrite an existing `hypridle.conf`/`hyprlock.conf`; it writes `*.new` next to them. It
also doesn't `git pull` its own repo, so a checked-out pin holds. This wipes the
Quickshell fork's `.git` and user-only files such as `kitty/current-theme.conf`.

## Options
- Full install, then restore.
- Selective install (deps via setup, files by hand).
- Move protected dirs aside, run setup, move them back.

## Decision
Full install, then restore. The customisation surface outside hypr/quickshell is small and
inventoried (INVENTORY §5).

## Consequences
- Everything setup will clobber has to be inventoried, tagged and pushed **before** day H
  (RUNBOOK §1).
- Restore steps are written out (RUNBOOK §6).
- Future dots updates follow the same pattern, so INVENTORY §5 is worth keeping current.
