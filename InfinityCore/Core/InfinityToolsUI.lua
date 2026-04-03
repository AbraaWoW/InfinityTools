-- =========================================================
-- Comment translated to English
-- =========================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus -- Backward-compatible local alias while modules are migrated.
if not InfinityTools then return end

local L = InfinityTools.L

-- Comment translated to English
local RevUI = InfinityTools.UI or {}
InfinityTools.UI = RevUI
_G.InfinityToolsUI = RevUI
_G.InfinityMythicPlusUI = RevUI


-- =========================================================
-- Comment translated to English
-- =========================================================
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
-- Comment translated to English
-- Comment translated to English
local defaultFontPath = GameFontNormal:GetFont()
-- Comment translated to English
local msyh = defaultFontPath
local msyhbd = defaultFontPath


local THEME = {
-- Comment translated to English
    Background = { 0.04, 0.04, 0.05, 0.98 }, -- Comment translated to English
    Sidebar = { 0, 0, 0, 0 }, -- Comment translated to English
    Border = { 0.25, 0.25, 0.28, 1 }, -- Comment translated to English
    Primary = { 0.733, 0.4, 1.0 }, -- Comment translated to English
    Success = { 0.13, 0.77, 0.37 },
    Danger = { 0.87, 0.26, 0.26 },
    TextMain = { 0.9, 0.9, 0.9, 1 },
    TextSub = { 0.6, 0.6, 0.65, 1 },
    TextDim = { 0.4, 0.4, 0.45, 1 },
    CardBg = { 0.18, 0.18, 0.22, 0.6 },
    CardBgHover = { 0.22, 0.22, 0.26, 0.8 },
}

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local BACKDROP_SIMPLE = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = nil,
}

-- =========================================================
-- Comment translated to English
-- =========================================================
RevUI.MainFrame = nil -- Comment translated to English
RevUI.SidebarFrame = nil -- Comment translated to English
RevUI.RightPanel = nil -- Comment translated to English
RevUI.CurrentPage = "Home"
RevUI.CurrentModule = nil
RevUI.ActivePageFrame = nil -- Comment translated to English
RevUI.PendingRightScrollRestore = nil -- Comment translated to English

-- =========================================================
-- Toggle UI
-- =========================================================
function RevUI:Toggle()
    if not RevUI.MainFrame then
        RevUI:CreateMainFrame()
    end
    if RevUI.MainFrame:IsShown() then
        RevUI.MainFrame:Hide()
    else
        RevUI.MainFrame:Show()
        RevUI:RefreshContent()
    end
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:CreateMainFrame()
-- Comment translated to English
    local f = CreateFrame("Frame", "InfinityMythicPlusMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(1200, 720)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(false)

-- Comment translated to English
    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(unpack(THEME.Background))
    f:SetBackdropBorderColor(unpack(THEME.Border))

-- Comment translated to English
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

-- Comment translated to English
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -15)
    title:SetText("|cFFBB66FFInfinity|rMythicPlus " .. L["Settings"])
    f.Title = title

-- Comment translated to English
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("BOTTOMLEFT", 20, 15)
    status:SetText(string.format(L["Version: %s | Engine: GRID %s"], InfinityTools.VERSION or "Unknown",
        InfinityTools.GridEngineVersion or "Unknown"))
    f.Status = status

-- Comment translated to English
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    f.CloseButton = closeBtn -- Comment translated to English
    do
        local nTex = closeBtn:GetNormalTexture()
        if nTex then nTex:SetVertexColor(1, 0.15, 0.15, 1) end
        local hTex = closeBtn:GetHighlightTexture()
        if hTex then hTex:SetVertexColor(1, 0.4, 0.4, 1) end
        local pTex = closeBtn:GetPushedTexture()
        if pTex then pTex:SetVertexColor(0.7, 0.05, 0.05, 1) end
    end

-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
    _G.InfinityToolsMainFrame = f -- Backward-compatible alias.
    tinsert(UISpecialFrames, "InfinityMythicPlusMainFrame")
    RevUI.MainFrame = f

-- Comment translated to English
    RevUI:CreateSidebar(f)
    RevUI:CreateRightPanel(f)

-- Comment translated to English
    local footer = CreateFrame("Frame", nil, f)
    footer:SetSize(850, 40)
    footer:SetPoint("BOTTOMRIGHT", -15, 10)

    local reloadBtn = RevUI:CreateSmallButton(footer, L["Reload UI"], function()
        C_UI.Reload()
    end)
    reloadBtn:SetPoint("RIGHT", 0, -8)
    reloadBtn:SetSize(180, 26)

-- Comment translated to English
    local editBtn = RevUI:CreateSmallButton(footer, InfinityTools.GlobalEditMode and L["Disable Edit Mode"] or L["Enable Edit Mode"], function()
        InfinityTools:ToggleGlobalEditMode()
-- Comment translated to English
        if InfinityTools.GlobalEditMode and f:IsShown() then
            f:Hide()
        end
    end)
    editBtn:SetPoint("RIGHT", reloadBtn, "LEFT", -10, 0)
    editBtn:SetSize(180, 26)
    RevUI.EditModeToggleButton = editBtn

    local changelogBtn = RevUI:CreateSmallButton(footer, L["Changelog"], function()
        if InfinityTools.ShowChangelog then
            InfinityTools:ShowChangelog({ markShown = true })
        end
    end)
    changelogBtn:SetPoint("RIGHT", editBtn, "LEFT", -10, 0)
    changelogBtn:SetSize(150, 26)
    RevUI.ChangelogButton = changelogBtn

    f:Hide()

    -- Restore saved theme color from RRT (deferred so RRTDB is ready)
    C_Timer.After(0.2, function()
        local c = _G.RRT and _G.RRT.Settings and _G.RRT.Settings.TabSelectionColor
        if c then RevUI:ApplyThemeColor(c[1], c[2], c[3]) end
    end)
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:CreateSidebar(parent)
    local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    sidebar:SetSize(280, 630)
    sidebar:SetPoint("TOPLEFT", 15, -50)
-- Comment translated to English
    sidebar:SetBackdrop(nil)
    -- sidebar:SetBackdropColor(unpack(THEME.Sidebar))

-- Comment translated to English
    local vLine = sidebar:CreateTexture(nil, "ARTWORK")
    vLine:SetSize(1, 620)
    vLine:SetPoint("TOPRIGHT", 0, 0)
    vLine:SetColorTexture(1, 1, 1, 0.05)

-- Comment translated to English
    local scrollFrame = CreateFrame("ScrollFrame", "InfinitySidebarScroll", sidebar, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

-- Comment translated to English
    if _G["InfinitySidebarScrollTop"] then _G["InfinitySidebarScrollTop"]:Hide() end
    if _G["InfinitySidebarScrollBottom"] then _G["InfinitySidebarScrollBottom"]:Hide() end

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(250, 1)
    scrollFrame:SetScrollChild(scrollChild)

    RevUI.SidebarFrame = scrollChild
    RevUI:BuildNavigationTree(scrollChild)
end

-- =========================================================
-- [v4.6] Sidebar Redesign (Modern Tree View)
-- =========================================================
-- Comment translated to English
RevUI.SidebarState = { Expanded = { true, true, true, true, true } }
RevUI.SidebarPool = { Headers = {}, Items = {} }

-- =========================================================
-- Theme color sync with RRT UI Appearance
-- =========================================================
function RevUI:ApplyThemeColor(r, g, b)
    THEME.Primary = {r, g, b}
    for _, hdr in ipairs(RevUI.SidebarPool.Headers) do
        if hdr.bar   then hdr.bar:SetColorTexture(r, g, b, 0.9)  end
        if hdr.label then hdr.label:SetTextColor(r, g, b)         end
    end
    for _, item in ipairs(RevUI.SidebarPool.Items) do
        if item.accent then item.accent:SetColorTexture(r, g, b)      end
        if item.bg     then item.bg:SetColorTexture(r, g, b, 0.1)     end
    end
end

-- Register cross-addon global callback (fires when RRT tab color changes)
_G.RRT = _G.RRT or {}
_G.RRT.GlobalThemeCallbacks = _G.RRT.GlobalThemeCallbacks or {}
table.insert(_G.RRT.GlobalThemeCallbacks, function(r, g, b)
    RevUI:ApplyThemeColor(r, g, b)
end)

-- Comment translated to English
function RevUI:GetSidebarObj(type, parent)
    local pool = RevUI.SidebarPool[type]
    for _, obj in ipairs(pool) do
        if not obj:IsShown() then
            obj:SetParent(parent)
            obj:Show()
            return obj
        end
    end
-- Comment translated to English
    local obj
    if type == "Headers" then
        obj = RevUI:CreateCategoryHeaderBase(parent)
    elseif type == "Items" then
        obj = RevUI:CreateSidebarItemBase(parent)
    end
    table.insert(pool, obj)
    return obj
end

-- Comment translated to English
function RevUI:CreateCategoryHeaderBase(parent)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(240, 32) -- Comment translated to English

-- Comment translated to English
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(1, 1, 1, 1)
-- Comment translated to English
    btn.bg:SetGradient("HORIZONTAL", CreateColor(0.18, 0.18, 0.22, 0.7), CreateColor(0.05, 0.05, 0.08, 0))

-- Comment translated to English
    btn.bar = btn:CreateTexture(nil, "ARTWORK")
    btn.bar:SetSize(3, 30)
    btn.bar:SetPoint("LEFT", 0, 0)
    btn.bar:SetColorTexture(0.733, 0.4, 1.0, 0.9)

-- Comment translated to English
    btn.arrow = btn:CreateFontString(nil, "OVERLAY")
    btn.arrow:SetFontObject("GameFontHighlight") -- Comment translated to English
    btn.arrow:SetPoint("LEFT", 8, 0)
    btn.arrow:SetTextColor(0.8, 0.8, 0.8)

-- Comment translated to English
    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFontObject("GameFontNormal")
    btn.label:SetPoint("LEFT", 22, 0)
    btn.label:SetTextColor(0.733, 0.4, 1.0) -- Comment translated to English

-- Comment translated to English
    btn:SetScript("OnEnter", function(self)
-- Comment translated to English
        self.bg:SetGradient("HORIZONTAL", CreateColor(0.25, 0.25, 0.3, 0.8), CreateColor(0.1, 0.1, 0.15, 0))
        self.arrow:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
-- Comment translated to English
        self.bg:SetGradient("HORIZONTAL", CreateColor(0.18, 0.18, 0.22, 0.7), CreateColor(0.05, 0.05, 0.08, 0))
        self.arrow:SetTextColor(0.8, 0.8, 0.8)
    end)

    return btn
end

-- Comment translated to English
function RevUI:CreateSidebarItemBase(parent)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(240, 30) -- Comment translated to English

-- Comment translated to English
    btn.accent = btn:CreateTexture(nil, "ARTWORK")
    btn.accent:SetSize(4, 18)
    btn.accent:SetPoint("LEFT", 12, 0)
    btn.accent:SetColorTexture(0.733, 0.4, 1.0) -- Comment translated to English
    btn.accent:SetAlpha(0)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.733, 0.4, 1.0, 0.1) -- Comment translated to English
    btn.bg:SetAlpha(0)

    btn.badge = btn:CreateTexture(nil, "OVERLAY")
    btn.badge:SetSize(64, 33)
    btn.badge:Hide()

-- Comment translated to English
    btn.label = btn:CreateFontString(nil, "OVERLAY")
    btn.label:SetFontObject("GameFontHighlight")
    btn.label:SetPoint("LEFT", 28, 0) -- Comment translated to English
    btn.label:SetJustifyH("LEFT")
    btn.label:SetTextColor(0.8, 0.8, 0.85) -- Comment translated to English
    btn.label:SetWidth(200)
    btn.label:SetWordWrap(false)

    btn:SetBackdrop(BACKDROP_SIMPLE)
    btn:SetBackdropColor(0, 0, 0, 0)

    btn:SetScript("OnEnter", function(self)
        if self.isLoaded == false then return end -- Comment translated to English
        if not self.isActive then
            self:SetBackdropColor(1, 1, 1, 0.04)
            self.label:SetTextColor(1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.isLoaded == false then return end
        if not self.isActive then
            self:SetBackdropColor(0, 0, 0, 0)
            self.label:SetTextColor(0.8, 0.8, 0.85, 1)
        end
    end)

    return btn
end

local function UpdateSidebarItemBadge(btn, meta)
    if not btn or not btn.badge or not btn.label then return end

    btn.badge:Hide()
    btn.label:ClearAllPoints()
    btn.label:SetPoint("LEFT", 28, 0)
    btn.label:SetWidth(200)

    if meta and meta.new then
        local faction = _G.UnitFactionGroup and _G.UnitFactionGroup("player")
        local atlas = faction == "Alliance" and "NewCharacter-Alliance" or "NewCharacter-Horde"
        btn.badge:SetAtlas(atlas, false)
        btn.badge:ClearAllPoints()
        btn.badge:SetPoint("RIGHT", btn.label, "LEFT", 25, 0)
        btn.label:SetWidth(160)
        btn.badge:Show()
    end
end

-- Comment translated to English
function RevUI:BuildNavigationTree(parent)
-- Comment translated to English
    if RevUI.SidebarPool.Headers then for _, v in ipairs(RevUI.SidebarPool.Headers) do v:Hide() end end
    if RevUI.SidebarPool.Items then for _, v in ipairs(RevUI.SidebarPool.Items) do v:Hide() end end

    local yOffset = -5

-- Comment translated to English
    local staticItems = {
        { name = L["Home"], page = "Home" },
        { name = L["Modules"], page = "LoadSettings" },
        { name = L["Diagnostics"], page = "Diagnostic" },
        { name = L["Profiles"], page = "ProfileManager" }
    }

    local function CreateItem(name, page, key, meta)
        local btn = RevUI:GetSidebarObj("Items", parent)
        btn.page = page
        btn.moduleKey = key
        UpdateSidebarItemBadge(btn, meta)

-- Comment translated to English
        local isModule = (key ~= nil)
        local isLoaded = not isModule
        if isModule and InfinityTools.DB and InfinityTools.DB.LoadByKey then
            isLoaded = InfinityTools.DB.LoadByKey[key]
        end
        btn.isLoaded = isLoaded

        if isModule and not isLoaded then
            btn.label:SetText("|cff888888" .. name .. " (" .. L["disabled"] .. ")|r")
        else
            btn.label:SetText(name)
        end

        btn:SetPoint("TOPLEFT", 5, yOffset)

        btn:SetScript("OnClick", function()
-- Comment translated to English
            if isModule and not isLoaded then return end

-- Comment translated to English
            C_Timer.After(0.1, function()
                RevUI.CurrentPage = page
                RevUI.CurrentModule = key
                RevUI:RefreshContent()
            end)
        end)

        yOffset = yOffset - 31 -- Comment translated to English
    end

    for _, info in ipairs(staticItems) do
        CreateItem(info.name, info.page, nil, nil)
    end

    yOffset = yOffset - 10

-- Comment translated to English
    if not RevUI.NavDivider then
        RevUI.NavDivider = parent:CreateTexture(nil, "ARTWORK")
        RevUI.NavDivider:SetSize(230, 1)
        RevUI.NavDivider:SetColorTexture(1, 1, 1, 0.08)
    end
    RevUI.NavDivider:SetPoint("TOP", 0, yOffset)
    yOffset = yOffset - 15

    -- 2b. External panel launchers (Boss / Mythic+)
    local function CreateExternalItem(name, onClickFn)
        local btn = RevUI:GetSidebarObj("Items", parent)
        btn.page      = nil
        btn.moduleKey = nil
        btn.isLoaded  = true
        btn.label:SetText(name)
        btn:SetPoint("TOPLEFT", 5, yOffset)
        btn:SetScript("OnClick", function()
            C_Timer.After(0.1, onClickFn)
        end)
        yOffset = yOffset - 31
    end

    CreateExternalItem("Boss", function()
        if InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel then
            InfinityBoss.UI.Panel:Toggle()
        end
    end)

    CreateExternalItem("Mythic+", function()
        if InfinityTools and InfinityTools.ToggleMythicFrame then
            InfinityTools.ToggleMythicFrame()
        end
    end)

    yOffset = yOffset - 10

-- Comment translated to English
    for cateId = 1, 5 do
        local cateName = InfinityTools.Cate[cateId]
        if cateName then
            local header = RevUI:GetSidebarObj("Headers", parent)
            local isExpanded = RevUI.SidebarState.Expanded[cateId]

            header.arrow:SetText(isExpanded and "v" or ">")
            header.label:SetText(cateName)
            header:SetPoint("TOPLEFT", 5, yOffset)

            header:SetScript("OnClick", function()
-- Comment translated to English
                C_Timer.After(0.1, function()
                    RevUI.SidebarState.Expanded[cateId] = not RevUI.SidebarState.Expanded[cateId]
                    RevUI:BuildNavigationTree(parent) -- Comment translated to English
                end)
            end)

            yOffset = yOffset - 34 -- Comment translated to English

            if isExpanded then
                for _, meta in ipairs(InfinityTools.ModuleList) do
                    if meta.Category == cateId and not meta.HideCfg then
                        CreateItem(meta.Name, "ModuleSettings", meta.Key, meta)
                    end
                end
                yOffset = yOffset - 8
            end
        end
    end

    parent:SetHeight(math.abs(yOffset) + 50)
    RevUI:UpdateNavButtonStates()
end

-- Comment translated to English
function RevUI:UpdateNavButtonStates()
    if not RevUI.SidebarFrame or not RevUI.SidebarPool.Items then return end

    for _, btn in ipairs(RevUI.SidebarPool.Items) do
        if btn:IsShown() and btn.page then
            local isActive = (btn.page == RevUI.CurrentPage and btn.moduleKey == RevUI.CurrentModule)
            btn.isActive = isActive
            if isActive then
                btn.accent:SetAlpha(1)
                btn.bg:SetAlpha(1)
                btn.label:SetTextColor(1, 1, 1, 1)
            else
                btn.accent:SetAlpha(0)
                btn.bg:SetAlpha(0)
                if btn.isLoaded == false then
                    btn.label:SetTextColor(0.5, 0.5, 0.5, 1) -- Comment translated to English
                else
                    btn.label:SetTextColor(0.8, 0.8, 0.85, 1) -- Comment translated to English
                end
                btn:SetBackdropColor(0, 0, 0, 0)
            end
        end
    end
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:CreateRightPanel(parent)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(850, 630)
    panel:SetPoint("TOPLEFT", 335, -50)
-- Comment translated to English
    panel:SetBackdrop(nil)
    -- panel:SetBackdropColor(0.05, 0.05, 0.07, 0.5)

-- Comment translated to English
    local sf = CreateFrame("ScrollFrame", "InfinityCommonScroll", panel, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 0, -5)
    sf:SetPoint("BOTTOMRIGHT", -25, 5)

-- Comment translated to English
    if _G["InfinityCommonScrollTop"] then _G["InfinityCommonScrollTop"]:Hide() end
    if _G["InfinityCommonScrollBottom"] then _G["InfinityCommonScrollBottom"]:Hide() end
    if _G["InfinityCommonScrollScrollBarScrollUpButton"] then _G["InfinityCommonScrollScrollBarScrollUpButton"]:Hide() end
    if _G["InfinityCommonScrollScrollBarScrollDownButton"] then _G["InfinityCommonScrollScrollBarScrollDownButton"]:Hide() end

    local sc = CreateFrame("Frame", nil, sf)
    sc:SetSize(750, 1)
    sf:SetScrollChild(sc)

    RevUI.RightPanel = panel
    RevUI.RightScrollFrame = sf
    RevUI.RightScrollChild = sc
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:RefreshContent()
    local restoreRightScroll = RevUI.PendingRightScrollRestore
    RevUI.PendingRightScrollRestore = nil

-- Comment translated to English
    RevUI.SwitchingModule = true

-- Comment translated to English
    if RevUI.ActivePageFrame then
        RevUI.ActivePageFrame:Hide()
        RevUI.ActivePageFrame:SetParent(nil)
        RevUI.ActivePageFrame = nil
    end

-- Comment translated to English
    if RevUI.ModuleScrollFrame then RevUI.ModuleScrollFrame:Hide() end
    if RevUI.NoLayoutLabel then RevUI.NoLayoutLabel:Hide() end

-- Comment translated to English
    RevUI.SwitchingModule = nil
-- Comment translated to English
    if not RevUI.RightPanel then return end

-- Comment translated to English
    if RevUI.CurrentPage == "ModuleSettings" then
-- Comment translated to English
        if RevUI.RightScrollFrame then RevUI.RightScrollFrame:Hide() end
        RevUI:ShowModuleSettingsPage()
    else
-- Comment translated to English
        if RevUI.RightScrollFrame then
            RevUI.RightScrollFrame:Show()
            if restoreRightScroll == nil then
                RevUI.RightScrollFrame:SetVerticalScroll(0)
            end
        end
-- Comment translated to English
        if RevUI.CurrentPage == "Home" then
            RevUI.RightPanel:Show()
            RevUI:ShowHomePage()
        elseif RevUI.CurrentPage == "LoadSettings" then
            RevUI.RightPanel:Show()
            RevUI:ShowLoadSettingsPage()
        elseif RevUI.CurrentPage == "Diagnostic" then
            RevUI.RightPanel:Show()
            RevUI:ShowDiagnosticPage()
        elseif RevUI.CurrentPage == "ProfileManager" then
            RevUI.RightPanel:Show()
            RevUI:ShowProfileManagerPage()
        end

-- Comment translated to English
        if restoreRightScroll ~= nil and RevUI.RightScrollFrame and RevUI.RightScrollFrame:IsShown() then
            RevUI.RightScrollFrame:SetVerticalScroll(restoreRightScroll)
        end
    end

    RevUI:UpdateNavButtonStates()
end

-- Comment translated to English
function RevUI:RefreshContentKeepRightScroll()
    if RevUI.CurrentPage ~= "ModuleSettings" and RevUI.RightScrollFrame and RevUI.RightScrollFrame:IsShown() then
        RevUI.PendingRightScrollRestore = RevUI.RightScrollFrame:GetVerticalScroll() or 0
    end
    RevUI:RefreshContent()
end

-- =========================================================
-- Comment translated to English
-- =========================================================
RevUI.PageCache = {}

function RevUI:GetCachedPage(key, parent)
-- Comment translated to English
    if not RevUI.PageCache[key] then
        local page = CreateFrame("Frame", nil, parent)
-- Comment translated to English
        page:SetWidth(parent:GetWidth())
        page:SetPoint("TOPLEFT", 0, 0)
        RevUI.PageCache[key] = page
        page:Show()
        return page, true -- isNew = true
    end
    local page = RevUI.PageCache[key]
    page:SetParent(parent)
    page:SetWidth(parent:GetWidth())
    page:ClearAllPoints()
    page:SetPoint("TOPLEFT", 0, 0)
    page:Show()
    return page, false -- isNew = false
end

-- =========================================================
-- Comment translated to English
-- =========================================================

-- Comment translated to English
StaticPopupDialogs["INFINITY_CONFIRM_RESET"] = {
    text = L["Reset all InfinityTools settings and reload?\n|cffff4444This cannot be undone!|r"],
    button1 = L["Confirm Reset"],
    button2 = L["Cancel"],
    OnAccept = function()
        _G.InfinityToolsDB = nil
        C_UI.Reload()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function RevUI:ShowHomePage()
    local page, isNew = RevUI:GetCachedPage("Home", RevUI.RightScrollChild)
    RevUI.ActivePageFrame = page

    if not isNew then
        RevUI.RightScrollChild:SetHeight(760)
        return
    end

    local FONT = InfinityTools.MAIN_FONT
    local PURPLE = "|cFFBB66FF"
    local CYAN = "|cff00DDFF"
    local GOLD = "|cffFFD700"
    local GREY = "|cff888888"
-- Comment translated to English
    local W = math.min((page:GetWidth() or 750) - 30, 720)
    local PAGE_H = 760
    local COL_GAP = 14
    local COL_W = math.floor((W - COL_GAP) / 2)
    local INNER_W = COL_W - 42

    local function MakePanel(parent, w, h, point, rel, relPoint, x, y, bg, border)
        local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        frame:SetSize(w, h)
        frame:SetPoint(point, rel, relPoint, x, y)
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        frame:SetBackdropColor(unpack(bg or { 0.1, 0.1, 0.12, 0.85 }))
        frame:SetBackdropBorderColor(unpack(border or { 0.35, 0.35, 0.4, 0.85 }))
        return frame
    end

    local function MakeDivider(parent, anchor, yOff)
        local line = parent:CreateTexture(nil, "ARTWORK")
        line:SetSize(W, 1)
        line:SetPoint("TOP", anchor, "BOTTOM", 0, yOff)
        line:SetColorTexture(0.23, 0.23, 0.3, 0.8)
        return line
    end

-- Comment translated to English
    local hero = MakePanel(page, W, 132, "TOP", page, "TOP", 0, -18, { 0.08, 0.06, 0.12, 0.92 }, { 0.45, 0.2, 0.65, 0.9 })

    local heroGlow = hero:CreateTexture(nil, "BACKGROUND")
    heroGlow:SetPoint("TOPLEFT", 6, -6)
    heroGlow:SetPoint("BOTTOMRIGHT", -6, 6)
    heroGlow:SetColorTexture(0.733, 0.4, 1.0, 0.06)

    local logoTitle = hero:CreateFontString(nil, "OVERLAY")
    logoTitle:SetFont(FONT, 30, "OUTLINE")
    logoTitle:SetPoint("TOPLEFT", 20, -18)
    logoTitle:SetText(PURPLE .. "InfinityMythicPlus|r")

    local subTitle = hero:CreateFontString(nil, "OVERLAY")
    subTitle:SetFont(FONT, 13, "")
    subTitle:SetPoint("TOPLEFT", logoTitle, "BOTTOMLEFT", 0, -8)
    subTitle:SetText("|cffcfcfe0" .. L["Zero deps - Event-driven - State bus - Grid layout"] .. "|r")
    subTitle:SetTextColor(0.82, 0.82, 0.88, 1)

    local versionText = hero:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(FONT, 12, "")
    versionText:SetPoint("TOPRIGHT", -20, -22)
    versionText:SetText(GREY .. L["Version: "] .. (InfinityTools.VERSION or "Unknown") .. "|r")
    versionText:SetTextColor(0.65, 0.65, 0.7, 1)

    local openInfinityBossBtn = RevUI:CreateSmallButton(hero, L["Open InfinityBoss"], function()
        local panel = _G.InfinityBoss and _G.InfinityBoss.UI and _G.InfinityBoss.UI.Panel
        if not panel then
            return
        end
        if panel.SetTab then
            panel:SetTab("boss")
        end
        if RevUI.MainFrame then
            RevUI.MainFrame:Hide()
        end
        if panel.Show then
            panel:Show()
        elseif panel.Toggle then
            panel:Toggle()
        end
    end)
    openInfinityBossBtn:SetSize(120, 24)
    openInfinityBossBtn:SetPoint("TOPRIGHT", versionText, "BOTTOMRIGHT", 0, -10)
    if openInfinityBossBtn:GetFontString() then
        openInfinityBossBtn:GetFontString():SetFont(FONT, 11, "OUTLINE")
    end

    local heroDesc = hero:CreateFontString(nil, "OVERLAY")
    heroDesc:SetFont(FONT, 12, "")
    heroDesc:SetPoint("TOPLEFT", subTitle, "BOTTOMLEFT", 0, -12)
    heroDesc:SetWidth(W - 170)
    heroDesc:SetJustifyH("LEFT")
    heroDesc:SetText(L["Use Modules to enable/disable features. Configure each module via its Grid panel."])
    heroDesc:SetTextColor(0.7, 0.7, 0.76, 1)

    local div1 = MakeDivider(page, hero, -18)

-- Comment translated to English
    local cardRow = CreateFrame("Frame", nil, page)
    cardRow:SetSize(W, 360)
    cardRow:SetPoint("TOP", div1, "BOTTOM", 0, -18)

-- Comment translated to English
    local infoPanel = MakePanel(cardRow, COL_W, 360, "TOPLEFT", cardRow, "TOPLEFT", 0, 0, { 0.09, 0.09, 0.12, 0.92 },
        { 0.28, 0.3, 0.38, 0.9 })

    local infoTitle = infoPanel:CreateFontString(nil, "OVERLAY")
    infoTitle:SetFont(FONT, 16, "OUTLINE")
    infoTitle:SetPoint("TOPLEFT", 18, -16)
    infoTitle:SetText("|cffe6e6f0" .. L["Info & Feedback"] .. "|r")

    local authorLabel = infoPanel:CreateFontString(nil, "OVERLAY")
    authorLabel:SetFont(FONT, 12, "OUTLINE")
    authorLabel:SetPoint("TOPLEFT", infoTitle, "BOTTOMLEFT", 0, -18)
    authorLabel:SetText(GREY .. L["Author"] .. "|r")

    local authorValue = infoPanel:CreateFontString(nil, "OVERLAY")
    authorValue:SetFont(FONT, 18, "OUTLINE")
    authorValue:SetPoint("TOPLEFT", authorLabel, "BOTTOMLEFT", 0, -6)
    authorValue:SetText(CYAN .. "Abraa|r")

    local webLabel = infoPanel:CreateFontString(nil, "OVERLAY")
    webLabel:SetFont(FONT, 12, "OUTLINE")
    webLabel:SetPoint("TOPLEFT", authorValue, "BOTTOMLEFT", 0, -20)
    webLabel:SetText(GREY .. L["Twitch"] .. "|r")

    local siteBox = RevUI:CreateEditBox(infoPanel, "https://www.twitch.tv/abraa_", INNER_W, 28, nil, {})
    siteBox:SetPoint("TOPLEFT", webLabel, "BOTTOMLEFT", 0, -8)
    do
        local fixedText = "https://www.twitch.tv/abraa_"
        siteBox:SetAutoFocus(false)
        siteBox:SetText(fixedText)
        siteBox:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
        siteBox:HookScript("OnMouseUp", function(self)
            self:SetFocus(); self:HighlightText()
        end)
        siteBox:HookScript("OnTextChanged", function(self, userInput)
            if userInput and self:GetText() ~= fixedText then
                self:SetText(fixedText)
                self:HighlightText()
            end
        end)
    end

    local siteHint = infoPanel:CreateFontString(nil, "OVERLAY")
    siteHint:SetFont(FONT, 10, "")
    siteHint:SetPoint("TOPLEFT", siteBox, "BOTTOMLEFT", 0, -4)
    siteHint:SetText(GREY .. L["Click the box to select all and copy"] .. "|r")
    siteHint:SetTextColor(0.55, 0.55, 0.6, 1)

    local feedbackTitle = infoPanel:CreateFontString(nil, "OVERLAY")
    feedbackTitle:SetFont(FONT, 13, "OUTLINE")
    feedbackTitle:SetPoint("TOPLEFT", siteHint, "BOTTOMLEFT", 0, -18)
    feedbackTitle:SetText("|cffffd88a" .. L["Feedback"] .. "|r")

    local curseLabel = infoPanel:CreateFontString(nil, "OVERLAY")
    curseLabel:SetFont(FONT, 12, "")
    curseLabel:SetPoint("TOPLEFT", feedbackTitle, "BOTTOMLEFT", 0, -10)
    curseLabel:SetText("AbraaWoW: " .. CYAN .. "Curseforge|r")
    curseLabel:SetTextColor(0.82, 0.82, 0.88, 1)

    local curseBox = RevUI:CreateEditBox(infoPanel, "https://www.curseforge.com/wow/addons/infinitytools", INNER_W, 28, nil, {})
    curseBox:SetPoint("TOPLEFT", curseLabel, "BOTTOMLEFT", 0, -8)
    do
        local fixedText = "https://www.curseforge.com/wow/addons/infinitytools"
        curseBox:SetAutoFocus(false)
        curseBox:SetText(fixedText)
        curseBox:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
        curseBox:HookScript("OnMouseUp", function(self)
            self:SetFocus(); self:HighlightText()
        end)
        curseBox:HookScript("OnTextChanged", function(self, userInput)
            if userInput and self:GetText() ~= fixedText then
                self:SetText(fixedText)
                self:HighlightText()
            end
        end)
    end

    local curseHint = infoPanel:CreateFontString(nil, "OVERLAY")
    curseHint:SetFont(FONT, 10, "")
    curseHint:SetPoint("TOPLEFT", curseBox, "BOTTOMLEFT", 0, -4)
    curseHint:SetText(GREY .. L["Click to select all, Ctrl+C to copy"] .. "|r")
    curseHint:SetTextColor(0.55, 0.55, 0.6, 1)

-- Comment translated to English
    local actionPanel = MakePanel(cardRow, COL_W, 360, "TOPRIGHT", cardRow, "TOPRIGHT", 0, 0, { 0.09, 0.08, 0.08, 0.92 },
        { 0.35, 0.28, 0.28, 0.9 })

    local actionTitle = actionPanel:CreateFontString(nil, "OVERLAY")
    actionTitle:SetFont(FONT, 16, "OUTLINE")
    actionTitle:SetPoint("TOPLEFT", 18, -16)
    actionTitle:SetText("|cffe6e6f0" .. L["Quick Actions"] .. "|r")

    local actionDesc = actionPanel:CreateFontString(nil, "OVERLAY")
    actionDesc:SetFont(FONT, 12, "")
    actionDesc:SetPoint("TOPLEFT", actionTitle, "BOTTOMLEFT", 0, -10)
    actionDesc:SetWidth(INNER_W)
    actionDesc:SetJustifyH("LEFT")
    actionDesc:SetText(L["These actions affect addon settings directly. Reset will wipe InfinityTools data and reload."])
    actionDesc:SetTextColor(0.72, 0.72, 0.78, 1)

    local btnReset = CreateFrame("Button", nil, actionPanel, "BackdropTemplate")
-- Comment translated to English
    btnReset:SetSize(120, 24)
    btnReset:SetPoint("BOTTOMRIGHT", actionPanel, "BOTTOMRIGHT", -16, 16)
    btnReset:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    btnReset:SetBackdropColor(0.35, 0.06, 0.06, 0.9)
    btnReset:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.9)

    local btnResetLabel = btnReset:CreateFontString(nil, "OVERLAY")
    btnResetLabel:SetFont(FONT, 11, "OUTLINE")
    btnResetLabel:SetPoint("CENTER")
    btnResetLabel:SetText("|cffFF6666" .. L["Reset Settings"] .. "|r")

    btnReset:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.5, 0.08, 0.08, 0.95)
        self:SetBackdropBorderColor(1, 0.3, 0.3, 1)
    end)
    btnReset:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.35, 0.06, 0.06, 0.9)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.9)
    end)
    btnReset:SetScript("OnClick", function()
        StaticPopup_Show("INFINITY_CONFIRM_RESET")
    end)

    local minimapToggle = RevUI:CreateCheckbox(
        actionPanel,
        L["Hide Minimap Button"],
        InfinityTools.IsMinimapButtonHidden and InfinityTools:IsMinimapButtonHidden() or false,
        function(checked)
            if InfinityTools.SetMinimapButtonHidden then
                InfinityTools:SetMinimapButtonHidden(checked)
            end
        end
    )
    minimapToggle:SetSize(170, 24)
    minimapToggle:SetPoint("BOTTOMRIGHT", btnReset, "TOPRIGHT", 0, 8)
    minimapToggle.label:ClearAllPoints()
    minimapToggle.label:SetPoint("LEFT", minimapToggle.checkbox, "RIGHT", 4, 0)
    minimapToggle.label:SetTextColor(0.82, 0.82, 0.88, 1)

    local resetHint = actionPanel:CreateFontString(nil, "OVERLAY")
    resetHint:SetFont(FONT, 10, "")
    resetHint:SetPoint("BOTTOMLEFT", actionPanel, "BOTTOMLEFT", 18, 20)
    resetHint:SetWidth(INNER_W - 110)
    resetHint:SetJustifyH("LEFT")
    resetHint:SetText(GREY .. L["RESET_HINT"] .. "|r")
    resetHint:SetTextColor(0.55, 0.55, 0.6, 1)

    local tipHeader = actionPanel:CreateFontString(nil, "OVERLAY")
    tipHeader:SetFont(FONT, 13, "OUTLINE")
    tipHeader:SetPoint("TOPLEFT", actionDesc, "BOTTOMLEFT", 0, -20)
    tipHeader:SetText("|cffffd88a" .. L["Tips"] .. "|r")

    local tips = {
        L["Use the Modules page to enable/disable modules. Changes take effect after /reload."],
        L["Inside a module settings page, use the Grid panel to adjust styles, position, and toggles."],
        L["Global edit mode: /ex edmode (drag HUD elements to reposition)."],
    }
    local lastTip = tipHeader
    for _, tip in ipairs(tips) do
        local fs = actionPanel:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT, 12, "")
        fs:SetPoint("TOPLEFT", lastTip, "BOTTOMLEFT", 0, -8)
        fs:SetWidth(INNER_W)
        fs:SetJustifyH("LEFT")
        fs:SetText("|cff9fb0c0•|r " .. tip)
        fs:SetTextColor(0.8, 0.82, 0.88, 1)
        lastTip = fs
    end

    local div2 = MakeDivider(page, cardRow, -18)

    local footerPanel = MakePanel(page, W, 84, "TOP", div2, "BOTTOM", 0, -18, { 0.06, 0.06, 0.08, 0.92 },
        { 0.22, 0.22, 0.28, 0.85 })
    local footerText = footerPanel:CreateFontString(nil, "OVERLAY")
    footerText:SetFont(FONT, 16, "")
    footerText:SetPoint("CENTER", footerPanel, "CENTER", 0, 0)
    footerText:SetWidth(W - 36)
    footerText:SetJustifyH("CENTER")
    footerText:SetWordWrap(true)
    footerText:SetText(GREY .. L["Author: Abraa"] .. "|r")
    footerText:SetTextColor(0.55, 0.55, 0.62, 1)

    page:SetHeight(PAGE_H)
    RevUI.RightScrollChild:SetHeight(PAGE_H)
end

-- =========================================================
-- Comment translated to English
-- =========================================================
RevUI.AsyncHandler = LibStub("LibAsync"):GetHandler({
    type = "everyFrame",
    maxTime = 20, -- Comment translated to English
    errorHandler = geterrorhandler()
})

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:ShowLoadSettingsPage()
-- Comment translated to English
    local page, isNew = RevUI:GetCachedPage("LoadSettings", RevUI.RightScrollChild)
    RevUI.ActivePageFrame = page

    if isNew then
        local pageTitle = page:CreateFontString(nil, "OVERLAY")
        pageTitle:SetFontObject("GameFontNormalLarge")
        pageTitle:SetPoint("TOPLEFT", 20, -15)
        pageTitle:SetText(L["Module Manager"])

        local hint = page:CreateFontString(nil, "OVERLAY")
        hint:SetFontObject("GameFontHighlight")
        hint:SetPoint("TOPLEFT", 20, -45)
        hint:SetText("|cffff8800" .. L["Click a card to enable/disable. Click Settings to configure. Changes require /reload."] .. "|r")

        local btnEnableAll = RevUI:CreateSmallButton(page, L["Enable All"], function()
            for _, meta in ipairs(InfinityTools.ModuleList) do
                InfinityTools.DB.LoadByKey[meta.Key] = true
            end
            if page.cardsContainer then
                RevUI:RefreshModuleCardStates(page.cardsContainer)
            else
                RevUI:RefreshContentKeepRightScroll()
            end
        end)
        btnEnableAll:SetPoint("TOPRIGHT", -150, -12)

        local btnDisableAll = RevUI:CreateSmallButton(page, L["Disable All"], function()
            for _, meta in ipairs(InfinityTools.ModuleList) do
                InfinityTools.DB.LoadByKey[meta.Key] = false
            end
            if page.cardsContainer then
                RevUI:RefreshModuleCardStates(page.cardsContainer)
            else
                RevUI:RefreshContentKeepRightScroll()
            end
        end)
        btnDisableAll:SetPoint("TOPRIGHT", -20, -12)

-- Comment translated to English
-- Comment translated to English
        page.cardsContainer = CreateFrame("Frame", nil, page)
        page.cardsContainer:SetPoint("TOPLEFT", 15, -75)
        page.cardsContainer:SetPoint("BOTTOMRIGHT", -15, 0)
        page.cardsContainer:SetSize(720, 1) -- Comment translated to English
    end

-- Comment translated to English
    if page.cardsContainer then
        RevUI.AsyncHandler:CancelAsync("InfinityTools_GenCards")
        for _, child in ipairs({ page.cardsContainer:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end
-- Comment translated to English
        RevUI:GenerateModuleCards(page.cardsContainer, function(contentHeight)
            page:SetHeight(contentHeight + 100)
            RevUI.RightScrollChild:SetHeight(page:GetHeight())
        end)
    end
end

-- Comment translated to English
function RevUI:ApplyModuleCardState(card, isEnabled)
    if not card then return end

    card:SetBackdropBorderColor(isEnabled and THEME.Success[1] or 0.3,
        isEnabled and THEME.Success[2] or 0.3,
        isEnabled and THEME.Success[3] or 0.35, 0.8)

    if card.Thumbnail then
        card.Thumbnail:SetDesaturated(not isEnabled)
        card.Thumbnail:SetAlpha(isEnabled and 1 or 0.5)
    end

    if card.EnableBtn then
        card.EnableBtn:SetBackdropColor(isEnabled and THEME.Success[1] or THEME.Danger[1],
            isEnabled and THEME.Success[2] or THEME.Danger[2],
            isEnabled and THEME.Success[3] or THEME.Danger[3])
    end

    if card.EnableBtnText then
        card.EnableBtnText:SetText(isEnabled and L["Disable"] or L["Enable"])
    end
end

function RevUI:RefreshModuleCardStates(container)
    if not container then return end
    for _, child in ipairs({ container:GetChildren() }) do
        if child._moduleKey then
            local isEnabled = InfinityTools.DB.LoadByKey[child._moduleKey] ~= false
            RevUI:ApplyModuleCardState(child, isEnabled)
        end
    end
end

-- Comment translated to English
function RevUI:GenerateModuleCards(parent, onComplete)
    local cardWidth = 250
    local cardHeight = 200
    local cardsPerRow = 3
    local cardSpacing = 10
    local xOffset = 5
    local yOffset = -5

    RevUI.AsyncHandler:Async(function()
        local totalRows = math.ceil(#InfinityTools.ModuleList / cardsPerRow)
        local totalHeight = totalRows * (cardHeight + cardSpacing) + 20
        parent:SetHeight(totalHeight)
        if onComplete then onComplete(totalHeight) end

        for i, meta in ipairs(InfinityTools.ModuleList) do
            if i % 3 == 0 then coroutine.yield() end
            if not parent:IsVisible() then return end

            local isEnabled = InfinityTools.DB.LoadByKey[meta.Key] ~= false
            -- ... (Layout check logic if needed)
            local hasSettings = not meta.HideCfg and InfinityTools.RegisteredLayouts[meta.Key] ~= nil

            local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
            card._moduleKey = meta.Key
            card:SetSize(cardWidth, cardHeight)
            card:SetBackdrop(BACKDROP)
            card:SetBackdropColor(unpack(THEME.CardBg))

            local row = math.floor((i - 1) / cardsPerRow)
            local col = (i - 1) % cardsPerRow
            card:SetPoint("TOPLEFT", xOffset + col * (cardWidth + cardSpacing),
                yOffset - row * (cardHeight + cardSpacing))

            local thumbnail = card:CreateTexture(nil, "ARTWORK")
            card.Thumbnail = thumbnail
            thumbnail:SetSize(cardWidth - 20, 90)
            thumbnail:SetPoint("TOP", 0, -10)
            thumbnail:SetTexture("Interface\\AddOns\\InfinityTools\\InfinityMythicPlus\\Textures\\LOGO\\RevTools.png")

            local nameText = card:CreateFontString(nil, "OVERLAY")
            nameText:SetFontObject("GameFontNormalLarge")
            nameText:SetPoint("TOPLEFT", 10, -105)
            nameText:SetText(meta.Name or meta.Key)
            nameText:SetTextColor(unpack(THEME.TextMain))
            nameText:SetWidth(cardWidth - 20)
            nameText:SetJustifyH("LEFT")

            local descText = card:CreateFontString(nil, "OVERLAY")
            descText:SetFontObject("GameFontHighlight")
            descText:SetPoint("TOPLEFT", 10, -122)
            descText:SetText(meta.Desc or "")
            descText:SetTextColor(unpack(THEME.TextSub))
            descText:SetWidth(cardWidth - 20)
            descText:SetJustifyH("LEFT")
            descText:SetWordWrap(true)
            descText:SetMaxLines(2)

            if hasSettings then
                local settingsBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
                settingsBtn:SetSize(70, 22)
                settingsBtn:SetPoint("BOTTOMLEFT", 10, 8)
                settingsBtn:SetBackdrop(BACKDROP_SIMPLE)
                settingsBtn:SetBackdropColor(unpack(THEME.Primary))
                local settingsBtnText = settingsBtn:CreateFontString(nil, "OVERLAY")
                settingsBtnText:SetFontObject("GameFontNormal")
                settingsBtnText:SetPoint("CENTER")
                settingsBtnText:SetText(L["Settings"])  -- TODO: missing key: L["Settings"]
                settingsBtnText:SetTextColor(1, 1, 1, 1)
                settingsBtn:SetScript("OnClick", function()
                    RevUI.CurrentPage = "ModuleSettings"
                    RevUI.CurrentModule = meta.Key
                    RevUI:RefreshContent()
                end)
            end

            local enableBtn = CreateFrame("Button", nil, card, "BackdropTemplate")
            card.EnableBtn = enableBtn
            enableBtn:SetSize(70, 22)
            enableBtn:SetPoint("BOTTOMRIGHT", -10, 8)
            enableBtn:SetBackdrop(BACKDROP_SIMPLE)

            local enableBtnText = enableBtn:CreateFontString(nil, "OVERLAY")
            card.EnableBtnText = enableBtnText
            enableBtnText:SetFontObject("GameFontNormal")
            enableBtnText:SetPoint("CENTER")
            enableBtnText:SetTextColor(1, 1, 1, 1)

            RevUI:ApplyModuleCardState(card, isEnabled)

            enableBtn:SetScript("OnClick", function(self)
                local currentEnabled = InfinityTools.DB.LoadByKey[meta.Key] ~= false
                local newEnabled = not currentEnabled
                InfinityTools.DB.LoadByKey[meta.Key] = newEnabled
                RevUI:ApplyModuleCardState(card, newEnabled)
            end)
        end
    end, "InfinityTools_GenCards")
end

-- =========================================================
-- Comment translated to English
-- Comment translated to English
-- =========================================================
function RevUI:ShowModuleSettingsPage()
    if not RevUI.CurrentModule then return end

    local moduleMeta = nil
    for _, meta in ipairs(InfinityTools.ModuleList) do
        if meta.Key == RevUI.CurrentModule then
            moduleMeta = meta
            break
        end
    end
    if not moduleMeta then return end

    RevUI.SwitchingModule = true

-- Comment translated to English
    local layoutData = InfinityTools.RegisteredLayouts[RevUI.CurrentModule]
    if layoutData and _G.InfinityGrid then
        RevUI.RightPanel:Show()
-- Comment translated to English
        RevUI.RightPanel:SetFrameLevel(RevUI.MainFrame:GetFrameLevel() + 10)

        if not RevUI.ModuleScrollFrame then
-- Comment translated to English
            RevUI.ModuleScrollFrame = CreateFrame("ScrollFrame", "InfinityModuleGridScroll", RevUI.RightPanel,
                "UIPanelScrollFrameTemplate")
            RevUI.ModuleScrollFrame:SetPoint("TOPLEFT", 0, -5)
            RevUI.ModuleScrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

            if _G["InfinityModuleGridScrollTop"] then _G["InfinityModuleGridScrollTop"]:Hide() end
            if _G["InfinityModuleGridScrollBottom"] then _G["InfinityModuleGridScrollBottom"]:Hide() end

            local child = CreateFrame("Frame", nil, RevUI.ModuleScrollFrame)
            child:SetSize(750, 1)
            RevUI.ModuleScrollFrame:SetScrollChild(child)
            RevUI.ModuleScrollChild = child
        end
        RevUI.ModuleScrollFrame:Show()
        RevUI.ModuleScrollFrame:SetVerticalScroll(0) -- Comment translated to English

-- Comment translated to English
        for _, cachedPage in pairs(RevUI.PageCache) do
            cachedPage:Hide()
        end

-- Comment translated to English
        local page, isNew = RevUI:GetCachedPage("ModuleGrid_" .. RevUI.CurrentModule, RevUI.ModuleScrollChild)
        RevUI.ActivePageFrame = page

-- Comment translated to English
        for _, child in ipairs({ page:GetChildren() }) do
            if not child._isPersistent then
                child:Hide()
                child:SetParent(nil)
            end
        end

-- Comment translated to English
        if RevUI.NoLayoutLabel then RevUI.NoLayoutLabel:Hide() end

-- Comment translated to English
        local config = InfinityTools:GetModuleDB(RevUI.CurrentModule)
        local currentModuleKey = RevUI.CurrentModule
        _G.InfinityGrid:Render(page, layoutData, config, currentModuleKey, function()
-- Comment translated to English
            InfinityTools:UpdateState(currentModuleKey .. ".PanelRendered", GetTime())
        end)

-- Comment translated to English
        if InfinityTools.State.DevMode then
            local editBtn = RevUI:CreateSmallButton(page, "|cff00ff00Edit Layout|r", function()
                _G.InfinityGrid:ToggleLiveEdit(page, RevUI.CurrentModule)
            end)
            editBtn:SetPoint("TOPRIGHT", page, "TOPRIGHT", -20, -5)
            editBtn:SetFrameLevel(page:GetFrameLevel() + 50)
            editBtn._isPersistent = true -- Comment translated to English
        end
    else
-- Comment translated to English
        RevUI.RightPanel:Show()
        RevUI.RightPanel:SetFrameLevel(RevUI.MainFrame:GetFrameLevel() + 10)

        if not RevUI.NoLayoutLabel then
            local lbl = RevUI.RightPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            lbl:SetPoint("CENTER", RevUI.RightPanel, "CENTER", 0, 0)
            RevUI.NoLayoutLabel = lbl
        end
        RevUI.NoLayoutLabel:SetText("|cffffaa00[" .. moduleMeta.Key .. ":" .. moduleMeta.Name .. "]|r\n\nThis module has not registered a Grid layout yet.\n\nPlease send a screenshot to the addon developer.\n\nAdd an REGISTER_LAYOUT() function near the end of the module file.")
        RevUI.NoLayoutLabel:Show()
    end


-- Comment translated to English
    RevUI.SwitchingModule = nil
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:CreateActionButton(parent, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(180, 40)
    btn:SetBackdrop(BACKDROP)
    btn:SetBackdropColor(unpack(THEME.Primary))
    btn:SetBackdropBorderColor(0.5, 0.5, 0.55, 0.8)

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFontObject("GameFontNormal")
    btnText:SetPoint("CENTER")
    btnText:SetText(text)
    btnText:SetTextColor(1, 1, 1, 1)

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(THEME.Primary[1] * 1.3, THEME.Primary[2] * 1.3, THEME.Primary[3] * 1.3, 1)
        self:SetBackdropBorderColor(0.8, 0.5, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
-- Comment translated to English
        self:SetBackdropColor(unpack(THEME.Primary))
        self:SetBackdropBorderColor(0.5, 0.5, 0.55, 0.8)
    end)

    return btn
end

function RevUI:CreateSmallButton(parent, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(120, 28)
    btn:SetBackdrop(BACKDROP_SIMPLE)
    btn:SetBackdropColor(0.2, 0.2, 0.25, 0.9)

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFontObject("GameFontNormal")
    btnText:SetPoint("CENTER")
    btnText:SetText(text)
    btnText:SetTextColor(unpack(THEME.TextMain))

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.35, 0.95)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.25, 0.9)
    end)

    return btn
end

-- =========================================================
-- Comment translated to English
-- =========================================================
-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:ShowDiagnosticPage()
-- Comment translated to English
    local page, isNew = RevUI:GetCachedPage("Diagnostic", RevUI.RightScrollChild)
    RevUI.ActivePageFrame = page

-- Comment translated to English
    for _, child in pairs({ page:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in pairs({ page:GetRegions() }) do
        region:Hide()
    end

    local env = InfinityTools:GetEnvironmentInfo()
    local db = _G.InfinityToolsDB
    local yOffset = -15
    local localTime = date("%Y-%m-%d %H:%M:%S")

-- Comment translated to English
    local pageTitle = page:CreateFontString(nil, "OVERLAY")
    pageTitle:SetFont(InfinityTools.MAIN_FONT, 25, "OUTLINE")
    pageTitle:SetPoint("TOPLEFT", 20, yOffset)
    pageTitle:SetText("|cffA330C9" .. L["Diagnostics"] .. "|r")  -- TODO: missing key: L["Diagnostics"]
    yOffset = yOffset - 35

-- Comment translated to English
    local envHeader = page:CreateFontString(nil, "OVERLAY")
    envHeader:SetFont(InfinityTools.MAIN_FONT, 20, "OUTLINE")
    envHeader:SetPoint("TOPLEFT", 20, yOffset)
    envHeader:SetText(L["[ Environment ]"])
    envHeader:SetTextColor(0.4, 0.8, 1)
    yOffset        = yOffset - 22

    local YES      = "|cff00ff00" .. L["Yes"] .. "|r"
    local NO       = "|cffaaaaaa" .. L["No"] .. "|r"
    local envLines = {
        string.format(L["Addon: |cff00ff00%s|r  |  WTF: |cff00ff00%d|r"], env.addonVersion, env.dbVersion),
        string.format(L["Game: |cffffd100%s|r (Build: %s)"], env.gameVersion, env.gameBuild),
        string.format(L["OS: |cffffd100%s (%s)|r  |  Region: |cffffd100%s|r  |  Locale: |cffffd100%s|r"], env.platform, env.arch,
            env.region, env.locale),
        string.format(L["PTR: %s  |  BETA: %s  |  ElvUI: %s"],
            env.isPTR == "Yes" and YES or NO,
            env.isBeta == "Yes" and YES or NO,
            env.isElvUI == "Yes" and YES or NO),
        string.format(L["Time: |cffffd100%s|r"], localTime),  -- TODO: missing key: L["Time: |cffffd100%s|r"]
    }
    for _, line in ipairs(envLines) do
        local text = page:CreateFontString(nil, "OVERLAY")
        text:SetFontObject("GameFontHighlightLarge")
        text:SetPoint("TOPLEFT", 30, yOffset)
        text:SetText(line)
        yOffset = yOffset - 18
    end
    yOffset = yOffset - 10

-- Comment translated to English
    local stateHeader = page:CreateFontString(nil, "OVERLAY")
    stateHeader:SetFont(InfinityTools.MAIN_FONT, 20, "OUTLINE")
    stateHeader:SetPoint("TOPLEFT", 20, yOffset)
    stateHeader:SetText(L["[ Current State ]"])
    stateHeader:SetTextColor(0.4, 0.8, 1)
    yOffset = yOffset - 22

    local state = InfinityTools.State
    local mapID = tonumber(state.MapID) or 0
    local mapGroup = tonumber(state.MapGroup) or 0
    local instanceID = tonumber(state.InstanceID) or 0
    if mapGroup <= 0 then mapGroup = mapID end
    local encounterID = tonumber(state.EncounterID) or 0
    local level = tonumber(state.Level) or 0
    local stateLines = {
        string.format(L["Class: |cff00ff00%s|r  |  Spec: |cff00ff00%s|r  |  Level: |cffffd100%d|r"], state.ClassName, state
            .SpecName, level),
        string.format(L["Instance: %s  |  Type: |cffffd100%s|r  |  Combat: %s"],
            state.InInstance and YES or NO,
            state.InstanceType,
            state.InCombat and "|cffff0000" .. L["Yes"] .. "|r" or NO),
        string.format(L["MapID: |cffffd100%d|r  |  MapGroup: |cffffd100%d|r  |  InstanceID: |cffffd100%d|r"], mapID, mapGroup,
            instanceID),
        string.format(L["Boss: %s  |  BossID: |cffffd100%d|r"],
            state.IsBossEncounter and YES or NO,
            encounterID),
        string.format(L["Party: %s  |  Raid: %s"],
            state.IsInParty and YES or NO,
            state.IsInRaid and YES or NO),
    }
    for _, line in ipairs(stateLines) do
        local text = page:CreateFontString(nil, "OVERLAY")
        text:SetFontObject("GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", 30, yOffset)
        text:SetText(line)
        yOffset = yOffset - 18
    end
    yOffset = yOffset - 10

-- Comment translated to English
    local statsHeader = page:CreateFontString(nil, "OVERLAY")
    statsHeader:SetFontObject("GameFontNormalLarge")
    statsHeader:SetPoint("TOPLEFT", 20, yOffset)
    statsHeader:SetText(L["[ Player Stats ]"])
    statsHeader:SetTextColor(0.4, 0.8, 1)
    yOffset = yOffset - 22

    local statsLines = {
        string.format(L["Primary: STR: |cffffd100%d|r AGI: |cffffd100%d|r INT: |cffffd100%d|r STA: |cffffd100%d|r"],
            state.PStat_Str, state.PStat_Agi, state.PStat_Int, state.PStat_Sta),
        string.format(L["Secondary: Crit: |cffffd100%.2f%%|r Haste: |cffffd100%.2f%%|r Mastery: |cffffd100%.2f%%|r Vers: |cffffd100%.2f%%|r"],
            state.PStat_Crit, state.PStat_Haste, state.PStat_Mastery, state.PStat_Versa),
        string.format(L["Tertiary: Leech: |cffffd100%.2f%%|r Avoid: |cffffd100%.2f%%|r Speed: |cffffd100%.2f%%|r Move: |cffffd100%d%%|r"],
            state.PStat_Leech, state.PStat_Avoidance, state.PStat_Speed, state.PStat_Movement),
        string.format(L["Defense: Armor: |cffffd100%d|r Dodge: |cffffd100%.2f%%|r Parry: |cffffd100%.2f%%|r Block: |cffffd100%.2f%%|r"],
            state.PStat_Armor, state.PStat_Dodge, state.PStat_Parry, state.PStat_Block),
        string.format(L["Other: iLvl: |cffffd100%.1f|r HP: |cffffd100%d|r"],
            state.PStat_EquippedItemLevel, state.PStat_MaxHealth),
    }

    for _, line in ipairs(statsLines) do
        local text = page:CreateFontString(nil, "OVERLAY")
        text:SetFontObject("GameFontHighlightLarge")
        text:SetPoint("TOPLEFT", 30, yOffset)
        text:SetText(line)
        yOffset = yOffset - 18
    end

    yOffset = yOffset - 10

-- Comment translated to English
    local libHeader = page:CreateFontString(nil, "OVERLAY")
    libHeader:SetFontObject("GameFontNormalLarge")
    libHeader:SetPoint("TOPLEFT", 20, yOffset)
    libHeader:SetText(L["[ Libraries ]"])
    libHeader:SetTextColor(0.4, 0.8, 1)
    yOffset = yOffset - 22

    local libText = page:CreateFontString(nil, "OVERLAY")
    libText:SetFontObject("GameFontHighlightLarge")
    libText:SetPoint("TOPLEFT", 30, yOffset)
    local libParts = {}
    for name, loaded in pairs(InfinityTools.LibStatus) do
        local status = loaded and "|cff00ff00[OK]|r" or "|cffff0000[X]|r"
        table.insert(libParts, string.format("%s %s", status, name))
    end
    libText:SetText(table.concat(libParts, "  |  "))
    yOffset = yOffset - 25

-- Comment translated to English
    local eventHeader = page:CreateFontString(nil, "OVERLAY")
    eventHeader:SetFontObject("GameFontNormal")
    eventHeader:SetPoint("TOPLEFT", 20, yOffset)
    eventHeader:SetText(L["[ Event Registry ]"])
    eventHeader:SetTextColor(0.4, 0.8, 1)
    yOffset = yOffset - 22

    local eventCount = 0
    local eventList = {}
    for event, handlers in pairs(InfinityTools.EventHandlers or {}) do
        local handlerCount = 0
        for _ in pairs(handlers) do handlerCount = handlerCount + 1 end
        eventCount = eventCount + 1
        table.insert(eventList, string.format("|cffffd100%s|r(%d)", event, handlerCount))
    end

    local eventText = page:CreateFontString(nil, "OVERLAY")
    eventText:SetFontObject("GameFontHighlight")
    eventText:SetPoint("TOPLEFT", 30, yOffset)
    if eventCount == 0 then
        eventText:SetText("|cffaaaaaa" .. L["No events registered"] .. "|r")
    else
        eventText:SetText(string.format(L["|cff00ff00%d|r events: %s"], eventCount, table.concat(eventList, ", ")))
    end
    eventText:SetWidth(800)
    yOffset = yOffset - 25

-- Comment translated to English
-- Comment translated to English
    local textHeight = eventText:GetStringHeight()
    yOffset = yOffset - textHeight - 20

-- Comment translated to English
    local modHeader = page:CreateFontString(nil, "OVERLAY")
    modHeader:SetFontObject("GameFontNormal")
    modHeader:SetPoint("TOPLEFT", 20, yOffset)
    modHeader:SetText(L["[ Module Status ]"])
    modHeader:SetTextColor(0.4, 0.8, 1)
    yOffset = yOffset - 22

    local colWidth = 280
    local col = 0
    local rowY = yOffset

    for _, meta in ipairs(InfinityTools.ModuleList) do
        local key = meta.Key
        local enabled = db.LoadByKey[key]
        local ready = InfinityTools.ModuleStatus[key] == "ready"

        local statusIcon, statusColor
        if not enabled then
            statusIcon = "|cff888888[" .. L["OFF"] .. "]|r"
            statusColor = { 0.6, 0.6, 0.6 }
        elseif ready then
            statusIcon = "|cff00ff00[OK]|r"
            statusColor = { 0.13, 0.77, 0.37 }
        else
            statusIcon = "|cffff0000[!!]|r"
            statusColor = { 0.87, 0.26, 0.26 }
        end

        local modText = page:CreateFontString(nil, "OVERLAY")
        modText:SetFontObject("GameFontHighlight")
        modText:SetPoint("TOPLEFT", 30 + col * colWidth, rowY)
        modText:SetText(string.format("%s %s", statusIcon, meta.Name))
        modText:SetTextColor(unpack(statusColor))

        col = col + 1
        if col >= 3 then
            col = 0
            rowY = rowY - 18
        end
    end
    if col > 0 then rowY = rowY - 18 end
    yOffset = rowY - 15

-- Comment translated to English
    page:SetHeight(math.abs(yOffset) + 50)
    RevUI.RightScrollChild:SetHeight(page:GetHeight())
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:ShowProfileManagerPage()
    local page, isNew = RevUI:GetCachedPage("ProfileManager", RevUI.RightScrollChild)
    RevUI.ActivePageFrame = page

-- Comment translated to English
    if not RevUI.ProfileState then
        RevUI.ProfileState = {
            exportSelected = {}, -- Comment translated to English
            importSelected = {}, -- Comment translated to English
            parsedData = nil, -- Comment translated to English
            mergeMode = "replace", -- Comment translated to English
        }
    end
    local state = RevUI.ProfileState

    if not isNew then
        RevUI.RightScrollChild:SetHeight(1200)
        return
    end

    local yOffset = -20
    local Export = InfinityTools.Export

-- Comment translated to English
    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFont(InfinityTools.MAIN_FONT, 25, "OUTLINE")
    title:SetPoint("TOPLEFT", 20, yOffset)
    title:SetText("|cffA330C9" .. L["Profiles"] .. "|r")
    yOffset = yOffset - 40

-- Comment translated to English
    local exportSection = CreateFrame("Frame", nil, page, "BackdropTemplate")
    exportSection:SetSize(780, 400)
    exportSection:SetPoint("TOPLEFT", 20, yOffset)
    exportSection:SetBackdrop(BACKDROP)
    exportSection:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
    exportSection:SetBackdropBorderColor(unpack(THEME.Border))

    local exportTitle = exportSection:CreateFontString(nil, "OVERLAY")
    exportTitle:SetFont(InfinityTools.MAIN_FONT, 20, "OUTLINE")
    exportTitle:SetPoint("TOPLEFT", 15, -15)
    exportTitle:SetText("|cff00ff80 " .. L["Export Profile"] .. "|r")

-- Comment translated to English
    local nameInput = RevUI:CreateEditBox(exportSection, L["My Profile"], 300, 30, L["Profile Name:"], { labelPos = "left" })
    nameInput:SetPoint("TOPLEFT", 100, -50)

-- Comment translated to English
    local authorInput = RevUI:CreateEditBox(exportSection, "", 200, 30, L["Author:"],
        { labelPos = "left", placeholder = L["Leave blank to use current name"] })
    authorInput:SetPoint("LEFT", nameInput, "RIGHT", 80, 0)

-- Comment translated to English
    local noteInput = RevUI:CreateEditBox(exportSection, "", 600, 70, L["Notes:"], { labelPos = "left" })
    noteInput:SetPoint("TOPLEFT", 100, -100)

-- Comment translated to English
    local moduleLabel = exportSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moduleLabel:SetPoint("TOPLEFT", 15, -190)
    moduleLabel:SetText(L["Select modules to export:"])

-- Comment translated to English
    local selectAllBtn = RevUI:CreateSmallButton(exportSection, L["All"], function()
        local modules = Export:GetExportableModules()
        for _, m in ipairs(modules) do state.exportSelected[m.key] = true end
        RevUI:RefreshExportCheckboxes()
    end)
    selectAllBtn:SetSize(60, 22); selectAllBtn:SetPoint("LEFT", moduleLabel, "RIGHT", 15, 0)

    local selectNoneBtn = RevUI:CreateSmallButton(exportSection, L["None"], function()
        wipe(state.exportSelected); RevUI:RefreshExportCheckboxes()
    end)
    selectNoneBtn:SetSize(70, 22); selectNoneBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 5, 0)

-- Comment translated to English
    local exportList = CreateFrame("Frame", nil, exportSection)
    exportList:SetSize(740, 1)
    exportList:SetPoint("TOPLEFT", 15, -220)
    RevUI.ExportListFrame = exportList

-- Comment translated to English
    local exportBtn = RevUI:CreateActionButton(exportSection, L["Generate Export String"], function()
        local profileName = nameInput:GetText() or L["Untitled"]
        local authorName = authorInput:GetText() or ""
        local note = noteInput:GetText() or ""
        local result, err = Export:ExportModules(state.exportSelected, profileName, authorName, note)
        if result then
            RevUI:ShowExportResultPopup(result, profileName)
        else
            print("|cffff0000[InfinityTools]|r " .. L["Export failed: "] .. (err or L["Unknown error"]))
        end
    end)
    exportBtn:SetSize(200, 38)
    exportBtn:SetBackdropColor(unpack(THEME.Primary))
    exportBtn:SetBackdropBorderColor(0.5, 0.5, 0.55, 0.8)
    exportBtn:SetPoint("BOTTOMRIGHT", exportSection, "BOTTOMRIGHT", -15, 15)
    RevUI.ExportGenBtn = exportBtn

    yOffset = yOffset - 420

-- Comment translated to English
    local importSection = CreateFrame("Frame", nil, page, "BackdropTemplate")
    importSection:SetSize(780, 480)
-- Comment translated to English
    importSection:SetPoint("TOPLEFT", 20, -1000)
    RevUI.ImportSection = importSection
    importSection:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
    importSection:SetBackdropBorderColor(unpack(THEME.Border))

    local importTitle = importSection:CreateFontString(nil, "OVERLAY")
    importTitle:SetFont(InfinityTools.MAIN_FONT, 20, "OUTLINE")
    importTitle:SetPoint("TOPLEFT", 15, -15)
    importTitle:SetText("|cff00aaff " .. L["Import Profile"] .. "|r")

-- Comment translated to English
    local importInput = RevUI:CreateEditBox(importSection, "", 750, 100, L["Paste import string:"], { labelPos = "top" })
    importInput:SetPoint("TOPLEFT", 15, -60)
    RevUI.ImportStringField = importInput

-- Comment translated to English
    local parseBtn = RevUI:CreateSmallButton(importSection, L["Parse & Preview"], function()
        local importDataInput = RevUI.ImportStringField:GetText()
        local data, err = Export:ParseImportString(importDataInput)
        if data then
            state.parsedData = data
            local summary = Export:GetImportSummary(data)
            wipe(state.importSelected)
            for _, m in ipairs(summary.modules) do state.importSelected[m.key] = true end
            RevUI:RefreshImportPreview(summary)
            print("|cff00ff00[InfinityTools]|r " .. string.format(L["Parsed successfully! Found %d module(s)"], summary.moduleCount))
        else
            state.parsedData = nil
            RevUI:RefreshImportPreview(nil)
            print("|cffff0000[InfinityTools]|r " .. L["Parse failed: "] .. (err or L["Unknown error"]))
        end
    end)
    parseBtn:SetSize(120, 26)
    parseBtn:SetPoint("TOPLEFT", RevUI.ImportStringField, "BOTTOMLEFT", 0, -10)

-- Comment translated to English
    local previewFrame = CreateFrame("Frame", nil, importSection)
    previewFrame:SetSize(740, 1)
    previewFrame:SetPoint("TOPLEFT", 15, -195)
    RevUI.ImportPreviewFrame = previewFrame

-- Comment translated to English
    local pName = RevUI:CreateEditBox(previewFrame, "", 300, 30, "|cffffd100" .. L["Profile Name:"] .. "|r", { labelPos = "left" })
    pName:SetPoint("TOPLEFT", 85, 0)
    pName.editBox:Disable(); pName:SetBackdropColor(0.05, 0.05, 0.05, 1)
    RevUI.ImportPreviewName = pName

    local pAuthor = RevUI:CreateEditBox(previewFrame, "", 200, 30, "|cffffd100" .. L["Author:"] .. "|r", { labelPos = "left" })  -- TODO: missing key: L["Author:"]
    pAuthor:SetPoint("LEFT", pName, "RIGHT", 75, 0)
    pAuthor.editBox:Disable(); pAuthor:SetBackdropColor(0.05, 0.05, 0.05, 1)
    RevUI.ImportPreviewAuthor = pAuthor

    local pNote = RevUI:CreateEditBox(previewFrame, "", 600, 60, "|cffffd100" .. L["Notes:"] .. "|r", { labelPos = "left" })
    pNote:SetPoint("TOPLEFT", 85, -45)
    pNote.editBox:Disable(); pNote:SetBackdropColor(0.05, 0.05, 0.05, 1)
    RevUI.ImportPreviewNote = pNote

-- Comment translated to English
    local importModLabel = previewFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    importModLabel:SetPoint("TOPLEFT", 0, -125)
    importModLabel:SetText(L["Select modules to import:"])
    RevUI.ImportPreviewLabel = importModLabel

-- Comment translated to English
    local importList = CreateFrame("Frame", nil, previewFrame)
    importList:SetSize(740, 1)
    importList:SetPoint("TOPLEFT", 0, -155)
    RevUI.ImportListFrame = importList

-- Comment translated to English
    local applyBtn = RevUI:CreateActionButton(importSection, L["Apply Import"], function()
        if not state.parsedData then
            print("|cffff0000[InfinityTools]|r " .. L["Please parse the import string first"])
            return
        end
-- Comment translated to English
        local count = Export:ApplyImport(state.parsedData, state.importSelected, "replace")
        if count > 0 then
            StaticPopup_Show("INFINITY_IMPORT_SUCCESS", count)
        else
            print("|cffff8800[InfinityTools]|r " .. L["No modules imported (none selected or data empty)"])
        end
    end)
    applyBtn:SetSize(160, 38)
    applyBtn:SetPoint("BOTTOMRIGHT", importSection, "BOTTOMRIGHT", -15, 15)

    yOffset = yOffset - 500

-- Comment translated to English
    RevUI:RefreshExportCheckboxes()

-- Comment translated to English
    page:SetHeight(math.abs(yOffset) + 50)
    RevUI.RightScrollChild:SetHeight(page:GetHeight())
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:RefreshExportCheckboxes()
    local Export = InfinityTools.Export
    local state = RevUI.ProfileState
    local parent = RevUI.ExportListFrame
    if not parent then return end

-- Comment translated to English
    for _, child in ipairs({ parent:GetChildren() }) do
        if not child._isPersistent then
            child:Hide(); child:SetParent(nil)
        end
    end

    local modules = Export:GetExportableModules()
    local yOff = 0
    local col = 0
    local rowHeight = 32 -- Comment translated to English

    for i, m in ipairs(modules) do
-- Comment translated to English
        local cb = RevUI:CreateCheckbox(parent, m.name, state.exportSelected[m.key] or false, function(checked)
            state.exportSelected[m.key] = checked
        end)
        cb:SetSize(220, 26)
        cb:SetPoint("TOPLEFT", (col * 240), yOff)

-- Comment translated to English
        cb.label:ClearAllPoints()
        cb.label:SetPoint("LEFT", cb.checkbox, "RIGHT", 5, 0)
        cb.label:SetJustifyH("LEFT")
        cb.label:SetTextColor(0.9, 0.9, 0.9)

        col = col + 1
        if col >= 3 then
            col = 0
            yOff = yOff - rowHeight
        end
    end

-- Comment translated to English
    local listHeight = math.abs(yOff) + 40
    parent:SetHeight(listHeight)

    local exportSection = parent:GetParent()
-- Comment translated to English
    local sectionHeight = 250 + listHeight + 80
    exportSection:SetHeight(sectionHeight)

-- Comment translated to English
    if RevUI.ImportSection then
        RevUI.ImportSection:ClearAllPoints()
        RevUI.ImportSection:SetPoint("TOPLEFT", 20, -(100 + sectionHeight + 50))
    end

-- Comment translated to English
    local page = exportSection:GetParent()
    if page then
        page:SetHeight(sectionHeight + (RevUI.ImportSection and RevUI.ImportSection:GetHeight() or 500) + 200)
    end
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:RefreshImportPreview(summary)
    local state = RevUI.ProfileState
    local parent = RevUI.ImportListFrame
    if not parent then return end

-- Comment translated to English
    for _, child in ipairs({ parent:GetChildren() }) do
        child:Hide(); child:SetParent(nil)
    end

    if not summary then
        RevUI.ImportPreviewName:SetText("")
        RevUI.ImportPreviewAuthor:SetText("")
        RevUI.ImportPreviewNote:SetText("")
        RevUI.ImportPreviewLabel:SetText("|cff888888" .. L["Waiting for parse..."] .. "|r")
        return
    end

-- Comment translated to English
    RevUI.ImportPreviewName:SetText(summary.profileName or L["Untitled"])
    RevUI.ImportPreviewAuthor:SetText(summary.author or L["Unknown"])
    RevUI.ImportPreviewNote:SetText(summary.note or L["No notes"])
    RevUI.ImportPreviewLabel:SetText("|cff00ff80" ..
        L["Preview:"] .. "|r " .. string.format("|cffaaaaaa(" .. L["Version: %s"] .. ")|r", summary.addonVersion))

-- Comment translated to English
    local yOff = 0
    local col = 0
    local rowHeight = 32

    for i, m in ipairs(summary.modules) do
        local labelText = m.name
        if not m.exists then
            labelText = "|cffff6666" .. labelText .. " (" .. L["not installed"] .. ")|r"
        else
            labelText = "|cff90ee90" .. labelText .. "|r"
        end

        local cb = RevUI:CreateCheckbox(parent, labelText, state.importSelected[m.key] or false, function(checked)
            state.importSelected[m.key] = checked
        end)
        cb:SetSize(220, 26)
        cb:SetPoint("TOPLEFT", (col * 240), yOff)

-- Comment translated to English
        cb.label:ClearAllPoints()
        cb.label:SetPoint("LEFT", cb.checkbox, "RIGHT", 5, 0)
        cb.label:SetJustifyH("LEFT")

        col = col + 1
        if col >= 3 then
            col = 0; yOff = yOff - rowHeight
        end
    end

-- Comment translated to English
    local listHeight = math.abs(yOff) + 60
    parent:SetHeight(listHeight)

    local importSection = parent:GetParent():GetParent()
    if importSection then
        importSection:SetHeight(260 + listHeight + 80)
    end

    local page = importSection:GetParent()
    if page then page:SetHeight(math.abs(page:GetTop() - importSection:GetBottom()) + 200) end
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevUI:ShowExportResultPopup(exportString, profileName)
-- Comment translated to English
    if not RevUI.ExportPopup then
        local popup = CreateFrame("Frame", "InfinityExportPopup", UIParent, "BackdropTemplate")
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
        popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

        local title = popup:CreateFontString(nil, "OVERLAY")
        title:SetFont(InfinityTools.MAIN_FONT, 25, "OUTLINE")
        title:SetPoint("TOP", 0, -15)
        title:SetText("|cff00ff80" .. L["Export Successful"] .. "|r")
        popup.Title = title

        local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function() popup:Hide() end)

        local hint = popup:CreateFontString(nil, "OVERLAY")
        hint:SetFontObject("GameFontHighlight")
        hint:SetPoint("TOP", title, "BOTTOM", 0, -10)
        hint:SetText(L["|cffffd100Ctrl+C|r to copy and close, or click |cffffd100Select All|r"])  -- TODO: missing key: L["|cffffd100Ctrl+C|r to copy and close, or click |cffffd100Select All|r"]
        hint:SetTextColor(0.8, 0.8, 0.8)
        popup.Hint = hint

-- Comment translated to English
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
        copyHintText:SetText("|cff00ff00✓ " .. L["Copied to clipboard"] .. "|r")
        popup.CopyHint = copyHint

        local editFrame = CreateFrame("Frame", nil, popup, "BackdropTemplate")
        editFrame:SetSize(560, 200)
        editFrame:SetPoint("TOP", hint, "BOTTOM", 0, -10)
        editFrame:SetBackdrop(BACKDROP_SIMPLE)
        editFrame:SetBackdropColor(0.1, 0.1, 0.12, 1)

        local scrollFrame = CreateFrame("ScrollFrame", nil, editFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 5, -5)
        scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetSize(530, 190)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetTextColor(0.7, 0.9, 0.7)
        editBox:SetAutoFocus(false)
        editBox:SetMultiLine(true)
        editBox:SetMaxLetters(999999)
        scrollFrame:SetScrollChild(editBox)
        popup.EditBox = editBox

-- Comment translated to English
        popup.lastCtrlDown = 0
        popup:SetScript("OnUpdate", function(self)
            if IsControlKeyDown() then
                self.lastCtrlDown = GetTime()
            end
        end)

-- Comment translated to English
        editBox:SetScript("OnKeyUp", function(self, key)
            local wasCtrlDown = IsControlKeyDown() or (GetTime() - popup.lastCtrlDown < 0.5)
            if wasCtrlDown and key == "C" then
                self:ClearFocus()
-- Comment translated to English
                popup.CopyHint:Show()
                popup.CopyHint:SetAlpha(1)
                C_Timer.After(0.6, function()
                    popup:Hide()
                    popup.CopyHint:Hide()
                end)
            end
        end)

        local selectBtn = RevUI:CreateSmallButton(popup, L["Select All"], function()
            editBox:SetFocus()
            editBox:HighlightText()
        end)
        selectBtn:SetSize(100, 28)
        selectBtn:SetPoint("BOTTOM", popup, "BOTTOM", -60, 15)

        local closeBtn2 = RevUI:CreateSmallButton(popup, L["Close"], function()
            popup:Hide()
        end)
        closeBtn2:SetSize(80, 28)
        closeBtn2:SetPoint("BOTTOM", popup, "BOTTOM", 60, 15)

        RevUI.ExportPopup = popup
    end

    local popup = RevUI.ExportPopup
    popup.EditBox:SetText(exportString)
    popup.Title:SetText("|cff00ff80" .. L["Export Successful"] .. "|r - " .. profileName)
    popup.CopyHint:Hide()
    popup:Show()
    popup.EditBox:SetFocus()
    popup.EditBox:HighlightText()
end

-- =========================================================
-- Comment translated to English
-- =========================================================
local function OnIdentityStateChanged()
-- Comment translated to English
    if RevUI.MainFrame and RevUI.MainFrame:IsShown() then
        if RevUI.CurrentPage == "Diagnostic" then
-- Comment translated to English
            RevUI:RefreshContent()
        end
-- Comment translated to English
-- Comment translated to English
    end
end

-- Comment translated to English
InfinityTools:WatchState("ClassID", "RevUI_Identity", OnIdentityStateChanged)
InfinityTools:WatchState("ClassName", "RevUI_Identity", OnIdentityStateChanged)
InfinityTools:WatchState("SpecID", "RevUI_Identity", OnIdentityStateChanged)
InfinityTools:WatchState("SpecName", "RevUI_Identity", OnIdentityStateChanged)

-- Comment translated to English
if InfinityTools.Grid then
    RevUI.Grid = InfinityTools.Grid
end
