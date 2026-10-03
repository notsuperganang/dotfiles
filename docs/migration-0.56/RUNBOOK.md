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
$ git -C ~/.cache/dots-hyprland log --oneline 547836f1..origin/main
```
✅ Review any commits after the pinned target. Either stay on `547836f1` or deliberately
move the pin (and re-check INVENTORY). If you move it, re-run the config check:
`$ ~/dev/hypr-lua/docs/migration-0.56/harness/check.sh <new-sha>` (the worktree still exists at §0).

```sh
$ df -h / /boot/efi          # free space on / must cover: ~5 GB packages + a full first Timeshift
                              # snapshot (≈ used size of / , more if /home is included, see V8)
$ systemctl --failed          # note the baseline so new failures stand out later
```

Check Timeshift's home handling (INVENTORY V8): open Timeshift → Settings → Users and note
whether `/home/notsuperganang` is included. Either way, the config rollback is git + the
local tarball below.

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
$ git checkout 547836f1   # or the pin agreed in §0
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
$ git add -A && git commit -m "chore: install end-4/dots-hyprland @ 547836f1 (Lua)"
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

Then spot-check the mainline kernel: reboot, pick `linux` in GRUB, confirm the session and the
external monitor work, and reboot back to lts.

When everything passes:
```sh
$ git -C ~/.config/hypr switch main && git -C ~/.config/hypr merge --ff-only migrate/lua-0.56
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
  git -C ii checkout pre-lua-migration   # the tag must exist in ~/dev/shell-qml (fetch --tags)
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
