# Runbook — day H

Prerequisites:
- Phase 1 is complete (PRD §6), including P1.10: `migrate/lua-0.56` is rebased onto `main`,
  and both it and `rebase/upstream` (in `~/dev/shell-qml`) are pushed. Every Lua file passes `luac -p`.
- No `pacman -S` / `yay -S` since planning (partial-upgrade guard, PRD §1).
- From here on, write notes and the outcome log **on `migrate/lua-0.56`**, not `main`.

Time budget: 3–4 h. **Abort rule:** if there is no usable Lua session 2 h after step 3
starts, go to §8 (fallback).

Keep this file open on a second device or print it. The desktop may be unusable mid-run.

Conventions: `$` = run as user, `#` = needs sudo. Each step has a ✅ check. Don't move on
until it passes.

---

## 0. Preflight (session still on 0.54.3)

```sh
$ checkupdates | grep -E '^(hyprland|aquamarine|hyprutils) '
$ pacman -Si --dbpath /tmp/checkup-db-$UID hyprland | grep Version
```
✅ Hyprland target is **0.56.x**. If it is **0.57.x**: STOP. The hyprlang fallback may be
gone. Re-plan before continuing.

```sh
$ git -C ~/.cache/dots-hyprland fetch
$ git -C ~/.cache/dots-hyprland log --oneline 33f31a08..origin/main
```
✅ Review any commits after the pinned target. (2026-10-04: the pin moved from `547836f1` to `33f31a08`,
decision D14; `7d3e85d3`'s maximize suppression is neutralised in `custom/env.lua`.) Either stay on `33f31a08` or deliberately
move the pin (and re-check INVENTORY). If you move it, re-run the config check:
`$ ~/dev/hypr-lua/docs/migration-0.56/harness/check.sh <new-sha>` (the worktree still exists at §0).

```sh
$ df -h / /boot/efi          # need ≥ ~20 GB free on /: ~5 GB packages + an incremental snapshot.
                              # 162 GB free after the dry-run snapshot on 2026-10-03
$ systemctl --failed          # note the baseline so new failures stand out later
```

Timeshift excludes `/root` and `/home/notsuperganang` (INVENTORY V8, checked 2026-10-03). If
anyone changed Settings → Users since, set both back to *Exclude All Files*, because a home-inclusive
first snapshot would not fit on `/`. Config rollback is git + the local tarball below.

## 1. Freeze the current state

```sh
# git tags (both repos must be clean and pushed)
$ git -C ~/.config/hypr status --short            # must be empty
$ git -C ~/.config/hypr tag pre-lua-migration && git -C ~/.config/hypr push origin pre-lua-migration
$ git -C ~/.config/quickshell/ii status --short   # must be empty
$ git -C ~/.config/quickshell/ii tag pre-lua-migration && git -C ~/.config/quickshell/ii push origin pre-lua-migration

# local tarball of everything setup may touch (stays on this disk)
$ mkdir -p ~/migration-backup
$ tar --zstd -cf ~/migration-backup/config-pre-lua-$(date +%F).tar.zst -C ~ \
    .config/hypr .config/quickshell .config/kitty .config/mpv .config/fish \
    .config/fuzzel .config/foot .config/illogical-impulse .config/kdeglobals
$ cp /etc/pacman.conf ~/migration-backup/pacman.conf.pre
```
✅ Both tags are visible on GitHub; the tarball exists and `tar -tf` lists files.

```sh
# Timeshift system snapshot
# timeshift --create --comments "pre-lua-migration (hyprland 0.54.3)" --tags O
```
✅ `sudo timeshift --list` shows the snapshot.

Reference: the dry-run snapshot `2026-10-03_22-08-23` (system only, ~135k+ files) took **554 s**
and used **~39 GB**. Day H's snapshot is incremental (rsync hardlinks against it), so expect
minutes and a few GB. Keep the dry-run snapshot until the migration is stable; it is a second,
older restore point. Run the snapshot with sleep/idle blocked, because hypridle locks after 5 min
and suspends after 15 min idle: `sudo systemd-inhibit --what=idle:sleep --why="timeshift snapshot" timeshift --create …`,
or keep a terminal open with `systemd-inhibit --what=idle:sleep --why="day H" sleep infinity` (works without
sudo; Ctrl+C to release). **Don't rely on the Quickshell keep-awake (coffee) toggle**: it silently stops
working after suspend/resume or monitor changes until Quickshell restarts (PRD Phase 3). Closing the lid is fine
only while the external monitor stays connected (logind `HandleLidSwitchDocked=ignore`).

## 2. Switch to a TTY

Log out of Hyprland and switch to TTY2 (`Ctrl+Alt+F2`). Do the upgrade from there, not from
inside the session being replaced.

## 3. Full system upgrade

```sh
# sed -i 's/^IgnorePkg   = hyprland/#IgnorePkg   = hyprland/' /etc/pacman.conf
# grep -n IgnorePkg /etc/pacman.conf          # ✅ line is commented
# pacman -Sy archlinux-keyring && pacman -Su
```
- Read every prompt. Expect provider/replace questions around the hypr* and Qt packages.
- **Do not** run `yay`/AUR updates here (D12).
- Watch the output for the `dkms` and `mkinitcpio` hooks. Errors there matter (§4).

✅ `pacman -Qu` is empty (AUR excluded). Save the transaction log:
`$ grep -n "$(date +%F)" /var/log/pacman.log > ~/migration-backup/pacman-dayH.log`

Check `pacman.log` for `.pacnew` files and merge any that matter
(`/etc/pacman.conf`, `/etc/mkinitcpio.conf`, `/etc/default/grub`):
`$ grep pacnew ~/migration-backup/pacman-dayH.log`

## 4. Kernel, NVIDIA, bootloader: before any reboot

```sh
$ dkms status
```
✅ Both lines show `nvidia/615.x, <kernel>, x86_64: installed`:
`7.2.x-arch…` **and** `6.18.54-…-lts`.

If one is missing or failed:
```sh
# dkms autoinstall -k <kernel-version>      # retry and read the error
```
If it still fails, the other kernel is the boot target. Note it and continue: the laptop panel
runs on the AMD iGPU either way; only the external monitor (NVIDIA DP-1) is affected.

```sh
# ls -l /boot/initramfs-linux*.img            # ✅ fresh timestamps for both kernels
```

GRUB (the package moved 2.14 → 2.16; Arch does not reinstall the EFI binary by itself). The ESP
is shared with Windows, so use **exactly** this bootloader-id:
```sh
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
# grub-mkconfig -o /boot/grub/grub.cfg
```
✅ `efibootmgr` still shows a single `GRUB` entry (Boot0001) plus Windows Boot Manager. No
duplicates. ✅ `grub-mkconfig` output lists both kernels and Windows (os-prober).

Default kernel (ADR-0004): the lts entry must be the default. Check which entry comes first:
```sh
# grep -E "^\s*menuentry '" /boot/grub/grub.cfg | head -3
```
If lts is not first, set `GRUB_DEFAULT` to the lts entry (by title, or `saved` +
`grub-set-default`) and re-run `grub-mkconfig`.

## 5. Install dots-hyprland (Lua)

First, put the hypr repo on the migration branch so setup writes on top of our Lua layer.
Hyprland isn't running (we're in a TTY), so the branch's Lua-syntax scripts can't break
anything yet.
```sh
$ git -C ~/.config/hypr worktree remove ~/dev/hypr-lua   # frees the branch (must be clean & pushed)
$ git -C ~/.config/hypr switch migrate/lua-0.56
```
✅ `ls ~/.config/hypr/custom` shows our `*.lua` files.

```sh
$ cd ~/.cache/dots-hyprland
$ git stash            # setup may have left local changes
$ git checkout 33f31a08   # or the pin agreed in §0
$ git submodule update --init --recursive
$ ./setup install
```
- When asked whether to back up clashing configs, answer **yes**.
- Setup rebuilds the `illogical-impulse-*` packages, including Quickshell against the new Qt.

What setup does that we undo or extend next (INVENTORY §5):
- rsync `--delete` → `~/.config/quickshell` (the fork's `.git` is gone), `kitty/current-theme.conf` deleted
- `hyprland.conf` → `hyprland.conf.old`; new `hyprland.lua` + `hyprland/*.lua`
- `hypridle.conf` / `hyprlock.conf` **not** replaced (non-first run): setup writes `*.new` beside them.
  Our branch already carries the upstream versions.

```sh
$ cd ~/.config/hypr
$ for f in hypridle.conf hyprlock.conf; do [ -f $f.new ] && diff $f $f.new && rm $f.new; done
$ grep -c 'hl.dsp' hypridle.conf   # ✅ > 0 (Lua-syntax dispatches, otherwise lock/DPMS break)
```
✅ `~/.config/hypr/hyprland.lua` exists; `pacman -Q illogical-impulse-quickshell-git` shows a
fresh build date.

## 6. Restore our layer

### 6.1 Hypr custom config

`~/.config/hypr` is the `dotfiles` repo on `migrate/lua-0.56`, so setup's output is now a
dirty tree on top of our branch.
```sh
$ cd ~/.config/hypr
$ git status --short          # review: hyprland/*.conf deleted, hyprland/*.lua + hyprland.lua added,
                              # maybe hyprland.conf.old; hypridle/hyprlock unchanged (*.new handled in §5)
$ ls custom/                  # ✅ our *.lua untouched (setup only creates placeholders if missing)
$ rm -f hyprland.conf.old     # still recoverable from the pre-lua-migration tag
$ git add -A && git commit -m "chore: install end-4/dots-hyprland @ 33f31a08 (Lua)"
```
Do **not** merge into `main` yet. That happens after verification (§7).

✅ The tree contains upstream `hyprland/` + `hyprland.lua`, our `custom/*.lua`, `monitors.lua`,
`workspaces.lua`, ported scripts (no `alt-tab.sh`), and upstream `hypridle.conf`/`hyprlock.conf`.
No `custom/*.conf`, `monitors.conf` or `workspaces.conf` remain (the branch deleted them).

### 6.2 Quickshell fork

```sh
$ cd ~/.config/quickshell
$ mv ii ii.setup                            # what setup installed (upstream @ pin)
$ git clone -b rebase/upstream ~/dev/shell-qml ii   # local clone: no network/SSH needed in a TTY
$ git -C ii remote set-url origin git@github.com:notsuperganang/shell-qml.git
$ diff -rq ii.setup ii | grep -v '\.git'    # ✅ only RegionSelection/RegionSelector/ScreenshotAction/Dock differ
$ rm -rf ii.setup
# .claude/ was untracked in the old fork, so restore it from the tarball (§1)
$ tar --zstd -xf ~/migration-backup/config-pre-lua-*.tar.zst -C ~ .config/quickshell/ii/.claude
```

### 6.3 Other configs

Re-apply from INVENTORY §5, using the tarball from §1 as the source:
```sh
$ mkdir -p ~/migration-backup/pre
$ tar --zstd -xf ~/migration-backup/config-pre-lua-*.tar.zst -C ~/migration-backup/pre .config/kitty .config/mpv
$ cp ~/migration-backup/pre/.config/kitty/current-theme.conf ~/.config/kitty/
$ diff ~/migration-backup/pre/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf   # re-apply our lines
$ diff ~/migration-backup/pre/.config/mpv/mpv.conf ~/.config/mpv/mpv.conf
```
- `kitty.conf`: font 14, opacity 0.85, `shell zsh`, Dracula include block; copy back `current-theme.conf`
- `mpv.conf`: `hwdec=auto`, `gpu-context=wayland`

## 7. Verify config, then log in

From the TTY, before starting the session:
```sh
$ Hyprland --verify-config
```
✅ No errors. If there are errors, fix them now (they point at the file/line).

Reboot into **linux-lts** (default), log in, and go through the PRD §7 acceptance list plus the
INVENTORY §3 parity table, row by row. V1–V7 were resolved from source in Phase 1; confirm them
live:
- `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` turns the screens off (any input or
  `{ action = "enable" }` turns them back on)
- `hyprctl -j activeworkspace | jq '.id, .monitor'` prints sensible values (used by the ws scripts)
- the error banner is empty (no shadowed or unset-missing gestures, no unknown fields)
- every bind and gesture in INVENTORY §3.1/§3.2, including lid close/open with the external monitor connected
- **apps can maximize themselves (D14)**: open a browser/app that requests maximize on start (e.g. the
  work-test browser, or a browser window closed while maximized) and confirm it comes up maximized.
  `hyprctl clients -j | jq '.[] | {class, fullscreen}'` shows `fullscreen: 1` for maximized windows

Then spot-check the mainline kernel: reboot, pick `linux` in GRUB, confirm the session and the
external monitor work, and reboot back to lts.

When everything passes:
```sh
# Fast-forward the main ref WITHOUT touching the live working tree, then switch (no file changes).
# Never `git switch main` first: that briefly restores the old hyprlang tree (no hyprland.lua),
# autoreload fires, and Hyprland drops into emergency mode with no binds (happened on 2026-10-04).
$ git -C ~/.config/hypr push . migrate/lua-0.56:main
$ git -C ~/.config/hypr switch main
$ git -C ~/.config/hypr push origin main
$ git -C ~/.config/quickshell/ii push origin rebase/upstream   # and make it the default branch when happy
```
Record the outcome (date, final versions, anything that deviated) at the bottom of this file.

---

## 8. Fallback and rollback

Use the **lightest** level that gets a working session.

### Level 1: fix forward (Lua error)
`Hyprland --verify-config` / the in-session error banner names the file and line. Fix it in a
TTY, then `hyprctl reload` or re-login.

### Level 2: back to hyprlang on 0.56 (Lua unusable, packages fine)
A coherent set must be restored. Renaming `hyprland.lua` alone is **not** enough, because setup
already replaced the hyprlang base files, hypridle and Quickshell:
```sh
$ cd ~/.config/hypr
$ git add -A && git commit -m "wip: lua migration (paused)"   # park the half-done Lua state on the branch
$ git switch --detach pre-lua-migration         # hyprland.conf, hyprland/*.conf, custom/*.conf, scripts, hypridle.conf
$ ls hyprland.lua 2>/dev/null && mv hyprland.lua hyprland.lua.disabled   # must not exist, or Lua wins
$ cd ~/.config/quickshell && rm -rf ii && \
  git clone ~/dev/shell-qml ii && \
  git -C ii checkout pre-lua-migration   # tag already exists locally in ~/dev/shell-qml (@ 461bf57)
```
Then re-login (or `hyprctl reload full-reset` from a running session). Hyprland 0.56 loads
`hyprland.conf` when no `hyprland.lua` exists.
⚠️ Only valid while the installed Hyprland still supports hyprlang (0.56.x). Old Quickshell
QML on a newer Qt and Hyprland may have glitches. This is a "get work done" mode, not a
destination.

### Level 3: boot the other kernel
NVIDIA/kernel trouble: choose the other kernel in GRUB (30 s timeout). The laptop panel works
on either kernel via the AMD iGPU.

### Level 4: package downgrade
Old packages are in `/var/cache/pacman/pkg` (don't run `paccache` until stable):
```sh
# pacman -U /var/cache/pacman/pkg/<pkg>-<oldver>-*.pkg.tar.zst
```
Use this for a single bad package (e.g. the NVIDIA driver). Downgrading Hyprland alone is
not viable because of the soname coupling. That's Level 5.

### Level 5: full system restore
```sh
# timeshift --restore      # pick the "pre-lua-migration" snapshot
```
Then restore the configs from the git tags / tarball (§1) if Timeshift excluded `/home`.
Re-add `IgnorePkg = hyprland`. You're back at the 2026-10-03 state. Re-plan before retrying.

---

## Outcome log

_(fill in on day H, on the `migrate/lua-0.56` branch)_

### 2026-10-04

- **P1.9** (07:2x): repo Hyprland = 0.56.2-4 (not 0.57). dots had 8 new commits; pin moved
  `547836f1` → `33f31a08` (D14) with the maximize wrapper in `custom/env.lua`; fork re-vendored.
- **§0** (07:3x): `/` 162 GB free, ESP 57 MB free; no failed system units; baseline failed user unit
  `plasma-xdg-desktop-portal-kde` (pre-existing); kernel `6.18.33-1-lts`; AC power, battery 98 %.
- **§1** (07:35–07:40): tags `pre-lua-migration` pushed (hypr @ `37d6dbf`, shell-qml @ `461bf57`);
  `~/migration-backup/config-pre-lua-2026-10-04.tar.zst` (1385 files) + `pacman.conf.pre`;
  Timeshift `2026-10-04_07-40-01` "pre-lua-migration (hyprland 0.54.3)": 27 s, 21.6 MB (linked to
  `2026-10-03_22-08-23`).
- **§2**: logged out to TTY. The external monitor stays dark on the console (it hangs off the NVIDIA
  GPU; fbcon is on the AMD iGPU), so keep the lid **open**. Shift+PgUp scrollback no longer exists
  (removed in kernel 5.9), so wrap long commands in `script -q -e -c "…" log`.
- **§3** (08:00–08:50), three attempts:
  1. `pacman -Su` → *ntfs-3g breaks dependency 'ntfsprogs' required by woeusb-ng*: ntfsprogs is now a
     separate package → add `ntfsprogs` to the transaction.
  2. download aborted (*Operation too slow* on `mirror.sg.cdn-perfprod.com`) → `--disable-download-timeout`.
  3. 98 file conflicts under `/usr/lib/node_modules/npm/` (npm had been self-updated to 12.0.1, leaving
     unowned files) → `--overwrite '/usr/lib/node_modules/npm/*'` (repo npm 12.2.0 is newer).
  Final command: `sudo pacman -Su ntfsprogs --disable-download-timeout --overwrite '/usr/lib/node_modules/npm/*'`
  → exit 0, 824 packages. Expected hook error: Quickshell symbol lookup after the Qt6 update (rebuilt in §5).
  `.pacnew`: locale.gen, mirrorlist, 2× tpm2-tss profiles (not boot-critical; review later).
- **§4**: DKMS nvidia 615.71.09 built for 7.2.8-arch1-2 and 6.18.54-2-lts; all 3 initramfs OK.
  **Deviation:** this machine has custom Secure Boot hooks (`/etc/pacman.d/hooks/99-secureboot-grub.hook`
  → `/usr/local/bin/regenerate-grub-secureboot.sh`: `grub-install` with a module list + `--sbat`, then
  `sbsign` with `/etc/mok/MOK.*`; `99-secureboot-kernel.hook` signs kernels). It already re-installed and
  signed GRUB, so the manual `grub-install` was **skipped** (it would have produced an unsigned GRUB without
  the module list). Only `grub-mkconfig` was run: lts first → default "Arch Linux" = linux-lts. Firmware
  SecureBoot efivar = 0 (currently disabled). Single GRUB EFI entry.
- **§5** (08:52–09:04): `./setup install -s` (skip sysupdate) at `33f31a08`. MicroTeX build failed:
  the cached clone `sdata/dist-arch/illogical-impulse-microtex-git/MicroTeX` pointed at the old
  `NanoMichael/MicroTeX` URL (upstream moved to `end-4/MicroTeX`) → deleted `MicroTeX/` and `src/`, retried
  OK. uv asked to replace the Quickshell venv → yes (it's recreated and requirements reinstalled).
  Quickshell rebuilt: 0.3.1 rev `41651d7`. `hypridle.conf.new`/`hyprlock.conf.new` identical → removed.
  Committed as `8f76b6c`.
- **§6**: fork cloned from `~/dev/shell-qml` (`rebase/upstream`); only our 4 files differ from setup's
  copy; `.claude/` restored from the tarball. kitty (+ `current-theme.conf`) and mpv restored verbatim.
- **§7** (pre-login): `Hyprland --verify-config` → `config ok`.
- **§7** (post-reboot, linux-lts): Hyprland 0.56.2, `hyprctl configerrors` empty, no failed units (the
  baseline `plasma-xdg-desktop-portal-kde` failure is gone too). Monitors: eDP-2 2560×1440@165 ×1.33 at 0x0,
  DP-1 SKYDATA 1920×1080@240 at 1925x2 (Layout B); ws 1–2 → DP-1 via `desc:`, ws 4 → eDP-2. NVIDIA 615.71.09
  loaded. 11 `User:` binds registered; Super+D/A/Tab/Shift+S each have exactly one bind; no Super-tap
  search binds; both lid binds `locked=true`. The user walked the parity checklist (binds, cook mode, gestures,
  lid, self-maximize, screenshot save, dock, lock): **all OK**.
  - **Regression found & fixed:** terminals opened **foot → fish** because upstream moved foot ahead of
    kitty in `terminal` (and dots' `foot.ini` has `shell=fish`); the login shell was still zsh. Fixed in
    `custom/variables.lua` (kitty first), commit `efa595e`.
  - EasyEffects isn't installed (never was; the old `exec-once` failed silently too). Not a regression.
- Merged `migrate/lua-0.56` → `main` (ff) and pushed; shell-qml `main` fast-forwarded to `rebase/upstream`.
  - **Incident:** the merge was done as `git switch main` + `merge --ff-only` inside the live
    `~/.config/hypr`. The switch briefly checked out the old hyprlang tree, autoreload saw no
    `hyprland.lua`, and Hyprland showed "emergency mode: a lua config error resulted in no binds being
    registered". The files came back with the merge; `hyprctl reload` restored all 198 binds. The merge
    step above now fast-forwards the ref with `git push . branch:main` instead.
- **Not done yet:** mainline kernel (`linux` 7.2.8) spot check; hypridle timings in normal use.
- **Post-migration (2026-10-04 ~10:00–10:30):** `yay -Syu` (removed the orphan Qt5 chain first: qt5-webengine,
  qt5-location, qt5-webchannel, qt5-remoteobjects, kirigami2, accounts-qml-module, plus foot). Cleanup: yay/pip/uv/
  thumbnail/Hugging Face caches (~45 GB); `pkg-cleanup.sh` removed 40 `-debug` packages, the AGS/astal stack,
  electron34/37/39, cef, js128 and the KF5 leftovers (npm marked explicit first, because AGS had pulled it in);
  journal trimmed to ~200 MB. Free space on `/`: 148 → 195 GB.
- **Timeshift:** new baseline `2026-10-04_10-20-04` "post-lua-migration (hyprland 0.56.2, stable)" (374 s, ~10 GB).
  Dry-run snapshot deleted. **Delete `2026-10-04_07-40-01` (pre-lua-migration) around 2026-10-18** if still stable.
