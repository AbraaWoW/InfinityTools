---@diagnostic disable: undefined-global

local MDTMod = InfinityBoss.MDT
MDTMod.Notes = MDTMod.Notes or {}

local Notes = MDTMod.Notes

local store = {}

function Notes.Register(routeKey, pullNotes)
    if type(routeKey) ~= "string" or routeKey == "" then return end
    if type(pullNotes) ~= "table" then return end
    store[routeKey] = pullNotes
end

function Notes.Get(routeKey, pullIndex)
    local t = store[tostring(routeKey or "")]
    if type(t) ~= "table" then return "" end
    return tostring(t[tonumber(pullIndex)] or "")
end
