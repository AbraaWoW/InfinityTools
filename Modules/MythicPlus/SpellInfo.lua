local _, RRT_NS = ...

local Core      = RRT_NS.Mythic or _G.RRTMythicTools
local SpellData = RRT_NS.MythicSpellData
if not Core or not SpellData then return end

local MODULE_KEY = "RRTTools.SpellInfo"
local DEFAULTS   = { enabled = false, lastDungeon = nil }
local DB         = Core:GetModuleDB(MODULE_KEY, DEFAULTS)

local Factory    = Core.Factory or _G.RRTMythicFactory

-- ============================================================
-- Frame pools
-- ============================================================

Factory:InitPool("SG_NpcButton", "Button", "BackdropTemplate", function(btn)
    btn:SetSize(230, 52)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn.selBar = btn:CreateTexture(nil, "OVERLAY")
    btn.selBar:SetWidth(3)
    btn.selBar:SetPoint("TOPLEFT", 0, 0)
    btn.selBar:SetPoint("BOTTOMLEFT", 0, 0)
    btn.selBar:SetColorTexture(0.72, 0.33, 1, 1)

    btn.portrait = btn:CreateTexture(nil, "ARTWORK")
    btn.portrait:SetSize(42, 42)
    btn.portrait:SetPoint("LEFT", 6, 0)
    btn.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.nameText:SetPoint("LEFT", btn.portrait, "RIGHT", 8, 3)
    btn.nameText:SetPoint("RIGHT", -4, 0)
    btn.nameText:SetJustifyH("LEFT")
    btn.nameText:SetWordWrap(false)

    btn.typeText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.typeText:SetPoint("LEFT", btn.portrait, "RIGHT", 8, -11)
    btn.typeText:SetJustifyH("LEFT")
end)

Factory:InitPool("SG_SpellCard", "Frame", "BackdropTemplate", function(card)
    card:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.06, 0.06, 0.06, 0.90)
    card:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.9)
    card._pool = {}  -- internal sub-widget pool (FontStrings / Textures)
end)

-- ============================================================
-- Helpers
-- ============================================================

local function GetMythicMultiplier()
    -- Integrate with MythicDamage module if available
    local InfinityMythicDamage = _G.InfinityMythicDamage
    if InfinityMythicDamage and InfinityMythicDamage.GetCurrentMultiplier then
        return InfinityMythicDamage.GetCurrentMultiplier()
    end
    return 1
end

-- Sub-widget pool for spell cards (FontStrings and Textures reused per card)
local function AcquireSubWidget(card, objType)
    for _, w in ipairs(card._pool) do
        if not w:IsShown() and w:GetObjectType() == objType then
            w:Show(); return w
        end
    end
    local w
    if objType == "FontString" then
        w = card:CreateFontString(nil, "OVERLAY")
        w:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 13, "OUTLINE")
    else
        w = card:CreateTexture(nil, "ARTWORK")
    end
    w:Show()
    card._pool[#card._pool + 1] = w
    return w
end

local function HideAllSubWidgets(card)
    for _, w in ipairs(card._pool) do
        w:Hide()
        w:ClearAllPoints()
    end
end

-- Release all NPC buttons from a container
local function ReleaseNpcButtons(container)
    for _, child in ipairs({ container:GetChildren() }) do
        if child._fromPool == "SG_NpcButton" then
            Factory:Release("SG_NpcButton", child)
        end
    end
end

-- Release all spell cards from a container
local function ReleaseSpellCards(container)
    for _, child in ipairs({ container:GetChildren() }) do
        if child._fromPool == "SG_SpellCard" then
            Factory:Release("SG_SpellCard", child)
        end
    end
end

-- ============================================================
-- Spell card builder
-- ============================================================

local CARD_WIDTH = 560

local function BuildSpellCard(parent, spellID)
    local card = Factory:Acquire("SG_SpellCard", parent)
    card:SetWidth(CARD_WIDTH)
    HideAllSubWidgets(card)

    -- Spell data not cached yet
    if not C_Spell.IsSpellDataCached(spellID) then
        C_Spell.RequestLoadSpellData(spellID)
        local lbl = AcquireSubWidget(card, "FontString")
        lbl:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 12, "OUTLINE")
        lbl:SetTextColor(0.6, 0.6, 0.6, 1)
        lbl:SetPoint("CENTER")
        lbl:SetText(string.format("|cff888888Loading spell %d...|r", spellID))
        card:SetHeight(28)
        return card
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local tip       = C_TooltipInfo.GetSpellByID(spellID)

    if not spellInfo or not tip or not tip.lines then
        local lbl = AcquireSubWidget(card, "FontString")
        lbl:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 12, "OUTLINE")
        lbl:SetTextColor(1, 0.5, 0.2, 1)
        lbl:SetPoint("CENTER")
        lbl:SetText(string.format("|cffff8000Spell %d data unavailable|r", spellID))
        card:SetHeight(28)
        return card
    end

    local inlineTags, footerTags = SpellData:GetTagsForSpell(spellID)

    local ICON_SIZE = 36
    local cursorY   = -8
    local totalH    = 8

    -- Icon
    local icon = AcquireSubWidget(card, "Texture")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPLEFT", 7, -8)
    icon:SetTexture(spellInfo.iconID)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- First line: spell name + inline tags
    if tip.lines[1] then
        local nameStr = AcquireSubWidget(card, "FontString")
        nameStr:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 14, "OUTLINE")
        nameStr:SetTextColor(1, 0.82, 0, 1)
        nameStr:SetPoint("TOPLEFT", ICON_SIZE + 16, cursorY)
        nameStr:SetText(string.format("%s  |cff888888(%d)|r", tip.lines[1].leftText or "", spellID))

        local anchor = nameStr
        for _, t in ipairs(inlineTags) do
            local tagIcon = AcquireSubWidget(card, "Texture")
            tagIcon:SetSize(18, 18)
            tagIcon:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
            tagIcon:SetTexture(t.def.icon)
            tagIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local tagLbl = AcquireSubWidget(card, "FontString")
            tagLbl:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 13, "OUTLINE")
            tagLbl:SetTextColor(0.4, 0.85, 1, 1)
            tagLbl:SetPoint("LEFT", tagIcon, "RIGHT", 3, 0)
            tagLbl:SetText(t.def.name)
            anchor = tagLbl
        end

        totalH = totalH + 18
        cursorY = cursorY - 18
    end

    -- Remaining tooltip lines
    local lastFS = nil
    for i = 2, #tip.lines do
        local line = tip.lines[i]
        local text = line.leftText or ""

        -- Apply mythic damage multiplier if relevant
        if _G.InfinityMythicDamage and _G.InfinityMythicDamage.ProcessDamageText then
            text = _G.InfinityMythicDamage.ProcessDamageText(text, GetMythicMultiplier())
        end

        local fs = AcquireSubWidget(card, "FontString")
        fs:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 12, "OUTLINE")
        fs:SetSpacing(3)
        fs:SetWidth(CARD_WIDTH - ICON_SIZE - 28)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        if line.leftColor then
            fs:SetTextColor(line.leftColor.r, line.leftColor.g, line.leftColor.b, 1)
        else
            fs:SetTextColor(0.85, 0.85, 0.85, 1)
        end
        fs:SetText(text)

        if lastFS then
            fs:SetPoint("TOPLEFT", lastFS, "BOTTOMLEFT", 0, -3)
        else
            fs:SetPoint("TOPLEFT", ICON_SIZE + 16, cursorY - 2)
        end

        local lineH = math.max(fs:GetStringHeight(), 14) + 3
        totalH  = totalH + lineH
        cursorY = cursorY - lineH
        lastFS  = fs
    end

    -- Footer tags (MISC category)
    if #footerTags > 0 then
        totalH = totalH + 10
        local sep = AcquireSubWidget(card, "Texture")
        sep:SetSize(CARD_WIDTH - 20, 1)
        sep:SetPoint("TOPLEFT", 10, -(totalH + 2))
        sep:SetColorTexture(1, 1, 1, 0.08)
        totalH = totalH + 6

        local prev = nil
        for _, t in ipairs(footerTags) do
            local ti = AcquireSubWidget(card, "Texture")
            ti:SetSize(18, 18)
            if prev then
                ti:SetPoint("LEFT", prev, "RIGHT", 14, 0)
            else
                ti:SetPoint("TOPLEFT", 12, -(totalH + 2))
            end
            ti:SetTexture(t.def.icon)
            ti:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local tl = AcquireSubWidget(card, "FontString")
            tl:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 12, "OUTLINE")
            tl:SetTextColor(0.75, 0.75, 0.75, 1)
            tl:SetPoint("LEFT", ti, "RIGHT", 3, 0)
            tl:SetText(t.def.name)
            prev = tl
        end
        totalH = totalH + 24
    end

    card:SetHeight(math.max(ICON_SIZE + 16, totalH + 10))
    return card
end

-- ============================================================
-- Main frame state
-- ============================================================

local mainFrame        = nil
local currentDungeon   = nil
local currentNPC       = nil
local dungeonTabFrames = {}

-- ============================================================
-- NPC list refresh
-- ============================================================

local function RefreshNpcList(dungeonName, filter)
    currentDungeon = dungeonName
    DB.lastDungeon = dungeonName

    local container = mainFrame.npcScrollChild
    ReleaseNpcButtons(container)

    local npcs    = SpellData:GetNPCsForDungeon(dungeonName)
    local sorted  = {}
    for name in pairs(npcs) do sorted[#sorted + 1] = name end
    table.sort(sorted)

    local filt = (filter and filter ~= "" and filter ~= "Search...") and filter:lower() or nil
    local y    = 0

    for _, name in ipairs(sorted) do
        local data = npcs[name]
        if not filt or name:lower():find(filt, 1, true) then
            local btn = Factory:Acquire("SG_NpcButton", container)
            btn:SetPoint("TOPLEFT", 2, -y - 2)

            local isSelected = (currentNPC == name)
            if isSelected then
                btn:SetBackdropColor(0.20, 0.08, 0.32, 0.7)
                btn:SetBackdropBorderColor(0.72, 0.33, 1, 1)
                btn.selBar:Show()
            else
                btn:SetBackdropColor(0.05, 0.05, 0.05, 0.7)
                btn:SetBackdropBorderColor(0.22, 0.22, 0.22, 0.8)
                btn.selBar:Hide()
            end

            if data.displayID and data.displayID > 0 then
                SetPortraitTextureFromCreatureDisplayID(btn.portrait, data.displayID)
            else
                btn.portrait:SetTexture(134400)
            end

            btn.nameText:SetText(name)
            local levelLabel = data.level == 92 and "|cffb46fd4Boss|r" or (data.level == 91 and "|cff0070ddElite|r" or "|cff888888Normal|r")
            btn.typeText:SetText((data.type or "") .. "  " .. levelLabel)

            local capName = name
            btn:SetScript("OnClick", function()
                currentNPC = capName
                RefreshNpcList(dungeonName, filter)
                mainFrame.npcScroll:SetVerticalScroll(0)
                -- Rebuild spell list
                if mainFrame.RefreshSpells then mainFrame.RefreshSpells() end
            end)

            y = y + 56
        end
    end

    container:SetHeight(math.max(y + 4, 1))

    -- Auto-select first NPC if none selected
    if not currentNPC and #sorted > 0 then
        currentNPC = sorted[1]
        RefreshNpcList(dungeonName, filter)
        if mainFrame.RefreshSpells then mainFrame.RefreshSpells() end
    end
end

-- ============================================================
-- Spell panel refresh
-- ============================================================

local function RefreshSpellPanel()
    if not currentDungeon or not currentNPC then return end

    local npcs = SpellData:GetNPCsForDungeon(currentDungeon)
    local data = npcs[currentNPC]
    if not data then return end

    -- Update NPC info header
    local info = mainFrame.npcInfo
    info.nameText:SetText(currentNPC)
    local lvlStr = data.level == 92 and "|cffb46fd4Boss|r" or (data.level == 91 and "|cff0070ddElite|r" or "|cff888888Normal|r")
    info.detailText:SetText(string.format("|cffaaaaaa%s|r   NPC %d   %s", data.type or "", data.npcID or 0, lvlStr))

    -- Model
    if mainFrame.modelFrame then
        if mainFrame.modelFrame.lastDisplayID ~= data.displayID then
            mainFrame.modelFrame:SetDisplayInfo(data.displayID or 0)
            mainFrame.modelFrame.lastDisplayID = data.displayID
        end
    end

    -- Spell cards
    local container = mainFrame.spellScrollChild
    ReleaseSpellCards(container)

    local lastCard = nil
    if data.spells then
        for _, id in ipairs(data.spells) do
            local card = BuildSpellCard(container, id)
            if lastCard then
                card:SetPoint("TOPLEFT", lastCard, "BOTTOMLEFT", 0, -6)
            else
                card:SetPoint("TOPLEFT", 0, 0)
            end
            lastCard = card
        end
    end

    -- Resize scroll child
    local totalH = 0
    if lastCard then
        local _, yOff = lastCard:GetPoint(1)
        totalH = math.abs(yOff) + lastCard:GetHeight() + 6
    end
    container:SetHeight(math.max(totalH, 1))
    mainFrame.spellScroll:SetVerticalScroll(0)
end

-- ============================================================
-- Dungeon tab selection
-- ============================================================

local function SelectDungeon(dungeonName)
    currentNPC = nil
    for _, tab in ipairs(dungeonTabFrames) do
        tab.icon:SetDesaturated(tab.dungeonName ~= dungeonName)
        if tab.dungeonName == dungeonName then
            tab:SetBackdropBorderColor(0.72, 0.33, 1, 1)
        else
            tab:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.8)
        end
    end
    RefreshNpcList(dungeonName)
end

-- ============================================================
-- Main frame construction
-- ============================================================

local FRAME_W  = 1000
local FRAME_H  = 660
local LEFT_W   = 245
local MODEL_H  = 180

local function CreateMainFrame()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "RRTSpellGuideFrame", UIParent, "BackdropTemplate")
    tinsert(UISpecialFrames, "RRTSpellGuideFrame")
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.04, 0.04, 0.04, 0.97)
    f:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 18, "OUTLINE")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cFFBB66FFSpell Guide|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", 0, 0)

    -- -------------------------------------------------------
    -- Dungeon tab row
    -- -------------------------------------------------------
    local TAB_SIZE  = 48
    local TAB_PAD   = 8
    local tabY      = -36
    local tabStartX = LEFT_W + 10
    local dungeons  = SpellData:GetDungeonList()

    if #dungeons == 0 then
        local warn = f:CreateFontString(nil, "OVERLAY", "GameFontRed")
        warn:SetPoint("TOP", 0, -40)
        warn:SetText("No dungeons found. Check C_ChallengeMode data.")
    end

    for i, entry in ipairs(dungeons) do
        local tab = CreateFrame("Button", nil, f, "BackdropTemplate")
        tab:SetSize(TAB_SIZE, TAB_SIZE)
        tab:SetPoint("TOPLEFT", tabStartX + (i - 1) * (TAB_SIZE + TAB_PAD), tabY)
        tab:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        tab:SetBackdropColor(0.08, 0.08, 0.08, 0.8)
        tab:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.8)

        local tabIcon = tab:CreateTexture(nil, "ARTWORK")
        tabIcon:SetAllPoints()
        tabIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tabIcon:SetTexture(entry.icon)
        tabIcon:SetDesaturated(true)
        tab.icon = tabIcon

        local abbr = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        abbr:SetPoint("BOTTOM", 0, -14)
        abbr:SetText(entry.name:sub(1, 4))

        tab.dungeonName = entry.name
        tab:SetScript("OnClick", function() SelectDungeon(entry.name) end)
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(entry.name, 1, 1, 1)
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", function() GameTooltip:Hide() end)

        dungeonTabFrames[#dungeonTabFrames + 1] = tab
    end

    -- -------------------------------------------------------
    -- Left panel: NPC list
    -- -------------------------------------------------------
    local CONTENT_Y = tabY - TAB_SIZE - 28

    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetPoint("TOPLEFT", 4, CONTENT_Y)
    leftPanel:SetPoint("BOTTOMLEFT", 4, 4)
    leftPanel:SetWidth(LEFT_W)
    leftPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    leftPanel:SetBackdropColor(0.03, 0.03, 0.03, 0.6)
    leftPanel:SetBackdropBorderColor(0.20, 0.20, 0.20, 0.7)

    -- Search box
    local search = CreateFrame("EditBox", "RRTSpellGuideSearch", leftPanel, "InputBoxTemplate")
    search:SetSize(LEFT_W - 16, 22)
    search:SetPoint("TOPLEFT", 8, -8)
    search:SetAutoFocus(false)
    search:SetText("Search...")
    search:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Search..." then self:SetText("") end
    end)
    search:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then self:SetText("Search...") end
    end)
    search:SetScript("OnTextChanged", function(self)
        if currentDungeon then RefreshNpcList(currentDungeon, self:GetText()) end
    end)
    f.searchBox = search

    -- NPC scroll frame
    local npcSF = CreateFrame("ScrollFrame", nil, leftPanel, "UIPanelScrollFrameTemplate")
    npcSF:SetPoint("TOPLEFT", 4, -36)
    npcSF:SetPoint("BOTTOMRIGHT", -22, 4)
    local npcChild = CreateFrame("Frame", nil, npcSF)
    npcChild:SetWidth(LEFT_W - 28)
    npcChild:SetHeight(1)
    npcSF:SetScrollChild(npcChild)
    f.npcScroll      = npcSF
    f.npcScrollChild = npcChild

    -- -------------------------------------------------------
    -- Right panel: NPC info header + spell list
    -- -------------------------------------------------------
    local rightX = LEFT_W + 10
    local rightW = FRAME_W - LEFT_W - 18

    -- NPC info strip
    local infoStrip = CreateFrame("Frame", nil, f, "BackdropTemplate")
    infoStrip:SetPoint("TOPLEFT", rightX, CONTENT_Y)
    infoStrip:SetWidth(rightW)
    infoStrip:SetHeight(60)
    infoStrip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    infoStrip:SetBackdropColor(0.06, 0.06, 0.06, 0.7)
    infoStrip:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

    local infoModel = CreateFrame("PlayerModel", nil, infoStrip)
    infoModel:SetSize(56, 56)
    infoModel:SetPoint("LEFT", 4, 0)
    infoModel.lastDisplayID = nil
    infoStrip.model = infoModel
    f.modelFrame = infoModel

    local npcName = infoStrip:CreateFontString(nil, "OVERLAY")
    npcName:SetFont(Core.MAIN_FONT or STANDARD_TEXT_FONT, 16, "OUTLINE")
    npcName:SetPoint("TOPLEFT", 66, -10)
    npcName:SetText("")
    infoStrip.nameText = npcName

    local npcDetail = infoStrip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    npcDetail:SetPoint("TOPLEFT", 66, -30)
    npcDetail:SetText("")
    infoStrip.detailText = npcDetail

    f.npcInfo = infoStrip

    -- Mythic level slider (if MythicDamage module is loaded)
    if _G.InfinityMythicDamage and _G.InfinityMythicDamage.EX_DB then
        local sliderFrame = CreateFrame("Frame", nil, infoStrip)
        sliderFrame:SetSize(160, 40)
        sliderFrame:SetPoint("TOPRIGHT", -8, -10)

        local sliderLbl = sliderFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sliderLbl:SetPoint("TOP", 0, 0)
        sliderLbl:SetText(string.format("|cffffff00Level %d|r", _G.InfinityMythicDamage.EX_DB.mythicLevel or 10))

        local slider = CreateFrame("Slider", "RRTSpellGuideSlider", sliderFrame, "OptionsSliderTemplate")
        slider:SetPoint("TOP", 0, -14)
        slider:SetWidth(150)
        slider:SetMinMaxValues(0, 30)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(_G.InfinityMythicDamage.EX_DB.mythicLevel or 10)
        _G["RRTSpellGuideSliderLow"]:SetText("0")
        _G["RRTSpellGuideSliderHigh"]:SetText("30")
        _G["RRTSpellGuideSliderText"]:SetText("")

        slider:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val + 0.5)
            _G.InfinityMythicDamage.EX_DB.mythicLevel = val
            sliderLbl:SetText(string.format("|cffffff00Level %d|r", val))
            if currentDungeon and currentNPC then RefreshSpellPanel() end
        end)
        f.levelSlider     = slider
        f.levelSliderLabel = sliderLbl
    end

    -- Spell scroll frame
    local spellSF = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    spellSF:SetPoint("TOPLEFT", rightX, CONTENT_Y - 66)
    spellSF:SetPoint("BOTTOMRIGHT", -4, 4)
    local spellChild = CreateFrame("Frame", nil, spellSF)
    spellChild:SetWidth(rightW - 18)
    spellChild:SetHeight(1)
    spellSF:SetScrollChild(spellChild)
    f.spellScroll      = spellSF
    f.spellScrollChild = spellChild

    -- Expose refresh function
    f.RefreshSpells = RefreshSpellPanel

    f:Hide()
    mainFrame = f

    -- Auto-select first dungeon if we had one last session
    if DB.lastDungeon then
        local found = false
        for _, tab in ipairs(dungeonTabFrames) do
            if tab.dungeonName == DB.lastDungeon then
                SelectDungeon(DB.lastDungeon)
                found = true
                break
            end
        end
        if not found and #dungeonTabFrames > 0 then
            SelectDungeon(dungeonTabFrames[1].dungeonName)
        end
    elseif #dungeonTabFrames > 0 then
        SelectDungeon(dungeonTabFrames[1].dungeonName)
    end

    return f
end

-- ============================================================
-- Events
-- ============================================================

Core:RegisterEvent("SPELL_DATA_LOAD_RESULT", MODULE_KEY, function(_, spellID, success)
    if not success then return end
    if not mainFrame or not mainFrame:IsShown() then return end
    if not currentDungeon or not currentNPC then return end
    -- Check if this spell belongs to the displayed NPC
    local npcs = SpellData:GetNPCsForDungeon(currentDungeon)
    local data = npcs[currentNPC]
    if not data then return end
    for _, id in ipairs(data.spells or {}) do
        if id == spellID then
            RefreshSpellPanel()
            return
        end
    end
end)

-- ============================================================
-- Toggle function (called from slash command / options button)
-- ============================================================

local function Toggle()
    if not mainFrame then
        CreateMainFrame()
        -- Pre-request all spell data on first open
        SpellData:RequestAllSpellData()
    end
    if not mainFrame then return end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

-- ============================================================
-- Module export
-- ============================================================

RRT_NS.MythicSpellInfo = {
    Toggle         = Toggle,
    RefreshDisplay = function()
        if mainFrame and mainFrame:IsShown() then
            if currentDungeon then RefreshNpcList(currentDungeon) end
            RefreshSpellPanel()
        end
    end,
    ToggleWindow = Toggle, -- legacy alias
}

Core:ReportReady(MODULE_KEY)
