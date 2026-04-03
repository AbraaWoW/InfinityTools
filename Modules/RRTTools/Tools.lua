local _, RRT_NS = ...

-- ═══════════════════════════════════════════════════════════════
-- DB helper
-- ═══════════════════════════════════════════════════════════════
local function GetDB()
    RRT.Tools = RRT.Tools or {}
    local db = RRT.Tools
    if db.AutoDelete == nil then db.AutoDelete = false end
    if db.AutoSellJunk == nil then db.AutoSellJunk = false end
    if db.AutoRepair == nil then db.AutoRepair = false end
    if db.AutoRepairGuild == nil then db.AutoRepairGuild = false end
    if db.BulkBuy == nil then db.BulkBuy = false end
    if db.BulkBuyWarnGold == nil then db.BulkBuyWarnGold = 1000 end
    if db.MapInfo == nil then db.MapInfo = false end
    if db.MapInfoShowMapID == nil then db.MapInfoShowMapID = true end
    if db.RangeCheck == nil then db.RangeCheck = false end
    if db.RangeCheckFontSize == nil then db.RangeCheckFontSize = 18 end
    if db.RangeCheckPosX == nil then db.RangeCheckPosX = 0 end
    if db.RangeCheckPosY == nil then db.RangeCheckPosY = -85 end
    if db.RangeCheckHideThreshold == nil then db.RangeCheckHideThreshold = 60 end
    if db.RangeCheckRangeSpell == nil then db.RangeCheckRangeSpell = "" end
    if db.PlayerPosition == nil then db.PlayerPosition = false end
    if db.PlayerPositionShape == nil then db.PlayerPositionShape = "CROSS" end
    if db.PlayerPositionScale == nil then db.PlayerPositionScale = 0.5 end
    if db.PlayerPositionPosX == nil then db.PlayerPositionPosX = 0 end
    if db.PlayerPositionPosY == nil then db.PlayerPositionPosY = 0 end
    if db.PlayerPositionInCombat == nil then db.PlayerPositionInCombat = true end
    if db.PlayerPositionOutCombat == nil then db.PlayerPositionOutCombat = true end
    if db.PlayerPositionInstanceOnly == nil then db.PlayerPositionInstanceOnly = false end
    if db.TeleMsg == nil then db.TeleMsg = false end
    if db.TelemsgText == nil then db.TelemsgText = '[RRT] Casting %link, teleporting to "%name"' end
    if db.TelemsgOnSuccess == nil then db.TelemsgOnSuccess = true end
    if db.SpellQueue == nil then db.SpellQueue = false end
    if db.SpellQueueAI == nil then db.SpellQueueAI = false end
    if db.SpellQueueGlobal == nil then db.SpellQueueGlobal = 400 end
    if db.SpellQueueSpecs == nil then db.SpellQueueSpecs = {} end
    if db.YYSound == nil then db.YYSound = false end
    if db.YYSoundFile == nil then db.YYSoundFile = "None" end
    if db.YYIconSize == nil then db.YYIconSize = 59 end
    if db.YYPosX == nil then db.YYPosX = -390 end
    if db.YYPosY == nil then db.YYPosY = 14 end
    if db.YYShowIcon == nil then db.YYShowIcon = true end
    return db
end

local function GetSpellNameSafe(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then
            return info.name
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- Teleport spell IDs (M+ dungeon teleports)
-- ═══════════════════════════════════════════════════════════════
local TELEPORT_SPELLS = {
    [1254555] = "Salanar Mines",
    [1254400] = "Tower of Windrunner",
    [1254572] = "Archmage's Platform",
    [1254559] = "Measara Caverns",
    [1254563] = "Node of Sinath",
    [445443]  = "The Stonevault",
    [445269]  = "The Stonevault",
    [445444]  = "Priory of the Sacred Flame",
    [445416]  = "City of Threads",
    [445440]  = "Cinderbrew Meadery",
    [445441]  = "Darkflame Cleft",
    [445414]  = "The Dawnbreaker",
    [445417]  = "Ara-Kara, City of Echoes",
    [445418]  = "Siege of Boralus",
    [1216786] = "Operation: Floodgate",
    [1226482] = "Liberation of Undermine",
    [1237215] = "Operation: Mechagon",
    [1239155] = "Manaforge Omega",
    [393222]  = "Algeth'ar Academy",
    [393256]  = "Ruby Life Pools",
    [393262]  = "The Nokhud Offensive",
    [393267]  = "Brackenhide Hollow",
    [393273]  = "Halls of Infusion",
    [393276]  = "Neltharus",
    [393279]  = "The Azure Vault",
    [393283]  = "Uldaman: Legacy of Tyr",
    [159897]  = "Auchindoun",
    [159898]  = "Shado-Pan Monastery",
    [1254557] = "Shado-Pan Monastery",
    [159899]  = "Shadowmoon Burial Grounds",
    [159901]  = "Everbloom",
    [159902]  = "Upper Blackrock Spire",
    [159895]  = "Bloodmaul Slag Mines",
    [159900]  = "Iron Docks",
    [159896]  = "Iron Docks",
    [131232]  = "Shado-Pan Monastery",
    [131204]  = "Temple of the Jade Serpent",
    [131205]  = "Stormstout Brewery",
    [131206]  = "Mogu'shan Palace",
    [373262]  = "Karazhan",
    [354462]  = "Necrotic Wake",
    [354463]  = "Sanguine Depths",
    [354464]  = "Mists of Tirna Scithe",
    [354465]  = "Halls of Atonement",
    [354466]  = "Spires of Ascension",
    [354467]  = "Theater of Pain",
    [354468]  = "De Other Side",
    [354469]  = "Plaguefall",
}

-- ═══════════════════════════════════════════════════════════════
-- Bloodlust / Heroism buff IDs
-- ═══════════════════════════════════════════════════════════════
local BLOODLUST_BUFFS = {
    2825, 32182, 80353, 90355, 160452, 264667, 390386,
    178207, 146555, 230935, 256740,
}
local BLOODLUST_SET = {}
for _, id in ipairs(BLOODLUST_BUFFS) do BLOODLUST_SET[id] = true end

-- ═══════════════════════════════════════════════════════════════
-- Frame handles
-- ═══════════════════════════════════════════════════════════════
local ToolsFrame = CreateFrame("Frame", "RRT_ToolsFrame")

local RangeCheckFrame, RangeText
local PlayerPosFrame, PlayerPosTextures
local YYSoundFrame, YYIconTex, YYCooldown
local MapInfoFrame, MapInfoText
local BulkBuyPanel

-- ═══════════════════════════════════════════════════════════════
-- ─── 1. Auto Tools ───────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function InitAutoTools()
    local db = GetDB()

    -- Auto Delete: fill in the confirmation popup automatically
    ToolsFrame:RegisterEvent("DELETE_ITEM_CONFIRM")

    -- Merchant: sell junk + repair
    ToolsFrame:RegisterEvent("MERCHANT_SHOW")
end

-- ═══════════════════════════════════════════════════════════════
-- ─── 2. Map Info ────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function InitMapInfo()
    if MapInfoFrame then
        MapInfoFrame:SetShown(GetDB().MapInfo)
        return
    end
    MapInfoFrame = CreateFrame("Frame", "RRT_Tools_MapInfoFrame", WorldMapFrame)
    MapInfoFrame:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 6, 6)
    MapInfoFrame:SetSize(300, 36)
    MapInfoFrame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 10)

    MapInfoText = MapInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then MapInfoText:SetFont(f, 10, fl or "") end end
    MapInfoText:SetPoint("BOTTOMLEFT", MapInfoFrame, "BOTTOMLEFT", 0, 0)
    MapInfoText:SetTextColor(1, 1, 1, 0.9)
    MapInfoText:SetJustifyH("LEFT")

    local elapsed = 0
    MapInfoFrame:SetScript("OnUpdate", function(self, dt)
        if not WorldMapFrame:IsShown() then return end
        elapsed = elapsed + dt
        if elapsed < 0.15 then return end
        elapsed = 0
        local db = GetDB()
        if not db.MapInfo then self:Hide(); return end

        local mapID = WorldMapFrame:GetMapID()
        local cx, cy = WorldMapFrame:GetNormalizedCursorPosition()
        local px, py = C_Map.GetPlayerMapPosition(mapID, "player")
            and C_Map.GetPlayerMapPosition(mapID, "player"):GetXY()
            or 0, 0

        local lines = {}
        if db.MapInfoShowMapID then
            lines[#lines+1] = string.format("MapID: %d", mapID or 0)
        end
        lines[#lines+1] = string.format("Cursor: %.2f, %.2f", cx or 0, cy or 0)
        if px and py then
            lines[#lines+1] = string.format("Player: %.2f, %.2f", px * 100, py * 100)
        end
        MapInfoText:SetText(table.concat(lines, "  |  "))
    end)

    MapInfoFrame:SetShown(GetDB().MapInfo)
end

-- ═══════════════════════════════════════════════════════════════
-- ─── 3. Range Check ─────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function InitRangeCheck()
    if RangeCheckFrame then
        local db = GetDB()
        RangeCheckFrame:ClearAllPoints()
        RangeCheckFrame:SetPoint("CENTER", UIParent, "CENTER", db.RangeCheckPosX, db.RangeCheckPosY)
        RangeText:SetFont(select(1, GameFontNormalLarge:GetFont()), db.RangeCheckFontSize, "OUTLINE")
        RangeCheckFrame:SetShown(db.RangeCheck)
        return
    end

    RangeCheckFrame = CreateFrame("Frame", "RRT_Tools_RangeCheckFrame", UIParent)
    local db = GetDB()
    RangeCheckFrame:SetSize(120, 40)
    RangeCheckFrame:SetPoint("CENTER", UIParent, "CENTER", db.RangeCheckPosX, db.RangeCheckPosY)
    RangeCheckFrame:SetMovable(true)
    RangeCheckFrame:EnableMouse(false)
    RangeCheckFrame:SetClampedToScreen(true)

    -- Shift+drag to move
    RangeCheckFrame:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" and IsShiftKeyDown() then
            self:EnableMouse(true)
            self:StartMoving()
        end
    end)
    RangeCheckFrame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        self:EnableMouse(false)
        local pt, _, rpt, x, y = self:GetPoint()
        GetDB().RangeCheckPosX = x
        GetDB().RangeCheckPosY = y
    end)

    RangeText = RangeCheckFrame:CreateFontString(nil, "OVERLAY")
    do local f, _, fl = GameFontNormalLarge:GetFont(); if f then RangeText:SetFont(f, db.RangeCheckFontSize, "OUTLINE") end end
    RangeText:SetPoint("CENTER", RangeCheckFrame, "CENTER", 0, 0)
    RangeText:SetText("")
    RangeText:SetTextColor(0.9, 0.9, 0.9, 1)

    local elapsed = 0
    RangeCheckFrame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.3 then return end
        elapsed = 0
        local db = GetDB()
        if not db.RangeCheck then self:Hide(); return end
        if not UnitExists("target") or UnitIsDeadOrGhost("target") then
            RangeText:SetText("")
            self:Hide()
            return
        end

        local rangeSpell = db.RangeCheckRangeSpell and tonumber(db.RangeCheckRangeSpell)
        local threshold = db.RangeCheckHideThreshold or 60
        local displayVal = "?"
        local r, g, b = 0.9, 0.9, 0.9

        if rangeSpell and rangeSpell > 0 then
            local inRange = C_Spell.IsSpellInRange(rangeSpell, "target")
            if inRange == 1 then
                displayVal = "<" .. threshold .. "y"
                r, g, b = 0.039, 1, 0
            elseif inRange == 0 then
                displayVal = ">" .. threshold .. "y"
                r, g, b = 1, 0, 0
            else
                displayVal = "?"
            end
        else
            -- No safe generic fallback here: range should be driven by an explicit spell.
            RangeText:SetText("")
            self:Hide()
            return
        end

        RangeText:SetText(displayVal)
        RangeText:SetTextColor(r, g, b, 1)
        self:Show()
    end)

    RangeCheckFrame:SetShown(db.RangeCheck)
end

-- ═══════════════════════════════════════════════════════════════
-- ─── 4. Player Position Shape ───────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function DestroyPlayerPosTextures()
    if PlayerPosTextures then
        for _, t in ipairs(PlayerPosTextures) do
            t:Hide()
            t:SetParent(nil)
        end
        PlayerPosTextures = nil
    end
end

local function BuildPlayerPosShape(db)
    DestroyPlayerPosTextures()
    PlayerPosTextures = {}
    local shape = db.PlayerPositionShape or "CROSS"
    local scale = db.PlayerPositionScale or 0.5
    local sz = math.max(4, math.floor(64 * scale))
    local r, g, b = 0.15, 1, 0.25

    if shape == "CROSS" then
        -- Vertical bar
        local vBar = PlayerPosFrame:CreateTexture(nil, "OVERLAY")
        vBar:SetColorTexture(r, g, b, 0.85)
        vBar:SetSize(math.max(2, math.floor(sz * 0.18)), sz)
        vBar:SetPoint("CENTER", PlayerPosFrame, "CENTER", 0, 0)
        PlayerPosTextures[#PlayerPosTextures+1] = vBar
        -- Horizontal bar
        local hBar = PlayerPosFrame:CreateTexture(nil, "OVERLAY")
        hBar:SetColorTexture(r, g, b, 0.85)
        hBar:SetSize(sz, math.max(2, math.floor(sz * 0.18)))
        hBar:SetPoint("CENTER", PlayerPosFrame, "CENTER", 0, 0)
        PlayerPosTextures[#PlayerPosTextures+1] = hBar

    elseif shape == "SQUARE" then
        local sq = PlayerPosFrame:CreateTexture(nil, "OVERLAY")
        sq:SetColorTexture(r, g, b, 0.75)
        sq:SetSize(sz, sz)
        sq:SetPoint("CENTER", PlayerPosFrame, "CENTER", 0, 0)
        PlayerPosTextures[#PlayerPosTextures+1] = sq

    elseif shape == "CIRCLE" then
        -- Approximate circle with multiple squares in a cross pattern
        local steps = 8
        local radius = sz * 0.45
        local dotSz = math.max(3, math.floor(sz * 0.22))
        for i = 0, steps - 1 do
            local angle = (2 * math.pi * i) / steps
            local ox = math.cos(angle) * radius
            local oy = math.sin(angle) * radius
            local dot = PlayerPosFrame:CreateTexture(nil, "OVERLAY")
            dot:SetColorTexture(r, g, b, 0.85)
            dot:SetSize(dotSz, dotSz)
            dot:SetPoint("CENTER", PlayerPosFrame, "CENTER", ox, oy)
            PlayerPosTextures[#PlayerPosTextures+1] = dot
        end
        -- Center dot
        local center = PlayerPosFrame:CreateTexture(nil, "OVERLAY")
        center:SetColorTexture(r, g, b, 0.85)
        center:SetSize(dotSz, dotSz)
        center:SetPoint("CENTER", PlayerPosFrame, "CENTER", 0, 0)
        PlayerPosTextures[#PlayerPosTextures+1] = center

    elseif shape == "DIAMOND" then
        -- Diamond: four triangles via rotated squares at compass points
        local half = math.floor(sz * 0.5)
        local barW = math.max(2, math.floor(sz * 0.15))
        local dirs = { {0, half}, {0, -half}, {half, 0}, {-half, 0} }
        for _, d in ipairs(dirs) do
            local arm = PlayerPosFrame:CreateTexture(nil, "OVERLAY")
            arm:SetColorTexture(r, g, b, 0.85)
            local isV = d[1] == 0
            arm:SetSize(isV and barW or math.floor(half * 0.6), isV and math.floor(half * 0.6) or barW)
            arm:SetPoint("CENTER", PlayerPosFrame, "CENTER", d[1] * 0.6, d[2] * 0.6)
            PlayerPosTextures[#PlayerPosTextures+1] = arm
        end
        local center = PlayerPosFrame:CreateTexture(nil, "OVERLAY")
        center:SetColorTexture(r, g, b, 0.85)
        center:SetSize(barW, barW)
        center:SetPoint("CENTER", PlayerPosFrame, "CENTER", 0, 0)
        PlayerPosTextures[#PlayerPosTextures+1] = center
    end
end

local function InitPlayerPosition()
    local db = GetDB()
    if not PlayerPosFrame then
        PlayerPosFrame = CreateFrame("Frame", "RRT_Tools_PlayerPosFrame", UIParent)
        PlayerPosFrame:SetSize(128, 128)
        PlayerPosFrame:SetFrameStrata("BACKGROUND")
        PlayerPosFrame:SetPoint("CENTER", UIParent, "CENTER", db.PlayerPositionPosX, db.PlayerPositionPosY)
        PlayerPosFrame:SetMovable(true)
        PlayerPosFrame:EnableMouse(false)

        PlayerPosFrame:SetScript("OnMouseDown", function(self, btn)
            if btn == "LeftButton" and IsShiftKeyDown() then
                self:EnableMouse(true)
                self:StartMoving()
            end
        end)
        PlayerPosFrame:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
            self:EnableMouse(false)
            local pt, _, rpt, x, y = self:GetPoint()
            GetDB().PlayerPositionPosX = x
            GetDB().PlayerPositionPosY = y
        end)

        PlayerPosFrame:SetScript("OnUpdate", function(self)
            local d = GetDB()
            if not d.PlayerPosition then self:Hide(); return end
            local inCombat = InCombatLockdown()
            local _, instanceType = IsInInstance()
            local isInstance = instanceType ~= "none"

            if d.PlayerPositionInstanceOnly and not isInstance then self:Hide(); return end
            if inCombat and not d.PlayerPositionInCombat then self:Hide(); return end
            if not inCombat and not d.PlayerPositionOutCombat then self:Hide(); return end
            self:Show()
        end)
    end

    PlayerPosFrame:SetPoint("CENTER", UIParent, "CENTER", db.PlayerPositionPosX, db.PlayerPositionPosY)
    BuildPlayerPosShape(db)
    PlayerPosFrame:SetShown(db.PlayerPosition)
end

-- ═══════════════════════════════════════════════════════════════
-- ─── 5. Tele Message ─────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function InitTeleMsg()
    -- Registration happens in event handler
end

-- ═══════════════════════════════════════════════════════════════
-- ─── 6. Spell Queue ──────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function ApplySpellQueue()
    local db = GetDB()
    if not db.SpellQueue then return end
    if InCombatLockdown() then return end

    local specID = GetSpecializationInfo(GetSpecialization())
    local base = db.SpellQueueSpecs and specID and db.SpellQueueSpecs[specID]
    if not base or base == 0 then
        base = db.SpellQueueGlobal or 400
    end

    if db.SpellQueueAI then
        local _, _, latencyHome = GetNetStats()
        base = base + (latencyHome or 0)
    end
    base = math.max(0, math.min(400, base))
    SetCVar("SpellQueueWindow", tostring(base))
end

local function InitSpellQueue()
    ApplySpellQueue()
    ToolsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

-- ═══════════════════════════════════════════════════════════════
-- ─── 7. YY Sound (Bloodlust/Heroism) ────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function InitYYSound()
    if YYSoundFrame then
        local db = GetDB()
        local sz = db.YYIconSize or 59
        YYSoundFrame:SetSize(sz, sz)
        YYSoundFrame:SetPoint("CENTER", UIParent, "CENTER", db.YYPosX or -390, db.YYPosY or 14)
        YYSoundFrame:SetShown(false)
        return
    end

    local db = GetDB()
    local sz = db.YYIconSize or 59

    YYSoundFrame = CreateFrame("Frame", "RRT_Tools_YYSoundFrame", UIParent)
    YYSoundFrame:SetSize(sz, sz)
    YYSoundFrame:SetPoint("CENTER", UIParent, "CENTER", db.YYPosX or -390, db.YYPosY or 14)
    YYSoundFrame:SetFrameStrata("HIGH")
    YYSoundFrame:Hide()

    -- Background icon (Bloodlust spell icon)
    YYIconTex = YYSoundFrame:CreateTexture(nil, "BACKGROUND")
    YYIconTex:SetAllPoints(YYSoundFrame)
    YYIconTex:SetTexture("Interface\\Icons\\Spell_Nature_TimeWarp")
    YYIconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown frame for the countdown animation
    YYCooldown = CreateFrame("Cooldown", "RRT_Tools_YYCooldown", YYSoundFrame, "CooldownFrameTemplate")
    YYCooldown:SetAllPoints(YYSoundFrame)
    YYCooldown:SetDrawEdge(true)
    YYCooldown:SetHideCountdownNumbers(false)
    YYCooldown:SetSwipeColor(0, 0, 0, 0.7)
end

local function TriggerYYSound()
    local db = GetDB()
    if not db.YYSound then return end

    -- Play sound
    if db.YYSoundFile and db.YYSoundFile ~= "None" and db.YYSoundFile ~= "" then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local path = LSM:Fetch("sound", db.YYSoundFile)
            if path then
                PlaySoundFile(path, "Master")
            end
        end
    end

    -- Show icon
    if db.YYShowIcon and YYSoundFrame then
        local sz = db.YYIconSize or 59
        YYSoundFrame:SetSize(sz, sz)
        YYSoundFrame:SetPoint("CENTER", UIParent, "CENTER", db.YYPosX or -390, db.YYPosY or 14)
        YYSoundFrame:Show()
        if YYCooldown then
            CooldownFrame_Set(YYCooldown, GetTime(), 40, 1, true)
        end
        C_Timer.After(40, function()
            if YYSoundFrame then YYSoundFrame:Hide() end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ─── 8. Bulk Buy Panel ──────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
local function InitBulkBuy()
    if BulkBuyPanel then return end

    BulkBuyPanel = CreateFrame("Frame", "RRT_Tools_BulkBuyPanel", UIParent, "BackdropTemplate")
    BulkBuyPanel:SetSize(280, 200)
    BulkBuyPanel:SetPoint("LEFT", MerchantFrame, "RIGHT", 4, 0)
    BulkBuyPanel:SetFrameStrata("DIALOG")
    BulkBuyPanel:SetMovable(true)
    BulkBuyPanel:EnableMouse(true)
    BulkBuyPanel:SetClampedToScreen(true)
    BulkBuyPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    BulkBuyPanel:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    BulkBuyPanel:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    BulkBuyPanel:SetScript("OnMouseDown", function(self) self:StartMoving() end)
    BulkBuyPanel:SetScript("OnMouseUp",   function(self) self:StopMovingOrSizing() end)
    BulkBuyPanel:Hide()

    BulkBuyPanel._selectedIndex = nil
    BulkBuyPanel._unitPrice = 0

    -- Title
    local title = BulkBuyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText("Bulk Buy")
    BulkBuyPanel.title = title

    -- Item name
    local itemLabel = BulkBuyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemLabel:SetPoint("TOPLEFT", 8, -26)
    itemLabel:SetSize(264, 20)
    itemLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    itemLabel:SetJustifyH("LEFT")
    itemLabel:SetText("")
    BulkBuyPanel.itemLabel = itemLabel

    -- Quantity EditBox
    local qtyLabel = BulkBuyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qtyLabel:SetPoint("TOPLEFT", 8, -52)
    qtyLabel:SetText("Quantity:")
    qtyLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    local qtyBox = CreateFrame("EditBox", "RRT_Tools_BulkBuyQtyBox", BulkBuyPanel, "InputBoxTemplate")
    qtyBox:SetSize(80, 20)
    qtyBox:SetPoint("LEFT", qtyLabel, "RIGHT", 6, 0)
    qtyBox:SetAutoFocus(false)
    qtyBox:SetNumeric(true)
    qtyBox:SetText("1")
    qtyBox:SetScript("OnTextChanged", function(self)
        local qty = tonumber(self:GetText()) or 0
        local total = qty * BulkBuyPanel._unitPrice
        local goldTotal = math.floor(total / 10000)
        local silverTotal = math.floor((total % 10000) / 100)
        local copperTotal = total % 100
        BulkBuyPanel.totalLabel:SetText(string.format("Total: |cFFFFD700%dg|r |cFFC0C0C0%ds|r %dc", goldTotal, silverTotal, copperTotal))
    end)
    BulkBuyPanel.qtyBox = qtyBox

    -- Total price label
    local totalLabel = BulkBuyPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalLabel:SetPoint("TOPLEFT", 8, -78)
    totalLabel:SetText("Total: 0g")
    totalLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    BulkBuyPanel.totalLabel = totalLabel

    -- Quick quantity buttons
    local quickQtys = {20, 50, 100, 200, 500, 999}
    for i, qty in ipairs(quickQtys) do
        local q = qty
        local btn = CreateFrame("Button", nil, BulkBuyPanel, "BackdropTemplate")
        btn:SetSize(40, 18)
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        btn:SetPoint("TOPLEFT", BulkBuyPanel, "TOPLEFT", 8 + col * 44, -100 - row * 22)
        btn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then lbl:SetFont(f, 9, fl or "") end end
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(tostring(q))
        btn:SetScript("OnClick", function()
            BulkBuyPanel.qtyBox:SetText(tostring(q))
            BulkBuyPanel.qtyBox:GetScript("OnTextChanged")(BulkBuyPanel.qtyBox)
        end)
        btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.25, 0.25, 0.25, 1) end)
        btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 0.9) end)
    end

    -- Buy button
    local buyBtn = CreateFrame("Button", nil, BulkBuyPanel, "BackdropTemplate")
    buyBtn:SetSize(120, 22)
    buyBtn:SetPoint("BOTTOMRIGHT", BulkBuyPanel, "BOTTOMRIGHT", -8, 8)
    buyBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    buyBtn:SetBackdropColor(0.1, 0.35, 0.1, 0.9)
    buyBtn:SetBackdropBorderColor(0.2, 0.6, 0.2, 1)
    local buyLbl = buyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then buyLbl:SetFont(f, 9, fl or "") end end
    buyLbl:SetPoint("CENTER", buyBtn, "CENTER", 0, 0)
    buyLbl:SetText("Buy")
    buyLbl:SetTextColor(0.9, 1, 0.9, 1)
    buyBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.15, 0.5, 0.15, 1) end)
    buyBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.1, 0.35, 0.1, 0.9) end)

    buyBtn:SetScript("OnClick", function()
        local db = GetDB()
        local idx = BulkBuyPanel._selectedIndex
        if not idx then return end
        local qty = tonumber(BulkBuyPanel.qtyBox:GetText()) or 0
        if qty <= 0 then return end

        local total = qty * BulkBuyPanel._unitPrice
        local warnCopper = (db.BulkBuyWarnGold or 0) * 10000

        local function DoPurchase()
            BuyMerchantItem(idx, qty)
            BulkBuyPanel:Hide()
        end

        if warnCopper > 0 and total > warnCopper then
            local goldTotal = math.floor(total / 10000)
            StaticPopupDialogs["RRT_BULKBUY_CONFIRM"] = {
                text = string.format("Buy %d items for |cFFFFD700%dg|r?", qty, goldTotal),
                button1 = "Yes",
                button2 = "No",
                OnAccept = DoPurchase,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("RRT_BULKBUY_CONFIRM")
        else
            DoPurchase()
        end
    end)

    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, BulkBuyPanel, "BackdropTemplate")
    cancelBtn:SetSize(60, 22)
    cancelBtn:SetPoint("BOTTOMLEFT", BulkBuyPanel, "BOTTOMLEFT", 8, 8)
    cancelBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    cancelBtn:SetBackdropColor(0.3, 0.1, 0.1, 0.9)
    cancelBtn:SetBackdropBorderColor(0.6, 0.2, 0.2, 1)
    local cancelLbl = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then cancelLbl:SetFont(f, 9, fl or "") end end
    cancelLbl:SetPoint("CENTER", cancelBtn, "CENTER", 0, 0)
    cancelLbl:SetText("Cancel")
    cancelLbl:SetTextColor(1, 0.7, 0.7, 1)
    cancelBtn:SetScript("OnClick", function() BulkBuyPanel:Hide() end)

    -- Hook merchant item right-click
    hooksecurefunc("MerchantItemButton_OnModifiedClick", function(self, button)
        if button ~= "RightButton" then return end
        local db = GetDB()
        if not db.BulkBuy then return end

        local index = self:GetID()
        local name, texture, price, quantity, numAvailable = GetMerchantItemInfo(index)
        if not name then return end

        BulkBuyPanel._selectedIndex = index
        BulkBuyPanel._unitPrice = price or 0
        BulkBuyPanel.itemLabel:SetText(name)
        BulkBuyPanel.qtyBox:SetText("1")
        BulkBuyPanel.qtyBox:GetScript("OnTextChanged")(BulkBuyPanel.qtyBox)
        BulkBuyPanel:Show()
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- ─── Event Handler ───────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════
ToolsFrame:SetScript("OnEvent", function(self, event, ...)
    local db = GetDB()

    if event == "DELETE_ITEM_CONFIRM" then
        if not db.AutoDelete then return end
        C_Timer.After(0.1, function()
            local popups = {
                "DELETE_GOOD_ITEM",
                "DELETE_GOOD_QUEST_ITEM",
                "DELETE_QUEST_ITEM",
                "DELETE_ITEM",
            }
            for _, popupName in ipairs(popups) do
                local popup = StaticPopup_Visible(popupName)
                if popup then
                    local dialog = _G["StaticPopup" .. popup]
                    if dialog and dialog.editBox then
                        dialog.editBox:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
                    end
                end
            end
        end)

    elseif event == "MERCHANT_SHOW" then
        if db.AutoSellJunk then
            C_MerchantFrame.SellAllJunkItems()
        end
        if db.AutoRepair then
            C_Timer.After(0.2, function()
                local repairCost, canRepair = GetRepairAllCost()
                if canRepair and repairCost and repairCost > 0 then
                    if db.AutoRepairGuild and CanGuildBankRepair() then
                        RepairAllItems(1)
                    else
                        RepairAllItems()
                    end
                    local gold = math.floor(repairCost / 10000)
                    local silver = math.floor((repairCost % 10000) / 100)
                    local copper = repairCost % 100
                    local source = (db.AutoRepairGuild and CanGuildBankRepair()) and " (Guild Bank)" or ""
                    print(string.format("|cFFBB66FFRRT|r Auto-Repair%s: |cFFFFD700%dg %ds %dc|r", source, gold, silver, copper))
                end
            end)
        end

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not db.TeleMsg or not db.TelemsgOnSuccess then return end
        local unit, _, spellID = ...
        if unit ~= "player" then return end
        local dungeonName = TELEPORT_SPELLS[spellID]
        if not dungeonName then return end
        if not IsInGroup() then return end
        local link = C_Spell.GetSpellLink(spellID) or GetSpellNameSafe(spellID) or tostring(spellID)
        local msg = db.TelemsgText or '[RRT] Casting %link, teleporting to "%name"'
        msg = msg:gsub("%%link", link):gsub("%%name", dungeonName)
        SendChatMessage(msg, IsInRaid() and "RAID" or "PARTY")

    elseif event == "UNIT_SPELLCAST_START" then
        if not db.TeleMsg or db.TelemsgOnSuccess then return end
        local unit, _, spellID = ...
        if unit ~= "player" then return end
        local dungeonName = TELEPORT_SPELLS[spellID]
        if not dungeonName then return end
        if not IsInGroup() then return end
        local link = C_Spell.GetSpellLink(spellID) or GetSpellNameSafe(spellID) or tostring(spellID)
        local msg = db.TelemsgText or '[RRT] Casting %link, teleporting to "%name"'
        msg = msg:gsub("%%link", link):gsub("%%name", dungeonName)
        SendChatMessage(msg, IsInRaid() and "RAID" or "PARTY")

    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit ~= "player" then return end
        if not db.YYSound then return end
        for buffID in pairs(BLOODLUST_SET) do
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(buffID)
            if aura then
                -- Only trigger once per application (track by expiry)
                local expiry = aura.expirationTime or 0
                if expiry ~= (ToolsFrame._lastYYExpiry or 0) then
                    ToolsFrame._lastYYExpiry = expiry
                    TriggerYYSound()
                end
                break
            end
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if db.SpellQueue then
            ApplySpellQueue()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- RefreshRangeCheck — called from Options when settings change
-- ═══════════════════════════════════════════════════════════════
local function RefreshRangeCheck()
    local db = GetDB()
    if not RangeCheckFrame then
        if db.RangeCheck then InitRangeCheck() end
        return
    end
    RangeCheckFrame:ClearAllPoints()
    RangeCheckFrame:SetPoint("CENTER", UIParent, "CENTER", db.RangeCheckPosX, db.RangeCheckPosY)
    if RangeText then
        local f = select(1, GameFontNormalLarge:GetFont())
        if f then RangeText:SetFont(f, db.RangeCheckFontSize, "OUTLINE") end
    end
    RangeCheckFrame:SetShown(db.RangeCheck)
end

-- ═══════════════════════════════════════════════════════════════
-- RefreshPlayerPosition — called from Options when settings change
-- ═══════════════════════════════════════════════════════════════
local function RefreshPlayerPosition()
    local db = GetDB()
    if not PlayerPosFrame then
        if db.PlayerPosition then InitPlayerPosition() end
        return
    end
    PlayerPosFrame:ClearAllPoints()
    PlayerPosFrame:SetPoint("CENTER", UIParent, "CENTER", db.PlayerPositionPosX, db.PlayerPositionPosY)
    BuildPlayerPosShape(db)
    PlayerPosFrame:SetShown(db.PlayerPosition)
end

-- ═══════════════════════════════════════════════════════════════
-- RefreshYYSound — called from Options when settings change
-- ═══════════════════════════════════════════════════════════════
local function RefreshYYSound()
    local db = GetDB()
    if not YYSoundFrame then return end
    local sz = db.YYIconSize or 59
    YYSoundFrame:SetSize(sz, sz)
    YYSoundFrame:SetPoint("CENTER", UIParent, "CENTER", db.YYPosX or -390, db.YYPosY or 14)
end

-- ═══════════════════════════════════════════════════════════════
-- RefreshAll — re-apply all settings
-- ═══════════════════════════════════════════════════════════════
local function RefreshAll()
    local db = GetDB()

    -- Range check
    RefreshRangeCheck()

    -- Player position
    RefreshPlayerPosition()

    -- YY Sound
    RefreshYYSound()

    -- Map info
    if MapInfoFrame then
        MapInfoFrame:SetShown(db.MapInfo)
    end

    -- Player position frame show/hide
    if PlayerPosFrame then
        PlayerPosFrame:SetShown(db.PlayerPosition)
    end

    -- TeleMsg events
    ToolsFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    ToolsFrame:UnregisterEvent("UNIT_SPELLCAST_START")
    if db.TeleMsg then
        if db.TelemsgOnSuccess then
            ToolsFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        else
            ToolsFrame:RegisterEvent("UNIT_SPELLCAST_START")
        end
    end

    -- UNIT_AURA for YY
    ToolsFrame:UnregisterEvent("UNIT_AURA")
    if db.YYSound then
        ToolsFrame:RegisterEvent("UNIT_AURA")
    end

    -- SpellQueue
    if db.SpellQueue then
        ApplySpellQueue()
    end
end

-- ═══════════════════════════════════════════════════════════════
-- Init — called from PLAYER_LOGIN in EventHandler
-- ═══════════════════════════════════════════════════════════════
local function Init()
    local db = GetDB()

    -- Register events for auto tools
    ToolsFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
    ToolsFrame:RegisterEvent("MERCHANT_SHOW")
    ToolsFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    ToolsFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    -- TeleMsg
    if db.TeleMsg then
        if db.TelemsgOnSuccess then
            ToolsFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        else
            ToolsFrame:RegisterEvent("UNIT_SPELLCAST_START")
        end
    end

    -- YY Sound aura tracking
    if db.YYSound then
        ToolsFrame:RegisterEvent("UNIT_AURA")
    end

    -- Detect initial instance state
    _wasInInstance = select(1, IsInInstance()) == true or IsInInstance()

    -- Init subsystems after a short delay so all frames exist
    C_Timer.After(0.5, function()
        InitAutoTools()
        InitMapInfo()
        if db.RangeCheck then InitRangeCheck() end
        if db.PlayerPosition then InitPlayerPosition() end
        InitYYSound()
        if db.SpellQueue then InitSpellQueue() end
        if db.BulkBuy and MerchantFrame then InitBulkBuy() end
    end)

    -- Bulk buy panel needs merchant frame to exist
    C_Timer.After(1, function()
        if db.BulkBuy and MerchantFrame and not BulkBuyPanel then
            InitBulkBuy()
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- Export
-- ═══════════════════════════════════════════════════════════════
RRT_NS.Tools = {
    GetDB                = GetDB,
    Init                 = Init,
    RefreshRangeCheck    = RefreshRangeCheck,
    RefreshPlayerPosition= RefreshPlayerPosition,
    RefreshYYSound       = RefreshYYSound,
    RefreshAll           = RefreshAll,
    ApplySpellQueue      = ApplySpellQueue,
    InitBulkBuy          = InitBulkBuy,
    InitMapInfo          = InitMapInfo,
    InitRangeCheck       = InitRangeCheck,
    InitPlayerPosition   = InitPlayerPosition,
    InitYYSound          = InitYYSound,
}



