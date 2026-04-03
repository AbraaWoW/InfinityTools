---@diagnostic disable: undefined-global, undefined-field, need-check-nil

InfinityBoss.UI.Panel.ConditionsPage = InfinityBoss.UI.Panel.ConditionsPage or {}
local Page = InfinityBoss.UI.Panel.ConditionsPage

local root
local widgets = {}
local quickRows = {}
local refreshElapsed = 0

local function EnsureGlobalDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.conditions = InfinityBossDB.conditions or {}
    if InfinityBossDB.conditions.enabled == nil then
        InfinityBossDB.conditions.enabled = false
    end
    return InfinityBossDB.conditions
end

local function GetEventConfigRoot()
    local api = _G.InfinityBossData
    if type(api) == "table" and type(api.GetEventOverrideRoot) == "function" then
        local ok, db = pcall(api.GetEventOverrideRoot)
        if ok and type(db) == "table" then
            return db
        end
    end
    return {}
end

local function CompactEventOverride(eventID)
    local api = _G.InfinityBossData
    if type(api) == "table" and type(api.CompactEventOverride) == "function" then
        pcall(api.CompactEventOverride, eventID)
    end
end

local function SafeNum(v, def)
    local n = tonumber(v)
    if n == nil then
        return def
    end
    return n
end

local function Bg(parent, r, g, b, a)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(r or 0.03, g or 0.04, b or 0.07, a or 0.92)
    f:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.95)
    return f
end

local function NewLabel(parent, text, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetJustifyH("LEFT")
    fs:SetText(text or "")
    return fs
end

local function NewEditBox(parent, width)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetAutoFocus(false)
    eb:SetSize(width or 120, 28)
    eb:SetTextInsets(6, 6, 0, 0)
    if eb.SetNumeric then
        eb:SetNumeric(false)
    end
    return eb
end

local function NewCheck(parent, text)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb.text = cb.text or _G[cb:GetName() and (cb:GetName() .. "Text") or ""]
    if not cb.text then
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    end
    cb.text:SetText(text or "")
    return cb
end

local function EnsureRule(eventID)
    eventID = tonumber(eventID)
    if not eventID then
        return nil
    end
    local rootDB = GetEventConfigRoot()
    rootDB[eventID] = rootDB[eventID] or {}
    rootDB[eventID].rules = rootDB[eventID].rules or {}
    rootDB[eventID].rules.castWindow = rootDB[eventID].rules.castWindow or {
        enabled = false,
        windowBefore = 2,
        windowAfter = 2,
        ringEnabled = true,
    }
    return rootDB[eventID].rules.castWindow
end

local function LoadEventRule(eventID)
    local rule = EnsureRule(eventID)
    if not rule then
        return
    end
    widgets.eventID:SetText(tostring(eventID))
    widgets.ruleEnabled:SetChecked(rule.enabled == true)
    widgets.windowBefore:SetText(tostring(SafeNum(rule.windowBefore, 2)))
    widgets.windowAfter:SetText(tostring(SafeNum(rule.windowAfter, 2)))
    widgets.ringEnabled:SetChecked(rule.ringEnabled ~= false)
    widgets.status:SetText(string.format("|cff33ee77Loaded event %d|r", eventID))
end

local function SaveCurrentRule()
    local eventID = tonumber(widgets.eventID:GetText() or "")
    if not eventID then
        widgets.status:SetText("|cffff6666Invalid eventID|r")
        return
    end
    local rule = EnsureRule(eventID)
    if not rule then
        widgets.status:SetText("|cffff6666Write failed|r")
        return
    end
    rule.enabled = widgets.ruleEnabled:GetChecked() == true
    rule.windowBefore = math.max(0, SafeNum(widgets.windowBefore:GetText(), 2))
    rule.windowAfter = math.max(0, SafeNum(widgets.windowAfter:GetText(), 2))
    rule.ringEnabled = widgets.ringEnabled:GetChecked() == true
    CompactEventOverride(eventID)
    local Profiles = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Profiles
    if Profiles and Profiles.SaveEventToActiveProfile then
        Profiles:SaveEventToActiveProfile(eventID)
    end
    widgets.status:SetText(string.format("|cff33ee77Saved window rule for event %d|r", eventID))
end

local function BuildActiveEventRows()
    local scheduler = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
    local timers = scheduler and (scheduler.GetActiveTimers and scheduler:GetActiveTimers() or scheduler._active) or nil
    local seen = {}
    local out = {}
    if type(timers) == "table" then
        for _, timer in pairs(timers) do
            local eventID = tonumber(timer and timer.eventID)
            if eventID and not seen[eventID] then
                seen[eventID] = true
                out[#out + 1] = {
                    eventID = eventID,
                    name = tostring(timer.displayName or ("Event " .. tostring(eventID))),
                }
            end
        end
    end
    table.sort(out, function(a, b)
        return a.eventID < b.eventID
    end)
    return out
end

local function RefreshQuickList()
    if not widgets.quickList then
        return
    end

    local rows = BuildActiveEventRows()
    for i = 1, #quickRows do
        quickRows[i]:Hide()
    end

    if #rows == 0 then
        widgets.quickEmpty:Show()
        return
    end

    widgets.quickEmpty:Hide()
    local anchor = widgets.quickHeader
    for i = 1, #rows do
        local row = quickRows[i]
        if not row then
            row = CreateFrame("Button", nil, widgets.quickList, "BackdropTemplate")
            row:SetHeight(28)
            row:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 },
            })
            row:SetBackdropColor(0.04, 0.05, 0.08, 0.95)
            row:SetBackdropBorderColor(0.20, 0.23, 0.30, 0.95)
            row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
            row:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -8)

            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", row, "LEFT", 8, 0)
            fs:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            fs:SetJustifyH("LEFT")
            row.text = fs

            row:SetScript("OnClick", function(self)
                LoadEventRule(self._eventID)
            end)
            quickRows[i] = row
        else
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8 - (i - 1) * 34)
            row:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -8 - (i - 1) * 34)
        end
        row._eventID = rows[i].eventID
        row.text:SetText(string.format("[%d] %s", rows[i].eventID, rows[i].name))
        row:Show()
    end
end

local function RefreshMatchStatus()
    local rt = InfinityBoss and InfinityBoss.Condition and InfinityBoss.Condition.Runtime
    if not (rt and rt.GetLastMatch) then
        widgets.matchStatus:SetText("|cff888888No runtime state|r")
        return
    end
    local row = rt:GetLastMatch()
    if not row then
        widgets.matchStatus:SetText("|cff888888No window match active|r")
        return
    end
    widgets.matchStatus:SetText(string.format(
        "|cff33ee77Active|r  eventID:%s  event:%s  cast:%s  offset:%.2f  remain:%.1f",
        tostring(row.eventID or "?"),
        tostring(row.eventName or "?"),
        tostring(row.castName or "?"),
        tonumber(row.delta or 0),
        tonumber(row.castRemaining or 0)
    ))
end

local function CreateUI(parent)
    root = CreateFrame("Frame", nil, parent)
    root:SetAllPoints(parent)

    local header = NewLabel(root, "Condition System (v1)", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", root, "TOPLEFT", 18, -16)

    local desc = NewLabel(root,
        "Only one core rule is implemented: event end window + boss cast -> ring. Run this chain first; no WA-style universal conditions.",
        "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(980)

    local left = Bg(root, 0.03, 0.04, 0.07, 0.94)
    left:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
    left:SetSize(620, 300)

    local right = Bg(root, 0.03, 0.04, 0.07, 0.94)
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 14, 0)
    right:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -18, 18)

    local globalEnabled = NewCheck(left, "Enable Condition System")
    globalEnabled:SetPoint("TOPLEFT", left, "TOPLEFT", 12, -12)
    globalEnabled:SetChecked(EnsureGlobalDB().enabled == true)
    globalEnabled:SetScript("OnClick", function(self)
        EnsureGlobalDB().enabled = self:GetChecked() == true
    end)
    widgets.globalEnabled = globalEnabled

    local eventLabel = NewLabel(left, "eventID")
    eventLabel:SetPoint("TOPLEFT", globalEnabled, "BOTTOMLEFT", 4, -18)

    local eventID = NewEditBox(left, 120)
    if eventID.SetNumeric then
        eventID:SetNumeric(true)
    end
    eventID:SetPoint("LEFT", eventLabel, "RIGHT", 12, 0)
    widgets.eventID = eventID

    local loadBtn = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    loadBtn:SetSize(80, 24)
    loadBtn:SetPoint("LEFT", eventID, "RIGHT", 10, 0)
    loadBtn:SetText("Load")
    loadBtn:SetScript("OnClick", function()
        local id = tonumber(eventID:GetText() or "")
        if id then
            LoadEventRule(id)
        else
            widgets.status:SetText("|cffff6666Invalid eventID|r")
        end
    end)

    local ruleEnabled = NewCheck(left, "Enable \"Event End Window + Boss Cast\" Rule")
    ruleEnabled:SetPoint("TOPLEFT", eventLabel, "BOTTOMLEFT", -4, -18)
    widgets.ruleEnabled = ruleEnabled

    local beforeLabel = NewLabel(left, "Window Before (sec)")
    beforeLabel:SetPoint("TOPLEFT", ruleEnabled, "BOTTOMLEFT", 4, -18)
    local beforeBox = NewEditBox(left, 90)
    beforeBox:SetPoint("LEFT", beforeLabel, "RIGHT", 12, 0)
    widgets.windowBefore = beforeBox

    local afterLabel = NewLabel(left, "Window After (sec)")
    afterLabel:SetPoint("LEFT", beforeBox, "RIGHT", 24, 0)
    local afterBox = NewEditBox(left, 90)
    afterBox:SetPoint("LEFT", afterLabel, "RIGHT", 12, 0)
    widgets.windowAfter = afterBox

    local ringEnabled = NewCheck(left, "Show Ring on Match")
    ringEnabled:SetPoint("TOPLEFT", beforeLabel, "BOTTOMLEFT", -4, -18)
    widgets.ringEnabled = ringEnabled

    local saveBtn = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 24)
    saveBtn:SetPoint("TOPLEFT", ringEnabled, "BOTTOMLEFT", 4, -18)
    saveBtn:SetText("Save Rule")
    saveBtn:SetScript("OnClick", SaveCurrentRule)

    local status = NewLabel(left, "", "GameFontHighlightSmall")
    status:SetPoint("LEFT", saveBtn, "RIGHT", 12, 0)
    status:SetWidth(420)
    widgets.status = status

    local quickHeader = NewLabel(left, "Active Events (click to quick-load)", "GameFontNormal")
    quickHeader:SetPoint("TOPLEFT", saveBtn, "BOTTOMLEFT", 0, -18)
    widgets.quickHeader = quickHeader

    local quickList = CreateFrame("Frame", nil, left)
    quickList:SetPoint("TOPLEFT", quickHeader, "BOTTOMLEFT", 0, -8)
    quickList:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -12, 12)
    widgets.quickList = quickList

    local quickEmpty = NewLabel(quickList, "No active event timers. Enter combat or start a test.", "GameFontDisable")
    quickEmpty:SetPoint("TOPLEFT", quickList, "TOPLEFT", 0, 0)
    widgets.quickEmpty = quickEmpty

    local rightTitle = NewLabel(right, "Runtime Status", "GameFontNormal")
    rightTitle:SetPoint("TOPLEFT", right, "TOPLEFT", 12, -12)

    local matchStatus = NewLabel(right, "", "GameFontHighlightSmall")
    matchStatus:SetPoint("TOPLEFT", rightTitle, "BOTTOMLEFT", 0, -10)
    matchStatus:SetWidth(780)
    widgets.matchStatus = matchStatus

    local note = NewLabel(right,
        "Rule notes:\n1. Uses event end time as anchor\n2. Within [X sec before, Y sec after end] window\n3. If boss1-boss5 has an active cast/channel\n4. Display remaining cast time as ring progress\n\nNot yet implemented: countdown, center text, multi-condition trees, multi-action combos.",
        "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", matchStatus, "BOTTOMLEFT", 0, -16)
    note:SetWidth(760)

    root:SetScript("OnUpdate", function(_, elapsed)
        refreshElapsed = refreshElapsed + elapsed
        if refreshElapsed < 0.5 then
            return
        end
        refreshElapsed = 0
        RefreshQuickList()
        RefreshMatchStatus()
    end)
end

function Page:Hide()
    if root then
        root:Hide()
    end
end

function Page:Render(parent)
    if not root then
        CreateUI(parent)
    end
    root:Show()
    root:SetParent(parent)
    root:SetAllPoints(parent)
    RefreshQuickList()
    RefreshMatchStatus()
end
