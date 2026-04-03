-- =============================================================
-- [[ Movement CD Alert (No Move Skill Alert) ]]
-- =============================================================

local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevClass.NoMoveSkillAlert"

-- =============================================================
-- Grid Layout
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 54, h = 2, label = L["Movement CD Alert"], labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 54, h = 2, label = L["Shows an on-screen alert when movement abilities are on cooldown.|cffff0518Currently supports Mage/Rogue. More classes later.|r"] },
        { key = "divider_top", type = "divider", x = 1, y = 20, w = 54, h = 1, label = "--[[ Function ]]" },
        { key = "enabled", type = "checkbox", x = 1, y = 8, w = 10, h = 2, label = L["Enable"] },  -- TODO: missing key: L["Enable"]
        { key = "displayFormat", type = "input", x = 1, y = 50, w = 26, h = 2, label = L["Display Format (%t = time)"], labelPos = "top" },
        { key = "decimalThreshold", type = "slider", x = 1, y = 13, w = 18, h = 2, label = L["Decimal Threshold (sec)"], min = 0, max = 30 },
        { key = "desc_format", type = "description", x = 1, y = 16, w = 54, h = 1, label = L["|cff97a393Example: No Blink (%t) -> No Blink (12) or No Blink (3.2)|r"], labelSize = 12 },
        { key = "font_alert", type = "fontgroup", x = 1, y = 27, w = 53, h = 17, label = L["Alert Text|cffff140d (position set above)|r"], labelSize = 20 },
        { key = "sub_pos", type = "subheader", x = 1, y = 18, w = 54, h = 2, label = L["Position"], labelSize = 20 },
        { key = "posX", type = "slider", x = 1, y = 23, w = 15, h = 2, label = L["Position X|cff0aff2a (edit here)|r"], min = -800, max = 800 },
        { key = "posY", type = "slider", x = 18, y = 23, w = 15, h = 2, label = L["Position Y|cff0aff2a (edit here)|r"], min = -500, max = 500 },
        { key = "btn_reset_pos", type = "button", x = 37, y = 22, w = 13, h = 3, label = L["Reset Position"] },
        { key = "divider_8703", type = "divider", x = 1, y = 6, w = 54, h = 1, label = L["Components"] },
        { key = "h_rogue", type = "header", x = 1, y = 53, w = 54, h = 2, label = "|cfffff468" .. L["Rogue Settings"] .. "|r", labelSize = 20 },
        { key = "rogue_fmt_shadow", type = "input", x = 1, y = 57, w = 26, h = 2, label = L["Shadowstep Format (%t = time)"], labelPos = "top" },
        { key = "rogue_fmt_phantom", type = "input", x = 28, y = 57, w = 26, h = 2, label = L["Grappling Hook Format (%t = time)"], labelPos = "top" },
        { key = "header_8482", type = "header", x = 1, y = 46, w = 53, h = 2, label = "|cff3fc7eb" .. L["Mage Settings"] .. "|r", labelSize = 20 },
    }


    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =============================================================
-- Default Settings
-- =============================================================
local MODULE_DEFAULTS                         = {
    decimalThreshold  = 6,
    displayFormat     = "No Blink (%t)",
    enabled           = false,
    font_alert        = {
        a = 1,
        align = "CENTER",
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = false,
        shadowX = 2,
        shadowY = -2,
        size = 15,
    },
    posX              = 15,
    posY              = -5,
    -- Rogue-only settings
    rogue_fmt_shadow  = "No Shadowstep (%t)",
    rogue_fmt_phantom = "No Grapple (%t)",
}

local MODULE_DB                               = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =============================================================
-- Declarative Config
-- =============================================================
--REPLACE_SPELL=Replace Spell
--CD_REDUCE=Reduce CD
--CHARGE_ADD=Add Charge

local CLASS_CONFIGS                       = {
    -- [v12.2 Adjust] Mage now uses direct API reads; old manual calculation config is disabled
    --[[
    MAGE = {
        base = {
            spellID = 1953,
            charges = 1,
            cd = 18,
        },
        upgrades = {
            {
                talentID = 212653,
                action = "REPLACE_SPELL",
                newSpellID = 212653,
                newCD = 30,
            },
        },
        modifiers = {
            {
                talentID = 382268,
                action = "CD_REDUCE",
                value = 3,
            },
            {
                talentID = 1244031,
                action = "CHARGE_ADD",
                value = 1,
            },
        },
        displayText = "No Blink",
    },
    ]]
}

-- =============================================================
-- [Rogue] Event-driven engine
-- Listens for UNIT_SPELLCAST_SUCCEEDED; determines the monitored spell and timer duration by spec:
-- 259(Subtlety)/261(Assassination) → 36554(Shadowstep) 30s
-- 260(Outlaw) → 195457(Grappling Hook) 45s
-- Consecutive casts only keep the latest timer (overwrites rogueEndTime)
-- =============================================================
local ROGUE_SPELL_SHADOW                  = 36554 -- Shadowstep (Subtlety/Assassination)
local ROGUE_SPELL_PHANTOM                 = 195457 -- Grappling Hook (Outlaw)
local MAGE_SPELL_BLINK                    = 1953 -- Blink
local MAGE_SPELL_SHIMMER                  = 212653 -- Shimmer
local ALERT_REFRESH_INTERVAL              = 0.5

local rogueFrame                          = CreateFrame("Frame")
local rogueEndTime                        = nil -- Absolute expiration time of the timer; nil means inactive
local rogueDuration                       = 30 -- Timer duration for the current spec (seconds)
local rogueRefresh                        = ALERT_REFRESH_INTERVAL -- Refresh counter (initial value triggers immediate first-frame refresh)
local mageFrame                           = CreateFrame("Frame")
local mageSpellID                         = nil
local mageRefresh                         = ALERT_REFRESH_INTERVAL
-- OnUpdate / event registration happens after alertFrame is created (see below)

-- =============================================================
-- Runtime State
-- =============================================================
local activeSpellID                       = nil
local maxCharges                          = 0
local currentCharges                      = 0
local chargeCooldown                      = 0
local rechargeStartTime                   = 0
local isActive                            = false
local GRACE_PERIOD                        = 2



-- =============================================================
-- UI Frame
-- =============================================================
local alertFrame = CreateFrame("Frame", "RevNoMoveSkillAlertFrame", UIParent)
alertFrame:SetSize(300, 50)
alertFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
alertFrame:SetMovable(true)
alertFrame:SetClampedToScreen(true)
alertFrame:Hide()

local alertText = alertFrame:CreateFontString(nil, "OVERLAY")
alertText:SetPoint("CENTER")

-- [v12.1 Fix] Centralized mouse interaction control; ensures click-through in non-edit mode
local function SetAlertFrameMouseInteractive(enabled)
    alertFrame:EnableMouse(enabled)
    if alertFrame.SetMouseClickEnabled then
        alertFrame:SetMouseClickEnabled(enabled)
    end
    if alertFrame.SetMouseMotionEnabled then
        alertFrame:SetMouseMotionEnabled(enabled)
    end
end

local function ApplyFontSettings()
    local db = MODULE_DB.font_alert
    local fontPath = InfinityTools.MAIN_FONT
    if db.font and db.font ~= "Default" then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            fontPath = LSM:Fetch("font", db.font) or fontPath
        end
    end
    alertText:SetFont(fontPath, db.size or 28, db.outline or "OUTLINE")
    alertText:SetTextColor(db.r or 1, db.g or 0.2, db.b or 0.2, db.a or 1)
    if db.shadow then
        alertText:SetShadowOffset(db.shadowX or 2, db.shadowY or -2)
        alertText:SetShadowColor(0, 0, 0, 1)
    else
        alertText:SetShadowOffset(0, 0)
    end
    alertText:SetJustifyH(db.align or "CENTER")
end
ApplyFontSettings()

local function UpdatePosition()
    alertFrame:ClearAllPoints()
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
end

-- alertFrame created; register Rogue event-driven logic
-- OnUpdate: calls GetSpellCooldown every 0.5s to read the actual remaining CD
-- timeUntilEndOfStartRecovery is a secret number
-- string.format("%d", secret) → secret string; prefix/suffix are plain strings, .. concatenation with secret string is valid; SetText accepts secret string
rogueFrame:SetScript("OnUpdate", function(_, elapsed)
    if not rogueEndTime then return end
    if not MODULE_DB.enabled then
        rogueEndTime = nil
        alertFrame:Hide()
        return
    end
    -- Plain number check to see if the timer has expired
    local wallRemaining = rogueEndTime - GetTime()
    if wallRemaining <= 0 then
        rogueEndTime = nil
        alertFrame:Hide()
        return
    end
    rogueRefresh = rogueRefresh + elapsed
    if rogueRefresh < ALERT_REFRESH_INTERVAL then return end
    rogueRefresh = 0
    -- Read actual CD for the spell corresponding to the current spec
    local spellID = (rogueDuration == 45) and ROGUE_SPELL_PHANTOM or ROGUE_SPELL_SHADOW
    local info = C_Spell.GetSpellCooldown(spellID)
    if not info or info.isOnGCD ~= false then
        alertFrame:Hide()
        return
    end
    -- Select the format string for the current spec; prefix/suffix extracted via match (plain string ops), then wrap around secret string with ..
    local fmt = (rogueDuration == 45) and (MODULE_DB.rogue_fmt_phantom or "No Grapple (%t)") or
    (MODULE_DB.rogue_fmt_shadow or "No Shadowstep (%t)")
    local prefix, suffix = fmt:match("^(.-)%%t(.*)$")
    if prefix then
        alertText:SetText(prefix .. string.format("%d", info.timeUntilEndOfStartRecovery) .. suffix)
    else
        alertText:SetText(string.format("%d", info.timeUntilEndOfStartRecovery))
    end
    alertFrame:Show()
end)
rogueFrame:Hide()

-- Listen for cast succeeded event: determine monitored spell and timer duration by spec; consecutive casts keep only the latest
local rogueEventFrame = CreateFrame("Frame")
rogueEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
rogueEventFrame:SetScript("OnEvent", function(_, _, unitTarget, _, spellID)
    if unitTarget ~= "player" then return end
    if spellID ~= ROGUE_SPELL_SHADOW and spellID ~= ROGUE_SPELL_PHANTOM then return end
    if not MODULE_DB.enabled then return end
    -- Determine timer duration by spec: 260(Outlaw)=45s, 259/261=30s
    local specID = GetSpecializationInfo(GetSpecialization())
    if specID == 260 then
        rogueDuration = 45
    else
        rogueDuration = 30
    end
    -- Always reset with the latest cast regardless of existing timer (consecutive casts keep only the latest)
    rogueEndTime = GetTime() + rogueDuration
    rogueRefresh = ALERT_REFRESH_INTERVAL -- Trigger first refresh immediately
    rogueFrame:Show()
end)

-- =============================================================
-- [Mage] Direct API engine
-- No longer manually calculates charges/CD; reads real data directly via C_Spell
-- =============================================================
local function IsSpellKnownSafe(spellID)
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) then
        return true
    end
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end
    return false
end

local function ResolveMageSpellID()
    if IsSpellKnownSafe(MAGE_SPELL_SHIMMER) then
        return MAGE_SPELL_SHIMMER
    end
    if IsSpellKnownSafe(MAGE_SPELL_BLINK) then
        return MAGE_SPELL_BLINK
    end
    return nil
end

local function HideMageDirectAlert()
    alertFrame:Hide()
end

local function UpdateMageDirectAlert()
    if not MODULE_DB.enabled or not mageSpellID then
        HideMageDirectAlert()
        return
    end

    local info = C_Spell.GetSpellCooldown(mageSpellID)
    if not info or info.isOnGCD ~= false then
        HideMageDirectAlert()
        return
    end

    local fmt = MODULE_DB.displayFormat or "No Blink (%t)"
    local prefix, suffix = fmt:match("^(.-)%%t(.*)$")
    if prefix then
        alertText:SetText(prefix .. string.format("%d", info.timeUntilEndOfStartRecovery) .. suffix)
    else
        alertText:SetText(string.format("%d", info.timeUntilEndOfStartRecovery))
    end
    alertFrame:Show()
end

mageFrame:SetScript("OnUpdate", function(_, elapsed)
    if not mageSpellID then return end
    if not MODULE_DB.enabled then
        HideMageDirectAlert()
        return
    end

    mageRefresh = mageRefresh + elapsed
    if mageRefresh < ALERT_REFRESH_INTERVAL then return end
    mageRefresh = 0
    UpdateMageDirectAlert()
end)
mageFrame:Hide()

-- =============================================================
-- Charge Tracking Engine
-- =============================================================
local engineFrame = CreateFrame("Frame")
engineFrame:Hide()

local lastDisplayed = nil

engineFrame:SetScript("OnUpdate", function(self)
    if not isActive or not MODULE_DB.enabled then
        alertFrame:Hide()
        self:Hide()
        return
    end

    if currentCharges < maxCharges and rechargeStartTime > 0 then
        if GetTime() - rechargeStartTime >= chargeCooldown then
            currentCharges = currentCharges + 1
            if currentCharges < maxCharges then
                rechargeStartTime = rechargeStartTime + chargeCooldown
            else
                rechargeStartTime = 0
                self:Hide()
            end
        end
    end

    if currentCharges == 0 and rechargeStartTime > 0 then
        local remaining = chargeCooldown - (GetTime() - rechargeStartTime)
        if remaining > 0 then
            local threshold = MODULE_DB.decimalThreshold or 6
            local timeStr
            if remaining <= threshold then
                local displayVal = math.floor(remaining * 10)
                if displayVal ~= lastDisplayed then
                    lastDisplayed = displayVal
                    timeStr = string.format("%.1f", remaining)
                end
            else
                local displayVal = math.floor(remaining)
                if displayVal ~= lastDisplayed then
                    lastDisplayed = displayVal
                    timeStr = string.format("%d", displayVal)
                end
            end
            if timeStr then
                local fmt = MODULE_DB.displayFormat or "No Blink (%t)"
                alertText:SetText(fmt:gsub("%%t", timeStr))
            end
            alertFrame:Show()
        else
            alertFrame:Hide()
            lastDisplayed = nil
        end
    else
        if alertFrame:IsShown() then
            alertFrame:Hide()
            lastDisplayed = nil
        end
    end
end)

-- =============================================================
-- Talent Scan
-- =============================================================
local function RefreshActiveSkillData()
    local _, className = UnitClass("player")

    -- Rogue uses a separate polling engine, not the charge tracking engine
    if className == "ROGUE" then
        mageSpellID = nil
        mageFrame:Hide()
        isActive = false
        engineFrame:Hide()
        if MODULE_DB.enabled then
            rogueFrame:Show()
        else
            rogueFrame:Hide()
            rogueEndTime = nil
            alertFrame:Hide()
        end
        return
    end

    if className == "MAGE" then
        rogueFrame:Hide()
        rogueEndTime = nil
        -- [v12.2 Adjust] Mage disables old manual calculation logic; now uses direct API reads
        isActive = false
        engineFrame:Hide()
        mageSpellID = ResolveMageSpellID()
        if MODULE_DB.enabled and mageSpellID then
            mageRefresh = ALERT_REFRESH_INTERVAL
            mageFrame:Show()
            UpdateMageDirectAlert()
        else
            mageFrame:Hide()
            alertFrame:Hide()
        end
        return
    end

    rogueFrame:Hide()
    rogueEndTime = nil
    mageSpellID = nil
    mageFrame:Hide()

    local config = CLASS_CONFIGS[className]
    if not config then
        isActive = false
        alertFrame:Hide()
        engineFrame:Hide()

        return
    end

    activeSpellID = config.base.spellID
    maxCharges = config.base.charges
    chargeCooldown = config.base.cd


    for _, upgrade in ipairs(config.upgrades) do
        local known = C_SpellBook.IsSpellKnown(upgrade.talentID)

        if known then
            if upgrade.action == "REPLACE_SPELL" then
                activeSpellID = upgrade.newSpellID
                chargeCooldown = upgrade.newCD
            end
        end
    end

    for _, mod in ipairs(config.modifiers) do
        local known = C_SpellBook.IsSpellKnown(mod.talentID)

        if known then
            if mod.action == "CD_REDUCE" then
                chargeCooldown = chargeCooldown - mod.value
            elseif mod.action == "CHARGE_ADD" then
                maxCharges = maxCharges + mod.value
            end
        end
    end

    currentCharges = maxCharges
    rechargeStartTime = 0
    isActive = true
    alertFrame:Hide()
    engineFrame:Hide()
end

-- =============================================================
-- Successful spell cast handling
-- =============================================================
local function OnSpellCastSucceeded(spellID)
    if not isActive or not MODULE_DB.enabled then return end
    if spellID ~= activeSpellID then return end



    if currentCharges > 0 then
        currentCharges = currentCharges - 1
        if rechargeStartTime == 0 then
            rechargeStartTime = GetTime()
        end
        engineFrame:Show()
    elseif rechargeStartTime > 0 then
        local remaining = chargeCooldown - (GetTime() - rechargeStartTime)

        if remaining > 0 and remaining < GRACE_PERIOD then
            currentCharges = 0
            rechargeStartTime = GetTime()
            engineFrame:Show()
        else

        end
    else
        rechargeStartTime = GetTime()
        engineFrame:Show()
    end
end

-- [v12.2 Adjust] Mage old override-event charge-restore logic disabled (replaced by direct API reads)
--[[
local function OnCooldownViewerSpellOverrideUpdated(baseSpellID, overrideSpellID)
end
]]

-- =============================================================
-- Event Registration
-- =============================================================
InfinityTools:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", INFINITY_MODULE_KEY, function(_, unit, _, spellID)
    if unit ~= "player" then return end
    OnSpellCastSucceeded(spellID)
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    C_Timer.After(1, RefreshActiveSkillData)
end)

InfinityTools:RegisterEvent("PLAYER_TALENT_UPDATE", INFINITY_MODULE_KEY, function()
    C_Timer.After(0.5, RefreshActiveSkillData)
end)

InfinityTools:RegisterEvent("TRAIT_CONFIG_UPDATED", INFINITY_MODULE_KEY, function()
    C_Timer.After(0.5, RefreshActiveSkillData)
end)

-- [v12.2 Adjust] Mage now uses direct API reads; old override event logic disabled
-- InfinityTools:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED", INFINITY_MODULE_KEY, ...)

-- =============================================================
-- Grid Listeners
-- =============================================================
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    if info.key == "enabled" then
        if not MODULE_DB.enabled then
            alertFrame:Hide()
            engineFrame:Hide()
            rogueFrame:Hide()
            rogueEndTime = nil
            mageSpellID = nil
            mageFrame:Hide()
        else
            -- Re-trigger refresh to let Rogue/Mage branches start as needed
            RefreshActiveSkillData()
        end
    elseif info.key == "posX" or info.key == "posY" then
        UpdatePosition()
    elseif info.key == "displayFormat" then
        if alertFrame:IsShown() and alertFrame:IsMouseEnabled() then
            local fmt = MODULE_DB.displayFormat or "No Blink (%t)"
            alertText:SetText(fmt:gsub("%%t", "12"))
        end
    else
        ApplyFontSettings()
    end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if info and info.key == "btn_reset_pos" then
        MODULE_DB.posX = 0
        MODULE_DB.posY = 150
        UpdatePosition()
    end
end)

-- =============================================================
-- Drag / Edit Mode
-- =============================================================
local function SetDragMode(enabled)
    if enabled then
        ApplyFontSettings()
        local fmt = MODULE_DB.displayFormat or "No Blink (%t)"
        alertText:SetText(fmt:gsub("%%t", "12"))
        alertFrame:Show()
        SetAlertFrameMouseInteractive(true)
        alertFrame:RegisterForDrag("LeftButton")

        if not alertFrame.editBG then
            local bg = CreateFrame("Frame", nil, alertFrame, "BackdropTemplate")
            bg:SetPoint("TOPLEFT", alertFrame, "TOPLEFT", -10, 10)
            bg:SetPoint("BOTTOMRIGHT", alertFrame, "BOTTOMRIGHT", 10, -10)
            bg:SetBackdrop({
                bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
                edgeFile = [[Interface\Buttons\WHITE8X8]],
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            bg:SetBackdropColor(0, 0.4, 0, 0.35)
            bg:SetBackdropBorderColor(0, 0.8, 0, 0.8)
            bg:SetFrameLevel(alertFrame:GetFrameLevel())
            alertFrame.editBG = bg
        end
        alertFrame.editBG:Show()

        if not alertFrame.editLabel then
            local label = alertFrame:CreateFontString(nil, "OVERLAY")
            label:SetFont(InfinityTools.MAIN_FONT, 11, "OUTLINE")
            label:SetPoint("BOTTOM", alertFrame, "TOP", 0, 6)
            label:SetTextColor(0, 1, 0, 0.9)
            alertFrame.editLabel = label
        end
        alertFrame.editLabel:SetText(L["Movement CD Alert"])
        alertFrame.editLabel:Show()

        alertFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        alertFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local cx, cy = self:GetCenter()
            local sx, sy = UIParent:GetCenter()
            if cx and sx then
                MODULE_DB.posX = math.floor(cx - sx + 0.5)
                MODULE_DB.posY = math.floor(cy - sy + 0.5)
            end
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
            InfinityTools:UpdateState(INFINITY_MODULE_KEY .. ".DatabaseChanged", { key = "posX", ts = GetTime() })
        end)
        alertFrame:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" and InfinityTools.GlobalEditMode then
                InfinityTools:OpenConfig(INFINITY_MODULE_KEY)
            end
        end)

        if not alertFrame.DragHint then
            alertFrame.DragHint = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            alertFrame.DragHint:SetPoint("TOP", alertFrame, "BOTTOM", 0, -8)
        end
        alertFrame.DragHint:SetText("|cff00ff00" .. L["Drag to reposition"] .. "|r\n|cffaaaaaa" .. L["Right-click to open settings"] .. "|r")
        alertFrame.DragHint:Show()
    else
        SetAlertFrameMouseInteractive(false)
        alertFrame:SetScript("OnDragStart", nil)
        alertFrame:SetScript("OnDragStop", nil)
        alertFrame:SetScript("OnMouseDown", nil)
        if alertFrame.editBG then alertFrame.editBG:Hide() end
        if alertFrame.editLabel then alertFrame.editLabel:Hide() end
        if alertFrame.DragHint then alertFrame.DragHint:Hide() end
        if currentCharges > 0 or not isActive or not MODULE_DB.enabled then
            alertFrame:Hide()
        end
    end
end

InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    SetDragMode(enabled)
end)

InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, alertFrame)
-- RegisterHUD internally forces EnableMouse(true); disable immediately after registration to restore click-through
SetAlertFrameMouseInteractive(false)
InfinityTools:ReportReady(INFINITY_MODULE_KEY)
