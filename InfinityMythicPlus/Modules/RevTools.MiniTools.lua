-- [[ MiniTools ]]
-- { Key = "RevTools.MiniTools", Name = "MiniTools", Desc = "A collection of simple quality-of-life tweaks.", Category = 4 }

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

-- Global references
local UIParent = _G.UIParent


-- ========================================================================
-- 1. [ShowMapInfo] Map ID + cursor coordinates + player coordinates
-- ========================================================================
local function Init_ShowMapInfo()
    local db = InfinityTools:GetModuleDB("RevTools.MiniTools")
    local ANCHOR_MAP = {
        ["Bottom Left"] = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = 10, y = 10, align = "LEFT" },
        ["Top Left"] = { point = "TOPLEFT", relPoint = "TOPLEFT", x = 10, y = -10, align = "LEFT" },
        ["Bottom Right"] = { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -10, y = 10, align = "RIGHT" },
        ["Top Right"] = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -10, y = -10, align = "RIGHT" },
        ["Bottom Center"] = { point = "BOTTOM", relPoint = "BOTTOM", x = 0, y = 10, align = "CENTER" },
    }

    local frame = CreateFrame("Frame", "InfinityMapInfoWatcher", WorldMapFrame)
    frame:SetSize(520, 20)
    frame:SetFrameStrata("TOOLTIP")
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetAllPoints(frame)

    local function ApplyFont()
        local cfg = db.MapInfoFont
        local rawFont = (cfg and cfg.font and cfg.font ~= "" and cfg.font ~= "Default") and cfg.font or nil
        local font
        if rawFont then
            -- [Fix] fontgroup stores the LSM display name, so resolve it to a file path.
            local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
            if LSM then
                local resolved = LSM:Fetch("font", rawFont)
                font = (resolved and resolved ~= "") and resolved or (InfinityTools.MAIN_FONT or "Fonts\\ARHei.ttf")
            else
                font = InfinityTools.MAIN_FONT or "Fonts\\ARHei.ttf"
            end
        else
            font = InfinityTools.MAIN_FONT or "Fonts\\ARHei.ttf"
        end
        local size = (cfg and cfg.size) or 14
        local outline = (cfg and cfg.outline and cfg.outline ~= "NONE") and cfg.outline or ""
        text:SetFont(font, size, outline)
        text:SetTextColor(
            (cfg and cfg.r) or 1,
            (cfg and cfg.g) or 1,
            (cfg and cfg.b) or 1,
            (cfg and cfg.a) or 1
        )
        if cfg and cfg.shadow then
            text:SetShadowOffset(cfg.shadowX or 1, -1)
            text:SetShadowColor(0, 0, 0, 1)
        else
            text:SetShadowOffset(0, 0)
        end
    end

    local function ApplyAnchor()
        local anchor = ANCHOR_MAP[db.MapInfoAnchor] or ANCHOR_MAP["Bottom Left"]
        local frameTarget = WorldMapFrame.ScrollContainer or WorldMapFrame

        -- Apply the font offset settings.
        local cfg = db.MapInfoFont
        local offX = (anchor.x) + (cfg and cfg.x or 0)
        local offY = (anchor.y) + (cfg and cfg.y or 0)

        frame:ClearAllPoints()
        frame:SetPoint(anchor.point, frameTarget, anchor.relPoint, offX, offY)
        text:SetJustifyH(anchor.align)
    end

    local mapID = nil
    local function UpdateMapID()
        mapID = WorldMapFrame.mapID or C_Map.GetBestMapForUnit("player")
    end

    local function GetPlayerMapCoord()
        local currentMapID = WorldMapFrame.mapID or mapID or C_Map.GetBestMapForUnit("player")
        if not currentMapID then return nil, nil end

        local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
        if not pos then return nil, nil end

        local px, py = pos:GetXY()
        if type(px) ~= "number" or type(py) ~= "number" then return nil, nil end
        return px * 100, py * 100
    end

    frame:SetScript("OnUpdate", function()
        if not WorldMapFrame:IsVisible() then return end

        local hideMapID = (db.MapInfoHideMapID ~= false) -- nil follows the default "hide Map ID" behavior
        local showMapID = not hideMapID
        local mapText = showMapID and string.format(L["MapID: %s"], mapID or "?") or nil
        local pX, pY = GetPlayerMapCoord()
        local hasPlayerCoord = (type(pX) == "number" and type(pY) == "number")
        local canvas = WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
        if canvas and canvas:IsMouseOver() then
            local nx, ny = WorldMapFrame:GetNormalizedCursorPosition()
            if nx and ny then
                if hasPlayerCoord then
                    if mapText then
                        text:SetText(string.format("%s  " .. L["Mouse: %.2f, %.2f  Player: %.2f, %.2f"], mapText, nx * 100,  -- TODO: missing key: L["Mouse: %.2f, %.2f  Player: %.2f, %.2f"]
                            ny * 100, pX, pY))
                    else
                        text:SetText(string.format(L["Mouse: %.2f, %.2f  Player: %.2f, %.2f"], nx * 100, ny * 100, pX, pY))  -- TODO: missing key: L["Mouse: %.2f, %.2f  Player: %.2f, %.2f"]
                    end
                else
                    if mapText then
                        text:SetText(string.format("%s  " .. L["Mouse: %.2f, %.2f"], mapText, nx * 100, ny * 100))  -- TODO: missing key: L["Mouse: %.2f, %.2f"]
                    else
                        text:SetText(string.format(L["Mouse: %.2f, %.2f"], nx * 100, ny * 100))  -- TODO: missing key: L["Mouse: %.2f, %.2f"]
                    end
                end
                return
            end
        end
        if hasPlayerCoord then
            if mapText then
                text:SetText(string.format("%s  " .. L["Player: %.2f, %.2f"], mapText, pX, pY))  -- TODO: missing key: L["Player: %.2f, %.2f"]
            else
                text:SetText(string.format(L["Player: %.2f, %.2f"], pX, pY))  -- TODO: missing key: L["Player: %.2f, %.2f"]
            end
        else
            text:SetText(mapText or "")
        end
    end)

    hooksecurefunc(WorldMapFrame, "OnMapChanged", UpdateMapID)
    InfinityTools:RegisterEvent("ZONE_CHANGED_NEW_AREA", "RevTools_Mini_MapInfo", UpdateMapID)

    InfinityTools:WatchState("RevTools.MiniTools.DatabaseChanged", "RevTools_MapInfo_ConfigUpdate", function(info)
        if not info or not info.key then return end
        if string.find(info.key, "MapInfoFont") then
            ApplyFont()
            ApplyAnchor() -- Coordinates may have changed
        end
        if info.key == "MapInfoAnchor" then ApplyAnchor() end
    end)

    UpdateMapID()
    ApplyFont()
    ApplyAnchor()
end

-- ========================================================================
-- 2. [AutoDelete] Automatic delete confirmation
-- ========================================================================
local function Init_AutoDelete()
    local DELETE_STR = DELETE_ITEM_CONFIRM_STRING or "DELETE"
    InfinityTools:RegisterEvent("DELETE_ITEM_CONFIRM", "RevTools_Mini_AutoDelete", function()
        C_Timer.After(0.1, function()
            local popupList = { "DELETE_GOOD_ITEM", "DELETE_GOOD_QUEST_ITEM", "DELETE_QUEST_ITEM" }
            for _, which in ipairs(popupList) do
                local dialog = StaticPopup_FindVisible(which)
                if dialog and dialog.GetEditBox then
                    local box = dialog:GetEditBox()
                    if box then box:SetText(DELETE_STR) end
                end
            end
        end)
    end)
end

-- ========================================================================
-- 3. [AutoSellJunk] Auto sell junk
-- ========================================================================
local function Init_AutoSellJunk()
    InfinityTools:RegisterEvent("MERCHANT_SHOW", "RevTools_Mini_Junk", function()
        if C_MerchantFrame and C_MerchantFrame.SellAllJunkItems then
            C_MerchantFrame.SellAllJunkItems()
        end
    end)
end

-- ========================================================================
-- 4. [AutoCombatLog] Automatic combat logging
-- ========================================================================
local function Init_AutoCombatLog()
    local function CheckLog()
        -- Read flattened settings directly from db.ACL_xyz.
        -- These keys must match INFINITY_DEFAULTS.
        local db = InfinityTools:GetModuleDB("RevTools.MiniTools")
        if not db then return end

        local _, _, dID = GetInstanceInfo()
        local shouldLog = false

        -- 5-player dungeons
        if dID == 1 and db.ACL_DungeonNormal then shouldLog = true end
        if dID == 2 and db.ACL_DungeonHeroic then shouldLog = true end
        if dID == 23 and db.ACL_DungeonMythic then shouldLog = true end
        if dID == 8 and db.ACL_DungeonChallenge then shouldLog = true end
        if dID == 205 and db.ACL_DungeonFollower then shouldLog = true end

        -- Raids
        if dID == 17 and db.ACL_RaidLFR then shouldLog = true end
        if dID == 14 and db.ACL_RaidNormal then shouldLog = true end
        if dID == 15 and db.ACL_RaidHeroic then shouldLog = true end
        if dID == 16 and db.ACL_RaidMythic then shouldLog = true end

        local isLogging = LoggingCombat()
        if shouldLog and not isLogging then
            LoggingCombat(true)
            print("|cff00ff00[Rev] " .. L["Entered instance, combat logging enabled automatically"] .. "|r")
        elseif not shouldLog and isLogging then
            LoggingCombat(false)
            print("|cffff0000[Rev] " .. L["Left instance, combat logging disabled automatically"] .. "|r")
        end
    end

    InfinityTools:RegisterEvent("ZONE_CHANGED_NEW_AREA", "RevTools_Mini_ACL", CheckLog)
    InfinityTools:RegisterEvent("CHALLENGE_MODE_START", "RevTools_Mini_ACL", CheckLog)
    InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", "RevTools_Mini_ACL", CheckLog)
    C_Timer.After(3, CheckLog)
end

-- ========================================================================
-- 5. [BulkBuy] Bulk purchase helper
-- ========================================================================
local function Init_BulkBuy()
    -- Fetch DB lazily to ensure the latest values.
    local function GetDB()
        return InfinityTools:GetModuleDB("RevTools.MiniTools")
    end

    -- Build UI frame
    local Frame = CreateFrame("Frame", "InfinityMerchantBulkFrame", MerchantFrame, "BackdropTemplate")
    Frame:SetSize(240, 420)
    Frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 5, -20)
    Frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    Frame:Hide()
    Frame:SetFrameStrata("DIALOG")

    -- Close button
    Frame.CloseBtn = CreateFrame("Button", nil, Frame, "UIPanelCloseButton")
    Frame.CloseBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Title
    Frame.Title = Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    Frame.Title:SetPoint("TOP", 0, -20)
    Frame.Title:SetText(L["Bulk Buy"])

    -- Icon
    Frame.Icon = Frame:CreateTexture(nil, "ARTWORK")
    Frame.Icon:SetSize(50, 50)
    Frame.Icon:SetPoint("TOP", 0, -50)

    -- Item name
    Frame.ItemName = Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    Frame.ItemName:SetPoint("TOP", Frame.Icon, "BOTTOM", 0, -10)
    Frame.ItemName:SetWidth(240)
    Frame.ItemName:SetWordWrap(true)

    -- Stack size
    Frame.StackInfo = Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Frame.StackInfo:SetPoint("TOP", Frame.ItemName, "BOTTOM", 0, -5)

    -- EditBox
    Frame.Input = CreateFrame("EditBox", nil, Frame, "InputBoxTemplate")
    Frame.Input:SetSize(120, 30)
    Frame.Input:SetPoint("TOP", Frame.StackInfo, "BOTTOM", 0, -15)
    Frame.Input:SetAutoFocus(false)
    Frame.Input:SetNumeric(true)
    Frame.Input:SetFontObject(ChatFontNormal)

    Frame:SetScript("OnKeyDown", function(self, key) if key == "ESCAPE" then self:Hide() end end)
    Frame.Input:SetScript("OnEscapePressed", function() Frame:Hide() end)

    -- State variables
    local currentIndex = 0
    local currentMaxStack = 1
    local currentPrice = 0

    local function GetMerchantInfoSafe(index)
        if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
            local info = C_MerchantFrame.GetItemInfo(index)
            if info then
                return info.name, info.texture, info.price, info.stackCount, info.numAvailable, info.isUsable,
                    info.extendedCost
            end
        end
        if GetMerchantItemInfo then return GetMerchantItemInfo(index) end
    end

    local function UpdateFrame(index)
        local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantInfoSafe(index)
        if not name then return end
        local link = GetMerchantItemLink(index)
        local maxStack = 20
        if GetMerchantItemMaxStack then
            maxStack = GetMerchantItemMaxStack(index)
        elseif link then
            maxStack = select(8, C_Item.GetItemInfo(link)) or 20
        end

        currentIndex = index
        currentMaxStack = maxStack or 20
        currentPrice = price

        Frame.Icon:SetTexture(texture)
        Frame.ItemName:SetText(link or name)
        Frame.StackInfo:SetText(L["Max Stack: "] .. currentMaxStack)

        Frame.Input:SetNumber(currentMaxStack)
        Frame.Input:SetFocus()
        Frame.Input:HighlightText()
        Frame:Show()
    end

    -- Confirmation dialog
    StaticPopupDialogs["INFINITY_BULK_BUY_CONFIRM"] = {
        text = L["This purchase will cost %s\nBuy %s?"],
        button1 = YES,
        button2 = NO,
        OnAccept = function(self) self.data.callback() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local function BuyBatch(index, remaining, callback)
        if remaining <= 0 then
            if callback then callback() end
            return
        end
        local BATCH_LIMIT = 200
        local thisBatch = math.min(remaining, BATCH_LIMIT)
        local stack = currentMaxStack
        local processed = 0
        local callCount = 0
        while processed < thisBatch do
            local buy = math.min(stack, thisBatch - processed)
            BuyMerchantItem(index, buy)
            processed = processed + buy
            callCount = callCount + 1
        end
        local left = remaining - thisBatch
        if left > 0 then
            -- Adjust delay based on the number of API calls in this batch.
            local delay
            if callCount <= 5 then
                delay = 0.3
            elseif callCount <= 20 then
                delay = 0.8
            else
                delay = 2
            end
            C_Timer.After(delay, function() BuyBatch(index, left, callback) end)
        else
            if callback then callback() end
        end
    end

    local function ExecuteBuy()
        local amount = tonumber(Frame.Input:GetText()) or 0
        if amount <= 0 or currentIndex == 0 then return end

        Frame.BuyBtn:Disable()
        Frame.BuyBtn:SetText(L["Buying..."])
        BuyBatch(currentIndex, amount, function()
            Frame.BuyBtn:Enable()
            Frame.BuyBtn:SetText(L["Buy"])
            Frame.Input:ClearFocus()
            Frame:Hide()
        end)
    end

    local function DoBuyCheck()
        local amount = tonumber(Frame.Input:GetText()) or 0
        if amount <= 0 then return end
        local db = GetDB()

        if currentPrice and currentPrice > 0 then
            local totalCopper = currentPrice * amount
            local thresholdGold = tonumber(db.BulkBuy_WarnThreshold) or 1000
            if thresholdGold > 0 and (totalCopper / 10000) >= thresholdGold then
                local priceStr = GetMoneyString(totalCopper, true)
                local itemLink = GetMerchantItemLink(currentIndex) or L["item"]
                local descStr = string.format(L["%d x %s"], amount, itemLink)
                StaticPopup_Show("INFINITY_BULK_BUY_CONFIRM", priceStr, descStr, { callback = ExecuteBuy })
                return
            end
        end
        ExecuteBuy()
    end

    Frame.TotalPrice = Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    Frame.TotalPrice:SetPoint("TOP", Frame.Input, "BOTTOM", 0, 40)
    Frame.Input:SetScript("OnTextChanged", function(self)
        local amount = tonumber(self:GetText()) or 0
        if currentPrice and currentPrice > 0 and amount > 0 then
            Frame.TotalPrice:SetText(L["Total: "] .. GetMoneyString(currentPrice * amount, true))
        else
            Frame.TotalPrice:SetText("")
        end
    end)

    Frame.BuyBtn = CreateFrame("Button", nil, Frame, "UIPanelButtonTemplate")
    Frame.BuyBtn:SetSize(160, 40)
    Frame.BuyBtn:SetPoint("BOTTOM", 0, 100)
    Frame.BuyBtn:SetText(L["Buy"])
    Frame.BuyBtn:SetScript("OnClick", DoBuyCheck)
    Frame.Input:SetScript("OnEnterPressed", DoBuyCheck)

    -- Quick buttons
    local function AddQuickBtn(label, val, x, y, width)
        local btn = CreateFrame("Button", nil, Frame, "UIPanelButtonTemplate")
        btn:SetSize(width or 60, 22)
        btn:SetPoint("TOPLEFT", Frame.Input, "BOTTOMLEFT", x, y)
        btn:SetText(label)
        btn:SetScript("OnClick", function()
            Frame.Input:SetNumber(val); Frame.Input:HighlightText()
        end)
    end
    local y1, y2, w = -10, -40, 60
    AddQuickBtn("20", 20, -35, y1, w); AddQuickBtn("50", 50, 30, y1, w); AddQuickBtn("100", 100, 95, y1, w)
    AddQuickBtn("200", 200, -35, y2, w); AddQuickBtn("500", 500, 30, y2, w); AddQuickBtn("999", 999, 95, y2, w)

    -- Hook
    local Original_MerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick
    MerchantItemButton_OnModifiedClick = function(self, button)
        local db = GetDB()
        if db.BulkBuy and button == "RightButton" and MerchantFrame.selectedTab == 1 and IsModifiedClick("SPLITSTACK") then
            local index = self:GetID()
            UpdateFrame(index)
            return
        end
        if Original_MerchantItemButton_OnModifiedClick then
            Original_MerchantItemButton_OnModifiedClick(self, button)
        end
    end

    InfinityTools:RegisterEvent("MERCHANT_CLOSED", "RevTools_Mini_BulkBuy", function() Frame:Hide() end)
end

-- ========================================================================
-- 6. [ResetDMG] Reset damage meters when entering an instance
-- ========================================================================
local function Init_ResetDamageMeter()
    _G.StaticPopupDialogs["INFINITY_RESET_DMG_METER"] = {
        text = L["Instance detected. Reset damage meter data?"],
        button1 = _G.YES,
        button2 = _G.NO,
        OnAccept = function()
            local CDM = _G.C_DamageMeter
            if CDM and CDM.ResetAllCombatSessions then
                CDM.ResetAllCombatSessions()
                print("|cff00ff00[InfinityTools] " .. L["Damage meter data has been reset"] .. "|r")
            else
                print("|cffff0000[InfinityTools] " .. L["Error: C_DamageMeter.ResetAllCombatSessions API is unavailable"] .. "|r")
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    -- [Critical Fix] Record the initial real state.
    -- If the player is already in an instance during init, ignore the false->true transition from State sync.
    local lastInInstance = IsInInstance()

    InfinityTools:WatchState("InInstance", "RevTools_Mini_ResetDMG", function(inInstance)
        -- Trigger only on a real outdoor -> instance transition.
        if inInstance and lastInInstance == false then
            _G.StaticPopup_Show("INFINITY_RESET_DMG_METER")
        end
        lastInInstance = inInstance
    end)
end

-- ========================================================================
-- 9. [AutoRepair] Automatic repair
-- ========================================================================
local function Init_AutoRepair()
    local function GetDB() return InfinityTools:GetModuleDB("RevTools.MiniTools") end

    local function TryRepair()
        local db = GetDB()
        if not db.AutoRepair then return end
        if not CanMerchantRepair() then return end

        -- Prefer guild bank repairs first.
        if db.AutoRepair_UseGuildBank and CanGuildBankRepair() then
            local cost = GetRepairAllCost()
            if cost and cost > 0 then
                RepairAllItems(true)
                if db.AutoRepair_ShowMessage then
                    local gold = GetMoneyString(cost, true)
                    print(string.format("|cffffd100[InfinityTools]|r " .. L["Repaired all gear using guild bank funds for %s"], gold))
                end
            end
            return
        end

        -- Fallback to personal funds.
        local cost, canRepair = GetRepairAllCost()
        if canRepair and cost and cost > 0 then
            RepairAllItems()
            if db.AutoRepair_ShowMessage then
                local gold = GetMoneyString(cost, true)
                print(string.format("|cffffd100[InfinityTools]|r " .. L["Automatically repaired all gear for %s"], gold))
            end
        end
    end

    InfinityTools:RegisterEvent("MERCHANT_SHOW", "RevTools_Mini_AutoRepair", TryRepair)
end

-- ========================================================================
-- 8. [HideBattleTag] BattleTag masking
-- ========================================================================
local function Init_HideBattleTag()
    local Hooked = false

    local function Apply()
        local db = InfinityTools:GetModuleDB("RevTools.MiniTools")
        local target = FriendsFrameBattlenetFrame and FriendsFrameBattlenetFrame.Tag
        if not target then return end

        if db.HideBattleTag then
            local fakeName = db.BattleTagText or ""
            if target:GetText() ~= fakeName then
                target:SetText(fakeName)
                target:SetTextColor(0.345, 0.667, 0.867)
            end
        end
    end

    -- Hook logic
    if FriendsFrameBattlenetFrame and FriendsFrameBattlenetFrame.Tag then
        hooksecurefunc(FriendsFrameBattlenetFrame.Tag, "SetText", function(self, text)
            local db = InfinityTools:GetModuleDB("RevTools.MiniTools")
            if not db.HideBattleTag then return end

            local fakeName = db.BattleTagText or ""
            -- Only override when the text differs to avoid recursion.
            if text ~= fakeName then
                self:SetText(fakeName)
                self:SetTextColor(0.345, 0.667, 0.867)
            end
        end)
    end

    InfinityTools:WatchState("RevTools.MiniTools.DatabaseChanged", "RevTools_HideBattleTag", function(info)
        if info.key == "HideBattleTag" or info.key == "BattleTagText" then
            Apply()
        end
    end)

    Apply()
end

-- ========================================================================
-- 10. [EJTooltip] Encounter Journal tooltip enhancement
-- ========================================================================
local function Init_EJTooltip()
    local EJ_TOOLTIP = {}

    function EJ_TOOLTIP:OnEnter(button)
        local db = InfinityTools:GetModuleDB("RevTools.MiniTools")
        if not db.EJTooltip then return end
        local parent = button:GetParent()
        if not parent then return end

        local spellID = parent.spellID
        if spellID and spellID > 0 then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            if GameTooltip.SetSpellByID then
                GameTooltip:SetSpellByID(spellID)
            else
                local link = GetSpellLink(spellID)
                if link then GameTooltip:SetHyperlink(link) end
            end

            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("|cff00ff00SpellID:|r", "|cffffd100" .. spellID .. "|r")
            GameTooltip:Show()
        end
    end

    function EJ_TOOLTIP:OnLeave()
        if GameTooltip:IsForbidden() then return end
        GameTooltip:Hide()
    end

    function EJ_TOOLTIP:HookHeaders()
        if not EncounterJournal then return end

        local usedHeaders = EncounterJournal.encounter and EncounterJournal.encounter.usedHeaders
        if usedHeaders then
            for _, header in ipairs(usedHeaders) do
                if header.button and not header.button.INFINITY_EJ_Hooked then
                    header.button:HookScript("OnEnter", function(s) self:OnEnter(s) end)
                    header.button:HookScript("OnLeave", function() self:OnLeave() end)
                    header.button.INFINITY_EJ_Hooked = true
                end
            end
        end

        local overviewFrame = EncounterJournal.encounter and EncounterJournal.encounter.overviewFrame
        if overviewFrame and overviewFrame.overviews then
            for _, header in ipairs(overviewFrame.overviews) do
                if header.button and not header.button.INFINITY_EJ_Hooked then
                    header.button:HookScript("OnEnter", function(s) self:OnEnter(s) end)
                    header.button:HookScript("OnLeave", function() self:OnLeave() end)
                    header.button.INFINITY_EJ_Hooked = true
                end
            end
        end
    end

    local function SetupHooks()
        hooksecurefunc("EncounterJournal_ToggleHeaders", function() EJ_TOOLTIP:HookHeaders() end)
        hooksecurefunc("EncounterJournal_SetUpOverview", function() EJ_TOOLTIP:HookHeaders() end)

        hooksecurefunc("EncounterJournal_SetTooltipWithCompare", function(tooltip, link)
            local db = InfinityTools:GetModuleDB("RevTools.MiniTools")
            if not db.EJTooltip or not link then return end
            local type, id = link:match("H(%a+):(%d+)")
            if id then
                tooltip:AddLine(" ")
                local label = (type == "spell") and "SpellID:" or "ID:"
                tooltip:AddDoubleLine("|cff00ff00" .. label .. "|r", "|cffffd100" .. id .. "|r")
                tooltip:Show()
            end
        end)
    end

    if C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
        SetupHooks()
        EJ_TOOLTIP:HookHeaders()
    else
        InfinityTools:RegisterEvent("ADDON_LOADED", "RevTools_Mini_EJTooltip", function(_, addonName)
            if addonName == "Blizzard_EncounterJournal" then
                SetupHooks()
                C_Timer.After(0.1, function() EJ_TOOLTIP:HookHeaders() end)
            end
        end)
    end
end

-- ========================================================================
-- 11. [MerchantExpansion] Wider merchant frame
-- ========================================================================
local function Init_MerchantExpansion()
    local function GetDB() return InfinityTools:GetModuleDB("RevTools.MiniTools") end

    -- Track current width for the repair button hook.
    local currentMerchantWidth = 0
    local merchantBottomBorderLeft, merchantBottomBorderRight

    local function EnsureBottomBorderParts()
        if merchantBottomBorderLeft and merchantBottomBorderRight then
            return
        end

        merchantBottomBorderLeft = MerchantFrame:CreateTexture(nil, "OVERLAY")
        merchantBottomBorderLeft:SetAtlas("UI-Merchant-BotFrame")
        merchantBottomBorderLeft:SetTexCoord(0, 0.495, 0, 1)

        merchantBottomBorderRight = MerchantFrame:CreateTexture(nil, "OVERLAY")
        merchantBottomBorderRight:SetAtlas("UI-Merchant-BotFrame")
        merchantBottomBorderRight:SetTexCoord(0.505, 1, 0, 1)
    end

    -- Bottom border handling:
    -- The native texture has a visible seam in the middle, so stretch one segment across the full width.
    -- This avoids a center seam.
    local function UpdateBottomBorder(isBuyback, newWidth)
        EnsureBottomBorderParts()

        if MerchantFrameBottomLeftBorder then
            MerchantFrameBottomLeftBorder:Hide()
        end

        if isBuyback then
            if merchantBottomBorderLeft then merchantBottomBorderLeft:Hide() end
            if merchantBottomBorderRight then merchantBottomBorderRight:Hide() end
            return
        end

        merchantBottomBorderLeft:Show()
        merchantBottomBorderLeft:ClearAllPoints()
        merchantBottomBorderLeft:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 1, 26)
        merchantBottomBorderLeft:SetPoint("TOPRIGHT", MerchantFrame, "BOTTOMRIGHT", -1, 87)
        merchantBottomBorderLeft:SetTexCoord(0.02, 0.47, 0, 1)

        merchantBottomBorderRight:Hide()
    end

    -- Re-anchor bottom insets to avoid visible seams after widening.
    local function UpdateBottomInsets(newWidth)
        -- Blizzard splits the bottom into two insets (currency + money),
        -- which creates a visible seam when widened. Replace it with one full-width inset.
        if MerchantExtraCurrencyInset then
            MerchantExtraCurrencyInset:Hide()
        end
        if MerchantExtraCurrencyBg then
            MerchantExtraCurrencyBg:Hide()
        end

        if MerchantMoneyInset then
            MerchantMoneyInset:Show()
            MerchantMoneyInset:ClearAllPoints()
            MerchantMoneyInset:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMLEFT", 4, 27)
            MerchantMoneyInset:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -5, 4)
            if MerchantMoneyInset.Bg then
                MerchantMoneyInset.Bg:SetTexture("Interface\\Buttons\\WHITE8X8")
                MerchantMoneyInset.Bg:SetHorizTile(false)
                MerchantMoneyInset.Bg:SetVertTile(false)
                MerchantMoneyInset.Bg:SetVertexColor(0, 0, 0, 0.35)
            end
        end

        if MerchantMoneyBg then
            MerchantMoneyBg:Show()
            MerchantMoneyBg:ClearAllPoints()
            MerchantMoneyBg:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMLEFT", 7, 25)
            MerchantMoneyBg:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -7, 6)
            if MerchantMoneyBgMiddle then
                MerchantMoneyBgMiddle:SetTexture("Interface\\Buttons\\WHITE8X8")
                MerchantMoneyBgMiddle:SetTexCoord(0, 1, 0, 1)
                MerchantMoneyBgMiddle:SetVertexColor(0, 0, 0, 1)
            end
        end
    end

    -- Repair/sell junk button placement.
    -- This avoids stacked SetPoint anchors from MerchantFrame_UpdateRepairButtons.
    local function FixRepairButtons()
        if not MerchantFrame or not MerchantFrame:IsShown() then return end
        local centerX = currentMerchantWidth / 2
        local btnY = 34

        -- Blizzard's MerchantFrame_UpdateRepairButtons calls SetPoint without clearing previous anchors.
        -- ClearAllPoints first so each button has only one anchor.
        if MerchantRepairAllButton and MerchantRepairAllButton:IsShown() then
            MerchantRepairAllButton:ClearAllPoints()
            MerchantRepairAllButton:SetPoint("BOTTOM", MerchantFrame, "BOTTOMLEFT", centerX + 10, btnY)
        end

        if MerchantRepairItemButton and MerchantRepairItemButton:IsShown() then
            MerchantRepairItemButton:ClearAllPoints()
            MerchantRepairItemButton:SetPoint("RIGHT", MerchantRepairAllButton, "LEFT", -4, 0)
        end

        if MerchantSellAllJunkButton then
            MerchantSellAllJunkButton:ClearAllPoints()
            if MerchantRepairAllButton and MerchantRepairAllButton:IsShown() then
                -- Sell Junk sits to the right of Repair All.
                MerchantSellAllJunkButton:SetPoint("LEFT", MerchantRepairAllButton, "RIGHT", 12, 0)
            else
                -- Center it when the repair button is hidden.
                MerchantSellAllJunkButton:SetPoint("BOTTOM", MerchantFrame, "BOTTOMLEFT", centerX, btnY)
            end
        end

        if MerchantGuildBankRepairButton and MerchantGuildBankRepairButton:IsShown() then
            MerchantGuildBankRepairButton:ClearAllPoints()
            MerchantGuildBankRepairButton:SetPoint("LEFT", MerchantSellAllJunkButton, "RIGHT", 4, 0)
        end
    end

    local function ApplyLayout()
        if not MerchantFrame then return end
        local db = GetDB()
        local cols = tonumber(db.MerchantColumns) or 3
        -- Preserve Blizzard's original height: 5 rows on Merchant, 6 rows on Buyback.
        local isBuyback = (MerchantFrame.selectedTab == 2)
        local rows = isBuyback and 6 or 5
        local itemsPerPage = cols * rows

        _G.MERCHANT_ITEMS_PER_PAGE = itemsPerPage
        _G.BUYBACK_ITEMS_PER_PAGE = itemsPerPage

        -- Create extra item slots as needed for 2-5 columns.
        for i = 1, 30 do
            local name = "MerchantItem" .. i
            local f = _G[name]
            if i <= itemsPerPage then
                if not f then
                    f = CreateFrame("Frame", name, MerchantFrame, "MerchantItemTemplate")
                end
                f:Show()
            elseif f then
                f:Hide()
            end
        end

        local itemWidth = 153
        local spacingX = 12
        local newWidth = 11 + cols * itemWidth + (cols - 1) * spacingX + 19
        local originalHeight = 444 -- Lock Blizzard's original height

        MerchantFrame:SetSize(newWidth, originalHeight)
        currentMerchantWidth = newWidth

        UpdateBottomBorder(isBuyback, newWidth)
        UpdateBottomInsets(newWidth)

        -- Center page text and buttons.
        local centerX = newWidth / 2
        if MerchantPageText then
            MerchantPageText:ClearAllPoints()
            MerchantPageText:SetPoint("BOTTOM", MerchantFrame, "BOTTOMLEFT", centerX, 86)
        end
        if MerchantPrevPageButton then
            MerchantPrevPageButton:ClearAllPoints()
            MerchantPrevPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOMLEFT", 25, 96)
        end
        if MerchantNextPageButton then
            MerchantNextPageButton:ClearAllPoints()
            MerchantNextPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOMLEFT", newWidth - 26, 96)
        end

        -- FixRepairButtons owns repair/junk button positioning.
        FixRepairButtons()
    end

    local function PositionItems()
        if not MerchantFrame or not MerchantFrame:IsShown() then return end
        local db = GetDB()
        local cols = tonumber(db.MerchantColumns) or 3
        local isBuyback = MerchantFrame.selectedTab == 2
        local offset_y = isBuyback and 15 or 8
        local rows = isBuyback and 6 or 5

        for i = 1, cols * rows do
            local item = _G["MerchantItem" .. i]
            if item then
                item:ClearAllPoints()
                if i == 1 then
                    item:SetPoint("TOPLEFT", 11, -69) -- Original row start
                elseif (i - 1) % cols == 0 then
                    -- New row
                    item:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - cols)], "BOTTOMLEFT", 0, -offset_y)
                else
                    -- Same row
                    item:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", 12, 0)
                end
            end
        end

        -- BuyBackItem is normally anchored to MerchantItem10, which breaks when column count changes.
        -- Pin it to the right side of the frame so it stays away from the repair buttons.
        if MerchantBuyBackItem and not isBuyback then
            MerchantBuyBackItem:ClearAllPoints()
            MerchantBuyBackItem:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -8, 33)
        end
    end

    hooksecurefunc("MerchantFrame_Update", function()
        ApplyLayout()
        PositionItems()
    end)

    -- Blizzard's MerchantFrame_UpdateRepairButtons stacks SetPoint anchors without ClearAllPoints.
    -- Re-apply clean anchors after Blizzard finishes.
    hooksecurefunc("MerchantFrame_UpdateRepairButtons", function()
        FixRepairButtons()
    end)

    MerchantFrame:HookScript("OnShow", function()
        ApplyLayout()
        PositionItems()
    end)

    InfinityTools:WatchState("RevTools.MiniTools.DatabaseChanged", "RevTools_Merchant_Update", function(info)
        if info.key == "MerchantExpansion" or info.key == "MerchantColumns" then
            ApplyLayout()
            PositionItems()
            if MerchantFrame:IsShown() then MerchantFrame_Update() end
        end
    end)
end

-- ========================================================================
-- 12. [MacroEnhancement] Macro UI enhancement (migrated from RevTools.MacroExtension)
-- Only exposes an enable/disable toggle, no extra settings.
-- ========================================================================
local function Init_MacroEnhancement()
    local DB_KEY = "RevTools.MiniTools"
    local OWNER_PREFIX = "RevTools_Mini_MacroEnhance"

    local BASE_WIDTH = 338
    local BASE_HEIGHT = 424
    local TARGET_WIDTH = 500
    local TARGET_HEIGHT = 560

    local SpellIconKeywordMap = {}
    local IconPathFileIDCache = {}
    local IconFileIDProbeTexture = nil
    local HooksInstalled = false

    local function IsFeatureEnabled()
        local db = InfinityTools:GetModuleDB(DB_KEY)
        return db and db.MacroEnhancement
    end

    local function TrimText(text)
        if not text then return "" end
        text = string.gsub(text, "^%s+", "")
        text = string.gsub(text, "%s+$", "")
        return text
    end

    local function Clamp(value, minValue, maxValue)
        if value < minValue then return minValue end
        if value > maxValue then return maxValue end
        return value
    end

    local function UpdateSearchBoxVisual(searchBox)
        if not searchBox then return end
        if SearchBoxTemplate_OnTextChanged then
            SearchBoxTemplate_OnTextChanged(searchBox)
        elseif searchBox.Instructions then
            searchBox.Instructions:SetShown(searchBox:GetText() == "")
        end
    end

    local function AddIconKeyword(map, icon, keyword)
        if not icon or not keyword or keyword == "" then return end
        local normalized = string.lower(keyword)
        local current = map[icon]
        if not current then
            map[icon] = normalized
            return
        end
        if not string.find(current, normalized, 1, true) then
            map[icon] = current .. "\n" .. normalized
        end
    end

    local function RebuildSpellIconKeywordMap()
        SpellIconKeywordMap = {}
        if not C_SpellBook or not Enum or not Enum.SpellBookSpellBank then
            return
        end

        local skillLineCount = C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetNumSpellBookSkillLines() or 0
        for skillLineIndex = 1, skillLineCount do
            local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
            if skillLineInfo then
                for i = 1, skillLineInfo.numSpellBookItems do
                    local slotIndex = skillLineInfo.itemIndexOffset + i
                    local icon = C_SpellBook.GetSpellBookItemTexture(slotIndex, Enum.SpellBookSpellBank.Player)
                    local name, subName = C_SpellBook.GetSpellBookItemName(slotIndex, Enum.SpellBookSpellBank.Player)
                    AddIconKeyword(SpellIconKeywordMap, icon, name)
                    AddIconKeyword(SpellIconKeywordMap, icon, subName)
                end
            end
        end
    end

    local function GetIconFileID(icon)
        if not icon then return nil end
        if type(icon) == "number" then return icon end
        if type(icon) ~= "string" then return nil end

        local cached = IconPathFileIDCache[icon]
        if cached ~= nil then
            return cached
        end

        local fileID = nil
        if GetFileIDFromPath then
            local pathVariants = {
                icon,
                string.gsub(icon, "\\", "/"),
                string.lower(icon),
                string.lower(string.gsub(icon, "\\", "/")),
            }
            for i = 1, #pathVariants do
                local ok, result = pcall(GetFileIDFromPath, pathVariants[i])
                if ok and result and result > 0 then
                    fileID = result
                    break
                end
            end
        end

        if not fileID then
            if not IconFileIDProbeTexture then
                local probeFrame = CreateFrame("Frame")
                IconFileIDProbeTexture = probeFrame:CreateTexture(nil, "ARTWORK")
            end
            local ok = pcall(IconFileIDProbeTexture.SetTexture, IconFileIDProbeTexture, icon)
            if ok and IconFileIDProbeTexture.GetTextureFileID then
                local probeFileID = IconFileIDProbeTexture:GetTextureFileID()
                if probeFileID and probeFileID > 0 then
                    fileID = probeFileID
                end
            end
            IconFileIDProbeTexture:SetTexture(nil)
        end

        IconPathFileIDCache[icon] = fileID or false
        return fileID
    end

    local function ApplyMacroFrameLayout()
        if not MacroFrame then return end

        local enabled = IsFeatureEnabled()
        local width = enabled and TARGET_WIDTH or BASE_WIDTH
        local height = enabled and TARGET_HEIGHT or BASE_HEIGHT

        local deltaHeight = height - BASE_HEIGHT
        local selectorExtraHeight = math.floor(deltaHeight * 0.65)
        local inputExtraHeight = deltaHeight - selectorExtraHeight

        MacroFrame:SetSize(width, height)

        if MacroFrame.MacroSelector then
            local selectorWidth = width - 19
            local selectorHeight = math.max(146, 146 + selectorExtraHeight)
            MacroFrame.MacroSelector:SetSize(selectorWidth, selectorHeight)
            MacroFrame.MacroSelector:ClearAllPoints()
            MacroFrame.MacroSelector:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 12, -66)

            local selector = MacroFrame.MacroSelector
            local stride, horizontalSpacing
            if enabled then
                -- Prefer 10 icons per row when enabled, and degrade automatically if width is insufficient.
                local usableWidth = selectorWidth - 32
                local targetStride = 10
                local buttonSize = 36
                local minSpacing = 2
                local maxSpacing = 20
                horizontalSpacing = math.floor((usableWidth - targetStride * buttonSize) / (targetStride - 1))
                stride = targetStride

                if horizontalSpacing < minSpacing then
                    horizontalSpacing = minSpacing
                    stride = Clamp(math.floor((usableWidth + horizontalSpacing) / (buttonSize + horizontalSpacing)), 6,
                        targetStride)
                elseif horizontalSpacing > maxSpacing then
                    horizontalSpacing = maxSpacing
                end
            else
                -- Fall back to Blizzard's original 6-column layout when disabled.
                stride = 6
                horizontalSpacing = 13
            end

            if selector.SetCustomPadding then
                selector:SetCustomPadding(5, 5, 5, 5, horizontalSpacing, 13)
            end
            if selector.SetCustomStride then
                selector:SetCustomStride(stride)
            end

            -- ScrollBoxSelector stride is locked during Init(), so rebuild the view after changing it.
            if selector.initialized and selector.Init then
                selector.initialized = false
                selector:Init()
            elseif selector.UpdateSelections then
                selector:UpdateSelections()
            end
        end

        if MacroHorizontalBarLeft then
            MacroHorizontalBarLeft:SetWidth(width - 82)
            MacroHorizontalBarLeft:ClearAllPoints()
            MacroHorizontalBarLeft:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 2, -(210 + selectorExtraHeight))
        end

        if MacroFrameSelectedMacroBackground then
            MacroFrameSelectedMacroBackground:ClearAllPoints()
            MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 5,
                -(218 + selectorExtraHeight))
        end

        if MacroFrameSelectedMacroName then
            MacroFrameSelectedMacroName:SetWidth(width - 82)
            MacroFrameSelectedMacroName:ClearAllPoints()
            MacroFrameSelectedMacroName:SetPoint("TOPLEFT", MacroFrameSelectedMacroBackground, "TOPRIGHT", -4, -10)
        end

        if MacroEditButton then
            MacroEditButton:ClearAllPoints()
            MacroEditButton:SetPoint("TOPLEFT", MacroFrameSelectedMacroBackground, "TOPLEFT", 55, -30)
            MacroEditButton:SetWidth(math.max(170, width - 163))
        end

        if MacroFrameTextBackground then
            MacroFrameTextBackground:SetSize(width - 16, 95 + inputExtraHeight)
            MacroFrameTextBackground:ClearAllPoints()
            MacroFrameTextBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 6, -(289 + selectorExtraHeight))
        end

        if MacroFrameScrollFrame then
            local scrollWidth = width - 52
            local scrollHeight = 85 + inputExtraHeight
            MacroFrameScrollFrame:SetSize(scrollWidth, scrollHeight)
            MacroFrameScrollFrame:ClearAllPoints()
            MacroFrameScrollFrame:SetPoint("TOPLEFT", MacroFrameSelectedMacroBackground, "BOTTOMLEFT", 11, -13)
            if MacroFrameText then
                MacroFrameText:SetSize(scrollWidth, scrollHeight)
            end
            if MacroFrameTextButton then
                MacroFrameTextButton:SetSize(scrollWidth, scrollHeight)
            end
        end

        SetUIPanelAttribute(MacroFrame, "width", width)
        if MacroFrame:IsShown() then
            UpdateUIPanelPositions(MacroFrame)
        end
    end

    local function GetSearchBox(popup)
        if not popup or not popup.BorderBox then return nil end
        if popup.RevMiniMacroSearchBox then
            return popup.RevMiniMacroSearchBox
        end

        local searchBox = CreateFrame("EditBox", nil, popup.BorderBox, "SearchBoxTemplate")
        searchBox:SetSize(182, 20)
        searchBox:SetPoint("TOPLEFT", popup.BorderBox.IconSelectorEditBox, "BOTTOMLEFT", 0, -13)
        searchBox:SetAutoFocus(false)
        if searchBox.Instructions then
            searchBox.Instructions:SetText(L["Search spell / icon ID"])
        end

        popup.RevMiniMacroSearchBox = searchBox
        return searchBox
    end

    local function UpdatePopupHintTextState(popup)
        if not popup or not popup.BorderBox or not popup.BorderBox.IconSelectionText then return end
        if IsFeatureEnabled() then
            popup.BorderBox.IconSelectionText:Hide()
            popup.BorderBox.IconSelectionText:SetAlpha(0)
        else
            popup.BorderBox.IconSelectionText:SetAlpha(1)
            local draggingIcon = popup.BorderBox.IconDragArea and popup.BorderBox.IconDragArea:IsShown()
            popup.BorderBox.IconSelectionText:SetShown(not draggingIcon)
        end
    end

    local function MatchIcon(icon, queryLower, queryNumber)
        if icon == nil then return false end

        if queryNumber then
            if type(icon) == "number" then
                if icon == queryNumber or string.find(tostring(icon), queryLower, 1, true) then
                    return true
                end
            elseif type(icon) == "string" then
                local asNumber = tonumber(icon)
                if asNumber and (asNumber == queryNumber or string.find(tostring(asNumber), queryLower, 1, true)) then
                    return true
                end

                local fileID = GetIconFileID(icon)
                if fileID and (fileID == queryNumber or string.find(tostring(fileID), queryLower, 1, true)) then
                    return true
                end
            end
        end

        if type(icon) == "string" then
            local iconLower = string.lower(icon)
            if string.find(iconLower, queryLower, 1, true) then
                return true
            end
            local shortName = string.gsub(iconLower, "^interface\\icons\\", "")
            if string.find(shortName, queryLower, 1, true) then
                return true
            end
        elseif type(icon) == "number" then
            if string.find(tostring(icon), queryLower, 1, true) then
                return true
            end
        end

        local keywords = SpellIconKeywordMap[icon]
        if keywords and string.find(keywords, queryLower, 1, true) then
            return true
        end

        return false
    end

    local function BuildFilteredIcons(popup, query)
        local filtered = {}
        if not popup or not popup.iconDataProvider then
            return filtered
        end

        local queryLower = string.lower(query)
        local queryNumber = tonumber(queryLower)
        local seen = {}

        local function BuildIconKey(icon)
            if type(icon) == "number" then
                return "n:" .. tostring(icon)
            end
            return "s:" .. tostring(icon)
        end

        local function AddUnique(icon)
            if icon == nil then return end
            local key = BuildIconKey(icon)
            if seen[key] then return end
            seen[key] = true
            filtered[#filtered + 1] = icon
        end

        local total = popup.iconDataProvider:GetNumIcons()
        for i = 1, total do
            local icon = popup.iconDataProvider:GetIconByIndex(i)
            if MatchIcon(icon, queryLower, queryNumber) then
                AddUnique(icon)
            end
        end

        if queryNumber then
            AddUnique(queryNumber)
            if C_Spell and C_Spell.GetSpellTexture then
                local ok, spellIcon = pcall(C_Spell.GetSpellTexture, queryNumber)
                if ok and spellIcon then
                    AddUnique(spellIcon)
                end
            end
        end

        return filtered
    end

    local function ApplyDefaultProvider(popup)
        popup.IconSelector:SetSelectionsDataProvider(
            GenerateClosure(popup.GetIconByIndex, popup),
            GenerateClosure(popup.GetNumIcons, popup)
        )
        popup.IconSelector:UpdateSelections()
    end

    local function ApplyFilteredProvider(popup, filteredIcons)
        popup._exMiniMacroFilteredIcons = filteredIcons
        popup.IconSelector:SetSelectionsDataProvider(
            function(index)
                local list = popup._exMiniMacroFilteredIcons
                return list and list[index] or nil
            end,
            function()
                local list = popup._exMiniMacroFilteredIcons
                return list and #list or 0
            end
        )
        popup.IconSelector:UpdateSelections()
    end

    local function ReevaluateSelection(popup, filteredIcons)
        local selectedTexture = popup.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
        local selectedIndex = nil

        if filteredIcons then
            for i = 1, #filteredIcons do
                if filteredIcons[i] == selectedTexture then
                    selectedIndex = i
                    break
                end
            end
        else
            selectedIndex = popup:GetIndexOfIcon(selectedTexture)
        end

        popup.IconSelector:SetSelectedIndex(selectedIndex)
        popup:SetSelectedIconText()
        if selectedIndex then
            popup.IconSelector:ScrollToSelectedIndex()
        end
    end

    local function RefreshIconSearch(popup)
        if not popup or not popup.IconSelector or not popup.iconDataProvider then return end

        local searchBox = GetSearchBox(popup)
        if not searchBox then return end

        local searchEnabled = IsFeatureEnabled()
        if not searchEnabled then
            searchBox:Hide()
            popup._exMiniMacroFilteredIcons = nil
            ApplyDefaultProvider(popup)
            ReevaluateSelection(popup, nil)
            UpdatePopupHintTextState(popup)
            return
        end

        UpdatePopupHintTextState(popup)
        searchBox:Show()

        local query = TrimText(searchBox:GetText() or "")
        if query == "" then
            popup._exMiniMacroFilteredIcons = nil
            ApplyDefaultProvider(popup)
            ReevaluateSelection(popup, nil)
            return
        end

        local filteredIcons = BuildFilteredIcons(popup, query)
        ApplyFilteredProvider(popup, filteredIcons)
        ReevaluateSelection(popup, filteredIcons)
    end

    local function SetupSearchBoxHandlers(popup)
        local searchBox = GetSearchBox(popup)
        if not searchBox or searchBox._exMiniMacroHooked then return end

        searchBox:SetScript("OnTextChanged", function(self)
            UpdateSearchBoxVisual(self)
            RefreshIconSearch(popup)
        end)

        searchBox:SetScript("OnEscapePressed", function(self)
            self:SetText("")
            self:ClearFocus()
            RefreshIconSearch(popup)
        end)

        searchBox._exMiniMacroHooked = true
    end

    local function InstallHooks()
        if HooksInstalled or not MacroFrame or not MacroPopupFrame then return end
        HooksInstalled = true

        MacroFrame:HookScript("OnShow", function()
            -- When disabled, stop forcing a relayout on every MacroFrame open to avoid overriding other addons.
            if IsFeatureEnabled() then
                ApplyMacroFrameLayout()
            end
        end)

        MacroPopupFrame:HookScript("OnShow", function(popup)
            RebuildSpellIconKeywordMap()
            SetupSearchBoxHandlers(popup)
            UpdatePopupHintTextState(popup)
            if popup.RevMiniMacroSearchBox then
                popup.RevMiniMacroSearchBox:SetText("")
                UpdateSearchBoxVisual(popup.RevMiniMacroSearchBox)
            end
            RefreshIconSearch(popup)
        end)

        MacroPopupFrame:HookScript("OnHide", function(popup)
            if popup.RevMiniMacroSearchBox then
                popup.RevMiniMacroSearchBox:SetText("")
                UpdateSearchBoxVisual(popup.RevMiniMacroSearchBox)
            end
            popup._exMiniMacroFilteredIcons = nil
        end)

        hooksecurefunc(MacroPopupFrame, "Update", function(popup)
            RefreshIconSearch(popup)
        end)
        hooksecurefunc(MacroPopupFrame, "SetIconFilterInternal", function(popup)
            RefreshIconSearch(popup)
        end)
        hooksecurefunc(MacroPopupFrame, "UpdateStateFromCursorType", function(popup)
            UpdatePopupHintTextState(popup)
        end)

        ApplyMacroFrameLayout()
    end

    local function TryInit()
        if not C_AddOns.IsAddOnLoaded("Blizzard_MacroUI") then
            return false
        end
        if not MacroFrame or not MacroPopupFrame then
            return false
        end
        InstallHooks()
        return true
    end

    -- Always register the listener so runtime enable works, but install hooks only when enabled.
    InfinityTools:RegisterEvent("ADDON_LOADED", OWNER_PREFIX .. "_Init", function(_, addonName)
        if addonName ~= "Blizzard_MacroUI" then return end
        if not IsFeatureEnabled() or HooksInstalled then return end
        C_Timer.After(0, TryInit)
    end)

    if IsFeatureEnabled() then
        TryInit()
    end

    InfinityTools:WatchState(DB_KEY .. ".DatabaseChanged", OWNER_PREFIX .. "_DB", function(info)
        if not info or info.key ~= "MacroEnhancement" then return end

        if IsFeatureEnabled() and not HooksInstalled then
            TryInit()
        end

        if MacroFrame then
            ApplyMacroFrameLayout()
        end
        if MacroPopupFrame and MacroPopupFrame:IsShown() then
            RefreshIconSearch(MacroPopupFrame)
        end
    end)
end

-- ========================================================================
-- Module core
-- ========================================================================
local INFINITY_MODULE_KEY = "RevTools.MiniTools"
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local INFINITY_DEFAULTS = {
    --
    ShowMapInfo = true,
    MapInfoHideMapID = true,
    MapInfoAnchor = "Bottom Center",
    MapInfoFont = {
        font = "Default",
        size = 20,
        outline = "OUTLINE",
        r = 1,
        g = 0.88,
        b = 0.11,
        a = 1,
        shadow = false,
        shadowX = 1,
    },
    AutoDelete = true,
    AutoSellJunk = true,

    -- AutoCombatLog detailed settings
    AutoCombatLog = true, -- Master toggle
    ACL_DungeonNormal = false,
    ACL_DungeonHeroic = false,
    ACL_DungeonMythic = true,
    ACL_DungeonChallenge = true, -- M+
    ACL_DungeonFollower = false,
    ACL_RaidLFR = false,
    ACL_RaidNormal = false,
    ACL_RaidHeroic = true,
    ACL_RaidMythic = true,

    -- BulkBuy
    BulkBuy = true,
    BulkBuy_WarnThreshold = 1000,

    -- ResetDMG
    AutoResetDamageMeter = true,

    -- AutoRepair
    AutoRepair = true,
    AutoRepair_UseGuildBank = false,
    AutoRepair_ShowMessage = true,

    -- HideBattleTag
    HideBattleTag = false,
    BattleTagText = "",

    -- EJTooltip
    EJTooltip = true,

    -- MerchantExpansion
    MerchantExpansion = false,
    MerchantColumns = "3",

    -- MacroEnhancement
    MacroEnhancement = false,
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)


local function NormalizeMiniToolsConfig(db)
    if not db then return end
    local anchorMap = { ["Bottom Left"] = "Bottom Left", ["Top Left"] = "Top Left", ["Bottom Right"] = "Bottom Right", ["Top Right"] = "Top Right", ["Bottom Center"] = "Bottom Center" }
    if anchorMap[db.MapInfoAnchor] then db.MapInfoAnchor = anchorMap[db.MapInfoAnchor] end
    
    
end

NormalizeMiniToolsConfig(INFINITY_DEFAULTS)
-- Initialization
local function SafeInit(func, name)
    local ok, err = pcall(func)
    if not ok then
        print("|cffff0000[InfinityTools] MiniTool Init Error (" .. name .. "):|r " .. tostring(err))
    end
end

if MODULE_DB.ShowMapInfo then SafeInit(Init_ShowMapInfo, "ShowMapInfo") end
if MODULE_DB.AutoDelete then SafeInit(Init_AutoDelete, "AutoDelete") end
if MODULE_DB.AutoSellJunk then SafeInit(Init_AutoSellJunk, "AutoSellJunk") end
if MODULE_DB.AutoCombatLog then SafeInit(Init_AutoCombatLog, "AutoCombatLog") end
if MODULE_DB.BulkBuy then SafeInit(Init_BulkBuy, "BulkBuy") end
if MODULE_DB.AutoResetDamageMeter then SafeInit(Init_ResetDamageMeter, "AutoResetDamageMeter") end
if MODULE_DB.AutoRepair then SafeInit(Init_AutoRepair, "AutoRepair") end
if MODULE_DB.HideBattleTag then SafeInit(Init_HideBattleTag, "HideBattleTag") end
if MODULE_DB.EJTooltip then SafeInit(Init_EJTooltip, "EJTooltip") end
if MODULE_DB.MerchantExpansion then SafeInit(Init_MerchantExpansion, "MerchantExpansion") end
SafeInit(Init_MacroEnhancement, "MacroEnhancement")

-- ========================================================================
-- Grid layout
-- ========================================================================
local function REGISTER_LAYOUT()
    local layout = {
        { key = "head", type = "header", x = 2, y = 1, w = 52, h = 2, label = L["Mini Tools"], labelSize = 25 },  -- TODO: missing key: L["Mini Tools"]
        { key = "desc", type = "description", x = 2, y = 4, w = 52, h = 2, label = L["A collection of small utility features. |cffff0000Note: changes usually require /reload to fully apply.|r"] },
        { key = "h_map", type = "header", x = 2, y = 6, w = 52, h = 2, label = L["1. Map Info (optional ID + mouse/player coordinates)"], labelSize = 20 },
        { key = "ShowMapInfo", type = "checkbox", x = 2, y = 9, w = 30, h = 2, label = L["Enable: show coordinates on the world map"] },
        { key = "MapInfoHideMapID", type = "checkbox", x = 34, y = 9, w = 20, h = 2, label = L["Hide MapID"] },
        { key = "MapInfoAnchor", type = "dropdown", x = 2, y = 12, w = 14, h = 2, label = L["????"], items = { "Bottom Left", "Top Left", "Bottom Right", "Top Right", "Bottom Center" } },
        { key = "MapInfoFont", type = "fontgroup", x = 2, y = 15, w = 53, h = 20, label = L["Font Settings"] },
        { key = "h_del", type = "header", x = 2, y = 36, w = 52, h = 2, label = L["2. Auto Delete Confirm"], labelSize = 20 },
        { key = "AutoDelete", type = "checkbox", x = 2, y = 39, w = 30, h = 2, label = L["Enable: auto-fill 'DELETE' when deleting items"] },
        { key = "h_junk", type = "header", x = 2, y = 42, w = 52, h = 2, label = L["3. Auto Sell Junk"], labelSize = 18 },
        { key = "AutoSellJunk", type = "checkbox", x = 2, y = 45, w = 30, h = 2, label = L["Enable: auto-sell gray items when opening a merchant"] },
        { key = "h_acl", type = "header", x = 2, y = 48, w = 52, h = 2, label = L["4. Auto Combat Log"], labelSize = 18 },
        { key = "AutoCombatLog", type = "checkbox", x = 2, y = 51, w = 30, h = 2, label = L["Enable Module"] },  -- TODO: missing key: L["Enable Module"]
        { key = "lbl_dungeon", type = "description", x = 2, y = 54, w = 20, h = 2, label = "|cffffd100> " .. L["5-player dungeon settings"] .. "|r" },
        { key = "ACL_DungeonNormal", type = "checkbox", x = 9, y = 56, w = 5, h = 2, label = L["Normal"] },
        { key = "ACL_DungeonHeroic", type = "checkbox", x = 15, y = 56, w = 5, h = 2, label = L["Heroic"] },
        { key = "ACL_DungeonMythic", type = "checkbox", x = 21, y = 56, w = 5, h = 2, label = L["Mythic"] },
        { key = "ACL_DungeonChallenge", type = "checkbox", x = 27, y = 56, w = 6, h = 2, label = L["Mythic+"] },  -- TODO: missing key: L["Mythic+"]
        { key = "ACL_DungeonFollower", type = "checkbox", x = 2, y = 56, w = 6, h = 2, label = L["Follower"] },
        { key = "lbl_raid", type = "description", x = 2, y = 59, w = 10, h = 2, label = "|cffffd100> " .. L["Raid settings"] .. "|r" },
        { key = "ACL_RaidLFR", type = "checkbox", x = 2, y = 61, w = 6, h = 2, label = L["LFR"] },
        { key = "ACL_RaidNormal", type = "checkbox", x = 9, y = 61, w = 5, h = 2, label = L["Normal"] },
        { key = "ACL_RaidHeroic", type = "checkbox", x = 15, y = 61, w = 5, h = 2, label = L["Heroic"] },
        { key = "ACL_RaidMythic", type = "checkbox", x = 21, y = 61, w = 6, h = 2, label = L["Mythic"] },
        { key = "h_bulk", type = "header", x = 2, y = 64, w = 53, h = 2, label = L["5. Bulk Buy Assistant"], labelSize = 20 },
        { key = "BulkBuy", type = "checkbox", x = 2, y = 67, w = 30, h = 2, label = L["Enable: Shift+Click to override merchant purchase"] },
        { key = "BulkBuy_WarnThreshold", type = "input", x = 2, y = 71, w = 7, h = 2, label = L["Require a confirmation popup when total cost exceeds this many gold"], labelPos = "top" },
        { key = "h_dmg", type = "header", x = 2, y = 74, w = 53, h = 2, label = L["6. Reset Damage on Instance Entry"], labelSize = 20 },
        { key = "AutoResetDamageMeter", type = "checkbox", x = 2, y = 77, w = 30, h = 2, label = L["Enable: show a reset damage meter prompt when entering an instance"] },
        { key = "h_btag", type = "header", x = 2, y = 80, w = 53, h = 2, label = L["7. Override BattleTag"], labelSize = 20 },
        { key = "HideBattleTag", type = "checkbox", x = 2, y = 83, w = 30, h = 2, label = L["Enable: override BattleTag |cffff0c08(/rl required)|r"] },
        { key = "BattleTagText", type = "input", x = 2, y = 87, w = 20, h = 2, label = L["Enter name (leave blank to hide)"] },
        { key = "h_repair", type = "header", x = 2, y = 90, w = 53, h = 2, label = L["8. Auto Repair"], labelSize = 20 },
        { key = "AutoRepair", type = "checkbox", x = 2, y = 93, w = 30, h = 2, label = L["Enable: automatically repair all gear when opening a merchant"] },
        { key = "AutoRepair_UseGuildBank", type = "checkbox", x = 2, y = 95, w = 30, h = 2, label = L["Prefer guild bank repairs (pay yourself if guild funds are insufficient)"] },
        { key = "AutoRepair_ShowMessage", type = "checkbox", x = 2, y = 97, w = 30, h = 2, label = L["Show repair cost in chat after repairing"] },
        { key = "h_ej", type = "header", x = 2, y = 100, w = 53, h = 2, label = L["9. Adventure Guide Enhancements"], labelSize = 20 },
        { key = "EJTooltip", type = "checkbox", x = 2, y = 103, w = 40, h = 2, label = L["Enable: show SpellID and full spell tooltip when hovering ability titles"] },
        { key = "h_merch", type = "header", x = 2, y = 106, w = 53, h = 2, label = L["10. Merchant UI Enhancements"], labelSize = 20 },
        { key = "MerchantExpansion", type = "checkbox", x = 2, y = 109, w = 40, h = 2, label = L["Enable: widen the merchant frame (keep original height)"] },
        { key = "MerchantColumns", type = "dropdown", x = 2, y = 112, w = 15, h = 2, label = L["Columns"], items = { "2", "3", "4", "5" } },
        { key = "h_macro", type = "header", x = 2, y = 115, w = 53, h = 2, label = L["11. Macro UI Enhancements"], labelSize = 20 },
        { key = "MacroEnhancement", type = "checkbox", x = 2, y = 118, w = 48, h = 2, label = L["Enable: macro UI enhancements |cffff1f13(beta, still under testing!)|r"] },
    }





    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

REGISTER_LAYOUT()

-- Bind button events
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(data)
    if data.key == "rlbtn" then C_UI.Reload() end
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)

