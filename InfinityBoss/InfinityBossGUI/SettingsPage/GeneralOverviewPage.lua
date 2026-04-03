---@diagnostic disable: undefined-global, undefined-field, need-check-nil

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

InfinityBoss.UI.Panel.GeneralOverviewPage = InfinityBoss.UI.Panel.GeneralOverviewPage or {}
local Page = InfinityBoss.UI.Panel.GeneralOverviewPage

local MODULE_KEY = "InfinityBoss.GeneralOverview"
local BASE_GRID_COLS = 63
local MIN_GRID_COLS = 63
local MAX_GRID_COLS = 63
local TARGET_CELL_PX = 18
local LAYOUT_CACHE = {}
local ACTIVE_CONTENT_FRAME

local CHANNEL_OPTIONS = {
    { "Master", "Master" },
    { "SFX", "SFX" },
    { "Dialog", "Dialog" },
    { "Music", "Music" },
    { "Ambience", "Ambience" },
}

local BAR_MODE_OPTIONS = {
    { "Bun Bars Only", "bun" },
    { "Both Enabled", "both" },
    { "Timer Bars Only", "timer" },
    { "Both Hidden", "none" },
}

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
    local s = tostring(value or "")
    if key == "" or s == "" then
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

local LAYOUT = {
    { key = "header", type = "header", x = 1, y = 1, w = 63, h = 2, label = "General Settings", labelSize = 25 },
    { key = "desc", type = "description", x = 1, y = 4, w = 63, h = 2, label = "Manage InfinityBoss global display modes and voice output here." },
    { key = "barDisplayMode", type = "dropdown", x = 1, y = 7, w = 20, h = 2, label = "Timeline Display Mode", items = BAR_MODE_OPTIONS, parentKey = "ui.general" },
    { key = "header_load", type = "header", x = 1, y = 9, w = 62, h = 3, label = "Load Settings", labelSize = 20 },
    { key = "bossAlertsEnabledMplus", type = "checkbox", x = 1, y = 12, w = 24, h = 2, label = "Enable M+ Boss Alerts", parentKey = "ui.general" },
    { key = "bossAlertsEnabledRaid", type = "checkbox", x = 1, y = 14, w = 24, h = 2, label = "Enable Raid Boss Alerts", parentKey = "ui.general" },
    { key = "disableBlizzardEncounterTimeline", type = "checkbox", x = 1, y = 16, w = 24, h = 2, label = "Disable Blizzard Timeline", parentKey = "ui.general" },
    { key = "autoDisableCAAInBoss", type = "checkbox", x = 1, y = 18, w = 24, h = 2, label = "Auto-Disable Combat Audio Alerts in Boss", parentKey = "ui.general" },
    { key = "encounterWarningsEnabled", type = "checkbox", x = 1, y = 20, w = 40, h = 2, label = "Enable Blizzard Center-Text Alerts (Warning: disabling this breaks voice)", parentKey = "ui.general" },
    { key = "channel", type = "dropdown", x = 1, y = 27, w = 15, h = 2, label = "Output Channel", items = CHANNEL_OPTIONS, parentKey = "voice.global" },
    { key = "volume", type = "slider", x = 18, y = 27, w = 14, h = 2, label = "Global Volume", min = 0, max = 1, step = 0.01, parentKey = "voice.global" },
    { key = "header_5292", type = "header", x = 1, y = 24, w = 62, h = 3, label = "Audio Output Options", labelSize = 20 },
}

local function NormalizeBarDisplayMode(mode)
    local m = tostring(mode or ""):lower()
    if m == "timer" or m == "bun" or m == "both" or m == "none" then
        return m
    end
    return "bun"
end

local function EnsureRootDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    InfinityBossDB.voice.global = InfinityBossDB.voice.global or {}

    local general = InfinityBossDB.ui.general
    general.barDisplayMode = NormalizeBarDisplayMode(general.barDisplayMode)
    if general.bossAlertsEnabledMplus == nil then
        general.bossAlertsEnabledMplus = true
    else
        general.bossAlertsEnabledMplus = (general.bossAlertsEnabledMplus == true)
    end
    if general.bossAlertsEnabledRaid == nil then
        general.bossAlertsEnabledRaid = false
    else
        general.bossAlertsEnabledRaid = (general.bossAlertsEnabledRaid == true)
    end
    if general.autoDisableCAAInBoss == nil then
        general.autoDisableCAAInBoss = false
    else
        general.autoDisableCAAInBoss = (general.autoDisableCAAInBoss == true)
    end
    general.encounterWarningsEnabled = IsEncounterWarningsEnabled()
    general.disableBlizzardEncounterTimeline = not IsEncounterTimelineEnabled()

    local voice = InfinityBossDB.voice.global
    voice.channel = tostring(voice.channel or "Master")
    voice.volume = tonumber(voice.volume) or 1.0
    if voice.volume < 0 then voice.volume = 0 end
    if voice.volume > 1 then voice.volume = 1 end

    return InfinityBossDB
end

local function IsTimerBarEnabledByGlobal()
    local root = EnsureRootDB()
    local mode = NormalizeBarDisplayMode(root.ui.general.barDisplayMode)
    return mode == "both" or mode == "timer"
end

local function IsBunBarEnabledByGlobal()
    local root = EnsureRootDB()
    local mode = NormalizeBarDisplayMode(root.ui.general.barDisplayMode)
    return mode == "both" or mode == "bun"
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

local function ApplyVoiceOverrides()
    if InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine and InfinityBoss.Voice.Engine.ApplyEventOverridesToAPI then
        InfinityBoss.Voice.Engine:ApplyEventOverridesToAPI()
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

local function ConfirmEnableRaidBossAlerts()
    local popupID = "InfinityBoss_ENABLE_RAID_BOSS_ALERTS_CONFIRM"
    if not StaticPopupDialogs[popupID] then
        StaticPopupDialogs[popupID] = {
            text = "Raid config is not yet complete. Confirm enable?",
            button1 = "OK",
            button2 = "Cancel",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function()
                EnsureRootDB().ui.general.bossAlertsEnabledRaid = true
                ApplyBossSceneToggleChange()
                if Page and ACTIVE_CONTENT_FRAME and ACTIVE_CONTENT_FRAME:IsShown() then
                    Page:Render(ACTIVE_CONTENT_FRAME)
                end
            end,
            OnCancel = function()
                EnsureRootDB().ui.general.bossAlertsEnabledRaid = false
                if Page and ACTIVE_CONTENT_FRAME and ACTIVE_CONTENT_FRAME:IsShown() then
                    Page:Render(ACTIVE_CONTENT_FRAME)
                end
            end,
        }
    end
    StaticPopup_Show(popupID)
end

local function ResolveGridCols(contentWidth)
    local w = tonumber(contentWidth) or 0
    if w < 100 then
        return BASE_GRID_COLS
    end
    local cols = math.floor(((w - 20) / TARGET_CELL_PX) + 0.5)
    if cols < MIN_GRID_COLS then cols = MIN_GRID_COLS end
    if cols > MAX_GRID_COLS then cols = MAX_GRID_COLS end
    return cols
end

local function ScaleLayout(items, toCols)
    if toCols == BASE_GRID_COLS then
        return LAYOUT
    end
    local cached = LAYOUT_CACHE[toCols]
    if cached then
        return cached
    end

    local scale = toCols / BASE_GRID_COLS
    local function ScaleItems(src)
        local out = {}
        for _, item in ipairs(src) do
            local row = {}
            for k, v in pairs(item) do
                if k ~= "children" then
                    row[k] = v
                end
            end
            if type(item.x) == "number" and type(item.w) == "number" then
                local nx = math.floor(((item.x - 1) * scale) + 1 + 0.5)
                local nw = math.max(1, math.floor(item.w * scale + 0.5))
                if nx < 1 then nx = 1 end
                if nx > toCols then nx = toCols end
                if nx + nw - 1 > toCols then
                    nw = math.max(1, toCols - nx + 1)
                end
                row.x = nx
                row.w = nw
            end
            if type(item.children) == "table" then
                row.children = ScaleItems(item.children)
            end
            out[#out + 1] = row
        end
        return out
    end

    cached = ScaleItems(items)
    LAYOUT_CACHE[toCols] = cached
    return cached
end

InfinityTools:RegisterModuleLayout(MODULE_KEY, LAYOUT)

InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY .. "_cfg", function(info)
    if not info then return end
    local fullPath = tostring(info.fullPath or "")
    if fullPath:find("^ui%.general%.") then
        if fullPath == "ui.general.bossAlertsEnabledRaid" and info.value == true then
            local g = EnsureRootDB().ui.general
            if g._raidBossAlertsConfirming ~= true then
                g._raidBossAlertsConfirming = true
                g.bossAlertsEnabledRaid = false
                C_Timer.After(0, function()
                    local current = EnsureRootDB().ui.general
                    current._raidBossAlertsConfirming = nil
                    ConfirmEnableRaidBossAlerts()
                end)
                return
            end
        end
        if fullPath == "ui.general.encounterWarningsEnabled" then
            WriteCVarValue("encounterWarningsEnabled", (info.value == true) and "1" or "0")
        elseif fullPath == "ui.general.disableBlizzardEncounterTimeline" then
            WriteCVarValue("encounterTimelineEnabled", (info.value == true) and "0" or "1")
        end
        ApplyBarModeChange()
        if fullPath == "ui.general.bossAlertsEnabledMplus" or fullPath == "ui.general.bossAlertsEnabledRaid" then
            ApplyBossSceneToggleChange()
        end
        if fullPath == "ui.general.autoDisableCAAInBoss" and InfinityBoss and InfinityBoss.ApplyBossAutoCAASetting then
            InfinityBoss.ApplyBossAutoCAASetting()
        end
    elseif fullPath:find("^voice%.global%.") then
        ApplyVoiceOverrides()
    end
end)

function Page:Render(contentFrame)
    local Grid = _G.InfinityGrid
    if not Grid or not contentFrame then
        return
    end

    ACTIVE_CONTENT_FRAME = contentFrame

    local rootDB = EnsureRootDB()

    if not Page._scrollFrame then
        local sf = CreateFrame("ScrollFrame", "InfinityBoss_GeneralOverviewScroll", contentFrame, "ScrollFrameTemplate")
        if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
            InfinityBoss.UI.ApplyModernScrollBarSkin(sf)
        end

        local sc = CreateFrame("Frame", nil, sf)
        sc:SetHeight(1)
        sf:SetScrollChild(sc)

        Page._scrollFrame = sf
        Page._scrollChild = sc
    end

    local sf = Page._scrollFrame
    local sc = Page._scrollChild

    sf:SetParent(contentFrame)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 4, -4)
    sf:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -24, 4)
    sf:SetVerticalScroll(0)
    sf:Show()

    C_Timer.After(0, function()
        if not sf:IsShown() then return end
        local w = contentFrame:GetWidth()
        if w < 100 then w = 820 end
        sc:SetWidth(w - 16)
        sc:SetParent(sf)
        sc:ClearAllPoints()
        sc:SetPoint("TOPLEFT", 0, 0)
        sc:Show()
        if InfinityTools.UI then
            InfinityTools.UI.ActivePageFrame = sc
            InfinityTools.UI.CurrentModule = MODULE_KEY
        end
        local cols = ResolveGridCols(sc:GetWidth())
        if Grid.SetContainerCols then
            Grid:SetContainerCols(sc, cols)
        end
        Grid:Render(sc, ScaleLayout(LAYOUT, cols), rootDB, MODULE_KEY)
    end)
end
