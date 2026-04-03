---@diagnostic disable: undefined-global

InfinityBoss.Voice = InfinityBoss.Voice or {}
InfinityBoss.Voice.Engine = InfinityBoss.Voice.Engine or {}
local Engine = InfinityBoss.Voice.Engine

local _lastPlayTime = {}
local PLAY_THROTTLE = 0.15
local _labelPackCache = {}
local _registeredEventSet = {}
local _registeredEventMeta = {}
local _registeredEventCount = 0
local _lastRegistrationSnapshot = nil
local _lastRegistrationError = nil
local _lastApplyScope = nil

local function EnsureDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    InfinityBossDB.voice.global = InfinityBossDB.voice.global or {}
    local g = InfinityBossDB.voice.global
    if g.enabled == nil then g.enabled = false end
    g.selectedVoicePack = g.selectedVoicePack or "Infinity (Default)"
    if g.fallbackLabel == nil or g.fallbackLabel == "" or g.fallbackLabel == "Prepare Special" then
        g.fallbackLabel = "Special Mechanic"
    end
    g.channel = g.channel or "Master"
    g.volume = g.volume or 1.0
    if g.enabledInRaid    == nil then g.enabledInRaid    = true end
    if g.enabledInDungeon == nil then g.enabledInDungeon = true end
    local CS = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ColorSchemes
    if CS and CS.EnsureDB then CS.EnsureDB() end

    local events
    if _G.InfinityBossData and _G.InfinityBossData.GetEventConfigRoot then
        events = _G.InfinityBossData.GetEventConfigRoot()
    else
        InfinityBossDataDB = InfinityBossDataDB or {}
        InfinityBossDataDB.events = InfinityBossDataDB.events or {}
        events = InfinityBossDataDB.events
    end

    return {
        global = InfinityBossDB.voice.global,
        events = events,
    }
end

local function TryPublishRuntimeSelection()
    local bossCfg = InfinityBoss and InfinityBoss.BossConfig
    if bossCfg and type(bossCfg.PublishRuntimeSelection) == "function" then
        pcall(bossCfg.PublishRuntimeSelection, bossCfg)
    end
end

local function ResolveRuntimeEventConfig(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end

    local bossCfg = InfinityBoss and InfinityBoss.BossConfig
    if bossCfg and type(bossCfg.GetResolvedEventConfig) == "function" then
        local ok, cfg = pcall(bossCfg.GetResolvedEventConfig, bossCfg, eid)
        if ok and type(cfg) == "table" then
            return cfg
        end
    end

    local events
    if _G.InfinityBossData and _G.InfinityBossData.GetEventConfigRoot then
        events = _G.InfinityBossData.GetEventConfigRoot()
    else
        InfinityBossDataDB = InfinityBossDataDB or {}
        InfinityBossDataDB.events = InfinityBossDataDB.events or {}
        events = InfinityBossDataDB.events
    end
    if type(events) ~= "table" then
        return nil
    end
    return events[eid]
end

local function ResolveEventColor(colorCfg)
    if type(colorCfg) ~= "table" or colorCfg.enabled == false then
        return nil
    end
    local CS = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ColorSchemes
    if CS and CS.ResolveEventColor then
        local r, g, b = CS.ResolveEventColor(colorCfg)
        if r ~= nil and g ~= nil and b ~= nil then
            return r, g, b
        end
    end
    if colorCfg.r ~= nil and colorCfg.g ~= nil and colorCfg.b ~= nil then
        return tonumber(colorCfg.r), tonumber(colorCfg.g), tonumber(colorCfg.b)
    end
    return nil
end

local function NormalizeEventID(key, cfg)
    if type(key) == "number" then
        return key
    end
    if type(key) == "string" then
        return tonumber(key)
    end
    if type(cfg) == "table" then
        return tonumber(cfg.eventID)
    end
    return nil
end

local function WipeTable(t)
    if type(t) ~= "table" then return end
    if wipe then
        wipe(t)
        return
    end
    for k in pairs(t) do
        t[k] = nil
    end
end

local TRIGGER_BIT = {
    [0] = 1,
    [1] = 2,
    [2] = 4,
}

local function HasTriggerBit(mask, trigger)
    local bitValue = TRIGGER_BIT[tonumber(trigger) or -1]
    if not bitValue then
        return false
    end
    local n = tonumber(mask) or 0
    return (n % (bitValue * 2)) >= bitValue
end

local function AddTriggerBit(mask, trigger)
    local bitValue = TRIGGER_BIT[tonumber(trigger) or -1]
    if not bitValue then
        return tonumber(mask) or 0
    end
    local n = tonumber(mask) or 0
    if HasTriggerBit(n, trigger) then
        return n
    end
    return n + bitValue
end

local function BuildTriggerList(mask)
    local out = {}
    for trigger = 0, 2 do
        if HasTriggerBit(mask, trigger) then
            out[#out + 1] = trigger
        end
    end
    return out
end

local function BuildTriggerText(mask)
    local list = BuildTriggerList(mask)
    if #list == 0 then
        return "-"
    end
    local labels = {}
    for i = 1, #list do
        labels[i] = tostring(list[i])
    end
    return table.concat(labels, ",")
end

local function BuildEventBossIndex()
    local out = {}
    local data = _G.InfinityBoss_ENCOUNTER_DATA
    if type(data) ~= "table" then
        return out
    end
    local maps = data.maps
    if type(maps) ~= "table" then
        maps = data
    end

    for mapID, mapRow in pairs(maps) do
        if type(mapRow) == "table" and type(mapRow.bosses) == "table" then
            local dungeonID = tonumber(mapRow.instanceID) or tonumber(mapRow.instanceId) or tonumber(mapID)
            local gameMapID = tonumber(mapRow.mapID) or tonumber(mapID)
            local mapName = tostring(mapRow.mapName or mapRow.name or ("Unknown Dungeon " .. tostring(mapID)))
            local instanceType = tonumber(mapRow.instanceType)
            local categoryText = tostring(mapRow.category or "")
            local isRaid = (instanceType == 2) or (categoryText:find("Raid") ~= nil)
            for bossID, bossRow in pairs(mapRow.bosses) do
                if type(bossRow) == "table" and type(bossRow.events) == "table" then
                    local encounterID = tonumber(bossRow.encounterID) or tonumber(bossID) or bossID
                    local bossName = tostring(bossRow.bossName or bossRow.name or ("Unknown Boss " .. tostring(encounterID)))
                    for eventID, eventRow in pairs(bossRow.events) do
                        local eid = tonumber(type(eventRow) == "table" and eventRow.eventID or eventID)
                        if eid then
                            local list = out[eid]
                            if not list then
                                list = {}
                                out[eid] = list
                            end
                            local exists = false
                            for i = 1, #list do
                                if tostring(list[i].encounterID) == tostring(encounterID) then
                                    exists = true
                                    break
                                end
                            end
                            if not exists then
                                list[#list + 1] = {
                                    encounterID = encounterID,
                                    bossName = bossName,
                                    instanceID = dungeonID,
                                    mapID = gameMapID,
                                    mapName = mapName,
                                    isRaid = (isRaid == true),
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return out
end

local function GetMapNameByID(mapID)
    local id = tonumber(mapID)
    if not id or id <= 0 then
        return ""
    end
    local data = _G.InfinityBoss_ENCOUNTER_DATA
    if type(data) == "table" then
        local maps = data.maps
        if type(maps) ~= "table" then
            maps = data
        end
        local row = maps and maps[id]
        if type(row) ~= "table" and type(maps) == "table" then
            for _, item in pairs(maps) do
                if type(item) == "table" then
                    local iid = tonumber(item.instanceID) or tonumber(item.instanceId)
                    if iid and iid == id then
                        row = item
                        break
                    end
                end
            end
        end
        if type(row) == "table" then
            local name = tostring(row.mapName or row.name or "")
            if name ~= "" then
                return name
            end
        end
    end
    return "Unknown Dungeon " .. tostring(id)
end

local function BuildRegistrationSnapshot(eventMeta, eventCount, opts)
    opts = type(opts) == "table" and opts or {}
    local includeRaid = (opts.includeRaid ~= false)
    local scope = type(opts.scope) == "table" and opts.scope or nil
    local bossMap = BuildEventBossIndex()
    local bossAgg = {}
    local orphan = 0
    local filteredOutByRaid = 0
    local includedEventCount = 0
    local trigger0Events = 0
    local trigger1Events = 0
    local trigger2Events = 0

    for eventID, meta in pairs(eventMeta or {}) do
        local refs = type(meta) == "table" and meta.refs or nil
        if type(refs) ~= "table" or #refs == 0 then
            refs = bossMap[tonumber(eventID)]
        end
        local triggerMask = tonumber(type(meta) == "table" and meta.triggerMask) or 0
        local matched = false
        if type(refs) == "table" and #refs > 0 then
            for i = 1, #refs do
                local ref = refs[i]
                if includeRaid or not (ref and ref.isRaid == true) then
                    matched = true
                    local key = tostring(ref.encounterID)
                    local row = bossAgg[key]
                    if not row then
                        row = {
                            encounterID = ref.encounterID,
                            bossName = ref.bossName,
                            instanceID = ref.instanceID,
                            mapID = ref.mapID,
                            mapName = ref.mapName,
                            isRaid = (ref.isRaid == true),
                            count = 0,
                            _eventSet = {},
                            _eventMeta = {},
                        }
                        bossAgg[key] = row
                    end
                    if not row._eventSet[eventID] then
                        row._eventSet[eventID] = true
                        row._eventMeta[eventID] = meta
                        row.count = row.count + 1
                    end
                end
            end
        end

        if matched then
            includedEventCount = includedEventCount + 1
            if HasTriggerBit(triggerMask, 0) then trigger0Events = trigger0Events + 1 end
            if HasTriggerBit(triggerMask, 1) then trigger1Events = trigger1Events + 1 end
            if HasTriggerBit(triggerMask, 2) then trigger2Events = trigger2Events + 1 end
        elseif type(refs) == "table" and #refs > 0 and not includeRaid then
            filteredOutByRaid = filteredOutByRaid + 1
        else
            orphan = orphan + 1
        end
    end

    local rows = {}
    for _, row in pairs(bossAgg) do
        local eventIDs = {}
        for eid in pairs(row._eventSet or {}) do
            eventIDs[#eventIDs + 1] = tonumber(eid) or eid
        end
        table.sort(eventIDs, function(a, b)
            local na = tonumber(a)
            local nb = tonumber(b)
            if na and nb then
                return na < nb
            end
            return tostring(a) < tostring(b)
        end)
        local eventDetails = {}
        for i = 1, #eventIDs do
            local eid = eventIDs[i]
            local meta = row._eventMeta and row._eventMeta[eid] or nil
            local triggerMask = tonumber(type(meta) == "table" and meta.triggerMask) or 0
            eventDetails[#eventDetails + 1] = {
                eventID = eid,
                triggerMask = triggerMask,
                triggerText = BuildTriggerText(triggerMask),
                triggers = BuildTriggerList(triggerMask),
                policy = type(meta) == "table" and tostring(meta.policy or "") or "",
                mode = type(meta) == "table" and tostring(meta.mode or "") or "",
            }
        end
        row.eventIDs = eventIDs
        row._eventSet = nil
        row._eventMeta = nil
        row.eventDetails = eventDetails
        rows[#rows + 1] = row
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        return tostring(a.bossName or "") < tostring(b.bossName or "")
    end)

    local stamp = date and date("%Y-%m-%d %H:%M:%S") or ""
    return {
        eventCount = includedEventCount,
        rawEventCount = tonumber(eventCount) or 0,
        bossCount = #rows,
        trigger0Events = trigger0Events,
        trigger1Events = trigger1Events,
        trigger2Events = trigger2Events,
        orphanEventCount = orphan,
        filteredOutByRaid = filteredOutByRaid,
        includeRaid = includeRaid,
        scopeInstanceID = scope and tonumber(scope.instanceID) or nil,
        scopeMapID = scope and tonumber(scope.mapID) or nil,
        scopeMapName = scope and GetMapNameByID(scope.instanceID) or "",
        scopeEncounterID = scope and tonumber(scope.encounterID) or nil,
        scopeInstanceType = scope and tostring(scope.instanceType or "") or "",
        scopeReason = scope and tostring(scope.reason or "") or "",
        updatedAt = stamp,
        rows = rows,
        error = _lastRegistrationError,
    }
end

local function BuildEventLookupKeys(timer)
    if not timer then return {} end
    local eid = tonumber(timer.eventID)
    if not eid then
        eid = tonumber(timer.timelineEventID)
    end
    return eid and { eid } or {}
end

local function IsContextEnabled(globalCfg)
    local _, instanceType = GetInstanceInfo()
    if instanceType == "raid" then
        return globalCfg.enabledInRaid ~= false
    end
    if instanceType == "party" then
        return globalCfg.enabledInDungeon ~= false
    end
    return true
end

local function IsBossSceneEnabled(scene)
    local bossCfg = InfinityBoss and InfinityBoss.BossConfig
    if bossCfg and type(bossCfg.IsSceneEnabled) == "function" then
        local ok, enabled = pcall(bossCfg.IsSceneEnabled, bossCfg, scene)
        if ok then
            return enabled ~= false
        end
    end

    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    local g = InfinityBossDB.ui.general
    if g.bossAlertsEnabledRaid == nil then g.bossAlertsEnabledRaid = true end
    if g.bossAlertsEnabledMplus == nil then g.bossAlertsEnabledMplus = true end
    if tostring(scene or "") == "raid" then
        return g.bossAlertsEnabledRaid ~= false
    end
    return g.bossAlertsEnabledMplus ~= false
end

local function ReadCVarValue(name)
    local key = tostring(name or "")
    if key == "" then
        return nil
    end
    local ok, value
    if C_CVar and C_CVar.GetCVar then
        ok, value = pcall(C_CVar.GetCVar, key)
    end
    if (not ok or value == nil) and type(GetCVar) == "function" then
        ok, value = pcall(GetCVar, key)
    end
    if not ok or value == nil then
        return nil
    end
    local text = tostring(value or "")
    if text == "" then
        return nil
    end
    return text
end

local function WriteCVarValue(name, value)
    local key = tostring(name or "")
    local text = tostring(value or "")
    if key == "" or text == "" then
        return false
    end
    local ok = false
    if C_CVar and C_CVar.SetCVar then
        ok = pcall(C_CVar.SetCVar, key, text)
        if ok then
            return true
        end
    end
    if type(SetCVar) == "function" then
        ok = pcall(SetCVar, key, text)
        if ok then
            return true
        end
    end
    return false
end

local function EnsureEncounterWarningsEnabled()
    local value = ReadCVarValue("encounterWarningsEnabled")
    if value == "0" then
        WriteCVarValue("encounterWarningsEnabled", "1")
        value = ReadCVarValue("encounterWarningsEnabled")
    elseif value == nil then
        WriteCVarValue("encounterWarningsEnabled", "1")
        value = "1"
    end
    return value ~= "0"
end

local function BuildLSMLabel(packName, label)
    packName = tostring(packName or "")
    label    = tostring(label    or "")
    if packName == "" or label == "" then return nil end
    return "[" .. packName .. "]" .. label
end

local function NormalizeLegacyVoiceLabel(label)
    local text = tostring(label or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return ""
    end
    if text:lower() == "none" then
        return ""
    end
    return text
end

local function ResolvePackTriggerLabel(triggerCfg, triggerIndex)
    local label = NormalizeLegacyVoiceLabel(triggerCfg and triggerCfg.label)
    if label ~= "" then
        return label
    end
    if tonumber(triggerIndex) == 2 then
        return "54321"
    end
    return nil
end

local function ResolveEventConfig(db, timer)
    local events = db and db.events
    for _, key in ipairs(BuildEventLookupKeys(timer)) do
        local cfg = ResolveRuntimeEventConfig(key)
        if cfg == nil and type(events) == "table" then
            cfg = events[key]
        end
        if type(cfg) == "table" then
            return cfg, key
        end
    end
    return nil, nil
end

local function BuildPackCandidates(globalCfg)
    local list = {}
    local function Add(name)
        if type(name) ~= "string" or name == "" then return end
        for _, v in ipairs(list) do if v == name then return end end
        list[#list + 1] = name
    end
    Add(globalCfg and globalCfg.selectedVoicePack)
    Add("Infinity(Default)")
    return list
end

local function FindPackForLabel(lsm, label)
    if _labelPackCache[label] ~= nil then
        return _labelPackCache[label] or nil
    end
    local tbl = lsm and lsm:HashTable("sound")
    if type(tbl) ~= "table" then
        _labelPackCache[label] = false
        return nil
    end
    for key in pairs(tbl) do
        local pack, tail = key:match("^%[([^%]]+)%](.+)$")
        if pack and tail == label then
            _labelPackCache[label] = pack
            return pack
        end
    end
    _labelPackCache[label] = false
    return nil
end

local function ResolveLabelSoundInfo(globalCfg, eventCfg, label)
    label = tostring(label or "")
    if label == "" then return nil end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return nil end

    local soundPath = nil

    local customLSM = eventCfg and eventCfg.customLSM
    if type(customLSM) == "string" and customLSM ~= "" then
        soundPath = LSM:Fetch("sound", customLSM, true)
    end

    if not soundPath then
        for _, pack in ipairs(BuildPackCandidates(globalCfg)) do
            soundPath = LSM:Fetch("sound", BuildLSMLabel(pack, label), true)
            if soundPath then break end
        end
    end

    if not soundPath then
        local pack = FindPackForLabel(LSM, label)
        if pack then
            soundPath = LSM:Fetch("sound", BuildLSMLabel(pack, label), true)
        end
    end

    if not soundPath then return nil end

    return {
        file    = soundPath,
        channel = (eventCfg and eventCfg.channel) or globalCfg.channel or "Master",
        volume  = (eventCfg and eventCfg.volume)  or globalCfg.volume  or 1.0,
    }
end

local function TryPlaySoundInfo(soundInfo, throttleKey)
    if type(soundInfo) ~= "table" or type(soundInfo.file) ~= "string" or soundInfo.file == "" then
        return false, "invalid sound info"
    end
    local now = GetTime and GetTime() or 0
    if _lastPlayTime[throttleKey] and (now - _lastPlayTime[throttleKey]) < PLAY_THROTTLE then
        return false, "throttled"
    end
    local ok = PlaySoundFile and PlaySoundFile(soundInfo.file, soundInfo.channel or "Master")
    if ok then
        _lastPlayTime[throttleKey] = now
        return true
    end
    return false, "PlaySoundFile failed"
end

local function ResolveTriggerSound(globalCfg, triggerCfg, triggerIndex)
    if type(triggerCfg) ~= "table" then return nil end
    if triggerCfg.enabled == false    then return nil end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local sourceType = tostring(triggerCfg.sourceType or ""):lower()
    local file

    local function FetchSoundByKey(key)
        if not (LSM and type(key) == "string" and key ~= "") then
            return nil
        end
        local path = LSM:Fetch("sound", key, true)
        if path and path ~= "" then
            return path
        end
        local tbl = LSM:HashTable("sound")
        local raw = type(tbl) == "table" and tbl[key] or nil
        if type(raw) == "string" and raw ~= "" then
            return raw
        end
        return nil
    end

    if sourceType == "file" and triggerCfg.customPath and triggerCfg.customPath ~= "" then
        file = triggerCfg.customPath
    elseif sourceType == "lsm" and triggerCfg.customLSM and triggerCfg.customLSM ~= "" and LSM then
        file = FetchSoundByKey(triggerCfg.customLSM)
    else
        local label = ResolvePackTriggerLabel(triggerCfg, triggerIndex)
        local pack  = globalCfg.selectedVoicePack or "Infinity(Default)"
        if label and label ~= "" and LSM then
            local lsmKey = BuildLSMLabel(pack, label)
            file = FetchSoundByKey(lsmKey)
            if not file and pack ~= "Infinity(Default)" then
                file = FetchSoundByKey(BuildLSMLabel("Infinity(Default)", label))
            end
        end
    end

    if not file or file == "" then return nil end

    return {
        file    = file,
        channel = globalCfg.channel or "Master",
        volume  = tonumber(globalCfg.volume) or 1.0,
    }
end

local function NormalizeStandaloneTriggerConfig(triggerCfg)
    if type(triggerCfg) ~= "table" then
        return nil
    end

    local sourceType = tostring(triggerCfg.sourceType or "pack"):lower()
    if sourceType ~= "lsm" and sourceType ~= "file" then
        sourceType = "pack"
    end

    return {
        enabled = (triggerCfg.enabled ~= false),
        sourceType = sourceType,
        label = tostring(triggerCfg.label or ""),
        customLSM = tostring(triggerCfg.customLSM or ""),
        customPath = tostring(triggerCfg.customPath or ""),
    }
end

local function HasMeaningfulTriggerSource(triggerCfg)
    if type(triggerCfg) ~= "table" then
        return false
    end
    local sourceType = tostring(triggerCfg.sourceType or ""):lower()
    if sourceType == "file" then
        return type(triggerCfg.customPath) == "string" and triggerCfg.customPath ~= ""
    end
    if sourceType == "lsm" then
        return type(triggerCfg.customLSM) == "string" and triggerCfg.customLSM ~= ""
    end
    return type(triggerCfg.label) == "string" and triggerCfg.label ~= ""
end


function Engine:InvalidateLabelCache()
    _labelPackCache = {}
end

function Engine:ResolveStandaloneSound(triggerCfg, opts)
    opts = type(opts) == "table" and opts or {}
    local db = EnsureDB()
    local g = db.global
    if opts.ignoreState ~= true and g.enabled == false then
        return nil, "voice disabled"
    end
    if opts.ignoreState ~= true and not IsContextEnabled(g) then
        return nil, "context disabled"
    end

    local normalized = NormalizeStandaloneTriggerConfig(triggerCfg)
    if not normalized then
        return nil, "invalid trigger cfg"
    end

    local soundInfo = ResolveTriggerSound(g, normalized, opts.triggerIndex)
    if not soundInfo then
        return nil, "sound not found"
    end
    return soundInfo
end

function Engine:TryPlayStandaloneSound(triggerCfg, throttleKey, opts)
    local soundInfo, err = self:ResolveStandaloneSound(triggerCfg, opts)
    if not soundInfo then
        return false, err
    end
    return TryPlaySoundInfo(soundInfo, tostring(throttleKey or "standalone"))
end

function Engine:TryPlayLabel(label, timer)
    local db = EnsureDB()
    local g  = db.global
    if g.enabled == false    then return false, "voice disabled"   end
    if not IsContextEnabled(g) then return false, "context disabled" end

    local eventCfg = ResolveEventConfig(db, timer)
    if eventCfg and eventCfg.enabled == false then
        return false, "event muted"
    end

    local info = ResolveLabelSoundInfo(g, eventCfg, label)
    if not info and g.fallbackLabel then
        info = ResolveLabelSoundInfo(g, nil, g.fallbackLabel)
    end
    if not info then return false, "sound not found" end
    return TryPlaySoundInfo(info, "label:" .. tostring(label))
end

function Engine:TryPlayForTimer(timer, trigger)
    if not timer then return false, "nil timer" end
    local db = EnsureDB()
    local g  = db.global
    if g.enabled == false    then return false, "voice disabled"   end
    if not IsContextEnabled(g) then return false, "context disabled" end

    local eventCfg, eventKey = ResolveEventConfig(db, timer)
    if eventCfg and eventCfg.enabled == false then
        return false, "event muted"
    end

    trigger = tonumber(trigger) or 2
    if eventCfg and type(eventCfg.triggers) == "table" then
        local triggerCfg  = eventCfg.triggers[trigger]
        if type(triggerCfg) == "table" and triggerCfg.enabled == false then
            if HasMeaningfulTriggerSource(triggerCfg) then
                return false, "trigger muted"
            end
            triggerCfg = nil
        end
        local triggerSound = ResolveTriggerSound(g, triggerCfg, trigger)
        if triggerSound then
            local tk = "event:" .. tostring(eventKey or "unknown") .. ":tr:" .. tostring(trigger)
            return TryPlaySoundInfo(triggerSound, tk)
        end
    end

    local label = timer.voiceLabel

    if not label and not (timer.timelineManaged or timer.source == "blizzard") then
        label = timer.displayName
    end
    if not label then
        local sid = tonumber(timer.spellID)
        local tid = tonumber(timer.timelineEventID)
        if sid then
            label = "Spell " .. tostring(sid)
        elseif tid then
            label = "Timeline Event " .. tostring(tid)
        end
    end
    if not label then label = g.fallbackLabel end
    if not label then return false, "no fallback label" end

    local soundInfo = ResolveLabelSoundInfo(g, eventCfg, label)
    if not soundInfo and g.fallbackLabel then
        soundInfo = ResolveLabelSoundInfo(g, nil, g.fallbackLabel)
        label = g.fallbackLabel
    end
    if not soundInfo then return false, "sound not found" end

    local tk = "timer:" .. tostring(eventKey or "noevent") .. ":" .. tostring(label)
    return TryPlaySoundInfo(soundInfo, tk)
end


local function ResolveApplyScope(opts)
    opts = type(opts) == "table" and opts or {}
    local state = InfinityTools and InfinityTools.State or nil

    local inInstance = (opts.inInstance ~= nil) and (opts.inInstance == true)
    if opts.inInstance == nil then
        inInstance = (state and state.InInstance == true) or false
    end
    if not inInstance then
        return nil, "not in instance"
    end

    local instanceType = tostring(opts.instanceType or (state and state.InstanceType) or ""):lower()
    if instanceType == "" then
        local ok, ii, it = pcall(IsInInstance)
        if ok and ii then
            instanceType = tostring(it or ""):lower()
        end
    end
    if instanceType ~= "party" and instanceType ~= "raid" then
        return nil, "unsupported instanceType: " .. tostring(instanceType)
    end

    local instanceID = tonumber(opts.instanceID or (state and state.InstanceID)) or 0
    if instanceID <= 0 then
        local _, _, _, _, _, _, _, runtimeInstanceID = GetInstanceInfo()
        instanceID = tonumber(runtimeInstanceID) or 0
    end
    if instanceID <= 0 then
        return nil, "instanceID unavailable"
    end

    local encounterID = tonumber(opts.encounterID)
    if (not encounterID or encounterID <= 0) and opts.useEncounterState == true then
        encounterID = tonumber(state and state.EncounterID) or 0
    end
    if encounterID and encounterID <= 0 then
        encounterID = nil
    end

    return {
        instanceID = instanceID,
        mapID = tonumber(opts.mapID or (state and state.MapID)) or nil,
        encounterID = encounterID,
        instanceType = instanceType,
        reason = tostring(opts.reason or ""),
    }, nil
end

local function MatchRefsForScope(eventID, scope, bossMap)
    local refs = bossMap and bossMap[tonumber(eventID)] or nil
    if type(refs) ~= "table" or #refs == 0 then
        return {}
    end
    if type(scope) ~= "table" then
        return refs
    end
    local scopeInstanceID = tonumber(scope.instanceID)
    local scopeEncounterID = tonumber(scope.encounterID)
    local out = {}
    for i = 1, #refs do
        local ref = refs[i]
        local refInstanceID = tonumber(ref and ref.instanceID)
        local refEncounterID = tonumber(ref and ref.encounterID)
        local instanceOK = (scopeInstanceID == nil) or (scopeInstanceID == refInstanceID)
        local encounterOK = (scopeEncounterID == nil) or (scopeEncounterID == refEncounterID)
        if instanceOK and encounterOK then
            out[#out + 1] = ref
        end
    end
    return out
end

local function ResolveEncounterMode(encounterID, modeCache)
    local id = tonumber(encounterID)
    if not id then
        return "blizzard"
    end
    if type(modeCache) == "table" and modeCache[id] then
        return modeCache[id]
    end

    local mode = nil
    local sched = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
    if sched and type(sched.GetResolvedMode) == "function" then
        local ok, resolved = pcall(sched.GetResolvedMode, sched, id)
        if ok then
            local m = tostring(resolved or ""):lower()
            if m == "fixed" or m == "blizzard" then
                mode = m
            end
        end
    end

    if not mode then
        local fixed = _G.InfinityBoss_FIXED_TIMELINE_ENCOUNTERS
        if type(fixed) == "table" and fixed[id] == true then
            mode = "fixed"
        else
            mode = "blizzard"
        end
    end

    if type(modeCache) == "table" then
        modeCache[id] = mode
    end
    return mode
end

local function IsCentralTriggerChecked(cfg)
    local triggers = cfg and cfg.triggers
    local trigger0 = type(triggers) == "table" and triggers[0] or nil
    return type(trigger0) == "table" and trigger0.enabled == true
end

local function EvaluateRegistrationPolicy(eventID, cfg, refs, modeCache)
    local allowedRefs = {}
    local allowMask = 0
    local sawFixed = false
    local sawNonFixed = false
    local centralChecked = IsCentralTriggerChecked(cfg)

    for i = 1, #refs do
        local ref = refs[i]
        local mode = ResolveEncounterMode(ref and ref.encounterID, modeCache)
        if mode == "fixed" then
            sawFixed = true
            if centralChecked then
                allowMask = AddTriggerBit(allowMask, 0)
                local copy = {}
                for k, v in pairs(ref) do copy[k] = v end
                copy.mode = "fixed"
                allowedRefs[#allowedRefs + 1] = copy
            end
        else
            sawNonFixed = true
            allowMask = AddTriggerBit(AddTriggerBit(AddTriggerBit(allowMask, 0), 1), 2)
            local copy = {}
            for k, v in pairs(ref) do copy[k] = v end
            copy.mode = "blizzard"
            allowedRefs[#allowedRefs + 1] = copy
        end
    end

    if #allowedRefs == 0 or allowMask == 0 then
        return nil
    end

    local mode = "blizzard"
    local policy = "non-fixed"
    if sawFixed and not sawNonFixed then
        mode = "fixed"
        policy = "fixed-central-only"
    elseif sawFixed and sawNonFixed then
        mode = "mixed"
        policy = "mixed"
    end

    return {
        allowMask = allowMask,
        mode = mode,
        policy = policy,
        refs = allowedRefs,
    }
end

local function CollectEventEntries(db, scope)
    local entries = {}
    local visited = {}
    local bossMap = BuildEventBossIndex()
    local globalCfg = db.global or {}
    local modeCache = {}
    for key, cfg in pairs(db.events or {}) do
        local eventID = NormalizeEventID(key, cfg)
        if eventID and type(cfg) == "table" and not visited[eventID] then
            visited[eventID] = true
            local refs = MatchRefsForScope(eventID, scope, bossMap)
            if #refs > 0 then
                local policy = EvaluateRegistrationPolicy(eventID, cfg, refs, modeCache)
                if policy then
                    local triggerSounds = {}
                    local triggerMask = 0
                    local triggers = cfg.triggers
                    for trigger = 0, 2 do
                        if HasTriggerBit(policy.allowMask, trigger) then
                            local triggerCfg = type(triggers) == "table" and triggers[trigger] or nil
                            local soundInfo = ResolveTriggerSound(globalCfg, triggerCfg, trigger)
                            if soundInfo then
                                triggerMask = AddTriggerBit(triggerMask, trigger)
                                triggerSounds[trigger] = soundInfo
                            end
                        end
                    end

                    local hasColor = (cfg.enabled ~= false) and (ResolveEventColor(cfg.color) ~= nil)
                    if triggerMask ~= 0 or hasColor then
                        entries[#entries + 1] = {
                            eventID = eventID,
                            cfg = cfg,
                            globalCfg = globalCfg,
                            triggerMask = triggerMask,
                            triggerSounds = triggerSounds,
                            hasColor = hasColor,
                            mode = policy.mode,
                            policy = policy.policy,
                            refs = policy.refs,
                        }
                    end
                end
            end
        end
    end
    return entries
end

local function ApplyOneEntry(entry)
    if not C_EncounterEvents then return end
    local eventID   = entry.eventID
    local cfg       = entry.cfg
    local globalCfg = entry.globalCfg

    local eventEnabled = (cfg.enabled ~= false)

    if C_EncounterEvents.SetEventColor then
        if not eventEnabled then
            pcall(C_EncounterEvents.SetEventColor, eventID, nil)
        else
            local r, g, b = ResolveEventColor(cfg.color)
            if r ~= nil and g ~= nil and b ~= nil then
                local color = CreateColor and CreateColor(r, g, b) or { r=r, g=g, b=b }
                pcall(C_EncounterEvents.SetEventColor, eventID, color)
            else
                pcall(C_EncounterEvents.SetEventColor, eventID, nil)
            end
        end
    end

    if C_EncounterEvents.SetEventSound then
        for trigger = 0, 2 do
            local soundInfo = nil
            if eventEnabled then
                soundInfo = type(entry.triggerSounds) == "table" and entry.triggerSounds[trigger] or nil
            end
            pcall(C_EncounterEvents.SetEventSound, eventID, trigger, soundInfo)
        end
    end
end

local BATCH_SIZE     = 500
local BATCH_INTERVAL = 0.05
local _applyScheduleToken = 0

local function RefreshTimelineVisuals()
    if InfinityBoss and InfinityBoss.UI then
        if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.RefreshVisuals then
            pcall(function()
                InfinityBoss.UI.TimerBar:RefreshVisuals()
            end)
        end
        if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.RefreshVisuals then
            pcall(function()
                InfinityBoss.UI.BunBar:RefreshVisuals()
            end)
        end
    end
end

local function ApplyOneColorEntry(entry)
    if not (C_EncounterEvents and C_EncounterEvents.SetEventColor) then
        return false
    end
    local eventID = entry.eventID
    local cfg = entry.cfg
    local eventEnabled = (cfg and cfg.enabled ~= false)

    if not eventEnabled then
        pcall(C_EncounterEvents.SetEventColor, eventID, nil)
        return true
    end

    local r, g, b = ResolveEventColor(cfg and cfg.color or nil)
    if r ~= nil and g ~= nil and b ~= nil then
        local color = CreateColor and CreateColor(r, g, b) or { r = r, g = g, b = b }
        pcall(C_EncounterEvents.SetEventColor, eventID, color)
    else
        pcall(C_EncounterEvents.SetEventColor, eventID, nil)
    end
    return true
end

local function ApplyInBatches(entries)
    if not C_EncounterEvents then return end
    local total = #entries
    local idx   = 1

    local function DoNextBatch()
        if idx > total then
            RefreshTimelineVisuals()
            return
        end
        local limit = math.min(idx + BATCH_SIZE - 1, total)
        for i = idx, limit do
            ApplyOneEntry(entries[i])
        end
        RefreshTimelineVisuals()
        idx = limit + 1
        if idx <= total then
            C_Timer.After(BATCH_INTERVAL, DoNextBatch)
        end
    end

    DoNextBatch()
end

local ClearOneEntryByEventID

function Engine:ApplyEventOverridesToAPI(opts)
    TryPublishRuntimeSelection()
    local db = EnsureDB()
    if not C_EncounterEvents then
        _lastRegistrationError = "C_EncounterEvents unavailable"
        return false, "C_EncounterEvents unavailable"
    end
    if C_EncounterEvents.SetEventSound and not EnsureEncounterWarningsEnabled() then
        _lastRegistrationError = "encounter warnings disabled"
        return false, _lastRegistrationError
    end

    local scope, scopeErr = ResolveApplyScope(opts)
    if not scope then
        _lastRegistrationError = scopeErr or "scope invalid"
        return false, _lastRegistrationError
    end

    local scene = nil
    if scope.instanceType == "raid" then
        scene = "raid"
    elseif scope.instanceType == "party" then
        scene = "mplus"
    end
    if scene and not IsBossSceneEnabled(scene) then
        Engine:ClearEventOverridesInMemory("boss scene disabled")
        return false, "boss scene disabled"
    end

    local entries = CollectEventEntries(db, scope)
    local prevSet = {}
    for eid in pairs(_registeredEventSet) do
        prevSet[eid] = true
    end

    WipeTable(_registeredEventSet)
    WipeTable(_registeredEventMeta)
    _registeredEventCount = 0
    for i = 1, #entries do
        local entry = entries[i]
        local eid = entry and tonumber(entry.eventID)
        if eid and not _registeredEventSet[eid] then
            _registeredEventSet[eid] = true
            _registeredEventMeta[eid] = {
                eventID = eid,
                triggerMask = tonumber(entry.triggerMask) or 0,
                mode = tostring(entry.mode or ""),
                policy = tostring(entry.policy or ""),
                refs = entry.refs,
            }
            _registeredEventCount = _registeredEventCount + 1
        end
    end

    for eid in pairs(prevSet) do
        if not _registeredEventSet[eid] then
            ClearOneEntryByEventID(eid)
        end
    end

    _lastApplyScope = {
        instanceID = scope.instanceID,
        mapID = scope.mapID,
        encounterID = scope.encounterID,
        instanceType = scope.instanceType,
        reason = scope.reason,
    }
    _lastRegistrationError = nil
    _lastRegistrationSnapshot = BuildRegistrationSnapshot(_registeredEventMeta, _registeredEventCount, {
        scope = _lastApplyScope,
    })
    ApplyInBatches(entries)
    return true
end

ClearOneEntryByEventID = function(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return
    end
    if C_EncounterEvents and C_EncounterEvents.SetEventSound then
        for trigger = 0, 2 do
            pcall(C_EncounterEvents.SetEventSound, eid, trigger, nil)
        end
    end
    if C_EncounterEvents and C_EncounterEvents.SetEventColor then
        pcall(C_EncounterEvents.SetEventColor, eid, nil)
    end
end

function Engine:ClearEventOverridesInMemory(reason)
    reason = tostring(reason or "")
    for eventID in pairs(_registeredEventSet) do
        ClearOneEntryByEventID(eventID)
    end
    WipeTable(_registeredEventSet)
    WipeTable(_registeredEventMeta)
    _registeredEventCount = 0
    _lastApplyScope = nil
    _lastRegistrationError = (reason ~= "" and reason) or "cleared"
    _lastRegistrationSnapshot = BuildRegistrationSnapshot(_registeredEventMeta, _registeredEventCount, {
        scope = nil,
    })
end

function Engine:ApplyEventColorOverridesToAPI(opts)
    local db = EnsureDB()
    if not (C_EncounterEvents and C_EncounterEvents.SetEventColor) then
        return false, "SetEventColor unavailable", 0
    end
    local scope, scopeErr = ResolveApplyScope(opts)
    if not scope then
        return false, scopeErr or "scope invalid", 0
    end
    local entries = CollectEventEntries(db, scope)
    local count = 0
    for i = 1, #entries do
        if ApplyOneColorEntry(entries[i]) then
            count = count + 1
        end
    end
    RefreshTimelineVisuals()
    return true, nil, count
end

function Engine:ScheduleApplyEventOverrides(delays)
    delays = type(delays) == "table" and delays or { 1, 3, 5 }
    _applyScheduleToken = _applyScheduleToken + 1
    local token = _applyScheduleToken
    for _, delay in ipairs(delays) do
        local d = tonumber(delay) or 0
        if d < 0 then d = 0 end
        C_Timer.After(d, function()
            if token ~= _applyScheduleToken then
                return
            end
            local ok, err = Engine:ApplyEventOverridesToAPI({
                reason = "schedule:" .. tostring(d),
            })
            local _, instanceType = GetInstanceInfo()
--             print(string.format(
--                 d,
--                 tostring(instanceType or "unknown"),
--                 tostring(ok),
--                 err and (" err=" .. tostring(err)) or ""
--             ))
        end)
    end
end

function Engine:GetRegistrationSnapshot(opts)
    opts = type(opts) == "table" and opts or {}
    TryPublishRuntimeSelection()
    local includeRaid = (opts.includeRaid ~= false)
    if type(_lastRegistrationSnapshot) == "table" then
        if includeRaid == true and (not _lastRegistrationSnapshot.scopeInstanceID or _lastRegistrationSnapshot.scopeInstanceID > 0) then
            return _lastRegistrationSnapshot
        end
        return BuildRegistrationSnapshot(_registeredEventMeta, _registeredEventCount, {
            includeRaid = false,
            scope = _lastApplyScope,
        })
    end

    local scope, scopeErr = ResolveApplyScope(opts)
    if not scope then
        return {
            eventCount = 0,
            rawEventCount = 0,
            bossCount = 0,
            trigger0Events = 0,
            trigger1Events = 0,
            trigger2Events = 0,
            orphanEventCount = 0,
            filteredOutByRaid = 0,
            includeRaid = includeRaid,
            scopeInstanceID = nil,
            scopeMapID = nil,
            scopeMapName = "",
            scopeEncounterID = nil,
            scopeInstanceType = "",
            scopeReason = tostring(opts.reason or ""),
            updatedAt = date and date("%Y-%m-%d %H:%M:%S") or "",
            rows = {},
            error = scopeErr or "scope invalid",
            isPreview = true,
        }
    end

    local db = EnsureDB()
    local entries = CollectEventEntries(db, scope)
    local previewMeta = {}
    local previewCount = 0
    for i = 1, #entries do
        local entry = entries[i]
        local eid = entry and tonumber(entry.eventID)
        if eid and not previewMeta[eid] then
            previewMeta[eid] = {
                eventID = eid,
                triggerMask = tonumber(entry.triggerMask) or 0,
                mode = tostring(entry.mode or ""),
                policy = tostring(entry.policy or ""),
                refs = entry.refs,
            }
            previewCount = previewCount + 1
        end
    end

    local snap = BuildRegistrationSnapshot(previewMeta, previewCount, {
        includeRaid = includeRaid,
        scope = scope,
    })
    snap.isPreview = true
    return snap
end


if InfinityTools and not Engine._eventsRegistered then
    local function ApplyCurrentInstance(reason, encounterID)
        local opts = {
            reason = tostring(reason or ""),
            encounterID = tonumber(encounterID),
            useEncounterState = (encounterID == nil),
        }
        local ok, err = Engine:ApplyEventOverridesToAPI(opts)
        if not ok and tostring(err) == "not in instance" then
            Engine:ClearEventOverridesInMemory("not in instance")
        end
    end

    InfinityTools:WatchState("InInstance", "InfinityBossVoice.Engine.InInstanceScope", function(newValue)
        if newValue == true then
            C_Timer.After(0.1, function()
                ApplyCurrentInstance("state:InInstance=true", nil)
            end)
        else
            Engine:ClearEventOverridesInMemory("state:InInstance=false")
        end
    end)

    InfinityTools:WatchState("InstanceID", "InfinityBossVoice.Engine.InstanceScope", function(newID, oldID)
        if tonumber(newID) == tonumber(oldID) then
            return
        end
        if InfinityTools.State and InfinityTools.State.InInstance == true then
            C_Timer.After(0.1, function()
                ApplyCurrentInstance("state:InstanceID", nil)
            end)
        end
    end)

    InfinityTools:WatchState("RoleKey", "InfinityBossVoice.Engine.RoleScope", function()
        if InfinityTools.State and InfinityTools.State.InInstance == true then
            C_Timer.After(0.05, function()
                ApplyCurrentInstance("state:RoleKey", nil)
            end)
        end
    end)

    InfinityTools:WatchState("SpecID", "InfinityBossVoice.Engine.SpecScope", function(newID, oldID)
        if tonumber(newID) == tonumber(oldID) then
            return
        end
        if InfinityTools.State and InfinityTools.State.InInstance == true then
            C_Timer.After(0.05, function()
                ApplyCurrentInstance("state:SpecID", nil)
            end)
        end
    end)

    InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", "InfinityBossVoice.Engine.OnPEW", function()
        C_Timer.After(0.2, function()
            ApplyCurrentInstance("event:PLAYER_ENTERING_WORLD", nil)
        end)
    end)

    InfinityTools:RegisterEvent("ENCOUNTER_START", "InfinityBossVoice.Engine.OnEncounterStart", function(_, encounterID)
        C_Timer.After(0, function()
            ApplyCurrentInstance("event:ENCOUNTER_START", encounterID)
        end)
    end)

    InfinityTools:RegisterEvent("ENCOUNTER_END", "InfinityBossVoice.Engine.OnEncounterEnd", function()
        C_Timer.After(0, function()
            ApplyCurrentInstance("event:ENCOUNTER_END", nil)
        end)
    end)

    C_Timer.After(0.5, function()
        ApplyCurrentInstance("init:delayed", nil)
    end)

    Engine._eventsRegistered = true
end
