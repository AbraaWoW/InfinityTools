-- Comment translated to English
-- Comment translated to English

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local InfinityState = InfinityTools.State

-- Comment translated to English
local INFINITY_MODULE_KEY = "RevMplusInfo.SpellInfo"

-- Comment translated to English
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local InfinityDB = _G.InfinityDB

-- =========================================================
-- Comment translated to English
-- =========================================================

-- Comment translated to English
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 47, h = 2, label = "Mythic Spell Guide", labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 47, h = 1, label = "This module provides a detailed dungeon reference with mob spell data across all key levels." },
        { key = "open", type = "button", x = 1, y = 6, w = 15, h = 2, label = "Open guide now" },
        { key = "sub_sim", type = "subheader", x = 1, y = 9, w = 47, h = 1, label = "Damage simulation (global sync)" },
        { key = "mythicLevel", type = "slider", x = 1, y = 12, w = 24, h = 2, label = "Mythic level", min = 0, max = 30, parentKey = "RevMplus.MythicDamage" },
        { key = "info", type = "description", x = 1, y = 15, w = 47, h = 2, label = "|cff888888Note: the simulated level is shared with the Mythic Damage module.|r" },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

-- Comment translated to English
REGISTER_LAYOUT()


InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(data)
    if data.key == "open" then
        if SlashCmdList and SlashCmdList["EXSP"] then SlashCmdList["EXSP"]() end
    end
end)

-- =========================================================
-- Comment translated to English
-- =========================================================



-- Comment translated to English
local INFINITY_MAIN_TITLE_TEXT = "Infinity Mythic Spell Details"
-- Comment translated to English
local INFINITY_DEBUG_MODE = false

EXSP = EXSP or {}
EXSP.Tabs = {}
EXSP.DungeonDisplayNames = {

}
EXSP.MobDisplayNamesByNpcID = {
    [122056] = "Viceroy Nezhar",
    [122313] = "Zuraal the Ascended",
    [122316] = "Saprish",
    [124729] = "L'ura",
    [191736] = "Crawth",
    [190609] = "Echo of Doragosa",
    [194181] = "Vexamus",
    [196482] = "Overgrown Ancient",
    [252625] = "Ick",
    [252648] = "Scourgelord Tyrannus",
    [252635] = "Forgemaster Garfrost",
    [75964] = "Ranjit",
    [76141] = "Araknath",
    [76266] = "High Sage Viryx",
    [76143] = "Rukhran",
    [231626] = "Kallis",
    [231629] = "Lachri",
    [231631] = "Commander Kolurg",
    [231636] = "The Sleepless Heart",
    [231606] = "Cinderbrew",
    [231864] = "Gimelrus",
    [239636] = "Gimelrus",
    [231861] = "Custos",
    [231863] = "Sthaarbs",
    [231865] = "Dizjandrius",
    [241539] = "Caster Khasresis",
    [241542] = "Core Guardian Nysara",
    [254227] = "Core Guardian Nysara",
    [241546] = "Losaqsen",
    [247572] = "Nekkrak",
    [247570] = "Mrozin",
    [248605] = "Rakhtul",
    [248595] = "Wodaza",
    [122423] = "Grand Shadow-Weaver",
    [122403] = "Shadowguard Subjugator",
    [122404] = "Dreadweaver",
    [122413] = "Rift Hunter",
    [122421] = "Shadowguard Champion",
    [122827] = "Shadow Tentacle",
    [124171] = "Conqueror",
    [252756] = "Void Injector",
    [256424] = "Void Tendril",
    [122571] = "Rift Warden",
    [255320] = "Ravenous Shadowfiend",
    [122322] = "Starved Crusher",
    [122405] = "Darkcaster",
    [196044] = "Unruly Textbook",
    [192333] = "Alpha Eagle",
    [196694] = "Arcane Ravager",
    [192680] = "Guardian Sentry",
    [196202] = "Spectral Invoker",
    [196671] = "Venomous Forager",
    [197219] = "Vile Lasher",
    [196577] = "Spellbound Battleaxe",
    [196200] = "Algeth'ar Echoknight",
    [197406] = "Agitated Skitterfly",
    [196045] = "Corrupted Manafiend",
    [250299] = "Conduit Stalker",
    [254932] = "Glory Swarm",
    [254926] = "Luminescence",
    [255179] = "Fractured Image",
    [248706] = "Cursed Voidcaller",
    [248373] = "Circuit Prophet",
    [251853] = "Greater Nullbot",
    [251031] = "Greater Nullbot",
    [241643] = "Shadowguard Phaseblade",
    [248506] = "Dreadtether",
    [241660] = "Twilight Enforcer",
    [241644] = "Arcane Scalebane",
    [254485] = "Flashpoint Crystal",
    [241642] = "Residual Image",
    [259569] = "Mana Battery",
    [254928] = "Radiant Lynx",
    [248708] = "Nexus-Princess Ky'veza",
    [248502] = "Void Sentinel",
    [241645] = "Ghost of the Deep Seeker",
    [241647] = "Throughput Engineer",
    [248501] = "Reshaped Spawn",
    [248769] = "Black Blood",
    [252551] = "Deathspeaker Disciple",
    [252610] = "Ymirjar Graveblade",
    [252564] = "Iceborn Revenant",
    [257190] = "Frostwyrm",
    [252602] = "Reanimated Warrior",
    [254691] = "Scourge Plaguebringer",
    [252603] = "Skeletal Arcanist",
    [252567] = "Deathbound Shadowcaster",
    [252565] = "Wrathbone Laborer",
    [252563] = "Terrorpulse Witch",
    [255037] = "Krick's Shadow",
    [252555] = "Lumbering Fearbringer",
    [252558] = "Rotting Ghoul",
    [252559] = "Bounding Geist",
    [252606] = "Fallen Gargoyle",
    [252561] = "Excavation Torturer",
    [252566] = "Frostbone Skeleton",
    [248685] = "Ritual Hexxer",
    [253458] = "Gilga",
    [248692] = "Reanimated Fighter",
    [251639] = "Lost Soul",
    [249020] = "Hexwing Screecher",
    [254740] = "Spectral Hextrickster",
    [251674] = "Poisonous Soul",
    [248686] = "Dreadfeaster",
    [242964] = "Sharpshot Hunter",
    [253473] = "Dawnwing Bat",
    [253701] = "Grasp of Death",
    [253683] = "Rokzaar",
    [254233] = "Rokzaar",
    [249024] = "Hollow Soulrender",
    [249002] = "Ward Mask",
    [251047] = "Soulbound Totem",
    [249022] = "Bramblethroat Bear",
    [252886] = "Potato Toad",
    [249036] = "Tormented Shadowfiend",
    [249025] = "Bound Defender",
    [248684] = "Frenzied Berserker",
    [248690] = "Chillborne Footman",
    [248678] = "Hulking Terror",
    [76227] = "Sunwing",
    [79303] = "Dreadtalon Warrior",
    [78933] = "Solar Familiar",
    [251880] = "Solar Orb",
    [78932] = "Highwind Speaker",
    [76149] = "Dread Raven",
    [79093] = "Solar Zealot",
    [76154] = "Sunclaw Trapper",
    [79466] = "Dawn Initiate",
    [76205] = "Exiled Arcanist",
    [76087] = "Sun Construct",
    [250992] = "Raging Tempest",
    [79462] = "Blinding Solar Priest",
    [76142] = "Prototype Sun Construct",
    [76132] = "Skylord Tovra Disciple",
    [79467] = "Dawn Elite",
    [238049] = "Scout Trapper",
    [232063] = "Lynx Captain",
    [232146] = "Shapeshifting Illusionist",
    [232148] = "Phantom Axe Thrower",
    [232147] = "Wandering Raider",
    [232283] = "Loyal Wolf",
    [232446] = "Pestering Infantry",
    [232113] = "Warden Mage",
    [232067] = "Lurking Nerubian",
    [232118] = "Blazing Fiend",
    [238099] = "Annoying Lashroom Sprout",
    [232173] = "Devoted Apothecary",
    [232070] = "Agitated Steward",
    [232171] = "Fanatical Ripper",
    [232232] = "Fanatical Raider",
    [232122] = "Siegebreaker Rider",
    [232121] = "Siegebreaker Rider",
    [234673] = "Spiderling",
    [236894] = "Bloated Lashroom",
    [232175] = "Devout Harbinger",
    [232176] = "Flesh Behemoth",
    [232119] = "Swift Bowman",
    [232056] = "Territorial Roc",
    [232116] = "Vortex Soldier",
    [255376] = "Unstable Voidling",
    [232106] = "Brightscale Wyrm",
    [234066] = "Devourer Tyrant",
    [241397] = "Astral Traveler",
    [234062] = "Arcane Sentinel",
    [232369] = "Arcane Magus",
    [234068] = "Shadowguard Voidmage",
    [234064] = "Horrifying Voidwalker",
    [234486] = "Sunblessed Medic",
    [234124] = "Flameblade Adept",
    [251861] = "Blazing Fiendcaster",
    [240973] = "Runeshaper",
    [234069] = "Voidling",
    [249086] = "Void Terror",
    [234065] = "Umbral Soulrender",
    [257447] = "Umbral Soulrender",
    [259387] = "Netherweave Familiar",
}

local function EXSP_GetCreatureTypeDisplayName(name)
    return name or "Unknown"
end

local function EXSP_GetDungeonDisplayName(name)
    return EXSP.DungeonDisplayNames[name] or name
end

local function EXSP_GetMobDisplayName(name, data)
    if data and data.npcID and EXSP.MobDisplayNamesByNpcID[data.npcID] then
        return EXSP.MobDisplayNamesByNpcID[data.npcID]
    end
    if data and data.npcID then
        return string.format("NPC %d", data.npcID)
    end
    return name
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local SPELL_INFO_FACTORY = _G.InfinityFactory

-- Comment translated to English
local EXSP_DEFAULT_FONT = InfinityTools.MAIN_FONT or STANDARD_TEXT_FONT
local EXSP_FALLBACK_FONT = InfinityTools.MAIN_FONT

-------------------------------------------------------------------
-- Comment translated to English
-------------------------------------------------------------------

-- Comment translated to English
function EXSP_GetTagsForSpell(spellID)
    if not spellID then return {} end
    local tags = {}
    local function ex_hasValue(tab, val)
        if not tab then return false end
        for _, v in ipairs(tab) do if v == val then return true end end
        return false
    end
    -- MISC
    if ex_hasValue(EXSP.aoe_List, spellID) then table.insert(tags, "aoe") end
    if ex_hasValue(EXSP.los_List, spellID) then table.insert(tags, "los") end
    if ex_hasValue(EXSP.interrupt_List, spellID) then table.insert(tags, "interrupt") end
    if ex_hasValue(EXSP.noReflect_List, spellID) then table.insert(tags, "noReflect") end
    if ex_hasValue(EXSP.alwaysHit_List, spellID) then table.insert(tags, "alwaysHit") end
    if ex_hasValue(EXSP.noBlock_List, spellID) then table.insert(tags, "noBlock") end
    if ex_hasValue(EXSP.noDodge_List, spellID) then table.insert(tags, "noDodge") end
    if ex_hasValue(EXSP.noParry_List, spellID) then table.insert(tags, "noParry") end

-- Comment translated to English
    if ex_hasValue(EXSP.DispelBleed_List, spellID) then table.insert(tags, "DispelBleed") end
    if ex_hasValue(EXSP.DispelCurse_List, spellID) then table.insert(tags, "DispelCurse") end
    if ex_hasValue(EXSP.DispelDisease_List, spellID) then table.insert(tags, "DispelDisease") end
    if ex_hasValue(EXSP.DispelEnrage_List, spellID) then table.insert(tags, "DispelEnrage") end
    if ex_hasValue(EXSP.DispelMagic_List, spellID) then table.insert(tags, "DispelMagic") end
    if ex_hasValue(EXSP.DispelPoison_List, spellID) then table.insert(tags, "DispelPoison") end

-- Comment translated to English
    if ex_hasValue(EXSP.MechanicAsleep_List, spellID) then table.insert(tags, "MechanicAsleep") end
    if ex_hasValue(EXSP.MechanicBleeding_List, spellID) then table.insert(tags, "MechanicBleeding") end
    if ex_hasValue(EXSP.MechanicDisoriented_List, spellID) then table.insert(tags, "MechanicDisoriented") end
    if ex_hasValue(EXSP.MechanicEnraged_List, spellID) then table.insert(tags, "MechanicEnraged") end
    if ex_hasValue(EXSP.MechanicFrozen_List, spellID) then table.insert(tags, "MechanicFrozen") end
    if ex_hasValue(EXSP.MechanicPolymorphed_List, spellID) then table.insert(tags, "MechanicPolymorphed") end
    if ex_hasValue(EXSP.MechanicRooted_List, spellID) then table.insert(tags, "MechanicRooted") end
    if ex_hasValue(EXSP.MechanicSnared_List, spellID) then table.insert(tags, "MechanicSnared") end
    if ex_hasValue(EXSP.MechanicStunned_List, spellID) then table.insert(tags, "MechanicStunned") end
    if ex_hasValue(EXSP.MechanicFleeing_List, spellID) then table.insert(tags, "MechanicFleeing") end

    if INFINITY_DEBUG_MODE and #tags > 0 then
        print("|cff00ffff[EXSP Debug]|r Spell ID:", spellID, "matched tags:", table.concat(tags, ","))
    end
    return tags
end

-- Comment translated to English
function EXSP_SetupModelInteractions(model)
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    model.ex_curRotation = 0
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.ex_isDragging = true
            self.ex_startX = GetCursorPosition()
        end
    end)
    model:SetScript("OnMouseUp", function(self)
        self.ex_isDragging = false
    end)
    model:SetScript("OnUpdate", function(self)
        if self.ex_isDragging then
            local cx = GetCursorPosition()
-- Comment translated to English
            local diff = (cx - (self.ex_startX or cx)) / self:GetEffectiveScale()
            self.ex_curRotation = self.ex_curRotation + (diff * 0.015)
            self:SetRotation(self.ex_curRotation)
            self.ex_startX = cx
        end
    end)
    model:SetScript("OnMouseWheel", function(self, delta)
-- Comment translated to English
        local zoom = (self.ex_zoomLevel or 0) + delta * 0.15
        self.ex_zoomLevel = math.max(0, math.min(1.5, zoom))
        self:SetPortraitZoom(self.ex_zoomLevel)
    end)
end

-- Comment translated to English
function EXSP_SafeModelInit(model)
    model:ClearModel()
    model:SetPosition(0, 0, 0)
    model:SetRotation(0)
    model.ex_curRotation = 0
    model.ex_zoomLevel = 0
    EXSP_SetupModelInteractions(model)
end

function EXSP_DoCache()
    if not EXSP.Database then return end
    for _, mobs in pairs(EXSP.Database) do
        for _, d in pairs(mobs) do
            for _, id in ipairs(d.spells) do
                C_Spell.RequestLoadSpellData(id)
            end
        end
    end
end

-------------------------------------------------------------------
-- Comment translated to English
-------------------------------------------------------------------

-- Comment translated to English
SPELL_INFO_FACTORY:InitPool("SpellInfo_MobButton", "Button", "BackdropTemplate", function(b)
    b:SetSize(275, 65)
    b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } })

    b.ex_selBar = b:CreateTexture(nil, "OVERLAY")
    b.ex_selBar:SetWidth(4)
    b.ex_selBar:SetPoint("TOPLEFT", 2, -2)
    b.ex_selBar:SetPoint("BOTTOMLEFT", 2, 2)
    b.ex_selBar:SetColorTexture(0, 0.7, 1, 1)

    b.portrait = b:CreateTexture(nil, "ARTWORK")
    b.portrait:SetSize(58, 58)
    b.portrait:SetPoint("LEFT", 4, 0)
    b.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.nameText = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.nameText:SetPoint("LEFT", b.portrait, "RIGHT", 12, 0)
end)

-- Comment translated to English
SPELL_INFO_FACTORY:InitPool("SpellInfo_SpellFrame", "Frame", "BackdropTemplate", function(f)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    f.ex_internalPool = {} -- Comment translated to English
end)

-------------------------------------------------------------------
-- Comment translated to English
-------------------------------------------------------------------

function EXSP.CreateMainFrame()
    EXSP.CurrentFont = EXSP_DEFAULT_FONT

    local f = CreateFrame("Frame", "EXSP_MainFrame", UIParent, "BackdropTemplate")
-- Comment translated to English
    tinsert(UISpecialFrames, "EXSP_MainFrame")
-- Comment translated to English
    f:SetSize(1650, 850); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(false)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.ex_bgTexture = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.ex_bgTexture:SetTexture("Interface\\AddOns\\InfinityMythicPlus\\DK.png")
    f.ex_bgTexture:SetAllPoints(); f.ex_bgTexture:SetAlpha(0.9)

    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
-- Comment translated to English
    f:SetBackdropColor(0, 0, 0, 0.95); f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    f.Title = f:CreateFontString(nil, "OVERLAY")
-- Comment translated to English
    f.Title:SetFont(EXSP.CurrentFont, 30, "OUTLINE")
    f.Title:SetPoint("TOP", 0, -12); f.Title:SetText(INFINITY_MAIN_TITLE_TEXT)



-- Comment translated to English
    if _G.EXMD and InfinityTools.UI then
        local currentLevel = _G.EXMD.MODULE_DB.mythicLevel or 10

-- Comment translated to English
        local slider = InfinityTools.UI:CreateSlider(
            f, -- parent
            220, -- width
            "Simulate Level", -- label
            0, 30, -- min, max
            currentLevel, -- value
            1, -- step
            function(v) return string.format("|cffffd100+%d|r", v) end, -- formatter
            function(value) -- onValueChanged callback
                value = math.floor(value + 0.5)
                if value ~= _G.EXMD.MODULE_DB.mythicLevel then
                    _G.EXMD.MODULE_DB.mythicLevel = value

-- Comment translated to English
                    if EXSP.CurrentDungeon and EXSP.CurrentMob then
                        EXSP_RefreshRightPanel(EXSP.CurrentDungeon, EXSP.CurrentMob)
                    end

-- Comment translated to English
-- Comment translated to English
                    InfinityTools:UpdateState("RevMplus.MythicDamage.DatabaseChanged", { key = "mythicLevel", value = value })
                end
            end
        )

-- Comment translated to English
        slider:SetPoint("TOPRIGHT", -55, -20)

        EXSP.LevelSlider = slider

-- Comment translated to English
        InfinityTools:WatchState("RevMplus.MythicDamage.DatabaseChanged", INFINITY_MODULE_KEY, function()
            local newLevel = _G.EXMD.MODULE_DB.mythicLevel or 10
            if EXSP.LevelSlider and EXSP.LevelSlider:GetValue() ~= newLevel then
                EXSP.LevelSlider:SetValue(newLevel)
            end
        end)
    end

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", 0, 0)
    do
        local nTex = close:GetNormalTexture()
        if nTex then nTex:SetVertexColor(1, 0.15, 0.15, 1) end
        local hTex = close:GetHighlightTexture()
        if hTex then hTex:SetVertexColor(1, 0.4, 0.4, 1) end
        local pTex = close:GetPushedTexture()
        if pTex then pTex:SetVertexColor(0.7, 0.05, 0.05, 1) end
    end

-- Comment translated to English
    if not EXSP.DungeonList then
        print("|cffff0000[InfinityTools] SpellGuide: Spell database not loaded. Please ensure RevMplusInfoSpellData module is enabled.|r")
        f:Hide(); return
    end
    for i, name in ipairs(EXSP.DungeonList) do
        local tab = CreateFrame("Button", nil, f)
-- Comment translated to English
        tab:SetSize(60, 60); tab:SetPoint("TOPLEFT", 25 + (i - 1) * 75, -45)
        local tex = tab:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints(); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local maps = C_ChallengeMode.GetMapTable()
        local _, _, _, icon = C_ChallengeMode.GetMapUIInfo(maps[i] or 0)
        tex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark"); tab.icon = tex
        local sub = tab:CreateFontString(nil, "OVERLAY")
-- Comment translated to English
        sub:SetFont(EXSP.CurrentFont, 18, "OUTLINE"); sub:SetPoint("TOP", tab, "BOTTOM", 0, -2); sub:SetText(EXSP
            .DungeonAbbr[name] or EXSP_GetDungeonDisplayName(name)); tab.text = sub
        tab:SetScript("OnClick",
            function()
                for _, t in ipairs(EXSP.Tabs) do t.icon:SetDesaturated(true) end
                tab.icon:SetDesaturated(false); EXSP_RefreshMobList(name)
            end)
        EXSP.Tabs[i] = tab
    end

-- Comment translated to English
    local search = CreateFrame("EditBox", "EXSP_Search", f, "InputBoxTemplate")
-- Comment translated to English
    search:SetSize(275, 30); search:SetPoint("TOPLEFT", 20, -140); search:SetAutoFocus(false)
    search:SetText("Search mobs..."); search:SetTextInsets(10, 10, 0, 0)
    search:SetScript("OnTextChanged",
        function(s) if EXSP.CurrentDungeon then EXSP_RefreshMobList(EXSP.CurrentDungeon, s:GetText()) end end)

    local mobSF = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate"); mobSF:SetSize(285, 600); mobSF
        :SetPoint("TOPLEFT", 20, -180)
    local mobChild = CreateFrame("Frame", nil, mobSF); mobChild:SetSize(270, 1); mobSF:SetScrollChild(mobChild)
    EXSP.MobScroll = mobSF
-- Comment translated to English
    local model = CreateFrame("PlayerModel", "EXSP_MainModel", f); model:SetSize(555, 410); model:SetPoint("TOPLEFT", 345,
        -135)
    EXSP_SafeModelInit(model); EXSP.ModelFrame = model

-- Comment translated to English
    local infoPanel = CreateFrame("Frame", nil, f); infoPanel:SetSize(750, 200); infoPanel:SetPoint("TOP", model,
        "BOTTOM", 0, -15)
    EXSP.NPCInfoPanel = infoPanel
    infoPanel.Name = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal"); infoPanel.Name:SetPoint("TOP", 0, 0)
    infoPanel.TopLine = infoPanel:CreateTexture(nil, "OVERLAY"); infoPanel.TopLine:SetHeight(2); infoPanel.TopLine
        :SetPoint("BOTTOM", infoPanel.Name, "TOP", 0, 8); infoPanel.TopLine:SetColorTexture(1, 0.82, 0, 0.4)
    infoPanel.BottomLine = infoPanel:CreateTexture(nil, "OVERLAY"); infoPanel.BottomLine:SetHeight(2); infoPanel
        .BottomLine:SetPoint("TOP", infoPanel.Name, "BOTTOM", 0, -8); infoPanel.BottomLine:SetColorTexture(1, 0.82, 0,
        0.4)

    infoPanel.CenterInfo = infoPanel:CreateFontString(nil, "OVERLAY"); infoPanel.CenterInfo:SetPoint("TOP",
        infoPanel.BottomLine, "BOTTOM", 0, -12); infoPanel.CenterInfo:SetJustifyH("CENTER")
    infoPanel.IDFootnote = infoPanel:CreateFontString(nil, "OVERLAY"); infoPanel.IDFootnote:SetPoint("TOP",
        infoPanel.CenterInfo, "BOTTOM", 0, -8); infoPanel.IDFootnote:SetJustifyH("CENTER")

    local spellSF = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate"); spellSF:SetSize(710, 640); spellSF
        :SetPoint("TOPLEFT", 915, -140)
    local spellChild = CreateFrame("Frame", nil, spellSF); spellChild:SetSize(700, 1); spellSF:SetScrollChild(spellChild)
    EXSP.SpellScroll = spellSF

    f:Hide(); EXSP.MainFrame = f

-- Comment translated to English
    EXSP.RefreshRightPanel = EXSP_RefreshRightPanel
end

-------------------------------------------------------------------
-- Comment translated to English
-------------------------------------------------------------------

function EXSP_RefreshMobList(dungeonName, filter)
    EXSP.CurrentDungeon = dungeonName
    local container = EXSP.MobScroll:GetScrollChild()

-- Comment translated to English
    local children = { container:GetChildren() }
    for _, child in ipairs(children) do
-- Comment translated to English
        if child.poolType == "SpellInfo_MobButton" then
            SPELL_INFO_FACTORY:Release("SpellInfo_MobButton", child)
        else
            child:Hide()
        end
    end
    local mobs = EXSP.Database[dungeonName] or {}
    local sorted = {}
    for n in pairs(mobs) do table.insert(sorted, n) end
    table.sort(sorted)
    local firstBtn, idx = nil, 0
    filter = (filter and filter ~= "" and filter ~= "Search mobs...") and filter:lower() or nil
    for _, name in ipairs(sorted) do
        local data = mobs[name]
        if not filter or name:lower():find(filter) then
-- Comment translated to English
            local b = SPELL_INFO_FACTORY:Acquire("SpellInfo_MobButton", container)
            b.poolType = "SpellInfo_MobButton" -- Comment translated to English
            b:SetPoint("TOPLEFT", 5, -(idx * 70) - 5)
            if EXSP.CurrentMob == name then
                b:SetBackdropColor(0.1, 0.4, 0.8, 0.3); b:SetBackdropBorderColor(0, 0.8, 1, 1); b.ex_selBar:Show()
            else
                b:SetBackdropColor(0.04, 0.04, 0.04, 0.8); b:SetBackdropBorderColor(0.4, 0.4, 0.4, 1); b.ex_selBar:Hide()
            end
            if data.displayID then
                SetPortraitTextureFromCreatureDisplayID(b.portrait, data.displayID); b.portrait:SetTexCoord(0.15, 0.85,
                    0.15, 0.85)
            end
-- Comment translated to English
            b.nameText:SetFont(EXSP.CurrentFont, 19, "OUTLINE"); b.nameText:SetText(EXSP_GetMobDisplayName(name, data))
            b:SetScript("OnClick",
                function()
                    EXSP.CurrentMob = name; EXSP_RefreshRightPanel(dungeonName, name); EXSP_RefreshMobList(dungeonName,
                        filter)
                end)
            if not firstBtn then firstBtn = b end
            idx = idx + 1
        end
    end
    if firstBtn and not filter and not EXSP.CurrentMob then firstBtn:Click() end
end

function EXSP_RefreshRightPanel(dungeonName, mobName)
-- Comment translated to English
    if type(dungeonName) == "table" then dungeonName = nil end

    dungeonName = dungeonName or EXSP.CurrentDungeon
    mobName = mobName or EXSP.CurrentMob

    if not dungeonName or not mobName then return end

    local dungeonData = EXSP.Database[dungeonName]
    if not dungeonData then return end

    local data = dungeonData[mobName]
    local info = EXSP.NPCInfoPanel
    local font = EXSP_DEFAULT_FONT
    if not data then return end
    if EXSP.ModelFrame.lastID ~= data.displayID then
        EXSP.ModelFrame:SetDisplayInfo(data.displayID); EXSP.ModelFrame.lastID = data.displayID
    end

-- Comment translated to English
    info.Name:SetFont(font, 52, "OUTLINE"); info.Name:SetTextColor(1, 0.82, 0); info.Name:SetText(EXSP_GetMobDisplayName(mobName, data))
-- Comment translated to English
    local nameWidth = info.Name:GetStringWidth(); info.TopLine:SetWidth(-1); info.BottomLine:SetWidth(nameWidth + 100)

-- Comment translated to English
    local lvColor, lvSuffix = "|cff00ff00", ""
    if data.level == 91 then
        lvColor = "|cff0070dd"; lvSuffix = " (Elite)"
    elseif data.level == 92 then
        lvColor = "|cffa335ee"; lvSuffix = " (Boss)"
    end
-- Comment translated to English
    info.CenterInfo:SetFont(font, 24, "OUTLINE")
    info.CenterInfo:SetText(string.format("|cffffffff%s|r    %sLV.%d%s|r", data.type or "Unknown", lvColor, data.level or 90,
        lvSuffix))
-- Comment translated to English
    info.IDFootnote:SetFont(font, 18, "OUTLINE"); info.IDFootnote:SetText("|cff888888NPCID:" ..
        (data.npcID or 0) .. "|r")

    local container = EXSP.SpellScroll:GetScrollChild()
    local children = { container:GetChildren() }
    for _, child in ipairs(children) do
        if child.poolType == "SpellInfo_SpellFrame" then
            SPELL_INFO_FACTORY:Release("SpellInfo_SpellFrame", child)
        else
            child:Hide()
        end
    end
    local last = nil
    if data.spells then
        for _, id in ipairs(data.spells) do
            local f = EXSP_UpdateSpellItem(container, id)
-- Comment translated to English
            if last then f:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -8) else f:SetPoint("TOPLEFT", 0, 0) end
            last = f
        end
    end
end

-- Comment translated to English
function EXSP_UpdateSpellItem(parent, spellID)
-- Comment translated to English
    local f = SPELL_INFO_FACTORY:Acquire("SpellInfo_SpellFrame", parent)
    f.poolType = "SpellInfo_SpellFrame"
-- Comment translated to English
    f:SetWidth(690)
    if not f.ex_internalPool then f.ex_internalPool = {} end
    for _, obj in ipairs(f.ex_internalPool) do
        obj:Hide(); obj:ClearAllPoints()
    end

    local font = EXSP_DEFAULT_FONT
    local function AcquireObject(type)
        for _, obj in ipairs(f.ex_internalPool) do
            if not obj:IsShown() and obj:GetObjectType() == type then
                if type == "FontString" then
                    obj:SetWidth(0); obj:SetSpacing(0); obj:SetTextColor(1, 1, 1);
                    obj:SetFont(font, 22, "OUTLINE")
                end
                obj:Show(); return obj
            end
        end
        local obj = (type == "FontString") and f:CreateFontString(nil, "OVERLAY") or f:CreateTexture(nil, "ARTWORK")
        if type == "FontString" then obj:SetFont(font, 22, "OUTLINE") end
        obj:Show(); table.insert(f.ex_internalPool, obj); return obj
    end

    if not C_Spell.IsSpellDataCached(spellID) then
        C_Spell.RequestLoadSpellData(spellID)
        local t = AcquireObject("FontString"); t:SetPoint("CENTER"); t:SetText("Caching..."); f:SetHeight(30); return f
    end

    local tags = EXSP_GetTagsForSpell(spellID)
    local inlineTags, footerTags = {}, {}
    for _, tk in ipairs(tags) do
        local d = EXSP.TagDefs[tk]
        if d then if d.category >= 2 then table.insert(inlineTags, d) else table.insert(footerTags, d) end end
    end
    table.sort(inlineTags, function(a, b) return a.category < b.category end)

    local tip = C_TooltipInfo.GetSpellByID(spellID)
    local spellInfo = C_Spell.GetSpellInfo(spellID)

    if not tip or not tip.lines or not spellInfo then
        local t = AcquireObject("FontString"); t:SetPoint("CENTER")
        t:SetText(string.format("|cffff8800(Spell %d data unavailable)|r", spellID))
        f:SetHeight(30); return f
    end

-- Comment translated to English
    local lastL, totalH, iSize = nil, 10, 42
    local icon = AcquireObject("Texture"); icon:SetSize(iSize, iSize); icon:SetPoint("TOPLEFT", 8, -8);
    icon:SetTexture(spellInfo.iconID)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English

    for i, line in ipairs(tip.lines) do
        local fs = AcquireObject("FontString")
-- Comment translated to English
        fs:SetFont(font, i == 1 and 20 or 16, "OUTLINE")
-- Comment translated to English
        fs:SetSpacing(5)
        if line.leftColor then fs:SetTextColor(line.leftColor.r, line.leftColor.g, line.leftColor.b) end

        if i == 1 then
            fs:SetText(string.format("%s  |cff888888(%d)|r", line.leftText or "", spellID))
            fs:SetPoint("TOPLEFT", iSize + 18, -10)
            local inlineAnchor = fs
            for _, d in ipairs(inlineTags) do
-- Comment translated to English
                local itex = AcquireObject("Texture"); itex:SetSize(25, 25); itex:SetPoint("LEFT", inlineAnchor, "RIGHT",
                    15, 0); itex:SetTexture(d.icon)
                itex:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
-- Comment translated to English
                local ilbl = AcquireObject("FontString"); ilbl:SetWidth(0); ilbl:SetFont(font, 20, "OUTLINE"); ilbl
                    :SetPoint("LEFT", itex, "RIGHT", 5, 0); ilbl:SetText(d.name)
                inlineAnchor = ilbl
            end
        else
-- Comment translated to English
            fs:SetWidth(600); fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
-- Comment translated to English
-- Comment translated to English
            local displayText = line.leftText
            if _G.EXMD then
                displayText = _G.EXMD.ProcessDamageText(line.leftText, _G.EXMD.GetCurrentMultiplier())
            end
            fs:SetText(displayText); fs:SetPoint("TOPLEFT", lastL, "BOTTOMLEFT", 0, -5)
        end
        totalH = totalH + (fs:GetStringHeight() > 0 and fs:GetStringHeight() or 16) + 5
        lastL = fs
    end

-- Comment translated to English
    if #footerTags > 0 then
        local l = AcquireObject("Texture"); l:SetSize(660, 1); l:SetPoint("TOPLEFT", 15, -totalH - 5); l:SetColorTexture(
            1, 1, 1, 0.1)
        totalH = totalH + 15; local prev = nil
        for _, d in ipairs(footerTags) do
-- Comment translated to English
            local ic = AcquireObject("Texture"); ic:SetSize(25, 25)
            if prev then ic:SetPoint("LEFT", prev, "RIGHT", 15, 0) else ic:SetPoint("TOPLEFT", 15, -totalH) end
            ic:SetTexture(d.icon)
            ic:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Comment translated to English
-- Comment translated to English
            local lb = AcquireObject("FontString"); lb:SetWidth(0); lb:SetFont(font, 17, "OUTLINE"); lb:SetPoint("LEFT",
                ic, "RIGHT", 4, 0); lb:SetText(d.name); prev = lb
        end
        totalH = totalH + 28
    end
    f:SetHeight(math.max(iSize + 16, totalH + 12)); return f
end

-------------------------------------------------------------------
-- Comment translated to English
-------------------------------------------------------------------
InfinityTools:RegisterEvent("SPELL_TEXT_UPDATE", INFINITY_MODULE_KEY, function()
    if EXSP.MainFrame and EXSP.MainFrame:IsShown() and EXSP.CurrentMob then
        EXSP_RefreshRightPanel(EXSP.CurrentDungeon, EXSP.CurrentMob)
    end
end)

InfinityTools:RegisterEvent("SPELL_DATA_LOAD_RESULT", INFINITY_MODULE_KEY, function(_, spellID, success)
    if success and EXSP.MainFrame and EXSP.MainFrame:IsShown() and EXSP.CurrentMob then
-- Comment translated to English
        local data = EXSP.Database[EXSP.CurrentDungeon] and EXSP.Database[EXSP.CurrentDungeon][EXSP.CurrentMob]
        if data and data.spells then
            for _, id in ipairs(data.spells) do
                if id == spellID then
                    EXSP_RefreshRightPanel(EXSP.CurrentDungeon, EXSP.CurrentMob)
                    break
                end
            end
        end
    end
end)

SLASH_EXSP1 = "/EXSP"
SLASH_EXSP2 = "/EXSPELL"
SlashCmdList["EXSP"] = function()
    if not EXSP.MainFrame then
        EXSP.CreateMainFrame()
        -- Pré-charger les données de tous les sorts au premier usage
        EXSP_DoCache()
    end
    if not EXSP.MainFrame then return end  -- CreateMainFrame a échoué (ex: SpellData désactivé)
    if EXSP.MainFrame:IsShown() then
        EXSP.MainFrame:Hide()
    else
        EXSP.MainFrame:Show(); if not EXSP.CurrentDungeon and EXSP.Tabs[1] then EXSP.Tabs[1]:Click() end
    end
end

-- Comment translated to English
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

