---@diagnostic disable: undefined-global, undefined-field

InfinityBoss.UI.Panel.MDTPage = InfinityBoss.UI.Panel.MDTPage or {}
local Page = InfinityBoss.UI.Panel.MDTPage

local L = InfinityBoss.L or setmetatable({}, { __index = function(_, key) return key end })
local Provider = InfinityBoss.MDT.Provider
local Runtime = InfinityBoss.MDT.Runtime
local Overlay = InfinityBoss.MDT.Overlay
local ImportPreset = InfinityBoss.MDT.ImportPreset

local root
local routeInfoText
local progressText
local overlayToggleBtn
local collectionDropdown
local importPresetStatusText
local pullPaneTitle
local dungeonScrollFrame, dungeonScrollChild
local pullScrollFrame, pullScrollChild
local detailScrollFrame, detailScrollChild
local settingsScrollFrame, settingsScrollChild
local noteEditBox
local detailTitle
local settingsListFrame
local showCasterCheck
local noteLabel
local saveNoteBtn
local pullImageFrame
local pullImageTexture
local pullImageText

local dungeonButtons = {}
local pullButtons = {}
local detailRows = {}

local selectedDungeonIdx
local selectedPullIndex = 1
local selectedLeftMode = "dungeon"
local selectedSettingKey = "general"

local InfinityTools = _G.InfinityTools

local function GetCollectionItems()
    local items = {}
    if InfinityBoss.MDT.Presets then
        for _, col in ipairs(InfinityBoss.MDT.Presets.GetAllCollections() or {}) do
            items[#items + 1] = { tostring(col.label or col.key), col.key }
        end
    end
    return items
end

local DUNGEON_BTN_H = 74
local PULL_BTN_H = 24
local DUNGEON_BTN_W = 72
local PULL_BTN_W = 356
local DETAIL_ROW_W = 900
local SETTINGS_MODULE_KEY = "InfinityBoss.MDT.Settings"
local SETTINGS_GRID_COLS = 63

local SETTINGS_LIST_ITEMS = {
    { key = "general", label = function() return "General Settings" end },
}

local SETTINGS_LAYOUTS = {
    general = {
        { key = "header", type = "header", x = 1, y = 1, w = 63, h = 2, label = function() return "General Settings" end, labelSize = 24 },
        { key = "desc", type = "description", x = 1, y = 4, w = 63, h = 2, label = function() return "Control which mob types are shown in the overlay and detail panel." end },
        { key = "showCasters", type = "checkbox", x = 1, y = 8, w = 18, h = 2, label = function() return "Show Casters" end },
    },
}

local NOTE_INPUT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 20, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function FindDropdownText(items, value)
    local target = tostring(value or "")
    for _, item in ipairs(items or {}) do
        if type(item) == "table" then
            if tostring(item[2] or "") == target then
                return tostring(item[1] or "")
            end
        elseif tostring(item or "") == target then
            return tostring(item)
        end
    end
    return ""
end

local function GetSettingListLabel(key)
    for _, item in ipairs(SETTINGS_LIST_ITEMS) do
        if tostring(item.key or "") == tostring(key or "") then
            if type(item.label) == "function" then
                return tostring(item.label() or "")
            end
            return tostring(item.label or "")
        end
    end
    return tostring(key or "")
end

local function CreateSectionBackdrop(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.07, 0.9)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    return frame
end

local function CreateMultiLineInput(parent, width, height)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(width, height)
    container:SetBackdrop(NOTE_INPUT_BACKDROP)
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -25, 5)
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(scrollFrame)
    end

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(width - 30, 2000)
    scrollFrame:SetScrollChild(scrollContent)

    local editBox = CreateFrame("EditBox", nil, scrollContent)
    editBox:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
    editBox:SetPoint("TOPRIGHT", scrollContent, "TOPRIGHT", 0, 0)
    editBox:SetHeight(2000)
    editBox:SetMultiLine(true)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlight")
    if InfinityTools and InfinityTools.MAIN_FONT then
        editBox:SetFont(InfinityTools.MAIN_FONT, 16, "")
    end
    editBox:SetTextColor(0.9, 0.93, 1)
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusGained", function()
        container:SetBackdropBorderColor(0.64, 0.19, 0.79, 1)
    end)
    editBox:SetScript("OnEditFocusLost", function()
        container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end)
    editBox:SetScript("OnCursorChanged", function(_, _, y, _, lineHeight)
        local verticalScroll = scrollFrame:GetVerticalScroll()
        local frameHeight = scrollFrame:GetHeight()
        local cursorY = -y
        if cursorY < verticalScroll then
            scrollFrame:SetVerticalScroll(cursorY)
        elseif (cursorY + lineHeight) > (verticalScroll + frameHeight) then
            scrollFrame:SetVerticalScroll(cursorY + lineHeight - frameHeight)
        end
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(current - delta * 20, self:GetVerticalScrollRange())))
    end)
    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    container.editBox = editBox
    function container:GetText()
        return self.editBox:GetText()
    end
    function container:SetText(value)
        self.editBox:SetText(value or "")
    end
    function container:HasFocus()
        return self.editBox:HasFocus()
    end
    function container:SetFocus()
        self.editBox:SetFocus()
    end

    return container
end

local function UTF8Left(text, maxChars)
    local s = tostring(text or "")
    local n = tonumber(maxChars) or 0
    if n <= 0 or s == "" then
        return ""
    end
    if type(strlenutf8) == "function" then
        local len = strlenutf8(s)
        if len and len <= n then
            return s
        end
    end
    local i, chars, bytes = 1, 0, #s
    while i <= bytes and chars < n do
        local c = string.byte(s, i)
        local step = 1
        if c and c >= 240 then
            step = 4
        elseif c and c >= 224 then
            step = 3
        elseif c and c >= 192 then
            step = 2
        end
        i = i + step
        chars = chars + 1
    end
    return string.sub(s, 1, i - 1)
end

local function GetDungeonIcon(mapID)
    local id = tonumber(mapID)
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo and id and id > 0 then
        local _, _, _, icon = C_ChallengeMode.GetMapUIInfo(id)
        if icon then
            return icon
        end
    end
    return "Interface\\LFGFrame\\LFGIcon-Dungeon"
end

local function AcquireDungeonButton(index)
    local btn = dungeonButtons[index]
    if btn then
        return btn
    end

    btn = CreateFrame("Button", nil, dungeonScrollChild, "BackdropTemplate")
    btn:SetSize(DUNGEON_BTN_W, DUNGEON_BTN_H)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(44, 44)
    btn.icon:SetPoint("TOP", 0, -4)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn._fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn._fs:SetPoint("TOP", btn.icon, "BOTTOM", 0, -3)
    btn._fs:SetWidth(DUNGEON_BTN_W - 4)
    btn._fs:SetJustifyH("CENTER")
    btn._fs:SetWordWrap(false)
    if InfinityTools and InfinityTools.MAIN_FONT then
        btn._fs:SetFont(InfinityTools.MAIN_FONT, 11, "OUTLINE")
    end
    btn:SetScript("OnEnter", function(self)
        self._hovered = true
        if self._applyVisual then
            self:_applyVisual()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self._hovered = false
        if self._applyVisual then
            self:_applyVisual()
        end
    end)
    btn:SetScript("OnClick", function(self)
        if self._isSettingsEntry then
            selectedLeftMode = "settings"
            Page:_Refresh(Runtime.GetState())
            return
        end
        selectedLeftMode = "dungeon"
        selectedDungeonIdx = self._dungeonIdx
        selectedPullIndex = 1
        Runtime.SetSelectedDungeonIdx(selectedDungeonIdx)
    end)
    dungeonButtons[index] = btn
    return btn
end

local function AcquirePullButton(index)
    local btn = pullButtons[index]
    if btn then
        return btn
    end

    btn = CreateFrame("Button", nil, pullScrollChild)
    btn:SetSize(PULL_BTN_W, PULL_BTN_H)
    btn._bg = btn:CreateTexture(nil, "BACKGROUND")
    btn._bg:SetAllPoints()
    btn._fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn._fs:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btn._fs:SetWidth(PULL_BTN_W - 16)
    btn._fs:SetJustifyH("LEFT")
    btn:SetScript("OnClick", function(self)
        if selectedLeftMode == "settings" and self._settingKey then
            selectedSettingKey = tostring(self._settingKey)
            Page:_Refresh(Runtime.GetState())
            return
        end
        selectedPullIndex = self._pullIndex
        Runtime.SetManualPullIndex(selectedPullIndex)
    end)
    pullButtons[index] = btn
    return btn
end

local function AcquireDetailRow(index)
    local row = detailRows[index]
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, detailScrollChild)
    row:SetSize(DETAIL_ROW_W, 18)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.text:SetWidth(DETAIL_ROW_W - 22)
    row.text:SetJustifyH("LEFT")
    row.text:SetTextColor(0.9, 0.93, 1)
    if InfinityTools and InfinityTools.MAIN_FONT then
        row.text:SetFont(InfinityTools.MAIN_FONT, 18, "")
    end
    detailRows[index] = row
    return row
end

local function HideUnused(list, startIndex)
    for i = startIndex, #list do
        if list[i] then
            list[i]:Hide()
        end
    end
end

local function UpdateLeftPaneMode()
    local showSettings = selectedLeftMode == "settings"
    if pullPaneTitle then
        pullPaneTitle:SetText(showSettings and "General Settings" or "MDT Pulls")
    end
    if pullScrollFrame then
        if showSettings then
            pullScrollFrame:Hide()
        else
            pullScrollFrame:Show()
        end
    end
    if settingsListFrame then
        settingsListFrame:Hide()
    end
end

local function UpdateButtons(state)
    local rows = Provider.CollectDungeonRows()
    local cols = 4
    local gapX = 6
    local gapY = 8
    local leftPad = 4
    local topPad = 4
    local yBottom = 0
    for index, rowData in ipairs(rows) do
        local btn = AcquireDungeonButton(index)
        btn:ClearAllPoints()
        btn._dungeonIdx = rowData.mdtDungeonIdx
        btn._isSettingsEntry = false
        local active = selectedLeftMode ~= "settings" and tonumber(selectedDungeonIdx) == tonumber(rowData.mdtDungeonIdx)
        local row = math.floor((index - 1) / cols)
        local col = (index - 1) % cols
        btn:SetPoint("TOPLEFT", leftPad + col * (DUNGEON_BTN_W + gapX), -topPad - row * (DUNGEON_BTN_H + gapY))
        btn.icon:SetTexture(GetDungeonIcon(rowData.mapID))
        local label = tostring(rowData.shortName and rowData.shortName ~= "" and rowData.shortName or rowData.name or "")
        label = UTF8Left(label, 5)
        btn._fs:SetText(label)
        btn._selected = active
        btn._hovered = false
        btn._applyVisual = function(self)
            if self._selected then
                self:SetBackdropColor(0.1, 0.4, 0.8, 0.3)
                self:SetBackdropBorderColor(0, 0.8, 1, 1)
                self.icon:SetDesaturated(false)
                self._fs:SetTextColor(1, 0.85, 0.35)
            elseif self._hovered then
                self:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
                self:SetBackdropBorderColor(0.48, 0.48, 0.55, 0.9)
                self.icon:SetDesaturated(false)
                self._fs:SetTextColor(0.95, 0.95, 0.95)
            else
                self:SetBackdropColor(0.04, 0.04, 0.04, 0.8)
                self:SetBackdropBorderColor(0.36, 0.36, 0.4, 0.85)
                self.icon:SetDesaturated(true)
                self._fs:SetTextColor(rowData.hasRoute == false and 0.45 or 0.78, rowData.hasRoute == false and 0.45 or 0.78, rowData.hasRoute == false and 0.48 or 0.8)
            end
        end
        btn:_applyVisual()
        btn:Show()
        yBottom = row * (DUNGEON_BTN_H + gapY) + DUNGEON_BTN_H
    end

    HideUnused(dungeonButtons, #rows + 1)
    dungeonScrollChild:SetHeight(math.max(120, yBottom + topPad + 8))

    local y = 0
    if selectedLeftMode == "settings" then
        for index, item in ipairs(SETTINGS_LIST_ITEMS) do
            local btn = AcquirePullButton(index)
            btn:SetPoint("TOPLEFT", 4, -y)
            btn._pullIndex = nil
            btn._settingKey = item.key
            local isSelected = tostring(selectedSettingKey or "") == tostring(item.key or "")
            local r, g, b = 0.04, 0.04, 0.04
            if isSelected then
                r, g, b = 0.22, 0.36, 0.62
            end
            btn._bg:SetColorTexture(r, g, b, 1)
            btn._fs:SetText(GetSettingListLabel(item.key))
            btn._fs:SetTextColor(1, 1, 1)
            btn:Show()
            y = y + PULL_BTN_H + 2
        end
        HideUnused(pullButtons, #SETTINGS_LIST_ITEMS + 1)
    else
        local snapshot = state and state.snapshot
        local pulls = snapshot and snapshot.pulls or {}
        for index, pull in ipairs(pulls) do
            local btn = AcquirePullButton(index)
            btn:SetPoint("TOPLEFT", 4, -y)
            btn._settingKey = nil
            btn._pullIndex = index
            local isSelected = index == selectedPullIndex
            local isCurrent = state and state.currentPullIndex == index
            local r, g, b = 0.04, 0.04, 0.04
            if isCurrent then
                r, g, b = 0.18, 0.48, 0.24
            end
            if isSelected then
                r, g, b = 0.22, 0.36, 0.62
            end
            btn._bg:SetColorTexture(r, g, b, 1)
            btn._fs:SetText(string.format("Pull %d   [%d types / %d units]", index, tonumber(pull.enemyKinds) or 0, tonumber(pull.unitCount) or 0))
            btn._fs:SetTextColor(1, 1, 1)
            btn:Show()
            y = y + PULL_BTN_H + 2
        end
        HideUnused(pullButtons, #pulls + 1)
    end
    pullScrollChild:SetHeight(math.max(120, y + 8))
end

local function UpdateDetail(state)
    if selectedLeftMode == "settings" then
        return
    end
    local snapshot = state and state.snapshot
    if not (snapshot and snapshot.pulls and snapshot.pulls[selectedPullIndex]) then
        detailTitle:SetText("Please select an MDT pull.")
        HideUnused(detailRows, 1)
        detailScrollChild:SetHeight(120)
        return
    end

    local pull = snapshot.pulls[selectedPullIndex]
    detailTitle:SetText(string.format("Pull %d Enemy Details", selectedPullIndex))

    local y = -40
    local rowIndex = 1
    local shownCount = 0
    for _, enemy in ipairs(pull.enemies or {}) do
        if Runtime.ShouldShowEnemy(enemy) then
            local row = AcquireDetailRow(rowIndex)
            row:SetPoint("TOPLEFT", 8, y)
            Provider.SetCreaturePortrait(row.icon, enemy.displayID, enemy.icon or 134400)
            local line = string.format("%s x%d", tostring(enemy.name), tonumber(enemy.count) or 0)
            if enemy.hasInterruptible then
                line = line .. "  |cff7cffb5" .. "Caster" .. "|r"
            end
            row.text:SetText(line)
            row.text:SetTextColor(0.9, 0.93, 1)
            row:Show()
            rowIndex = rowIndex + 1
            y = y - 20
            shownCount = shownCount + 1

            if enemy.hasInterruptible and type(enemy.interruptibleSpells) == "table" and enemy.interruptibleSpells[1] then
                local spellNames = {}
                local spellIcon = nil
                for i = 1, math.min(#enemy.interruptibleSpells, 3) do
                    local spellID = enemy.interruptibleSpells[i]
                    if not spellIcon then
                        spellIcon = Provider.GetSpellTexture(spellID)
                    end
                    spellNames[#spellNames + 1] = Provider.GetSpellName(spellID) or tostring(spellID)
                end
                local spellRow = AcquireDetailRow(rowIndex)
                spellRow:SetPoint("TOPLEFT", 28, y)
                spellRow.icon:SetTexture(spellIcon or 134400)
                spellRow.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                spellRow.text:SetText(string.format("Interruptible casts: %s", table.concat(spellNames, " / ")))
                spellRow.text:SetTextColor(0.86, 0.95, 0.76)
                spellRow:Show()
                rowIndex = rowIndex + 1
                y = y - 18
            end
        end
    end

    if shownCount == 0 then
        local emptyRow = AcquireDetailRow(rowIndex)
        emptyRow:SetPoint("TOPLEFT", 8, y)
        emptyRow.icon:SetTexture(134400)
        emptyRow.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        emptyRow.text:SetText("No mobs in this pull match the current settings.")
        emptyRow.text:SetTextColor(0.76, 0.8, 0.88)
        emptyRow:Show()
        rowIndex = rowIndex + 1
        y = y - 20
    end

    HideUnused(detailRows, rowIndex)
    detailScrollChild:SetHeight(math.max(220, math.abs(y) + 40))

    if not noteEditBox:HasFocus() then
        if noteEditBox._routeKey ~= snapshot.routeKey or noteEditBox._pullIndex ~= selectedPullIndex then
            noteEditBox._routeKey = snapshot.routeKey
            noteEditBox._pullIndex = selectedPullIndex
            noteEditBox:SetText(Runtime.GetPullNote(snapshot.routeKey, selectedPullIndex) or "")
        end
    end
end

local function UpdatePullImage(state)
    if not (pullImageFrame and pullImageTexture and pullImageText) then
        return
    end

    local snapshot = state and state.snapshot
    local pull = snapshot and snapshot.pulls and snapshot.pulls[selectedPullIndex] or nil
    pullImageTexture:SetTexture(nil)
    if not (snapshot and pull) then
        pullImageText:SetText("Current pull image: none")
        return
    end

    local imagePath = Provider.GetPullImagePath(snapshot.mapID, selectedPullIndex)
    if imagePath then
        pullImageTexture:SetTexture(imagePath)
        pullImageText:SetText(string.format("Current pull image: %s", string.format("%s/%d.jpg", tostring(snapshot.mapID or "?"), tonumber(selectedPullIndex) or 0)))
    else
        pullImageText:SetText("Current pull image: none")
    end
end

local function UpdateRightPaneMode()
    local isSettingsMode = selectedLeftMode == "settings"
    if detailTitle then
        if isSettingsMode then
            detailTitle:SetText(GetSettingListLabel(selectedSettingKey))
        else
            detailTitle:SetText("Mobs / Spells")
        end
    end
    if noteLabel then
        if isSettingsMode then noteLabel:Hide() else noteLabel:Show() end
    end
    if noteEditBox then
        if isSettingsMode then noteEditBox:Hide() else noteEditBox:Show() end
    end
    if saveNoteBtn then
        if isSettingsMode then saveNoteBtn:Hide() else saveNoteBtn:Show() end
    end
    if pullImageFrame then
        pullImageFrame:Hide()
    end
    if detailScrollFrame then
        if isSettingsMode then detailScrollFrame:Hide() else detailScrollFrame:Show() end
    end
    if settingsScrollFrame then
        if isSettingsMode then settingsScrollFrame:Show() else settingsScrollFrame:Hide() end
    end
end

local function RenderSettingsGrid()
    local Grid = _G.InfinityGrid
    if not (selectedLeftMode == "settings" and settingsScrollFrame and settingsScrollChild and Grid) then
        return
    end
    local layout = SETTINGS_LAYOUTS[selectedSettingKey]
    if type(layout) ~= "table" then
        settingsScrollChild:SetHeight(1)
        return
    end
    local width = tonumber(settingsScrollFrame:GetWidth()) or 0
    if width < 100 then
        width = 900
    end
    settingsScrollChild:SetWidth(width - 16)
    settingsScrollChild:ClearAllPoints()
    settingsScrollChild:SetPoint("TOPLEFT", 0, 0)
    if InfinityTools and InfinityTools.UI then
        InfinityTools.UI.ActivePageFrame = settingsScrollChild
        InfinityTools.UI.CurrentModule = SETTINGS_MODULE_KEY
    end
    if Grid.SetContainerCols then
        Grid:SetContainerCols(settingsScrollChild, SETTINGS_GRID_COLS)
    end
    Grid:Render(settingsScrollChild, layout, Runtime.GetDisplaySettings(), SETTINGS_MODULE_KEY)
    settingsScrollFrame:SetVerticalScroll(0)
end

function Page:_Refresh(state)
    state = state or Runtime.GetState()
    if state and state.ok and state.snapshot and tonumber(state.snapshot.dungeonIdx) then
        if selectedLeftMode ~= "settings" then
            selectedDungeonIdx = tonumber(state.snapshot.dungeonIdx)
        elseif not selectedDungeonIdx then
            selectedDungeonIdx = tonumber(state.snapshot.dungeonIdx)
        end
    end
    if state and state.ok and selectedLeftMode ~= "settings" then
        selectedPullIndex = tonumber(state.currentPullIndex) or 1
    elseif state and state.ok and (selectedPullIndex < 1 or not state.snapshot.pulls[selectedPullIndex]) then
        selectedPullIndex = tonumber(state.currentPullIndex) or 1
    end

    if not (state and state.ok) then
        routeInfoText:SetText("|cffff6666" .. tostring(state and state.reason or "MDT unavailable") .. "|r")
        progressText:SetText("Progress: not available")
    else
        routeInfoText:SetText(string.format("Dungeon: %s    Route: %s (%s/%s)    Current Pull: %s",
            tostring(state.snapshot.dungeonName or "-"),
            tostring(state.snapshot.routeName or "-"),
            tostring(state.snapshot.presetIndex or "-"),
            tostring(state.snapshot.presetCount or "-"),
            tostring(state.currentPullIndex or "-")))
    end

    local db = InfinityBoss.MDT.EnsureDB()
    overlayToggleBtn:SetText((db.overlay and db.overlay.enabled ~= false) and "Overlay On" or "Overlay Off")
    if state and state.ok and state.progress and tonumber(state.progress.percent) then
        progressText:SetText(string.format(
            "Progress: %.1f / %.1f (%.1f%%)",
            tonumber(state.progress.current) or 0,
            tonumber(state.progress.total) or 0,
            tonumber(state.progress.percent) or 0
        ))
    else
        progressText:SetText("Progress: not available")
    end

    if collectionDropdown and ImportPreset and InfinityBoss.MDT.Presets then
        local colItems = GetCollectionItems and GetCollectionItems() or {}
        collectionDropdown._items = colItems
        if not collectionDropdown._currentValue or collectionDropdown._currentValue == "" then
            local currentCol = ImportPreset.GetSelectedCollectionKey and ImportPreset.GetSelectedCollectionKey() or ""
            collectionDropdown._currentValue = currentCol
            collectionDropdown:SetText(FindDropdownText(colItems, currentCol))
        end
    end

    local display = Runtime.GetDisplaySettings()
    if showCasterCheck then
        showCasterCheck:SetChecked(display.showCasters ~= false)
    end

    UpdateLeftPaneMode()
    UpdateButtons(state)
    UpdateRightPaneMode()
    if selectedLeftMode == "settings" then
        RenderSettingsGrid()
    else
        UpdatePullImage(state)
        UpdateDetail(state)
    end
end

local function EnsureUI(contentFrame)
    if root then
        return
    end

    root = CreateFrame("Frame", nil, contentFrame)
    root:SetAllPoints(contentFrame)

    local header = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("MDT Route Module")
    header:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(header, "text") end

    local desc = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    desc:SetText("Read MDT routes / pulls and show current-pull interruptible mobs.")
    desc:SetTextColor(0.8, 0.85, 0.92)

    local refreshBtn = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
    refreshBtn:SetSize(90, 22)
    refreshBtn:SetPoint("TOPRIGHT", -12, -10)
    refreshBtn:SetText("Refresh MDT")
    refreshBtn:SetScript("OnClick", function()
        Runtime.Refresh(true)
    end)

    overlayToggleBtn = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
    overlayToggleBtn:SetSize(90, 22)
    overlayToggleBtn:SetPoint("RIGHT", refreshBtn, "LEFT", -6, 0)
    overlayToggleBtn:SetScript("OnClick", function()
        local db = InfinityBoss.MDT.EnsureDB()
        Overlay.SetEnabled(not (db.overlay and db.overlay.enabled ~= false))
        Page:_Refresh(Runtime.GetState())
    end)

    routeInfoText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    routeInfoText:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -8)
    routeInfoText:SetPoint("RIGHT", overlayToggleBtn, "LEFT", -10, 0)
    routeInfoText:SetJustifyH("LEFT")
    routeInfoText:SetTextColor(0.85, 0.9, 1)
    routeInfoText:SetText("")

    progressText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progressText:SetPoint("TOPLEFT", routeInfoText, "BOTTOMLEFT", 0, -4)
    progressText:SetPoint("RIGHT", refreshBtn, "LEFT", -10, 0)
    progressText:SetJustifyH("LEFT")
    progressText:SetTextColor(0.82, 0.9, 1)
    progressText:SetText("")
    if InfinityTools and InfinityTools.MAIN_FONT then
        progressText:SetFont(InfinityTools.MAIN_FONT, 15, "")
    end

    local presetLabel = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    presetLabel:SetPoint("TOPLEFT", progressText, "BOTTOMLEFT", 0, -20)
    presetLabel:SetText("Route Collection")
    presetLabel:SetTextColor(0.82, 0.86, 0.92)

    local InfinityUI = InfinityTools and InfinityTools.UI

    if InfinityUI and InfinityUI.CreateDropdown and ImportPreset then
        local initKey = ImportPreset.GetSelectedCollectionKey and ImportPreset.GetSelectedCollectionKey() or ""
        collectionDropdown = InfinityUI:CreateDropdown(root, 200, "", GetCollectionItems(), initKey, function(collKey)
            local ok, message = ImportPreset.SelectCollection(collKey)
            importPresetStatusText:SetText(tostring(message or ""))
            if ok then
                importPresetStatusText:SetTextColor(0.45, 0.95, 0.55)
            else
                importPresetStatusText:SetTextColor(1, 0.45, 0.45)
            end
            Page:_Refresh(Runtime.GetState())
        end)
        collectionDropdown:SetPoint("TOPLEFT", presetLabel, "BOTTOMLEFT", 0, -6)
    else
        collectionDropdown = nil
    end

    local importBtn = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
    importBtn:SetSize(70, 22)
    importBtn:SetText("Import MDT")
    importBtn:SetPoint("LEFT", collectionDropdown or presetLabel, "RIGHT", 8, 0)
    importBtn:SetScript("OnClick", function()
        local colKey = collectionDropdown and collectionDropdown._currentValue or ""
        if colKey == "" then
            colKey = ImportPreset.GetSelectedCollectionKey and ImportPreset.GetSelectedCollectionKey() or ""
        end
        local ok, message = ImportPreset.SwitchCollection(colKey)
        importPresetStatusText:SetText(tostring(message or ""))
        if ok then
            importPresetStatusText:SetTextColor(0.45, 0.95, 0.55)
        else
            importPresetStatusText:SetTextColor(1, 0.45, 0.45)
        end
        Page:_Refresh(Runtime.GetState())
    end)

    importPresetStatusText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    importPresetStatusText:SetPoint("TOPLEFT", collectionDropdown or presetLabel, "BOTTOMLEFT", 0, -8)
    importPresetStatusText:SetPoint("RIGHT", refreshBtn, "LEFT", -10, 0)
    importPresetStatusText:SetJustifyH("LEFT")
    importPresetStatusText:SetTextColor(0.82, 0.86, 0.92)
    importPresetStatusText:SetText("")

    local topY = -160
    local gap = 6
    local leftW = 392
    local topLeftH = 410

    local dungeonPane = CreateSectionBackdrop(root)
    dungeonPane:SetPoint("TOPLEFT", 8, topY)
    dungeonPane:SetWidth(leftW)
    dungeonPane:SetHeight(topLeftH)

    local pullPane = CreateSectionBackdrop(root)
    pullPane:SetPoint("TOPLEFT", dungeonPane, "BOTTOMLEFT", 0, -gap)
    pullPane:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 8, 8)
    pullPane:SetWidth(leftW)

    local rightPane = CreateSectionBackdrop(root)
    rightPane:SetPoint("TOPLEFT", dungeonPane, "TOPRIGHT", gap, 0)
    rightPane:SetPoint("BOTTOMRIGHT", -8, 8)

    local leftTitle = dungeonPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftTitle:SetPoint("TOPLEFT", 10, -8)
    leftTitle:SetText("Dungeons")
    leftTitle:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(leftTitle, "text") end
    if InfinityTools and InfinityTools.MAIN_FONT then
        leftTitle:SetFont(InfinityTools.MAIN_FONT, 16, "OUTLINE")
    end

    pullPaneTitle = pullPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pullPaneTitle:SetPoint("TOPLEFT", 10, -8)
    pullPaneTitle:SetText("MDT Pulls")
    pullPaneTitle:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(pullPaneTitle, "text") end
    if InfinityTools and InfinityTools.MAIN_FONT then
        pullPaneTitle:SetFont(InfinityTools.MAIN_FONT, 16, "OUTLINE")
    end

    detailTitle = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailTitle:SetPoint("TOPLEFT", 10, -8)
    detailTitle:SetText("Mobs / Spells")
    detailTitle:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(detailTitle, "text") end
    if InfinityTools and InfinityTools.MAIN_FONT then
        detailTitle:SetFont(InfinityTools.MAIN_FONT, 20, "OUTLINE")
    end

    noteLabel = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteLabel:SetPoint("TOPLEFT", detailTitle, "BOTTOMLEFT", 0, -6)
    noteLabel:SetText("Note")
    noteLabel:SetTextColor(0.9, 0.93, 1)
    if InfinityTools and InfinityTools.MAIN_FONT then
        noteLabel:SetFont(InfinityTools.MAIN_FONT, 16, "")
    end

    noteEditBox = CreateMultiLineInput(rightPane, 760, 92)
    noteEditBox:SetPoint("TOPLEFT", noteLabel, "BOTTOMLEFT", 0, -6)

    saveNoteBtn = CreateFrame("Button", nil, rightPane, "UIPanelButtonTemplate")
    saveNoteBtn:SetSize(80, 22)
    saveNoteBtn:SetPoint("TOPLEFT", noteEditBox, "TOPRIGHT", 10, 0)
    saveNoteBtn:SetText("Save Note")
    saveNoteBtn:SetScript("OnClick", function()
        local state = Runtime.GetState()
        if state and state.ok and state.snapshot then
            Runtime.SetPullNote(state.snapshot.routeKey, selectedPullIndex, noteEditBox:GetText())
        end
    end)

    pullImageFrame = CreateSectionBackdrop(rightPane)
    pullImageFrame:SetPoint("TOPLEFT", noteEditBox, "BOTTOMLEFT", 0, -12)
    pullImageFrame:SetSize(760, 260)

    pullImageTexture = pullImageFrame:CreateTexture(nil, "ARTWORK")
    pullImageTexture:SetPoint("TOPLEFT", 8, -8)
    pullImageTexture:SetPoint("BOTTOMRIGHT", -8, 26)
    pullImageTexture:SetTexCoord(0, 1, 0, 1)

    pullImageText = pullImageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pullImageText:SetPoint("LEFT", pullImageFrame, "BOTTOMLEFT", 10, 8)
    pullImageText:SetPoint("RIGHT", pullImageFrame, "BOTTOMRIGHT", -10, 8)
    pullImageText:SetJustifyH("LEFT")
    pullImageText:SetTextColor(0.82, 0.86, 0.92)
    pullImageText:SetText("Current pull image: none")

    dungeonScrollFrame = CreateFrame("ScrollFrame", nil, dungeonPane, "UIPanelScrollFrameTemplate")
    dungeonScrollFrame:SetPoint("TOPLEFT", 2, -30)
    dungeonScrollFrame:SetPoint("BOTTOMRIGHT", dungeonPane, "BOTTOMRIGHT", -22, 4)
    dungeonScrollChild = CreateFrame("Frame", nil, dungeonScrollFrame)
    dungeonScrollChild:SetWidth(leftW - 28)
    dungeonScrollChild:SetHeight(100)
    dungeonScrollFrame:SetScrollChild(dungeonScrollChild)

    pullScrollFrame = CreateFrame("ScrollFrame", nil, pullPane, "UIPanelScrollFrameTemplate")
    pullScrollFrame:SetPoint("TOPLEFT", 2, -30)
    pullScrollFrame:SetPoint("BOTTOMRIGHT", pullPane, "BOTTOMRIGHT", -22, 4)
    pullScrollChild = CreateFrame("Frame", nil, pullScrollFrame)
    pullScrollChild:SetWidth(leftW - 28)
    pullScrollChild:SetHeight(100)
    pullScrollFrame:SetScrollChild(pullScrollChild)

    settingsListFrame = CreateFrame("Frame", nil, pullPane)
    settingsListFrame:SetPoint("TOPLEFT", 12, -38)
    settingsListFrame:SetPoint("BOTTOMRIGHT", pullPane, "BOTTOMRIGHT", -28, 8)
    settingsListFrame:Hide()

    local settingsHeader = settingsListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsHeader:SetPoint("TOPLEFT", 0, 0)
    settingsHeader:SetText("General Settings")
    settingsHeader:SetTextColor(0.733, 0.4, 1.0)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(settingsHeader, "text") end
    if InfinityTools and InfinityTools.MAIN_FONT then
        settingsHeader:SetFont(InfinityTools.MAIN_FONT, 16, "OUTLINE")
    end

    local settingsDesc = settingsListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    settingsDesc:SetPoint("TOPLEFT", settingsHeader, "BOTTOMLEFT", 0, -8)
    settingsDesc:SetWidth(leftW - 40)
    settingsDesc:SetJustifyH("LEFT")
    settingsDesc:SetTextColor(0.82, 0.86, 0.92)
    settingsDesc:SetText("Control whether casters are shown in the overlay and detail panel.")

    if InfinityUI and InfinityUI.CreateCheckbox then
        showCasterCheck = InfinityUI:CreateCheckbox(settingsListFrame, "Show Casters", true, function(checked)
            Runtime.SetDisplayOption("showCasters", checked)
        end)
        showCasterCheck:SetPoint("TOPLEFT", settingsDesc, "BOTTOMLEFT", 0, -16)

        if showCasterCheck.label and InfinityTools and InfinityTools.MAIN_FONT then
            showCasterCheck.label:SetFont(InfinityTools.MAIN_FONT, 16, "")
        end
    end

    detailScrollFrame = CreateFrame("ScrollFrame", nil, rightPane, "UIPanelScrollFrameTemplate")
    detailScrollFrame:SetPoint("TOPLEFT", pullImageFrame, "BOTTOMLEFT", 2, -8)
    detailScrollFrame:SetPoint("BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -22, 4)
    detailScrollChild = CreateFrame("Frame", nil, detailScrollFrame)
    detailScrollChild:SetWidth(DETAIL_ROW_W + 16)
    detailScrollChild:SetHeight(220)
    detailScrollFrame:SetScrollChild(detailScrollChild)

    settingsScrollFrame = CreateFrame("ScrollFrame", nil, rightPane, "ScrollFrameTemplate")
    settingsScrollFrame:SetPoint("TOPLEFT", 4, -40)
    settingsScrollFrame:SetPoint("BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -24, 4)
    settingsScrollChild = CreateFrame("Frame", nil, settingsScrollFrame)
    settingsScrollChild:SetHeight(1)
    settingsScrollFrame:SetScrollChild(settingsScrollChild)
    settingsScrollFrame:Hide()

    if InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(dungeonScrollFrame)
        InfinityBoss.UI.ApplyModernScrollBarSkin(pullScrollFrame)
        InfinityBoss.UI.ApplyModernScrollBarSkin(detailScrollFrame)
        InfinityBoss.UI.ApplyModernScrollBarSkin(settingsScrollFrame)
    end

    UpdateLeftPaneMode()
    UpdateRightPaneMode()
end

function Page:Render(contentFrame)
    EnsureUI(contentFrame)
    root:SetParent(contentFrame)
    root:ClearAllPoints()
    root:SetAllPoints(contentFrame)
    root:Show()
    self:_Refresh(Runtime.GetState())
end

function Page:Hide()
    if root then
        root:Hide()
    end
end

Runtime.RegisterListener("MDTPage", function(state)
    if root and root:IsShown() then
        Page:_Refresh(state)
    end
end)

if InfinityTools and InfinityTools.WatchState then
    InfinityTools:WatchState(SETTINGS_MODULE_KEY .. ".DatabaseChanged", SETTINGS_MODULE_KEY .. "_cfg", function()
        Runtime.Refresh(true)
    end)
end
