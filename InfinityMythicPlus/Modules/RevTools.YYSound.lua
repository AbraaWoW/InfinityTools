-- [[ Bloodlust Sound (YY Sound Effect) ]]
-- { Key = "RevTools.YYSound", Name = "Bloodlust Sound", Desc = "Monitors haste spikes (e.g. Bloodlust) and plays a custom sound with a countdown icon.", Category = 4 },
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevTools.YYSound"
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local LSM = LibStub("LibSharedMedia-3.0")

-- 1. Default Settings
local MODULE_DEFAULTS = {
    borderColorA = 1,
    borderColorB = 0,
    borderColorG = 0,
    borderColorR = 0,
    borderPadding = 1,
    borderSize = 1,
    borderTexture = "1 Pixel",
    customSounds = { "", "", "", "", "", "" },
    customSound1 = "",
    customSound2 = "",
    customSound3 = "",
    customSound4 = "",
    customSound5 = "",
    customSound6 = "",
    enabled = false,
    font_timer = {
        a = 1,
        b = 0,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = true,
        shadowColor = { 0, 0, 0, 1 },
        shadowX = 1,
        shadowY = -1,
        size = 48,
        x = 0,
        y = 0,
    },
    hideIcon = false,
    iconSize = 59,
    iconTexture = "132313",
    posX = -390,
    posY = 14,
    randomSound = false,
    reverseCD = true,
    showBorder = true,
    sound = "None",
    soundChannel = "Master",
    spellID = "",
    unlockDrag = false,
    useCustomSound = false,
    useNativeCD = false,
}

-- Fixed values
local HASTE_THRESHOLD = 30 -- Haste percentage delta threshold
local CD_DURATION = 40     -- Countdown display duration

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

local function NormalizeCustomSounds()
    local sounds = {}

    if type(MODULE_DB.customSounds) == "table" then
        local maxIndex = math.max(#MODULE_DB.customSounds, 6)
        for i = 1, maxIndex do
            sounds[i] = tostring(MODULE_DB.customSounds[i] or "")
        end
    end

    for i = 1, 6 do
        local legacyValue = MODULE_DB["customSound" .. i]
        if type(legacyValue) == "string" and legacyValue ~= "" then
            sounds[i] = legacyValue
        end
        MODULE_DB["customSound" .. i] = nil
    end

    for i = 1, 6 do
        if sounds[i] == nil then
            sounds[i] = ""
        end
    end

    MODULE_DB.customSounds = sounds
end

local function GetCustomSoundCount()
    if type(MODULE_DB.customSounds) ~= "table" or #MODULE_DB.customSounds == 0 then
        return 1
    end
    return #MODULE_DB.customSounds
end

NormalizeCustomSounds()

-- =========================================================
-- [Core] Feature Component: Countdown Icon Frame
-- =========================================================
local DeathFrame = CreateFrame("Frame", "InfinityDeathSoundFrame", UIParent)
DeathFrame:SetSize(MODULE_DB.iconSize, MODULE_DB.iconSize)
DeathFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
DeathFrame:Hide()


DeathFrame.Bg = DeathFrame:CreateTexture(nil, "BACKGROUND")
DeathFrame.Bg:SetAllPoints()
DeathFrame.Bg:SetColorTexture(0, 0, 0, 0.5)


DeathFrame.Icon = DeathFrame:CreateTexture(nil, "ARTWORK")
DeathFrame.Icon:SetAllPoints()
DeathFrame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

DeathFrame.BorderFrame = CreateFrame("Frame", nil, DeathFrame, "BackdropTemplate")
DeathFrame.BorderFrame:SetFrameLevel(DeathFrame:GetFrameLevel() + 5)

DeathFrame.TimerText = DeathFrame:CreateFontString(nil, "OVERLAY")
local fontPath = InfinityTools.MAIN_FONT
DeathFrame.TimerText:SetFont(fontPath, 48, "OUTLINE")
DeathFrame.TimerText:SetPoint("CENTER", 0, 0)
DeathFrame.TimerText:SetTextColor(1, 1, 0)


DeathFrame.CD = CreateFrame("Cooldown", nil, DeathFrame, "CooldownFrameTemplate")
DeathFrame.CD:SetAllPoints()
DeathFrame.CD:SetDrawEdge(false)
DeathFrame.CD:SetHideCountdownNumbers(true)

local function UpdateVisuals()
    DeathFrame:SetSize(MODULE_DB.iconSize, MODULE_DB.iconSize)
    DeathFrame:ClearAllPoints()
    DeathFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
    local icon = MODULE_DB.iconTexture or 132313
    -- [New] Spell ID priority logic
    if MODULE_DB.spellID and MODULE_DB.spellID ~= "" then
        local spellIcon = C_Spell.GetSpellTexture(MODULE_DB.spellID)
        if spellIcon then
            icon = spellIcon
        end
    end
    DeathFrame.Icon:SetTexture(icon)

    local edgeTexture
    if MODULE_DB.showBorder and MODULE_DB.borderTexture and MODULE_DB.borderTexture ~= "None" then
        edgeTexture = LSM:Fetch("border", MODULE_DB.borderTexture)
    end

    if edgeTexture then
        local padding = MODULE_DB.borderPadding or 0
        DeathFrame.BorderFrame:ClearAllPoints()
        DeathFrame.BorderFrame:SetPoint("TOPLEFT", DeathFrame, "TOPLEFT", -padding, padding)
        DeathFrame.BorderFrame:SetPoint("BOTTOMRIGHT", DeathFrame, "BOTTOMRIGHT", padding, -padding)
        DeathFrame.BorderFrame:SetBackdrop({
            edgeFile = edgeTexture,
            edgeSize = MODULE_DB.borderSize or 1,
        })
        DeathFrame.BorderFrame:SetBackdropBorderColor(
            MODULE_DB.borderColorR or 0,
            MODULE_DB.borderColorG or 0,
            MODULE_DB.borderColorB or 0,
            MODULE_DB.borderColorA or 1
        )
        DeathFrame.BorderFrame:Show()
    else
        DeathFrame.BorderFrame:Hide()
    end

    if InfinityTools.DB_Static and MODULE_DB.font_timer then
        InfinityTools.DB_Static:ApplyFont(DeathFrame.TimerText, MODULE_DB.font_timer)
    end
    DeathFrame.TimerText:ClearAllPoints()
    DeathFrame.TimerText:SetPoint(
        "CENTER",
        DeathFrame,
        "CENTER",
        (MODULE_DB.font_timer and MODULE_DB.font_timer.x) or 0,
        (MODULE_DB.font_timer and MODULE_DB.font_timer.y) or 0
    )

    -- Show or hide the Blizzard native countdown based on settings
    if DeathFrame.CD.SetHideCountdownNumbers then
        DeathFrame.CD:SetHideCountdownNumbers(not MODULE_DB.useNativeCD)
    end
    -- Show or hide the custom font based on settings
    if MODULE_DB.useNativeCD then
        DeathFrame.TimerText:Hide()
    else
        DeathFrame.TimerText:Show()
    end

    -- Reverse the countdown swipe (swap light/dark)
    if DeathFrame.CD.SetReverse then
        DeathFrame.CD:SetReverse(MODULE_DB.reverseCD)
    end
end

-- Unlock drag functionality
local function SetDragMode(enabled)
    if enabled then
        -- Show icon and enable dragging
        UpdateVisuals()
        DeathFrame:Show()
        DeathFrame:EnableMouse(true)
        DeathFrame:SetMovable(true)
        DeathFrame:RegisterForDrag("LeftButton")
        DeathFrame:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" and InfinityTools.GlobalEditMode then
                -- [v4.7.2 Fix] Add right-click settings routing for YY Sound
                InfinityTools:OpenConfig(INFINITY_MODULE_KEY)
            end
        end)
        DeathFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        DeathFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Calculate the frame center offset relative to the screen center
            local frameCenter = self:GetCenter()
            local screenCenter = UIParent:GetCenter()
            if frameCenter and screenCenter then
                MODULE_DB.posX = math.floor(frameCenter - screenCenter + 0.5)
                local _, frameCenterY = self:GetCenter()
                local _, screenCenterY = UIParent:GetCenter()
                MODULE_DB.posY = math.floor(frameCenterY - screenCenterY + 0.5)
            end
            -- Re-anchor to CENTER for consistency
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
            -- Trigger UI refresh to sync slider values
            InfinityTools:UpdateState(INFINITY_MODULE_KEY .. ".DatabaseChanged", { key = "posX", ts = GetTime() })
            if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() then
                InfinityTools.UI:RefreshContent()
            end
        end)
        -- Show a hint label
        if not DeathFrame.DragHint then
            DeathFrame.DragHint = DeathFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            DeathFrame.DragHint:SetPoint("TOP", DeathFrame, "BOTTOM", 0, -5)
        end
        DeathFrame.DragHint:SetText("|cff00ff00" .. L["Drag to reposition"] .. "|r\n|cffaaaaaa" .. L["Right-click to open settings"] .. "|r")
        DeathFrame.DragHint:Show()
    else
        -- Hide icon and disable dragging
        DeathFrame:Hide()
        DeathFrame:EnableMouse(false)
        DeathFrame:SetMovable(false)
        DeathFrame:SetScript("OnMouseDown", nil)
        DeathFrame:SetScript("OnDragStart", nil)
        DeathFrame:SetScript("OnDragStop", nil)
        if DeathFrame.DragHint then DeathFrame.DragHint:Hide() end
    end
end

local activeTimer
local lastSoundHandle

local function StopEffect()
    if lastSoundHandle then
        StopSound(lastSoundHandle)
        lastSoundHandle = nil
    end
    if activeTimer then
        activeTimer:Cancel()
        activeTimer = nil
    end
    DeathFrame:Hide()
end

--  Debuff expiration timestamp for calibrating the countdown (can be nil; falls back to fixed duration)
local function PlayEffect(expirationTime)
    if not MODULE_DB.enabled then return end

    -- Stop the previous effect to prevent overlap
    StopEffect()

    -- 1. Play sound (source determined by settings)
    local soundToPlay = nil

    if MODULE_DB.useCustomSound then
        -- Use custom sound
        if MODULE_DB.randomSound then
            -- Random play: randomly select from all non-empty custom sounds
            local validSounds = {}
            for _, s in ipairs(MODULE_DB.customSounds or {}) do
                if s and s ~= "" then
                    table.insert(validSounds, s)
                end
            end
            if #validSounds > 0 then
                soundToPlay = validSounds[math.random(1, #validSounds)]
            end
        else
            -- Always use the first entry
            local s = MODULE_DB.customSounds and MODULE_DB.customSounds[1]
            if s and s ~= "" then
                soundToPlay = s
            end
        end
    else
        -- Use LSM sound
        if MODULE_DB.sound and MODULE_DB.sound ~= "None" then
            soundToPlay = LSM:Fetch("sound", MODULE_DB.sound)
        end
    end

    if soundToPlay then
        local _, handle = PlaySoundFile(soundToPlay, MODULE_DB.soundChannel or "Master")
        lastSoundHandle = handle
    end

    -- 2. Activate UI feedback (if hide icon is not checked)
    -- Calibrate countdown using debuff expiration time; fall back to fixed duration if unavailable
    local now = GetTime()
    local duration = (expirationTime and expirationTime > now)
        and (expirationTime - now)
        or CD_DURATION

    if not MODULE_DB.hideIcon then
        UpdateVisuals()
        DeathFrame:Show()

        -- Start the swipe animation (calibrated to actual remaining duration)
        DeathFrame.CD:SetCooldown(now, duration)
    end

    if MODULE_DB.useNativeCD then
        -- Use native mode
        if activeTimer then
            activeTimer:Cancel(); activeTimer = nil
        end
        -- [Fix] In native CD mode, CooldownFrame does not auto-hide the parent frame after the swipe ends;
        -- a delayed hide timer must be created manually and attached to activeTimer so StopEffect() can cancel it.
        activeTimer = C_Timer.After(duration, function()
            activeTimer = nil
            if not MODULE_DB.unlockDrag then
                DeathFrame:Hide()
            end
        end)
        return
    end

    -- Use custom mode
    if activeTimer then
        activeTimer:Cancel(); activeTimer = nil
    end

    local timeLeft = duration
    local lastDisplayNum = math.ceil(timeLeft)
    DeathFrame.TimerText:SetText(lastDisplayNum)

    activeTimer = C_Timer.NewTicker(0.1, function()
        timeLeft = timeLeft - 0.1
        if timeLeft <= 0 then
            DeathFrame:Hide()
            if activeTimer then activeTimer:Cancel() end
            activeTimer = nil
        else
            -- Only update text when the second value changes (no animation)
            local currentDisplayNum = math.ceil(timeLeft)
            if currentDisplayNum ~= lastDisplayNum then
                lastDisplayNum = currentDisplayNum
                DeathFrame.TimerText:SetText(currentDisplayNum)
            end
        end
    end)
end


-- =========================================================
-- [Core] Haste change monitoring (WatchesData logic)
-- =========================================================
local isReady = false
C_Timer.After(5, function() isReady = true end) -- Allow triggers only 5 seconds after login

-- =========================================================
-- [Aura] Debuff verification (these 8 IDs are not secret values after Blizzard hotfixes)
-- Confirms Bloodlust truly triggered by checking whether the debuff was "just applied"
-- =========================================================
local EXHAUSTION_IDS = { 57723, 57724, 80354, 95809, 160455, 207400, 264689, 390435, 1243972 }
local EXHAUSTION_DURATION = 600 -- Exhaustion debuff lasts 10 minutes
local FRESH_WINDOW = 5          -- Tolerance window of 5 seconds (network/frame delay buffer)

-- Check whether the player just received the Exhaustion debuff (remaining time close to full)
-- Returns true and expirationTime (used to calibrate the countdown)
local function CheckExhaustionFresh()
    local UnitAuras = _G.C_UnitAuras
    local now = _G.GetTime()
    for _, id in ipairs(EXHAUSTION_IDS) do
        local aura = UnitAuras.GetPlayerAuraBySpellID(id)
        if aura then
            local remaining = aura.expirationTime - now
            if remaining >= (EXHAUSTION_DURATION - FRESH_WINDOW) then
                return true, aura.expirationTime
            end
        end
    end
    return false, nil
end


local function RegisterHasteWatcher(threshold)
    InfinityTools:WatchStateDelta("PStat_Haste", INFINITY_MODULE_KEY, threshold or HASTE_THRESHOLD, function()
        if not isReady then return end

        -- Wait 0.5s before verifying: COMBAT_RATING_UPDATE may arrive before UNIT_AURA
        -- Wait for the debuff to stabilize before checking
        C_Timer.After(0.5, function()
            local fresh = CheckExhaustionFresh()
            if not fresh then return end
            PlayEffect()
        end)
    end)
end

-- Listen for equipment changes to recalibrate
InfinityTools:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", INFINITY_MODULE_KEY, function()
    C_Timer.After(1, function() RegisterHasteWatcher() end)
end)

RegisterHasteWatcher()


-- =========================================================
-- [Grid] Layout config (normalized static table)
-- =========================================================
local function REGISTER_LAYOUT()
    local soundCount = GetCustomSoundCount()
    local soundRowsStartY = 63
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 53, h = 3, label = L["Bloodlust Sound (YY Sound)"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 53, h = 2, label = L["Plays a sound and countdown when Bloodlust/Heroism is gained. Beta feature."] },
        { key = "sub1", type = "subheader", x = 2, y = 6, w = 53, h = 2, label = L["Icon Settings"], labelSize = 20 },
        { key = "enabled", type = "checkbox", x = 2, y = 10, w = 6, h = 2, label = L["Enable"] },  -- TODO: missing key: L["Enable"]
        { key = "hideIcon", type = "checkbox", x = 10, y = 10, w = 10, h = 2, label = L["Hide Icon"] },
        { key = "unlockDrag", type = "checkbox", x = 20, y = 10, w = 10, h = 2, label = L["Unlock Drag"] },
        { key = "useNativeCD", type = "checkbox", x = 32, y = 10, w = 18, h = 2, label = L["Use Blizzard Native Cooldown (lower CPU)"] },

        { key = "spellID", type = "input", x = 2, y = 14, w = 15, h = 2, label = L["Spell ID (Preferred)"], labelPos = "top" },
        { key = "iconTexture", type = "input", x = 19, y = 14, w = 23, h = 2, label = L["Icon Path/ID |cffff2628Spell ID takes priority if set|r"], labelPos = "top" },
        { key = "iconSize", type = "slider", x = 43, y = 14, w = 12, h = 2, label = L["Size"], min = 15, max = 300 },
        { key = "description_5432", type = "description", x = 19, y = 16, w = 24, h = 1, label = L["|cff97a393Example: Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV1.PNG|r"], labelSize = 12 },

        { key = "posX", type = "slider", x = 2, y = 19, w = 15, h = 2, label = L["Position X"], min = -800, max = 800 },
        { key = "posY", type = "slider", x = 19, y = 19, w = 15, h = 2, label = L["Position Y"], min = -500, max = 500 },
        { key = "reverseCD", type = "checkbox", x = 36, y = 19, w = 10, h = 2, label = L["Reverse CD"] },

        { key = "divider_2497", type = "divider", x = 2, y = 22, w = 53, h = 1, label = "" },
        { key = "showBorder", type = "checkbox", x = 2, y = 25, w = 15, h = 2, label = L["Show Border"] },
        { key = "borderTexture", type = "lsm_border", x = 19, y = 25, w = 17, h = 2, label = L["Border Texture"] },
        { key = "borderColor", type = "color", x = 37, y = 25, w = 18, h = 2, label = L["Border Color"] },
        { key = "borderSize", type = "slider", x = 19, y = 29, w = 17, h = 2, label = L["Border Size"], min = 1, max = 16, step = 1 },
        { key = "borderPadding", type = "slider", x = 37, y = 29, w = 18, h = 2, label = L["Border Padding"], min = 0, max = 16, step = 1 },
        { key = "font_timer", type = "fontgroup", x = 2, y = 33, w = 53, h = 17, label = L["Timer Text"], labelSize = 20 },

        { key = "divider_1504", type = "divider", x = 2, y = 51, w = 53, h = 1, label = "" },
        { key = "sub2", type = "subheader", x = 2, y = 52, w = 53, h = 2, label = L["Sound Settings"], labelSize = 20 },
        { key = "divider_2880", type = "divider", x = 2, y = 54, w = 53, h = 2, label = "" },
        { key = "sound", type = "lsm_sound", x = 9, y = 56, w = 25, h = 2, label = "|cff2bff6a" .. L["Built-in Sound"] .. "|r", labelPos = "left", labelSize = 20 },
        { key = "soundChannel", type = "dropdown", x = 40, y = 56, w = 12, h = 2, label = L["Output Channel"], items = { { L["Master"], "Master" }, { L["SFX"], "SFX" }, { L["Ambience"], "Ambience" }, { L["Music"], "Music" }, { L["Dialog"], "Dialog" } }, labelPos = "left" },

        { key = "useCustomSound", type = "checkbox", x = 3, y = 59, w = 2, h = 2, label = L["Use Custom Paths (add more below)"] },
        { key = "randomSound", type = "checkbox", x = 30, y = 59, w = 2, h = 2, label = L["Play Random Entry"] },
    }






    for i = 1, soundCount do
        layout[#layout + 1] = {
            key = "customSound_" .. i,
            type = "input",
            x = 10,
            y = soundRowsStartY + ((i - 1) * 2),
            w = 45,
            h = 2,
            label = string.format("%s (%d)", L["Sound"], i),
            labelPos = "left",
            parentKey = "customSounds",
            subKey = tostring(i),
        }
    end

    local addButtonY = soundRowsStartY + (soundCount * 2)
    layout[#layout + 1] = { key = "btn_add_sound", type = "button", x = 10, y = addButtonY, w = 14, h = 3, label = L["Add Sound"] }

    local testSectionY = addButtonY + 4
    layout[#layout + 1] = { key = "sub3", type = "subheader", x = 2, y = testSectionY, w = 53, h = 1, label = L["Test Actions"], labelSize = 20 }
    layout[#layout + 1] = { key = "divider_7795", type = "divider", x = 2, y = testSectionY + 1, w = 53, h = 1, label = "" }
    layout[#layout + 1] = { key = "btn_test", type = "button", x = 2, y = testSectionY + 2, w = 13, h = 3, label = L["Test Effect"] }
    layout[#layout + 1] = { key = "btn_stop", type = "button", x = 16, y = testSectionY + 2, w = 13, h = 3, label = L["Stop Test"] }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()
UpdateVisuals()

-- =========================================================
-- [Logic] Respond to Grid events
-- =========================================================

-- 1. Handle database changes (auto re-register Watcher)
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(data)
    if data and (data.key == "threshold") then
        RegisterHasteWatcher()
    end
    -- Unlock drag state changed
    if data and data.key == "unlockDrag" then
        SetDragMode(MODULE_DB.unlockDrag)
    end
    UpdateVisuals()
end)

-- 2. Handle button clicks
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if info and info.key == "btn_test" then
        PlayEffect()
    elseif info and info.key == "btn_stop" then
        StopEffect()
    elseif info and info.key == "btn_add_sound" then
        if type(MODULE_DB.customSounds) ~= "table" then
            MODULE_DB.customSounds = { "" }
        end
        MODULE_DB.customSounds[#MODULE_DB.customSounds + 1] = ""
        REGISTER_LAYOUT()
        if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() then
            if InfinityTools.UI.RefreshContentKeepModuleScroll then
                InfinityTools.UI:RefreshContentKeepModuleScroll()
            else
                InfinityTools.UI:RefreshContent()
            end
        end
    end
end)

-- =============================================================
-- Global Edit Mode Support
-- =============================================================
-- [v3.1 New] Register global edit mode callback
InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    if enabled then
        -- Enable edit mode: turn on drag unlock
        MODULE_DB.unlockDrag = true
        SetDragMode(true)
    else
        -- Disable edit mode: turn off drag unlock
        MODULE_DB.unlockDrag = false
        SetDragMode(false)
    end
end)

-- Register HUD (centralized management)
InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, DeathFrame)

-- Report module ready
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

