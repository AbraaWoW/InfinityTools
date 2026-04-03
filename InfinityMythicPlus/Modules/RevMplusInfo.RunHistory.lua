-- [[ Mythic+ Season Run History ]]
-- { Key = "RevMplusInfo.RunHistory", Name = "Mythic+ Season Run History", Desc = "View this season's completed Mythic+ run table.", Category = 2 },

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local InfinityState = InfinityTools.State
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

-- 1. Module key
local INFINITY_MODULE_KEY = "RevMplusInfo.RunHistory"

-- 2. Load guard
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local InfinityDB = _G.InfinityDB

-- 3. Data initialization
local EXMYRUN_DEFAULTS = {
    size = 16,
    outline = "OUTLINE",
    font = nil,
    filterThisWeek = false,
    filterTimed = false,
    point = "CENTER",
    relativePoint = "CENTER",
    xOfs = 0,
    yOfs = 0,
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, EXMYRUN_DEFAULTS)

-- =========================================================
-- [v4.2] Registration and configuration
-- =========================================================


-- 2. Grid layout
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 53, h = 2, label = L["M+ Run History"], labelSize = 25 },  -- TODO: missing key: L["M+ Run History"]
        { key = "desc", type = "description", x = 2, y = 5, w = 53, h = 1, label = L["Provides an on-demand detailed run history table. Use /emr to open it."] },
        { key = "open", type = "button", x = 2, y = 21, w = 21, h = 3, label = L["Open Run History"] },
        { key = "sub_filter", type = "subheader", x = 2, y = 8, w = 53, h = 1, label = L["Filters"], labelSize = 20 },
        { key = "filterThisWeek", type = "checkbox", x = 2, y = 11, w = 10, h = 2, label = L["This Week Only"] },
        { key = "filterTimed", type = "checkbox", x = 13, y = 11, w = 10, h = 2, label = L["Timed Runs Only"] },
        { key = "size", type = "slider", x = 2, y = 16, w = 21, h = 3, label = L["Font Size"], min = 10, max = 30 },  -- TODO: missing key: L["Font Size"]
        { key = "divider_1965", type = "divider", x = 2, y = 9, w = 53, h = 1, label = "" },
    }


    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

-- 3. Register immediately
REGISTER_LAYOUT()

-- Button event handling
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(data)
    if data.key == "open" then
        if _G.EXMYRUN and _G.EXMYRUN.ToggleWindow then _G.EXMYRUN:ToggleWindow() end
    end
end)

-- Database change listener (live UI refresh)
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function()
    -- [Fix] Refresh the DB reference after settings changes.
    MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, EXMYRUN_DEFAULTS)

    -- Refresh only while the window exists and is visible.
    if EXMYRUN.MainFrame and EXMYRUN.MainFrame:IsShown() then
        EXMYRUN:UpdateList()
    end
end)

-- =========================================================
-- Core logic
-- =========================================================
local EXMYRUN = {}
_G.EXMYRUN = EXMYRUN
-- Do not redefine MODULE_DB.WatchState here; use the global watcher only.

-- 5. Business logic
-- local EXMYRUN = {} -- [Fix] Removed duplicate definition

local LSM = LibStub("LibSharedMedia-3.0", true)
EXMYRUN.TimeOffset = 8
EXMYRUN.RowHeight = 25
EXMYRUN.FrameWidth = 700
EXMYRUN.FrameHeight = 600

EXMYRUN.MainFrame = nil
EXMYRUN.SortState = { key = "date", asc = false }

-- Helper functions
local function EXMYRUN_FormatTime(seconds)
    if not seconds then return "00:00" end
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function EXMYRUN_GetFormattedDate(completionDate)
    if not completionDate then return L["Unknown"], 0 end

    local adjustedYear = completionDate.year + 2000
    local adjustedMonth = completionDate.month + 1
    local adjustedDay = completionDate.day + 1
    local adjustedHour = completionDate.hour + EXMYRUN.TimeOffset
    local adjustedMinute = completionDate.minute

    if adjustedHour >= 24 then
        adjustedHour = adjustedHour - 24
        adjustedDay = adjustedDay + 1
    end

    local str = string.format("%02d/%02d %02d:%02d", adjustedMonth, adjustedDay, adjustedHour, adjustedMinute)
    local sortVal = adjustedYear * 100000000 + adjustedMonth * 1000000 + adjustedDay * 10000 + adjustedHour * 100 +
        adjustedMinute

    return str, sortVal
end

local function EXMYRUN_GetLevelColorHex(level)
    local colorMixin = C_ChallengeMode.GetKeystoneLevelRarityColor(level)
    return colorMixin and colorMixin:GenerateHexColor() or "ffffffff"
end

-- UI construction
function EXMYRUN:CreateMainFrame()
    local f = CreateFrame("Frame", "EXMYRUNMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(self.FrameWidth, self.FrameHeight)

    if MODULE_DB.point then
        f:SetPoint(MODULE_DB.point, UIParent, MODULE_DB.relativePoint, MODULE_DB.xOfs, MODULE_DB.yOfs)
    else
        f:SetPoint("CENTER")
    end
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(f:GetFrameLevel() + 101)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        MODULE_DB.point = point
        MODULE_DB.relativePoint = relativePoint
        MODULE_DB.xOfs = xOfs
        MODULE_DB.yOfs = yOfs
    end)

    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.98)

    f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.Title:SetPoint("TOP", 0, -10)
    f.Title:SetText(L["M+ Run History"])

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-CloseButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-CloseButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-CloseButton-Highlight", "ADD")
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    do
        local nTex = closeBtn:GetNormalTexture()
        if nTex then nTex:SetVertexColor(1, 0.15, 0.15, 1) end
        local pTex = closeBtn:GetPushedTexture()
        if pTex then pTex:SetVertexColor(0.7, 0.05, 0.05, 1) end
    end

    local configBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    configBtn:SetSize(80, 22)
    configBtn:SetPoint("TOPLEFT", 10, -10)
    configBtn:SetText(L["Settings"])  -- TODO: missing key: L["Settings"]
    configBtn:SetScript("OnClick", function()
        if InfinityTools.UI then InfinityTools.UI:Toggle() end
    end)

    f.headers = {
        { key = "id", text = L["#"], width = 50, justify = "CENTER" },
        { key = "map", text = L["Dungeon (Level)"], width = 280, justify = "LEFT" },
        { key = "date", text = L["Date & Time"], width = 140, justify = "LEFT" },
        { key = "result", text = L["Result (Time)"], width = 250, justify = "LEFT" },
    }

    local currentX = 20
    local headerY = -45
    f.headerBtns = {}

    for _, col in ipairs(f.headers) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", currentX, headerY)
        btn:SetSize(col.width, 20)

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetAllPoints()
        text:SetJustifyH(col.justify)
        text:SetText(col.text)
        btn.textWidget = text
        btn.key = col.key
        btn.textData = col.text

        btn:SetScript("OnClick", function(self)
            if self.key == "result" then return end
            if EXMYRUN.SortState.key == self.key then
                EXMYRUN.SortState.asc = not EXMYRUN.SortState.asc
            else
                EXMYRUN.SortState.key = self.key
                EXMYRUN.SortState.asc = (self.key ~= "date")
            end
            EXMYRUN:UpdateList()
        end)

        table.insert(f.headerBtns, btn)
        currentX = currentX + col.width
    end

    f.Scroll = CreateFrame("ScrollFrame", "EXMYRUNHistoryScroll", f, "UIPanelScrollFrameTemplate")
    f.Scroll:SetPoint("TOPLEFT", 10, headerY - 25)
    f.Scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    f.ScrollChild = CreateFrame("Frame", nil, f.Scroll)
    f.ScrollChild:SetSize(self.FrameWidth - 40, 1)
    f.Scroll:SetScrollChild(f.ScrollChild)

    self.MainFrame = f
    f:Hide()
end

function EXMYRUN:UpdateList()
    if not self.MainFrame then return end

    local rawData = C_MythicPlus.GetRunHistory(true, true, false)
    local displayData = {}

    for i, run in ipairs(rawData) do
        local _, _, timeLimit = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
        local isTimed, isOverTime, hasData = false, false, false

        if run.durationSec and run.durationSec > 0 and timeLimit and timeLimit > 0 then
            hasData = true
            if run.durationSec <= timeLimit then
                isTimed = true
            else
                isOverTime = true
            end
        end

        local pass = true
        if MODULE_DB.filterThisWeek and not run.thisWeek then pass = false end
        if MODULE_DB.filterTimed and not isTimed then pass = false end

        if pass then
            run.originalIndex = i
            local mapName = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
            run.mapNameSort = mapName or ""
            local str, sortVal = EXMYRUN_GetFormattedDate(run.completionDate)
            run.dateStr = str
            run.dateSort = sortVal
            run.isTimed = isTimed
            run.isOverTime = isOverTime
            run.timeLimit = timeLimit
            run.hasData = hasData
            table.insert(displayData, run)
        end
    end

    -- [Safety] Keep the row list compact with no nil holes.
    local compactData = {}
    for _, v in pairs(displayData) do
        if v then table.insert(compactData, v) end
    end
    displayData = compactData

    table.sort(displayData, function(a, b)
        if not a or not b then return false end
        local k = self.SortState.key
        local asc = self.SortState.asc

        if k == "id" then
            if a.originalIndex == b.originalIndex then return false end
            if asc then return a.originalIndex < b.originalIndex else return a.originalIndex > b.originalIndex end
        elseif k == "map" then
            if a.mapNameSort ~= b.mapNameSort then
                if asc then return a.mapNameSort < b.mapNameSort else return a.mapNameSort > b.mapNameSort end
            end
            if a.level ~= b.level then return a.level > b.level end
            return a.originalIndex < b.originalIndex
        elseif k == "date" then
            local aSort = a.dateSort or 0
            local bSort = b.dateSort or 0
            if aSort ~= bSort then
                if asc then return aSort < bSort else return aSort > bSort end
            end
            return a.originalIndex < b.originalIndex
        end
        return a.originalIndex < b.originalIndex
    end)

    for _, btn in ipairs(self.MainFrame.headerBtns) do
        local arrow = ""
        if self.SortState.key == btn.key then
            arrow = self.SortState.asc and " |cff00ff00▲|r" or " |cff00ff00▼|r"
        end
        btn.textWidget:SetText(btn.textData .. arrow)
    end

    -- Track active rows so refresh can release them back to the pool.
    self.ActiveRows = self.ActiveRows or {}
    for _, row in ipairs(self.ActiveRows) do
        InfinityFactory:Release("StandardRow", row)
    end
    wipe(self.ActiveRows)

    local totalHeight = 0
    local fontPath = LSM and LSM:Fetch("font", MODULE_DB.font) or InfinityTools.MAIN_FONT

    for i, run in ipairs(displayData) do
        local row = InfinityFactory:Acquire("StandardRow", self.MainFrame.ScrollChild)
        table.insert(self.ActiveRows, row)

        row:Show()
        row:SetSize(self.FrameWidth - 40, MODULE_DB.size + 12)
        row:SetPoint("TOPLEFT", self.MainFrame.ScrollChild, "TOPLEFT", 0, -totalHeight)

        if i % 2 == 0 then row.bg:Show() else row.bg:Hide() end

        -- Configure column alignment and font. StandardRow exposes 5 cells.
        for idx, col in ipairs(self.MainFrame.headers) do
            local cell = row.cells[idx]
            if cell then
                cell:SetFont(fontPath, MODULE_DB.size, MODULE_DB.outline)
                cell:SetJustifyH(col.justify)
                -- Adjust horizontal offset dynamically.
                local xOfs = 10
                for prevIdx = 1, idx - 1 do
                    xOfs = xOfs + self.MainFrame.headers[prevIdx].width
                end
                cell:SetPoint("LEFT", row, "LEFT", xOfs, 0)
                cell:SetWidth(col.width)
            end
        end

        row.cells[1]:SetText(run.originalIndex)
        local mapName, _, _, texture = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
        -- Apply the standard 0.08-0.92 crop for inline icons (5:59 in 64px space).
        local icon = texture and ("|T" .. texture .. ":" .. MODULE_DB.size .. ":" .. MODULE_DB.size .. ":0:0:64:64:5:59:5:59|t ") or
            ""
        local color = EXMYRUN_GetLevelColorHex(run.level)
        row.cells[2]:SetText(icon .. "|c" .. color .. (mapName or L["Unknown Dungeon"]) .. " (+" .. run.level .. ")|r")
        row.cells[3]:SetText(run.dateStr)

        local res = "|cff999999" .. L["No Time Data"] .. "|r"
        if run.hasData then
            local diff = math.abs(run.durationSec - run.timeLimit)
            local diffStr = EXMYRUN_FormatTime(diff)
            if run.isTimed then
                res = string.format("|cff00ff00" .. L["Timed (%s left)"] .. "|r", diffStr)
            elseif run.isOverTime then
                res = string.format("|cffff0000" .. L["Overtime (%s over)"] .. "|r", diffStr)
            end
        end
        row.cells[4]:SetText(res)

        totalHeight = totalHeight + (MODULE_DB.size + 12)
    end
    self.MainFrame.ScrollChild:SetHeight(totalHeight)
end

function EXMYRUN:ToggleWindow()
    if not self.MainFrame then
        self:CreateMainFrame()
    end
    if self.MainFrame:IsShown() then
        self.MainFrame:Hide()
    else
        self.MainFrame:Show()
        self:UpdateList()
    end
end

-- Register slash command
SLASH_EXMYRUN1 = "/emr"
SLASH_EXMYRUN2 = "/exmythicrun"
SlashCmdList["EXMYRUN"] = function()
    EXMYRUN:ToggleWindow()
end

-- Report module ready
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

