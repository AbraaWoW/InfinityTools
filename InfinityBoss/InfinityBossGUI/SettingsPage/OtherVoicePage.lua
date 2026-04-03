---@diagnostic disable: undefined-global, undefined-field, need-check-nil

InfinityBoss.UI.Panel.OtherVoicePage = InfinityBoss.UI.Panel.OtherVoicePage or {}
local Page = InfinityBoss.UI.Panel.OtherVoicePage
local L = InfinityBoss.L or setmetatable({}, { __index = function(_, key) return key end })

local root = nil
local ui = {}

local THEME = {
    accent = { 0.733, 0.4, 1.0 },
    cyan = { 0.24, 0.78, 1.00 },
    ok = { 0.20, 0.95, 0.50 },
    muted = { 0.55, 0.60, 0.68 },
    border = { 0.18, 0.22, 0.28 },
}

local SOURCE_ITEMS = {
    { "Voice Pack Label", "pack" },
    { "LSM Sound", "lsm" },
    { "Custom Path", "file" },
}

local function Bg(parent, r, g, b, a)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(r or 0.03, g or 0.04, b or 0.07, a or 0.92)
    f:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.95)
    return f
end

local function TopBar(parent, r, g, b)
    local t = parent:CreateTexture(nil, "BORDER")
    t:SetColorTexture(r, g, b, 0.95)
    t:SetHeight(2)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6)
    return t
end

local function Trim(text)
    return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function NormalizeSourceType(value)
    local sourceType = tostring(value or "pack"):lower()
    if sourceType ~= "lsm" and sourceType ~= "file" then
        sourceType = "pack"
    end
    return sourceType
end

local function GetOtherSoundsModule()
    return InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.OtherSounds
end

local function GetConfig()
    local module = GetOtherSoundsModule()
    if module and module.GetPlayerCountdown5Config then
        return module:GetPlayerCountdown5Config()
    end
    return nil
end

local function FindItemText(items, value, fallback)
    local target = tostring(value or "")
    for i = 1, #(items or {}) do
        local row = items[i]
        if type(row) == "table" and tostring(row[2] or "") == target then
            return tostring(row[1] or "")
        end
    end
    return fallback or target
end

local function BuildLabelItems()
    local Catalog = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.LabelCatalog
    if Catalog and Catalog.GetDropdownItems then
        local items = Catalog.GetDropdownItems()
        if type(items) == "table" and #items > 0 then
            return items
        end
    end
    return {
        { "(No Labels)", "" },
    }
end

local function BuildLSMSoundItems()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local tbl = LSM and LSM:HashTable("sound") or nil
    local items = {}
    if type(tbl) == "table" then
        for key in pairs(tbl) do
            items[#items + 1] = { tostring(key), tostring(key) }
        end
        table.sort(items, function(a, b)
            return tostring(a[1] or "") < tostring(b[1] or "")
        end)
    end
    if #items == 0 then
        items[1] = { "(No LSM Sounds)", "" }
    end
    return items
end

local function SetEditBoxValue(widget, value)
    if not widget then
        return
    end
    if widget.HasFocus and widget:HasFocus() then
        return
    end
    if widget.SetText then
        widget:SetText(value or "")
    elseif widget.editBox and widget.editBox.SetText then
        widget.editBox:SetText(value or "")
    end
end

local function GetSelectedPackName()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    InfinityBossDB.voice.global = InfinityBossDB.voice.global or {}
    return tostring(InfinityBossDB.voice.global.selectedVoicePack or "Infinity(Default)")
end

local function PreviewCurrentConfig()
    local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    local cfg = GetConfig()
    if not (Engine and Engine.TryPlayStandaloneSound and cfg) then
        if ui.statusText then
            ui.statusText:SetText("|cffff6666Preview failed: voice engine not ready.|r")
        end
        return
    end

    local ok, err = Engine:TryPlayStandaloneSound(cfg, "preview:playerCountdown5", {
        ignoreState = true,
        triggerIndex = 2,
    })
    if ui.statusText then
        if ok then
            ui.statusText:SetText("|cff33dd88Preview succeeded.|r")
        else
            ui.statusText:SetText(string.format("|cffff6666Preview failed: %s|r", tostring(err or "unknown")))
        end
    end
end

local function RefreshControls()
    local cfg = GetConfig()
    if not cfg then
        return
    end

    local sourceType = NormalizeSourceType(cfg.sourceType)
    local labelItems = BuildLabelItems()
    local lsmItems = BuildLSMSoundItems()

    if ui.enableCheck and ui.enableCheck.SetChecked then
        ui.enableCheck:SetChecked(cfg.enabled == true)
    end

    if ui.sourceDropdown then
        ui.sourceDropdown._items = SOURCE_ITEMS
        ui.sourceDropdown._currentValue = sourceType
        ui.sourceDropdown:SetText(FindItemText(SOURCE_ITEMS, sourceType, "Voice Pack Label"))
    end

    if ui.labelDropdown then
        ui.labelDropdown._items = labelItems
        ui.labelDropdown._currentValue = tostring(cfg.label or "")
        ui.labelDropdown:SetText(FindItemText(labelItems, cfg.label, "Select a label"))
    end

    if ui.lsmDropdown then
        ui.lsmDropdown._items = lsmItems
        ui.lsmDropdown._currentValue = tostring(cfg.customLSM or "")
        ui.lsmDropdown:SetText(FindItemText(lsmItems, cfg.customLSM, "Select an LSM sound"))
    end

    SetEditBoxValue(ui.pathInput, tostring(cfg.customPath or ""))

    if ui.valueLabel then
        if sourceType == "pack" then
            ui.valueLabel:SetText("Voice Label")
        elseif sourceType == "lsm" then
            ui.valueLabel:SetText("LSM Sound")
        else
            ui.valueLabel:SetText("File Path")
        end
    end

    if ui.labelDropdown then ui.labelDropdown:SetShown(sourceType == "pack") end
    if ui.lsmDropdown then ui.lsmDropdown:SetShown(sourceType == "lsm") end
    if ui.pathInput then ui.pathInput:SetShown(sourceType == "file") end

    if ui.packInfo then
        ui.packInfo:SetText(string.format("Current voice pack: %s", GetSelectedPackName()))
    end
    if ui.runtimeInfo then
        ui.runtimeInfo:SetText("Listening event: START_PLAYER_COUNTDOWN\nTrigger: 5 seconds remaining\nIf a player starts a 10-second countdown, it will play once about 5 seconds after start.")
    end
end

local function BuildUI(contentFrame)
    local InfinityUI = _G.InfinityTools and _G.InfinityTools.UI

    for key in pairs(ui) do
        ui[key] = nil
    end

    root = CreateFrame("Frame", nil, contentFrame)
    root:SetAllPoints(contentFrame)

    local bg = root:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(root)
    bg:SetColorTexture(0.012, 0.016, 0.032, 0.96)

    local glow = root:CreateTexture(nil, "BACKGROUND", nil, 1)
    glow:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
    glow:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    glow:SetHeight(120)
    glow:SetColorTexture(0.06, 0.10, 0.22, 0.35)

    if not (InfinityUI and InfinityUI.CreateDropdown and InfinityUI.CreateCheckbox and InfinityUI.CreateEditBox) then
        local missing = root:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        missing:SetPoint("TOPLEFT", 24, -24)
        missing:SetPoint("RIGHT", root, "RIGHT", -24, 0)
        missing:SetJustifyH("LEFT")
        missing:SetTextColor(1, 0.4, 0.4)
        missing:SetText("The Other Voice page depends on InfinityTools.UI and is not ready. Confirm InfinityCore is loaded correctly, then reopen the panel.")
        root._missingDeps = true
        return
    end

    local title = root:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", 24, -22)
    title:SetTextColor(THEME.accent[1], THEME.accent[2], THEME.accent[3])
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(title, "text") end
    if _G.InfinityTools and _G.InfinityTools.MAIN_FONT then
        title:SetFont(_G.InfinityTools.MAIN_FONT, 24, "OUTLINE")
    else
        title:SetFontObject("GameFontNormalLarge")
    end
    title:SetText("Other Voice")

    local titleEn = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    titleEn:SetPoint("TOPLEFT", title, "TOPRIGHT", 10, -4)
    titleEn:SetText("OTHER VOICE")
    titleEn:SetTextColor(THEME.cyan[1], THEME.cyan[2], THEME.cyan[3])

    local desc = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    desc:SetText("Configure the 5-second team countdown voice.")
    desc:SetTextColor(0.60, 0.64, 0.72)

    local hLine = root:CreateTexture(nil, "ARTWORK")
    hLine:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    hLine:SetPoint("TOPRIGHT", root, "TOPRIGHT", -24, 0)
    hLine:SetHeight(1)
    hLine:SetColorTexture(0.22, 0.26, 0.32, 0.80)

    local leftPane = Bg(root, 0.03, 0.04, 0.07, 0.92)
    leftPane:SetPoint("TOPLEFT", root, "TOPLEFT", 24, -98)
    leftPane:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 24, 24)
    leftPane:SetWidth(760)
    local _tb1 = TopBar(leftPane, THEME.accent[1], THEME.accent[2], THEME.accent[3])
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(_tb1, "texture", 0.95) end
    ui.leftPane = leftPane

    local rightPane = Bg(root, 0.03, 0.04, 0.07, 0.92)
    rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 16, 0)
    rightPane:SetPoint("TOPRIGHT", root, "TOPRIGHT", -24, -98)
    rightPane:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -24, 24)
    TopBar(rightPane, THEME.cyan[1], THEME.cyan[2], THEME.cyan[3])
    ui.rightPane = rightPane

    local cfgTitle = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cfgTitle:SetPoint("TOPLEFT", 14, -12)
    cfgTitle:SetText("|cffffd16d" .. "Player Countdown: 5 Seconds" .. "|r")

    local cfgDesc = leftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cfgDesc:SetPoint("TOPLEFT", cfgTitle, "BOTTOMLEFT", 0, -6)
    cfgDesc:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -14, 0)
    cfgDesc:SetJustifyH("LEFT")
    cfgDesc:SetTextColor(0.72, 0.78, 0.86)
    cfgDesc:SetText("Uses `START_PLAYER_COUNTDOWN`. When any player starts a raid countdown, your configured sound will play exactly once at 5 seconds remaining.")

    ui.enableCheck = InfinityUI:CreateCheckbox(leftPane, "Enable player 5-second countdown voice", false, function(checked)
        local cfg = GetConfig()
        if not cfg then
            return
        end
        cfg.enabled = (checked == true)
        RefreshControls()
    end)
    ui.enableCheck:SetPoint("TOPLEFT", cfgDesc, "BOTTOMLEFT", 0, -18)

    local sourceLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sourceLabel:SetPoint("TOPLEFT", ui.enableCheck, "BOTTOMLEFT", 4, -18)
    sourceLabel:SetText("Voice Source")
    sourceLabel:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])

    ui.sourceDropdown = InfinityUI:CreateDropdown(leftPane, 220, "", SOURCE_ITEMS, "pack", function(value)
        local cfg = GetConfig()
        if not cfg then
            return
        end
        cfg.sourceType = NormalizeSourceType(value)
        RefreshControls()
    end)
    ui.sourceDropdown:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -6)

    ui.valueLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.valueLabel:SetPoint("TOPLEFT", ui.sourceDropdown, "TOPRIGHT", 24, 0)
    ui.valueLabel:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])

    ui.labelDropdown = InfinityUI:CreateDropdown(leftPane, 360, "", BuildLabelItems(), "", function(value)
        local cfg = GetConfig()
        if not cfg then
            return
        end
        cfg.label = tostring(value or "")
        RefreshControls()
    end)
    ui.labelDropdown:SetPoint("TOPLEFT", ui.valueLabel, "BOTTOMLEFT", 0, -6)

    ui.lsmDropdown = InfinityUI:CreateDropdown(leftPane, 360, "", BuildLSMSoundItems(), "", function(value)
        local cfg = GetConfig()
        if not cfg then
            return
        end
        cfg.customLSM = tostring(value or "")
        RefreshControls()
    end)
    ui.lsmDropdown:SetPoint("TOPLEFT", ui.valueLabel, "BOTTOMLEFT", 0, -6)

    ui.pathInput = InfinityUI:CreateEditBox(leftPane, "", 360, 28, "", {
        onEditFocusLost = function(text)
            local cfg = GetConfig()
            if not cfg then
                return
            end
            cfg.customPath = Trim(text)
            RefreshControls()
        end,
        onEnter = function(text)
            local cfg = GetConfig()
            if not cfg then
                return
            end
            cfg.customPath = Trim(text)
            RefreshControls()
        end,
    })
    ui.pathInput:SetPoint("TOPLEFT", ui.valueLabel, "BOTTOMLEFT", 0, -6)

    local previewBtn = CreateFrame("Button", nil, leftPane, "UIPanelButtonTemplate")
    previewBtn:SetSize(72, 24)
    previewBtn:SetPoint("TOPLEFT", ui.labelDropdown, "TOPRIGHT", 12, 1)
    previewBtn:SetText("Preview")
    previewBtn:SetScript("OnClick", function()
        PreviewCurrentConfig()
    end)
    ui.previewBtn = previewBtn

    ui.statusText = leftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.statusText:SetPoint("TOPLEFT", ui.sourceDropdown, "BOTTOMLEFT", 0, -44)
    ui.statusText:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -14, 0)
    ui.statusText:SetJustifyH("LEFT")
    ui.statusText:SetTextColor(0.70, 0.76, 0.84)
    ui.statusText:SetText("Click \"Preview\" to validate the current configuration.")

    ui.packInfo = leftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.packInfo:SetPoint("TOPLEFT", ui.statusText, "BOTTOMLEFT", 0, -10)
    ui.packInfo:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -14, 0)
    ui.packInfo:SetJustifyH("LEFT")
    ui.packInfo:SetTextColor(0.48, 0.78, 1.00)

    local rightTitle = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightTitle:SetPoint("TOPLEFT", 14, -12)
    rightTitle:SetText("|cff66d0ff" .. "Behavior" .. "|r")

    ui.runtimeInfo = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.runtimeInfo:SetPoint("TOPLEFT", rightTitle, "BOTTOMLEFT", 0, -12)
    ui.runtimeInfo:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, 0)
    ui.runtimeInfo:SetJustifyH("LEFT")
    ui.runtimeInfo:SetJustifyV("TOP")
    ui.runtimeInfo:SetTextColor(0.92, 0.95, 1.00)

    local noteTitle = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteTitle:SetPoint("TOPLEFT", ui.runtimeInfo, "BOTTOMLEFT", 0, -24)
    noteTitle:SetText("|cffffd16d" .. "Notes" .. "|r")

    local noteText = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteText:SetPoint("TOPLEFT", noteTitle, "BOTTOMLEFT", 0, -8)
    noteText:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, 0)
    noteText:SetJustifyH("LEFT")
    noteText:SetJustifyV("TOP")
    noteText:SetTextColor(0.75, 0.80, 0.88)
    noteText:SetText("1. This is a global setting, not part of the eventID table.\n2. Preview uses the current page config; live playback and preview share the same sound resolution path.\n3. If \"Voice Pack Label\" is used, the current global voice pack will be read.")

    local eventTitle = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    eventTitle:SetPoint("TOPLEFT", noteText, "BOTTOMLEFT", 0, -24)
    eventTitle:SetText("|cff66d0ff" .. "Event Payload" .. "|r")

    local eventText = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    eventText:SetPoint("TOPLEFT", eventTitle, "BOTTOMLEFT", 0, -8)
    eventText:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, 0)
    eventText:SetJustifyH("LEFT")
    eventText:SetJustifyV("TOP")
    eventText:SetTextColor(0.75, 0.80, 0.88)
    eventText:SetText("`START_PLAYER_COUNTDOWN: initiatedBy, timeRemaining, totalTime, informChat, initiatedByName`\nRuntime calculates the target moment from `timeRemaining`, so a 10-second countdown will play exactly at 5 seconds remaining instead of immediately at start.")
end

function Page:Render(contentFrame)
    if true then
        if contentFrame and contentFrame._placeholder then
            contentFrame._placeholder:SetText("Other voice features are temporarily disabled")
            contentFrame._placeholder:Show()
        end
        if root and root.Hide then
            root:Hide()
        end
        return
    end

    local InfinityUI = _G.InfinityTools and _G.InfinityTools.UI
    local uiReady = InfinityUI and InfinityUI.CreateDropdown and InfinityUI.CreateCheckbox and InfinityUI.CreateEditBox
    if root and root._missingDeps and uiReady then
        root:Hide()
        root = nil
    end
    if not root then
        BuildUI(contentFrame)
    end
    if not root then
        return
    end

    root:SetParent(contentFrame)
    root:ClearAllPoints()
    root:SetAllPoints(contentFrame)
    root:Show()

    if ui.leftPane then
        local leftW = math.max(680, math.floor((contentFrame:GetWidth() or 1200) * 0.58))
        ui.leftPane:SetWidth(leftW)
    end
    if ui.rightPane and ui.leftPane then
        ui.rightPane:SetPoint("TOPLEFT", ui.leftPane, "TOPRIGHT", 16, 0)
    end

    RefreshControls()
end

function Page:Hide()
    if root then
        root:Hide()
    end
end
