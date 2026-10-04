-- usage: HOME=<fakehome> lua run.lua <harness dir>
local dir = arg[1]
local cfg = os.getenv("HOME") .. "/.config/hypr"
package.path = cfg .. "/?.lua;" .. cfg .. "/?/init.lua;" .. package.path
local state = dofile(dir .. "/stub.lua")

local ok, e = pcall(dofile, cfg .. "/hyprland.lua")
local s = state()
print(ok and "LOAD: ok" or ("LOAD: FAILED: " .. tostring(e)))
print(("errors: %d"):format(#s.errors))
for _, m in ipairs(s.errors) do print("  ! " .. m:gsub("\n", " | ")) end

print("\ngestures (final):")
for _, g in ipairs(s.gestures) do print(("  %d %-10s -> %s"):format(g.fingers, g.direction, type(g.action) == "function" and "<fn>" or g.action)) end

local function show(keys)
    local found = {}
    for _, b in ipairs(s.binds) do
        if b.keys:gsub("%s", ""):lower() == keys:gsub("%s", ""):lower() then
            local d = type(b.d) == "function" and "<fn>" or (b.d.__dsp .. "(" .. (type(b.d.args[1]) == "string" and b.d.args[1] or (type(b.d.args[1]) == "table" and "{...}" or "")) .. ")")
            found[#found + 1] = d .. (b.opts.description and ("  [" .. b.opts.description .. "]") or "")
        end
    end
    print(("  %-28s %s"):format(keys, #found == 0 and "(none)" or table.concat(found, " ; ")))
end
print("\nbinds we care about:")
for _, k in ipairs({ "CTRL + SUPER + Slash", "CTRL + SUPER + ALT + Slash", "SUPER + Tab", "SUPER + SHIFT + Tab", "ALT + Tab", "ALT + SHIFT + Tab",
    "SUPER + grave", "SUPER + SUPER_L", "SUPER + SUPER_R", "SUPER_L", "SUPER + D", "SUPER + CTRL + F", "SUPER + A", "SUPER + SHIFT + S",
    "switch:on:Lid Switch", "switch:off:Lid Switch" }) do show(k) end

-- Hyprland matches binds by modmask + key, so modifier order doesn't matter at runtime even
-- though hl.unbind() compares the literal string. Flag any custom bind that shares its
-- canonical combo with a bind from another file: both would fire.
local function canon(keys)
    local parts = {}
    for p in keys:gmatch("[^+]+") do parts[#parts + 1] = p:gsub("^%s+", ""):gsub("%s+$", "") end
    local key = table.remove(parts):lower()
    for i, m in ipairs(parts) do parts[i] = m:upper():gsub("^CONTROL$", "CTRL") end
    table.sort(parts)
    return table.concat(parts, "+") .. "|" .. key
end
local collisions = 0
for _, ours in ipairs(s.binds) do
    if ours.src:find("/custom/") then
        for _, other in ipairs(s.binds) do
            if not other.src:find("/custom/") and canon(other.keys) == canon(ours.keys) then
                collisions = collisions + 1
                print(("  ! collision: %q (%s) also bound by %q in %s"):format(ours.keys, ours.src:match("[^/]+$"), other.keys, other.src:match("[^/]+$")))
            end
        end
    end
end
print(("\nbind collisions with upstream: %d"):format(collisions))

-- Some apps (e.g. browsers for proctored work tests) must be able to maximize themselves.
-- suppress_event only accumulates (Window.cpp ORs the bits) and upstream rules are unnamed,
-- so a catch-all "maximize" suppression can't be undone from custom/ — flag it loudly.
local maxSuppress = 0
for _, w in ipairs(s.wrules) do
    local ev = w.rule.suppress_event
    local events = type(ev) == "table" and table.concat(ev, " ") or tostring(ev or "")
    if events:find("maximize") then
        local m = w.rule.match or {}
        maxSuppress = maxSuppress + 1
        print(("  ! window rule suppresses maximize (match class=%s title=%s) in %s"):format(
            tostring(m.class), tostring(m.title), w.src:match("[^/]+$")))
    end
end
print(("\nmaximize-suppressing window rules: %d"):format(maxSuppress))

print("\nmonitors:")
for o, r in pairs(s.monitors) do
    local parts = {}
    for k, v in pairs(r) do parts[#parts + 1] = k .. "=" .. tostring(v) end
    table.sort(parts)
    print(("  %-45s %s"):format(o == "" and '""' or o, table.concat(parts, " ")))
end
print("\nworkspace rules:")
for _, w in ipairs(s.wsrules) do print(("  ws %s -> %s%s"):format(w.workspace, tostring(w.monitor), w.default and " (default)" or "")) end
print("\nenv QT_SCALE_FACTOR=" .. tostring(s.envs.QT_SCALE_FACTOR) .. "  qsConfig=" .. tostring(s.envs.qsConfig))

if not ok or #s.errors > 0 or collisions > 0 or maxSuppress > 0 then os.exit(1) end
