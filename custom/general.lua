-- Put general config stuff here
-- Here's a list of every variable: https://wiki.hypr.land/0.56.0/Configuring/Basics/Variables/

-- --- Gestures ---
-- Matikan dulu gesture bawaan (hyprland/general.lua) sebelum menambah yang baru:
-- gesture baru ditolak kalau "tertutup" gesture lama (mis. 3-jari swipe menutup
-- 3-jari horizontal/up/down). `unset` harus cocok persis: fingers, direction,
-- mods, scale (action tidak ikut dicocokkan).
hl.gesture({ fingers = 3, direction = "swipe", action = "unset" })      -- bawaan: move
hl.gesture({ fingers = 3, direction = "pinch", action = "unset" })      -- bawaan: fullscreen
hl.gesture({ fingers = 4, direction = "horizontal", action = "unset" }) -- bawaan: workspace
hl.gesture({ fingers = 4, direction = "up", action = "unset" })         -- bawaan: overview
hl.gesture({ fingers = 4, direction = "down", action = "unset" })       -- bawaan: overview

-- workspace: 3-jari kiri/kanan
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- overview: 3-jari up & down sama-sama toggle
hl.gesture({
    fingers = 3,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end
})
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end
})

hl.config({
    misc = {
        on_focus_under_fullscreen = 1
    },
    input = {
        touchpad = {
            clickfinger_behavior = false,
            tap_to_click = true,
            tap_button_map = "lrm"
        }
    }
})
