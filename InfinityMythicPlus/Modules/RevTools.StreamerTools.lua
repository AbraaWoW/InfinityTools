-- =============================================================
-- [[ Streamer Tools ]]
-- { Key = "RevTools.StreamerTools", Name = "Streamer Tools", Desc = "Provides combat timer, battle rez tracker, mob count, and keystone utility features.", Category = 4 },
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevTools.StreamerTools"
local InfinityDB = _G.InfinityDB
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local SPELL_ID_REBIRTH = 20484
local KEYSTONE_RETRY_INTERVAL = 0.15
local KEYSTONE_RETRY_MAX = 8
local BREZ_RETRY_DELAYS = { 0, 1, 2, 5, 10 }

local TimerFrame
local BRezFrame
local MobCountFrame

local combatStartTime = 0
local combatEndTime = 0
local timerRunning = false
local keystoneRetryToken = 0
local brezRetryToken = 0

local ApplyStyle
local ApplyMobCountStyle
local UpdateBRezInfo
local UpdateMobCountText

local function REGISTER_LAYOUT()
    local layout = {
        { key = "timer_header", type = "header", x = 1, y = 1, w = 47, h = 2, label = L["1. Combat Timer"], labelSize = 20 },
        { key = "enabled", type = "checkbox", x = 1, y = 4, w = 11, h = 2, label = L["Enable Timer"] },
        { key = "resetOnBoss", type = "checkbox", x = 12, y = 4, w = 11, h = 2, label = L["Reset on Boss"] },
        { key = "hideOutOfCombat", type = "checkbox", x = 24, y = 4, w = 10, h = 2, label = L["Hide Out of Combat"] },
        { key = "keepTimeOnLeaveCombat", type = "checkbox", x = 35, y = 4, w = 11, h = 2, label = L["Freeze on Combat End"] },
        { key = "locked", type = "checkbox", x = 47, y = 4, w = 8, h = 2, label = L["Lock"] },
        { key = "leftText", type = "input", x = 1, y = 8, w = 15, h = 2, label = L["Prefix Text"], labelPos = "top" },
        { key = "rightText", type = "input", x = 18, y = 8, w = 15, h = 2, label = L["Suffix Text"], labelPos = "top" },
        { key = "timerFont", type = "fontgroup", x = 1, y = 11, w = 53, h = 17, label = L["Timer Font"] },

        { key = "brez_header", type = "header", x = 1, y = 32, w = 52, h = 2, label = L["2. Battle Rez Tracker"], labelSize = 20 },
        { key = "brezEnabled", type = "checkbox", x = 1, y = 35, w = 12, h = 2, label = L["Enable BRez Tracker"] },
        { key = "brezLocked", type = "checkbox", x = 16, y = 35, w = 10, h = 2, label = L["Lock Position"] },
        { key = "brezIcon", type = "icongroup", x = 1, y = 38, w = 54, h = 18, label = L["BRez Icon Size / Position"], labelSize = 20 },
        { key = "brezTimerFont", type = "fontgroup", x = 1, y = 57, w = 54, h = 18, label = L["BRez Timer Text"], labelSize = 20 },
        { key = "brezCountFont", type = "fontgroup", x = 1, y = 76, w = 54, h = 18, label = L["BRez Charge Text"], labelSize = 20 },

        { key = "keystone_header", type = "header", x = 1, y = 96, w = 52, h = 2, label = L["3. Mythic+ Keystone"], labelSize = 20 },
        { key = "autoInsertKeystone", type = "checkbox", x = 1, y = 99, w = 24, h = 2, label = L["Auto Insert Keystone When Panel Opens"] },

        { key = "mob_header", type = "header", x = 1, y = 103, w = 52, h = 2, label = L["4. Active Mob Count"], labelSize = 20 },
        { key = "mobCountEnabled", type = "checkbox", x = 1, y = 106, w = 18, h = 2, label = L["Enable Mob Count Text"] },
        { key = "mobCountTemplate", type = "input", x = 1, y = 110, w = 24, h = 2, label = L["Text Template (%n = count)"], labelPos = "top" },
        { key = "mobCountFont", type = "fontgroup", x = 1, y = 114, w = 53, h = 17, label = L["Mob Count Font"], labelSize = 20 },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local MODULE_DEFAULTS = {
    enabled = false,
    resetOnBoss = true,
    hideOutOfCombat = false,
    keepTimeOnLeaveCombat = true,
    locked = true,
    leftText = "[",
    rightText = "]",
    pos = { "CENTER", 0, 0 },
    preview = false,

    timerFont = {
        font = "Default",
        size = 24,
        outline = "OUTLINE",
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        r = 1,
        g = 1,
        b = 1,
        a = 1,
        x = 0,
        y = 0,
    },

    brezEnabled = true,
    brezLocked = true,
    brezIcon = {
        width = 50,
        height = 50,
        x = -831,
        y = -65,
        reverse = false,
        showIcon = true,
    },
    brezTimerFont = {
        font = "Default",
        size = 20,
        outline = "OUTLINE",
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        r = 1,
        g = 0.78823536634445,
        b = 0.1843137294054,
        a = 1,
        x = 0,
        y = 0,
    },
    brezCountFont = {
        font = "Friz Quadrata TT",
        size = 15,
        outline = "OUTLINE",
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        r = 1,
        g = 1,
        b = 1,
        a = 1,
        x = -2,
        y = 3,
    },

    autoInsertKeystone = true,

    mobCountEnabled = false,
    mobCountTemplate = "Nearby mobs: %n",
    mobCountPos = { "CENTER", 0, 120 },
    mobCountFont = {
        font = "Default",
        size = 22,
        outline = "OUTLINE",
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        r = 1,
        g = 1,
        b = 1,
        a = 1,
        x = 0,
        y = 0,
    },
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

local function ApplyFontString(fontString, fontDB)
    if not fontString then
        return
    end

    fontDB = fontDB or {}

    if InfinityDB and InfinityDB.ApplyFont and InfinityDB:ApplyFont(fontString, fontDB) then
        return
    end

    local fontPath
    if LSM and fontDB.font then
        fontPath = LSM:Fetch("font", fontDB.font)
    end

    fontString:SetFont(fontPath or STANDARD_TEXT_FONT, fontDB.size or 14, fontDB.outline or "")
    fontString:SetTextColor(fontDB.r or 1, fontDB.g or 1, fontDB.b or 1, fontDB.a or 1)

    if fontDB.shadow then
        fontString:SetShadowOffset(fontDB.shadowX or 1, fontDB.shadowY or -1)
        fontString:SetShadowColor(0, 0, 0, 1)
    else
        fontString:SetShadowOffset(0, 0)
    end
end

local function RestoreFramePoint(frame, positionData, defaultPoint, defaultX, defaultY)
    if not frame then
        return
    end

    local point = positionData and positionData[1] or defaultPoint or "CENTER"
    local x = positionData and positionData[2] or defaultX or 0
    local y = positionData and positionData[3] or defaultY or 0

    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, point, x, y)
end

local function SaveFramePoint(frame, targetTable, fallbackPoint)
    if not frame or type(targetTable) ~= "table" then
        return
    end

    local point, _, _, x, y = frame:GetPoint()
    targetTable[1] = point or fallbackPoint or "CENTER"
    targetTable[2] = x or 0
    targetTable[3] = y or 0
end

local function GetFormattedCombatTime()
    local duration = 0
    if timerRunning then
        duration = math.max(0, GetTime() - combatStartTime)
    elseif MODULE_DB.keepTimeOnLeaveCombat and combatEndTime > combatStartTime then
        duration = math.max(0, combatEndTime - combatStartTime)
    end

    local minutes = math.floor(duration / 60)
    local seconds = math.floor(duration % 60)
    return string.format("%s%02d:%02d%s", MODULE_DB.leftText or "", minutes, seconds, MODULE_DB.rightText or "")
end

local function IsBRezActiveEnvironment()
    local state = InfinityTools.State or {}
    if state.DifficultyID == 8 then
        return true
    end
    if state.InstanceType == "party" then
        return false
    end
    if state.InstanceType == "raid" then
        return state.IsBossEncounter and true or false
    end
    return state.IsBossEncounter and true or false
end

local function GetBattleRezCharges()
    if not C_Spell or not C_Spell.GetSpellCharges then
        return nil
    end

    return C_Spell.GetSpellCharges(SPELL_ID_REBIRTH)
end

local function HasBRezChargeData()
    local chargeInfo = GetBattleRezCharges()
    return chargeInfo and (chargeInfo.maxCharges or 0) > 0
end

local function GetActiveNameplateCombatCount()
    local count = 0
    for index = 1, 40 do
        local unit = "nameplate" .. index
        if UnitExists(unit) and UnitAffectingCombat(unit) then
            count = count + 1
        end
    end
    return count
end

local function CreateTimerFrame()
    if TimerFrame then
        return TimerFrame
    end

    local frame = CreateFrame("Frame", "InfinityCombatTimerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(200, 40)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetPoint("CENTER", 0, 0)
    frame.text:SetJustifyH("CENTER")

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not MODULE_DB.locked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePoint(self, MODULE_DB.pos, "CENTER")
        if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() then
            InfinityTools.UI:RefreshContent()
        end
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not timerRunning then
            return
        end

        self._elapsed = (self._elapsed or 0) + elapsed
        if self._elapsed < 0.05 then
            return
        end
        self._elapsed = 0
        self.text:SetText(GetFormattedCombatTime())
    end)

    RestoreFramePoint(frame, MODULE_DB.pos, "CENTER", 0, 0)
    TimerFrame = frame
    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, frame)
    return frame
end

local function CreateBRezFrame()
    if BRezFrame then
        return BRezFrame
    end

    local frame = CreateFrame("Frame", "InfinityBRezFrame", UIParent, "BackdropTemplate")
    frame:SetSize(50, 50)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)

    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetPoint("TOPLEFT", 2, -2)
    frame.Icon:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.Cooldown = CreateFrame("Cooldown", "$parentCooldown", frame, "CooldownFrameTemplate")
    frame.Cooldown:SetAllPoints(frame)
    frame.Cooldown:SetDrawEdge(false)
    frame.Cooldown:SetSwipeColor(0, 0, 0, 0.7)
    frame.Cooldown:SetHideCountdownNumbers(true)
    frame.Cooldown:SetFrameLevel(frame:GetFrameLevel() + 1)

    frame.TextOverlay = CreateFrame("Frame", nil, frame)
    frame.TextOverlay:SetAllPoints(frame)
    frame.TextOverlay:SetFrameLevel(frame.Cooldown:GetFrameLevel() + 1)
    frame.TextOverlay:EnableMouse(false)

    frame.Timer = frame.TextOverlay:CreateFontString(nil, "OVERLAY")
    frame.Timer:SetPoint("CENTER", 0, 0)
    frame.Timer:SetJustifyH("CENTER")

    frame.Count = frame.TextOverlay:CreateFontString(nil, "OVERLAY")
    frame.Count:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.Count:SetJustifyH("RIGHT")

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not MODULE_DB.brezLocked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local centerX, centerY = UIParent:GetCenter()
        local selfX, selfY = self:GetCenter()
        local scale = self:GetScale() or 1
        if centerX and centerY and selfX and selfY then
            MODULE_DB.brezIcon = MODULE_DB.brezIcon or {}
            MODULE_DB.brezIcon.x = math.floor((selfX * scale - centerX) + 0.5)
            MODULE_DB.brezIcon.y = math.floor((selfY * scale - centerY) + 0.5)
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.brezIcon.x, MODULE_DB.brezIcon.y)
        end
        if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() then
            InfinityTools.UI:RefreshContent()
        end
    end)

    BRezFrame = frame
    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, frame)
    return frame
end

local function CreateMobCountFrame()
    if MobCountFrame then
        return MobCountFrame
    end

    local frame = CreateFrame("Frame", "InfinityMobCountFrame", UIParent, "BackdropTemplate")
    frame:SetSize(220, 40)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetPoint("CENTER", 0, 0)
    frame.text:SetJustifyH("CENTER")

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if MODULE_DB.preview then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        MODULE_DB.mobCountPos = MODULE_DB.mobCountPos or { "CENTER", 0, 120 }
        SaveFramePoint(self, MODULE_DB.mobCountPos, "CENTER")
        if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() then
            InfinityTools.UI:RefreshContent()
        end
    end)

    RestoreFramePoint(frame, MODULE_DB.mobCountPos, "CENTER", 0, 120)
    MobCountFrame = frame
    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, frame)
    return frame
end

local function StartTimer()
    if timerRunning then
        return
    end
    combatStartTime = GetTime()
    timerRunning = true
    if TimerFrame then
        TimerFrame:Show()
    end
end

local function StopTimer()
    if timerRunning then
        combatEndTime = GetTime()
    end
    timerRunning = false
end

local function ResetTimer()
    combatStartTime = GetTime()
    combatEndTime = combatStartTime
    if TimerFrame then
        TimerFrame.text:SetText(GetFormattedCombatTime())
    end
end

UpdateBRezInfo = function()
    if not BRezFrame then
        return false
    end

    local chargeInfo = GetBattleRezCharges()
    if not chargeInfo or (chargeInfo.maxCharges or 0) <= 0 then
        if not MODULE_DB.preview then
            BRezFrame.Count:SetText("")
            BRezFrame.Timer:SetText("")
            if BRezFrame.Cooldown then
                BRezFrame.Cooldown:Clear()
            end
        end
        return MODULE_DB.preview and true or false
    end

    local currentCharges = chargeInfo.currentCharges or 0
    local maxCharges = chargeInfo.maxCharges or 0
    local cooldownDuration = chargeInfo.cooldownDuration or 0
    local cooldownStart = chargeInfo.cooldownStartTime or 0
    local remaining = 0

    if MODULE_DB.preview then
        currentCharges = 2
        maxCharges = 3
        cooldownDuration = 60
        cooldownStart = GetTime() - 5
        remaining = 55
    elseif currentCharges < maxCharges and cooldownStart > 0 then
        remaining = math.max(0, cooldownStart + cooldownDuration - GetTime())
    end

    if remaining > 0 and BRezFrame.Cooldown then
        BRezFrame.Cooldown:SetCooldown(cooldownStart, cooldownDuration)
        if remaining >= 600 then
            BRezFrame.Timer:SetFormattedText("%dm", math.ceil(remaining / 60))
        else
            BRezFrame.Timer:SetFormattedText("%d:%02d", math.floor(remaining / 60), remaining % 60)
        end
    else
        if BRezFrame.Cooldown then
            BRezFrame.Cooldown:Clear()
        end
        BRezFrame.Timer:SetText("")
    end

    BRezFrame.Count:SetText(currentCharges)
    return true
end

local function BRez_OnUpdate(_, elapsed)
    BRezFrame._updateElapsed = (BRezFrame._updateElapsed or 0) + elapsed
    if BRezFrame._updateElapsed < 0.1 then
        return
    end
    BRezFrame._updateElapsed = 0
    UpdateBRezInfo()
end

local function ScheduleBRezRefresh()
    brezRetryToken = brezRetryToken + 1
    local token = brezRetryToken

    for _, delay in ipairs(BREZ_RETRY_DELAYS) do
        C_Timer.After(delay, function()
            if token ~= brezRetryToken then
                return
            end
            ApplyStyle()
            if HasBRezChargeData() then
                brezRetryToken = brezRetryToken + 1
            end
        end)
    end
end

local function FindKeystoneInBags()
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then
        return nil, nil
    end
    if not C_Item or not C_Item.IsItemKeystoneByID then
        return nil, nil
    end

    local bagStart = _G.BACKPACK_CONTAINER or 0
    local bagEnd = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4

    for bag = bagStart, bagEnd do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            local itemID = itemInfo and itemInfo.itemID
            if itemID and C_Item.IsItemKeystoneByID(itemID) then
                if C_ChallengeMode and C_ChallengeMode.CanUseKeystoneInCurrentMap and ItemLocation and ItemLocation.CreateFromBagAndSlot then
                    local itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
                    if itemLocation and C_ChallengeMode.CanUseKeystoneInCurrentMap(itemLocation) then
                        return bag, slot
                    end
                else
                    return bag, slot
                end
            end
        end
    end

    return nil, nil
end

local function TryAutoInsertKeystone()
    if not MODULE_DB.autoInsertKeystone then
        return false
    end
    if C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and not C_MythicPlus.GetOwnedKeystoneLevel() then
        return false
    end
    if not C_ChallengeMode or not C_ChallengeMode.SlotKeystone or not C_ChallengeMode.HasSlottedKeystone then
        return false
    end
    if C_ChallengeMode.HasSlottedKeystone() then
        return true
    end
    if CursorHasItem and CursorHasItem() then
        return false
    end

    local bag, slot = FindKeystoneInBags()
    if not bag or not slot then
        return false
    end

    C_Container.PickupContainerItem(bag, slot)
    if CursorHasItem and CursorHasItem() then
        C_ChallengeMode.SlotKeystone()
        if C_ChallengeMode.HasSlottedKeystone() then
            if CloseAllBags then
                CloseAllBags()
            end
            return true
        end

        if C_Container and C_Container.PickupContainerItem then
            C_Container.PickupContainerItem(bag, slot)
        end
    end

    return false
end

local function ScheduleAutoInsertKeystone()
    if not MODULE_DB.autoInsertKeystone then
        return
    end

    keystoneRetryToken = keystoneRetryToken + 1
    local token = keystoneRetryToken

    local function Attempt(remaining)
        if token ~= keystoneRetryToken or not MODULE_DB.autoInsertKeystone then
            return
        end
        if C_ChallengeMode and C_ChallengeMode.HasSlottedKeystone and C_ChallengeMode.HasSlottedKeystone() then
            return
        end
        if TryAutoInsertKeystone() then
            return
        end
        if remaining > 0 then
            C_Timer.After(KEYSTONE_RETRY_INTERVAL, function()
                Attempt(remaining - 1)
            end)
        end
    end

    Attempt(KEYSTONE_RETRY_MAX)
end

ApplyStyle = function()
    CreateTimerFrame()
    CreateBRezFrame()

    if TimerFrame then
        ApplyFontString(TimerFrame.text, MODULE_DB.timerFont)
        TimerFrame.text:ClearAllPoints()
        TimerFrame.text:SetPoint("CENTER", TimerFrame, "CENTER", MODULE_DB.timerFont.x or 0, MODULE_DB.timerFont.y or 0)
        TimerFrame.text:SetText(GetFormattedCombatTime())

        if MODULE_DB.locked then
            TimerFrame:SetBackdropColor(0, 0, 0, 0)
            TimerFrame:SetBackdropBorderColor(0, 0, 0, 0)
            TimerFrame:EnableMouse(false)
        else
            TimerFrame:SetBackdropColor(0, 0.5, 0, 0.45)
            TimerFrame:SetBackdropBorderColor(0.2, 1, 0.2, 1)
            TimerFrame:EnableMouse(true)
        end

        local showTimer = MODULE_DB.enabled
        if MODULE_DB.hideOutOfCombat and not timerRunning and not MODULE_DB.preview then
            showTimer = false
        end
        TimerFrame:SetShown(showTimer)
    end

    if BRezFrame then
        local iconCfg = MODULE_DB.brezIcon or {}
        ApplyFontString(BRezFrame.Timer, MODULE_DB.brezTimerFont)
        ApplyFontString(BRezFrame.Count, MODULE_DB.brezCountFont)

        BRezFrame.Timer:ClearAllPoints()
        BRezFrame.Timer:SetPoint("CENTER", BRezFrame, "CENTER", MODULE_DB.brezTimerFont.x or 0, MODULE_DB.brezTimerFont.y or 0)
        BRezFrame.Count:ClearAllPoints()
        BRezFrame.Count:SetPoint("BOTTOMRIGHT", BRezFrame, "BOTTOMRIGHT", MODULE_DB.brezCountFont.x or -2, MODULE_DB.brezCountFont.y or 3)

        BRezFrame:SetSize(iconCfg.width or 50, iconCfg.height or 50)
        BRezFrame.Cooldown:SetReverse(iconCfg.reverse and true or false)
        BRezFrame.Icon:SetTexture(iconCfg.iconID or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(SPELL_ID_REBIRTH)) or 136080)
        BRezFrame.Icon:SetShown(iconCfg.showIcon ~= false)
        BRezFrame:ClearAllPoints()
        BRezFrame:SetPoint("CENTER", UIParent, "CENTER", iconCfg.x or 0, iconCfg.y or 0)

        local poolActive = UpdateBRezInfo()
        local showBRez = MODULE_DB.brezEnabled and (poolActive or MODULE_DB.preview) and IsBRezActiveEnvironment()
        if MODULE_DB.preview or not MODULE_DB.brezLocked then
            showBRez = true
        end

        BRezFrame:SetShown(showBRez)
        if showBRez then
            BRezFrame:SetScript("OnUpdate", BRez_OnUpdate)
        else
            BRezFrame:SetScript("OnUpdate", nil)
        end

        if MODULE_DB.brezLocked then
            BRezFrame:SetBackdropColor(0, 0, 0, 0)
            BRezFrame:SetBackdropBorderColor(0, 0, 0, 0)
            BRezFrame:EnableMouse(false)
        else
            BRezFrame:SetBackdropColor(0, 0.5, 1, 0.45)
            BRezFrame:SetBackdropBorderColor(0.35, 0.7, 1, 1)
            BRezFrame:EnableMouse(true)
        end
    end
end

UpdateMobCountText = function()
    if not MobCountFrame then
        return
    end

    local count = MODULE_DB.preview and 5 or GetActiveNameplateCombatCount()
    local textTemplate = MODULE_DB.mobCountTemplate or "Nearby mobs: %n"
    MobCountFrame.text:SetText((textTemplate:gsub("%%n", tostring(count))))
end

ApplyMobCountStyle = function()
    CreateMobCountFrame()
    if not MobCountFrame then
        return
    end

    ApplyFontString(MobCountFrame.text, MODULE_DB.mobCountFont)
    MobCountFrame.text:ClearAllPoints()
    MobCountFrame.text:SetPoint("CENTER", MobCountFrame, "CENTER", MODULE_DB.mobCountFont.x or 0, MODULE_DB.mobCountFont.y or 0)

    RestoreFramePoint(MobCountFrame, MODULE_DB.mobCountPos, "CENTER", 0, 120)
    UpdateMobCountText()

    if MODULE_DB.preview then
        MobCountFrame:SetBackdropColor(0.3, 0.3, 0.8, 0.45)
        MobCountFrame:SetBackdropBorderColor(0.6, 0.6, 1, 1)
        MobCountFrame:EnableMouse(true)
        MobCountFrame:Show()
    elseif MODULE_DB.mobCountEnabled then
        MobCountFrame:SetBackdropColor(0, 0, 0, 0)
        MobCountFrame:SetBackdropBorderColor(0, 0, 0, 0)
        MobCountFrame:EnableMouse(false)
        MobCountFrame:Show()
    else
        MobCountFrame:Hide()
    end
end

local function OnEvent(event, unit)
    if event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
        ScheduleAutoInsertKeystone()
        return
    end

    if event == "CHALLENGE_MODE_KEYSTONE_SLOTTED" then
        keystoneRetryToken = keystoneRetryToken + 1
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        MODULE_DB.preview = false
        MODULE_DB.locked = true
        MODULE_DB.brezLocked = true

        if InCombatLockdown() then
            StartTimer()
        else
            StopTimer()
        end

        ApplyStyle()
        ApplyMobCountStyle()
        ScheduleBRezRefresh()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if MODULE_DB.enabled then
            ResetTimer()
            StartTimer()
        end
        UpdateMobCountText()
        ApplyStyle()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        StopTimer()
        UpdateMobCountText()
        ApplyStyle()
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" or event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_COMPLETED" or event == "SPELL_UPDATE_CHARGES" then
        ApplyStyle()
        ScheduleBRezRefresh()
        return
    end

    if event == "UNIT_FLAGS" then
        if unit and unit:find("nameplate", 1, true) then
            UpdateMobCountText()
        else
            UpdateBRezInfo()
        end
    end
end

CreateTimerFrame()
CreateBRezFrame()
CreateMobCountFrame()
ApplyStyle()
ApplyMobCountStyle()

InfinityTools:RegisterEvent("PLAYER_REGEN_DISABLED", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("PLAYER_REGEN_ENABLED", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("ZONE_CHANGED_NEW_AREA", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("CHALLENGE_MODE_START", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("CHALLENGE_MODE_COMPLETED", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("CHALLENGE_MODE_KEYSTONE_SLOTTED", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("UNIT_FLAGS", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("SPELL_UPDATE_CHARGES", INFINITY_MODULE_KEY, OnEvent)
InfinityTools:RegisterEvent("NAME_PLATE_UNIT_ADDED", INFINITY_MODULE_KEY, UpdateMobCountText)
InfinityTools:RegisterEvent("NAME_PLATE_UNIT_REMOVED", INFINITY_MODULE_KEY, UpdateMobCountText)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function()
    ApplyStyle()
    ApplyMobCountStyle()
end)

InfinityTools:WatchState("IsBossEncounter", INFINITY_MODULE_KEY, function(isBossEncounter)
    if isBossEncounter and MODULE_DB.resetOnBoss then
        ResetTimer()
        StartTimer()
    end
    ApplyStyle()
    ScheduleBRezRefresh()
end)

InfinityTools:WatchState("DifficultyID", INFINITY_MODULE_KEY, ApplyStyle)
InfinityTools:WatchState("InstanceType", INFINITY_MODULE_KEY, ApplyStyle)

InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    MODULE_DB.preview = enabled and true or false
    MODULE_DB.locked = not enabled
    MODULE_DB.brezLocked = not enabled

    ApplyStyle()
    ApplyMobCountStyle()

    if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() and InfinityTools.UI.RefreshContent then
        InfinityTools.UI:RefreshContent()
    end
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)

