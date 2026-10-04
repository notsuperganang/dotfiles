# ADR-0005: Hand-written monitors.lua; drop nwg-displays

Status: Superseded by [ADR-0007](0007-display-settings-page.md) (2026-10-04) · originally accepted 2026-10-03

## Context
Upstream dots load `monitors.lua`/`workspaces.lua` when present (the hook for nwg-displays).
Our `monitors.conf` is hand-maintained in git: monitors matched by `desc:`, two layouts and a
mirror mode toggled by commenting, with Indonesian comments. nwg-displays is installed, but its
profiles dir is empty and `use-desc` is false. Any save from it would have replaced the
`desc:` lines, so it hasn't been used for the current layout.

## Decision
Write `monitors.lua` and `workspaces.lua` by hand in the same toggle-by-comment style, keeping
`desc:` matching. Don't keep nwg-displays compatibility.

## Consequences
- Never let nwg-displays save into `~/.config/hypr`. The package can be removed in the
  follow-up cleanup.
- Layout changes stay as edits + commits.
