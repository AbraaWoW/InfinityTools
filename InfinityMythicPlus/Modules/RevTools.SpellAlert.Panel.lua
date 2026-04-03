-- =========================================================
-- RevTools.SpellAlert.Panel.lua
-- SpellAlert standalone floating panel, full migrated version
-- =========================================================
local ondev = false

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end

local RevUI = InfinityTools.UI
if not RevUI then
    print("|cffff0000[SpellAlert.Panel]|r RevUI not ready")
    return
end

-- =========================================================
-- Panel constants
-- =========================================================
local PANEL_TITLE     = "Spell Alert"
local PANEL_WIDTH     = 820
local PANEL_HEIGHT    = 700
local LIST_WIDTH      = 180 -- Left list width
local LIST_ITEM_H     = 36  -- One list item height

-- =========================================================
-- Panel state
-- =========================================================
local MainFrame
local MainPageTrigger
local MainPageCondition
local MainPageAction
local MainPageDisplay
local MainPageLoad
local SelectedMainTab = 1
local SetMainTab -- forward declaration

-- Left list
local ListScrollFrame
local ListScrollChild
local ListItems       = {}
local RefreshList -- forward declaration

-- =========================================================
-- Helper functions

-- =========================================================

local function EnsureSpecialFrame(name)
    _G.UISpecialFrames = _G.UISpecialFrames or {}
    for i = 1, #_G.UISpecialFrames do
        if _G.UISpecialFrames[i] == name then return end
    end
    table.insert(_G.UISpecialFrames, name)
end

local function IsElvUILoaded()
    local skin = InfinityTools.ElvUISkin
    return skin and skin.IsElvUILoaded and skin:IsElvUILoaded()
end

local function ApplyElvUISkin(frame)
    if not frame then return end
    local skin = InfinityTools.ElvUISkin
    if not (skin and skin.IsElvUILoaded and skin:IsElvUILoaded()) then return end
    skin:SkinFrame(frame, "Transparent")
end

-- =========================================================
-- Tab switching
-- =========================================================
SetMainTab = function(tabID)
    tabID = tonumber(tabID) or 1
    if tabID < 1 or tabID > 5 then tabID = 1 end

    SelectedMainTab = tabID

    if MainFrame and _G.PanelTemplates_SetTab then
        pcall(_G.PanelTemplates_SetTab, MainFrame, tabID)
    end

    if MainPageDisplay then MainPageDisplay:SetShown(tabID == 1) end
    if MainPageTrigger then MainPageTrigger:SetShown(tabID == 2) end
    if MainPageCondition then MainPageCondition:SetShown(tabID == 3) end
    if MainPageAction then MainPageAction:SetShown(tabID == 4) end
    if MainPageLoad then MainPageLoad:SetShown(tabID == 5) end
end

-- =========================================================
-- Access the SpellAlert DB and helper functions injected by SpellAlert.lua
-- =========================================================
-- Read lazily when the panel opens
local function GetDB()
    local db = InfinityTools.DB and InfinityTools.DB.ModuleDB
    return db and db["RevTools.SpellAlert"]
end

local function GetCurrentRule()
    local db = GetDB()
    if not db then return nil, nil end
    local sel = tonumber(db.selectedAlert) or 1
    if sel < 1 then sel = 1 end
    if #db.alerts > 0 and sel > #db.alerts then sel = #db.alerts end
    db.selectedAlert = sel
    return db.alerts[sel], sel
end

local function GetCurrentTrigger(rule)
    if not rule then return nil, 1 end

    if type(rule.triggers) ~= "table" then
        rule.triggers = {}
    end
    if type(rule.triggers[1]) ~= "table" then
        rule.triggers[1] = { type = "spell", enabled = true, spellID = "", icd = 0 }
    end

    -- Single-trigger mode: force only the first trigger
    local first = rule.triggers[1]
    rule.triggers = { first }
    rule.selectedTrigger = 1
    rule.triggerMode = nil

    return first, 1
end

-- =========================================================
-- Data option tables mirrored from SpellAlert.lua
-- =========================================================
local STATE_KEY_OPTIONS       = {
    { "Haste%", "PStat_Haste" },
    { "Critical Strike%", "PStat_Crit" },
    { "Mastery%", "PStat_Mastery" },
    { "Versatility%", "PStat_Versa" },
    { "Leech%", "PStat_Leech" },
    { "Avoidance%", "PStat_Avoidance" },
    { "Speed%", "PStat_Speed" },
    { "Primary Stat", "PStat_Major" },
    { "Strength", "PStat_Str" },
    { "Agility", "PStat_Agi" },
    { "Stamina", "PStat_Sta" },
    { "Intellect", "PStat_Int" },
    { "Armor", "PStat_Armor" },
    { "Max Health", "PStat_MaxHealth" },
    { "Item Level", "PStat_EquippedItemLevel" },
}

local STATE_CONDITION_OPTIONS = {
    { "Increase (buff gained)", "increase" },
    { "Decrease (buff faded)", "decrease" },
}

local TRIGGER_TYPE_OPTIONS    = {
    { "Spell Cast", "spell" },
    { "Stat Change", "state" },
    { "On Load", "onload" },
    { "Always Active", "always" },
}

-- =========================================================
-- Local isUnlocked state synchronized with SpellAlert.lua
-- =========================================================
local _isUnlocked             = false

-- =========================================================
-- Dynamic content widget tables for selective refresh
-- =========================================================

local DisplayWidgets          = {} -- Dynamic widgets for Tab 1
local TriggerWidgets          = {} -- Dynamic widgets for Tab 2
local ConditionWidgets        = {} -- Dynamic widgets for Tab 3
local ActionWidgets           = {} -- Dynamic widgets for Tab 4
local LoadWidgets             = {} -- Dynamic widgets for Tab 5

local function ClearWidgets(tbl)
    for _, w in pairs(tbl) do
        if w and w.Hide then w:Hide() end
        if w and w.SetParent then w:SetParent(nil) end
    end
    for k in pairs(tbl) do tbl[k] = nil end
end

-- =========================================================
-- Notify changes so SpellAlert.lua receives DatabaseChanged
-- =========================================================
local INFINITY_MODULE_KEY = "RevTools.SpellAlert"

local function NotifyChanged(key, fullPath)
    InfinityTools:UpdateState(INFINITY_MODULE_KEY .. ".DatabaseChanged", {
        key = key,
        fullPath = fullPath,
        ts = GetTime(),
    })
end

local function NotifyButtonClicked(key)
    InfinityTools:UpdateState(INFINITY_MODULE_KEY .. ".ButtonClicked", {
        key = key,
        ts = GetTime(),
    })
end

-- =========================================================
-- Global refresh entry point
-- =========================================================
local BuildTriggerPage   -- forward declaration
local BuildConditionPage -- forward declaration
local BuildActionPage    -- forward declaration
local BuildStylePage     -- forward declaration
local BuildLoadPage      -- forward declaration

local function RefreshPanel()
    if not MainFrame or not MainFrame:IsShown() then return end
    -- Rebuild page contents
    BuildTriggerPage()
    BuildConditionPage()
    BuildActionPage()
    BuildStylePage()
    BuildLoadPage()
    -- Keep the current tab
    SetMainTab(SelectedMainTab)
    -- Refresh the left list
    RefreshList()
end

-- =========================================================
-- Right-click menu and rule movement
-- =========================================================
local ContextMenuFrame
local FallbackContextMenuFrame

local function ShowFallbackContextMenu(menuList)
    if not FallbackContextMenuFrame then
        local f = CreateFrame("Frame", "EXSA_FallbackContextMenu", UIParent, "BackdropTemplate")
        f:SetFrameStrata("DIALOG")
        f:SetSize(168, 10)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.96)
        f.buttons = {}

        local overlay = CreateFrame("Button", nil, f)
        overlay:SetFrameLevel(f:GetFrameLevel() - 1)
        overlay:SetAllPoints(UIParent)
        overlay:SetScript("OnClick", function() f:Hide() end)
        f.overlay = overlay

        FallbackContextMenuFrame = f
    end

    local frame = FallbackContextMenuFrame
    frame:Hide()
    for _, b in ipairs(frame.buttons) do b:Hide() end

    local y = -6
    for i, info in ipairs(menuList) do
        local btn = frame.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, frame)
            btn:SetSize(150, 20)
            local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            txt:SetPoint("LEFT", 8, 0)
            btn.text = txt

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.16)
            btn:SetHighlightTexture(hl)

            btn:SetScript("OnClick", function(self)
                frame:Hide()
                if self.func then
                    local ok, err = pcall(self.func)
                    if not ok then
                        print("|cffff0000[SpellAlert.Panel] Right-click menu failed:|r " .. tostring(err))
                    end
                end
            end)
            frame.buttons[i] = btn
        end

        local text = info.text
        if info.disabled and (not text or text == "") then
            text = "----------------"
        end

        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, y)
        btn.text:SetText(text or "")
        btn.func = info.func
        btn:Show()

        if info.disabled or info.isTitle then
            btn:Disable()
            btn.text:SetTextColor(0.65, 0.65, 0.65)
        else
            btn:Enable()
            btn.text:SetTextColor(1, 1, 1)
        end

        y = y - 20
    end

    frame:SetHeight(-y + 8)
    frame:ClearAllPoints()
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale + 5, cy / scale - 5)
    frame:Show()
end

local function MoveRule(idx, dir)
    local db = GetDB()
    if not db then return end
    local newIdx = idx + dir
    if newIdx < 1 or newIdx > #db.alerts then return end
    db.alerts[idx], db.alerts[newIdx] = db.alerts[newIdx], db.alerts[idx]
    db.selectedAlert = newIdx
    NotifyButtonClicked("btn_move_rule")
    C_Timer.After(0.05, RefreshPanel)
end

local function ShowListContextMenu(ruleIndex)
    local menuList = {
        { text = "Move Up", notCheckable = true, func = function() MoveRule(ruleIndex, -1) end },
        { text = "Move Down", notCheckable = true, func = function() MoveRule(ruleIndex, 1) end },
        { text = "Export", notCheckable = true, func = function() NotifyButtonClicked("btn_export") end },
        { text = "", notCheckable = true, disabled = true },
        {
            text = "|cffff4444Delete|r",
            notCheckable = true,
            func = function()
                NotifyButtonClicked("btn_del_rule")
                C_Timer.After(0.05, RefreshPanel)
            end
        },
    }
    if _G.EasyMenu then
        if not ContextMenuFrame then
            ContextMenuFrame = CreateFrame("Frame", "EXSA_ContextMenu", UIParent, "UIDropDownMenuTemplate")
        end
        _G.EasyMenu(menuList, ContextMenuFrame, "cursor", 0, 0, "MENU")
        return
    end

    ShowFallbackContextMenu(menuList)
end

-- =========================================================
-- Left list refresh
-- =========================================================
RefreshList = function()
    local db = GetDB()
    if not db or not ListScrollChild then return end

    -- Hide stale list items
    for _, item in ipairs(ListItems) do item:Hide() end
    ListItems = {}

    local sel = db.selectedAlert or 1
    local totalH = 0

    for i, rule in ipairs(db.alerts) do
        local item = CreateFrame("Button", nil, ListScrollChild)
        item:SetSize(LIST_WIDTH - 22, LIST_ITEM_H)
        item:SetPoint("TOPLEFT", ListScrollChild, "TOPLEFT", 0, -totalH)

        -- Selected background
        local bg = item:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        local function UpdateBg()
            local isSel = (db.selectedAlert == i)
            if isSel then
                bg:SetColorTexture(0.2, 0.5, 1.0, 0.3)
            else
                bg:SetColorTexture(0, 0, 0, 0)
            end
        end
        UpdateBg()

        item:SetScript("OnEnter", function()
            if db.selectedAlert ~= i then bg:SetColorTexture(1, 1, 1, 0.06) end
        end)
        item:SetScript("OnLeave", function() UpdateBg() end)

        -- Enabled status dot
        local dot = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dot:SetPoint("LEFT", item, "LEFT", 4, 0)
        dot:SetText(rule.enabled and "|cff00ff00●|r" or "|cff555555○|r")
        dot:SetWidth(14)

        -- Icon, from iconID or current trigger spell icon
        local iconTex = item:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(24, 24)
        iconTex:SetPoint("LEFT", dot, "RIGHT", 2, 0)
        iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local iconVal = rule.iconID
        if not iconVal or iconVal == "" then
            local t = GetCurrentTrigger(rule)
            if t and t.type == "spell" and t.spellID and t.spellID ~= "" then
                local tex = C_Spell and C_Spell.GetSpellTexture(tonumber(t.spellID))
                if tex then iconVal = tex end
            end
        end
        iconTex:SetTexture(iconVal or 134400)

        -- Rule name
        local lbl = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", iconTex, "RIGHT", 4, 0)
        lbl:SetPoint("RIGHT", item, "RIGHT", -2, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText((rule.name and rule.name ~= "") and rule.name or ("Rule " .. i))

        -- Click handling
        item:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        item:SetScript("OnClick", function(_, btn)
            if btn == "RightButton" then
                db.selectedAlert = i
                ShowListContextMenu(i)
            else
                db.selectedAlert = i
                NotifyChanged("selectedAlert", "selectedAlert")
                RefreshPanel()
            end
        end)

        table.insert(ListItems, item)
        totalH = totalH + LIST_ITEM_H
    end

    ListScrollChild:SetHeight(math.max(totalH, 10))
end

-- =========================================================
-- Build the left list panel once from CreateMainFrame
-- =========================================================
local function BuildListPanel()
    -- Vertical divider
    local divV = MainFrame:CreateTexture(nil, "ARTWORK")
    divV:SetWidth(1)
    divV:SetPoint("TOP", MainFrame, "TOPLEFT", LIST_WIDTH + 8, -55)
    divV:SetPoint("BOTTOM", MainFrame, "BOTTOMLEFT", LIST_WIDTH + 8, 10)
    divV:SetTexture("Interface\\Buttons\\WHITE8X8")
    divV:SetVertexColor(1, 1, 1, 0.15)

    -- ScrollFrame
    ListScrollFrame = CreateFrame("ScrollFrame", nil, MainFrame, "UIPanelScrollFrameTemplate")
    ListScrollFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", 8, -55)
    ListScrollFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMLEFT", LIST_WIDTH - 2, 44)

    ListScrollChild = CreateFrame("Frame")
    ListScrollChild:SetWidth(LIST_WIDTH - 22)
    ListScrollChild:SetHeight(10)
    ListScrollFrame:SetScrollChild(ListScrollChild)

    -- Bottom button row
    local btnAdd = RevUI:CreateButton(MainFrame, 96, 22, "+ New Alert", function()
        local menuList = {
            { text = "Icon", notCheckable = true, func = function() NotifyButtonClicked("btn_add_rule_icon") end },
            { text = "Bar", notCheckable = true, func = function() NotifyButtonClicked("btn_add_rule_bar") end },
            { text = "Text", notCheckable = true, func = function() NotifyButtonClicked("btn_add_rule_text") end },
        }
        if _G.EasyMenu then
            if not ContextMenuFrame then
                ContextMenuFrame = CreateFrame("Frame", "EXSA_ContextMenu", UIParent, "UIDropDownMenuTemplate")
            end
            _G.EasyMenu(menuList, ContextMenuFrame, "cursor", 0, 0, "MENU")
        else
            ShowFallbackContextMenu(menuList)
        end
        C_Timer.After(0.1, RefreshPanel)
    end)
    btnAdd:SetPoint("BOTTOMLEFT", MainFrame, "BOTTOMLEFT", 8, 12)

    local btnImport = RevUI:CreateButton(MainFrame, 72, 22, "Import", function()
        NotifyButtonClicked("btn_import")
        C_Timer.After(0.3, RefreshPanel)
    end)
    btnImport:SetPoint("LEFT", btnAdd, "RIGHT", 6, 0)
end

-- =========================================================
-- Tab 2: Trigger page
-- =========================================================
BuildTriggerPage = function()
    -- Clear old widgets
    ClearWidgets(TriggerWidgets)

    local db = GetDB()
    if not db then return end

    local rule, sel = GetCurrentRule()
    if not rule then return end

    local trigger = GetCurrentTrigger(rule)

    local page = MainPageTrigger
    local FONT = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"

    -- Rule basics
    -- Enable rule
    local cbEnabled = RevUI:CreateCheckbox(page, "Enable Rule", rule.enabled, function(checked)
        rule.enabled = checked
        NotifyChanged("enabled", "alerts." .. sel .. ".enabled")
    end)
    cbEnabled:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -8)
    TriggerWidgets.cbEnabled = cbEnabled

    -- Rule name
    local lblName = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblName:SetPoint("TOPLEFT", page, "TOPLEFT", 160, -8)
    lblName:SetText("Rule Name:")
    TriggerWidgets.lblName = lblName

    local editName = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editName:SetSize(160, 24)
    editName:SetPoint("TOPLEFT", page, "TOPLEFT", 228, -4)
    editName:SetAutoFocus(false)
    editName:SetText(rule.name or "")
    editName:SetScript("OnEnterPressed", function(self)
        rule.name = self:GetText()
        NotifyChanged("name", "alerts." .. sel .. ".name")
        self:ClearFocus()
        RefreshPanel()
    end)
    editName:SetScript("OnEditFocusLost", function(self)
        rule.name = self:GetText()
        NotifyChanged("name", "alerts." .. sel .. ".name")
        RefreshPanel()
    end)
    TriggerWidgets.editName = editName

    -- Delay
    local lblDelay = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblDelay:SetPoint("TOPLEFT", page, "TOPLEFT", 400, -8)
    lblDelay:SetText("Delay (sec):")
    TriggerWidgets.lblDelay = lblDelay

    local editDelay = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editDelay:SetSize(60, 24)
    editDelay:SetPoint("TOPLEFT", page, "TOPLEFT", 460, -4)
    editDelay:SetAutoFocus(false)
    editDelay:SetNumeric(false)
    editDelay:SetText(tostring(rule.delay or 0))
    editDelay:SetScript("OnEnterPressed", function(self)
        rule.delay = tonumber(self:GetText()) or 0
        NotifyChanged("delay", "alerts." .. sel .. ".delay")
        self:ClearFocus()
    end)
    editDelay:SetScript("OnEditFocusLost", function(self)
        rule.delay = tonumber(self:GetText()) or 0
        NotifyChanged("delay", "alerts." .. sel .. ".delay")
    end)
    TriggerWidgets.editDelay = editDelay

    -- Divider
    local div1 = page:CreateTexture(nil, "ARTWORK")
    div1:SetHeight(1)
    div1:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -38)
    div1:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -38)
    div1:SetTexture("Interface\\Buttons\\WHITE8X8")
    div1:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.3), CreateColor(1, 1, 1, 0.05))
    TriggerWidgets.div1 = div1

    -- Single trigger title
    local lblTrig = page:CreateFontString(nil, "OVERLAY")
    lblTrig:SetFont(FONT, 14, "OUTLINE")
    lblTrig:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -54)
    lblTrig:SetTextColor(1, 0.82, 0)
    lblTrig:SetText("Trigger")
    TriggerWidgets.lblTrig = lblTrig

    local lblTrigHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblTrigHint:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -76)
    lblTrigHint:SetTextColor(0.7, 0.7, 0.7)
    lblTrigHint:SetText("Each rule keeps a single trigger. You can switch between spell cast, stat change, on load, and always active.")
    TriggerWidgets.lblTrigHint = lblTrigHint

    -- Enable trigger
    local cbTrigEnabled = RevUI:CreateCheckbox(page, "Enable Trigger", trigger.enabled ~= false,
        function(checked)
            trigger.enabled = checked
            NotifyChanged("enabled", "alerts." .. sel .. ".trigger.enabled")
        end
    )
    cbTrigEnabled:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -102)
    TriggerWidgets.cbTrigEnabled = cbTrigEnabled

    -- Trigger type dropdown
    local lblType = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblType:SetPoint("TOPLEFT", page, "TOPLEFT", 200, -102)
    lblType:SetText("Type:")
    TriggerWidgets.lblType = lblType

    local ddType = RevUI:CreateDropdown(page, 160, "", TRIGGER_TYPE_OPTIONS,
        trigger.type or "spell",
        function(val)
            local enabled = trigger.enabled ~= false
            if val == "state" then
                trigger = {
                    type = "state",
                    enabled = enabled,
                    stateKey = trigger.stateKey or "PStat_Haste",
                    condition = trigger.condition or "increase",
                    min = tonumber(trigger.min) or 0,
                    max = tonumber(trigger.max) or 100,
                    margin = tonumber(trigger.margin) or 0.1,
                }
            elseif val == "onload" then
                trigger = {
                    type = "onload",
                    enabled = enabled,
                    after = tonumber(trigger.after) or 0,
                }
            elseif val == "always" then
                trigger = {
                    type = "always",
                    enabled = enabled,
                }
            else
                trigger = {
                    type = "spell",
                    enabled = enabled,
                    spellID = tostring(trigger.spellID or ""),
                    icd = tonumber(trigger.icd) or 0,
                }
            end
            rule.triggers[1] = trigger
            NotifyChanged("type", "alerts." .. sel .. ".trigger.type")
            BuildTriggerPage()
            SetMainTab(SelectedMainTab)
        end
    )
    ddType:SetPoint("TOPLEFT", page, "TOPLEFT", 234, -98)
    TriggerWidgets.ddType = ddType

    -- Divider
    local div2 = page:CreateTexture(nil, "ARTWORK")
    div2:SetHeight(1)
    div2:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -132)
    div2:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -132)
    div2:SetTexture("Interface\\Buttons\\WHITE8X8")
    div2:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.3), CreateColor(1, 1, 1, 0.05))
    TriggerWidgets.div2 = div2

    local function BuildDurationEditor(y, permanent)
        local lblDur = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblDur:SetPoint("TOPLEFT", page, "TOPLEFT", 400, y)
        lblDur:SetText("Duration:")
        TriggerWidgets.lblDur = lblDur

        if permanent then
            local lblDurVal = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lblDurVal:SetPoint("TOPLEFT", page, "TOPLEFT", 462, y)
            lblDurVal:SetTextColor(0.4, 1, 0.4)
            lblDurVal:SetText("Permanent")
            TriggerWidgets.lblDurVal = lblDurVal
            return
        end

        local editDur = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editDur:SetSize(72, 24)
        editDur:SetPoint("TOPLEFT", page, "TOPLEFT", 462, y + 4)
        editDur:SetAutoFocus(false)
        editDur:SetText(tostring(rule.duration or 2))
        editDur:SetScript("OnEnterPressed", function(self)
            rule.duration = math.max(0.05, tonumber(self:GetText()) or 2)
            NotifyChanged("duration", "alerts." .. sel .. ".duration")
            self:ClearFocus()
        end)
        editDur:SetScript("OnEditFocusLost", function(self)
            rule.duration = math.max(0.05, tonumber(self:GetText()) or 2)
            NotifyChanged("duration", "alerts." .. sel .. ".duration")
            self:SetText(tostring(rule.duration))
        end)
        TriggerWidgets.editDur = editDur
    end

    -- Spell trigger parameters
    if trigger.type == "spell" then
        BuildDurationEditor(-146, false)

        local lblSpell = page:CreateFontString(nil, "OVERLAY")
        lblSpell:SetFont(FONT, 13, "OUTLINE")
        lblSpell:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -146)
        lblSpell:SetTextColor(0.6, 0.9, 1)
        lblSpell:SetText("Spell Trigger")
        TriggerWidgets.lblSpell = lblSpell

        local lblSID = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblSID:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -172)
        lblSID:SetText("Spell ID:")
        TriggerWidgets.lblSID = lblSID

        local editSID = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editSID:SetSize(100, 24)
        editSID:SetPoint("TOPLEFT", page, "TOPLEFT", 64, -168)
        editSID:SetAutoFocus(false)
        editSID:SetText(tostring(trigger.spellID or ""))
        editSID:SetScript("OnEnterPressed", function(self)
            trigger.spellID = self:GetText()
            NotifyChanged("spellID", "alerts." .. sel .. ".trigger.spellID")
            self:ClearFocus()
        end)
        editSID:SetScript("OnEditFocusLost", function(self)
            trigger.spellID = self:GetText()
            NotifyChanged("spellID", "alerts." .. sel .. ".trigger.spellID")
        end)
        TriggerWidgets.editSID = editSID

        local lblICD = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblICD:SetPoint("TOPLEFT", page, "TOPLEFT", 200, -172)
        lblICD:SetText("Debounce Cooldown (sec):")
        TriggerWidgets.lblICD = lblICD

        local editICD = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editICD:SetSize(80, 24)
        editICD:SetPoint("TOPLEFT", page, "TOPLEFT", 300, -168)
        editICD:SetAutoFocus(false)
        editICD:SetText(tostring(trigger.icd or 0))
        editICD:SetScript("OnEnterPressed", function(self)
            trigger.icd = tonumber(self:GetText()) or 0
            NotifyChanged("icd", "alerts." .. sel .. ".trigger.icd")
            self:ClearFocus()
        end)
        editICD:SetScript("OnEditFocusLost", function(self)
            trigger.icd = tonumber(self:GetText()) or 0
            NotifyChanged("icd", "alerts." .. sel .. ".trigger.icd")
        end)
        TriggerWidgets.editICD = editICD

        -- Spell ID hint
        local lblHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblHint:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -200)
        lblHint:SetTextColor(0.7, 0.7, 0.7)
        lblHint:SetText("Tip: You can get a Spell ID in game with /run print(C_Spell.GetSpellInfo(ID).name), or look it up on Wowhead.")
        lblHint:SetWordWrap(true)
        lblHint:SetWidth(560)
        TriggerWidgets.lblHint = lblHint

        -- State-change trigger parameters
    elseif trigger.type == "state" then
        BuildDurationEditor(-146, false)

        local lblState = page:CreateFontString(nil, "OVERLAY")
        lblState:SetFont(FONT, 13, "OUTLINE")
        lblState:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -146)
        lblState:SetTextColor(0.6, 1, 0.6)
        lblState:SetText("Stat Change Trigger (WatchStateDelta)")
        TriggerWidgets.lblState = lblState

        -- Watched state key
        local lblSK = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblSK:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -172)
        lblSK:SetText("Watched Stat:")
        TriggerWidgets.lblSK = lblSK

        local ddSK = RevUI:CreateDropdown(page, 180, "", STATE_KEY_OPTIONS,
            trigger.stateKey or "PStat_Haste",
            function(val)
                trigger.stateKey = val
                NotifyChanged("stateKey", "alerts." .. sel .. ".trigger.stateKey")
            end
        )
        ddSK:SetPoint("TOPLEFT", page, "TOPLEFT", 70, -168)
        TriggerWidgets.ddSK = ddSK

        -- Change direction
        local lblCond = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblCond:SetPoint("TOPLEFT", page, "TOPLEFT", 280, -172)
        lblCond:SetText("Change Direction:")
        TriggerWidgets.lblCond = lblCond

        local ddCond = RevUI:CreateDropdown(page, 180, "", STATE_CONDITION_OPTIONS,
            trigger.condition or "increase",
            function(val)
                trigger.condition = val
                NotifyChanged("condition", "alerts." .. sel .. ".trigger.condition")
            end
        )
        ddCond:SetPoint("TOPLEFT", page, "TOPLEFT", 354, -168)
        TriggerWidgets.ddCond = ddCond

        -- Delta range hint
        local lblRangeDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblRangeDesc:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -202)
        lblRangeDesc:SetTextColor(0.8, 0.8, 0.8)
        lblRangeDesc:SetText("Delta range: triggers when the stat change falls within [min, max]. Percent-based stats use the same units shown in game (example: about +30% haste means 25~35).")
        lblRangeDesc:SetWordWrap(true)
        lblRangeDesc:SetWidth(560)
        TriggerWidgets.lblRangeDesc = lblRangeDesc

        -- Minimum delta
        local lblMin = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblMin:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -228)
        lblMin:SetText("Min Delta:")
        TriggerWidgets.lblMin = lblMin

        local editMin = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editMin:SetSize(80, 24)
        editMin:SetPoint("TOPLEFT", page, "TOPLEFT", 68, -224)
        editMin:SetAutoFocus(false)
        editMin:SetText(tostring(trigger.min or 0))
        editMin:SetScript("OnEnterPressed", function(self)
            trigger.min = tonumber(self:GetText()) or 0
            NotifyChanged("min", "alerts." .. sel .. ".trigger.min")
            self:ClearFocus()
        end)
        editMin:SetScript("OnEditFocusLost", function(self)
            trigger.min = tonumber(self:GetText()) or 0
            NotifyChanged("min", "alerts." .. sel .. ".trigger.min")
        end)
        TriggerWidgets.editMin = editMin

        -- Maximum delta
        local lblMax = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblMax:SetPoint("TOPLEFT", page, "TOPLEFT", 170, -228)
        lblMax:SetText("Max Delta:")
        TriggerWidgets.lblMax = lblMax

        local editMax = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editMax:SetSize(80, 24)
        editMax:SetPoint("TOPLEFT", page, "TOPLEFT", 238, -224)
        editMax:SetAutoFocus(false)
        editMax:SetText(tostring(trigger.max or 100))
        editMax:SetScript("OnEnterPressed", function(self)
            trigger.max = tonumber(self:GetText()) or 100
            NotifyChanged("max", "alerts." .. sel .. ".trigger.max")
            self:ClearFocus()
        end)
        editMax:SetScript("OnEditFocusLost", function(self)
            trigger.max = tonumber(self:GetText()) or 100
            NotifyChanged("max", "alerts." .. sel .. ".trigger.max")
        end)
        TriggerWidgets.editMax = editMax

        -- Tolerance
        local lblMargin = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblMargin:SetPoint("TOPLEFT", page, "TOPLEFT", 340, -228)
        lblMargin:SetText("Tolerance (0~1):")
        TriggerWidgets.lblMargin = lblMargin

        local editMargin = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editMargin:SetSize(80, 24)
        editMargin:SetPoint("TOPLEFT", page, "TOPLEFT", 418, -224)
        editMargin:SetAutoFocus(false)
        editMargin:SetText(tostring(trigger.margin or 0.1))
        editMargin:SetScript("OnEnterPressed", function(self)
            trigger.margin = tonumber(self:GetText()) or 0.1
            NotifyChanged("margin", "alerts." .. sel .. ".trigger.margin")
            self:ClearFocus()
        end)
        editMargin:SetScript("OnEditFocusLost", function(self)
            trigger.margin = tonumber(self:GetText()) or 0.1
            NotifyChanged("margin", "alerts." .. sel .. ".trigger.margin")
        end)
        TriggerWidgets.editMargin = editMargin
    elseif trigger.type == "onload" then
        BuildDurationEditor(-146, false)

        local lblOnLoad = page:CreateFontString(nil, "OVERLAY")
        lblOnLoad:SetFont(FONT, 13, "OUTLINE")
        lblOnLoad:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -146)
        lblOnLoad:SetTextColor(0.95, 0.95, 0.6)
        lblOnLoad:SetText("On Load Trigger")
        TriggerWidgets.lblOnLoad = lblOnLoad

        local lblAfter = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblAfter:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -172)
        lblAfter:SetText("Delay After Load (sec):")
        TriggerWidgets.lblAfter = lblAfter

        local editAfter = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editAfter:SetSize(80, 24)
        editAfter:SetPoint("TOPLEFT", page, "TOPLEFT", 96, -168)
        editAfter:SetAutoFocus(false)
        editAfter:SetText(tostring(trigger.after or 0))
        editAfter:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText()) or 0
            if v < 0 then v = 0 end
            trigger.after = v
            NotifyChanged("after", "alerts." .. sel .. ".trigger.after")
            self:SetText(tostring(v))
            self:ClearFocus()
        end)
        editAfter:SetScript("OnEditFocusLost", function(self)
            local v = tonumber(self:GetText()) or 0
            if v < 0 then v = 0 end
            trigger.after = v
            NotifyChanged("after", "alerts." .. sel .. ".trigger.after")
            self:SetText(tostring(v))
        end)
        TriggerWidgets.editAfter = editAfter

        local lblOnLoadDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblOnLoadDesc:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -200)
        lblOnLoadDesc:SetTextColor(0.72, 0.72, 0.72)
        lblOnLoadDesc:SetWordWrap(true)
        lblOnLoadDesc:SetWidth(560)
        lblOnLoadDesc:SetText("Triggers once when load conditions change from unmet to met. You can add a delay in seconds. If the load conditions fail and become valid again, it will trigger again.")
        TriggerWidgets.lblOnLoadDesc = lblOnLoadDesc
    elseif trigger.type == "always" then
        BuildDurationEditor(-146, true)

        local lblAlways = page:CreateFontString(nil, "OVERLAY")
        lblAlways:SetFont(FONT, 13, "OUTLINE")
        lblAlways:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -146)
        lblAlways:SetTextColor(1, 0.9, 0.5)
        lblAlways:SetText("Always Active Trigger")
        TriggerWidgets.lblAlways = lblAlways

        local lblAlwaysDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblAlwaysDesc:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -172)
        lblAlwaysDesc:SetTextColor(0.72, 0.72, 0.72)
        lblAlwaysDesc:SetWordWrap(true)
        lblAlwaysDesc:SetWidth(560)
        lblAlwaysDesc:SetText("This trigger has no extra parameters. It fires automatically when load conditions are met and works well with text-based scene prompts.")
        TriggerWidgets.lblAlwaysDesc = lblAlwaysDesc
    end
end

-- =========================================================
-- Helper: parse/format ID lists for Conditions and Load tabs
-- =========================================================
local function ParseIDList(str)
    local ids = {}
    for s in tostring(str or ""):gmatch("[^%s,]+") do
        local n = tonumber(s)
        if n then table.insert(ids, n) end
    end
    return ids
end

local function FormatIDList(tbl)
    local parts = {}
    for _, v in ipairs(tbl or {}) do
        table.insert(parts, tostring(v))
    end
    return table.concat(parts, ", ")
end

-- =========================================================
-- Generic condition block builder shared by Conditions and Load tabs
-- Parameters:
-- page = parent frame
-- cData = rule.conditions or rule.loadConditions
-- widgets = widget table for this page
-- startY = starting Y offset from TOPLEFT, negative value
-- prefix = NotifyChanged key prefix
-- sel = rule index
-- isLoad = true to also show inInstance/mapIDs
-- Returns: final Y offset used
-- =========================================================
local COMBAT_OPTIONS = {
    { "Any", "any" },
    { "In Combat", "true" },
    { "Out of Combat", "false" },
}
local INSTANCE_TYPE_OPTIONS = {
    { "Dungeon (dungeon)", "dungeon" },
    { "Raid (raid)", "raid" },
    { "Battleground (pvp)", "pvp" },
    { "Arena (arena)", "arena" },
    { "None (none)", "none" },
}

local function CombatBoolToOption(v)
    if v == true then return "true" end
    if v == false then return "false" end
    return "any"
end
local function OptionToCombatBool(s)
    if s == "true" then return true end
    if s == "false" then return false end
    return nil
end

local function BuildConditionBlock(page, cData, widgets, startY, prefix, sel, isLoad)
    local FONT = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"
    local y = startY

    -- Divider
    local divE = page:CreateTexture(nil, "ARTWORK")
    divE:SetHeight(1)
    divE:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    divE:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, y)
    divE:SetTexture("Interface\\Buttons\\WHITE8X8")
    divE:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.25), CreateColor(1, 1, 1, 0.05))
    widgets.divE = divE
    y = y - 14

    -- Combat state
    local lblCombat = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblCombat:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblCombat:SetText("Combat State:")
    widgets.lblCombat = lblCombat

    local ddCombat = RevUI:CreateDropdown(page, 160, "", COMBAT_OPTIONS,
        CombatBoolToOption(cData.inCombat),
        function(val)
            cData.inCombat = OptionToCombatBool(val)
            NotifyChanged(isLoad and "loadConditions" or "conditions",
                "alerts." .. sel .. "." .. prefix)
        end
    )
    ddCombat:SetPoint("TOPLEFT", page, "TOPLEFT", 70, y + 4)
    widgets.ddCombat = ddCombat
    y = y - 36

    -- In instance, Load tab only
    if isLoad then
        local lblInst = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblInst:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
        lblInst:SetText("In Instance:")
        widgets.lblInst = lblInst

        local INST_OPTIONS = {
            { "Any", "any" },
            { "Yes", "true" },
            { "No", "false" },
        }
        local ddInst = RevUI:CreateDropdown(page, 120, "", INST_OPTIONS,
            CombatBoolToOption(cData.inInstance),
            function(val)
                cData.inInstance = OptionToCombatBool(val)
                NotifyChanged("loadConditions", "alerts." .. sel .. "." .. prefix)
            end
        )
        ddInst:SetPoint("TOPLEFT", page, "TOPLEFT", 70, y + 4)
        widgets.ddInst = ddInst
        y = y - 36
    end

    -- Spec IDs, comma-separated EditBox
    local lblSpec = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblSpec:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblSpec:SetText("Spec ID:")
    widgets.lblSpec = lblSpec

    local editSpec = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editSpec:SetSize(200, 24)
    editSpec:SetPoint("TOPLEFT", page, "TOPLEFT", 64, y + 4)
    editSpec:SetAutoFocus(false)
    editSpec:SetText(FormatIDList(cData.specIDs))
    local function SaveSpec(self)
        cData.specIDs = ParseIDList(self:GetText())
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editSpec:SetScript("OnEnterPressed", function(self)
        SaveSpec(self); self:ClearFocus()
    end)
    editSpec:SetScript("OnEditFocusLost", SaveSpec)
    widgets.editSpec = editSpec

    local lblSpecHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblSpecHint:SetPoint("LEFT", editSpec, "RIGHT", 6, 0)
    lblSpecHint:SetTextColor(0.6, 0.6, 0.6)
    lblSpecHint:SetText("Empty = any, comma-separated")
    widgets.lblSpecHint = lblSpecHint
    y = y - 36

    -- Map IDs, Load tab only
    if isLoad then
        local lblMap = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblMap:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
        lblMap:SetText("Map ID:")
        widgets.lblMap = lblMap

        local editMap = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editMap:SetSize(200, 24)
        editMap:SetPoint("TOPLEFT", page, "TOPLEFT", 64, y + 4)
        editMap:SetAutoFocus(false)
        editMap:SetText(FormatIDList(cData.mapIDs))
        local function SaveMap(self)
            cData.mapIDs = ParseIDList(self:GetText())
            NotifyChanged("loadConditions", "alerts." .. sel .. "." .. prefix)
        end
        editMap:SetScript("OnEnterPressed", function(self)
            SaveMap(self); self:ClearFocus()
        end)
        editMap:SetScript("OnEditFocusLost", SaveMap)
        widgets.editMap = editMap

        local lblMapHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblMapHint:SetPoint("LEFT", editMap, "RIGHT", 6, 0)
        lblMapHint:SetTextColor(0.6, 0.6, 0.6)
        lblMapHint:SetText("Empty = any, C_Map.GetBestMapForUnit(\"player\")")
        widgets.lblMapHint = lblMapHint
        y = y - 36
    end

    -- Instance types, multi-select comma-separated EditBox with helper text
    local lblInstType = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblInstType:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblInstType:SetText("Instance Type:")
    widgets.lblInstType = lblInstType

    local editInstType = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editInstType:SetSize(200, 24)
    editInstType:SetPoint("TOPLEFT", page, "TOPLEFT", 70, y + 4)
    editInstType:SetAutoFocus(false)
    local function FormatTypes(tbl)
        local parts = {}
        for _, v in ipairs(tbl or {}) do table.insert(parts, v) end
        return table.concat(parts, ", ")
    end
    local function ParseTypes(str)
        local valid = { dungeon = true, raid = true, pvp = true, arena = true, none = true }
        local out = {}
        for s in tostring(str or ""):gmatch("[^%s,]+") do
            if valid[s] then table.insert(out, s) end
        end
        return out
    end
    editInstType:SetText(FormatTypes(cData.instanceTypes))
    local function SaveInstType(self)
        cData.instanceTypes = ParseTypes(self:GetText())
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editInstType:SetScript("OnEnterPressed", function(self)
        SaveInstType(self); self:ClearFocus()
    end)
    editInstType:SetScript("OnEditFocusLost", SaveInstType)
    widgets.editInstType = editInstType

    local lblInstTypeHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblInstTypeHint:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y - 18)
    lblInstTypeHint:SetTextColor(0.55, 0.55, 0.55)
    lblInstTypeHint:SetText("Allowed values: dungeon, raid, pvp, arena, none (comma-separated, empty = any)")
    lblInstTypeHint:SetWidth(560)
    widgets.lblInstTypeHint = lblInstTypeHint
    y = y - 54

    -- Difficulty IDs
    local lblDiff = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblDiff:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblDiff:SetText("Difficulty ID:")
    widgets.lblDiff = lblDiff

    local editDiff = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editDiff:SetSize(200, 24)
    editDiff:SetPoint("TOPLEFT", page, "TOPLEFT", 64, y + 4)
    editDiff:SetAutoFocus(false)
    editDiff:SetText(FormatIDList(cData.difficultyIDs))
    local function SaveDiff(self)
        cData.difficultyIDs = ParseIDList(self:GetText())
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editDiff:SetScript("OnEnterPressed", function(self)
        SaveDiff(self); self:ClearFocus()
    end)
    editDiff:SetScript("OnEditFocusLost", SaveDiff)
    widgets.editDiff = editDiff

    local lblDiffHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblDiffHint:SetPoint("LEFT", editDiff, "RIGHT", 6, 0)
    lblDiffHint:SetTextColor(0.6, 0.6, 0.6)
    lblDiffHint:SetText("Empty = any, comma-separated")
    widgets.lblDiffHint = lblDiffHint
    y = y - 36

    -- Encounter IDs
    local lblEnc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblEnc:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblEnc:SetText("Encounter ID:")
    widgets.lblEnc = lblEnc

    local editEnc = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editEnc:SetSize(200, 24)
    editEnc:SetPoint("TOPLEFT", page, "TOPLEFT", 72, y + 4)
    editEnc:SetAutoFocus(false)
    editEnc:SetText(FormatIDList(cData.encounterIDs))
    local function SaveEnc(self)
        cData.encounterIDs = ParseIDList(self:GetText())
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editEnc:SetScript("OnEnterPressed", function(self)
        SaveEnc(self); self:ClearFocus()
    end)
    editEnc:SetScript("OnEditFocusLost", SaveEnc)
    widgets.editEnc = editEnc

    local lblEncHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblEncHint:SetPoint("LEFT", editEnc, "RIGHT", 6, 0)
    lblEncHint:SetTextColor(0.6, 0.6, 0.6)
    lblEncHint:SetText("Empty = any, comma-separated")
    widgets.lblEncHint = lblEncHint
    y = y - 36

    -- Class IDs
    local lblClass = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblClass:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblClass:SetText("Class ID:")
    widgets.lblClass = lblClass

    local editClass = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editClass:SetSize(200, 24)
    editClass:SetPoint("TOPLEFT", page, "TOPLEFT", 64, y + 4)
    editClass:SetAutoFocus(false)
    editClass:SetText(FormatIDList(cData.classIDs or {}))
    local function SaveClass(self)
        cData.classIDs = ParseIDList(self:GetText())
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editClass:SetScript("OnEnterPressed", function(self)
        SaveClass(self); self:ClearFocus()
    end)
    editClass:SetScript("OnEditFocusLost", SaveClass)
    widgets.editClass = editClass

    local lblClassHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblClassHint:SetPoint("LEFT", editClass, "RIGHT", 6, 0)
    lblClassHint:SetTextColor(0.6, 0.6, 0.6)
    do
        local InfinityState = InfinityTools.State
        local function ReadStateValue(key)
            if not InfinityState then return "?" end
            if type(InfinityState.Get) == "function" then
                return InfinityState:Get(key)
            end
            local value = InfinityState[key]
            if value == nil then return "?" end
            return value
        end
        local cid = ReadStateValue("ClassID")
        local cname = ReadStateValue("ClassName")
        lblClassHint:SetText(string.format("Empty = any  Current: %s(%s)", tostring(cname), tostring(cid)))
    end
    widgets.lblClassHint = lblClassHint
    y = y - 36

    -- Group type
    local lblGroup = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblGroup:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblGroup:SetText("Group Type:")
    widgets.lblGroup = lblGroup

    local GROUP_OPTIONS = {
        { "Any", "any" },
        { "Solo", "solo" },
        { "Party", "party" },
        { "Raid", "raid" },
    }
    local function InGroupToOption(v)
        if v == nil then return "any" end
        return v
    end
    local ddGroup = RevUI:CreateDropdown(page, 140, "", GROUP_OPTIONS,
        InGroupToOption(cData.inGroup),
        function(val)
            cData.inGroup = (val == "any") and nil or val
            NotifyChanged(isLoad and "loadConditions" or "conditions",
                "alerts." .. sel .. "." .. prefix)
        end
    )
    ddGroup:SetPoint("TOPLEFT", page, "TOPLEFT", 70, y + 4)
    widgets.ddGroup = ddGroup
    y = y - 36

    -- Level range
    local lblLevel = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblLevel:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblLevel:SetText("Level Range:")
    widgets.lblLevel = lblLevel

    local editMinLv = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editMinLv:SetSize(60, 24)
    editMinLv:SetPoint("TOPLEFT", page, "TOPLEFT", 70, y + 4)
    editMinLv:SetAutoFocus(false)
    editMinLv:SetNumeric(true)
    editMinLv:SetText(cData.minLevel and tostring(cData.minLevel) or "")
    local function SaveMinLv(self)
        local v = tonumber(self:GetText())
        cData.minLevel = (v and v > 0) and v or nil
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editMinLv:SetScript("OnEnterPressed", function(self)
        SaveMinLv(self); self:ClearFocus()
    end)
    editMinLv:SetScript("OnEditFocusLost", SaveMinLv)
    widgets.editMinLv = editMinLv

    local lblLvSep = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblLvSep:SetPoint("LEFT", editMinLv, "RIGHT", 4, 0)
    lblLvSep:SetText("~")
    widgets.lblLvSep = lblLvSep

    local editMaxLv = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editMaxLv:SetSize(60, 24)
    editMaxLv:SetPoint("LEFT", lblLvSep, "RIGHT", 4, 0)
    editMaxLv:SetAutoFocus(false)
    editMaxLv:SetNumeric(true)
    editMaxLv:SetText(cData.maxLevel and tostring(cData.maxLevel) or "")
    local function SaveMaxLv(self)
        local v = tonumber(self:GetText())
        cData.maxLevel = (v and v > 0) and v or nil
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editMaxLv:SetScript("OnEnterPressed", function(self)
        SaveMaxLv(self); self:ClearFocus()
    end)
    editMaxLv:SetScript("OnEditFocusLost", SaveMaxLv)
    widgets.editMaxLv = editMaxLv

    local lblLvHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblLvHint:SetPoint("LEFT", editMaxLv, "RIGHT", 6, 0)
    lblLvHint:SetTextColor(0.6, 0.6, 0.6)
    lblLvHint:SetText("Empty = any")
    widgets.lblLvHint = lblLvHint
    y = y - 36

    -- Character names
    local lblPName = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblPName:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
    lblPName:SetText("Character Name:")
    widgets.lblPName = lblPName

    local editPName = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
    editPName:SetSize(200, 24)
    editPName:SetPoint("TOPLEFT", page, "TOPLEFT", 56, y + 4)
    editPName:SetAutoFocus(false)
    editPName:SetText(cData.playerName or "")
    local function SavePName(self)
        cData.playerName = self:GetText()
        NotifyChanged(isLoad and "loadConditions" or "conditions",
            "alerts." .. sel .. "." .. prefix)
    end
    editPName:SetScript("OnEnterPressed", function(self)
        SavePName(self); self:ClearFocus()
    end)
    editPName:SetScript("OnEditFocusLost", SavePName)
    widgets.editPName = editPName

    local lblPNameHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblPNameHint:SetPoint("LEFT", editPName, "RIGHT", 6, 0)
    lblPNameHint:SetTextColor(0.6, 0.6, 0.6)
    lblPNameHint:SetText("Comma-separated, partial match, empty = any")
    widgets.lblPNameHint = lblPNameHint
    y = y - 36

    -- Realm names, Load tab only
    if isLoad then
        local lblRealm = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblRealm:SetPoint("TOPLEFT", page, "TOPLEFT", 0, y)
        lblRealm:SetText("Realm:")
        widgets.lblRealm = lblRealm

        local editRealm = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        editRealm:SetSize(200, 24)
        editRealm:SetPoint("TOPLEFT", page, "TOPLEFT", 56, y + 4)
        editRealm:SetAutoFocus(false)
        editRealm:SetText(cData.realmName or "")
        local function SaveRealm(self)
            cData.realmName = self:GetText()
            NotifyChanged("loadConditions", "alerts." .. sel .. "." .. prefix)
        end
        editRealm:SetScript("OnEnterPressed", function(self)
            SaveRealm(self); self:ClearFocus()
        end)
        editRealm:SetScript("OnEditFocusLost", SaveRealm)
        widgets.editRealm = editRealm

        local lblRealmHint = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblRealmHint:SetPoint("LEFT", editRealm, "RIGHT", 6, 0)
        lblRealmHint:SetTextColor(0.6, 0.6, 0.6)
        lblRealmHint:SetText("Comma-separated, partial match, empty = any")
        widgets.lblRealmHint = lblRealmHint
        y = y - 36
    end

    return y
end

local ACTION_WHEN_OPTIONS = {
    { "On Trigger", "on_trigger" },
    { "On End", "on_end" },
    { "On Remaining Time", "remaining" },
}

local ACTION_OP_OPTIONS = {
    { ">",  ">" },
    { ">=", ">=" },
    { "=",  "=" },
    { "<=", "<=" },
    { "<",  "<" },
}

local ACTION_GLOW_OPTIONS = {
    { "Do Nothing", "none" },
    { "Turn Glow On", "on" },
    { "Turn Glow Off", "off" },
}

local function EnsureActionCondition(rule)
    if type(rule.actionCondition) ~= "table" then
        rule.actionCondition = {}
    end
    local ac = rule.actionCondition
    if ac.enabled == nil then ac.enabled = false end
    if not ac.when or ac.when == "" then ac.when = "on_trigger" end
    if not ac.op or ac.op == "" then ac.op = "<=" end
    ac.value = tonumber(ac.value) or 0
    if ac.value < 0 then ac.value = 0 end
    if not ac.actionGlow or ac.actionGlow == "" then ac.actionGlow = "none" end
    if ac.actionSound == nil then ac.actionSound = false end
    return ac
end

-- =========================================================
-- Tab 3: Conditions page (action conditions)
-- =========================================================
BuildConditionPage = function()
    ClearWidgets(ConditionWidgets)

    local db = GetDB()
    if not db then return end

    local rule, sel = GetCurrentRule()
    if not rule then return end

    local ac = EnsureActionCondition(rule)
    local p = MainPageCondition
    local page = ConditionWidgets
    local FONT = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"

    local lblTitle = p:CreateFontString(nil, "OVERLAY")
    lblTitle:SetFont(FONT, 14, "OUTLINE")
    lblTitle:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -8)
    lblTitle:SetTextColor(1, 0.82, 0)
    lblTitle:SetText("Conditional Actions")
    page.lblTitle = lblTitle

    local lblDesc = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblDesc:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -28)
    lblDesc:SetTextColor(0.68, 0.68, 0.68)
    lblDesc:SetWidth(580)
    lblDesc:SetWordWrap(true)
    lblDesc:SetText("Run actions at a chosen moment. Supported actions: turn glow on/off and play a sound using the settings from the Actions tab.")
    page.lblDesc = lblDesc

    local cbEnable = RevUI:CreateCheckbox(p, "Enable Conditional Actions", ac.enabled == true, function(checked)
        ac.enabled = checked
        NotifyChanged("actionCondition", "alerts." .. sel .. ".actionCondition")
        BuildConditionPage()
        SetMainTab(SelectedMainTab)
    end)
    cbEnable:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -74)
    page.cbEnable = cbEnable

    local lblWhen = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblWhen:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -106)
    lblWhen:SetText("When to Run:")
    page.lblWhen = lblWhen

    local ddWhen = RevUI:CreateDropdown(p, 170, "", ACTION_WHEN_OPTIONS, ac.when or "on_trigger", function(val)
        ac.when = val
        NotifyChanged("actionCondition", "alerts." .. sel .. ".actionCondition")
        BuildConditionPage()
        SetMainTab(SelectedMainTab)
    end)
    ddWhen:SetPoint("TOPLEFT", p, "TOPLEFT", 58, -102)
    page.ddWhen = ddWhen

    if ac.when == "remaining" then
        local lblRemain = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblRemain:SetPoint("TOPLEFT", p, "TOPLEFT", 250, -106)
        lblRemain:SetText("Remaining Time:")
        page.lblRemain = lblRemain

        local ddOp = RevUI:CreateDropdown(p, 72, "", ACTION_OP_OPTIONS, ac.op or "<=", function(val)
            ac.op = val
            NotifyChanged("actionCondition", "alerts." .. sel .. ".actionCondition")
        end)
        ddOp:SetPoint("TOPLEFT", p, "TOPLEFT", 314, -102)
        page.ddOp = ddOp

        local editVal = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
        editVal:SetSize(80, 24)
        editVal:SetPoint("TOPLEFT", p, "TOPLEFT", 392, -98)
        editVal:SetAutoFocus(false)
        editVal:SetText(tostring(ac.value or 0))
        editVal:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText()) or 0
            if v < 0 then v = 0 end
            ac.value = v
            NotifyChanged("actionCondition", "alerts." .. sel .. ".actionCondition")
            self:SetText(tostring(v))
            self:ClearFocus()
        end)
        editVal:SetScript("OnEditFocusLost", function(self)
            local v = tonumber(self:GetText()) or 0
            if v < 0 then v = 0 end
            ac.value = v
            NotifyChanged("actionCondition", "alerts." .. sel .. ".actionCondition")
            self:SetText(tostring(v))
        end)
        page.editVal = editVal

        local lblSec = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblSec:SetPoint("LEFT", editVal, "RIGHT", 6, 0)
        lblSec:SetTextColor(0.68, 0.68, 0.68)
        lblSec:SetText("sec")
        page.lblSec = lblSec
    end

    local div = p:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    div:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -144)
    div:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -144)
    div:SetTexture("Interface\\Buttons\\WHITE8X8")
    div:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.3), CreateColor(1, 1, 1, 0.05))
    page.div = div

    local lblAction = p:CreateFontString(nil, "OVERLAY")
    lblAction:SetFont(FONT, 14, "OUTLINE")
    lblAction:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -166)
    lblAction:SetTextColor(1, 0.82, 0)
    lblAction:SetText("Actions")
    page.lblAction = lblAction

    local lblGlow = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblGlow:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -198)
    lblGlow:SetText("Glow:")
    page.lblGlow = lblGlow

    local ddGlow = RevUI:CreateDropdown(p, 180, "", ACTION_GLOW_OPTIONS, ac.actionGlow or "none", function(val)
        ac.actionGlow = val
        NotifyChanged("actionCondition", "alerts." .. sel .. ".actionCondition")
    end)
    ddGlow:SetPoint("TOPLEFT", p, "TOPLEFT", 40, -194)
    page.ddGlow = ddGlow

    local cbSound = RevUI:CreateCheckbox(p, "Play Sound", ac.actionSound == true, function(checked)
        ac.actionSound = checked
        NotifyChanged("actionCondition", "alerts." .. sel .. ".actionCondition")
    end)
    cbSound:SetPoint("TOPLEFT", p, "TOPLEFT", 250, -196)
    page.cbSound = cbSound
end

-- =========================================================
-- Tab 4: Action / Sound page
-- =========================================================
BuildActionPage = function()
    ClearWidgets(ActionWidgets)

    local db = GetDB()
    if not db then return end

    local rule, sel = GetCurrentRule()
    if not rule then return end

    local page = ActionWidgets
    local p = MainPageAction
    local FONT = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"

    -- Sound section
    local lblSoundSec = p:CreateFontString(nil, "OVERLAY")
    lblSoundSec:SetFont(FONT, 14, "OUTLINE")
    lblSoundSec:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -8)
    lblSoundSec:SetTextColor(1, 0.82, 0)
    lblSoundSec:SetText("Sound Settings")
    page.lblSoundSec = lblSoundSec

    local soundWidget = RevUI:CreateSoundGroup(p, PANEL_WIDTH - 56, "Sound", rule, "mySound", function()
        NotifyChanged("mySound", "alerts." .. sel)
    end)
    soundWidget:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -28)
    page.soundWidget = soundWidget

    local lblHint = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblHint:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -320)
    lblHint:SetTextColor(0.7, 0.7, 0.7)
    lblHint:SetText("Configure display type, position, and style in the Display tab. Set duration in the Trigger tab.")
    page.lblHint = lblHint
end

-- =========================================================
-- Tab 1: Display page
-- =========================================================
BuildStylePage = function()
    ClearWidgets(DisplayWidgets)

    local db = GetDB()
    if not db then return end

    local rule, sel = GetCurrentRule()
    if not rule then return end

    local p = MainPageDisplay
    local page = DisplayWidgets
    local FONT = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"

    -- Backward-compatible display defaults
    if rule.displayType ~= "icon" and rule.displayType ~= "bar" and rule.displayType ~= "text" then
        rule.displayType = "icon"
    end
    if type(rule.barStyle) ~= "table" then
        rule.barStyle = {
            width = 240,
            height = 24,
            texture = "Clean",
            barColorR = 1,
            barColorG = 0.7,
            barColorB = 0,
            barColorA = 1,
            barBgColorR = 0,
            barBgColorG = 0,
            barBgColorB = 0,
            barBgColorA = 0.5,
            showIcon = true,
            iconSide = "LEFT",
            iconSize = 24,
            iconOffsetX = -5,
            iconOffsetY = 0,
        }
    else
        local bs = rule.barStyle
        if type(bs.barColor) == "table" then
            bs.barColorR = bs.barColorR or bs.barColor.r
            bs.barColorG = bs.barColorG or bs.barColor.g
            bs.barColorB = bs.barColorB or bs.barColor.b
            bs.barColorA = bs.barColorA or bs.barColor.a
        end
        if type(bs.barBgColor) == "table" then
            bs.barBgColorR = bs.barBgColorR or bs.barBgColor.r
            bs.barBgColorG = bs.barBgColorG or bs.barBgColor.g
            bs.barBgColorB = bs.barBgColorB or bs.barBgColor.b
            bs.barBgColorA = bs.barBgColorA or bs.barBgColor.a
        end
        if bs.width == nil then bs.width = 240 end
        if bs.height == nil then bs.height = 24 end
        if bs.texture == nil then bs.texture = "Clean" end
        if bs.barColorR == nil then bs.barColorR = 1 end
        if bs.barColorG == nil then bs.barColorG = 0.7 end
        if bs.barColorB == nil then bs.barColorB = 0 end
        if bs.barColorA == nil then bs.barColorA = 1 end
        if bs.barBgColorR == nil then bs.barBgColorR = 0 end
        if bs.barBgColorG == nil then bs.barBgColorG = 0 end
        if bs.barBgColorB == nil then bs.barBgColorB = 0 end
        if bs.barBgColorA == nil then bs.barBgColorA = 0.5 end
        if bs.showIcon == nil then bs.showIcon = true end
        if bs.iconSide == nil then bs.iconSide = "LEFT" end
        if bs.iconSize == nil then bs.iconSize = 24 end
        if bs.iconOffsetX == nil then bs.iconOffsetX = -5 end
        if bs.iconOffsetY == nil then bs.iconOffsetY = 0 end
    end
    if not rule.textStyle then
        rule.textStyle = { text = "Spell Alert", font = nil, size = 28, outline = "OUTLINE", r = 1, g = 1, b = 1, a = 1 }
    end

    -- Display type
    local lblType = p:CreateFontString(nil, "OVERLAY")
    lblType:SetFont(FONT, 14, "OUTLINE")
    lblType:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -8)
    lblType:SetTextColor(1, 0.82, 0)
    lblType:SetText("Display Type")
    page.lblType = lblType

    local typeOptions = {
        { "Icon", "icon" },
        { "Bar", "bar" },
        { "Text", "text" },
    }
    local ddType = RevUI:CreateDropdown(p, 220, "", typeOptions, rule.displayType, function(val)
        rule.displayType = val
        NotifyChanged("type", "alerts." .. sel .. ".displayType")
        BuildStylePage()
        SetMainTab(SelectedMainTab)
    end)
    ddType:SetPoint("TOPLEFT", p, "TOPLEFT", 88, -4)
    page.ddType = ddType

    -- Common display parameters
    local lblX = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblX:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -44)
    lblX:SetText("X:")
    page.lblX = lblX

    local editX = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    editX:SetSize(70, 24)
    editX:SetPoint("TOPLEFT", p, "TOPLEFT", 20, -40)
    editX:SetAutoFocus(false)
    editX:SetText(tostring(rule.x or 0))
    editX:SetScript("OnEnterPressed", function(self)
        rule.x = tonumber(self:GetText()) or 0
        NotifyChanged("x", "alerts." .. sel .. ".x")
        self:ClearFocus()
    end)
    editX:SetScript("OnEditFocusLost", function(self)
        rule.x = tonumber(self:GetText()) or 0
        NotifyChanged("x", "alerts." .. sel .. ".x")
    end)
    page.editX = editX

    local lblY = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblY:SetPoint("TOPLEFT", p, "TOPLEFT", 112, -44)
    lblY:SetText("Y:")
    page.lblY = lblY

    local editY = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    editY:SetSize(70, 24)
    editY:SetPoint("TOPLEFT", p, "TOPLEFT", 132, -40)
    editY:SetAutoFocus(false)
    editY:SetText(tostring(rule.y or 100))
    editY:SetScript("OnEnterPressed", function(self)
        rule.y = tonumber(self:GetText()) or 100
        NotifyChanged("y", "alerts." .. sel .. ".y")
        self:ClearFocus()
    end)
    editY:SetScript("OnEditFocusLost", function(self)
        rule.y = tonumber(self:GetText()) or 100
        NotifyChanged("y", "alerts." .. sel .. ".y")
    end)
    page.editY = editY

    local cbReverse = RevUI:CreateCheckbox(p, "Reverse Progress", rule.reverse, function(checked)
        rule.reverse = checked
        NotifyChanged("reverse", "alerts." .. sel .. ".reverse")
    end)
    cbReverse:SetPoint("TOPLEFT", p, "TOPLEFT", 224, -42)
    page.cbReverse = cbReverse

    local lblGlow = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lblGlow:SetPoint("TOPLEFT", p, "TOPLEFT", 380, -44)
    lblGlow:SetText("Glow N sec before end:")
    page.lblGlow = lblGlow

    local editGlow = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
    editGlow:SetSize(70, 24)
    editGlow:SetPoint("TOPLEFT", p, "TOPLEFT", 458, -40)
    editGlow:SetAutoFocus(false)
    editGlow:SetText(tostring(rule.glowRemaining or 0))
    editGlow:SetScript("OnEnterPressed", function(self)
        rule.glowRemaining = tonumber(self:GetText()) or 0
        NotifyChanged("glowRemaining", "alerts." .. sel .. ".glowRemaining")
        self:ClearFocus()
    end)
    editGlow:SetScript("OnEditFocusLost", function(self)
        rule.glowRemaining = tonumber(self:GetText()) or 0
        NotifyChanged("glowRemaining", "alerts." .. sel .. ".glowRemaining")
    end)
    page.editGlow = editGlow

    local cbGlowAlways = RevUI:CreateCheckbox(p, "Always Glow", rule.glowAlways == true, function(checked)
        rule.glowAlways = checked
        NotifyChanged("glowAlways", "alerts." .. sel .. ".glowAlways")
    end)
    cbGlowAlways:SetPoint("TOPLEFT", p, "TOPLEFT", 540, -42)
    page.cbGlowAlways = cbGlowAlways

    local divTop = p:CreateTexture(nil, "ARTWORK")
    divTop:SetHeight(1)
    divTop:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -104)
    divTop:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -104)
    divTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    divTop:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.3), CreateColor(1, 1, 1, 0.05))
    page.divTop = divTop

    -- Render fields based on display type
    if rule.displayType == "bar" then
        local barWidget = RevUI:CreateTimerBarGroup(p, PANEL_WIDTH - 56, "Bar Settings", rule.barStyle, nil, function()
            NotifyChanged("barStyle", "alerts." .. sel .. ".barStyle")
        end)
        barWidget:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -114)
        page.barWidget = barWidget
    elseif rule.displayType == "text" then
        local lblTextSec = p:CreateFontString(nil, "OVERLAY")
        lblTextSec:SetFont(FONT, 14, "OUTLINE")
        lblTextSec:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -118)
        lblTextSec:SetTextColor(1, 0.82, 0)
        lblTextSec:SetText("Text Settings")
        page.lblTextSec = lblTextSec

        local lblText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lblText:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -146)
        lblText:SetText("Text Content:")
        page.lblText = lblText

        local textBox = RevUI:CreateEditBox(
            p,
            rule.textStyle.text or "",
            560, 92, nil,
            {
                onEditFocusLost = function(val)
                    rule.textStyle.text = tostring(val or "")
                    NotifyChanged("textStyle", "alerts." .. sel .. ".textStyle")
                end,
            }
        )
        textBox:SetPoint("TOPLEFT", p, "TOPLEFT", 64, -142)
        page.editText = textBox

        local lblTextHint = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lblTextHint:SetPoint("TOPLEFT", p, "TOPLEFT", 64, -238)
        lblTextHint:SetTextColor(0.68, 0.68, 0.68)
        lblTextHint:SetText("Supports multi-line text")
        page.lblTextHint = lblTextHint

        local fontDrop = RevUI:CreateLSMDropdown(p, "font", 220, "Font", rule.textStyle.font, function(key)
            rule.textStyle.font = key
            NotifyChanged("textStyle", "alerts." .. sel .. ".textStyle")
        end)
        fontDrop:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -274)
        page.fontDrop = fontDrop

        local sizeSlider = RevUI:CreateSlider(p, 220, "Font Size", 8, 80, rule.textStyle.size or 28, 1, nil, function(v)
            rule.textStyle.size = v
            NotifyChanged("textStyle", "alerts." .. sel .. ".textStyle")
        end)
        sizeSlider:SetPoint("TOPLEFT", p, "TOPLEFT", 250, -274)
        page.sizeSlider = sizeSlider

        local outlineOptions = {
            { "None", "" },
            { "Outline", "OUTLINE" },
            { "Thick Outline", "THICKOUTLINE" },
            { "Monochrome", "MONOCHROME" },
        }
        local ddOutline = RevUI:CreateDropdown(p, 220, "Outline", outlineOptions, rule.textStyle.outline or "OUTLINE",
            function(v)
                rule.textStyle.outline = v
                NotifyChanged("textStyle", "alerts." .. sel .. ".textStyle")
            end)
        ddOutline:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -338)
        page.ddOutline = ddOutline

        local colorBtn = RevUI:CreateColorButton(p, "Text Color", rule.textStyle, "", true, function()
            NotifyChanged("textStyle", "alerts." .. sel .. ".textStyle")
        end)
        colorBtn:SetPoint("TOPLEFT", p, "TOPLEFT", 250, -338)
        page.colorBtn = colorBtn
    else
        local iconWidget = RevUI:CreateIconGroup(p, PANEL_WIDTH - 56, "Icon Settings", rule, nil, function()
            NotifyChanged("icon", "alerts." .. sel)
        end)
        iconWidget:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -114)
        page.iconWidget = iconWidget

        local glowWidget = RevUI:CreateGlowSettings(p, PANEL_WIDTH - 56, "Glow Settings", rule, "myGlow", function()
            NotifyChanged("myGlow", "alerts." .. sel)
        end)
        glowWidget:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -406)
        page.glowWidget = glowWidget
    end
end

-- =========================================================
-- Tab 5: Load page, rule-level filter rechecked on State changes
-- =========================================================
BuildLoadPage = function()
    ClearWidgets(LoadWidgets)

    local db = GetDB()
    if not db then return end
    local rule, sel = GetCurrentRule()
    if not rule then return end
    if not rule.loadConditions then
        rule.loadConditions = {
            inCombat = nil,
            inInstance = nil,
            specIDs = {},
            mapIDs = {},
            instanceTypes = {},
            difficultyIDs = {},
            encounterIDs = {}
        }
    end

    local p = MainPageLoad
    local FONT = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"

    -- Page title
    local lblTitle = p:CreateFontString(nil, "OVERLAY")
    lblTitle:SetFont(FONT, 14, "OUTLINE")
    lblTitle:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -8)
    lblTitle:SetTextColor(1, 0.82, 0)
    lblTitle:SetText("Load  -  Rule Filters Rechecked on State Changes")
    LoadWidgets.lblTitle = lblTitle

    local lblDesc = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblDesc:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -28)
    lblDesc:SetTextColor(0.65, 0.65, 0.65)
    lblDesc:SetText("Load conditions are always active: filled fields must match, empty fields mean any. Conditions are rechecked automatically when state changes, such as spec swaps or entering an instance.")
    lblDesc:SetWordWrap(true)
    lblDesc:SetWidth(580)
    LoadWidgets.lblDesc = lblDesc

    local lastY = BuildConditionBlock(p, rule.loadConditions, LoadWidgets, -56,
        "loadConditions", sel, true)

    -- Current State hint line
    local divStatus = p:CreateTexture(nil, "ARTWORK")
    divStatus:SetHeight(1)
    divStatus:SetPoint("TOPLEFT", p, "TOPLEFT", 0, lastY - 8)
    divStatus:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, lastY - 8)
    divStatus:SetTexture("Interface\\Buttons\\WHITE8X8")
    divStatus:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.2), CreateColor(1, 1, 1, 0.02))
    LoadWidgets.divStatus = divStatus

    -- Read current State values for display
    local function GetStateHint()
        local InfinityState = InfinityTools.State
        local function S(k)
            if not InfinityState then return "?" end
            if type(InfinityState.Get) == "function" then
                return InfinityState:Get(k)
            end
            local value = InfinityState[k]
            if value == nil then return "?" end
            return value
        end
        local classID   = S("ClassID")
        local className = S("ClassName")
        local specID    = S("SpecID")
        local specName  = S("SpecName")
        local level     = S("Level")
        local isInRaid  = S("IsInRaid")
        local isInParty = S("IsInParty")
        local pName     = S("PlayerName")
        local realm     = S("RealmName")
        local mapID     = (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")) or 0
        local inCombat  = S("InCombat")
        local instType  = S("InstanceType")
        local diffID    = S("DifficultyID")
        local encID     = S("EncounterID")
        local groupStr  = isInRaid and "Raid" or (isInParty and "Party" or "Solo")
        return string.format(
            "Current State  Class:%s(%s)  Spec:%s(%s)  Level:%s  Group:%s  Map:%s  Combat:%s  Instance:%s  Difficulty:%s  Encounter:%s  Character:%s@%s",
            tostring(className), tostring(classID),
            tostring(specName), tostring(specID),
            tostring(level),
            groupStr,
            tostring(mapID),
            tostring(inCombat),
            tostring(instType),
            tostring(diffID),
            tostring(encID),
            tostring(pName), tostring(realm)
        )
    end

    local lblStatus = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lblStatus:SetPoint("TOPLEFT", p, "TOPLEFT", 0, lastY - 20)
    lblStatus:SetTextColor(0.5, 1, 0.5)
    lblStatus:SetText(GetStateHint())
    lblStatus:SetWordWrap(true)
    lblStatus:SetWidth(580)
    LoadWidgets.lblStatus = lblStatus
end

-- =========================================================
-- Panel creation
-- =========================================================
local function CreateMainFrame()
    if MainFrame then return end

    local useElvUI = IsElvUILoaded()
    if useElvUI then
        MainFrame = CreateFrame("Frame", "SpellAlert_Panel", _G.UIParent, "BackdropTemplate")
        MainFrame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
        MainFrame:SetPoint("CENTER")

        local close = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -2, -2)
        MainFrame.CloseButton = close

        local title = MainFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(InfinityTools.MAIN_FONT, 18, "OUTLINE")
        title:SetPoint("TOPLEFT", 16, -14)
        title:SetText(PANEL_TITLE)
        title:SetTextColor(1, 0.82, 0)
        MainFrame.TitleText = title

        ApplyElvUISkin(MainFrame)
    else
        MainFrame = CreateFrame("Frame", "SpellAlert_Panel", _G.UIParent, "DefaultPanelTemplate")
        MainFrame:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
        MainFrame:SetPoint("CENTER")
        if MainFrame.TitleText then
            MainFrame.TitleText:SetText(PANEL_TITLE)
        end
    end

    MainFrame:SetFrameStrata("HIGH")
    MainFrame:SetToplevel(true)
    MainFrame:SetClampedToScreen(true)
    MainFrame:SetMovable(true)
    MainFrame:EnableMouse(true)
    MainFrame:RegisterForDrag("LeftButton")
    MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
    MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
    MainFrame:Hide()

    EnsureSpecialFrame("SpellAlert_Panel")

    -- ---------------------------------------------------------
    -- Tab buttons: Display / Trigger / Condition / Action / Load
    -- ---------------------------------------------------------
    local function MakeTab(id, text, anchorFrame)
        local tab = CreateFrame("Button", "SpellAlert_PanelTab" .. id, MainFrame, "PanelTopTabButtonTemplate")
        tab:SetID(id)
        tab:SetText(text)
        if anchorFrame then
            tab:SetPoint("LEFT", anchorFrame, "RIGHT", -16, 0)
        else
            tab:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", LIST_WIDTH + 16, -30)
        end
        tab:SetScript("OnClick", function(self)
            SetMainTab(self:GetID())
            if _G.PlaySound and _G.SOUNDKIT and _G.SOUNDKIT.UI_TOYBOX_TABS then
                _G.PlaySound(_G.SOUNDKIT.UI_TOYBOX_TABS)
            end
        end)
        if _G.PanelTemplates_TabResize then
            _G.PanelTemplates_TabResize(tab, 0)
        end
        return tab
    end

    local tab1 = MakeTab(1, "Display", nil)
    local tab2 = MakeTab(2, "Trigger", tab1)
    local tab3 = MakeTab(3, "Conditions", tab2)
    local tab4 = MakeTab(4, "Actions", tab3)
    local tab5 = MakeTab(5, "Load", tab4)
    -- Keep tab5 referenced for chain anchors and to avoid LSP unused warnings.
    tab5:GetID()

    if _G.PanelTemplates_SetNumTabs then
        pcall(_G.PanelTemplates_SetNumTabs, MainFrame, 5)
    end

    -- ---------------------------------------------------------
    -- Left list panel
    -- ---------------------------------------------------------
    BuildListPanel()

    -- ---------------------------------------------------------
    -- Five page containers on the right side, starting after the list
    -- ---------------------------------------------------------
    local function MakePage()
        local f = CreateFrame("Frame", nil, MainFrame)
        f:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", LIST_WIDTH + 16, -55)
        f:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -8, 10)
        return f
    end

    MainPageTrigger   = MakePage()
    MainPageCondition = MakePage()
    MainPageAction    = MakePage()
    MainPageDisplay   = MakePage()
    MainPageLoad      = MakePage()

    -- Show Tab 1 by default
    SetMainTab(SelectedMainTab)
    RefreshList()
end

-- =========================================================
-- Public API
-- =========================================================
_G.SpellAlertPanel = {}

function _G.SpellAlertPanel.Open()
    if not MainFrame then CreateMainFrame() end
    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        MainFrame:Show()
        RefreshPanel()
        SetMainTab(SelectedMainTab)
    end
end

function _G.SpellAlertPanel.Refresh()
    RefreshPanel()
end

print("|cff00ff00[SpellAlert.Panel] Loaded|r")

