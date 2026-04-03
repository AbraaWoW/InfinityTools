-- =============================================================
-- [[ Focus Cast Monitor ]]
-- { Key = "RevClass.FocusCast", Name = "Focus Cast Alert", Desc = "Monitors focus target casts with cast bar display and alert sound support.", Category = 4 },
-- =============================================================

local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevClass.FocusCast"
local LSM = LibStub("LibSharedMedia-3.0")
local InfinityFactory = _G.InfinityFactory

local activeBar = nil
local previewBar = nil
local anchorFrame = nil
local isPreviewing = false
local TogglePreview

-- ------------------------------------------------------------
-- 1. Grid layout definition
-- ------------------------------------------------------------
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 53, h = 2, label = L["Focus Cast Alert"], labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 53, h = 2, label = L["Only monitors your focus target's casts, with separate toggles for cast bar and alert sound."] },
        { key = "div1", type = "divider", x = 1, y = 8, w = 53, h = 1, label = "--[[ Function ]]" },
        { key = "subheader_general", type = "subheader", x = 1, y = 7, w = 53, h = 1, label = L["General Settings"], labelSize = 20 },  -- TODO: missing key: L["General Settings"]
        { key = "enabled", type = "checkbox", x = 1, y = 9, w = 8, h = 2, label = L["Enable"] },  -- TODO: missing key: L["Enable"]
        { key = "showBar", type = "checkbox", x = 11, y = 9, w = 10, h = 2, label = L["Show Cast Bar"] },
        { key = "playSound", type = "checkbox", x = 1, y = 22, w = 10, h = 2, label = L["Play alert sound|cffff2007 (plays on all casts; cannot filter by interruptability)|r"] },
        { key = "muteSoundOnInterruptCD", type = "checkbox", x = 13, y = 22, w = 18, h = 2, label = L["Mute sound while interrupt is on cooldown"] },
        { key = "locked", type = "checkbox", x = 23, y = 9, w = 8, h = 2, label = L["Lock Position"] },
        { key = "preview", type = "checkbox", x = 34, y = 9, w = 8, h = 2, label = L["Preview"] },  -- TODO: missing key: L["Preview"]
        { key = "btn_reset_pos", type = "button", x = 36, y = 16, w = 16, h = 2, label = L["Reset Position"] },
        { key = "posX", type = "slider", x = 1, y = 16, w = 15, h = 2, label = L["Position X"], min = -1000, max = 1000 },
        { key = "posY", type = "slider", x = 19, y = 16, w = 15, h = 2, label = L["Position Y"], min = -1000, max = 1000 },
        { key = "subheader_sound", type = "subheader", x = 1, y = 19, w = 53, h = 1, label = L["Sound Settings"], labelSize = 20 },
        { key = "sound", type = "lsm_sound", x = 1, y = 26, w = 15, h = 2, label = L["Select Sound"], labelPos = "top" },
        { key = "soundChannel", type = "dropdown", x = 19, y = 26, w = 14, h = 2, label = L["Output Channel"], items = { { L["Master"], "Master" }, { L["SFX"], "SFX" }, { L["Ambience"], "Ambience" }, { L["Music"], "Music" }, { L["Dialog"], "Dialog" } }, labelPos = "top" },
        { key = "btn_test_sound", type = "button", x = 36, y = 26, w = 16, h = 2, label = L["Test Sound"] },
        { key = "subheader_bar", type = "subheader", x = 1, y = 36, w = 53, h = 2, label = L["Cast Bar Settings"], labelSize = 20 },
        { key = "showInterruptMarkerLine", type = "checkbox", x = 1, y = 39, w = 20, h = 2, label = L["Show interrupt-ready marker line"] },
        { key = "interruptMarkerColor", type = "color", x = 23, y = 39, w = 12, h = 2, label = L["Marker Color"], labelPos = "top" },
        { key = "interruptMarkerWidth", type = "slider", x = 37, y = 39, w = 16, h = 2, label = L["Marker Width"], min = 1, max = 8 },
        { key = "hideOnInterruptCD", type = "checkbox", x = 1, y = 41, w = 15, h = 2, label = L["Hide interruptible bars while interrupt is on cooldown"] },
        { key = "showInterruptCDThreshold", type = "slider", x = 32, y = 41, w = 23, h = 2, label = L["Show when interrupt cooldown is below this many seconds (left color)"], min = 0, max = 10 },
        { key = "nonInterruptColor", type = "color", x = 1, y = 45, w = 15, h = 2, label = L["Uninterruptible Color"], labelPos = "top" },
        { key = "interruptCDColor", type = "color", x = 19, y = 41, w = 12, h = 2, label = L["Interrupt CD Color"], labelPos = "top" },
        { key = "textAlign", type = "dropdown", x = 8, y = 78, w = 15, h = 2, label = L["Spell Alignment"], items = "LEFT,CENTER,RIGHT", labelPos = "left", labelSize = 18 },
        { key = "showTarget", type = "checkbox", x = 1, y = 103, w = 8, h = 2, label = L["Show Target"], labelSize = 18 },
        { key = "targetAlign", type = "dropdown", x = 21, y = 103, w = 15, h = 2, label = L["Target Alignment"], items = "LEFT,CENTER,RIGHT", labelPos = "left", labelSize = 18 },
        { key = "showTimer", type = "checkbox", x = 1, y = 128, w = 10, h = 2, label = L["Show Time"], labelSize = 18 },
        { key = "timerAlign", type = "dropdown", x = 21, y = 128, w = 15, h = 2, label = L["Time Alignment"], items = "LEFT,CENTER,RIGHT", labelPos = "left", labelSize = 18 },
        { key = "hideWhenNotInterruptible", type = "checkbox", x = 1, y = 12, w = 19, h = 2, label = L["|cffff080aHide non-interruptible bars|r"], labelSize = 18 },
        { key = "timerGroup", type = "timerBarGroup", x = 1, y = 47, w = 53, h = 27, label = L["Bar Appearance"], labelSize = 20 },
        { key = "font_spell_header", type = "header", x = 1, y = 75, w = 53, h = 2, label = L["Spell Text"], labelSize = 20 },
        { key = "font_spell", type = "fontgroup", x = 1, y = 81, w = 53, h = 17, label = L["Spell Name"], labelSize = 20 },
        { key = "font_target_header", type = "header", x = 1, y = 100, w = 53, h = 2, label = L["Target Text"], labelSize = 20 },
        { key = "font_target", type = "fontgroup", x = 1, y = 106, w = 53, h = 17, label = L["Cast Target"], labelSize = 20 },
        { key = "font_timer_header", type = "header", x = 1, y = 125, w = 53, h = 2, label = L["Time Text Settings"], labelSize = 20 },
        { key = "font_timer", type = "fontgroup", x = 1, y = 131, w = 53, h = 17, label = L["Remaining Time"], labelSize = 20 },
        { key = "divider_7144", type = "divider", x = 1, y = 20, w = 53, h = 1, label = L["Components"] },
        { key = "divider_5422", type = "divider", x = 1, y = 38, w = 53, h = 1, label = L["Components"] },
        { key = "customSoundPath", type = "input", x = 1, y = 31, w = 53, h = 2, label = L["Use custom file path (leave blank to use the selected sound above)"] },
        { key = "description_5178", type = "description", x = 1, y = 33, w = 53, h = 2, label = L["|cffafafafPath example: Interface\\AddOns\\Infinity\\sound\\Interrupt.mp3|r"], labelSize = 14 },
        { key = "description_6169", type = "description", x = 24, y = 43, w = 31, h = 2, label = L["Example: when interrupt cooldown reaches 2s, the bar uses the left color and changes when interrupt becomes ready."], labelSize = 14 },
    }






    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local MODULE_DEFAULTS = {
    enabled = false,
    font_spell = {
        a = 1,
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = false,
        shadowX = 1,
        shadowY = -1,
        size = 24,
        x = 4,
        y = 0,
    },
    font_target = {
        a = 1,
        b = 0.40392160415649,
        font = "Default",
        g = 0.80000007152557,
        outline = "OUTLINE",
        r = 0.27058824896812,
        shadow = false,
        shadowX = 1,
        shadowY = -1,
        size = 20,
        x = 48,
        y = 0,
    },
    font_timer = {
        a = 1,
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = false,
        shadowX = 1,
        shadowY = -1,
        size = 24,
        x = 0,
        y = 0,
    },
    hideOnInterruptCD = false,
    showInterruptCDThreshold = 2,
    hideWhenNotInterruptible = true,
    locked = false,
    nonInterruptColorA = 1,
    nonInterruptColorB = 0.16862745583057,
    nonInterruptColorG = 0.1294117718935,
    nonInterruptColorR = 1,
    interruptCDColorA = 0.6,
    interruptCDColorB = 0.5,
    interruptCDColorG = 0.5,
    interruptCDColorR = 0.5,
    interruptMarkerColorA = 1,
    interruptMarkerColorB = 0.25,
    interruptMarkerColorG = 0.95,
    interruptMarkerColorR = 1,
    interruptMarkerWidth = 2,
    showInterruptMarkerLine = true,
    muteSoundOnInterruptCD = true,
    playSound = false,
    posX = 23,
    posY = 272,
    preview = true,
    showBar = true,
    showTarget = true,
    showTimer = true,
    sound = "None",
    soundChannel = "Master",
    customSoundPath = "",
    targetAlign = "CENTER",
    textAlign = "LEFT",
    timerAlign = "RIGHT",
    timerGroup = {
        barBgColor = {
            a = 0.5,
            b = 0,
            g = 0,
            r = 0,
        },
        barBgColorA = 0.5,
        barBgColorB = 0,
        barBgColorG = 0,
        barBgColorR = 0,
        barColor = {
            a = 1,
            b = 1,
            g = 0.90980398654938,
            r = 0.29019609093666,
        },
        barColorA = 1,
        barColorB = 1,
        barColorG = 0.90980398654938,
        barColorR = 0.29019609093666,
        height = 50,
        iconOffsetX = -1,
        iconOffsetY = 0,
        iconSide = "LEFT",
        iconSize = 50,
        showIcon = true,
        texture = "Melli",
        width = 350,
    },
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)
if MODULE_DB.customSoundPath == nil and type(MODULE_DB.input_1127) == "string" then
    MODULE_DB.customSoundPath = MODULE_DB.input_1127
end

local function GetColor(dbKey)
    local r, g, b, a = MODULE_DB[dbKey .. "R"], MODULE_DB[dbKey .. "G"], MODULE_DB[dbKey .. "B"], MODULE_DB[dbKey .. "A"]
    if r == nil and MODULE_DB[dbKey] and type(MODULE_DB[dbKey]) == "table" then
        return MODULE_DB[dbKey].r, MODULE_DB[dbKey].g, MODULE_DB[dbKey].b, MODULE_DB[dbKey].a
    end
    return r or 1, g or 1, b or 1, a or 1
end

local function GetInterruptDynamicState()
    if _G.InfinityTools.State.InterruptReady then return "READY" end
    local remaining = 0
    local startTime = _G.InfinityTools.State.InterruptStartTime or 0
    local duration = _G.InfinityTools.State.InterruptDuration or 0
    if duration > 0 then remaining = (startTime + duration) - GetTime() end
    if remaining <= 0 then return "READY" end

    local threshold = MODULE_DB.showInterruptCDThreshold or 0
    if remaining <= threshold then
        return "ALMOST_READY"
    end

    if MODULE_DB.hideOnInterruptCD then
        return "HIDDEN"
    else
        return "ON_CD"
    end
end

local function ApplyDynamicInterrupt(bar, state)
    if not bar then return end
    if state == "HIDDEN" then
        bar:SetAlpha(0)
    else
        bar:SetAlpha(1)
        local sbTex = bar:GetStatusBarTexture()
        if sbTex and bar._isNotInt ~= nil then
            local nrR, nrG, nrB, nrA = GetColor("nonInterruptColor")
            local intColor = CreateColor(nrR, nrG, nrB, nrA)
            local normColor
            if state == "READY" then
                local group = MODULE_DB.timerGroup or {}
                normColor = CreateColor(group.barColorR or 1, group.barColorG or 0.7, group.barColorB or 0,
                    group.barColorA or 1)
            else
                local cdR, cdG, cdB, cdA = GetColor("interruptCDColor")
                normColor = CreateColor(cdR, cdG, cdB, cdA)
            end
            sbTex:SetVertexColorFromBoolean(bar._isNotInt, intColor, normColor)
        end
    end
    bar._lastIntState = state
end

local function PlayConfiguredSound(forcePlay)
    if not forcePlay and not MODULE_DB.playSound then return end
    local soundChannel = MODULE_DB.soundChannel or "Master"
    local customPath = MODULE_DB.customSoundPath
    if type(customPath) == "string" then
        customPath = customPath:gsub("^%s+", ""):gsub("%s+$", "")
        if customPath ~= "" then
            PlaySoundFile(customPath, soundChannel)
            return
        end
    end

    if not LSM then return end
    if not MODULE_DB.sound or MODULE_DB.sound == "None" then return end

    local soundFile = LSM:Fetch("sound", MODULE_DB.sound)
    if soundFile then
        PlaySoundFile(soundFile, soundChannel)
    end
end

local function InitCastBarStructure(bar)
    bar:SetClampedToScreen(true)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bar.bg = bg

    bar.Text = bar:CreateFontString(nil, "OVERLAY")
    bar.TargetNameText = bar:CreateFontString(nil, "OVERLAY")
    bar.TimerText = bar:CreateFontString(nil, "OVERLAY")
    bar.Icon = bar:CreateTexture(nil, "OVERLAY")

    bar.InterruptMarkerBar = CreateFrame("StatusBar", nil, bar)
    bar.InterruptMarkerBar:SetAllPoints(true)
    bar.InterruptMarkerBar:SetClipsChildren(true)
    bar.InterruptMarkerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar.InterruptMarkerBar:GetStatusBarTexture():SetAlpha(0)
    bar.InterruptMarkerBar:SetAlpha(0)

    bar.InterruptMarkerLine = bar.InterruptMarkerBar:CreateTexture(nil, "OVERLAY")
    bar.InterruptMarkerLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    bar.InterruptMarkerLine:SetWidth(2)
    bar.InterruptMarkerLine:Hide()
end

if InfinityFactory then
    InfinityFactory:InitPool("RevFocusCastBar", "StatusBar", "BackdropTemplate", InitCastBarStructure)
end

local function AcquireBar()
    if not InfinityFactory then return nil end
    local bar = InfinityFactory:Acquire("RevFocusCastBar", anchorFrame)
    bar._isPreview = nil
    bar._isNotInt = nil
    bar._interruptMarkerReady = nil
    bar:SetAlpha(1)
    return bar
end

local function ReleaseBar(bar)
    if not InfinityFactory or not bar then return end
    bar:SetScript("OnUpdate", nil)
    if bar.InterruptMarkerBar then
        bar.InterruptMarkerBar:SetAlpha(0)
    end
    if bar.InterruptMarkerLine then
        bar.InterruptMarkerLine:Hide()
    end
    bar:SetAlpha(1)
    InfinityFactory:Release("RevFocusCastBar", bar)
end

local function GetFocusCastInfo()
    if not UnitExists("focus") then return nil end

    local objCast = UnitCastingDuration("focus")
    local objChannel = UnitChannelDuration("focus")
    local activeObj = objCast or objChannel
    local isChanneling = (objChannel ~= nil)
    if not activeObj then return nil end

    local name, texture, notInterruptible, startTimeMS, endTimeMS, spellID
    if isChanneling then
        name, _, texture, startTimeMS, endTimeMS, _, notInterruptible, spellID = UnitChannelInfo("focus")
    else
        name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID = UnitCastingInfo("focus")
    end
    if not name then return nil end
    if notInterruptible == nil then notInterruptible = false end

    local targetName = UnitSpellTargetName("focus")
    local finalTargetName = nil
    if targetName then
        local un = (UnitName(targetName))
        if un then
            finalTargetName = un
        else
            finalTargetName = targetName
        end
    end

    local shouldDisplayTarget = nil
    if UnitShouldDisplaySpellTargetName then
        shouldDisplayTarget = UnitShouldDisplaySpellTargetName("focus")
    end

    return {
        name = name,
        texture = texture,
        activeObj = activeObj,
        isChanneling = isChanneling,
        notInterruptible = notInterruptible,
        targetName = finalTargetName,
        targetClass = UnitSpellTargetClass("focus"),
        shouldDisplayTarget = shouldDisplayTarget,
    }
end

local function GetInterruptCooldownObject()
    local state = InfinityTools.State or {}
    local specID = state.SpecID or 0

    if specID == 0 then
        local specIndex = GetSpecialization and GetSpecialization()
        if specIndex and GetSpecializationInfo then
            specID = GetSpecializationInfo(specIndex) or 0
        end
    end

    local interruptData = InfinityDB and InfinityDB.InterruptData and InfinityDB.InterruptData[specID]
    local interruptSpellID = interruptData and interruptData.id
    if not interruptSpellID or interruptSpellID == 0 then
        return nil
    end

    if not C_Spell or not C_Spell.GetSpellCooldownDuration then
        return nil
    end

    return C_Spell.GetSpellCooldownDuration(interruptSpellID)
end

local function HideInterruptMarker(bar)
    if not bar then
        return
    end
    if bar.InterruptMarkerBar then
        bar.InterruptMarkerBar:SetAlpha(0)
    end
    if bar.InterruptMarkerLine then
        bar.InterruptMarkerLine:Hide()
    end
end

local function UpdateInterruptMarker(bar, castInfo)
    if not bar or not bar.InterruptMarkerBar or not bar.InterruptMarkerLine then
        return
    end

    if not MODULE_DB.showInterruptMarkerLine or not castInfo or not castInfo.activeObj then
        HideInterruptMarker(bar)
        return
    end

    local cooldownObject = GetInterruptCooldownObject()
    if not cooldownObject then
        HideInterruptMarker(bar)
        return
    end

    local markerBar = bar.InterruptMarkerBar
    local markerLine = bar.InterruptMarkerLine
    local castDuration = castInfo.activeObj:GetTotalDuration()
    local markerR, markerG, markerB, markerA = GetColor("interruptMarkerColor")

    markerBar:SetFrameLevel(bar:GetFrameLevel() + 3)
    markerBar:SetFillStyle(castInfo.isChanneling and Enum.StatusBarFillStyle.Reverse or Enum.StatusBarFillStyle.Standard)
    markerBar:SetMinMaxValues(0, castDuration)
    markerBar:SetValue(cooldownObject:GetRemainingDuration())
    markerBar:SetAlpha(1)

    markerLine:SetWidth(MODULE_DB.interruptMarkerWidth or 2)
    markerLine:SetHeight(bar:GetHeight())
    markerLine:SetVertexColor(markerR, markerG, markerB, markerA or 1)
    markerLine:ClearAllPoints()
    if castInfo.isChanneling then
        markerLine:SetPoint("RIGHT", markerBar:GetStatusBarTexture(), "LEFT")
    else
        markerLine:SetPoint("LEFT", markerBar:GetStatusBarTexture(), "RIGHT")
    end

    if markerBar.SetAlphaFromBoolean then
        markerBar:SetAlphaFromBoolean(castInfo.notInterruptible, 0, 1)
        markerBar:SetAlphaFromBoolean(cooldownObject:IsZero(), 0, markerBar:GetAlpha())
    end
    if markerLine.SetAlphaFromBoolean then
        markerLine:SetAlphaFromBoolean(castInfo.notInterruptible, 0, 1)
        markerLine:SetAlphaFromBoolean(cooldownObject:IsZero(), 0, markerLine:GetAlpha())
    end

    markerLine:Show()
end

local function RefreshInterruptMarkerVisibility(bar, castInfo)
    if not bar or not bar.InterruptMarkerBar or not bar.InterruptMarkerLine then
        return
    end
    if not castInfo then
        HideInterruptMarker(bar)
        return
    end
    if bar.InterruptMarkerBar.SetAlphaFromBoolean then
        bar.InterruptMarkerBar:SetAlphaFromBoolean(castInfo.notInterruptible, 0, bar.InterruptMarkerBar:GetAlpha())
    end
    if bar.InterruptMarkerLine.SetAlphaFromBoolean then
        bar.InterruptMarkerLine:SetAlphaFromBoolean(castInfo.notInterruptible, 0, bar.InterruptMarkerLine:GetAlpha())
    end
end

local function UpdateBarVisuals(bar)
    if not bar then return end

    local db = MODULE_DB
    local group = db.timerGroup or {}
    local StaticDB = InfinityTools.DB_Static

    bar:SetSize(group.width or 220, group.height or 20)
    local texName = group.texture or "Melli"
    local tex = LSM and LSM:Fetch("statusbar", texName)
    if not tex then tex = "Interface\\Buttons\\WHITE8X8" end

    if tex then
        if bar.bg then
            bar.bg:SetTexture(tex)
            bar.bg:SetVertexColor(
                group.barBgColorR or 0,
                group.barBgColorG or 0,
                group.barBgColorB or 0,
                group.barBgColorA or 0.5
            )
        end
        bar:SetStatusBarTexture(tex)
    end

    -- [Feature] Apply border styling (ensure the border renders in front of the status bar)
    local edgeTex = group.showBorder and group.borderTexture and group.borderTexture ~= "None" and
        LSM:Fetch("border", group.borderTexture) or nil
    if edgeTex then
        if not bar.BorderFrame then
            bar.BorderFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            bar.BorderFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
        end
        local edgeSize = group.borderSize or 12
        local pad = group.borderPadding or 0
        bar.BorderFrame:ClearAllPoints()
        bar.BorderFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", -pad, pad)
        bar.BorderFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", pad, -pad)
        bar.BorderFrame:SetBackdrop({
            edgeFile = edgeTex,
            edgeSize = edgeSize,
        })
        local br, bg, bb, ba = group.borderColorR or 1, group.borderColorG or 1, group.borderColorB or 1,
            group.borderColorA or 1
        bar.BorderFrame:SetBackdropBorderColor(br, bg, bb, ba)
        bar.BorderFrame:Show()
    else
        if bar.BorderFrame then
            bar.BorderFrame:Hide()
        end
    end

    if bar.Text then
        StaticDB:ApplyFont(bar.Text, db.font_spell)
        bar.Text:ClearAllPoints()
        bar.Text:SetPoint(db.textAlign, bar, db.textAlign, db.font_spell.x, db.font_spell.y)
        bar.Text:SetJustifyH(db.textAlign)
    end

    if bar.TargetNameText then
        StaticDB:ApplyFont(bar.TargetNameText, db.font_target)
        bar.TargetNameText:ClearAllPoints()
        bar.TargetNameText:SetPoint(db.targetAlign, bar, db.targetAlign, db.font_target.x, db.font_target.y)
        bar.TargetNameText:SetJustifyH(db.targetAlign)
        bar.TargetNameText:SetShown(db.showTarget)
    end

    if bar.TimerText then
        StaticDB:ApplyFont(bar.TimerText, db.font_timer)
        bar.TimerText:ClearAllPoints()
        bar.TimerText:SetPoint(db.timerAlign, bar, db.timerAlign, db.font_timer.x, db.font_timer.y)
        bar.TimerText:SetJustifyH(db.timerAlign)
        bar.TimerText:SetShown(db.showTimer or bar._isPreview)
    end

    if bar.Icon then
        bar.Icon:SetSize(group.iconSize or 20, group.iconSize or 20)
        bar.Icon:ClearAllPoints()
        local side = group.iconSide or "LEFT"
        if side == "LEFT" then
            bar.Icon:SetPoint("RIGHT", bar, "LEFT", group.iconOffsetX or 0, group.iconOffsetY or 0)
        else
            bar.Icon:SetPoint("LEFT", bar, "RIGHT", group.iconOffsetX or 0, group.iconOffsetY or 0)
        end
        bar.Icon:SetShown(group.showIcon)
        bar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    if bar.InterruptMarkerBar then
        bar.InterruptMarkerBar:SetFrameLevel(bar:GetFrameLevel() + 3)
    end

    -- 3. Enhancement: dynamic color and alpha blending
    -- Core fix: in 12.0 _isNotInt may be a secret value; never use `== true`, `== false`, or `not` for branching in Lua.
    -- We only generate the colors, then pass the raw _isNotInt back to the engine's SetVertexColorFromBoolean
    if bar._isNotInt ~= nil then
        local state = GetInterruptDynamicState()
        ApplyDynamicInterrupt(bar, state)
        -- Use a safe C function to handle alpha-hide logic (hideWhenNotInterruptible)
        if MODULE_DB.hideWhenNotInterruptible and bar.SetAlphaFromBoolean then
            -- If not interruptible (_isNotInt == true), set fully transparent (0)
            -- If interruptible (_isNotInt == false), keep the alpha set in the previous step (ApplyDynamicInterrupt), normally 1
            bar:SetAlphaFromBoolean(bar._isNotInt, 0, bar:GetAlpha())
        end
    else
        bar:SetAlpha(1)
    end
end

local function ReLayout()
    if not anchorFrame then return end
    local group = MODULE_DB.timerGroup or {}
    local width = group.width or 220
    local height = group.height or 20

    anchorFrame:SetSize(width, height)
    if anchorFrame.bg then
        anchorFrame.bg:SetSize(width, height)
        anchorFrame.bg:ClearAllPoints()
        anchorFrame.bg:SetPoint("CENTER", anchorFrame, "CENTER")
    end
    if anchorFrame.label then
        anchorFrame.label:ClearAllPoints()
        anchorFrame.label:SetPoint("CENTER", anchorFrame, "CENTER")
    end

    local bar = isPreviewing and previewBar or activeBar
    if bar then
        bar:ClearAllPoints()
        bar:SetPoint("CENTER", anchorFrame, "CENTER")
    end
end

local function RefreshAnchorState()
    if not anchorFrame then return end

    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX or 0, MODULE_DB.posY or 0)

    local shouldShowHandle = isPreviewing or (not MODULE_DB.locked)
    anchorFrame:EnableMouse(shouldShowHandle)
    if anchorFrame.bg then anchorFrame.bg:SetShown(shouldShowHandle) end
    if anchorFrame.label then anchorFrame.label:SetShown(shouldShowHandle) end
end

local function CreateAnchor()
    if anchorFrame then return end

    anchorFrame = CreateFrame("Frame", "RevFocusCastAnchor", UIParent)
    anchorFrame:SetSize(220, 20)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(true)

    anchorFrame.bg = anchorFrame:CreateTexture(nil, "BACKGROUND")
    anchorFrame.bg:SetColorTexture(0, 1, 0, 0.45)
    anchorFrame.bg:Hide()

    anchorFrame.label = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFrame.label:SetText(L["Focus Cast Alert"])
    anchorFrame.label:Hide()

    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, anchorFrame)

    anchorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and (isPreviewing or not MODULE_DB.locked) then
            self.isMoving = true
            self:StartMoving()
        elseif button == "RightButton" and InfinityTools.GlobalEditMode then
            InfinityTools:OpenConfig(INFINITY_MODULE_KEY)
        end
    end)

    anchorFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self.isMoving = false
            self:StopMovingOrSizing()
            local cx, cy = UIParent:GetCenter()
            local sx, sy = self:GetCenter()
            if sx and cx then
                local scale = self:GetScale()
                MODULE_DB.posX = math.floor(sx * scale - cx)
                MODULE_DB.posY = math.floor(sy * scale - cy)
                if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() then
                    InfinityTools.UI:RefreshContent()
                end
            end
        end
    end)
end

local function EnsureActiveBar()
    if activeBar then return activeBar end
    activeBar = AcquireBar()
    return activeBar
end

local function ClearActiveBar()
    if not activeBar then return end
    ReleaseBar(activeBar)
    activeBar = nil
end

local function ApplyFocusCastToBar(bar, castInfo)
    if not bar or not castInfo then return end

    bar._isPreview = nil
    bar._isNotInt = castInfo.notInterruptible
    UpdateBarVisuals(bar)

    bar.Text:SetText(castInfo.name or "")
    bar.Icon:SetTexture(castInfo.texture)

    if MODULE_DB.showTarget then
        bar.TargetNameText:SetText(castInfo.targetName or "")
        local tc = castInfo.targetClass
        local c = nil
        if tc then
            c = C_ClassColor.GetClassColor(tc)
        end
        if c then
            bar.TargetNameText:SetTextColor(c.r, c.g, c.b, 1)
        else
            bar.TargetNameText:SetTextColor(1, 1, 1, 1)
        end
        if castInfo.shouldDisplayTarget ~= nil then
            bar.TargetNameText:SetShown(castInfo.shouldDisplayTarget)
        else
            bar.TargetNameText:SetShown(castInfo.targetName ~= nil)
        end
    else
        bar.TargetNameText:SetText("")
        bar.TargetNameText:Hide()
    end

    if bar.SetTimerDuration then
        bar:SetTimerDuration(castInfo.activeObj, Enum.StatusBarInterpolation.None, (castInfo.isChanneling and 1 or 0))
    end

    if not bar._interruptMarkerReady then
        UpdateInterruptMarker(bar, castInfo)
        bar._interruptMarkerReady = true
    else
        RefreshInterruptMarkerVisibility(bar, castInfo)
    end

    local needsUpdateTimer = MODULE_DB.showTimer and not bar._isPreview
    local needsDynamicVisual = not bar._isPreview

    if needsUpdateTimer or needsDynamicVisual then
        bar:SetScript("OnUpdate", function(self)
            if needsUpdateTimer then
                local dur = self:GetTimerDuration()
                if dur then
                    local remaining = dur:GetRemainingDuration()
                    self.TimerText:SetText(string.format("%.1f", remaining))
                else
                    self.TimerText:SetText("")
                end
            end
            if needsDynamicVisual then
                local state = GetInterruptDynamicState()
                if self._lastIntState ~= state then
                    ApplyDynamicInterrupt(self, state)
                    -- Sync-refresh alpha that may have been overridden
                    if MODULE_DB.hideWhenNotInterruptible and self.SetAlphaFromBoolean and self._isNotInt ~= nil then
                        self:SetAlphaFromBoolean(self._isNotInt, 0, self:GetAlpha())
                    end
                end
            end
        end)
        if MODULE_DB.showTimer then bar.TimerText:Show() end
    else
        if bar.TimerText then bar.TimerText:SetText("") end
        bar:SetScript("OnUpdate", nil)
    end
end

local function UpdateFocusCast()
    if isPreviewing then return end
    if not MODULE_DB.enabled then
        ClearActiveBar()
        if anchorFrame then anchorFrame:Hide() end
        return
    end

    CreateAnchor()
    if anchorFrame then anchorFrame:Show() end

    local castInfo = GetFocusCastInfo()
    if not castInfo then
        ClearActiveBar()
        ReLayout()
        return
    end

    if MODULE_DB.showBar then
        local bar = EnsureActiveBar()
        if bar then
            ApplyFocusCastToBar(bar, castInfo)
            bar:Show()
        end
    else
        ClearActiveBar()
    end

    ReLayout()
end

local function TryPlayFocusSound()
    if not MODULE_DB.enabled or not MODULE_DB.playSound then return end
    if MODULE_DB.muteSoundOnInterruptCD and GetInterruptDynamicState() ~= "READY" then
        return
    end
    PlayConfiguredSound(false)
end

local function RefreshAll()
    if not MODULE_DB.enabled then
        if anchorFrame then anchorFrame:Hide() end
        return
    end

    CreateAnchor()
    if anchorFrame then anchorFrame:Show() end

    if activeBar then
        UpdateBarVisuals(activeBar)
    end
    if previewBar then
        UpdateBarVisuals(previewBar)
    end

    RefreshAnchorState()
    ReLayout()
end

function TogglePreview(enable)
    isPreviewing = enable
    CreateAnchor()
    if not anchorFrame then return end

    if enable then
        if activeBar then activeBar:Hide() end
        if previewBar then
            ReleaseBar(previewBar)
            previewBar = nil
        end

        if MODULE_DB.showBar then
            previewBar = AcquireBar()
            if previewBar then
                previewBar._isPreview = true
                -- Preview mode focus cast bar: fixed as “interruptible” during demo, responds to its own interrupt CD
                previewBar._isNotInt = false
                UpdateBarVisuals(previewBar)

    previewBar.Text:SetText(L["Focus Test Cast"])
                previewBar.Icon:SetTexture(136197)
                previewBar:SetMinMaxValues(0, 1)
                previewBar:SetValue(0.55)

                if previewBar.InterruptMarkerBar and previewBar.InterruptMarkerLine then
                    previewBar.InterruptMarkerBar:SetFrameLevel(previewBar:GetFrameLevel() + 3)
                    previewBar.InterruptMarkerBar:SetFillStyle(Enum.StatusBarFillStyle.Standard)
                    previewBar.InterruptMarkerBar:SetMinMaxValues(0, 4)
                    previewBar.InterruptMarkerBar:SetValue(3)

                    local markerR, markerG, markerB, markerA = GetColor("interruptMarkerColor")
                    previewBar.InterruptMarkerLine:SetVertexColor(markerR, markerG, markerB, markerA or 1)
                    previewBar.InterruptMarkerLine:SetWidth(MODULE_DB.interruptMarkerWidth or 2)
                    previewBar.InterruptMarkerLine:SetHeight(previewBar:GetHeight())
                    previewBar.InterruptMarkerLine:ClearAllPoints()
                    previewBar.InterruptMarkerLine:SetPoint("LEFT", previewBar.InterruptMarkerBar:GetStatusBarTexture(), "RIGHT")

                    if MODULE_DB.showInterruptMarkerLine then
                        previewBar.InterruptMarkerBar:SetAlpha(1)
                        previewBar.InterruptMarkerLine:Show()
                    else
                        previewBar.InterruptMarkerBar:SetAlpha(0)
                        previewBar.InterruptMarkerLine:Hide()
                    end
                end

                if previewBar.TargetNameText then
    previewBar.TargetNameText:SetText((UnitName("player")) or L["Player"])
                    local _, class = UnitClass("player")
                    local colorObj = C_ClassColor.GetClassColor(class or "")
                    if colorObj then
                        previewBar.TargetNameText:SetTextColor(colorObj.r, colorObj.g, colorObj.b, 1)
                    end
                    previewBar.TargetNameText:SetShown(MODULE_DB.showTarget)
                end

                if previewBar.TimerText then
                    previewBar.TimerText:SetText("2.5")
                    previewBar.TimerText:SetShown(true)
                end

                previewBar:Show()
            end
        end
    else
        if previewBar then
            ReleaseBar(previewBar)
            previewBar = nil
        end
        UpdateFocusCast()
    end

    RefreshAll()
end

local function OnFocusSpellEvent(event, unit, castID, spellID, interruptedBy)
    if unit and unit ~= "focus" then return end
    if not MODULE_DB.enabled or isPreviewing then return end

    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        TryPlayFocusSound()
        UpdateFocusCast()
        return
    end

    UpdateFocusCast()
end

InfinityTools:RegisterEvent("PLAYER_FOCUS_CHANGED", INFINITY_MODULE_KEY, function()
    if not MODULE_DB.enabled or isPreviewing then return end
    UpdateFocusCast()
end)

InfinityTools:RegisterEvent("UNIT_SPELLCAST_START", INFINITY_MODULE_KEY, OnFocusSpellEvent)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", INFINITY_MODULE_KEY, OnFocusSpellEvent)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_STOP", INFINITY_MODULE_KEY, OnFocusSpellEvent)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", INFINITY_MODULE_KEY, OnFocusSpellEvent)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", INFINITY_MODULE_KEY, OnFocusSpellEvent)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_FAILED", INFINITY_MODULE_KEY, OnFocusSpellEvent)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", INFINITY_MODULE_KEY, OnFocusSpellEvent)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", INFINITY_MODULE_KEY, OnFocusSpellEvent)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "preview" then
        TogglePreview(MODULE_DB.preview)
        return
    end

    if info.key == "enabled" then
        if MODULE_DB.enabled then
            CreateAnchor()
            if anchorFrame then anchorFrame:Show() end
            RefreshAll()
            UpdateFocusCast()
        else
            TogglePreview(false)
            ClearActiveBar()
            if anchorFrame then anchorFrame:Hide() end
        end
        return
    end

    if info.key == "showBar" then
        if not MODULE_DB.showBar then
            ClearActiveBar()
        else
            UpdateFocusCast()
        end
    end

    RefreshAll()
    UpdateFocusCast()
end)

-- [Dynamic interrupt response] Watch State changes
InfinityTools:WatchState("InterruptReady", INFINITY_MODULE_KEY, function()
    if not MODULE_DB.enabled then return end
    RefreshAll()
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "btn_reset_pos" then
        MODULE_DB.posX = 0
        MODULE_DB.posY = -140
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
        end
        RefreshAll()
    elseif info.key == "btn_test_sound" then
        PlayConfiguredSound(true)
    end
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    MODULE_DB.preview = false
    C_Timer.After(1, function()
        CreateAnchor()
        TogglePreview(false)
        RefreshAll()
        UpdateFocusCast()
    end)
end)

-- =============================================================
-- Global edit mode support
-- =============================================================
InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    if enabled then
        MODULE_DB.locked = false
        MODULE_DB.preview = true
        TogglePreview(true)
        RefreshAll()
    else
        MODULE_DB.locked = true
        MODULE_DB.preview = false
        TogglePreview(false)
        RefreshAll()
    end
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)
