---@diagnostic disable: undefined-global, undefined-field, need-check-nil

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

InfinityBoss.UI.Panel.GlobalSettingsPage = InfinityBoss.UI.Panel.GlobalSettingsPage or {}
local Page = InfinityBoss.UI.Panel.GlobalSettingsPage

local leftRoot
local rightRoot
local listScroll
local listChild
local titleText
local titleSep
local descText
local overviewSection
local barModeDropdown
local bossAlertsEnabledMplusCheck
local bossAlertsEnabledRaidCheck
local autoDisableCAAInBossCheck
local encounterWarningsEnabledCheck
local encounterTimelineDisabledCheck
local voiceSection
local voiceRegisterSection
local voiceChannelDrop
local voiceVolumeSlider
local voiceRegisterSummary
local voiceRegisterTime
local voiceRegisterListScroll
local voiceRegisterListChild
local voiceRegisterListText
local colorSection
local embedPlaceholder
local activeButtons = {}
local buttonPool = {}
local selectedIndex = 1

local fixedColorButtons = {}
local fixedColorLabels = {}
local customNameInput
local customColorButton
local extraCustomEnableChecks = {}
local extraCustomNameInputs = {}
local extraCustomColorButtons = {}
local resetSection

local ITEMS = {
    { key = "overview", title = "General Settings", desc = "Global display mode and voice output.", mode = "embedded" },
    { key = "color", title = "General Color Schemes", desc = "4 fixed color schemes + 1 custom scheme + up to 3 extra schemes. The boss spell page can select a scheme or customize colors directly.", mode = "builtin" },
    { key = "timerbar", title = "Timer Bars", desc = "Timer bar appearance, text, and position.", mode = "embedded" },
    { key = "bunbar", title = "Bun Bars", desc = "Bun bar appearance, track, and position.", mode = "embedded" },
    { key = "countdown", title = "Countdown", desc = "Central countdown text, font, and position.", mode = "embedded" },
    { key = "flashtext", title = "Flash Text", desc = "Flash text style and position.", mode = "embedded" },
    { key = "ringprogress", title = "Ring Progress", desc = "Ring progress style, size, and position at screen center.", mode = "embedded" },
    { key = "voiceregister", title = "Voice Register Monitor", desc = "View current voice registration details (non-raid by default): Dungeon > Boss name (count) + eventID (trigger0/1/2).", mode = "builtin" },
    { key = "privateauramonitor", title = "Private Aura Monitor", desc = "Monitor the player's 3 private aura slots with icon size, position, countdown, and sound configuration.", mode = "embedded" },
    { key = "reset", title = "Reset Settings", desc = "Three reset options:\n1) Reset appearance settings only\n2) Reset all config (excluding appearance)\n3) Clear all settings (including appearance)", mode = "builtin" },
}

local CHANNEL_OPTIONS = {
    { "Master", "Master" },
    { "SFX", "SFX" },
    { "Dialog", "Dialog" },
    { "Music", "Music" },
    { "Ambience", "Ambience" },
}

local BAR_MODE_OPTIONS = {
    { "Bun Bars Only", "bun" },
    { "Both Enabled",  "both" },
    { "Timer Bars Only","timer" },
    { "Both Hidden",   "none" },
}

local FALLBACK_SCHEME_ORDER = { "tank", "heal", "cooldown", "mechanic" }
local FALLBACK_SCHEME_NAMES = {
    tank = "Tank Scheme",
    heal = "Heal Scheme",
    cooldown = "Other Scheme",
    mechanic = "Special Mechanic",
}
local EXTRA_CUSTOM_COUNT_FALLBACK = 3

local function GetColorModule()
    return InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ColorSchemes
end

local function EnsureVoiceDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    InfinityBossDB.voice.global = InfinityBossDB.voice.global or {}

    local CS = GetColorModule()
    if CS and CS.EnsureDB then
        CS.EnsureDB()
    end

    local g = InfinityBossDB.voice.global
    g.channel = g.channel or "Master"
    g.volume = tonumber(g.volume) or 1.0
    return g
end

local function NormalizeBarDisplayMode(mode)
    local m = tostring(mode or ""):lower()
    if m == "timer" or m == "bun" or m == "both" or m == "none" then
        return m
    end
    return "bun"
end

local function EnsureGeneralDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    local g = InfinityBossDB.ui.general
    if g.bossAlertsEnabledMplus == nil then
        g.bossAlertsEnabledMplus = true
    else
        g.bossAlertsEnabledMplus = (g.bossAlertsEnabledMplus == true)
    end
    if g.bossAlertsEnabledRaid == nil then
        g.bossAlertsEnabledRaid = true
    else
        g.bossAlertsEnabledRaid = (g.bossAlertsEnabledRaid == true)
    end
    g.barDisplayMode = NormalizeBarDisplayMode(g.barDisplayMode)
    if g.autoDisableCAAInBoss == nil then
        g.autoDisableCAAInBoss = false
    else
        g.autoDisableCAAInBoss = (g.autoDisableCAAInBoss == true)
    end
    return g
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
    local s = tostring(value)
    if s == "" then
        return nil
    end
    return s
end

local function WriteCVarValue(name, value)
    local key = tostring(name or "")
    if key == "" then
        return false
    end
    local s = tostring(value or "")
    if s == "" then
        return false
    end

    local ok = false
    if C_CVar and C_CVar.SetCVar then
        ok = pcall(C_CVar.SetCVar, key, s)
        if ok then
            return true
        end
    end
    if type(SetCVar) == "function" then
        ok = pcall(SetCVar, key, s)
        if ok then
            return true
        end
    end
    return false
end

local function IsEncounterWarningsEnabled()
    local value = ReadCVarValue("encounterWarningsEnabled")
    if value == nil then
        WriteCVarValue("encounterWarningsEnabled", "1")
        return true
    end
    return value ~= "0"
end

local function IsEncounterTimelineEnabled()
    local value = ReadCVarValue("encounterTimelineEnabled")
    if value == nil then
        WriteCVarValue("encounterTimelineEnabled", "1")
        return true
    end
    return value ~= "0"
end

local function SetEncounterWarningsEnabled(enabled)
    WriteCVarValue("encounterWarningsEnabled", enabled and "1" or "0")
end

local function SetEncounterTimelineEnabled(enabled)
    WriteCVarValue("encounterTimelineEnabled", enabled and "1" or "0")
end

local function IsTimerBarEnabledByGlobal()
    local g = EnsureGeneralDB()
    local mode = NormalizeBarDisplayMode(g.barDisplayMode)
    return mode == "both" or mode == "timer"
end

local function IsBunBarEnabledByGlobal()
    local g = EnsureGeneralDB()
    local mode = NormalizeBarDisplayMode(g.barDisplayMode)
    return mode == "both" or mode == "bun"
end

local function RefreshGeneralControls()
    local g = EnsureGeneralDB()
    if barModeDropdown then
        local mode = NormalizeBarDisplayMode(g.barDisplayMode)
        barModeDropdown._currentValue = mode
        local label = "Bun Bars Only"
        for _, item in ipairs(BAR_MODE_OPTIONS) do
            if item[2] == mode then
                label = item[1]
                break
            end
        end
        barModeDropdown:SetText(label)
    end
    if bossAlertsEnabledMplusCheck and bossAlertsEnabledMplusCheck.SetChecked then
        bossAlertsEnabledMplusCheck:SetChecked(g.bossAlertsEnabledMplus == true)
    end
    if bossAlertsEnabledRaidCheck and bossAlertsEnabledRaidCheck.SetChecked then
        bossAlertsEnabledRaidCheck:SetChecked(g.bossAlertsEnabledRaid == true)
    end
    if autoDisableCAAInBossCheck and autoDisableCAAInBossCheck.SetChecked then
        autoDisableCAAInBossCheck:SetChecked(g.autoDisableCAAInBoss == true)
    end
    if encounterWarningsEnabledCheck and encounterWarningsEnabledCheck.SetChecked then
        encounterWarningsEnabledCheck:SetChecked(IsEncounterWarningsEnabled())
    end
    if encounterTimelineDisabledCheck and encounterTimelineDisabledCheck.SetChecked then
        encounterTimelineDisabledCheck:SetChecked(not IsEncounterTimelineEnabled())
    end
end

local function ApplyBossSceneToggleChange()
    local sched = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
    local bossCfg = InfinityBoss and InfinityBoss.BossConfig
    local sceneEnabled = true
    if bossCfg and type(bossCfg.IsCurrentSceneEnabled) == "function" then
        local ok, enabled = pcall(bossCfg.IsCurrentSceneEnabled, bossCfg)
        if ok then
            sceneEnabled = (enabled ~= false)
        end
    end

    if sceneEnabled == false then
        if sched and sched.EndBoss then
            sched:EndBoss()
        end
        if InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine and InfinityBoss.Voice.Engine.ClearEventOverridesInMemory then
            InfinityBoss.Voice.Engine:ClearEventOverridesInMemory("boss scene disabled")
        end
    elseif sched and sched._running and sched.StartBoss and sched._encounterID then
        sched:StartBoss(sched._encounterID)
    end

    if InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine and InfinityBoss.Voice.Engine.ApplyEventOverridesToAPI then
        InfinityBoss.Voice.Engine:ApplyEventOverridesToAPI()
    end
end

local function ApplyBarModeChange()
    if not IsBunBarEnabledByGlobal() and InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.ReleaseAll then
        InfinityBoss.UI.BunBar:ReleaseAll()
    end
    if not IsTimerBarEnabledByGlobal() and InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.ReleaseAll then
        InfinityBoss.UI.TimerBar:ReleaseAll()
    end

    local sched = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
    if sched and sched._running and sched.StartBoss and sched._encounterID then
        sched:StartBoss(sched._encounterID)
    end
end

local function EnsureColorDB()
    local CS = GetColorModule()
    if CS and CS.EnsureDB then
        local db = CS.EnsureDB()
        local custom = (db.customColors and db.customColors[1]) or {}
        return db, db.colorSchemes or {}, custom, db.extraCustomColors or {}
    end

    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    InfinityBossDB.voice.colorSchemes = InfinityBossDB.voice.colorSchemes or {}
    InfinityBossDB.voice.customColors = InfinityBossDB.voice.customColors or {}
    InfinityBossDB.voice.extraCustomColors = InfinityBossDB.voice.extraCustomColors or {}
    InfinityBossDB.voice.customColors[1] = InfinityBossDB.voice.customColors[1] or { name = "Custom Scheme", r = 1, g = 0.82, b = 0.25 }

    for i = 1, EXTRA_CUSTOM_COUNT_FALLBACK do
        local row = InfinityBossDB.voice.extraCustomColors[i]
        if type(row) ~= "table" then
            InfinityBossDB.voice.extraCustomColors[i] = {
                enabled = false,
                name = "Extra Scheme " .. tostring(i),
                r = 1,
                g = 0.82,
                b = 0.25,
            }
        else
            if row.enabled == nil then row.enabled = false end
            if type(row.name) ~= "string" or row.name == "" then
                row.name = "Extra Scheme " .. tostring(i)
            end
            row.r = tonumber(row.r) or 1
            row.g = tonumber(row.g) or 0.82
            row.b = tonumber(row.b) or 0.25
        end
    end

    for _, key in ipairs(FALLBACK_SCHEME_ORDER) do
        local row = InfinityBossDB.voice.colorSchemes[key]
        if type(row) ~= "table" then
            InfinityBossDB.voice.colorSchemes[key] = {
                name = FALLBACK_SCHEME_NAMES[key],
                r = 1,
                g = 1,
                b = 1,
            }
        end
    end

    return InfinityBossDB.voice, InfinityBossDB.voice.colorSchemes, InfinityBossDB.voice.customColors[1], InfinityBossDB.voice.extraCustomColors
end

local function GetSchemeOrder()
    local CS = GetColorModule()
    if CS and CS.GetFixedOrder then
        return CS.GetFixedOrder()
    end
    return FALLBACK_SCHEME_ORDER
end

local function GetSchemeDisplayName(key)
    local CS = GetColorModule()
    if CS and CS.GetSchemeDisplayName then
        return CS.GetSchemeDisplayName(key)
    end
    return FALLBACK_SCHEME_NAMES[key] or tostring(key or "")
end

local function GetExtraCustomCount()
    local CS = GetColorModule()
    if CS and CS.GetExtraCustomCount then
        return tonumber(CS.GetExtraCustomCount()) or EXTRA_CUSTOM_COUNT_FALLBACK
    end
    return EXTRA_CUSTOM_COUNT_FALLBACK
end

local function ApplyVoiceOverrides()
    if InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine and InfinityBoss.Voice.Engine.ApplyEventOverridesToAPI then
        InfinityBoss.Voice.Engine:ApplyEventOverridesToAPI()
    end
end

local STYLE_MODULE_KEYS = {
    "InfinityBoss.TimerBar",
    "InfinityBoss.BunBar",
    "InfinityBoss.Countdown",
    "InfinityBoss.FlashText",
    "InfinityBoss.RingProgress",
}

local InfinityBoss_MODULE_KEYS = {
    "InfinityBoss.TimerBar",
    "InfinityBoss.BunBar",
    "InfinityBoss.Countdown",
    "InfinityBoss.FlashText",
    "InfinityBoss.RingProgress",
    "InfinityBoss.BossSpellOptions",
}

local STYLE_MODULE_KEY_SET = {
    ["InfinityBoss.TimerBar"] = true,
    ["InfinityBoss.BunBar"] = true,
    ["InfinityBoss.Countdown"] = true,
    ["InfinityBoss.FlashText"] = true,
    ["InfinityBoss.RingProgress"] = true,
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[DeepCopy(k)] = DeepCopy(v)
    end
    return out
end

local function CaptureAppearanceSnapshot()
    local snap = {
        timer = {},
        voice = {},
        moduleDB = {},
    }

    if type(InfinityBossDB) == "table" then
        local timer = type(InfinityBossDB.timer) == "table" and InfinityBossDB.timer or nil
        if timer then
            if timer.timerBar ~= nil then snap.timer.timerBar = DeepCopy(timer.timerBar) end
            if timer.bunBar ~= nil then snap.timer.bunBar = DeepCopy(timer.bunBar) end
            if timer.countdown ~= nil then snap.timer.countdown = DeepCopy(timer.countdown) end
            if timer.flashText ~= nil then snap.timer.flashText = DeepCopy(timer.flashText) end
            if timer.ringProgress ~= nil then snap.timer.ringProgress = DeepCopy(timer.ringProgress) end
        end

        local voice = type(InfinityBossDB.voice) == "table" and InfinityBossDB.voice or nil
        if voice then
            if voice.colorSchemes ~= nil then snap.voice.colorSchemes = DeepCopy(voice.colorSchemes) end
            if voice.customColors ~= nil then snap.voice.customColors = DeepCopy(voice.customColors) end
            if voice.extraCustomColors ~= nil then snap.voice.extraCustomColors = DeepCopy(voice.extraCustomColors) end
        end
    end

    if type(InfinityToolsDB) == "table" and type(InfinityToolsDB.ModuleDB) == "table" then
        for _, key in ipairs(STYLE_MODULE_KEYS) do
            if InfinityToolsDB.ModuleDB[key] ~= nil then
                snap.moduleDB[key] = DeepCopy(InfinityToolsDB.ModuleDB[key])
            end
        end
    end

    return snap
end

local function RestoreAppearanceSnapshot(snap)
    if type(snap) ~= "table" then
        return
    end

    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}

    InfinityBossDB.timer.timerBar = DeepCopy(snap.timer and snap.timer.timerBar)
    InfinityBossDB.timer.bunBar = DeepCopy(snap.timer and snap.timer.bunBar)
    InfinityBossDB.timer.countdown = DeepCopy(snap.timer and snap.timer.countdown)
    InfinityBossDB.timer.flashText = DeepCopy(snap.timer and snap.timer.flashText)
    InfinityBossDB.timer.ringProgress = DeepCopy(snap.timer and snap.timer.ringProgress)
    InfinityBossDB.voice.colorSchemes = DeepCopy(snap.voice and snap.voice.colorSchemes)
    InfinityBossDB.voice.customColors = DeepCopy(snap.voice and snap.voice.customColors)
    InfinityBossDB.voice.extraCustomColors = DeepCopy(snap.voice and snap.voice.extraCustomColors)

    InfinityToolsDB = InfinityToolsDB or {}
    InfinityToolsDB.ModuleDB = InfinityToolsDB.ModuleDB or {}
    for _, key in ipairs(STYLE_MODULE_KEYS) do
        InfinityToolsDB.ModuleDB[key] = nil
    end
    if type(snap.moduleDB) == "table" then
        for key, value in pairs(snap.moduleDB) do
            InfinityToolsDB.ModuleDB[key] = DeepCopy(value)
        end
    end
end

local function ClearInfinityBossModuleDB(preserveAppearanceModules)
    if type(InfinityToolsDB) ~= "table" or type(InfinityToolsDB.ModuleDB) ~= "table" then
        return
    end
    for _, key in ipairs(InfinityBoss_MODULE_KEYS) do
        if not (preserveAppearanceModules and STYLE_MODULE_KEY_SET[key]) then
            InfinityToolsDB.ModuleDB[key] = nil
        end
    end
end

local function ResetDisplayStylesOnly()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    InfinityBossDB.timer.timerBar = nil
    InfinityBossDB.timer.bunBar = nil
    InfinityBossDB.timer.countdown = nil
    InfinityBossDB.timer.flashText = nil
    InfinityBossDB.timer.ringProgress = nil

    if InfinityToolsDB and type(InfinityToolsDB.ModuleDB) == "table" then
        for _, key in ipairs(STYLE_MODULE_KEYS) do
            InfinityToolsDB.ModuleDB[key] = nil
        end
    end

    if InfinityBoss and InfinityBoss.UI then
        if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.RefreshVisuals then
            InfinityBoss.UI.TimerBar:RefreshVisuals()
        end
        if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.RefreshVisuals then
            InfinityBoss.UI.BunBar:RefreshVisuals()
        end
        if InfinityBoss.UI.Countdown and InfinityBoss.UI.Countdown.RefreshVisuals then
            InfinityBoss.UI.Countdown:RefreshVisuals()
        end
        if InfinityBoss.UI.FlashText and InfinityBoss.UI.FlashText.RefreshVisuals then
            InfinityBoss.UI.FlashText:RefreshVisuals()
        end
        if InfinityBoss.UI.RingProgress and InfinityBoss.UI.RingProgress.RefreshVisuals then
            InfinityBoss.UI.RingProgress:RefreshVisuals()
        end
    end
end

local function ResetAllConfigExceptAppearance()
    local appearance = CaptureAppearanceSnapshot()

    InfinityBossDB = {}
    InfinityBossDataDB = nil
    ClearInfinityBossModuleDB(false)

    RestoreAppearanceSnapshot(appearance)
end

local function ResetAllConfigIncludingAppearance()
    InfinityBossDB = nil
    InfinityBossDataDB = nil
    ClearInfinityBossModuleDB(false)
end

local function RefreshVoiceControls()
    local g = EnsureVoiceDB()
    if voiceChannelDrop then
        voiceChannelDrop._currentValue = g.channel
        local label = g.channel
        for _, item in ipairs(CHANNEL_OPTIONS) do
            if item[2] == g.channel then
                label = item[1]
                break
            end
        end
        voiceChannelDrop:SetText(label or "Master")
    end
    if voiceVolumeSlider then
        if voiceVolumeSlider.Init then
            voiceVolumeSlider:Init(g.volume, 0, 1, 100)
        else
            voiceVolumeSlider:SetValue(g.volume)
        end
    end
end

local function RefreshVoiceRegisterMonitor()
    if not (voiceRegisterSummary and voiceRegisterTime and voiceRegisterListText and voiceRegisterListChild and voiceRegisterListScroll) then
        return
    end

    local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    if not (Engine and Engine.GetRegistrationSnapshot) then
        voiceRegisterSummary:SetText("Voice engine not ready, cannot read registration status.")
        voiceRegisterTime:SetText("")
        voiceRegisterListText:SetText("No data")
        voiceRegisterListChild:SetHeight(24)
        return
    end

    local snap = Engine:GetRegistrationSnapshot({ includeRaid = false })
    if type(snap) ~= "table" then
        voiceRegisterSummary:SetText("Voice registration snapshot is empty.")
        voiceRegisterTime:SetText("")
        voiceRegisterListText:SetText("No data")
        voiceRegisterListChild:SetHeight(24)
        return
    end

    local bossCount = tonumber(snap.bossCount) or 0
    local eventCount = tonumber(snap.eventCount) or 0
    local rawEventCount = tonumber(snap.rawEventCount) or eventCount
    local trigger0Events = tonumber(snap.trigger0Events) or 0
    local trigger1Events = tonumber(snap.trigger1Events) or 0
    local trigger2Events = tonumber(snap.trigger2Events) or 0
    local orphanCount = tonumber(snap.orphanEventCount) or 0
    local filteredByRaid = tonumber(snap.filteredOutByRaid) or 0
    local extra = ""
    if orphanCount > 0 then
        extra = string.format("  |  unmatched boss events: %d", orphanCount)
    end
    if filteredByRaid > 0 then
        extra = extra .. string.format("  |  raid filtered: %d", filteredByRaid)
    end
    voiceRegisterSummary:SetText(string.format("Non-raid registered bosses: %d  |  Non-raid events: %d / total: %d  |  triggers (0/1/2): %d/%d/%d%s",
        bossCount, eventCount, rawEventCount, trigger0Events, trigger1Events, trigger2Events, extra))

    local stamp = tostring(snap.updatedAt or "")
    if stamp == "" then
        stamp = "Unknown"
    end
    local modeSuffix = (snap.isPreview == true) and " (estimated)" or " (measured)"
    local errSuffix = ""
    if type(snap.error) == "string" and snap.error ~= "" then
        errSuffix = "  |  last error: " .. snap.error
    end
    local scopeText = ""
    local scopeMapName = tostring(snap.scopeMapName or "")
    local scopeInstanceID = tonumber(snap.scopeInstanceID)
    local scopeEncounterID = tonumber(snap.scopeEncounterID)
    if scopeInstanceID and scopeInstanceID > 0 then
        scopeText = string.format("  |  scope: %s[InstanceID:%d]", (scopeMapName ~= "" and scopeMapName or "Unknown Dungeon"), scopeInstanceID)
        if scopeEncounterID and scopeEncounterID > 0 then
            scopeText = scopeText .. string.format(" > encounter:%d", scopeEncounterID)
        end
    end
    voiceRegisterTime:SetText("Last refresh: " .. stamp .. modeSuffix .. scopeText .. errSuffix)

    local lines = {}
    local rows = snap.rows
    if type(rows) == "table" and #rows > 0 then
        for i = 1, #rows do
            local row = rows[i]
            local bossName = tostring(row and row.bossName or ("Unknown Boss " .. tostring(row and row.encounterID or i)))
            local n = tonumber(row and row.count) or 0
            local mapName = tostring(row and row.mapName or "Unknown Dungeon")
            local eventIDs = row and row.eventIDs
            local eventDetails = row and row.eventDetails
            local detail = ""
            if type(eventDetails) == "table" and #eventDetails > 0 then
                local chunks = {}
                for j = 1, #eventDetails do
                    local d = eventDetails[j]
                    local eid = tonumber(d and d.eventID) or (d and d.eventID) or "?"
                    local triggerText = tostring(d and d.triggerText or "-")
                    chunks[#chunks + 1] = string.format("%s(%s)", tostring(eid), triggerText)
                end
                detail = "  [eventID(trigger): " .. table.concat(chunks, ",") .. "]"
            elseif type(eventIDs) == "table" and #eventIDs > 0 then
                local ids = {}
                for j = 1, #eventIDs do
                    ids[#ids + 1] = tostring(eventIDs[j]) .. "(-)"
                end
                detail = "  [eventID(trigger): " .. table.concat(ids, ",") .. "]"
            end
            lines[#lines + 1] = string.format("%s > %s (%d)%s", mapName, bossName, n, detail)
        end
    else
        lines[1] = "No non-raid registered bosses"
    end

    local text = table.concat(lines, "\n")
    voiceRegisterListText:SetText(text)

    local w = (voiceRegisterListScroll:GetWidth() or 540) - 26
    if w < 120 then w = 120 end
    voiceRegisterListChild:SetWidth(w)
    voiceRegisterListText:SetWidth(w - 6)
    voiceRegisterListChild:SetHeight(math.max(24, (#lines * 20) + 8))
end

local function RefreshColorControls()
    local _, schemes, custom, extraSlots = EnsureColorDB()
    for _, key in ipairs(GetSchemeOrder()) do
        local btn = fixedColorButtons[key]
        local nameFS = fixedColorLabels[key]
        local row = schemes and schemes[key]
        if btn and type(row) == "table" then
            btn._currentDb = row
            if btn.UpdateColor then
                btn:UpdateColor(row.r, row.g, row.b, 1)
            end
        end
        if nameFS then
            nameFS:SetText(GetSchemeDisplayName(key))
        end
    end

    if customNameInput and type(custom) == "table" then
        if not customNameInput:HasFocus() then
            customNameInput:SetText(custom.name or "Custom Scheme")
        end
    end
    if customColorButton and type(custom) == "table" then
        customColorButton._currentDb = custom
        if customColorButton.UpdateColor then
            customColorButton:UpdateColor(custom.r, custom.g, custom.b, 1)
        end
    end

    for i = 1, GetExtraCustomCount() do
        local row = type(extraSlots) == "table" and extraSlots[i] or nil
        local cb = extraCustomEnableChecks[i]
        local nameInput = extraCustomNameInputs[i]
        local colorBtn = extraCustomColorButtons[i]
        if cb and cb.SetChecked then
            cb:SetChecked(row and row.enabled == true)
        end
        if nameInput and type(row) == "table" then
            if not nameInput:HasFocus() then
                nameInput:SetText(row.name or ("Extra Scheme " .. tostring(i)))
            end
        end
        if colorBtn and type(row) == "table" then
            colorBtn._currentDb = row
            if colorBtn.UpdateColor then
                colorBtn:UpdateColor(row.r, row.g, row.b, 1)
            end
        end
    end
end

local function ClearButtons()
    for _, b in ipairs(activeButtons) do
        b:Hide()
        b:ClearAllPoints()
        buttonPool[#buttonPool + 1] = b
    end
    wipe(activeButtons)
end

local function AcquireListButton()
    local b = table.remove(buttonPool)
    if b then
        b:SetParent(listChild)
        return b
    end

    b = CreateFrame("Button", nil, listChild, "BackdropTemplate")
    b:SetHeight(28)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    b.fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.fs:SetPoint("LEFT", 8, 0)
    b.fs:SetPoint("RIGHT", -8, 0)
    b.fs:SetJustifyH("LEFT")
    return b
end

local function HideEmbeddedPages()
    local pages = {
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.GeneralOverviewPage,
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.TimerBarPage,
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.BunBarPage,
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.CountdownPage,
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.FlashTextPage,
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.RingProgressPage,
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.ImportExportPage,
        InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.PrivateAuraMonitorPage,
    }
    for _, page in ipairs(pages) do
        if page and page._scrollFrame then
            page._scrollFrame:Hide()
            if InfinityTools.UI and InfinityTools.UI.ActivePageFrame == page._scrollChild then
                InfinityTools.UI.ActivePageFrame = nil
                InfinityTools.UI.CurrentModule = nil
            end
        end
    end
end

local function ShowBuiltinLayout(show)
    if titleText then
        if show then titleText:Show() else titleText:Hide() end
    end
    if titleSep then
        if show then titleSep:Show() else titleSep:Hide() end
    end
    if descText then
        if show then descText:Show() else descText:Hide() end
    end
end

local function RefreshRight()
    local item = ITEMS[selectedIndex] or ITEMS[1]
    local key = item and item.key or "overview"

    HideEmbeddedPages()
    if overviewSection then overviewSection:Hide() end
    if voiceSection then voiceSection:Hide() end
    if voiceRegisterSection then voiceRegisterSection:Hide() end
    if colorSection then colorSection:Hide() end
    if resetSection then resetSection:Hide() end
    if embedPlaceholder then embedPlaceholder:Hide() end

    if item and item.mode == "embedded" then
        ShowBuiltinLayout(false)

        local pageMap = {
            overview = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.GeneralOverviewPage,
            timerbar = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.TimerBarPage,
            bunbar = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.BunBarPage,
            countdown = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.CountdownPage,
            flashtext = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.FlashTextPage,
            ringprogress         = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.RingProgressPage,
            privateauramonitor   = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.PrivateAuraMonitorPage,
        }
        local page = pageMap[key]
        if page and page.Render then
            page:Render(rightRoot)
        elseif embedPlaceholder then
            embedPlaceholder:SetText((item.title or "Settings") .. " not ready")
            embedPlaceholder:Show()
        end
        return
    end

    ShowBuiltinLayout(true)
    if titleText then
        titleText:SetText(item and item.title or "General Settings")
    end
    if descText then
        descText:SetText(item and item.desc or "")
    end

    if key == "overview" then
        if overviewSection then overviewSection:Show() end
    elseif key == "voice" then
        if voiceSection then voiceSection:Show() end
    elseif key == "voiceregister" then
        if voiceRegisterSection then
            voiceRegisterSection:Show()
            RefreshVoiceRegisterMonitor()
        end
    elseif key == "color" then
        if colorSection then colorSection:Show() end
    elseif key == "reset" then
        if resetSection then resetSection:Show() end
    end
end

local function RefreshList()
    if not listChild then return end
    ClearButtons()

    local y = -6
    for i, item in ipairs(ITEMS) do
        local b = AcquireListButton()
        b:SetPoint("TOPLEFT", 4, y)
        b:SetPoint("RIGHT", listChild, "RIGHT", -4, 0)

        local active = (i == selectedIndex)
        if active then
            b:SetBackdropColor(0.12, 0.32, 0.58, 0.85)
            b:SetBackdropBorderColor(0.2, 0.65, 1, 1)
        else
            b:SetBackdropColor(0.05, 0.05, 0.06, 0.7)
            b:SetBackdropBorderColor(0.32, 0.32, 0.36, 0.9)
        end

        local fs = b.fs
        fs:SetText(item.title or ("Item " .. tostring(i)))
        fs:SetTextColor(active and 1 or 0.85, active and 0.9 or 0.85, active and 0.5 or 0.85)

        b:SetScript("OnClick", function()
            selectedIndex = i
            RefreshList()
            RefreshRight()
        end)

        activeButtons[#activeButtons + 1] = b
        b:Show()
        y = y - 30
    end

    listChild:SetHeight(math.max(1, -y + 8))
end

local function EnsureUI(leftFrame, contentFrame)
    if leftRoot and rightRoot then return end

    leftRoot = CreateFrame("Frame", nil, leftFrame)
    leftRoot:SetAllPoints(leftFrame)

    local lt = leftRoot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lt:SetPoint("TOPLEFT", 10, -10)
    lt:SetText("General Settings")
    lt:SetTextColor(0.733, 0.4, 1.0)
    lt:SetFont(InfinityTools.MAIN_FONT, 14, "OUTLINE")
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(lt, "text") end

    listScroll = CreateFrame("ScrollFrame", nil, leftRoot, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(listScroll)
    end
    listScroll:SetPoint("TOPLEFT", leftRoot, "TOPLEFT", 4, -32)
    listScroll:SetPoint("BOTTOMRIGHT", leftRoot, "BOTTOMRIGHT", -22, 8)

    listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetSize(200, 1)
    listScroll:SetScrollChild(listChild)

    rightRoot = CreateFrame("Frame", nil, contentFrame)
    rightRoot:SetAllPoints(contentFrame)

    titleText = rightRoot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 14, -14)
    titleText:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(titleText, "text") end

    local sep = rightRoot:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -8)
    sep:SetPoint("TOPRIGHT", rightRoot, "TOPRIGHT", -12, -8)
    sep:SetHeight(1)
    sep:SetColorTexture(1, 1, 1, 0.18)
    titleSep = sep

    descText = rightRoot:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    descText:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 0, -10)
    descText:SetPoint("RIGHT", rightRoot, "RIGHT", -14, 0)
    descText:SetJustifyH("LEFT")
    descText:SetJustifyV("TOP")
    descText:SetWordWrap(true)
    descText:SetTextColor(0.88, 0.88, 0.9)

    embedPlaceholder = rightRoot:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    embedPlaceholder:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -14)
    embedPlaceholder:SetPoint("RIGHT", rightRoot, "RIGHT", -14, 0)
    embedPlaceholder:SetJustifyH("LEFT")
    embedPlaceholder:SetTextColor(0.75, 0.75, 0.8, 1)
    embedPlaceholder:Hide()

    local InfinityUI = InfinityTools.UI

    overviewSection = CreateFrame("Frame", nil, rightRoot, "BackdropTemplate")
    overviewSection:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -12)
    overviewSection:SetPoint("TOPRIGHT", rightRoot, "TOPRIGHT", -14, 0)
    overviewSection:SetHeight(306)
    overviewSection:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    overviewSection:SetBackdropColor(0.03, 0.04, 0.06, 0.82)
    overviewSection:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.95)

    local overviewTitle = overviewSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    overviewTitle:SetPoint("TOPLEFT", 10, -8)
    overviewTitle:SetText("Global Bar Display Mode")
    overviewTitle:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(overviewTitle, "text") end

    if InfinityUI and InfinityUI.CreateDropdown then
        barModeDropdown = InfinityUI:CreateDropdown(
            overviewSection,
            220,
            "Display Mode",
            BAR_MODE_OPTIONS,
            EnsureGeneralDB().barDisplayMode,
            function(val)
                local g = EnsureGeneralDB()
                g.barDisplayMode = NormalizeBarDisplayMode(val)
                RefreshGeneralControls()
                ApplyBarModeChange()
            end
        )
        barModeDropdown:SetPoint("TOPLEFT", 10, -36)
    end

    if InfinityUI and InfinityUI.CreateCheckbox then
        bossAlertsEnabledMplusCheck = InfinityUI:CreateCheckbox(
            overviewSection,
            "Enable M+ Boss Alerts",
            EnsureGeneralDB().bossAlertsEnabledMplus == true,
            function(checked)
                local g = EnsureGeneralDB()
                g.bossAlertsEnabledMplus = (checked == true)
                RefreshGeneralControls()
                ApplyBossSceneToggleChange()
            end
        )
        bossAlertsEnabledMplusCheck:SetPoint("TOPLEFT", 10, -72)
    end

    if InfinityUI and InfinityUI.CreateCheckbox then
        bossAlertsEnabledRaidCheck = InfinityUI:CreateCheckbox(
            overviewSection,
            "Enable Raid Boss Alerts",
            EnsureGeneralDB().bossAlertsEnabledRaid == true,
            function(checked)
                local g = EnsureGeneralDB()
                g.bossAlertsEnabledRaid = (checked == true)
                RefreshGeneralControls()
                ApplyBossSceneToggleChange()
            end
        )
        bossAlertsEnabledRaidCheck:SetPoint("TOPLEFT", 10, -106)
    end

    if InfinityUI and InfinityUI.CreateCheckbox then
        autoDisableCAAInBossCheck = InfinityUI:CreateCheckbox(
            overviewSection,
            "Auto-Disable Combat Audio Alerts in Boss",
            EnsureGeneralDB().autoDisableCAAInBoss == true,
            function(checked)
                local g = EnsureGeneralDB()
                g.autoDisableCAAInBoss = (checked == true)
                RefreshGeneralControls()
                if InfinityBoss and InfinityBoss.ApplyBossAutoCAASetting then
                    InfinityBoss.ApplyBossAutoCAASetting()
                end
            end
        )
        autoDisableCAAInBossCheck:SetPoint("TOPLEFT", 10, -140)
    end

    if InfinityUI and InfinityUI.CreateCheckbox then
        encounterWarningsEnabledCheck = InfinityUI:CreateCheckbox(
            overviewSection,
            "Enable Center-Text Alerts (Warning: disabling breaks voice)",
            IsEncounterWarningsEnabled(),
            function(checked)
                SetEncounterWarningsEnabled(checked == true)
                RefreshGeneralControls()
            end
        )
        encounterWarningsEnabledCheck:SetPoint("TOPLEFT", 10, -174)
    end

    if InfinityUI and InfinityUI.CreateCheckbox then
        encounterTimelineDisabledCheck = InfinityUI:CreateCheckbox(
            overviewSection,
            "Disable Blizzard Timeline",
            not IsEncounterTimelineEnabled(),
            function(checked)
                SetEncounterTimelineEnabled(not (checked == true))
                RefreshGeneralControls()
            end
        )
        encounterTimelineDisabledCheck:SetPoint("TOPLEFT", 10, -208)
    end

    local overviewDesc = overviewSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    overviewDesc:SetPoint("TOPLEFT", 10, -244)
    overviewDesc:SetPoint("RIGHT", overviewSection, "RIGHT", -10, 0)
    overviewDesc:SetJustifyH("LEFT")
    overviewDesc:SetTextColor(0.85, 0.85, 0.9)
    overviewDesc:SetText("Control global display: Timer Bars only / Bun Bars only / Both enabled / Both hidden.\nYou can disable M+ or Raid boss alerts independently; disabling a scene turns off its boss timers, center text, voice, and color overlays.\nOptional: auto-mute combat audio alert channel volume (to 0) during boss fights, restoring it on exit.")
    overviewSection:Hide()

    voiceSection = CreateFrame("Frame", nil, rightRoot, "BackdropTemplate")
    voiceSection:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -12)
    voiceSection:SetPoint("TOPRIGHT", rightRoot, "TOPRIGHT", -14, 0)
    voiceSection:SetHeight(120)
    voiceSection:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    voiceSection:SetBackdropColor(0.03, 0.04, 0.06, 0.82)
    voiceSection:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.95)

    local voiceTitle = voiceSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    voiceTitle:SetPoint("TOPLEFT", 10, -8)
    voiceTitle:SetText("Global Voice Output")
    voiceTitle:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(voiceTitle, "text") end

    if InfinityUI and InfinityUI.CreateDropdown then
        voiceChannelDrop = InfinityUI:CreateDropdown(
            voiceSection,
            180,
            "Output Channel",
            CHANNEL_OPTIONS,
            EnsureVoiceDB().channel,
            function(val)
                local g = EnsureVoiceDB()
                g.channel = tostring(val or "Master")
                ApplyVoiceOverrides()
            end
        )
        voiceChannelDrop:SetPoint("TOPLEFT", 10, -34)
    end

    if InfinityUI and InfinityUI.CreateSlider then
        voiceVolumeSlider = InfinityUI:CreateSlider(
            voiceSection,
            300,
            "Global Volume",
            0,
            1,
            EnsureVoiceDB().volume,
            0.01,
            function(v) return string.format("%.2f", v) end,
            function(v)
                local g = EnsureVoiceDB()
                g.volume = tonumber(string.format("%.2f", v)) or 1.0
                ApplyVoiceOverrides()
            end
        )
        voiceVolumeSlider:SetPoint("TOPLEFT", 10, -78)
    end
    voiceSection:Hide()

    voiceRegisterSection = CreateFrame("Frame", nil, rightRoot, "BackdropTemplate")
    voiceRegisterSection:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -12)
    voiceRegisterSection:SetPoint("TOPRIGHT", rightRoot, "TOPRIGHT", -14, 0)
    voiceRegisterSection:SetHeight(520)
    voiceRegisterSection:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    voiceRegisterSection:SetBackdropColor(0.03, 0.04, 0.06, 0.82)
    voiceRegisterSection:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.95)

    local monitorTitle = voiceRegisterSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    monitorTitle:SetPoint("TOPLEFT", 10, -8)
    monitorTitle:SetText("Current Voice Registration Status")
    monitorTitle:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(monitorTitle, "text") end

    voiceRegisterSummary = voiceRegisterSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    voiceRegisterSummary:SetPoint("TOPLEFT", 10, -32)
    voiceRegisterSummary:SetPoint("RIGHT", voiceRegisterSection, "RIGHT", -120, 0)
    voiceRegisterSummary:SetJustifyH("LEFT")
    voiceRegisterSummary:SetTextColor(0.9, 0.95, 1)
    voiceRegisterSummary:SetText("Registered Bosses: 0  |  Registered Events: 0")

    voiceRegisterTime = voiceRegisterSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    voiceRegisterTime:SetPoint("TOPLEFT", 10, -52)
    voiceRegisterTime:SetPoint("RIGHT", voiceRegisterSection, "RIGHT", -120, 0)
    voiceRegisterTime:SetJustifyH("LEFT")
    voiceRegisterTime:SetTextColor(0.75, 0.8, 0.9)
    voiceRegisterTime:SetText("Last refresh: -")

    local refreshBtn = CreateFrame("Button", nil, voiceRegisterSection, "UIPanelButtonTemplate")
    refreshBtn:SetSize(96, 24)
    refreshBtn:SetPoint("TOPRIGHT", -10, -24)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        RefreshVoiceRegisterMonitor()
    end)

    local listBg = CreateFrame("Frame", nil, voiceRegisterSection, "BackdropTemplate")
    listBg:SetPoint("TOPLEFT", 10, -76)
    listBg:SetPoint("BOTTOMRIGHT", voiceRegisterSection, "BOTTOMRIGHT", -10, 10)
    listBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    listBg:SetBackdropColor(0.02, 0.02, 0.03, 0.92)
    listBg:SetBackdropBorderColor(0.18, 0.18, 0.22, 0.95)

    voiceRegisterListScroll = CreateFrame("ScrollFrame", nil, listBg, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(voiceRegisterListScroll)
    end
    voiceRegisterListScroll:SetPoint("TOPLEFT", 4, -4)
    voiceRegisterListScroll:SetPoint("BOTTOMRIGHT", -22, 4)

    voiceRegisterListChild = CreateFrame("Frame", nil, voiceRegisterListScroll)
    voiceRegisterListChild:SetSize(560, 24)
    voiceRegisterListScroll:SetScrollChild(voiceRegisterListChild)

    voiceRegisterListText = voiceRegisterListChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    voiceRegisterListText:SetPoint("TOPLEFT", 3, -2)
    voiceRegisterListText:SetJustifyH("LEFT")
    voiceRegisterListText:SetJustifyV("TOP")
    voiceRegisterListText:SetWordWrap(true)
    voiceRegisterListText:SetTextColor(0.92, 0.92, 0.92)
    voiceRegisterListText:SetText("No registered bosses")

    voiceRegisterSection:Hide()

    colorSection = CreateFrame("Frame", nil, rightRoot, "BackdropTemplate")
    colorSection:SetPoint("TOPLEFT", voiceSection, "BOTTOMLEFT", 0, -12)
    colorSection:SetPoint("TOPRIGHT", rightRoot, "TOPRIGHT", -14, 0)
    colorSection:SetHeight(430)
    colorSection:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    colorSection:SetBackdropColor(0.03, 0.04, 0.06, 0.82)
    colorSection:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.95)

    local colorTitle = colorSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorTitle:SetPoint("TOPLEFT", 10, -8)
    colorTitle:SetText("General Color Schemes")
    colorTitle:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(colorTitle, "text") end

    local colorDesc = colorSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    colorDesc:SetPoint("TOPLEFT", 10, -28)
    colorDesc:SetPoint("RIGHT", colorSection, "RIGHT", -10, 0)
    colorDesc:SetText("The boss spell page can choose from the schemes below. When \"Custom Color\" is selected, \"Custom Scheme\" is used. Enabled extra schemes appear in the color dropdown on the spell page.")
    colorDesc:SetTextColor(0.85, 0.85, 0.9)
    colorDesc:SetJustifyH("LEFT")

    local _, schemes, custom, extraSlots = EnsureColorDB()
    local rowY = -52
    for _, key in ipairs(GetSchemeOrder()) do
        local row = schemes and schemes[key]

        local nameFS = colorSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameFS:SetPoint("TOPLEFT", 12, rowY)
        nameFS:SetText(GetSchemeDisplayName(key))
        nameFS:SetTextColor(0.95, 0.95, 0.95)
        fixedColorLabels[key] = nameFS

        if InfinityUI and InfinityUI.CreateColorButton then
            local btn = InfinityUI:CreateColorButton(colorSection, "Color", row or { r = 1, g = 1, b = 1 }, "", false, function()
                ApplyVoiceOverrides()
            end)
            btn:SetPoint("TOPLEFT", 180, rowY + 8)
            btn:SetSize(220, 30)
            fixedColorButtons[key] = btn
        end
        rowY = rowY - 38
    end

    if InfinityUI and InfinityUI.CreateEditBox then
        customNameInput = InfinityUI:CreateEditBox(
            colorSection,
            (custom and custom.name) or "Custom Scheme",
            160,
            28,
            "Custom Scheme Name",
            {
                onEditFocusLost = function(text)
                    local _, _, c = EnsureColorDB()
                    c.name = (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "") ~= "")
                        and tostring(text)
                        or "Custom Scheme"
                    RefreshColorControls()
                end,
                onEnter = function(text)
                    local _, _, c = EnsureColorDB()
                    c.name = (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "") ~= "")
                        and tostring(text)
                        or "Custom Scheme"
                    RefreshColorControls()
                end,
            }
        )
        customNameInput:SetPoint("TOPLEFT", 12, rowY - 2)
    end

    if InfinityUI and InfinityUI.CreateColorButton then
        customColorButton = InfinityUI:CreateColorButton(colorSection, "Custom Scheme Color", custom or { r = 1, g = 0.82, b = 0.25 }, "", false,
            function()
                ApplyVoiceOverrides()
            end
        )
        customColorButton:SetPoint("TOPLEFT", 180, rowY + 6)
        customColorButton:SetSize(220, 30)
    end

    rowY = rowY - 42
    local extraTitle = colorSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    extraTitle:SetPoint("TOPLEFT", 12, rowY)
    extraTitle:SetText("Extra Schemes (up to 3)")
    extraTitle:SetTextColor(0.95, 0.95, 0.95)

    rowY = rowY - 24
    for i = 1, GetExtraCustomCount() do
        local slot = type(extraSlots) == "table" and extraSlots[i] or nil
        if type(slot) ~= "table" then
            slot = { enabled = false, name = "Extra Scheme " .. tostring(i), r = 1, g = 0.82, b = 0.25 }
        end

        if InfinityUI and InfinityUI.CreateCheckbox then
            local cb = InfinityUI:CreateCheckbox(colorSection, "Enable", slot.enabled == true, function(checked)
                local _, _, _, slots = EnsureColorDB()
                if type(slots) ~= "table" then return end
                local row = slots and slots[i]
                if type(row) ~= "table" then
                    row = { name = "Extra Scheme " .. tostring(i), r = 1, g = 0.82, b = 0.25, enabled = false }
                    slots[i] = row
                end
                row.enabled = (checked == true)
                RefreshColorControls()
                ApplyVoiceOverrides()
            end)
            cb:SetPoint("TOPLEFT", 12, rowY + 4)
            extraCustomEnableChecks[i] = cb
        end

        if InfinityUI and InfinityUI.CreateEditBox then
            local nameInput = InfinityUI:CreateEditBox(
                colorSection,
                slot.name or ("Extra Scheme " .. tostring(i)),
                190,
                28,
                "",
                {
                    onEditFocusLost = function(text)
                        local _, _, _, slots = EnsureColorDB()
                        if type(slots) ~= "table" then return end
                        local row = slots and slots[i]
                        if type(row) ~= "table" then
                            row = { enabled = false, r = 1, g = 0.82, b = 0.25 }
                            slots[i] = row
                        end
                        local s = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                        row.name = (s ~= "" and s) or ("Extra Scheme " .. tostring(i))
                        RefreshColorControls()
                    end,
                    onEnter = function(text)
                        local _, _, _, slots = EnsureColorDB()
                        if type(slots) ~= "table" then return end
                        local row = slots and slots[i]
                        if type(row) ~= "table" then
                            row = { enabled = false, r = 1, g = 0.82, b = 0.25 }
                            slots[i] = row
                        end
                        local s = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                        row.name = (s ~= "" and s) or ("Extra Scheme " .. tostring(i))
                        RefreshColorControls()
                    end,
                }
            )
            nameInput:SetPoint("TOPLEFT", 88, rowY + 2)
            extraCustomNameInputs[i] = nameInput
        end

        if InfinityUI and InfinityUI.CreateColorButton then
            local colorBtn = InfinityUI:CreateColorButton(colorSection, "Color", slot, "", false, function()
                ApplyVoiceOverrides()
            end)
            colorBtn:SetPoint("TOPLEFT", 290, rowY + 6)
            colorBtn:SetSize(220, 30)
            extraCustomColorButtons[i] = colorBtn
        end

        rowY = rowY - 38
    end
    colorSection:Hide()

    resetSection = CreateFrame("Frame", nil, rightRoot, "BackdropTemplate")
    resetSection:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -12)
    resetSection:SetPoint("TOPRIGHT", rightRoot, "TOPRIGHT", -14, 0)
    resetSection:SetHeight(168)
    resetSection:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    resetSection:SetBackdropColor(0.12, 0.03, 0.03, 0.85)
    resetSection:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.95)

    local resetTitle = resetSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetTitle:SetPoint("TOPLEFT", 10, -10)
    resetTitle:SetText("|cffff4444Reset Settings|r")

    local resetDesc = resetSection:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetDesc:SetPoint("TOPLEFT", 10, -30)
    resetDesc:SetPoint("RIGHT", resetSection, "RIGHT", -10, 0)
    resetDesc:SetJustifyH("LEFT")
    resetDesc:SetText("Recommended: use \"Reset Appearance Only\" first — resets timer bars, bun bars, countdown, flash text, and color schemes.\n\"Reset All Config (keep appearance)\" clears general settings, voice config, spell config, and timeline settings, but keeps appearance.\n\"Clear All Settings\" restores all InfinityBoss config to default state.")
    resetDesc:SetTextColor(0.9, 0.7, 0.7)

    local resetStyleBtn = CreateFrame("Button", nil, resetSection, "UIPanelButtonTemplate")
    resetStyleBtn:SetSize(220, 28)
    resetStyleBtn:SetPoint("BOTTOMLEFT", resetSection, "BOTTOMLEFT", 10, 82)
    resetStyleBtn:SetText("Reset Appearance Only")
    resetStyleBtn:SetScript("OnClick", function()
        local popupID = "InfinityBoss_RESET_STYLE_ONLY_CONFIRM"
        if not StaticPopupDialogs[popupID] then
            StaticPopupDialogs[popupID] = {
                text = "Reset the appearance style of timer bars, bun bars, countdown, and flash text only (spell configs are preserved). Continue?",
                button1 = "OK",
                button2 = "Cancel",
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
                OnAccept = function()
                    ResetDisplayStylesOnly()
                    ReloadUI()
                end,
            }
        end
        StaticPopup_Show(popupID)
    end)

    local resetConfigBtn = CreateFrame("Button", nil, resetSection, "UIPanelButtonTemplate")
    resetConfigBtn:SetSize(220, 28)
    resetConfigBtn:SetPoint("BOTTOMLEFT", resetSection, "BOTTOMLEFT", 10, 46)
    resetConfigBtn:SetText("Reset All Config (keep appearance)")
    resetConfigBtn:SetScript("OnClick", function()
        local popupID = "InfinityBoss_RESET_CONFIG_ONLY_CONFIRM"
        if not StaticPopupDialogs[popupID] then
            StaticPopupDialogs[popupID] = {
                text = "|cffffcc00This will clear InfinityBoss general settings, voice config, spell config, and timeline settings, but keep appearance styles.|r\nContinue?",
                button1 = "Confirm Reset",
                button2 = "Cancel",
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
                OnAccept = function()
                    ResetAllConfigExceptAppearance()
                    ReloadUI()
                end,
            }
        end
        StaticPopup_Show(popupID)
    end)

    local resetAllBtn = CreateFrame("Button", nil, resetSection, "UIPanelButtonTemplate")
    resetAllBtn:SetSize(220, 28)
    resetAllBtn:SetPoint("BOTTOMLEFT", resetSection, "BOTTOMLEFT", 10, 10)
    resetAllBtn:SetText("Clear All Settings (including appearance)")
    resetAllBtn:SetScript("OnClick", function()
        local popupID = "InfinityBoss_RESET_ALL_CONFIRM"
        if not StaticPopupDialogs[popupID] then
            StaticPopupDialogs[popupID] = {
                text = "|cffff4444Danger: This will clear ALL InfinityBoss settings (including appearance) and reload. This cannot be undone.|r\nContinue?",
                button1 = "Confirm Clear",
                button2 = "Cancel",
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
                OnAccept = function()
                    ResetAllConfigIncludingAppearance()
                    ReloadUI()
                end,
            }
        end
        StaticPopup_Show(popupID)
    end)
    resetSection:Hide()
end

function Page:Render(leftFrame, contentFrame)
    if not leftFrame or not contentFrame then return end
    EnsureUI(leftFrame, contentFrame)
    if selectedIndex < 1 or selectedIndex > #ITEMS then
        selectedIndex = 1
    end

    leftRoot:SetParent(leftFrame)
    leftRoot:ClearAllPoints()
    leftRoot:SetAllPoints(leftFrame)
    leftRoot:Show()

    rightRoot:SetParent(contentFrame)
    rightRoot:ClearAllPoints()
    rightRoot:SetAllPoints(contentFrame)
    rightRoot:Show()

    RefreshList()
    RefreshGeneralControls()
    RefreshVoiceControls()
    RefreshVoiceRegisterMonitor()
    RefreshColorControls()
    RefreshRight()
end

function Page:Hide()
    HideEmbeddedPages()
    if leftRoot then leftRoot:Hide() end
    if rightRoot then rightRoot:Hide() end
end

function Page:SetSelectedKey(key)
    if type(key) ~= "string" or key == "" then return end
    for i, item in ipairs(ITEMS) do
        if item.key == key then
            selectedIndex = i
            break
        end
    end

    if leftRoot and rightRoot and leftRoot:IsShown() and rightRoot:IsShown() then
        RefreshList()
        RefreshGeneralControls()
        RefreshVoiceControls()
        RefreshColorControls()
        RefreshRight()
    end
end

