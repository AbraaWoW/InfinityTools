local _, RRT_NS = ...

local Tools = RRT_NS.Tools or {}

local function GetDB()
    local db = (Tools.GetDB and Tools.GetDB()) or {}

    if db.NoMoveSkillAlert == nil then db.NoMoveSkillAlert = false end
    if db.NoMoveSkillAlertPosX == nil then db.NoMoveSkillAlertPosX = 0 end
    if db.NoMoveSkillAlertPosY == nil then db.NoMoveSkillAlertPosY = 140 end
    if db.NoMoveSkillAlertFontSize == nil then db.NoMoveSkillAlertFontSize = 24 end
    if db.NoMoveSkillAlertMageFormat == nil then db.NoMoveSkillAlertMageFormat = "No Blink (%t)" end
    if db.NoMoveSkillAlertRogueFormat == nil then db.NoMoveSkillAlertRogueFormat = "No Step (%t)" end
    if db.FocusCast == nil then db.FocusCast = false end
    if db.FocusCastPosX == nil then db.FocusCastPosX = 0 end
    if db.FocusCastPosY == nil then db.FocusCastPosY = -140 end
    if db.FocusCastWidth == nil then db.FocusCastWidth = 260 end
    if db.FocusCastHeight == nil then db.FocusCastHeight = 22 end
    if db.FocusCastSound == nil then db.FocusCastSound = "None" end
    if db.FocusCastShowTarget == nil then db.FocusCastShowTarget = true end
    if db.SpellEffectAlpha == nil then db.SpellEffectAlpha = false end
    if db.SpellEffectAlphaDefault == nil then db.SpellEffectAlphaDefault = 100 end
    if db.SpellEffectAlphaSpecs == nil then db.SpellEffectAlphaSpecs = {} end
    if db.CastSequence == nil then db.CastSequence = false end
    if db.CastSequencePosX == nil then db.CastSequencePosX = -8 end
    if db.CastSequencePosY == nil then db.CastSequencePosY = -200 end
    if db.CastSequenceSize == nil then db.CastSequenceSize = 34 end
    if db.CastSequenceAmount == nil then db.CastSequenceAmount = 8 end
    if db.CastSequenceGrow == nil then db.CastSequenceGrow = "RIGHT" end
    if db.CastSequenceIgnored == nil then db.CastSequenceIgnored = "" end
    if db.SpellAlert == nil then db.SpellAlert = false end
    if db.SpellAlertSpellIDs == nil then db.SpellAlertSpellIDs = "" end
    if db.SpellAlertDuration == nil then db.SpellAlertDuration = 2 end
    if db.SpellAlertPosX == nil then db.SpellAlertPosX = 0 end
    if db.SpellAlertPosY == nil then db.SpellAlertPosY = 90 end
    if db.SpellAlertIconSize == nil then db.SpellAlertIconSize = 44 end
    if db.SpellAlertSound == nil then db.SpellAlertSound = "None" end
    if db.SpellAlertText == nil then db.SpellAlertText = "%spell" end
    if db.SetKey == nil then db.SetKey = false end
    if db.SetKeySide == nil then db.SetKeySide = "LEFT" end
    if db.SetKeyOffsetX == nil then db.SetKeyOffsetX = -8 end
    if db.SetKeyOffsetY == nil then db.SetKeyOffsetY = 0 end

    return db
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
local MythicCore = RRT_NS.Mythic or _G.RRTMythicTools
local ExtrasFrame = CreateFrame("Frame", "RRT_ToolsExtrasFrame")
local NoMoveFrame, NoMoveText
local FocusFrame, FocusBar, FocusText, FocusTimer, FocusTarget, FocusIcon
local CastSequenceFrame, CastSequenceIcons = nil, {}
local SpellAlertFrame
local SetKeyFrame
local setKeyHooked = false
local castSequenceEntries = {}
local spellAlertDisplays = {}
local focusSoundToken = 0

local function CopyDefaults(target, defaults)
    target = target or {}
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = CopyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

local function GetSpellAlertDefaultRule()
    return {
        enabled = false,
        name = "New Alert",
        trigger = {
            type = "spell",
            spellID = 0,
            stateKey = "PStat_Haste",
            condition = "increase",
            threshold = 0,
            margin = 0.1,
            delay = 0,
        },
        load = {
            inCombat = nil,
            inInstance = nil,
            instanceTypes = {},
            specIDs = {},
            classIDs = {},
            inGroup = nil,
        },
        display = {
            type = "icon",
            iconID = 0,
            text = "%spell",
            width = 44,
            height = 44,
            posX = 0,
            posY = 90,
            duration = 2,
            reverse = false,
            barTexture = "Interface\\TargetingFrame\\UI-StatusBar",
            barColor = { 1, 0.75, 0.1, 1 },
            textColor = { 1, 1, 1, 1 },
            fontSize = 26,
            glow = "none",
            sound = "None",
        },
    }
end

local function EnsureSpellAlertRules(db)
    if type(db.SpellAlertRules) ~= "table" or #db.SpellAlertRules == 0 then
        local migrated = GetSpellAlertDefaultRule()
        migrated.enabled = db.SpellAlert == true
        migrated.name = "Migrated Alert"
        migrated.trigger.spellID = tonumber((db.SpellAlertSpellIDs or ""):match("%d+")) or 0
        migrated.display.text = db.SpellAlertText or "%spell"
        migrated.display.width = db.SpellAlertIconSize or 44
        migrated.display.height = db.SpellAlertIconSize or 44
        migrated.display.posX = db.SpellAlertPosX or 0
        migrated.display.posY = db.SpellAlertPosY or 90
        migrated.display.duration = db.SpellAlertDuration or 2
        migrated.display.sound = db.SpellAlertSound or "None"
        db.SpellAlertRules = { migrated }
    end
    for i, rule in ipairs(db.SpellAlertRules) do
        db.SpellAlertRules[i] = CopyDefaults(rule, GetSpellAlertDefaultRule())
    end
    if db.SpellAlertLegacySync ~= false and #db.SpellAlertRules == 1 then
        local rule = db.SpellAlertRules[1]
        rule.enabled = db.SpellAlert == true
        rule.trigger.type = "spell"
        rule.trigger.spellID = tonumber((db.SpellAlertSpellIDs or ""):match("%d+")) or rule.trigger.spellID
        rule.display.type = "icon"
        rule.display.text = db.SpellAlertText or rule.display.text
        rule.display.width = db.SpellAlertIconSize or rule.display.width
        rule.display.height = db.SpellAlertIconSize or rule.display.height
        rule.display.posX = db.SpellAlertPosX or rule.display.posX
        rule.display.posY = db.SpellAlertPosY or rule.display.posY
        rule.display.duration = db.SpellAlertDuration or rule.display.duration
        rule.display.sound = db.SpellAlertSound or rule.display.sound
    end
    return db.SpellAlertRules
end

local function PlayNamedSound(name)
    if not name or name == "" or name == "None" or not LSM then
        return
    end
    local path = LSM:Fetch("sound", name)
    if path then
        PlaySoundFile(path, "Master")
    end
end

local function PlayNamedSoundOnChannel(name, channel)
    if not name or name == "" or name == "None" or not LSM then
        return
    end
    local path = LSM:Fetch("sound", name)
    if path then
        PlaySoundFile(path, channel or "Master")
    end
end

local function GetCurrentSpecID()
    local specIndex = GetSpecialization and GetSpecialization()
    if not specIndex then
        return nil
    end
    return GetSpecializationInfo(specIndex)
end

local function FormatSeconds(seconds)
    if seconds >= 10 then
        return tostring(math.floor(seconds + 0.5))
    end
    return string.format("%.1f", seconds)
end

local function UpdateSpellOverlayAlpha()
    local db = GetDB()
    if not db.SpellEffectAlpha then
        return
    end
    local specID = GetCurrentSpecID()
    local value = db.SpellEffectAlphaDefault or 100
    if specID and db.SpellEffectAlphaSpecs[specID] ~= nil then
        value = db.SpellEffectAlphaSpecs[specID]
    end
    value = math.max(0, math.min(100, tonumber(value) or 100))
    SetCVar("spellActivationOverlayOpacity", value / 100)
    SetCVar("displaySpellActivationOverlays", value > 0 and 1 or 0)
end

local function EnsureNoMoveFrame()
    if NoMoveFrame then
        return
    end
    NoMoveFrame = CreateFrame("Frame", "RRT_NoMoveSkillAlert", UIParent)
    NoMoveFrame:SetSize(320, 40)
    NoMoveFrame:SetFrameStrata("HIGH")
    NoMoveText = NoMoveFrame:CreateFontString(nil, "OVERLAY")
    NoMoveText:SetPoint("CENTER")
    NoMoveFrame:Hide()
    NoMoveFrame:SetScript("OnUpdate", function(_, elapsed)
        NoMoveFrame._elapsed = (NoMoveFrame._elapsed or 0) + elapsed
        if NoMoveFrame._elapsed < 0.1 then
            return
        end
        NoMoveFrame._elapsed = 0
        local db = GetDB()
        if not db.NoMoveSkillAlert then
            NoMoveFrame:Hide()
            return
        end

        local _, classTag = UnitClass("player")
        local spellID, template = nil, nil
        if classTag == "MAGE" then
            spellID = IsPlayerSpell(212653) and 212653 or 1953
            template = db.NoMoveSkillAlertMageFormat
        elseif classTag == "ROGUE" then
            local specID = GetCurrentSpecID()
            spellID = (specID == 260) and 195457 or 36554
            template = db.NoMoveSkillAlertRogueFormat
        else
            NoMoveFrame:Hide()
            return
        end

        local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(spellID)
        local remaining = info and info.startTime and info.duration and ((info.startTime + info.duration) - GetTime()) or 0
        if not remaining or remaining <= 1.5 or info.isOnGCD then
            NoMoveFrame:Hide()
            return
        end

        NoMoveText:SetText((template or "No movement spell (%t)"):gsub("%%t", FormatSeconds(remaining)))
        NoMoveFrame:Show()
    end)
end

local function RefreshNoMoveAlert()
    EnsureNoMoveFrame()
    local db = GetDB()
    NoMoveFrame:ClearAllPoints()
    NoMoveFrame:SetPoint("CENTER", UIParent, "CENTER", db.NoMoveSkillAlertPosX, db.NoMoveSkillAlertPosY)
    local font = select(1, GameFontNormalLarge:GetFont())
    NoMoveText:SetFont(font or STANDARD_TEXT_FONT, db.NoMoveSkillAlertFontSize, "OUTLINE")
    NoMoveText:SetTextColor(1, 0.95, 0.2, 1)
    NoMoveFrame:SetShown(db.NoMoveSkillAlert)
end

local function EnsureFocusFrame()
    if FocusFrame then
        return
    end
    FocusFrame = CreateFrame("Frame", "RRT_FocusCastFrame", UIParent, "BackdropTemplate")
    FocusFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    FocusFrame:SetBackdropColor(0.02, 0.02, 0.02, 0.7)
    FocusFrame:SetBackdropBorderColor(0.18, 0.18, 0.18, 0.9)
    FocusBar = CreateFrame("StatusBar", nil, FocusFrame)
    FocusBar:SetAllPoints(FocusFrame)
    FocusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    FocusBar:SetMinMaxValues(0, 1)
    FocusBar:SetValue(0)
    FocusIcon = FocusFrame:CreateTexture(nil, "OVERLAY")
    FocusIcon:SetPoint("RIGHT", FocusFrame, "LEFT", -6, 0)
    FocusIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    FocusText = FocusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FocusText:SetPoint("LEFT", FocusFrame, "LEFT", 6, 0)
    FocusText:SetJustifyH("LEFT")
    FocusTimer = FocusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FocusTimer:SetPoint("RIGHT", FocusFrame, "RIGHT", -6, 0)
    FocusTimer:SetJustifyH("RIGHT")
    FocusTarget = FocusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FocusTarget:SetPoint("BOTTOM", FocusFrame, "TOP", 0, 3)
    FocusFrame:Hide()
    FocusFrame:SetScript("OnUpdate", function(self)
        local db = GetDB()
        if not db.FocusCast or not UnitExists("focus") then
            self:Hide()
            return
        end

        local name, _, texture, startMS, endMS, _, _, notInterruptible, spellID = UnitCastingInfo("focus")
        local isChannel = false
        if not name then
            name, _, texture, startMS, endMS, _, notInterruptible, spellID = UnitChannelInfo("focus")
            isChannel = name ~= nil
        end
        if not name or not startMS or not endMS then
            self:Hide()
            return
        end

        local now = GetTime()
        local startTime = startMS / 1000
        local endTime = endMS / 1000
        local duration = math.max(0.01, endTime - startTime)
        local progress = math.max(0, math.min(1, (now - startTime) / duration))
        FocusBar:SetValue(isChannel and (1 - progress) or progress)
        FocusBar:SetStatusBarColor(notInterruptible and 0.75 or 0.95, notInterruptible and 0.2 or 0.7, 0.18, 0.9)
        FocusText:SetText(name)
        FocusTimer:SetText(string.format("%.1f", math.max(0, endTime - now)))
        FocusIcon:SetTexture(texture or C_Spell.GetSpellTexture(spellID or 0))
        if db.FocusCastShowTarget then
            FocusTarget:SetText(UnitName("focustarget") or "")
            FocusTarget:Show()
        else
            FocusTarget:Hide()
        end
        self:Show()
    end)
end

local function RefreshFocusCast()
    EnsureFocusFrame()
    local db = GetDB()
    FocusFrame:SetSize(db.FocusCastWidth, db.FocusCastHeight)
    FocusFrame:ClearAllPoints()
    FocusFrame:SetPoint("CENTER", UIParent, "CENTER", db.FocusCastPosX, db.FocusCastPosY)
    FocusIcon:SetSize(db.FocusCastHeight + 8, db.FocusCastHeight + 8)
    FocusFrame:SetShown(db.FocusCast and UnitExists("focus"))
end

local function EnsureCastSequenceFrame()
    if CastSequenceFrame then
        return
    end
    CastSequenceFrame = CreateFrame("Frame", "RRT_CastSequenceFrame", UIParent)
    for i = 1, 20 do
        local icon = CreateFrame("Frame", nil, CastSequenceFrame, "BackdropTemplate")
        icon:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        icon.tex = icon:CreateTexture(nil, "ARTWORK")
        icon.tex:SetAllPoints()
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints()
        icon.cooldown:SetHideCountdownNumbers(true)
        icon:Hide()
        CastSequenceIcons[i] = icon
    end
end

local function ParseIgnoredSpells()
    local ignored = {}
    for token in string.gmatch(GetDB().CastSequenceIgnored or "", "[^,%s]+") do
        local id = tonumber(token)
        if id then
            ignored[id] = true
        end
    end
    return ignored
end

local function RefreshCastSequence()
    EnsureCastSequenceFrame()
    local db = GetDB()
    CastSequenceFrame:ClearAllPoints()
    CastSequenceFrame:SetPoint("CENTER", UIParent, "CENTER", db.CastSequencePosX, db.CastSequencePosY)
    local size = db.CastSequenceSize
    local amount = math.max(1, math.min(20, db.CastSequenceAmount or 8))
    for i, icon in ipairs(CastSequenceIcons) do
        icon:SetSize(size, size)
        icon:ClearAllPoints()
        local step = (size + 2) * (i - 1)
        if db.CastSequenceGrow == "LEFT" then
            icon:SetPoint("RIGHT", CastSequenceFrame, "RIGHT", -step, 0)
        else
            icon:SetPoint("LEFT", CastSequenceFrame, "LEFT", step, 0)
        end
        icon:SetShown(db.CastSequence and i <= amount and castSequenceEntries[i] ~= nil)
        if castSequenceEntries[i] then
            icon.tex:SetTexture(castSequenceEntries[i].icon)
        end
    end
    CastSequenceFrame:SetSize((size + 2) * amount, size)
    CastSequenceFrame:SetShown(db.CastSequence)
end

local function PushCastSequence(spellID)
    local ignored = ParseIgnoredSpells()
    if ignored[spellID] then
        return
    end
    local info = C_Spell.GetSpellInfo(spellID)
    if not info then
        return
    end
    table.insert(castSequenceEntries, 1, { spellID = spellID, icon = info.iconID, at = GetTime() })
    while #castSequenceEntries > 20 do
        table.remove(castSequenceEntries)
    end
    RefreshCastSequence()
end

local function EnsureSpellAlertFrame()
    if SpellAlertFrame then
        return
    end
    SpellAlertFrame = CreateFrame("Frame", "RRT_SpellAlertAnchor", UIParent)
    SpellAlertFrame:Hide()
end

local function GetSpellAlertDisplay(index)
    EnsureSpellAlertFrame()
    if spellAlertDisplays[index] then
        return spellAlertDisplays[index]
    end

    local frame = CreateFrame("Frame", "RRT_SpellAlertDisplay" .. index, UIParent, "BackdropTemplate")
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.02, 0.02, 0.02, 0.75)
    frame:SetBackdropBorderColor(0.18, 0.18, 0.18, 0.9)
    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.timer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar.bg = frame.bar:CreateTexture(nil, "BACKGROUND")
    frame.bar.bg:SetAllPoints()
    frame.bar.bg:SetColorTexture(0, 0, 0, 0.35)
    frame.bar:SetMinMaxValues(0, 1)
    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()
    frame.cooldown:SetHideCountdownNumbers(true)
    frame:Hide()
    spellAlertDisplays[index] = frame
    return frame
end

local function StopSpellAlertGlow(frame)
    if not frame or not LCG then
        return
    end
    LCG.ButtonGlow_Stop(frame)
    LCG.PixelGlow_Stop(frame)
    LCG.AutoCastGlow_Stop(frame)
    if LCG.ProcGlow_Stop then
        LCG.ProcGlow_Stop(frame)
    end
end

local function StartSpellAlertGlow(frame, glowType)
    if not frame or not LCG or not glowType or glowType == "none" then
        return
    end
    StopSpellAlertGlow(frame)
    if glowType == "pixel" then
        LCG.PixelGlow_Start(frame, { 1, 0.82, 0.2, 1 }, 8, 0.2, nil, 1)
    elseif glowType == "autocast" then
        LCG.AutoCastGlow_Start(frame, { 1, 0.82, 0.2, 1 }, 8, 0.2, 1)
    else
        LCG.ButtonGlow_Start(frame, { 1, 0.82, 0.2, 1 }, 0.2)
    end
end

local function EvaluateSpellAlertLoad(rule)
    local state = MythicCore and MythicCore.State
    if not state then
        return true
    end
    local load = rule.load or {}
    if load.inCombat ~= nil and load.inCombat ~= state.InCombat then
        return false
    end
    if load.inInstance ~= nil and load.inInstance ~= state.InInstance then
        return false
    end
    if load.inGroup ~= nil then
        local currentGroup = state.IsInRaid and "raid" or (state.IsInParty and "party" or "solo")
        if load.inGroup ~= currentGroup then
            return false
        end
    end
    if load.instanceTypes and #load.instanceTypes > 0 then
        local ok = false
        for _, instanceType in ipairs(load.instanceTypes) do
            if instanceType == state.InstanceType then
                ok = true
                break
            end
        end
        if not ok then
            return false
        end
    end
    if load.specIDs and #load.specIDs > 0 then
        local ok = false
        for _, specID in ipairs(load.specIDs) do
            if tonumber(specID) == tonumber(state.SpecID) then
                ok = true
                break
            end
        end
        if not ok then
            return false
        end
    end
    if load.classIDs and #load.classIDs > 0 then
        local ok = false
        for _, classID in ipairs(load.classIDs) do
            if tonumber(classID) == tonumber(state.ClassID) then
                ok = true
                break
            end
        end
        if not ok then
            return false
        end
    end
    return true
end

local function HideSpellAlertDisplay(index)
    local frame = spellAlertDisplays[index]
    if not frame then
        return
    end
    frame:SetScript("OnUpdate", nil)
    StopSpellAlertGlow(frame)
    frame:Hide()
end

local function BuildSpellAlertText(rule, spellInfo)
    local template = ((rule.display or {}).text or "%spell")
    return template:gsub("%%spell", (spellInfo and spellInfo.name) or "")
end

local function PlaySpellAlertRule(index, spellID)
    local db = GetDB()
    local rules = EnsureSpellAlertRules(db)
    local rule = rules[index]
    if not rule or not db.SpellAlert or not rule.enabled or not EvaluateSpellAlertLoad(rule) then
        return
    end

    local display = rule.display or {}
    local frame = GetSpellAlertDisplay(index)
    local spellInfo = spellID and C_Spell.GetSpellInfo(spellID) or nil
    local iconID = tonumber(display.iconID) and tonumber(display.iconID) > 0 and tonumber(display.iconID) or (spellInfo and spellInfo.iconID) or 136243
    local width = tonumber(display.width) or 44
    local height = tonumber(display.height) or 44
    local duration = math.max(0.05, tonumber(display.duration) or 2)
    local displayType = display.type or "icon"
    local textColor = display.textColor or { 1, 1, 1, 1 }

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", tonumber(display.posX) or 0, tonumber(display.posY) or 90)
    frame:SetSize(math.max(width, 140), math.max(height, 24))
    frame.icon:SetTexture(iconID)
    frame.icon:SetSize(height, height)
    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.text:SetFont(select(1, GameFontNormalLarge:GetFont()) or STANDARD_TEXT_FONT, tonumber(display.fontSize) or 26, "OUTLINE")
    frame.text:SetTextColor(textColor[1] or 1, textColor[2] or 1, textColor[3] or 1, textColor[4] or 1)
    frame.text:SetText(BuildSpellAlertText(rule, spellInfo))
    frame.text:ClearAllPoints()
    frame.timer:ClearAllPoints()
    frame.cooldown:Hide()
    frame.bar:Hide()
    frame.text:Hide()
    frame.timer:Hide()
    StopSpellAlertGlow(frame)

    if displayType == "text" then
        frame.icon:Hide()
        frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.text:Show()
    elseif displayType == "bar" then
        local barColor = display.barColor or { 1, 0.75, 0.1, 1 }
        frame.icon:Show()
        frame.bar:SetAllPoints(frame)
        frame.bar:SetStatusBarTexture(display.barTexture or "Interface\\TargetingFrame\\UI-StatusBar")
        frame.bar:SetStatusBarColor(barColor[1] or 1, barColor[2] or 0.75, barColor[3] or 0.1, barColor[4] or 1)
        frame.bar:SetValue(display.reverse and 0 or 1)
        frame.bar:Show()
        frame.text:SetPoint("LEFT", frame, "LEFT", height + 8, 0)
        frame.timer:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
        frame.text:Show()
        frame.timer:Show()
    else
        frame.icon:Show()
        frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 8, 0)
        frame.text:Show()
        frame.cooldown:Show()
        frame.cooldown:SetReverse(display.reverse == true)
        frame.cooldown:SetCooldown(GetTime(), duration)
    end

    StartSpellAlertGlow(frame, display.glow)
    PlayNamedSoundOnChannel(display.sound, "Master")
    frame:Show()
    frame._expireAt = GetTime() + duration
    frame:SetScript("OnUpdate", function(self)
        local remaining = (self._expireAt or 0) - GetTime()
        if remaining <= 0 then
            HideSpellAlertDisplay(index)
            return
        end
        if displayType == "bar" then
            local progress = math.max(0, math.min(1, remaining / duration))
            self.bar:SetValue(display.reverse and (1 - progress) or progress)
            self.timer:SetText(string.format("%.1f", remaining))
        elseif displayType == "text" then
            self.text:SetAlpha(math.min(1, remaining / math.max(0.2, duration)))
        end
    end)
end

local function RefreshSpellAlertLoadTriggers()
    local db = GetDB()
    local rules = EnsureSpellAlertRules(db)
    for index, rule in ipairs(rules) do
        local trigger = rule.trigger or {}
        if rule.enabled and db.SpellAlert and EvaluateSpellAlertLoad(rule) then
            if trigger.type == "always" then
                PlaySpellAlertRule(index, nil)
            elseif trigger.type == "onload" and not rule._rrtOnLoadFired then
                rule._rrtOnLoadFired = true
                local delay = math.max(0, tonumber(trigger.delay) or 0)
                if delay > 0 then
                    C_Timer.After(delay, function()
                        PlaySpellAlertRule(index, nil)
                    end)
                else
                    PlaySpellAlertRule(index, nil)
                end
            end
        else
            rule._rrtOnLoadFired = false
            if trigger.type == "always" then
                HideSpellAlertDisplay(index)
            end
        end
    end
end

local function EvaluateSpellAlertStateRules(changedKey, newValue, oldValue)
    local db = GetDB()
    local rules = EnsureSpellAlertRules(db)
    if not db.SpellAlert then
        return
    end
    for index, rule in ipairs(rules) do
        local trigger = rule.trigger or {}
        if rule.enabled and trigger.type == "state" and trigger.stateKey == changedKey and EvaluateSpellAlertLoad(rule) then
            local threshold = tonumber(trigger.threshold) or 0
            local margin = tonumber(trigger.margin) or 0.1
            local previous = tonumber(oldValue) or 0
            local current = tonumber(newValue) or 0
            local hit = false
            if trigger.condition == "decrease" then
                hit = previous > threshold and current <= (threshold * (1 + margin))
            else
                hit = previous < threshold and current >= (threshold * (1 - margin))
            end
            if hit then
                local delay = math.max(0, tonumber(trigger.delay) or 0)
                if delay > 0 then
                    C_Timer.After(delay, function()
                        PlaySpellAlertRule(index, nil)
                    end)
                else
                    PlaySpellAlertRule(index, nil)
                end
            end
        end
    end
end

local function RefreshSpellAlert()
    local db = GetDB()
    EnsureSpellAlertRules(db)
    if not db.SpellAlert then
        for index in pairs(spellAlertDisplays) do
            HideSpellAlertDisplay(index)
        end
    end
end

local function TriggerSpellAlert(spellID)
    local db = GetDB()
    local rules = EnsureSpellAlertRules(db)
    if not db.SpellAlert then
        return
    end
    for index, rule in ipairs(rules) do
        local trigger = rule.trigger or {}
        if rule.enabled and trigger.type == "spell" and tonumber(trigger.spellID) == tonumber(spellID) then
            local delay = math.max(0, tonumber(trigger.delay) or 0)
            if delay > 0 then
                C_Timer.After(delay, function()
                    PlaySpellAlertRule(index, spellID)
                end)
            else
                PlaySpellAlertRule(index, spellID)
            end
        end
    end
end

local function BuildSetKeyFrame()
    if SetKeyFrame or not IsBetaBuild or not IsBetaBuild() then
        return
    end
    SetKeyFrame = CreateFrame("Frame", "RRT_SetKeyFrame", UIParent, "BackdropTemplate")
    SetKeyFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    SetKeyFrame:SetBackdropColor(0.04, 0.04, 0.04, 0.9)
    SetKeyFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    SetKeyFrame:SetSize(264, 118)
    SetKeyFrame.title = SetKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetKeyFrame.title:SetPoint("TOP", 0, -8)
    SetKeyFrame.title:SetText("RRT Beta Keystone")
    SetKeyFrame.current = SetKeyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    SetKeyFrame.current:SetPoint("TOPLEFT", 10, -28)
    SetKeyFrame.levelButtons = {}
    local levels = { 10, 12, 14, 16, 18 }
    for i, level in ipairs(levels) do
        local btn = CreateFrame("Button", nil, SetKeyFrame, "SecureActionButtonTemplate,UIPanelButtonTemplate")
        btn:SetSize(42, 20)
        btn:SetPoint("TOPLEFT", 10 + (i - 1) * 48, -52)
        btn:SetText(level)
        btn:RegisterForClicks("AnyUp")
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", "/run if C_MythicPlus and C_MythicPlus.SetOwnedKeystoneLevel then C_MythicPlus.SetOwnedKeystoneLevel(" .. level .. ") end")
        SetKeyFrame.levelButtons[i] = btn
    end
    SetKeyFrame:Hide()
end

local function UpdateSetKeyVisibility()
    if not SetKeyFrame then
        BuildSetKeyFrame()
    end
    if not SetKeyFrame then
        return
    end
    local db = GetDB()
    if not db.SetKey or not IsBetaBuild or not IsBetaBuild() or not PVEFrame or not PVEFrame:IsShown() then
        SetKeyFrame:Hide()
        return
    end
    local selectedTab = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(PVEFrame)
    if selectedTab ~= 3 then
        SetKeyFrame:Hide()
        return
    end
    SetKeyFrame:ClearAllPoints()
    if db.SetKeySide == "RIGHT" then
        SetKeyFrame:SetPoint("TOPLEFT", PVEFrame, "TOPRIGHT", db.SetKeyOffsetX, db.SetKeyOffsetY)
    else
        SetKeyFrame:SetPoint("TOPRIGHT", PVEFrame, "TOPLEFT", db.SetKeyOffsetX, db.SetKeyOffsetY)
    end
    local mapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()
    if mapID and level and mapID > 0 and level > 0 then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        SetKeyFrame.current:SetText(string.format("Current: %s (%d)", name or "Unknown", level))
    else
        SetKeyFrame.current:SetText("Current: none")
    end
    SetKeyFrame:Show()
end

local function HookPVEFrame()
    if setKeyHooked or not PVEFrame then
        return
    end
    setKeyHooked = true
    PVEFrame:HookScript("OnShow", UpdateSetKeyVisibility)
    PVEFrame:HookScript("OnHide", UpdateSetKeyVisibility)
    if PVEFrame_ShowFrame then
        hooksecurefunc("PVEFrame_ShowFrame", UpdateSetKeyVisibility)
    end
end

local function InitExtras()
    ExtrasFrame:RegisterEvent("ADDON_LOADED")
    ExtrasFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    ExtrasFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ExtrasFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    ExtrasFrame:RegisterEvent("UNIT_SPELLCAST_START")
    ExtrasFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    ExtrasFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
    ExtrasFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    ExtrasFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    ExtrasFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    ExtrasFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
    ExtrasFrame:RegisterEvent("ITEM_CHANGED")
    HookPVEFrame()
    if MythicCore and MythicCore.WatchState then
        for _, key in ipairs({
            "InCombat", "InInstance", "InstanceType", "SpecID", "ClassID", "IsInParty", "IsInRaid",
            "PStat_Haste", "PStat_Crit", "PStat_Mastery", "PStat_Versa", "PStat_Str", "PStat_Agi", "PStat_Int",
        }) do
            MythicCore:WatchState(key, "RRT_NATIVE_SPELL_ALERT_" .. key, function(newValue, oldValue)
                EvaluateSpellAlertStateRules(key, newValue, oldValue)
                RefreshSpellAlertLoadTriggers()
            end)
        end
    end
    RefreshNoMoveAlert()
    RefreshFocusCast()
    RefreshCastSequence()
    RefreshSpellAlert()
    RefreshSpellAlertLoadTriggers()
    UpdateSpellOverlayAlpha()
    UpdateSetKeyVisibility()
end

ExtrasFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        HookPVEFrame()
        UpdateSpellOverlayAlpha()
        UpdateSetKeyVisibility()
        RefreshSpellAlertLoadTriggers()
    elseif event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_GroupFinder" then
            HookPVEFrame()
            UpdateSetKeyVisibility()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        UpdateSpellOverlayAlpha()
    elseif event == "PLAYER_FOCUS_CHANGED" then
        RefreshFocusCast()
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit = ...
        if unit == "focus" then
            local db = GetDB()
            focusSoundToken = focusSoundToken + 1
            if db.FocusCast then
                PlayNamedSound(db.FocusCastSound)
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then
            PushCastSequence(spellID)
            TriggerSpellAlert(spellID)
        end
    elseif event == "CHALLENGE_MODE_MAPS_UPDATE" or event == "ITEM_CHANGED" then
        UpdateSetKeyVisibility()
    end
end)

local previousInit = Tools.Init
Tools.Init = function(...)
    if previousInit then
        previousInit(...)
    end
    InitExtras()
end

local previousRefreshAll = Tools.RefreshAll
Tools.RefreshAll = function(...)
    if previousRefreshAll then
        previousRefreshAll(...)
    end
    RefreshNoMoveAlert()
    RefreshFocusCast()
    RefreshCastSequence()
    RefreshSpellAlert()
    RefreshSpellAlertLoadTriggers()
    UpdateSpellOverlayAlpha()
    UpdateSetKeyVisibility()
end

Tools.GetSpellAlertRules = function()
    return EnsureSpellAlertRules(GetDB())
end

Tools.GetSpellAlertDefaultRule = GetSpellAlertDefaultRule

Tools.NotifySpellAlertChanged = function()
    RefreshSpellAlert()
    RefreshSpellAlertLoadTriggers()
end

Tools.RefreshNoMoveAlert = RefreshNoMoveAlert
Tools.RefreshFocusCast = RefreshFocusCast
Tools.RefreshCastSequence = RefreshCastSequence
Tools.RefreshSpellAlert = RefreshSpellAlert
Tools.UpdateSpellOverlayAlpha = UpdateSpellOverlayAlpha
Tools.UpdateSetKeyVisibility = UpdateSetKeyVisibility

RRT_NS.Tools = Tools
