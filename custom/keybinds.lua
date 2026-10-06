-- Custom keybinds, loaded after hyprland/keybinds.lua so they win.
-- See https://wiki.hypr.land/0.56.0/Configuring/Basics/Binds/
--
-- `hl.unbind("KEYS")` removes EVERY bind on that key combo (upstream often binds a
-- key twice: a Quickshell global plus a fallback). The match ignores case and
-- spaces but NOT modifier order, so copy the string exactly as upstream writes it.
-- Descriptions use "Category: text"; the cheatsheet groups by the category.

local scripts = "~/.config/hypr/custom/scripts"

-- --- User ---
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"),
    { description = "User: Edit shell config" })
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
    { description = "User: Edit extra keybinds" })

-- --- Workspace & focus ---
-- Super+Tab / Super+Shift+Tab: pindah workspace relatif (upstream: overview)
hl.unbind("SUPER + Tab")
hl.bind("SUPER + Tab", hl.dsp.exec_cmd(scripts .. "/ws12-mode.sh next"), { description = "User: Next workspace" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.exec_cmd(scripts .. "/ws-cycle.sh prev"), { description = "User: Previous workspace" })

-- Alt+Tab: pindah fokus antar window di workspace aktif
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "User: Next window" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }), { description = "User: Previous window" })

-- Toggle mode memasak (kunci Super+Tab ke WS 1 <-> 2)
hl.bind("SUPER + grave", hl.dsp.exec_cmd(scripts .. "/ws12-mode.sh toggle"), { description = "User: Toggle cook mode" })

-- Tap Super tidak membuka search (upstream: Quickshell search + fuzzel fallback)
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")

-- Super+D: overview (upstream: maximize)
hl.unbind("SUPER + D")
hl.bind("SUPER + D", hl.dsp.global("quickshell:overviewWorkspacesToggle"), { description = "User: Toggle overview" })
-- Maximize dipakai paling sering, jadi di Super+F; fullscreen penuh pindah ke Super+Ctrl+F
-- (upstream: Super+F = fullscreen)
hl.unbind("SUPER + F")
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
    { description = "User: Maximize" })
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
    { description = "User: Fullscreen" })

-- Super+A: toggle dock (upstream: sidebar kiri)
hl.unbind("SUPER + A")
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs -c $qsConfig ipc call dock toggle"), { description = "User: Toggle dock" })

-- --- Screenshot mode ---
-- Pilih SATU baris bind di bawah (comment yang lain).
hl.unbind("SUPER + SHIFT + S")
-- hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot"), { description = "User: Screenshot to clipboard" })
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshotSave"),
    { description = "User: Screenshot to clipboard + ~/Pictures/Screenshots" })

-- --- Lid switch ---
-- Tutup laptop -> matikan layar laptop (eDP-2), buka -> reload (posisi eDP-2 balik
-- dari layout aktif di monitors.lua). Saat DP-1 tersambung, logind tidak suspend
-- (HandleLidSwitchDocked=ignore). hl.monitor() saat runtime langsung diterapkan.
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = "eDP-2", disabled = true })
end, { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl reload"), { locked = true })
