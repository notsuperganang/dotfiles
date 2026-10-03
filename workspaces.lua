-- Workspace -> monitor mapping.
-- Monitor eksternal dicocokkan lewat deskripsi, sama seperti di monitors.lua.
local ext = "desc:SKYDATA S.P.A. F24G41F 0x01010101"

-- Single Monitor Setup
-- hl.workspace_rule({ workspace = "1", monitor = "eDP-2", default = true })

-- Dual Monitors Setup
hl.workspace_rule({ workspace = "1", monitor = ext, default = true })
hl.workspace_rule({ workspace = "2", monitor = ext })
hl.workspace_rule({ workspace = "3", monitor = ext })

hl.workspace_rule({ workspace = "4", monitor = "eDP-2" })
hl.workspace_rule({ workspace = "5", monitor = "eDP-2" })
