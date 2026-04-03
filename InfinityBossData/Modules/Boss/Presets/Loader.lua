---@diagnostic disable: undefined-global

_G.InfinityBossData = _G.InfinityBossData or {}
_G.InfinityBoss_AUTHOR_PRESETS = _G.InfinityBoss_AUTHOR_PRESETS or { slots = {} }

local ROOT = _G.InfinityBoss_AUTHOR_PRESETS

function _G.InfinityBossData.RegisterBossPreset(slotKey, row)
    slotKey = tostring(slotKey or "")
    if slotKey == "" or type(row) ~= "table" then
        return
    end

    ROOT.slots = type(ROOT.slots) == "table" and ROOT.slots or {}
    ROOT.slots[slotKey] = type(ROOT.slots[slotKey]) == "table" and ROOT.slots[slotKey] or {}

    local key = tostring(row.key or row.author or row.name or "")
    if key == "" then
        return
    end

    ROOT.slots[slotKey][key] = {
        key = key,
        name = tostring(row.name or key),
        author = tostring(row.author or row.name or key),
        builtIn = (row.builtIn == true),
        events = type(row.events) == "table" and row.events or {},
    }
end

