---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/RingProgressPage.lua
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

InfinityBoss.UI.Panel.RingProgressPage = InfinityBoss.UI.Panel.RingProgressPage or {}
local Page = InfinityBoss.UI.Panel.RingProgressPage

local MODULE_KEY = "InfinityBoss.RingProgress"
local BASE_GRID_COLS = 63
local MIN_GRID_COLS = 63
local MAX_GRID_COLS = 63
local TARGET_CELL_PX = 18
local LAYOUT_CACHE = {}

local DEFAULTS = {
    enabled = false,
    style = "thin1",
    size = 170,
    alpha = 0.95,
    ringColorR = 0.1,
    ringColorG = 0.8,
    ringColorB = 1.0,
    ringColorA = 1.0,
    anchorX = 0,
    anchorY = 0,
}

local LAYOUT = {
    { key = "header", type = "header", x = 1, y = 1, w = 63, h = 2, label = "Ring Progress Settings", labelSize = 25 },
    { key = "desc", type = "description", x = 1, y = 4, w = 63, h = 1, label = "Ring progress displayed at screen center", labelSize = 18 },
    { key = "div_func", type = "divider", x = 1, y = 6, w = 63, h = 1, label = "Features" },
    { key = "enabled", type = "checkbox", x = 1, y = 7, w = 10, h = 2, label = "Enable" },
    { key = "style", type = "dropdown", x = 2, y = 11, w = 14, h = 2, label = "Ring Style", items = {
        { "Thin Ring 1", "thin1" },
        { "Thin Ring 2", "thin2" },
        { "Standard Ring", "classic" },
    }, labelPos = "top" },
    { key = "size", type = "slider", x = 2, y = 15, w = 14, h = 2, label = "Ring Size", min = 80, max = 360, step = 2 },
    { key = "ringColor", type = "color", x = 17, y = 11, w = 14, h = 2, label = "Color" },
    { key = "alpha", type = "slider", x = 33, y = 11, w = 14, h = 2, label = "Opacity", min = 0.1, max = 1, step = 0.05 },
    { key = "anchorX", type = "slider", x = 17, y = 15, w = 14, h = 2, label = "Horizontal (X)", min = -1000, max = 1000, step = 5 },
    { key = "anchorY", type = "slider", x = 33, y = 15, w = 14, h = 2, label = "Vertical (Y)", min = -600, max = 600, step = 5 },
    { key = "btn_test", type = "button", x = 2, y = 18, w = 14, h = 2, label = "Test Ring (3 sec)" },
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

local function EnsureInfinityBossDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    InfinityBossDB.timer.ringProgress = InfinityBossDB.timer.ringProgress or {}
    local db = InfinityBossDB.timer.ringProgress
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then
            db[k] = v
        end
    end
    return db
end

InfinityTools:RegisterModuleLayout(MODULE_KEY, LAYOUT)

InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY .. "_cfg", function(info)
    if not info then return end
    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
    local exdb = EnsureInfinityBossDB()
    if gridDB and exdb then
        for k, v in pairs(gridDB) do
            exdb[k] = v
        end
    end
    if InfinityBoss.UI.RingProgress and InfinityBoss.UI.RingProgress.RefreshVisuals then
        InfinityBoss.UI.RingProgress:RefreshVisuals()
    end
end)

InfinityTools:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY .. "_btn", function(info)
    if not info then return end
    if info.key == "btn_reset_pos" then
        local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
        if gridDB then
            gridDB.anchorX = 0
            gridDB.anchorY = 0
        end
        local exdb = EnsureInfinityBossDB()
        exdb.anchorX = 0
        exdb.anchorY = 0
        if InfinityBoss.UI.RingProgress and InfinityBoss.UI.RingProgress.RefreshVisuals then
            InfinityBoss.UI.RingProgress:RefreshVisuals()
        end
    elseif info.key == "btn_preview" then
        if InfinityTools.ToggleGlobalEditMode then
            InfinityTools:ToggleGlobalEditMode()
        end
    elseif info.key == "btn_test" then
        if InfinityBoss.UI.RingProgress and InfinityBoss.UI.RingProgress.Preview then
            InfinityBoss.UI.RingProgress:Preview(3)
        end
    end
end)

function Page:Render(contentFrame)
    local Grid = _G.InfinityGrid
    if not Grid then
        return
    end

    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
    local exdb = EnsureInfinityBossDB()
    if exdb and gridDB then
        for k, v in pairs(exdb) do
            gridDB[k] = v
        end
    end

    if not Page._scrollFrame then
        local sf = CreateFrame("ScrollFrame", "InfinityBoss_RingProgressSettingsScroll", contentFrame, "ScrollFrameTemplate")
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

