-- =============================================================
-- [[ InfinityTools Core Component: Party Specialization System (PartySpec) ]]
-- This implementation now reuses PartySync:
-- 1. Keep the legacy API so upper modules do not need changes
-- 2. Stop depending on LibSpecialization to avoid addon communication limits in instances
-- =============================================================

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

local PartySync = InfinityTools.PartySync
local PartySpec = {}
InfinityTools.PartySpec = PartySpec

function PartySpec:GetSpec(unit)
    if not PartySync then return 0 end
    return PartySync:GetSpec(unit)
end

function PartySpec:GetCache()
    if not PartySync then return {} end
    return PartySync:GetCache()
end

function PartySpec:Debug()
    if PartySync and PartySync.Debug then
        PartySync:Debug()
        return
    end
    print("|cffff0000[InfinityTools PartySpec]|r PartySync not initialized.")
end
