# PRD — Hyprland Lua migration & system catch-up

Status: **Planned** · Snapshot date: 2026-10-03 · Owner: notsuperganang

## 1. Problem

Hyprland is pinned at 0.54.3 (`IgnorePkg = hyprland` in `/etc/pacman.conf`) because 0.55
introduced the Lua config and end-4/dots-hyprland followed with a full Lua rewrite. Because
the Hypr libraries (`hyprutils`, `aquamarine`, …) bump sonames in lockstep with Hyprland,
the pin blocks **every** system upgrade: 795 packages are pending, including kernels, the
NVIDIA driver, glibc, systemd, mesa and Qt.

There is also an existing **partial-upgrade** state: a `pacman -Syu` on 2026-09-16 refreshed
the sync DBs but was aborted, and packages were installed afterwards with `-S`
(`cloudflared`, `ttf-liberation`, `google-chrome`). Nothing is visibly broken, but this is an
unsupported state on Arch. **Guard until day H: no `pacman -S` / `yay -S` of anything** (it
would install against newer sync DBs than the rest of the system).

The hyprlang compatibility layer is expected to disappear in Hyprland 0.57, so waiting longer
turns a planned migration into a forced one.

## 2. Goals

1. Bring the system fully up to date (`pacman -Syu` with no `IgnorePkg`) and leave it on a
   normal update cadence.
2. Run Hyprland 0.56.x with a **Lua** config (`hyprland.lua`), built on the latest
   end-4/dots-hyprland.
3. Keep **100% behavioural parity** with today's custom setup (see INVENTORY §3), plus the
   agreed gesture cleanup.
4. Re-baseline the Quickshell fork (`shell-qml`) on upstream so future updates are a rebase
   rather than a manual port.
5. Have a written, tested-on-paper rollback path at every step of day H.

## 3. Non-goals

- Cleaning up leftover AUR packages from earlier setups (`aylurs-gtk-shell`, `libastal-*`,
  orphans). Tracked as a follow-up.
- Updating AUR packages on day H. Done separately with `yay -Sua` once Hyprland is verified.
- Supporting nwg-displays (see ADR-0005).
- Off-machine backups (external drive / cloud). Rollback relies on Timeshift + git tags +
  the pacman package cache.
- New features or keybinds beyond parity + the gesture cleanup.

## 4. Decision log

Decisions settled during planning (2026-10-03). ADRs exist for the hard-to-reverse ones.

| # | Topic | Decision | Rationale |
|---|---|---|---|
| D1 | Overall strategy | **Two phases**: prepare everything on branches while on 0.54.3, then one day-H session. ([ADR-0001](adr/0001-two-phase-migration.md)) | Short downtime; everything that can be done offline is done offline. hyprlang on 0.56 stays as an emergency fallback, not the plan. |
| D2 | Docs | Live in `~/.config/hypr/docs/migration-0.56/`, written in English. | Same repo as the config; matches README/commit language. |
| D3 | Safety net | Manual Timeshift snapshot right before `-Syu`; keep `/var/cache/pacman/pkg` (no `paccache -r` until stable); git tag `pre-lua-migration` in `hypr` and `shell-qml`, pushed; a local tarball of the
affected `~/.config` dirs in `~/migration-backup/`. No external/cloud backup. | Timeshift covers the system; git tags are the real config rollback (Timeshift rsync mode normally excludes `/home`). |
| D4 | Quickshell fork | **Re-baseline** on upstream `quickshell/ii` and re-apply our changes on top. The notification fixes are dropped (upstream `c58bb07a` covers them). ([ADR-0003](adr/0003-rebaseline-quickshell-fork.md)) | Upstream is 153 commits ahead and now uses Lua dispatches; our delta is small and well bounded. |
| D5 | Installing dots | **Full `./setup install`**, then restore customisations and the fork. ([ADR-0002](adr/0002-full-setup-install-then-restore.md)) | Lowest-friction path that matches upstream's supported flow; the customisation surface is small and inventoried. |
| D6 | Kernel / NVIDIA | Keep both `linux` and `linux-lts`; **lts stays the default boot entry**; verify the DKMS build for both kernels before rebooting; re-run `grub-install` + `grub-mkconfig` after grub 2.16. ([ADR-0004](adr/0004-lts-default-kernel.md)) | NVIDIA 595 → 615 plus kernel 7.0 → 7.2 is the riskiest jump; two kernels give a fallback. |
| D7 | Feature parity | 100% parity; delete the unused `alt-tab.sh`; clean up the gesture conflicts. ([ADR-0006](adr/0006-gesture-cleanup.md)) | — |
| D8 | Timing | Weekend, 3–4 h window. **Abort budget: 2 h** after `-Syu`, then fall back. Must finish before 0.57 reaches the Arch repos. | It's a work laptop. |
| D9 | Monitors | Hand-written `monitors.lua` / `workspaces.lua` in the same toggle-by-comment style (Layout A/B, mirror) with `desc:` matching. nwg-displays is dropped. ([ADR-0005](adr/0005-handwritten-monitors-drop-nwg-displays.md)) | nwg-displays was never actually used to save a layout (empty profiles, `use-desc: false`). |
| D10 | Prep workspace | `git worktree` on branch `migrate/lua-0.56` at `~/dev/hypr-lua` (branched from `main` **after** the docs commit). For `shell-qml`, a **standalone clone** at `~/dev/shell-qml` on branch `rebase/upstream`, not a worktree, because setup's `rsync --delete` wipes `~/.config/quickshell/ii/.git`, which a worktree depends on. | Lua-syntax scripts would break the running 0.54 session if placed live. |
| D11 | Validation | Before day H: `luac -p` on every `.lua` file + review against upstream templates and the **0.56.0** wiki. On day H: `Hyprland --verify-config` before logging in. | 0.56 can't run before the upgrade. |
| D12 | AUR | Day H = `pacman -Syu` + `./setup install` only. `yay -Sua` afterwards, separately. AGS/astal cleanup is a follow-up. | Keep the day-H blast radius small. |
| D13 | hypridle / hyprlock | Accept upstream's new versions (Lua-syntax dispatches). They are committed **on the migration branch** because setup does not overwrite existing files on a non-first run; it only writes `*.new`. | Our `hypridle.conf` has no customisations. |

## 5. Reference versions (frozen 2026-10-03)

| Thing | Current | Target |
|---|---|---|
| Hyprland | 0.54.3-4 | 0.56.2-3 (repo). **If the repo shows 0.57.x on day H → stop and re-plan.** |
| dots-hyprland (`~/.cache/dots-hyprland`) | `a2c16410` (2026-04-18) | `547836f1` (pinned; review any newer commits before moving the target) |
| dots pre-Lua release tag | — | `2026.05.11` (reference only) |
| `hypr` repo (`notsuperganang/dotfiles`) | `8ad19d6` | branch `migrate/lua-0.56` |
| `shell-qml` repo (Quickshell fork) | `461bf57` | branch `rebase/upstream` |
| Syntax reference | — | Hyprland wiki **0.56.0** (`wiki.hypr.land/0.56.0/...`) and upstream dots `547836f1`. Do **not** use wiki `main`; it already differs from 0.56 in places. |

## 6. Work breakdown

### Phase 1: prep (no package changes, live config untouched)

1. **P1.1** Create worktree `~/dev/hypr-lua` on `migrate/lua-0.56`.
2. **P1.2** Write `custom/env.lua`, `custom/general.lua` (gestures, misc, touchpad),
   `custom/keybinds.lua`, `custom/rules.lua` (empty), and `custom/execs.lua` if needed,
   following the upstream `custom/*.lua` conventions. Delete `custom/*.conf` on the branch.
3. **P1.3** Write `monitors.lua` and `workspaces.lua` (D9); delete `monitors.conf` and
   `workspaces.conf` on the branch.
4. **P1.4** Port `ws12-mode.sh` and `ws-cycle.sh` to Lua-syntax `hyprctl dispatch`; delete
   `alt-tab.sh`. Consider moving the logic into Lua functions bound directly instead of
   shell scripts (decide during P1.4; both are acceptable if parity holds).
5. **P1.5** Rewrite the lid-switch binds (`hyprctl keyword monitor` is hyprlang-only).
   Copy upstream `hypridle.conf` and `hyprlock.conf` from `547836f1` onto the branch (D13).
6. **P1.6** `shell-qml` (standalone clone `~/dev/shell-qml`): build `rebase/upstream` = vendored upstream `quickshell/ii` @
   `547836f1` + re-applied commits (screenshot save, dock IPC toggle). See INVENTORY §4.
7. **P1.7** `luac -p` on every Lua file; walk the INVENTORY parity table line by line
   against the 0.56.0 wiki.
8. **P1.8** Update `README.md` (layout section now shows `.lua` files).
9. **P1.9** Check that `checkupdates` still shows Hyprland 0.56.x and re-read the dots
   commits after `547836f1`.
10. **P1.10** Last step: rebase `migrate/lua-0.56` onto `main` and push both branches. From
    here until RUNBOOK §7, **no commits on `main`**. Day-H notes (including the RUNBOOK
    outcome log) go on the branch, so the final `merge --ff-only` works.

### Phase 2: day H

Follow [RUNBOOK.md](RUNBOOK.md).

### Phase 3: follow-ups (separate work)

- `yay -Sua` for AUR packages.
- Remove AGS/astal leftovers and orphans (`pacman -Qdtq`).
- `paccache -r` once things have been stable for about a week.
- Clean up stale dirs: `~/.config/quickshell.backup`, `illogical-impulse.backup`,
  `swaync-backup`.

## 7. Acceptance criteria

Day H counts as done when all of the following hold after a reboot into **linux-lts**:

- [ ] `pacman -Qu` is empty and `IgnorePkg` no longer lists `hyprland`.
- [ ] `hyprctl version` reports 0.56.x and `~/.config/hypr/hyprland.lua` is the loaded config
      (no hyprlang deprecation banner, no config errors).
- [ ] `dkms status` shows nvidia 615.x `installed` for **both** kernels.
- [ ] The external monitor (SKYDATA, via NVIDIA DP-1) comes up in Layout B at 240 Hz.
- [ ] Every row of the INVENTORY §3 parity table passes.
- [ ] Quickshell runs from the `shell-qml` `rebase/upstream` branch; screenshot-save and
      dock IPC toggle work.
- [ ] hypridle: lock at 5 min, DPMS off/on at 10 min, suspend at 15 min; resume
      re-focuses the lock screen.
- [ ] Kitty and mpv customisations are restored (INVENTORY §5).
- [ ] The `linux` (mainline) kernel also boots to a working session (spot check).
- [ ] `hypr` and `shell-qml` changes are merged and pushed.

## 8. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| NVIDIA DKMS fails to build for the new kernel(s) | External monitor dead on that kernel; the laptop panel still works (AMD iGPU drives eDP-2) | Check `dkms status` before reboot; boot the other kernel; downgrade from the pkg cache |
| `grub` 2.16 package vs. stale EFI binary | Boot failure | `grub-install` + `grub-mkconfig` right after `-Syu` (RUNBOOK §4) |
| Lua config error on first login | No/partial session | `Hyprland --verify-config` first; fallback procedure in RUNBOOK §8 |
| 0.57 lands in the repo before day H | hyprlang fallback gone | Preflight check; re-plan if seen |
| `./setup install` deletes the shell-qml `.git` and kitty theme | Lost work | Push + tag before; restore steps in RUNBOOK §6 |
| Upstream 4-finger gestures use Lua lambdas, so `action = "unset"` may not match them | Unwanted 4-finger actions | Verify item V5 in INVENTORY; fallback is to override or redefine |
| Windows shares the ESP (`/boot/efi`, nvme1n1p1) | A wrong `--bootloader-id` creates a duplicate entry | Exact command fixed in RUNBOOK §4 (`--bootloader-id=GRUB`) |
