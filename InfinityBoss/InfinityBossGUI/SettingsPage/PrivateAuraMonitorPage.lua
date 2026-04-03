---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/PrivateAuraMonitorPage.lua
-- =============================================================

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

InfinityBoss.UI.Panel.PrivateAuraMonitorPage = InfinityBoss.UI.Panel.PrivateAuraMonitorPage or {}
local Page = InfinityBoss.UI.Panel.PrivateAuraMonitorPage

local MODULE_KEY  = "InfinityBoss.PrivateAuraMonitor"
local BASE_COLS   = 63
local TARGET_CELL = 18

-- =============================================================
-- =============================================================
local DEFAULTS = {
    enabled       = false,
    iconSize      = 56,
    iconSpacing   = 8,
    growDir       = "RIGHT",
    showBorder    = true,
    borderScale   = 1.0,
    showCountdown = true,
    showNumbers   = true,
    anchorX       = 0,
    anchorY       = -200,
    anchorPoint   = "CENTER",
}

-- =============================================================
-- =============================================================
local LAYOUT = {
    { key = "header",         type = "header",      x = 1,  y = 1,  w = 63, h = 2, label = "Private Aura Monitor", labelSize = 25 },
    { key = "desc",           type = "description", x = 1,  y = 3,  w = 63, h = 2, label = "Monitor the player's 3 private aura slots. Enable then enter edit mode to drag and reposition." },

    { key = "sub_enable",     type = "subheader",   x = 1,  y = 6,  w = 63, h = 1, label = "Enable", labelSize = 20 },
    { key = "div_0",          type = "divider",     x = 1,  y = 7,  w = 63, h = 1 },
    { key = "enabled",        type = "checkbox",    x = 2,  y = 8,  w = 20, h = 2, label = "Enable Private Aura Monitor" },
    { key = "btn_preview",    type = "button",      x = 24, y = 8,  w = 16, h = 2, label = "Enter Edit Mode" },

    { key = "sub_icon",       type = "subheader",   x = 1,  y = 11, w = 63, h = 1, label = "Icon Appearance", labelSize = 20 },
    { key = "div_1",          type = "divider",     x = 1,  y = 12, w = 63, h = 1 },
    { key = "iconSize",       type = "slider",      x = 1,  y = 13, w = 18, h = 2, label = "Icon Size",  min = 20, max = 128 },
    { key = "iconSpacing",    type = "slider",      x = 20, y = 13, w = 18, h = 2, label = "Icon Spacing",  min = 0,  max = 60  },
    { key = "growDir",        type = "dropdown",    x = 39, y = 13, w = 18, h = 2, label = "Layout Direction",  items = {
        { "Right", "RIGHT" }, { "Left", "LEFT" }, { "Up", "UP" }, { "Down", "DOWN" },
    }},
    { key = "showBorder",     type = "checkbox",    x = 1,  y = 16, w = 18, h = 2, label = "Show Border" },
    { key = "borderScale",    type = "slider",      x = 20, y = 16, w = 18, h = 2, label = "Border Scale",  min = 0.1, max = 3.0, step = 0.1 },

    { key = "sub_cd",         type = "subheader",   x = 1,  y = 19, w = 63, h = 1, label = "Countdown", labelSize = 20 },
    { key = "div_2",          type = "divider",     x = 1,  y = 20, w = 63, h = 1 },
    { key = "showCountdown",  type = "checkbox",    x = 1,  y = 21, w = 20, h = 2, label = "Show Cooldown Ring" },
    { key = "showNumbers",    type = "checkbox",    x = 22, y = 21, w = 20, h = 2, label = "Show Numeric Countdown" },

    { key = "sub_pos",        type = "subheader",   x = 1,  y = 24, w = 63, h = 1, label = "Position", labelSize = 20 },
    { key = "div_3",          type = "divider",     x = 1,  y = 25, w = 63, h = 1 },
    { key = "anchorX",        type = "slider",      x = 1,  y = 26, w = 18, h = 2, label = "Horizontal (X)", min = -1500, max = 1500 },
    { key = "anchorY",        type = "slider",      x = 20, y = 26, w = 18, h = 2, label = "Vertical (Y)", min = -800,  max = 800  },
    { key = "anchorPoint",    type = "dropdown",    x = 39, y = 26, w = 18, h = 2, label = "Anchor", items = {
        { "Screen Center", "CENTER" }, { "Top Left",     "TOPLEFT"     }, { "Top Center",   "TOP"         },
        { "Top Right",    "TOPRIGHT"    }, { "Left",         "LEFT"        }, { "Right",        "RIGHT"       },
        { "Bottom Left",  "BOTTOMLEFT"  }, { "Bottom",       "BOTTOM"      }, { "Bottom Right", "BOTTOMRIGHT" },
    }},
    { key = "btn_reset_pos",  type = "button",      x = 1,  y = 29, w = 14, h = 2, label = "Reset Position" },
}

-- =============================================================
-- =============================================================
local anchorIDs  = {}   -- [1..3] anchorID
local rootFrame  = nil
local slotFrames = {}
local previewFrames = {}

-- =============================================================
-- =============================================================
local function GetDB()
    local db = InfinityTools:GetModuleDB(MODULE_KEY, DEFAULTS)
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then db[k] = v end
    end
    return db
end

local function SetClickThrough(frame)
    frame:EnableMouse(false)
    frame:EnableMouseWheel(false)
end

local function GetSlotOffset(db, idx)
    local step = (db.iconSize or 56) + (db.iconSpacing or 8)
    local i    = idx - 1
    local dir  = db.growDir or "RIGHT"
    if     dir == "RIGHT" then return  i * step, 0
    elseif dir == "LEFT"  then return -i * step, 0
    elseif dir == "UP"    then return 0,  i * step
    else                       return 0, -i * step
    end
end

-- =============================================================
-- =============================================================
local function RemoveAllAnchors()
    for i = 1, 3 do
        if anchorIDs[i] then
            C_UnitAuras.RemovePrivateAuraAnchor(anchorIDs[i])
            anchorIDs[i] = nil
        end
    end
end

local function EnsureFrames()
    if not rootFrame then
        rootFrame = CreateFrame("Frame", "InfinityBoss_PAMonitor_Root", UIParent)
        rootFrame:SetSize(1, 1)
        SetClickThrough(rootFrame)
        rootFrame:SetMovable(true)
        rootFrame:SetClampedToScreen(false)
        rootFrame:SetFrameStrata("MEDIUM")

        rootFrame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and InfinityTools.GlobalEditMode then
                self._moving = true
                self:StartMoving()
            elseif button == "RightButton" and InfinityTools.GlobalEditMode then
                InfinityTools:OpenConfig(MODULE_KEY)
            end
        end)
        rootFrame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self._moving then
                self._moving = false
                self:StopMovingOrSizing()
                local cx, cy = UIParent:GetCenter()
                local sx, sy = self:GetCenter()
                if sx and cx then
                    local db = GetDB()
                    db.anchorX     = math.floor(sx - cx)
                    db.anchorY     = math.floor(sy - cy)
                    db.anchorPoint = "CENTER"
                    InfinityTools:UpdateState(MODULE_KEY .. ".DatabaseChanged", { key = "anchorX" })
                end
            end
        end)

        InfinityTools:RegisterHUD(MODULE_KEY, rootFrame)
        SetClickThrough(rootFrame)
    end

    for i = 1, 3 do
        if not slotFrames[i] then
            slotFrames[i] = CreateFrame("Frame", nil, UIParent)
            SetClickThrough(slotFrames[i])
        end
        if not previewFrames[i] then
            local pf = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            pf:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 10,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
            pf:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
            pf:SetBackdropBorderColor(0.2, 0.8, 1, 0.9)
            local tex = pf:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            tex:SetAlpha(0.5)
            pf.tex = tex
            local num = pf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            num:SetPoint("CENTER")
            num:SetTextColor(1, 1, 0)
            num:SetText(tostring(i))
            pf:Hide()
            previewFrames[i] = pf
        end
    end
end

function Page:ApplyAnchors()
    RemoveAllAnchors()
    EnsureFrames()

    local db = GetDB()

    rootFrame:ClearAllPoints()
    rootFrame:SetPoint(db.anchorPoint or "CENTER", UIParent, db.anchorPoint or "CENTER",
        db.anchorX or 0, db.anchorY or 0)

    if not db.enabled then
        rootFrame:Hide()
        for i = 1, 3 do
            slotFrames[i]:Hide()
            previewFrames[i]:Hide()
        end
        return
    end

    rootFrame:Show()

    local sz      = db.iconSize or 56
    local bScale  = db.showBorder and (db.borderScale or 1.0) or -100
    local borderPx = sz / 16 * bScale

    for i = 1, 3 do
        local ox, oy = GetSlotOffset(db, i)

        local f = slotFrames[i]
        f:SetSize(sz, sz)
        f:ClearAllPoints()
        f:SetPoint("CENTER", rootFrame, "CENTER", ox, oy)
        f:Show()

        anchorIDs[i] = C_UnitAuras.AddPrivateAuraAnchor({
            unitToken            = "player",
            auraIndex            = i,
            parent               = f,
            showCountdownFrame   = db.showCountdown == true,
            showCountdownNumbers = db.showNumbers == true,
            iconInfo = {
                iconAnchor = {
                    point         = "CENTER",
                    relativeTo    = f,
                    relativePoint = "CENTER",
                    offsetX       = 0,
                    offsetY       = 0,
                },
                iconWidth   = sz,
                iconHeight  = sz,
                borderScale = borderPx,
            },
        })

        local pf = previewFrames[i]
        pf:SetSize(sz, sz)
        pf:ClearAllPoints()
        pf:SetPoint("CENTER", f, "CENTER", 0, 0)
    end
end

-- =============================================================
-- =============================================================
local function SetEditMode(enabled)
    EnsureFrames()
    local db = GetDB()
    if enabled and db.enabled then
        rootFrame:SetSize(
            (db.iconSize or 56) + math.abs(GetSlotOffset(db, 3)),
            db.iconSize or 56
        )
        rootFrame:EnableMouse(true)
        for i = 1, 3 do
            previewFrames[i]:Show()
            previewFrames[i]:SetFrameStrata("DIALOG")
        end
    else
        SetClickThrough(rootFrame)
        for i = 1, 3 do
            previewFrames[i]:Hide()
        end
    end
end

local function UpdateRootSize()
    if not rootFrame then return end
    local db = GetDB()
    if not db.enabled then return end
    local sz   = db.iconSize or 56
    local step = sz + (db.iconSpacing or 8)
    local dir  = db.growDir or "RIGHT"
    local w, h
    if dir == "RIGHT" or dir == "LEFT" then
        w = step * 3 - (db.iconSpacing or 8)
        h = sz
    else
        w = sz
        h = step * 3 - (db.iconSpacing or 8)
    end
    rootFrame:SetSize(math.max(w, 1), math.max(h, 1))
end

InfinityTools:RegisterEditModeCallback(MODULE_KEY, SetEditMode)

-- =============================================================
-- =============================================================
InfinityTools:RegisterModuleLayout(MODULE_KEY, LAYOUT)

InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY .. "_cfg", function()
    Page:ApplyAnchors()
    UpdateRootSize()
    if InfinityTools.GlobalEditMode then
        SetEditMode(true)
    end
end)

InfinityTools:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY .. "_btn", function(info)
    if not info then return end
    if info.key == "btn_preview" then
        InfinityTools:ToggleGlobalEditMode()
    elseif info.key == "btn_reset_pos" then
        local db = GetDB()
        db.anchorX     = DEFAULTS.anchorX
        db.anchorY     = DEFAULTS.anchorY
        db.anchorPoint = DEFAULTS.anchorPoint
        Page:ApplyAnchors()
        InfinityTools:UpdateState(MODULE_KEY .. ".DatabaseChanged", { key = "anchorX" })
    end
end)

-- =============================================================
-- =============================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    C_Timer.After(0.5, function()
        Page:ApplyAnchors()
        UpdateRootSize()
    end)
end)

-- =============================================================
-- =============================================================
function Page:Render(contentFrame)
    local Grid = _G.InfinityGrid
    if not Grid then return end

    if not Page._scrollFrame then
        local sf = CreateFrame("ScrollFrame", "InfinityBoss_PAMonitorSettingsScroll",
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
    sf:SetAllPoints(contentFrame)
    sc:SetWidth(contentFrame:GetWidth() - 24)

    local cols = math.max(BASE_COLS, math.floor(((contentFrame:GetWidth() - 24 - 20) / TARGET_CELL) + 0.5))
    Grid:SetContainerCols(sc, cols)

    InfinityTools.UI.ActivePageFrame = sc
    InfinityTools.UI.CurrentModule   = MODULE_KEY

    Grid:Render(sc, LAYOUT, GetDB(), MODULE_KEY)

    sf:Show()
end

function Page:Hide()
    if Page._scrollFrame then
        Page._scrollFrame:Hide()
        if InfinityTools.UI and InfinityTools.UI.ActivePageFrame == Page._scrollChild then
            InfinityTools.UI.ActivePageFrame = nil
            InfinityTools.UI.CurrentModule   = nil
        end
    end
end
