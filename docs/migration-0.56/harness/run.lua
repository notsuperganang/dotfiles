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

if not ok or #s.errors > 0 then os.exit(1) end
