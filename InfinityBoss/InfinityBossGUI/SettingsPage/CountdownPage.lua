---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/CountdownPage.lua
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

InfinityBoss.UI.Panel.CountdownPage = InfinityBoss.UI.Panel.CountdownPage or {}
local Page = InfinityBoss.UI.Panel.CountdownPage

local MODULE_KEY = "InfinityBoss.Countdown"
local BASE_GRID_COLS = 63
local MIN_GRID_COLS = 63
local MAX_GRID_COLS = 63
local TARGET_CELL_PX = 18

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
    showIcon      = true,
    iconSize      = 24,
    showDecimal   = true,
    labelTemplate = " %s %t",
    preSecs       = 5,
    anchorX       = 15,
    anchorY       = 75,
    font_label = {
        font="Default", size=22, outline="OUTLINE",
        r=1, g=1, b=1, a=1,
        shadow=true, shadowX=2, shadowY=-2, x=0, y=0,
    },
    font_cd = {
        font="Default", size=22, outline="OUTLINE",
        r=1, g=1, b=1, a=1,
        shadow=true, shadowX=2, shadowY=-2, x=0, y=0,
    },
}

-- =============================================================
-- =============================================================
local function SafeNum(v, def) return tonumber(v) or def end

local function ToHex(r, g, b)
    local function c(v) return string.format("%02x", math.floor((tonumber(v) or 1) * 255 + 0.5)) end
    return "ff" .. c(r) .. c(g) .. c(b)
end

-- =============================================================
-- =============================================================
local function BuildPreviewText(db)
    db = db or DEFAULTS
    local tmpl     = (type(db.labelTemplate)=="string" and db.labelTemplate~="") and db.labelTemplate or DEFAULTS.labelTemplate
    local fl       = db.font_label or DEFAULTS.font_label
    local fc       = db.font_cd    or DEFAULTS.font_cd
    local labelHex = ToHex(fl.r, fl.g, fl.b)
    local cdHex    = ToHex(fc.r, fc.g, fc.b)
    local showDec  = db.showDecimal

    local s = tmpl:gsub("%%s", "|c" .. labelHex .. "Tank Buster|r")
    local pre, suf = s:match("^(.-)%%t(.*)$")
    local numStr = showDec and "3.0" or "3"
    local colored
    if pre then
        colored = "|c" .. labelHex .. pre .. "|r"
                .. "|c" .. cdHex   .. numStr .. "|r"
                .. "|c" .. labelHex .. suf .. "|r"
    else
        colored = "|c" .. labelHex .. s .. "|r"
    end

    local iconLine = db.showIcon ~= false
                     and "|TInterface\\Icons\\Ability_Warrior_ShieldBlock:" .. tostring(math.floor(SafeNum(db.iconSize, 30))) .. "|t  "
                     or ""

    return "|cffaaaaff Preview:|r\n" .. iconLine .. colored
end

-- =============================================================
-- =============================================================
local LAYOUT = {}

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

local function BuildBaseRows(previewText)
    return {
        { key="header", type="header", x=1, y=1, w=63, h=2,
          label="Countdown Settings", labelSize=22 },
        { key="desc", type="description", x=1, y=4, w=63, h=2,
          label="Displays a 5-second central countdown when a spell alert triggers.\n"
             .. "|cff00ff00%s|r = spell name  |cffffd100%t|r = countdown number" },
        { key="div_func",    type="divider",  x=1, y=7,  w=63, h=1, label="Features" },
        { key="enabled",     type="checkbox", x=1,  y=8,  w=10, h=2, label="Enable" },
        { key="showIcon",    type="checkbox", x=15, y=8,  w=10, h=2, label="Show Icon" },
        { key="showDecimal", type="checkbox", x=29, y=8,  w=13, h=2, label="Show Decimal" },
        { key="iconSize",    type="slider",   x=1,  y=11, w=30, h=2,
          label="Icon Size", min=16, max=96, step=2 },
        { key="div_tmpl",      type="divider", x=1, y=14, w=63, h=1, label="Alert Text Template" },
        { key="labelTemplate", type="input",   x=1, y=15, w=60, h=2,
          label="Template (|cff00ff00%s|r=spell name  |cffffd100%t|r=countdown number)" },
        { key="previewLabel", type="description", x=1, y=18, w=63, h=3,
          label=previewText, labelSize=20 },
        { key="hdr_label",  type="header",    x=1, y=22, w=63, h=2,
          label="Alert text font (%s)", labelSize=20 },
        { key="font_label", type="fontgroup", x=1, y=25, w=63, h=17,
          label="Alert Text", labelSize=18 },
        { key="hdr_cd",  type="header",    x=1, y=43, w=63, h=2,
          label="Countdown number font (%t)", labelSize=20 },
        { key="font_cd", type="fontgroup", x=1, y=46, w=63, h=17,
          label="Countdown Number", labelSize=18 },
        { key="div_pos",     type="divider", x=1,  y=64, w=63, h=1, label="Position" },
        { key="anchorX",     type="slider",  x=1,  y=65, w=23, h=2,
          label="Horizontal (X)", min=-1000, max=1000, step=5 },
        { key="anchorY",     type="slider",  x=26, y=65, w=23, h=2,
          label="Vertical (Y)", min=-600,  max=600,  step=5 },
        { key="btn_reset_pos", type="button", x=51, y=65, w=11, h=2,
          label="Reset Position" },
        { key="div_preview", type="divider", x=1,  y=68, w=63, h=1, label="Preview" },
        { key="btn_preview", type="button",  x=1,  y=69, w=18, h=2, label="Toggle Edit Mode" },
        { key="btn_test",    type="button",  x=21, y=69, w=18, h=2, label="Test Countdown" },
    }
end

local function ScaleLayout(items, toCols)
    if toCols == BASE_GRID_COLS then
        return items
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
    return ScaleItems(items)
end

local function RegisterLayout()
    local db = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
    local rows = BuildBaseRows(BuildPreviewText(db))
    for i = #LAYOUT, 1, -1 do LAYOUT[i] = nil end
    for _, row in ipairs(rows) do LAYOUT[#LAYOUT + 1] = row end
    InfinityTools:RegisterModuleLayout(MODULE_KEY, LAYOUT)
end

RegisterLayout()

-- =============================================================
-- =============================================================
InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY .. "_cfg", function(info)
    if not info then return end
    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
    local exdb   = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.countdown
    if gridDB then
        ApplyDefaults(gridDB, DEFAULTS)
    end
    if exdb then
        ApplyDefaults(exdb, DEFAULTS)
    end
    if gridDB and exdb then
        for k, v in pairs(gridDB) do exdb[k] = v end
    end
    if InfinityBoss.UI.Countdown and InfinityBoss.UI.Countdown.RefreshVisuals then
        InfinityBoss.UI.Countdown:RefreshVisuals()
    end
    RegisterLayout()

    local Grid = _G.InfinityGrid
    if Grid and type(Grid.Widgets) == "table" and InfinityTools.UI and InfinityTools.UI.CurrentModule == MODULE_KEY then
        local preview = Grid.Widgets["previewLabel"]
        if preview and preview.text and preview.text.SetText then
            preview.text:SetText(BuildPreviewText(gridDB))
        end
    end
end)

-- =============================================================
-- =============================================================
InfinityTools:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY .. "_btn", function(info)
    if not info then return end
    if info.key == "btn_reset_pos" then
        local gridDB = InfinityTools:GetModuleDB(MODULE_KEY)
        if gridDB then gridDB.anchorX = 15; gridDB.anchorY = 75 end
        local exdb = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.countdown
        if exdb then exdb.anchorX = 15; exdb.anchorY = 75 end
        if InfinityBoss.UI.Countdown and InfinityBoss.UI.Countdown.RefreshVisuals then
            InfinityBoss.UI.Countdown:RefreshVisuals()
        end
    elseif info.key == "btn_preview" then
        if InfinityTools.ToggleGlobalEditMode then InfinityTools:ToggleGlobalEditMode() end
    elseif info.key == "btn_test" then
        if InfinityBoss.UI.Countdown and InfinityBoss.UI.Countdown.Show then
            InfinityBoss.UI.Countdown:Show({ displayName = "Tank Buster", spellID = 46968 })
        end
    end
end)

-- =============================================================
-- Render
-- =============================================================
function Page:Render(contentFrame)
    local Grid = _G.InfinityGrid
    if not Grid then
        return
    end

    local gridDB = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
    local exdb   = _G.InfinityBossDB and _G.InfinityBossDB.timer and _G.InfinityBossDB.timer.countdown
    if gridDB then
        ApplyDefaults(gridDB, DEFAULTS)
    end
    if exdb then
        ApplyDefaults(exdb, DEFAULTS)
    end
    if exdb and gridDB then
        for k, v in pairs(exdb) do
            if gridDB[k] == nil then gridDB[k] = v end
        end
    end

    if not Page._scrollFrame then
        local sf = CreateFrame("ScrollFrame", "InfinityBoss_CountdownSettingsScroll",
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
        local currentDB = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
        local cols = ResolveGridCols(sc:GetWidth())
        local renderLayout = BuildBaseRows(BuildPreviewText(currentDB))
        if Grid.SetContainerCols then
            Grid:SetContainerCols(sc, cols)
        end
        Grid:Render(sc, ScaleLayout(renderLayout, cols), currentDB, MODULE_KEY)
    end)
end

