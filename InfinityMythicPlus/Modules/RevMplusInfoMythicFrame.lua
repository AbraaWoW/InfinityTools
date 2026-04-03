-- Comment translated to English
-- Comment translated to English

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local InfinityState = InfinityTools.State
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })
local addonVersion = ((C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("InfinityTools", "Version")) or "DEV-Build"):gsub("^v", "")

-- Comment translated to English
local INFINITY_MODULE_KEY = "RevMplusInfoMythicFrame"

-- Comment translated to English
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end



-- Comment translated to English
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 47, h = 2, label = L["Mythic Dashboard"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 47, h = 1, label = L["A full-screen immersive panel for Mythic+ analysis with live score, title-line gap, CN rank, Great Vault progress, and more."] },
        { key = "open", type = "button", x = 2, y = 6, w = 16, h = 3, label = L["Open Dashboard"] },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

-- Comment translated to English
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(data)
    if data.key == "open" then
        if SlashCmdList and SlashCmdList["EXMPLUS"] then SlashCmdList["EXMPLUS"]() end
    end
end)

-- Comment translated to English
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, {})



-- =========================================================
-- Comment translated to English
-- =========================================================
-- [[ PYTHON_DATA_START ]]
local RevMRH_PYTHON_DATA = {
    RankTable = {
        { label = "0.1%", score = 3364.00, count = 568 },
        { label = "1%", score = 3155.00, count = 5685 },
        { label = "10%", score = 2769.00, count = 56855 },
        { label = "25%", score = 2603.00, count = 142139 },
        { label = "40%", score = 2321.00, count = 227422 },
        { label = "50%", score = 2095.00, count = 284278 },
        { label = "60%", score = 1733.00, count = 341133 },
        { label = "70%", score = 1311.00, count = 397989 },
    },
    PopulationLabel = "EU",
    TotalPopulation = 568556,
    DataTime = "2026.04.02 06:49",
    Source = "Raider.IO Addon DB",
    InfinityVersion = "v26.4.3.1318",
}
-- [[ PYTHON_DATA_END ]]

local RevMRH_KeystoneAchievementList = {
    { 61253, 30 }, { 61252, 29 }, { 61251, 28 }, { 61250, 27 }, { 61249, 26 },
    { 61248, 25 }, { 61247, 24 }, { 61246, 23 }, { 61245, 22 }, { 61244, 21 },
    { 61243, 20 }, { 61242, 19 }, { 61241, 18 }, { 61240, 17 }, { 61239, 16 },
    { 61237, 15 }, { 61236, 14 }, { 61233, 12 }
}

-- =========================================================
-- Comment translated to English
-- =========================================================
local RevMRH                         = {}
local LSM                           = LibStub and LibStub("LibSharedMedia-3.0", true)
local SAFE_TEXT_FONT                = STANDARD_TEXT_FONT or InfinityTools.MAIN_FONT or MAIN_FONT

-- Comment translated to English
local DUNGEON_SHORT_NAMES           = {
    ["zhCN"] = {
        ["Eco-Dome Al'dani"] = "Eco-Dome",
        ["Ara-Kara, City of Echoes"] = "Echoes",
        ["Tazavesh, So'leah's Gambit"] = "Gambit",
        ["Tazavesh: Streets of Wonder"] = "Streets",
    },
    ["enUS"] = {
        ["The Underkeep"] = "Underkeep",
        ["Ara-Kara, City of Echoes"] = "Echoes",
        ["Tazavesh: So'leah's Gambit"] = "Gambit",
        ["Tazavesh: Streets of Wonder"] = "Streets",
    },
    ["frFR"] = {
        ["Dôme de l'Eco"] = "Eco-Dome",
        ["Ara-Kara, la cité des Échos"] = "Échos",
        ["Tazavesh : Le coup de So'leah"] = "Gambit",
        ["Tazavesh : les rues aux Merveilles"] = "Streets",
        ["La Sape"] = "Sape",
        ["Le Caveau Merektha"] = "Caveau",
        ["L'Opération Vannes ouvertes"] = "Vannes",
        ["Le Gardien du temps: Galakrond"] = "Galakrond",
        ["Le Gardien du temps: la chute de Murozond"] = "Murozond",
        ["Le Siège du triumvirat"] = "Siège",
        ["L'Orée-du-Ciel"] = "Orée",
        ["Les Cavernes de Matra"] = "Cavernes",
        ["La Flèche de Courvent"] = "Courvent",
        ["La Fosse de Saron"] = "Saron",
        ["L'Académie d'Algeth'ar"] = "Académie",
        ["La Terrasse des Magistères"] = "Terrasse",
        ["Le point-nexus Xy'exa"] = "Xy'exa",
    }
}

local function GetDungeonShortName(fullName)
    if not fullName then return "??" end
    local locale = GetLocale()
    local shortNames = DUNGEON_SHORT_NAMES[locale]
    if shortNames and shortNames[fullName] then
        return shortNames[fullName]
    end
    return fullName
end

local INFINITY_THEME            = {
-- Comment translated to English
    Background  = { 0.08, 0.08, 0.1, 0.98 },
-- Comment translated to English
    Surface     = { 1, 1, 1, 0.08 },
-- Comment translated to English
    DungeonName = { 0.78, 0.78, 0.78, 1 },
    Border      = { 1, 1, 1, 0.25 },
    Primary     = { 0.733, 0.4, 1.0 },
    TextMain    = { 1, 1, 1, 1 },
    TextSub     = { 0.7, 0.7, 0.75, 1 },
    Success     = { 0.13, 0.77, 0.37, 1 },
    Danger      = { 0.94, 0.27, 0.27, 1 },
    Gold        = { 1, 0.82, 0, 1 },
}

local MAIN_FONT               = InfinityTools.MAIN_FONT or STANDARD_TEXT_FONT

-- Comment translated to English
RevMRH.CustomWidth             = 1200
-- Comment translated to English
RevMRH.CustomHeight            = 720

local INFINITY_BACKDROP_ROUNDED = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

function RevMRH.GetClassColor()
    local _, classFile = UnitClass("player")
    local color = C_ClassColor.GetClassColor(classFile)
    return color or { r = 1, g = 1, b = 1, a = 1 }
end

local function RevMRH_GetHexColor(color)
    if not color then return "ffffffff" end
    return string.format("ff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
end


-- Comment translated to English
function RevMRH.GetTalentData()
    local data = { specIcon = nil, specName = " ", heroName = " " }
    local specIndex = GetSpecialization()
    if specIndex then
        local specID, name = GetSpecializationInfo(specIndex)
        if specID then
            local _, _, _, specIcon = GetSpecializationInfoForSpecID(specID)
            data.specIcon = specIcon
            data.specName = name
        end
    end
    local heroSubTreeID = C_ClassTalents.GetActiveHeroTalentSpec()
    local configID = C_ClassTalents.GetActiveConfigID()
    if heroSubTreeID and configID then
        local heroInfo = C_Traits.GetSubTreeInfo(configID, heroSubTreeID)
        if heroInfo then data.heroName = heroInfo.name end
    end
    return data
end

function RevMRH.GetLootInfo(level)
    local rewardIlvl = C_MythicPlus.GetRewardLevelFromKeystoneLevel(level)
    if not rewardIlvl or rewardIlvl == 0 then return "-", L["No Reward"], 0 end
    local lootMap = {
        [259] = { name = L["Hero 1/6"], star = 0 },
        [263] = { name = L["Hero 2/6"], star = 0 },
        [266] = { name = L["Hero 3/6"], star = 0 },
        [269] = { name = L["Hero 4/6"], star = 0 },
        [272] = { name = L["Myth 1/6"], star = 1 },
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
    }
    local data = lootMap[rewardIlvl]
    if data then return rewardIlvl, data.name, data.star else return rewardIlvl, L["Unknown Track"], 0 end
end

-- Comment translated to English
function RevMRH.CalculateRank(score)
    local tableData = RevMRH_PYTHON_DATA.RankTable
    local totalPop = RevMRH_PYTHON_DATA.TotalPopulation

-- Comment translated to English
    if score >= tableData[1].score then
        return tableData[1].label:gsub("%%", ""), tableData[1].count, 100, nil
    end

-- Comment translated to English
    for i = 1, #tableData - 1 do
        local high = tableData[i]
        local low = tableData[i + 1]

        if score <= high.score and score >= low.score then
            local ratio = (score - low.score) / (high.score - low.score)
            local highPct = tonumber((high.label:gsub("%%", "")))
            local lowPct = tonumber((low.label:gsub("%%", "")))
            local currentPct = lowPct - (lowPct - highPct) * ratio
            local currentRank = math.floor(low.count - (low.count - high.count) * ratio)

            return string.format("%.2f", currentPct), currentRank, ratio * 100, high
        end
    end

-- Comment translated to English
    return "100.00", totalPop, 0, nil
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevMRH.CreateStandaloneFrame()
    if _G["RevMRH_MainFrame"] then return end

    local f = CreateFrame("Frame", "RevMRH_MainFrame", UIParent, "BackdropTemplate")
    f:SetSize(RevMRH.CustomWidth, RevMRH.CustomHeight)
    f:SetPoint("CENTER", 0, 0); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop",
        f.StopMovingOrSizing)

-- Comment translated to English
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(50)

    f:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
    f:SetBackdropColor(unpack(INFINITY_THEME.Background))
    f:SetBackdropBorderColor(0, 0, 0, 0.8)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    do
        local nTex = closeBtn:GetNormalTexture()
        if nTex then nTex:SetVertexColor(1, 0.15, 0.15, 1) end
        local hTex = closeBtn:GetHighlightTexture()
        if hTex then hTex:SetVertexColor(1, 0.4, 0.4, 1) end
        local pTex = closeBtn:GetPushedTexture()
        if pTex then pTex:SetVertexColor(0.7, 0.05, 0.05, 1) end
    end

    -- Sync Primary color with RRT UI Appearance
    _G.RRT = _G.RRT or {}
    _G.RRT.GlobalThemeCallbacks = _G.RRT.GlobalThemeCallbacks or {}
    table.insert(_G.RRT.GlobalThemeCallbacks, function(r, g, b)
        INFINITY_THEME.Primary[1] = r
        INFINITY_THEME.Primary[2] = g
        INFINITY_THEME.Primary[3] = b
    end)

    tinsert(UISpecialFrames, "RevMRH_MainFrame")
    RevMRH.Main = CreateFrame("Frame", nil, f); RevMRH.Main:SetAllPoints()

    local footer = CreateFrame("Frame", "INFINITY_Footer", f, "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", 20, 20); footer:SetPoint("BOTTOMRIGHT", -20, 20); footer:SetHeight(50)
    footer:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
    footer:SetBackdropColor(1, 1, 1, 0.04); footer:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))

    local function CreateFootBtn(name, xOfs)
        local btn = CreateFrame("Button", nil, footer, "BackdropTemplate")
        btn:SetSize(170, 32); btn:SetPoint("RIGHT", xOfs, 0)
        btn:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
        btn:SetBackdropColor(1, 1, 1, 0.08); btn:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))
        local t = btn:CreateFontString(nil, "OVERLAY")
        t:SetFont(MAIN_FONT, 13, "THINOUTLINE"); t:SetPoint("CENTER"); t:SetText(name); t:SetTextColor(unpack(
            INFINITY_THEME
            .TextMain))
        btn:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 1, 1, 0.15) end)
        btn:SetScript("OnLeave", function(self) self:SetBackdropColor(1, 1, 1, 0.08) end)
        return btn
    end

-- Comment translated to English
    RevMRH.BtnHistory = CreateFootBtn(L["Season Run History"], -185)
    RevMRH.BtnHistory:SetScript("OnClick", function()
        if _G.EXMYRUN and _G.EXMYRUN.ToggleWindow then
            _G.EXMYRUN:ToggleWindow()
        elseif SlashCmdList and SlashCmdList["EXMYRUN"] then
            SlashCmdList["EXMYRUN"]()
        end
    end)

    RevMRH.BtnStats = CreateFootBtn(L["Advanced Analytics (Soon)"], -10)

    local versionText = footer:CreateFontString(nil, "OVERLAY")
    versionText:SetFont(SAFE_TEXT_FONT, 14, "THINOUTLINE"); versionText:SetPoint("LEFT", 20, 0); versionText:SetTextColor(
        unpack(
            INFINITY_THEME.TextSub))
    -- Compact English formatting for population counts
    local pop = tonumber(RevMRH_PYTHON_DATA.TotalPopulation) or 0
    local formattedPop = pop >= 1000 and string.format("%.1fk", pop / 1000) or tostring(pop)

-- Comment translated to English
    local populationLabel = tostring(RevMRH_PYTHON_DATA.PopulationLabel or "Tracked")
    versionText:SetText(string.format(L["INFINITY Mythic Dashboard %s  |  Title data updated: %s  |  %s player count: %s"],
        addonVersion, RevMRH_PYTHON_DATA.DataTime, populationLabel, formattedPop))

    RevMRH.InitSubPanels()
    f:Hide()
    SlashCmdList["EXMPLUS"] = function()
        if f:IsShown() then
            f:Hide()
        else
            f:Show(); RevMRH.UpdateAllData()
        end
    end
    SLASH_EXMPLUS1 = "/exm"
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevMRH.InitHeader()
    local header = CreateFrame("Frame", "INFINITY_Header", RevMRH.Main, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 20, -20); header:SetPoint("TOPRIGHT", -20, -20); header:SetHeight(150)
    header:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
    header:SetBackdropColor(1, 1, 1, 0.06); header:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))

    local classColor = RevMRH.GetClassColor()
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
-- Comment translated to English
    local portraitFrame = CreateFrame("Frame", "INFINITY_AvatarBox", header, "BackdropTemplate")
    portraitFrame:SetSize(120, 120); portraitFrame:SetPoint("LEFT", 17, 0)
    portraitFrame:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14, tile = true })
    RevMRH.AvatarFrame = portraitFrame

-- Comment translated to English
    local model = CreateFrame("PlayerModel", nil, portraitFrame)
    model:SetPoint("TOPLEFT", 4, -4); model:SetPoint("BOTTOMRIGHT", -4, 4)
    model:SetUnit("player")
    model:SetPortraitZoom(0.9) -- Comment translated to English
    model:SetAlpha(0.95); RevMRH.PlayerModel = model

-- Comment translated to English
    local ilvlFrame = CreateFrame("Frame", nil, portraitFrame, "BackdropTemplate")
    ilvlFrame:SetSize(58, 26); ilvlFrame:SetPoint("BOTTOMRIGHT", portraitFrame, "BOTTOMRIGHT", 6, -6)
    ilvlFrame:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
    ilvlFrame:SetBackdropColor(0, 0, 0, 0.95)
    ilvlFrame:SetFrameLevel(portraitFrame:GetFrameLevel() + 25)
    RevMRH.IlvlFrame = ilvlFrame

    local ilvlStr = ilvlFrame:CreateFontString(nil, "OVERLAY")
    ilvlStr:SetFont(MAIN_FONT, 16, "THINOUTLINE"); ilvlStr:SetPoint("CENTER", 0, 0); ilvlStr:SetTextColor(1, 1, 1)
    RevMRH.IlvlDisplay = ilvlStr
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
-- Comment translated to English
    local specIcon = header:CreateTexture(nil, "OVERLAY")
-- Comment translated to English
    specIcon:SetSize(50, 50); specIcon:SetPoint("LEFT", portraitFrame, "RIGHT", 20, 26)
    specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
    RevMRH.SpecIcon = specIcon

-- Comment translated to English
    local nameStr = header:CreateFontString(nil, "OVERLAY")
-- Comment translated to English
    nameStr:SetFont(SAFE_TEXT_FONT, 42, "THINOUTLINE"); nameStr:SetPoint("LEFT", specIcon, "RIGHT", 5, -8)
    RevMRH.NameStr = nameStr

-- Comment translated to English
    local infoStr = header:CreateFontString(nil, "OVERLAY")
-- Comment translated to English
    infoStr:SetFont(SAFE_TEXT_FONT, 17, "THINOUTLINE"); infoStr:SetPoint("TOPLEFT", specIcon, "BOTTOMLEFT", 0, -8)
    infoStr:SetTextColor(unpack(INFINITY_THEME.TextMain)); RevMRH.PlayerInfoDisplay = infoStr

-- Comment translated to English
    local function CreateTrinketFrame(xOfs)
        local btn = CreateFrame("Button", nil, header, "BackdropTemplate")
-- Comment translated to English
        btn:SetSize(142, 30); btn:SetPoint("TOPLEFT", infoStr, "BOTTOMLEFT", xOfs, -5)
        btn:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
        btn:SetBackdropColor(0, 0, 0, 0.5); btn:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))

        local ic = btn:CreateTexture(nil, "OVERLAY"); ic:SetSize(22, 22); ic:SetPoint("LEFT", 4, 0.5)
        ic:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
        local tx = btn:CreateFontString(nil, "OVERLAY")
        tx:SetFont(SAFE_TEXT_FONT, 13, "THINOUTLINE"); tx:SetPoint("LEFT", ic, "RIGHT", 3, 0)
        tx:SetWidth(120); tx:SetJustifyH("LEFT"); tx:SetWordWrap(false)

        btn:SetScript("OnEnter",
            function(self)
                if self.itemID then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetHyperlink(self.itemID); GameTooltip:Show()
                end
            end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn, ic, tx
    end
    RevMRH.T1, RevMRH.T1I, RevMRH.T1T = CreateTrinketFrame(-2); RevMRH.T1.slotID = 13
    RevMRH.T2, RevMRH.T2I, RevMRH.T2T = CreateTrinketFrame(138); RevMRH.T2.slotID = 14
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
-- Comment translated to English
    local scoreGroup = CreateFrame("Frame", nil, header); scoreGroup:SetSize(300, 100)
    scoreGroup:SetPoint("CENTER", 40, -18)

    local sLabel = scoreGroup:CreateFontString(nil, "OVERLAY")
-- Comment translated to English
    sLabel:SetFont(MAIN_FONT, 18, "THINOUTLINE"); sLabel:SetPoint("TOPLEFT", 0, 23); sLabel:SetTextColor(unpack(
        INFINITY_THEME
        .TextSub)); sLabel:SetText(L["SEASON SCORE"])
-- Comment translated to English
    RevMRH.ScoreText = scoreGroup:CreateFontString(nil, "OVERLAY")
    RevMRH.ScoreText:SetFont(MAIN_FONT, 72, "THICKOUTLINE"); RevMRH.ScoreText:SetPoint("TOPLEFT", sLabel, "BOTTOMLEFT", 18,
        -6)
-- Comment translated to English
    RevMRH.PctText = scoreGroup:CreateFontString(nil, "OVERLAY")
    RevMRH.PctText:SetFont(MAIN_FONT, 18, "OUTLINE"); RevMRH.PctText:SetPoint("TOPLEFT", RevMRH.ScoreText, "BOTTOMLEFT",
        -20, -2)
    RevMRH.PctText:SetTextColor(unpack(INFINITY_THEME.Success))
-- Comment translated to English
    RevMRH.RankNumText = scoreGroup:CreateFontString(nil, "OVERLAY")
    RevMRH.RankNumText:SetFont(MAIN_FONT, 16, "OUTLINE"); RevMRH.RankNumText:SetPoint("TOPRIGHT", RevMRH.ScoreText,
        "BOTTOMRIGHT", 20, -2)
    RevMRH.RankNumText:SetTextColor(unpack(INFINITY_THEME.TextSub))

    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
-- Comment translated to English
    local barGroup = CreateFrame("Frame", nil, header);
-- Comment translated to English
    barGroup:SetSize(260, 110); barGroup:SetPoint("CENTER", 275, -2)

    RevMRH.NextRankText = barGroup:CreateFontString(nil, "OVERLAY")
-- Comment translated to English
    RevMRH.NextRankText:SetFont(MAIN_FONT, 18, "OUTLINE");
    RevMRH.NextRankText:SetPoint("TOPLEFT", 0, -2);
    RevMRH.NextRankText:SetTextColor(unpack(INFINITY_THEME.Gold))

-- Comment translated to English
    local barBG = CreateFrame("Frame", nil, barGroup, "BackdropTemplate")
    barBG:SetSize(270, 30);
    barBG:SetPoint("TOPLEFT", 0, -28);
    barBG:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
    barBG:SetBackdropColor(0, 0, 0, 0.6);
    barBG:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))

-- Comment translated to English
    RevMRH.RankBar = CreateFrame("StatusBar", nil, barBG);
-- Comment translated to English
    RevMRH.RankBar:SetPoint("TOPLEFT", barBG, "TOPLEFT", 5, -5)
    RevMRH.RankBar:SetPoint("BOTTOMRIGHT", barBG, "BOTTOMRIGHT", -2, 5)

-- Comment translated to English
    RevMRH.RankBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local INFINITY_BarTex = RevMRH.RankBar:GetStatusBarTexture()
    INFINITY_BarTex:SetHorizTile(false)
    INFINITY_BarTex:SetVertTile(false)
-- Comment translated to English
    RevMRH.RankBarText = RevMRH.RankBar:CreateFontString(nil, "OVERLAY");
    RevMRH.RankBarText:SetFont(MAIN_FONT, 14, "OUTLINE");
    RevMRH.RankBarText:SetPoint("CENTER")

-- Comment translated to English
    RevMRH.TitleLineText = barGroup:CreateFontString(nil, "OVERLAY")
    RevMRH.TitleLineText:SetFont(MAIN_FONT, 14, "OUTLINE");
    RevMRH.TitleLineText:SetPoint("TOPLEFT", barBG, "BOTTOMLEFT", 0, -6);
    RevMRH.TitleLineText:SetTextColor(1, 0.92, 0.22)

    local function CreateCrestFrame(id, xOfs)
        local cF = CreateFrame("Frame", nil, barGroup, "BackdropTemplate")
        cF:SetSize(130, 30);
        cF:SetPoint("TOPLEFT", RevMRH.TitleLineText, "BOTTOMLEFT", xOfs, -5)
        cF:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
        cF:SetBackdropColor(0, 0, 0, 0.5);
        cF:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))
-- Comment translated to English
        local ic = cF:CreateTexture(nil, "OVERLAY");
        ic:SetSize(25, 25);
        ic:SetPoint("LEFT", 5, 0)
        ic:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
-- Comment translated to English
        local tx = cF:CreateFontString(nil, "OVERLAY");
        tx:SetFont(MAIN_FONT, 15, "THINOUTLINE");
        tx:SetPoint("CENTER", cF, "CENTER", 5, 0)

        cF:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetCurrencyByID(id);
            GameTooltip:Show()
        end)
        cF:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return ic, tx
    end
-- Comment translated to English
    RevMRH.C1I, RevMRH.C1T = CreateCrestFrame(3345, 0);
    RevMRH.C2I, RevMRH.C2T = CreateCrestFrame(3347, 140)
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
-- Comment translated to English
    RevMRH.MaxKeyCard = InfinityFactory:Acquire("IconTextCard", header)
    RevMRH.MaxKeyCard:SetPoint("TOPRIGHT", -10, -5)
    RevMRH.MaxKeyCard.icon:SetTexture([[Interface\AddOns\InfinityTools\InfinityMythicPlus\Textures\EJ-UI\M1.png]])
    RevMRH.MaxKeyCard.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
    RevMRH.MaxKeyCard.title:SetFont(MAIN_FONT, 15, "OUTLINE")
    RevMRH.MaxKeyCard.title:SetTextColor(0.76, 0.76, 0.76)
    RevMRH.MaxKeyCard.title:SetText(L["Highest Key"])
    RevMRH.MaxKeyCard.value:SetFont(MAIN_FONT, 32, "THINOUTLINE")
    RevMRH.MaxKeyCard.value:SetTextColor(unpack(INFINITY_THEME.TextMain))
    RevMRH.MaxKeyText = RevMRH.MaxKeyCard.value

    RevMRH.TotalRunsCard = InfinityFactory:Acquire("IconTextCard", header)
    RevMRH.TotalRunsCard:SetPoint("TOPRIGHT", -10, -75)
    RevMRH.TotalRunsCard.icon:SetTexture([[Interface\AddOns\InfinityTools\InfinityMythicPlus\Textures\EJ-UI\M2.png]])
    RevMRH.TotalRunsCard.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
    RevMRH.TotalRunsCard.title:SetFont(MAIN_FONT, 15, "OUTLINE")
    RevMRH.TotalRunsCard.title:SetTextColor(0.76, 0.76, 0.76)
    RevMRH.TotalRunsCard.title:SetText(L["Season Total"])
    RevMRH.TotalRunsCard.value:SetFont(MAIN_FONT, 32, "THINOUTLINE")
    RevMRH.TotalRunsCard.value:SetTextColor(unpack(INFINITY_THEME.TextMain))
    RevMRH.TotalRunsText = RevMRH.TotalRunsCard.value
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevMRH.InitStatTable()
    local tableFrame = CreateFrame("Frame", "INFINITY_TableBox", RevMRH.Main, "BackdropTemplate")
    --@@
    tableFrame:SetPoint("TOPLEFT", 20, -185); tableFrame:SetPoint("BOTTOMLEFT", 20, 85); tableFrame:SetWidth(816)
    tableFrame:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
    tableFrame:SetBackdropColor(0, 0, 0, 0); -- Comment translated to English
    tableFrame:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))
-- Comment translated to English
    tableFrame:SetFrameLevel(RevMRH.Main:GetFrameLevel() + 10)

    local header = CreateFrame("Frame", nil, tableFrame, "BackdropTemplate");
    header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1);
    header:SetHeight(54)
-- Comment translated to English
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    header:SetBackdropColor(1, 1, 1, 0.05)
    header:SetBackdropBorderColor(0, 0, 0, 0)
    header:SetFrameLevel(tableFrame:GetFrameLevel() - 1)

    local function ColLabel(txt, x, y, w, justify, fontSize)
        local fs = header:CreateFontString(nil, "OVERLAY")
        fs:SetFont(SAFE_TEXT_FONT, fontSize or 14, "OUTLINE"); fs:SetPoint("LEFT", x, y or 0); fs:SetWidth(w); fs:SetJustifyH(justify or
            "CENTER")
        fs:SetText(txt); fs:SetTextColor(unpack(INFINITY_THEME.TextSub))
        return fs
    end
    --@@ Header rows
    ColLabel(L["Dungeon"], 60, 10, 125, "LEFT", 14)
    ColLabel(L["Best"], 190, 10, 52, "CENTER", 14)
    ColLabel(L["Score"], 248, 10, 64, "CENTER", 14)
    ColLabel(L["Season"], 346, 12, 164, "CENTER", 15)
    ColLabel(L["Week"], 571, 12, 164, "CENTER", 15)
    ColLabel(L["Total"], 346, -12, 44, "CENTER", 13)
    ColLabel(L["Timed"], 403, -12, 44, "CENTER", 13)
    ColLabel(L["Over"], 460, -12, 44, "CENTER", 13)
    ColLabel(L["Total"], 571, -12, 44, "CENTER", 13)
    ColLabel(L["Timed"], 628, -12, 44, "CENTER", 13)
    ColLabel(L["Over"], 685, -12, 44, "CENTER", 13)

    RevMRH.StatRows = {}
    for i = 1, 9 do
        local r = InfinityFactory:Acquire("StatRow", tableFrame)
        r:SetSize(807.5, 45)

        if i == 9 then
            r:SetPoint("TOPLEFT", 4, -51.3 - 8 * 45)
-- Comment translated to English
            if not r.SummaryBG then
                r.SummaryBG = CreateFrame("Frame", nil, r, "BackdropTemplate")
-- Comment translated to English
                r.SummaryBG:SetPoint("TOPLEFT", r, "TOPLEFT", -3, 5)
                r.SummaryBG:SetPoint("BOTTOMRIGHT", tableFrame, "BOTTOMRIGHT", -1, 1)
                r.SummaryBG:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    edgeSize = 14,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 }
                })
                r.SummaryBG:SetBackdropBorderColor(0, 0, 0, 0) -- Comment translated to English
                r.SummaryBG:SetFrameLevel(tableFrame:GetFrameLevel() - 2) -- Comment translated to English

-- Comment translated to English
                local bgTex = r.SummaryBG.Center
                if bgTex then
                    bgTex:SetGradient("HORIZONTAL", CreateColor(0.05, 0.15, 0.3, 0.6), CreateColor(0.02, 0.05, 0.1, 0.1))
                end

-- Comment translated to English
                r.TopLine = r.SummaryBG:CreateTexture(nil, "OVERLAY")
                r.TopLine:SetHeight(1)
                r.TopLine:SetPoint("TOPLEFT", 10, -5)
                r.TopLine:SetPoint("TOPRIGHT", -10, -5)
                r.TopLine:SetColorTexture(1, 1, 1, 0.2)
            end
            r.bg:Hide() -- Comment translated to English
        else
            r:SetPoint("TOPLEFT", 4, -51.3 - (i - 1) * 45)
            r.bg:SetColorTexture(1, 1, 1, (i % 2 == 0 and 0.025 or 0))
-- Comment translated to English
            r.bg:ClearAllPoints()
            r.bg:SetPoint("TOPLEFT", r, "TOPLEFT", 4, 0)
            r.bg:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -4, 0)
        end

-- Comment translated to English
        r.name:SetFont(SAFE_TEXT_FONT, 17, "THICKOUTLINE")
        r.name:SetTextColor(unpack(INFINITY_THEME.DungeonName))
        r.name:SetWidth(118)
        r.name:SetJustifyH("LEFT")
        r.name:SetWordWrap(false)

-- Comment translated to English
        r.max = r.cells[1]
        r.max:SetFont(SAFE_TEXT_FONT, 16, "THINOUTLINE")
        r.max:SetPoint("LEFT", 186, 0); r.max:SetWidth(54); r.max:SetJustifyH("CENTER")

-- Comment translated to English
        r.pts = r.cells[2]
        r.pts:SetFont(SAFE_TEXT_FONT, 16, "THINOUTLINE")
        r.pts:SetPoint("LEFT", 245, 0); r.pts:SetWidth(62); r.pts:SetJustifyH("CENTER")

        local function SetupStatGroup(startIdx, x)
            local t = r.cells[startIdx]
            t:SetFont(SAFE_TEXT_FONT, 16, "THINOUTLINE"); t:SetPoint("LEFT", x + 16, 0); t:SetWidth(40); t:SetJustifyH("CENTER"); t:SetTextColor(unpack(INFINITY_THEME
                .TextMain))

            local l = r.cells[startIdx + 1]
            l:SetFont(SAFE_TEXT_FONT, 16, "THINOUTLINE"); l:SetPoint("LEFT", x + 73, 0); l:SetWidth(40); l:SetJustifyH("CENTER"); l:SetTextColor(unpack(INFINITY_THEME
                .Success))

            local o = r.cells[startIdx + 2]
            o:SetFont(SAFE_TEXT_FONT, 16, "THINOUTLINE"); o:SetPoint("LEFT", x + 130, 0); o:SetWidth(40); o:SetJustifyH("CENTER"); o:SetTextColor(unpack(INFINITY_THEME
                .Danger))

            return t, l, o
        end

        r.s_total, r.s_timed, r.s_over = SetupStatGroup(3, 330)
        r.w_total, r.w_timed, r.w_over = SetupStatGroup(6, 555)

        RevMRH.StatRows[i] = r
    end
end

-- =========================================================
-- Comment translated to English
-- =========================================================
function RevMRH.InitRightPanel()
    local rf = CreateFrame("Frame", "INFINITY_RightSide", RevMRH.Main, "BackdropTemplate")
-- Comment translated to English
    rf:SetPoint("TOPRIGHT", -20, -185); rf:SetPoint("BOTTOMRIGHT", -20, 85); rf:SetWidth(330)
    rf:SetBackdrop(INFINITY_BACKDROP_ROUNDED)
    rf:SetBackdropColor(unpack(INFINITY_THEME.Surface)); rf:SetBackdropBorderColor(unpack(INFINITY_THEME.Border))
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
    RevMRH.Slots = {}
-- Comment translated to English
    local sw = (330 - 40) / 3
    for i = 1, 3 do
        local s = CreateFrame("Frame", nil, rf, "BackdropTemplate")
-- Comment translated to English
        s:SetSize(sw, 70); s:SetPoint("TOPLEFT", 15 + (i - 1) * (sw + 5), -15)
-- Comment translated to English
        s:SetBackdrop(INFINITY_BACKDROP_ROUNDED); s:SetBackdropColor(1, 1, 1, 0.06); s:SetBackdropBorderColor(unpack(
            INFINITY_THEME.Border))
-- Comment translated to English
        s.ilvl = s:CreateFontString(nil, "OVERLAY"); s.ilvl:SetFont(MAIN_FONT, 24, "OUTLINE"); s.ilvl:SetPoint(
            "CENTER", 0, 6); s.ilvl:SetTextColor(0.64, 0.21, 0.93, 1)
-- Comment translated to English
        s.rank = s:CreateFontString(nil, "OVERLAY"); s.rank:SetFont(MAIN_FONT, 14, "THINOUTLINE"); s.rank:SetPoint(
            "BOTTOM",
            0, 10); s.rank:SetTextColor(1, 0.5, 0, 1)
        RevMRH.Slots[i] = s
    end

    local hLabel = rf:CreateFontString(nil, "OVERLAY"); hLabel:SetFont(MAIN_FONT, 12, "THINOUTLINE"); hLabel:SetPoint(
        "TOPLEFT", 15, -100); hLabel:SetTextColor(unpack(INFINITY_THEME.TextSub)); hLabel:SetText(L["This Week's M+ Runs (Top 8)"])
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
    RevMRH.RunRows = {}
    for i = 1, 8 do
        local r = InfinityFactory:Acquire("RunRow", rf)
        r:SetSize(299, 40); r:SetPoint("TOPLEFT", 17, -120 - (i - 1) * 38)
        r:SetBackdropColor(1, 1, 1, 0.03)

        if i == 1 or i == 4 or i == 8 then
            if not r.HighlightBG then
                r.HighlightBG = r:CreateTexture(nil, "BACKGROUND")
                r.HighlightBG:SetPoint("TOPLEFT", 3, -3); r.HighlightBG:SetPoint("BOTTOMRIGHT", -3, 3)
                r.HighlightBG:SetColorTexture(1, 1, 1, 0.12)
            end
            r.HighlightBG:Hide()
        end

        r.text:SetFont(SAFE_TEXT_FONT, 14, "OUTLINE")
        r.text:SetWidth(205); r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
        r.ilvl:SetFont(SAFE_TEXT_FONT, 14, "THINOUTLINE")
        r.ilvl:SetTextColor(0.64, 0.21, 0.93, 1)

        RevMRH.RunRows[i] = r
    end
end

-- =========================================================
-- Comment translated to English
-- =========================================================
local function FormatRank(n)
    if not n or n == 0 then return "-" end
    if n >= 10000 then return string.format("%.1fW", n / 10000) else return tostring(n) end
end

function RevMRH.UpdateAllData()
    if not _G["RevMRH_MainFrame"] or not _G["RevMRH_MainFrame"]:IsShown() then return end

    local score = C_ChallengeMode.GetOverallDungeonScore() or 0
    local scoreColor = C_ChallengeMode.GetDungeonScoreRarityColor(score)

-- Comment translated to English
    RevMRH.ScoreText:SetFont(MAIN_FONT, 72, "THICKOUTLINE")
    RevMRH.ScoreText:SetText(score);
    if scoreColor then
        RevMRH.ScoreText:SetTextColor(scoreColor.r, scoreColor.g, scoreColor.b)
    end

    local classCol = RevMRH.GetClassColor()
-- Comment translated to English
    RevMRH.NameStr:SetText(UnitName("player"))
    RevMRH.NameStr:SetTextColor(classCol.r, classCol.g, classCol.b)
    RevMRH.AvatarFrame:SetBackdropBorderColor(classCol.r, classCol.g, classCol.b, 1)
    RevMRH.IlvlFrame:SetBackdropBorderColor(classCol.r, classCol.g, classCol.b, 1)

    local tal = RevMRH.GetTalentData(); if tal.specIcon then RevMRH.SpecIcon:SetTexture(tal.specIcon) end
    local raceName = UnitRace("player")
    local heroPart = (tal.heroName and tal.heroName ~= " ") and string.format(" - |cFFFFD100%s|r", tal.heroName) or ""
    RevMRH.PlayerInfoDisplay:SetText(string.format("%s - %s%s", raceName or L["Unknown Race"], tal.specName or "", heroPart))

    local _, eq = GetAverageItemLevel(); RevMRH.IlvlDisplay:SetText(string.format("%.1f", eq))

-- Comment translated to English
    local function UpdateItem(slotID, ic, tx, btn)
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local itemName, _, quality, _, _, _, _, _, _, itemTexture = GetItemInfo(link)
            if itemName then
                tx:SetText(itemName)
                local r, g, b = GetItemQualityColor(quality or 4)
                tx:SetTextColor(r, g, b)
                ic:SetTexture(itemTexture)
            else
                tx:SetText(L["Loading..."])
                tx:SetTextColor(0.5, 0.5, 0.5)
            end
            btn.itemID = link
        else
            ic:SetTexture(nil); tx:SetText(L["Unequipped"]); tx:SetTextColor(0.5, 0.5, 0.5); btn.itemID = nil
        end
    end
    UpdateItem(13, RevMRH.T1I, RevMRH.T1T, RevMRH.T1); UpdateItem(14, RevMRH.T2I, RevMRH.T2T, RevMRH.T2)

    local summary = { s_tot = 0, s_tim = 0, s_ovr = 0, w_tot = 0, w_tim = 0, w_ovr = 0, minMax = 99 }
    local sRuns = C_MythicPlus.GetRunHistory(true, true, true)
    local wRuns = C_MythicPlus.GetRunHistory(false, true, true)

    local dData = {}
    local function Process(runs, prefix)
        if not runs then return end
        for _, r in ipairs(runs) do
            local _, _, tl = C_ChallengeMode.GetMapUIInfo(r.mapChallengeModeID)
            local isT = (r.durationSec > 0 and tl and tl > 0 and r.durationSec <= tl)
            if not dData[r.mapChallengeModeID] then dData[r.mapChallengeModeID] = { s_tot = 0, s_tim = 0, s_ovr = 0, w_tot = 0, w_tim = 0, w_ovr = 0 } end
            local d = dData[r.mapChallengeModeID]; d[prefix .. "_tot"] = d[prefix .. "_tot"] + 1; summary[prefix .. "_tot"] =
                summary[prefix .. "_tot"] + 1
            if isT then
                d[prefix .. "_tim"] = d[prefix .. "_tim"] + 1; summary[prefix .. "_tim"] = summary[prefix .. "_tim"] + 1
            else
                d[prefix .. "_ovr"] = d[prefix .. "_ovr"] + 1; summary[prefix .. "_ovr"] = summary[prefix .. "_ovr"] + 1
            end
        end
    end
    Process(sRuns, "s"); Process(wRuns, "w")
    RevMRH.TotalRunsText:SetText(summary.s_tot)

    local mT = C_ChallengeMode.GetMapTable()
    if mT then
        for i, mID in ipairs(mT) do
            if RevMRH.StatRows[i] then
                local n, _, _, tex = C_ChallengeMode.GetMapUIInfo(mID); local d = dData[mID] or
                    { s_tot = 0, s_tim = 0, s_ovr = 0, w_tot = 0, w_tim = 0, w_ovr = 0 }
                local inT, overT = C_MythicPlus.GetSeasonBestForMap(mID); local bD = inT or overT
                local ms, ml = bD and bD.dungeonScore or 0, bD and bD.level or 0
                if ml < summary.minMax then summary.minMax = ml end
                local r = RevMRH.StatRows[i]
                local lCol = C_ChallengeMode.GetKeystoneLevelRarityColor(ml); local sCol = C_ChallengeMode
                    .GetSpecificDungeonScoreRarityColor(ms)
                r.icon:SetTexture(tex);
                r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
                r.name:SetText(GetDungeonShortName(n)); r.max:SetText("+" .. ml); r.pts:SetText(ms)
                if lCol then r.max:SetTextColor(lCol.r, lCol.g, lCol.b) end; if sCol then
                    r.pts:SetTextColor(sCol.r,
                        sCol.g, sCol.b)
                end
                r.s_total:SetText(d.s_tot); r.s_timed:SetText(d.s_tim); r.s_over:SetText(d.s_ovr)
                r.w_total:SetText(d.w_tot); r.w_timed:SetText(d.w_tim); r.w_over:SetText(d.w_ovr)
            end
        end
        local rowSum = RevMRH.StatRows[9]; rowSum.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09");
        rowSum.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
        rowSum.name:SetText("|cff00d9ff" .. L["Summary"] .. "|r")
        rowSum.name:SetFont(SAFE_TEXT_FONT, 17, "THICKOUTLINE")
        rowSum.max:SetText(summary.minMax == 99 and "0" or summary.minMax); rowSum.pts:SetText("-")
        rowSum.s_total:SetText(summary.s_tot); rowSum.s_timed:SetText(summary.s_tim); rowSum.s_over:SetText(summary
            .s_ovr)
        rowSum.w_total:SetText(summary.w_tot); rowSum.w_timed:SetText(summary.w_tim); rowSum.w_over:SetText(summary
            .w_ovr)
    end
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
-- Comment translated to English
    local pct, rk, _, _ = RevMRH.CalculateRank(score)
    RevMRH.PctText:SetText(string.format(L["Top %s%%"], pct))
    RevMRH.RankNumText:SetText(string.format(L["Rank %s"], FormatRank(rk)))

-- Comment translated to English
    local INFINITY_Milestones = { "50%", "25%", "10%", "1%", "0.1%" }
    local INFINITY_NextTarget = nil
    local currentPctNum = tonumber(pct) or 100

-- Comment translated to English
    for _, label in ipairs(INFINITY_Milestones) do
        local milestonePct = tonumber((label:gsub("%%", "")))
        if currentPctNum > milestonePct then
-- Comment translated to English
            for _, entry in ipairs(RevMRH_PYTHON_DATA.RankTable) do
                if entry.label == label then
                    INFINITY_NextTarget = entry
                    break
                end
            end
            if INFINITY_NextTarget then break end -- Comment translated to English
        end
    end

-- Comment translated to English
    if INFINITY_NextTarget then
        RevMRH.NextRankText:SetText(string.format(L["|cFFFFFFFF%s|r needs |cFF00FF00%.1f|r more score"],
            INFINITY_NextTarget.label, INFINITY_NextTarget.score - score))
    else
-- Comment translated to English
        RevMRH.NextRankText:SetText("|cFFFFD100" .. L["Congratulations, you are already a title player!"] .. "|r")
    end

-- Comment translated to English
    local realVal = 100 - currentPctNum -- Comment translated to English
    RevMRH.RankBar:SetMinMaxValues(0, 100)
    RevMRH.RankBar:SetValue(realVal)
    RevMRH.RankBar:SetStatusBarColor(classCol.r, classCol.g, classCol.b) -- Comment translated to English
    RevMRH.RankBarText:SetText(string.format("%.2f%%", realVal)) -- Comment translated to English

-- Comment translated to English
    RevMRH.TitleLineText:SetText(L["Current title line (0.1%): "] .. RevMRH_PYTHON_DATA.RankTable[1].score)
    --=======================================================================================
-- Comment translated to English
    ---=======================================================================================

    local hl = 0; for _, ach in ipairs(RevMRH_KeystoneAchievementList) do
        if select(13, GetAchievementInfo(ach[1])) then
            hl = ach[2]; break
        end
    end
    local mc = C_ChallengeMode.GetKeystoneLevelRarityColor(hl)
    RevMRH.MaxKeyText:SetText(hl); if mc then RevMRH.MaxKeyText:SetTextColor(mc.r, mc.g, mc.b) end

    local function UpdateCrest(id, ic, tx)
        local info = C_CurrencyInfo.GetCurrencyInfo(id)
        if info then
            ic:SetTexture(info.iconFileID); local cur, maxW = info.quantity or 0, info.maxWeeklyQuantity or 0; tx
                :SetText(maxW > 0 and string.format("%d/%d", cur, maxW) or tostring(cur))
        end
    end
    UpdateCrest(3345, RevMRH.C1I, RevMRH.C1T); UpdateCrest(3347, RevMRH.C2I, RevMRH.C2T)
    --=======================================================================================
-- Comment translated to English
    --=======================================================================================
    if wRuns then
        table.sort(wRuns, function(a, b) return a.level > b.level end)
        for i, idx in ipairs({ 1, 4, 8 }) do
            if wRuns[idx] then
                local il, info = RevMRH.GetLootInfo(wRuns[idx].level); RevMRH.Slots[i].ilvl:SetText(il); RevMRH.Slots[i]
                    .rank:SetText(info)
            else
                RevMRH.Slots[i].ilvl:SetText("-"); RevMRH.Slots[i].rank:SetText(L["Not Reached"])
            end
        end
        for i = 1, 8 do
-- Comment translated to English
            local run = wRuns[i]; local r = RevMRH.RunRows[i]
            if r.HighlightBG then
                if run then
                    r.HighlightBG:Show(); r.HighlightBG:SetColorTexture(classCol.r, classCol.g, classCol.b, 0.12)
                else
                    r.HighlightBG:Hide()
                end
            end
            if run then
                local n, _, _, tx = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID); local lCol = C_ChallengeMode
                    .GetKeystoneLevelRarityColor(run.level)
                r.icon:SetTexture(tx)
                r.text:SetText(string.format("%s (%d)", GetDungeonShortName(n), run.level))
                if lCol then r.text:SetTextColor(lCol.r, lCol.g, lCol.b) end
                local reward = C_MythicPlus.GetRewardLevelFromKeystoneLevel(run.level); r.ilvl:SetText(reward > 0 and
                    reward or "")
            else
                r.icon:SetTexture(nil); r.text:SetText("-"); r.ilvl:SetText("")
            end
        end
    end
end

function RevMRH.InitSubPanels()
    RevMRH.InitHeader(); RevMRH.InitStatTable(); RevMRH.InitRightPanel()
end

RevMRH.CreateStandaloneFrame()
C_Timer.After(1, function() C_MythicPlus.RequestMapInfo() end)



-- =========================================================
-- Comment translated to English
-- =========================================================
local function RevMRH_RemoveLegacyButtons()
    if not ChallengesFrame then return end

    local launchBtn = ChallengesFrame.RevMRH_LaunchButton or _G.RevMRH_LaunchButton
    if launchBtn then
        launchBtn:Hide()
        launchBtn:SetParent(UIParent)
    end

    local spellInfoBtn = ChallengesFrame.RevMRH_SpellInfoButton or _G.RevMRH_SpellInfoButton
    if spellInfoBtn then
        spellInfoBtn:Hide()
        spellInfoBtn:SetParent(UIParent)
    end
end

-- Comment translated to English
local function RevMRH_HookChallenges()
    if not ChallengesFrame then return end
    if ChallengesFrame.__RevMRH_HOOKED then return end
    ChallengesFrame.__RevMRH_HOOKED = true

    RevMRH_RemoveLegacyButtons()
    ChallengesFrame:HookScript("OnShow", RevMRH_RemoveLegacyButtons)

-- Comment translated to English
    if ChallengesFrame.WeeklyInfo and ChallengesFrame.WeeklyInfo.Child and ChallengesFrame.WeeklyInfo.Child.SeasonBest then
        ChallengesFrame.WeeklyInfo.Child.SeasonBest:Hide()
        ChallengesFrame.WeeklyInfo.Child.SeasonBest:SetAlpha(0)
    end
end

-- Comment translated to English
local RevMRH_EventFrame = CreateFrame("Frame")
RevMRH_EventFrame:RegisterEvent("ADDON_LOADED")
RevMRH_EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ChallengesUI" then
        RevMRH_HookChallenges()
    end
end)

-- Comment translated to English
-- Comment translated to English
-- Comment translated to English

-- Toggle public API (used by the main Infinity sidebar)
InfinityTools.ToggleMythicFrame = function()
    RevMRH.CreateStandaloneFrame()
    local frame = _G["RevMRH_MainFrame"]
    if not frame then return end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        RevMRH.UpdateAllData()
    end
end

-- Comment translated to English
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

