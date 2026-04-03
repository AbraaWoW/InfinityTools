-- [[ Spell Alert ]]
-- { Key = "RevTools.SpellAlert", Name = "Spell Alert", Desc = "Monitors successful player casts and plays a sound or shows an icon after a configurable delay.", Category = 4 },

-- =========================================================
-- Architecture notes (v2.0)
-- Each rule (Alert) contains:
-- triggers[1] -> single trigger
-- selectedTrigger -> always 1 (UI state)
-- selectedTab -> current tab
-- action/style fields -> kept compatible with v1.0
--
-- Trigger types:
-- "spell" -> successful cast events (UNIT_SPELLCAST_SUCCEEDED)
-- "state" -> state delta changes (WatchStateDelta)
--   "always" -> always active, fires once when load conditions become true
--   "onload" -> fires once after load conditions become true, respecting delay
-- (future) "aura" -> buff gained/lost
-- (future) "combat" -> enter/leave combat
-- =========================================================
local ondev = true
if ondev then
    return
end

local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB

local LSM = LibStub("LibSharedMedia-3.0")
local LibSerialize = LibStub and LibStub("LibSerialize")
local LibDeflate = LibStub and LibStub("LibDeflate")

local INFINITY_MODULE_KEY = "RevTools.SpellAlert"
local ALERT_EXPORT_PREFIX = "!EXSA1!"
print("|cff00ff00[SpellAlert] Module loading...|r")
-- =========================================================
-- 0. LibCustomGlow wrapper
-- =========================================================
local LCG = LibStub("LibCustomGlow-1.0")

local function ActionButton_StopAllGlows(frame)
    if not LCG then return end
    LCG.ButtonGlow_Stop(frame)
    LCG.PixelGlow_Stop(frame)
    LCG.AutoCastGlow_Stop(frame)
    if LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(frame) end
end

local function ActionButton_ShowOverlayGlow(frame, rule)
    if not LCG then return end
    local target = frame.glowFrame or frame
    local offset = tonumber(rule.myGlowOffset) or 0
    if frame.glowFrame then
        frame.glowFrame:ClearAllPoints()
        frame.glowFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
        frame.glowFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)
    end
    ActionButton_StopAllGlows(target)
    local style = rule.myGlowStyle or "Action Button Glow"
    local color = nil
    if rule.myGlowColorR then
        color = { rule.myGlowColorR, rule.myGlowColorG, rule.myGlowColorB, rule.myGlowColorA or 1 }
    end
    local freq = tonumber(rule.myGlowFrequency)
    local lines = tonumber(rule.myGlowLines)
    local scale = tonumber(rule.myGlowScale)
    if style == "Action Button Glow" then
        LCG.ButtonGlow_Start(target, color, freq)
    elseif style == "Pixel Glow" then
        LCG.PixelGlow_Start(target, color, lines, freq, nil, scale)
    elseif style == "Autocast Shine" then
        LCG.AutoCastGlow_Start(target, color, lines, freq, scale)
    elseif style == "Proc Glow" then
        if LCG.ProcGlow_Start then LCG.ProcGlow_Start(target, { color }) end
    end
end

local function ActionButton_HideOverlayGlow(frame)
    local target = frame.glowFrame or frame
    ActionButton_StopAllGlows(target)
end

-- =========================================================
-- 1. Data model
-- =========================================================


local function GetDefaultSpellTrigger()
    return {
        type = "spell",
        enabled = true,
        spellID = "",
        icd = 0,
    }
end

local function GetDefaultStateTrigger()
    return {
        type = "state",
        enabled = true,
        stateKey = "PStat_Haste",
        condition = "increase", -- "increase" | "decrease"
        min = 0,
        max = 100,
        margin = 0.1,
    }
end

local function GetDefaultBarStyle()
    return {
        width = 240,
        height = 24,
        texture = "Clean",
        barColorR = 1,
        barColorG = 0.7,
        barColorB = 0,
        barColorA = 1,
        barBgColorR = 0,
        barBgColorG = 0,
        barBgColorB = 0,
        barBgColorA = 0.5,
        showIcon = true,
        iconSide = "LEFT",
        iconSize = 24,
        iconOffsetX = -5,
        iconOffsetY = 0,
    }
end

local function GetDefaultTextStyle()
    return {
        text = "Spell Alert",
        font = nil, -- nil = use main font
        size = 28,
        outline = "OUTLINE",
        r = 1,
        g = 1,
        b = 1,
        a = 1,
    }
end

local function EnsureDisplayConfig(rule)
    local t = tostring(rule.displayType or "icon")
    if t ~= "icon" and t ~= "bar" and t ~= "text" then
        t = "icon"
    end
    rule.displayType = t

    if not rule.barStyle or type(rule.barStyle) ~= "table" then
        rule.barStyle = GetDefaultBarStyle()
    else
        local d = GetDefaultBarStyle()
        for k, v in pairs(d) do
            if rule.barStyle[k] == nil then
                rule.barStyle[k] = v
            end
        end
        if type(rule.barStyle.barColor) == "table" then
            rule.barStyle.barColorR = rule.barStyle.barColorR or rule.barStyle.barColor.r
            rule.barStyle.barColorG = rule.barStyle.barColorG or rule.barStyle.barColor.g
            rule.barStyle.barColorB = rule.barStyle.barColorB or rule.barStyle.barColor.b
            rule.barStyle.barColorA = rule.barStyle.barColorA or rule.barStyle.barColor.a
        end
        if type(rule.barStyle.barBgColor) == "table" then
            rule.barStyle.barBgColorR = rule.barStyle.barBgColorR or rule.barStyle.barBgColor.r
            rule.barStyle.barBgColorG = rule.barStyle.barBgColorG or rule.barStyle.barBgColor.g
            rule.barStyle.barBgColorB = rule.barStyle.barBgColorB or rule.barStyle.barBgColor.b
            rule.barStyle.barBgColorA = rule.barStyle.barBgColorA or rule.barStyle.barBgColor.a
        end
    end

    if not rule.textStyle or type(rule.textStyle) ~= "table" then
        rule.textStyle = GetDefaultTextStyle()
    else
        local d = GetDefaultTextStyle()
        for k, v in pairs(d) do
            if rule.textStyle[k] == nil then
                rule.textStyle[k] = v
            end
        end
    end
end

local function NormalizeSingleTrigger(rule)
    if type(rule.triggers) ~= "table" then
        rule.triggers = { GetDefaultSpellTrigger() }
    end

    local t = rule.triggers[1]
    if type(t) ~= "table" then
        t = GetDefaultSpellTrigger()
    end

    -- Fill missing default fields.
    if t.type == "state" then
        if t.enabled == nil then t.enabled = true end
        if not t.stateKey or t.stateKey == "" then t.stateKey = "PStat_Haste" end
        if not t.condition or t.condition == "" then t.condition = "increase" end
        t.min = tonumber(t.min) or 0
        t.max = tonumber(t.max) or 100
        t.margin = tonumber(t.margin) or 0.1
    elseif t.type == "onload" then
        if t.enabled == nil then t.enabled = true end
        t.after = tonumber(t.after) or 0
        if t.after < 0 then t.after = 0 end
    elseif t.type == "always" then
        t.type = "always"
        if t.enabled == nil then t.enabled = true end
    else
        t.type = "spell"
        if t.enabled == nil then t.enabled = true end
        t.spellID = tostring(t.spellID or "")
        t.icd = tonumber(t.icd) or 0
    end

    rule.triggers = { t }    -- Single-trigger mode
    rule.selectedTrigger = 1 -- Always 1
    rule.triggerMode = nil   -- Multi-trigger mode is deprecated
    return t
end

local function GetDefaultConditions()
    return {
        checkEnabled  = false,
        inCombat      = nil, -- nil = no limit, true = in combat, false = out of combat
        specIDs       = {},  -- Empty = no limit, otherwise current spec ID must be listed
        instanceTypes = {},  -- Empty = no limit, values: "dungeon"/"raid"/"pvp"/"arena"/"none"
        difficultyIDs = {},  -- Empty = no limit, list of difficulty IDs
        encounterIDs  = {},  -- Empty = no limit, list of encounter IDs
        classIDs      = {},  -- Empty = no limit, list of class IDs
        inGroup       = nil, -- nil = no limit, "solo"/"party"/"raid"
        minLevel      = nil, -- Minimum level, nil = no limit
        maxLevel      = nil, -- Maximum level, nil = no limit
        playerName    = "",  -- Character name list, comma-separated, partial match, empty = no limit
    }
end

local function GetDefaultLoadConditions()
    return {
        inCombat      = nil, -- nil = no limit, true = in combat, false = out of combat
        inInstance    = nil, -- nil = no limit, true = in instance, false = outside instance
        specIDs       = {},
        mapIDs        = {},  -- Map IDs / map group IDs (MapID / MapGroup)
        instanceTypes = {},
        difficultyIDs = {},
        encounterIDs  = {},
        classIDs      = {},
        inGroup       = nil,
        minLevel      = nil,
        maxLevel      = nil,
        playerName    = "",
        realmName     = "", -- Realm names, comma-separated, partial match, empty = no limit
    }
end

local function GetDefaultActionCondition()
    return {
        enabled = false,
        when = "on_trigger", -- on_trigger | on_end | remaining
        op = "<=",           -- > | >= | = | <= | <
        value = 0,           -- Seconds
        actionGlow = "none", -- none | on | off
        actionSound = false, -- Use the sound configured on the Action tab
    }
end

local function GetDefaultAlert(displayType)
    return {
        enabled = true,
        name = "New Rule",

        -- Single trigger, stored in triggers[1]
        triggers = { GetDefaultSpellTrigger() },
        selectedTrigger = 1, -- UI state
        selectedTab = 1,     -- UI state

        delay = 0,
        displayType = displayType or "icon",

        -- Trigger conditions checked before every fire; skip if not matched
        conditions = GetDefaultConditions(),

        -- Load conditions, empty = no limit, rechecked on State changes
        loadConditions = GetDefaultLoadConditions(),

        -- Action condition controls when glow/sound fires
        actionCondition = GetDefaultActionCondition(),

        -- Action: sound
        mySoundSound = "None",
        mySoundChannel = "Master",
        mySoundUseCustom = false,
        mySoundCustomPath = "",

        -- Action: icon
        showIcon = true,
        iconID = "",
        reverse = false,
        glowRemaining = 0,
        glowAlways = false,
        width = 40,
        height = 40,
        duration = 2,
        x = 0,
        y = 100,

        -- New display settings
        barStyle = GetDefaultBarStyle(),
        textStyle = GetDefaultTextStyle(),
    }
end

local MODULE_DEFAULTS = {
    selectedAlert = 1,
    alerts = { GetDefaultAlert() },
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)
if not MODULE_DB.alerts or #MODULE_DB.alerts == 0 then
    MODULE_DB.alerts = { GetDefaultAlert() }
end

local function InitializeRule(rule)
    NormalizeSingleTrigger(rule)
    EnsureDisplayConfig(rule)
    rule.selectedTab = rule.selectedTab or 1
    -- Fill missing condition tables.
    if not rule.conditions then rule.conditions = GetDefaultConditions() end
    if not rule.loadConditions then rule.loadConditions = GetDefaultLoadConditions() end
    if not rule.actionCondition or type(rule.actionCondition) ~= "table" then
        rule.actionCondition = GetDefaultActionCondition()
    else
        local d = GetDefaultActionCondition()
        for k, v in pairs(d) do
            if rule.actionCondition[k] == nil then
                rule.actionCondition[k] = v
            end
        end
    end
end

for _, rule in ipairs(MODULE_DB.alerts) do
    InitializeRule(rule)
end

local isUnlocked = false

-- =========================================================
-- 1b. State access helpers
-- =========================================================

local function GetStateValue(key, defaultValue)
    local st = InfinityTools.State
    if not st then return defaultValue end
    local v = st[key]
    if v == nil then return defaultValue end
    return v
end

-- Forward declaration for RegisterStateTriggers, defined below
local RegisterStateTriggers

local STATE_KEYS_TO_WATCH = {
    "InCombat", "InInstance", "InstanceType",
    "MapID", "MapGroup",
    "DifficultyID", "SpecID", "SpecName",
    "IsBossEncounter", "EncounterID",
    "ClassID", "ClassName",
    "IsInParty", "IsInRaid",
    "Level", "PlayerName", "RealmName",
}
for _, k in ipairs(STATE_KEYS_TO_WATCH) do
    local watchedKey = k
    InfinityTools:WatchState(watchedKey, INFINITY_MODULE_KEY .. ".StateWatch", function()
        if RegisterStateTriggers then RegisterStateTriggers() end
    end)
end

-- =========================================================
-- 1c. Condition checks
-- =========================================================

local function CheckConditions(rule)
    local c = rule.conditions
    if not c or not c.checkEnabled then return true end

    local inCombat = GetStateValue("InCombat", false)
    local specID = tonumber(GetStateValue("SpecID", 0)) or 0
    local instanceType = tostring(GetStateValue("InstanceType", "none"))
    local difficultyID = tonumber(GetStateValue("DifficultyID", 0)) or 0
    local encounterID = tonumber(GetStateValue("EncounterID", 0)) or 0
    local classID = tonumber(GetStateValue("ClassID", 0)) or 0
    local isInRaid = GetStateValue("IsInRaid", false) == true
    local isInParty = GetStateValue("IsInParty", false) == true
    local level = tonumber(GetStateValue("Level", 0)) or 0
    local playerName = tostring(GetStateValue("PlayerName", "") or "")

    -- Combat state
    if c.inCombat ~= nil and c.inCombat ~= inCombat then
        return false
    end
    -- Spec IDs
    if c.specIDs and #c.specIDs > 0 then
        local found = false
        for _, id in ipairs(c.specIDs) do
            if tonumber(id) == specID then
                found = true; break
            end
        end
        if not found then return false end
    end
    -- Instance types
    if c.instanceTypes and #c.instanceTypes > 0 then
        local found = false
        for _, t in ipairs(c.instanceTypes) do
            if t == instanceType then
                found = true; break
            end
        end
        if not found then return false end
    end
    -- Difficulty IDs
    if c.difficultyIDs and #c.difficultyIDs > 0 then
        local found = false
        for _, id in ipairs(c.difficultyIDs) do
            if tonumber(id) == difficultyID then
                found = true; break
            end
        end
        if not found then return false end
    end
    -- Encounter IDs
    if c.encounterIDs and #c.encounterIDs > 0 then
        local found = false
        for _, id in ipairs(c.encounterIDs) do
            if tonumber(id) == encounterID then
                found = true; break
            end
        end
        if not found then return false end
    end
    -- Class IDs
    if c.classIDs and #c.classIDs > 0 then
        local found = false
        for _, id in ipairs(c.classIDs) do
            if tonumber(id) == classID then
                found = true; break
            end
        end
        if not found then return false end
    end
    -- Group type
    if c.inGroup ~= nil then
        local cur = isInRaid and "raid" or isInParty and "party" or "solo"
        if c.inGroup ~= cur then return false end
    end
    -- Level range
    if c.minLevel and level < c.minLevel then return false end
    if c.maxLevel and level > c.maxLevel then return false end
    -- Character names, comma-separated partial match
    if c.playerName and c.playerName ~= "" then
        local myName = playerName:lower()
        local matched = false
        for name in c.playerName:gmatch("[^,]+") do
            name = name:match("^%s*(.-)%s*$"):lower()
            if name ~= "" and myName:find(name, 1, true) then
                matched = true; break
            end
        end
        if not matched then return false end
    end
    return true
end

local function CheckLoadConditions(rule)
    local lc = rule.loadConditions
    if not lc then return true end

    local inCombat = GetStateValue("InCombat", false)
    local inInstance = GetStateValue("InInstance", false) == true
    local specID = tonumber(GetStateValue("SpecID", 0)) or 0
    local instanceType = tostring(GetStateValue("InstanceType", "none"))
    local difficultyID = tonumber(GetStateValue("DifficultyID", 0)) or 0
    local encounterID = tonumber(GetStateValue("EncounterID", 0)) or 0
    local classID = tonumber(GetStateValue("ClassID", 0)) or 0
    local isInRaid = GetStateValue("IsInRaid", false) == true
    local isInParty = GetStateValue("IsInParty", false) == true
    local level = tonumber(GetStateValue("Level", 0)) or 0
    local playerName = tostring(GetStateValue("PlayerName", "") or "")
    local realmName = tostring(GetStateValue("RealmName", "") or "")
    local mapID = tonumber(GetStateValue("MapID", 0)) or 0
    local mapGroup = tonumber(GetStateValue("MapGroup", 0)) or 0
    if mapGroup <= 0 then mapGroup = mapID end

    if lc.inCombat ~= nil and lc.inCombat ~= inCombat then
        return false
    end
    if lc.inInstance ~= nil and lc.inInstance ~= inInstance then
        return false
    end
    if lc.specIDs and #lc.specIDs > 0 then
        local found = false
        for _, id in ipairs(lc.specIDs) do
            if tonumber(id) == specID then
                found = true; break
            end
        end
        if not found then return false end
    end
    if lc.mapIDs and #lc.mapIDs > 0 then
        local found = false
        for _, id in ipairs(lc.mapIDs) do
            local n = tonumber(id)
            if n and (n == mapID or n == mapGroup) then
                found = true; break
            end
        end
        if not found then return false end
    end
    if lc.instanceTypes and #lc.instanceTypes > 0 then
        local found = false
        for _, t in ipairs(lc.instanceTypes) do
            if t == instanceType then
                found = true; break
            end
        end
        if not found then return false end
    end
    if lc.difficultyIDs and #lc.difficultyIDs > 0 then
        local found = false
        for _, id in ipairs(lc.difficultyIDs) do
            if tonumber(id) == difficultyID then
                found = true; break
            end
        end
        if not found then return false end
    end
    if lc.encounterIDs and #lc.encounterIDs > 0 then
        local found = false
        for _, id in ipairs(lc.encounterIDs) do
            if tonumber(id) == encounterID then
                found = true; break
            end
        end
        if not found then return false end
    end
    -- Class IDs
    if lc.classIDs and #lc.classIDs > 0 then
        local found = false
        for _, id in ipairs(lc.classIDs) do
            if tonumber(id) == classID then
                found = true; break
            end
        end
        if not found then return false end
    end
    -- Group type
    if lc.inGroup ~= nil then
        local cur = isInRaid and "raid" or isInParty and "party" or "solo"
        if lc.inGroup ~= cur then return false end
    end
    -- Level range
    if lc.minLevel and level < lc.minLevel then return false end
    if lc.maxLevel and level > lc.maxLevel then return false end
    -- Character names
    if lc.playerName and lc.playerName ~= "" then
        local myName = playerName:lower()
        local matched = false
        for name in lc.playerName:gmatch("[^,]+") do
            name = name:match("^%s*(.-)%s*$"):lower()
            if name ~= "" and myName:find(name, 1, true) then
                matched = true; break
            end
        end
        if not matched then return false end
    end
    -- Realm names
    if lc.realmName and lc.realmName ~= "" then
        local myRealm = realmName:lower()
        local matched = false
        for name in lc.realmName:gmatch("[^,]+") do
            name = name:match("^%s*(.-)%s*$"):lower()
            if name ~= "" and myRealm:find(name, 1, true) then
                matched = true; break
            end
        end
        if not matched then return false end
    end
    return true
end

-- =========================================================
-- 2. Import/export for one rule
-- =========================================================

local function ExportAlert(rule)
    if not LibSerialize or not LibDeflate then
        return nil, "Missing LibSerialize / LibDeflate"
    end
    local exportData = {
        version = 1,
        alert = InfinityTools.Export:DeepCopy(rule),
    }
    -- Strip pure UI state fields; they do not need to be exported.
    exportData.alert.selectedTrigger = nil
    exportData.alert.selectedTab = nil

    local ok, serialized = pcall(function() return LibSerialize:Serialize(exportData) end)
    if not ok then return nil, "Serialization failed" end

    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then return nil, "Compression failed" end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then return nil, "Encoding failed" end

    return ALERT_EXPORT_PREFIX .. encoded, nil
end

local function ImportAlert(str)
    if not LibSerialize or not LibDeflate then
        return nil, "Missing LibSerialize / LibDeflate"
    end
    str = str:match("^%s*(.-)%s*$")
    if not str:find("^" .. ALERT_EXPORT_PREFIX:gsub("!", "%%!")) then
        return nil, "Invalid format (requires !EXSA1! prefix)"
    end
    local encoded = str:sub(#ALERT_EXPORT_PREFIX + 1)
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then return nil, "Decoding failed" end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return nil, "Decompression failed" end
    local ok, data = LibSerialize:Deserialize(decompressed)
    if not ok then return nil, "Deserialization failed" end
    if type(data) ~= "table" or not data.alert then return nil, "Invalid data structure" end

    local newRule = data.alert
    InitializeRule(newRule)
    newRule.selectedTrigger = 1
    newRule.selectedTab = 1
    return newRule, nil
end

-- Simple text dialog for export display / import input
local TextDialog_OnImport = nil

local function GetPopupEditBox(popup)
    if not popup then return nil end

    if type(popup.GetEditBox) == "function" then
        local ok, eb = pcall(popup.GetEditBox, popup)
        if ok and eb then return eb end
    end

    if popup.editBox then return popup.editBox end
    if popup.EditBox then return popup.EditBox end

    if popup.GetName then
        local name = popup:GetName()
        if name and _G[name .. "EditBox"] then
            return _G[name .. "EditBox"]
        end
    end

    return nil
end

local function NormalizePopupEditBox(popup)
    local eb = GetPopupEditBox(popup)
    if eb and popup then
        if not popup.EditBox then popup.EditBox = eb end
        if not popup.editBox then popup.editBox = eb end
    end
    return eb
end

StaticPopupDialogs["EXSA_TEXT_DIALOG"] = {
    text = "%s",
    hasEditBox = true,
    editBoxWidth = 360,
    button1 = "Confirm",
    button2 = "Cancel",
    OnShow = function(self)
        local payload = self.data
        if type(payload) == "table" then
            self._saText = payload.text or ""
            self._saReadOnly = payload.readOnly == true
            self._saOnImport = payload.onImport
        end

        local eb = NormalizePopupEditBox(self)
        if not eb then return end
        if self._saText then
            eb:SetText(self._saText)
        end
        if self._saReadOnly then
            eb:SetFocus()
            eb:HighlightText()
        end
    end,
    OnAccept = function(self)
        local onImport = self._saOnImport or TextDialog_OnImport
        if onImport then
            local eb = NormalizePopupEditBox(self)
            local text = eb and eb:GetText() or ""
            onImport(text)
            TextDialog_OnImport = nil
            self._saOnImport = nil
        end
    end,
    OnCancel = function(self)
        TextDialog_OnImport = nil
        if self then
            self._saOnImport = nil
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function ShowTextDialog(title, defaultText, isExport, onImport)
    TextDialog_OnImport = onImport
    local d = StaticPopupDialogs["EXSA_TEXT_DIALOG"]
    d.button1 = isExport and "Close" or "Confirm Import"
    local payload = {
        text = defaultText or "",
        readOnly = isExport == true,
        onImport = onImport,
    }
    local popup = StaticPopup_Show("EXSA_TEXT_DIALOG", title, nil, payload)
    if popup then
        popup._saText = payload.text
        popup._saReadOnly = payload.readOnly
        popup._saOnImport = payload.onImport
        local eb = NormalizePopupEditBox(popup)
        if eb then
            eb:SetText(payload.text)
            if isExport then
                eb:SetFocus()
                eb:HighlightText()
            end
        end
    end
end

-- =========================================================
-- 3. Icon frame pool and playback logic
-- =========================================================

local Runtime = {
    LastTrigger = {},    -- [ruleIndex] = timestamp for spell ICD
    ActiveDelta = {},    -- [ownerKey] = stateKey for cleanup
    LoadMatch = {},      -- [ruleIndex] = cached load-condition match / diff baseline
    LoadActive = {},     -- [ruleIndex] = edge state for always/onload triggers
    LoadTimerToken = {}, -- [ruleIndex] = cancellation token for onload delay timers
}
local DisplayFrames = {}

local function GetColor(style, key, dr, dg, db, da)
    if not style then return dr, dg, db, da end
    local t = style[key]
    if type(t) == "table" then
        return t.r or dr, t.g or dg, t.b or db, t.a or da
    end
    return style[key .. "R"] or dr, style[key .. "G"] or dg, style[key .. "B"] or db, style[key .. "A"] or da
end

local function ResetDisplayFrame(f)
    if not f then return end
    f:SetScript("OnUpdate", nil)
    f._playToken = (f._playToken or 0) + 1

    if f.icon then f.icon:Hide() end
    if f.bar then f.bar:Hide() end
    if f.barBg then f.barBg:Hide() end
    if f.barIcon then f.barIcon:Hide() end
    if f.textFS then f.textFS:Hide() end
    if f.cooldown then
        f.cooldown:Hide()
        if _G.CooldownFrame_Clear then
            _G.CooldownFrame_Clear(f.cooldown)
        end
    end
end

local function GetDisplayFrame(index)
    if not DisplayFrames[index] then
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetFrameStrata("HIGH")
        f:SetClampedToScreen(false)
        f.ruleIndex = index

        -- Icon display
        f.icon = f:CreateTexture(nil, "ARTWORK")
        f.icon:SetAllPoints()
        f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Border
        f.border = f:CreateTexture(nil, "OVERLAY")
        f.border:SetColorTexture(0, 0, 0, 1)
        f.border:SetPoint("TOPLEFT", -1, 1)
        f.border:SetPoint("BOTTOMRIGHT", 1, -1)
        f.border:SetDrawLayer("BACKGROUND")

        -- Cooldown overlay
        f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
        f.cooldown:SetAllPoints()
        f.cooldown:SetDrawEdge(false)
        f.cooldown:SetHideCountdownNumbers(false)

        -- Timer bar
        f.barBg = f:CreateTexture(nil, "BACKGROUND")
        f.barBg:SetAllPoints()
        f.barBg:SetTexture("Interface\\Buttons\\WHITE8X8")

        f.bar = CreateFrame("StatusBar", nil, f)
        f.bar:SetAllPoints()
        f.bar:SetMinMaxValues(0, 1)
        f.bar:SetValue(1)

        f.barIcon = f:CreateTexture(nil, "OVERLAY")
        f.barIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Text display
        f.textFS = f:CreateFontString(nil, "OVERLAY")
        f.textFS:SetPoint("CENTER")

        f.glowFrame = CreateFrame("Frame", nil, f)
        f.glowFrame:SetAllPoints()
        f.glowFrame:SetFrameLevel(f:GetFrameLevel() + 5)

        f.dragText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.dragText:SetPoint("TOP", f, "BOTTOM", 0, -2)
        f.dragText:SetText("Rule " .. index)
        f.dragText:Hide()

        InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, f)

        f:SetScript("OnDragStart", function(self)
            if isUnlocked then self:StartMoving() end
        end)
        f:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local rule = MODULE_DB.alerts[self.ruleIndex]
            if rule then
                local cx, cy = self:GetCenter()
                local screenW, screenH = UIParent:GetSize()
                if cx and cy then
                    rule.x = cx - (screenW / 2)
                    rule.y = cy - (screenH / 2)
                end
            end
        end)

        DisplayFrames[index] = f
    end
    return DisplayFrames[index]
end

-- Smart icon resolution: use iconID first, otherwise use the first spell trigger icon
local function GetAlertIcon(rule)
    local tex = rule.iconID
    if not tex or tex == "" then
        local t = NormalizeSingleTrigger(rule)
        if t.type == "spell" and t.spellID and t.spellID ~= "" then
            tex = C_Spell.GetSpellTexture(tonumber(t.spellID)) or 134400
        end
        tex = tex or 134400
    elseif tonumber(tex) then
        tex = tonumber(tex)
    end
    if type(tex) == "string" and tex:match("^%d+$") then
        local val = tonumber(tex)
        local spellTex = C_Spell.GetSpellTexture(val)
        tex = spellTex or val
    end
    return tex
end

local function SetupBarVisual(f, rule)
    local style = rule.barStyle or GetDefaultBarStyle()
    local w = tonumber(style.width) or 240
    local h = tonumber(style.height) or 24
    f:SetSize(w, h)

    local barTexture = style.texture
    if LSM and type(barTexture) == "string" and barTexture ~= "" then
        local fetched = LSM:Fetch("statusbar", barTexture)
        if fetched then barTexture = fetched end
    end
    if not barTexture or barTexture == "" then
        barTexture = "Interface\\TargetingFrame\\UI-StatusBar"
    end
    f.bar:SetStatusBarTexture(barTexture)

    local br, bg, bb, ba = GetColor(style, "barColor", 1, 0.7, 0, 1)
    local rr, rg, rb, ra = GetColor(style, "barBgColor", 0, 0, 0, 0.5)
    f.bar:SetStatusBarColor(br, bg, bb, ba)
    f.barBg:SetVertexColor(rr, rg, rb, ra)
    f.barBg:Show()
    f.bar:Show()

    if style.showIcon ~= false then
        local iconSize = tonumber(style.iconSize) or 24
        local side = style.iconSide or "LEFT"
        local ox = tonumber(style.iconOffsetX) or -5
        local oy = tonumber(style.iconOffsetY) or 0
        f.barIcon:SetSize(iconSize, iconSize)
        f.barIcon:SetTexture(GetAlertIcon(rule))
        f.barIcon:ClearAllPoints()
        if side == "RIGHT" then
            f.barIcon:SetPoint("LEFT", f, "RIGHT", ox, oy)
        else
            f.barIcon:SetPoint("RIGHT", f, "LEFT", ox, oy)
        end
        f.barIcon:Show()
    else
        f.barIcon:Hide()
    end
end

local function SetupTextVisual(f, rule)
    local t = rule.textStyle or GetDefaultTextStyle()
    local text = t.text
    if not text or text == "" then
        text = rule.name or "Spell Alert"
    end

    local fontPath = t.font
    if LSM and type(fontPath) == "string" and fontPath ~= "" then
        local fetched = LSM:Fetch("font", fontPath)
        if fetched then fontPath = fetched end
    end
    if not fontPath or fontPath == "" then
        fontPath = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"
    end

    local size = tonumber(t.size) or 28
    local outline = t.outline or "OUTLINE"
    local ok = pcall(function() f.textFS:SetFont(fontPath, size, outline) end)
    if not ok then
        f.textFS:SetFont("Fonts\\FRIZQT__.TTF", size, outline)
    end
    f.textFS:SetTextColor(t.r or 1, t.g or 1, t.b or 1, t.a or 1)
    f.textFS:SetText(text)
    f.textFS:Show()

    local w = math.max(40, (f.textFS:GetStringWidth() or 0) + 20)
    local h = math.max(20, (f.textFS:GetStringHeight() or 0) + 10)
    f:SetSize(w, h)
end

local function UpdateUnlockVisuals()
    for i, rule in ipairs(MODULE_DB.alerts) do
        EnsureDisplayConfig(rule)
        local f = GetDisplayFrame(i)
        ActionButton_HideOverlayGlow(f)
        ResetDisplayFrame(f)
        if isUnlocked then
            f:Show()
            f:EnableMouse(true)
            f:SetMovable(true)
            f:RegisterForDrag("LeftButton")
            f.border:SetColorTexture(0, 1, 0, 1)
            f.dragText:SetText("Rule " .. i)
            f.dragText:Show()
            f:ClearAllPoints()
            f:SetPoint("CENTER", UIParent, "CENTER", tonumber(rule.x) or 0, tonumber(rule.y) or 0)

            local displayType = rule.displayType or "icon"
            if displayType == "bar" then
                SetupBarVisual(f, rule)
                f.bar:SetValue(rule.reverse and 0 or 1)
            elseif displayType == "text" then
                SetupTextVisual(f, rule)
            else
                f:SetSize(tonumber(rule.width) or 40, tonumber(rule.height) or 40)
                f.icon:SetTexture(GetAlertIcon(rule))
                f.icon:Show()
            end

            local glowEnabled = rule.myGlowEnabled
            if glowEnabled == nil then glowEnabled = true end
            if glowEnabled then ActionButton_ShowOverlayGlow(f, rule) end
        else
            f:Hide()
            f:EnableMouse(false)
            f:SetMovable(false)
            f.border:SetColorTexture(0, 0, 0, 1)
            f.dragText:Hide()
        end
    end
    for i = #MODULE_DB.alerts + 1, #DisplayFrames do
        if DisplayFrames[i] then
            ActionButton_HideOverlayGlow(DisplayFrames[i])
            DisplayFrames[i]:Hide()
        end
    end
end

local function ResolveRuleSound(rule)
    if rule.mySoundUseCustom and rule.mySoundCustomPath and rule.mySoundCustomPath ~= "" then
        return rule.mySoundCustomPath
    end
    if rule.mySoundSound and rule.mySoundSound ~= "None" then
        return LSM:Fetch("sound", rule.mySoundSound)
    end
    return nil
end

local function ComputeRuleLoadMatch(rule)
    return (rule and rule.enabled and CheckLoadConditions(rule)) and true or false
end

local function RefreshRuleLoadMatch(ruleIndex, rule)
    local r = rule or (MODULE_DB.alerts and MODULE_DB.alerts[ruleIndex])
    local newMatch = ComputeRuleLoadMatch(r)
    Runtime.LoadMatch[ruleIndex] = newMatch
    return newMatch
end

local function RefreshAllRuleLoadMatch()
    if not MODULE_DB.alerts then return end
    for i, rule in ipairs(MODULE_DB.alerts) do
        RefreshRuleLoadMatch(i, rule)
    end
    for idx in pairs(Runtime.LoadMatch) do
        if idx > #MODULE_DB.alerts then
            Runtime.LoadMatch[idx] = nil
        end
    end
end

local function IsRuleLoadMatched(ruleIndex, rule)
    local cached = Runtime.LoadMatch[ruleIndex]
    if cached == nil then
        cached = RefreshRuleLoadMatch(ruleIndex, rule)
    end
    return cached == true
end

local function PlayRuleSound(rule)
    local soundFile = ResolveRuleSound(rule)
    if soundFile then
        PlaySoundFile(soundFile, rule.mySoundChannel or "Master")
    end
end

local function ExecuteActionCondition(rule, frame)
    local ac = rule and rule.actionCondition
    if type(ac) ~= "table" or ac.enabled ~= true then return end

    if ac.actionGlow == "on" then
        ActionButton_ShowOverlayGlow(frame, rule)
    elseif ac.actionGlow == "off" then
        ActionButton_HideOverlayGlow(frame)
    end

    if ac.actionSound == true then
        PlayRuleSound(rule)
    end
end

local function ComputeRemainingConditionDelay(ac, dur)
    if not ac or not dur or dur <= 0 then return nil end
    local op = tostring(ac.op or "<=")
    local value = tonumber(ac.value) or 0
    if value < 0 then value = 0 end

    if op == ">" then
        return (dur > value) and 0 or nil
    elseif op == ">=" then
        return (dur >= value) and 0 or nil
    elseif op == "=" then
        if value > dur then return nil end
        return math.max(0, dur - value)
    elseif op == "<=" then
        if dur <= value then return 0 end
        return math.max(0, dur - value)
    else -- "<"
        if dur < value then return 0 end
        local threshold = dur - value
        if threshold < 0 then threshold = 0 end
        return threshold + 0.01
    end
end

local function PlayAlert(ruleIndex)
    local rule = MODULE_DB.alerts[ruleIndex]
    if not rule or not rule.enabled then return end
    if not IsRuleLoadMatched(ruleIndex, rule) then return end
    EnsureDisplayConfig(rule)
    local trigger = NormalizeSingleTrigger(rule)
    local isAlwaysTrigger = (trigger.type == "always" and trigger.enabled ~= false)

    -- Sound normally plays on trigger; avoid double playback when actionCondition also requests sound on trigger.
    local ac = rule.actionCondition
    local suppressDefaultSound = (type(ac) == "table" and ac.enabled == true and ac.when == "on_trigger" and ac.actionSound == true)
    if not suppressDefaultSound then
        PlayRuleSound(rule)
    end

    local f = GetDisplayFrame(ruleIndex)
    local x = tonumber(rule.x) or 0
    local y = tonumber(rule.y) or 0
    local dur = tonumber(rule.duration) or 2
    if isAlwaysTrigger then
        dur = nil -- always triggers stay visible until load conditions become false
    end
    local now = GetTime()
    local token

    ActionButton_HideOverlayGlow(f)
    ResetDisplayFrame(f)

    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", x, y)
    f:Show()

    local displayType = rule.displayType or "icon"
    if displayType == "bar" then
        SetupBarVisual(f, rule)
        local reverse = rule.reverse == true
        f.bar:SetValue(reverse and 0 or 1)
        if dur and dur > 0 then
            token = f._playToken
            f:SetScript("OnUpdate", function(self)
                if self._playToken ~= token then return end
                local passed = GetTime() - now
                if passed >= dur then
                    self:SetScript("OnUpdate", nil)
                    self.bar:SetValue(reverse and 1 or 0)
                    return
                end
                local p = passed / dur
                self.bar:SetValue(reverse and p or (1 - p))
            end)
        end
    elseif displayType == "text" then
        SetupTextVisual(f, rule)
    else
        if rule.showIcon == false then
            f:Hide()
            return
        end
        local w = tonumber(rule.width) or 40
        local h = tonumber(rule.height) or 40
        f:SetSize(w, h)
        f.icon:SetTexture(GetAlertIcon(rule))
        f.icon:Show()
        if dur and dur > 0 then
            f.cooldown:Show()
            f.cooldown:SetReverse(rule.reverse or false)
            f.cooldown:SetCooldown(now, dur)
        end
    end

    if rule.glowAlways == true then
        ActionButton_ShowOverlayGlow(f, rule)
    else
        local glowTime = tonumber(rule.glowRemaining) or 0
        if glowTime > 0 and dur and dur > 0 then
            if glowTime >= dur then
                ActionButton_ShowOverlayGlow(f, rule)
            else
                local glowDelay = dur - glowTime
                if glowDelay > 0 then
                    token = f._playToken
                    C_Timer.After(glowDelay, function()
                        if f._playToken == token and f:IsShown() then
                            ActionButton_ShowOverlayGlow(f, rule)
                        end
                    end)
                end
            end
        end
    end

    -- Action condition: on trigger / on end / compare remaining duration
    if type(ac) == "table" and ac.enabled == true then
        local when = tostring(ac.when or "on_trigger")
        local delay = nil
        if when == "on_trigger" then
            delay = 0
        elseif when == "on_end" then
            if dur and dur > 0 then
                delay = dur
            end
        elseif when == "remaining" then
            delay = ComputeRemainingConditionDelay(ac, dur)
        end

        if delay ~= nil then
            local actionToken = f._playToken
            if delay <= 0.01 then
                if f._playToken == actionToken and f:IsShown() then
                    ExecuteActionCondition(rule, f)
                end
            else
                C_Timer.After(delay, function()
                    if f._playToken ~= actionToken then return end
                    if not f:IsShown() then return end
                    ExecuteActionCondition(rule, f)
                end)
            end
        end
    end

    if dur and dur > 0 then
        token = f._playToken
        C_Timer.After(dur, function()
            if f._playToken ~= token then return end
            if not isUnlocked then
                ActionButton_HideOverlayGlow(f)
                ResetDisplayFrame(f)
                f:Hide()
            end
        end)
    end
end

-- =========================================================
-- 4. Trigger engine
-- =========================================================

-- Trigger entry point. The old Conditions tab is retired, so rule.conditions is no longer applied here.
local function TryPlayAlert(ruleIndex)
    local rule = MODULE_DB.alerts[ruleIndex]
    if not rule or not rule.enabled then return end
    if not IsRuleLoadMatched(ruleIndex, rule) then return end
    local delay = tonumber(rule.delay) or 0
    if delay <= 0.05 then
        PlayAlert(ruleIndex)
    else
        C_Timer.After(delay, function()
            local r = MODULE_DB.alerts[ruleIndex]
            if not r or not r.enabled then return end
            if not IsRuleLoadMatched(ruleIndex, r) then return end
            PlayAlert(ruleIndex)
        end)
    end
end

-- Spell trigger (event-driven)
InfinityTools:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", INFINITY_MODULE_KEY, function(_, unit, _, spellID)
    if unit ~= "player" then return end
    if not MODULE_DB.alerts or isUnlocked then return end

    local now = GetTime()

    for i, rule in ipairs(MODULE_DB.alerts) do
        if IsRuleLoadMatched(i, rule) then
            local trigger = NormalizeSingleTrigger(rule)
            if trigger.type == "spell" and trigger.enabled ~= false and tonumber(trigger.spellID) == spellID then
                local icd = tonumber(trigger.icd) or 0
                local last = Runtime.LastTrigger[i] or 0
                if now - last >= icd then
                    Runtime.LastTrigger[i] = now
                    TryPlayAlert(i)
                end
            end
        end
    end
end)

-- State delta triggers: registration/unregistration
-- Forward declaration is above: local RegisterStateTriggers
RegisterStateTriggers = function()
    -- Clear previous subscriptions
    for owner, stateKey in pairs(Runtime.ActiveDelta) do
        InfinityTools:UnwatchStateDelta(stateKey, owner)
    end
    Runtime.ActiveDelta = {}

    -- Rebuild load-condition caches and diff baselines.
    RefreshAllRuleLoadMatch()

    for i, rule in ipairs(MODULE_DB.alerts) do
        -- Skip registration when load conditions are not matched.
        if IsRuleLoadMatched(i, rule) then
            local trigger = NormalizeSingleTrigger(rule)
            if trigger.type == "state" and trigger.enabled ~= false then
                local sk = trigger.stateKey
                if sk and sk ~= "" then
                    local minVal               = tonumber(trigger.min) or 0
                    local maxVal               = tonumber(trigger.max) or 100
                    local margin               = tonumber(trigger.margin) or 0.1
                    local cond                 = trigger.condition or "increase"
                    local owner                = string.format("EXSA.delta.%d", i)
                    local ruleIdx              = i

                    Runtime.ActiveDelta[owner] = sk

                    local function doPlay()
                        if isUnlocked then return end
                        local r = MODULE_DB.alerts[ruleIdx]
                        if not r or not r.enabled then return end
                        TryPlayAlert(ruleIdx)
                    end

                    InfinityTools:WatchStateDelta(sk, owner, {
                        min       = minVal * (1 - margin),
                        max       = maxVal * (1 + margin) * 2,
                        onTrigger = (cond == "increase") and doPlay or nil,
                        onFade    = (cond == "decrease") and doPlay or nil,
                    })
                end
            end
        end
    end

    -- always/onload triggers fire once when load conditions are satisfied.
    for i, rule in ipairs(MODULE_DB.alerts) do
        local trigger = NormalizeSingleTrigger(rule)
        local triggerType = trigger.type
        local isLoadType = (triggerType == "always" or triggerType == "onload")
        local shouldActive = IsRuleLoadMatched(i, rule) and isLoadType and trigger.enabled ~= false
        local wasActive = Runtime.LoadActive[i] == true
        Runtime.LoadActive[i] = shouldActive
        local frameVisible = DisplayFrames[i] and DisplayFrames[i]:IsShown()
        if shouldActive and (not isUnlocked) then
            if triggerType == "onload" then
                if not wasActive then
                    local delay = tonumber(trigger.after) or 0
                    if delay < 0 then delay = 0 end
                    if delay <= 0.05 then
                        TryPlayAlert(i)
                    else
                        local token = (Runtime.LoadTimerToken[i] or 0) + 1
                        Runtime.LoadTimerToken[i] = token
                        local ruleIdx = i
                        C_Timer.After(delay, function()
                            if Runtime.LoadTimerToken[ruleIdx] ~= token then return end
                            if isUnlocked then return end
                            local r = MODULE_DB.alerts[ruleIdx]
                            if not r or not r.enabled then return end
                            local t = NormalizeSingleTrigger(r)
                            if t.type ~= "onload" or t.enabled == false then return end
                            if not IsRuleLoadMatched(ruleIdx, r) then return end
                            TryPlayAlert(ruleIdx)
                        end)
                    end
                end
            elseif triggerType == "always" and ((not wasActive) or (not frameVisible)) then
                TryPlayAlert(i)
            end
        elseif (not shouldActive) and wasActive and (not isUnlocked) then
            Runtime.LoadTimerToken[i] = (Runtime.LoadTimerToken[i] or 0) + 1
            local f = DisplayFrames[i]
            if f and triggerType == "always" then
                ActionButton_HideOverlayGlow(f)
                ResetDisplayFrame(f)
                f:Hide()
            end
        end
    end
    for idx in pairs(Runtime.LoadActive) do
        if idx > #MODULE_DB.alerts then
            Runtime.LoadActive[idx] = nil
        end
    end
    for idx in pairs(Runtime.LoadTimerToken) do
        if idx > #MODULE_DB.alerts then
            Runtime.LoadTimerToken[idx] = nil
        end
    end
    for idx in pairs(Runtime.LoadMatch) do
        if idx > #MODULE_DB.alerts then
            Runtime.LoadMatch[idx] = nil
        end
    end
end

-- =========================================================
-- 5. Config UI layout (InfinityGrid)
-- =========================================================

-- Getter helpers are no longer needed; Panel.lua reads MODULE_DB directly.

-- -------------------------
-- Minimal layout: keep only unlock preview and open panel actions.
-- Detailed settings moved to RevTools.SpellAlert.Panel.lua
-- -------------------------
local function REGISTER_LAYOUT()
    local layout = {
        {
            key = "header",
            type = "header",
            x = 2,
            y = 1,
            w = 50,
            h = 2,
            label = "Spell Alert v2",
            labelSize = 25
        },
        {
            key = "desc",
            type = "description",
            x = 2,
            y = 4,
            w = 54,
            h = 2,
            label = "Supports single trigger type switching (spell cast / stat change / on load / always active). Each rule can be individually imported/exported. Click the button below to open the full configuration panel."
        },
        {
            key = "btn_open_panel",
            type = "button",
            x = 2,
            y = 7,
            w = 20,
            h = 3,
            label = "Open Config Panel"
        },
        {
            key = "btn_unlock",
            type = "button",
            x = 24,
            y = 7,
            w = 16,
            h = 3,
            label = isUnlocked and "|cff00ff00Lock Preview|r" or "|cffff0000Unlock & Preview|r"
        },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

REGISTER_LAYOUT()

-- =========================================================
-- 6. Button events. Detailed actions are handled by Panel.
-- =========================================================

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    local sel  = tonumber(MODULE_DB.selectedAlert) or 1
    local rule = MODULE_DB.alerts[sel]

    local function Refresh()
        REGISTER_LAYOUT()
        InfinityTools.UI:RefreshContent()
    end

    -- Open config panel
    if info.key == "btn_open_panel" then
        if _G.SpellAlertPanel then
            _G.SpellAlertPanel.Open()
        end
        return
    end

    -- Unlock preview from InfinityGrid
    if info.key == "btn_unlock" then
        isUnlocked = not isUnlocked
        UpdateUnlockVisuals()
        if not isUnlocked then
            RegisterStateTriggers()
        end
        Refresh()
        return
    end

    -- The following buttons are triggered by Panel via NotifyButtonClicked.
    if info.key == "btn_add_rule" or info.key == "btn_add_rule_icon"
        or info.key == "btn_add_rule_bar" or info.key == "btn_add_rule_text" then
        local displayType = "icon"
        if info.key == "btn_add_rule_bar" then
            displayType = "bar"
        elseif info.key == "btn_add_rule_text" then
            displayType = "text"
        end
        isUnlocked = false; UpdateUnlockVisuals()
        table.insert(MODULE_DB.alerts, GetDefaultAlert(displayType))
        MODULE_DB.selectedAlert = #MODULE_DB.alerts
        RegisterStateTriggers()
        if _G.SpellAlertPanel then _G.SpellAlertPanel.Refresh() end
        return
    elseif info.key == "btn_del_rule" then
        if #MODULE_DB.alerts > 0 then
            isUnlocked = false; UpdateUnlockVisuals()
            table.remove(MODULE_DB.alerts, sel)
            MODULE_DB.selectedAlert = math.max(1, sel - 1)
            RegisterStateTriggers()
            if _G.SpellAlertPanel then _G.SpellAlertPanel.Refresh() end
        end
        return
    elseif info.key == "btn_export" then
        if not rule then return end
        local str, err = ExportAlert(rule)
        if str then
            ShowTextDialog("Export Rule — Copy the string below", str, true, nil)
        else
            print("|cffff0000[SpellAlert] Export failed:|r " .. tostring(err))
        end
        return
    elseif info.key == "btn_import" then
        ShowTextDialog("Import Rule — Paste string then click Confirm", "", false, function(text)
            local newRule, err = ImportAlert(text)
            if newRule then
                table.insert(MODULE_DB.alerts, newRule)
                MODULE_DB.selectedAlert = #MODULE_DB.alerts
                RegisterStateTriggers()
                if _G.SpellAlertPanel then _G.SpellAlertPanel.Refresh() end
                print("|cff00ff00[SpellAlert] Import successful:|r " .. (newRule.name or "Unnamed"))
            else
                print("|cffff0000[SpellAlert] Import failed:|r " .. tostring(err))
            end
        end)
        return
    end

    -- Rule reordering triggered by Panel
    if info.key == "btn_move_rule" then
        -- Panel already reordered rules, so only re-register triggers.
        RegisterStateTriggers()
        return
    end
end)

-- =========================================================
-- 7. DatabaseChanged handling
-- =========================================================

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info then return end
    local key = info.key
    local fullPath = tostring(info.fullPath or "")
    local isTriggerTypeChange = (key == "type" and fullPath:find("%.trigger%.type", 1, false) ~= nil)
    local isDisplayTypeChange = (key == "type" and fullPath:find("%.displayType", 1, false) ~= nil)

    -- State trigger parameter changes -> re-register Delta watchers
    if isTriggerTypeChange or key == "stateKey" or key == "condition" or key == "min" or key == "max" or key == "margin"
        or key == "enabled" or key == "after" then
        RegisterStateTriggers()
        return
    end

    -- Condition/load-condition changes -> re-register, because load conditions can toggle rules
    if key == "conditions" or key == "loadConditions" then
        RegisterStateTriggers()
        return
    end

    -- Live refresh while preview is unlocked
    if isUnlocked and (key == "width" or key == "height" or key == "iconID" or key == "myGlow"
            or key == "icon" or key == "barStyle" or key == "textStyle"
            or key == "duration" or key == "x" or key == "y" or key == "reverse"
            or key == "glowRemaining" or key == "glowAlways" or isDisplayTypeChange) then
        UpdateUnlockVisuals()
    end

    -- Sync unlocked preview visuals when selectedAlert changes
    if key == "selectedAlert" and isUnlocked then
        UpdateUnlockVisuals()
    end
end)

-- =========================================================
-- 8. Initialization
-- =========================================================

-- Wait 1 second so InfinityState can finish initialization before Delta subscriptions are registered.
C_Timer.After(1, function()
    RegisterStateTriggers()
end)

-- Slash command shortcut for opening the config panel
InfinityTools:RegisterChatCommand("exsa", function()
    if _G.SpellAlertPanel then
        _G.SpellAlertPanel.Open()
    end
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)


print("|cff00ff00[SpellAlert] Module loaded.|r")
