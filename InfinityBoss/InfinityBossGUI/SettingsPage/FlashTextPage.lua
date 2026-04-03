---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/FlashTextPage.lua
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

InfinityBoss.UI.Panel.FlashTextPage = InfinityBoss.UI.Panel.FlashTextPage or {}
local Page = InfinityBoss.UI.Panel.FlashTextPage

local MODULE_KEY = "InfinityBoss.FlashText"
local BASE_GRID_COLS = 63
local MIN_GRID_COLS = 63
local MAX_GRID_COLS = 63
local TARGET_CELL_PX = 18
local LAYOUT_CACHE = {}

local DEFAULTS = {
    enabled       = false,
    anchorX       = 0,
    anchorY       = 105,
    flashDuration = 2.5,
    font_flash = {
        font    = "Default",
        size    = 46,
        outline = "OUTLINE",
        r = 1.0, g = 1.0, b = 1.0, a = 1.0,
        shadow  = true,
        shadowX = 2,
        shadowY = -2,
        x = 0, y = 0,
    },
}

local LAYOUT = {
    { key = "header", type = "header", x = 1, y = 1, w = 63, h = 2, label = "Flash Text", labelSize = 25 },
    { key = "desc", type = "description", x = 1, y = 4, w = 63, h = 1, label = "Displays spell name at screen center on trigger (fade in ? hold ? fade out).", labelSize = 18 },
    { key = "div_func", type = "divider", x = 1, y = 6, w = 63, h = 1, label = "Features" },
    { key = "enabled", type = "checkbox", x = 1, y = 8, w = 10, h = 2, label = "Enable" },
    { key = "flashDuration", type = "slider", x = 13, y = 8, w = 14, h = 2, label = "Duration (sec)", min = 0.5, max = 6, step = 0.5 },
    { key = "font_flash", type = "fontgroup", x = 1, y = 12, w = 63, h = 17, label = "Flash Text", labelSize = 20 },
    { key = "anchorX", type = "slider", x = 43, y = 8, w = 14, h = 2, label = "Horizontal (X)", min = -1000, max = 1000, step = 5 },
    { key = "anchorY", type = "slider", x = 28, y = 8, w = 14, h = 2, label = "Vertical (Y)", min = -600, max = 600, step = 5 },
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
    local exdb   = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.flashText
    if gridDB and exdb then
        for k, v in pairs(gridDB) do exdb[k] = v end
    end
    if InfinityBoss.UI.FlashText and InfinityBoss.UI.FlashText.RefreshVisuals then
        InfinityBoss.UI.FlashText:RefreshVisuals()
    end
end)

InfinityTools:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY .. "_btn", function(info)
    if not info then return end
    if info.key == "btn_reset_pos" then
        local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
        if gridDB then gridDB.anchorX = 0; gridDB.anchorY = 105 end
        local exdb = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.flashText
        if exdb then exdb.anchorX = 0; exdb.anchorY = 105 end
        if InfinityBoss.UI.FlashText and InfinityBoss.UI.FlashText.RefreshVisuals then
            InfinityBoss.UI.FlashText:RefreshVisuals()
        end
    elseif info.key == "btn_preview" then
        if InfinityTools.ToggleGlobalEditMode then InfinityTools:ToggleGlobalEditMode() end
    elseif info.key == "btn_test" then
        if InfinityBoss.UI.FlashText and InfinityBoss.UI.FlashText.Show then
            local db = InfinityTools:GetModuleDB(MODULE_KEY)
            InfinityBoss.UI.FlashText:Show(nil, "Test Spell Name", db and db.flashDuration or 2.5)
        end
    end
end)

function Page:Render(contentFrame)
    local Grid = _G.InfinityGrid
    if not Grid then
        return
    end

    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
    local exdb   = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.flashText
    if exdb and gridDB then
        for k, v in pairs(exdb) do
            if gridDB[k] == nil then gridDB[k] = v end
        end
    end

    if not Page._scrollFrame then
        local sf = CreateFrame("ScrollFrame", "InfinityBoss_FlashTextSettingsScroll",
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

