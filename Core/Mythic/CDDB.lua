local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

Core.CDDB = Core.CDDB or {
    ImportantSpells = {},
}
