-- =============================================================
-- [[ InfinityTools core component: party spec/keystone sync (PartySync) ]]
-- Design goals:
-- 1. Never send addon communication in Mythic+ or raid instances to avoid triggering AddOnMessageLockdown.
-- 2. In non-instance party environments, use lightweight addon communication to sync party specs and keystones.
-- 3. After entering a restricted environment, only consume existing caches; specs may still be filled in through Inspect.
-- 4. Passively support external data sources such as BigWigs / Details(OpenRaid), writing everything into the same cache.
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local PartySync = {}
InfinityTools.PartySync = PartySync

local PREFIX = "RevPTI1"
local MSG_REQUEST = "R"
local MSG_DATA = "D"
local COMM_THROTTLE = 2
local CACHE_TTL = 600
local GC_INTERVAL = 60
local INSPECT_TIMEOUT = 1.5

local Cache = {}          -- [guid] = data
local GuidToUnit = {}     -- [guid] = "partyN"
local NameToGUID = {}     -- [full/short/plain] = guid
local PendingInspect = {} -- FIFO queue of unit tokens
local PendingLookup = {}  -- [guid] = true

local activeInspectGUID
local inspectTimeoutTimer
local sendTimer
local requestTimer
local lastSendTime = 0
local lastRequestTime = 0

local RegisterAddonMessagePrefix = _G.C_ChatInfo and _G.C_ChatInfo.RegisterAddonMessagePrefix
local SendAddonMessage = _G.C_ChatInfo and _G.C_ChatInfo.SendAddonMessage
local LibSpecialization = _G.LibStub and _G.LibStub("LibSpecialization", true)
local LibKeystone = _G.LibStub and _G.LibStub("LibKeystone", true)
local LibOpenRaid = _G.LibStub and _G.LibStub("LibOpenRaid-1.0", true)
local libSpecReceiver = {}
local libKeystoneReceiver = {}
local libOpenRaidReceiver = {}
local libSpecRegistered = false
local libKeystoneRegistered = false
local libOpenRaidRegistered = false
local canaccessvalue = _G.canaccessvalue
local issecretvalue = _G.issecretvalue

local function CanUsePossiblySecretValue(value)
    if canaccessvalue then
        local ok, allowed = pcall(canaccessvalue, value)
        if ok then
            return allowed
        end
    end

    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then
            return false
        end
    end

    return true
end

local function NormalizeGUIDKey(guid)
    if type(guid) ~= "string" or guid == "" then
        return nil
    end
    return guid
end

local function NormalizeName(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if not CanUsePossiblySecretValue(name) then
        return nil
    end

    local ok, normalized = pcall(_G.Ambiguate, name, "none")
    if ok and type(normalized) == "string" then
        return normalized
    end

    return nil
end

local function GetPlayerSpecID()
    local specIndex = _G.GetSpecialization and _G.GetSpecialization()
    if not specIndex then return 0 end
    return _G.GetSpecializationInfo(specIndex) or 0
end

local function GetPlayerKeystoneInfo()
    local keyLevel = (_G.C_MythicPlus and _G.C_MythicPlus.GetOwnedKeystoneLevel and _G.C_MythicPlus.GetOwnedKeystoneLevel()) or 0
    local keyMapID = (_G.C_MythicPlus and _G.C_MythicPlus.GetOwnedKeystoneChallengeMapID and _G.C_MythicPlus.GetOwnedKeystoneChallengeMapID()) or 0
    local rating = 0
    if _G.C_PlayerInfo and _G.C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = _G.C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if type(summary) == "table" and type(summary.currentSeasonScore) == "number" then
            rating = summary.currentSeasonScore
        end
    end
    return keyLevel or 0, keyMapID or 0, rating or 0
end

local function HasRealPlayerPartyMembers()
    if not (_G.IsInGroup and _G.IsInGroup()) then
        return false
    end

    for i = 1, 4 do
        local unit = "party" .. i
        if _G.UnitExists(unit) and _G.UnitIsPlayer(unit) then
            return true
        end
    end

    return false
end

local function IsPartySyncContextAllowed()
    local state = InfinityTools.State or {}
    local inRaid = (_G.IsInRaid and _G.IsInRaid()) or state.IsInRaid
    if inRaid then
        return false
    end

    local inParty = (_G.IsInGroup and _G.IsInGroup()) or state.IsInParty
    if not inParty then
        return false
    end

    if not HasRealPlayerPartyMembers() then
        return false
    end

    if state.InMythicPlus then
        return false
    end

    local inInstance = false
    local instanceType = state.InstanceType
    if _G.IsInInstance then
        inInstance, instanceType = _G.IsInInstance()
    else
        inInstance = state.InInstance
    end

    if not inInstance then
        return true
    end

    return instanceType == "party"
end

local function IsPartyCommAllowed()
    if not SendAddonMessage then
        return false
    end
    return IsPartySyncContextAllowed()
end

local function EnsureCache(guid, unit)
    local entry = Cache[guid]
    if not entry then
        entry = {
            guid = guid,
            specID = 0,
            keyLevel = 0,
            keyMapID = 0,
            rating = 0,
            class = nil,
            name = nil,
            shortName = nil,
            unit = nil,
            specTS = 0,
            keyTS = 0,
            sourceSpec = nil,
            sourceKey = nil,
        }
        Cache[guid] = entry
    end

    if unit and _G.UnitExists(unit) then
        entry.unit = unit
        local fullName = _G.GetUnitName(unit, true)
        if type(fullName) == "string" and CanUsePossiblySecretValue(fullName) then
            entry.name = fullName
        end

        local plainName = _G.UnitName(unit)
        if type(plainName) ~= "string" or not CanUsePossiblySecretValue(plainName) then
            plainName = nil
        end

        entry.shortName = NormalizeName(entry.name) or plainName or entry.shortName
        local _, classTag = _G.UnitClass(unit)
        entry.class = classTag or entry.class
    end

    return entry
end

local function IndexUnit(unit)
    if not _G.UnitExists(unit) then return end

    local guid = NormalizeGUIDKey(_G.UnitGUID(unit))
    if not guid then return end

    GuidToUnit[guid] = unit
    local entry = EnsureCache(guid, unit)
    if entry.name then
        NameToGUID[entry.name] = guid
    end
    if entry.shortName then
        NameToGUID[entry.shortName] = guid
    end
    local plain = _G.UnitName(unit)
    if type(plain) == "string" and CanUsePossiblySecretValue(plain) then
        NameToGUID[plain] = guid
    end
end

local function FindGUIDBySender(sender)
    if not sender then return nil end
    if not CanUsePossiblySecretValue(sender) then
        return nil
    end
    return NameToGUID[sender] or NameToGUID[NormalizeName(sender)]
end

local function FindPartyUnitByName(name)
    if not IsPartySyncContextAllowed() then
        return nil
    end

    local guid = FindGUIDBySender(name)
    if guid then
        return guid, GuidToUnit[guid]
    end

    for i = 1, 4 do
        local unit = "party" .. i
        if _G.UnitExists(unit) then
            IndexUnit(unit)
            local unitGUID = NormalizeGUIDKey(_G.UnitGUID(unit))
            if unitGUID and FindGUIDBySender(name) == unitGUID then
                return unitGUID, unit
            end
        end
    end
end

local function ResolvePartyMember(unitHint, nameHint)
    if not IsPartySyncContextAllowed() then
        return nil
    end

    if type(unitHint) == "string" and unitHint ~= "" and _G.UnitExists(unitHint) then
        local guid = NormalizeGUIDKey(_G.UnitGUID(unitHint))
        if guid then
            IndexUnit(unitHint)
            return guid, unitHint
        end
    end

    return FindPartyUnitByName(nameHint or unitHint)
end

local function FireInfoEvent(unit, guid)
    InfinityTools:SendEvent("INFINITY_PARTY_INFO_UPDATED", unit, guid)
end

local function UpdateSpec(guid, unit, specID, source)
    specID = tonumber(specID) or 0
    if not guid or specID <= 0 then return end

    local entry = EnsureCache(guid, unit)
    local oldSpecID = entry.specID
    entry.specID = specID
    entry.specTS = _G.GetTime()
    entry.sourceSpec = source or "Unknown"

    local resolvedUnit = unit or GuidToUnit[guid]
    if oldSpecID ~= specID then
        InfinityTools:SendEvent("INFINITY_PARTY_SPEC_UPDATED", resolvedUnit, specID, guid)
        FireInfoEvent(resolvedUnit, guid)
    end
end

local function UpdateKeystone(guid, unit, keyLevel, keyMapID, rating, source)
    if not guid then return end

    local entry = EnsureCache(guid, unit)
    keyLevel = tonumber(keyLevel) or 0
    keyMapID = tonumber(keyMapID) or 0
    rating = tonumber(rating) or 0

    local changed = entry.keyLevel ~= keyLevel or entry.keyMapID ~= keyMapID or entry.rating ~= rating
    entry.keyLevel = keyLevel
    entry.keyMapID = keyMapID
    entry.rating = rating
    entry.keyTS = _G.GetTime()
    entry.sourceKey = source or "Unknown"

    if changed then
        local resolvedUnit = unit or GuidToUnit[guid]
        InfinityTools:SendEvent("INFINITY_PARTY_KEYSTONE_UPDATED", resolvedUnit, keyLevel, keyMapID, rating, guid)
        FireInfoEvent(resolvedUnit, guid)
    end
end

local function ImportOpenRaidUnitInfo(unitHint, unitInfo, source)
    if not IsPartySyncContextAllowed() then return end
    if type(unitInfo) ~= "table" then return end

    local guid, unit = ResolvePartyMember(unitHint, unitInfo.nameFull or unitInfo.name)
    if not guid then return end

    local entry = EnsureCache(guid, unit)
    if unitInfo.class and unitInfo.class ~= "" then
        entry.class = unitInfo.class
    end

    local specID = tonumber(unitInfo.specId) or 0
    if specID > 0 then
        UpdateSpec(guid, unit, specID, source or "OpenRaidUnit")
    end
end

local function ImportOpenRaidKeystone(unitHint, unitName, keystoneInfo, source)
    if not IsPartySyncContextAllowed() then return end
    if type(keystoneInfo) ~= "table" then return end

    local guid, unit = ResolvePartyMember(unitHint, unitName)
    if not guid then return end

    local entry = EnsureCache(guid, unit)
    if tonumber(keystoneInfo.classID) and tonumber(keystoneInfo.classID) > 0 and not entry.class and unit and _G.UnitExists(unit) then
        local _, classTag = _G.UnitClass(unit)
        entry.class = classTag or entry.class
    end

    local specID = tonumber(keystoneInfo.specID) or 0
    if specID > 0 then
        UpdateSpec(guid, unit, specID, source or "OpenRaidKey")
    end

    UpdateKeystone(
        guid,
        unit,
        tonumber(keystoneInfo.level) or 0,
        tonumber(keystoneInfo.challengeMapID) or 0,
        tonumber(keystoneInfo.rating) or 0,
        source or "OpenRaid"
    )
end

local function ImportOpenRaidCache()
    if not IsPartySyncContextAllowed() then return end
    if not LibOpenRaid then return end

    if LibOpenRaid.GetAllUnitsInfo then
        local allUnitsInfo = LibOpenRaid.GetAllUnitsInfo()
        if type(allUnitsInfo) == "table" then
            for unitName, unitInfo in pairs(allUnitsInfo) do
                ImportOpenRaidUnitInfo(unitName, unitInfo, "OpenRaidUnit")
            end
        end
    end

    if LibOpenRaid.GetAllKeystonesInfo then
        local allKeystonesInfo = LibOpenRaid.GetAllKeystonesInfo()
        if type(allKeystonesInfo) == "table" then
            for unitName, keystoneInfo in pairs(allKeystonesInfo) do
                ImportOpenRaidKeystone(nil, unitName, keystoneInfo, "OpenRaid")
            end
        end
    end
end

local function ClearInspectState()
    activeInspectGUID = nil
    if inspectTimeoutTimer then
        inspectTimeoutTimer:Cancel()
        inspectTimeoutTimer = nil
    end
    if _G.ClearInspectPlayer then
        _G.ClearInspectPlayer()
    end
end

local function TryInspectNext()
    if activeInspectGUID or _G.InCombatLockdown() then return end

    while #PendingInspect > 0 do
        local unit = table.remove(PendingInspect, 1)
        if _G.UnitExists(unit) then
            local guid = NormalizeGUIDKey(_G.UnitGUID(unit))
            if guid then
                PendingLookup[guid] = nil
                if _G.CanInspect(unit) then
                    activeInspectGUID = guid
                    _G.NotifyInspect(unit)
                    inspectTimeoutTimer = _G.C_Timer.NewTimer(INSPECT_TIMEOUT, function()
                        ClearInspectState()
                        TryInspectNext()
                    end)
                    return
                end
            end
        end
    end
end

local function QueueInspect(unit)
    if not IsPartySyncContextAllowed() then return end
    if _G.IsInRaid() then return end
    if not _G.UnitExists(unit) or _G.UnitIsUnit(unit, "player") then return end

    local guid = NormalizeGUIDKey(_G.UnitGUID(unit))
    if not guid or PendingLookup[guid] then return end

    local entry = Cache[guid]
    if entry and entry.specID and entry.specID > 0 and (_G.GetTime() - (entry.specTS or 0) < CACHE_TTL) then
        return
    end

    PendingLookup[guid] = true
    PendingInspect[#PendingInspect + 1] = unit
    TryInspectNext()
end

local function BuildPayload()
    local specID = GetPlayerSpecID()
    local keyLevel, keyMapID, rating = GetPlayerKeystoneInfo()
    return string.format("%s:%d,%d,%d,%d", MSG_DATA, specID, keyLevel, keyMapID, rating)
end

local function SendSnapshot(force)
    if not IsPartyCommAllowed() then return end

    local now = _G.GetTime()
    if not force and now - lastSendTime < COMM_THROTTLE then
        if not sendTimer then
            sendTimer = _G.C_Timer.NewTimer((COMM_THROTTLE + 0.1) - (now - lastSendTime), function()
                sendTimer = nil
                SendSnapshot(true)
            end)
        end
        return
    end

    lastSendTime = now
    local result = SendAddonMessage(PREFIX, BuildPayload(), "PARTY")
    if result == 9 and not sendTimer then
        sendTimer = _G.C_Timer.NewTimer(COMM_THROTTLE, function()
            sendTimer = nil
            SendSnapshot(true)
        end)
    end
end

local function RequestSnapshot(force)
    if not IsPartyCommAllowed() then return end

    local now = _G.GetTime()
    if not force and now - lastRequestTime < COMM_THROTTLE then
        if not requestTimer then
            requestTimer = _G.C_Timer.NewTimer((COMM_THROTTLE + 0.1) - (now - lastRequestTime), function()
                requestTimer = nil
                RequestSnapshot(true)
            end)
        end
        return
    end

    lastRequestTime = now
    local result = SendAddonMessage(PREFIX, MSG_REQUEST, "PARTY")
    if result == 9 and not requestTimer then
        requestTimer = _G.C_Timer.NewTimer(COMM_THROTTLE, function()
            requestTimer = nil
            RequestSnapshot(true)
        end)
    end
end

local function RebuildRoster()
    _G.wipe(GuidToUnit)
    _G.wipe(NameToGUID)

    if not _G.IsInGroup() or _G.IsInRaid() then
        _G.wipe(PendingInspect)
        _G.wipe(PendingLookup)
        ClearInspectState()
        return
    end

    for i = 1, 4 do
        local unit = "party" .. i
        if _G.UnitExists(unit) then
            IndexUnit(unit)
            QueueInspect(unit)
        end
    end
end

local function ApplyIncomingData(sender, specID, keyLevel, keyMapID, rating)
    local guid = FindGUIDBySender(sender)
    if not guid then return end

    local unit = GuidToUnit[guid]
    if specID and specID > 0 then
        UpdateSpec(guid, unit, specID, "Addon")
    end
    UpdateKeystone(guid, unit, keyLevel, keyMapID, rating, "Addon")
end

local function OnInspectReady(guid)
    guid = NormalizeGUIDKey(guid)
    if not guid then return end

    local unit = GuidToUnit[guid]
    if unit and _G.UnitExists(unit) then
        local specID = _G.GetInspectSpecialization(unit)
        if specID and specID > 0 then
            UpdateSpec(guid, unit, specID, "Inspect")
        end
    end

    if guid == activeInspectGUID then
        ClearInspectState()
        TryInspectNext()
    end
end

local function RefreshOwnData()
    local specID = GetPlayerSpecID()
    local keyLevel, keyMapID, rating = GetPlayerKeystoneInfo()
    if specID > 0 then
        PartySync.playerSpecID = specID
    end
    PartySync.playerKeyLevel = keyLevel
    PartySync.playerKeyMapID = keyMapID
    PartySync.playerRating = rating
end

local function TryHookExternalLibs()
    if not LibSpecialization and _G.LibStub then
        LibSpecialization = _G.LibStub("LibSpecialization", true)
    end
    if not LibKeystone and _G.LibStub then
        LibKeystone = _G.LibStub("LibKeystone", true)
    end
    if not LibOpenRaid and _G.LibStub then
        LibOpenRaid = _G.LibStub("LibOpenRaid-1.0", true)
    end

    if LibSpecialization and not libSpecRegistered then
        LibSpecialization.RegisterGroup(libSpecReceiver, function(specID, _, _, playerName)
            local guid, unit = FindPartyUnitByName(playerName)
            if guid and specID and specID > 0 then
                UpdateSpec(guid, unit, specID, "LibSpec")
            end
        end)
        libSpecRegistered = true
    end

    if LibKeystone and not libKeystoneRegistered then
        LibKeystone.Register(libKeystoneReceiver, function(keyLevel, keyMapID, rating, playerName, channel)
            if channel ~= "PARTY" then return end
            local guid, unit = FindPartyUnitByName(playerName)
            if guid then
                UpdateKeystone(guid, unit, keyLevel, keyMapID, rating, "LibKeystone")
            end
        end)
        libKeystoneRegistered = true
    end

    if LibOpenRaid and not libOpenRaidRegistered and LibOpenRaid.RegisterCallback then
        function libOpenRaidReceiver:OnUnitInfoUpdate(unitID, unitInfo)
            ImportOpenRaidUnitInfo(unitID, unitInfo, "OpenRaidUnit")
        end

        function libOpenRaidReceiver:OnKeystoneUpdate(unitName, keystoneInfo)
            ImportOpenRaidKeystone(nil, unitName, keystoneInfo, "OpenRaid")
        end

        LibOpenRaid.RegisterCallback(libOpenRaidReceiver, "UnitInfoUpdate", "OnUnitInfoUpdate")
        LibOpenRaid.RegisterCallback(libOpenRaidReceiver, "KeystoneUpdate", "OnKeystoneUpdate")
        libOpenRaidRegistered = true
    end

    if LibOpenRaid then
        ImportOpenRaidCache()
    end
end

local function RequestExternalLibData()
    if not IsPartyCommAllowed() then return end
    TryHookExternalLibs()

    if LibSpecialization and LibSpecialization.RequestGroupSpecialization then
        LibSpecialization.RequestGroupSpecialization()
    end
    if LibKeystone and LibKeystone.Request then
        LibKeystone.Request("PARTY")
    end
    if LibOpenRaid then
        ImportOpenRaidCache()
        if LibOpenRaid.RequestAllData then
            LibOpenRaid.RequestAllData()
        end
        if LibOpenRaid.RequestKeystoneDataFromParty then
            LibOpenRaid.RequestKeystoneDataFromParty()
        end
    end
end

local function CollectGarbage()
    local now = _G.GetTime()

    for guid, entry in pairs(Cache) do
        if not GuidToUnit[guid] then
            local newestTS = math.max(entry.specTS or 0, entry.keyTS or 0)
            if now - newestTS > CACHE_TTL then
                Cache[guid] = nil
            end
        end
    end
end

local function HandleAddonMessage(prefix, msg, channel, sender)
    if prefix ~= PREFIX or channel ~= "PARTY" then return end

    if msg == MSG_REQUEST then
        SendSnapshot()
        return
    end

    local specID, keyLevel, keyMapID, rating = string.match(msg, "^" .. MSG_DATA .. ":(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+)$")
    if not specID then return end

    ApplyIncomingData(sender, tonumber(specID), tonumber(keyLevel), tonumber(keyMapID), tonumber(rating))
end

local function OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        HandleAddonMessage(...)
    elseif event == "ADDON_LOADED" then
        TryHookExternalLibs()
    elseif event == "GROUP_ROSTER_UPDATE" then
        TryHookExternalLibs()
        RebuildRoster()
        RefreshOwnData()
        RequestSnapshot()
        RequestExternalLibData()
    elseif event == "PLAYER_ENTERING_WORLD" then
        _G.C_Timer.After(0.3, function()
            TryHookExternalLibs()
            RebuildRoster()
            RefreshOwnData()
            RequestSnapshot()
            SendSnapshot()
            RequestExternalLibData()
        end)
    elseif event == "INSPECT_READY" then
        OnInspectReady(...)
    elseif event == "PLAYER_REGEN_ENABLED" then
        TryInspectNext()
    elseif event == "ACTIVE_COMBAT_CONFIG_CHANGED" or event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        RefreshOwnData()
        SendSnapshot()
    elseif event == "BAG_UPDATE_DELAYED" or event == "ITEM_CHANGED" or event == "CHALLENGE_MODE_MAPS_UPDATE" then
        RefreshOwnData()
        SendSnapshot()
    end
end

function PartySync:GetSpec(unit)
    if unit == "player" then
        return GetPlayerSpecID()
    end

    local guid = NormalizeGUIDKey(_G.UnitGUID(unit))
    local entry = guid and Cache[guid]
    if not entry then return 0 end
    return entry.specID or 0
end

function PartySync:GetKeystone(unit)
    if unit == "player" then
        return GetPlayerKeystoneInfo()
    end

    local guid = NormalizeGUIDKey(_G.UnitGUID(unit))
    local entry = guid and Cache[guid]
    if not entry then
        return 0, 0, 0
    end
    return entry.keyLevel or 0, entry.keyMapID or 0, entry.rating or 0
end

function PartySync:GetMember(unit)
    local guid = NormalizeGUIDKey(_G.UnitGUID(unit))
    if not guid then return nil end
    return Cache[guid]
end

function PartySync:GetCache()
    return Cache
end

function PartySync:IsPartyCommAllowed()
    return IsPartyCommAllowed()
end

function PartySync:HasRealPartyMembers()
    return HasRealPlayerPartyMembers()
end

function PartySync:RequestPartyData()
    RefreshOwnData()
    RequestSnapshot()
    RequestExternalLibData()
end

function PartySync:BroadcastSelf()
    RefreshOwnData()
    SendSnapshot()
end

function PartySync:Debug()
    print("|cff00c0ff[InfinityTools PartySync]|r Debug report:")
    print("  Party comm:", IsPartyCommAllowed() and "|cff00ff00allowed|r" or "|cffff0000blocked|r")
    for guid, entry in pairs(Cache) do
        print(string.format("  - %s spec:%d key:+%d/%d rating:%d src:%s/%s",
            entry.shortName or guid:sub(-6),
            entry.specID or 0,
            entry.keyLevel or 0,
            entry.keyMapID or 0,
            entry.rating or 0,
            entry.sourceSpec or "?",
            entry.sourceKey or "?"))
    end
end

do
    local result = RegisterAddonMessagePrefix and RegisterAddonMessagePrefix(PREFIX)
    if type(result) == "number" and result > 1 then
        error("PartySync: Addon message prefix registration failed.")
    end
end

InfinityTools:RegisterEvent("CHAT_MSG_ADDON", "PartySync", OnEvent)
InfinityTools:RegisterEvent("ADDON_LOADED", "PartySync", OnEvent)
InfinityTools:RegisterEvent("GROUP_ROSTER_UPDATE", "PartySync", OnEvent)
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", "PartySync", OnEvent)
InfinityTools:RegisterEvent("INSPECT_READY", "PartySync", OnEvent)
InfinityTools:RegisterEvent("PLAYER_REGEN_ENABLED", "PartySync", OnEvent)
InfinityTools:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED", "PartySync", OnEvent)
InfinityTools:RegisterEvent("TRAIT_CONFIG_UPDATED", "PartySync", OnEvent)
InfinityTools:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "PartySync", OnEvent)
InfinityTools:RegisterEvent("BAG_UPDATE_DELAYED", "PartySync", OnEvent)
InfinityTools:RegisterEvent("ITEM_CHANGED", "PartySync", OnEvent)
InfinityTools:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE", "PartySync", OnEvent)

_G.C_Timer.NewTicker(GC_INTERVAL, CollectGarbage)
TryHookExternalLibs()
RefreshOwnData()

