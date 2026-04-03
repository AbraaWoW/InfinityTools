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

-- ─────────────────────────────────────────────────────────────────────────────
-- Main builder — called from RRTUI.lua after this file is loaded
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildExToolsUI(parent)
    local Opts = RRT_NS.UI.Options.ExTools

    local SECTIONS = {
        { name = "Auto Tools",    key = "autotools", build = Opts.BuildAutoToolsOptions  },
        { name = "Map & Display", key = "display",   build = Opts.BuildMapDisplayOptions },
        { name = "M+ Tools",      key = "mplus",     build = Opts.BuildMPlusOptions      },
        { name = "Class Tools",   key = "class",     build = Opts.BuildClassOptions      },
    }

    -- Breadcrumb
    local breadcrumb = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    breadcrumb:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -76)
    breadcrumb:SetText("|cFFBB66FF" .. SECTIONS[1].name .. "|r")

    -- Sidebar
    local sidebar = CreateFrame("Frame", "RRT_ExToolsSidebar", parent, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",    parent, "TOPLEFT",    4, -100)
    sidebar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4,  22)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    -- Content area
    local contentArea = CreateFrame("Frame", "RRT_ExToolsContent", parent)
    contentArea:SetPoint("TOPLEFT",     parent, "TOPLEFT",     SIDEBAR_WIDTH + 8, -100)
    contentArea:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 22)

    -- One panel per section
    local panels = {}
    local menuH  = window_height - 120

    for _, sec in ipairs(SECTIONS) do
        local panel = CreateFrame("Frame", "RRT_ExToolsSection_" .. sec.key, contentArea)
        panel:SetAllPoints(contentArea)
        panel:Hide()

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
RRT_NS.UI.ExTools = { BuildExToolsUI = BuildExToolsUI }
