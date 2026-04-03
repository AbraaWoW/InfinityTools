-- =============================================================
-- [[ Streamer Tools ]]
-- { Key = "RRTTools.StreamerTools", Name = "Streamer Tools", Desc = "Provides combat timer and livestream helper tools.", Category = 4 },
-- =============================================================

local RRTToolsCore = _G.RRTToolsCore
if not RRTToolsCore then return end
local L = (RRTToolsCore and RRTToolsCore.L) or setmetatable({}, { __index = function(_, key) return key end })

local RRT_MODULE_KEY = "RRTTools.StreamerTools"

-- =============================================================
-- Comment translated to English
-- =============================================================
local function RRT_RegisterLayout()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 47, h = 2, label = L["1. Combat Timer"], labelSize = 20 },
        { key = "enabled", type = "checkbox", x = 1, y = 4, w = 11, h = 2, label = L["Enable Timer"] },
        { key = "resetOnBoss", type = "checkbox", x = 12, y = 4, w = 11, h = 2, label = L["Reset on Boss"] },
        { key = "hideOutOfCombat", type = "checkbox", x = 24, y = 4, w = 10, h = 2, label = L["Hide Out of Combat"] },
        { key = "keepTimeOnLeaveCombat", type = "checkbox", x = 35, y = 4, w = 11, h = 2, label = L["Pause Out of Combat"] },
        { key = "locked", type = "checkbox", x = 47, y = 4, w = 8, h = 2, label = L["Lock"] },
        { key = "leftText", type = "input", x = 1, y = 8, w = 15, h = 2, label = L["Prefix Text (Left)"], labelPos = "top" },
        { key = "rightText", type = "input", x = 18, y = 8, w = 15, h = 2, label = L["Suffix Text (Right)"], labelPos = "top" },
        { key = "timerFont", type = "fontgroup", x = 1, y = 11, w = 53, h = 17, label = L["Font Style Settings"] },
        { key = "header2", type = "header", x = 1, y = 32, w = 52, h = 2, label = L["2. Battle Resurrection"], labelSize = 20 },
        { key = "brezEnabled", type = "checkbox", x = 1, y = 35, w = 12, h = 2, label = L["Enable Brez Tracking"] },
        { key = "brezLocked", type = "checkbox", x = 16, y = 35, w = 10, h = 2, label = L["Lock Position"] },
        { key = "brezTimerFont", type = "fontgroup", x = 1, y = 57, w = 54, h = 18, label = L["Brez Timer Text (Center)"], labelSize = 20 },
        { key = "brezCountFont", type = "fontgroup", x = 1, y = 76, w = 54, h = 18, label = L["Brez Charges Text (Bottom Right)"], labelSize = 20 },
        { key = "brezIcon", type = "icongroup", x = 1, y = 38, w = 54, h = 18, label = L["Brez Icon Size/Position"], labelSize = 20 },
        { key = "header3", type = "header", x = 1, y = 96, w = 52, h = 2, label = L["3. Mythic+ Keystone"], labelSize = 20 },
        { key = "autoInsertKeystone", type = "checkbox", x = 1, y = 99, w = 24, h = 2, label = L["Auto Insert Keystone When Panel Opens"] },
    }




    RRTToolsCore:RegisterModuleLayout(RRT_MODULE_KEY, layout)
end
RRT_RegisterLayout()

-- =============================================================
-- Comment translated to English
-- =============================================================
if not RRTToolsCore:IsModuleEnabled(RRT_MODULE_KEY) then return end

-- =============================================================
-- Comment translated to English
-- =============================================================
local RRT_DEFAULTS = {
    brezCountFont = {
        a = 1,
        b = 1,
        font = "Friz Quadrata TT",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        size = 15,
        x = -2,
        y = 3,
    },
    brezEnabled = false,
    brezIcon = {
        height = 50,
        reverse = false,
        showIcon = true,
        width = 50,
        x = -831,
        y = -65,
    },
    brezLocked = true,
    preview = false, -- Edit Mode preview state
    autoInsertKeystone = true,
    brezTimerFont = {
        a = 1,
        b = 0.1843137294054,
        font = "Default",
        g = 0.78823536634445,
        outline = "OUTLINE",
        r = 1,
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        size = 20,
        x = 0,
        y = 0,
    },
    enabled = false,
    leftText = "[",
    locked = true,
    pos = {
        "CENTER",
        0,
        0,
    },
    resetOnBoss = true,
    hideOutOfCombat = false,
    keepTimeOnLeaveCombat = true,
    rightText = "]",
    timerFont = {
        a = 1,
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        size = 24,
        x = 0,
        y = 0,
    },
}

local RRT_DB = RRTToolsCore:GetModuleDB(RRT_MODULE_KEY, RRT_DEFAULTS)
local InfinityDB = _G.InfinityDB

-- Comment translated to English
local ApplyStyle, UpdateBRezInfo
local brezRetryToken = 0
local BREZ_RETRY_DELAYS = { 0, 1, 2, 5, 10 }

-- =============================================================
-- Comment translated to English
-- =============================================================
local KEYSTONE_RETRY_INTERVAL = 0.15
local KEYSTONE_RETRY_MAX = 8
local keystoneRetryToken = 0

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
    if not RRT_DB.autoInsertKeystone then return false end
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
            if CloseAllBags then CloseAllBags() end
            return true
        end

-- Comment translated to English
        if C_Container and C_Container.PickupContainerItem then
            C_Container.PickupContainerItem(bag, slot)
        end
        return false
    end

    return false
end

local function ScheduleAutoInsertKeystone()
    if not RRT_DB.autoInsertKeystone then return end

    keystoneRetryToken = keystoneRetryToken + 1
    local token = keystoneRetryToken

    local function Attempt(remaining)
        if token ~= keystoneRetryToken then return end
        if not RRT_DB.autoInsertKeystone then return end
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

-- =============================================================
-- Comment translated to English
-- =============================================================
local BRezFrame
local SPELL_ID_REBIRTH = 20484    -- Rebirth (Standard)
local SPELL_ID_OVERRIDE = 1259644 -- M+ Context Check ID (User Provided)

-- Comment translated to English
local function CreateBRezFrame()
    if BRezFrame then return BRezFrame end

    local f = CreateFrame("Frame", "RRTBRezFrame", UIParent, "BackdropTemplate")
    f:SetSize(40, 40) -- Default size, will be updated by ApplyStyle
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:SetClampedToScreen(true)

-- Comment translated to English
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    f:SetBackdropColor(0, 0, 0, 0.5)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

-- Comment translated to English
    f.Icon = f:CreateTexture(nil, "ARTWORK")
    f.Icon:SetTexture(C_Spell.GetSpellTexture(SPELL_ID_REBIRTH) or 136080) -- Rebirth Icon
    f.Icon:SetPoint("TOPLEFT", 2, -2)
    f.Icon:SetPoint("BOTTOMRIGHT", -2, 2)
    f.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Comment translated to English
    f.Cooldown = CreateFrame("Cooldown", "$parentCooldown", f, "CooldownFrameTemplate")
    f.Cooldown:SetAllPoints()
    f.Cooldown:SetDrawEdge(false)
    f.Cooldown:SetSwipeColor(0, 0, 0, 0.7)
    f.Cooldown:SetHideCountdownNumbers(true)
    f.Cooldown:SetFrameLevel(f:GetFrameLevel() + 1)

-- Comment translated to English
    f.TextOverlay = CreateFrame("Frame", nil, f)
    f.TextOverlay:SetAllPoints()
    f.TextOverlay:SetFrameStrata(f:GetFrameStrata())
    f.TextOverlay:SetFrameLevel(f.Cooldown:GetFrameLevel() + 1)
    f.TextOverlay:EnableMouse(false)

-- Comment translated to English
    f.Timer = f.TextOverlay:CreateFontString(nil, "OVERLAY")
    f.Timer:SetPoint("CENTER", 0, 0)
    f.Timer:SetJustifyH("CENTER")
    if f.Timer.SetDrawLayer then
        f.Timer:SetDrawLayer("OVERLAY", 7)
    end

-- Comment translated to English
    f.Count = f.TextOverlay:CreateFontString(nil, "OVERLAY")
    f.Count:SetPoint("BOTTOMRIGHT", -2, 2)
    f.Count:SetJustifyH("RIGHT")
    if f.Count.SetDrawLayer then
        f.Count:SetDrawLayer("OVERLAY", 7)
    end

-- Comment translated to English
    f.Text = f.Timer

-- Comment translated to English
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not RRT_DB.brezLocked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        local ex, ey = self:GetCenter()
        local scale = self:GetScale()
        if cx and ex and scale then
            RRT_DB.brezIcon.x = math.floor((ex * scale - cx) + 0.5)
            RRT_DB.brezIcon.y = math.floor((ey * scale - cy) + 0.5)
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", RRT_DB.brezIcon.x / scale, RRT_DB.brezIcon.y / scale)
            if RRTToolsCore.UI and RRTToolsCore.UI.MainFrame and RRTToolsCore.UI.MainFrame:IsShown() then
                RRTToolsCore.UI:RefreshContent()
            end
        end
    end)

-- Comment translated to English
    local iconCfg = RRT_DB.brezIcon
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", (iconCfg.x or 100), (iconCfg.y or 0))

    BRezFrame = f
    RRTToolsCore:RegisterHUD(RRT_MODULE_KEY, f)
    return f
end


-- =============================================================
-- Comment translated to English
-- =============================================================

-- ----------------- Timer Logic (Original) -----------------
local TimerFrame
local combatStartTime = 0
local combatEndTime = 0
local isRunning = false

local function CreateTimerFrame()
    if TimerFrame then return TimerFrame end

    local f = CreateFrame("Frame", "RRTCombatTimerFrame", UIParent, "BackdropTemplate")
    f:SetSize(200, 40)
    f:SetFrameStrata("MEDIUM")
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0)
    f:SetBackdropBorderColor(0, 0, 0, 0)

    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("CENTER", 0, 0)
    f.text:SetJustifyH("CENTER")

    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not RRT_DB.locked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        RRT_DB.pos = { point, x, y }
    end)

    if RRT_DB.pos then
        f:ClearAllPoints()
        f:SetPoint(RRT_DB.pos[1], UIParent, RRT_DB.pos[1], RRT_DB.pos[2], RRT_DB.pos[3])
    else
        f:SetPoint("CENTER")
    end

    f:SetScript("OnUpdate", function(self, elapsed)
        if not isRunning then return end
        self.updater = (self.updater or 0) + elapsed
        if self.updater < 0.05 then return end
        self.updater = 0

        local now = GetTime()
        local duration = now - combatStartTime
        local minutes = math.floor(duration / 60)
        local seconds = math.floor(duration % 60)
        local timeStr = string.format("%02d:%02d", minutes, seconds)
        local fullText = (RRT_DB.leftText or "") .. timeStr .. (RRT_DB.rightText or "")
        self.text:SetText(fullText)
    end)

    TimerFrame = f
    RRTToolsCore:RegisterHUD(RRT_MODULE_KEY, f)
    return f
end

local function StartTimer()
    if isRunning then return end
    combatStartTime = GetTime()
    isRunning = true
    if TimerFrame then TimerFrame:Show() end
end

local function StopTimer()
    if isRunning then
        combatEndTime = GetTime()
    end
    isRunning = false
end

local function ResetTimer()
    combatStartTime = GetTime()
    if not isRunning and RRT_DB.enabled then
        local fullText = (RRT_DB.leftText or "") .. "00:00" .. (RRT_DB.rightText or "")
        if TimerFrame then TimerFrame.text:SetText(fullText) end
    end
end

-- ----------------- BRez Logic (New) -----------------

-- Comment translated to English
-- Comment translated to English
local function IsActiveEnvironment()
    local state = RRTToolsCore.State
-- Comment translated to English
    if state.DifficultyID == 8 then return true end

-- Comment translated to English
-- Comment translated to English
    if state.InstanceType == "party" then
        return false
    end

-- Comment translated to English
    if state.InstanceType == "raid" then
        return state.IsBossEncounter
    end

-- Comment translated to English
    if state.IsBossEncounter then return true end

    return false
end

-- Comment translated to English
UpdateBRezInfo = function()
    if not BRezFrame then return false end

    local currentCharges, maxCharges, cooldownDuration, cooldownStartTime, remainingCooldown

-- Comment translated to English
    if RRT_DB.preview then
        currentCharges = 2
        maxCharges = 3
        cooldownDuration = 60
        cooldownStartTime = GetTime() - 5
        remainingCooldown = 55
    else
        local spellIdentifier = SPELL_ID_REBIRTH
        local RRT_Charges = C_Spell.GetSpellCharges(spellIdentifier)
        if not (RRT_Charges and (RRT_Charges.maxCharges or 0) > 0) then
            return false
        end
        currentCharges = RRT_Charges.currentCharges or 0
        maxCharges = RRT_Charges.maxCharges or 0
        cooldownDuration = RRT_Charges.cooldownDuration or 0
        cooldownStartTime = RRT_Charges.cooldownStartTime or 0
        remainingCooldown = 0
    end

-- Comment translated to English
    if not RRT_DB.preview then
        if currentCharges < maxCharges and cooldownStartTime > 0 then
            remainingCooldown = math.max(0, cooldownStartTime + cooldownDuration - GetTime())
        end
    end

    if remainingCooldown > 0 then
-- Comment translated to English
        if BRezFrame.Cooldown then
            BRezFrame.Cooldown:SetCooldown(cooldownStartTime, cooldownDuration)
        end

-- Comment translated to English
        if BRezFrame.Timer:GetFont() then
-- Comment translated to English
            if remainingCooldown >= 600 then
                BRezFrame.Timer:SetFormattedText("%dm", math.ceil(remainingCooldown / 60))
            else
                BRezFrame.Timer:SetFormattedText("%d:%02d", math.floor(remainingCooldown / 60), remainingCooldown % 60)
            end
        end
    else
        if BRezFrame.Cooldown then BRezFrame.Cooldown:Clear() end
        if BRezFrame.Timer:GetFont() then
            BRezFrame.Timer:SetText("")
        end
    end

-- Comment translated to English
    if BRezFrame.Count:GetFont() then
        BRezFrame.Count:SetText(currentCharges)
    end
    return true
end

-- BRez OnUpdate Handling
local brezUpdater = 0
local function BRez_OnUpdate(self, elapsed)
    brezUpdater = brezUpdater + elapsed
    if brezUpdater < 0.1 then return end
    brezUpdater = 0
    UpdateBRezInfo()
end

local function HasBRezChargeData()
    local chargeInfo = C_Spell.GetSpellCharges(SPELL_ID_REBIRTH)
    return chargeInfo and (chargeInfo.maxCharges or 0) > 0
end

local function ScheduleBRezRefresh(reason)
    brezRetryToken = brezRetryToken + 1
    local token = brezRetryToken

    for _, delay in ipairs(BREZ_RETRY_DELAYS) do
        C_Timer.After(delay, function()
            if token ~= brezRetryToken then return end
            ApplyStyle()
            if HasBRezChargeData() then
                brezRetryToken = brezRetryToken + 1
            end
        end)
    end
end

-- ----------------- Apply Styles -----------------

ApplyStyle = function()
    -- 1. Combat Timer
    if TimerFrame then
        local font = RRT_DB.timerFont
        if InfinityDB and InfinityDB.ApplyFont then
            InfinityDB:ApplyFont(TimerFrame.text, font)
        else
            local LSM = LibStub("LibSharedMedia-3.0")
            local fontPath = LSM:Fetch("font", font.font) or "Fonts\\FRIZQT__.TTF"
            TimerFrame.text:SetFont(fontPath, font.size, font.outline)
            TimerFrame.text:SetTextColor(font.r, font.g, font.b, font.a)
            if font.shadow then
                TimerFrame.text:SetShadowOffset(font.shadowX, font.shadowY)
                TimerFrame.text:SetShadowColor(0, 0, 0, 1)
            else
                TimerFrame.text:SetShadowOffset(0, 0)
            end
        end
        TimerFrame.text:ClearAllPoints()
        TimerFrame.text:SetPoint("CENTER", font.x or 0, font.y or 0)

        if not RRT_DB.locked then
            TimerFrame:SetBackdropColor(0, 0.5, 0, 0.5)
            TimerFrame:EnableMouse(true)
        else
            TimerFrame:SetBackdropColor(0, 0, 0, 0)
            TimerFrame:EnableMouse(false)
        end

        if not isRunning then
            local fullText
-- Comment translated to English
            if RRT_DB.keepTimeOnLeaveCombat and combatEndTime > combatStartTime then
                local duration = combatEndTime - combatStartTime
                local minutes = math.floor(duration / 60)
                local seconds = math.floor(duration % 60)
                fullText = (RRT_DB.leftText or "") ..
                    string.format("%02d:%02d", minutes, seconds) .. (RRT_DB.rightText or "")
            else
                fullText = (RRT_DB.leftText or "") .. "00:00" .. (RRT_DB.rightText or "")
            end
            TimerFrame.text:SetText(fullText)
        end

-- Comment translated to English
        local showTimer = RRT_DB.enabled
        if RRT_DB.hideOutOfCombat and not isRunning and not RRT_DB.preview then
            showTimer = false
        end

        if showTimer then TimerFrame:Show() else TimerFrame:Hide() end
    end

    -- 2. Battle Res Frame
    if BRezFrame then
-- Comment translated to English
        -- 1. Timer Font & Style (Center)
        local tFont = RRT_DB.brezTimerFont
        if InfinityDB and InfinityDB.ApplyFont and InfinityDB:ApplyFont(BRezFrame.Timer, tFont) then
            -- Done via engine
        else
            local LSM = LibStub("LibSharedMedia-3.0")
            local fPath = LSM:Fetch("font", tFont.font) or "Fonts\\FRIZQT__.TTF"
            BRezFrame.Timer:SetFont(fPath, tFont.size, tFont.outline)
            BRezFrame.Timer:SetTextColor(tFont.r, tFont.g, tFont.b, tFont.a)
            if tFont.shadow then
                BRezFrame.Timer:SetShadowOffset(tFont.shadowX, tFont.shadowY)
                BRezFrame.Timer:SetShadowColor(0, 0, 0, 1)
            else
                BRezFrame.Timer:SetShadowOffset(0, 0)
            end
        end
        BRezFrame.Timer:ClearAllPoints()
        BRezFrame.Timer:SetPoint("CENTER", BRezFrame, "CENTER", tFont.x or 0, tFont.y or 0)

        -- 2. Count Font & Style (Bottom Right)
        local cFont = RRT_DB.brezCountFont
        if InfinityDB and InfinityDB.ApplyFont and InfinityDB:ApplyFont(BRezFrame.Count, cFont) then
            -- Done via engine
        else
            local LSM = LibStub("LibSharedMedia-3.0")
            local fPath = LSM:Fetch("font", cFont.font) or "Fonts\\FRIZQT__.TTF"
            BRezFrame.Count:SetFont(fPath, cFont.size, cFont.outline)
            BRezFrame.Count:SetTextColor(cFont.r, cFont.g, cFont.b, cFont.a)
            if cFont.shadow then
                BRezFrame.Count:SetShadowOffset(cFont.shadowX, cFont.shadowY)
                BRezFrame.Count:SetShadowColor(0, 0, 0, 1)
            else
                BRezFrame.Count:SetShadowOffset(0, 0)
            end
        end
        BRezFrame.Count:ClearAllPoints()
        BRezFrame.Count:SetPoint("BOTTOMRIGHT", BRezFrame, "BOTTOMRIGHT", cFont.x or 0, cFont.y or 0)
-- Comment translated to English

-- Comment translated to English
        local poolActive = UpdateBRezInfo()
        local showBrez = (RRT_DB.brezEnabled and poolActive and IsActiveEnvironment())

-- Comment translated to English
        if not RRT_DB.brezLocked then showBrez = true end

        if showBrez then
            BRezFrame:Show()
            BRezFrame:SetScript("OnUpdate", BRez_OnUpdate) -- Enable updates
        else
            BRezFrame:Hide()
            BRezFrame:SetScript("OnUpdate", nil)
        end

        -- 3. Cooldown Swipe Effect
        if BRezFrame.Cooldown then
            BRezFrame.Cooldown:SetReverse(RRT_DB.brezIcon and RRT_DB.brezIcon.reverse or false)
        end

        BRezFrame:SetSize(RRT_DB.brezIcon.width or 32, RRT_DB.brezIcon.height or 32)
-- Comment translated to English
        BRezFrame:SetScale(1.0)

-- Comment translated to English
        local tex = RRT_DB.brezIcon.iconID or C_Spell.GetSpellTexture(SPELL_ID_REBIRTH) or 136080
        BRezFrame.Icon:SetTexture(tex)

        -- Position override if moving
        if not RRT_DB.brezLocked then
            BRezFrame:SetBackdropColor(0, 0.5, 1, 0.5) -- Blue for BRez
            BRezFrame:EnableMouse(true)
        else
            BRezFrame:SetBackdropColor(0, 0, 0, 0)
            BRezFrame:EnableMouse(false)
        end

-- Comment translated to English
        local iconCfg = RRT_DB.brezIcon
        BRezFrame:ClearAllPoints()
        BRezFrame:SetPoint("CENTER", UIParent, "CENTER", iconCfg.x or 100, iconCfg.y or 0)

        UpdateBRezInfo() -- Initial update
    end
end

-- =============================================================
-- 6. Event Handling
-- =============================================================

local function OnEvent(event, unit)
    if event == "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN" then
        ScheduleAutoInsertKeystone()
        return
    elseif event == "CHALLENGE_MODE_KEYSTONE_SLOTTED" then
-- Comment translated to English
        keystoneRetryToken = keystoneRetryToken + 1
    elseif event == "PLAYER_ENTERING_WORLD" then
        RRT_DB.preview = false
        RRT_DB.locked = true
        RRT_DB.brezLocked = true
    end

    -- Combat Timer Logic
    if RRT_DB.enabled then
        if event == "PLAYER_REGEN_DISABLED" then
            ResetTimer()
            StartTimer()
        elseif event == "PLAYER_REGEN_ENABLED" then
            StopTimer()
            ApplyStyle() -- Comment translated to English
        elseif event == "PLAYER_ENTERING_WORLD" then
            if InCombatLockdown() then
                if not isRunning then StartTimer() end
            else
                StopTimer()
            end
            ApplyStyle() -- Re-check zone (M+)
        end
    end

    -- Battle Res Logic
    if event == "ZONE_CHANGED_NEW_AREA" or event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_COMPLETED" then
        ApplyStyle()
        ScheduleBRezRefresh(event)
    elseif event == "SPELL_UPDATE_CHARGES" then
        ApplyStyle()
    end

    -- Specific Update Trigger (User Requested)
    if event == "UNIT_FLAGS" then
        UpdateBRezInfo()
    end
end

-- =============================================================
-- 7. Initialization
-- =============================================================

CreateTimerFrame()
-- Don't create a duplicate BattleRez frame if the dedicated QoL BattleRez module is loaded
if not (_G.RRT_NS and _G.RRT_NS.BattleRez) then
    CreateBRezFrame()
end
ApplyStyle()

RRTToolsCore:RegisterEvent("PLAYER_REGEN_DISABLED", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("PLAYER_REGEN_ENABLED", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("PLAYER_ENTERING_WORLD", RRT_MODULE_KEY, OnEvent)

RRTToolsCore:RegisterEvent("ZONE_CHANGED_NEW_AREA", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("CHALLENGE_MODE_START", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("CHALLENGE_MODE_COMPLETED", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("CHALLENGE_MODE_KEYSTONE_SLOTTED", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("UNIT_FLAGS", RRT_MODULE_KEY, OnEvent)
RRTToolsCore:RegisterEvent("SPELL_UPDATE_CHARGES", RRT_MODULE_KEY, OnEvent)

-- Comment translated to English
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".DatabaseChanged", RRT_MODULE_KEY, function(info)
    ApplyStyle()
end)

-- Comment translated to English
RRTToolsCore:WatchState("IsBossEncounter", RRT_MODULE_KEY, function(isBoss)
    if isBoss and RRT_DB.resetOnBoss then
-- Comment translated to English
        ResetTimer()
        StartTimer()
    end
    ApplyStyle() -- Comment translated to English
    ScheduleBRezRefresh("IsBossEncounter")
end)

-- Comment translated to English
RRTToolsCore:WatchState("DifficultyID", RRT_MODULE_KEY, function()
    ApplyStyle()
end)
RRTToolsCore:WatchState("InstanceType", RRT_MODULE_KEY, function()
    ApplyStyle()
end)

-- Comment translated to English
RRTToolsCore:RegisterEditModeCallback(RRT_MODULE_KEY, function(enabled)
    RRT_DB.preview = enabled
    RRT_DB.locked = not enabled
    RRT_DB.brezLocked = not enabled
    ApplyStyle()

-- Comment translated to English
    if RRTToolsCore.UI and RRTToolsCore.UI.RightPanel and RRTToolsCore.UI.RightPanel:IsVisible() and RRTToolsCore.UI.RefreshContent then
        RRTToolsCore.UI:RefreshContent()
    end
end)

RRTToolsCore:ReportReady(RRT_MODULE_KEY)
