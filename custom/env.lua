-- You can put extra environment variables here
-- https://wiki.hypr.land/0.56.0/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("QT_SCALE_FACTOR", "1")

-- --- Let apps maximize themselves ---
-- Some work-test browsers maximize themselves and flag "cheating" if they can't.
-- Upstream dots (7d3e85d3+) add an unnamed catch-all rule
--   hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
-- suppress_event only accumulates, so it can't be undone from custom/rules.lua.
-- custom/env.lua is the only custom file loaded before hyprland/rules.lua, so wrap
-- hl.window_rule here and drop "maximize" from catch-all rules only.
do
    local window_rule = hl.window_rule
    hl.window_rule = function(rule, ...)
        local match = type(rule) == "table" and rule.match
        if type(match) == "table" and match.class == ".*" and type(rule.suppress_event) == "string" then
            local kept = {}
            for ev in rule.suppress_event:gmatch("%S+") do
                if ev ~= "maximize" then kept[#kept + 1] = ev end
            end
            if #kept == 0 then return end
            rule.suppress_event = table.concat(kept, " ")
        end
        return window_rule(rule, ...)
    end
end
