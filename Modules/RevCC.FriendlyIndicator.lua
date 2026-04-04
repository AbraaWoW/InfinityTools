-- =====================================================================
-- [[ RevCC.FriendlyIndicator — Friendly Unit Frame Spell Icons ]]
-- Ported from MiniCC by Jaliborc.
-- Attaches defensive/important/CC spell icons to friendly unit frames.
-- =====================================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local INFINITY_MODULE_KEY = "RevCC.FriendlyIndicator"
local L = (InfinityTools and InfinityTools.L)
    or setmetatable({}, { __index = function(_, k) return k end })

-- =====================================================================
-- SECTION 1: InfinityGrid layout registration
-- =====================================================================

local function REGISTER_LAYOUT()
    local layout = {
        { key = "header",    type = "header",      x = 1,  y = 1,  w = 53, h = 2, label = "Friendly Indicator", labelSize = 25 },
        { key = "desc",      type = "description", x = 1,  y = 4,  w = 53, h = 2, label = "Shows CC, defensive, and important spell icons on friendly unit frames." },

        { key = "div_enable",type = "divider",     x = 1,  y = 8,  w = 53, h = 1 },
        { key = "sub_enable",type = "subheader",   x = 1,  y = 7,  w = 53, h = 1, label = "Enable", labelSize = 18 },
        { key = "enabled",         type = "checkbox", x = 1,  y = 9,  w = 8,  h = 2, label = L["Enable"] },
        { key = "enabledWorld",    type = "checkbox", x = 11, y = 9,  w = 8,  h = 2, label = "World" },
        { key = "enabledArena",    type = "checkbox", x = 21, y = 9,  w = 8,  h = 2, label = "Arena" },
        { key = "enabledBG",       type = "checkbox", x = 31, y = 9,  w = 8,  h = 2, label = "BG" },
        { key = "enabledDungeon",  type = "checkbox", x = 1,  y = 12, w = 10, h = 2, label = "Dungeon" },
        { key = "enabledRaid",     type = "checkbox", x = 13, y = 12, w = 8,  h = 2, label = "Raid" },

        -- Party/World settings
        { key = "div_default",type = "divider",    x = 1,  y = 17, w = 53, h = 1 },
        { key = "sub_default",type = "subheader",  x = 1,  y = 16, w = 53, h = 1, label = "Party / World", labelSize = 18 },
        { key = "defaultExcludePlayer",     type = "checkbox",  x = 1,  y = 18, w = 15, h = 2, label = "Exclude Self" },
        { key = "defaultShowDefensives",    type = "checkbox",  x = 18, y = 18, w = 16, h = 2, label = "Show Defensives" },
        { key = "defaultShowImportant",     type = "checkbox",  x = 36, y = 18, w = 16, h = 2, label = "Show Important" },
        { key = "defaultShowCC",            type = "checkbox",  x = 1,  y = 21, w = 10, h = 2, label = "Show CC" },
        { key = "defaultGrow",              type = "dropdown",  x = 13, y = 21, w = 14, h = 2, label = "Grow", items = "LEFT,RIGHT,CENTER,DOWN" },
        { key = "defaultOffX",              type = "slider",    x = 29, y = 21, w = 12, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "defaultOffY",              type = "slider",    x = 43, y = 21, w = 10, h = 2, label = "Offset Y", min = -100, max = 100 },
        { key = "defaultSize",              type = "slider",    x = 1,  y = 24, w = 12, h = 2, label = "Icon Size", min = 16, max = 64 },
        { key = "defaultMaxIcons",          type = "slider",    x = 15, y = 24, w = 12, h = 2, label = "Max Icons", min = 1,  max = 8  },
        { key = "defaultGlow",              type = "checkbox",  x = 29, y = 24, w = 8,  h = 2, label = "Glow" },
        { key = "defaultReverse",           type = "checkbox",  x = 39, y = 24, w = 14, h = 2, label = "Reverse CD" },
        { key = "defaultColorByDispelType", type = "checkbox",  x = 1,  y = 27, w = 22, h = 2, label = "Color by Dispel Type" },
        { key = "defaultShowTooltips",      type = "checkbox",  x = 25, y = 27, w = 14, h = 2, label = "Show Tooltips" },

        -- Raid settings
        { key = "div_raid",  type = "divider",     x = 1,  y = 32, w = 53, h = 1 },
        { key = "sub_raid",  type = "subheader",   x = 1,  y = 31, w = 53, h = 1, label = "Raid", labelSize = 18 },
        { key = "raidExcludePlayer",     type = "checkbox",  x = 1,  y = 33, w = 15, h = 2, label = "Exclude Self" },
        { key = "raidShowDefensives",    type = "checkbox",  x = 18, y = 33, w = 16, h = 2, label = "Show Defensives" },
        { key = "raidShowImportant",     type = "checkbox",  x = 36, y = 33, w = 16, h = 2, label = "Show Important" },
        { key = "raidShowCC",            type = "checkbox",  x = 1,  y = 36, w = 10, h = 2, label = "Show CC" },
        { key = "raidGrow",              type = "dropdown",  x = 13, y = 36, w = 14, h = 2, label = "Grow", items = "LEFT,RIGHT,CENTER,DOWN" },
        { key = "raidOffX",              type = "slider",    x = 29, y = 36, w = 12, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "raidOffY",              type = "slider",    x = 43, y = 36, w = 10, h = 2, label = "Offset Y", min = -100, max = 100 },
        { key = "raidSize",              type = "slider",    x = 1,  y = 39, w = 12, h = 2, label = "Icon Size", min = 16, max = 64 },
        { key = "raidMaxIcons",          type = "slider",    x = 15, y = 39, w = 12, h = 2, label = "Max Icons", min = 1,  max = 8  },
        { key = "raidGlow",              type = "checkbox",  x = 29, y = 39, w = 8,  h = 2, label = "Glow" },
        { key = "raidReverse",           type = "checkbox",  x = 39, y = 39, w = 14, h = 2, label = "Reverse CD" },
        { key = "raidColorByDispelType", type = "checkbox",  x = 1,  y = 42, w = 22, h = 2, label = "Color by Dispel Type" },
        { key = "raidShowTooltips",      type = "checkbox",  x = 25, y = 42, w = 14, h = 2, label = "Show Tooltips" },
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
    enabledBG = true,
    enabledDungeon = true,
    enabledRaid = false,
    -- Default (party/world) instance settings
    defaultExcludePlayer = false,
    defaultShowDefensives = true,
    defaultShowImportant = true,
    defaultShowCC = false,
    defaultOffX = 0,
    defaultOffY = 0,
    defaultGrow = "CENTER",
    defaultSize = 30,
    defaultGlow = true,
    defaultReverse = true,
    defaultMaxIcons = 1,
    defaultColorByDispelType = true,
    defaultShowTooltips = false,
    -- Raid instance settings
    raidExcludePlayer = false,
    raidShowDefensives = true,
    raidShowImportant = true,
    raidShowCC = true,
    raidOffX = 0,
    raidOffY = 0,
    raidGrow = "CENTER",
    raidSize = 25,
    raidGlow = true,
    raidReverse = true,
    raidMaxIcons = 1,
    raidColorByDispelType = true,
    raidShowTooltips = false,
}

local DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =====================================================================
-- SECTION 3: Module logic
-- =====================================================================

local MCC = InfinityTools.RevCC
if not MCC then return end

local UnitExists       = _G.UnitExists
local IsInInstance     = _G.IsInInstance
local C_Timer          = _G.C_Timer
local UIParent         = _G.UIParent

-- Tracks per-anchor watcher entries
---@type table<table, table>
local watchers = {}

local paused = false

-- Returns current options based on raid vs default context
local function GetOptions()
    if MCC.InstanceOptions:IsRaid() then
        return {
            ExcludePlayer    = DB.raidExcludePlayer,
            ShowDefensives   = DB.raidShowDefensives,
            ShowImportant    = DB.raidShowImportant,
            ShowCC           = DB.raidShowCC,
            Grow             = DB.raidGrow,
            OffsetX          = DB.raidOffX,
            OffsetY          = DB.raidOffY,
            Size             = DB.raidSize,
            Glow             = DB.raidGlow,
            Reverse          = DB.raidReverse,
            MaxIcons         = DB.raidMaxIcons,
            ColorByDispelType= DB.raidColorByDispelType,
            ShowTooltips     = DB.raidShowTooltips,
        }
    else
        return {
            ExcludePlayer    = DB.defaultExcludePlayer,
            ShowDefensives   = DB.defaultShowDefensives,
            ShowImportant    = DB.defaultShowImportant,
            ShowCC           = DB.defaultShowCC,
            Grow             = DB.defaultGrow,
            OffsetX          = DB.defaultOffX,
            OffsetY          = DB.defaultOffY,
            Size             = DB.defaultSize,
            Glow             = DB.defaultGlow,
            Reverse          = DB.defaultReverse,
            MaxIcons         = DB.defaultMaxIcons,
            ColorByDispelType= DB.defaultColorByDispelType,
            ShowTooltips     = DB.defaultShowTooltips,
        }
    end
end

local function IsCompoundUnit(unit)
    return unit:find("target") ~= nil
        or unit:find("pet") ~= nil
        or unit:find("focus") ~= nil
end

local function IsPet(unit)
    return unit:find("pet") ~= nil
end

local function AnchorContainer(container, anchor, options)
    if not options then return end

    local frame = container.Frame
    frame:ClearAllPoints()
    frame:SetAlpha(1)
    frame:SetFrameStrata(MCC.Frames:GetNextStrata(anchor:GetFrameStrata()))
    frame:SetFrameLevel(anchor:GetFrameLevel() + 1)

    local anchorPoint    = "CENTER"
    local relativeToPoint = "CENTER"

    if options.Grow == "LEFT" then
        anchorPoint       = "RIGHT"
        relativeToPoint   = "LEFT"
    elseif options.Grow == "RIGHT" then
        anchorPoint       = "LEFT"
        relativeToPoint   = "RIGHT"
    elseif options.Grow == "DOWN" then
        anchorPoint       = "TOP"
        relativeToPoint   = "BOTTOM"
    end

    container:SetGrowDown(options.Grow == "DOWN")
    frame:SetPoint(anchorPoint, anchor, relativeToPoint, options.OffsetX, options.OffsetY)
end

local function UpdateWatcherAuras(entry)
    if not entry or not entry.Watcher or not entry.Container then return end
    if paused then return end
    if not entry.Unit or not UnitExists(entry.Unit) then return end

    local options = GetOptions()
    if not options then return end

    local iconsReverse      = options.Reverse
    local iconsGlow         = options.Glow
    local maxIcons          = options.MaxIcons or 1
    local container         = entry.Container
    local colorByDispelType = options.ColorByDispelType
    local showTooltips      = options.ShowTooltips

    local ccState        = entry.Watcher:GetCcState()
    local defensiveState = entry.Watcher:GetDefensiveState()
    local importantState = entry.Watcher:GetImportantState()

    local ccCount        = options.ShowCC          and #ccState        or 0
    local defensiveCount = options.ShowDefensives  and #defensiveState or 0
    local importantCount = options.ShowImportant   and #importantState or 0

    local ccSlots, defensiveSlots, importantSlots =
        MCC.SlotDistribution.Calculate(maxIcons, ccCount, defensiveCount, importantCount)

    local slotIndex = 1

    for i = 1, ccSlots do
        if slotIndex > container.Count then break end
        local aura = ccState[i]
        container:SetSlot(slotIndex, {
            Texture         = aura.SpellIcon,
            DurationObject  = aura.DurationObject,
            Alpha           = aura.IsCC,
            ReverseCooldown = iconsReverse,
            Glow            = iconsGlow,
            Color           = colorByDispelType and aura.DispelColor or nil,
            FontScale       = nil,
            SpellId         = showTooltips and aura.SpellId or nil,
        })
        slotIndex = slotIndex + 1
    end

    for i = 1, defensiveSlots do
        if slotIndex > container.Count then break end
        local aura = defensiveState[i]
        container:SetSlot(slotIndex, {
            Texture         = aura.SpellIcon,
            DurationObject  = aura.DurationObject,
            Alpha           = aura.IsDefensive,
            ReverseCooldown = iconsReverse,
            Glow            = iconsGlow,
            FontScale       = nil,
            SpellId         = showTooltips and aura.SpellId or nil,
        })
        slotIndex = slotIndex + 1
    end

    for i = 1, importantSlots do
        if slotIndex > container.Count then break end
        local aura = importantState[i]
        container:SetSlot(slotIndex, {
            Texture         = aura.SpellIcon,
            DurationObject  = aura.DurationObject,
            Alpha           = aura.IsImportant,
            ReverseCooldown = iconsReverse,
            Glow            = iconsGlow,
            FontScale       = nil,
            SpellId         = showTooltips and aura.SpellId or nil,
        })
        slotIndex = slotIndex + 1
    end

    for i = slotIndex, container.Count do
        container:SetSlotUnused(i)
    end
end

local function EnsureWatcher(anchor, unit)
    unit = unit or (anchor.unit) or (anchor.GetAttribute and anchor:GetAttribute("unit"))
    if not unit then return nil end

    if IsCompoundUnit(unit) then return nil end
    if IsPet(unit) then return nil end

    local options = GetOptions()
    if not options then return nil end

    local entry = watchers[anchor]

    if not entry then
        local maxIcons = tonumber(options.MaxIcons) or 1
        local size     = tonumber(options.Size) or 30
        local container = MCC.IconSlotContainer:New(UIParent, maxIcons, size, 2,
            "Friendly Indicators", nil, "Friendly Indicators")
        local watcher = MCC.UnitAuraWatcher:New(unit, nil, {
            Defensives = true,
            Important  = true,
            CC         = true,
        })

        entry = {
            Container = container,
            Watcher   = watcher,
            Anchor    = anchor,
            Unit      = unit,
        }
        watchers[anchor] = entry

        watcher:RegisterCallback(function()
            UpdateWatcherAuras(entry)
        end)
    else
        if entry.Unit ~= unit then
            entry.Watcher:Dispose()
            entry.Watcher = MCC.UnitAuraWatcher:New(unit, nil, {
                Defensives = true,
                Important  = true,
                CC         = true,
            })
            entry.Watcher:RegisterCallback(function()
                UpdateWatcherAuras(entry)
            end)
            entry.Unit = unit
            entry.Container:ResetAllSlots()
            UpdateWatcherAuras(entry)
        end
    end

    UpdateWatcherAuras(entry)
    AnchorContainer(entry.Container, anchor, options)
    MCC.Frames:ShowHideFrame(entry.Container.Frame, anchor, options.ExcludePlayer)

    return entry
end

-- Scan all supported unit frames (Blizzard, ElvUI, Cell, Grid2, SUF, Plexus, TPerl…)
local function EnsureWatchers()
    local anchors = MCC.Frames:GetAll(true)
    for _, frame in ipairs(anchors) do
        EnsureWatcher(frame)
    end
end

local function DisableWatchers()
    for _, entry in pairs(watchers) do
        if entry.Watcher then
            entry.Watcher:Disable()
        end
        if entry.Container then
            entry.Container:ResetAllSlots()
            entry.Container.Frame:Hide()
        end
    end
end

local function EnableWatchers()
    for _, entry in pairs(watchers) do
        if entry.Watcher then
            entry.Watcher:Enable()
        end
    end
end

local function IsModuleActiveForZone()
    if not DB.enabled then return false end

    local inInstance, instanceType = IsInInstance()

    if instanceType == "raid"  and DB.enabledRaid    then return true end
    if instanceType == "party" and DB.enabledDungeon then return true end
    if instanceType == "arena" and DB.enabledArena   then return true end
    if instanceType == "pvp"   and DB.enabledBG      then return true end
    if not inInstance          and DB.enabledWorld    then return true end

    return false
end

local function Refresh()
    local options = GetOptions()

    if not options or not IsModuleActiveForZone() then
        DisableWatchers()
        return
    end

    EnableWatchers()
    EnsureWatchers()

    for anchor, entry in pairs(watchers) do
        local container = entry.Container
        local iconSize  = tonumber(options.Size) or 30
        local maxIcons  = tonumber(options.MaxIcons) or 1
        container:SetIconSize(iconSize)
        container:SetCount(maxIcons)

        UpdateWatcherAuras(entry)
        AnchorContainer(container, anchor, options)
        MCC.Frames:ShowHideFrame(container.Frame, anchor, options.ExcludePlayer)
    end
end

local function OnCufSetUnit(frame, unit)
    if not frame or not MCC.Frames:IsFriendlyCuf(frame) then return end
    if not unit then return end
    EnsureWatcher(frame, unit)
end

local function OnCufUpdateVisible(frame)
    if not frame or not MCC.Frames:IsFriendlyCuf(frame) then return end
    local entry = watchers[frame]
    if not entry then return end
    local options = GetOptions()
    if not options then return end
    MCC.Frames:ShowHideFrame(entry.Container.Frame, frame, options.ExcludePlayer)
end

local function Init()
    local eventsFrame = CreateFrame("Frame")
    eventsFrame:SetScript("OnEvent", function(_, event)
        if event == "GROUP_ROSTER_UPDATE" or event == "ZONE_CHANGED_NEW_AREA" then
            C_Timer.After(0, function()
                Refresh()
            end)
        end
    end)
    eventsFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventsFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    if not MCC.WoWEx:IsDandersEnabled() then
        if CompactUnitFrame_SetUnit then
            hooksecurefunc("CompactUnitFrame_SetUnit", OnCufSetUnit)
        end
        if CompactUnitFrame_UpdateVisible then
            hooksecurefunc("CompactUnitFrame_UpdateVisible", OnCufUpdateVisible)
        end
    end

    if IsModuleActiveForZone() then
        EnsureWatchers()
    end
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
-- SECTION 5: Live settings listener
-- =====================================================================

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    local key = info.key

    if key == "enabled" or key == "enabledWorld" or key == "enabledArena"
    or key == "enabledBG" or key == "enabledDungeon" or key == "enabledRaid" then
        C_Timer.After(0, Refresh)
    end
end)
