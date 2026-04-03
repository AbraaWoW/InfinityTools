---@diagnostic disable: undefined-global, undefined-field, need-check-nil

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

InfinityBoss.UI.Panel.ImportExportPage = InfinityBoss.UI.Panel.ImportExportPage or {}
local Page = InfinityBoss.UI.Panel.ImportExportPage


local function Trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end


local BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local BACKDROP_SIMPLE = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = nil,
}
local TOOLTIP_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 20, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local THEME = {
    Background  = { 0.04, 0.04, 0.05, 0.98 },
    Border      = { 0.25, 0.25, 0.28, 1 },
    Primary     = { 0.64, 0.19, 0.79 },
    Success     = { 0.13, 0.77, 0.37 },
    Danger      = { 0.87, 0.26, 0.26 },
    TextMain    = { 0.9,  0.9,  0.9,  1 },
    TextSub     = { 0.6,  0.6,  0.65, 1 },
    TextDim     = { 0.4,  0.4,  0.45, 1 },
    CardBg      = { 0.18, 0.18, 0.22, 0.6 },
}


local function CreateSmallButton(parent, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(120, 28)
    btn:SetBackdrop(BACKDROP_SIMPLE)
    btn:SetBackdropColor(0.2, 0.2, 0.25, 0.9)
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject("GameFontNormal")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    fs:SetTextColor(unpack(THEME.TextMain))
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.3, 0.3, 0.35, 0.95) end)
    btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.2, 0.25, 0.9)  end)
    return btn
end


local function CreateActionButton(parent, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(180, 40)
    btn:SetBackdrop(BACKDROP)
    btn:SetBackdropColor(unpack(THEME.Primary))
    btn:SetBackdropBorderColor(0.5, 0.5, 0.55, 0.8)
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject("GameFontNormal")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    fs:SetTextColor(1, 1, 1, 1)
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(THEME.Primary[1]*1.3, THEME.Primary[2]*1.3, THEME.Primary[3]*1.3, 1)
        self:SetBackdropBorderColor(0.8, 0.5, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(THEME.Primary))
        self:SetBackdropBorderColor(0.5, 0.5, 0.55, 0.8)
    end)
    return btn
end


local function CreateMultiLineEditBox(parent, w, h)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(w, h)
    container:SetBackdrop(TOOLTIP_BACKDROP)
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    local sf = CreateFrame("ScrollFrame", nil, container, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(sf)
    end
    sf:SetPoint("TOPLEFT",     container, "TOPLEFT",     5, -5)
    sf:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -25, 5)

    local scrollContent = CreateFrame("Frame", nil, sf)
    scrollContent:SetSize(w - 30, 2000)
    sf:SetScrollChild(scrollContent)

    local eb = CreateFrame("EditBox", nil, scrollContent)
    eb:SetPoint("TOPLEFT",  scrollContent, "TOPLEFT",  0, 0)
    eb:SetPoint("TOPRIGHT", scrollContent, "TOPRIGHT", 0, 0)
    eb:SetHeight(2000)
    eb:SetMultiLine(true)
    eb:SetTextInsets(8, 8, 8, 8)
    eb:SetJustifyH("LEFT")
    eb:SetJustifyV("TOP")
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextColor(0.7, 0.9, 0.7)
    eb:SetMaxLetters(0)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function()
        container:SetBackdropBorderColor(0.64, 0.19, 0.79, 1)
    end)
    eb:SetScript("OnEditFocusLost", function()
        container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end)
    eb:SetScript("OnCursorChanged", function(_, _, y, _, height)
        local vs = sf:GetVerticalScroll()
        local fh = sf:GetHeight()
        local cursorY = -y
        if cursorY < vs then
            sf:SetVerticalScroll(cursorY)
        elseif (cursorY + height) > (vs + fh) then
            sf:SetVerticalScroll(cursorY + height - fh)
        end
    end)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 20, self:GetVerticalScrollRange())))
    end)
    sf:SetScript("OnMouseDown", function() eb:SetFocus() end)

    container.editBox = eb
    function container:GetText() return self.editBox:GetText() end
    function container:SetText(t)  self.editBox:SetText(t or "") end
    function container:SetFocus()  self.editBox:SetFocus() end
    function container:HighlightText() self.editBox:HighlightText() end

    return container
end


local exportPopup = nil

local function ShowExportPopup(encoded, configName)
    if not exportPopup then
        local popup = CreateFrame("Frame", "InfinityBoss_ExportPopup", UIParent, "BackdropTemplate")
        popup:SetSize(600, 350)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetBackdrop(BACKDROP)
        popup:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
        popup:SetBackdropBorderColor(unpack(THEME.Border))
        popup:EnableMouse(true)
        popup:SetMovable(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop",  popup.StopMovingOrSizing)
        if not tContains(UISpecialFrames, "InfinityBoss_ExportPopup") then
            table.insert(UISpecialFrames, "InfinityBoss_ExportPopup")
        end

        local title = popup:CreateFontString(nil, "OVERLAY")
        title:SetFont(InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
        title:SetPoint("TOP", 0, -15)
        title:SetText("|cff00ff80Export Successful|r")
        popup.Title = title

        local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() popup:Hide() end)

        local hint = popup:CreateFontString(nil, "OVERLAY")
        hint:SetFontObject("GameFontHighlight")
        hint:SetPoint("TOP", title, "BOTTOM", 0, -8)
        hint:SetText("|cffffd100Ctrl+C|r to copy and close, or click |cffffd100Select All & Copy|r")
        hint:SetTextColor(0.8, 0.8, 0.8)

        local copyHint = CreateFrame("Frame", nil, popup, "BackdropTemplate")
        copyHint:SetSize(200, 60)
        copyHint:SetPoint("CENTER", popup, "CENTER", 0, 0)
        copyHint:SetFrameLevel(popup:GetFrameLevel() + 10)
        copyHint:SetBackdrop(BACKDROP)
        copyHint:SetBackdropColor(0.1, 0.3, 0.1, 0.95)
        copyHint:SetBackdropBorderColor(0.3, 0.8, 0.3, 1)
        copyHint:Hide()
        local copyHintText = copyHint:CreateFontString(nil, "OVERLAY")
        copyHintText:SetFontObject("GameFontNormalLarge")
        copyHintText:SetPoint("CENTER")
        copyHintText:SetText("|cff00ff00Copied to clipboard|r")
        popup.CopyHint = copyHint

        local editFrame = CreateFrame("Frame", nil, popup, "BackdropTemplate")
        editFrame:SetSize(560, 200)
        editFrame:SetPoint("TOP", hint, "BOTTOM", 0, -10)
        editFrame:SetBackdrop(BACKDROP_SIMPLE)
        editFrame:SetBackdropColor(0.1, 0.1, 0.12, 1)

        local sf = CreateFrame("ScrollFrame", nil, editFrame, "ScrollFrameTemplate")
        if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
            InfinityBoss.UI.ApplyModernScrollBarSkin(sf)
        end
        sf:SetPoint("TOPLEFT",     editFrame, "TOPLEFT",      5, -5)
        sf:SetPoint("BOTTOMRIGHT", editFrame, "BOTTOMRIGHT", -25, 5)

        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetSize(530, 190)
        eb:SetFontObject("ChatFontNormal")
        eb:SetTextColor(0.7, 0.9, 0.7)
        eb:SetAutoFocus(false)
        eb:SetMultiLine(true)
        eb:SetMaxLetters(999999)
        sf:SetScrollChild(eb)
        popup.EditBox = eb

        popup.lastCtrlDown = 0
        popup:SetScript("OnUpdate", function(self)
            if IsControlKeyDown() then self.lastCtrlDown = GetTime() end
        end)

        eb:SetScript("OnKeyUp", function(self, key)
            local wasCtrl = IsControlKeyDown() or (GetTime() - popup.lastCtrlDown < 0.5)
            if wasCtrl and key == "C" then
                self:ClearFocus()
                popup.CopyHint:Show()
                popup.CopyHint:SetAlpha(1)
                C_Timer.After(0.6, function()
                    popup:Hide()
                    popup.CopyHint:Hide()
                end)
            end
        end)

        local selectBtn = CreateSmallButton(popup, "Select All & Copy", function()
            eb:SetFocus()
            eb:HighlightText()
        end)
        selectBtn:SetSize(100, 28)
        selectBtn:SetPoint("BOTTOM", popup, "BOTTOM", -60, 15)

        local closeBtn2 = CreateSmallButton(popup, "Close", function()
            popup:Hide()
        end)
        closeBtn2:SetSize(80, 28)
        closeBtn2:SetPoint("BOTTOM", popup, "BOTTOM", 60, 15)

        exportPopup = popup
    end

    exportPopup.EditBox:SetText(encoded or "")
    exportPopup.Title:SetText("|cff00ff80Export Successful|r - " .. tostring(configName or ""))
    exportPopup.CopyHint:Hide()
    exportPopup:Show()
    exportPopup.EditBox:SetFocus()
    exportPopup.EditBox:HighlightText()
end


local scrollFrame
local scrollChild

local SLOT_ROWS = {
    { key = "raid_tank",  label = "Raid Tank" },
    { key = "raid_dps",   label = "Raid DPS"  },
    { key = "raid_heal",  label = "Raid Healer" },
    { key = "mplus_tank", label = "M+ Tank" },
    { key = "mplus_dps",  label = "M+ DPS"  },
    { key = "mplus_heal", label = "M+ Healer" },
}

local exportNameBox
local exportNoteBox
local exportAppearanceCheck
local exportSlotChecks = {}
local exportStatus

local importInputBox
local importSummaryText
local importAppearanceCheck
local importSlotChecks = {}
local importNamePrefixBox
local importStatus

local manageProfileDropdown
local manageNameBox
local manageStatus
local manageInfo
local manageRenameBtn
local manageDeleteBtn
local manageTitleText

local parsedPayload = nil


local function ShowDeleteProfileConfirm(profileKey, profileName, onAccept)
    if not StaticPopupDialogs or not StaticPopup_Show then
        if type(onAccept) == "function" then onAccept(profileKey) end
        return
    end
    local dialogKey = "InfinityBoss_DELETE_PROFILE_CONFIRM"
    if not StaticPopupDialogs[dialogKey] then
        StaticPopupDialogs[dialogKey] = {
            text = "Confirm delete config: %s?",
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function(_, data)
                if type(data) == "table" and type(data.onAccept) == "function" then
                    data.onAccept(data.profileKey)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show(dialogKey, tostring(profileName or profileKey), nil, {
        profileKey = profileKey,
        onAccept   = onAccept,
    })
end


local function CBChecked(cb)
    if not cb then return false end
    if cb.GetChecked then return cb:GetChecked() end
    if cb.checkbox and cb.checkbox.GetChecked then return cb.checkbox:GetChecked() end
    return false
end


local function DoExport()
    local IE = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ImportExport
    if not IE then
        if exportStatus then exportStatus:SetText("|cffff6666Import/Export module not loaded|r") end
        return
    end

    local inclAppearance = CBChecked(exportAppearanceCheck)
    local includeSlots = {}
    for _, row in ipairs(SLOT_ROWS) do
        includeSlots[row.key] = CBChecked(exportSlotChecks[row.key])
    end
    local hasSlot = false
    for _, enabled in pairs(includeSlots) do
        if enabled == true then
            hasSlot = true
            break
        end
    end

    if not inclAppearance and not hasSlot then
        if exportStatus then exportStatus:SetText("|cffff6666Please check at least one export item.|r") end
        return
    end

    local configName = Trim(exportNameBox and exportNameBox:GetText() or "")
    local note       = Trim(exportNoteBox  and exportNoteBox:GetText()  or "")
    if configName == "" or configName == "Unnamed Config" then configName = "Unnamed Config" end

    local encoded, err = IE:Export({
        includeAppearance = inclAppearance,
        includeSlots      = includeSlots,
        configName        = configName,
        note              = note,
    })

    if not encoded then
        if exportStatus then
            exportStatus:SetText("|cffff6666Export failed: |r" .. tostring(err))
        end
        return
    end

    if exportStatus then exportStatus:SetText("|cff33ee77Export successful|r") end
    ShowExportPopup(encoded, configName)
end


local function ParseImport()
    parsedPayload = nil

    local IE = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ImportExport
    if not IE then
        if importStatus then importStatus:SetText("|cffff6666Import/Export module not loaded|r") end
        return
    end

    local raw = Trim(importInputBox and importInputBox:GetText() or "")
    if raw == "" then
        if importStatus then importStatus:SetText("|cffff6666Please paste an export string first.|r") end
        return
    end

    local payload, err = IE:DecodePayload(raw)
    if not payload then
        if importStatus then
            importStatus:SetText("|cffff6666Parse failed: |r" .. tostring(err))
        end
        return
    end

    parsedPayload = payload

    local summary, sumErr = IE:GetImportSummary(payload)
    if not summary then
        if importStatus then
            importStatus:SetText("|cffff6666Failed to read summary: |r" .. tostring(sumErr))
        end
        return
    end

    if importSummaryText then
        local lines = {}
        lines[#lines+1] = string.format("|cffffd16dConfig Name:|r %s", tostring(summary.configName))
        lines[#lines+1] = string.format("|cffffd16dExporter:|r %s", tostring(summary.exporter))
        if summary.exportedAt and summary.exportedAt ~= "" then
            lines[#lines+1] = string.format("|cffffd16dTime:|r %s", tostring(summary.exportedAt))
        end
        if summary.note and summary.note ~= "" then
            lines[#lines+1] = string.format("|cffffd16dNote:|r %s", tostring(summary.note))
        end
        lines[#lines+1] = ""
        lines[#lines+1] = string.format("Appearance: %s",
            summary.hasAppearance and "|cff33ee77Included|r" or "|cffaaaaaa None|r")
        lines[#lines+1] = string.format("M+ Config: %s%s",
            summary.hasMplus and "|cff33ee77Included|r" or "|cffaaaaaa None|r",
            summary.hasMplus and string.format(" (%d events)", summary.mplusEventCount) or "")
        lines[#lines+1] = string.format("Raid Config: %s%s",
            summary.hasRaid and "|cff33ee77Included|r" or "|cffaaaaaa None|r",
            summary.hasRaid and string.format(" (%d events)", summary.raidEventCount) or "")
        lines[#lines+1] = ""
        for _, row in ipairs(SLOT_ROWS) do
            if summary.slotAvailability and summary.slotAvailability[row.key] then
                local count = summary.slotEventCount and summary.slotEventCount[row.key] or 0
                lines[#lines+1] = string.format("%s: |cff33ee77Included|r (%d events)", row.label, count)
            else
                lines[#lines+1] = string.format("%s: |cffaaaaaa None|r", row.label)
            end
        end
        importSummaryText:SetText(table.concat(lines, "\n"))
    end

    local function SetCB(cb, enabled)
        if not cb then return end
        if cb.SetEnabled then cb:SetEnabled(enabled)
        elseif cb.checkbox then
            if enabled then cb.checkbox:Enable() else cb.checkbox:Disable() end
            cb:SetAlpha(enabled and 1 or 0.45)
        end
        if not enabled then
            if cb.SetChecked then cb:SetChecked(false)
            elseif cb.checkbox and cb.checkbox.SetChecked then cb.checkbox:SetChecked(false) end
        end
    end
    SetCB(importAppearanceCheck, summary.hasAppearance)
    for _, row in ipairs(SLOT_ROWS) do
        SetCB(importSlotChecks[row.key], summary.slotAvailability and summary.slotAvailability[row.key] == true)
    end

    if importStatus then
        importStatus:SetText("|cff33ee77Parse successful — select content to import then click [Execute Import].|r")
    end
end


local function DoImport()
    if not parsedPayload then
        if importStatus then importStatus:SetText("|cffff6666Click [Parse] first.|r") end
        return
    end

    local IE = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.ImportExport
    if not IE then
        if importStatus then importStatus:SetText("|cffff6666Import/Export module not loaded|r") end
        return
    end

    local doAppearance = CBChecked(importAppearanceCheck)
    local importSlots = {}
    for _, row in ipairs(SLOT_ROWS) do
        importSlots[row.key] = CBChecked(importSlotChecks[row.key])
    end
    local hasSlot = false
    for _, enabled in pairs(importSlots) do
        if enabled == true then
            hasSlot = true
            break
        end
    end

    if not doAppearance and not hasSlot then
        if importStatus then importStatus:SetText("|cffff6666Please check at least one import item.|r") end
        return
    end

    local namePrefix = Trim(importNamePrefixBox and importNamePrefixBox:GetText() or "")

    local ok, msg = IE:Import(parsedPayload, {
        importAppearance = doAppearance,
        importSlots      = importSlots,
        namePrefix       = namePrefix ~= "" and namePrefix or nil,
    })

    if importStatus then
        if ok then
            importStatus:SetText("|cff33ee77Import successful: |r" .. tostring(msg))
        else
            importStatus:SetText("|cffff6666Import failed: |r" .. tostring(msg))
        end
    end

    RefreshManagePanel()
end


local function BuildManageProfileItems()
    local items = {}
    local bossCfg = InfinityBoss and InfinityBoss.BossConfig
    if not (type(bossCfg) == "table" and type(bossCfg.GetSelectionSummary) == "function") then
        return items
    end
    bossCfg:Ensure()
    local list = bossCfg:GetSelectionSummary() or {}
    for i = 1, #list do
        local row = list[i]
        if type(row) == "table" then
            items[#items+1] = {
                string.format("%s -> %s", tostring(row.label or row.slotKey), tostring(row.author or "Infinity")),
                row.slotKey,
            }
        end
    end
    return items
end

function RefreshManagePanel()
    if not manageProfileDropdown then return end
    local bossCfg = InfinityBoss and InfinityBoss.BossConfig
    if not (type(bossCfg) == "table" and type(bossCfg.GetSelectionSummary) == "function") then
        return
    end
    bossCfg:Ensure()

    local items = BuildManageProfileItems()
    manageProfileDropdown._items = items
    local currentKey = manageProfileDropdown._currentValue

    local found = false
    for _, row in ipairs(items) do
        if row[2] == currentKey then found = true; break end
    end
    if not found then
        currentKey = (items[1] and items[1][2]) or ""
        manageProfileDropdown._currentValue = currentKey
        manageProfileDropdown:SetText(items[1] and items[1][1] or "(None)")
    end

    if manageInfo and currentKey ~= "" then
        local summary = bossCfg:GetSelectionSummary() or {}
        local found
        for i = 1, #summary do
            local row = summary[i]
            if row.slotKey == currentKey then
                found = row
                break
            end
        end
        if found then
            manageInfo:SetText(string.format(
                "Slot: %s    Author Config: %s",
                tostring(found.label or found.slotKey), tostring(found.author or "Infinity")
            ))
        else
            manageInfo:SetText("")
        end
    end

    if manageRenameBtn then
        manageRenameBtn:Disable()
    end
    if manageDeleteBtn then
        manageDeleteBtn:Disable()
    end
    if manageNameBox then
        manageNameBox:SetText("")
    end
end


local function SectionBg(parent, title, topR, topG, topB)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(unpack(THEME.Background))
    f:SetBackdropBorderColor(unpack(THEME.Border))

    local bar = f:CreateTexture(nil, "BORDER")
    bar:SetColorTexture(topR or 1, topG or 0.82, topB or 0.22, 0.90)
    bar:SetHeight(2)
    bar:SetPoint("TOPLEFT",  f, "TOPLEFT",  6, -6)
    bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

    if title and title ~= "" then
        local fs = f:CreateFontString(nil, "OVERLAY")
        if InfinityTools.MAIN_FONT then
            fs:SetFont(InfinityTools.MAIN_FONT, 16, "OUTLINE")
        else
            fs:SetFontObject("GameFontNormal")
        end
        fs:SetPoint("TOPLEFT", 14, -14)
        fs:SetText(title)
        fs:SetTextColor(topR or 1, topG or 0.82, topB or 0.22)
        f._titleFS = fs
    end
    return f
end


local function CreateSingleLineInput(parent, w, placeholder)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetSize(w or 300, 28)
    eb:SetBackdrop(TOOLTIP_BACKDROP)
    eb:SetBackdropColor(0, 0, 0, 0.6)
    eb:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(8, 8, 0, 0)
    eb:SetMaxLetters(128)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(0.64, 0.19, 0.79, 1)
        if placeholder and self:GetText() == placeholder then self:SetText("") end
        self:SetTextColor(unpack(THEME.TextMain))
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        if placeholder and Trim(self:GetText()) == "" then
            self:SetText(placeholder)
            self:SetTextColor(unpack(THEME.TextDim))
        end
    end)
    if placeholder then
        eb:SetText(placeholder)
        eb:SetTextColor(unpack(THEME.TextDim))
    end
    return eb
end

-- ─── MakeCheckbox ─────────────────────────────────────────────

local function MakeCheckbox(parent, label, defaultVal)
    local InfinityUI = _G.InfinityTools and _G.InfinityTools.UI
    if InfinityUI and InfinityUI.CreateCheckbox then
        local cb = InfinityUI:CreateCheckbox(parent, label, defaultVal, nil)
        if not cb.GetChecked then
            function cb:GetChecked()
                if self.checkbox and self.checkbox.GetChecked then return self.checkbox:GetChecked() end
                return false
            end
        end
        if not cb.SetChecked then
            function cb:SetChecked(v)
                if self.checkbox and self.checkbox.SetChecked then self.checkbox:SetChecked(v) end
            end
        end
        if not cb.SetEnabled then
            function cb:SetEnabled(v)
                if self.checkbox then
                    if v then self.checkbox:Enable() else self.checkbox:Disable() end
                end
                self:SetAlpha(v and 1 or 0.45)
            end
        end
        return cb
    end
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label or "")
    fs:SetTextColor(unpack(THEME.TextMain))
    cb:SetChecked(defaultVal == true)
    return cb
end


local function MakeLabel(parent, text, isSmall)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    if isSmall then
        fs:SetFontObject("GameFontHighlightSmall")
    else
        fs:SetFontObject("GameFontHighlight")
    end
    fs:SetText(text or "")
    fs:SetTextColor(unpack(THEME.TextSub))
    fs:SetJustifyH("LEFT")
    return fs
end


local uiBuilt = false

local function EnsureUI(contentFrame)
    if uiBuilt and scrollFrame and scrollFrame:GetParent() == contentFrame then return end
    uiBuilt = false

    if scrollFrame then
        scrollFrame:Hide()
        scrollFrame:SetParent(UIParent)
    end

    local InfinityUI = _G.InfinityTools and _G.InfinityTools.UI

    scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(scrollFrame)
    end
    scrollFrame:SetPoint("TOPLEFT",     contentFrame, "TOPLEFT",     4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -26, 4)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(contentFrame:GetWidth() - 40, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local fullW = (contentFrame:GetWidth() or 1100) - 50
    local colW  = math.floor((fullW - 20) / 2) - 6

    local y = -16

    local expSec = SectionBg(scrollChild, "Export", THEME.Primary[1], THEME.Primary[2], THEME.Primary[3])
    expSec:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, y)
    expSec:SetWidth(colW)

    local ey = -38

    local nameLbl = MakeLabel(expSec, "Config Name", true)
    nameLbl:SetPoint("TOPLEFT", 14, ey)
    ey = ey - 18

    exportNameBox = CreateSingleLineInput(expSec, colW - 28, "Unnamed Config")
    exportNameBox:SetPoint("TOPLEFT", expSec, "TOPLEFT", 14, ey)
    ey = ey - 38

    local noteLbl = MakeLabel(expSec, "Note (optional)", true)
    noteLbl:SetPoint("TOPLEFT", expSec, "TOPLEFT", 14, ey)
    ey = ey - 18

    exportNoteBox = CreateSingleLineInput(expSec, colW - 28, "None")
    exportNoteBox:SetPoint("TOPLEFT", expSec, "TOPLEFT", 14, ey)
    ey = ey - 38

    local inclLbl = MakeLabel(expSec, "Export Contents", true)
    inclLbl:SetPoint("TOPLEFT", expSec, "TOPLEFT", 14, ey)
    ey = ey - 24

    exportAppearanceCheck = MakeCheckbox(expSec, "Appearance Settings (timer bar styles, etc.)", false)
    exportAppearanceCheck:SetPoint("TOPLEFT", expSec, "TOPLEFT", 14, ey)
    ey = ey - 28

    exportSlotChecks = {}
    for _, row in ipairs(SLOT_ROWS) do
        local cb = MakeCheckbox(expSec, row.label, true)
        cb:SetPoint("TOPLEFT", expSec, "TOPLEFT", 14, ey)
        exportSlotChecks[row.key] = cb
        ey = ey - 28
    end
    ey = ey - 16

    local expBtn = CreateActionButton(expSec, "Export", DoExport)
    expBtn:SetSize(140, 36)
    expBtn:SetPoint("TOPLEFT", expSec, "TOPLEFT", 14, ey)
    ey = ey - 44

    exportStatus = expSec:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    exportStatus:SetPoint("TOPLEFT",  expSec, "TOPLEFT",  14, ey)
    exportStatus:SetPoint("TOPRIGHT", expSec, "TOPRIGHT", -14, 0)
    exportStatus:SetJustifyH("LEFT")
    exportStatus:SetTextColor(unpack(THEME.TextSub))
    exportStatus:SetText("")
    ey = ey - 26

    expSec:SetHeight(math.abs(ey) + 16)

    local impSec = SectionBg(scrollChild, "Import", THEME.Success[1], THEME.Success[2], THEME.Success[3])
    impSec:SetPoint("TOPLEFT", expSec, "TOPRIGHT", 20, 0)
    impSec:SetWidth(colW)

    local iy = -38

    local strLbl = MakeLabel(impSec, "Paste Export String", true)
    strLbl:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    iy = iy - 20

    importInputBox = CreateMultiLineEditBox(impSec, colW - 28, 80)
    importInputBox:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    iy = iy - 90

    local parseBtn = CreateActionButton(impSec, "Parse", ParseImport)
    parseBtn:SetSize(100, 32)
    parseBtn:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    iy = iy - 42

    importSummaryText = impSec:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    importSummaryText:SetPoint("TOPLEFT",  impSec, "TOPLEFT",  14, iy)
    importSummaryText:SetPoint("TOPRIGHT", impSec, "TOPRIGHT", -14, 0)
    importSummaryText:SetJustifyH("LEFT")
    importSummaryText:SetJustifyV("TOP")
    importSummaryText:SetTextColor(unpack(THEME.TextMain))
    importSummaryText:SetText("")
    iy = iy - 100

    local divLine = impSec:CreateTexture(nil, "ARTWORK")
    divLine:SetHeight(1)
    divLine:SetColorTexture(unpack(THEME.Border))
    divLine:SetPoint("TOPLEFT",  impSec, "TOPLEFT",  14, iy)
    divLine:SetPoint("TOPRIGHT", impSec, "TOPRIGHT", -14, 0)
    iy = iy - 16

    local inclLbl2 = MakeLabel(impSec, "Import Contents", true)
    inclLbl2:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    iy = iy - 24

    importAppearanceCheck = MakeCheckbox(impSec, "Import Appearance Settings (apply immediately)", false)
    importAppearanceCheck:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    if importAppearanceCheck.SetEnabled then importAppearanceCheck:SetEnabled(false) end
    iy = iy - 28

    importSlotChecks = {}
    for _, row in ipairs(SLOT_ROWS) do
        local cb = MakeCheckbox(impSec, row.label, false)
        cb:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
        if cb.SetEnabled then cb:SetEnabled(false) end
        importSlotChecks[row.key] = cb
        iy = iy - 28
    end
    iy = iy - 10

    local prefixLbl = MakeLabel(impSec, "Import as Author (leave blank to use config name)", true)
    prefixLbl:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    iy = iy - 20

    importNamePrefixBox = CreateSingleLineInput(impSec, colW - 28)
    importNamePrefixBox:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    importNamePrefixBox:Enable()
    iy = iy - 44

    local impBtn = CreateActionButton(impSec, "Execute Import", DoImport)
    impBtn:SetSize(140, 36)
    impBtn:SetPoint("TOPLEFT", impSec, "TOPLEFT", 14, iy)
    iy = iy - 44

    importStatus = impSec:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    importStatus:SetPoint("TOPLEFT",  impSec, "TOPLEFT",  14, iy)
    importStatus:SetPoint("TOPRIGHT", impSec, "TOPRIGHT", -14, 0)
    importStatus:SetJustifyH("LEFT")
    importStatus:SetTextColor(unpack(THEME.TextSub))
    importStatus:SetText("")
    iy = iy - 26

    local maxH = math.max(math.abs(ey) + 16, math.abs(iy) + 16)
    expSec:SetHeight(maxH)
    impSec:SetHeight(maxH)

    local sectionBottom = y - maxH

    local manY = sectionBottom - 20

    local manSec = SectionBg(scrollChild, "Slot Overview",
        THEME.Success[1]*0.8, THEME.Success[2]*0.8, THEME.Success[3]*0.8)
    manSec:SetPoint("TOPLEFT",  scrollChild, "TOPLEFT",  10, manY)
    manSec:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, 0)

    local my = -38

    if InfinityUI and InfinityUI.CreateDropdown then
        manageProfileDropdown = InfinityUI:CreateDropdown(manSec, 420, "Select Config",
            BuildManageProfileItems(), "", function(value)
                manageProfileDropdown._currentValue = value
                RefreshManagePanel()
            end)
        manageProfileDropdown:SetPoint("TOPLEFT", manSec, "TOPLEFT", 14, my)
        my = my - 44
    end

    manageInfo = manSec:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    manageInfo:SetPoint("TOPLEFT",  manSec, "TOPLEFT",  14, my)
    manageInfo:SetPoint("TOPRIGHT", manSec, "TOPRIGHT", -14, 0)
    manageInfo:SetJustifyH("LEFT")
    manageInfo:SetTextColor(unpack(THEME.TextMain))
    manageInfo:SetText("")
    my = my - 36

    local renameLbl = MakeLabel(manSec, "This section shows the author config for each of the 6 slots.", true)
    renameLbl:SetPoint("TOPLEFT", manSec, "TOPLEFT", 14, my)
    my = my - 20

    manageNameBox = CreateSingleLineInput(manSec, 320)
    manageNameBox:SetPoint("TOPLEFT", manSec, "TOPLEFT", 14, my)
    manageNameBox:Disable()

    manageRenameBtn = CreateSmallButton(manSec, "Rename", function()
        if manageStatus then
            manageStatus:SetText("|cffffcc66Slots have a fixed structure. Switch author configs on the Voice/Config page.|r")
        end
    end)
    manageRenameBtn:SetSize(100, 28)
    manageRenameBtn:SetPoint("LEFT", manageNameBox, "RIGHT", 10, 0)
    my = my - 40

    manageDeleteBtn = CreateFrame("Button", nil, manSec, "BackdropTemplate")
    manageDeleteBtn:SetSize(90, 28)
    manageDeleteBtn:SetPoint("TOPLEFT", manSec, "TOPLEFT", 14, my)
    manageDeleteBtn:SetBackdrop(BACKDROP_SIMPLE)
    manageDeleteBtn:SetBackdropColor(THEME.Danger[1]*0.5, THEME.Danger[2]*0.5, THEME.Danger[3]*0.5, 0.9)
    local delFS = manageDeleteBtn:CreateFontString(nil, "OVERLAY")
    delFS:SetFontObject("GameFontNormal")
    delFS:SetPoint("CENTER")
    delFS:SetText("Delete")
    delFS:SetTextColor(1, 1, 1, 1)
    manageDeleteBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(THEME.Danger))
    end)
    manageDeleteBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(THEME.Danger[1]*0.5, THEME.Danger[2]*0.5, THEME.Danger[3]*0.5, 0.9)
    end)
    manageDeleteBtn:SetScript("OnClick", function()
        if manageStatus then
            manageStatus:SetText("|cffffcc66Slots have a fixed structure and cannot be deleted.|r")
        end
    end)
    my = my - 44

    manageStatus = manSec:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    manageStatus:SetPoint("TOPLEFT",  manSec, "TOPLEFT",  14, my)
    manageStatus:SetPoint("TOPRIGHT", manSec, "TOPRIGHT", -14, 0)
    manageStatus:SetJustifyH("LEFT")
    manageStatus:SetTextColor(unpack(THEME.TextSub))
    manageStatus:SetText("")
    my = my - 26

    manSec:SetHeight(math.abs(my) + 16)

    local totalH = math.abs(manY) + math.abs(my) + 40
    scrollChild:SetHeight(totalH)

    uiBuilt = true
end


function Page:Render(contentFrame)
    EnsureUI(contentFrame)
    if not scrollFrame then return end
    scrollFrame:SetParent(contentFrame)
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT",     contentFrame, "TOPLEFT",     4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -26, 4)
    scrollFrame:Show()
    scrollChild:SetWidth(contentFrame:GetWidth() - 40)
    RefreshManagePanel()
end

function Page:Hide()
    if scrollFrame then scrollFrame:Hide() end
end
