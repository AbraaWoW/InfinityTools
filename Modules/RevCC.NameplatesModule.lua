-- =====================================================================
-- [[ RevCC.Nameplates — Nameplate Spell Icons ]]
-- Ported from MiniCC by Jaliborc.
-- Attaches CC / Important spell icons to enemy and friendly nameplates.
-- =====================================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local INFINITY_MODULE_KEY = "RevCC.Nameplates"
local L = (InfinityTools and InfinityTools.L)
    or setmetatable({}, { __index = function(_, k) return k end })

-- =====================================================================
-- SECTION 1: InfinityGrid layout registration
-- =====================================================================

local function REGISTER_LAYOUT()
    local layout = {
        { key = "header",      type = "header",      x = 1,  y = 1,  w = 53, h = 2, label = "Nameplates", labelSize = 25 },
        { key = "desc",        type = "description", x = 1,  y = 4,  w = 53, h = 2, label = "Attaches CC and important spell icons to enemy and friendly nameplates." },

        { key = "div_enable",  type = "divider",     x = 1,  y = 8,  w = 53, h = 1 },
        { key = "sub_enable",  type = "subheader",   x = 1,  y = 7,  w = 53, h = 1, label = "Enable", labelSize = 18 },
        { key = "enabled",          type = "checkbox", x = 1,  y = 9,  w = 8,  h = 2, label = L["Enable"] },
        { key = "enabledWorld",     type = "checkbox", x = 11, y = 9,  w = 8,  h = 2, label = "World" },
        { key = "enabledArena",     type = "checkbox", x = 21, y = 9,  w = 8,  h = 2, label = "Arena" },
        { key = "enabledBG",        type = "checkbox", x = 31, y = 9,  w = 8,  h = 2, label = "BG" },
        { key = "enabledDungeon",   type = "checkbox", x = 1,  y = 12, w = 10, h = 2, label = "Dungeon" },
        { key = "enabledRaid",      type = "checkbox", x = 13, y = 12, w = 8,  h = 2, label = "Raid" },
        { key = "scaleWithNameplate",type = "checkbox",x = 24, y = 12, w = 20, h = 2, label = "Scale With Nameplate" },

        -- Enemy section
        { key = "div_enemy",   type = "divider",     x = 1,  y = 17, w = 53, h = 1 },
        { key = "sub_enemy",   type = "subheader",   x = 1,  y = 16, w = 53, h = 1, label = "Enemy", labelSize = 18 },

        -- Enemy CC
        { key = "sub_enemy_cc",type = "subheader",   x = 1,  y = 18, w = 53, h = 1, label = "Crowd Control", labelSize = 15 },
        { key = "enemyCCEnabled",    type = "checkbox",  x = 1,  y = 20, w = 8,  h = 2, label = "Enable" },
        { key = "enemyCCSize",       type = "slider",    x = 12, y = 20, w = 13, h = 2, label = "Size",      min = 16, max = 64 },
        { key = "enemyCCMaxIcons",   type = "slider",    x = 27, y = 20, w = 13, h = 2, label = "Max Icons", min = 1,  max = 10 },
        { key = "enemyCCGlow",       type = "checkbox",  x = 42, y = 20, w = 8,  h = 2, label = "Glow" },
        { key = "enemyCCReverse",    type = "checkbox",  x = 1,  y = 23, w = 16, h = 2, label = "Reverse CD" },
        { key = "enemyCCGrow",       type = "dropdown",  x = 19, y = 23, w = 14, h = 2, label = "Grow", items = "LEFT,RIGHT,CENTER" },
        { key = "enemyCCOffX",       type = "slider",    x = 35, y = 23, w = 10, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "enemyCCOffY",       type = "slider",    x = 1,  y = 26, w = 10, h = 2, label = "Offset Y", min = -100, max = 100 },

        -- Enemy Important
        { key = "sub_enemy_imp",type = "subheader",  x = 1,  y = 29, w = 53, h = 1, label = "Important Spells", labelSize = 15 },
        { key = "enemyImportantEnabled",  type = "checkbox", x = 1,  y = 31, w = 8,  h = 2, label = "Enable" },
        { key = "enemyImportantSize",     type = "slider",   x = 12, y = 31, w = 13, h = 2, label = "Size",      min = 16, max = 64 },
        { key = "enemyImportantMaxIcons", type = "slider",   x = 27, y = 31, w = 13, h = 2, label = "Max Icons", min = 1,  max = 10 },
        { key = "enemyImportantGlow",     type = "checkbox", x = 42, y = 31, w = 8,  h = 2, label = "Glow" },
        { key = "enemyImportantReverse",  type = "checkbox", x = 1,  y = 34, w = 16, h = 2, label = "Reverse CD" },
        { key = "enemyImportantGrow",     type = "dropdown", x = 19, y = 34, w = 14, h = 2, label = "Grow", items = "LEFT,RIGHT,CENTER" },
        { key = "enemyImportantOffX",     type = "slider",   x = 35, y = 34, w = 10, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "enemyImportantOffY",     type = "slider",   x = 1,  y = 37, w = 10, h = 2, label = "Offset Y", min = -100, max = 100 },

        -- Enemy Combined
        { key = "sub_enemy_combined",type = "subheader", x = 1,  y = 40, w = 53, h = 1, label = "Combined Mode (overrides CC + Important)", labelSize = 15 },
        { key = "enemyCombinedEnabled", type = "checkbox", x = 1, y = 42, w = 20, h = 2, label = "Enable Combined Mode" },

        -- Friendly section
        { key = "div_friendly",type = "divider",     x = 1,  y = 47, w = 53, h = 1 },
        { key = "sub_friendly",type = "subheader",   x = 1,  y = 46, w = 53, h = 1, label = "Friendly", labelSize = 18 },

        -- Friendly CC
        { key = "sub_friendly_cc",type = "subheader",x = 1,  y = 48, w = 53, h = 1, label = "Crowd Control", labelSize = 15 },
        { key = "friendlyCCEnabled",    type = "checkbox",  x = 1,  y = 50, w = 8,  h = 2, label = "Enable" },
        { key = "friendlyCCSize",       type = "slider",    x = 12, y = 50, w = 13, h = 2, label = "Size",      min = 16, max = 64 },
        { key = "friendlyCCMaxIcons",   type = "slider",    x = 27, y = 50, w = 13, h = 2, label = "Max Icons", min = 1,  max = 10 },
        { key = "friendlyCCGlow",       type = "checkbox",  x = 42, y = 50, w = 8,  h = 2, label = "Glow" },
        { key = "friendlyCCReverse",    type = "checkbox",  x = 1,  y = 53, w = 16, h = 2, label = "Reverse CD" },
        { key = "friendlyCCGrow",       type = "dropdown",  x = 19, y = 53, w = 14, h = 2, label = "Grow", items = "LEFT,RIGHT,CENTER" },
        { key = "friendlyCCOffX",       type = "slider",    x = 35, y = 53, w = 10, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "friendlyCCOffY",       type = "slider",    x = 1,  y = 56, w = 10, h = 2, label = "Offset Y", min = -100, max = 100 },

        -- Friendly Important
        { key = "sub_friendly_imp",type = "subheader",x = 1,  y = 59, w = 53, h = 1, label = "Important Spells", labelSize = 15 },
        { key = "friendlyImportantEnabled",  type = "checkbox", x = 1,  y = 61, w = 8,  h = 2, label = "Enable" },
        { key = "friendlyImportantSize",     type = "slider",   x = 12, y = 61, w = 13, h = 2, label = "Size",      min = 16, max = 64 },
        { key = "friendlyImportantMaxIcons", type = "slider",   x = 27, y = 61, w = 13, h = 2, label = "Max Icons", min = 1,  max = 10 },
        { key = "friendlyImportantGlow",     type = "checkbox", x = 42, y = 61, w = 8,  h = 2, label = "Glow" },
        { key = "friendlyImportantReverse",  type = "checkbox", x = 1,  y = 64, w = 16, h = 2, label = "Reverse CD" },
        { key = "friendlyImportantGrow",     type = "dropdown", x = 19, y = 64, w = 14, h = 2, label = "Grow", items = "LEFT,RIGHT,CENTER" },
        { key = "friendlyImportantOffX",     type = "slider",   x = 35, y = 64, w = 10, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "friendlyImportantOffY",     type = "slider",   x = 1,  y = 67, w = 10, h = 2, label = "Offset Y", min = -100, max = 100 },
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
    enabledRaid = true,
    scaleWithNameplate = true,
    -- Enemy CC
    enemyCCEnabled = true,
    enemyCCGrow = "RIGHT",
    enemyCCOffX = 0,
    enemyCCOffY = 0,
    enemyCCSize = 35,
    enemyCCGlow = true,
    enemyCCReverse = true,
    enemyCCMaxIcons = 5,
    -- Enemy Important
    enemyImportantEnabled = true,
    enemyImportantGrow = "LEFT",
    enemyImportantOffX = 0,
    enemyImportantOffY = 0,
    enemyImportantSize = 35,
    enemyImportantGlow = true,
    enemyImportantReverse = true,
    enemyImportantMaxIcons = 5,
    -- Enemy Combined
    enemyCombinedEnabled = false,
    -- Friendly CC
    friendlyCCEnabled = false,
    friendlyCCGrow = "RIGHT",
    friendlyCCOffX = 0,
    friendlyCCOffY = 0,
    friendlyCCSize = 35,
    friendlyCCGlow = true,
    friendlyCCReverse = true,
    friendlyCCMaxIcons = 5,
    -- Friendly Important
    friendlyImportantEnabled = false,
    friendlyImportantGrow = "LEFT",
    friendlyImportantOffX = 0,
    friendlyImportantOffY = 0,
    friendlyImportantSize = 35,
    friendlyImportantGlow = true,
    friendlyImportantReverse = true,
    friendlyImportantMaxIcons = 5,
}

local DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =====================================================================
-- SECTION 3: Module logic
-- =====================================================================

local MCC = InfinityTools.RevCC
if not MCC then return end

local UnitIsEnemy     = _G.UnitIsEnemy
local UnitIsUnit      = _G.UnitIsUnit
local C_NamePlate     = _G.C_NamePlate
local C_Timer         = _G.C_Timer
local IsInInstance    = _G.IsInInstance
local GetTime         = _G.GetTime
local mathMin         = math.min

-- Keys used to store containers on the nameplate frame
local nameplateCcKey        = "InfinityTools_NM_CcContainer"
local nameplateImportantKey = "InfinityTools_NM_ImportantContainer"

-- Tracks active nameplate data
---@type table<string, table>
local nameplateAnchors = {}
---@type table<string, table>  -- Watcher instances keyed by unitToken
local watchers = {}

-- Reusable scratch table for SetSlot to avoid per-frame allocations
local layerScratch = {}

local paused = false

-- Category colors for combined mode
local defensiveColor = { r = 0.0, g = 0.8, b = 0.0 }
local importantColor = { r = 1.0, g = 0.2, b = 0.2 }

local function IsEnemy(unitToken)
    return UnitIsEnemy("player", unitToken)
end

local function GrowToAnchor(grow)
    if grow == "LEFT" then
        return "RIGHT", "LEFT"
    elseif grow == "RIGHT" then
        return "LEFT", "RIGHT"
    elseif grow == "DOWN" then
        return "TOP", "BOTTOM"
    else
        return "CENTER", "CENTER"
    end
end

local function HideAndReset(container)
    if not container then return end
    container:ResetAllSlots()
    container.Frame:Hide()
end

local function GetNameplateAnchorFrame(nameplate)
    if nameplate.TPFrame then
        if nameplate.TPFrame.GetAnchor then
            local anchor = nameplate.TPFrame:GetAnchor()
            if anchor and anchor.GetFrameLevel then
                return anchor
            end
        end
        return nameplate.TPFrame
    end
    return nameplate
end

local function SetupContainerFrame(container, nameplate, anchorPoint, relativeToPoint, offsetX, offsetY)
    local anchorFrame = GetNameplateAnchorFrame(nameplate)
    local frame = container.Frame
    frame:ClearAllPoints()
    frame:SetPoint(anchorPoint, anchorFrame, relativeToPoint, offsetX, offsetY)
    frame:SetFrameLevel(anchorFrame:GetFrameLevel() + 10)
    frame:EnableMouse(false)
    frame:SetIgnoreParentScale(not DB.scaleWithNameplate)
    frame:Show()
end

-- Returns options table for a given unit token (enemy vs friendly)
local function GetUnitOptions(unitToken)
    if IsEnemy(unitToken) then
        return {
            CC = {
                Enabled   = DB.enemyCCEnabled,
                Grow      = DB.enemyCCGrow,
                OffX      = DB.enemyCCOffX,
                OffY      = DB.enemyCCOffY,
                Size      = DB.enemyCCSize,
                Glow      = DB.enemyCCGlow,
                Reverse   = DB.enemyCCReverse,
                MaxIcons  = DB.enemyCCMaxIcons,
            },
            Important = {
                Enabled   = DB.enemyImportantEnabled,
                Grow      = DB.enemyImportantGrow,
                OffX      = DB.enemyImportantOffX,
                OffY      = DB.enemyImportantOffY,
                Size      = DB.enemyImportantSize,
                Glow      = DB.enemyImportantGlow,
                Reverse   = DB.enemyImportantReverse,
                MaxIcons  = DB.enemyImportantMaxIcons,
            },
            CombinedEnabled = DB.enemyCombinedEnabled,
        }
    else
        return {
            CC = {
                Enabled   = DB.friendlyCCEnabled,
                Grow      = DB.friendlyCCGrow,
                OffX      = DB.friendlyCCOffX,
                OffY      = DB.friendlyCCOffY,
                Size      = DB.friendlyCCSize,
                Glow      = DB.friendlyCCGlow,
                Reverse   = DB.friendlyCCReverse,
                MaxIcons  = DB.friendlyCCMaxIcons,
            },
            Important = {
                Enabled   = DB.friendlyImportantEnabled,
                Grow      = DB.friendlyImportantGrow,
                OffX      = DB.friendlyImportantOffX,
                OffY      = DB.friendlyImportantOffY,
                Size      = DB.friendlyImportantSize,
                Glow      = DB.friendlyImportantGlow,
                Reverse   = DB.friendlyImportantReverse,
                MaxIcons  = DB.friendlyImportantMaxIcons,
            },
            CombinedEnabled = false,
        }
    end
end

local function AnyEnabled()
    return DB.enemyCCEnabled
        or DB.enemyImportantEnabled
        or DB.enemyCombinedEnabled
        or DB.friendlyCCEnabled
        or DB.friendlyImportantEnabled
end

-- Apply CC data to a nameplate CC container
local function ApplyCcToNameplate(data, watcher, unitOptions)
    local container = data.CcContainer
    if not container then return end

    local ccOpts = unitOptions.CC
    if not ccOpts or not ccOpts.Enabled then return end

    local ccData = watcher:GetCcState()
    local ccDataCount = #ccData

    if ccDataCount == 0 then
        container:ResetAllSlots()
        return
    end

    local iconsGlow    = ccOpts.Glow
    local iconsReverse = ccOpts.Reverse
    local limit        = mathMin(ccDataCount, container.Count)

    for i = 1, limit do
        local entry = ccData[i]
        layerScratch.Texture        = entry.SpellIcon
        layerScratch.DurationObject = entry.DurationObject
        layerScratch.Alpha          = entry.IsCC
        layerScratch.Glow           = iconsGlow
        layerScratch.ReverseCooldown= iconsReverse
        layerScratch.FontScale      = nil
        layerScratch.Color          = entry.DispelColor or nil
        container:SetSlot(i, layerScratch)
    end

    for i = limit + 1, container.Count do
        container:SetSlotUnused(i)
    end
end

-- Apply important+defensive data to nameplate important container
local function ApplyImportantSpellsToNameplate(data, watcher, unitOptions)
    local container = data.ImportantContainer
    if not container then return end

    local opts = unitOptions.Important
    if not opts or not opts.Enabled then return end

    local iconsGlow    = opts.Glow
    local iconsReverse = opts.Reverse
    local defensivesData = watcher:GetDefensiveState()
    local importantData  = watcher:GetImportantState()

    local importantSlots, defensiveSlots, _ =
        MCC.SlotDistribution.Calculate(container.Count, #importantData, #defensivesData, 0)

    local slot = 0

    if importantSlots > 0 then
        for i = 1, mathMin(importantSlots, #importantData) do
            if slot >= container.Count then break end
            slot = slot + 1
            local entry = importantData[i]
            layerScratch.Texture        = entry.SpellIcon
            layerScratch.DurationObject = entry.DurationObject
            layerScratch.Alpha          = entry.IsImportant
            layerScratch.Glow           = iconsGlow
            layerScratch.ReverseCooldown= iconsReverse
            layerScratch.FontScale      = nil
            layerScratch.Color          = importantColor
            container:SetSlot(slot, layerScratch)
        end
    end

    if defensiveSlots > 0 then
        for i = 1, mathMin(defensiveSlots, #defensivesData) do
            if slot >= container.Count then break end
            slot = slot + 1
            local entry = defensivesData[i]
            layerScratch.Texture        = entry.SpellIcon
            layerScratch.DurationObject = entry.DurationObject
            layerScratch.Alpha          = entry.IsDefensive
            layerScratch.Glow           = iconsGlow
            layerScratch.ReverseCooldown= iconsReverse
            layerScratch.FontScale      = nil
            layerScratch.Color          = defensiveColor
            container:SetSlot(slot, layerScratch)
        end
    end

    for i = slot + 1, container.Count do
        container:SetSlotUnused(i)
    end
end

local function OnAuraDataChanged(unitToken)
    if paused or not unitToken then return end

    local data = nameplateAnchors[unitToken]
    if not data then return end

    local watcher = watchers[unitToken]
    if not watcher then return end

    local unitOptions = GetUnitOptions(unitToken)

    if unitOptions.CombinedEnabled then
        -- Combined mode: apply all aura types to single container
        local container = data.CcContainer or data.ImportantContainer
        if not container then return end

        local ccData         = watcher:GetCcState()
        local defensivesData = watcher:GetDefensiveState()
        local importantData  = watcher:GetImportantState()

        local ccOpts  = unitOptions.CC
        local impOpts = unitOptions.Important
        local iconsGlow    = (ccOpts and ccOpts.Glow) or false
        local iconsReverse = (ccOpts and ccOpts.Reverse) or true

        local ccSlots, defensiveSlots, importantSlots =
            MCC.SlotDistribution.Calculate(container.Count, #ccData, #defensivesData, #importantData)

        local s = 0
        for i = 1, mathMin(ccSlots, #ccData) do
            if s >= container.Count then break end
            s = s + 1
            local entry = ccData[i]
            layerScratch.Texture        = entry.SpellIcon
            layerScratch.DurationObject = entry.DurationObject
            layerScratch.Alpha          = entry.IsCC
            layerScratch.Glow           = iconsGlow
            layerScratch.ReverseCooldown= iconsReverse
            layerScratch.FontScale      = nil
            layerScratch.Color          = entry.DispelColor or nil
            container:SetSlot(s, layerScratch)
        end
        for i = 1, mathMin(defensiveSlots, #defensivesData) do
            if s >= container.Count then break end
            s = s + 1
            local entry = defensivesData[i]
            layerScratch.Texture        = entry.SpellIcon
            layerScratch.DurationObject = entry.DurationObject
            layerScratch.Alpha          = entry.IsDefensive
            layerScratch.Glow           = iconsGlow
            layerScratch.ReverseCooldown= iconsReverse
            layerScratch.FontScale      = nil
            layerScratch.Color          = defensiveColor
            container:SetSlot(s, layerScratch)
        end
        for i = 1, mathMin(importantSlots, #importantData) do
            if s >= container.Count then break end
            s = s + 1
            local entry = importantData[i]
            layerScratch.Texture        = entry.SpellIcon
            layerScratch.DurationObject = entry.DurationObject
            layerScratch.Alpha          = entry.IsImportant
            layerScratch.Glow           = iconsGlow
            layerScratch.ReverseCooldown= iconsReverse
            layerScratch.FontScale      = nil
            layerScratch.Color          = importantColor
            container:SetSlot(s, layerScratch)
        end
        for i = s + 1, container.Count do
            container:SetSlotUnused(i)
        end
    else
        ApplyCcToNameplate(data, watcher, unitOptions)
        ApplyImportantSpellsToNameplate(data, watcher, unitOptions)
    end
end

local function EnsureContainersForNameplate(nameplate, unitToken)
    local unitOptions = GetUnitOptions(unitToken)
    local ccContainer = nil
    local importantContainer = nil

    if unitOptions.CombinedEnabled then
        -- Single container for combined mode; reuse CC slot
        local ccOpts = unitOptions.CC
        local size      = (ccOpts and ccOpts.Size) or 35
        local maxIcons  = (ccOpts and ccOpts.MaxIcons) or 5
        local grow      = (ccOpts and ccOpts.Grow) or "RIGHT"
        local offX      = (ccOpts and ccOpts.OffX) or 0
        local offY      = (ccOpts and ccOpts.OffY) or 0
        local anchorPoint, relativeToPoint = GrowToAnchor(grow)

        ccContainer = nameplate[nameplateCcKey]
        if not ccContainer then
            ccContainer = MCC.IconSlotContainer:New(nameplate, maxIcons, size, 2, "Nameplates", nil, "Nameplates")
            nameplate[nameplateCcKey] = ccContainer
        else
            ccContainer:SetIconSize(size)
            ccContainer:SetCount(maxIcons)
        end
        SetupContainerFrame(ccContainer, nameplate, anchorPoint, relativeToPoint, offX, offY)
        HideAndReset(nameplate[nameplateImportantKey])
        return ccContainer, nil
    end

    -- Separate mode
    local ccOpts = unitOptions.CC
    if ccOpts and ccOpts.Enabled then
        local size     = ccOpts.Size or 35
        local maxIcons = ccOpts.MaxIcons or 5
        local offsetX  = ccOpts.OffX or 0
        local offsetY  = ccOpts.OffY or 0
        local anchorPoint, relativeToPoint = GrowToAnchor(ccOpts.Grow)

        ccContainer = nameplate[nameplateCcKey]
        if not ccContainer then
            ccContainer = MCC.IconSlotContainer:New(nameplate, maxIcons, size, 2, "Nameplates", nil, "Nameplates")
            nameplate[nameplateCcKey] = ccContainer
        else
            ccContainer:SetIconSize(size)
            ccContainer:SetCount(maxIcons)
        end
        SetupContainerFrame(ccContainer, nameplate, anchorPoint, relativeToPoint, offsetX, offsetY)
    else
        HideAndReset(nameplate[nameplateCcKey])
    end

    local impOpts = unitOptions.Important
    if impOpts and impOpts.Enabled then
        local size     = impOpts.Size or 35
        local maxIcons = impOpts.MaxIcons or 5
        local offsetX  = impOpts.OffX or 0
        local offsetY  = impOpts.OffY or 0
        local anchorPoint, relativeToPoint = GrowToAnchor(impOpts.Grow)

        importantContainer = nameplate[nameplateImportantKey]
        if not importantContainer then
            importantContainer = MCC.IconSlotContainer:New(nameplate, maxIcons, size, 2, "Nameplates", nil, "Nameplates")
            nameplate[nameplateImportantKey] = importantContainer
        else
            importantContainer:SetIconSize(size)
            importantContainer:SetCount(maxIcons)
        end
        SetupContainerFrame(importantContainer, nameplate, anchorPoint, relativeToPoint, offsetX, offsetY)
    else
        HideAndReset(nameplate[nameplateImportantKey])
    end

    return ccContainer, importantContainer
end

local function OnNamePlateRemoved(unitToken)
    local data = nameplateAnchors[unitToken]
    if not data then return end

    HideAndReset(data.CcContainer)
    HideAndReset(data.ImportantContainer)

    if watchers[unitToken] then
        watchers[unitToken]:Dispose()
        watchers[unitToken] = nil
    end

    nameplateAnchors[unitToken] = nil
end

local function OnNamePlateAdded(unitToken)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if not nameplate then return end

    if not DB.enabled then return end

    local ccContainer, importantContainer = EnsureContainersForNameplate(nameplate, unitToken)

    if not ccContainer and not importantContainer then return end

    nameplateAnchors[unitToken] = {
        Nameplate          = nameplate,
        CcContainer        = ccContainer,
        ImportantContainer = importantContainer,
        UnitToken          = unitToken,
    }

    watchers[unitToken] = MCC.UnitAuraWatcher:New(unitToken, nil, nil,
        Enum.UnitAuraSortRule.Unsorted, Enum.UnitAuraSortDirection.Reverse)
    watchers[unitToken]:RegisterCallback(function()
        OnAuraDataChanged(unitToken)
    end)
end

local function ClearNameplate(unitToken)
    local data = nameplateAnchors[unitToken]
    if not data then return end
    if data.CcContainer        then data.CcContainer:ResetAllSlots() end
    if data.ImportantContainer then data.ImportantContainer:ResetAllSlots() end
end

local function DisableWatchers()
    for _, watcher in pairs(watchers) do
        if watcher then watcher:Disable() end
    end
    for unitToken, _ in pairs(nameplateAnchors) do
        ClearNameplate(unitToken)
    end
end

local function EnableWatchers()
    for _, watcher in pairs(watchers) do
        if watcher then watcher:Enable() end
    end
end

local function RebuildContainers()
    if not DB.enabled then return end

    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        local unitToken = nameplate.unitToken
        if unitToken then
            OnNamePlateAdded(unitToken)
        end
    end
end

local function RefreshAnchorsAndSizes()
    local ignoreParentScale = not DB.scaleWithNameplate
    for _, data in pairs(nameplateAnchors) do
        if data.Nameplate and data.UnitToken then
            local unitOptions = GetUnitOptions(data.UnitToken)
            local anchorFrame = GetNameplateAnchorFrame(data.Nameplate)

            local ccContainer = data.CcContainer
            if ccContainer then
                local ccOpts = unitOptions.CC
                if ccOpts then
                    ccContainer.Frame:ClearAllPoints()
                    if ccOpts.Enabled or unitOptions.CombinedEnabled then
                        local ap, rp = GrowToAnchor(ccOpts.Grow)
                        ccContainer.Frame:SetPoint(ap, anchorFrame, rp, ccOpts.OffX, ccOpts.OffY)
                        ccContainer:SetGrowDown(ccOpts.Grow == "DOWN")
                        ccContainer:SetIconSize(ccOpts.Size)
                        ccContainer:SetCount(ccOpts.MaxIcons)
                        ccContainer.Frame:SetFrameLevel(anchorFrame:GetFrameLevel() + 10)
                    end
                    ccContainer.Frame:SetIgnoreParentScale(ignoreParentScale)
                end
            end

            local importantContainer = data.ImportantContainer
            if importantContainer then
                local impOpts = unitOptions.Important
                if impOpts then
                    importantContainer.Frame:ClearAllPoints()
                    if impOpts.Enabled then
                        local ap, rp = GrowToAnchor(impOpts.Grow)
                        importantContainer.Frame:SetPoint(ap, anchorFrame, rp, impOpts.OffX, impOpts.OffY)
                        importantContainer:SetGrowDown(impOpts.Grow == "DOWN")
                        importantContainer:SetIconSize(impOpts.Size)
                        importantContainer:SetCount(impOpts.MaxIcons)
                        importantContainer.Frame:SetFrameLevel(anchorFrame:GetFrameLevel() + 10)
                    end
                    importantContainer.Frame:SetIgnoreParentScale(ignoreParentScale)
                end
            end
        end
    end
end

local function EnableDisable()
    if not DB.enabled or not AnyEnabled() then
        DisableWatchers()
        return
    end

    local inInstance, instanceType = IsInInstance()

    local shouldEnable = false
    if instanceType == "raid"  and DB.enabledRaid    then shouldEnable = true
    elseif instanceType == "party" and DB.enabledDungeon then shouldEnable = true
    elseif instanceType == "arena" and DB.enabledArena   then shouldEnable = true
    elseif instanceType == "pvp"   and DB.enabledBG      then shouldEnable = true
    elseif not inInstance          and DB.enabledWorld    then shouldEnable = true
    end

    if not shouldEnable then
        DisableWatchers()
        return
    end

    EnableWatchers()
    RebuildContainers()
    RefreshAnchorsAndSizes()
end

local function Init()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:SetScript("OnEvent", function(_, event, unitToken)
        if event == "NAME_PLATE_UNIT_ADDED" then
            OnNamePlateAdded(unitToken)
            OnAuraDataChanged(unitToken)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            OnNamePlateRemoved(unitToken)
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            EnableDisable()
        end
    end)

    if DB.enabled and AnyEnabled() then
        RebuildContainers()
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
        EnableDisable()
    elseif key == "scaleWithNameplate" then
        RebuildContainers()
    end
end)
