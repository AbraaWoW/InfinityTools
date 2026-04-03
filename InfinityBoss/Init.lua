---@diagnostic disable: undefined-global
-- =============================================================
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then
    return
end

InfinityBoss._initLoaded = true

local _autoCAAWasForced = false
local _autoCAAPrevValue = nil
local _autoCAAVolumeMuted = false
local _autoCAAPrevVolumes = {}
local _autoCAACurrentEncounterID = nil
local _externalBossModBarsHidden = false
local _externalBossModBarTicker = nil
local _externalBossModBarStates = {}
local _externalBossModSavedState = {}
local CAA_DEBUG_LOG = false

local function CAADebug(msg)
    if not CAA_DEBUG_LOG then return end
    --     print("|cffff8800InfinityBoss CAA|r " .. tostring(msg or ""))
end

local function EnsureGeneralDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    local g = InfinityBossDB.ui.general
    if g.bossAlertsEnabledMplus == nil then
        g.bossAlertsEnabledMplus = false
    else
        g.bossAlertsEnabledMplus = (g.bossAlertsEnabledMplus == true)
    end
    if g.bossAlertsEnabledRaid == nil then
        g.bossAlertsEnabledRaid = false
    else
        g.bossAlertsEnabledRaid = (g.bossAlertsEnabledRaid == true)
    end
    if g.autoDisableCAAInBoss == nil then
        g.autoDisableCAAInBoss = false
    else
        g.autoDisableCAAInBoss = (g.autoDisableCAAInBoss == true)
    end
    return g
end

local function EnsureBunBarDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    InfinityBossDB.timer.bunBar = InfinityBossDB.timer.bunBar or {}

    local b = InfinityBossDB.timer.bunBar
    if b.enabled == nil then
        b.enabled = false
    else
        b.enabled = (b.enabled ~= false)
    end
    b.hideExternalBossModBars = (b.hideExternalBossModBars == true)
    return b
end

local function IsBunBarDisplayEnabled()
    local g = EnsureGeneralDB()
    local mode = tostring(g.barDisplayMode or "bun"):lower()
    return mode == "bun" or mode == "both"
end

local function IsTrackedInfinityBossEncounter(encounterID)
    local bosses = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline._bosses
    if type(bosses) ~= "table" then
        return false
    end

    local id = tonumber(encounterID) or encounterID
    return bosses[id] ~= nil or bosses[tostring(id or "")] ~= nil
end

local function ShouldHideExternalBossModBars(encounterID)
    local b = EnsureBunBarDB()
    if b.hideExternalBossModBars ~= true then
        return false
    end
    return IsTrackedInfinityBossEncounter(encounterID)
end

local function IsExternalBossModBarFrame(frame)
    if not frame then
        return false
    end

    local name = frame.GetName and frame:GetName() or nil
    if type(name) ~= "string" or name == "" then
        return false
    end

    if name == "BigWigsAnchor"
        or name == "BigWigsEmphasizeAnchor"
        or name == "DBMBarAnchor"
        or name == "DBMMainFrame"
        or name == "DBT_Bar_Anchor"
        or name == "DBT_Bar_EnlargeAnchor" then
        return true
    end

    if name:match("^DBT_Bar_%d+") or name:match("^DBM.*Bar") then
        return true
    end

    if name:match("^BigWigs") and name:find("Bar") then
        return true
    end

    return false
end

local function HideExternalBossModBarFrame(frame)
    if not frame then
        return
    end

    if not _externalBossModBarStates[frame] then
        local alpha = 1
        if frame.GetAlpha then
            local ok, value = pcall(frame.GetAlpha, frame)
            if ok and tonumber(value) then
                alpha = tonumber(value)
            end
        end

        _externalBossModBarStates[frame] = {
            shown = frame.IsShown and frame:IsShown() or false,
            alpha = alpha,
        }
    end

    if frame.SetAlpha then
        pcall(frame.SetAlpha, frame, 0)
    end
    if frame.Hide then
        pcall(frame.Hide, frame)
    end
end

local function SetBigWigsBarsPluginHidden(hidden)
    local bw = _G.BigWigs
    if not bw or type(bw.GetPlugin) ~= "function" then
        return
    end

    local ok, barsPlugin = pcall(bw.GetPlugin, bw, "Bars", true)
    if not ok or not barsPlugin then
        return
    end

    if hidden then
        if _externalBossModSavedState.bigWigsBarsEnabled == nil then
            local wasEnabled = true
            if type(barsPlugin.IsEnabled) == "function" then
                local okEnabled, enabledValue = pcall(barsPlugin.IsEnabled, barsPlugin)
                if okEnabled then
                    wasEnabled = (enabledValue == true)
                end
            end
            _externalBossModSavedState.bigWigsBarsEnabled = wasEnabled
        end
        if type(barsPlugin.Disable) == "function" then
            pcall(barsPlugin.Disable, barsPlugin)
        end
        return
    end

    local shouldEnable = (_externalBossModSavedState.bigWigsBarsEnabled == true)
    _externalBossModSavedState.bigWigsBarsEnabled = nil
    if shouldEnable and type(barsPlugin.Enable) == "function" then
        pcall(barsPlugin.Enable, barsPlugin)
    end
end

local function SetDBMBossTimersHidden(hidden)
    local dbm = _G.DBM
    if not dbm or type(dbm) ~= "table" then
        return
    end

    dbm.Options = dbm.Options or {}

    if hidden then
        if _externalBossModSavedState.dbmDontShowBossTimers == nil then
            _externalBossModSavedState.dbmDontShowBossTimers = (dbm.Options.DontShowBossTimers == true)
        end
        dbm.Options.DontShowBossTimers = true
        if _G.DBT and type(_G.DBT.CancelAllBars) == "function" then
            pcall(_G.DBT.CancelAllBars, _G.DBT)
        end
        return
    end

    if _externalBossModSavedState.dbmDontShowBossTimers ~= nil then
        dbm.Options.DontShowBossTimers = (_externalBossModSavedState.dbmDontShowBossTimers == true)
        _externalBossModSavedState.dbmDontShowBossTimers = nil
    end
end

local function ScanExternalBossModBars()
    SetBigWigsBarsPluginHidden(true)
    SetDBMBossTimersHidden(true)

    local frame = EnumerateFrames()
    while frame do
        if IsExternalBossModBarFrame(frame) then
            HideExternalBossModBarFrame(frame)
        end
        frame = EnumerateFrames(frame)
    end
end

local function RestoreExternalBossModBars()
    if _externalBossModBarTicker then
        _externalBossModBarTicker:Cancel()
        _externalBossModBarTicker = nil
    end

    for frame, state in pairs(_externalBossModBarStates) do
        if frame and frame.SetAlpha then
            pcall(frame.SetAlpha, frame, tonumber(state.alpha) or 1)
        end
        if frame and state.shown and frame.Show then
            pcall(frame.Show, frame)
        end
        _externalBossModBarStates[frame] = nil
    end

    SetBigWigsBarsPluginHidden(false)
    SetDBMBossTimersHidden(false)

    _externalBossModBarsHidden = false
end

local function ApplyExternalBossModBarVisibility(encounterID, inEncounter)
    if not inEncounter or not ShouldHideExternalBossModBars(encounterID) then
        RestoreExternalBossModBars()
        return
    end

    if _externalBossModBarsHidden then
        return
    end

    _externalBossModBarsHidden = true
    ScanExternalBossModBars()
    _externalBossModBarTicker = C_Timer.NewTicker(0.2, ScanExternalBossModBars)
end

InfinityBoss.ApplyExternalBossModBarVisibility = ApplyExternalBossModBarVisibility

local function IsFixedTimelineEncounterForCAA(encounterID)
    local id = tonumber(encounterID)
    local fixed = _G.InfinityBoss_FIXED_TIMELINE_ENCOUNTERS
    if type(fixed) ~= "table" then
        return false, "no fixed table"
    end
    if id and fixed[id] == true then
        return true, "fixed=true(id)"
    end
    if encounterID ~= nil and fixed[encounterID] == true then
        return true, "fixed=true(raw)"
    end
    return false, "fixed=false"
end

local function ReadCAAEnabled()
    local ok, value
    if C_CVar and C_CVar.GetCVar then
        ok, value = pcall(C_CVar.GetCVar, "CAAEnabled")
    end
    if (not ok or value == nil) and type(GetCVar) == "function" then
        ok, value = pcall(GetCVar, "CAAEnabled")
    end
    if not ok then return nil end
    if value == nil then return nil end
    local s = tostring(value)
    if s == "" then return nil end
    return s
end

local function WriteCAAEnabled(value)
    local s = tostring(value or "")
    if s == "" then return false end
    local ok = false
    if C_CVar and C_CVar.SetCVar then
        ok = pcall(C_CVar.SetCVar, "CAAEnabled", s)
        if ok then
            CAADebug("fallback SetCVar CAAEnabled=" .. s .. " via C_CVar.SetCVar")
            return true
        end
    end
    if type(SetCVar) == "function" then
        ok = pcall(SetCVar, "CAAEnabled", s)
        if ok then
            CAADebug("fallback SetCVar CAAEnabled=" .. s .. " via SetCVar")
            return true
        end
    end
    CAADebug("fallback SetCVar CAAEnabled failed: " .. s)
    return false
end

local function ReadGenericCVar(name)
    local key = tostring(name or "")
    if key == "" then return nil end
    local ok, value
    if C_CVar and C_CVar.GetCVar then
        ok, value = pcall(C_CVar.GetCVar, key)
    end
    if (not ok or value == nil) and type(GetCVar) == "function" then
        ok, value = pcall(GetCVar, key)
    end
    if not ok or value == nil then return nil end
    local s = tostring(value)
    if s == "" then return nil end
    return s
end

local function WriteGenericCVar(name, value)
    local key = tostring(name or "")
    local s = tostring(value or "")
    if key == "" or s == "" then return false end
    local ok = false
    if C_CVar and C_CVar.SetCVar then
        ok = pcall(C_CVar.SetCVar, key, s)
        if ok then return true end
    end
    if type(SetCVar) == "function" then
        ok = pcall(SetCVar, key, s)
        if ok then return true end
    end
    return false
end


local PROTECTED_ENCOUNTER_CVARS = {
    encounterWarningsEnabled = true,
    encounterTimelineEnabled = true,
}

local function GetDesiredEncounterCVarValue(name)
    local key = tostring(name or "")
    local g = EnsureGeneralDB()
    if key == "encounterWarningsEnabled" then
        return (g.encounterWarningsEnabled ~= false) and "1" or "0"
    end
    if key == "encounterTimelineEnabled" then
        return (g.disableBlizzardEncounterTimeline == true) and "0" or "1"
    end
    return nil
end

local function ApplyProtectedEncounterCVar(name)
    local key = tostring(name or "")
    if not PROTECTED_ENCOUNTER_CVARS[key] then
        return
    end
    local desired = GetDesiredEncounterCVarValue(key)
    if not desired then
        return
    end
    local current = ReadGenericCVar(key)
    if current ~= desired then
        WriteGenericCVar(key, desired)
    end
end

local function ScheduleProtectedEncounterCVarRepair(name)
    local key = tostring(name or "")
    if not PROTECTED_ENCOUNTER_CVARS[key] then
        return
    end
    C_Timer.After(0.1, function()
        ApplyProtectedEncounterCVar(key)
    end)
    C_Timer.After(0.5, function()
        ApplyProtectedEncounterCVar(key)
    end)
end

local function ScheduleAllProtectedEncounterCVarRepairs()
    ScheduleProtectedEncounterCVarRepair("encounterWarningsEnabled")
    ScheduleProtectedEncounterCVarRepair("encounterTimelineEnabled")
end

local function GetCAACategoryRange()
    local minValue, maxValue = 0, 8
    local meta = Enum and Enum.CombatAudioAlertCategoryMeta
    if type(meta) == "table" then
        minValue = tonumber(meta.MinValue) or minValue
        maxValue = tonumber(meta.MaxValue) or maxValue
    end
    return minValue, maxValue
end

local function CanUseCAAApi()
    local ok = C_CombatAudioAlert
        and type(C_CombatAudioAlert.GetCategoryVolume) == "function"
        and type(C_CombatAudioAlert.SetCategoryVolume) == "function"
    if not ok then
        CAADebug("C_CombatAudioAlert API unavailable")
    end
    return ok
end

local function MuteCAAByCategoryVolumes()
    if _autoCAAVolumeMuted then
        return true
    end
    if not CanUseCAAApi() then
        return false
    end

    wipe(_autoCAAPrevVolumes)
    local minValue, maxValue = GetCAACategoryRange()
    CAADebug(string.format("Mute categories range: %d..%d", minValue, maxValue))
    local setOK = 0
    local setFail = 0
    for category = minValue, maxValue do
        local okGet, vol = pcall(C_CombatAudioAlert.GetCategoryVolume, category)
        if okGet and tonumber(vol) ~= nil then
            _autoCAAPrevVolumes[category] = tonumber(vol)
        else
            CAADebug(string.format("GetCategoryVolume failed c=%d ok=%s vol=%s", category, tostring(okGet), tostring(vol)))
        end
        local okSet, success = pcall(C_CombatAudioAlert.SetCategoryVolume, category, 0)
        if okSet and success ~= false then
            setOK = setOK + 1
        else
            setFail = setFail + 1
            CAADebug(string.format("SetCategoryVolume(0) failed c=%d ok=%s ret=%s", category, tostring(okSet),
                tostring(success)))
        end
    end
    _autoCAAVolumeMuted = true
    CAADebug(string.format("Mute done: success=%d fail=%d", setOK, setFail))
    return true
end

local function RestoreCAAByCategoryVolumes()
    if not _autoCAAVolumeMuted then
        return true
    end
    if not CanUseCAAApi() then
        return false
    end

    local minValue, maxValue = GetCAACategoryRange()
    CAADebug(string.format("Restore categories range: %d..%d", minValue, maxValue))
    local setOK = 0
    local setFail = 0
    for category = minValue, maxValue do
        local restoreVol = tonumber(_autoCAAPrevVolumes[category])
        if restoreVol == nil then
            local okGet, currentVol = pcall(C_CombatAudioAlert.GetCategoryVolume, category)
            if okGet and tonumber(currentVol) ~= nil then
                restoreVol = tonumber(currentVol)
            else
                restoreVol = 100
            end
        end
        local okSet, success = pcall(C_CombatAudioAlert.SetCategoryVolume, category, restoreVol)
        if okSet and success ~= false then
            setOK = setOK + 1
        else
            setFail = setFail + 1
            CAADebug(string.format("Restore volume failed c=%d v=%s ok=%s ret=%s", category, tostring(restoreVol),
                tostring(okSet), tostring(success)))
        end
    end
    wipe(_autoCAAPrevVolumes)
    _autoCAAVolumeMuted = false
    CAADebug(string.format("Restore done: success=%d fail=%d", setOK, setFail))
    return true
end

function InfinityBoss.ApplyBossAutoCAASetting(forceIsBossEncounter)
    local g = EnsureGeneralDB()
    local enabled = (g.autoDisableCAAInBoss == true)
    local isBoss = (forceIsBossEncounter == true)
    if forceIsBossEncounter == nil and InfinityTools and InfinityTools.State then
        isBoss = (InfinityTools.State.IsBossEncounter == true)
    end
    local shouldMuteBecauseFixed = false
    local muteReason = "n/a"
    if isBoss then
        shouldMuteBecauseFixed, muteReason = IsFixedTimelineEncounterForCAA(_autoCAACurrentEncounterID)
    end
    CAADebug(string.format(
        "Apply: enabled=%s isBoss=%s encounter=%s shouldMute=%s reason=%s muted=%s forced=%s prevCAA=%s",
        tostring(enabled), tostring(isBoss), tostring(_autoCAACurrentEncounterID), tostring(shouldMuteBecauseFixed),
        tostring(muteReason),
        tostring(_autoCAAVolumeMuted), tostring(_autoCAAWasForced), tostring(_autoCAAPrevValue)
    ))

    if not enabled then
        if _autoCAAVolumeMuted then
            CAADebug("Apply -> disabled path: restoring muted categories")
            RestoreCAAByCategoryVolumes()
            _autoCAAWasForced = false
            _autoCAAPrevValue = nil
        elseif _autoCAAWasForced then
            CAADebug("Apply -> disabled path: restoring CAAEnabled fallback")
            WriteCAAEnabled(_autoCAAPrevValue or "1")
            _autoCAAWasForced = false
            _autoCAAPrevValue = nil
        end
        return
    end

    if isBoss and not shouldMuteBecauseFixed then
        CAADebug("Apply -> boss path: current encounter is not fixed-timeline, skip CAA mute")
        if _autoCAAVolumeMuted then
            RestoreCAAByCategoryVolumes()
            _autoCAAWasForced = false
            _autoCAAPrevValue = nil
        elseif _autoCAAWasForced then
            WriteCAAEnabled(_autoCAAPrevValue or "1")
            _autoCAAWasForced = false
            _autoCAAPrevValue = nil
        end
        return
    end

    if isBoss then
        CAADebug("Apply -> boss path: try mute categories")
        local muted = MuteCAAByCategoryVolumes()
        if muted then
            _autoCAAWasForced = true
            CAADebug("Apply -> boss path: category mute success")
            return
        end
        if not _autoCAAWasForced then
            _autoCAAPrevValue = ReadCAAEnabled()
            CAADebug("Apply -> boss path: fallback remember CAAEnabled=" .. tostring(_autoCAAPrevValue))
        end
        WriteCAAEnabled("0")
        _autoCAAWasForced = true
    else
        if _autoCAAVolumeMuted then
            CAADebug("Apply -> leave boss path: restore categories")
            RestoreCAAByCategoryVolumes()
            _autoCAAWasForced = false
            _autoCAAPrevValue = nil
        elseif _autoCAAWasForced then
            CAADebug("Apply -> leave boss path: restore CAAEnabled fallback")
            WriteCAAEnabled(_autoCAAPrevValue or "1")
            _autoCAAWasForced = false
            _autoCAAPrevValue = nil
        end
    end
end

if InfinityTools and InfinityTools.WatchState then
    InfinityTools:WatchState("IsBossEncounter", "InfinityBoss_AutoCAA_Toggle", function(newValue)
        CAADebug("WatchState IsBossEncounter -> " .. tostring(newValue))
        if InfinityBoss and InfinityBoss.ApplyBossAutoCAASetting then
            InfinityBoss.ApplyBossAutoCAASetting(newValue == true)
        end
    end)
    C_Timer.After(0.2, function()
        if InfinityBoss and InfinityBoss.ApplyBossAutoCAASetting then
            InfinityBoss.ApplyBossAutoCAASetting()
        end
    end)
end

InfinityTools:RegisterEvent("ADDON_LOADED", "InfinityBoss_Init_Loaded", function(event, addonName)
    local name = tostring(addonName or ""):lower()
    if name ~= "infinitytools" and name ~= "infinityboss" then return end

    if InfinityBoss.DB and InfinityBoss.DB.Init then
        InfinityBoss.DB:Init()
    end

    if ReadGenericCVar("encounterWarningsEnabled") == nil then
        WriteGenericCVar("encounterWarningsEnabled", "1")
    end
    if ReadGenericCVar("encounterTimelineEnabled") == nil then
        WriteGenericCVar("encounterTimelineEnabled", "1")
    end
    ScheduleAllProtectedEncounterCVarRepairs()

    if type(InfinityBossDataDB) == "table" then
        InfinityBossDataDB.events = InfinityBossDataDB.events or {}
        InfinityBossDataDB.voice = nil
        InfinityBossDataDB.timer = InfinityBossDataDB.timer or {}
        InfinityBossDataDB.timer.skillOverrides = nil
    end

    if type(InfinityBossDB) == "table" and type(InfinityBossDB.voice) == "table" then
        local v                      = InfinityBossDB.voice
        v.events                     = nil
        v.profileBindings            = nil
        v.profileDefaults            = nil
        v.profileDefaultsByScene     = nil
        v.specProfileBindingsByScene = nil
        v._liveEvents                = nil
        if type(v.profiles) == "table" then
            for _, p in pairs(v.profiles) do
                if type(p) == "table" then
                    p.global = nil
                end
            end
        end
    end

    local mecMap = _G.InfinityBoss_S12_MECHANIC_MAP
    local infer = InfinityBossDB and InfinityBossDB.timer and InfinityBossDB.timer.spellInference
    if type(mecMap) == "table" and type(infer) == "table" then
        infer.mappings = infer.mappings or {}
        for encounterID, boss in pairs(mecMap) do
            if type(boss.mechanics) == "table" then
                infer.mappings[encounterID] = infer.mappings[encounterID] or {}
                local existing = {}
                for _, m in ipairs(infer.mappings[encounterID]) do
                    if m.spellID then existing[m.spellID] = true end
                end
                for _, mech in ipairs(boss.mechanics) do
                    local castTime = tonumber(mech.castTime)
                    if castTime and castTime > 0 then
                        for _, spellID in ipairs(mech.fixedSpellIDs or {}) do
                            if not existing[spellID] then
                                table.insert(infer.mappings[encounterID], {
                                    spellID  = spellID,
                                    castTime = castTime,
                                })
                                existing[spellID] = true
                            end
                        end
                    end
                end
            end
        end
    end
end)

InfinityTools:RegisterEvent("CVAR_UPDATE", "InfinityBoss_EncounterCVarGuard", function(event, cvarName)
    local key = tostring(cvarName or "")
    if PROTECTED_ENCOUNTER_CVARS[key] then
        ScheduleProtectedEncounterCVarRepair(key)
    end
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", "InfinityBoss_EncounterCVarGuardPEW", function()
    ScheduleAllProtectedEncounterCVarRepairs()
end)

InfinityTools:RegisterEvent("ADDON_LOADED", "InfinityBoss_EncounterCVarGuardDBM", function(event, addonName)
    local name = tostring(addonName or ""):lower()
    if name == "dbm-core" or name == "dbm-gui" then
        ScheduleAllProtectedEncounterCVarRepairs()
    end
end)

InfinityTools:RegisterEvent("ENCOUNTER_START", "InfinityBoss_Init_EncStart", function(_, encounterID)
    _autoCAACurrentEncounterID = tonumber(encounterID) or encounterID
    if InfinityBoss and InfinityBoss.ApplyBossAutoCAASetting then
        InfinityBoss.ApplyBossAutoCAASetting(true)
    end
    if InfinityBoss and InfinityBoss.ApplyExternalBossModBarVisibility then
        InfinityBoss.ApplyExternalBossModBarVisibility(_autoCAACurrentEncounterID, true)
    end
    if InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler and InfinityBoss.Timeline.Scheduler.HandleEncounterStart then
        InfinityBoss.Timeline.Scheduler:HandleEncounterStart(encounterID, "exwind")
        return
    end
    if InfinityBoss.Timeline.Scheduler and InfinityBoss.Timeline.Scheduler.StartBoss then
        InfinityBoss.Timeline.Scheduler:StartBoss(encounterID)
    end
end)

InfinityTools:RegisterEvent("ENCOUNTER_END", "InfinityBoss_Init_EncEnd", function()
    _autoCAACurrentEncounterID = nil
    if InfinityBoss and InfinityBoss.ApplyBossAutoCAASetting then
        InfinityBoss.ApplyBossAutoCAASetting(false)
    end
    if InfinityBoss and InfinityBoss.ApplyExternalBossModBarVisibility then
        InfinityBoss.ApplyExternalBossModBarVisibility(nil, false)
    end
    if InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler and InfinityBoss.Timeline.Scheduler.HandleEncounterEnd then
        InfinityBoss.Timeline.Scheduler:HandleEncounterEnd("exwind")
        return
    end
    if InfinityBoss.Timeline.Scheduler and InfinityBoss.Timeline.Scheduler.EndBoss then
        InfinityBoss.Timeline.Scheduler:EndBoss()
    end
end)

