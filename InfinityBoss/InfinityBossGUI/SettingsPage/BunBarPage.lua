---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/BunBarPage.lua
-- =============================================================

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

InfinityBoss.UI.Panel.BunBarPage = InfinityBoss.UI.Panel.BunBarPage or {}
local Page = InfinityBoss.UI.Panel.BunBarPage

local MODULE_KEY = "InfinityBoss.BunBar"
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

local DEFAULTS = {
    enabled       = false,
    locked        = false,
    anchorX       = -755,
    anchorY       = 120,
    width         = 420,
    iconSize      = 39,
    trackHeight   = 49,
    preAlertSecs  = 5,
    maxTracks     = 1,
    layoutMode    = "Single",
    axis          = "Vertical",
    moveDir       = "Down",
    showIcon      = true,
    showName      = true,
    showTimer     = true,
    hideExternalBossModBars = false,
    font_name = {
        font = "Default",
        size = 14,
        r = 1, g = 1, b = 1, a = 1,
        outline = "OUTLINE",
        shadow = false,
        shadowX = 1, shadowY = -1,
        side = "RIGHT",
        x = 8, y = 0,
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
    axisLineWidth = 1,
    axisLineColorR = 1.0,
    axisLineColorG = 1.0,
    axisLineColorB = 1.0,
    axisLineColorA = 0.20,
    fiveSecLineWidth = 2,
    fiveSecLineColorR = 1.0,
    fiveSecLineColorG = 0.90,
    fiveSecLineColorB = 0.35,
    fiveSecLineColorA = 0.85,
    showBg        = true,
    showBorder    = false,
    bgSettings = {
        texture       = "Solid",
        bgColorR      = 0.05098039656877518,
        bgColorG      = 0.05882353335618973,
        bgColorB      = 0.0784313753247261,
        bgColorA      = 0.6949490904808044,
        borderTexture = "Blizzard Dialog",
        borderColorR  = 0.9372549653053284,
        borderColorG  = 1.0,
        borderColorB  = 0.9137255549430847,
        borderColorA  = 0.3499999940395355,
        edgeSize      = 1,
        inset         = 0,
    },
    colors = {
        [1] = { r=1.0, g=0.2, b=0.2, a=1.0 },
        [2] = { r=1.0, g=0.8, b=0.0, a=1.0 },
        [3] = { r=0.6, g=0.6, b=0.6, a=0.6 },
    },
}

local LAYOUT = {
    { key = "header", type = "header", x = 1, y = 1, w = 63, h = 2, label = "Bun Bar Settings", labelSize = 25 },
    { key = "showIcon", type = "checkbox", x = 1, y = 11, w = 10, h = 2, label = "Show Icon" },
    { key = "showName", type = "checkbox", x = 16, y = 7, w = 10, h = 2, label = "Show Name" },
    { key = "showTimer", type = "checkbox", x = 32, y = 7, w = 10, h = 2, label = "Show Time" },
    { key = "hideExternalBossModBars", type = "checkbox", x = 48, y = 7, w = 15, h = 2, label = "Hide BigWigs/DBM Bars" },
    { key = "width", type = "slider", x = 1, y = 15, w = 14, h = 2, label = "Track Width", min = 200, max = 1400 },
    { key = "iconSize", type = "slider", x = 16, y = 11, w = 14, h = 2, label = "Icon Size", min = 12, max = 64 },
    { key = "trackHeight", type = "slider", x = 16, y = 15, w = 14, h = 2, label = "Track Height", min = 16, max = 90 },
    { key = "moveDir", type = "dropdown", x = 32, y = 11, w = 14, h = 2, label = "Move Direction", items = "Up,Down" },
    { key = "showBg", type = "checkbox", x = 1, y = 22, w = 10, h = 2, label = "Show Background" },
    { key = "showBorder", type = "checkbox", x = 1, y = 26, w = 10, h = 2, label = "Show Border" },
    { key = "font_name", type = "fontgroup", x = 1, y = 33, w = 63, h = 14, label = "Spell Name", labelSize = 20 },
    { key = "font_time", type = "fontgroup", x = 1, y = 53, w = 63, h = 14, label = "Pattern Countdown", labelSize = 20 },
    { key = "axisLineWidth", type = "slider", x = 1, y = 69, w = 14, h = 2, label = "BG Line Width", min = 1, max = 8 },
    { key = "axisLineColor", type = "color", x = 16, y = 69, w = 14, h = 2, label = "BG Line Color" },
    { key = "fiveSecLineWidth", type = "slider", x = 31, y = 69, w = 14, h = 2, label = "5-Sec Line Width", min = 1, max = 8 },
    { key = "fiveSecLineColor", type = "color", x = 46, y = 69, w = 14, h = 2, label = "5-Sec Line Color" },
    { key = "fontNameGroup", type = "TableGroup", x = 1, y = 1, w = 1, h = 1, label = "--[[ Function ]]", parentKey = "font_name", children = {
        { key = "side", type = "dropdown", x = 1, y = 49, w = 14, h = 2, label = "Name Position", items = {
            { "Left of Icon", "LEFT" },
            { "Right of Icon", "RIGHT" },
        } },
    } },
    { key = "bgGroup", type = "TableGroup", x = 1, y = 1, w = 1, h = 1, label = "--[[ Function ]]", parentKey = "bgSettings", children = {
        { key = "texture", type = "lsm_background", x = 16, y = 22, w = 14, h = 2, label = "BG Texture", labelPos = "left" },
        { key = "bgColor", type = "color", x = 32, y = 22, w = 14, h = 2, label = "BG Color" },
        { key = "borderTexture", type = "lsm_border", x = 16, y = 26, w = 14, h = 2, label = "Border Texture", labelPos = "left" },
        { key = "borderColor", type = "color", x = 32, y = 26, w = 14, h = 2, label = "Border Color" },
        { key = "edgeSize", type = "slider", x = 16, y = 30, w = 14, h = 2, label = "Border Width", min = 1, max = 32 },
        { key = "inset", type = "slider", x = 32, y = 30, w = 14, h = 2, label = "Border Inset", min = 0, max = 16 },
    } },
    { key = "anchorX", type = "slider", x = 48, y = 15, w = 14, h = 2, label = "Horizontal (X)", min = -1500, max = 1500 },
    { key = "anchorY", type = "slider", x = 32, y = 15, w = 14, h = 2, label = "Vertical (Y)", min = -1000, max = 1000 },
    { key = "header_7996", type = "header", x = 1, y = 19, w = 63, h = 2, label = "Background Settings", labelSize = 20 },
    { key = "header_5885", type = "header", x = 1, y = 5, w = 63, h = 1, label = "General Settings", labelSize = 20 },
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

InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY .. "_cfg", function(info)
    if not info then return end

    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
    local exdb = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.bunBar
    if gridDB and exdb then
        ApplyDefaults(gridDB, DEFAULTS)
        ApplyDefaults(exdb, DEFAULTS)
        for k, v in pairs(gridDB) do
            exdb[k] = v
        end
    end
    if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.RefreshVisuals then
        InfinityBoss.UI.BunBar:RefreshVisuals()
    end
    if InfinityBoss.ApplyExternalBossModBarVisibility and InfinityTools.State then
        local encID = InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler and InfinityBoss.Timeline.Scheduler._encounterID
        InfinityBoss.ApplyExternalBossModBarVisibility(encID, InfinityTools.State.IsBossEncounter == true)
    end
end)

InfinityTools:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY .. "_btn", function(info)
    if not info then return end

    if info.key == "btn_reset_pos" then
        local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
        if gridDB then
            gridDB.anchorX = -755
            gridDB.anchorY = 120
        end
        local exdb = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.bunBar
        if exdb then
            exdb.anchorX = -755
            exdb.anchorY = 120
        end
        if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.RefreshVisuals then
            InfinityBoss.UI.BunBar:RefreshVisuals()
        end
    elseif info.key == "btn_preview" then
        if InfinityTools.ToggleGlobalEditMode then
            InfinityTools:ToggleGlobalEditMode()
        end
    elseif info.key == "btn_create_test" then
        if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.CreateTestBars then
            InfinityBoss.UI.BunBar:CreateTestBars(5)
        end
    elseif info.key == "btn_clear_test" then
        if InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.ClearTestBars then
            InfinityBoss.UI.BunBar:ClearTestBars()
        end
    end
end)

function Page:Render(contentFrame)
    local Grid = _G.InfinityGrid
    if not Grid then
        return
    end

    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
    local exdb = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.bunBar
    if gridDB then
        ApplyDefaults(gridDB, DEFAULTS)
    end
    if exdb and gridDB then
        ApplyDefaults(exdb, DEFAULTS)
        for k, v in pairs(exdb) do
            gridDB[k] = v
        end
        ApplyDefaults(gridDB, DEFAULTS)
    end

    if not Page._scrollFrame then
        local sf = CreateFrame("ScrollFrame", "InfinityBoss_BunBarSettingsScroll",
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
        Grid:Render(sc, ScaleLayout(LAYOUT, cols), gridDB, MODULE_KEY)
    end)
end
