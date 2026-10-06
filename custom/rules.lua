-- You can put custom rules here
-- Window/layer rules: https://wiki.hypr.land/0.56.0/Configuring/Basics/Window-Rules/
-- Workspace rules: https://wiki.hypr.land/0.56.0/Configuring/Basics/Workspace-Rules/

-- WhatsApp Web PWA always opens on workspace 3 (autostarted from custom/execs.lua)
hl.window_rule({ match = { class = "^(brave-hnpfjngllnobngcgfapefoaidbinmjnm-Default)$" }, workspace = "3 silent" })
