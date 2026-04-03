local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
local InfinityExtrasDB = _G.InfinityExtrasDB
if not Core or not InfinityExtrasDB then
    return
end

local MODULE_KEY = "RRTTools.MythicDamage"
local DEFAULTS = {
    enabled = false,
    mythicLevel = 10,
    baseDamage = 100000,
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local frame
local floor = math.floor

local function GetMultiplier(level)
    local multipliers = InfinityExtrasDB.MythicDamageData and InfinityExtrasDB.MythicDamageData.LevelMultipliers or {}
    return multipliers[tonumber(level) or 0] or 1
end

local function EnsureFrame()
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", "RRTMythicDamageFrame", UIParent, "BackdropTemplate")
    frame:SetSize(320, 140)
    frame:SetPoint("CENTER", UIParent, "CENTER", 360, 40)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Mythic Damage")

    frame.levelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.levelText:SetPoint("TOPLEFT", 16, -42)

    frame.multiplierText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.multiplierText:SetPoint("TOPLEFT", 16, -66)

    frame.resultText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.resultText:SetPoint("TOPLEFT", 16, -98)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    frame:Hide()
    return frame
end

local function RefreshFrame()
    if not frame then
        return
    end

    local level = tonumber(DB.mythicLevel) or DEFAULTS.mythicLevel
    local base = tonumber(DB.baseDamage) or DEFAULTS.baseDamage
    local multiplier = GetMultiplier(level)
    local result = floor(base * multiplier + 0.5)

    frame.levelText:SetText(string.format("Level: +%d", level))
    frame.multiplierText:SetText(string.format("Multiplier: x%.2f", multiplier))
    frame.resultText:SetText(string.format("Estimated hit: %s", BreakUpLargeNumbers(result)))
end

RRT_NS.MythicDamage = {
    ToggleWindow = function()
        EnsureFrame()
        RefreshFrame()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    end,
    RefreshDisplay = function()
        DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
        RefreshFrame()
    end,
    GetMultiplier = GetMultiplier,
}
