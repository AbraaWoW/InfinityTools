local _, RRT_NS = ...

local Core = _G.RRTMythicTools
if not Core then
    return
end

local PartySync = Core.PartySync or {}
Core.PartySync = PartySync

local LibSpecialization = LibStub and LibStub("LibSpecialization", true)
local LibKeystone = LibStub and LibStub("LibKeystone", true)
local LibOpenRaid = LibStub and LibStub("LibOpenRaid-1.0", true)

PartySync.Cache = PartySync.Cache or {}
PartySync.GuidToUnit = PartySync.GuidToUnit or {}
PartySync.NameToGuid = PartySync.NameToGuid or {}
PartySync._callbacksRegistered = PartySync._callbacksRegistered or false

local function IsPartyCommAllowed()
    if not IsInGroup() or IsInRaid() then
        return false
    end

    local inInstance, instanceType = IsInInstance and IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid") then
        return false
    end

    return true
end

local function normalizeName(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return Ambiguate(name, "none")
end

local function ensureEntry(guid, unit)
    if not guid then
        return nil
    end

    local entry = PartySync.Cache[guid]
    if not entry then
        entry = {
            guid = guid,
            unit = unit,
            name = nil,
            shortName = nil,
            class = nil,
            specID = 0,
            keyLevel = 0,
            keyMapID = 0,
            rating = 0,
            specTS = 0,
            keyTS = 0,
            sourceSpec = nil,
            sourceKey = nil,
            updatedAt = 0,
        }
        PartySync.Cache[guid] = entry
    end

    if unit and UnitExists(unit) then
        entry.unit = unit
        entry.name = GetUnitName(unit, true) or entry.name
        entry.shortName = normalizeName(entry.name) or UnitName(unit) or entry.shortName
        local _, classTag = UnitClass(unit)
        entry.class = classTag or entry.class
        PartySync.GuidToUnit[guid] = unit
        if entry.name then
            PartySync.NameToGuid[entry.name] = guid
        end
        if entry.shortName then
            PartySync.NameToGuid[entry.shortName] = guid
        end
    end

    entry.updatedAt = GetTime()
    return entry
end

local function indexGroupUnits()
    wipe(PartySync.GuidToUnit)
    wipe(PartySync.NameToGuid)

    local units = { "player", "party1", "party2", "party3", "party4" }
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then
                ensureEntry(guid, unit)
            end
        end
    end
end

local function findGuidByName(name)
    if not name then
        return nil
    end
    return PartySync.NameToGuid[name] or PartySync.NameToGuid[normalizeName(name)]
end

local function findUnitByName(name)
    local guid = findGuidByName(name)
    return guid and PartySync.GuidToUnit[guid] or nil, guid
end

local function updateSpec(guid, unit, specID, source)
    specID = tonumber(specID) or 0
    if not guid or specID <= 0 then
        return
    end

    local entry = ensureEntry(guid, unit)
    if not entry then
        return
    end

    local changed = entry.specID ~= specID
    entry.specID = specID
    entry.specTS = GetTime()
    entry.specSource = source or "unknown"
    entry.sourceSpec = source or "unknown"
    entry.updatedAt = GetTime()

    if changed then
        Core:SendEvent("RRT_PARTY_SPEC_UPDATED", entry.unit, specID, guid)
        Core:SendEvent("INFINITY_PARTY_SPEC_UPDATED", entry.unit, specID, guid)
        Core:SendEvent("RRT_PARTY_INFO_UPDATED", entry.unit, guid)
        Core:SendEvent("INFINITY_PARTY_INFO_UPDATED", entry.unit, guid)
    end
end

local function updateKeystone(guid, unit, keyLevel, keyMapID, rating, source)
    if not guid then
        return
    end

    local entry = ensureEntry(guid, unit)
    if not entry then
        return
    end

    keyLevel = tonumber(keyLevel) or 0
    keyMapID = tonumber(keyMapID) or 0
    rating = tonumber(rating) or 0

    local changed = entry.keyLevel ~= keyLevel or entry.keyMapID ~= keyMapID or entry.rating ~= rating
    entry.keyLevel = keyLevel
    entry.keyMapID = keyMapID
    entry.rating = rating
    entry.keyTS = GetTime()
    entry.keySource = source or "unknown"
    entry.sourceKey = source or "unknown"
    entry.updatedAt = GetTime()

    if changed then
        Core:SendEvent("RRT_PARTY_KEYSTONE_UPDATED", entry.unit, keyLevel, keyMapID, rating, guid)
        Core:SendEvent("INFINITY_PARTY_KEYSTONE_UPDATED", entry.unit, keyLevel, keyMapID, rating, guid)
        Core:SendEvent("RRT_PARTY_INFO_UPDATED", entry.unit, guid)
        Core:SendEvent("INFINITY_PARTY_INFO_UPDATED", entry.unit, guid)
    end
end

local function updatePlayerInfo()
    local guid = UnitGUID("player")
    if not guid then
        return
    end

    ensureEntry(guid, "player")

    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        local specID = GetSpecializationInfo(specIndex)
        if specID then
            updateSpec(guid, "player", specID, "player")
        end
    end

    local keyLevel = 0
    local keyMapID = 0
    if C_MythicPlus then
        if C_MythicPlus.GetOwnedKeystoneLevel then
            keyLevel = C_MythicPlus.GetOwnedKeystoneLevel() or 0
        end
        if C_MythicPlus.GetOwnedKeystoneChallengeMapID then
            keyMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID() or 0
        end
    end

    local rating = 0
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if type(summary) == "table" then
            rating = tonumber(summary.currentSeasonScore) or 0
        end
    end

    updateKeystone(guid, "player", keyLevel, keyMapID, rating, "player")
end

local function refreshGroupFromInspect()
    if not LibSpecialization then
        return
    end

    if type(LibSpecialization.RequestGroupSpecialization) == "function" then
        LibSpecialization.RequestGroupSpecialization()
    end
end

local function refreshGroupFromKeystone()
    if not LibKeystone then
        return
    end

    if type(LibKeystone.Request) == "function" then
        LibKeystone.Request("PARTY")
    end
end

local function importOpenRaidUnit(unitData)
    if type(unitData) ~= "table" then
        return
    end

    local guid = unitData.unitGUID or findGuidByName(unitData.nameFull or unitData.name)
    local unit = guid and PartySync.GuidToUnit[guid] or nil
    if not guid then
        return
    end

    local entry = ensureEntry(guid, unit)
    if unitData.class and unitData.class ~= "" then
        entry.class = unitData.class
    end

    local specID = tonumber(unitData.specId or unitData.specID) or 0
    if specID > 0 then
        updateSpec(guid, unit, specID, "LibOpenRaid")
    end
end

local function importOpenRaidKeystone(unitName, keystoneData)
    if type(keystoneData) ~= "table" then
        return
    end

    local guid = keystoneData.guid or findGuidByName(unitName)
    local unit = guid and PartySync.GuidToUnit[guid] or nil
    if not guid then
        return
    end

    updateKeystone(
        guid,
        unit,
        keystoneData.level or keystoneData.keyLevel or 0,
        keystoneData.challengeMapID or keystoneData.mapID or 0,
        keystoneData.rating or 0,
        "LibOpenRaid"
    )
end

local function importLibSpecialization(specID, playerName)
    local unit, guid = findUnitByName(playerName)
    if not guid and playerName and normalizeName(playerName) == normalizeName(UnitName("player")) then
        unit = "player"
        guid = UnitGUID("player")
    end
    if guid and specID then
        updateSpec(guid, unit, specID, "LibSpecialization")
    end
end

function PartySync:RefreshAll()
    indexGroupUnits()
    updatePlayerInfo()
    refreshGroupFromInspect()
    refreshGroupFromKeystone()
end

function PartySync:GetCache()
    return self.Cache
end

function PartySync:GetUnitData(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end
    local guid = UnitGUID(unit)
    return guid and self.Cache[guid] or nil
end

function PartySync:GetMember(unit)
    return self:GetUnitData(unit)
end

function PartySync:GetSpec(unit)
    local data = self:GetUnitData(unit)
    return data and data.specID or 0
end

function PartySync:GetKeystone(unit)
    local data = self:GetUnitData(unit)
    if not data then
        return 0, 0, 0
    end
    return data.keyLevel or 0, data.keyMapID or 0, data.rating or 0
end

function PartySync:IsPartyCommAllowed()
    return IsPartyCommAllowed()
end

function PartySync:RequestPartyData()
    self:RefreshAll()
end

function PartySync:Debug()
    return self.Cache
end

local syncFrame = CreateFrame("Frame")
syncFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
syncFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
syncFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
syncFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
syncFrame:RegisterEvent("BAG_UPDATE_DELAYED")
syncFrame:SetScript("OnEvent", function(_, eventName, unit)
    if eventName == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then
        return
    end
    PartySync:RefreshAll()
end)

if not PartySync._callbacksRegistered then
    if LibOpenRaid and type(LibOpenRaid.RegisterCallback) == "function" then
        LibOpenRaid.RegisterCallback(PartySync, "UnitInfoUpdate", function(_, _, unitData)
            importOpenRaidUnit(unitData)
        end)
        LibOpenRaid.RegisterCallback(PartySync, "KeystoneUpdate", function(_, _, unitName, keystoneData)
            importOpenRaidKeystone(unitName, keystoneData)
        end)
    end

    if LibKeystone and type(LibKeystone.Register) == "function" then
        LibKeystone.Register(PartySync, function(keyLevel, challengeMapID, rating, playerName)
            local unit, guid = findUnitByName(playerName)
            if not guid and playerName and normalizeName(playerName) == normalizeName(UnitName("player")) then
                unit = "player"
                guid = UnitGUID("player")
            end
            if guid then
                updateKeystone(
                    guid,
                    unit,
                    keyLevel or 0,
                    challengeMapID or 0,
                    rating or 0,
                    "LibKeystone"
                )
            end
        end)
    end

    if LibSpecialization then
        if type(LibSpecialization.RegisterGroup) == "function" then
            LibSpecialization.RegisterGroup(PartySync, function(specID, _, _, playerName)
                importLibSpecialization(specID, playerName)
            end)
        end
        if type(LibSpecialization.RegisterPlayerSpecChange) == "function" then
            LibSpecialization.RegisterPlayerSpecChange(PartySync, function()
                local specID = type(LibSpecialization.MySpecialization) == "function" and LibSpecialization.MySpecialization() or nil
                if specID then
                    updateSpec(UnitGUID("player"), "player", specID, "LibSpecialization")
                end
            end)
        end
    end

    PartySync._callbacksRegistered = true
end

C_Timer.After(0, function()
    PartySync:RefreshAll()
end)
