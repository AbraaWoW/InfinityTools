-- [[ MDT Spell Icon Hook ]]
-- { Key = "RevMplusInfo.MDTIconHook", Name = "MDT Spell Icon Hook", Desc = "Replaces enemy portraits in the MDT map with spell icons and supports automatic raid markers.", Category = 2 },

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevMplusInfo.MDTIconHook"
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local INFINITY_DEFAULTS = {
    enabled = false,
    useSpellIconMode = false,


    interruptMarkerIcon = "1", -- Default: Skull
    eliteMarkerIcon = "8",     -- Default: Star

    customNPCIcons = {},
    blacklistNPCs = {},
    customIconsText = "", -- Cached text
    blacklistText = "",   -- Cached text
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)
MODULE_DB.customNPCIcons = MODULE_DB.customNPCIcons or {}
MODULE_DB.blacklistNPCs = MODULE_DB.blacklistNPCs or {}

local RAID_MARKER_DROPDOWN_ITEMS = {
    { L["None"], "0" },
    { L["Star (1)"], "1" },
    { L["Circle (2)"], "2" },
    { L["Diamond (3)"], "3" },
    { L["Triangle (4)"], "4" },
    { L["Moon (5)"], "5" },
    { L["Square (6)"], "6" },
    { L["Cross (7)"], "7" },
    { L["Skull (8)"], "8" },
}

local MDT_HOOK_INSTALLED = false
local MDT_BUTTONS_CREATED = false
local MDT_BUTTON_RETRY_PENDING = false
local MDT_PANEL_FRAME_HOOKED = false
local ELITE_LEVEL_BASE_CACHE = {}

local function RefreshMDTMap(silent)
    local MDT = _G.MDT
    local frame = MDT and MDT.main_frame
    if MDT and MDT.UpdateMap and frame and frame.sidePanel and frame.sidePanel.DifficultySlider then
        MDT:UpdateMap()
        if not silent then
            print("|cff00ff00[InfinityTools]|r " .. L["MDT refreshed."])
        end
    end
end

local function RefreshMDTMapDeferred(silent)
    local MDT = _G.MDT
    local frame = MDT and MDT.main_frame
    if MDT and MDT.Async and frame and frame.sidePanel and frame.sidePanel.DifficultySlider then
        MDT:Async(function()
            RefreshMDTMap(silent)
        end, "InfinityTools_MDTIconHook_RefreshMap", true)
        return
    end

    C_Timer.After(0, function()
        RefreshMDTMap(silent)
    end)
end

local function NormalizeMarkerIndex(value)
    local n = tonumber(value)
    if not n or n < 1 or n > 8 then
        return nil
    end
    return n
end

local function HasInterruptibleSpell(data)
    if not data or not data.spells then return false end
    for _, spellInfo in pairs(data.spells) do
        if type(spellInfo) == "table" and spellInfo.interruptible then
            return true
        end
    end
    return false
end

local function GetManualAssignment(enemyIdx, cloneIdx)
    local MDT = _G.MDT
    if not MDT or not MDT.GetCurrentPreset then return nil end
    local preset = MDT:GetCurrentPreset()
    local assignments = preset and preset.value and preset.value.enemyAssignments
    return assignments and assignments[enemyIdx] and assignments[enemyIdx][cloneIdx] or nil
end

local function GetCurrentDungeonEnemyTable()
    local MDT = _G.MDT
    if not MDT or not MDT.dungeonEnemies or not MDT.GetDB then return nil, nil end
    local db = MDT:GetDB()
    local dungeonIdx = db and db.currentDungeonIdx
    if not dungeonIdx then return nil, nil end
    return MDT.dungeonEnemies[dungeonIdx], dungeonIdx
end


local function GetEliteLevelBase()
    local enemies, dungeonIdx = GetCurrentDungeonEnemyTable()
    if not enemies or not dungeonIdx then return nil end

    local cached = ELITE_LEVEL_BASE_CACHE[dungeonIdx]
    if cached ~= nil then
        return cached or nil
    end

    local minLevel, maxLevel
    for _, enemy in pairs(enemies) do
        if enemy and not enemy.isBoss then
            local level = tonumber(enemy.level)
            if level then
                if not minLevel or level < minLevel then minLevel = level end
                if not maxLevel or level > maxLevel then maxLevel = level end
            end
        end
    end

    if not minLevel or not maxLevel or maxLevel <= minLevel then
        ELITE_LEVEL_BASE_CACHE[dungeonIdx] = false
        return nil
    end

    ELITE_LEVEL_BASE_CACHE[dungeonIdx] = minLevel
    return minLevel
end

local function IsEliteEnemy(data)
    if not data or data.isBoss then return false end
    local level = tonumber(data.level)
    if not level then return false end
    local baseLevel = GetEliteLevelBase()
    return baseLevel and level > baseLevel or false
end

local function ApplyCustomSettings()
    wipe(MODULE_DB.customNPCIcons)
    local rawMap = MODULE_DB.customIconsText or ""
    for line in rawMap:gmatch("[^\r\n]+") do
        local n, s = line:match("(%d+)%s*=%s*(%d+)")
        if n and s then
            MODULE_DB.customNPCIcons[tonumber(n)] = tonumber(s)
        end
    end

    wipe(MODULE_DB.blacklistNPCs)
    local rawBlack = MODULE_DB.blacklistText or ""
    for id in rawBlack:gmatch("(%d+)") do
        MODULE_DB.blacklistNPCs[tonumber(id)] = true
    end

    RefreshMDTMap(false)
end

local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 3, y = 1, w = 50, h = 2, label = L["MDT Spell Icon Hook"], labelSize = 25 },
        { key = "desc", type = "description", x = 3, y = 4, w = 50, h = 2, label = L["Supports spell icon replacement plus one-shot real raid markers written into the current MDT route."] },
        { key = "enabled", type = "checkbox", x = 3, y = 8, w = 10, h = 2, label = L["Enable Feature"] },
        { key = "divider_top", type = "divider", x = 3, y = 6, w = 50, h = 1, label = L["Components"] },

        { key = "sub_c", type = "subheader", x = 3, y = 11, w = 21, h = 2, label = L["Custom Icons (NPCID = SpellID), one per line"] },
        { key = "customIconsText", type = "input", x = 3, y = 13, w = 24, h = 17, label = "" },
        { key = "sub_b", type = "subheader", x = 28, y = 11, w = 23, h = 2, label = L["Blacklisted NPCs (comma-separated IDs)"] },
        { key = "blacklistText", type = "input", x = 28, y = 13, w = 23, h = 17, label = "" },
        { key = "apply", type = "button", x = 3, y = 31, w = 48, h = 3, label = L["Save and Refresh (text config only applies after this)"] },

        { key = "divider_marker", type = "divider", x = 3, y = 35, w = 50, h = 1, label = L["Real Raid Markers (one-time write)"] },
        { key = "marker_desc", type = "description", x = 3, y = 36, w = 49, h = 2, label = "|cff97a393" .. L["Writes into the current route when clicking the left/MDT buttons. It will not auto-overwrite or auto-clear."] .. "|r" },

        { key = "interruptMarkerIcon", type = "dropdown", x = 3, y = 39, w = 16, h = 2, label = L["Interrupt Marker"], items = RAID_MARKER_DROPDOWN_ITEMS },
        { key = "btn_apply_interrupt_markers", type = "button", x = 22, y = 38, w = 29, h = 3, label = L["Apply real markers to all interrupt mobs"] },

        { key = "eliteMarkerIcon", type = "dropdown", x = 3, y = 42, w = 16, h = 2, label = L["Elite Marker"], items = RAID_MARKER_DROPDOWN_ITEMS },
        { key = "btn_apply_elite_markers", type = "button", x = 22, y = 41, w = 29, h = 3, label = L["Apply real markers to all elite mobs"] },
    }

    for _, item in ipairs(layout) do
        if item.key == "apply" then
            item.func = ApplyCustomSettings
            break
        end
    end

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

local function ApplyTrueMarkersByRule(ruleType)
    local MDT = _G.MDT
    if not MDT or not MDT.GetCurrentPreset or not MDT.GetDB then
        print("|cffff8800[InfinityTools]|r " .. L["MDT not detected. Cannot write real markers."])
        return false
    end

    local preset = MDT:GetCurrentPreset()
    local db = MDT:GetDB()
    local dungeonIdx = db and db.currentDungeonIdx
    if not preset or not preset.value or not dungeonIdx then
        print("|cffff8800[InfinityTools]|r " .. L["No current MDT route detected. Cannot write real markers."])
        return false
    end

    local enemies = MDT.dungeonEnemies and MDT.dungeonEnemies[dungeonIdx]
    if not enemies then
        print("|cffff8800[InfinityTools]|r " .. L["No MDT enemy data found for the current dungeon."])
        return false
    end

    local markerIndex
    local matchFunc
    local ruleName
    if ruleType == "interrupt" then
        markerIndex = NormalizeMarkerIndex(MODULE_DB.interruptMarkerIcon)
        matchFunc = HasInterruptibleSpell
        ruleName = L["Interrupt Mobs"]
    elseif ruleType == "elite" then
        markerIndex = NormalizeMarkerIndex(MODULE_DB.eliteMarkerIcon)
        matchFunc = IsEliteEnemy
        ruleName = L["Elite Mobs"]
    else
        return false
    end

    if not markerIndex then
        print("|cffff8800[InfinityTools]|r " .. L["Please select a valid raid marker first."])
        return false
    end

    preset.value.enemyAssignments = preset.value.enemyAssignments or {}
    local assignments = preset.value.enemyAssignments

    local appliedCount, skippedManualCount = 0, 0
    for enemyIdx, data in pairs(enemies) do
        if data and matchFunc(data) then
            for cloneIdx, _ in pairs(data.clones or {}) do
                local current = assignments[enemyIdx] and assignments[enemyIdx][cloneIdx] or nil
                if current == nil then
                    assignments[enemyIdx] = assignments[enemyIdx] or {}
                    assignments[enemyIdx][cloneIdx] = markerIndex
                    appliedCount = appliedCount + 1
                else
                    skippedManualCount = skippedManualCount + 1
                end
            end
        end
    end

    RefreshMDTMap(true)
    print(string.format("|cff00ff00[InfinityTools]|r " .. L["Wrote MDT real markers for %s: added %d, skipped %d existing markers"],
        ruleName, appliedCount, skippedManualCount))
    return true
end

local function ClearAllTrueMarkers()
    local MDT = _G.MDT
    if not MDT or not MDT.GetCurrentPreset then return false end
    local preset = MDT:GetCurrentPreset()
    if not preset or not preset.value then return false end

    preset.value.enemyAssignments = {}
    RefreshMDTMap(true)
    print("|cff00ff00[InfinityTools]|r " .. L["Cleared all markers from the current MDT route."])
    return true
end

local function InitializeMDTVisuals()
    if MDT_HOOK_INSTALLED then return true end

    local Mixin = _G.MDTDungeonEnemyMixin
    if not Mixin or not Mixin.SetUp then
        return false
    end

    MDT_HOOK_INSTALLED = true

    hooksecurefunc(Mixin, "SetUp", function(self, data, clone)
        if not MODULE_DB.enabled or not data then return end

        -- Feature 1: Replace portrait with spell icon (original logic)
        if MODULE_DB.useSpellIconMode and not data.isBoss and not data.iconTexture and not MODULE_DB.blacklistNPCs[data.id] then
            local targetID = MODULE_DB.customNPCIcons[data.id] or data.SPELLICON or (data.spells and next(data.spells))
            if targetID then
                local tex = C_Spell.GetSpellTexture(targetID)
                if tex and self.texture_Portrait then
                    self.texture_Portrait:SetTexture(tex)
                    self.texture_Portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                end
            end
        end
    end)

    return true
end

local function UpdateMDTButtonsVisual()
    local toggleBtn = _G.RevMDT_Btn_ToggleIcon
    if toggleBtn and toggleBtn.Text then
        if MODULE_DB.useSpellIconMode then
            toggleBtn.Text:SetTextColor(0.2, 1, 0.2)   -- Green = enabled
        else
            toggleBtn.Text:SetTextColor(0.6, 0.6, 0.6) -- Gray = disabled
        end
    end
end

local function ApplyElvUISkin(frame)
    if not frame then return false end
    local Skin = InfinityTools.ElvUISkin
    if not Skin or not Skin:IsElvUILoaded() then return false end

    Skin:SkinFrame(frame, "Transparent")
    local E = _G.ElvUI and _G.ElvUI[1]
    local S = E and E:GetModule("Skins", true)
    if S and S.CreateShadowModule then
        _G.pcall(S.CreateShadowModule, S, frame)
    end
    if frame.CloseButton then Skin:SkinCloseButton(frame.CloseButton) end
    return true
end

local function UpdateMDTActionPanelPosition()
    local panel = _G.RevMDT_ActionPanel
    local MDT = _G.MDT
    local mainFrame = MDT and MDT.main_frame
    if not panel or not mainFrame then return end

    panel:ClearAllPoints()
    panel:SetPoint("TOP", mainFrame, "BOTTOM", 0, -10)
end

local function UpdateMDTActionPanelVisibility()
    local panel = _G.RevMDT_ActionPanel
    local MDT = _G.MDT
    local mainFrame = MDT and MDT.main_frame
    if not panel then return end

    if MODULE_DB.enabled and mainFrame and mainFrame:IsShown() then
        UpdateMDTActionPanelPosition()
        panel:Show()
    else
        panel:Hide()
    end
end

local function HookMDTMainFrame()
    if MDT_PANEL_FRAME_HOOKED then return end

    local MDT = _G.MDT
    local mainFrame = MDT and MDT.main_frame
    if not mainFrame then return end

    MDT_PANEL_FRAME_HOOKED = true
    mainFrame:HookScript("OnShow", function()
        C_Timer.After(0.05, UpdateMDTActionPanelVisibility)
    end)
    mainFrame:HookScript("OnHide", function()
        UpdateMDTActionPanelVisibility()
    end)
    mainFrame:HookScript("OnSizeChanged", function()
        UpdateMDTActionPanelPosition()
    end)
end

local function CreateMDTTextButton(name, parent, width, labelText, onClick)
    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(width, 22)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER")
    txt:SetText(labelText)
    btn.Text = txt

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" and InfinityTools.OpenConfig then
            InfinityTools:OpenConfig(INFINITY_MODULE_KEY)
        else
            onClick(self, button)
        end
    end)
    btn:SetScript("OnEnter", function(self)
        if txt:GetTextColor() ~= 0.2 then
            txt:SetTextColor(1, 1, 1)
        end
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(labelText .. " (Right-click to open settings)", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        UpdateMDTButtonsVisual()
        if GameTooltip then GameTooltip:Hide() end
    end)

    return btn
end

local function CreateMDTButtons()
    local MDT = _G.MDT
    if not MDT or not MDT.main_frame then
        if not MDT_BUTTON_RETRY_PENDING then
            MDT_BUTTON_RETRY_PENDING = true
            C_Timer.After(1, function()
                MDT_BUTTON_RETRY_PENDING = false
                CreateMDTButtons()
            end)
        end
        return false
    end

    if not _G.RevMDT_ActionPanel then
        local panel
        local Skin = InfinityTools.ElvUISkin
        local isElv = Skin and Skin:IsElvUILoaded()

        if isElv then
            panel = CreateFrame("Frame", "RevMDT_ActionPanel", UIParent)
            panel:SetSize(300, 94)

            local title = panel:CreateFontString(nil, "OVERLAY")
            title:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
            title:SetPoint("TOP", 0, -8)
            title:SetTextColor(1, 0.82, 0)
            panel.TitleText = title

            local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
            close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
            panel.CloseButton = close

            ApplyElvUISkin(panel)
        else
            panel = CreateFrame("Frame", "RevMDT_ActionPanel", UIParent, "DefaultPanelTemplate")
            panel:SetSize(300, 94)
        end

        panel:SetFrameStrata("MEDIUM")
        panel:SetToplevel(true)
        if panel.TitleText then
            panel.TitleText:SetText(L["MDT Quick Actions"])
        end

        if panel.CloseButton then
            panel.CloseButton:HookScript("OnClick", function()
                panel:Hide()
            end)
        end

        if _G.UISpecialFrames then
            local exists = false
            for _, frameName in ipairs(_G.UISpecialFrames) do
                if frameName == "RevMDT_ActionPanel" then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(_G.UISpecialFrames, "RevMDT_ActionPanel")
            end
        end

        local content = CreateFrame("Frame", nil, panel)
        content:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -28)
        content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 8)
        panel.Content = content

        local btnWidth = 132
        local btnHeight = 22

        local btnToggle = CreateMDTTextButton("RevMDT_Btn_ToggleIcon", content, btnWidth, "Replace Icons", function()
            MODULE_DB.useSpellIconMode = not MODULE_DB.useSpellIconMode
            RefreshMDTMap(true)
            UpdateMDTButtonsVisual()
        end)
        btnToggle:SetSize(btnWidth, btnHeight)
        btnToggle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

        local btnInt = CreateMDTTextButton("RevMDT_Btn_Int", content, btnWidth, "Mark Interrupts", function()
            ApplyTrueMarkersByRule("interrupt")
        end)
        btnInt:SetSize(btnWidth, btnHeight)
        btnInt:SetPoint("LEFT", btnToggle, "RIGHT", 8, 0)

        local btnElite = CreateMDTTextButton("RevMDT_Btn_Elite", content, btnWidth, "Mark Elites", function()
            ApplyTrueMarkersByRule("elite")
        end)
        btnElite:SetSize(btnWidth, btnHeight)
        btnElite:SetPoint("TOPLEFT", btnToggle, "BOTTOMLEFT", 0, -10)

        local btnClear = CreateMDTTextButton("RevMDT_Btn_Clear", content, btnWidth, "Clear Markers", function()
            ClearAllTrueMarkers()
        end)
        btnClear:SetSize(btnWidth, btnHeight)
        btnClear:SetPoint("LEFT", btnElite, "RIGHT", 8, 0)

        panel:Hide()
    end

    HookMDTMainFrame()
    UpdateMDTActionPanelPosition()
    MDT_BUTTONS_CREATED = true
    UpdateMDTButtonsVisual()
    UpdateMDTActionPanelVisibility()
    return true
end

local function TryBootstrapMDT()
    InitializeMDTVisuals()
    CreateMDTButtons()
    ELITE_LEVEL_BASE_CACHE = {}
end

TryBootstrapMDT()
C_Timer.After(0.1, TryBootstrapMDT)

InfinityTools:RegisterEvent("ADDON_LOADED", INFINITY_MODULE_KEY .. "_MDT", function(_, addonName)
    if addonName == "MythicDungeonTools" then
        C_Timer.After(0.2, function()
            ELITE_LEVEL_BASE_CACHE = {}
            TryBootstrapMDT()
        end)
    end
end)

-- After Grid config changes, refresh the MDT map and button appearance
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    local key = info.key
    if key == "enabled"
        or key == "useSpellIconMode"
        or key == "interruptMarkerIcon"
        or key == "eliteMarkerIcon" then
        ELITE_LEVEL_BASE_CACHE = {}
        UpdateMDTButtonsVisual()
        UpdateMDTActionPanelVisibility()
        -- One-shot real marker scheme: config changes do not auto-write, to avoid interfering with the player's manual operations in MDT
        if key == "enabled" or key == "useSpellIconMode" then
            RefreshMDTMapDeferred(true)
        end
    end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    if info.key == "btn_apply_interrupt_markers" then
        ApplyTrueMarkersByRule("interrupt")
    elseif info.key == "btn_apply_elite_markers" then
        ApplyTrueMarkersByRule("elite")
    end
    UpdateMDTButtonsVisual()
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)

