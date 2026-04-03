-- =============================================================
-- [[ Target Range Monitor ]]
-- { Key = "RevClass.RangeCheck", Name = "Range Monitor", Desc = "Displays target distance range in real time.", Category = 4 },
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevClass.RangeCheck"

-- =============================================================
-- Part 1: Grid layout definition (must run first).
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        -- Title
        { key = "header", type = "header", x = 2, y = 1, w = 50, h = 3, label = L["Range Monitor"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 50, h = 2, label = L["Displays the target distance range in real time and changes color based on the minimum distance."] },

        -- Basic settings
        { key = "sub_general", type = "subheader", x = 2, y = 6, w = 50, h = 2, label = L["General Settings"], labelSize = 20 },
        { key = "div_general", type = "divider", x = 2, y = 8, w = 50, h = 1 },
        { key = "enabled", type = "checkbox", x = 2, y = 10, w = 12, h = 2, label = L["Enable"] },  -- TODO: missing key: L["Enable"]
        { key = "locked", type = "checkbox", x = 16, y = 10, w = 12, h = 2, label = L["Lock Position"] },
        { key = "showText", type = "checkbox", x = 30, y = 10, w = 14, h = 2, label = L["Show Distance Text"] },

        -- Appearance settings
        { key = "sub_appearance", type = "subheader", x = 2, y = 13, w = 50, h = 2, label = L["Appearance"], labelSize = 20 },
        { key = "div_appearance", type = "divider", x = 2, y = 15, w = 50, h = 1 },
        { key = "fontSize", type = "slider", x = 2, y = 17, w = 16, h = 2, label = L["Font Size"], min = 10, max = 48, step = 1, labelPos = "top" },
        { key = "frameScale", type = "slider", x = 20, y = 17, w = 16, h = 2, label = L["Scale"], min = 0.5, max = 3.0, step = 0.1, labelPos = "top" },
        { key = "hideThreshold", type = "slider", x = 38, y = 17, w = 16, h = 2, label = L["Hide Distance Threshold"], min = 5, max = 100, step = 5, labelPos = "top" },
        { key = "desc_threshold", type = "description", x = 38, y = 20, w = 16, h = 2, label = L["Hide when the target is beyond this range (100 = never hide)"] },

        -- Font outline and shadow
        {
            key = "fontOutline",
            type = "dropdown",
            x = 2,
            y = 20,
            w = 16,
            h = 2,
            label = L["Text Outline"],
            labelPos = "top",
            items = "None,Outline,Thick Outline,Monochrome"
        },
        { key = "fontShadow", type = "checkbox", x = 20, y = 20, w = 14, h = 2, label = L["Enable Shadow"] },
        { key = "fontShadowX", type = "slider", x = 2, y = 23, w = 16, h = 2, label = L["Shadow X"], min = -10, max = 10, step = 1, labelPos = "top" },
        { key = "fontShadowY", type = "slider", x = 20, y = 23, w = 16, h = 2, label = L["Shadow Y"], min = -10, max = 10, step = 1, labelPos = "top" },

        -- Custom format
        { key = "rangeFormat", type = "input", x = 2, y = 26, w = 16, h = 2, label = L["Range Format"], labelPos = "top", placeholder = "%d - %d" },
        { key = "minOnlyFormat", type = "input", x = 20, y = 26, w = 16, h = 2, label = L["Min-Only Format"], labelPos = "top", placeholder = "%d+" },
        { key = "desc_format", type = "description", x = 2, y = 29, w = 34, h = 2, label = L["Range format requires two %d values (min/max, e.g. %d - %d). Min-only format requires one %d+. Leave blank to use the default."] },

        -- Position settings
        { key = "sub_position", type = "subheader", x = 2, y = 32, w = 50, h = 2, label = L["Position"], labelSize = 20 },
        { key = "div_position", type = "divider", x = 2, y = 34, w = 50, h = 1 },
        { key = "xOffset", type = "slider", x = 2, y = 36, w = 16, h = 2, label = L["X Offset"], min = -1000, max = 1000, step = 1, labelPos = "top" },
        { key = "yOffset", type = "slider", x = 20, y = 36, w = 16, h = 2, label = L["Y Offset"], min = -1000, max = 1000, step = 1, labelPos = "top" },
        { key = "btn_resetPos", type = "button", x = 38, y = 36, w = 14, h = 3, label = L["Reset Position"] },

        -- Color settings
        { key = "sub_colors", type = "subheader", x = 2, y = 41, w = 50, h = 2, label = L["Distance Colors"], labelSize = 20 },
        { key = "div_colors", type = "divider", x = 2, y = 43, w = 50, h = 1 },
        { key = "desc_colors", type = "description", x = 2, y = 45, w = 50, h = 2, label = L["Automatically switches text color based on target distance. Each color maps to a distance bracket."] },

        { key = "crColor", type = "color", x = 2, y = 48, w = 7, h = 2, label = L["< 5 yd"] },
        { key = "srColor", type = "color", x = 9, y = 48, w = 7, h = 2, label = L[">= 5 yd"] },
        { key = "s10Color", type = "color", x = 16, y = 48, w = 7, h = 2, label = L[">= 10 yd"] },
        { key = "s15Color", type = "color", x = 23, y = 48, w = 7, h = 2, label = L[">= 15 yd"] },
        { key = "mrColor", type = "color", x = 30, y = 48, w = 7, h = 2, label = L[">= 20 yd"] },
        { key = "lrColor", type = "color", x = 37, y = 48, w = 7, h = 2, label = L[">= 30 yd"] },
        { key = "oorColor", type = "color", x = 44, y = 48, w = 7, h = 2, label = L[">= 40 yd"] },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT() -- Execute registration immediately

-- =============================================================
-- Part 2: load checks and environment filtering
-- =============================================================
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =============================================================
-- Part 3: dependencies and data initialization
-- =============================================================

-- Get LibRangeCheck-3.0 (already loaded in InfinityCore/libs).
local LRC = LibStub("LibRangeCheck-3.0")
if not LRC then
    print(string.format("|cffff0000[%s]|r %s", L["Range Check"], L["LibRangeCheck-3.0 not found. Module cannot function."]))
    return
end

-- Default settings
local INFINITY_DEFAULTS = {
    enabled = false,
    locked = true, -- Locked by default; unlock via edit mode
    showText = true,
    fontSize = 18,
    frameScale = 1.0,
    hideThreshold = 60, -- Hide when distance exceeds this value (100 = never hide)

    -- Position
    point = "CENTER",
    relativePoint = "CENTER",
    xOffset = 0,
    yOffset = -85,

    -- Font outline and shadow
    fontOutline = "Outline",
    fontShadow = true, -- Enable shadow
    fontShadowX = 1, -- Shadow X offset
    fontShadowY = -1, -- Shadow Y offset

    -- Custom format (leave empty to use the default)
    rangeFormat = "",   -- Range format, default "%d - %d"
    minOnlyFormat = "", -- Min-only format, default "%d+"

    -- Color settings (Grid ColorPicker automatically splits values into R/G/B suffixes)
    crColorR = 0.9,
    crColorG = 0.9,
    crColorB = 0.9, -- < 5 yd  White
    srColorR = 0.063,
    srColorG = 1.0,
    srColorB = 0.941, -- >= 5 yd  Cyan #10FFF0
    s10ColorR = 0.063,
    s10ColorG = 1.0,
    s10ColorB = 0.941, -- >= 10 yd  Cyan (same as >5 yd by default)
    s15ColorR = 0.063,
    s15ColorG = 1.0,
    s15ColorB = 0.941, -- >= 15 yd  Cyan (same as >5 yd by default)
    mrColorR = 0.039,
    mrColorG = 1.0,
    mrColorB = 0.0, -- >= 20 yd  Green #0AFF00
    lrColorR = 1.0,
    lrColorG = 1.0,
    lrColorB = 0.0, -- >= 30 yd  Yellow #FFFF00
    oorColorR = 1.0,
    oorColorG = 0.0,
    oorColorB = 0.0, -- >= 40 yd  Red #FF0000
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)

-- =============================================================
-- Part 4: business logic
-- =============================================================

-- Main frame
local rangeFrame = CreateFrame("Frame", "InfinityRangeCheckFrame", UIParent)
rangeFrame:SetSize(120, 40)
rangeFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
rangeFrame:SetMovable(true)
rangeFrame:SetClampedToScreen(true)
rangeFrame:Hide()

-- Range text
local rangeText = rangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rangeText:SetPoint("CENTER")
rangeText:SetText("")
rangeFrame.text = rangeText

-- Edit mode helper layer
local editBG = CreateFrame("Frame", nil, rangeFrame, "BackdropTemplate")
editBG:SetPoint("TOPLEFT", rangeFrame, "TOPLEFT", -8, 8)
editBG:SetPoint("BOTTOMRIGHT", rangeFrame, "BOTTOMRIGHT", 8, -8)
editBG:SetBackdrop({
    bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
    edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
editBG:SetBackdropColor(0, 0.7, 0.2, 0.4)
editBG:SetFrameLevel(rangeFrame:GetFrameLevel())
editBG:Hide()
rangeFrame.editBG = editBG

-- Edit mode label
local editLabel = rangeFrame:CreateFontString(nil, "OVERLAY")
editLabel:SetFont(InfinityTools.MAIN_FONT or select(1, GameFontNormalLarge:GetFont()), 12, "OUTLINE")
editLabel:SetPoint("BOTTOM", rangeFrame, "TOP", 0, 4)
editLabel:SetText(L["Range Check"])
editLabel:SetTextColor(0, 1, 0, 0.8)
editLabel:Hide()
rangeFrame.editLabel = editLabel

-- ===================== Position save/restore =====================

local function SavePosition()
    if not rangeFrame then return end
    local point, _, relativePoint, xOfs, yOfs = rangeFrame:GetPoint()
    if point and relativePoint then
        MODULE_DB.point = point
        MODULE_DB.relativePoint = relativePoint
        MODULE_DB.xOffset = xOfs or 0
        MODULE_DB.yOffset = yOfs or 0
    end
end

local function RestorePosition()
    if not rangeFrame then return end

    rangeFrame:SetScale(MODULE_DB.frameScale or 1.0)
    rangeFrame:ClearAllPoints()
    rangeFrame:SetPoint(
        MODULE_DB.point or "CENTER",
        UIParent,
        MODULE_DB.relativePoint or "CENTER",
        MODULE_DB.xOffset or 0,
        MODULE_DB.yOffset or -85
    )
end

-- ===================== Lock state =====================

local function UpdateLockState()
    if not rangeFrame then return end

    if MODULE_DB.locked then
        rangeFrame:EnableMouse(false)
        if rangeFrame.editBG then rangeFrame.editBG:Hide() end
        if rangeFrame.editLabel then rangeFrame.editLabel:Hide() end
    else
        rangeFrame:EnableMouse(true)
        if rangeFrame.editBG then rangeFrame.editBG:Show() end
        if rangeFrame.editLabel then rangeFrame.editLabel:Show() end
    end
end

-- ===================== Range color logic =====================

--- Get the corresponding color from the minimum distance (R, G, B)
local function GetRangeColor(minRange)
    if not minRange then
        return MODULE_DB.crColorR or 0.9, MODULE_DB.crColorG or 0.9, MODULE_DB.crColorB or 0.9
    end

    if minRange >= 40 then
        return MODULE_DB.oorColorR or 1, MODULE_DB.oorColorG or 0, MODULE_DB.oorColorB or 0
    end

    if minRange >= 30 then
        return MODULE_DB.lrColorR or 1, MODULE_DB.lrColorG or 1, MODULE_DB.lrColorB or 0
    end

    if minRange >= 20 then
        return MODULE_DB.mrColorR or 0.039, MODULE_DB.mrColorG or 1, MODULE_DB.mrColorB or 0
    end

    if minRange >= 15 then
        return MODULE_DB.s15ColorR or 0.063, MODULE_DB.s15ColorG or 1, MODULE_DB.s15ColorB or 0.941
    end

    if minRange >= 10 then
        return MODULE_DB.s10ColorR or 0.063, MODULE_DB.s10ColorG or 1, MODULE_DB.s10ColorB or 0.941
    end

    if minRange >= 5 then
        return MODULE_DB.srColorR or 0.063, MODULE_DB.srColorG or 1, MODULE_DB.srColorB or 0.941
    end

    -- <= 5 yards
    return MODULE_DB.crColorR or 0.9, MODULE_DB.crColorG or 0.9, MODULE_DB.crColorB or 0.9
end

-- ===================== Format range text =====================

local function FormatRangeText(minRange, maxRange)
    if not minRange then
        return ""
    elseif not maxRange then
        local fmt = MODULE_DB.minOnlyFormat
        if not fmt or fmt == "" then fmt = "%d+" end
        return string.format(fmt, minRange)
    else
        local fmt = MODULE_DB.rangeFormat
        if not fmt or fmt == "" then fmt = "%d - %d" end
        return string.format(fmt, minRange, maxRange)
    end
end

-- ===================== Range updates =====================

local function UpdateRange()
    if not MODULE_DB.enabled or not MODULE_DB.showText then
        rangeText:SetText("")
        return
    end

    if not UnitExists("target") then
        rangeText:SetText("")
        return
    end

    local minRange, maxRange = LRC:GetRange("target")

    -- Check whether the value exceeds the hide threshold (100 = do not hide)
    local hideThreshold = MODULE_DB.hideThreshold or 60
    if hideThreshold < 100 and minRange and minRange > hideThreshold then
        rangeText:SetText("")
        return
    end

    local r, g, b = GetRangeColor(minRange)
    rangeText:SetText(FormatRangeText(minRange, maxRange))
    rangeText:SetTextColor(r, g, b)
end

-- ===================== Apply font styling (size/outline/shadow) =====================

-- Dropdown option text -> SetFont outline parameter
local OUTLINE_MAP = {
    ["None"] = "",
    ["Outline"] = "OUTLINE",
    ["Thick Outline"] = "THICKOUTLINE",
    ["Monochrome"] = "MONOCHROME",
}

local function ApplyFontSize()
    local fontPath   = InfinityTools.MAIN_FONT or select(1, GameFontNormalLarge:GetFont())
    local fontSize   = MODULE_DB.fontSize or INFINITY_DEFAULTS.fontSize
    local outlineKey = MODULE_DB.fontOutline or INFINITY_DEFAULTS.fontOutline
    local outline    = OUTLINE_MAP[outlineKey] or "OUTLINE"
    rangeText:SetFont(fontPath, fontSize, outline)

    -- Shadow
    if MODULE_DB.fontShadow then
        rangeText:SetShadowColor(0, 0, 0, 1)
        rangeText:SetShadowOffset(
            MODULE_DB.fontShadowX or INFINITY_DEFAULTS.fontShadowX,
            MODULE_DB.fontShadowY or INFINITY_DEFAULTS.fontShadowY
        )
    else
        rangeText:SetShadowOffset(0, 0)
    end
end

-- ===================== Visibility control =====================

local function UpdateVisibility()
    if not MODULE_DB.enabled then
        rangeFrame:Hide()
        return
    end

    if MODULE_DB.showText then
        rangeFrame:Show()
    else
        rangeFrame:Hide()
    end
end

-- ===================== Full refresh =====================

local function RefreshAll()
    RestorePosition()
    ApplyFontSize()
    UpdateLockState()
    UpdateVisibility()
    UpdateRange()
end

-- ===================== Drag interaction =====================

rangeFrame:SetScript("OnMouseDown", function(self, button)
    if MODULE_DB.locked then return end
    if button == "LeftButton" then
        self.moving = true
        self:StartMoving()
    elseif button == "RightButton" and InfinityTools.GlobalEditMode then
        InfinityTools:OpenConfig(INFINITY_MODULE_KEY)
    end
end)

rangeFrame:SetScript("OnMouseUp", function(self)
    if self.moving then
        self.moving = false
        self:StopMovingOrSizing()
        SavePosition()
    end
end)

-- ===================== OnUpdate range polling =====================

local UPDATE_INTERVAL = 0.3
local timeSinceLastUpdate = 0

rangeFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= UPDATE_INTERVAL then
        UpdateRange()
        timeSinceLastUpdate = 0
    end
end)

-- =============================================================
-- Part 5: events and state subscriptions
-- =============================================================

-- Register edit mode callback
local function RegisterEditMode()
    InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
        MODULE_DB.locked = not enabled
        UpdateLockState()

        -- Force the frame to show in edit mode and place a preview text
        if enabled then
            rangeFrame:Show()
            if not UnitExists("target") then
                rangeText:SetText("15 - 20")
                rangeText:SetTextColor(MODULE_DB.srColorR or 0.063, MODULE_DB.srColorG or 1, MODULE_DB.srColorB or 0.941)
            end
        else
            UpdateVisibility()
        end
    end)
end
RegisterEditMode()

-- Register HUD (right-click to open settings)
InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, rangeFrame)

-- Refresh immediately when the target changes
InfinityTools:RegisterEvent("PLAYER_TARGET_CHANGED", INFINITY_MODULE_KEY, function()
    UpdateRange()
end)

-- Watch database changes (user changes settings in the Grid panel)
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    RefreshAll()
end)

-- Watch the reset position button
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    if info.key == "btn_resetPos" then
        MODULE_DB.point = "CENTER"
        MODULE_DB.relativePoint = "CENTER"
        MODULE_DB.xOffset = INFINITY_DEFAULTS.xOffset
        MODULE_DB.yOffset = INFINITY_DEFAULTS.yOffset
        RestorePosition()
        print(string.format("|cff00ff00[%s]|r %s", L["Range Check"], L["Position reset."]))
    end
end)

-- =============================================================
-- Part 6: initialization and module reporting
-- =============================================================

-- Delayed initialization
C_Timer.After(1, function()
    MODULE_DB.locked = true
    RefreshAll()
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    MODULE_DB.locked = true
    RefreshAll()
end)

-- Report module load complete
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

