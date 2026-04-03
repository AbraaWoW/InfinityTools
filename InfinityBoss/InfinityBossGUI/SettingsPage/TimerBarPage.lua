---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/TimerBarPage.lua
--
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

InfinityBoss.UI.Panel.TimerBarPage = InfinityBoss.UI.Panel.TimerBarPage or {}
local Page = InfinityBoss.UI.Panel.TimerBarPage

local MODULE_KEY = "InfinityBoss.TimerBar"
local BASE_GRID_COLS = 63
local MIN_GRID_COLS = 63
local MAX_GRID_COLS = 63
local TARGET_CELL_PX = 18
local LAYOUT_CACHE = {}

local function ApplyDefaults(dst, defaults)
    if type(dst) ~= "table" or type(defaults) ~= "table" then
        return
    end
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

-- =============================================================
-- =============================================================
local DEFAULTS = {
    enabled      = false,
    spacing      = 4,
    maxBars      = 10,
    growDir      = "DOWN",
    fillMode     = "RTL_FADE",
    showName     = true,
    showTimer    = true,
    anchorX      = -535,
    anchorY      = -5,
    font_name = {
        font = "Default",
        size = 14,
        r = 1, g = 1, b = 1, a = 1,
        outline = "OUTLINE",
        shadow = false,
        shadowX = 1, shadowY = -1,
        x = 4, y = 0,
    },
    font_time = {
        font = "Default",
        size = 14,
        r = 1, g = 1, b = 1, a = 1,
        outline = "OUTLINE",
        shadow = false,
        shadowX = 1, shadowY = -1,
        x = 0, y = 0,
    },
    timerBarGroup = {
        width = 200,
        height = 25,
        texture = "Melli",
        barColorR = 1.0,
        barColorG = 0.7,
        barColorB = 0.0,
        barColorA = 1.0,
        barBgColorR = 0.0,
        barBgColorG = 0.0,
        barBgColorB = 0.0,
        barBgColorA = 0.5,
        showBorder = true,
        borderTexture = "Blizzard Tooltip",
        borderColorR = 1.0,
        borderColorG = 1.0,
        borderColorB = 1.0,
        borderColorA = 1.0,
        borderSize = 10,
        borderPadding = 2,
        showIcon = true,
        iconSide = "LEFT",
        iconSize = 26,
        iconOffsetX = -2,
        iconOffsetY = 0,
    },
}

-- =============================================================
-- =============================================================
local LAYOUT = {
    { key = "header", type = "header", x = 1, y = 1, w = 63, h = 2, label = "Timer Bar Settings", labelSize = 25 },
    { key = "desc", type = "description", x = 1, y = 4, w = 63, h = 1, label = "All timer bar appearance settings." },
    { key = "showName", type = "checkbox", x = 12, y = 9, w = 10, h = 2, label = "Show Name" },
    { key = "showTimer", type = "checkbox", x = 24, y = 9, w = 10, h = 2, label = "Show Time" },
    { key = "fillMode", type = "dropdown", x = 46, y = 13, w = 14, h = 2, label = "Fill Mode", items = {
        { "Fill Left to Right", "LTR_FILL" },
        { "Fade Left to Right", "LTR_FADE" },
        { "Fill Right to Left", "RTL_FILL" },
        { "Fade Right to Left", "RTL_FADE" },
    } },
    { key = "spacing", type = "slider", x = 1, y = 13, w = 14, h = 2, label = "Spacing", min = 0, max = 20 },
    { key = "maxBars", type = "slider", x = 16, y = 13, w = 14, h = 2, label = "Max Bars", min = 1, max = 20 },
    { key = "growDir", type = "dropdown", x = 31, y = 13, w = 14, h = 2, label = "Grow Direction", items = "DOWN,UP" },
    { key = "timerBarGroup", type = "timerBarGroup", x = 1, y = 20, w = 63, h = 21, label = "Timer Bar Appearance", labelSize = 20 },
    { key = "font_name", type = "fontgroup", x = 1, y = 43, w = 63, h = 14, label = "Spell Name", labelSize = 20 },
    { key = "font_time", type = "fontgroup", x = 1, y = 59, w = 63, h = 14, label = "Time Text", labelSize = 20 },
    { key = "anchorX", type = "slider", x = 1, y = 16, w = 14, h = 2, label = "Horizontal (X)", min = -1000, max = 1000 },
    { key = "anchorY", type = "slider", x = 16, y = 16, w = 14, h = 2, label = "Vertical (Y)", min = -600, max = 600 },
    { key = "btn_reset_pos", type = "button", x = 31, y = 16, w = 14, h = 2, label = "Reset Position" },
    { key = "subheader_8209", type = "subheader", x = 1, y = 7, w = 63, h = 1, label = "General", labelSize = 20 },
    { key = "divider_5953", type = "divider", x = 1, y = 8, w = 63, h = 1, label = "New Component" },
}

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

-- =============================================================
-- =============================================================
InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY .. "_cfg", function(info)
    if not info then return end
    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
    local exdb   = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.timerBar
    if gridDB and exdb then
        ApplyDefaults(gridDB, DEFAULTS)
        ApplyDefaults(exdb, DEFAULTS)
        for k, v in pairs(gridDB) do
            exdb[k] = v
        end
    end
    if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.RefreshVisuals then
        InfinityBoss.UI.TimerBar:RefreshVisuals()
    end
end)

InfinityTools:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY .. "_btn", function(info)
    if not info then return end
    if info.key == "btn_reset_pos" then
        local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
        if gridDB then
            gridDB.anchorX = -535
            gridDB.anchorY = -5
        end
        local exdb = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.timerBar
        if exdb then
            exdb.anchorX = -535
            exdb.anchorY = -5
        end
        if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.RefreshVisuals then
            InfinityBoss.UI.TimerBar:RefreshVisuals()
        end
    elseif info.key == "btn_preview" then
        if InfinityTools.ToggleGlobalEditMode then
            InfinityTools:ToggleGlobalEditMode()
        end
    elseif info.key == "btn_create_test" then
        if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.CreateTestBars then
            InfinityBoss.UI.TimerBar:CreateTestBars(5)
        end
    elseif info.key == "btn_clear_test" then
        if InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.ClearTestBars then
            InfinityBoss.UI.TimerBar:ClearTestBars()
        end
    end
end)

-- =============================================================
-- =============================================================
function Page:Render(contentFrame)
    local Grid = _G.InfinityGrid
    if not Grid then
        return
    end

    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
    local exdb   = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.timerBar
    if exdb and gridDB then
        ApplyDefaults(exdb, DEFAULTS)
        ApplyDefaults(gridDB, DEFAULTS)
        for k, v in pairs(exdb) do
            gridDB[k] = v
        end
    end

    if not Page._scrollFrame then
        local sf = CreateFrame("ScrollFrame", "InfinityBoss_TimerBarSettingsScroll",
                               contentFrame, "ScrollFrameTemplate")
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
    sf:SetPoint("TOPLEFT",     contentFrame, "TOPLEFT",     4,  -4)
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
        Grid:Render(sc, ScaleLayout(LAYOUT, cols), gridDB, MODULE_KEY)
    end)
end

