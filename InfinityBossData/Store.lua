---@diagnostic disable: undefined-global
-- =============================================================
-- InfinityBossData/Store.lua
-- =============================================================

local DATA_WTF_VERSION = 3

_G.InfinityBossDataDB = _G.InfinityBossDataDB or {}

local _resolvedEventCache = {}
local _resolvedRootCache = nil
local GetFactoryDefaultEvent
local _encounterEventIndexCache = nil
local _encounterEventIndexSource = nil
local EVENT_BLACKLIST = {
    [513] = true,
}

local EVENT_TYPE_SCHEME_MAP = {
    ["Tank"] = "tank",
    ["Healing"] = "heal",
    ["Mechanic"] = "mechanic",
    ["Other"] = "cooldown",
}

local PACK_LABELS = {
    ["Prepare AOE"] = true, ["Prepare Beam"] = true, ["Prepare Interrupt"] = true, ["Prepare Pull"] = true, ["Prepare Block Line"] = true, ["Prepare Soak"] = true, ["Prepare Clear Stack"] = true,
    ["Prepare Target"] = true, ["Prepare Arrow"] = true, ["Prepare Enter Circle"] = true, ["Prepare Link"] = true, ["Prepare Ball"] = true, ["Prepare Hook"] = true, ["Prepare Stack"] = true,
    ["Prepare Dispel"] = true, ["Hit Clone"] = true, ["Tank Buster"] = true, ["Fix Camera"] = true, ["Clear Water"] = true, ["Find Beacon"] = true, ["Step Trap"] = true,
    ["None"] = true, ["Watch Knockback"] = true, ["Watch Frontal"] = true, ["Block Ball"] = true, ["Clear Ball"] = true, ["Watch Dodge"] = true, ["Target Frontal"] = true,
    ["Target Drop Water"] = true, ["Target Clear Line"] = true, ["Dodge Frontal"] = true, ["Switch Add"] = true, ["Phase Change"] = true, ["Away Boss"] = true, ["Spread Close"] = true, ["Kite Add"] = true,
    ["Boss Enrage"] = true, ["Boss Vuln"] = true, ["You White"] = true, ["You Black"] = true, ["Prepare AOE Break"] = true, ["Prepare Absorb Ball"] = true, ["Drop Water"] = true,
    ["Intercept Add"] = true, ["Beam On You"] = true, ["Watch Shockwave"] = true, ["Watch Launch"] = true, ["Empower HPal"] = true, ["Empower Ret"] = true, ["Empower Prot"] = true,
    ["Spread Now"] = true, ["Interrupt Now"] = true, ["Rescue Now"] = true, ["Break Shield"] = true, ["Enter Bubble"] = true, ["Break Link"] = true, ["Vuln Burst"] = true, ["Use Defensive"] = true,
    ["Watch Healing"] = true, ["Special Mechanic"] = true, ["Switch Boss"] = true, ["Away Add"] = true, ["Stack Share"] = true,
    ["Countdown 5"] = true, ["Countdown 4"] = true, ["Countdown 3"] = true, ["Countdown 2"] = true, ["Countdown 1"] = true,
}

local function SafeNum(v)
    local n = tonumber(v)
    return n
end

local function IsEventBlacklisted(eventID)
    local eid = tonumber(eventID)
    return eid and EVENT_BLACKLIST[eid] and true or false
end

local function DeepCopy(v)
    if type(v) ~= "table" then
        return v
    end
    local out = {}
    for k, x in pairs(v) do
        out[k] = DeepCopy(x)
    end
    return out
end

local function WipeTable(t)
    if type(t) ~= "table" then
        return
    end
    if wipe then
        wipe(t)
        return
    end
    for k in pairs(t) do
        t[k] = nil
    end
end

local function MarkEventConfigDirty(eventID)
    _resolvedRootCache = nil
    if eventID ~= nil then
        _resolvedEventCache[tonumber(eventID) or eventID] = nil
        return
    end
    WipeTable(_resolvedEventCache)
end

local function MergeOverride(dst, src)
    if type(src) ~= "table" then
        return dst
    end
    if type(dst) ~= "table" then
        dst = {}
    end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            MergeOverride(dst[k], v)
        else
            dst[k] = DeepCopy(v)
        end
    end
    return dst
end

local function BuildOverrideDelta(current, defaults)
    local currentType = type(current)
    local defaultType = type(defaults)

    if currentType ~= "table" then
        if defaults == nil or current ~= defaults then
            return current
        end
        return nil
    end

    local out = {}
    local hasAny = false
    for k, v in pairs(current) do
        local delta = BuildOverrideDelta(v, defaultType == "table" and defaults[k] or nil)
        if delta ~= nil then
            out[k] = delta
            hasAny = true
        end
    end

    if hasAny then
        return out
    end
    return nil
end

local function NormalizeStandaloneTriggerStorage(trigger)
    if type(trigger) ~= "table" then
        return nil
    end
    if type(trigger.label) == "string" and trigger.label == "" then
        trigger.label = nil
    end
    if type(trigger.customLSM) == "string" and trigger.customLSM == "" then
        trigger.customLSM = nil
    end
    if type(trigger.customPath) == "string" and trigger.customPath == "" then
        trigger.customPath = nil
    end

    if next(trigger) == nil then
        return nil
    end
    return trigger
end

local function NormalizeEventOverrideRowForStorage(row)
    if type(row) ~= "table" then
        return nil
    end
    if type(row.centralText) == "string" and row.centralText == "" then
        row.centralText = nil
    end

    if type(row.preAlertText) == "string" and row.preAlertText == "" then
        row.preAlertText = nil
    end

    if type(row.timerBarRenameText) == "string" and row.timerBarRenameText == "" then
        row.timerBarRenameText = nil
    end

    if type(row.color) == "table" then
        if type(row.color.scheme) == "string" and row.color.scheme == "" then
            row.color.scheme = nil
        end
        if row.color.r == nil and row.color.g == nil and row.color.b == nil and next(row.color) == nil then
            row.color = nil
        elseif next(row.color) == nil then
            row.color = nil
        end
    end

    if type(row.triggers) == "table" then
        local normalized = {}
        for triggerKey, triggerCfg in pairs(row.triggers) do
            local kept = NormalizeStandaloneTriggerStorage(type(triggerCfg) == "table" and DeepCopy(triggerCfg) or nil)
            if kept then
                normalized[triggerKey] = kept
            end
        end
        if next(normalized) == nil then
            row.triggers = nil
        else
            row.triggers = normalized
        end
    end

    if type(row.rules) == "table" then
        local cw = row.rules.castWindow
        if type(cw) == "table" then
            if next(cw) == nil then
                row.rules.castWindow = nil
            end
        end
        if next(row.rules) == nil then
            row.rules = nil
        end
    end

    if next(row) == nil then
        return nil
    end
    return row
end

local function BuildCompactedEventOverride(eventID, row)
    local eid = tonumber(eventID)
    if not eid or type(row) ~= "table" then
        return nil
    end
    local normalized = NormalizeEventOverrideRowForStorage(DeepCopy(row))
    if type(normalized) ~= "table" then
        return nil
    end
    return BuildOverrideDelta(normalized, GetFactoryDefaultEvent(eid))
end

local function BuildEncounterEventIndex()
    local data = _G.InfinityBoss_ENCOUNTER_DATA
    if _encounterEventIndexCache and _encounterEventIndexSource == data then
        return _encounterEventIndexCache
    end
    local out = {}
    if type(data) == "table" and type(data.maps) == "table" then
        for _, mapRow in pairs(data.maps) do
            if type(mapRow) == "table" and type(mapRow.bosses) == "table" then
                for _, bossRow in pairs(mapRow.bosses) do
                    if type(bossRow) == "table" and type(bossRow.events) == "table" then
                        for rawEventID, eventRow in pairs(bossRow.events) do
                            local eid = tonumber(rawEventID) or (type(eventRow) == "table" and tonumber(eventRow.eventID))
                            if eid and type(eventRow) == "table" and not IsEventBlacklisted(eid) then
                                out[eid] = eventRow
                            end
                        end
                    end
                end
            end
        end
    end
    _encounterEventIndexCache = out
    _encounterEventIndexSource = data
    return out
end

local function GetEncounterEventRow(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    if IsEventBlacklisted(eid) then
        return nil
    end
    local index = BuildEncounterEventIndex()
    return type(index) == "table" and index[eid] or nil
end

local function BuildFactoryRowFromEncounterEvent(eventID, eventRow)
    local eid = tonumber(eventID)
    if not eid or type(eventRow) ~= "table" then
        return nil
    end
    if IsEventBlacklisted(eid) then
        return nil
    end
    local label = tostring(eventRow.voiceLabel or "")
    local eventType = tostring(eventRow.eventType or "Other")
    local scheme = EVENT_TYPE_SCHEME_MAP[eventType] or "cooldown"
    local sourceType = PACK_LABELS[label] and "pack" or "none"
    return {
        enabled = true,
        centralEnabled = false,
        eventID = eid,
        color = {
            enabled = true,
            scheme = scheme,
            useCustom = false,
        },
        triggers = {
            [0] = { enabled = false, label = label, sourceType = sourceType },
            [1] = { enabled = true,  label = label, sourceType = sourceType },
            [2] = { enabled = false, label = label, sourceType = sourceType },
        },
    }
end

local function GetFactoryDefaultsRoot()
    local out = {}
    local index = BuildEncounterEventIndex()
    for eid, eventRow in pairs(index) do
        local row = BuildFactoryRowFromEncounterEvent(eid, eventRow)
        if type(row) == "table" then
            out[eid] = row
        end
    end
    return out
end

GetFactoryDefaultEvent = function(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    if IsEventBlacklisted(eid) then
        return nil
    end
    return BuildFactoryRowFromEncounterEvent(eid, GetEncounterEventRow(eid))
end

local function ResetLegacySavedData()
    InfinityBossDataDB = {
        wtfVersion = DATA_WTF_VERSION,
        events = {},
        timer = {
            timelineMode = {},
        },
    }

    if type(InfinityBossDB) == "table" then
        InfinityBossDB.voice = type(InfinityBossDB.voice) == "table" and InfinityBossDB.voice or {}
        InfinityBossDB.voice.profiles = nil
        InfinityBossDB.voice.activeProfileMplus = nil
        InfinityBossDB.voice.activeProfileRaid = nil
    end

    MarkEventConfigDirty()
end

local function InitInfinityBossDataDB()
    if type(InfinityBossDataDB) ~= "table" or tonumber(InfinityBossDataDB.wtfVersion) ~= DATA_WTF_VERSION then
        ResetLegacySavedData()
        return
    end

    InfinityBossDataDB.events = type(InfinityBossDataDB.events) == "table" and InfinityBossDataDB.events or {}
    InfinityBossDataDB.timer = type(InfinityBossDataDB.timer) == "table" and InfinityBossDataDB.timer or {}
    InfinityBossDataDB.timer.timelineMode = type(InfinityBossDataDB.timer.timelineMode) == "table" and InfinityBossDataDB.timer.timelineMode or {}
end

local function GetOverrideRoot()
    InitInfinityBossDataDB()
    return InfinityBossDataDB.events
end

local function BuildResolvedEvent(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end

    local cached = _resolvedEventCache[eid]
    if type(cached) == "table" then
        return cached
    end

    local defaults = GetFactoryDefaultEvent(eid)
    local override = GetOverrideRoot()[eid]

    if type(defaults) ~= "table" and type(override) ~= "table" then
        return nil
    end

    local resolved = DeepCopy(defaults or {})
    MergeOverride(resolved, override)
    _resolvedEventCache[eid] = resolved
    return resolved
end

local function BuildResolvedRoot()
    if type(_resolvedRootCache) == "table" then
        return _resolvedRootCache
    end

    local out = {}
    local seen = {}
    local defaultsRoot = GetFactoryDefaultsRoot()
    local overrideRoot = GetOverrideRoot()

    for rawKey in pairs(defaultsRoot) do
        local eid = tonumber(rawKey)
        if eid then
            seen[eid] = true
            local resolved = BuildResolvedEvent(eid)
            if type(resolved) == "table" then
                out[eid] = resolved
            end
        end
    end

    for rawKey in pairs(overrideRoot) do
        local eid = tonumber(rawKey)
        if eid and not seen[eid] then
            local resolved = BuildResolvedEvent(eid)
            if type(resolved) == "table" then
                out[eid] = resolved
            end
        end
    end

    _resolvedRootCache = out
    return out
end

local function CompactEventOverride(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    if IsEventBlacklisted(eid) then
        return nil
    end

    local root = GetOverrideRoot()
    local row = root[eid]
    if type(row) ~= "table" then
        root[eid] = nil
        MarkEventConfigDirty(eid)
        return nil
    end

    local compacted = BuildCompactedEventOverride(eid, row)
    if type(compacted) == "table" then
        root[eid] = compacted
    else
        root[eid] = nil
    end
    MarkEventConfigDirty(eid)
    return root[eid]
end

local function CompactAllEventOverrides()
    local root = GetOverrideRoot()
    local toCheck = {}
    for rawKey in pairs(root) do
        toCheck[#toCheck + 1] = rawKey
    end
    for i = 1, #toCheck do
        CompactEventOverride(toCheck[i])
    end
    MarkEventConfigDirty()
end

local function BuildInterval(cdSeriesSec)
    if type(cdSeriesSec) ~= "table" then
        return nil
    end
    local out = {}
    for _, v in ipairs(cdSeriesSec) do
        local n = SafeNum(v)
        if n and n > 0 then
            out[#out + 1] = n
        end
    end
    if #out == 0 then return nil end
    if #out == 1 then return out[1] end
    return out
end

local function BuildTimelineSkill(eventID, event)
    if type(event) ~= "table" then return nil end
    if IsEventBlacklisted(eventID) then return nil end
    local first = SafeNum(event.firstSeenSec)
    if not first then
        return nil
    end

    local evenSpellID = SafeNum(event.evenSpellID)
    local spellID = SafeNum(event.spellID) or evenSpellID
    local name = event.eventName or event.name
        or (spellID and ("Spell " .. tostring(spellID)))
        or ("Event " .. tostring(eventID))
    local voiceLabel = tostring(event.voiceLabel or name or "")

    return {
        eventID = SafeNum(event.eventID) or SafeNum(eventID),
        spellID = spellID,
        evenSpellID = evenSpellID,
        spellIdentifier = evenSpellID or spellID,
        displayName = name,
        source = "fixed",
        first = first,
        interval = BuildInterval(event.cdSeriesSec),
        preAlert = 5,
        castDuration = 1.5,
        barPriority = 2,
        showBunBar = true,
        showTimerBar = true,
        screenAlert = false,
        preAlertText = "{name}",
        screenText = nil,
        voiceLabel = voiceLabel,
    }
end

local function BuildTimelineBossRow(mapID, bossID, boss)
    if type(boss) ~= "table" then return nil, nil end
    local encounterID = SafeNum(boss.encounterID) or SafeNum(bossID)
    if not encounterID then return nil, nil end

    local skills = {}
    if type(boss.events) == "table" then
        for eventID, event in pairs(boss.events) do
            local skill = BuildTimelineSkill(eventID, event)
            if skill then
                skills[#skills + 1] = skill
            end
        end
    end

    table.sort(skills, function(a, b)
        if a.first ~= b.first then
            return a.first < b.first
        end
        return (SafeNum(a.eventID) or 0) < (SafeNum(b.eventID) or 0)
    end)

    local fixedSet = _G.InfinityBoss_FIXED_TIMELINE_ENCOUNTERS or {}
    local canFixed = (fixedSet[encounterID] == true) and (#skills > 0)

    return encounterID, {
        encounterID = encounterID,
        name = boss.bossName or boss.name or tostring(encounterID),
        mapID = SafeNum(mapID),
        axisType = canFixed and "fixed" or "blizzard",
        skills = skills,
    }
end

local function GetEncounterMaps()
    local data = _G.InfinityBoss_ENCOUNTER_DATA
    if type(data) ~= "table" then
        return nil
    end
    if type(data.maps) == "table" then
        return data.maps
    end
    return data
end

local function RebuildTimelineBosses()
    local maps = GetEncounterMaps()
    if type(maps) ~= "table" then
        print("|cffff4400InfinityBoss|r Store: EncounterData missing (please enable InfinityBossData addon)")
        return
    end

    InfinityBoss = InfinityBoss or {}
    InfinityBoss.Timeline = InfinityBoss.Timeline or {}
    InfinityBoss.Timeline._bosses = {}

    for mapID, map in pairs(maps) do
        if type(map) == "table" and type(map.bosses) == "table" then
            for bossID, boss in pairs(map.bosses) do
                local encounterID, bossDef = BuildTimelineBossRow(mapID, bossID, boss)
                if encounterID and bossDef then
                    InfinityBoss.Timeline._bosses[encounterID] = bossDef
                end
            end
        end
    end
end

_G.InfinityBossData = _G.InfinityBossData or _G.InfinityBossData or {}
_G.InfinityBossData = _G.InfinityBossData

function _G.InfinityBossData.GetEncounterDataRoot()
    return GetEncounterMaps() or {}
end

function _G.InfinityBossData.GetFactoryEventDefaults(eventID)
    local eid = tonumber(eventID)
    if eid then
        if IsEventBlacklisted(eid) then
            return nil
        end
        return GetFactoryDefaultEvent(eid)
    end
    return GetFactoryDefaultsRoot()
end

function _G.InfinityBossData.GetEventOverrideRoot()
    return GetOverrideRoot()
end

function _G.InfinityBossData.GetResolvedEventConfig(eventID)
    if IsEventBlacklisted(eventID) then
        return nil
    end
    return BuildResolvedEvent(eventID)
end

function _G.InfinityBossData.GetEventConfigRoot()
    return BuildResolvedRoot()
end

function _G.InfinityBossData.TouchEventConfig(eventID)
    MarkEventConfigDirty(eventID)
end

function _G.InfinityBossData.CompactEventOverride(eventID)
    if IsEventBlacklisted(eventID) then
        return nil
    end
    return CompactEventOverride(eventID)
end

function _G.InfinityBossData.CompactExternalEventOverride(eventID, row)
    if IsEventBlacklisted(eventID) then
        return nil
    end
    return BuildCompactedEventOverride(eventID, row)
end

function _G.InfinityBossData.IsEventBlacklisted(eventID)
    return IsEventBlacklisted(eventID)
end

function _G.InfinityBossData.CompactAllEventOverrides()
    CompactAllEventOverrides()
end

function _G.InfinityBossData.GetTimelineModeDB()
    InitInfinityBossDataDB()
    local tdb = InfinityBossDataDB.timer.timelineMode
    if type(tdb.byEncounter) ~= "table" then tdb.byEncounter = {} end
    if type(tdb.default) ~= "string" or tdb.default == "" then tdb.default = "auto" end
    return tdb
end

function _G.InfinityBossData.RebuildTimelineBosses()
    RebuildTimelineBosses()
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, addonName)
        local loadedAddon = tostring(addonName or ""):lower()
        if loadedAddon == "infinitytools" or loadedAddon == "reversionraidtools" then
            InitInfinityBossDataDB()
            CompactAllEventOverrides()
            RebuildTimelineBosses()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

RebuildTimelineBosses()
