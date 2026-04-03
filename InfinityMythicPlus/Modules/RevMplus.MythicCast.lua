-- =============================================================
-- [[ Mythic+ Cast Monitor ]]
-- { Key = "RevMplus.MythicCast", Name = "Cast Monitor", Desc = "Monitors cast progress of nearby hostile targets (formerly InfinityCast)", Category = 2 },
-- =============================================================

local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevMplus.MythicCast"
local LSM = LibStub("LibSharedMedia-3.0") -- assume LSM is available in the InfinityTools environment

-- ------------------------------------------------------------
-- Constant definitions
-- ------------------------------------------------------------
local INFINITY_COLOR_INTERRUPTIBLE = CreateColor(0, 1, 0)     -- interruptible (green)
local INFINITY_COLOR_NOT_INTERRUPTIBLE = CreateColor(1, 0, 0) -- not interruptible (red)

local InfinityFactory = _G.InfinityFactory

-- ------------------------------------------------------------
-- Local variables (restore variables that were deleted by mistake)
-- ------------------------------------------------------------
local activeBars = {}
local usedBarsList = {}
local previewBars = {}
local anchorFrame = nil
local isPreviewing = false
local TogglePreview
local UpdateCast

-- Common API references
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local WorldFrame = _G.WorldFrame
local GetTime = _G.GetTime
local UnitName = _G.UnitName
local UnitClass = _G.UnitClass
local C_ClassColor = _G.C_ClassColor
local string = _G.string
local type = _G.type
local pairs = _G.pairs
local next = _G.next
local select = _G.select
local tonumber = _G.tonumber
local math = _G.math
local table = _G.table
local ipairs = _G.ipairs
local print = _G.print
local UnitExists = _G.UnitExists
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local UnitCastingDuration = _G.UnitCastingDuration
local UnitChannelDuration = _G.UnitChannelDuration
local UnitGUID = _G.UnitGUID
local C_Spell = _G.C_Spell
local CreateColor = _G.CreateColor
local IsMouseButtonDown = _G.IsMouseButtonDown
local IsKeyDown = _G.IsKeyDown
local ResetCursor = _G.ResetCursor
local SetCursor = _G.SetCursor
local GetMouseFocus = _G.GetMouseFocus
local GetMouseFoci = _G.GetMouseFoci
local GameTooltip = _G.GameTooltip
local C_StringUtil = _G.C_StringUtil

-- ------------------------------------------------------------
-- 1. Grid layout definition
-- ------------------------------------------------------------
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 53, h = 2, label = L["Mythic Mob Casts (MythicCast)"], labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 53, h = 2, label = L["Tracks cast progress on nameplate units in real time."] },
        { key = "div1", type = "divider", x = 1, y = 7, w = 53, h = 1, label = "--[[ Function ]]" },
        { key = "subheader_main", type = "subheader", x = 1, y = 9, w = 53, h = 2, label = L["General Settings"], labelSize = 20 },  -- TODO: missing key: L["General Settings"]
        { key = "enabled", type = "checkbox", x = 1, y = 11, w = 6, h = 2, label = L["Enable"] },  -- TODO: missing key: L["Enable"]
        { key = "locked", type = "checkbox", x = 10, y = 11, w = 8, h = 2, label = L["Lock Position"] },
        { key = "preview", type = "checkbox", x = 20, y = 11, w = 8, h = 2, label = L["Preview Mode"] },
        { key = "btn_reset_pos", type = "button", x = 34, y = 11, w = 14, h = 2, label = L["Reset Position"] },
        { key = "posX", type = "slider", x = 1, y = 14, w = 17, h = 2, label = L["Overall Horizontal Position"], min = -1000, max = 1000 },
        { key = "posY", type = "slider", x = 21, y = 14, w = 17, h = 2, label = L["Overall Vertical Position"], min = -1000, max = 1000 },

        { key = "custom_attach_header", type = "header", x = 1, y = 18, w = 53, h = 2, label = L["Free Attach (Beta)"], labelSize = 20 },
        { key = "custom_attach_desc", type = "description", x = 1, y = 21, w = 48, h = 1, label = L["Attach the cast bar group to any UI element. Falls back to screen center if the target frame is missing."] },
        { key = "attachToCustom", type = "checkbox", x = 1, y = 23, w = 10, h = 2, label = L["Enable Free Attach"] },
        { key = "customAttachTarget", type = "input", x = 12, y = 23, w = 26, h = 2, label = L["Current Target Path"] },
        { key = "btn_pick_frame", type = "button", x = 39, y = 23, w = 10, h = 2, label = L["Pick With Mouse"] },

        { key = "raid_header", type = "header", x = 1, y = 27, w = 53, h = 2, label = L["Raid Markers"], labelSize = 20 },
        { key = "showRaidIcon", type = "checkbox", x = 1, y = 30, w = 15, h = 2, label = L["Show Raid Markers"] },
        { key = "raidIconSize", type = "slider", x = 21, y = 30, w = 15, h = 2, label = L["Marker Size"], min = 10, max = 64 },
        { key = "raidIconX", type = "slider", x = 1, y = 33, w = 15, h = 2, label = L["Horizontal Offset"], min = -100, max = 100 },
        { key = "raidIconY", type = "slider", x = 21, y = 33, w = 15, h = 2, label = L["Vertical Offset"], min = -100, max = 100 },

        { key = "color_header", type = "header", x = 1, y = 37, w = 53, h = 2, label = L["Bar Appearance"], labelSize = 20 },
        { key = "nonInterruptColor", type = "color", x = 21, y = 42, w = 15, h = 2, label = L["Uninterruptible Color"], labelPos = "top" },
        { key = "spacing", type = "slider", x = 1, y = 42, w = 17, h = 2, label = L["Vertical Spacing"], min = 0, max = 50 },  -- TODO: missing key: L["Vertical Spacing"]
        { key = "growDirection", type = "dropdown", x = 21, y = 45, w = 15, h = 2, label = L["Grow Direction"], items = "Down,Up" },
        { key = "maxBars", type = "slider", x = 1, y = 45, w = 17, h = 2, label = L["Max Visible Bars"], min = 1, max = 15 },
        { key = "timerGroup", type = "timerBarGroup", x = 1, y = 49, w = 53, h = 26, label = "", labelSize = 20 },

        { key = "font_spell_header", type = "header", x = 1, y = 77, w = 53, h = 2, label = L["Font: Spell Name"], labelSize = 20 },
        { key = "textAlign", type = "dropdown", x = 1, y = 80, w = 15, h = 2, label = L["Alignment"], items = "LEFT,CENTER,RIGHT" },
        { key = "font_spell", type = "fontgroup", x = 1, y = 83, w = 53, h = 17, label = "", labelSize = 20 },

        { key = "font_target_header", type = "header", x = 1, y = 102, w = 47, h = 2, label = L["Font: Cast Target"], labelSize = 20 },
        { key = "showTarget", type = "checkbox", x = 1, y = 105, w = 15, h = 2, label = L["Show Target Name"] },
        { key = "targetAlign", type = "dropdown", x = 18, y = 105, w = 15, h = 2, label = L["Alignment"], items = "LEFT,CENTER,RIGHT" },
        { key = "mergeTargetIntoSpellName", type = "checkbox", x = 35, y = 105, w = 18, h = 2, label = L["Merge Into Spell Name"] },
        { key = "spellTargetInlineFormat", type = "input", x = 1, y = 108, w = 22, h = 2, label = L["Separator"], placeholder = "-" },
        { key = "font_target", type = "fontgroup", x = 1, y = 111, w = 53, h = 18, label = "", labelSize = 20 },

        { key = "font_timer_header", type = "header", x = 1, y = 128, w = 53, h = 2, label = L["Font: Cooldown Time"], labelSize = 20 },
        { key = "showTimer", type = "checkbox", x = 1, y = 131, w = 15, h = 2, label = L["Show Time Text"] },
        { key = "timerAlign", type = "dropdown", x = 18, y = 131, w = 15, h = 2, label = L["Alignment"], items = "LEFT,CENTER,RIGHT" },
        { key = "font_timer", type = "fontgroup", x = 1, y = 134, w = 53, h = 18, label = "", labelSize = 20 },
    }






    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local MODULE_DEFAULTS = {
    enabled = false,
    font_spell = {
        a = 1,
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = false,
        shadowX = 1,
        size = 20,
        x = 2,
        y = 0,
    },
    font_target = {
        a = 1,
        b = 0.40392160415649,
        font = "Default",
        g = 0.80000007152557,
        outline = "OUTLINE",
        r = 0.27058824896812,
        shadow = false,
        shadowX = 1,
        size = 16,
        x = 38,
        y = 0,
    },
    font_timer = {
        a = 1,
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = false,
        shadowX = 9,
        size = 17,
        x = 0,
        y = 0,
    },
    growDirection = "Up",
    locked = true,
    maxBars = 6,
    nonInterruptColorA = 1,
    nonInterruptColorB = 0.16862745583057,
    nonInterruptColorG = 0.1294117718935,
    nonInterruptColorR = 1,
    posX = -527,
    posY = -12,
    preview = false,
    raidIconSize = 27,
    raidIconX = -1,
    raidIconY = 0,
    -- scale removed
    showRaidIcon = true,
    showTarget = true,
    showTimer = true,
    mergeTargetIntoSpellName = false,
    spellTargetInlineFormat = "-",
    spacing = 1,
    targetAlign = "CENTER",
    textAlign = "LEFT",
    timerAlign = "RIGHT",
    attachToCustom = false,  -- Whether free attach is enabled
    customAttachTarget = "", -- Target frame name or path
    timerGroup = {
        barBgColor = {
            a = 0.5,
            b = 0,
            g = 0,
            r = 0,
        },
        barBgColorA = 0.71539187431335,
        barBgColorB = 0.27843138575554,
        barBgColorG = 0.27843138575554,
        barBgColorR = 0.27843138575554,
        barColor = {
            a = 1,
            b = 0,
            g = 0.7,
            r = 1,
        },
        barColorA = 1,
        barColorB = 1,
        barColorG = 0.90980398654938,
        barColorR = 0.29019609093666,
        height = 28,
        iconOffsetX = 0,
        iconOffsetY = 0,
        iconSide = "LEFT",
        iconSize = 30,
        showIcon = true,
        texture = "Melli",
        width = 224,
    },
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- Migrate legacy Chinese grow direction values
-- (CN migration removed)

local function GetColor(dbKey)
    local r, g, b, a = MODULE_DB[dbKey .. "R"], MODULE_DB[dbKey .. "G"], MODULE_DB[dbKey .. "B"], MODULE_DB[dbKey .. "A"]
    if r == nil and MODULE_DB[dbKey] and type(MODULE_DB[dbKey]) == "table" then
        return MODULE_DB[dbKey].r, MODULE_DB[dbKey].g, MODULE_DB[dbKey].b, MODULE_DB[dbKey].a
    end
    return r or 1, g or 1, b or 1, a or 1
end

local function BuildInlineTargetText(targetName, targetClass)
    if not targetName then
        return targetName
    end

    local coloredTarget = targetName
    if targetClass then
        local classColor = C_ClassColor.GetClassColor(targetClass)
        if classColor and classColor.GenerateHexColor and WrapTextInColorCode then
            coloredTarget = WrapTextInColorCode(targetName, classColor:GenerateHexColor())
        end
    end

    local separator = MODULE_DB.spellTargetInlineFormat
    if type(separator) ~= "string" or separator == "" then
        separator = "-"
    end

    -- Legacy compatibility: if the user previously entered a format string like "%s - %s", automatically extract the separator in the middle
    local extracted = separator:match("^%%s(.-)%%s$")
    if extracted ~= nil then
        separator = extracted
    end

    local wrappedTarget = coloredTarget
    if C_StringUtil and C_StringUtil.WrapString then
        wrappedTarget = C_StringUtil.WrapString(coloredTarget, separator)
    else
        wrappedTarget = string.concat(separator, coloredTarget)
    end
    return wrappedTarget
end

local function BuildMergedSpellText(spellName, targetName, targetClass)
    if not spellName or not targetName then
        return spellName
    end

    local inlineTarget = BuildInlineTargetText(targetName, targetClass)
    if string.concat then
        return string.concat(spellName, inlineTarget)
    end
    return spellName
end

local function UpdateBarVisuals(bar)
    local db = MODULE_DB
    local group = db.timerGroup or {}
    local barWidth = group.width or 200
    local spellTextWidth
    if db.mergeTargetIntoSpellName then
        spellTextWidth = math.max(40, math.floor(barWidth * 0.85))
    else
        local timerReserve = db.showTimer and 48 or 0
        spellTextWidth = math.max(40, barWidth - timerReserve - 8)
    end
    -- 1. Base visuals
    bar:SetSize(barWidth, group.height or 20)
    local texName = group.texture or "Melli"
    local tex = LSM:Fetch("statusbar", texName)
    if not tex then tex = "Interface\\Buttons\\WHITE8X8" end

    if bar.bg then
        bar.bg:SetTexture(tex)
        bar.bg:SetVertexColor(
            group.barBgColorR or 0,
            group.barBgColorG or 0,
            group.barBgColorB or 0,
            group.barBgColorA or 0.5
        )
    end
    bar:SetStatusBarTexture(tex)

    -- [Feature] Apply border styling (ensure the border renders in front of the status bar)
    local edgeTex = group.showBorder and group.borderTexture and group.borderTexture ~= "None" and
        LSM:Fetch("border", group.borderTexture) or nil
    if edgeTex then
        if not bar.BorderFrame then
            bar.BorderFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            bar.BorderFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
        end
        local edgeSize = group.borderSize or 12
        local pad = group.borderPadding or 0
        bar.BorderFrame:ClearAllPoints()
        bar.BorderFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", -pad, pad)
        bar.BorderFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", pad, -pad)
        bar.BorderFrame:SetBackdrop({
            edgeFile = edgeTex,
            edgeSize = edgeSize,
        })
        local br, bg, bb, ba = group.borderColorR or 1, group.borderColorG or 1, group.borderColorB or 1,
            group.borderColorA or 1
        bar.BorderFrame:SetBackdropBorderColor(br, bg, bb, ba)
        bar.BorderFrame:Show()
    else
        if bar.BorderFrame then
            bar.BorderFrame:Hide()
        end
    end

    -- 2. Apply the standard font group (InfinityDB:ApplyFont handles font/size/color/outline/shadow)
    local StaticDB = InfinityTools.DB_Static

    if bar.Text then
        StaticDB:ApplyFont(bar.Text, db.font_spell)
        bar.Text:ClearAllPoints()
        if db.mergeTargetIntoSpellName then
            bar.Text:SetPoint("LEFT", bar, "LEFT", db.font_spell.x, db.font_spell.y)
            bar.Text:SetJustifyH("LEFT")
        else
            bar.Text:SetPoint(db.textAlign, bar, db.textAlign, db.font_spell.x, db.font_spell.y)
            bar.Text:SetJustifyH(db.textAlign)
        end
        bar.Text:SetWidth(spellTextWidth)
        bar.Text:SetMaxLines(1)
        bar.Text:SetWordWrap(false)
        if bar.Text.SetNonSpaceWrap then
            bar.Text:SetNonSpaceWrap(false)
        end
    end

    if bar.TargetNameText then
        StaticDB:ApplyFont(bar.TargetNameText, db.font_target)
        bar.TargetNameText:ClearAllPoints()
        if db.mergeTargetIntoSpellName then
            -- In side-by-side mode, do not reuse the large offset used for standalone target names, or it creates too much empty space in the middle
            bar.TargetNameText:SetPoint("LEFT", bar.Text, "RIGHT", 2, db.font_target.y)
            bar.TargetNameText:SetJustifyH("LEFT")
        else
            bar.TargetNameText:SetPoint(db.targetAlign, bar, db.targetAlign, db.font_target.x, db.font_target.y)
            bar.TargetNameText:SetJustifyH(db.targetAlign)
        end
        bar.TargetNameText:SetShown(db.showTarget and not db.mergeTargetIntoSpellName)
        bar.TargetNameText:SetWidth(math.max(30, barWidth - 16))
        bar.TargetNameText:SetMaxLines(1)
        bar.TargetNameText:SetWordWrap(false)
        if bar.TargetNameText.SetNonSpaceWrap then
            bar.TargetNameText:SetNonSpaceWrap(false)
        end


        if bar._isPreview then
            local _, class = UnitClass("player")
            local colorObj = C_ClassColor.GetClassColor(class)
            if colorObj then
                bar.TargetNameText:SetTextColor(colorObj.r, colorObj.g, colorObj.b, 1)
            end
        end
    end

    if bar.TimerText then
        StaticDB:ApplyFont(bar.TimerText, db.font_timer)
        bar.TimerText:ClearAllPoints()
        bar.TimerText:SetPoint(db.timerAlign, bar, db.timerAlign, db.font_timer.x, db.font_timer.y)
        bar.TimerText:SetJustifyH(db.timerAlign)
        bar.TimerText:SetShown(db.showTimer)
    end
    if bar.Icon then
        bar.Icon:SetSize(group.iconSize or 20, group.iconSize or 20)
        bar.Icon:ClearAllPoints()
        local side = group.iconSide or "LEFT"
        if side == "LEFT" then
            bar.Icon:SetPoint("RIGHT", bar, "LEFT", group.iconOffsetX or 0, group.iconOffsetY or 0)
        else
            bar.Icon:SetPoint("LEFT", bar, "RIGHT", group.iconOffsetX or 0, group.iconOffsetY or 0)
        end
        bar.Icon:SetShown(group.showIcon)
        -- Apply 8% cropping (Zoom) to all icons to remove Blizzards default black edges
        bar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    if bar.RaidIcon then
        -- Real-time visual preview: apply the configured size and position
        bar.RaidIcon:SetSize(db.raidIconSize or 24, db.raidIconSize or 24)
        bar.RaidIcon:ClearAllPoints()
        bar.RaidIcon:SetPoint("RIGHT", bar.Icon, "LEFT", db.raidIconX or -2, db.raidIconY or 0)

        -- In preview mode, if display is enabled but there is no real marker, show a simulated marker so the user can clearly see the position
        -- Special handling for preview mode
        if bar._isPreview then
            if bar.RaidIcon and MODULE_DB.showRaidIcon then
                bar.RaidIcon:Show()
                -- [Fix] Support displaying different icons (cycles through 1-8)
                local idx = bar._previewRaidIndex or 1
                bar.RaidIcon:SetSpriteSheetCell(idx, 4, 4)
            else
                if bar.RaidIcon then
                    bar.RaidIcon:Hide()
                end
            end
        end
    end

    -- 3. Enhancement: real-time color preview in preview mode
    local sbTex = bar:GetStatusBarTexture()
    if sbTex and bar._isPreview then
        local nrR, nrG, nrB, nrA = GetColor("nonInterruptColor")
        local intColor = CreateColor(nrR, nrG, nrB, nrA)
        local normColor = CreateColor(
            group.barColorR or 1,
            group.barColorG or 0.7,
            group.barColorB or 0,
            group.barColorA or 1
        )
        -- Use the stored _isNotInt state so color changes refresh immediately
        sbTex:SetVertexColorFromBoolean(bar._isNotInt, intColor, normColor)
    end
end

-- ------------------------------------------------------------
-- Anchor offset saving: supports relative coordinate calculation in free-attach mode
-- ------------------------------------------------------------
local function SaveAnchorPosition()
    if not anchorFrame then return end
    local sx, sy = anchorFrame:GetCenter()
    if not sx or not sy then return end

    -- Default reference point: screen center (UIParent)
    local tx, ty = UIParent:GetCenter()
    local targetScale = UIParent:GetEffectiveScale()
    local anchorScale = anchorFrame:GetEffectiveScale()

    -- Core logic: in attach mode, calculate the offset relative to the center of the target frame
    if MODULE_DB.attachToCustom and MODULE_DB.customAttachTarget ~= "" then
        local target = _G
        for part in string.gmatch(MODULE_DB.customAttachTarget, "([^%.]+)") do
            if target then target = target[part] else break end
        end
        if target and type(target) == "table" and target.GetCenter then
            local t_sx, t_sy = target:GetCenter()
            if t_sx and t_sy then
                tx, ty = t_sx, t_sy
                targetScale = target:GetEffectiveScale()
            end
        end
    end

    -- Take each effective scale into account and convert to logical coordinates relative to the anchors own scale
    MODULE_DB.posX = math.floor((sx * anchorScale - tx * targetScale) / anchorScale)
    MODULE_DB.posY = math.floor((sy * anchorScale - ty * targetScale) / anchorScale)

    -- Synchronize the slider values in the settings UI
    if InfinityTools.UI and InfinityTools.UI.RefreshContent then
        InfinityTools.UI:RefreshContent()
    end
end

local function ReLayout()
    if not anchorFrame then return end
    local group = MODULE_DB.timerGroup or {}
    local height = group.height or 20
    local spacing = MODULE_DB.spacing or 0
    local list = isPreviewing and previewBars or usedBarsList
    local growUp = (MODULE_DB.growDirection == "Up")
    local maxLimit = MODULE_DB.maxBars or 5

    local visibleCount = 0
    for i, bar in ipairs(list) do
        if i <= maxLimit then
            visibleCount = visibleCount + 1
            bar:Show()
            bar:EnableMouse(false) -- [v4.7 Fix] Disable mouse on bars to prevent blocking anchor drag
        else
            bar:Hide()
        end
    end

    -- [v4.7 Fix] Core refactor: keep anchorFrame at a fixed size as the logical origin
    -- This ensures the center point (CENTER) never shifts when the number of bars changes
    anchorFrame:SetSize(group.width or 220, 20)

    if anchorFrame.bg then
        local totalHeight = math.max(20, visibleCount * height + math.max(0, visibleCount - 1) * spacing)

        anchorFrame.bg:ClearAllPoints()
        anchorFrame.label:ClearAllPoints()
        anchorFrame.label:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)

        -- [v4.7.1] Dynamic hit area: let the background cover the full item area and act as the drag handle
        anchorFrame.bg:SetSize(group.width or 220, totalHeight)
        if growUp then
            -- Grow upward: align the background bottom edge with the origin center
            anchorFrame.bg:SetPoint("BOTTOM", anchorFrame, "CENTER")
        else
            -- Grow downward: align the background top edge with the origin center
            anchorFrame.bg:SetPoint("TOP", anchorFrame, "CENTER")
        end

        -- Attach drag logic to the background handle (forwarded to the parent)
        anchorFrame.bg:EnableMouse(not MODULE_DB.locked)
        anchorFrame.bg:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" and not MODULE_DB.locked then
                anchorFrame.isMoving = true
                anchorFrame:StartMoving()
            elseif button == "RightButton" and InfinityTools.GlobalEditMode then
                -- [v4.7.2 Fix] Forward right-clicks to avoid the background layer blocking HUD registration hooks
                InfinityTools:OpenConfig(INFINITY_MODULE_KEY)
            end
        end)
        anchorFrame.bg:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and anchorFrame.isMoving then
                anchorFrame.isMoving = false
                anchorFrame:StopMovingOrSizing()
                SaveAnchorPosition() -- Use unified save logic
            end
        end)

        -- All bars stack relative to the fixed anchorFrame
        for i, bar in ipairs(list) do
            if i <= maxLimit then
                bar:ClearAllPoints()
                local yOffset = (i - 1) * (height + spacing)
                if growUp then
                    bar:SetPoint("BOTTOM", anchorFrame, "CENTER", 0, yOffset)
                else
                    bar:SetPoint("TOP", anchorFrame, "CENTER", 0, -yOffset)
                end
            end
        end
    end

    -- [Feature] Free-attach logic
    local attached = false
    if MODULE_DB.attachToCustom and MODULE_DB.customAttachTarget ~= "" then
        local target = _G
        for part in string.gmatch(MODULE_DB.customAttachTarget, "([^%.]+)") do
            if target then target = target[part] else break end
        end

        if target and type(target) == "table" and target.GetPoint then
            anchorFrame:ClearAllPoints()
            -- Default to center alignment, with the offset controlled by the original posX/Y values
            anchorFrame:SetPoint("CENTER", target, "CENTER", MODULE_DB.posX or 0, MODULE_DB.posY or 0)
            attached = true
        end
    end

    if not attached then
        -- [Fallback] If the attach target does not exist, automatically fall back to screen-center-relative positioning (UIParent)
        anchorFrame:ClearAllPoints()
        anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX or 0, MODULE_DB.posY or 0)
    end
end

local function RefreshAll()
    if isPreviewing then
        -- If preview mode is active, regenerate the configured number of preview bars
        TogglePreview(false)
        TogglePreview(true)
    else
        for unit, bar in pairs(activeBars) do
            UpdateBarVisuals(bar)
            UpdateCast(unit)
        end
    end
    ReLayout()
    if anchorFrame then
        -- Global scaling support has been removed

        if MODULE_DB.locked then
            anchorFrame:EnableMouse(false)
            anchorFrame.bg:Hide()
            anchorFrame.label:Hide()
        else
            anchorFrame:EnableMouse(true)
            anchorFrame.bg:Show()
            anchorFrame.label:Show()
        end
    end
end

-- ------------------------------------------------------------
-- Frame picker
-- ------------------------------------------------------------
local pickerOverlay = nil
local highlightFrame = nil

local function GetRawFrameName(frame)
    if not frame then return end
    local name = frame.GetName and frame:GetName()
    if name then return name end

    -- Handle anonymous frames: walk up the parent chain and probe for the key
    local parent = frame.GetParent and frame:GetParent()
    if parent then
        for k, v in pairs(parent) do
            if v == frame then
                local pName = GetRawFrameName(parent)
                return pName and (pName .. "." .. k) or nil
            end
        end
    end
    return nil
end

local function StartFramePicker()
    if not pickerOverlay then
        pickerOverlay = CreateFrame("Frame")
    end

    if not highlightFrame then
        highlightFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        highlightFrame:SetFrameStrata("TOOLTIP")
        highlightFrame:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        highlightFrame:SetBackdropBorderColor(0, 1, 0) -- Classic green
    end

    local lastFocus = nil
    pickerOverlay:SetScript("OnUpdate", function(self)
        -- Watch for exit (right-click or ESC)
        if IsMouseButtonDown("RightButton") or IsKeyDown("ESCAPE") then
            self:SetScript("OnUpdate", nil)
            highlightFrame:Hide()
            ResetCursor()
            GameTooltip:Hide()
            return
        end

        SetCursor("CAST_CURSOR")

        local focus
        if GetMouseFoci then
            local foci = GetMouseFoci()
            focus = foci and foci[1]
        elseif GetMouseFocus then
            focus = GetMouseFocus()
        end

        if focus and focus ~= WorldFrame and focus ~= highlightFrame then
            local name = GetRawFrameName(focus)
            if name then
                if focus ~= lastFocus then
                    highlightFrame:ClearAllPoints()
                    highlightFrame:SetPoint("BOTTOMLEFT", focus, "BOTTOMLEFT", -2, -2)
                    highlightFrame:SetPoint("TOPRIGHT", focus, "TOPRIGHT", 2, 2)
                    highlightFrame:Show()
                    lastFocus = focus
                end

                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
                GameTooltip:SetText("|cff00ff00Picking: |r" .. name)
                GameTooltip:AddLine("|cffffffff Left-click : Select this frame|r")
                GameTooltip:AddLine("|cffaaaaaa Right-click/ESC : Cancel|r")
                GameTooltip:Show()

                -- Watch for save (left-click)
                if IsMouseButtonDown("LeftButton") then
                    MODULE_DB.customAttachTarget = name
                    MODULE_DB.attachToCustom = true
                    self:SetScript("OnUpdate", nil)
                    highlightFrame:Hide()
                    ResetCursor()
                    GameTooltip:Hide()

                    if InfinityTools.UI and InfinityTools.UI.RefreshContent then
                        InfinityTools.UI:RefreshContent()
                    end
                    RefreshAll()
                end
                return
            end
        end

        highlightFrame:Hide()
        lastFocus = nil
        GameTooltip:Hide()
    end)
end


local function InitCastBarStructure(bar)
    bar:SetClampedToScreen(true)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bar.bg = bg
    bar.Text = bar:CreateFontString(nil, "OVERLAY")
    bar.TargetNameText = bar:CreateFontString(nil, "OVERLAY")
    bar.TimerText = bar:CreateFontString(nil, "OVERLAY")
    bar.Icon = bar:CreateTexture(nil, "OVERLAY")

    -- Raid marker icon
    local ri = bar:CreateTexture(nil, "OVERLAY")
    ri:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    ri:Hide()
    bar.RaidIcon = ri
end

if InfinityFactory then
    InfinityFactory:InitPool("RevMythicCastBar", "StatusBar", "BackdropTemplate", InitCastBarStructure)
end

local function AcquireBar()
    if not InfinityFactory then return end
    local bar = InfinityFactory:Acquire("RevMythicCastBar", anchorFrame)
    -- Key point: because of frame-pool reuse, preview markers must be cleared manually or live bars can stay stuck in preview state (for example 2.5s) during combat
    bar._isPreview = nil
    bar._isNotInt = nil
    if bar.RaidIcon then bar.RaidIcon:Hide() end
    UpdateBarVisuals(bar)
    return bar
end

local function ReleaseBar(bar)
    if not InfinityFactory or not bar then return end
    bar:SetScript("OnUpdate", nil)
    InfinityFactory:Release("RevMythicCastBar", bar)
end

UpdateCast = function(unit)
    if isPreviewing then return end


    -- Fix combat-state detection delay:

    local inCombat = UnitAffectingCombat(unit) or UnitExists(unit .. "target")
    if not inCombat and unit ~= "player" then
        local bar = activeBars[unit]
        if bar then
            activeBars[unit] = nil
            for i, b in ipairs(usedBarsList) do
                if b == bar then
                    table.remove(usedBarsList, i); break
                end
            end
            ReleaseBar(bar); ReLayout()
        end
        return
    end

    local objCast = UnitCastingDuration(unit)
    local objChannel = UnitChannelDuration(unit)
    local activeObj = objCast or objChannel
    local isChanneling = (objChannel ~= nil)

    if not activeObj then
        local bar = activeBars[unit]
        if bar then
            activeBars[unit] = nil
            for i, b in ipairs(usedBarsList) do
                if b == bar then
                    table.remove(usedBarsList, i); break
                end
            end
            ReleaseBar(bar)
            ReLayout()
        end
        return
    end

    local bar = activeBars[unit]
    if not bar then
        bar = AcquireBar()
        activeBars[unit] = bar
        table.insert(usedBarsList, bar)
        ReLayout()
    end

    local name, texture, notInterruptible;
    if isChanneling then
        name, _, texture, _, _, _, notInterruptible = UnitChannelInfo(unit)
    else
        name, _, texture, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    end

    if not name then return end

    local targetName = UnitSpellTargetName(unit)
    local finalTargetName = nil
    if targetName then
        local un = UnitName(targetName)
        if un then
            finalTargetName = un
        else
            finalTargetName = targetName
        end
    end
    local targetClass = UnitSpellTargetClass(unit)

    if MODULE_DB.mergeTargetIntoSpellName then
        bar.Text:SetText(BuildMergedSpellText(name, finalTargetName, targetClass))
    else
        bar.Text:SetText(name)
    end
    bar.Icon:SetTexture(texture)

    -- 12.0 adaptation: show raid markers (Raid Icon)
    -- In 12.0, GetRaidTargetIndex returns a Secret Number
    local raidIndex = GetRaidTargetIndex(unit)
    if raidIndex and bar.RaidIcon and MODULE_DB.showRaidIcon then
        bar.RaidIcon:Show()
        -- Use the 12.0-specific API to safely set the sprite sheet cell from the secret index (4x4 layout)
        bar.RaidIcon:SetSpriteSheetCell(raidIndex, 4, 4)
    else
        if bar.RaidIcon then bar.RaidIcon:Hide() end
    end

    if notInterruptible == nil then notInterruptible = false end

    local sbTex = bar:GetStatusBarTexture()
    if sbTex then
        -- Adaptation for 12.0 Secret Boolean: never perform boolean tests on notInterruptible in Lua
        local nrR, nrG, nrB, nrA = GetColor("nonInterruptColor")
        local intColor = CreateColor(nrR, nrG, nrB, nrA)

        local group = MODULE_DB.timerGroup
        local normColor = CreateColor(
            group.barColorR or 1,
            group.barColorG or 0.7,
            group.barColorB or 0,
            group.barColorA or 1
        )

        -- Use the 12.0-safe API, which handles Secret Boolean logic internally
        sbTex:SetVertexColorFromBoolean(notInterruptible, intColor, normColor)
    end

    if bar.SetTimerDuration then
        bar:SetTimerDuration(activeObj, Enum.StatusBarInterpolation.None, (isChanneling and 1 or 0))
    end

    -- Advanced time-text update logic (continuously refreshed through OnUpdate)
    if bar.TimerText and MODULE_DB.showTimer and not bar._isPreview then
        bar:SetScript("OnUpdate", function(self)
            local duration = self:GetTimerDuration()
            if duration then
                -- 12.0 adaptation: GetRemainingDuration() returns a secret number
                -- Do not use math.max or similar numeric functions on it; pass it straight to string.format instead
                local remaining = duration:GetRemainingDuration()
                self.TimerText:SetText(string.format("%.1f", remaining))
            else
                self.TimerText:SetText("")
                self:SetScript("OnUpdate", nil)
            end
        end)
    else
        if bar.TimerText and not bar._isPreview then bar.TimerText:SetText("") end
        bar:SetScript("OnUpdate", nil)
    end

    if bar.TargetNameText and (MODULE_DB.showTarget or MODULE_DB.mergeTargetIntoSpellName) then
        local shouldShow = false
        if UnitShouldDisplaySpellTargetName then
            shouldShow = UnitShouldDisplaySpellTargetName(unit)
        else
            shouldShow = finalTargetName ~= nil
        end

        if MODULE_DB.mergeTargetIntoSpellName then
            bar.TargetNameText:SetText("")
            bar.TargetNameText:Hide()
        else
            bar.TargetNameText:SetText(finalTargetName)

            local c = nil
            if targetClass then
                c = C_ClassColor.GetClassColor(targetClass)
            end
            if c then
                bar.TargetNameText:SetTextColor(c.r, c.g, c.b, 1)
            else
                bar.TargetNameText:SetTextColor(GetColor("textColor"))
            end
            bar.TargetNameText:SetShown(shouldShow and MODULE_DB.showTarget)
        end
    else
        if bar.TargetNameText then bar.TargetNameText:Hide() end
    end
end

local function CreateAnchor()
    if anchorFrame then return end
    anchorFrame = CreateFrame("Frame", "RevMythicCastAnchor", UIParent)
    anchorFrame:SetSize(200, 20)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
    anchorFrame:SetMovable(true); anchorFrame:SetClampedToScreen(true); anchorFrame:RegisterForDrag("LeftButton")
    anchorFrame.bg = anchorFrame:CreateTexture(nil, "BACKGROUND")
    -- [Fix] Remove SetAllPoints and let ReLayout dynamically control the background expansion direction
    anchorFrame.bg:SetColorTexture(0, 1, 0, 0.5)
    anchorFrame.label = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFrame.label:SetPoint("CENTER")
    anchorFrame.label:SetText(L["M+ Cast Monitor"])

    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, anchorFrame)

    -- [v4.7 Fix] Ensure anchor click detection works properly and dragging stops correctly
    anchorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not MODULE_DB.locked then
            self.isMoving = true
            self:StartMoving()
        end
    end)

    anchorFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self.isMoving = false
            self:StopMovingOrSizing()
            SaveAnchorPosition() -- Use unified save logic
        end
    end)
    RefreshAll()
end

function TogglePreview(enable)
    isPreviewing = enable
    if enable then
        -- [v3.1 Fix] Automatically enable dragging in preview mode
        if anchorFrame then
            anchorFrame:EnableMouse(true)
            anchorFrame.bg:Show()
            anchorFrame.label:Show()
        end

        for _, bar in pairs(activeBars) do bar:Hide() end
        -- Always clean up and return old preview bars to the pool so the count and settings stay aligned
        for i = #previewBars, 1, -1 do
            local bar = previewBars[i]
            bar:Hide()
            ReleaseBar(bar)
            table.remove(previewBars, i)
        end

        local nrR, nrG, nrB, nrA = GetColor("nonInterruptColor")
        local intColor = CreateColor(nrR, nrG, nrB, nrA)
        local group = MODULE_DB.timerGroup
        local normColor = CreateColor(
            group.barColorR or 1,
            group.barColorG or 0.7,
            group.barColorB or 0,
            group.barColorA or 1
        )

        -- Generate previews based on the current max visible count
        local maxLimit = MODULE_DB.maxBars or 5
        for i = 1, maxLimit do
            local bar = AcquireBar()
            bar._isPreview = true
            -- [v4.3.17] Simulated markers cycle between 1 and 8
            bar._previewRaidIndex = (i - 1) % 8 + 1
            bar._isNotInt = (i % 2 == 1) -- Odd rows show “not interruptible” style for demo
            local previewSpellName = L["Test Cast "] .. i  -- TODO: missing key: L["Test Cast "]
            local previewTargetName = UnitName("player") or L["Player"]
            local _, previewClass = UnitClass("player")
            if MODULE_DB.mergeTargetIntoSpellName then
                bar.Text:SetText(BuildMergedSpellText(previewSpellName, previewTargetName, previewClass))
            else
                bar.Text:SetText(previewSpellName)
            end
            bar.Icon:SetTexture(136197)  -- Demo icon
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(0.5)

            -- [Fix] Refresh visuals immediately after setting preview markers so simulated raid markers remain visible
            UpdateBarVisuals(bar)

            -- Safely apply 12.0 preview colors
            local sbTex = bar:GetStatusBarTexture()
            if sbTex then
                sbTex:SetVertexColorFromBoolean(bar._isNotInt, intColor, normColor)
            end

            -- Demo target and time
            if bar.TargetNameText then
                if MODULE_DB.mergeTargetIntoSpellName then
                    bar.TargetNameText:SetText("")
                    bar.TargetNameText:Hide()
                else
                    bar.TargetNameText:SetText(UnitName("player"))
                    bar.TargetNameText:Show()
                end
            end
            if bar.TimerText then
                bar.TimerText:SetText(L["2.5s"])
                bar.TimerText:Show()
            end

            table.insert(previewBars, bar)
        end
    else
        -- Exit preview mode and clear simulated data
        for i = #previewBars, 1, -1 do
            local bar = previewBars[i]
            bar:Hide()
            ReleaseBar(bar)
            table.remove(previewBars, i)
        end
        for _, bar in pairs(activeBars) do UpdateCast(bar.unit) end

        -- [v3.1 Fix] Restore the lock state when leaving preview mode
        if anchorFrame then
            if MODULE_DB.locked then
                anchorFrame:EnableMouse(false)
                anchorFrame.bg:Hide()
                anchorFrame.label:Hide()
            else
                anchorFrame:EnableMouse(true)
                anchorFrame.bg:Show()
                anchorFrame.label:Show()
            end
        end
    end
    ReLayout()
end

-- =============================================================
-- Event handling and state management
-- =============================================================

local function OnEvent(event, unit)
    -- [Fix] Strict filtering: only monitor hostile nameplates, excluding the player and friendly/party units
    if not MODULE_DB.enabled or not unit then return end
    if not string.match(unit, "^nameplate%d+$") or UnitIsUnit(unit, "player") or not UnitCanAttack("player", unit) then
        return
    end
    UpdateCast(unit)
end

local function OnUnitRemoved(event, unit)
    local bar = activeBars[unit]
    if bar then
        activeBars[unit] = nil
        for i, b in ipairs(usedBarsList) do
            if b == bar then
                table.remove(usedBarsList, i); break
            end
        end
        ReleaseBar(bar); ReLayout()
    end
end

local areEventsEnabled = false

local function EnableEnvEvents()
    if areEventsEnabled then return end
    areEventsEnabled = true

    InfinityTools:RegisterEvent("NAME_PLATE_UNIT_ADDED", INFINITY_MODULE_KEY, OnEvent)
    InfinityTools:RegisterEvent("NAME_PLATE_UNIT_REMOVED", INFINITY_MODULE_KEY, OnUnitRemoved)

    local events = {
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
    }
    for _, e in ipairs(events) do
        InfinityTools:RegisterEvent(e, INFINITY_MODULE_KEY, OnEvent)
    end

    if InfinityTools.DebugMode then
        print("|cff00ff00[RevMplus.MythicCast]|r " .. L["Entered a 5-player instance. Cast monitor enabled."])
    end
end

local function DisableEnvEvents()
    if not areEventsEnabled then return end
    areEventsEnabled = false

    InfinityTools:UnregisterEvent("NAME_PLATE_UNIT_ADDED", INFINITY_MODULE_KEY)
    InfinityTools:UnregisterEvent("NAME_PLATE_UNIT_REMOVED", INFINITY_MODULE_KEY)

    local events = {
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"
    }
    for _, e in ipairs(events) do
        InfinityTools:UnregisterEvent(e, INFINITY_MODULE_KEY)
    end

    -- Full cleanup
    for unit, bar in pairs(activeBars) do
        ReleaseBar(bar)
    end
    activeBars = {}
    usedBarsList = {}
    ReLayout()
end

local function CheckEnvStatus()
    -- Core optimization: only register events in 5-player instances (party) when the module is enabled
    -- Note: State.InstanceType is maintained by InfinityState
    local isParty = (InfinityTools.State.InstanceType == "party")

    if isParty and MODULE_DB.enabled then
        EnableEnvEvents()
    else
        DisableEnvEvents()
    end
end

-- Watch InstanceType changes (entering/leaving instances)
InfinityTools:WatchState("InstanceType", INFINITY_MODULE_KEY, function(newType)
    CheckEnvStatus()
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    if info.key == "preview" then
        TogglePreview(MODULE_DB.preview)
    elseif info.key == "enabled" then
        if MODULE_DB.enabled then
            CreateAnchor(); RefreshAll()
        else
            if anchorFrame then anchorFrame:Hide() end
        end
        CheckEnvStatus() -- Also check on toggle changes
    else
        RefreshAll()
    end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if info.key == "btn_reset_pos" then
        MODULE_DB.posX, MODULE_DB.posY = 0, 100
        MODULE_DB.attachToCustom = false
        MODULE_DB.customAttachTarget = ""
        if anchorFrame then
            anchorFrame:ClearAllPoints(); anchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        end
        RefreshAll()
    elseif info.key == "btn_pick_frame" then
        StartFramePicker()
    end
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    -- [v4.3.18 Fix] Resolve persistence issues by forcing preview mode off when loading
    -- Because the frame syncs DB values after the script loads, it must be forcibly reset to false in the entering-world event
    MODULE_DB.preview = false
    MODULE_DB.locked = true

    C_Timer.After(1, function()
        CreateAnchor(); TogglePreview(false)
        RefreshAll()
        CheckEnvStatus() -- Initial check
    end)
end)

-- =============================================================
-- Global edit mode support
-- =============================================================
-- [v3.1 Added] Register the global edit mode callback
InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    if enabled then
        -- Enable edit mode: unlock position and enable preview
        MODULE_DB.locked = false
        MODULE_DB.preview = true
        TogglePreview(true)
        RefreshAll()
    else
        -- Disable edit mode: lock position and disable preview
        MODULE_DB.locked = true
        MODULE_DB.preview = false
        TogglePreview(false)
        RefreshAll()
    end
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)
