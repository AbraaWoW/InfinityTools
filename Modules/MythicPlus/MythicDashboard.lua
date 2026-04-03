local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

local MODULE_KEY = "RRTTools.MythicDashboard"
local DEFAULTS = {
    enabled = false,
}

Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local frame

local function GetSummary()
    local history = C_MythicPlus and C_MythicPlus.GetRunHistory and C_MythicPlus.GetRunHistory(false, true, true) or {}
    local score = C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary and C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    local runCount = #history
    local timedCount = 0
    local bestLevel = 0

    for _, run in ipairs(history) do
        if run.wasCompletedInTime then
            timedCount = timedCount + 1
        end
        bestLevel = math.max(bestLevel, run.level or 0)
    end

    return {
        score = score and floor(score.currentSeasonScore or 0) or 0,
        runCount = runCount,
        timedCount = timedCount,
        bestLevel = bestLevel,
    }
end

local function EnsureFrame()
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", "RRTMythicDashboardFrame", UIParent, "BackdropTemplate")
    frame:SetAllPoints(UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0.88)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -70)
    title:SetText("Mythic+ Dashboard")

    frame.cards = {}
    local labels = { "Score", "Best Key", "Runs", "Timed" }
    for i = 1, 4 do
        local card = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        card:SetSize(220, 120)
        card:SetPoint("TOPLEFT", 150 + ((i - 1) * 250), -180)
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        card:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        card:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        card.label = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.label:SetPoint("TOP", 0, -16)
        card.label:SetText(labels[i])

        card.value = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        card.value:SetPoint("CENTER")

        frame.cards[i] = card
    end

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -20, -20)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame:Hide()
    return frame
end

RRT_NS.MythicDashboard = {
    ToggleWindow = function()
        EnsureFrame()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
            RRT_NS.MythicDashboard:RefreshDisplay()
        end
    end,
    RefreshDisplay = function()
        if not frame then
            return
        end
        local summary = GetSummary()
        frame.cards[1].value:SetText(summary.score)
        frame.cards[2].value:SetText("+" .. summary.bestLevel)
        frame.cards[3].value:SetText(summary.runCount)
        frame.cards[4].value:SetText(summary.timedCount)
    end,
}
