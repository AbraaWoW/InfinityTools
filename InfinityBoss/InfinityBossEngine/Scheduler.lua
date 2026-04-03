---@diagnostic disable: undefined-global
-- =============================================================
-- InfinityBossEngine/Scheduler.lua
-- =============================================================

InfinityBoss.Timeline.Scheduler           = InfinityBoss.Timeline.Scheduler or {}
local Scheduler                     = InfinityBoss.Timeline.Scheduler

local ONUPDATE_INTERVAL             = 0.05
local MAX_ENCOUNTER_DURATION        = 600
local BUNBAR_LEAD_TIME              = 30
local TIMERBAR_LEAD_TIME            = 30
local DEFAULT_PREALERT_SECS         = 5
local VIRTUAL_HINT_REMAINING_SECS   = 5
local FIXED_DRIVER_TIME             = "time"
local FIXED_DRIVER_AI               = "ai"
local FIXED_AI_MATCH_TOLERANCE      = 0.75
local FIXED_AI_SYNC_WINDOW          = 0.5
local FIXED_TIME_MATCH_TOLERANCE    = 2.0
local FIXED_TIME_OFFSET_EPSILON     = 0.02
local FIXED_TIME_OFFSET_CALIBRATION_ENABLED = false
local TRIGGER_TIME                  = "TIME"
local TRIGGER_AI                    = "AI"
local TRIGGER_BLZ                   = "BLZ"

local STATE_ACTIVE                  = Enum and Enum.EncounterTimelineEventState and
    Enum.EncounterTimelineEventState.Active or
    0
local STATE_PAUSED                  = Enum and Enum.EncounterTimelineEventState and
    Enum.EncounterTimelineEventState.Paused or
    1
local STATE_FINISHED                = Enum and Enum.EncounterTimelineEventState and Enum.EncounterTimelineEventState
    .Finished or 2
local STATE_CANCELED                = Enum and Enum.EncounterTimelineEventState and Enum.EncounterTimelineEventState
    .Canceled or 3

Scheduler._active                   = {}
Scheduler._nextTimerID              = 1
Scheduler._elapsed                  = 0
Scheduler._running                  = false
Scheduler._frame                    = nil
Scheduler._encounterID              = nil
Scheduler._mode                     = "fixed"
Scheduler._timelineEventToTimer     = {}
Scheduler._lastFired                = {}
Scheduler._fixedDriver              = FIXED_DRIVER_TIME
Scheduler._fixedAIDurationRules     = nil
Scheduler._fixedAISkillByEventID    = {}
Scheduler._fixedAIEventToTimer      = {}
Scheduler._fixedAIPendingEvents     = {}
Scheduler._fixedAISequenceCounters  = {}
Scheduler._occurrenceCounts         = {}
Scheduler._fixedTimeOffset          = 0
Scheduler._fixedTimeEventToTimer    = {}
Scheduler._lastEncounterStartAt     = 0
Scheduler._lastEncounterStartID     = nil
Scheduler._lastEncounterEndAt       = 0
Scheduler._eventActionsByEventID    = {}
Scheduler._sessionToken             = 0
local MAX_LAST_FIRED                = 30
local LEGACY_EVENT_KEY              = "encounter" .. "EventID"
local _colorResolveErrorLogged      = false

local function SafeNum(v, def)
    local n = tonumber(v)
    if not n then return def end
    return n
end

local function ExtractColorRGB(colorObj)
    if type(colorObj) ~= "table" then
        return nil
    end
    local r = tonumber(colorObj.r)
    local g = tonumber(colorObj.g)
    local b = tonumber(colorObj.b)
    local a = tonumber(colorObj.a) or 1
    if r and g and b then
        return { r = r, g = g, b = b, a = a }
    end
    if type(colorObj.GetRGB) == "function" then
        local ok, rr, gg, bb = pcall(colorObj.GetRGB, colorObj)
        if ok and tonumber(rr) and tonumber(gg) and tonumber(bb) then
            return { r = tonumber(rr), g = tonumber(gg), b = tonumber(bb), a = a }
        end
    end
    return nil
end

local function ResolveTimelineDisplayName(spellIdentifier, eventID)
    if spellIdentifier ~= nil and C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellIdentifier)
        if ok and name then
            return name
        end
    end
    return "Timeline Event " .. tostring(eventID)
end

local function TimerDB()
    local tdb = nil
    if _G.InfinityBossData and _G.InfinityBossData.GetTimelineModeDB then
        tdb = _G.InfinityBossData.GetTimelineModeDB()
    else
        InfinityBossDB = InfinityBossDB or {}
        InfinityBossDB.timer = InfinityBossDB.timer or {}
        InfinityBossDB.timer.timelineMode = InfinityBossDB.timer.timelineMode or {}
        tdb = InfinityBossDB.timer.timelineMode
    end

    if type(tdb) ~= "table" then
        tdb = {}
    end
    if type(tdb.byEncounter) ~= "table" then tdb.byEncounter = {} end
    if type(tdb.default) ~= "string" or tdb.default == "" then tdb.default = "auto" end
    if type(tdb.fixedDriverByEncounter) ~= "table" then tdb.fixedDriverByEncounter = {} end
    if type(tdb.fixedDriverDefault) ~= "string" or tdb.fixedDriverDefault == "" then
        tdb.fixedDriverDefault = FIXED_DRIVER_TIME
    end
    return tdb
end

local function NormalizeBarDisplayMode(mode)
    local m = tostring(mode or ""):lower()
    if m == "timer" or m == "bun" or m == "both" or m == "none" then
        return m
    end
    return "bun"
end

local function GetBarDisplayMode()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    local g = InfinityBossDB.ui.general
    g.barDisplayMode = NormalizeBarDisplayMode(g.barDisplayMode)
    return g.barDisplayMode
end

local function IsTimerBarEnabledByGlobal()
    local mode = GetBarDisplayMode()
    return mode == "both" or mode == "timer"
end

local function IsBunBarEnabledByGlobal()
    local mode = GetBarDisplayMode()
    return mode == "both" or mode == "bun"
end

local function IsBossSceneEnabledForCurrentInstance()
    local bossCfg = InfinityBoss and InfinityBoss.BossConfig
    if bossCfg and type(bossCfg.IsCurrentSceneEnabled) == "function" then
        local ok, enabled = pcall(bossCfg.IsCurrentSceneEnabled, bossCfg)
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

    local _, instanceType = GetInstanceInfo()
    if instanceType == "raid" then
        return g.bossAlertsEnabledRaid ~= false
    end
    if instanceType == "party" then
        return g.bossAlertsEnabledMplus ~= false
    end
    return true
end

local function ResolveEncounterID(encounterID)
    local n = tonumber(encounterID)
    if n then
        return n
    end
    return encounterID
end

local function ResolveBossDef(encounterID)
    local bosses = InfinityBoss.Timeline and InfinityBoss.Timeline._bosses
    if type(bosses) ~= "table" then
        return nil, ResolveEncounterID(encounterID)
    end
    local id = ResolveEncounterID(encounterID)
    local def = bosses[id]
    if not def and type(id) == "number" then
        def = bosses[tostring(id)]
    end
    return def, id
end

local _encounterEventRowsCache = {}

local function GetEncounterEventRows(encounterID)
    local id = tonumber(encounterID)
    if not id then return nil end
    local cached = _encounterEventRowsCache[id]
    if cached ~= nil then
        return cached or nil
    end

    local data = _G.InfinityBoss_ENCOUNTER_DATA
    if type(data) ~= "table" or type(data.maps) ~= "table" then
        _encounterEventRowsCache[id] = false
        return nil
    end

    for _, map in pairs(data.maps) do
        if type(map) == "table" and type(map.bosses) == "table" then
            for _, boss in pairs(map.bosses) do
                if type(boss) == "table" and tonumber(boss.encounterID) == id and type(boss.events) == "table" then
                    _encounterEventRowsCache[id] = boss.events
                    return boss.events
                end
            end
        end
    end

    _encounterEventRowsCache[id] = false
    return nil
end

local function BuildRuntimeSkillFromEvent(eventID, event)
    if type(event) ~= "table" then return nil end
    local evenSpellID = tonumber(event.evenSpellID)
    local spellID = tonumber(event.spellID) or evenSpellID
    local name = event.eventName or event.name
    if type(name) ~= "string" or name == "" then
        name = spellID and ("Spell " .. tostring(spellID)) or ("Event " .. tostring(eventID))
    end
    return {
        eventID = tonumber(event.eventID) or tonumber(eventID),
        spellID = spellID,
        evenSpellID = evenSpellID,
        spellIdentifier = evenSpellID or spellID,
        displayName = name,
        source = "duration_map",
        preAlert = 5,
        castDuration = 1.5,
        barPriority = 2,
        showBunBar = true,
        showTimerBar = true,
        screenAlert = false,
        preAlertText = "{name}",
        screenText = nil,
        voiceLabel = name,
    }
end

local function NormalizeMode(mode)
    local m = tostring(mode or ""):lower()
    if m == "fixed" or m == "blizzard" or m == "auto" then
        return m
    end
    return "auto"
end

local function NormalizeFixedDriver(driver)
    local v = tostring(driver or ""):lower()
    if v == FIXED_DRIVER_AI then
        return FIXED_DRIVER_AI
    end
    return FIXED_DRIVER_TIME
end

local function NormalizeEncounterTrigger(trigger)
    local t = tostring(trigger or ""):upper()
    if t == TRIGGER_TIME or t == TRIGGER_AI or t == TRIGGER_BLZ then
        return t
    end
    return nil
end

local function GetEncounterTriggerPreset(encounterID)
    local id = tonumber(encounterID) or encounterID

    if _G.InfinityBossData and type(_G.InfinityBossData.GetEncounterTrigger) == "function" then
        local ok, trigger = pcall(_G.InfinityBossData.GetEncounterTrigger, id)
        if ok then
            local normalized = NormalizeEncounterTrigger(trigger)
            if normalized then
                return normalized
            end
        end
    end

    local all = _G.InfinityBoss_ENCOUNTER_TRIGGERS
    if type(all) ~= "table" then
        return nil
    end
    local row = all[id]
    if row == nil then
        row = all[tostring(id)]
    end
    if type(row) == "table" then
        return NormalizeEncounterTrigger(row.trigger)
    end
    return NormalizeEncounterTrigger(row)
end

local function GetEncounterTriggerRow(encounterID)
    local id = tonumber(encounterID) or encounterID
    local all = _G.InfinityBoss_ENCOUNTER_TRIGGERS
    if type(all) ~= "table" then
        return nil
    end
    local row = all[id]
    if row == nil then
        row = all[tostring(id)]
    end
    return type(row) == "table" and row or nil
end

local function BuildEncounterEventActions(encounterID)
    local out = {}
    local row = GetEncounterTriggerRow(encounterID)
    local src = row and row.eventActions
    if type(src) ~= "table" then
        return out
    end
    for rawEventID, actionRow in pairs(src) do
        local eventID = tonumber(rawEventID)
        if eventID and type(actionRow) == "table" then
            local clearDelay = tonumber(actionRow.clearActiveSnapshotAfter)
            if clearDelay and clearDelay > 0 then
                out[eventID] = {
                    clearActiveSnapshotAfter = clearDelay,
                }
            end
        end
    end
    return out
end

local function GetDurationRulesForEncounter(encounterID)
    local id = tonumber(encounterID)
    if not id then return nil end
    local rows = nil
    if type(_G.InfinityBoss_DURATION_EVENT_RULES) == "table" then
        rows = _G.InfinityBoss_DURATION_EVENT_RULES[id]
        if rows == nil then
            rows = _G.InfinityBoss_DURATION_EVENT_RULES[tostring(id)]
        end
    end
    if type(rows) ~= "table" or #rows == 0 then
        return nil
    end
    return rows
end

local function HasDurationRulesForEncounter(encounterID)
    return type(GetDurationRulesForEncounter(encounterID)) == "table"
end

local function GetFixedDriverOverride(encounterID)
    local tdb = TimerDB()
    local byID = tdb.fixedDriverByEncounter
    local v = byID[encounterID]
    if v == nil then
        v = byID[tostring(encounterID)]
    end
    if v == nil or v == "" then
        v = tdb.fixedDriverDefault or FIXED_DRIVER_TIME
    end
    return NormalizeFixedDriver(v)
end

local function ModeUsesFixed(mode)
    return mode == "fixed"
end

local function ModeUsesTimeline(mode)
    return mode == "blizzard"
end

local function CanUseFixedForEncounter(encounterID, bossDef)
    local id = tonumber(encounterID)
    if not id then return false end
    local set = _G.InfinityBoss_FIXED_TIMELINE_ENCOUNTERS
    if type(set) ~= "table" or set[id] ~= true then
        return false
    end
    local def = bossDef
    if type(def) ~= "table" then
        def = InfinityBoss.Timeline and InfinityBoss.Timeline._bosses and InfinityBoss.Timeline._bosses[id]
    end
    return type(def) == "table" and type(def.skills) == "table" and #def.skills > 0
end

local function CanUseDurationMapForEncounter(encounterID)
    return HasDurationRulesForEncounter(encounterID)
end

local function CanUseTimelineAPI()
    if not C_EncounterTimeline then return false end
    if C_EncounterTimeline.IsFeatureAvailable then
        local ok, available = pcall(C_EncounterTimeline.IsFeatureAvailable)
        if ok and not available then
            return false
        end
    end
    return true
end

local function NormalizeText(v)
    if type(v) ~= "string" then return "" end
    local t = v:gsub("^%s+", ""):gsub("%s+$", "")
    return t
end

local function IsSpellCountDisplayEnabled()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    return InfinityBossDB.ui.general.showSpellOccurrenceCount == true
end

local function BuildDisplayNameWithOccurrence(name, occurrence)
    if type(name) ~= "string" then
        return name
    end
    local n = tonumber(occurrence)
    if not n or n <= 0 or not IsSpellCountDisplayEnabled() then
        return name
    end
    return string.format("%s(%d)", tostring(name), n)
end

local function ResolveOccurrenceKey(skill, source)
    if type(skill) ~= "table" then
        return nil
    end
    local prefix = tostring(source or "timer")
    local eventID = tonumber(skill.eventID)
    if eventID then
        return prefix .. ":event:" .. tostring(eventID)
    end
    local spellID = tonumber(skill.evenSpellID) or tonumber(skill.spellIdentifier) or tonumber(skill.spellID)
    if spellID then
        return prefix .. ":spell:" .. tostring(spellID)
    end
    local name = NormalizeText(skill.displayName or skill.name)
    if name ~= "" then
        return prefix .. ":name:" .. name
    end
    return nil
end

local function ResolveDefaultCentralText(timer)
    if type(timer) ~= "table" then
        return ""
    end
    local text = NormalizeText(timer.screenText)
    if text ~= "" then
        return text
    end
    text = NormalizeText(timer.displayName)
    if text ~= "" then
        return text
    end
    return ""
end

local function NormalizeLeadSeconds(v, fallback)
    local n = tonumber(v)
    if not n then
        n = tonumber(fallback) or 0
    end
    if n < 0 then n = 0 end
    if n > 30 then n = 30 end
    return n
end

local function NormalizeTriggerOffsetMode(v)
    local s = tostring(v or ""):lower()
    if s == "early" then
        return "early"
    end
    return "delay"
end

local function NormalizeTriggerOffsetSeconds(v)
    local n = tonumber(v)
    if not n then
        n = 0
    end
    if n < 0 then n = 0 end
    if n > 30 then n = 30 end
    return n
end

local function GetEventConfigRoot()
    if _G.InfinityBossData and _G.InfinityBossData.GetEventConfigRoot then
        return _G.InfinityBossData.GetEventConfigRoot()
    end
    InfinityBossDataDB = InfinityBossDataDB or {}
    InfinityBossDataDB.events = InfinityBossDataDB.events or {}
    return InfinityBossDataDB.events
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

    local events = GetEventConfigRoot()
    if type(events) ~= "table" then
        return nil
    end
    return events[eid]
end

local function ResolveVoiceEventConfig(timer)
    if type(timer) ~= "table" then return nil end
    local eid = tonumber(timer.eventID) or tonumber(timer.timelineEventID)
    return ResolveRuntimeEventConfig(eid)
end

local function ResolveEventColorFromVoiceEvents(timer)
    if type(timer) ~= "table" then return nil end

    local eid = tonumber(timer.eventID) or tonumber(timer.timelineEventID)
    local cfg = ResolveRuntimeEventConfig(eid)
    if type(cfg) ~= "table" then return nil end
    if cfg.enabled == false then return nil end
    if type(cfg.color) ~= "table" or cfg.color.enabled == false then
        return nil
    end

    local CS = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ColorSchemes
    if CS and CS.ResolveEventColor then
        local r, g, b = CS.ResolveEventColor(cfg.color)
        if r ~= nil and g ~= nil and b ~= nil then
            return { r = r, g = g, b = b, a = 1 }
        end
    end
    if cfg.color.r ~= nil and cfg.color.g ~= nil and cfg.color.b ~= nil then
        return {
            r = tonumber(cfg.color.r) or 1,
            g = tonumber(cfg.color.g) or 0.82,
            b = tonumber(cfg.color.b) or 0.25,
            a = 1,
        }
    end
    return nil
end

local function SafeResolveEventColorFromVoiceEvents(timer)
    local ok, color = pcall(ResolveEventColorFromVoiceEvents, timer)
    if ok and type(color) == "table" then
        return color
    end
    if not ok and not _colorResolveErrorLogged then
        _colorResolveErrorLogged = true
    end
    return nil
end

local function GetSkillOverride(encounterID, eventID, spellID, legacySpellID)
    eventID = tonumber(eventID)
    if not eventID then return nil end
    return ResolveRuntimeEventConfig(eventID)
end

local function ResolveSkillEventID(skill)
    if type(skill) ~= "table" then return nil end
    local eventID = tonumber(skill.eventID)
    if eventID then return eventID end
    local legacy = rawget(skill, LEGACY_EVENT_KEY)
    return tonumber(legacy)
end

local function ResetFixedVoiceTriggerState(timer, trigger)
    timer["fixedVoiceTrigger" .. tostring(trigger) .. "Enabled"] = false
    timer["fixedVoiceTrigger" .. tostring(trigger) .. "Mode"] = "delay"
    timer["fixedVoiceTrigger" .. tostring(trigger) .. "Offset"] = 0
    timer["fixedVoiceTrigger" .. tostring(trigger) .. "Fired"] = false
end

local function ApplyFixedVoiceTriggerConfig(timer)
    ResetFixedVoiceTriggerState(timer, 1)
    ResetFixedVoiceTriggerState(timer, 2)

    if type(timer) ~= "table" then return end
    if timer.timelineManaged or timer.source == "blizzard" then return end

    local cfg = ResolveVoiceEventConfig(timer)
    if type(cfg) ~= "table" then
        if NormalizeText(timer.voiceLabel or timer.displayName) ~= "" then
            timer.fixedVoiceTrigger1Enabled = true
        end
        return
    end
    if cfg.enabled == false then
        return
    end

    local triggers = cfg.triggers
    if type(triggers) ~= "table" then
        if NormalizeText(timer.voiceLabel or timer.displayName) ~= "" then
            timer.fixedVoiceTrigger1Enabled = true
        end
        return
    end

    local hasExplicitFixedVoice = false
    for trigger = 1, 2 do
        local triggerCfg = triggers[trigger]
        if type(triggerCfg) == "table" and triggerCfg.enabled == true then
            hasExplicitFixedVoice = true
            timer["fixedVoiceTrigger" .. tostring(trigger) .. "Enabled"] = true
            timer["fixedVoiceTrigger" .. tostring(trigger) .. "Mode"] = NormalizeTriggerOffsetMode(triggerCfg
                .fixedOffsetMode)
            timer["fixedVoiceTrigger" .. tostring(trigger) .. "Offset"] = NormalizeTriggerOffsetSeconds(triggerCfg
                .fixedOffsetSeconds)
        end
    end

    if not hasExplicitFixedVoice and NormalizeText(timer.voiceLabel or timer.displayName) ~= "" then
        timer.fixedVoiceTrigger1Enabled = true
    end
end

local function GetFixedVoiceTriggerBaseTime(timer, trigger)
    if type(timer) ~= "table" then return nil end
    trigger = tonumber(trigger)
    if trigger == 1 then
        return tonumber(timer.castTime)
    end
    if trigger == 2 then
        if timer.preAlertEnabled == false then
            return nil
        end
        return tonumber(timer.preAlertTime)
    end
    return nil
end

local function GetFixedVoiceTriggerFireTime(timer, trigger)
    local baseTime = GetFixedVoiceTriggerBaseTime(timer, trigger)
    if not baseTime then
        return nil
    end

    local mode = NormalizeTriggerOffsetMode(timer["fixedVoiceTrigger" .. tostring(trigger) .. "Mode"])
    local offset = NormalizeTriggerOffsetSeconds(timer["fixedVoiceTrigger" .. tostring(trigger) .. "Offset"])
    if mode == "early" then
        return baseTime - offset
    end
    return baseTime + offset
end

local function HasPendingFixedVoiceTriggers(timer)
    if type(timer) ~= "table" then return false end
    for trigger = 1, 2 do
        if timer["fixedVoiceTrigger" .. tostring(trigger) .. "Enabled"] == true
            and timer["fixedVoiceTrigger" .. tostring(trigger) .. "Fired"] ~= true
            and GetFixedVoiceTriggerFireTime(timer, trigger) ~= nil then
            return true
        end
    end
    return false
end

local function HasAnyFixedVoiceTriggerEnabled(timer)
    if type(timer) ~= "table" then
        return false
    end
    return timer.fixedVoiceTrigger1Enabled == true or timer.fixedVoiceTrigger2Enabled == true
end

local function TryFireFixedVoiceTriggers(timer, now)
    if type(timer) ~= "table" then return end
    local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    if not (Engine and Engine.TryPlayForTimer) then
        return
    end

    for trigger = 1, 2 do
        local enabled = (timer["fixedVoiceTrigger" .. tostring(trigger) .. "Enabled"] == true)
        local firedKey = "fixedVoiceTrigger" .. tostring(trigger) .. "Fired"
        if enabled and timer[firedKey] ~= true then
            local fireAt = GetFixedVoiceTriggerFireTime(timer, trigger)
            if fireAt and now >= fireAt then
                timer[firedKey] = true
                Engine:TryPlayForTimer(timer, trigger)
            end
        end
    end
end

local function EnsureFixedVoiceAtCast(timer)
    if type(timer) ~= "table" then
        return
    end
    if timer.timelineManaged or timer.source == "blizzard" then
        return
    end
    if timer.fixedVoiceCastFallbackTried == true then
        return
    end
    timer.fixedVoiceCastFallbackTried = true

    local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    if not (Engine and Engine.TryPlayForTimer) then
        return
    end

    if not HasAnyFixedVoiceTriggerEnabled(timer) then
        local label = NormalizeText(timer.voiceLabel or timer.displayName)
        if label == "" then
            return
        end
    end

    Engine:TryPlayForTimer(timer, 1)
end

function Scheduler:_ApplySkillOverride(timer)
    if type(timer) ~= "table" then return true end
    timer.disabled = false
    local fixedOnlyAllowed = not (timer.timelineManaged or timer.source == "blizzard")

    if not fixedOnlyAllowed then
        timer.preAlertEnabled = false
        timer.preAlertTime = nil
        timer.preAlertText = nil
        timer.preAlertFired = true
        timer.screenAlert = false
        timer.centralEnabled = false
        timer.centralLead = 0
        timer.centralFired = true
        timer.screenText = nil
        timer.timerBarName = nil
        timer.flashTextColor = nil
        if timer.timelineManaged then
            timer.timelinePreAlertLead = 0
        end
    end

    if fixedOnlyAllowed then
        local eventColor = SafeResolveEventColorFromVoiceEvents(timer)
        if type(eventColor) == "table" then
            local resolved = {
                r = tonumber(eventColor.r) or 1,
                g = tonumber(eventColor.g) or 1,
                b = tonumber(eventColor.b) or 1,
                a = tonumber(eventColor.a) or 1,
            }
            timer.flashTextColor = resolved
            timer.eventColor = {
                r = resolved.r,
                g = resolved.g,
                b = resolved.b,
                a = resolved.a,
            }
        else
            timer.flashTextColor = nil
        end
    end

    local encounterID = tonumber(self._encounterID)
    local eventID = tonumber(timer.eventID) or tonumber(timer.timelineEventID)
    local spellIdentifier = nil
    if not (timer.timelineManaged or timer.source == "blizzard") then
        spellIdentifier = tonumber(timer.spellIdentifier) or tonumber(timer.spellID)
    end
    local legacySpellID = tonumber(timer.spellID)
    if not encounterID then
        return true
    end
    local override = GetSkillOverride(encounterID, eventID, spellIdentifier, legacySpellID)
    if type(override) ~= "table" then
        if fixedOnlyAllowed then
            local fallbackText = ResolveDefaultCentralText(timer)
            if fallbackText ~= "" then
                timer.centralEnabled = true
                timer.centralLead = 0
                timer.centralFired = false
                timer.screenText = fallbackText
            else
                timer.centralEnabled = false
                timer.centralLead = 0
                timer.centralFired = true
                timer.screenText = nil
            end
        end
        ApplyFixedVoiceTriggerConfig(timer)
        return true
    end

    if override.enabled == false then
        timer.disabled = true
        return false
    end

    if override.showBunBar ~= nil then
        timer.showBunBar = (override.showBunBar == true)
    end
    if override.showTimerBar ~= nil then
        timer.showTimerBar = (override.showTimerBar == true)
    end
    if override.screenAlert ~= nil then
        timer.screenAlert = (override.screenAlert == true)
    end
    if fixedOnlyAllowed then
        local preAlertSecs = tonumber(override.preAlert)
        if preAlertSecs then
            if preAlertSecs <= 0 then
                timer.preAlertTime = nil
                timer.preAlertFired = true
                if timer.timelineManaged then
                    timer.timelinePreAlertLead = 0
                end
            else
                timer.preAlertTime = (timer.castTime or GetTime()) - math.min(30, math.max(0, preAlertSecs))
                timer.preAlertFired = false
                if timer.timelineManaged then
                    timer.timelinePreAlertLead = math.min(30, math.max(0, preAlertSecs))
                end
            end
        end

        if override.centralEnabled == false then
            timer.centralEnabled = false
            timer.centralLead = 0
            timer.centralFired = true
            timer.screenText = nil
        else
            local fallbackText = ResolveDefaultCentralText(timer)
            timer.centralEnabled = true
            timer.centralLead = NormalizeLeadSeconds(override.centralLead, timer.centralLead)
            if timer.centralFired ~= true then
                timer.centralFired = false
            end
            local txt = NormalizeText(override.centralText)
            if txt ~= "" then
                timer.screenText = txt
            elseif fallbackText ~= "" then
                timer.screenText = fallbackText
            end
        end

        if override.preAlertEnabled == false then
            timer.preAlertEnabled = false
            timer.preAlertTime = nil
            timer.preAlertText = nil
            timer.screenAlert = false
            timer.preAlertFired = true
            if timer.timelineManaged then
                timer.timelinePreAlertLead = 0
            end
        else
            timer.preAlertEnabled = true
            timer.screenAlert = true
            local txt = NormalizeText(override.preAlertText)
            if txt ~= "" then
                timer.preAlertText = txt
            end
        end

        if override.timerBarRenameEnabled == true then
            local rename = NormalizeText(override.timerBarRenameText)
            if rename ~= "" then
                timer.timerBarName = rename
            else
                timer.timerBarName = nil
            end
        else
            timer.timerBarName = nil
        end
    end

    if override.timerTextColorEnabled == true then
        local r = tonumber(override.timerTextColorR)
        local g = tonumber(override.timerTextColorG)
        local b = tonumber(override.timerTextColorB)
        local a = tonumber(override.timerTextColorA) or 1
        if r and g and b then
            timer.timerTextColor = { r = r, g = g, b = b, a = a }
        end
    end

    ApplyFixedVoiceTriggerConfig(timer)

    return true
end

function Scheduler:_GetModeOverride(encounterID)
    local tdb = TimerDB()
    local byID = tdb.byEncounter
    local v = byID[encounterID]
    if v == nil then
        v = byID[tostring(encounterID)]
    end
    if v == nil or v == "" then
        v = tdb.default or "auto"
    end
    return NormalizeMode(v)
end

function Scheduler:GetResolvedMode(encounterID)
    local bossDef, resolvedID = ResolveBossDef(encounterID)
    local canFixedTime = CanUseFixedForEncounter(resolvedID, bossDef)
    local canDurationMap = CanUseDurationMapForEncounter(resolvedID)
    local canFixed = canFixedTime or canDurationMap
    local triggerPreset = GetEncounterTriggerPreset(resolvedID)
    local override = self:_GetModeOverride(resolvedID)

    if not bossDef and not canDurationMap then
        return "blizzard"
    end

    if override ~= "auto" then
        if override == "fixed" then
            if not canFixed then
                return "blizzard"
            end
            return "fixed"
        end
        if override == "blizzard" and not CanUseTimelineAPI() and canFixed then
            return "fixed"
        end
        return "blizzard"
    end

    if triggerPreset == TRIGGER_BLZ then
        return "blizzard"
    end
    if triggerPreset == TRIGGER_TIME then
        if canFixedTime then
            return "fixed"
        end
        if canDurationMap then
            return "fixed"
        end
        return "blizzard"
    end
    if triggerPreset == TRIGGER_AI then
        if canDurationMap then
            return "fixed"
        end
        if canFixedTime then
            return "fixed"
        end
        return "blizzard"
    end

    if canFixed then
        return "fixed"
    end
    return "blizzard"
end


function Scheduler:StartBoss(encounterID)
    if not IsBossSceneEnabledForCurrentInstance() then
        self:EndBoss()
        return false
    end
    self:EndBoss()
    TryPublishRuntimeSelection()

    local bossDef, resolvedID = ResolveBossDef(encounterID)
    if not bossDef then
        local count = 0
        if InfinityBoss.Timeline and InfinityBoss.Timeline._bosses then
            for _ in pairs(InfinityBoss.Timeline._bosses) do
                count = count + 1
            end
        end
        --         print("|cffff4400Ex|r|cff00ccffBoss|r StartBoss miss id=" .. tostring(encounterID)
        --             .. " type=" .. tostring(type(encounterID))
        --             .. " bosses=" .. tostring(count))
        bossDef = { axisType = "blizzard", skills = {} }
        resolvedID = ResolveEncounterID(encounterID)
    end

    self._encounterID = resolvedID
    self._mode = self:GetResolvedMode(resolvedID)
    self._running = true
    self._sessionToken = (tonumber(self._sessionToken) or 0) + 1
    self._eventActionsByEventID = BuildEncounterEventActions(resolvedID)

    local now = GetTime()
    if ModeUsesFixed(self._mode) then
        self:_SetupFixedDriver(resolvedID, bossDef)
        if self._fixedDriver == FIXED_DRIVER_TIME then
            for _, skill in ipairs(bossDef.skills or {}) do
                local src = tostring(skill.source or bossDef.axisType or "fixed"):lower()
                if src == "fixed" and skill.first then
                    self:_ExpandAndSchedule(skill, now)
                end
            end
        end
    else
        self._fixedDriver = FIXED_DRIVER_TIME
        self._fixedAIDurationRules = nil
        self._fixedAISkillByEventID = {}
        self._fixedAIEventToTimer = {}
    end

    if ModeUsesTimeline(self._mode) and CanUseTimelineAPI() then
        self:_RecoverTimelineEvents()
    end

    self._frame:Show()
    return true
end

function Scheduler:HandleEncounterStart(encounterID, source)
    local now = GetTime and GetTime() or 0
    local resolvedID = ResolveEncounterID(encounterID)
    if self._running and self._encounterID == resolvedID and (now - (tonumber(self._lastEncounterStartAt) or 0)) <= 1.0 then
        return
    end
    if self._lastEncounterStartID == resolvedID and (now - (tonumber(self._lastEncounterStartAt) or 0)) <= 1.0 then
        return
    end
    self._lastEncounterStartAt = now
    self._lastEncounterStartID = resolvedID
    self:StartBoss(encounterID)
end

function Scheduler:EndBoss()
    if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.ReleaseAll then
        InfinityBoss.UI.BunBar:ReleaseAll()
    end
    if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.ReleaseAll then
        InfinityBoss.UI.TimerBar:ReleaseAll()
    end
    if InfinityBoss.UI.Countdown and InfinityBoss.UI.Countdown.Stop then
        InfinityBoss.UI.Countdown:Stop()
    end
    if InfinityBoss.UI.FlashText and InfinityBoss.UI.FlashText.Stop then
        InfinityBoss.UI.FlashText:Stop()
    end
    self._active                = {}
    self._nextTimerID           = 1
    self._running               = false
    self._encounterID           = nil
    self._mode                  = "fixed"
    self._timelineEventToTimer  = {}
    self._lastFired             = {}
    self._fixedDriver           = FIXED_DRIVER_TIME
    self._fixedAIDurationRules  = nil
    self._fixedAISkillByEventID = {}
    self._fixedAIEventToTimer   = {}
    self._fixedAIPendingEvents      = {}
    self._fixedAISequenceCounters   = {}
    self._occurrenceCounts          = {}
    self._fixedTimeOffset           = 0
    self._fixedTimeEventToTimer     = {}
    self._eventActionsByEventID     = {}
    if self._frame then self._frame:Hide() end
end

function Scheduler:HandleEncounterEnd(source)
    local now = GetTime and GetTime() or 0
    if (now - (tonumber(self._lastEncounterEndAt) or 0)) <= 1.0 then
        return
    end
    self._lastEncounterEndAt = now
    self:EndBoss()
end

function Scheduler:StartBlizzardFallback()
    if not IsBossSceneEnabledForCurrentInstance() then
        self:EndBoss()
        return false
    end
    if self._running then
        return false
    end
    if not CanUseTimelineAPI() then
        return false
    end
    self._active                = {}
    self._nextTimerID           = 1
    self._encounterID           = nil
    self._mode                  = "blizzard"
    self._running               = true
    self._timelineEventToTimer  = {}
    self._lastFired             = {}
    self._fixedDriver           = FIXED_DRIVER_TIME
    self._fixedAIDurationRules  = nil
    self._fixedAISkillByEventID = {}
    self._fixedAIEventToTimer   = {}
    self._fixedAIPendingEvents  = {}
    self._fixedTimeOffset       = 0
    self._fixedTimeEventToTimer = {}
    if self._frame then
        self._frame:Show()
    end
    self:_RecoverTimelineEvents()
    return true
end


function Scheduler:_SetupFixedDriver(encounterID, bossDef)
    self._fixedDriver = FIXED_DRIVER_TIME
    self._fixedAIDurationRules = nil
    self._fixedAISkillByEventID = {}
    self._fixedAIEventToTimer = {}
    self._fixedAIPendingEvents = {}
    self._fixedTimeOffset = 0
    self._fixedTimeEventToTimer = {}

    local canFixedTime = CanUseFixedForEncounter(encounterID, bossDef)
    local durationRules = GetDurationRulesForEncounter(encounterID)
    local hasDurationRules = type(durationRules) == "table" and #durationRules > 0
    local triggerPreset = GetEncounterTriggerPreset(encounterID)
    local requestedDriver = GetFixedDriverOverride(encounterID)
    if triggerPreset == TRIGGER_AI then
        requestedDriver = FIXED_DRIVER_AI
    elseif triggerPreset == TRIGGER_TIME then
        requestedDriver = FIXED_DRIVER_TIME
    end

    local resolvedDriver = requestedDriver
    if resolvedDriver == FIXED_DRIVER_AI and not hasDurationRules then
        resolvedDriver = canFixedTime and FIXED_DRIVER_TIME or FIXED_DRIVER_TIME
    elseif resolvedDriver == FIXED_DRIVER_TIME and not canFixedTime and hasDurationRules then
        resolvedDriver = FIXED_DRIVER_AI
    elseif not canFixedTime and hasDurationRules then
        resolvedDriver = FIXED_DRIVER_AI
    elseif canFixedTime then
        resolvedDriver = FIXED_DRIVER_TIME
    end

    self._fixedDriver = resolvedDriver
    if resolvedDriver == FIXED_DRIVER_AI then
        self._fixedAIDurationRules = durationRules
    end

    if type(bossDef) == "table" and type(bossDef.skills) == "table" then
        for _, skill in ipairs(bossDef.skills) do
            local eventID = tonumber(skill and skill.eventID)
            if eventID then
                self._fixedAISkillByEventID[eventID] = skill
            end
        end
    end

    local eventRows = GetEncounterEventRows(encounterID)
    if type(eventRows) == "table" then
        for eventID, event in pairs(eventRows) do
            local eid = tonumber(eventID)
            if eid and not self._fixedAISkillByEventID[eid] then
                local skill = BuildRuntimeSkillFromEvent(eid, event)
                if skill then
                    self._fixedAISkillByEventID[eid] = skill
                end
            end
        end
    end
end

function Scheduler:_ApplyFixedTimeOffset(newOffset)
    local offset = tonumber(newOffset)
    if not offset then return end
    if math.abs(offset - (self._fixedTimeOffset or 0)) < FIXED_TIME_OFFSET_EPSILON then
        return
    end
    self._fixedTimeOffset = offset

    for _, timer in pairs(self._active) do
        if timer and timer.source == "fixed" and not timer.castFired then
            local base = tonumber(timer.baseCastTime) or tonumber(timer.castTime)
            if base then
                local oldCast = tonumber(timer.castTime) or base
                local newCast = base + offset
                local shift = newCast - oldCast
                timer.castTime = newCast
                if timer.preAlertTime then
                    timer.preAlertTime = timer.preAlertTime + shift
                end
            end
        end
    end
end

function Scheduler:_FindBestFixedTimeTimer(observedCastAt)
    local bestTimerID = nil
    local bestDelta = nil
    local target = tonumber(observedCastAt)
    if not target then return nil end

    for timerID, timer in pairs(self._active) do
        if timer and timer.source == "fixed" and not timer.castFired and timer.fixedTimelineMatched ~= true then
            local castTime = tonumber(timer.castTime)
            if castTime then
                local delta = math.abs(target - castTime)
                if (not bestDelta or delta < bestDelta) then
                    bestDelta = delta
                    bestTimerID = timerID
                end
            end
        end
    end

    if bestDelta and bestDelta <= FIXED_TIME_MATCH_TOLERANCE then
        return bestTimerID
    end
    return nil
end

function Scheduler:_ResolveFixedAIEventID(duration)
    local d = tonumber(duration)
    if not d then return nil end
    local rules = self._fixedAIDurationRules
    if type(rules) ~= "table" then return nil end

    local bestEventID, bestDelta = nil, nil
    for _, row in ipairs(rules) do
        local t = tonumber(row and row.time)
        local eventID = tonumber(row and row.eventID)
        if t and eventID then
            local delta = math.abs(d - t)
            if not bestDelta or delta < bestDelta then
                bestDelta = delta
                bestEventID = eventID
            end
        end
    end

    if bestDelta and bestDelta <= FIXED_AI_MATCH_TOLERANCE then
        return bestEventID
    end
    return nil
end

function Scheduler:_ResolveFixedAIEventIDForMode(duration, timelineEventID, syncMode)
    local d = tonumber(duration)
    if not d then return nil end
    local rules = self._fixedAIDurationRules
    if type(rules) ~= "table" then return nil end

    local bestEventID, bestDelta = nil, nil
    local timelineID = tonumber(timelineEventID)

    for _, row in ipairs(rules) do
        if type(row) == "table" then
            local rowSync = (row.sync == true)
            if rowSync == syncMode then
                local t = tonumber(row.time)
                local eventID = tonumber(row.eventID)
                if t and eventID then
                    if (not syncMode) or (timelineID and eventID == timelineID) then
                        local delta = math.abs(d - t)
                        if not bestDelta or delta < bestDelta then
                            bestDelta = delta
                            bestEventID = eventID
                        end
                    end
                end
            end
        end
    end

    if bestDelta and bestDelta <= FIXED_AI_MATCH_TOLERANCE then
        return bestEventID
    end
    return nil
end

function Scheduler:_ProcessFixedAIPendingBatch(batch, syncMode)
    if type(batch) ~= "table" or #batch == 0 then return end

    for _, queued in ipairs(batch) do
        local timelineEventID = tonumber(queued.timelineEventID)
        local duration = tonumber(queued.duration)
        local observedAt = tonumber(queued.receivedAt) or GetTime()
        if timelineEventID and duration then
            local inferredEventID = self:_ResolveFixedAIEventIDForMode(duration, timelineEventID, syncMode)
            if not inferredEventID and syncMode then
                inferredEventID = self:_ResolveFixedAIEventID(duration)
            end
            if inferredEventID then
                local skill = self._fixedAISkillByEventID[inferredEventID]
                if type(skill) == "table" then
                    local oldTimerID = self._fixedAIEventToTimer[timelineEventID]
                    if oldTimerID then
                        self._active[oldTimerID] = nil
                        self._fixedAIEventToTimer[timelineEventID] = nil
                    end

                    local castTime = observedAt + math.max(0, duration)
                    local timerID = self:_AddTimer(skill, castTime, "fixed_ai")
                    if timerID then
                        local timer = self._active[timerID]
                        if timer then
                            timer.fixedAITimelineEventID = timelineEventID
                        end
                        self._fixedAIEventToTimer[timelineEventID] = timerID
                    end
                end
            end
        end
    end
end

function Scheduler:_FlushFixedAIPendingEvents(now)
    if not (self._running and self._mode == "fixed" and self._fixedDriver == FIXED_DRIVER_AI) then return end
    local pending = self._fixedAIPendingEvents
    if type(pending) ~= "table" or #pending == 0 then return end
    now = tonumber(now) or GetTime()

    while #pending > 0 do
        local first = pending[1]
        local firstAt = tonumber(first and first.receivedAt)
        if not firstAt then
            table.remove(pending, 1)
        elseif (now - firstAt) < FIXED_AI_SYNC_WINDOW then
            break
        else
            local batch = {}
            local windowEnd = firstAt + FIXED_AI_SYNC_WINDOW
            while #pending > 0 do
                local row = pending[1]
                local rowAt = tonumber(row and row.receivedAt)
                if not rowAt or rowAt <= windowEnd then
                    table.insert(batch, row)
                    table.remove(pending, 1)
                else
                    break
                end
            end
            self:_ProcessFixedAIPendingBatch(batch, #batch >= 2)
        end
    end
end

function Scheduler:_OnFixedTimeTimelineEventAdded(eventInfo)
    if not FIXED_TIME_OFFSET_CALIBRATION_ENABLED then return end
    if not (self._running and self._mode == "fixed" and self._fixedDriver == FIXED_DRIVER_TIME) then return end
    if type(eventInfo) ~= "table" then return end

    local timelineEventID = tonumber(eventInfo.id)
    local duration = tonumber(eventInfo.duration)
    if not timelineEventID or not duration then return end

    local oldTimerID = self._fixedTimeEventToTimer[timelineEventID]
    if oldTimerID then
        self._active[oldTimerID] = nil
        self._fixedTimeEventToTimer[timelineEventID] = nil
    end

    local observedCastAt = GetTime() + math.max(0, duration)
    local timerID = self:_FindBestFixedTimeTimer(observedCastAt)
    if not timerID then
        return
    end

    local timer = self._active[timerID]
    if not timer then
        return
    end

    local baseCast = tonumber(timer.baseCastTime) or tonumber(timer.castTime)
    if baseCast then
        self:_ApplyFixedTimeOffset(observedCastAt - baseCast)
        timer = self._active[timerID] or timer
    end

    timer.fixedTimelineMatched = true
    timer.fixedTimeTimelineEventID = timelineEventID
    self._fixedTimeEventToTimer[timelineEventID] = timerID
end

function Scheduler:_OnFixedAITimelineEventAdded(eventInfo)
    if not (self._running and self._mode == "fixed" and self._fixedDriver == FIXED_DRIVER_AI) then return end
    if type(eventInfo) ~= "table" then return end

    local timelineEventID = tonumber(eventInfo.id)
    local duration = tonumber(eventInfo.duration)
    if not timelineEventID or not duration then return end
    table.insert(self._fixedAIPendingEvents, {
        timelineEventID = timelineEventID,
        duration = duration,
        receivedAt = GetTime(),
    })
end

function Scheduler:_OnFixedTimeTimelineEventRemoved(eventID)
    if not FIXED_TIME_OFFSET_CALIBRATION_ENABLED then return end
    if not (self._running and self._mode == "fixed" and self._fixedDriver == FIXED_DRIVER_TIME) then return end
    local timelineEventID = tonumber(eventID)
    if not timelineEventID then return end

    local timerID = self._fixedTimeEventToTimer[timelineEventID]
    if not timerID then return end

    self._fixedTimeEventToTimer[timelineEventID] = nil
    self._active[timerID] = nil
end

function Scheduler:_OnFixedAITimelineEventRemoved(eventID)
    if not (self._running and self._mode == "fixed" and self._fixedDriver == FIXED_DRIVER_AI) then return end
    local timelineEventID = tonumber(eventID)
    if not timelineEventID then return end

    local timerID = self._fixedAIEventToTimer[timelineEventID]
    if not timerID then return end

    self._fixedAIEventToTimer[timelineEventID] = nil
    self._active[timerID] = nil
end

function Scheduler:_ExpandAndSchedule(skill, battleStart)
    local first = tonumber(skill and skill.first)
    if not first then
        return nil
    end
    local castTime = battleStart + first
    local limit = battleStart + MAX_ENCOUNTER_DURATION
    if castTime > limit then
        return nil
    end

    local timerID = self:_AddTimer(skill, castTime, "fixed")
    local timer = timerID and self._active[timerID] or nil
    if timer then
        timer.fixedBattleStart = battleStart
        timer.fixedIntervalIndex = 1
    end
    return timerID
end

function Scheduler:_ScheduleNextFixedOccurrence(timer)
    if type(timer) ~= "table" or timer.source ~= "fixed" then
        return nil
    end

    local skill = timer.skillDef
    if type(skill) ~= "table" or skill.interval == nil then
        return nil
    end

    local interval = skill.interval
    local index = tonumber(timer.fixedIntervalIndex) or 1
    local delay = type(interval) == "table" and tonumber(interval[index]) or tonumber(interval)
    if not delay or delay <= 0 then
        return nil
    end

    local currentCast = tonumber(timer.castTime)
    local battleStart = tonumber(timer.fixedBattleStart)
    if not currentCast or not battleStart then
        return nil
    end

    local nextCast = currentCast + delay
    if nextCast > (battleStart + MAX_ENCOUNTER_DURATION) then
        return nil
    end

    local nextTimerID = self:_AddTimer(skill, nextCast, "fixed")
    local nextTimer = nextTimerID and self._active[nextTimerID] or nil
    if nextTimer then
        nextTimer.fixedBattleStart = battleStart
        nextTimer.fixedIntervalIndex = type(interval) == "table" and ((index % #interval) + 1) or 1
    end
    return nextTimerID
end

function Scheduler:_ApplyEncounterEventActions(timer)
    if type(timer) ~= "table" then
        return
    end
    local actions = self._eventActionsByEventID
    if type(actions) ~= "table" then
        timer.clearActiveSnapshotAfter = nil
        return
    end
    local eventID = tonumber(timer.eventID) or tonumber(timer.timelineEventID)
    local row = eventID and actions[eventID] or nil
    timer.clearActiveSnapshotAfter = tonumber(row and row.clearActiveSnapshotAfter)
end

function Scheduler:_NextOccurrenceCount(skill, source)
    local key = ResolveOccurrenceKey(skill, source)
    if not key then
        return nil
    end
    self._occurrenceCounts = type(self._occurrenceCounts) == "table" and self._occurrenceCounts or {}
    local nextCount = (tonumber(self._occurrenceCounts[key]) or 0) + 1
    self._occurrenceCounts[key] = nextCount
    return nextCount
end

function Scheduler:_ApplyTimerDisplayName(timer)
    if type(timer) ~= "table" then
        return
    end
    local baseName = timer.baseDisplayName or timer.displayName
    timer.baseDisplayName = baseName
    if timer.timelineManaged or timer.source == "blizzard" then
        timer.displayName = baseName
        return
    end
    timer.displayName = BuildDisplayNameWithOccurrence(baseName, timer.occurrenceCount)
end

function Scheduler:_AddTimer(skill, castTime, source)
    local id = self._nextTimerID
    self._nextTimerID = id + 1
    local occurrenceCount = self:_NextOccurrenceCount(skill, source)

    local timer = {
        id                   = id,
        spellID              = skill.spellID,
        spellIdentifier      = skill.evenSpellID or skill.spellIdentifier or skill.spellID,
        baseDisplayName      = skill.displayName,
        displayName          = skill.displayName,
        occurrenceCount      = occurrenceCount,
        baseCastTime         = castTime,
        castTime             = castTime,
        duration             = skill.preAlert and (skill.preAlert + (skill.castDuration or 0)) or 30,
        timerBarDuration     = TIMERBAR_LEAD_TIME,
        preAlertTime         = skill.preAlert and (castTime - skill.preAlert) or nil,
        barPriority          = skill.barPriority or 2,
        showBunBar           = skill.showBunBar ~= false,
        showTimerBar         = skill.showTimerBar ~= false,
        headAlert            = skill.headAlert or false,
        screenAlert          = skill.screenAlert or false,
        preAlertText         = skill.preAlertText,
        screenText           = skill.screenText,
        centralLead          = NormalizeLeadSeconds(skill.centralLead, 0),
        voiceLabel           = skill.voiceLabel,
        source               = source,
        eventID              = ResolveSkillEventID(skill),
        eventColor           = skill.eventColor,
        preAlertFired        = false,
        hintRemaining5Fired  = false,
        castFired            = false,
        bunBarShown          = false,
        timerBarShown        = false,
        timelineManaged      = false,
        timelineEventID      = nil,
        timelinePreAlertLead = DEFAULT_PREALERT_SECS,
        fixedTimelineMatched = false,
        centralFired         = false,
        skillDef             = skill,
    }

    self:_ApplyTimerDisplayName(timer)
    self:_ApplyEncounterEventActions(timer)

    if not self:_ApplySkillOverride(timer) then
        return nil
    end

    self._active[id] = timer

    return id
end


function Scheduler:_GetTimelineRemaining(eventID, fallback)
    if C_EncounterTimeline and C_EncounterTimeline.GetEventTimeRemaining then
        local ok, r = pcall(C_EncounterTimeline.GetEventTimeRemaining, eventID)
        if ok and type(r) == "number" then
            return r
        end
    end
    return fallback
end

function Scheduler:_GetTimelineState(eventID)
    if C_EncounterTimeline and C_EncounterTimeline.GetEventState then
        local ok, s = pcall(C_EncounterTimeline.GetEventState, eventID)
        if ok then return s end
    end
    return nil
end

function Scheduler:_BuildTimelineTimer(eventID, remaining, passthroughSpellIdentifier, passthroughIconFileID,
                                       passthroughEventColor)
    eventID = tonumber(eventID)
    if not eventID then return nil end

    local now = GetTime()
    remaining = SafeNum(remaining, self:_GetTimelineRemaining(eventID, 0))
    if remaining < 0 then remaining = 0 end

    local name = ResolveTimelineDisplayName(passthroughSpellIdentifier, eventID)
    local priority = 2
    local screenAlert = false

    local lead = math.min(DEFAULT_PREALERT_SECS, math.max(0, remaining))
    local timer = {
        spellID              = nil,
        spellIdentifier      = passthroughSpellIdentifier,
        iconFileID           = passthroughIconFileID,
        displayName          = name,
        castTime             = now + remaining,
        duration             = math.max(5, remaining),
        timerBarDuration     = TIMERBAR_LEAD_TIME,
        preAlertTime         = nil,
        barPriority          = priority,
        showBunBar           = true,
        showTimerBar         = true,
        headAlert            = false,
        screenAlert          = screenAlert,
        preAlertText         = "{name} incoming",
        screenText           = nil,
        centralLead          = 0,
        voiceLabel           = nil,
        source               = "blizzard",
        eventID              = nil,
        eventColor           = passthroughEventColor,
        preAlertFired        = false,
        hintRemaining5Fired  = false,
        castFired            = false,
        bunBarShown          = false,
        timerBarShown        = false,
        timelineManaged      = true,
        timelineEventID      = eventID,
        timelinePreAlertLead = lead,
        centralFired         = false,
    }
    if not self:_ApplySkillOverride(timer) then
        return nil
    end
    return timer
end

function Scheduler:_AttachTimelineEventByID(eventID, remaining, passthroughSpellIdentifier, passthroughIconFileID,
                                            passthroughEventColor)
    eventID = tonumber(eventID)
    if not eventID then return end

    local exists = self._timelineEventToTimer[eventID]
    if exists and self._active[exists] then
        local timer = self._active[exists]
        if timer then
            if passthroughSpellIdentifier ~= nil then
                timer.spellIdentifier = passthroughSpellIdentifier
            end
            if passthroughIconFileID ~= nil then
                timer.iconFileID = passthroughIconFileID
            end
            if type(passthroughEventColor) == "table" then
                timer.eventColor = passthroughEventColor
            end
            timer.spellID = nil
            timer.displayName = ResolveTimelineDisplayName(timer.spellIdentifier, eventID)
        end
        local now = GetTime()
        remaining = SafeNum(remaining, self:_GetTimelineRemaining(eventID, timer.castTime - now))
        if remaining and remaining >= 0 then
            timer.castTime = now + remaining
            timer.timelinePreAlertLead = math.min(DEFAULT_PREALERT_SECS, math.max(0, remaining))
        end
        if not self:_ApplySkillOverride(timer) then
            self:_DetachTimelineEvent(eventID)
        end
        return
    end

    local timer = self:_BuildTimelineTimer(eventID, remaining, passthroughSpellIdentifier, passthroughIconFileID,
        passthroughEventColor)
    if not timer then return end

    local id = self._nextTimerID
    self._nextTimerID = id + 1
    timer.id = id
    self._active[id] = timer
    self._timelineEventToTimer[eventID] = id
end

function Scheduler:_DetachTimelineEvent(eventID)
    local timerID = self._timelineEventToTimer[eventID]
    if not timerID then return end
    self._timelineEventToTimer[eventID] = nil
    self._active[timerID] = nil
end

function Scheduler:_RecoverTimelineEvents()
    if not (self._running and ModeUsesTimeline(self._mode) and CanUseTimelineAPI()) then
        return
    end
    if not (C_EncounterTimeline and C_EncounterTimeline.GetEventList) then
        return
    end
    local ok, events = pcall(C_EncounterTimeline.GetEventList)
    if not ok or type(events) ~= "table" then return end

    for _, eventID in ipairs(events) do
        local remaining = self:_GetTimelineRemaining(eventID, 0)
        local passthroughSpellIdentifier = nil
        local passthroughIconFileID = nil
        local passthroughEventColor = nil
        if C_EncounterTimeline and C_EncounterTimeline.GetEventInfo then
            local okInfo, info = pcall(C_EncounterTimeline.GetEventInfo, eventID)
            if okInfo and info then
                passthroughSpellIdentifier = info.spellID
                passthroughIconFileID = tonumber(info.iconFileID)
                passthroughEventColor = ExtractColorRGB(info.color)
            end
        end
        self:_AttachTimelineEventByID(eventID, remaining, passthroughSpellIdentifier, passthroughIconFileID,
            passthroughEventColor)
    end
end

function Scheduler:_OnTimelineEventAdded(eventInfo)
    if not (self._running and ModeUsesTimeline(self._mode)) then return end
    if type(eventInfo) == "table" and tonumber(eventInfo.id) then
        local eventID = tonumber(eventInfo.id)
        self:_AttachTimelineEventByID(
            eventID,
            self:_GetTimelineRemaining(eventID, 0),
            eventInfo.spellID,
            tonumber(eventInfo.iconFileID),
            ExtractColorRGB(eventInfo.color)
        )
        return
    end
    self:_RecoverTimelineEvents()
end

function Scheduler:_OnTimelineEventStateChanged(eventID)
    if not (self._running and ModeUsesTimeline(self._mode)) then return end
    local timerID = self._timelineEventToTimer[eventID]
    if not timerID then
        local passthroughSpellIdentifier = nil
        local passthroughIconFileID = nil
        local passthroughEventColor = nil
        if C_EncounterTimeline and C_EncounterTimeline.GetEventInfo then
            local okInfo, info = pcall(C_EncounterTimeline.GetEventInfo, eventID)
            if okInfo and info then
                passthroughSpellIdentifier = info.spellID
                passthroughIconFileID = tonumber(info.iconFileID)
                passthroughEventColor = ExtractColorRGB(info.color)
            end
        end
        self:_AttachTimelineEventByID(eventID, self:_GetTimelineRemaining(eventID, 0), passthroughSpellIdentifier,
            passthroughIconFileID, passthroughEventColor)
        return
    end

    local timer = self._active[timerID]
    if not timer then
        self._timelineEventToTimer[eventID] = nil
        return
    end

    local state = self:_GetTimelineState(eventID)
    if state == STATE_FINISHED then
        timer.castFired = true
        if InfinityBoss.Timeline.Dispatcher then
            InfinityBoss.Timeline.Dispatcher:OnCast(timer)
        end
        self:_DetachTimelineEvent(eventID)
    elseif state == STATE_CANCELED then
        self:_DetachTimelineEvent(eventID)
    end
end

function Scheduler:_OnTimelineEventRemoved(eventID)
    if not (self._running and ModeUsesTimeline(self._mode)) then return end
    self:_DetachTimelineEvent(eventID)
end

function Scheduler:_UpdateTimelineManagedTimer(timer, now)
    local eventID = timer.timelineEventID
    if not eventID then
        return "remove"
    end

    local state = self:_GetTimelineState(eventID)
    if state == nil then
        return "remove"
    end

    local remaining = self:_GetTimelineRemaining(eventID, timer.castTime - now)
    if type(remaining) == "number" and remaining >= 0 then
        timer.castTime = now + remaining
    else
        remaining = math.max(0, timer.castTime - now)
    end

    if not timer.hintRemaining5Fired and remaining <= VIRTUAL_HINT_REMAINING_SECS then
        timer.hintRemaining5Fired = true
        if InfinityBoss.Timeline.Dispatcher and InfinityBoss.Timeline.Dispatcher.OnTimelineHint then
            InfinityBoss.Timeline.Dispatcher:OnTimelineHint(timer, VIRTUAL_HINT_REMAINING_SECS)
        end
    end

    local lead = SafeNum(timer.timelinePreAlertLead, DEFAULT_PREALERT_SECS)
    if not timer.preAlertFired and remaining <= lead then
        timer.preAlertFired = true
        if InfinityBoss.Timeline.Dispatcher then
            InfinityBoss.Timeline.Dispatcher:OnPreAlert(timer)
        end
    end

    local centralLead = NormalizeLeadSeconds(timer.centralLead, 0)
    if centralLead > 0 and timer.centralEnabled ~= false and not timer.centralFired and remaining <= centralLead then
        timer.centralFired = true
        if InfinityBoss.Timeline.Dispatcher and InfinityBoss.Timeline.Dispatcher.OnCentral then
            InfinityBoss.Timeline.Dispatcher:OnCentral(timer)
        end
    end

    if state == STATE_FINISHED or remaining <= 0 then
        if not timer.castFired then
            timer.castFired = true
            if InfinityBoss.Timeline.Dispatcher then
                InfinityBoss.Timeline.Dispatcher:OnCast(timer)
            end
        end
        return "remove"
    end
    if state == STATE_CANCELED then
        return "remove"
    end
    return "keep"
end


local HIGHLIGHT_TARGET_SECS = 5
local HIGHLIGHT_SNAP_TOLERANCE = 4

function Scheduler:_OnTimelineHighlight()
    if not self._running then return end
    local targetTime = GetTime() + HIGHLIGHT_TARGET_SECS
    local bestID, bestDelta = nil, math.huge
    for id, timer in pairs(self._active) do
        if not timer.timelineManaged and not timer.castFired then
            local delta = math.abs(timer.castTime - targetTime)
            if delta < bestDelta then
                bestDelta = delta
                bestID = id
            end
        end
    end
    if bestID and bestDelta <= HIGHLIGHT_SNAP_TOLERANCE then
        local timer = self._active[bestID]
        local oldCast = timer.castTime
        timer.castTime = targetTime
        if timer.preAlertTime and not timer.preAlertFired then
            timer.preAlertTime = timer.preAlertTime + (targetTime - oldCast)
        end
    end
end


function Scheduler:_OnUpdate(elapsed)
    if not self._running then return end
    self._elapsed = self._elapsed + elapsed
    if self._elapsed < ONUPDATE_INTERVAL then return end
    self._elapsed  = 0

    local now      = GetTime()
    local toRemove = nil

    self:_FlushFixedAIPendingEvents(now)

    for id, timer in pairs(self._active) do
        local action = nil
        if timer.timelineManaged then
            action = self:_UpdateTimelineManagedTimer(timer, now)
        end

        if action ~= "remove" then
            if not timer.bunBarShown and timer.showBunBar and IsBunBarEnabledByGlobal() and now >= (timer.castTime - BUNBAR_LEAD_TIME) then
                timer.bunBarShown = true
                if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.AddTimer then
                    InfinityBoss.UI.BunBar:AddTimer(timer)
                end
            end

            if not timer.timerBarShown and timer.showTimerBar and IsTimerBarEnabledByGlobal() and now >= (timer.castTime - TIMERBAR_LEAD_TIME) then
                timer.timerBarShown = true
                if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.AddTimer then
                    InfinityBoss.UI.TimerBar:AddTimer(timer)
                end
            end

            if not timer.timelineManaged then
                if not timer.hintRemaining5Fired and now >= (timer.castTime - VIRTUAL_HINT_REMAINING_SECS) then
                    timer.hintRemaining5Fired = true
                    if InfinityBoss.Timeline.Dispatcher and InfinityBoss.Timeline.Dispatcher.OnTimelineHint then
                        InfinityBoss.Timeline.Dispatcher:OnTimelineHint(timer, VIRTUAL_HINT_REMAINING_SECS)
                    end
                end
                if not timer.preAlertFired and timer.preAlertTime and now >= timer.preAlertTime then
                    timer.preAlertFired = true
                    if InfinityBoss.Timeline.Dispatcher then
                        InfinityBoss.Timeline.Dispatcher:OnPreAlert(timer)
                    end
                end
                local centralLead = NormalizeLeadSeconds(timer.centralLead, 0)
                if centralLead > 0 and timer.centralEnabled ~= false and not timer.centralFired and now >= (timer.castTime - centralLead) then
                    timer.centralFired = true
                    if InfinityBoss.Timeline.Dispatcher and InfinityBoss.Timeline.Dispatcher.OnCentral then
                        InfinityBoss.Timeline.Dispatcher:OnCentral(timer)
                    end
                end
                TryFireFixedVoiceTriggers(timer, now)
                if not timer.castFired and now >= timer.castTime then
                    timer.castFired = true
                    timer.firedAt = now
                    table.insert(Scheduler._lastFired, 1, timer)
                    while #Scheduler._lastFired > MAX_LAST_FIRED do
                        table.remove(Scheduler._lastFired)
                    end
                    if InfinityBoss.Timeline.Dispatcher then
                        InfinityBoss.Timeline.Dispatcher:OnCast(timer)
                    end
                    EnsureFixedVoiceAtCast(timer)
                    if timer.source == "fixed" then
                        self:_ScheduleNextFixedOccurrence(timer)
                    end
                end
                if timer.castFired and not HasPendingFixedVoiceTriggers(timer) then
                    action = "remove"
                end
            end
        end

        if action == "remove" then
            if not toRemove then toRemove = {} end
            toRemove[id] = true
        end
    end

    if toRemove then
        for id in pairs(toRemove) do
            local timer = self._active[id]
            if timer and timer.timelineEventID then
                self._timelineEventToTimer[timer.timelineEventID] = nil
            end
            if timer and timer.fixedAITimelineEventID then
                self._fixedAIEventToTimer[timer.fixedAITimelineEventID] = nil
            end
            if timer and timer.fixedTimeTimelineEventID then
                self._fixedTimeEventToTimer[timer.fixedTimeTimelineEventID] = nil
            end
            self._active[id] = nil
        end
    end
end

function Scheduler:GetActiveTimers()
    return self._active
end

function Scheduler:GetCurrentEncounterID()
    return self._encounterID
end


local frame = CreateFrame("Frame")
frame:Hide()
frame:SetScript("OnUpdate", function(_, elapsed)
    Scheduler:_OnUpdate(elapsed)
end)
frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED")
frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")
frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT")
frame:RegisterEvent("ENCOUNTER_TIMELINE_STATE_UPDATED")
Scheduler._handlesEncounterEvents = false
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
        if Scheduler._running and Scheduler._mode == "fixed" then
            if Scheduler._fixedDriver == FIXED_DRIVER_AI then
                Scheduler:_OnFixedAITimelineEventAdded(arg1)
                return
            end
            if Scheduler._fixedDriver == FIXED_DRIVER_TIME then
                Scheduler:_OnFixedTimeTimelineEventAdded(arg1)
                return
            end
        end
        if not Scheduler._running then
            Scheduler:StartBlizzardFallback()
        end
        Scheduler:_OnTimelineEventAdded(arg1)
    elseif event == "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then
        if Scheduler._running and Scheduler._mode == "fixed" then
            return
        end
        if not Scheduler._running then
            Scheduler:StartBlizzardFallback()
        end
        Scheduler:_OnTimelineEventStateChanged(arg1)
    elseif event == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        if Scheduler._running and Scheduler._mode == "fixed" then
            if Scheduler._fixedDriver == FIXED_DRIVER_AI then
                Scheduler:_OnFixedAITimelineEventRemoved(arg1)
                return
            end
            if Scheduler._fixedDriver == FIXED_DRIVER_TIME then
                Scheduler:_OnFixedTimeTimelineEventRemoved(arg1)
                return
            end
        end
        if not Scheduler._running then
            Scheduler:StartBlizzardFallback()
        end
        Scheduler:_OnTimelineEventRemoved(arg1)
    elseif event == "ENCOUNTER_TIMELINE_STATE_UPDATED" then
        if not Scheduler._running then
            Scheduler:StartBlizzardFallback()
        end
        Scheduler:_RecoverTimelineEvents()
    elseif event == "ENCOUNTER_TIMELINE_EVENT_HIGHLIGHT" then
        Scheduler:_OnTimelineHighlight()
    end
end)
Scheduler._frame        = frame
Scheduler._elapsed      = 0

InfinityBoss.Timeline._bosses = InfinityBoss.Timeline._bosses or {}

function InfinityBoss.Timeline:RegisterBoss(encounterID, def)
    self._bosses[encounterID] = def
end
