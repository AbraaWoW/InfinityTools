local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

local MODULE_KEY = "RRTTools.RunHistory"
local DEFAULTS = {
    enabled = false,
    filterThisWeek = false,
    filterTimed = false,
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local frame
local rows = {}
local scrollOffset = 0
local visibleRows = 14
local floor = math.floor

local function GetMapName(mapID)
    local name = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(mapID)
    return name or ("Map " .. tostring(mapID or 0))
end

local function IsThisWeek(dateTable)
    if type(dateTable) ~= "table" then
        return false
    end
    local timestamp = time({
        year = (dateTable.year or 0) + 2000,
        month = (dateTable.month or 0) + 1,
        day = (dateTable.day or 0) + 1,
        hour = dateTable.hour or 0,
        min = dateTable.minute or 0,
    })
    return timestamp and (time() - timestamp) <= (7 * 24 * 60 * 60) or false
end

local function BuildHistory()
    local history = C_MythicPlus and C_MythicPlus.GetRunHistory and C_MythicPlus.GetRunHistory(false, true, true) or {}
    local list = {}

    for _, run in ipairs(history or {}) do
        if (not DB.filterTimed or run.wasCompletedInTime)
            and (not DB.filterThisWeek or IsThisWeek(run.completionDate)) then
            list[#list + 1] = run
        end
    end

    table.sort(list, function(a, b)
        local aLevel = a.level or 0
        local bLevel = b.level or 0
        if aLevel ~= bLevel then
            return aLevel > bLevel
        end
        return (a.mapChallengeModeID or 0) < (b.mapChallengeModeID or 0)
    end)

    return list
end

local function EnsureFrame()
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", "RRTRunHistoryFrame", UIParent, "BackdropTemplate")
    frame:SetSize(760, 460)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.02, 0.02, 0.02, 0.96)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        local maxOffset = math.max(#BuildHistory() - visibleRows, 0)
        scrollOffset = math.max(0, math.min(maxOffset, scrollOffset - delta))
        RRT_NS.RunHistory:RefreshDisplay()
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Run History")

    local headers = {
        { x = 20, text = "Dungeon" },
        { x = 300, text = "Level" },
        { x = 380, text = "Result" },
        { x = 500, text = "Time" },
        { x = 610, text = "Deaths" },
    }

    for _, header in ipairs(headers) do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", header.x, -40)
        label:SetText(header.text)
    end

    for i = 1, visibleRows do
        local row = CreateFrame("Frame", nil, frame)
        row:SetSize(710, 24)
        row:SetPoint("TOPLEFT", 18, -44 - (i * 26))

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(i % 2 == 0 and 0.09 or 0.06, 0.06, 0.06, 0.5)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 8, 0)
        row.text:SetPoint("RIGHT", -8, 0)
        row.text:SetJustifyH("LEFT")
        rows[i] = row
    end

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    frame:Hide()
    return frame
end

RRT_NS.RunHistory = {
    ToggleWindow = function()
        EnsureFrame()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
            RRT_NS.RunHistory:RefreshDisplay()
        end
    end,
    RefreshDisplay = function()
        DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
        if not frame then
            return
        end

        local history = BuildHistory()
        local maxOffset = math.max(#history - visibleRows, 0)
        scrollOffset = math.max(0, math.min(maxOffset, scrollOffset))

        for i = 1, visibleRows do
            local run = history[i + scrollOffset]
            local row = rows[i]
            if run then
                local result = run.wasCompletedInTime and "|cff33ff99Timed|r" or "|cffff6666Depleted|r"
                local durationSeconds = run.completionMilliseconds and floor(run.completionMilliseconds / 1000) or 0
                row.text:SetText(string.format("%s | +%d | %s | %s | %d",
                    GetMapName(run.mapChallengeModeID),
                    run.level or 0,
                    result,
                    SecondsToTime(durationSeconds),
                    run.deaths or 0))
                row:Show()
            else
                row:Hide()
            end
        end
    end,
}
