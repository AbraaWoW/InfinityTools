-- =====================================================================
-- [[ RevCC.AlertsModule — Enemy Spell Alerts ]]
-- Ported from MiniCC by Jaliborc.
-- Shows floating bar of enemy important/defensive spell icons.
-- =====================================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local INFINITY_MODULE_KEY = "RevCC.AlertsModule"
local L = (InfinityTools and InfinityTools.L)
    or setmetatable({}, { __index = function(_, k) return k end })

-- =====================================================================
-- SECTION 1: InfinityGrid layout registration
-- =====================================================================

local function REGISTER_LAYOUT()
    local layout = {
        { key = "header",       type = "header",      x = 1,  y = 1,  w = 53, h = 2, label = "Enemy Spell Alerts", labelSize = 25 },
        { key = "desc",         type = "description", x = 1,  y = 4,  w = 53, h = 2, label = "Shows enemy important/defensive spell icons in a floating bar." },

        { key = "div_enable",   type = "divider",     x = 1,  y = 8,  w = 53, h = 1 },
        { key = "sub_enable",   type = "subheader",   x = 1,  y = 7,  w = 53, h = 1, label = "Enable", labelSize = 18 },
        { key = "enabled",      type = "checkbox",    x = 1,  y = 9,  w = 8,  h = 2, label = L["Enable"] },
        { key = "enabledWorld",  type = "checkbox",   x = 11, y = 9,  w = 8,  h = 2, label = "World" },
        { key = "enabledArena",  type = "checkbox",   x = 21, y = 9,  w = 8,  h = 2, label = "Arena" },
        { key = "enabledBG",     type = "checkbox",   x = 31, y = 9,  w = 8,  h = 2, label = "BG" },
        { key = "enabledDungeon",type = "checkbox",   x = 39, y = 9,  w = 10, h = 2, label = "Dungeon" },
        { key = "enabledRaid",   type = "checkbox",   x = 1,  y = 12, w = 8,  h = 2, label = "Raid" },

        { key = "div_icons",    type = "divider",     x = 1,  y = 17, w = 53, h = 1 },
        { key = "sub_icons",    type = "subheader",   x = 1,  y = 16, w = 53, h = 1, label = "Icons", labelSize = 18 },
        { key = "iconsEnabled",       type = "checkbox", x = 1,  y = 18, w = 8,  h = 2, label = "Enable Icons" },
        { key = "iconsSize",          type = "slider",   x = 12, y = 18, w = 16, h = 2, label = "Icon Size",   min = 20, max = 80 },
        { key = "iconsMaxIcons",      type = "slider",   x = 30, y = 18, w = 14, h = 2, label = "Max Icons",   min = 1,  max = 16 },
        { key = "iconsGlow",          type = "checkbox", x = 1,  y = 21, w = 8,  h = 2, label = "Glow" },
        { key = "iconsReverse",       type = "checkbox", x = 11, y = 21, w = 16, h = 2, label = "Reverse Cooldown" },
        { key = "iconsColorByClass",  type = "checkbox", x = 29, y = 21, w = 15, h = 2, label = "Color by Class" },
        { key = "showTooltips",       type = "checkbox", x = 1,  y = 24, w = 12, h = 2, label = "Show Tooltips" },
        { key = "includeDefensives",  type = "checkbox", x = 15, y = 24, w = 16, h = 2, label = "Include Defensives" },

        { key = "div_sound",    type = "divider",     x = 1,  y = 29, w = 53, h = 1 },
        { key = "sub_sound",    type = "subheader",   x = 1,  y = 28, w = 53, h = 1, label = "Sound", labelSize = 18 },
        { key = "soundImportantEnabled", type = "checkbox", x = 1,  y = 30, w = 20, h = 2, label = "Play Sound on Important" },
        { key = "soundDefensiveEnabled", type = "checkbox", x = 23, y = 30, w = 20, h = 2, label = "Play Sound on Defensive" },

        { key = "div_pos",      type = "divider",     x = 1,  y = 35, w = 53, h = 1 },
        { key = "sub_pos",      type = "subheader",   x = 1,  y = 34, w = 53, h = 1, label = "Position", labelSize = 18 },
        { key = "locked",       type = "checkbox",    x = 1,  y = 36, w = 8,  h = 2, label = L["Lock Position"] },
        { key = "preview",      type = "checkbox",    x = 11, y = 36, w = 10, h = 2, label = L["Preview Mode"] },
        { key = "btn_reset_pos",type = "button",      x = 24, y = 36, w = 16, h = 2, label = L["Reset Position"] },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =====================================================================
-- SECTION 2: DB Defaults
-- =====================================================================

local MODULE_DEFAULTS = {
    enabled = false,
    enabledWorld = true,
    enabledArena = true,
    enabledBG = false,
    enabledDungeon = false,
    enabledRaid = false,
    includeDefensives = true,
    point = "CENTER",
    relativeTo = "UIParent",
    relativePoint = "TOP",
    offsetX = 0,
    offsetY = -100,
    soundImportantEnabled = false,
    soundDefensiveEnabled = false,
    iconsEnabled = true,
    iconsSize = 50,
    iconsGlow = true,
    iconsReverse = true,
    iconsColorByClass = true,
    iconsMaxIcons = 8,
    showTooltips = false,
    locked = false,
    preview = false,
}

local DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =====================================================================
-- SECTION 3: Module logic
-- =====================================================================

local MCC = InfinityTools.RevCC
if not MCC then return end

local UnitExists   = _G.UnitExists
local UnitClass    = _G.UnitClass
local IsInInstance = _G.IsInInstance
local C_NamePlate  = _G.C_NamePlate
local C_Timer      = _G.C_Timer
local UIParent     = _G.UIParent
local wipe         = _G.wipe
local GetTime      = _G.GetTime

local previousImportantAuras = {}
local previousDefensiveAuras = {}
local currentImportantAuras  = {}
local currentDefensiveAuras  = {}
local slotOptionsScratch     = {}
local colorScratch           = { r = 0, g = 0, b = 0, a = 1 }

local pendingAuraUpdate  = false

---@type IconSlotContainer
local container

---@type table<string, Watcher>
local nameplateWatchers = {}

local eventsFrame

local function PlayAlertSound(spellType)
    if spellType == "important" and DB.soundImportantEnabled then
        PlaySoundFile("Interface\\AddOns\\InfinityTools\\Media\\Sonar.ogg", "Master")
    elseif spellType == "defensive" and DB.soundDefensiveEnabled then
        PlaySoundFile("Interface\\AddOns\\InfinityTools\\Media\\Sonar.ogg", "Master")
    end
end

local function ProcessWatcherData(watcher, slot)
    local unit = watcher:GetUnit()

    if not unit or not UnitExists(unit) then
        return slot
    end

    local defensivesData = watcher:GetDefensiveState()
    local importantData  = watcher:GetImportantState()

    if #importantData == 0 and #defensivesData == 0 then
        return slot
    end

    local iconsEnabled   = DB.iconsEnabled
    local iconsGlow      = DB.iconsGlow
    local iconsReverse   = DB.iconsReverse
    local colorByClass   = DB.iconsColorByClass
    local includeDefensives = DB.includeDefensives
    local showTooltips   = DB.showTooltips

    local color = nil

    if colorByClass then
        local _, class = UnitClass(unit)
        if class then
            local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
            if classColor then
                colorScratch.r = classColor.r
                colorScratch.g = classColor.g
                colorScratch.b = classColor.b
                colorScratch.a = 1
                color = colorScratch
            end
        end
    end

    for _, data in ipairs(importantData) do
        if iconsEnabled and slot < container.Count then
            slot = slot + 1
            slotOptionsScratch.Texture        = data.SpellIcon
            slotOptionsScratch.DurationObject = data.DurationObject
            slotOptionsScratch.Alpha          = data.IsImportant
            slotOptionsScratch.Glow           = iconsGlow
            slotOptionsScratch.ReverseCooldown= iconsReverse
            slotOptionsScratch.Color          = color
            slotOptionsScratch.FontScale      = nil
            slotOptionsScratch.SpellId        = showTooltips and data.SpellId or nil
            container:SetSlot(slot, slotOptionsScratch)
        end

        if data.AuraInstanceID then
            currentImportantAuras[data.AuraInstanceID] = true
            if not previousImportantAuras[data.AuraInstanceID] then
                PlayAlertSound("important")
            end
        end
    end

    for _, data in ipairs(defensivesData) do
        if includeDefensives and iconsEnabled and slot < container.Count then
            slot = slot + 1
            slotOptionsScratch.Texture        = data.SpellIcon
            slotOptionsScratch.DurationObject = data.DurationObject
            slotOptionsScratch.Alpha          = data.IsDefensive
            slotOptionsScratch.Glow           = iconsGlow
            slotOptionsScratch.ReverseCooldown= iconsReverse
            slotOptionsScratch.Color          = color
            slotOptionsScratch.FontScale      = nil
            slotOptionsScratch.SpellId        = showTooltips and data.SpellId or nil
            container:SetSlot(slot, slotOptionsScratch)
        end

        if data.AuraInstanceID then
            currentDefensiveAuras[data.AuraInstanceID] = true
            if not previousDefensiveAuras[data.AuraInstanceID] then
                PlayAlertSound("defensive")
            end
        end
    end

    return slot
end

local function OnAuraDataChanged()
    if not DB.enabled then
        return
    end

    local slot = 0

    wipe(currentImportantAuras)
    wipe(currentDefensiveAuras)

    for _, watcher in pairs(nameplateWatchers) do
        slot = ProcessWatcherData(watcher, slot)
    end

    previousImportantAuras, currentImportantAuras = currentImportantAuras, previousImportantAuras
    previousDefensiveAuras, currentDefensiveAuras = currentDefensiveAuras, previousDefensiveAuras

    if not DB.iconsEnabled then
        container:ResetAllSlots()
        return
    end

    if slot > 0 then
        slot = slot + 1
    end

    if slot == 0 then
        container:ResetAllSlots()
    else
        for i = slot, container.Count do
            container:SetSlotUnused(i)
        end
    end
end

local function ScheduleAuraDataUpdate()
    if pendingAuraUpdate then
        return
    end
    pendingAuraUpdate = true
    C_Timer.After(0, function()
        pendingAuraUpdate = false
        OnAuraDataChanged()
    end)
end

local function OnNamePlateAdded(unitToken)
    if nameplateWatchers[unitToken] then
        nameplateWatchers[unitToken]:Dispose()
        nameplateWatchers[unitToken] = nil
    end

    if not UnitIsEnemy("player", unitToken) then
        return
    end

    local watcherFilter = {
        CC = true,
        Defensives = true,
        Important = true,
    }

    local watcher = MCC.UnitAuraWatcher:New(unitToken, nil, watcherFilter)
    watcher:RegisterCallback(ScheduleAuraDataUpdate)
    nameplateWatchers[unitToken] = watcher

    ScheduleAuraDataUpdate()
end

local function OnNamePlateRemoved(unitToken)
    if nameplateWatchers[unitToken] then
        nameplateWatchers[unitToken]:Dispose()
        nameplateWatchers[unitToken] = nil
        ScheduleAuraDataUpdate()
    end
end

local function RebuildNameplateWatchers()
    local activeTokens = {}
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        local unitToken = nameplate.unitToken
        if unitToken and UnitIsEnemy("player", unitToken) then
            activeTokens[unitToken] = true
        end
    end

    for unitToken, watcher in pairs(nameplateWatchers) do
        if not activeTokens[unitToken] then
            watcher:Dispose()
            nameplateWatchers[unitToken] = nil
        end
    end

    for unitToken in pairs(activeTokens) do
        if not nameplateWatchers[unitToken] then
            OnNamePlateAdded(unitToken)
        end
    end
end

local function DisableWatchers()
    for _, watcher in pairs(nameplateWatchers) do
        watcher:Disable()
    end
    if container then
        container:ResetAllSlots()
    end
    previousImportantAuras = {}
    previousDefensiveAuras = {}
end

local function EnableDisable()
    if not DB.enabled then
        DisableWatchers()
        return
    end

    local inInstance, instanceType = IsInInstance()

    local shouldEnable = false
    if instanceType == "raid" and DB.enabledRaid then
        shouldEnable = true
    elseif instanceType == "party" and DB.enabledDungeon then
        shouldEnable = true
    elseif instanceType == "arena" and DB.enabledArena then
        shouldEnable = true
    elseif instanceType == "pvp" and DB.enabledBG then
        shouldEnable = true
    elseif not inInstance and DB.enabledWorld then
        shouldEnable = true
    end

    if not shouldEnable then
        DisableWatchers()
        return
    end

    RebuildNameplateWatchers()
    ScheduleAuraDataUpdate()
end

local function RefreshContainerPosition()
    if not container then return end
    container.Frame:ClearAllPoints()
    container.Frame:SetPoint(
        DB.point,
        _G[DB.relativeTo] or UIParent,
        DB.relativePoint,
        DB.offsetX,
        DB.offsetY
    )
end

local function RefreshTestAlerts()
    if not container then return end

    local testSpells = {
        { spellId = 190319, class = "MAGE" },
        { spellId = 121471, class = "ROGUE" },
        { spellId = 107574, class = "WARRIOR" },
        { spellId = 47788,  class = "PRIEST", defensive = true },
        { spellId = 45438,  class = "MAGE",   defensive = true },
    }

    local slots = {}
    for _, entry in ipairs(testSpells) do
        if not entry.defensive or DB.includeDefensives then
            slots[#slots + 1] = entry
        end
    end

    local count = math.min(#slots, container.Count)
    local now = GetTime()

    for i = 1, count do
        local entry = slots[i]
        local tex = C_Spell.GetSpellTexture(entry.spellId)
        if tex then
            local duration  = 12 + (i - 1) * 3
            local startTime = now - (i - 1) * 1.25

            local color = nil
            if DB.iconsColorByClass and entry.class then
                local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
                if classColor then
                    color = { r = classColor.r, g = classColor.g, b = classColor.b, a = 1 }
                end
            end

            container:SetSlot(i, {
                Texture         = tex,
                DurationObject  = MCC.WoWEx:CreateDuration(startTime, duration),
                Alpha           = true,
                Glow            = DB.iconsGlow,
                ReverseCooldown = DB.iconsReverse,
                Color           = color,
                SpellId         = DB.showTooltips and entry.spellId or nil,
            })
        end
    end

    for i = count + 1, container.Count do
        container:SetSlotUnused(i)
    end
end

local function Init()
    local count = DB.iconsMaxIcons or 8
    local size  = DB.iconsSize or 50

    container = MCC.IconSlotContainer:New(UIParent, count, size, 2, "Alerts", nil, "Alerts")

    local initialRelativeTo = _G[DB.relativeTo] or UIParent
    container.Frame:SetPoint(
        DB.point,
        initialRelativeTo,
        DB.relativePoint,
        DB.offsetX,
        DB.offsetY
    )
    container.Frame:SetFrameLevel((initialRelativeTo:GetFrameLevel() or 0) + 5)
    container.Frame:SetClampedToScreen(true)
    container.Frame:RegisterForDrag("LeftButton")
    container.Frame:SetScript("OnDragStart", function(self)
        if not DB.locked then
            self:StartMoving()
        end
    end)
    container.Frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        DB.point = point
        DB.relativePoint = relativePoint
        DB.relativeTo = (relativeTo and relativeTo:GetName()) or "UIParent"
        DB.offsetX = x
        DB.offsetY = y
    end)
    container.Frame:Show()

    container:SetCount(count)
    container:SetIconSize(size)

    eventsFrame = CreateFrame("Frame")
    eventsFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventsFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventsFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventsFrame:SetScript("OnEvent", function(_, event, unitToken)
        if event == "NAME_PLATE_UNIT_ADDED" then
            if DB.enabled then
                local inInstance, instanceType = IsInInstance()
                local ok = (not inInstance and DB.enabledWorld)
                    or (instanceType == "party"   and DB.enabledDungeon)
                    or (instanceType == "raid"    and DB.enabledRaid)
                    or (instanceType == "arena"   and DB.enabledArena)
                    or (instanceType == "pvp"     and DB.enabledBG)
                if ok then
                    OnNamePlateAdded(unitToken)
                end
            end
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            OnNamePlateRemoved(unitToken)
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            EnableDisable()
        end
    end)

    EnableDisable()
end

-- =====================================================================
-- SECTION 4: Init on PLAYER_LOGIN
-- =====================================================================

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        Init()
    end
end)

-- =====================================================================
-- SECTION 5: Module callbacks (button wiring)
-- =====================================================================

InfinityTools:RegisterModuleCallback(INFINITY_MODULE_KEY, "btn_reset_pos", function()
    if container then
        container.Frame:ClearAllPoints()
        container.Frame:SetPoint("CENTER", UIParent, "TOP", 0, -100)
        DB.point = "CENTER"
        DB.relativePoint = "TOP"
        DB.relativeTo = "UIParent"
        DB.offsetX = 0
        DB.offsetY = -100
    end
end)

-- =====================================================================
-- SECTION 6: Live settings listener
-- =====================================================================

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    local key = info.key

    if key == "enabled" or key == "enabledWorld" or key == "enabledArena"
    or key == "enabledBG" or key == "enabledDungeon" or key == "enabledRaid" then
        EnableDisable()
        if DB.enabled and DB.preview then
            RefreshTestAlerts()
        end

    elseif key == "preview" then
        if DB.preview and DB.enabled then
            RefreshTestAlerts()
        elseif container then
            container:ResetAllSlots()
            ScheduleAuraDataUpdate()
        end

    elseif key == "iconsSize" then
        if container then
            container:SetIconSize(DB.iconsSize)
            if DB.preview and DB.enabled then RefreshTestAlerts() end
        end

    elseif key == "iconsMaxIcons" then
        if container then
            container:SetCount(DB.iconsMaxIcons)
            if DB.preview and DB.enabled then RefreshTestAlerts() end
        end

    elseif key == "locked" then
        if container then
            container.Frame:SetMovable(not DB.locked)
        end

    elseif key == "point" or key == "relativePoint" or key == "relativeTo"
    or key == "offsetX" or key == "offsetY" then
        RefreshContainerPosition()

    elseif container and DB.preview then
        RefreshTestAlerts()
    end
end)
