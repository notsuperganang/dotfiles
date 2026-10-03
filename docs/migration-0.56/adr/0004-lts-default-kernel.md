# ADR-0004: Keep two kernels; linux-lts is the default boot entry

Status: Accepted · 2026-10-03

## Context
Day H moves `nvidia-open-dkms` 595 → 615 alongside kernels `linux` 7.0 → 7.2 and `linux-lts`
6.18.33 → 6.18.54. The laptop panel (eDP-2) runs on the AMD iGPU and the external monitor
(DP-1) on the NVIDIA GPU, so a failed DKMS build costs the external monitor, not the whole
desktop. The machine already boots lts (`GRUB_DEFAULT=0` happens to be lts).

## Decision
Keep both kernels installed. lts is the default, set explicitly rather than by menu order.
Before rebooting, confirm the DKMS build for both kernels. After the grub 2.16 package
update, run `grub-install --bootloader-id=GRUB` + `grub-mkconfig` (the ESP is shared with
Windows).

## Consequences
- Every kernel/driver update must build for two kernels, which takes a little longer.
- Mainline is the fallback and gets a spot check on day H.
