# ADR-0003: Re-baseline the Quickshell fork on upstream

Status: Accepted · 2026-10-03

## Context
`shell-qml` was created from a copy of `dots/.config/quickshell/ii` (dots `a2c16410`), so it
has no shared git history with upstream. Upstream is 153 commits ahead and now sends
Lua-syntax Hyprland dispatches. Our delta is three commits (screenshot save, its crop fix,
dock IPC toggle) plus notification fixes that upstream has since fixed itself (`c58bb07a`).

## Decision
Create branch `rebase/upstream`. Its first commit vendors upstream `quickshell/ii` at the
pinned dots SHA; our three commits are re-applied on top. The notification fixes are dropped.

## Consequences
- Future updates: re-vendor upstream as a new commit, then rebase our commits on top.
- Once verified, `rebase/upstream` becomes the default branch. The old history stays
  reachable via the `pre-lua-migration` tag.
