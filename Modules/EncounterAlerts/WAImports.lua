local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

local wa_popup

local function WAButton(title, _, url)
    if not wa_popup then
        wa_popup = DF:CreateSimplePanel(UIParent, 300, 60, "", "RRTWAImportPopup", {
            DontRightClickClose = true,
        })
        wa_popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        wa_popup:SetFrameLevel(100)

        wa_popup.text_entry = DF:CreateTextEntry(wa_popup, function() end, 280, 20)
        wa_popup.text_entry:SetTemplate(options_button_template)
        wa_popup.text_entry:SetPoint("TOP", wa_popup, "TOP", 0, -30)
        wa_popup.text_entry.editbox:SetJustifyH("CENTER")
        wa_popup.text_entry:SetScript("OnEditFocusGained", function()
            wa_popup.text_entry.editbox:HighlightText()
        end)
    end

    wa_popup:SetTitle(title)

    local currentURL = url
    wa_popup.text_entry:SetText(currentURL)
    wa_popup.text_entry:SetScript("OnTextChanged", function()
        wa_popup.text_entry:SetText(currentURL)
        wa_popup.text_entry.editbox:HighlightText()
    end)

    wa_popup:Show()
    wa_popup.text_entry:SetFocus()
    wa_popup.text_entry.editbox:HighlightText()
end

local function BuildWAImportsOptions()
    return {
        {
            type = "label",
            get = function()
                return "You will need to get a compatible WA fork for this yourself. The buttons provide the Wago link for each aura."
            end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "button",
            name = "Heal Absorb WA",
            desc = "Link to a WA that shows the Heal Absorb on raid frames.",
            func = function()
                WAButton("Heal Absorb WA", "HealAbsorbWA", "https://wago.io/lylBMpoMB")
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Paladins Dispel Assign",
            desc = "Link to a WA that assigns Avenger's Shield dispels - All healers, warlocks and dwarfs should have this. Dwarfs get the lowest priority on getting assigned. They will be told to use their racial if there are more debuffs than dispellers available.",
            func = function()
                WAButton("Paladins Dispel Assign", "PaladinsDispelAssign", "https://wago.io/NspRXIk6n")
            end,
            nocombat = true,
        },
        {
            type = "button",
            name = "Alleria P1 Dmg Amp",
            desc = "Displays the stacks of the dmg amp debuff on the nameplate of the 3 big adds. It is not perfect and might not display at all in some instances but it's better than nothing.",
            func = function()
                WAButton("Alleria P1 Dmg Amp", "AlleriaP1DmgAmp", "https://wago.io/yh2rnY4_8")
            end,
            nocombat = true,
        },
    }
end

local function BuildWACallback()
    return function()
    end
end

local function BuildWAImportsUI(parent)
    local Core = RRT_NS.UI and RRT_NS.UI.Core
    if not Core then
        return
    end

    local options_text_template = Core.options_text_template
    local options_dropdown_template = Core.options_dropdown_template
    local options_switch_template = Core.options_switch_template
    local options_slider_template = Core.options_slider_template

    local SIDEBAR_W = 130
    local ITEM_H = 20
    local PAD = 4
    local SECTIONS = {
        { name = "Midnight", key = "midnight", options = BuildWAImportsOptions(), callback = BuildWACallback() },
    }

    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)
    breadcrumb:SetText("|cFFBB66FF" .. SECTIONS[1].name .. "|r")

    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, 22)
    sidebar:SetWidth(SIDEBAR_W)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    local contentArea = CreateFrame("Frame", nil, parent)
    contentArea:SetPoint("TOPLEFT", parent, "TOPLEFT", SIDEBAR_W + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 22)

    local panels = {}
    for _, sec in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRTWAImportsSection_" .. sec.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()
        DF:BuildMenu(panel, sec.options, 10, -5, 520, false,
            options_text_template, options_dropdown_template, options_switch_template,
            true, options_slider_template, options_button_template, sec.callback)
        panels[sec.key] = panel
    end

    local activeBtn = nil
    local currentName = SECTIONS[1].name

    local function SelectSection(key, btn, name)
        for panelKey, panel in pairs(panels) do
            panel:SetShown(panelKey == key)
        end
        if activeBtn then
            activeBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            activeBtn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
        end
        local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1] * 0.4, c[2] * 0.4, c[3] * 0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        activeBtn = btn
        currentName = name
        local hex = string.format("%02X%02X%02X",
            math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
        breadcrumb:SetText("|cFF" .. hex .. name .. "|r")
    end

    for i, sec in ipairs(SECTIONS) do
        local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
        btn:SetSize(SIDEBAR_W - PAD * 2, ITEM_H)
        btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", PAD, -(PAD + (i - 1) * (ITEM_H + 4)))
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do
            local fontPath, _, fontFlags = GameFontNormalSmall:GetFont()
            if fontPath then
                btnText:SetFont(fontPath, 9, fontFlags or "")
            end
        end
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(sec.name)
        btnText:SetTextColor(0.9, 0.9, 0.9, 1)

        local key = sec.key
        local name = sec.name
        btn:SetScript("OnClick", function(self)
            SelectSection(key, self, name)
        end)
        btn:SetScript("OnEnter", function(self)
            if activeBtn ~= self then
                self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeBtn ~= self then
                self:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            end
        end)

        if i == 1 then
            SelectSection(key, btn, name)
        end
    end

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        if activeBtn then
            activeBtn:SetBackdropColor(r * 0.4, g * 0.4, b * 0.4, 0.8)
            activeBtn:SetBackdropBorderColor(r, g, b, 1)
        end
        local hex = string.format("%02X%02X%02X",
            math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
        breadcrumb:SetText("|cFF" .. hex .. currentName .. "|r")
    end)
end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.WAImports = {
    BuildOptions = BuildWAImportsOptions,
    BuildCallback = BuildWACallback,
    BuildUI = BuildWAImportsUI,
}
