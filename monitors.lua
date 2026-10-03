-- =============================================================================
-- KONFIGURASI MONITOR
-- Ditulis manual (nwg-displays tidak dipakai, lihat docs/migration-0.56/adr/0005).
-- Field position/scale/mode bertipe string di Lua: "1925x2", "1.33".
-- =============================================================================

-- Monitor eksternal dicocokkan lewat deskripsi, bukan nama port (DP-1/DP-2),
-- jadi rule tetap berlaku di port mana pun monitor dicolok.
local ext = "desc:SKYDATA S.P.A. F24G41F 0x01010101"

-- -----------------------------------------------------------------------------
-- LAYOUT DUAL SCREEN
-- Aktifkan SATU layout saja (pasangan eDP-2 + ext), comment yang lain
-- -----------------------------------------------------------------------------

-- Layout A — Atas/bawah (monitor eksternal di atas, eDP-2 di bawah, rata tengah horizontal)
-- Offset 320px ke kanan agar center: (2560 - 1920) / 2 = 320
-- hl.monitor({ output = "eDP-2", mode = "2560x1440@165", position = "0x1080", scale = "1.33" })
-- hl.monitor({ output = ext, mode = "1920x1080@240", position = "320x0", scale = "1" })

-- Layout B — Kiri/kanan (eDP-2 di kiri, monitor eksternal di kanan, rata tengah vertikal)
-- Lebar logis eDP-2 = 2560 / 1.33 = 1925
-- Offset 2px ke bawah agar center: (1083 - 1080) / 2 = 2
hl.monitor({ output = "eDP-2", mode = "2560x1440@165", position = "0x0", scale = "1.33" })
hl.monitor({ output = ext, mode = "1920x1080@240", position = "1925x2", scale = "1" })

-- -----------------------------------------------------------------------------
-- MODE LAIN UNTUK MONITOR EKSTERNAL (ganti baris ext di layout aktif)
-- -----------------------------------------------------------------------------

-- Mirror / Presentasi (monitor eksternal mencerminkan eDP-2)
-- hl.monitor({ output = ext, mode = "1920x1080@60", position = "0x0", scale = "1", mirror = "eDP-2" })

-- Extended kiri (monitor eksternal di sebelah kiri eDP-2)
-- hl.monitor({ output = ext, mode = "1920x1080@60", position = "-1920x0", scale = "1" })
