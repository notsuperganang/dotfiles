-- Custom startup commands. Wrap one-shot commands in hl.on("hyprland.start", ...),
-- which fires once per session (not on reload); see hyprland/execs.lua.

-- Login layout: terminal on 1, Brave (last session's tabs) on 2, WhatsApp PWA on 3
hl.on("hyprland.start", function ()
    hl.exec_cmd("kitty", { workspace = "1" })
    hl.exec_cmd("brave --restore-last-session", { workspace = "2 silent" })
    -- The PWA runs inside Brave's process, so an exec rule can't place it: it goes to
    -- workspace 3 via its class rule in custom/rules.lua. Start it once Brave is up.
    hl.exec_cmd("sleep 3 && brave --profile-directory=Default --app-id=hnpfjngllnobngcgfapefoaidbinmjnm")
end)
