---@diagnostic disable: undefined-global, undefined-field, need-check-nil

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

InfinityBoss.UI.Panel.BossPage = InfinityBoss.UI.Panel.BossPage or {}
local Page = InfinityBoss.UI.Panel.BossPage

local DEFAULT_EVENT_BORDER_COLOR = { r = 0.65, g = 0.65, b = 0.65 }
local MODEL_TUNE = {
    zoom = 0.85,
    cam = 1.05,
    posX = 0.0,
    posY = 0.0,
    posZ = 0.0,
    facing = 0.0,
}

local UI = {}

local CARD_CACHE = {
    activeMapTabs = {},
    mapTabPool = {},
    activeBossCards = {},
    bossCardPool = {},
    activeSpellCards = {},
    spellCardPool = {},
    spellCachePending = {},
    spellTextCache = {},
    alertAtlasExistCache = {},
}
local SPELL_CARD = {
    cols = 5,
    gapX = 6,
    gapY = 6,
    height = 46,
    titleFontSizes = { 18, 16, 14, 12 },
}
local SPELL_SETTINGS_GRID_COLS = 82
local PREALERT_FIXED_SECS = 5
local ENABLE_ADVANCED_CONDITIONS = false
local TIMELINE_SOURCE_SCRIPT = Enum and Enum.EncounterTimelineEventSource and Enum.EncounterTimelineEventSource.Script or 1

local selectedSeason
local selectedMapID
local selectedBossIndex
local selectedEventID
local selectedPrivateAuraKey
local _testTimelineLoopActive = false
local _testTimelineScriptEventIDs = {}
local _testTimelineLoopHandles = {}
local _testTimelineCleanupHandles = {}

local _asyncHandler
local _buildToken = 0
local _bossBuildToken = 0
local _mapBuildToken = 0
local _settingsSyncLock = false
local _spellUIRefreshPending = false
local _spellUIRefreshToken = 0
local RefreshModeButton
local UpdateSummary
local RefreshSpellCards
local RefreshBossList
local RefreshMapTabs
local RefreshSeasonDropdown
local SetWidgetUsable
local PersistModuleDBToSelectedSpell

local SETTINGS_MODULE_KEY = "InfinityBoss.BossSpellOptions"
local PA_SETTINGS_MODULE_KEY = "InfinityBoss.PrivateAuraOptions"
local SETTINGS_DEFAULTS = {
    enabled = false,
    centralEnabled = false,
    centralLead = 0,
    centralText = "",
    preAlertEnabled = true,
    preAlert = PREALERT_FIXED_SECS,
    preAlertText = "",
    timerBarRenameEnabled = false,
    timerBarRenameText = "",
    tr0Enabled = false,
    tr0Source = "pack",
    tr0Label = "",
    tr0LSM = "",
    tr0Path = "",
    tr1Enabled = true,
    tr1Source = "pack",
    tr1Label = "",
    tr1LSM = "",
    tr1Path = "",
    tr1OffsetMode = "delay",
    tr1OffsetSeconds = "0",
    tr2Enabled = false,
    tr2Source = "pack",
    tr2Label = "",
    tr2LSM = "",
    tr2Path = "",
    tr2OffsetMode = "delay",
    tr2OffsetSeconds = "0",
    eventColorEnabled = false,
    eventColorMode = "cooldown",
    eventColorR = 1,
    eventColorG = 0.82,
    eventColorB = 0.25,
}
local PA_SETTINGS_DEFAULTS = {
    entries = {},
}
local PA_ENTRY_DEFAULTS = {
    enabled = false,
    sourceType = "pack",
    label = "",
    customLSM = "",
    customPath = "",
}
local SETTINGS_LAYOUT = {}
local PRIVATE_AURA_SETTINGS_LAYOUT = {}
local EVENT_COLOR_ITEMS_FUNC = "func:InfinityBoss.Voice.ColorSchemes.BuildDropdownItems"
local LABEL_ITEMS_FUNC = "func:InfinityBoss.Voice.LabelCatalog.GetDropdownItems"
local TRIGGER_SOURCE_ITEMS = {
    { "Voice Pack Label", "pack" },
    { "LSM Sound",        "lsm" },
    { "Custom Path",      "file" },
}
local TRIGGER_OFFSET_MODE_ITEMS = {
    { "Delay", "delay" },
    { "Early", "early" },
}
PRIVATE_AURA_SETTINGS_LAYOUT = {
    { key = "enabled",   type = "checkbox",  x = 1,  y = 1, w = 14, h = 2, label = "Enable",           labelSize = 18 },
    { key = "sourceType",type = "dropdown",  x = 1,  y = 5, w = 10, h = 2, label = "Voice Source",     items = TRIGGER_SOURCE_ITEMS },
    { key = "label",     type = "dropdown",  x = 12, y = 5, w = 28, h = 2, label = "Voice Label",      items = LABEL_ITEMS_FUNC },
    { key = "customLSM", type = "lsm_sound", x = 12, y = 5, w = 28, h = 2, label = "LSM Sound" },
    { key = "customPath",type = "input",     x = 12, y = 5, w = 28, h = 2, label = "File Path" },
    { key = "valueTest", type = "button",    x = 41, y = 5, w = 4,  h = 2, label = "Preview" },
}
local TRIGGER_NAME = {
    [0] = "Center Alert",
    [1] = "Cast Start",
    [2] = "5 Sec Early",
}

local _spellDescMeasureFS

local MAP_CATEGORY_ITEMS = {
    { "12.0 M+",   "12.0mplus" },
    { "12.0 Raid", "12.0raid" },
    { "Other",     "other" },
}

local MAP_ICON_RENDER_OVERRIDES = {

    -- [658] = { scale = 1.38, tex = { 0.24, 0.90, 0.14, 0.94 }, offsetX = 1, offsetY = -1 },
}

local S12_CORE_MAPS = {
    [1753] = true,
    [658] = true,
    [1209] = true,
    [2526] = true,
    [2805] = true,
    [2811] = true,
    [2874] = true,
    [2915] = true,
    [2912] = true,
    [2939] = true,
    [2913] = true,
}

-- 1 Deadly, 2 Enrage, 4 Bleed, 8 Magic, 16 Disease, 32 Curse, 64 Poison,
-- 128 Tank, 256 Healer, 512 Dps
local ALERT_FLAG_DEFS = {
    {
        name = "deadly",
        bit = 1,
        atlases = { "icons_64x64_deadly", "combattimeline-fx-deadlyglow-base", "common-icon-redx" },
        texture = { file = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", width = 64, height = 64, left = 0, right = 1, top = 0, bottom = 1 },
    },
    {
        name = "enrage",
        bit = 2,
        atlases = { "icons_64x64_enrage" },
        texture = { file = "Interface\\RaidFrame\\ReadyCheck-NotReady", width = 64, height = 64, left = 0, right = 1, top = 0, bottom = 1 },
    },
    {
        name = "bleed",
        bit = 4,
        atlases = { "icons_64x64_bleed", "UI-Debuff-Border-Bleed-Icon" },
        texture = { file = "Interface\\RaidFrame\\ReadyCheck-NotReady", width = 64, height = 64, left = 0, right = 1, top = 0, bottom = 1 },
    },
    { name = "magic",   bit = 8,  atlases = { "icons_64x64_magic", "RaidFrame-Icon-DebuffMagic", "UI-HUD-CoolDownManager-Debuff-Magic" } },
    { name = "disease", bit = 16, atlases = { "icons_64x64_disease", "RaidFrame-Icon-DebuffDisease", "UI-HUD-CoolDownManager-Debuff-Disease" } },
    { name = "curse",   bit = 32, atlases = { "icons_64x64_curse", "RaidFrame-Icon-DebuffCurse", "UI-HUD-CoolDownManager-Debuff-Curse" } },
    { name = "poison",  bit = 64, atlases = { "icons_64x64_poison", "RaidFrame-Icon-DebuffPoison", "UI-HUD-CoolDownManager-Debuff-Poison" } },
    {
        name = "tank",
        bit = 128,
        atlases = { "icons_64x64_tank", "UI-LFG-RoleIcon-Tank-Micro-GroupFinder", "UI-LFG-RoleIcon-Tank-Micro", "UI-LFG-RoleIcon-Tank" },
        texture = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", width = 64, height = 64, left = 0, right = 19 / 64, top = 22 / 64, bottom = 41 / 64 },
    },
    {
        name = "heal",
        bit = 256,
        atlases = { "icons_64x64_heal", "UI-LFG-RoleIcon-Healer-Micro-GroupFinder", "UI-LFG-RoleIcon-Healer-Micro", "UI-LFG-RoleIcon-Healer" },
        texture = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", width = 64, height = 64, left = 20 / 64, right = 39 / 64, top = 1 / 64, bottom = 20 / 64 },
    },
    {
        name = "damage",
        bit = 512,
        atlases = { "icons_64x64_damage", "UI-LFG-RoleIcon-DPS-Micro-GroupFinder", "UI-LFG-RoleIcon-DPS-Micro", "UI-LFG-RoleIcon-DPS" },
        texture = { file = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES", width = 64, height = 64, left = 20 / 64, right = 39 / 64, top = 22 / 64, bottom = 41 / 64 },
    },
}
local ALERT_ICON_SIZE = 20
local ALERT_ICON_Y_OFFSET = 1
local function GetPanelDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.panel = InfinityBossDB.ui.panel or {}
    return InfinityBossDB.ui.panel
end

local function GetBossConfig()
    local cfg = InfinityBoss and InfinityBoss.BossConfig
    if type(cfg) == "table" and type(cfg.Ensure) == "function" then
        cfg:Ensure()
        return cfg
    end
    return nil
end

local function GetEventOverrideRoot()
    if _G.InfinityBossData and _G.InfinityBossData.GetEventOverrideRoot then
        return _G.InfinityBossData.GetEventOverrideRoot()
    end
    InfinityBossDataDB = InfinityBossDataDB or {}
    InfinityBossDataDB.events = InfinityBossDataDB.events or {}
    return InfinityBossDataDB.events
end

local function GetResolvedEventConfig(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    local cfg = GetBossConfig()
    if cfg and cfg.GetResolvedEventConfig then
        return cfg:GetResolvedEventConfig(eid)
    end
    if _G.InfinityBossData and _G.InfinityBossData.GetResolvedEventConfig then
        return _G.InfinityBossData.GetResolvedEventConfig(eid)
    end
    local root = _G.InfinityBossData and _G.InfinityBossData.GetEventConfigRoot and _G.InfinityBossData.GetEventConfigRoot()
    return type(root) == "table" and root[eid] or nil
end

local function CompactEventOverride(eventID)
    local cfg = GetBossConfig()
    if cfg and cfg.CompactEventOverride then
        return cfg:CompactEventOverride(eventID)
    end
    if _G.InfinityBossData and _G.InfinityBossData.CompactEventOverride then
        return _G.InfinityBossData.CompactEventOverride(eventID)
    end
    return nil
end

local function GetColorSchemeModule()
    return InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ColorSchemes
end

local function StripLegacyRoleFields(override)
    if type(override) ~= "table" then
        return
    end
    override.enabledRoles = nil
    override.roleTankEnabled = nil
    override.roleHealEnabled = nil
    override.roleDpsEnabled = nil
end

local function ResolveVoiceEventBorderColor(eventID)
    local function ClampColor(v, fallback)
        local n = tonumber(v)
        if n == nil then
            return fallback or 0
        end
        if n < 0 then return 0 end
        if n > 1 then return 1 end
        return n
    end

    local eid = tonumber(eventID)
    if not eid then
        return nil
    end

    local cfg = GetResolvedEventConfig(eid)
    if type(cfg) ~= "table" then
        return nil
    end

    local colorCfg = cfg.color
    if type(colorCfg) ~= "table" or colorCfg.enabled == false then
        return nil
    end

    local CS = GetColorSchemeModule()
    if CS and CS.ResolveEventColor then
        local r, g, b = CS.ResolveEventColor(colorCfg)
        if r ~= nil and g ~= nil and b ~= nil then
            return ClampColor(r, 1), ClampColor(g, 1), ClampColor(b, 1)
        end
    end

    if colorCfg.r ~= nil and colorCfg.g ~= nil and colorCfg.b ~= nil then
        return ClampColor(colorCfg.r, 1), ClampColor(colorCfg.g, 1), ClampColor(colorCfg.b, 1)
    end

    if CS and CS.GetSchemeColor and type(colorCfg.scheme) == "string" and colorCfg.scheme ~= "" then
        local r, g, b = CS.GetSchemeColor(colorCfg.scheme)
        if r ~= nil and g ~= nil and b ~= nil then
            return ClampColor(r, 1), ClampColor(g, 1), ClampColor(b, 1)
        end
    end

    return nil
end

local function NormalizeEventColorMode(mode)
    local CS = GetColorSchemeModule()
    if CS and CS.NormalizeSchemeKey and CS.GetCustomKey then
        local n = CS.NormalizeSchemeKey(mode)
        if n then return n end
        return CS.GetCustomKey()
    end
    local s = tostring(mode or "")
    if s == "tank" or s == "heal" or s == "cooldown" or s == "mechanic" then
        return s
    end
    return "__custom"
end

local function Clamp01(v, fallback)
    local n = tonumber(v)
    if not n then return fallback or 0 end
    if n < 0 then return 0 end
    if n > 1 then return 1 end
    return n
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

local function NormalizeTriggerSource(v)
    local s = tostring(v or ""):lower()
    if s == "lsm" or s == "file" then
        return s
    end
    return "pack"
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

local function EnsureTriggerConfig(cfg, idx)
    cfg.triggers = type(cfg.triggers) == "table" and cfg.triggers or {}
    local row = cfg.triggers[idx]
    if type(row) ~= "table" then
        row = {}
        cfg.triggers[idx] = row
    end
    row.sourceType = NormalizeTriggerSource(row.sourceType)
    if type(row.label) ~= "string" then row.label = "" end
    if type(row.customLSM) ~= "string" then row.customLSM = "" end
    if type(row.customPath) ~= "string" then row.customPath = "" end
    row.fixedOffsetMode = NormalizeTriggerOffsetMode(row.fixedOffsetMode)
    row.fixedOffsetSeconds = NormalizeTriggerOffsetSeconds(row.fixedOffsetSeconds)
    return row
end

local function GetEventVoiceConfig(eventID, fallbackSpellIdentifier, createIfMissing)
    local eid = tonumber(eventID)
    if not eid then return nil end

    local root
    local cfg
    local bossCfg = GetBossConfig()
    if createIfMissing then
        if bossCfg and bossCfg.GetOverrideRootForEvent then
            root = bossCfg:GetOverrideRootForEvent(eid, true)
        else
            root = GetEventOverrideRoot()
        end
        cfg = root[eid]
    else
        cfg = DeepCopy(GetResolvedEventConfig(eid))
    end

    if createIfMissing then
        if type(root[eid]) ~= "table" then
            root[eid] = DeepCopy(GetResolvedEventConfig(eid) or {})
        end
        cfg = root[eid]
    elseif type(cfg) ~= "table" then
        return nil
    end

    cfg.eventID = eid
    if cfg.enabled == nil then
        cfg.enabled = true
    end
    EnsureTriggerConfig(cfg, 0)
    EnsureTriggerConfig(cfg, 1)
    EnsureTriggerConfig(cfg, 2)

    if type(cfg.color) == "table" then
        local CS = GetColorSchemeModule()
        if CS and CS.NormalizeEventColorConfig then
            CS.NormalizeEventColorConfig(cfg.color)
        else
            cfg.color.r = tonumber(cfg.color.r) or 1
            cfg.color.g = tonumber(cfg.color.g) or 0.82
            cfg.color.b = tonumber(cfg.color.b) or 0.25
            if cfg.color.enabled == nil then
                cfg.color.enabled = true
            end
            if cfg.color.useCustom == nil then
                cfg.color.useCustom = true
            end
        end
    end
    return cfg
end

local function NormalizeOptionText(v)
    if type(v) ~= "string" then return "" end
    local t = v:gsub("^%s+", ""):gsub("%s+$", "")
    return t
end

local function IsLegacyEmptyPackLabel(v)
    local t = NormalizeOptionText(v)
    if t == "" then
        return true
    end
    return t == "None" or t:lower() == "none"
end

local function NormalizeTriggerPackLabel(triggerIndex, sourceType, label)
    if NormalizeTriggerSource(sourceType) ~= "pack" then
        return NormalizeOptionText(label)
    end
    if tonumber(triggerIndex) == 2 and IsLegacyEmptyPackLabel(label) then
        return "54321"
    end
    if IsLegacyEmptyPackLabel(label) then
        return ""
    end
    return NormalizeOptionText(label)
end

local function ResolvePackTriggerLabelPreset(mdb, triggerIndex)
    if type(mdb) ~= "table" then
        return ""
    end
    local prefix = "tr" .. tostring(triggerIndex)
    local label = NormalizeTriggerPackLabel(triggerIndex, mdb[prefix .. "Source"], mdb[prefix .. "Label"])
    if tonumber(triggerIndex) == 2 and label == "54321" then
        return ""
    end
    return label
end

local function ApplyLinkedTextPresets(mdb, row, changedKey)
    if type(mdb) ~= "table" then
        return false
    end

    local applied = false

    if (not changedKey or changedKey == "tr2Label" or changedKey == "tr2Source")
        and NormalizeOptionText(mdb.preAlertText) == "" then
        local preset = ResolvePackTriggerLabelPreset(mdb, 2)
        if preset ~= "" then
            mdb.preAlertText = preset
            if type(row) == "table" then
                row.preAlertText = preset
            end
            applied = true
        end
    end

    if (not changedKey or changedKey == "tr1Label" or changedKey == "tr1Source")
        and NormalizeOptionText(mdb.timerBarRenameText) == "" then
        local preset = ResolvePackTriggerLabelPreset(mdb, 1)
        if preset ~= "" then
            mdb.timerBarRenameText = preset
            if type(row) == "table" then
                row.timerBarRenameText = preset
            end
            applied = true
        end
    end

    return applied
end

local function UTF8Left(text, maxChars)
    local s = tostring(text or "")
    local n = tonumber(maxChars) or 0
    if n <= 0 or s == "" then
        return ""
    end

    if type(strlenutf8) == "function" then
        local okLen = strlenutf8(s)
        if okLen and okLen <= n then
            return s
        end
    end

    local i, chars, bytes = 1, 0, #s
    while i <= bytes and chars < n do
        local c = string.byte(s, i)
        local step = 1
        if c and c >= 240 then
            step = 4
        elseif c and c >= 224 then
            step = 3
        elseif c and c >= 192 then
            step = 2
        end
        i = i + step
        chars = chars + 1
    end
    return string.sub(s, 1, i - 1)
end

local function GetTimelineModeDB()
    if _G.InfinityBossData and _G.InfinityBossData.GetTimelineModeDB then
        return _G.InfinityBossData.GetTimelineModeDB()
    end
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    InfinityBossDB.timer.timelineMode = InfinityBossDB.timer.timelineMode or {}
    local tdb = InfinityBossDB.timer.timelineMode
    if type(tdb.byEncounter) ~= "table" then
        tdb.byEncounter = {}
    end
    if type(tdb.default) ~= "string" or tdb.default == "" then
        tdb.default = "auto"
    end
    return tdb
end

local function NormalizeTimelineMode(mode)
    local m = tostring(mode or ""):lower()
    if m == "auto" or m == "fixed" or m == "blizzard" then
        return m
    end
    return "auto"
end

local function IsFixedTimelineAvailable(encounterID)
    local id = tonumber(encounterID)
    if not id then return false end
    local set = _G.InfinityBoss_FIXED_TIMELINE_ENCOUNTERS
    if type(set) ~= "table" or set[id] ~= true then
        return false
    end
    local def = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline._bosses and InfinityBoss.Timeline._bosses[id]
    return type(def) == "table" and type(def.skills) == "table" and #def.skills > 0
end

local function GetEncounterModeOverride(encounterID)
    if not encounterID then return "auto" end
    local tdb = GetTimelineModeDB()
    local by = tdb.byEncounter
    local mode = by[encounterID]
    if mode == nil then
        mode = by[tostring(encounterID)]
    end
    if mode == nil or mode == "" then
        mode = "auto"
    end
    return NormalizeTimelineMode(mode)
end

local function SetEncounterModeOverride(encounterID, mode)
    if not encounterID then return end
    local tdb = GetTimelineModeDB()
    local by = tdb.byEncounter
    mode = NormalizeTimelineMode(mode)
    if mode == "fixed" and not IsFixedTimelineAvailable(encounterID) then
        mode = "blizzard"
    end
    by[encounterID] = mode
    by[tostring(encounterID)] = mode
end

local function GetEncounterAxisType(encounterID)
    if IsFixedTimelineAvailable(encounterID) then
        return "fixed"
    end
    return "blizzard"
end

local function ResolveEffectiveMode(encounterID)
    local sched = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
    if sched and sched.GetResolvedMode then
        return NormalizeTimelineMode(sched:GetResolvedMode(encounterID))
    end

    local override = GetEncounterModeOverride(encounterID)
    if override ~= "auto" then
        return override
    end
    return GetEncounterAxisType(encounterID)
end

local function GetModeDisplay(mode)
    mode = NormalizeTimelineMode(mode)
    if mode == "fixed" then
        return "Fixed Timeline"
    elseif mode == "blizzard" then
        return "Blizzard Native"
    end
    return "Auto"
end

local function GetAsyncHandler()
    if _asyncHandler and _asyncHandler ~= false then
        return _asyncHandler
    end
    local lib = LibStub and LibStub("LibAsync", true)
    if not lib then
        _asyncHandler = nil
        return nil
    end
    _asyncHandler = lib:GetHandler({
        type = "everyFrame",
        maxTime = 6,
        maxTimeCombat = 4,
        errorHandler = geterrorhandler(),
    })
    return _asyncHandler
end

local _eventDataCache
local _eventDataSource
local _challengeMapLookup

local function DeepCopyShallow(src)
    if type(src) ~= "table" then
        return {}
    end
    local out = {}
    for k, v in pairs(src) do
        out[k] = v
    end
    return out
end

local function NormalizeMapNameKey(name)
    local s = tostring(name or ""):lower()
    s = s:gsub("%s+", "")
    s = s:gsub("[:.,%%.!?%-_~`'\"%(%[%{%)%]%}]", "")
    return s
end

local function GetChallengeMapLookup()
    if _challengeMapLookup ~= nil then
        return _challengeMapLookup
    end

    local lookup = {}
    if C_ChallengeMode and type(C_ChallengeMode.GetMapTable) == "function"
        and type(C_ChallengeMode.GetMapUIInfo) == "function" then
        local ok, idList = pcall(C_ChallengeMode.GetMapTable)
        if ok and type(idList) == "table" then
            for _, cmID in ipairs(idList) do
                local okInfo, name, _, _, icon = pcall(C_ChallengeMode.GetMapUIInfo, cmID)
                if okInfo and type(name) == "string" and name ~= "" then
                    local key = NormalizeMapNameKey(name)
                    if key ~= "" and not lookup[key] then
                        lookup[key] = {
                            id = tonumber(cmID),
                            icon = icon,
                        }
                    end
                end
            end
        end
    end

    _challengeMapLookup = lookup
    return _challengeMapLookup
end

local function NormalizeBossEvents(events)
    if type(events) ~= "table" then
        return {}
    end

    local out = {}
    local blacklistAPI = _G.InfinityBossData and _G.InfinityBossData.IsEventBlacklisted
    for eventID, eventRow in pairs(events) do
        local eid = type(eventRow) == "table" and (tonumber(eventRow.eventID) or tonumber(eventID)) or tonumber(eventID)
        if type(eventRow) == "table" and not (blacklistAPI and blacklistAPI(eid)) then
            local row = DeepCopyShallow(eventRow)
            row.eventID = eid
            row.name = row.name or row.eventName or (row.eventID and ("Event " .. tostring(row.eventID))) or "Unknown Event"
            out[#out + 1] = row
        end
    end

    table.sort(out, function(a, b)
        local aFirst = tonumber(a.firstSeenSec)
        local bFirst = tonumber(b.firstSeenSec)
        if aFirst ~= nil or bFirst ~= nil then
            if aFirst == nil then return false end
            if bFirst == nil then return true end
            if aFirst ~= bFirst then
                return aFirst < bFirst
            end
        end
        return (tonumber(a.eventID) or 0) < (tonumber(b.eventID) or 0)
    end)

    return out
end

local function NormalizeMapBosses(mapRow, bosses)
    if type(bosses) ~= "table" then
        return {}
    end

    local orderIndex = {}
    local bossOrder = type(mapRow) == "table" and mapRow.bossOrder or nil
    if type(bossOrder) == "table" then
        for idx, encounterID in ipairs(bossOrder) do
            local eid = tonumber(encounterID)
            if eid then
                orderIndex[eid] = idx
            end
        end
    end

    local out = {}
    for bossKey, bossRow in pairs(bosses) do
        if type(bossRow) == "table" then
            local row = DeepCopyShallow(bossRow)
            row.encounterID = tonumber(row.encounterID) or tonumber(bossKey)
            row.name = row.name or row.bossName or (row.encounterID and ("Boss " .. tostring(row.encounterID))) or "Unknown Boss"
            row.events = NormalizeBossEvents(row.events)
            out[#out + 1] = row
        end
    end

    table.sort(out, function(a, b)
        local aOrder = tonumber(a.bossOrder) or orderIndex[tonumber(a.encounterID)] or math.huge
        local bOrder = tonumber(b.bossOrder) or orderIndex[tonumber(b.encounterID)] or math.huge
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
        return (tonumber(a.encounterID) or 0) < (tonumber(b.encounterID) or 0)
    end)

    return out
end

local function GetEventData()
    local source = _G.InfinityBossData and _G.InfinityBossData.GetEncounterDataRoot and _G.InfinityBossData.GetEncounterDataRoot()
    if type(source) ~= "table" then
        source = _G.InfinityBoss_ENCOUNTER_DATA and _G.InfinityBoss_ENCOUNTER_DATA.maps or _G.InfinityBoss_ENCOUNTER_DATA
    end
    if _eventDataCache and _eventDataSource == source then
        return _eventDataCache
    end

    local out = {}
    local challengeLookup = GetChallengeMapLookup()
    for mapID, mapRow in pairs(source or {}) do
        if type(mapRow) == "table" then
            local id = tonumber(mapRow.mapID) or tonumber(mapID)
            if id then
                local mapName = tostring(mapRow.mapName or mapRow.name or ("Dungeon " .. tostring(id)))
                local challengeModeID = tonumber(mapRow.challengeModeID) or tonumber(mapRow.challengeMapID)
                local icon = mapRow.icon
                if not challengeModeID or challengeModeID <= 0 or not icon then
                    local hit = challengeLookup[NormalizeMapNameKey(mapName)]
                    if hit then
                        challengeModeID = challengeModeID or hit.id
                        icon = icon or hit.icon
                    end
                end
                out[id] = {
                    mapID = id,
                    name = mapName,
                    mapName = mapName,
                    season = mapRow.season,
                    category = mapRow.category,
                    instanceType = tonumber(mapRow.instanceType),
                    challengeModeID = challengeModeID,
                    icon = icon,
                    bosses = NormalizeMapBosses(mapRow, mapRow.bosses),
                }
            end
        end
    end

    _eventDataCache = out
    _eventDataSource = source
    return out
end

local function BuildSeasonList()
    return { "12.0mplus", "12.0raid", "other" }
end

local function GetMapCategoryKey(mapInfo)
    if type(mapInfo) ~= "table" then
        return "dungeon"
    end
    local instanceType = tonumber(mapInfo.instanceType)
    if instanceType == 2 then
        return "raid"
    end
    if instanceType == 1 then
        return "dungeon"
    end
    local category = tostring(mapInfo.category or "")
    if category:find("Raid") then
        return "raid"
    end
    return "dungeon"
end

local function BuildMapList(filterKey)
    local out = {}
    local added = {}
    local data = GetEventData()
    local key = tostring(filterKey or "12.0mplus")

    local function AddOne(mapID)
        local id = tonumber(mapID)
        if not id or added[id] then return end
        local info = data[id]
        if not info or type(info.bosses) ~= "table" then return end
        local isS12Core = (S12_CORE_MAPS[id] == true)
        local cat = GetMapCategoryKey(info)

        if key == "12.0mplus" then
            if (not isS12Core) or cat ~= "dungeon" then return end
        elseif key == "12.0raid" then
            if (not isS12Core) or cat ~= "raid" then return end
        elseif key == "other" then
            if isS12Core then return end
        else
            return
        end

        table.insert(out, id)
        added[id] = true
    end

    for mapID in pairs(data) do
        AddOne(mapID)
    end
    table.sort(out)

    return out
end

local function GetMapDisplayName(mapID)
    local info = GetEventData()[tonumber(mapID)]
    if info and info.name and info.name ~= "" then
        return info.name
    end
    if C_Map and C_Map.GetMapInfo then
        local mapInfo = C_Map.GetMapInfo(tonumber(mapID) or 0)
        if mapInfo and mapInfo.name and mapInfo.name ~= "" then
            return mapInfo.name
        end
    end
    return "Unknown Dungeon " .. tostring(mapID)
end

local function GetMapIcon(mapID)
    local id = tonumber(mapID)
    local info = GetEventData()[id]
    local InfinityDB = _G.InfinityDB or InfinityTools.DB_Static

    if id and InfinityDB and type(InfinityDB.InstanceIconByMapID) == "table" then
        local icon = InfinityDB.InstanceIconByMapID[id]
        if icon then
            return icon
        end
    end
    if info and info.icon then
        return info.icon
    end

    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local cmID = info and tonumber(info.challengeModeID) or id
        if cmID and cmID > 0 then
            local _, _, _, icon = C_ChallengeMode.GetMapUIInfo(cmID)
            if icon then return icon end
        end
    end

    if info and tonumber(info.instanceType) == 2 then
        return "Interface\\LFGFrame\\LFGIcon-Raid"
    end
    return "Interface\\LFGFrame\\LFGIcon-Dungeon"
end

local function GetMapIconRenderStyle(mapID)
    local id = tonumber(mapID)
    local style = MAP_ICON_RENDER_OVERRIDES[id]
    if not style then
        local info = GetEventData()[id]
        local cmID = info and tonumber(info.challengeModeID) or nil
        if cmID then
            style = MAP_ICON_RENDER_OVERRIDES[cmID]
        end
    end
    if style then
        return style
    end
    return { scale = 1.0, tex = { 0.08, 0.92, 0.08, 0.92 }, offsetX = 0, offsetY = 0 }
end

local function HasFlag(value, bitMask)
    local v = tonumber(value) or 0
    local b = tonumber(bitMask) or 0
    if b <= 0 then
        return false
    end
    if bit32 and bit32.band then
        return bit32.band(v, b) ~= 0
    end
    if bit and bit.band then
        return bit.band(v, b) ~= 0
    end
    -- Power-of-two fallback.
    return (v % (b * 2)) >= b
end

local function IsAlertAtlasValid(atlasName)
    if not atlasName or atlasName == "" then
        return false
    end
    local cached = CARD_CACHE.alertAtlasExistCache[atlasName]
    if cached ~= nil then
        return cached
    end
    local valid = true
    if C_Texture and C_Texture.GetAtlasInfo then
        valid = C_Texture.GetAtlasInfo(atlasName) ~= nil
    end
    CARD_CACHE.alertAtlasExistCache[atlasName] = valid and true or false
    return CARD_CACHE.alertAtlasExistCache[atlasName]
end

local function BuildAlertIconMarkup(iconFlags, iconSize, iconYOffset)
    local flags = tonumber(iconFlags) or 0
    if flags <= 0 then
        return ""
    end
    local renderSize = tonumber(iconSize) or ALERT_ICON_SIZE
    local renderYOffset = tonumber(iconYOffset) or ALERT_ICON_Y_OFFSET
    local marks = {}
    for _, cfg in ipairs(ALERT_FLAG_DEFS) do
        local bitMask = tonumber(cfg.bit) or 0
        if bitMask > 0 and HasFlag(flags, bitMask) then
            local atlasList = cfg.atlases
            local added = false
            if type(atlasList) ~= "table" or #atlasList == 0 then
                atlasList = { "icons_64x64_" .. tostring(cfg.name or "") }
            end
            for _, atlas in ipairs(atlasList) do
                if IsAlertAtlasValid(atlas) then
                    if CreateAtlasMarkup then
                        marks[#marks + 1] = CreateAtlasMarkup(atlas, renderSize, renderSize, 0, renderYOffset)
                    else
                        marks[#marks + 1] = string.format(
                            "|A:%s:%d:%d:0:%d|a",
                            atlas,
                            renderSize,
                            renderSize,
                            renderYOffset
                        )
                    end
                    added = true
                    break
                end
            end
            if (not added) and cfg.texture and cfg.texture.file and cfg.texture.file ~= "" then
                local tex = cfg.texture
                if CreateTextureMarkup then
                    marks[#marks + 1] = CreateTextureMarkup(
                        tex.file,
                        tonumber(tex.width) or 64,
                        tonumber(tex.height) or 64,
                        renderSize,
                        renderSize,
                        tonumber(tex.left) or 0,
                        tonumber(tex.right) or 1,
                        tonumber(tex.top) or 0,
                        tonumber(tex.bottom) or 1,
                        0,
                        renderYOffset
                    )
                else
                    marks[#marks + 1] = string.format(
                        "|T%s:%d:%d:0:%d:%d:%d:%d:%d:%d:%d:%d|t",
                        tex.file,
                        renderSize,
                        renderSize,
                        renderYOffset,
                        tonumber(tex.width) or 64,
                        tonumber(tex.height) or 64,
                        math.floor((tonumber(tex.left) or 0) * (tonumber(tex.width) or 64)),
                        math.floor((tonumber(tex.right) or 1) * (tonumber(tex.width) or 64)),
                        math.floor((tonumber(tex.top) or 0) * (tonumber(tex.height) or 64)),
                        math.floor((tonumber(tex.bottom) or 1) * (tonumber(tex.height) or 64))
                    )
                end
            end
        end
    end
    return table.concat(marks, " ")
end

local function GetEventIconFlags(event)
    if type(event) ~= "table" then
        return 0
    end
    local flags = tonumber(event.iconFlags)
    if not flags then
        flags = tonumber(event.icons)
    end
    return flags or 0
end

local function GetVoiceEventColorConfig(eventID)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    local cfg = GetResolvedEventConfig(eid)
    if type(cfg) ~= "table" or type(cfg.color) ~= "table" or cfg.color.enabled == false then
        return nil
    end
    return cfg.color
end

local function ColorDistanceSq(r1, g1, b1, r2, g2, b2)
    local ar, ag, ab = tonumber(r1), tonumber(g1), tonumber(b1)
    local br, bg, bb = tonumber(r2), tonumber(g2), tonumber(b2)
    if not (ar and ag and ab and br and bg and bb) then
        return math.huge
    end
    local dr, dg, db = ar - br, ag - bg, ab - bb
    return dr * dr + dg * dg + db * db
end

local function ResolvePrimaryAlertIconSourceByBorder(eventID, borderR, borderG, borderB)
    local iconKind = nil -- "tank" | "heal" | "deadly"
    local CS = GetColorSchemeModule()
    local colorCfg = GetVoiceEventColorConfig(eventID)

    if type(colorCfg) == "table" then
        local scheme = nil
        if colorCfg.useCustom == true then
            scheme = "__custom"
        else
            scheme = tostring(colorCfg.scheme or "")
        end
        if CS and CS.NormalizeSchemeKey then
            scheme = CS.NormalizeSchemeKey(scheme)
        end
        if scheme == "tank" then
            iconKind = "tank"
        elseif scheme == "heal" then
            iconKind = "heal"
        elseif scheme == "mechanic" then
            iconKind = "deadly"
        end
    end

    if not iconKind then
        local ref = {}
        if CS and CS.GetSchemeColor then
            local tr, tg, tb = CS.GetSchemeColor("tank")
            local hr, hg, hb = CS.GetSchemeColor("heal")
            local mr, mg, mb = CS.GetSchemeColor("mechanic")
            ref = {
                tank = { r = tr, g = tg, b = tb },
                heal = { r = hr, g = hg, b = hb },
                mechanic = { r = mr, g = mg, b = mb },
            }
        else
            ref = {
                tank = { r = 0xC6 / 255, g = 0x9B / 255, b = 0x6C / 255 },
                heal = { r = 0x5F / 255, g = 0xFF / 255, b = 0x9D / 255 },
                mechanic = { r = 0xDA / 255, g = 0x5B / 255, b = 0xFF / 255 },
            }
        end

        local bestKey, bestDist = nil, math.huge
        for key, c in pairs(ref) do
            local d = ColorDistanceSq(borderR, borderG, borderB, c.r, c.g, c.b)
            if d < bestDist then
                bestDist = d
                bestKey = key
            end
        end
        if bestDist <= 0.04 and bestKey then
            if bestKey == "tank" then
                iconKind = "tank"
            elseif bestKey == "heal" then
                iconKind = "heal"
            elseif bestKey == "mechanic" then
                iconKind = "deadly"
            end
        end
    end

    local candidates = nil
    if iconKind == "tank" then
        candidates = { atlases = { "icons_64x64_tank", "UI-LFG-RoleIcon-Tank", "UI-LFG-RoleIcon-Tank-Micro-GroupFinder", "UI-LFG-RoleIcon-Tank-Micro" } }
    elseif iconKind == "heal" then
        candidates = { atlases = { "icons_64x64_heal", "UI-LFG-RoleIcon-Healer", "UI-LFG-RoleIcon-Healer-Micro-GroupFinder", "UI-LFG-RoleIcon-Healer-Micro" } }
    elseif iconKind == "deadly" then
        candidates = { atlases = { "icons_64x64_deadly", "combattimeline-fx-deadlyglow-base", "common-icon-redx" }, texture = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" }
    else
        candidates = { atlases = { "Ping_Wheel_Icon_Warning_Disabled_Small" } }
    end

    for _, atlas in ipairs(candidates.atlases or {}) do
        if IsAlertAtlasValid(atlas) then
            return "atlas", atlas
        end
    end
    if candidates.texture and candidates.texture ~= "" then
        return "texture", candidates.texture
    end

    return nil, nil
end

local function GetEventCastWindowRuleConfig(eventID, createIfMissing)
    if not ENABLE_ADVANCED_CONDITIONS then
        return nil
    end
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    local root
    local row
    local bossCfg = GetBossConfig()
    if createIfMissing then
        if bossCfg and bossCfg.GetOverrideRootForEvent then
            root = bossCfg:GetOverrideRootForEvent(eid, true)
        else
            root = GetEventOverrideRoot()
        end
        row = root[eid]
    else
        row = DeepCopy(GetResolvedEventConfig(eid))
    end
    if createIfMissing then
        if type(root[eid]) ~= "table" then
            root[eid] = DeepCopy(GetResolvedEventConfig(eid) or {})
        end
        row = root[eid]
    elseif type(row) ~= "table" then
        return nil
    end
    row.rules = type(row.rules) == "table" and row.rules or {}
    local rule = row.rules.castWindow
    if type(rule) ~= "table" then
        if not createIfMissing then
            return nil
        end
        rule = {
            enabled = false,
            windowBefore = 2,
            windowAfter = 2,
            ringEnabled = true,
        }
        row.rules.castWindow = rule
    end
    return rule
end

local function BuildPrimaryCategoryMarkup(eventID, iconSize, iconYOffset)
    local borderR, borderG, borderB = ResolveVoiceEventBorderColor(eventID)
    if borderR == nil or borderG == nil or borderB == nil then
        borderR, borderG, borderB =
            DEFAULT_EVENT_BORDER_COLOR.r,
            DEFAULT_EVENT_BORDER_COLOR.g,
            DEFAULT_EVENT_BORDER_COLOR.b
    end

    local kind, source = ResolvePrimaryAlertIconSourceByBorder(eventID, borderR, borderG, borderB)
    local renderSize = tonumber(iconSize) or 18
    local renderYOffset = tonumber(iconYOffset) or 0
    if kind == "atlas" and source and source ~= "" then
        if CreateAtlasMarkup then
            return CreateAtlasMarkup(source, renderSize, renderSize, 0, renderYOffset)
        end
        return string.format("|A:%s:%d:%d:0:%d|a", source, renderSize, renderSize, renderYOffset)
    end
    if kind == "texture" and source and source ~= "" then
        if CreateTextureMarkup then
            return CreateTextureMarkup(source, 128, 128, renderSize, renderSize, 0, 1, 0, 1, 0, renderYOffset)
        end
        return string.format("|T%s:%d:%d:0:%d:128:128:0:128:0:128|t", source, renderSize, renderSize, renderYOffset)
    end
    return ""
end

local function BuildPrivateAuraMarkup(iconSize, iconYOffset)
    local atlas = "poi-nzothvision"
    local renderSize = tonumber(iconSize) or 18
    local renderYOffset = tonumber(iconYOffset) or 0
    if CreateAtlasMarkup then
        return CreateAtlasMarkup(atlas, renderSize, renderSize, 0, renderYOffset)
    end
    return string.format("|A:%s:%d:%d:0:%d|a", atlas, renderSize, renderSize, renderYOffset)
end

local function ResolveBossDisplayID(boss)
    if type(boss) ~= "table" then
        return nil
    end

    local displayID = tonumber(boss.creatureDisplayID)
    if displayID and displayID > 0 then
        return displayID
    end

    local legacyPortraitID = tonumber(boss.portrait)
    if legacyPortraitID and legacyPortraitID > 0 then
        return legacyPortraitID
    end

    return nil
end

local function ApplyModelTune(model)
    if not model then return end
    if model.SetPortraitZoom then
        model:SetPortraitZoom(MODEL_TUNE.zoom)
    end
    if model.SetCamDistanceScale then
        model:SetCamDistanceScale(MODEL_TUNE.cam)
    end
    if model.SetPosition then
        model:SetPosition(MODEL_TUNE.posX, MODEL_TUNE.posY, MODEL_TUNE.posZ)
    end
    if model.SetFacing then
        model:SetFacing(MODEL_TUNE.facing)
    end
end

local function BuildBossList(mapID)
    local out = {}
    local info = GetEventData()[tonumber(mapID)]
    if not info or type(info.bosses) ~= "table" then
        return out
    end
    for i, boss in ipairs(info.bosses) do
        table.insert(out, { index = i, data = boss })
    end
    return out
end

local function GetCurrentBossListEntry()
    local list = BuildBossList(selectedMapID)
    local idx = tonumber(selectedBossIndex)
    if not idx or idx < 1 or idx > #list then
        return nil
    end
    return list[idx]
end

local function GetCurrentBoss()
    local entry = GetCurrentBossListEntry()
    if not entry then
        return nil
    end
    return entry.data
end

local function GetCurrentEncounterID()
    local boss = GetCurrentBoss()
    return boss and tonumber(boss.encounterID) or nil
end

local function GetCurrentMapInfo()
    return GetEventData()[tonumber(selectedMapID)]
end

local function BuildCurrentPrivateAuraRows()
    local out = {}
    local registry = InfinityBoss and InfinityBoss.PrivateAura
    if not registry then
        return out
    end

    local encounterID = GetCurrentEncounterID()
    local raidRow = encounterID and registry:GetRaidBoss(encounterID) or nil
    if type(raidRow) == "table" and type(raidRow.spells) == "table" then
        for spellID, row in pairs(raidRow.spells) do
            local sid = tonumber(spellID)
            if sid and type(row) == "table" then
                out[#out + 1] = {
                    key = "pa:raid:" .. tostring(encounterID) .. ":" .. tostring(sid),
                    spellID = sid,
                    name = tostring(row.name or ("Spell " .. tostring(sid))),
                    bosses = row.bosses or {},
                    sources = row.sources or {},
                    sourceNPCIDs = row.sourceNPCIDs or {},
                    ownerLabel = tostring(raidRow.boss or ""),
                    tagText = "P",
                    _privateAura = true,
                }
            end
        end
    end

    local mapInfo = GetCurrentMapInfo()
    local dungeonRow = mapInfo and registry:GetMplusDungeon(mapInfo.mapName or mapInfo.name) or nil
    if type(dungeonRow) == "table" and type(dungeonRow.spells) == "table" then
        local entry = GetCurrentBossListEntry()
        local selectedBossName = (entry and entry.data and entry.data.name) and tostring(entry.data.name) or nil
        for spellID, row in pairs(dungeonRow.spells) do
            local sid = tonumber(spellID)
            if sid and type(row) == "table" then
                local bosses = row.bosses or {}
                local include = false
                if selectedBossName then
                    for i = 1, #bosses do
                        if tostring(bosses[i]) == selectedBossName then
                            include = true
                            break
                        end
                    end
                end
                if include then
                    out[#out + 1] = {
                        key = "pa:mplus:boss:" .. tostring(mapInfo and (mapInfo.mapName or mapInfo.name) or "unknown") .. ":" .. tostring(selectedBossName or "unknown") .. ":" .. tostring(sid),
                        spellID = sid,
                        name = tostring(row.name or ("Spell " .. tostring(sid))),
                        bosses = bosses,
                        sources = row.sources or {},
                        sourceNPCIDs = row.sourceNPCIDs or {},
                        ownerLabel = table.concat(bosses, " / "),
                        tagText = "P",
                        _privateAura = true,
                    }
                end
            end
        end
    end

    table.sort(out, function(a, b)
        local an = tostring(a.name or "")
        local bn = tostring(b.name or "")
        if an == bn then
            return (a.spellID or 0) < (b.spellID or 0)
        end
        return an < bn
    end)
    return out
end

local function NormalizePrivateAuraConfig(row)
    row = type(row) == "table" and row or {}
    if row.enabled == nil then
        row.enabled = PA_ENTRY_DEFAULTS.enabled
    else
        row.enabled = row.enabled == true
    end
    row.sourceType = NormalizeTriggerSource(row.sourceType or PA_ENTRY_DEFAULTS.sourceType)
    if type(row.label) ~= "string" then
        row.label = PA_ENTRY_DEFAULTS.label
    end
    if type(row.customLSM) ~= "string" then
        row.customLSM = PA_ENTRY_DEFAULTS.customLSM
    end
    if type(row.customPath) ~= "string" then
        row.customPath = PA_ENTRY_DEFAULTS.customPath
    end
    return row
end

local function GetPrivateAuraSettingsRoot()
    local root = InfinityTools:GetModuleDB(PA_SETTINGS_MODULE_KEY, PA_SETTINGS_DEFAULTS)
    root.entries = type(root.entries) == "table" and root.entries or {}
    return root
end

local function GetPrivateAuraConfigByKey(key, createIfMissing)
    if type(key) ~= "string" or key == "" then
        return nil
    end
    local root = GetPrivateAuraSettingsRoot()
    local row = root.entries[key]
    if row == nil and createIfMissing then
        row = {}
        root.entries[key] = row
    end
    if row then
        return NormalizePrivateAuraConfig(row)
    end
    return nil
end

local function PersistActivePrivateAuraConfig()
    if not selectedPrivateAuraKey then
        return
    end

    local root = GetPrivateAuraSettingsRoot()
    local existing = root.entries[selectedPrivateAuraKey]
    local Grid = _G.InfinityGrid
    local source = nil

    if Grid and Grid.ModuleKey == PA_SETTINGS_MODULE_KEY and type(Grid.LastConfig) == "table" then
        source = Grid.LastConfig
    elseif type(existing) == "table" then
        source = existing
    end

    if type(source) ~= "table" then
        return
    end

    local row = type(existing) == "table" and existing or {}
    root.entries[selectedPrivateAuraKey] = row
    row.enabled = (source.enabled ~= false)
    row.sourceType = NormalizeTriggerSource(source.sourceType or PA_ENTRY_DEFAULTS.sourceType)
    row.label = tostring(source.label or "")
    row.customLSM = tostring(source.customLSM or "")
    row.customPath = tostring(source.customPath or "")
    NormalizePrivateAuraConfig(row)
end

local function RefreshPrivateAuraSettingsWidgets(cfg)
    local Grid = _G.InfinityGrid
    if not Grid or not Grid.Widgets then
        return
    end
    local source = NormalizeTriggerSource(cfg and cfg.sourceType or "pack")
    local sourceWidget = Grid.Widgets.sourceType
    local packWidget = Grid.Widgets.label
    local lsmWidget = Grid.Widgets.customLSM
    local pathWidget = Grid.Widgets.customPath
    local testWidget = Grid.Widgets.valueTest
    SetWidgetUsable(sourceWidget, true)
    if source == "pack" then
        if packWidget then packWidget:Show() end
        if lsmWidget then lsmWidget:Hide() end
        if pathWidget then pathWidget:Hide() end
        if testWidget then testWidget:Show() end
        SetWidgetUsable(packWidget, true)
        SetWidgetUsable(testWidget, true)
    elseif source == "lsm" then
        if packWidget then packWidget:Hide() end
        if lsmWidget then lsmWidget:Show() end
        if pathWidget then pathWidget:Hide() end
        if testWidget then testWidget:Show() end
        SetWidgetUsable(lsmWidget, true)
        SetWidgetUsable(testWidget, true)
    else
        if packWidget then packWidget:Hide() end
        if lsmWidget then lsmWidget:Hide() end
        if pathWidget then pathWidget:Show() end
        if testWidget then testWidget:Show() end
        SetWidgetUsable(pathWidget, true)
        SetWidgetUsable(testWidget, true)
    end
end

local function PlayPrivateAuraPreview()
    if not selectedPrivateAuraKey then
        return
    end
    local cfg = GetPrivateAuraConfigByKey(selectedPrivateAuraKey, false)
    if not cfg or cfg.enabled == false then
        return
    end
    local sourceType = NormalizeTriggerSource(cfg.sourceType)
    if sourceType == "pack" then
        local label = tostring(cfg.label or "")
        if label == "" then
            return
        end
        local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
        if Engine and Engine.TryPlayLabel then
            Engine:TryPlayLabel(label, { source = "private_aura_preview" })
        end
        return
    end

    local soundPath
    if sourceType == "lsm" then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM and cfg.customLSM ~= "" then
            soundPath = LSM:Fetch("sound", cfg.customLSM, true)
        end
    elseif sourceType == "file" then
        soundPath = tostring(cfg.customPath or "")
    end
    if soundPath and soundPath ~= "" and PlaySoundFile then
        pcall(PlaySoundFile, soundPath, "Master")
    end
end

local function FindCurrentPrivateAuraRowByKey(key)
    if type(key) ~= "string" or key == "" then
        return nil
    end
    local rows = BuildCurrentPrivateAuraRows()
    for i = 1, #rows do
        if rows[i].key == key then
            return rows[i]
        end
    end
    return nil
end

local function AddTestTimelineHandle(handle)
    if type(handle) == "table" and type(handle.Cancel) == "function" then
        _testTimelineLoopHandles[#_testTimelineLoopHandles + 1] = handle
    end
end

local function CancelTestTimelineHandles()
    for i = 1, #_testTimelineLoopHandles do
        local h = _testTimelineLoopHandles[i]
        if type(h) == "table" and type(h.Cancel) == "function" then
            pcall(h.Cancel, h)
        end
    end
    wipe(_testTimelineLoopHandles)
end

local function AddTestTimelineCleanupHandle(handle)
    if type(handle) == "table" and type(handle.Cancel) == "function" then
        _testTimelineCleanupHandles[#_testTimelineCleanupHandles + 1] = handle
    end
end

local function CancelTestTimelineCleanupHandles()
    for i = 1, #_testTimelineCleanupHandles do
        local h = _testTimelineCleanupHandles[i]
        if type(h) == "table" and type(h.Cancel) == "function" then
            pcall(h.Cancel, h)
        end
    end
    wipe(_testTimelineCleanupHandles)
end

local function RemoveOneTestTimelineScriptEvent(eventID)
    local eid = tonumber(eventID)
    if not (eid and eid > 0 and C_EncounterTimeline) then
        return
    end
    if C_EncounterTimeline.FinishScriptEvent then
        pcall(C_EncounterTimeline.FinishScriptEvent, eid)
    end
    if C_EncounterTimeline.CancelScriptEvent then
        pcall(C_EncounterTimeline.CancelScriptEvent, eid)
    end
end

local function ForceCancelTestTimelineScriptEvents()
    if C_EncounterTimeline then
        if C_EncounterTimeline.CancelAllScriptEvents then
            pcall(C_EncounterTimeline.CancelAllScriptEvents)
        end

        if C_EncounterTimeline.GetEventList and C_EncounterTimeline.GetEventInfo and C_EncounterTimeline.CancelScriptEvent then
            local okEvents, events = pcall(C_EncounterTimeline.GetEventList)
            if okEvents and type(events) == "table" then
                for i = 1, #events do
                    local eventID = tonumber(events[i])
                    if eventID and eventID > 0 then
                        local okInfo, info = pcall(C_EncounterTimeline.GetEventInfo, eventID)
                        if okInfo and type(info) == "table" and tonumber(info.source) == TIMELINE_SOURCE_SCRIPT then
                            RemoveOneTestTimelineScriptEvent(eventID)
                        end
                    end
                end
            end
        end

        if C_EncounterTimeline.CancelScriptEvent or C_EncounterTimeline.FinishScriptEvent then
            for i = 1, #_testTimelineScriptEventIDs do
                local eventID = tonumber(_testTimelineScriptEventIDs[i])
                if eventID and eventID > 0 then
                    RemoveOneTestTimelineScriptEvent(eventID)
                end
            end
        end
    end
end

local function CancelTestTimelineScriptEvents()
    ForceCancelTestTimelineScriptEvents()
    wipe(_testTimelineScriptEventIDs)
end

local function ScheduleTestTimelineCleanupPasses()
    CancelTestTimelineCleanupHandles()
    local delays = { 0.05, 0.20, 0.50, 1.00 }
    for i = 1, #delays do
        local delay = delays[i]
        local h = C_Timer.NewTimer(delay, function()
            ForceCancelTestTimelineScriptEvents()
        end)
        AddTestTimelineCleanupHandle(h)
    end
end

local function StopTestTimelineLoop(skipDelayedCleanup)
    _testTimelineLoopActive = false
    CancelTestTimelineHandles()
    CancelTestTimelineCleanupHandles()
    CancelTestTimelineScriptEvents()
    if not skipDelayedCleanup then
        ScheduleTestTimelineCleanupPasses()
    end
end

local function NormalizeLoopDuration(v, fallback)
    local n = tonumber(v)
    if not n then
        n = tonumber(fallback) or 1
    end
    if n < 0.2 then n = 0.2 end
    if n > 600 then n = 600 end
    return n
end

local function ResolveScriptEventPriority(skill)
    local p = tonumber(skill and skill.barPriority)
    if p and p >= 3 then
        return 2
    end
    return 1
end

local function AddLoopScriptEvent(skill, duration)
    if not _testTimelineLoopActive then return end
    if not (C_EncounterTimeline and C_EncounterTimeline.AddScriptEvent) then return end
    if type(skill) ~= "table" then return end

    local spellID = tonumber(skill.spellIdentifier) or tonumber(skill.evenSpellID) or tonumber(skill.spellID)
    if not spellID or spellID <= 0 then return end

    local info = nil
    if C_Spell and C_Spell.GetSpellInfo then
        info = C_Spell.GetSpellInfo(spellID)
    end

    local req = {
        spellID = spellID,
        iconFileID = tonumber(skill.iconFileID) or (info and tonumber(info.iconID)) or 136243,
        duration = NormalizeLoopDuration(duration, 1),
        maxQueueDuration = 0,
        overrideName = tostring(skill.displayName or skill.name or (info and info.name) or ("Spell " .. tostring(spellID))),
        severity = ResolveScriptEventPriority(skill),
        paused = false,
    }

    local icons = tonumber(skill.icons)
    if icons and icons > 0 and icons <= 1023 then
        req.icons = icons
    end

    local ok, eventID = pcall(C_EncounterTimeline.AddScriptEvent, req)
    eventID = tonumber(eventID)
    if ok and eventID and eventID > 0 then
        _testTimelineScriptEventIDs[#_testTimelineScriptEventIDs + 1] = eventID
        if #_testTimelineScriptEventIDs > 2000 then
            table.remove(_testTimelineScriptEventIDs, 1)
        end
    end
end

local function StartSkillLoopScriptEvents(skill)
    if type(skill) ~= "table" then return end

    local firstDelay = NormalizeLoopDuration(skill.first, 5)
    AddLoopScriptEvent(skill, firstDelay)

    local function StartFixedIntervalLoop(period)
        period = NormalizeLoopDuration(period, firstDelay)
        local firstHandle = C_Timer.NewTimer(firstDelay, function()
            if not _testTimelineLoopActive then return end
            AddLoopScriptEvent(skill, period)
            local ticker = C_Timer.NewTicker(period, function()
                if not _testTimelineLoopActive then return end
                AddLoopScriptEvent(skill, period)
            end)
            AddTestTimelineHandle(ticker)
        end)
        AddTestTimelineHandle(firstHandle)
    end

    local ivNum = tonumber(skill.interval)
    if ivNum and ivNum > 0 then
        StartFixedIntervalLoop(ivNum)
        return
    end

    if type(skill.interval) == "table" and #skill.interval > 0 then
        local seq = {}
        for i = 1, #skill.interval do
            local v = tonumber(skill.interval[i])
            if v and v > 0 then
                seq[#seq + 1] = NormalizeLoopDuration(v, firstDelay)
            end
        end
        if #seq > 0 then
            local idx = 1
            local function ScheduleNext(waitSecs)
                local timer = C_Timer.NewTimer(waitSecs, function()
                    if not _testTimelineLoopActive then return end
                    local dur = seq[idx] or seq[1]
                    AddLoopScriptEvent(skill, dur)
                    idx = idx + 1
                    if idx > #seq then
                        idx = 1
                    end
                    ScheduleNext(dur)
                end)
                AddTestTimelineHandle(timer)
            end
            ScheduleNext(firstDelay)
            return
        end
    end

    StartFixedIntervalLoop(firstDelay)
end

local function StartTestTimelineLoop(encounterID)
    StopTestTimelineLoop(true)
    if not (C_EncounterTimeline and C_EncounterTimeline.AddScriptEvent) then
        return false
    end

    local bossDef = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline._bosses and InfinityBoss.Timeline._bosses[tonumber(encounterID)]
    local skills = bossDef and bossDef.skills
    if type(skills) ~= "table" or #skills == 0 then
        return false
    end

    _testTimelineLoopActive = true
    local started = 0
    for _, skill in ipairs(skills) do
        local sid = type(skill) == "table" and
            (tonumber(skill.spellIdentifier) or tonumber(skill.evenSpellID) or tonumber(skill.spellID)) or nil
        if sid and sid > 0 then
            StartSkillLoopScriptEvents(skill)
            started = started + 1
        end
    end

    if started <= 0 then
        StopTestTimelineLoop()
        return false
    end

    return true
end

local function GetEventID(event)
    if type(event) ~= "table" then return nil end
    return tonumber(event.eventID)
end

local function GetEventSpellIdentifier(event)
    if type(event) ~= "table" then return nil end
    return tonumber(event.evenSpellID) or tonumber(event.spellID)
end

local function EventExistsOnCurrentBoss(eventID)
    local eid = tonumber(eventID)
    if not eid then return false end
    local boss = GetCurrentBoss()
    if not (boss and type(boss.events) == "table") then
        return false
    end
    for _, event in ipairs(boss.events) do
        if GetEventID(event) == eid then
            return true
        end
    end
    return false
end

local function EnsureSelectedEvent()
    if selectedPrivateAuraKey and FindCurrentPrivateAuraRowByKey(selectedPrivateAuraKey) then
        return
    end
    selectedPrivateAuraKey = nil
    local boss = GetCurrentBoss()
    if not (boss and type(boss.events) == "table" and #boss.events > 0) then
        selectedEventID = nil
        return
    end
    if selectedEventID and EventExistsOnCurrentBoss(selectedEventID) then
        return
    end
    for _, event in ipairs(boss.events) do
        local eid = GetEventID(event)
        if eid then
            selectedEventID = eid
            return
        end
    end
    selectedEventID = nil
end

local function GetSpellOverride(encounterID, eventID, spellIdentifier, createIfMissing)
    eventID = tonumber(eventID)
    if not eventID then return nil end

    local root
    local row
    local bossCfg = GetBossConfig()
    if createIfMissing then
        if bossCfg and bossCfg.GetOverrideRootForEvent then
            root = bossCfg:GetOverrideRootForEvent(eventID, true)
        else
            root = GetEventOverrideRoot()
        end
        row = root[eventID]
    else
        row = DeepCopy(GetResolvedEventConfig(eventID))
    end
    if createIfMissing then
        if type(root[eventID]) ~= "table" then
            root[eventID] = DeepCopy(GetResolvedEventConfig(eventID) or {})
        end
        row = root[eventID]
        StripLegacyRoleFields(row)
    elseif type(row) ~= "table" then
        return nil
    end

    return row
end

local function IsSpellDataReady(spellID)
    if not spellID then return false end
    if C_Spell and C_Spell.IsSpellDataCached then
        local ok, cached = pcall(C_Spell.IsSpellDataCached, spellID)
        if ok then return cached and true or false end
    end
    return true
end

local function RequestSpellDataLoad(spellID)
    if not spellID then return end
    if not (C_Spell and C_Spell.RequestLoadSpellData) then return end
    if CARD_CACHE.spellCachePending[spellID] then return end
    CARD_CACHE.spellCachePending[spellID] = true
    pcall(C_Spell.RequestLoadSpellData, spellID)
end

local function PrimeSpellCache(events)
    for _, event in ipairs(events or {}) do
        local spellID = GetEventSpellIdentifier(event)
        if spellID and not IsSpellDataReady(spellID) then
            RequestSpellDataLoad(spellID)
        end
    end
end

local function CurrentBossHasSpellID(spellID)
    if not spellID then return false end
    local boss = GetCurrentBoss()
    if not (boss and type(boss.events) == "table") then
        return false
    end
    local sid = tonumber(spellID)
    for _, event in ipairs(boss.events) do
        local identifier = GetEventSpellIdentifier(event)
        if identifier == sid then
            return true
        end
    end
    return false
end

local function GetSpellNameAndIcon(spellID)
    if not spellID then
        return nil, 134400
    end
    local cached = CARD_CACHE.spellTextCache[spellID]
    if type(cached) == "table" and cached.name ~= nil and cached.icon ~= nil then
        return cached.name, cached.icon
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and info then
            local name = info.name
            local icon = info.iconID or 134400
            CARD_CACHE.spellTextCache[spellID] = CARD_CACHE.spellTextCache[spellID] or {}
            CARD_CACHE.spellTextCache[spellID].name = name
            CARD_CACHE.spellTextCache[spellID].icon = icon
            return name, icon
        end
    end
    return nil, 134400
end

local function NormalizeSpellDescText(text)
    local s = tostring(text or "")
    if s == "" then
        return ""
    end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
    s = s:gsub("|r", "")
    s = s:gsub("\r\n", "\n")
    return s
end

local function WrapColorText(text, color)
    local body = tostring(text or "")
    if body == "" then
        return ""
    end
    if type(color) ~= "table" then
        return body
    end
    local r = math.floor((tonumber(color.r) or 1) * 255 + 0.5)
    local g = math.floor((tonumber(color.g) or 1) * 255 + 0.5)
    local b = math.floor((tonumber(color.b) or 1) * 255 + 0.5)
    return string.format("|cff%02x%02x%02x%s|r", r, g, b, body)
end

local function GetSpellDescription(spellID)
    if not spellID then
        return "No description available."
    end
    local cached = CARD_CACHE.spellTextCache[spellID]
    if type(cached) == "table" and type(cached.desc) == "string" and cached.desc ~= "" then
        return cached.desc
    end

    if C_TooltipInfo and C_TooltipInfo.GetSpellByID then
        local ok, tip = pcall(C_TooltipInfo.GetSpellByID, spellID)
        if ok and tip and tip.lines then
            local lines = {}
            for i, line in ipairs(tip.lines) do
                local text = line and line.leftText
                if i > 1 and text and text ~= "" then
                    text = NormalizeSpellDescText(text)
                    if text ~= "" then
                        table.insert(lines, WrapColorText(text, line.leftColor))
                    end
                end
            end
            if #lines > 0 then
                local desc
                if #lines >= 2 then
                    desc = "\n" .. lines[1] .. "\n\n" .. table.concat(lines, "\n", 2)
                else
                    desc = "\n" .. table.concat(lines, "\n")
                end
                CARD_CACHE.spellTextCache[spellID] = CARD_CACHE.spellTextCache[spellID] or {}
                CARD_CACHE.spellTextCache[spellID].desc = desc
                return desc
            end
        end
    end

    if C_Spell and C_Spell.GetSpellDescription then
        local ok, desc = pcall(C_Spell.GetSpellDescription, spellID)
        if ok and desc and desc ~= "" then
            desc = NormalizeSpellDescText(desc)
            CARD_CACHE.spellTextCache[spellID] = CARD_CACHE.spellTextCache[spellID] or {}
            CARD_CACHE.spellTextCache[spellID].desc = desc
            return desc
        end
    end

    CARD_CACHE.spellTextCache[spellID] = CARD_CACHE.spellTextCache[spellID] or {}
    CARD_CACHE.spellTextCache[spellID].desc = "No description available."
    return "No description available."
end

local function ComputeSpellDescRows(descText)
    local text = tostring(descText or "")
    if text == "" then
        return 5
    end
    local gw = (UI.spellSettingsGridChild and UI.spellSettingsGridChild:GetWidth()) or 760
    local cell = (gw - 20) / SPELL_SETTINGS_GRID_COLS
    if cell < 6 then cell = 6 end
    local descWidthPx = math.max(200, math.floor(77 * cell - 2))
    local descRowsMin = 5

    if not _spellDescMeasureFS then
        _spellDescMeasureFS = UIParent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        _spellDescMeasureFS:Hide()
        _spellDescMeasureFS:SetWordWrap(true)
        _spellDescMeasureFS:SetJustifyH("LEFT")
        _spellDescMeasureFS:SetSpacing(0)
    end
    _spellDescMeasureFS:SetWidth(descWidthPx)
    _spellDescMeasureFS:SetText(text)

    local h = _spellDescMeasureFS:GetStringHeight() or 0
    local rows = math.ceil((h + 6) / cell)
    if rows < descRowsMin then
        rows = descRowsMin
    end
    return rows
end

local function SplitSpellDescription(descText)
    local lines = {}
    for raw in tostring(descText or ""):gmatch("[^\n]+") do
        local line = tostring(raw):gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            lines[#lines + 1] = line
        end
    end

    local castLine = lines[1] or ""
    if #lines <= 1 then
        return castLine, ""
    end

    local body = table.concat(lines, "\n\n", 2)
    return castLine, body
end

local function RefreshSpellDetailHeaderLayout()
    if not (UI.spellDetailHeader and UI.spellDetailTitle and UI.spellDetailMeta and UI.spellDetailCast and UI.spellDetailBody) then
        return
    end

    local headerW = UI.spellDetailHeader:GetWidth() or 0
    if headerW <= 0 and UI.spellSettingsFrame then
        headerW = (UI.spellSettingsFrame:GetWidth() or 0) - 16
    end
    if headerW <= 0 then
        headerW = 980
    end

    local metaWidth = math.min(300, math.floor(headerW * 0.28))
    local titleNatural = math.ceil(UI.spellDetailTitle:GetUnboundedStringWidth() or 0) + 8
    local titleWidth = math.min(
        math.max(220, headerW - 44 - 14 - 12 - 12 - metaWidth - 18),
        math.max(120, titleNatural)
    )
    local bodyWidth = math.max(320, headerW - 44 - 14 - 12 - 18)

    UI.spellDetailTitle:SetWidth(titleWidth)
    UI.spellDetailMeta:ClearAllPoints()
    UI.spellDetailMeta:SetPoint("LEFT", UI.spellDetailTitle, "RIGHT", 6, 0)
    UI.spellDetailMeta:SetPoint("RIGHT", UI.spellDetailHeader, "RIGHT", -18, 0)
    UI.spellDetailCast:SetWidth(bodyWidth)
    UI.spellDetailBody:SetWidth(bodyWidth)

    local castH = UI.spellDetailCast:GetStringHeight() or 0
    local bodyH = UI.spellDetailBody:GetStringHeight() or 0
    local desiredHeight = math.max(98, math.ceil(50 + castH + 6 + bodyH + 8))
    UI.spellDetailHeader:SetHeight(desiredHeight)
end

local function BuildSpellSettingsLayout(spellName, spellIdentifier, eventID, spellIcon, iconFlags)
    for i = #SETTINGS_LAYOUT, 1, -1 do
        SETTINGS_LAYOUT[i] = nil
    end

    local rows = {
        { key = "enabled", type = "checkbox", x = 1, y = 1, w = 16, h = 2, label = "Enable", labelSize = 18 },
        { key = "eventColorEnabled", type = "checkbox", x = 1, y = 4, w = 12, h = 2, label = "Enable Color Override" },
        {
            key = "eventColorMode",
            type = "dropdown",
            x = 14,
            y = 4,
            w = 18,
            h = 2,
            label = "",
            labelPos = "left",
            items = EVENT_COLOR_ITEMS_FUNC,
        },
        { key = "eventColor", type = "color", x = 33, y = 4, w = 17, h = 2, label = "Custom Color" },
        { key = "divider_text", type = "divider", x = 1, y = 7, w = 81, h = 1, label = "Text Settings" },
        { key = "centralEnabled", type = "checkbox", x = 1, y = 9, w = 12, h = 2, label = "Center Text" },
        { key = "centralLead", type = "input", x = 14, y = 9, w = 8, h = 2, label = "Early (sec)" },
        { key = "centralText", type = "input", x = 23, y = 9, w = 27, h = 2, label = "Center text ({name} available)" },
        { key = "preAlertEnabled", type = "checkbox", x = 1, y = 13, w = 12, h = 2, label = "5 Sec Early" },
        { key = "preAlertText", type = "input", x = 14, y = 13, w = 36, h = 2, label = "({name} available)", labelPos = "right" },
        { key = "timerBarRenameEnabled", type = "checkbox", x = 1, y = 17, w = 12, h = 2, label = "Rename Timer Bar" },
        { key = "timerBarRenameText", type = "input", x = 14, y = 17, w = 36, h = 2, label = "" },
        { key = "divider_voice", type = "divider", x = 1, y = 20, w = 81, h = 1, label = "Voice Settings" },

        { key = "tr0Enabled", type = "checkbox", x = 1, y = 23, w = 10, h = 2, label = TRIGGER_NAME[0] },
        { key = "tr0Source", type = "dropdown", x = 11, y = 23, w = 10, h = 2, label = "Voice Source", items = TRIGGER_SOURCE_ITEMS },
        { key = "tr0Label", type = "dropdown", x = 22, y = 23, w = 27, h = 2, label = "Voice Label", items = LABEL_ITEMS_FUNC },
        { key = "tr0LSM", type = "lsm_sound", x = 22, y = 23, w = 27, h = 2, label = "LSM Sound" },
        { key = "tr0Path", type = "input", x = 22, y = 23, w = 27, h = 2, label = "File Path" },
        { key = "tr0ValueTest", type = "button", x = 50, y = 23, w = 4, h = 2, label = "Preview" },

        { key = "tr1Enabled", type = "checkbox", x = 1, y = 27, w = 10, h = 2, label = TRIGGER_NAME[1] },
        { key = "tr1Source", type = "dropdown", x = 11, y = 27, w = 10, h = 2, label = "Voice Source", items = TRIGGER_SOURCE_ITEMS },
        { key = "tr1Label", type = "dropdown", x = 22, y = 27, w = 27, h = 2, label = "Voice Label", items = LABEL_ITEMS_FUNC },
        { key = "tr1LSM", type = "lsm_sound", x = 22, y = 27, w = 27, h = 2, label = "LSM Sound" },
        { key = "tr1Path", type = "input", x = 22, y = 27, w = 27, h = 2, label = "File Path" },
        { key = "tr1ValueTest", type = "button", x = 50, y = 27, w = 4, h = 2, label = "Preview" },
        { key = "tr1OffsetMode", type = "dropdown", x = 55, y = 27, w = 8, h = 2, label = "", items = TRIGGER_OFFSET_MODE_ITEMS },
        { key = "tr1OffsetSeconds", type = "input", x = 64, y = 27, w = 6, h = 2, label = "sec", labelPos = "right" },

        { key = "tr2Enabled", type = "checkbox", x = 1, y = 31, w = 10, h = 2, label = TRIGGER_NAME[2] },
        { key = "tr2Source", type = "dropdown", x = 11, y = 31, w = 10, h = 2, label = "Voice Source", items = TRIGGER_SOURCE_ITEMS },
        { key = "tr2Label", type = "dropdown", x = 22, y = 31, w = 27, h = 2, label = "Voice Label", items = LABEL_ITEMS_FUNC },
        { key = "tr2LSM", type = "lsm_sound", x = 22, y = 31, w = 27, h = 2, label = "LSM Sound" },
        { key = "tr2Path", type = "input", x = 22, y = 31, w = 27, h = 2, label = "File Path" },
        { key = "tr2ValueTest", type = "button", x = 50, y = 31, w = 4, h = 2, label = "Preview" },
        { key = "tr2OffsetMode", type = "dropdown", x = 55, y = 31, w = 8, h = 2, label = "", items = TRIGGER_OFFSET_MODE_ITEMS },
        { key = "tr2OffsetSeconds", type = "input", x = 64, y = 31, w = 6, h = 2, label = "sec", labelPos = "right" },
    }
    if ENABLE_ADVANCED_CONDITIONS then
        rows[#rows + 1] = { key = "divider_conditions", type = "divider", x = 1, y = 34, w = 81, h = 1, label = "Advanced Conditions (event window + boss cast)" }
        rows[#rows + 1] = { key = "advCondEnabled", type = "checkbox", x = 1, y = 36, w = 18, h = 2, label = "Enable Advanced Conditions" }
        rows[#rows + 1] = { key = "advCondWindowBefore", type = "input", x = 20, y = 36, w = 8, h = 2, label = "Window Before (sec)" }
        rows[#rows + 1] = { key = "advCondWindowAfter", type = "input", x = 29, y = 36, w = 8, h = 2, label = "Window After (sec)" }
        rows[#rows + 1] = { key = "advCondRingEnabled", type = "checkbox", x = 39, y = 36, w = 16, h = 2, label = "Show Ring on Match" }
    end

    for _, row in ipairs(rows) do
        SETTINGS_LAYOUT[#SETTINGS_LAYOUT + 1] = row
    end
    InfinityTools:RegisterModuleLayout(SETTINGS_MODULE_KEY, SETTINGS_LAYOUT)
end

local function UpdateSpellDetailHeader(spellName, spellIdentifier, eventID, spellIcon, iconFlags, alertMarkupOverride)
    if not UI.spellDetailHeader then
        return
    end

    local safeName = tostring(spellName or "No spell selected")
    local sid = tonumber(spellIdentifier)
    local eid = tonumber(eventID)
    local descText = GetSpellDescription(sid)
    local castLine, bodyText = SplitSpellDescription(descText)
    local alertMarkup = tostring(alertMarkupOverride or "") ~= "" and tostring(alertMarkupOverride) or BuildPrimaryCategoryMarkup(eid, 20, -1)

    UI.spellDetailHeader:Show()
    UI.spellDetailPlaceholder:Hide()
    UI.spellDetailIcon:SetTexture(spellIcon or 134400)
    UI.spellDetailIcon:Show()
    UI.spellDetailTitle:SetText(safeName)
    UI.spellDetailMeta:SetText(string.format(
        "%s |cff7f8794spell:%s  event:%s|r",
        alertMarkup ~= "" and alertMarkup or "",
        tostring(sid or "-"),
        tostring(eid or "-")
    ))
    UI.spellDetailCast:SetText(castLine or "")
    UI.spellDetailBody:SetText((bodyText and bodyText ~= "") and bodyText or "No description available.")
    RefreshSpellDetailHeaderLayout()
end

local function SetSpellDetailHeaderEmpty(message)
    if not UI.spellDetailHeader then
        return
    end

    UI.spellDetailHeader:Show()
    UI.spellDetailPlaceholder:SetText(tostring(message or "Click a spell card above to view its description here."))
    UI.spellDetailPlaceholder:Show()
    UI.spellDetailIcon:Hide()
    UI.spellDetailTitle:SetText("")
    UI.spellDetailMeta:SetText("")
    UI.spellDetailCast:SetText("")
    UI.spellDetailBody:SetText("")
    UI.spellDetailHeader:SetHeight(98)
end

local function SyncModuleDBFromSelectedSpell()
    local encounterID = GetCurrentEncounterID()
    local boss = GetCurrentBoss()
    if not (encounterID and boss and type(boss.events) == "table") then return end
    local selectedEvent
    for _, e in ipairs(boss.events) do
        if GetEventID(e) == tonumber(selectedEventID) then
            selectedEvent = e
            break
        end
    end
    if not selectedEvent then return end
    local eventID = GetEventID(selectedEvent)
    local spellIdentifier = GetEventSpellIdentifier(selectedEvent)
    if not eventID then return end

    local row = GetSpellOverride(encounterID, eventID, spellIdentifier, false)
    if not row then return end
    local voiceCfg = GetEventVoiceConfig(eventID, spellIdentifier, false)

    local mdb = InfinityTools:GetModuleDB(SETTINGS_MODULE_KEY, SETTINGS_DEFAULTS)
    if type(mdb) ~= "table" then return end

    _settingsSyncLock = true
    mdb.enabled = (row.enabled ~= false)
    mdb.centralEnabled = (row.centralEnabled == true)
    mdb.centralLead = tostring(tonumber(row.centralLead) or 0)
    mdb.centralText = tostring(row.centralText or "")
    mdb.preAlertEnabled = (row.preAlertEnabled ~= false)
    mdb.preAlertText = tostring(row.preAlertText or "")
    mdb.timerBarRenameEnabled = (row.timerBarRenameEnabled == true)
    mdb.timerBarRenameText = tostring(row.timerBarRenameText or "")
    for i = 0, 2 do
        local t = voiceCfg and voiceCfg.triggers and voiceCfg.triggers[i] or nil
        local prefix = "tr" .. tostring(i)
        mdb[prefix .. "Enabled"] = (t and t.enabled ~= false) or false
        mdb[prefix .. "Source"] = NormalizeTriggerSource(t and t.sourceType or "pack")
        mdb[prefix .. "Label"] = NormalizeTriggerPackLabel(i, t and t.sourceType or "pack", (t and t.label) or "")
        mdb[prefix .. "LSM"] = tostring((t and t.customLSM) or "")
        mdb[prefix .. "Path"] = tostring((t and t.customPath) or "")
        if i == 1 or i == 2 then
            mdb[prefix .. "OffsetMode"] = NormalizeTriggerOffsetMode(t and t.fixedOffsetMode or "delay")
            mdb[prefix .. "OffsetSeconds"] = tostring(NormalizeTriggerOffsetSeconds(t and t.fixedOffsetSeconds or 0))
        end
    end
    ApplyLinkedTextPresets(mdb, row, nil)
    local c = (type(row.color) == "table") and row.color or nil
    mdb.eventColorEnabled = (c and c.enabled ~= false) and true or false
    if c and c.enabled ~= false then
        local mode = SETTINGS_DEFAULTS.eventColorMode
        if c.useCustom == true then
            mode = "__custom"
        elseif type(c.scheme) == "string" and c.scheme ~= "" then
            mode = NormalizeEventColorMode(c.scheme)
        elseif c.r ~= nil and c.g ~= nil and c.b ~= nil then
            mode = "__custom"
        end
        mdb.eventColorMode = mode
    else
        mdb.eventColorMode = SETTINGS_DEFAULTS.eventColorMode
    end
    local fallbackR = SETTINGS_DEFAULTS.eventColorR
    local fallbackG = SETTINGS_DEFAULTS.eventColorG
    local fallbackB = SETTINGS_DEFAULTS.eventColorB
    if mdb.eventColorMode == "__custom" then
        local CS = GetColorSchemeModule()
        if CS and CS.GetCustomColor then
            fallbackR, fallbackG, fallbackB = CS.GetCustomColor()
        end
    end
    mdb.eventColorR = Clamp01(c and c.r, fallbackR)
    mdb.eventColorG = Clamp01(c and c.g, fallbackG)
    mdb.eventColorB = Clamp01(c and c.b, fallbackB)
    _settingsSyncLock = false
end

local function RestartRunningEncounterIfNeeded(encounterID)
    local sched = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
    if not (sched and sched._running and sched.StartBoss) then return end
    if tonumber(sched._encounterID) ~= tonumber(encounterID) then return end
    sched:StartBoss(encounterID)
end

local function CaptureSelectedSpellContext()
    local encounterID = GetCurrentEncounterID()
    local boss = GetCurrentBoss()
    if not (encounterID and boss and type(boss.events) == "table") then
        return nil
    end
    for _, e in ipairs(boss.events) do
        if GetEventID(e) == tonumber(selectedEventID) then
            local eventID = GetEventID(e)
            if eventID then
                return {
                    encounterID = encounterID,
                    eventID = eventID,
                    spellIdentifier = GetEventSpellIdentifier(e),
                }
            end
            break
        end
    end
    return nil
end

local function ApplyPersistedSpellSideEffects(ctx)
    if type(ctx) ~= "table" or not ctx.eventID then
        return
    end
    local bossCfg = GetBossConfig()
    if bossCfg and bossCfg.ApplyPersistedChange then
        bossCfg:ApplyPersistedChange(ctx.eventID)
    end
    RestartRunningEncounterIfNeeded(ctx.encounterID)
end

local function PersistCurrentSpellForSwitch()
    local ctx = CaptureSelectedSpellContext()
    if not ctx then
        return
    end
    PersistModuleDBToSelectedSpell()
    ApplyPersistedSpellSideEffects(ctx)
end

local function PersistSelectionBeforeNavigation()
    PersistCurrentSpellForSwitch()
    PersistActivePrivateAuraConfig()
end

PersistModuleDBToSelectedSpell = function(changedKey)
    if _settingsSyncLock then return end
    local ctx = CaptureSelectedSpellContext()
    if not ctx then return end
    local encounterID = ctx.encounterID
    local eventID = ctx.eventID
    local spellIdentifier = ctx.spellIdentifier

    local mdb = InfinityTools:GetModuleDB(SETTINGS_MODULE_KEY, SETTINGS_DEFAULTS)
    if type(mdb) ~= "table" then return end

    local row = GetSpellOverride(encounterID, eventID, spellIdentifier, true)
    if not row then return end
    local linkedPresetApplied = ApplyLinkedTextPresets(mdb, row, changedKey)

    if not changedKey or changedKey == "enabled" then
        row.enabled = (mdb.enabled == true)
    end
    StripLegacyRoleFields(row)
    if not changedKey or changedKey == "centralEnabled" then
        row.centralEnabled = (mdb.centralEnabled == true)
    end
    if not changedKey or changedKey == "centralLead" then
        local lead = tonumber(mdb.centralLead) or 0
        if lead < 0 then lead = 0 end
        if lead > 30 then lead = 30 end
        row.centralLead = lead
    end
    if not changedKey or changedKey == "centralText" then
        row.centralText = NormalizeOptionText(mdb.centralText)
    end
    if not changedKey or changedKey == "preAlertEnabled" then
        row.preAlertEnabled = (mdb.preAlertEnabled == true)
    end
    row.preAlert = (mdb.preAlertEnabled == true) and PREALERT_FIXED_SECS or 0
    if not changedKey or changedKey == "preAlertText" then
        row.preAlertText = NormalizeOptionText(mdb.preAlertText)
    end
    if not changedKey or changedKey == "timerBarRenameEnabled" then
        row.timerBarRenameEnabled = (mdb.timerBarRenameEnabled == true)
    end
    if not changedKey or changedKey == "timerBarRenameText" then
        row.timerBarRenameText = NormalizeOptionText(mdb.timerBarRenameText)
    end

    local voiceCfg = GetEventVoiceConfig(eventID, spellIdentifier, true)
    if voiceCfg then
        voiceCfg.enabled = (row.enabled == true)
        StripLegacyRoleFields(voiceCfg)
        voiceCfg.triggers = type(voiceCfg.triggers) == "table" and voiceCfg.triggers or {}
        for i = 0, 2 do
            local prefix = "tr" .. tostring(i)
            local trig = voiceCfg.triggers[i]
            if type(trig) ~= "table" then
                trig = {}
                voiceCfg.triggers[i] = trig
            end
            trig.enabled = (mdb[prefix .. "Enabled"] == true)
            trig.sourceType = NormalizeTriggerSource(mdb[prefix .. "Source"])
            local label = NormalizeTriggerPackLabel(i, mdb[prefix .. "Source"], mdb[prefix .. "Label"])
            local lsm = NormalizeOptionText(mdb[prefix .. "LSM"])
            local path = NormalizeOptionText(mdb[prefix .. "Path"])
            if trig.sourceType == "pack" then
                trig.label = label
                trig.customLSM = nil
                trig.customPath = nil
            elseif trig.sourceType == "lsm" then
                trig.label = nil
                trig.customLSM = lsm
                trig.customPath = nil
            else
                trig.label = nil
                trig.customLSM = nil
                trig.customPath = path
            end
            if i == 1 or i == 2 then
                trig.fixedOffsetMode = NormalizeTriggerOffsetMode(mdb[prefix .. "OffsetMode"])
                trig.fixedOffsetSeconds = NormalizeTriggerOffsetSeconds(mdb[prefix .. "OffsetSeconds"])
            else
                trig.fixedOffsetMode = nil
                trig.fixedOffsetSeconds = nil
            end
        end

        if mdb.eventColorEnabled == true then
            row.color = row.color or {}
            row.color.enabled = true
            local mode = NormalizeEventColorMode(mdb.eventColorMode)
            if mode == "__custom" then
                row.color.useCustom = true
                row.color.scheme = "__custom"
                row.color.r = Clamp01(mdb.eventColorR, SETTINGS_DEFAULTS.eventColorR)
                row.color.g = Clamp01(mdb.eventColorG, SETTINGS_DEFAULTS.eventColorG)
                row.color.b = Clamp01(mdb.eventColorB, SETTINGS_DEFAULTS.eventColorB)
            else
                row.color.useCustom = false
                row.color.scheme = mode
                row.color.r = nil
                row.color.g = nil
                row.color.b = nil
            end
        else
            row.color = {
                enabled = false,
            }
        end
    end

    CompactEventOverride(eventID)
    return linkedPresetApplied
end

local function SaveSelection()
    local db = GetPanelDB()
    db.selectedSeason = selectedSeason
    db.selectedMapID = selectedMapID
    db.selectedBossIdx = selectedBossIndex
end

local function NormalizeSelection()
    local seasons = BuildSeasonList()
    local seasonValid = false
    for _, s in ipairs(seasons) do
        if s == selectedSeason then
            seasonValid = true
            break
        end
    end
    if not seasonValid then
        selectedSeason = seasons[1]
    end

    local mapList = BuildMapList(selectedSeason)
    local mapValid = false
    for _, mapID in ipairs(mapList) do
        if tonumber(mapID) == tonumber(selectedMapID) then
            mapValid = true
            break
        end
    end
    if not mapValid then
        selectedMapID = mapList[1]
    end

    local bossList = BuildBossList(selectedMapID)
    local idx = tonumber(selectedBossIndex)
    if #bossList == 0 then
        selectedBossIndex = nil
    elseif not idx or idx < 1 or idx > #bossList then
        selectedBossIndex = 1
    end

    SaveSelection()
    return seasons, mapList, bossList
end

local function ReleaseMapTabs()
    for i = 1, #CARD_CACHE.activeMapTabs do
        local b = CARD_CACHE.activeMapTabs[i]
        b:Hide()
        b:ClearAllPoints()
        b:SetParent(nil)
        table.insert(CARD_CACHE.mapTabPool, b)
    end
    wipe(CARD_CACHE.activeMapTabs)
end

local function AcquireMapTab()
    local b = table.remove(CARD_CACHE.mapTabPool)
    if b then return b end

    b = CreateFrame("Button", nil, UI.mapScrollChild, "BackdropTemplate")
    b:SetSize(72, 74)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(44, 44)
    b.icon:SetPoint("TOP", 0, -4)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("TOP", b.icon, "BOTTOM", 0, -3)
    b.text:SetWidth(68)
    b.text:SetJustifyH("CENTER")
    b.text:SetWordWrap(false)
    b.text:SetFont(InfinityTools.MAIN_FONT, 11, "OUTLINE")

    b:SetScript("OnEnter", function(self)
        self._hovered = true
        if self._applyVisual then self:_applyVisual() end
    end)
    b:SetScript("OnLeave", function(self)
        self._hovered = false
        if self._applyVisual then self:_applyVisual() end
    end)

    return b
end

local function ReleaseBossCards()
    for i = 1, #CARD_CACHE.activeBossCards do
        local b = CARD_CACHE.activeBossCards[i]
        b:Hide()
        b:ClearAllPoints()
        b:SetParent(nil)
        table.insert(CARD_CACHE.bossCardPool, b)
    end
    wipe(CARD_CACHE.activeBossCards)
end

local function AcquireBossCard()
    local b = table.remove(CARD_CACHE.bossCardPool)
    if b then return b end

    b = CreateFrame("Button", nil, UI.bossScrollContent, "BackdropTemplate")
    b:SetSize(184, 68)
    b:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    b.activeBar = b:CreateTexture(nil, "OVERLAY")
    b.activeBar:SetPoint("TOPLEFT", 4, -4)
    b.activeBar:SetPoint("BOTTOMLEFT", 4, 4)
    b.activeBar:SetWidth(4)
    b.activeBar:SetColorTexture(0, 0.7, 1, 1)
    b.activeBar:Hide()

    b.creature = CreateFrame("PlayerModel", nil, b)
    b.creature:SetSize(82, 62)
    b.creature:SetPoint("LEFT", 6, 0)
    b.creature:SetFrameLevel(b:GetFrameLevel() + 3)
    b.creature:EnableMouse(false)

    b.noPortraitText = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.noPortraitText:SetPoint("CENTER", b.creature, "CENTER", 0, 0)
    b.noPortraitText:SetText("No portrait")
    b.noPortraitText:Hide()

    b.nameText = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    b.nameText:SetPoint("TOPLEFT", b.creature, "TOPRIGHT", 10, -8)
    b.nameText:SetPoint("RIGHT", b, "RIGHT", -8, 0)
    b.nameText:SetJustifyH("LEFT")
    b.nameText:SetWordWrap(false)
    b.nameText:SetFont(InfinityTools.MAIN_FONT, 14, "OUTLINE")

    b.detailText = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.detailText:SetPoint("TOPLEFT", b.nameText, "BOTTOMLEFT", 0, -4)
    b.detailText:SetPoint("RIGHT", b, "RIGHT", -8, 0)
    b.detailText:SetJustifyH("LEFT")

    b:SetScript("OnEnter", function(self)
        self._hovered = true
        if self._applyVisual then self:_applyVisual() end
    end)
    b:SetScript("OnLeave", function(self)
        self._hovered = false
        if self._applyVisual then self:_applyVisual() end
    end)

    return b
end

local function ReleaseSpellCards()
    for i = 1, #CARD_CACHE.activeSpellCards do
        local card = CARD_CACHE.activeSpellCards[i]
        card:Hide()
        card:ClearAllPoints()
        card:SetParent(nil)
        card.eventData = nil
        table.insert(CARD_CACHE.spellCardPool, card)
    end
    wipe(CARD_CACHE.activeSpellCards)
end

local function AcquireSpellCard()
    local card = table.remove(CARD_CACHE.spellCardPool)
    if card then return card end

    card = CreateFrame("Button", nil, UI.spellScrollChild, "BackdropTemplate")
    card:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    card:SetBackdropColor(0, 0, 0, 0.5)
    card:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.7)

    card.leftBar = card:CreateTexture(nil, "ARTWORK")
    card.leftBar:SetDrawLayer("ARTWORK", -8)
    card.leftBar:SetWidth(4)
    card.leftBar:SetPoint("TOPLEFT", 0, 0)
    card.leftBar:SetPoint("BOTTOMLEFT", 0, 0)

    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetDrawLayer("ARTWORK", 1)
    card.icon:SetSize(30, 30)
    card.icon:SetPoint("LEFT", 11, 0)
    card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    card.alertIcon = card:CreateTexture(nil, "OVERLAY")
    card.alertIcon:SetDrawLayer("OVERLAY", 7)
    card.alertIcon:SetSize(22, 22)
    card.alertIcon:SetPoint("LEFT", 9, 0)
    card.alertIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    card.alertIcon:Hide()

    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.title:SetPoint("LEFT", card.icon, "RIGHT", 8, 0)
    card.title:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    card.title:SetJustifyH("LEFT")
    card.title:SetJustifyV("MIDDLE")
    card.title:SetWordWrap(true)
    card.title:SetMaxLines(2)
    card.title:SetSpacing(1)
    card.title:SetFont(InfinityTools.MAIN_FONT, 18, "OUTLINE")

    card.desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.desc:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -6)
    card.desc:SetPoint("RIGHT", card, "RIGHT", -14, 0)
    card.desc:SetJustifyH("LEFT")
    card.desc:SetJustifyV("TOP")
    card.desc:SetWordWrap(true)
    card.desc:SetSpacing(2)

    card:SetScript("OnEnter", function(self)
        self._hovered = true
        if self._applyVisual then self:_applyVisual() end
    end)
    card:SetScript("OnLeave", function(self)
        self._hovered = false
        if self._applyVisual then self:_applyVisual() end
    end)

    return card
end

local function SetAdaptiveSpellCardTitle(card, text)
    if not (card and card.title) then
        return
    end

    local title = card.title
    local finalText = tostring(text or "")
    local maxHeight = 26

    for i = 1, #SPELL_CARD.titleFontSizes do
        local size = SPELL_CARD.titleFontSizes[i]
        title:SetFont(InfinityTools.MAIN_FONT, size, "OUTLINE")
        title:SetSpacing(size <= 14 and 0 or 1)
        title:SetText(finalText)
        if (title:GetStringHeight() or 0) <= maxHeight then
            return
        end
    end

    title:SetText(finalText)
end

local function EnsureUI(leftFrame, contentFrame)
    if UI.leftRoot and UI.rightRoot then return end

    UI.leftRoot = CreateFrame("Frame", nil, leftFrame)
    UI.leftRoot:SetAllPoints(leftFrame)

    local InfinityUI = InfinityTools.UI
    if InfinityUI and InfinityUI.CreateDropdown then
        UI.seasonDropdown = InfinityUI:CreateDropdown(
            UI.leftRoot,
            260,
            "",
            {},
            selectedSeason,
            function(val)
                if tostring(val or "") == tostring(selectedSeason or "") then return end
                PersistSelectionBeforeNavigation()
                selectedSeason = val
                selectedMapID = nil
                selectedBossIndex = nil
                selectedEventID = nil
                selectedPrivateAuraKey = nil
                local seasons = NormalizeSelection()
                RefreshSeasonDropdown(seasons)
                RefreshMapTabs(true)
                RefreshBossList(true)
                UpdateSummary()
                RefreshModeButton()
                RefreshSpellCards()
            end
        )
        UI.seasonDropdown:ClearAllPoints()
        UI.seasonDropdown:SetPoint("TOPLEFT", UI.leftRoot, "TOPLEFT", 10, -10)
        UI.seasonDropdown:SetPoint("TOPRIGHT", UI.leftRoot, "TOPRIGHT", -24, -10)
    end

    local mapTitle = UI.leftRoot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if UI.seasonDropdown then
        mapTitle:SetPoint("TOPLEFT", UI.seasonDropdown, "BOTTOMLEFT", 0, -10)
    else
        mapTitle:SetPoint("TOPLEFT", UI.leftRoot, "TOPLEFT", 10, -10)
    end
    mapTitle:SetText("Dungeon Selection")
    mapTitle:SetTextColor(0.733, 0.4, 1.0)
    mapTitle:SetFont(InfinityTools.MAIN_FONT, 14, "OUTLINE")
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(mapTitle, "text") end

    UI.mapScrollFrame = CreateFrame("ScrollFrame", nil, UI.leftRoot, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(UI.mapScrollFrame)
    end
    UI.mapScrollFrame:SetPoint("TOPLEFT", mapTitle, "BOTTOMLEFT", -2, -4)
    UI.mapScrollFrame:SetPoint("TOPRIGHT", UI.leftRoot, "TOPRIGHT", -24, -44)
    UI.mapScrollFrame:SetHeight(210)

    UI.mapScrollChild = CreateFrame("Frame", nil, UI.mapScrollFrame)
    UI.mapScrollChild:SetSize(208, 1)
    UI.mapScrollFrame:SetScrollChild(UI.mapScrollChild)

    UI.mapEmptyText = UI.mapScrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    UI.mapEmptyText:SetPoint("CENTER", 0, 0)
    UI.mapEmptyText:SetTextColor(0.55, 0.55, 0.55)
    UI.mapEmptyText:SetText("No dungeon data for this category")

    local sep = UI.leftRoot:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", UI.mapScrollFrame, "BOTTOMLEFT", 6, -3)
    sep:SetPoint("TOPRIGHT", UI.mapScrollFrame, "BOTTOMRIGHT", -6, -3)
    sep:SetColorTexture(1, 1, 1, 0.18)

    local bossTitle = UI.leftRoot:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bossTitle:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 4, -6)
    bossTitle:SetText("Boss List")
    bossTitle:SetTextColor(0.733, 0.4, 1.0)
    bossTitle:SetFont(InfinityTools.MAIN_FONT, 14, "OUTLINE")
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(bossTitle, "text") end

    UI.bossScrollFrame = CreateFrame("ScrollFrame", nil, UI.leftRoot, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(UI.bossScrollFrame)
    end
    UI.bossScrollFrame:SetPoint("TOPLEFT", bossTitle, "BOTTOMLEFT", -2, -4)
    UI.bossScrollFrame:SetPoint("BOTTOMRIGHT", UI.leftRoot, "BOTTOMRIGHT", -24, 10)

    UI.bossScrollContent = CreateFrame("Frame", nil, UI.bossScrollFrame)
    UI.bossScrollContent:SetSize(200, 1)
    UI.bossScrollFrame:SetScrollChild(UI.bossScrollContent)

    UI.bossEmptyText = UI.bossScrollContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    UI.bossEmptyText:SetPoint("TOPLEFT", 8, -6)
    UI.bossEmptyText:SetPoint("RIGHT", -8, 0)
    UI.bossEmptyText:SetJustifyH("LEFT")
    UI.bossEmptyText:SetTextColor(0.55, 0.55, 0.55)
    UI.bossEmptyText:SetText("No boss data for this dungeon")

    UI.rightRoot = CreateFrame("Frame", nil, contentFrame)
    UI.rightRoot:SetAllPoints(contentFrame)

    InfinityUI = InfinityTools.UI
    local panelFrame = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel._frame
    if panelFrame and not UI.titleControlHost then
        UI.titleControlHost = CreateFrame("Frame", nil, panelFrame)
        UI.titleControlHost:SetSize(420, 26)
        UI.titleControlHost:SetFrameLevel((panelFrame:GetFrameLevel() or 1) + 20)
        if panelFrame._editModeBtn then
            UI.titleControlHost:SetPoint("RIGHT", panelFrame._editModeBtn, "LEFT", -14, 0)
        else
            UI.titleControlHost:SetPoint("TOPRIGHT", panelFrame, "TOPRIGHT", -140, -7)
        end

        UI.modeLabelText = UI.titleControlHost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        UI.modeLabelText:SetPoint("RIGHT", UI.titleControlHost, "RIGHT", -196, 0)
        UI.modeLabelText:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
        UI.modeLabelText:SetTextColor(0.95, 0.95, 0.95)
        UI.modeLabelText:SetText("Timeline Mode")
    end

    if InfinityUI and InfinityUI.CreateDropdown and UI.titleControlHost and not UI.modeDropdown then
        UI.modeDropdown = InfinityUI:CreateDropdown(
            UI.titleControlHost,
            176,
            "",
            {
                { "Auto", "auto" },
                { "Fixed Timeline", "fixed" },
                { "Blizzard Native", "blizzard" },
            },
            "auto",
            function(val)
                local boss = GetCurrentBoss()
                local encounterID = boss and tonumber(boss.encounterID)
                if not encounterID then return end
                SetEncounterModeOverride(encounterID, val)
                if RefreshModeButton then
                    RefreshModeButton()
                end
                UpdateSummary()

                local sched = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
                if sched and sched._running and tonumber(sched._encounterID) == encounterID and sched.StartBoss then
                    sched:StartBoss(encounterID)
                end
                if InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine and InfinityBoss.Voice.Engine.ApplyEventOverridesToAPI then
                    C_Timer.After(0, function()
                        InfinityBoss.Voice.Engine:ApplyEventOverridesToAPI({
                            reason = "ui:timeline-mode-change",
                        })
                    end)
                end
            end
        )
        UI.modeDropdown:SetPoint("RIGHT", UI.titleControlHost, "RIGHT", 0, 0)
    end

    local function CreateTopTestButton(text)
        local b = CreateFrame("Button", nil, UI.rightRoot, "BackdropTemplate")
        b:SetSize(70, 28)
        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        b:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
        b:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.text:SetPoint("CENTER", 0, 0)
        b.text:SetFont(InfinityTools.MAIN_FONT, 13, "OUTLINE")
        b.text:SetText(text or "")
        b:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.1, 0.8, 1, 1)
        end)
        b:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
        end)
        return b
    end

    if UI.titleControlHost and not UI.modeTestStartBtn then
        UI.modeTestStartBtn = CreateTopTestButton("Test Start")
        UI.modeTestStartBtn:SetParent(UI.titleControlHost)
    end
    if UI.titleControlHost and not UI.modeTestEndBtn then
        UI.modeTestEndBtn = CreateTopTestButton("Test Stop")
        UI.modeTestEndBtn:SetParent(UI.titleControlHost)
    end

    if UI.modeDropdown and UI.modeTestStartBtn and UI.modeTestEndBtn then
        UI.modeTestEndBtn:SetPoint("RIGHT", UI.modeLabelText, "LEFT", -12, 0)
        UI.modeTestStartBtn:SetPoint("RIGHT", UI.modeTestEndBtn, "LEFT", -6, 0)
    end

    UI.modeTestStartBtn:SetScript("OnClick", function()
        local boss = GetCurrentBoss()
        local encounterID = boss and tonumber(boss.encounterID)
        if not encounterID then
            return
        end
        local encounterName = tostring((boss and (boss.bossName or boss.name)) or "Test Boss")
        local difficultyID = tonumber(InfinityTools and InfinityTools.State and InfinityTools.State.DifficultyID) or 8
        local groupSize = (IsInRaid and IsInRaid()) and 20 or 5
        if InfinityTools and InfinityTools.SendEvent then
            InfinityTools:SendEvent("ENCOUNTER_START", encounterID, encounterName, difficultyID, groupSize)
        else
        end

        StartTestTimelineLoop(encounterID)
    end)

    UI.modeTestEndBtn:SetScript("OnClick", function()
        local boss = GetCurrentBoss()
        local encounterID = boss and tonumber(boss.encounterID) or 0
        local encounterName = tostring((boss and (boss.bossName or boss.name)) or "Test Boss")
        local difficultyID = tonumber(InfinityTools and InfinityTools.State and InfinityTools.State.DifficultyID) or 8
        local groupSize = (IsInRaid and IsInRaid()) and 20 or 5
        if InfinityTools and InfinityTools.SendEvent then
            InfinityTools:SendEvent("ENCOUNTER_END", encounterID, encounterName, difficultyID, groupSize, 1)
        else
        end

        StopTestTimelineLoop()
    end)

    UI.spellSettingsFrame = CreateFrame("Frame", nil, UI.rightRoot, "BackdropTemplate")
    UI.spellSettingsFrame:SetPoint("BOTTOMLEFT", UI.rightRoot, "BOTTOMLEFT", 8, 8)
    UI.spellSettingsFrame:SetPoint("BOTTOMRIGHT", UI.rightRoot, "BOTTOMRIGHT", -8, 8)
    UI.spellSettingsFrame:SetHeight(660)
    UI.spellSettingsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    UI.spellSettingsFrame:SetBackdropColor(0.03, 0.04, 0.06, 0.92)
    UI.spellSettingsFrame:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)

    UI.spellDetailHeader = CreateFrame("Frame", nil, UI.spellSettingsFrame, "BackdropTemplate")
    UI.spellDetailHeader:SetPoint("TOPLEFT", UI.spellSettingsFrame, "TOPLEFT", 8, -8)
    UI.spellDetailHeader:SetPoint("TOPRIGHT", UI.spellSettingsFrame, "TOPRIGHT", -8, -8)
    UI.spellDetailHeader:SetHeight(144)
    UI.spellDetailHeader:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    UI.spellDetailHeader:SetBackdropColor(0.02, 0.03, 0.05, 0.96)
    UI.spellDetailHeader:SetBackdropBorderColor(0.22, 0.22, 0.28, 1)

    UI.spellDetailPlaceholder = UI.spellDetailHeader:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    UI.spellDetailPlaceholder:SetPoint("CENTER", 0, 0)
    UI.spellDetailPlaceholder:SetTextColor(0.55, 0.55, 0.6)
    UI.spellDetailPlaceholder:SetText("Click a spell card above to view its description here.")

    UI.spellDetailIcon = UI.spellDetailHeader:CreateTexture(nil, "ARTWORK")
    UI.spellDetailIcon:SetSize(52, 52)
    UI.spellDetailIcon:SetPoint("TOPLEFT", 10, -12)
    UI.spellDetailIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    UI.spellDetailTitle = UI.spellDetailHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.spellDetailTitle:SetPoint("TOPLEFT", UI.spellDetailIcon, "TOPRIGHT", 8, -1)
    UI.spellDetailTitle:SetJustifyH("LEFT")
    UI.spellDetailTitle:SetWordWrap(false)
    UI.spellDetailTitle:SetFont(InfinityTools.MAIN_FONT, 23, "OUTLINE")
    UI.spellDetailTitle:SetTextColor(1, 0.95, 0.55)

    UI.spellDetailMeta = UI.spellDetailHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    UI.spellDetailMeta:SetPoint("LEFT", UI.spellDetailTitle, "RIGHT", 10, 0)
    UI.spellDetailMeta:SetJustifyH("LEFT")
    UI.spellDetailMeta:SetWordWrap(false)
    UI.spellDetailMeta:SetFont(InfinityTools.MAIN_FONT, 16, "")
    UI.spellDetailMeta:SetTextColor(0.55, 0.57, 0.62)

    UI.spellDetailCast = UI.spellDetailHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    UI.spellDetailCast:SetPoint("TOPLEFT", UI.spellDetailTitle, "BOTTOMLEFT", 0, -2)
    UI.spellDetailCast:SetPoint("RIGHT", UI.spellDetailHeader, "RIGHT", -18, 0)
    UI.spellDetailCast:SetJustifyH("LEFT")
    UI.spellDetailCast:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
    UI.spellDetailCast:SetTextColor(0.92, 0.92, 0.95)

    UI.spellDetailBody = UI.spellDetailHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    UI.spellDetailBody:SetPoint("TOPLEFT", UI.spellDetailCast, "BOTTOMLEFT", 0, -8)
    UI.spellDetailBody:SetPoint("RIGHT", UI.spellDetailHeader, "RIGHT", -18, 0)
    UI.spellDetailBody:SetJustifyH("LEFT")
    UI.spellDetailBody:SetJustifyV("TOP")
    UI.spellDetailBody:SetWordWrap(true)
    UI.spellDetailBody:SetSpacing(2)
    UI.spellDetailBody:SetFont(InfinityTools.MAIN_FONT, 16, "OUTLINE")

    UI.spellDetailDivider = UI.spellDetailHeader:CreateTexture(nil, "ARTWORK")
    UI.spellDetailDivider:SetPoint("BOTTOMLEFT", UI.spellDetailHeader, "BOTTOMLEFT", 14, 10)
    UI.spellDetailDivider:SetPoint("BOTTOMRIGHT", UI.spellDetailHeader, "BOTTOMRIGHT", -14, 10)
    UI.spellDetailDivider:SetHeight(1)
    UI.spellDetailDivider:SetColorTexture(1, 1, 1, 0.14)
    UI.spellDetailDivider:Hide()

    UI.spellSettingsGridScroll = CreateFrame("ScrollFrame", nil, UI.spellSettingsFrame, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(UI.spellSettingsGridScroll)
    end
    UI.spellSettingsGridScroll:SetPoint("TOPLEFT", UI.spellDetailHeader, "BOTTOMLEFT", 0, -2)
    UI.spellSettingsGridScroll:SetPoint("BOTTOMRIGHT", UI.spellSettingsFrame, "BOTTOMRIGHT", -24, 6)

    UI.spellSettingsGridChild = CreateFrame("Frame", nil, UI.spellSettingsGridScroll)
    UI.spellSettingsGridChild:SetSize(760, 1)
    UI.spellSettingsGridScroll:SetScrollChild(UI.spellSettingsGridChild)

    UI.spellSettingsEmptyText = UI.spellSettingsGridChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    UI.spellSettingsEmptyText:SetPoint("TOPLEFT", 6, -6)
    UI.spellSettingsEmptyText:SetPoint("RIGHT", -6, 0)
    UI.spellSettingsEmptyText:SetJustifyH("LEFT")
    UI.spellSettingsEmptyText:SetWordWrap(true)
    UI.spellSettingsEmptyText:SetText("Click a spell card above to configure spell alert options.")

    UI.spellScrollFrame = CreateFrame("ScrollFrame", nil, UI.rightRoot, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(UI.spellScrollFrame)
    end
    UI.spellScrollFrame:SetPoint("TOPLEFT", UI.rightRoot, "TOPLEFT", 8, -8)
    UI.spellScrollFrame:SetPoint("BOTTOMRIGHT", UI.spellSettingsFrame, "TOPRIGHT", -16, 6)

    UI.spellScrollChild = CreateFrame("Frame", nil, UI.spellScrollFrame)
    UI.spellScrollChild:SetSize(760, 1)
    UI.spellScrollFrame:SetScrollChild(UI.spellScrollChild)

    UI.spellEmptyText = UI.spellScrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    UI.spellEmptyText:SetPoint("TOPLEFT", 4, -4)
    UI.spellEmptyText:SetPoint("RIGHT", -4, 0)
    UI.spellEmptyText:SetJustifyH("LEFT")
    UI.spellEmptyText:SetWordWrap(true)
    UI.spellEmptyText:SetText("Please select a boss with spell data")

    local panelDB = GetPanelDB()
    selectedSeason = panelDB.selectedSeason
    selectedMapID = panelDB.selectedMapID
    selectedBossIndex = panelDB.selectedBossIdx
end

local function ComputeSpellCardHeight(card)
    return SPELL_CARD.height
end

local function RefreshActiveMapTabVisuals()
    for i = 1, #CARD_CACHE.activeMapTabs do
        local tab = CARD_CACHE.activeMapTabs[i]
        if tab and tab._applyVisual then
            tab:_applyVisual()
        end
    end
end

local function RefreshActiveBossCardVisuals()
    for i = 1, #CARD_CACHE.activeBossCards do
        local card = CARD_CACHE.activeBossCards[i]
        if card then
            card._selected = (tonumber(card.index) == tonumber(selectedBossIndex))
            if card._applyVisual then
                card:_applyVisual()
            end
        end
    end
end

local function RefreshActiveSpellCardVisuals()
    local selected = tonumber(selectedEventID)
    for i = 1, #CARD_CACHE.activeSpellCards do
        local card = CARD_CACHE.activeSpellCards[i]
        if card then
            if card._selectionKey then
                card._selected = (selectedPrivateAuraKey and card._selectionKey == selectedPrivateAuraKey) and true or false
            else
                card._selected = (selected and tonumber(card._eventID) == selected) and true or false
            end
            if card._applyVisual then
                card:_applyVisual()
            end
        end
    end
end

local function RefreshSpellCardTitles()
    local encounterID = GetCurrentEncounterID()
    for i = 1, #CARD_CACHE.activeSpellCards do
        local card = CARD_CACHE.activeSpellCards[i]
        if card and not card._selectionKey and card.eventData then
            local event = card.eventData
            local eventID = GetEventID(event)
            local spellID = GetEventSpellIdentifier(event)
            local spellName = (event and event.name) or (spellID and select(1, GetSpellNameAndIcon(spellID))) or ("Unknown Spell " .. tostring(i))
            local override = encounterID and eventID and GetSpellOverride(encounterID, eventID, spellID, false) or nil
            local spellEnabled = not (override and override.enabled == false)

            local disableText = ""
            if not spellEnabled then
                if override and override.enabled == false then
                    disableText = " |cffff6666[Disabled]|r"
                end
            end
            SetAdaptiveSpellCardTitle(card, string.format("%s%s", tostring(spellName), disableText))
        end
    end
end

local function QueueSpellUIRefresh(delay)
    if _spellUIRefreshPending then
        return
    end
    _spellUIRefreshPending = true
    _spellUIRefreshToken = _spellUIRefreshToken + 1
    local token = _spellUIRefreshToken
    C_Timer.After(delay or 0.12, function()
        if token ~= _spellUIRefreshToken then
            return
        end
        _spellUIRefreshPending = false
        if not Page._visible then return end
        if RefreshSpellCards then
            RefreshSpellCards()
        end
    end)
end

UpdateSummary = function()
    if not UI.summaryText then
        return
    end
    local mapName = selectedMapID and GetMapDisplayName(selectedMapID) or "No dungeon selected"
    local boss = GetCurrentBoss()
    if not boss then
        UI.summaryText:SetText(string.format("|cffffd100[%s]|r  %s", tostring(selectedSeason or "-"), mapName))
        return
    end

    local events = boss.events or {}
    local encounterID = tonumber(boss.encounterID)
    local overrideMode = encounterID and GetEncounterModeOverride(encounterID) or "auto"
    local effectiveMode = encounterID and ResolveEffectiveMode(encounterID) or "blizzard"
    UI.summaryText:SetText(string.format(
        "|cffffd100[%s]|r  %s  >  %s  |  spells: |cff00ffcc%d|r  |  timeline: |cffffff99%s|r (active: %s)",
        tostring(selectedSeason or "-"),
        mapName,
        tostring(boss.name or "Unknown Boss"),
        #events,
        GetModeDisplay(overrideMode),
        GetModeDisplay(effectiveMode)
    ))
end

RefreshModeButton = function()
    if not UI.modeDropdown then return end
    local boss = GetCurrentBoss()
    local encounterID = boss and tonumber(boss.encounterID)
    if not encounterID then
        UI.modeDropdown._items = {
            { "Auto", "auto" },
            { "Blizzard Native", "blizzard" },
        }
        UI.modeDropdown._currentValue = "auto"
        UI.modeDropdown:SetText("None")
        if UI.modeDropdown.Disable then UI.modeDropdown:Disable() end
        return
    end

    local canFixed = IsFixedTimelineAvailable(encounterID)
    local overrideMode = GetEncounterModeOverride(encounterID)
    if overrideMode == "fixed" and not canFixed then
        SetEncounterModeOverride(encounterID, "blizzard")
        overrideMode = "blizzard"
    end
    local effectiveMode = ResolveEffectiveMode(encounterID)

    local items = {
        { "Auto", "auto" },
    }
    if canFixed then
        items[#items + 1] = { "Fixed Timeline", "fixed" }
    end
    items[#items + 1] = { "Blizzard Native", "blizzard" }

    UI.modeDropdown._items = items
    UI.modeDropdown._currentValue = overrideMode
    UI.modeDropdown:SetText(string.format("%s -> %s", GetModeDisplay(overrideMode), GetModeDisplay(effectiveMode)))
    if UI.modeDropdown.Enable then UI.modeDropdown:Enable() end
end

local function SyncScrollChildWidth()
    local sharedLeftW
    if UI.bossScrollFrame then
        sharedLeftW = (UI.bossScrollFrame:GetWidth() or 0) - 22
    elseif UI.mapScrollFrame then
        sharedLeftW = (UI.mapScrollFrame:GetWidth() or 0) - 22
    end
    if sharedLeftW then
        if sharedLeftW < 220 then sharedLeftW = 220 end
        if UI.mapScrollChild then
            UI.mapScrollChild:SetWidth(sharedLeftW)
        end
        if UI.bossScrollContent then
            UI.bossScrollContent:SetWidth(sharedLeftW)
        end
    end
    if UI.spellScrollFrame and UI.spellScrollChild then
        local sw = (UI.spellScrollFrame:GetWidth() or 0) - 26
        if sw < 360 then sw = 760 end
        UI.spellScrollChild:SetWidth(sw)
    end
    if UI.spellSettingsGridScroll and UI.spellSettingsGridChild then
        local gw = (UI.spellSettingsGridScroll:GetWidth() or 0) - 26
        if gw < 360 then gw = 760 end
        UI.spellSettingsGridChild:SetWidth(gw)
    end
end

local function FindEventByID(eventID)
    local eid = tonumber(eventID)
    if not eid then return nil end
    local boss = GetCurrentBoss()
    if not (boss and type(boss.events) == "table") then
        return nil
    end
    for _, event in ipairs(boss.events) do
        if GetEventID(event) == eid then
            return event
        end
    end
    return nil
end

SetWidgetUsable = function(widget, enabled)
    if not widget then return end
    widget:SetAlpha(1)

    if widget.checkbox and widget.checkbox.Enable then
        widget.checkbox:Enable()
    end

    if widget.editBox and widget.editBox.Enable then
        widget.editBox:Enable()
    end

    if widget.Enable then
        widget:Enable()
    else
        widget:EnableMouse(true)
    end
end

local function RefreshSettingsDynamicWidgets(mdb)
    local Grid = _G.InfinityGrid
    if not (Grid and type(Grid.Widgets) == "table" and type(mdb) == "table") then
        return
    end

    local modeDropdownWidget = Grid.Widgets["eventColorMode"]
    local customColor = Grid.Widgets["eventColor"]
    local centralLeadWidget = Grid.Widgets["centralLead"]
    local centralTextWidget = Grid.Widgets["centralText"]
    local preAlertTextWidget = Grid.Widgets["preAlertText"]
    local timerRenameTextWidget = Grid.Widgets["timerBarRenameText"]
    if centralLeadWidget then
        centralLeadWidget:Show()
        SetWidgetUsable(centralLeadWidget, true)
    end
    if centralTextWidget then
        centralTextWidget:Show()
        SetWidgetUsable(centralTextWidget, true)
    end
    if preAlertTextWidget then
        preAlertTextWidget:Show()
        SetWidgetUsable(preAlertTextWidget, true)
    end
    if timerRenameTextWidget then
        timerRenameTextWidget:Show()
        SetWidgetUsable(timerRenameTextWidget, true)
    end

    local colorOn = (mdb.eventColorEnabled == true)
    local colorMode = NormalizeEventColorMode(mdb.eventColorMode)
    SetWidgetUsable(modeDropdownWidget, colorOn)
    if customColor then
        if colorOn and colorMode == "__custom" then
            customColor:Show()
            SetWidgetUsable(customColor, true)
        else
            customColor:Hide()
        end
    end

    for i = 0, 2 do
        local prefix = "tr" .. tostring(i)
        local enabled = (mdb[prefix .. "Enabled"] == true)
        local source = NormalizeTriggerSource(mdb[prefix .. "Source"])

        local sourceWidget = Grid.Widgets[prefix .. "Source"]
        local packWidget = Grid.Widgets[prefix .. "Label"]
        local lsmWidget = Grid.Widgets[prefix .. "LSM"]
        local pathWidget = Grid.Widgets[prefix .. "Path"]
        local valueTestWidget = Grid.Widgets[prefix .. "ValueTest"]
        local offsetModeWidget = Grid.Widgets[prefix .. "OffsetMode"]
        local offsetSecondsWidget = Grid.Widgets[prefix .. "OffsetSeconds"]

        SetWidgetUsable(sourceWidget, enabled)

        if source == "pack" then
            if packWidget then packWidget:Show() end
            if lsmWidget then lsmWidget:Hide() end
            if pathWidget then pathWidget:Hide() end
            if valueTestWidget then valueTestWidget:Show() end
            SetWidgetUsable(packWidget, enabled)
            SetWidgetUsable(valueTestWidget, enabled)
        elseif source == "lsm" then
            if packWidget then packWidget:Hide() end
            if lsmWidget then lsmWidget:Show() end
            if pathWidget then pathWidget:Hide() end
            if valueTestWidget then valueTestWidget:Show() end
            SetWidgetUsable(lsmWidget, enabled)
            SetWidgetUsable(valueTestWidget, enabled)
        else
            if packWidget then packWidget:Hide() end
            if lsmWidget then lsmWidget:Hide() end
            if pathWidget then pathWidget:Show() end
            if valueTestWidget then valueTestWidget:Show() end
            SetWidgetUsable(pathWidget, enabled)
            SetWidgetUsable(valueTestWidget, enabled)
        end

        if i == 1 or i == 2 then
            if offsetModeWidget then
                offsetModeWidget:Show()
                SetWidgetUsable(offsetModeWidget, enabled)
            end
            if offsetSecondsWidget then
                offsetSecondsWidget:Show()
                SetWidgetUsable(offsetSecondsWidget, enabled)
            end
        end
    end

end

local function PlayTriggerPreviewByIndex(triggerIndex)
    local idx = tonumber(triggerIndex)
    if not idx then
        return
    end
    idx = math.floor(idx + 0.5)
    if idx < 0 then idx = 0 end
    if idx > 2 then idx = 2 end

    local event = FindEventByID(selectedEventID)
    if not event then
        return
    end
    local eventID = GetEventID(event)
    if not eventID then
        return
    end

    PersistModuleDBToSelectedSpell()

    local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    if not (Engine and Engine.TryPlayForTimer) then
        return
    end

    local timer = {
        eventID = eventID,
        spellID = GetEventSpellIdentifier(event),
        displayName = tostring(event.name or "Test Voice"),
        source = "manual_preview",
        timelineManaged = true,
    }
    local ok, err = Engine:TryPlayForTimer(timer, idx)
    if not ok then
    end
end

local function RefreshSpellSettingsPanel()
    if not (UI.spellSettingsGridChild and UI.spellSettingsEmptyText) then
        return
    end

    if selectedPrivateAuraKey then
        local row = FindCurrentPrivateAuraRowByKey(selectedPrivateAuraKey)
        if row then
            local _, spellIcon = GetSpellNameAndIcon(row.spellID)
            local sourceText = (#(row.sources or {}) > 0) and table.concat(row.sources, " / ") or "Unknown Source"
            local npcText = (#(row.sourceNPCIDs or {}) > 0) and table.concat(row.sourceNPCIDs, ", ") or "-"
            local descText = GetSpellDescription(row.spellID)
            local castLine, bodyText = SplitSpellDescription(descText)
            UpdateSpellDetailHeader(
                string.format("%s  |cff7fd3ff[%s]|r", tostring(row.name or "Private Aura"), tostring(row.tagText or "Private Aura")),
                row.spellID,
                nil,
                spellIcon,
                0,
                BuildPrivateAuraMarkup(20, -1)
            )
            UI.spellDetailCast:SetText((castLine ~= "" and castLine) or "Private Aura Spell")
            local descBody = (bodyText ~= "" and bodyText) or "No description available."
            UI.spellDetailBody:SetText(string.format("%s\n\n|cff7fd3ffSource:|r %s\n|cff7fd3ffSource NPCID:|r %s\n|cff7fd3ffOwner:|r %s", descBody, sourceText, npcText, tostring(row.ownerLabel or "-")))
            RefreshSpellDetailHeaderLayout()
            local Grid = _G.InfinityGrid
            if not Grid then
                UI.spellSettingsEmptyText:SetText("InfinityGrid unavailable, cannot render Private Aura settings.")
                UI.spellSettingsEmptyText:SetShown(true)
                UI.spellSettingsGridChild:SetHeight(1)
                return
            end
            UI.spellSettingsEmptyText:Hide()
            UI.spellSettingsGridScroll:SetVerticalScroll(0)
            local cfg = GetPrivateAuraConfigByKey(row.key, true)
            InfinityTools:RegisterModuleLayout(PA_SETTINGS_MODULE_KEY, PRIVATE_AURA_SETTINGS_LAYOUT)
            if Grid.SetContainerCols then
                Grid:SetContainerCols(UI.spellSettingsGridChild, SPELL_SETTINGS_GRID_COLS)
            end
            Grid:Render(UI.spellSettingsGridChild, PRIVATE_AURA_SETTINGS_LAYOUT, cfg, PA_SETTINGS_MODULE_KEY)
            RefreshPrivateAuraSettingsWidgets(cfg)
            return
        end
        selectedPrivateAuraKey = nil
    end

    EnsureSelectedEvent()
    local encounterID = GetCurrentEncounterID()
    local eventID = tonumber(selectedEventID)
    local event = FindEventByID(eventID)
    if not encounterID or not eventID or not event then
        SetSpellDetailHeaderEmpty("Click a spell card above to view its description here.")
        UI.spellSettingsEmptyText:SetShown(true)
        UI.spellSettingsGridChild:SetHeight(1)
        return
    end

    local spellIdentifier = GetEventSpellIdentifier(event)
    local _, spellIcon = GetSpellNameAndIcon(spellIdentifier)
    local spellName = tostring(event.name or "")
    if spellName == "" then
        local apiName = GetSpellNameAndIcon(spellIdentifier)
        if type(apiName) == "string" and apiName ~= "" then
            spellName = apiName
        else
            spellName = "Unknown Spell"
        end
    end

    UpdateSpellDetailHeader(spellName, spellIdentifier, eventID, spellIcon, GetEventIconFlags(event))
    BuildSpellSettingsLayout(spellName, spellIdentifier, eventID, spellIcon, GetEventIconFlags(event))
    SyncModuleDBFromSelectedSpell()

    local Grid = _G.InfinityGrid
    if not Grid then
        UI.spellSettingsEmptyText:SetText("InfinityGrid unavailable, cannot render settings panel.")
        UI.spellSettingsEmptyText:SetShown(true)
        UI.spellSettingsGridChild:SetHeight(1)
        return
    end

    UI.spellSettingsEmptyText:Hide()
    UI.spellSettingsGridScroll:SetVerticalScroll(0)
    local mdb = InfinityTools:GetModuleDB(SETTINGS_MODULE_KEY, SETTINGS_DEFAULTS)
    if Grid.SetContainerCols then
        Grid:SetContainerCols(UI.spellSettingsGridChild, SPELL_SETTINGS_GRID_COLS)
    end
    Grid:Render(UI.spellSettingsGridChild, SETTINGS_LAYOUT, mdb, SETTINGS_MODULE_KEY)
    RefreshSettingsDynamicWidgets(mdb)
end

RefreshSpellCards = function()
    if not UI.spellScrollChild then return end

    PersistSelectionBeforeNavigation()

    _spellUIRefreshPending = false
    _spellUIRefreshToken = _spellUIRefreshToken + 1
    _buildToken = _buildToken + 1
    local token = _buildToken

    ReleaseSpellCards()
    UI.spellScrollFrame:SetVerticalScroll(0)

    local boss = GetCurrentBoss()
    local privateAuraRows = BuildCurrentPrivateAuraRows()
    if not boss and #privateAuraRows == 0 then
        UI.spellEmptyText:SetShown(true)
        UI.spellScrollChild:SetHeight(1)
        selectedEventID = nil
        selectedPrivateAuraKey = nil
        RefreshSpellSettingsPanel()
        return
    end
    local events = (boss and type(boss.events) == "table") and boss.events or {}
    if #events == 0 and #privateAuraRows == 0 then
        UI.spellEmptyText:SetShown(true)
        UI.spellScrollChild:SetHeight(1)
        selectedEventID = nil
        selectedPrivateAuraKey = nil
        RefreshSpellSettingsPanel()
        return
    end
    EnsureSelectedEvent()
    UI.spellEmptyText:Hide()
    local encounterID = GetCurrentEncounterID()

    local function BuildOneCard(event, index, cardW)
        if token ~= _buildToken or not Page._visible or not UI.spellScrollChild then
            return nil
        end

        local card = AcquireSpellCard()
        card:SetParent(UI.spellScrollChild)

        local eventID = GetEventID(event)
        local spellID = GetEventSpellIdentifier(event)
        local spellCached = IsSpellDataReady(spellID)
        if spellID and not spellCached then
            RequestSpellDataLoad(spellID)
        end

        local spellName, icon = GetSpellNameAndIcon(spellID)
        local displayName = (event and event.name) or spellName or ("Unknown Spell " .. tostring(index))
        local override = encounterID and eventID and GetSpellOverride(encounterID, eventID, spellID, false) or nil
        local spellEnabled = not (override and override.enabled == false)

        local flags = GetEventIconFlags(event)
        local borderR, borderG, borderB = ResolveVoiceEventBorderColor(eventID)
        if borderR == nil or borderG == nil or borderB == nil then
            borderR, borderG, borderB =
                DEFAULT_EVENT_BORDER_COLOR.r,
                DEFAULT_EVENT_BORDER_COLOR.g,
                DEFAULT_EVENT_BORDER_COLOR.b
        end

        local col = (index - 1) % SPELL_CARD.cols
        local row = math.floor((index - 1) / SPELL_CARD.cols)
        local x = col * (cardW + SPELL_CARD.gapX)
        local y = -4 - row * (SPELL_CARD.height + SPELL_CARD.gapY)
        card:SetPoint("TOPLEFT", UI.spellScrollChild, "TOPLEFT", x, y)
        card:SetSize(cardW, SPELL_CARD.height)
        card.eventData = event
        card._eventID = eventID
        card._spellID = spellID
        card._selected = (eventID and tonumber(selectedEventID) == eventID) and true or false
        card._hovered = false

        local alertKind, alertSource = ResolvePrimaryAlertIconSourceByBorder(eventID, borderR, borderG, borderB)
        if alertKind == "atlas" and card.alertIcon and card.alertIcon.SetAtlas then
            card.alertIcon:SetAtlas(alertSource)
            card.alertIcon:Show()
            card.icon:ClearAllPoints()
            card.icon:SetPoint("LEFT", card.alertIcon, "RIGHT", 6, 0)
        elseif alertKind == "texture" and card.alertIcon then
            card.alertIcon:SetTexture(alertSource)
            card.alertIcon:Show()
            card.icon:ClearAllPoints()
            card.icon:SetPoint("LEFT", card.alertIcon, "RIGHT", 6, 0)
        else
            if card.alertIcon then
                card.alertIcon:Hide()
            end
            card.icon:ClearAllPoints()
            card.icon:SetPoint("LEFT", 11, 0)
        end

        card.icon:SetTexture(icon or 134400)
        local disableText = ""
        if not spellEnabled then
            if override and override.enabled == false then
                disableText = " |cffff6666[Disabled]|r"
            end
        end
        SetAdaptiveSpellCardTitle(card, string.format("%s%s", tostring(displayName), disableText))
        card.desc:SetText("")
        card.desc:Hide()
        card.leftBar:SetColorTexture(borderR, borderG, borderB, 1)
        card.leftBar:Show()
        card:SetAlpha(1)

        local h = ComputeSpellCardHeight(card)
        card:SetHeight(h)
        card.leftBar:ClearAllPoints()
        card.leftBar:SetPoint("TOPLEFT", 0, -3)
        card.leftBar:SetPoint("BOTTOMLEFT", 0, 3)
        card._borderR = borderR
        card._borderG = borderG
        card._borderB = borderB
        card._applyVisual = function(self)
            local br = Clamp01(self._borderR, 0.35)
            local bg = Clamp01(self._borderG, 0.35)
            local bb = Clamp01(self._borderB, 0.35)
            if self._selected then
                self:SetBackdropColor(0.08, 0.18, 0.30, 0.95)
                self:SetBackdropBorderColor(Clamp01(br * 1.15, 1), Clamp01(bg * 1.15, 1), Clamp01(bb * 1.15, 1), 1)
            elseif self._hovered then
                self:SetBackdropColor(0.08, 0.08, 0.12, 0.82)
                self:SetBackdropBorderColor(Clamp01(br * 1.08, 1), Clamp01(bg * 1.08, 1), Clamp01(bb * 1.08, 1), 1)
            else
                self:SetBackdropColor(0, 0, 0, 0.5)
                self:SetBackdropBorderColor(br, bg, bb, 1)
            end
        end
        card:SetScript("OnClick", function(self)
            PersistSelectionBeforeNavigation()
            if not self._eventID then return end
            selectedEventID = tonumber(self._eventID)
            selectedPrivateAuraKey = nil
            RefreshActiveSpellCardVisuals()
            RefreshSpellSettingsPanel()
        end)
        card:_applyVisual()
        card:Show()

        table.insert(CARD_CACHE.activeSpellCards, card)
        return card
    end

    local function BuildOnePrivateAuraCard(row, index, cardW)
        if token ~= _buildToken or not Page._visible or not UI.spellScrollChild then
            return nil
        end

        local card = AcquireSpellCard()
        card:SetParent(UI.spellScrollChild)

        local spellID = tonumber(row.spellID)
        local spellCached = IsSpellDataReady(spellID)
        if spellID and not spellCached then
            RequestSpellDataLoad(spellID)
        end

        local _, icon = GetSpellNameAndIcon(spellID)
        local displayName = string.format("[%s] %s", tostring(row.tagText or "Private Aura"), tostring(row.name or ("Spell " .. tostring(spellID))))
        local col = (index - 1) % SPELL_CARD.cols
        local rowIndex = math.floor((index - 1) / SPELL_CARD.cols)
        local x = col * (cardW + SPELL_CARD.gapX)
        local y = -4 - rowIndex * (SPELL_CARD.height + SPELL_CARD.gapY)

        card:SetPoint("TOPLEFT", UI.spellScrollChild, "TOPLEFT", x, y)
        card:SetSize(cardW, SPELL_CARD.height)
        card.eventData = nil
        card._eventID = nil
        card._spellID = spellID
        card._selectionKey = row.key
        card._selected = (selectedPrivateAuraKey and row.key == selectedPrivateAuraKey) and true or false
        card._hovered = false
        card._borderR, card._borderG, card._borderB = 1.00, 0.5451, 0.00

        if card.alertIcon then
            card.alertIcon:SetAtlas("poi-nzothvision")
            card.alertIcon:SetSize(22, 22)
            card.alertIcon:Show()
            card.icon:ClearAllPoints()
            card.icon:SetPoint("LEFT", card.alertIcon, "RIGHT", 6, 0)
        end
        card.icon:SetTexture(icon or 134400)
        SetAdaptiveSpellCardTitle(card, displayName)
        card.desc:SetText("")
        card.desc:Hide()
        card.leftBar:SetColorTexture(card._borderR, card._borderG, card._borderB, 1)
        card.leftBar:Show()
        card:SetAlpha(1)

        local h = ComputeSpellCardHeight(card)
        card:SetHeight(h)
        card.leftBar:ClearAllPoints()
        card.leftBar:SetPoint("TOPLEFT", 0, -3)
        card.leftBar:SetPoint("BOTTOMLEFT", 0, 3)
        card._applyVisual = function(self)
            local br, bg, bb = self._borderR, self._borderG, self._borderB
            if self._selected then
                self:SetBackdropColor(0.06, 0.22, 0.14, 0.95)
                self:SetBackdropBorderColor(Clamp01(br * 1.1, 1), Clamp01(bg * 1.1, 1), Clamp01(bb * 1.1, 1), 1)
            elseif self._hovered then
                self:SetBackdropColor(0.06, 0.11, 0.08, 0.84)
                self:SetBackdropBorderColor(Clamp01(br * 1.08, 1), Clamp01(bg * 1.08, 1), Clamp01(bb * 1.08, 1), 1)
            else
                self:SetBackdropColor(0, 0, 0, 0.5)
                self:SetBackdropBorderColor(br, bg, bb, 1)
            end
        end
        card:SetScript("OnClick", function(self)
            PersistSelectionBeforeNavigation()
            selectedEventID = nil
            selectedPrivateAuraKey = self._selectionKey
            RefreshActiveSpellCardVisuals()
            RefreshSpellSettingsPanel()
        end)
        card:_applyVisual()
        card:Show()

        table.insert(CARD_CACHE.activeSpellCards, card)
        return card
    end

    local function BuildSync(entries)
        local totalW = (UI.spellScrollChild:GetWidth() or 760)
        if totalW < 360 then totalW = 760 end
        local usableW = math.max(360, totalW - 2)
        local cardW = math.floor((usableW - ((SPELL_CARD.cols - 1) * SPELL_CARD.gapX)) / SPELL_CARD.cols)
        if cardW < 120 then
            cardW = 120
        end

        for i, entry in ipairs(entries) do
            local card
            if entry and entry._privateAura then
                card = BuildOnePrivateAuraCard(entry, i, cardW)
            else
                card = BuildOneCard(entry, i, cardW)
            end
            if not card then return end
        end
        if token == _buildToken and UI.spellScrollChild then
            local rows = math.max(1, math.ceil(#entries / SPELL_CARD.cols))
            local totalH = rows * SPELL_CARD.height + (rows - 1) * SPELL_CARD.gapY + 8
            UI.spellScrollChild:SetHeight(math.max(1, totalH))
        end
    end

    local function BuildAsync(entries)
        local totalW = (UI.spellScrollChild:GetWidth() or 760)
        if totalW < 360 then totalW = 760 end
        local usableW = math.max(360, totalW - 2)
        local cardW = math.floor((usableW - ((SPELL_CARD.cols - 1) * SPELL_CARD.gapX)) / SPELL_CARD.cols)
        if cardW < 120 then
            cardW = 120
        end

        for i, entry in ipairs(entries) do
            local card
            if entry and entry._privateAura then
                card = BuildOnePrivateAuraCard(entry, i, cardW)
            else
                card = BuildOneCard(entry, i, cardW)
            end
            if not card then return end
            coroutine.yield()
        end
        if token == _buildToken and UI.spellScrollChild then
            local rows = math.max(1, math.ceil(#entries / SPELL_CARD.cols))
            local totalH = rows * SPELL_CARD.height + (rows - 1) * SPELL_CARD.gapY + 8
            UI.spellScrollChild:SetHeight(math.max(1, totalH))
        end
    end

    local entries = {}
    for i = 1, #events do
        entries[#entries + 1] = events[i]
    end
    for i = 1, #privateAuraRows do
        entries[#entries + 1] = privateAuraRows[i]
    end
    PrimeSpellCache(events)
    local async = GetAsyncHandler()
    if async then
        async:Async(function()
            BuildAsync(entries)
        end, "InfinityBoss_BossPage_SpellCards", true)
    else
        BuildSync(entries)
    end

    RefreshSpellSettingsPanel()
end

RefreshBossList = function(resetScroll)
    if not UI.bossScrollContent then return end
    _bossBuildToken = _bossBuildToken + 1
    local token = _bossBuildToken

    ReleaseBossCards()
    UI.bossScrollContent:SetHeight(1)
    if resetScroll and UI.bossScrollFrame then
        UI.bossScrollFrame:SetVerticalScroll(0)
    end

    local list = BuildBossList(selectedMapID)
    if #list == 0 then
        UI.bossEmptyText:Show()
        UI.bossScrollContent:SetHeight(1)
        selectedEventID = nil
        selectedPrivateAuraKey = nil
        return
    end

    UI.bossEmptyText:Hide()

    local function IsValid()
        return token == _bossBuildToken and Page._visible and UI.bossScrollContent ~= nil
    end

    local function ApplyVisual(self)
        local selected = self._selected
        local hovered = self._hovered
        if selected then
            self:SetBackdropColor(0.1, 0.4, 0.8, 0.3)
            self:SetBackdropBorderColor(0, 0.8, 1, 1)
            self.activeBar:Show()
            self.nameText:SetTextColor(1, 0.86, 0.48)
        elseif hovered then
            self:SetBackdropColor(0.08, 0.08, 0.08, 0.88)
            self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            self.activeBar:Hide()
            self.nameText:SetTextColor(0.95, 0.95, 0.95)
        else
            self:SetBackdropColor(0.04, 0.04, 0.04, 0.8)
            self:SetBackdropBorderColor(0.38, 0.38, 0.38, 0.95)
            self.activeBar:Hide()
            self.nameText:SetTextColor(0.82, 0.66, 0.46)
        end
    end

    local y = -4
    local function ApplyPortrait(card)
        if not IsValid() or not card then return false end

        local displayID = tonumber(card._displayID)
        if displayID and card.creature and card.creature.SetDisplayInfo then
            if card._appliedDisplayID ~= displayID then
                if card.creature.ClearModel then
                    card.creature:ClearModel()
                end
                card.creature:SetDisplayInfo(displayID)
                card._appliedDisplayID = displayID
            end
            ApplyModelTune(card.creature)
            card.creature:Show()
            if card.noPortraitText then
                card.noPortraitText:Hide()
            end
        else
            card._appliedDisplayID = nil
            if card.creature then
                card.creature:Hide()
            end
            if card.noPortraitText then
                card.noPortraitText:SetText("No portrait")
                card.noPortraitText:Show()
            end
        end
        return true
    end

    local function BuildOne(entry)
        if not IsValid() then return false end
        local b = AcquireBossCard()
        local boss = entry.data

        b:SetParent(UI.bossScrollContent)
        b:SetPoint("TOPLEFT", 0, y)
        b:SetPoint("RIGHT", UI.bossScrollContent, "RIGHT", -2, 0)
        b:SetHeight(68)
        b:Show()

        b._selected = (entry.index == selectedBossIndex)
        b._hovered = false
        b._applyVisual = ApplyVisual
        b.index = entry.index

        b.nameText:SetText(tostring(boss and boss.name or ("Unknown Boss " .. tostring(entry.index))))
        b.detailText:SetText("encounterID: " .. tostring(boss and boss.encounterID or "-"))

        if b.noPortraitText then
            b.noPortraitText:Hide()
        end
        b._displayID = ResolveBossDisplayID(boss)
        b._appliedDisplayID = nil
        if b._displayID and b.creature then
            b.creature:Hide()
            if b.noPortraitText then
                b.noPortraitText:SetText("Loading")
                b.noPortraitText:Show()
            end
        else
            if b.creature then
                b.creature:Hide()
            end
            if b.noPortraitText then
                b.noPortraitText:SetText("No portrait")
                b.noPortraitText:Show()
            end
        end

        b:SetScript("OnClick", function(self)
            PersistSelectionBeforeNavigation()
            selectedBossIndex = self.index
            selectedEventID = nil
            selectedPrivateAuraKey = nil
            SaveSelection()
            RefreshActiveBossCardVisuals()
            UpdateSummary()
            RefreshModeButton()
            RefreshSpellCards()
        end)

        b:_applyVisual()
        table.insert(CARD_CACHE.activeBossCards, b)
        y = y - 72
        return true
    end

    local function Finalize()
        if not IsValid() then return end
        UI.bossScrollContent:SetHeight(math.max(1, -y + 6))
        if resetScroll and UI.bossScrollFrame then
            UI.bossScrollFrame:SetVerticalScroll(0)
        end

        local cards = CARD_CACHE.activeBossCards
        local function RenderPortraitsSync()
            for i = 1, #cards do
                if not ApplyPortrait(cards[i]) then
                    return
                end
            end
        end
        local function RenderPortraitsAsync()
            for i = 1, #cards do
                if not ApplyPortrait(cards[i]) then
                    return
                end
                coroutine.yield()
            end
        end
        local async = GetAsyncHandler()
        if async then
            async:Async(function()
                RenderPortraitsAsync()
            end, "InfinityBoss_BossPage_BossPortraits", true)
        else
            RenderPortraitsSync()
        end
    end

    local function BuildSync(entries)
        for _, entry in ipairs(entries) do
            if not BuildOne(entry) then
                return
            end
        end
        Finalize()
    end

    local function BuildAsync(entries)
        for _, entry in ipairs(entries) do
            if not BuildOne(entry) then
                return
            end
            coroutine.yield()
        end
        Finalize()
    end

    local async = GetAsyncHandler()
    if async then
        async:Async(function()
            BuildAsync(list)
        end, "InfinityBoss_BossPage_BossList", true)
    else
        BuildSync(list)
    end
end

RefreshMapTabs = function(resetScroll)
    if not UI.mapScrollChild then return end
    _mapBuildToken = _mapBuildToken + 1
    local token = _mapBuildToken

    ReleaseMapTabs()
    UI.mapScrollChild:SetHeight(1)
    if resetScroll and UI.mapScrollFrame then
        UI.mapScrollFrame:SetVerticalScroll(0)
    end

    local mapList = BuildMapList(selectedSeason)
    if #mapList == 0 then
        UI.mapEmptyText:Show()
        UI.mapScrollChild:SetHeight(1)
        return
    end

    UI.mapEmptyText:Hide()

    local function IsValid()
        return token == _mapBuildToken and Page._visible and UI.mapScrollChild ~= nil
    end

    local function ApplyVisual(self)
        local selected = tonumber(self.mapID) == tonumber(selectedMapID)
        local hovered = self._hovered
        if selected then
            self:SetBackdropColor(0.1, 0.4, 0.8, 0.3)
            self:SetBackdropBorderColor(0, 0.8, 1, 1)
            self.icon:SetDesaturated(false)
            self.text:SetTextColor(1, 0.85, 0.35)
        elseif hovered then
            self:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
            self:SetBackdropBorderColor(0.48, 0.48, 0.55, 0.9)
            self.icon:SetDesaturated(false)
            self.text:SetTextColor(0.95, 0.95, 0.95)
        else
            self:SetBackdropColor(0.04, 0.04, 0.04, 0.8)
            self:SetBackdropBorderColor(0.36, 0.36, 0.4, 0.85)
            self.icon:SetDesaturated(true)
            self.text:SetTextColor(0.75, 0.75, 0.78)
        end
    end

    local perRow = 4
    local gapX = 6
    local gapY = 8
    local leftPad = 2
    local topPad = 2
    local availW = (UI.mapScrollChild:GetWidth() or 208) - (leftPad * 2)
    if availW < 200 then availW = 200 end
    local cellW = math.floor((availW - ((perRow - 1) * gapX)) / perRow)
    if cellW < 50 then
        cellW = 50
    end
    local cellH = 74
    local yBottom = 0

    local function BuildOne(i, mapID)
        if not IsValid() then return false end
        local b = AcquireMapTab()
        b:SetParent(UI.mapScrollChild)
        b:Show()
        b.mapID = mapID
        b:SetSize(cellW, cellH)

        local style = GetMapIconRenderStyle(mapID)
        local iconSize = cellW - 4
        if iconSize > 46 then iconSize = 46 end
        if iconSize < 30 then iconSize = 30 end
        local scale = tonumber(style.scale) or 1
        if scale > 0 then
            iconSize = math.floor(iconSize * scale + 0.5)
        end
        if iconSize > (cellW - 4) then
            iconSize = cellW - 4
        end
        if iconSize < 30 then
            iconSize = 30
        end
        b.icon:SetSize(iconSize, iconSize)
        b.icon:ClearAllPoints()
        b.icon:SetPoint("TOP", tonumber(style.offsetX) or 0, -5 + (tonumber(style.offsetY) or 0))
        b.text:SetWidth(cellW - 4)

        b.icon:SetTexture(GetMapIcon(mapID))
        local tex = style.tex
        if type(tex) == "table" and #tex >= 4 then
            b.icon:SetTexCoord(tex[1], tex[2], tex[3], tex[4])
        else
            b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        local mapName = tostring(GetMapDisplayName(mapID) or "")
        local nameLen = (type(strlenutf8) == "function" and strlenutf8(mapName)) or #mapName
        if nameLen > 5 then
            mapName = UTF8Left(mapName, 5)
        end
        b.text:SetText(mapName)

        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        b:SetPoint("TOPLEFT", leftPad + col * (cellW + gapX), -topPad - row * (cellH + gapY))

        b._hovered = false
        b._applyVisual = ApplyVisual
        b:SetScript("OnClick", function(self)
            PersistSelectionBeforeNavigation()
            selectedMapID = self.mapID
            selectedBossIndex = nil
            selectedEventID = nil
            selectedPrivateAuraKey = nil
            NormalizeSelection()
            SaveSelection()
            RefreshActiveMapTabVisuals()
            RefreshBossList(true)
            UpdateSummary()
            RefreshModeButton()
            RefreshSpellCards()
        end)
        b:_applyVisual()

        table.insert(CARD_CACHE.activeMapTabs, b)
        yBottom = row * (cellH + gapY) + cellH
        return true
    end

    local function Finalize()
        if not IsValid() then return end
        UI.mapScrollChild:SetHeight(math.max(1, yBottom + topPad + 4))
        if resetScroll and UI.mapScrollFrame then
            UI.mapScrollFrame:SetVerticalScroll(0)
        end
    end

    local function BuildSync(entries)
        for i, mapID in ipairs(entries) do
            if not BuildOne(i, mapID) then
                return
            end
        end
        Finalize()
    end

    local function BuildAsync(entries)
        for i, mapID in ipairs(entries) do
            if not BuildOne(i, mapID) then
                return
            end
            coroutine.yield()
        end
        Finalize()
    end

    local async = GetAsyncHandler()
    if async then
        async:Async(function()
            BuildAsync(mapList)
        end, "InfinityBoss_BossPage_MapTabs", true)
    else
        BuildSync(mapList)
    end
end

RefreshSeasonDropdown = function(seasons)
    if not UI.seasonDropdown then return end
    local items = {}
    for _, row in ipairs(MAP_CATEGORY_ITEMS) do
        items[#items + 1] = { tostring(row[1]), row[2] }
    end
    UI.seasonDropdown._items = items
    UI.seasonDropdown._currentValue = selectedSeason
    UI.seasonDropdown:SetText(tostring(selectedSeason or "-"))
end

function Page:Render(leftFrame, contentFrame)
    if not leftFrame or not contentFrame then return end

    EnsureUI(leftFrame, contentFrame)

    UI.leftRoot:SetParent(leftFrame)
    UI.leftRoot:ClearAllPoints()
    UI.leftRoot:SetAllPoints(leftFrame)
    UI.leftRoot:Show()

    UI.rightRoot:SetParent(contentFrame)
    UI.rightRoot:ClearAllPoints()
    UI.rightRoot:SetAllPoints(contentFrame)
    UI.rightRoot:Show()
    if UI.titleControlHost then
        UI.titleControlHost:Show()
    end

    Page._visible = true

    local seasons = NormalizeSelection()
    SyncScrollChildWidth()
    RefreshSeasonDropdown(seasons)
    RefreshMapTabs(true)
    RefreshBossList(true)
    UpdateSummary()
    RefreshModeButton()

    C_Timer.After(0, function()
        if not Page._visible then return end
        SyncScrollChildWidth()
        RefreshSpellCards()
    end)
end

function Page:Hide()
    Page._visible = false
    PersistSelectionBeforeNavigation()
    _buildToken = _buildToken + 1
    _bossBuildToken = _bossBuildToken + 1
    _mapBuildToken = _mapBuildToken + 1
    _spellUIRefreshPending = false
    _spellUIRefreshToken = _spellUIRefreshToken + 1

    local Grid = _G.InfinityGrid
    if Grid and Grid.ClearContainerCols and UI.spellSettingsGridChild then
        Grid:ClearContainerCols(UI.spellSettingsGridChild)
    end
    if InfinityTools.UI and InfinityTools.UI.ActivePageFrame == UI.spellSettingsGridChild then
        InfinityTools.UI.ActivePageFrame = nil
        InfinityTools.UI.CurrentModule = nil
    end

    ReleaseMapTabs()
    ReleaseBossCards()
    ReleaseSpellCards()

    if UI.leftRoot then UI.leftRoot:Hide() end
    if UI.rightRoot then UI.rightRoot:Hide() end
    if UI.titleControlHost then UI.titleControlHost:Hide() end
end

if not Page._settingsEventsRegistered then
    InfinityTools:WatchState(SETTINGS_MODULE_KEY .. ".DatabaseChanged", "InfinityBoss.BossPage.SpellSettingDB", function(info)
        local key = info and info.key
        local linkedPresetApplied = PersistModuleDBToSelectedSpell(key)
        if linkedPresetApplied then
            SyncModuleDBFromSelectedSpell()
        end
        if Page._visible then
            local mdb = InfinityTools:GetModuleDB(SETTINGS_MODULE_KEY, SETTINGS_DEFAULTS)
            RefreshSettingsDynamicWidgets(mdb)
            if key == "enabled" then
                RefreshSpellCardTitles()
            end
        end
    end)

    InfinityTools:WatchState(SETTINGS_MODULE_KEY .. ".ButtonClicked", "InfinityBoss.BossPage.SpellSettingButton", function(info)
        if not info or not info.key then return end

        local triggerIdx = info.key:match("^tr([012])SourceTest$")
        if not triggerIdx then
            triggerIdx = info.key:match("^tr([012])ValueTest$")
        end
        if triggerIdx then
            PlayTriggerPreviewByIndex(tonumber(triggerIdx))
            return
        end

        -- reserved
    end)

    InfinityTools:WatchState("RoleKey", "InfinityBoss.BossPage.RoleState", function()
        if Page._visible then
            RefreshSpellCards()
        end
    end)

    Page._settingsEventsRegistered = true
end

if not Page._privateAuraSettingsEventsRegistered then
    InfinityTools:WatchState(PA_SETTINGS_MODULE_KEY .. ".DatabaseChanged", "InfinityBoss.BossPage.PrivateAuraSettingDB", function()
        if Page._visible and selectedPrivateAuraKey then
            local cfg = GetPrivateAuraConfigByKey(selectedPrivateAuraKey, true)
            RefreshPrivateAuraSettingsWidgets(cfg)
        end
    end)

    InfinityTools:WatchState(PA_SETTINGS_MODULE_KEY .. ".ButtonClicked", "InfinityBoss.BossPage.PrivateAuraSettingButton", function(info)
        if not info or info.key ~= "valueTest" then
            return
        end
        PlayPrivateAuraPreview()
    end)

    Page._privateAuraSettingsEventsRegistered = true
end

function Page:RefreshSpellUI()
    if not Page._visible then return end
    C_Timer.After(0, function()
        if not Page._visible then return end
        RefreshSpellCards()
        RefreshSpellSettingsPanel()
    end)
end

if not Page._eventsRegistered then
    InfinityTools:RegisterEvent("PORTRAITS_UPDATED", "InfinityBoss.BossPage.Portraits", function()
        if not Page._visible then return end
    end)

    InfinityTools:RegisterEvent("SPELL_DATA_LOAD_RESULT", "InfinityBoss.BossPage.SpellCache", function(_, spellID, success)
        if spellID then
            CARD_CACHE.spellCachePending[spellID] = nil
            CARD_CACHE.spellTextCache[spellID] = nil
        end
        if not success then return end
        if Page._visible and CurrentBossHasSpellID(spellID) then
            QueueSpellUIRefresh(0.10)
        end
    end)

    InfinityTools:RegisterEvent("SPELL_TEXT_UPDATE", "InfinityBoss.BossPage.SpellText", function()
        wipe(CARD_CACHE.spellTextCache)
        if Page._visible then
            QueueSpellUIRefresh(0.10)
        end
    end)

    Page._eventsRegistered = true
end
