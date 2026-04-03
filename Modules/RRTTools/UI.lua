local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core                   = RRT_NS.UI.Core
local window_height          = Core.window_height
local options_text_template  = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template   = Core.options_switch_template
local options_slider_template   = Core.options_slider_template
local options_button_template   = Core.options_button_template

local SIDEBAR_WIDTH   = 130
local SIDEBAR_PADDING = 4
local SIDEBAR_ITEM_H  = 20

local function BuildSpellAlertEditor(parent)
    local Tools = RRT_NS.Tools
    if not Tools or not Tools.GetDB or not Tools.GetSpellAlertRules then
        return
    end

    local db = Tools.GetDB()
    local selectedRule = 1
    local rows = {}
    local formWidgets = {}
    local RefreshList
    local RefreshEditor

    local function parseCSVNumbers(text)
        local out = {}
        for token in string.gmatch(text or "", "[^,%s]+") do
            local value = tonumber(token)
            if value then
                out[#out + 1] = value
            end
        end
        return out
    end

    local function parseCSVStrings(text)
        local out = {}
        for token in string.gmatch(text or "", "[^,%s]+") do
            out[#out + 1] = token
        end
        return out
    end

    local function joinCSV(values)
        if type(values) ~= "table" or #values == 0 then
            return ""
        end
        local parts = {}
        for i = 1, #values do
            parts[#parts + 1] = tostring(values[i])
        end
        return table.concat(parts, ", ")
    end

    local container = CreateFrame("Frame", "RRTSpellAlertEditor", parent)
    container:SetAllPoints(parent)

    local listPanel = CreateFrame("Frame", nil, container, "BackdropTemplate")
    listPanel:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -8)
    listPanel:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 8, 8)
    listPanel:SetWidth(220)
    listPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    listPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.55)
    listPanel:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)

    local formPanel = CreateFrame("Frame", nil, container, "BackdropTemplate")
    formPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", 8, 0)
    formPanel:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -8, 8)
    formPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    formPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.35)
    formPanel:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)

    local header = listPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 10, -10)
    header:SetText("Spell Alert Rules")

    local addBtn = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
    addBtn:SetSize(60, 20)
    addBtn:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
    addBtn:SetText("Add")

    local delBtn = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
    delBtn:SetSize(60, 20)
    delBtn:SetPoint("LEFT", addBtn, "RIGHT", 6, 0)
    delBtn:SetText("Delete")

    local dupBtn = CreateFrame("Button", nil, listPanel, "UIPanelButtonTemplate")
    dupBtn:SetSize(60, 20)
    dupBtn:SetPoint("LEFT", delBtn, "RIGHT", 6, 0)
    dupBtn:SetText("Clone")

    local listScroll = CreateFrame("ScrollFrame", nil, listPanel, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", addBtn, "BOTTOMLEFT", 0, -10)
    listScroll:SetPoint("BOTTOMRIGHT", listPanel, "BOTTOMRIGHT", -28, 10)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetSize(180, 1)
    listScroll:SetScrollChild(listContent)

    local formTitle = formPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    formTitle:SetPoint("TOPLEFT", 12, -10)
    formTitle:SetText("Rule Editor")

    local formScroll = CreateFrame("ScrollFrame", nil, formPanel, "UIPanelScrollFrameTemplate")
    formScroll:SetPoint("TOPLEFT", formTitle, "BOTTOMLEFT", 0, -8)
    formScroll:SetPoint("BOTTOMRIGHT", formPanel, "BOTTOMRIGHT", -28, 10)

    local formContent = CreateFrame("Frame", nil, formScroll)
    formContent:SetSize(520, 1200)
    formScroll:SetScrollChild(formContent)

    local function getRules()
        return Tools.GetSpellAlertRules()
    end

    local function currentRule()
        local rules = getRules()
        if #rules == 0 then
            return nil
        end
        if selectedRule < 1 then selectedRule = 1 end
        if selectedRule > #rules then selectedRule = #rules end
        return rules[selectedRule]
    end

    local function makeLabel(parentFrame, text, x, y)
        local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", x, y)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        return label
    end

    local function makeInput(key, labelText, width, y, getter, setter)
        local label = makeLabel(formContent, labelText, 12, y)
        local box = CreateFrame("EditBox", nil, formContent, "InputBoxTemplate")
        box:SetSize(width, 20)
        box:SetAutoFocus(false)
        box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
        box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        box:SetScript("OnTextChanged", function(self)
            local rule = currentRule()
            if not rule then return end
            setter(rule, self:GetText())
            Tools.NotifySpellAlertChanged()
            RefreshEditor()
        end)
        formWidgets[key] = {
            refresh = function(rule)
                local value = getter(rule)
                if box:GetText() ~= tostring(value or "") then
                    box:SetText(tostring(value or ""))
                end
            end
        }
        return box
    end

    local function makeCheckbox(key, labelText, x, y, getter, setter)
        local box = CreateFrame("CheckButton", nil, formContent, "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", x, y)
        box.text:SetText(labelText)
        box:SetScript("OnClick", function(self)
            local rule = currentRule()
            if not rule then return end
            setter(rule, self:GetChecked() == true)
            Tools.NotifySpellAlertChanged()
            RefreshEditor()
            RefreshList()
        end)
        formWidgets[key] = {
            refresh = function(rule)
                box:SetChecked(getter(rule) == true)
            end
        }
        return box
    end

    local function makeCycleButton(key, labelText, values, x, y, getter, setter)
        local label = makeLabel(formContent, labelText, x, y)
        local btn = CreateFrame("Button", nil, formContent, "UIPanelButtonTemplate")
        btn:SetSize(140, 20)
        btn:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
        btn:SetScript("OnClick", function()
            local rule = currentRule()
            if not rule then return end
            local current = getter(rule)
            local index = 1
            for i = 1, #values do
                if values[i] == current then
                    index = i
                    break
                end
            end
            index = (index % #values) + 1
            setter(rule, values[index])
            Tools.NotifySpellAlertChanged()
            RefreshEditor()
            RefreshList()
        end)
        formWidgets[key] = {
            refresh = function(rule)
                btn:SetText(tostring(getter(rule) or ""))
            end
        }
        return btn
    end

    RefreshList = function()
        local rules = getRules()
        for i = 1, math.max(#rows, #rules) do
            local row = rows[i]
            local rule = rules[i]
            if rule then
                if not row then
                    row = CreateFrame("Button", nil, listContent, "BackdropTemplate")
                    row:SetSize(180, 24)
                    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
                    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    row.text:SetPoint("LEFT", 6, 0)
                    row:SetScript("OnClick", function()
                        selectedRule = i
                        RefreshList()
                        RefreshEditor()
                    end)
                    rows[i] = row
                end
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -((i - 1) * 28))
                row:SetShown(true)
                row.text:SetText((rule.enabled and "|cff88ff88" or "|cffff8888") .. (rule.name or ("Rule " .. i)) .. "|r")
                if i == selectedRule then
                    row:SetBackdropColor(0.3, 0.16, 0.4, 0.8)
                    row:SetBackdropBorderColor(0.7, 0.35, 0.85, 1)
                else
                    row:SetBackdropColor(0.12, 0.12, 0.12, 0.6)
                    row:SetBackdropBorderColor(0.24, 0.24, 0.24, 0.7)
                end
            elseif row then
                row:Hide()
            end
        end
        listContent:SetHeight(math.max(1, #rules * 28))
    end

    RefreshEditor = function()
        local rule = currentRule()
        for _, widget in pairs(formWidgets) do
            if widget.refresh then
                widget.refresh(rule or {})
            end
        end
    end

    makeCheckbox("enabled", "Enabled", 12, -8, function(rule) return rule.enabled end, function(rule, value) rule.enabled = value end)
    makeInput("name", "Rule Name", 220, -36, function(rule) return rule.name end, function(rule, value) rule.name = value end)
    makeCycleButton("triggerType", "Trigger Type", {"spell", "state", "onload", "always"}, 12, -84,
        function(rule) return rule.trigger.type end,
        function(rule, value) rule.trigger.type = value end)
    makeInput("triggerSpellID", "Trigger Spell ID", 120, -132,
        function(rule) return rule.trigger.spellID end,
        function(rule, value) rule.trigger.spellID = tonumber(value) or 0 end)
    makeInput("triggerStateKey", "Trigger State Key", 180, -180,
        function(rule) return rule.trigger.stateKey end,
        function(rule, value) rule.trigger.stateKey = value end)
    makeCycleButton("triggerCondition", "State Condition", {"increase", "decrease"}, 12, -228,
        function(rule) return rule.trigger.condition end,
        function(rule, value) rule.trigger.condition = value end)
    makeInput("triggerThreshold", "State Threshold", 120, -276,
        function(rule) return rule.trigger.threshold end,
        function(rule, value) rule.trigger.threshold = tonumber(value) or 0 end)
    makeInput("triggerMargin", "State Margin", 120, -324,
        function(rule) return rule.trigger.margin end,
        function(rule, value) rule.trigger.margin = tonumber(value) or 0.1 end)
    makeInput("triggerDelay", "Trigger Delay", 120, -372,
        function(rule) return rule.trigger.delay end,
        function(rule, value) rule.trigger.delay = tonumber(value) or 0 end)

    makeCycleButton("displayType", "Display Type", {"icon", "bar", "text"}, 12, -430,
        function(rule) return rule.display.type end,
        function(rule, value) rule.display.type = value end)
    makeInput("displayText", "Display Text", 260, -478,
        function(rule) return rule.display.text end,
        function(rule, value) rule.display.text = value end)
    makeInput("displayIconID", "Display Icon ID", 120, -526,
        function(rule) return rule.display.iconID end,
        function(rule, value) rule.display.iconID = tonumber(value) or 0 end)
    makeInput("displayWidth", "Width", 80, -574,
        function(rule) return rule.display.width end,
        function(rule, value) rule.display.width = tonumber(value) or 44 end)
    makeInput("displayHeight", "Height", 80, -622,
        function(rule) return rule.display.height end,
        function(rule, value) rule.display.height = tonumber(value) or 44 end)
    makeInput("displayDuration", "Duration", 80, -670,
        function(rule) return rule.display.duration end,
        function(rule, value) rule.display.duration = tonumber(value) or 2 end)
    makeInput("displayPosX", "Position X", 80, -718,
        function(rule) return rule.display.posX end,
        function(rule, value) rule.display.posX = tonumber(value) or 0 end)
    makeInput("displayPosY", "Position Y", 80, -766,
        function(rule) return rule.display.posY end,
        function(rule, value) rule.display.posY = tonumber(value) or 90 end)
    makeCycleButton("displayGlow", "Glow", {"none", "button", "pixel", "autocast"}, 12, -814,
        function(rule) return rule.display.glow end,
        function(rule, value) rule.display.glow = value end)
    makeInput("displaySound", "Sound Name", 180, -862,
        function(rule) return rule.display.sound end,
        function(rule, value) rule.display.sound = value end)
    makeInput("fontSize", "Font Size", 80, -910,
        function(rule) return rule.display.fontSize end,
        function(rule, value) rule.display.fontSize = tonumber(value) or 26 end)
    makeInput("barColor", "Bar Color RGBA", 180, -958,
        function(rule)
            local c = rule.display.barColor or {}
            return string.format("%s,%s,%s,%s", c[1] or 1, c[2] or 0.75, c[3] or 0.1, c[4] or 1)
        end,
        function(rule, value) rule.display.barColor = parseCSVNumbers(value) end)
    makeInput("textColor", "Text Color RGBA", 180, -1006,
        function(rule)
            local c = rule.display.textColor or {}
            return string.format("%s,%s,%s,%s", c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
        end,
        function(rule, value) rule.display.textColor = parseCSVNumbers(value) end)

    makeCheckbox("loadCombat", "Load: In Combat", 300, -8,
        function(rule) return rule.load.inCombat == true end,
        function(rule, value) rule.load.inCombat = value and true or nil end)
    makeCheckbox("loadInstance", "Load: In Instance", 300, -36,
        function(rule) return rule.load.inInstance == true end,
        function(rule, value) rule.load.inInstance = value and true or nil end)
    makeInput("loadGroup", "Load Group (solo/party/raid)", 180, -84,
        function(rule) return rule.load.inGroup or "" end,
        function(rule, value) rule.load.inGroup = value ~= "" and value or nil end)
    makeInput("loadInstanceTypes", "Load Instance Types", 220, -132,
        function(rule) return joinCSV(rule.load.instanceTypes) end,
        function(rule, value) rule.load.instanceTypes = parseCSVStrings(value) end)
    makeInput("loadSpecIDs", "Load Spec IDs", 220, -180,
        function(rule) return joinCSV(rule.load.specIDs) end,
        function(rule, value) rule.load.specIDs = parseCSVNumbers(value) end)
    makeInput("loadClassIDs", "Load Class IDs", 220, -228,
        function(rule) return joinCSV(rule.load.classIDs) end,
        function(rule, value) rule.load.classIDs = parseCSVNumbers(value) end)

    addBtn:SetScript("OnClick", function()
        local rules = getRules()
        local newRule = Tools.GetSpellAlertDefaultRule()
        newRule.name = "Rule " .. (#rules + 1)
        rules[#rules + 1] = newRule
        selectedRule = #rules
        Tools.NotifySpellAlertChanged()
        RefreshList()
        RefreshEditor()
    end)

    delBtn:SetScript("OnClick", function()
        local rules = getRules()
        if #rules <= 1 then
            return
        end
        table.remove(rules, selectedRule)
        if selectedRule > #rules then
            selectedRule = #rules
        end
        Tools.NotifySpellAlertChanged()
        RefreshList()
        RefreshEditor()
    end)

    dupBtn:SetScript("OnClick", function()
        local rules = getRules()
        local rule = currentRule()
        if not rule then
            return
        end
        local copy = CopyTable and CopyTable(rule) or {
            enabled = rule.enabled,
            name = (rule.name or "Rule") .. " Copy",
            trigger = {
                type = rule.trigger.type,
                spellID = rule.trigger.spellID,
                stateKey = rule.trigger.stateKey,
                condition = rule.trigger.condition,
                threshold = rule.trigger.threshold,
                margin = rule.trigger.margin,
                delay = rule.trigger.delay,
            },
            load = {
                inCombat = rule.load.inCombat,
                inInstance = rule.load.inInstance,
                instanceTypes = { unpack(rule.load.instanceTypes or {}) },
                specIDs = { unpack(rule.load.specIDs or {}) },
                classIDs = { unpack(rule.load.classIDs or {}) },
                inGroup = rule.load.inGroup,
            },
            display = {
                type = rule.display.type,
                iconID = rule.display.iconID,
                text = rule.display.text,
                width = rule.display.width,
                height = rule.display.height,
                posX = rule.display.posX,
                posY = rule.display.posY,
                duration = rule.display.duration,
                reverse = rule.display.reverse,
                barTexture = rule.display.barTexture,
                barColor = { unpack(rule.display.barColor or {}) },
                textColor = { unpack(rule.display.textColor or {}) },
                fontSize = rule.display.fontSize,
                glow = rule.display.glow,
                sound = rule.display.sound,
            },
        }
        rules[#rules + 1] = copy
        selectedRule = #rules
        Tools.NotifySpellAlertChanged()
        RefreshList()
        RefreshEditor()
    end)

    RefreshList()
    RefreshEditor()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Main builder — called from RRTUI.lua after this file is loaded
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildToolsHubUI(parent)
    local Opts = RRT_NS.UI.Options.Tools

    local SECTIONS = {
        { name = "Auto Tools",    key = "autotools", build = Opts.BuildAutoToolsOptions  },
        { name = "Map & Display", key = "display",   build = Opts.BuildMapDisplayOptions },
        { name = "M+ Tools",      key = "mplus",     build = Opts.BuildMPlusOptions      },
        { name = "Class Tools",   key = "class",     build = Opts.BuildClassOptions      },
        { name = "Spell Alert",   key = "spellalert", custom = true },
    }

    -- Breadcrumb
    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)
    breadcrumb:SetText("|cFFBB66FF" .. SECTIONS[1].name .. "|r")

    -- Sidebar
    local sidebar = CreateFrame("Frame", "RRT_ToolsSidebar", parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    parent, "TOPLEFT",    4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4,  22)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", "RRT_ToolsContent", parent)
    contentArea:SetPoint("TOPLEFT",     parent, "TOPLEFT",     SIDEBAR_WIDTH + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 22)

    -- One panel per section
    local panels = {}
    local menuH  = window_height - 120

    for _, sec in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRT_ToolsSection_" .. sec.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()

        if sec.custom and sec.key == "spellalert" then
            BuildSpellAlertEditor(panel)
        else
            local optTable = sec.build()
            DF:BuildMenu(
                panel, optTable,
                10, -10, menuH,
                false,
                options_text_template,
                options_dropdown_template,
                options_switch_template,
                true,
                options_slider_template,
                options_button_template,
                Opts.BuildCallback()
            )
        end
        panels[sec.key] = panel
    end

    -- Sidebar selection logic
    local activeButton       = nil
    local currentSectionName = SECTIONS[1].name

    local function SelectSection(key, btn, sectionName)
        for k, p in pairs(panels) do p:SetShown(k == key) end
        if activeButton then
            activeButton:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            activeButton:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        end
        local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        activeButton        = btn
        currentSectionName  = sectionName
        local hex = string.format("%02X%02X%02X",
            math.floor(c[1]*255+0.5),
            math.floor(c[2]*255+0.5),
            math.floor(c[3]*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. sectionName .. "|r")
    end

    -- Build sidebar buttons
    for i, section in ipairs(SECTIONS) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(SIDEBAR_WIDTH - SIDEBAR_PADDING * 2, SIDEBAR_ITEM_H)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT",
            SIDEBAR_PADDING, -(SIDEBAR_PADDING + (i - 1) * (SIDEBAR_ITEM_H + 4)))
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont()
           if f then btnText:SetFont(f, 9, fl or "") end
        end
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(section.name)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)

        local key  = section.key
        local name = section.name
        btn:SetScript("OnClick", function(self) SelectSection(key, self, name) end)
        btn:SetScript("OnEnter", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeButton ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
        end)

        if i == 1 then SelectSection(key, btn, name) end
    end

    -- Register theme color callback
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        if activeButton then
            activeButton:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
            activeButton:SetBackdropBorderColor(r, g, b, 1)
        end
        local hex = string.format("%02X%02X%02X",
            math.floor(r*255+0.5),
            math.floor(g*255+0.5),
            math.floor(b*255+0.5))
        breadcrumb:SetText("|cFF" .. hex .. currentSectionName .. "|r")
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Export
-- ─────────────────────────────────────────────────────────────────────────────
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.ToolsHub = { BuildToolsHubUI = BuildToolsHubUI }



