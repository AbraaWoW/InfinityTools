-- =============================================================
-- [[ Brewmaster Stagger Monitor ]]
-- { Key = "RevClass.BrewmasterStagger", Name = "Brewmaster Stagger Monitor", Desc = "Shows Brewmaster Monk stagger as a configurable percentage bar.", Category = 4 },
-- =============================================================

local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end

local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local MODULE_KEY = "RevClass.BrewmasterStagger"
local BREWMASTER_SPEC_ID = 268
local STAGGER_SPELL_ID = 115069

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local anchorFrame
local staggerBar
local isPreviewing = false

local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 53, h = 2, label = L["Brewmaster Stagger Monitor"], labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 53, h = 2, label = L["Shows current stagger as a percentage of max health with configurable thresholds, bar style, and text options."] },

        { key = "subheader_general", type = "subheader", x = 1, y = 7, w = 53, h = 1, label = L["General Settings"], labelSize = 20 },
        { key = "div_general", type = "divider", x = 1, y = 8, w = 53, h = 1, label = "--[[ Function ]]" },
        { key = "enabled", type = "checkbox", x = 1, y = 9, w = 8, h = 2, label = L["Enable"] },
        { key = "locked", type = "checkbox", x = 11, y = 9, w = 8, h = 2, label = L["Lock Position"] },
        { key = "preview", type = "checkbox", x = 21, y = 9, w = 8, h = 2, label = L["Preview"] },
        { key = "showText", type = "checkbox", x = 31, y = 9, w = 10, h = 2, label = L["Show Text"] },
        { key = "textColorFollowsBar", type = "checkbox", x = 1, y = 16, w = 18, h = 2, label = L["Text Color Follows Bar"] },
        { key = "btn_reset_pos", type = "button", x = 41, y = 9, w = 12, h = 2, label = L["Reset Position"] },
        { key = "posX", type = "slider", x = 1, y = 13, w = 15, h = 2, label = L["Position X"], min = -1000, max = 1000, step = 1 },
        { key = "posY", type = "slider", x = 19, y = 13, w = 15, h = 2, label = L["Position Y"], min = -1000, max = 1000, step = 1 },
        { key = "textAlign", type = "dropdown", x = 37, y = 13, w = 16, h = 2, label = L["Text Alignment"], items = "LEFT,CENTER,RIGHT" },

        { key = "subheader_threshold", type = "subheader", x = 1, y = 18, w = 53, h = 1, label = L["Thresholds"], labelSize = 20 },
        { key = "div_threshold", type = "divider", x = 1, y = 19, w = 53, h = 1, label = "--[[ Threshold ]]" },
        { key = "fullBarPercent", type = "slider", x = 1, y = 21, w = 16, h = 2, label = L["Full Bar Cap (%)"], min = 50, max = 500, step = 1, labelPos = "top" },
        { key = "desc_cap", type = "description", x = 17, y = 21, w = 34, h = 2, label = L["The fill cap and color thresholds are independent. Below all thresholds, the bar uses the base bar color from Bar Appearance."] },
        { key = "warningEnabled", type = "checkbox", x = 1, y = 25, w = 8, h = 2, label = L["Enable"] },
        { key = "warningThresholdValue", type = "input", x = 10, y = 25, w = 11, h = 2, label = L["Above (%)"], labelPos = "top" },
        { key = "warningColor", type = "color", x = 23, y = 25, w = 12, h = 2, label = L["Color 1"] },
        { key = "dangerEnabled", type = "checkbox", x = 1, y = 29, w = 8, h = 2, label = L["Enable"] },
        { key = "dangerThresholdValue", type = "input", x = 10, y = 29, w = 11, h = 2, label = L["Above (%)"], labelPos = "top" },
        { key = "dangerColor", type = "color", x = 23, y = 29, w = 12, h = 2, label = L["Color 2"] },
        { key = "extraColor1Enabled", type = "checkbox", x = 1, y = 33, w = 8, h = 2, label = L["Enable"] },
        { key = "extraColor1ThresholdValue", type = "input", x = 10, y = 33, w = 11, h = 2, label = L["Above (%)"], labelPos = "top" },
        { key = "extraColor1", type = "color", x = 23, y = 33, w = 12, h = 2, label = L["Color 3"] },
        { key = "extraColor2Enabled", type = "checkbox", x = 1, y = 37, w = 8, h = 2, label = L["Enable"] },
        { key = "extraColor2ThresholdValue", type = "input", x = 10, y = 37, w = 11, h = 2, label = L["Above (%)"], labelPos = "top" },
        { key = "extraColor2", type = "color", x = 23, y = 37, w = 12, h = 2, label = L["Color 4"] },

        { key = "subheader_bar", type = "subheader", x = 1, y = 42, w = 53, h = 1, label = L["Bar Appearance"], labelSize = 20 },
        { key = "div_bar", type = "divider", x = 1, y = 43, w = 53, h = 1, label = "--[[ Bar ]]" },
        { key = "timerGroup", type = "timerBarGroup", x = 1, y = 45, w = 53, h = 26, label = L["Stagger Bar"], labelSize = 20 },

        { key = "font_text_header", type = "header", x = 1, y = 72, w = 53, h = 2, label = L["Text Settings"], labelSize = 20 },
        { key = "font_text", type = "fontgroup", x = 1, y = 76, w = 53, h = 17, label = L["Stagger Text"], labelSize = 20 },
    }

    InfinityTools:RegisterModuleLayout(MODULE_KEY, layout)
end

REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(MODULE_KEY) then return end

local MODULE_DEFAULTS = {
    enabled = false,
    locked = true,
    preview = false,
    showText = true,
    textColorFollowsBar = false,
    textAlign = "CENTER",
    posX = -8,
    posY = -107,
    fullBarPercent = 200,

    warningEnabled = true,
    warningThresholdValue = "70",
    warningColorR = 0.98823535442352,
    warningColorG = 1,
    warningColorB = 0,
    warningColorA = 1,

    dangerEnabled = true,
    dangerThresholdValue = "140",
    dangerColorR = 1,
    dangerColorG = 0.054901964962482,
    dangerColorB = 0.11372549831867,
    dangerColorA = 1,

    extraColor1Enabled = true,
    extraColor1ThresholdValue = "180",
    extraColor1R = 1,
    extraColor1G = 0.11372549831867,
    extraColor1B = 0.96470594406128,
    extraColor1A = 1,

    extraColor2Enabled = false,
    extraColor2ThresholdValue = "300",
    extraColor2R = 0.75,
    extraColor2G = 0.2,
    extraColor2B = 1,
    extraColor2A = 1,

    font_text = {
        font = "Default",
        size = 16,
        outline = "OUTLINE",
        shadow = false,
        shadowX = 1,
        shadowY = -1,
        r = 1,
        g = 1,
        b = 1,
        a = 1,
        x = 0,
        y = 0,
    },

    timerGroup = {
        width = 240,
        height = 35,
        texture = "Melli",
        barColorR = 0.52,
        barColorG = 1,
        barColorB = 0.52,
        barColorA = 1,
        barBgColorR = 0,
        barBgColorG = 0,
        barBgColorB = 0,
        barBgColorA = 0.55,
        showBorder = true,
        borderTexture = "1 Pixel",
        borderSize = 1,
        borderPadding = 1,
        borderColorR = 0.070588238537312,
        borderColorG = 0.082352943718433,
        borderColorB = 0.070588238537312,
        borderColorA = 1,
        showIcon = true,
        iconSide = "LEFT",
        iconSize = 26,
        iconOffsetX = -2,
        iconOffsetY = 0,
    },
}

local MODULE_DB = InfinityTools:GetModuleDB(MODULE_KEY, MODULE_DEFAULTS)

local function GetColor(prefix)
    local r = MODULE_DB[prefix .. "R"]
    local g = MODULE_DB[prefix .. "G"]
    local b = MODULE_DB[prefix .. "B"]
    local a = MODULE_DB[prefix .. "A"]
    local packed = MODULE_DB[prefix]

    if r == nil and type(packed) == "table" then
        return packed.r or 1, packed.g or 1, packed.b or 1, packed.a or 1
    end

    return r or 1, g or 1, b or 1, a or 1
end

local function GetStatusBarTexture()
    local textureName = MODULE_DB.timerGroup and MODULE_DB.timerGroup.texture
    if LSM and textureName then
        local texturePath = LSM:Fetch("statusbar", textureName)
        if texturePath then
            return texturePath
        end
    end
    return "Interface\\Buttons\\WHITE8X8"
end

local function GetBorderTexture()
    local group = MODULE_DB.timerGroup or {}
    if not group.showBorder or not LSM or not group.borderTexture or group.borderTexture == "None" then
        return nil
    end
    return LSM:Fetch("border", group.borderTexture)
end

local function ParseThreshold(rawValue)
    local value = tonumber(rawValue)
    if not value then
        return nil
    end
    return math.max(0, value)
end

local function GetBarBaseColor()
    local group = MODULE_DB.timerGroup or {}
    return group.barColorR or 0.52, group.barColorG or 1, group.barColorB or 0.52, group.barColorA or 1
end

local function BuildThresholdRules()
    local rules = {}

    local function AddRule(enabledKey, thresholdKey, colorKey)
        if not MODULE_DB[enabledKey] then
            return
        end

        local threshold = ParseThreshold(MODULE_DB[thresholdKey])
        if not threshold then
            return
        end

        rules[#rules + 1] = {
            threshold = threshold,
            colorKey = colorKey,
        }
    end

    AddRule("warningEnabled", "warningThresholdValue", "warningColor")
    AddRule("dangerEnabled", "dangerThresholdValue", "dangerColor")
    AddRule("extraColor1Enabled", "extraColor1ThresholdValue", "extraColor1")
    AddRule("extraColor2Enabled", "extraColor2ThresholdValue", "extraColor2")

    table.sort(rules, function(left, right)
        return left.threshold > right.threshold
    end)

    return rules
end

local function GetDisplayColor(percent)
    local rules = BuildThresholdRules()
    for i = 1, #rules do
        if percent >= rules[i].threshold then
            return GetColor(rules[i].colorKey)
        end
    end
    return GetBarBaseColor()
end

local function GetPreviewPercent()
    local fullBarPercent = math.max(1, MODULE_DB.fullBarPercent or 100)
    local targetPercent = fullBarPercent * 0.6
    local rules = BuildThresholdRules()

    if rules[1] and rules[1].threshold then
        targetPercent = math.max(targetPercent, rules[1].threshold + 10)
    end

    return math.min(targetPercent, fullBarPercent)
end

local function IsBrewmasterActive()
    local state = InfinityTools.State or {}
    if state.SpecID == BREWMASTER_SPEC_ID then
        return true
    end

    local _, classTag = UnitClass("player")
    if classTag ~= "MONK" then
        return false
    end

    local specIndex = GetSpecialization and GetSpecialization()
    local specID = specIndex and GetSpecializationInfo and GetSpecializationInfo(specIndex)
    return specID == BREWMASTER_SPEC_ID
end

local function GetStaggerIcon()
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(STAGGER_SPELL_ID) or 608951
    end
    if GetSpellTexture then
        return GetSpellTexture(STAGGER_SPELL_ID) or 608951
    end
    return 608951
end

local function BuildStaggerSnapshot(forcedPercent)
    local fullBarPercent = math.max(1, MODULE_DB.fullBarPercent or 100)

    if type(forcedPercent) == "number" then
        return {
            percent = forcedPercent,
            value = math.min(forcedPercent, fullBarPercent),
            maxValue = fullBarPercent,
        }
    end

    local maxHealth = UnitHealthMax("player") or 0
    local staggerValue = UnitStagger("player") or 0
    local percent = 0
    local capValue = 1

    if maxHealth > 0 then
        percent = (staggerValue / maxHealth) * 100
        capValue = maxHealth * (fullBarPercent / 100)
    end

    return {
        percent = percent,
        value = math.min(staggerValue, capValue),
        maxValue = math.max(1, capValue),
    }
end

local function SaveAnchorPosition()
    if not anchorFrame then
        return
    end

    local uiCenterX, uiCenterY = UIParent:GetCenter()
    local frameCenterX, frameCenterY = anchorFrame:GetCenter()
    if not uiCenterX or not uiCenterY or not frameCenterX or not frameCenterY then
        return
    end

    local scale = anchorFrame:GetScale() or 1
    MODULE_DB.posX = math.floor(frameCenterX * scale - uiCenterX + 0.5)
    MODULE_DB.posY = math.floor(frameCenterY * scale - uiCenterY + 0.5)
end

local function ApplyFontSettings()
    if not staggerBar or not staggerBar.ValueText then
        return
    end

    if InfinityDB and InfinityDB.ApplyFont then
        InfinityDB:ApplyFont(staggerBar.ValueText, MODULE_DB.font_text)
    end

    local align = MODULE_DB.textAlign or "CENTER"
    local fontDB = MODULE_DB.font_text or {}
    staggerBar.ValueText:ClearAllPoints()
    staggerBar.ValueText:SetPoint(align, staggerBar, align, fontDB.x or 0, fontDB.y or 0)
    staggerBar.ValueText:SetJustifyH(align)
end

local function ApplyFrameStyle()
    if not anchorFrame or not staggerBar then
        return
    end

    local group = MODULE_DB.timerGroup or {}
    local width = group.width or 240
    local height = group.height or 35
    local barTexture = GetStatusBarTexture()
    local borderTexture = GetBorderTexture()
    local showHandle = isPreviewing or not MODULE_DB.locked

    anchorFrame:SetSize(width, height)
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX or 0, MODULE_DB.posY or 0)
    anchorFrame:EnableMouse(showHandle)
    anchorFrame.EditBackground:SetShown(showHandle)
    anchorFrame.EditLabel:SetShown(showHandle)

    staggerBar:SetSize(width, height)
    staggerBar:SetStatusBarTexture(barTexture)
    staggerBar.Background:SetTexture(barTexture)
    staggerBar.Background:SetVertexColor(
        group.barBgColorR or 0,
        group.barBgColorG or 0,
        group.barBgColorB or 0,
        group.barBgColorA or 0.55
    )

    if borderTexture then
        local padding = group.borderPadding or 0
        staggerBar.BorderFrame:ClearAllPoints()
        staggerBar.BorderFrame:SetPoint("TOPLEFT", staggerBar, "TOPLEFT", -padding, padding)
        staggerBar.BorderFrame:SetPoint("BOTTOMRIGHT", staggerBar, "BOTTOMRIGHT", padding, -padding)
        staggerBar.BorderFrame:SetBackdrop({
            edgeFile = borderTexture,
            edgeSize = group.borderSize or 1,
        })
        staggerBar.BorderFrame:SetBackdropBorderColor(
            group.borderColorR or 1,
            group.borderColorG or 1,
            group.borderColorB or 1,
            group.borderColorA or 1
        )
        staggerBar.BorderFrame:Show()
    else
        staggerBar.BorderFrame:Hide()
    end

    if group.showIcon then
        local iconSize = group.iconSize or height
        local iconSide = group.iconSide == "RIGHT" and "RIGHT" or "LEFT"
        local iconX = group.iconOffsetX or 0
        local iconY = group.iconOffsetY or 0

        staggerBar.Icon:SetTexture(GetStaggerIcon())
        staggerBar.Icon:SetSize(iconSize, iconSize)
        staggerBar.Icon:ClearAllPoints()
        if iconSide == "RIGHT" then
            staggerBar.Icon:SetPoint("RIGHT", staggerBar, "RIGHT", iconX, iconY)
        else
            staggerBar.Icon:SetPoint("LEFT", staggerBar, "LEFT", iconX, iconY)
        end
        staggerBar.Icon:Show()
    else
        staggerBar.Icon:Hide()
    end

    staggerBar.ValueText:SetShown(MODULE_DB.showText)
    ApplyFontSettings()
end

local function ApplySnapshot(snapshot)
    if not staggerBar or not snapshot then
        return
    end

    local percent = snapshot.percent or 0
    staggerBar:SetMinMaxValues(0, math.max(1, snapshot.maxValue or 1))
    staggerBar:SetValue(math.max(0, snapshot.value or 0))

    local r, g, b, a = GetDisplayColor(percent)
    staggerBar:SetStatusBarColor(r, g, b, a or 1)

    if MODULE_DB.showText then
        staggerBar.ValueText:SetText(string.format("%.0f%%", percent))
        if MODULE_DB.textColorFollowsBar then
            staggerBar.ValueText:SetTextColor(r, g, b, a or 1)
        else
            local fontDB = MODULE_DB.font_text or {}
            staggerBar.ValueText:SetTextColor(fontDB.r or 1, fontDB.g or 1, fontDB.b or 1, fontDB.a or 1)
        end
        staggerBar.ValueText:Show()
    else
        staggerBar.ValueText:SetText("")
        staggerBar.ValueText:Hide()
    end
end

local function EnsureFrame()
    if anchorFrame then
        return
    end

    anchorFrame = CreateFrame("Frame", "InfinityBrewmasterStaggerAnchor", UIParent)
    anchorFrame:SetSize(240, 35)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX or 0, MODULE_DB.posY or 0)
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(true)

    anchorFrame.EditBackground = anchorFrame:CreateTexture(nil, "BACKGROUND")
    anchorFrame.EditBackground:SetAllPoints(anchorFrame)
    anchorFrame.EditBackground:SetColorTexture(0, 1, 0, 0.35)
    anchorFrame.EditBackground:Hide()

    anchorFrame.EditLabel = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFrame.EditLabel:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
    anchorFrame.EditLabel:SetText(L["Brewmaster Stagger Monitor"])
    anchorFrame.EditLabel:Hide()

    staggerBar = CreateFrame("StatusBar", "InfinityBrewmasterStaggerBar", anchorFrame, "BackdropTemplate")
    staggerBar:SetAllPoints(anchorFrame)
    staggerBar:SetMinMaxValues(0, 100)
    staggerBar:SetValue(0)

    staggerBar.Background = staggerBar:CreateTexture(nil, "BACKGROUND")
    staggerBar.Background:SetAllPoints(staggerBar)

    staggerBar.Icon = staggerBar:CreateTexture(nil, "OVERLAY")

    staggerBar.ValueText = staggerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    staggerBar.ValueText:SetPoint("CENTER", staggerBar, "CENTER", 0, 0)

    staggerBar.BorderFrame = CreateFrame("Frame", nil, staggerBar, "BackdropTemplate")
    staggerBar.BorderFrame:SetFrameLevel(staggerBar:GetFrameLevel() + 1)

    anchorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and (isPreviewing or not MODULE_DB.locked) then
            self:StartMoving()
            self._moving = true
        end
    end)

    anchorFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self._moving then
            self._moving = false
            self:StopMovingOrSizing()
            SaveAnchorPosition()
            if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() then
                InfinityTools.UI:RefreshContent()
            end
            ApplyFrameStyle()
        end
    end)

    InfinityTools:RegisterHUD(MODULE_KEY, anchorFrame)
end

local function SetPreviewEnabled(enabled)
    isPreviewing = enabled and true or false
    MODULE_DB.preview = isPreviewing
end

local function RefreshBar()
    EnsureFrame()
    ApplyFrameStyle()

    if isPreviewing then
        anchorFrame:Show()
        ApplySnapshot(BuildStaggerSnapshot(GetPreviewPercent()))
        return
    end

    if not MODULE_DB.enabled or not IsBrewmasterActive() then
        anchorFrame:Hide()
        return
    end

    anchorFrame:Show()
    ApplySnapshot(BuildStaggerSnapshot())
end

InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", MODULE_KEY, function(info)
    if type(info) ~= "table" then
        RefreshBar()
        return
    end

    if info.key == "preview" then
        SetPreviewEnabled(MODULE_DB.preview)
    end

    if info.key == "btn_reset_pos" then
        MODULE_DB.posX = -8
        MODULE_DB.posY = -107
    end

    RefreshBar()
end)

InfinityTools:WatchState(MODULE_KEY .. ".ButtonClicked", MODULE_KEY, function(info)
    if type(info) == "table" and info.key == "btn_reset_pos" then
        MODULE_DB.posX = -8
        MODULE_DB.posY = -107
        RefreshBar()
    end
end)

InfinityTools:WatchState("SpecID", MODULE_KEY, RefreshBar)
InfinityTools:WatchState("ClassID", MODULE_KEY, RefreshBar)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", MODULE_KEY, function()
    SetPreviewEnabled(false)
    C_Timer.After(1, RefreshBar)
end)

InfinityTools:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", MODULE_KEY, function(_, unit)
    if unit == "player" then
        RefreshBar()
    end
end)

InfinityTools:RegisterEvent("TRAIT_CONFIG_UPDATED", MODULE_KEY, RefreshBar)

InfinityTools:RegisterEvent("UNIT_MAXHEALTH", MODULE_KEY, function(_, unit)
    if unit == "player" then
        RefreshBar()
    end
end)

InfinityTools:RegisterEvent("UNIT_HEALTH", MODULE_KEY, function(_, unit)
    if unit == "player" then
        RefreshBar()
    end
end)

InfinityTools:RegisterEvent("UNIT_AURA", MODULE_KEY, function(_, unit)
    if unit == "player" then
        RefreshBar()
    end
end)

InfinityTools:RegisterEditModeCallback(MODULE_KEY, function(enabled)
    MODULE_DB.locked = not enabled
    SetPreviewEnabled(enabled)
    RefreshBar()
end)

C_Timer.After(2, RefreshBar)

InfinityTools:ReportReady(MODULE_KEY)
