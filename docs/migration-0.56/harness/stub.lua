-- Strict stub of the Hyprland 0.56.2 Lua API, built from the names registered in
-- src/config/lua/bindings/*.cpp. Unknown names raise; gesture/unbind/monitor logic
-- mirrors TrackpadGestures.cpp, KeybindManager.cpp and MonitorRuleManager.cpp.
local errors, binds, gestures, monitors, wsrules, envs, wrules = {}, {}, {}, {}, {}, {}, {}
local function err(msg) errors[#errors + 1] = debug.traceback(msg, 3):match("[^\n]*\n[^\n]*\n[^\n]*") end

local function strict(name, t)
    return setmetatable(t, { __index = function(_, k) error(name .. "." .. tostring(k) .. " does not exist in 0.56.2", 2) end })
end
local function dsp(name) return function(...) return { __dsp = name, args = { ... } } end end
local function names(list, mk)
    local t = {}
    for n in list:gmatch("%S+") do t[n] = mk(n) end
    return t
end

local MONITOR_FIELDS = names("mode position scale reserved reserved_area disabled transform mirror bitdepth cm sdr_eotf sdrbrightness sdrsaturation vrr icc supports_wide_color supports_hdr", function(n) return n end)
local STRING_MON = names("mode position scale mirror cm sdr_eotf icc", function() return true end)
local WS_FIELDS = names("monitor default persistent gaps_in gaps_out float_gaps border_size no_border no_rounding decorate no_shadow on_created_empty default_name layout animation sensitivity accel_profile rotation kb_file kb_layout kb_variant kb_options kb_rules kb_model repeat_rate enabled", function() return true end)
local DIRS = names("swipe horizontal vertical left right up down pinch pinchin pinchout", function() return true end)
local AXIS = { up = "vertical", down = "vertical", vertical = "vertical", left = "horizontal", right = "horizontal", horizontal = "horizontal", swipe = "swipe", pinch = "pinch", pinchin = "pinch", pinchout = "pinch" }

local function norm(k) return (k:gsub("%s", ""):lower()) end

hl = strict("hl", {
    dsp = strict("hl.dsp", (function()
        local t = names("exec_cmd exec_raw exit submap pass send_shortcut send_key_state layout dpms event global force_renderer_reload force_idle release_input_capture focus no_op", dsp)
        t.cursor = strict("hl.dsp.cursor", names("move_to_corner move", dsp))
        t.group = strict("hl.dsp.group", names("toggle next prev active move_window lock lock_active", dsp))
        t.window = strict("hl.dsp.window", names("close kill signal float fullscreen fullscreen_state pseudo move swap center cycle_next tag clear_tags toggle_swallow pin bring_to_top alter_zorder set_prop deny_from_group drag resize", dsp))
        t.workspace = strict("hl.dsp.workspace", names("rename change_id move swap_monitors toggle_special", dsp))
        return t
    end)()),
    notification = strict("hl.notification", names("create get", function() return function() end end)),
})
local raw = getmetatable(hl).__index
setmetatable(hl, nil)
for n in ("on define_submap timer dispatch version get_loaded_plugins exec_cmd clear_crashed_lockscreen exec_scheduled_prop_refresh_immediately is_key_down config get_config device window_rule layer_rule permission load curve animation get_windows get_window get_active_window get_urgent_window get_workspaces get_workspace get_active_special_workspace get_monitors get_monitor get_active_monitor get_monitor_at get_monitor_at_cursor get_layers get_workspace_windows get_cursor_pos get_last_window get_last_workspace get_current_submap"):gmatch("%S+") do
    hl[n] = function() return nil end
end
hl.get_active_workspace = function() return { id = 1 } end

function hl.bind(keys, d, opts)
    if type(keys) ~= "string" then return err("hl.bind: keys must be a string") end
    if type(d) ~= "function" and not (type(d) == "table" and d.__dsp) then return err("hl.bind(" .. keys .. "): dispatcher must be hl.dsp.* or a function") end
    if opts ~= nil and type(opts) ~= "table" then return err("hl.bind(" .. keys .. "): flags must be a table") end
    binds[#binds + 1] = { keys = keys, d = d, opts = opts or {}, src = debug.getinfo(2, "S").short_src }
end
function hl.unbind(keys)
    if type(keys) ~= "string" then return err("hl.unbind: bad argument") end
    local n, kept = norm(keys), {}
    for _, b in ipairs(binds) do if norm(b.keys) ~= n then kept[#kept + 1] = b end end
    binds = kept
end
function hl.gesture(t)
    if type(t) ~= "table" then return err("hl.gesture: expected a table") end
    if not DIRS[t.direction] then return err("hl.gesture: bad direction " .. tostring(t.direction)) end
    local mods, scale = t.mods or "", t.scale or 1
    if t.action == "unset" then
        for i, g in ipairs(gestures) do
            if g.fingers == t.fingers and g.direction == t.direction and g.mods == mods and g.scale == scale then
                table.remove(gestures, i); return
            end
        end
        return err(("hl.gesture: Can't remove a non-existent gesture (%d %s)"):format(t.fingers, t.direction))
    end
    local axis = AXIS[t.direction]
    for _, g in ipairs(gestures) do
        if g.fingers == t.fingers and g.mods == mods and (g.direction == axis or g.direction == t.direction or ((axis == "vertical" or axis == "horizontal") and g.direction == "swipe")) then
            return err(("hl.gesture: Previous %s shadows new %s (%d fingers)"):format(g.direction, t.direction, t.fingers))
        end
    end
    gestures[#gestures + 1] = { fingers = t.fingers, direction = t.direction, mods = mods, scale = scale, action = t.action }
end
function hl.monitor(t)
    if type(t) ~= "table" or type(t.output) ~= "string" then return err("hl.monitor: 'output' required") end
    local rule = monitors[t.output] or {}
    for k, v in pairs(t) do
        if k ~= "output" then
            if not MONITOR_FIELDS[k] then err("hl.monitor: unknown field '" .. k .. "'")
            elseif STRING_MON[k] and type(v) ~= "string" and type(v) ~= "number" then err("hl.monitor: field '" .. k .. "' must be a string")
            else rule[k] = v end
        end
    end
    monitors[t.output] = rule
end
function hl.workspace_rule(t)
    if type(t) ~= "table" or type(t.workspace) ~= "string" then return err("hl.workspace_rule: 'workspace' required and must be a string") end
    for k in pairs(t) do if k ~= "workspace" and not WS_FIELDS[k] then err("hl.workspace_rule: unknown field '" .. k .. "'") end end
    wsrules[#wsrules + 1] = t
end
function hl.window_rule(t)
    if type(t) ~= "table" then return err("hl.window_rule: argument must be a table") end
    wrules[#wrules + 1] = { rule = t, src = debug.getinfo(2, "S").short_src }
end
function hl.env(k, v)
    if type(k) ~= "string" or type(v) ~= "string" then return err("hl.env: key and value must be strings") end
    envs[k] = v
end
setmetatable(hl, { __index = function(_, k) error("hl." .. tostring(k) .. " does not exist in 0.56.2", 2) end })
_ = raw

return function()
    return { errors = errors, binds = binds, gestures = gestures, monitors = monitors, wsrules = wsrules, envs = envs, wrules = wrules }
end
