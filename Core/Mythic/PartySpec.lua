local _, RRT_NS = ...

local Core = _G.RRTMythicTools
if not Core then
    return
end

local PartySpec = Core.PartySpec or {}
Core.PartySpec = PartySpec

function PartySpec:GetSpec(unit)
    if not Core.PartySync then
        return 0
    end
    return Core.PartySync:GetSpec(unit)
end

function PartySpec:GetCache()
    if not Core.PartySync then
        return {}
    end
    return Core.PartySync:GetCache()
end

function PartySpec:GetUnitData(unit)
    if not Core.PartySync then
        return nil
    end
    return Core.PartySync:GetUnitData(unit)
end

function PartySpec:Debug()
    if not Core.PartySync then
        return {}
    end
    return Core.PartySync:Debug()
end
