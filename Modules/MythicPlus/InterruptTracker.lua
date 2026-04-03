local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
local InfinityExtrasDB = _G.InfinityExtrasDB
if not Core or not InfinityExtrasDB then
    return
end

local MODULE_KEY = "RRTTools.InterruptTracker"
local PARTY_SPEC = Core.PartySpec
local FACTORY = Core.Factory or _G.RRTMythicFactory
local SPEC_INTERRUPT_DB = InfinityExtrasDB.InterruptData or {}
local APPLY_FONT = InfinityExtrasDB.ApplyFont and function(fs, cfg) InfinityExtrasDB:ApplyFont(fs, cfg) end or nil

local C_Spell = _G.C_Spell
local C_Timer = _G.C_Timer
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local UnitGUID = _G.UnitGUID
local UnitName = _G.UnitName
local UnitClass = _G.UnitClass
local UnitExists = _G.UnitExists
local GetTime = _G.GetTime
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local IsInRaid = _G.IsInRaid
local wipe = _G.wipe
local math = _G.math
local ipairs = _G.ipairs
local pairs = _G.pairs
local string = _G.string
local C_ClassColor = _G.C_ClassColor
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local DEFAULTS = {
    enabled = false,
    locked = true,
    preview = false,
    posX = 0,
    posY = -200,
    growDirection = "DOWN",
    maxBars = 5,
    spacing = 1,
    showPlayerName = true,
    showTimer = true,
    showReadyText = false,
    readyText = "READY",
    useClassColorBar = true,
    useClassColorName = false,
    nameAlign = "LEFT",
    sortPriorityTank = 1,
    sortPriorityHealer = 2,
    sortPriorityDPS = 3,
    sortMeleeDPSFirst = false,
    attachToRaidFrame = false,
    attachFrame = "None",
    attachPoint = "Above",
    attachOffsetX = 0,
    attachOffsetY = 2,
    attachAutoWidth = true,
    _attachFrameSetByUser = false,
    font_name = { font = "Default", size = 16, outline = "OUTLINE", r = 1, g = 1, b = 1, a = 1, shadow = true, shadowX = 1.6, shadowY = -0.7, x = 2, y = 0 },
    font_timer = { font = "Default", size = 14, outline = "OUTLINE", r = 1, g = 1, b = 1, a = 1, shadow = false, shadowX = 1, shadowY = -1, x = 0, y = 0 },
    timerGroup = {
        width = 150, height = 24, texture = "Melli", showIcon = true, iconSize = 23, iconSide = "LEFT", iconOffsetX = -1, iconOffsetY = 0,
        barColorR = 0.2, barColorG = 0.8, barColorB = 0.2, barColorA = 1,
        barBgColorR = 0, barBgColorG = 0, barBgColorB = 0, barBgColorA = 0.5,
        showBorder = false, borderTexture = "None", borderSize = 12, borderPadding = 0,
        borderColorR = 1, borderColorG = 1, borderColorB = 1, borderColorA = 1,
    },
}

Core:RegisterModuleLayout(MODULE_KEY, {
    { key = "header", type = "header", x = 1, y = 1, w = 53, h = 2, label = "Interrupt Tracker", labelSize = 25 },
    { key = "enabled", type = "checkbox", x = 1, y = 9, w = 6, h = 2, label = "Enable" },
    { key = "locked", type = "checkbox", x = 10, y = 9, w = 8, h = 2, label = "Lock Position" },
    { key = "preview", type = "checkbox", x = 20, y = 9, w = 8, h = 2, label = "Preview" },
    { key = "btn_reset_pos", type = "button", x = 30, y = 9, w = 14, h = 2, label = "Reset Position" },
    { key = "attachToRaidFrame", type = "checkbox", x = 1, y = 16, w = 18, h = 2, label = "Attach To Party Frame" },
    { key = "attachFrame", type = "dropdown", x = 20, y = 16, w = 14, h = 2, label = "Frame", items = "None,DandersFrames,NDui,ElvUI,EQO,Grid2,Blizzard" },
    { key = "attachPoint", type = "dropdown", x = 36, y = 16, w = 14, h = 2, label = "Attach", items = "Above,Below" },
})

if not Core:IsModuleEnabled(MODULE_KEY) then
    return
end

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local anchorFrame
local activeBars, usedBars, previewBars = {}, {}, {}
local isPreviewing, isValidEnvironment = false, nil
local pendingEvents = { interrupts = {}, casts = {}, auras = {} }
local processingScheduled = false
local TIME_WINDOW = 0.050

local meleeSpecs = { [71]=true,[72]=true,[70]=true,[259]=true,[260]=true,[261]=true,[263]=true,[268]=true,[269]=true,[103]=true,[577]=true,[581]=true,[250]=true,[251]=true,[252]=true }

local function GetUnitSpecID(unit)
    local specID = PARTY_SPEC and PARTY_SPEC.GetSpec and (PARTY_SPEC:GetSpec(unit) or 0) or 0
    if specID == 0 and unit == "player" then
        specID = GetSpecializationInfo(GetSpecialization() or 1) or 0
    end
    return specID
end

local function GetAttachTargetFrame()
    local map = {
        DandersFrames = _G.DandersPartyHeader, NDui = _G.oUF_Party, ElvUI = _G.ElvUF_PartyGroup1,
        EQO = _G.EQOLUFPartyHeader or _G.EQOLUFPartyHeaderUnitButton1, Blizzard = _G.CompactPartyFrame,
    }
    if DB.attachFrame == "Grid2" then
        return _G.Grid2LayoutFrame
    end
    return map[DB.attachFrame]
end

local function IsAttachModeAvailable()
    if not DB.attachToRaidFrame or DB.attachFrame == "None" or IsInRaid() then
        return false
    end
    return GetAttachTargetFrame() ~= nil or DB.attachFrame == "Grid2"
end

local function CheckEnvironment()
    local state = Core.State or {}
    local enabled = (state.IsInParty or false) and state.InstanceType == "party"
    isValidEnvironment = enabled
    return enabled
end

local function InitBar(bar)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints(true)
    bar.Text = bar:CreateFontString(nil, "OVERLAY")
    bar.TimerText = bar:CreateFontString(nil, "OVERLAY")
    bar.Icon = bar:CreateTexture(nil, "OVERLAY")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
end

if FACTORY then
    FACTORY:InitPool("RRTInterruptBar", "StatusBar", "BackdropTemplate", InitBar)
end

local function AcquireBar()
    return FACTORY and FACTORY:Acquire("RRTInterruptBar", anchorFrame)
end

local function ReleaseBar(bar)
    if FACTORY and bar then
        bar:SetScript("OnUpdate", nil)
        FACTORY:Release("RRTInterruptBar", bar)
    end
end

local function EnsureAnchor()
    if anchorFrame then
        return
    end
    anchorFrame = CreateFrame("Frame", "RRTInterruptTrackerAnchor", UIParent)
    anchorFrame:SetSize(200, 20)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", DB.posX or 0, DB.posY or -200)
    anchorFrame:SetMovable(true)
    anchorFrame:RegisterForDrag("LeftButton")
    anchorFrame.bg = anchorFrame:CreateTexture(nil, "BACKGROUND")
    anchorFrame.bg:SetAllPoints()
    anchorFrame.bg:SetColorTexture(0, 0.5, 0, 0.5)
    anchorFrame.label = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFrame.label:SetPoint("CENTER")
    anchorFrame.label:SetText("Interrupt Tracker")
    anchorFrame:SetScript("OnDragStart", function(self) if not DB.locked then self:StartMoving() end end)
    anchorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        local sx, sy = self:GetCenter()
        if sx and sy and cx and cy then
            DB.posX = math.floor(sx - cx)
            DB.posY = math.floor(sy - cy)
        end
    end)
    Core:RegisterHUD(MODULE_KEY, anchorFrame)
end

local function StyleBar(bar)
    local g = DB.timerGroup
    local tex = LSM and LSM:Fetch("statusbar", g.texture or "Melli") or "Interface\\Buttons\\WHITE8X8"
    bar:SetSize(g.width or 150, g.height or 24)
    bar:SetStatusBarTexture(tex)
    bar.bg:SetTexture(tex)
    bar.bg:SetVertexColor(g.barBgColorR or 0, g.barBgColorG or 0, g.barBgColorB or 0, g.barBgColorA or 0.5)
    if APPLY_FONT then
        APPLY_FONT(bar.Text, DB.font_name)
        APPLY_FONT(bar.TimerText, DB.font_timer)
    end
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint(DB.nameAlign or "LEFT", bar, DB.nameAlign or "LEFT", DB.font_name.x or 2, DB.font_name.y or 0)
    bar.TimerText:ClearAllPoints()
    bar.TimerText:SetPoint("RIGHT", bar, "RIGHT", DB.font_timer.x or 0, DB.font_timer.y or 0)
    bar.Icon:SetSize(g.iconSize or 23, g.iconSize or 23)
    bar.Icon:ClearAllPoints()
    if (g.iconSide or "LEFT") == "LEFT" then
        bar.Icon:SetPoint("RIGHT", bar, "LEFT", g.iconOffsetX or -1, g.iconOffsetY or 0)
    else
        bar.Icon:SetPoint("LEFT", bar, "RIGHT", g.iconOffsetX or -1, g.iconOffsetY or 0)
    end
    if DB.useClassColorBar then
        local _, classTag = bar.unit and UnitClass(bar.unit) or nil, bar.unit and select(2, UnitClass(bar.unit)) or nil
        classTag = bar._previewClass or classTag
        local color = classTag and C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classTag)
        if color then
            bar:SetStatusBarColor(color.r, color.g, color.b, 1)
        end
    else
        bar:SetStatusBarColor(g.barColorR or 0.2, g.barColorG or 0.8, g.barColorB or 0.2, g.barColorA or 1)
    end
end

local function GetSpecPriority(unit)
    local specID = GetUnitSpecID(unit)
    local role = InfinityExtrasDB.SpecByID and InfinityExtrasDB.SpecByID[specID] and InfinityExtrasDB.SpecByID[specID].role or "DAMAGER"
    local p = role == "TANK" and (DB.sortPriorityTank or 1) or role == "HEALER" and (DB.sortPriorityHealer or 2) or (DB.sortPriorityDPS or 3)
    if role == "DAMAGER" and DB.sortMeleeDPSFirst and meleeSpecs[specID] then
        p = p - 0.5
    end
    return p
end

local function SortBars()
    local list = {}
    for guid, data in pairs(activeBars) do
        list[#list + 1] = { guid = guid, data = data }
    end
    table.sort(list, function(a, b)
        local ar = a.data.startTime == 0 or GetTime() - a.data.startTime >= a.data.cd
        local br = b.data.startTime == 0 or GetTime() - b.data.startTime >= b.data.cd
        if ar ~= br then return ar end
        if not ar then
            return a.data.cd - (GetTime() - a.data.startTime) < b.data.cd - (GetTime() - b.data.startTime)
        end
        local ap, bp = GetSpecPriority(a.data.unit), GetSpecPriority(b.data.unit)
        return ap == bp and a.guid < b.guid or ap < bp
    end)
    wipe(usedBars)
    for _, entry in ipairs(list) do usedBars[#usedBars + 1] = entry.data.bar end
end

local function LayoutBars()
    if not anchorFrame then return end
    if not isPreviewing then SortBars() end
    local bars = isPreviewing and previewBars or usedBars
    local h, s = DB.timerGroup.height or 24, DB.spacing or 1
    local growUp = DB.growDirection == "UP"
    for i, bar in ipairs(bars) do
        if i <= (DB.maxBars or 5) then
            bar:Show()
            bar:ClearAllPoints()
            if growUp then
                bar:SetPoint("BOTTOM", anchorFrame, "BOTTOM", 0, (i - 1) * (h + s))
            else
                bar:SetPoint("TOP", anchorFrame, "TOP", 0, -(i - 1) * (h + s))
            end
        else
            bar:Hide()
        end
    end
    if IsAttachModeAvailable() then
        local target = GetAttachTargetFrame()
        if target then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint(DB.attachPoint == "Below" and "TOP" or "BOTTOM", target, DB.attachPoint == "Below" and "BOTTOM" or "TOP", DB.attachOffsetX or 0, DB.attachPoint == "Below" and (DB.attachOffsetY or 2) or (DB.attachOffsetY or 2))
            anchorFrame.bg:Hide()
            anchorFrame.label:Hide()
        end
    else
        anchorFrame:ClearAllPoints()
        anchorFrame:SetPoint("CENTER", UIParent, "CENTER", DB.posX or 0, DB.posY or -200)
        anchorFrame.bg:SetShown(not DB.locked)
        anchorFrame.label:SetShown(not DB.locked)
    end
end

local function RefreshAll()
    for _, data in pairs(activeBars) do if data.bar then StyleBar(data.bar) end end
    for _, bar in ipairs(previewBars) do StyleBar(bar) end
    LayoutBars()
end

local function TriggerCooldown(unit)
    local data = activeBars[UnitGUID(unit) or ""]
    if not data then return end
    data.startTime = GetTime()
    data.bar:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - data.startTime
        local remaining = data.cd - elapsed
        if remaining > 0 then
            self:SetValue(elapsed / data.cd)
            if DB.showTimer then self.TimerText:SetText(remaining > 6 and string.format("%d", math.floor(remaining)) or string.format("%.1f", remaining)) end
        else
            self:SetValue(1)
            self.TimerText:SetText(DB.showReadyText and (DB.readyText or "READY") or "")
            self:SetScript("OnUpdate", nil)
            LayoutBars()
        end
    end)
    LayoutBars()
end

local function UpdateLayout()
    if not CheckEnvironment() or not DB.enabled then
        if anchorFrame then anchorFrame:Hide() end
        return
    end
    EnsureAnchor()
    anchorFrame:Show()
    if isPreviewing then return LayoutBars() end
    local current = {}
    for _, unit in ipairs({ "player", "party1", "party2", "party3", "party4" }) do
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then current[guid] = unit end
        end
    end
    for guid, data in pairs(activeBars) do
        if not current[guid] then ReleaseBar(data.bar) activeBars[guid] = nil end
    end
    for guid, unit in pairs(current) do
        if not activeBars[guid] then
            local spellData = SPEC_INTERRUPT_DB[GetUnitSpecID(unit)]
            if spellData and spellData.id and spellData.id > 0 then
                local bar = AcquireBar()
                if bar then
                    bar.unit = unit
                    bar.Text:SetText(UnitName(unit) or unit)
                    local spell = C_Spell.GetSpellInfo(spellData.id)
                    bar.Icon:SetTexture(spell and spell.iconID or 134400)
                    bar.TimerText:SetText(DB.showReadyText and (DB.readyText or "READY") or "")
                    StyleBar(bar)
                    activeBars[guid] = { bar = bar, cd = spellData.cd, startTime = 0, unit = unit }
                end
            end
        end
    end
    RefreshAll()
end

local function TogglePreview(enable)
    EnsureAnchor()
    isPreviewing = enable
    for _, data in pairs(activeBars) do if data.bar then data.bar:Hide() end end
    for _, bar in ipairs(previewBars) do ReleaseBar(bar) end
    wipe(previewBars)
    if not enable then return UpdateLayout() end
    local playerName = UnitName("player") or "Player"
    local _, playerClass = UnitClass("player")
    local preview = {
        { name = playerName, class = playerClass, spellID = 1766, ready = true },
        { name = "Mage", class = "MAGE", spellID = 2139, ready = true },
        { name = "Hunter", class = "HUNTER", spellID = 147362, ready = true },
        { name = "Paladin", class = "PALADIN", spellID = 96231, ready = false, cd = 15 },
        { name = "Shaman", class = "SHAMAN", spellID = 57994, ready = false, cd = 8 },
    }
    for _, info in ipairs(preview) do
        local bar = AcquireBar()
        if bar then
            bar._previewClass = info.class
            bar.Text:SetText(info.name)
            local spell = C_Spell.GetSpellInfo(info.spellID)
            bar.Icon:SetTexture(spell and spell.iconID or 136197)
            StyleBar(bar)
            if info.ready then
                bar:SetValue(1)
                bar.TimerText:SetText(DB.showReadyText and (DB.readyText or "READY") or "")
            else
                local start = GetTime()
                bar:SetValue(0)
                bar:SetScript("OnUpdate", function(self)
                    local rem = info.cd - (GetTime() - start)
                    if rem > 0 then self:SetValue(1 - rem / info.cd) self.TimerText:SetText(rem > 6 and string.format("%d", math.floor(rem)) or string.format("%.1f", rem))
                    else self:SetValue(1) self.TimerText:SetText(DB.showReadyText and (DB.readyText or "READY") or "") self:SetScript("OnUpdate", nil) end
                end)
            end
            previewBars[#previewBars + 1] = bar
        end
    end
    anchorFrame.bg:Show()
    anchorFrame.label:Show()
    LayoutBars()
end

local function ProcessPendingEvents()
    processingScheduled = false
    local interruptCount, targetUnit = 0, nil
    for unit in pairs(pendingEvents.interrupts) do interruptCount = interruptCount + 1 targetUnit = unit end
    if interruptCount == 1 then
        local interruptTime = pendingEvents.interrupts[targetUnit].time
        if not (pendingEvents.auras[targetUnit] and math.abs(interruptTime - pendingEvents.auras[targetUnit].time) <= 0.030) then
            local best, bestDiff = nil, math.huge
            for unit, data in pairs(pendingEvents.casts) do
                local diff = math.abs(interruptTime - data.time)
                if diff <= TIME_WINDOW and diff < bestDiff then best = unit bestDiff = diff end
            end
            if best then TriggerCooldown(best) end
        end
    end
    wipe(pendingEvents.interrupts) wipe(pendingEvents.casts) wipe(pendingEvents.auras)
end

local function ScheduleProcessing() if not processingScheduled then processingScheduled = true C_Timer.After(0.03, ProcessPendingEvents) end end

Core:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", MODULE_KEY, function(_, unit, _, spellID)
    if not DB.enabled or isPreviewing or not isValidEnvironment then return end
    if unit == "player" then
        local data = SPEC_INTERRUPT_DB[GetUnitSpecID("player")]
        if data and data.id == spellID then TriggerCooldown("player") end
    elseif string.find(unit or "", "party") then
        pendingEvents.casts[unit] = { time = GetTime() }
        ScheduleProcessing()
    end
end)

Core:RegisterEvent("UNIT_AURA", MODULE_KEY, function(_, unit)
    if DB.enabled and not isPreviewing and isValidEnvironment and string.find(unit or "", "nameplate") then
        pendingEvents.auras[unit] = { time = GetTime() } ScheduleProcessing()
    end
end)

Core:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", MODULE_KEY, function(_, unit)
    if DB.enabled and not isPreviewing and isValidEnvironment and string.find(unit or "", "nameplate") then
        pendingEvents.interrupts[unit] = { time = GetTime() } ScheduleProcessing()
    end
end)

Core:RegisterEvent("PLAYER_ENTERING_WORLD", MODULE_KEY, function() DB.preview = false C_Timer.After(1, UpdateLayout) end)
Core:RegisterEvent("GROUP_ROSTER_UPDATE", MODULE_KEY, UpdateLayout)
Core:RegisterEvent("ZONE_CHANGED_NEW_AREA", MODULE_KEY, UpdateLayout)
Core:RegisterEvent("CHALLENGE_MODE_START", MODULE_KEY, UpdateLayout)
Core:RegisterEvent("CHALLENGE_MODE_COMPLETED", MODULE_KEY, UpdateLayout)
Core:RegisterEvent("CHALLENGE_MODE_RESET", MODULE_KEY, UpdateLayout)
Core:RegisterEvent("EX_PARTY_SPEC_UPDATED", MODULE_KEY, UpdateLayout)

Core:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY, function(info)
    DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
    if info and info.key == "attachFrame" then DB._attachFrameSetByUser = true end
    if DB.preview then TogglePreview(true) else UpdateLayout() end
end)

Core:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY, function(info)
    if info and info.key == "btn_reset_pos" then
        DB.posX, DB.posY = 0, -200
        UpdateLayout()
    end
end)

Core:RegisterEditModeCallback(MODULE_KEY, function(enabled)
    DB.locked = not enabled
    DB.preview = enabled
    TogglePreview(enabled)
end)

local Module = {}
function Module:RefreshDisplay() if DB.preview then TogglePreview(true) else UpdateLayout() end end
function Module:ResetPosition() DB.posX, DB.posY = 0, -200 UpdateLayout() end

RRT_NS.InterruptTracker = Module
Core:ReportReady(MODULE_KEY)
