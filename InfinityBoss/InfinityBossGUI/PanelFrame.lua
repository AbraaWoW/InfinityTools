---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/PanelFrame.lua
-- =============================================================


local Panel = InfinityBoss.UI.Panel
local L = InfinityBoss.L or setmetatable({}, { __index = function(_, key) return key end })

-- =============================================================
-- Cross-page accent color registry
-- =============================================================
InfinityBoss.UI._accentRefs = InfinityBoss.UI._accentRefs or {}

function InfinityBoss.UI.RegisterAccent(obj, objType, alpha)
    if obj then
        table.insert(InfinityBoss.UI._accentRefs, { obj = obj, t = objType, a = alpha or 1.0 })
    end
end

function InfinityBoss.UI.ApplyThemeColor(r, g, b)
    for _, ref in ipairs(InfinityBoss.UI._accentRefs) do
        if ref.obj and ref.t == "text" then
            ref.obj:SetTextColor(r, g, b, 1)
        elseif ref.obj and ref.t == "texture" then
            ref.obj:SetColorTexture(r, g, b, ref.a)
        end
    end
end

-- Register with RRT global callbacks (fires on UI Appearance color change)
_G.RRT = _G.RRT or {}
_G.RRT.GlobalThemeCallbacks = _G.RRT.GlobalThemeCallbacks or {}
table.insert(_G.RRT.GlobalThemeCallbacks, function(r, g, b)
    InfinityBoss.UI.ApplyThemeColor(r, g, b)
end)

-- =============================================================
-- =============================================================
local PANEL_W   = 1560
local PANEL_H   = 980
local TAB_H     = 36
local TAB_BAR_Y = -30
local LEFT_W    = 380
local CONTENT_X = LEFT_W + 10

local TABS = {
    { key = "voicepack",     label = "Voice / Config" },
    { key = "boss",          label = "Dungeons" },
    { key = "mdt",           label = "MDT" },
    { key = "globalsettings",label = "Settings" },
    { key = "importexport",  label = "Import / Export" },
    { key = "fixedtimeline", label = "Timeline" },
}

-- =============================================================
-- =============================================================
local mainFrame    = nil
local tabButtons   = {}
local tabIndexByKey = {}
local leftFrame    = nil
local contentFrame = nil
local currentTab   = "boss"

local function IsMDTEnabled()
    if InfinityBoss and InfinityBoss.MDT and type(InfinityBoss.MDT.IsEnabled) == "function" then
        return InfinityBoss.MDT.IsEnabled()
    end
    return true
end

local function BuildVisibleTabs()
    local out = {}
    for i = 1, #TABS do
        local tabDef = TABS[i]
        if tabDef.key ~= "mdt" or IsMDTEnabled() then
            out[#out + 1] = tabDef
        end
    end
    return out
end

local function NormalizeTabKey(tabKey)
    local requested = tabKey or "boss"
    if requested == "voice" then
        requested = "voicepack"
    end
    if requested == "timeline" then
        requested = "fixedtimeline"
    end
    if requested == "index" then
        requested = "boss"
    end
    if requested == "general" then
        requested = "globalsettings"
    end
    if requested == "import" or requested == "export" or requested == "impexp" then
        requested = "importexport"
    end
    if requested == "trashcd" then
        requested = "mdt"
    end
    return requested
end

local function IsTabVisible(tabKey)
    local key = NormalizeTabKey(tabKey)
    for i = 1, #TABS do
        local tabDef = TABS[i]
        if tabDef.key == key then
            return key ~= "mdt" or IsMDTEnabled()
        end
    end
    return false
end

local function ResolveSafeTab(tabKey)
    local key = NormalizeTabKey(tabKey)
    if IsTabVisible(key) then
        return key
    end
    return "boss"
end

local function RefreshEditModeButtonLabel()
    if not mainFrame or not mainFrame._editModeBtn then return end
    local ET = _G.InfinityTools
    local enabled = ET and ET.GlobalEditMode == true
    mainFrame._editModeBtn:SetText(enabled and "Disable Edit Mode" or "Enable Edit Mode")
end

local function ShouldUseLeftNav(tabKey)
    return tabKey == "boss" or tabKey == "globalsettings"
end

local atlasExistCache = {}

local function HasAtlas(atlasName)
    if type(atlasName) ~= "string" or atlasName == "" then
        return false
    end
    local cached = atlasExistCache[atlasName]
    if cached ~= nil then
        return cached
    end
    local ok = true
    if C_Texture and C_Texture.GetAtlasInfo then
        ok = C_Texture.GetAtlasInfo(atlasName) ~= nil
    end
    atlasExistCache[atlasName] = ok and true or false
    return atlasExistCache[atlasName]
end

local function FindScrollBar(scrollFrame)
    if not scrollFrame then
        return nil
    end
    if scrollFrame.ScrollBar then
        return scrollFrame.ScrollBar
    end
    local frameName = scrollFrame.GetName and scrollFrame:GetName()
    if frameName and _G[frameName .. "ScrollBar"] then
        return _G[frameName .. "ScrollBar"]
    end
    local children = { scrollFrame:GetChildren() }
    for _, child in ipairs(children) do
        if child and child.GetObjectType and child:GetObjectType() == "Slider" then
            return child
        end
    end
    return nil
end

local function HideLegacyScrollBar(scrollBar)
    if not scrollBar then
        return
    end
    scrollBar:Hide()
    scrollBar:EnableMouse(false)
    local barName = scrollBar.GetName and scrollBar:GetName()
    local candidates = {
        scrollBar.ScrollUpButton,
        scrollBar.ScrollDownButton,
        scrollBar.ThumbTexture,
        barName and _G[barName .. "ScrollUpButton"] or nil,
        barName and _G[barName .. "ScrollDownButton"] or nil,
        barName and _G[barName .. "ThumbTexture"] or nil,
    }
    for _, obj in ipairs(candidates) do
        if obj then
            obj:Hide()
            if obj.EnableMouse then
                obj:EnableMouse(false)
            end
        end
    end
end

local function EnsureMinimalScrollBarFallback(scrollBar)
    if not scrollBar then
        return
    end

    local track = scrollBar.Track or (scrollBar.GetTrack and scrollBar:GetTrack()) or nil
    if track then
        if not track._exFallbackLine then
            local line = track:CreateTexture(nil, "BACKGROUND")
            line:SetTexture("Interface\\Buttons\\WHITE8X8")
            line:SetVertexColor(0.18, 0.18, 0.22, 0.95)
            line:SetPoint("TOP", track, "TOP", 0, 0)
            line:SetPoint("BOTTOM", track, "BOTTOM", 0, 0)
            line:SetWidth(2)
            track._exFallbackLine = line

            local glow = track:CreateTexture(nil, "BORDER")
            glow:SetTexture("Interface\\Buttons\\WHITE8X8")
            glow:SetVertexColor(0.32, 0.34, 0.42, 0.45)
            glow:SetPoint("TOP", line, "TOP", 0, 1)
            glow:SetPoint("BOTTOM", line, "BOTTOM", 0, -1)
            glow:SetWidth(6)
            track._exFallbackGlow = glow
        end
        track._exFallbackLine:Show()
        track._exFallbackGlow:Show()
    end

    local thumb = (track and track.Thumb) or (scrollBar.GetThumb and scrollBar:GetThumb()) or nil
    if thumb and not thumb._exFallbackBody then
        local body = thumb:CreateTexture(nil, "ARTWORK")
        body:SetTexture("Interface\\Buttons\\WHITE8X8")
        body:SetVertexColor(0.60, 0.64, 0.58, 0.95)
        body:SetPoint("TOP", thumb, "TOP", 0, 0)
        body:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
        body:SetWidth(6)
        thumb._exFallbackBody = body
    end
    if thumb and thumb._exFallbackBody then
        thumb._exFallbackBody:Show()
    end
end

local function ApplyModernScrollBarSkin(scrollFrame)
    if not scrollFrame then
        return
    end
    if not (ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar) then
        return
    end

    local legacyScrollBar = FindScrollBar(scrollFrame)
    if legacyScrollBar then
        HideLegacyScrollBar(legacyScrollBar)
    end

    local scrollBar = scrollFrame._exModernScrollBar
    if not scrollBar then
        local owner = scrollFrame:GetParent() or UIParent
        local ok, created = pcall(CreateFrame, "EventFrame", nil, owner, "MinimalScrollBar")
        if not ok or not created then
            return
        end
        scrollBar = created
        scrollBar:SetFrameStrata(scrollFrame:GetFrameStrata())
        scrollBar:SetFrameLevel(scrollFrame:GetFrameLevel() + 5)
        scrollFrame._exModernScrollBar = scrollBar
        scrollFrame:EnableMouseWheel(true)
        ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)
        scrollFrame:HookScript("OnShow", function(self)
            if self._exModernScrollBar then
                self._exModernScrollBar:Show()
            end
        end)
        scrollFrame:HookScript("OnHide", function(self)
            if self._exModernScrollBar then
                self._exModernScrollBar:Hide()
            end
        end)
    end

    local owner = scrollFrame:GetParent() or UIParent
    if scrollBar:GetParent() ~= owner then
        scrollBar:SetParent(owner)
    end
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 0, -4)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -1, 7)
    EnsureMinimalScrollBarFallback(scrollBar)
    if scrollFrame:IsShown() then
        scrollBar:Show()
    else
        scrollBar:Hide()
    end
end

InfinityBoss.UI.ApplyModernScrollBarSkin = ApplyModernScrollBarSkin

-- =============================================================
-- =============================================================
local function RefreshContent()
    if not contentFrame then return end

    if mainFrame then
        local useLeft = ShouldUseLeftNav(currentTab)
        local expectFull = not useLeft
        if contentFrame._fullWidthMode ~= expectFull then
            local contentTopY = TAB_BAR_Y - TAB_H - 4
            contentFrame:ClearAllPoints()
            if useLeft then
                contentFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", CONTENT_X + 4, contentTopY)
            else
                contentFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 4, contentTopY)
            end
            contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 4)
            contentFrame._fullWidthMode = expectFull
        end
    end

    if mainFrame and PanelTemplates_SetTab then
        local tabIndex = tabIndexByKey[currentTab]
        if tabIndex then
            PanelTemplates_SetTab(mainFrame, tabIndex)
        end
    end

    if contentFrame._placeholder then
        contentFrame._placeholder:SetText("")
        contentFrame._placeholder:Hide()
    end

    local BossPage       = InfinityBoss.UI.Panel.BossPage
    local FixedTimelinePage = InfinityBoss.UI.Panel.FixedTimelinePage
    local GlobalSettingsPage = InfinityBoss.UI.Panel.GlobalSettingsPage
    local ImportExportPage = InfinityBoss.UI.Panel.ImportExportPage
    local MDTPage = InfinityBoss.UI.Panel.MDTPage
    local OtherVoicePage = InfinityBoss.UI.Panel.OtherVoicePage
    local TimerBarPage   = InfinityBoss.UI.Panel.TimerBarPage
    local BunBarPage     = InfinityBoss.UI.Panel.BunBarPage
    local CountdownPage  = InfinityBoss.UI.Panel.CountdownPage
    local FlashTextPage  = InfinityBoss.UI.Panel.FlashTextPage
    local VoicePackPage  = InfinityBoss.UI.Panel.VoicePackPage
    for _, page in ipairs({ TimerBarPage, BunBarPage, CountdownPage, FlashTextPage }) do
        if page and page._scrollFrame then page._scrollFrame:Hide() end
    end
    if BossPage and BossPage.Hide then BossPage:Hide() end
    if FixedTimelinePage and FixedTimelinePage.Hide then FixedTimelinePage:Hide() end
    if GlobalSettingsPage and GlobalSettingsPage.Hide then GlobalSettingsPage:Hide() end
    if ImportExportPage and ImportExportPage.Hide then ImportExportPage:Hide() end
    if VoicePackPage and VoicePackPage.Hide then VoicePackPage:Hide() end
    if MDTPage and MDTPage.Hide then MDTPage:Hide() end
    if OtherVoicePage and OtherVoicePage.Hide then OtherVoicePage:Hide() end

    if currentTab == "boss" then
        leftFrame:Show()
        if BossPage and BossPage.Render then
            if leftFrame._placeholderLabel then
                leftFrame._placeholderLabel:Hide()
            end
            BossPage:Render(leftFrame, contentFrame)
        else
            if leftFrame._placeholderLabel then
                leftFrame._placeholderLabel:Show()
            end
            if contentFrame._placeholder then
                contentFrame._placeholder:SetText("Boss spell page is not ready.")
                contentFrame._placeholder:Show()
            end
        end

    elseif currentTab == "fixedtimeline" then
        leftFrame:Hide()
        if FixedTimelinePage and FixedTimelinePage.Render then
            FixedTimelinePage:Render(contentFrame)
        else
            if contentFrame._placeholder then
                contentFrame._placeholder:SetText("Fixed timeline preview page is not ready.")
                contentFrame._placeholder:Show()
            end
        end

    elseif currentTab == "mdt" then
        leftFrame:Hide()
        if MDTPage and MDTPage.Render then
            MDTPage:Render(contentFrame)
        else
            if contentFrame._placeholder then
                contentFrame._placeholder:SetText("MDT page is not ready.")
                contentFrame._placeholder:Show()
            end
        end

    elseif currentTab == "globalsettings" then
        leftFrame:Show()
        if GlobalSettingsPage and GlobalSettingsPage.Render then
            if leftFrame._placeholderLabel then
                leftFrame._placeholderLabel:Hide()
            end
            GlobalSettingsPage:Render(leftFrame, contentFrame)
        else
            if leftFrame._placeholderLabel then
                leftFrame._placeholderLabel:Show()
            end
            if contentFrame._placeholder then
                contentFrame._placeholder:SetText("General settings page is not ready.")
                contentFrame._placeholder:Show()
            end
        end

    elseif currentTab == "voicepack" then
        leftFrame:Hide()
        if VoicePackPage and VoicePackPage.Render then
            local ok, err = pcall(function()
                VoicePackPage:Render(contentFrame)
            end)
            if not ok and contentFrame._placeholder then
                contentFrame._placeholder:SetText(string.format("Voice pack page error:\n%s", tostring(err)))
                contentFrame._placeholder:Show()
            end
        else
            if contentFrame._placeholder then
                contentFrame._placeholder:SetText("Voice pack page is not ready.")
                contentFrame._placeholder:Show()
            end
        end

    elseif currentTab == "othervoice" then
        leftFrame:Hide()
        if OtherVoicePage and OtherVoicePage.Render then
            local ok, err = pcall(function()
                OtherVoicePage:Render(contentFrame)
            end)
            if not ok and contentFrame._placeholder then
                contentFrame._placeholder:SetText(string.format("Other voice page error:\n%s", tostring(err)))
                contentFrame._placeholder:Show()
            end
        else
            if contentFrame._placeholder then
                contentFrame._placeholder:SetText("Other voice page is not ready.")
                contentFrame._placeholder:Show()
            end
        end

    elseif currentTab == "importexport" then
        leftFrame:Hide()
        if ImportExportPage and ImportExportPage.Render then
            ImportExportPage:Render(contentFrame)
        else
            if contentFrame._placeholder then
                contentFrame._placeholder:SetText("Import / Export page is not ready.")
                contentFrame._placeholder:Show()
            end
        end

    else
        leftFrame:Hide()
        if contentFrame._placeholder then
            contentFrame._placeholder:SetText(string.format("Settings page [%s] - pending.", currentTab))
            contentFrame._placeholder:Show()
        end
    end
end

-- =============================================================
-- =============================================================
local function CreatePanel()
    if mainFrame then return end


    mainFrame = CreateFrame("Frame", "InfinityBoss_MainPanel", UIParent, "BackdropTemplate")
    mainFrame:SetSize(PANEL_W, PANEL_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(false)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    mainFrame:Hide()

    if not tContains(UISpecialFrames, "InfinityBoss_MainPanel") then
        table.insert(UISpecialFrames, "InfinityBoss_MainPanel")
    end

    mainFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left=3, right=3, top=3, bottom=3 },
    })
    mainFrame:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
    mainFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)

    local titleBar = mainFrame:CreateTexture(nil, "BACKGROUND")
    titleBar:SetPoint("TOPLEFT",  mainFrame, "TOPLEFT",  4, -4)
    titleBar:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -4, -4)
    titleBar:SetHeight(28)
    titleBar:SetColorTexture(0.12, 0.12, 0.16, 1)

    local titleText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    titleText:SetText("|cffBB66FFInfinity|r|cff00ccffBoss|r  " .. InfinityBoss.VERSION)

    local dragHandle = CreateFrame("Frame", nil, mainFrame)
    dragHandle:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 0, 0)
    dragHandle:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function()
        mainFrame:StartMoving()
    end)
    dragHandle:SetScript("OnDragStop", function()
        mainFrame:StopMovingOrSizing()
    end)

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)
    do
        local nTex = closeBtn:GetNormalTexture()
        if nTex then nTex:SetVertexColor(1, 0.15, 0.15, 1) end
        local hTex = closeBtn:GetHighlightTexture()
        if hTex then hTex:SetVertexColor(1, 0.4, 0.4, 1) end
        local pTex = closeBtn:GetPushedTexture()
        if pTex then pTex:SetVertexColor(0.7, 0.05, 0.05, 1) end
    end

    local editModeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    editModeBtn:SetSize(120, 22)
    editModeBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, -1)
    editModeBtn:SetScript("OnClick", function()
        local ET = _G.InfinityTools
        if ET and ET.ToggleGlobalEditMode then
            ET:ToggleGlobalEditMode()
            RefreshEditModeButtonLabel()
            if ET.GlobalEditMode and mainFrame:IsShown() then
                mainFrame:Hide()
            end
        end
    end)
    mainFrame._editModeBtn = editModeBtn
    RefreshEditModeButtonLabel()
    local ET = _G.InfinityTools
    if ET and ET.RegisterEditModeCallback then
        ET:RegisterEditModeCallback("InfinityBoss.Panel.EditButton", function()
            RefreshEditModeButtonLabel()
        end)
    end

    dragHandle:SetPoint("RIGHT", editModeBtn, "LEFT", -6, 0)

    local tabBarY = TAB_BAR_Y
    local prevTab = nil
    local visibleTabs = BuildVisibleTabs()
    for i, tabDef in ipairs(visibleTabs) do
        local btn = CreateFrame("Button", "InfinityBoss_MainPanelTab" .. i, mainFrame, "PanelTopTabButtonTemplate")
        btn:SetID(i)
        if prevTab then
            btn:SetPoint("LEFT", prevTab, "RIGHT", -15, 0)
        else
            btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, tabBarY)
        end
        btn:SetText(tabDef.label)
        if PanelTemplates_TabResize then
            PanelTemplates_TabResize(btn, 0)
        end
        btn._tabKey = tabDef.key

        btn:SetScript("OnClick", function(self)
            currentTab = self._tabKey
            RefreshContent()
        end)

        tabButtons[tabDef.key] = btn
        tabIndexByKey[tabDef.key] = i
        prevTab = btn
    end
    if PanelTemplates_SetNumTabs then
        PanelTemplates_SetNumTabs(mainFrame, #visibleTabs)
    end

    local contentTopY = tabBarY - TAB_H - 4
    leftFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    leftFrame:SetPoint("TOPLEFT",    mainFrame, "TOPLEFT",  4, contentTopY)
    leftFrame:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 4, 4)
    leftFrame:SetWidth(LEFT_W)
    leftFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left=2, right=2, top=2, bottom=2 },
    })
    leftFrame:SetBackdropColor(0.06, 0.06, 0.08, 1)
    leftFrame:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)

    local leftLabel = leftFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leftLabel:SetPoint("TOP", leftFrame, "TOP", 0, -10)
    leftLabel:SetTextColor(0.5, 0.5, 0.5, 1)
    leftLabel:SetText("Dungeon / Boss Navigation\n(Pending)")
    leftFrame._placeholderLabel = leftLabel

    Panel.leftFrame = leftFrame

    contentFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",  CONTENT_X + 4, contentTopY)
    contentFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 4)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left=2, right=2, top=2, bottom=2 },
    })
    contentFrame:SetBackdropColor(0.07, 0.07, 0.09, 1)
    contentFrame:SetBackdropBorderColor(0.2, 0.2, 0.25, 1)
    Panel.contentFrame = contentFrame

    local placeholder = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    placeholder:SetPoint("CENTER")
    placeholder:SetTextColor(0.5, 0.5, 0.5, 1)
    placeholder:SetJustifyH("CENTER")
    placeholder:SetText("")
    contentFrame._placeholder = placeholder

    local statusText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 12, 8)
    statusText:SetTextColor(0.5, 0.5, 0.5, 1)
    statusText:SetText("/exb  open/close    |    /exb edit  edit mode    |    /exb debug  debug")
    Panel.statusText = statusText

    local changelogBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    changelogBtn:SetSize(88, 22)
    changelogBtn:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -12, 6)
    changelogBtn:SetText("Changelog")
    changelogBtn:SetScript("OnClick", function()
        if InfinityBoss and InfinityBoss.ShowChangelog then
            InfinityBoss:ShowChangelog({ markShown = true })
        end
    end)
    Panel.changelogBtn = changelogBtn

    Panel._frame = mainFrame

    -- Restore saved theme color from RRT (deferred so RRTDB is ready)
    C_Timer.After(0.2, function()
        local c = _G.RRT and _G.RRT.Settings and _G.RRT.Settings.TabSelectionColor
        if c then InfinityBoss.UI.ApplyThemeColor(c[1], c[2], c[3]) end
    end)
end

-- =============================================================
-- =============================================================
function Panel:Toggle()
    CreatePanel()
    currentTab = ResolveSafeTab(currentTab)
    RefreshEditModeButtonLabel()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        local BossPage = InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.BossPage
        if BossPage and BossPage.OnPanelShown then
            BossPage:OnPanelShown()
        end
        RefreshContent()
    end
end

function Panel:Show()
    CreatePanel()
    currentTab = ResolveSafeTab(currentTab)
    RefreshEditModeButtonLabel()
    mainFrame:Show()
    local BossPage = InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.BossPage
    if BossPage and BossPage.OnPanelShown then
        BossPage:OnPanelShown()
    end
    RefreshContent()
end

function Panel:Hide()
    if mainFrame then mainFrame:Hide() end
end

function Panel:SetTab(tabKey)
    local requested = NormalizeTabKey(tabKey)
    if requested == "timerbar" or requested == "bunbar" or requested == "countdown" or requested == "flashtext" then
        local globalPage = InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.GlobalSettingsPage
        if globalPage and globalPage.SetSelectedKey then
            globalPage:SetSelectedKey(requested)
        end
        requested = "globalsettings"
    end
    currentTab = ResolveSafeTab(requested)
    if mainFrame and mainFrame:IsShown() then
        RefreshContent()
    end
end
