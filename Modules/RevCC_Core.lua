-- =====================================================================
-- [[ RevCC_Core — Shared utilities ported from MiniCC by Jaliborc ]]
-- Provides: FontUtil, WoWEx, SlotDistribution, InstanceOptions,
--           UnitAuraWatcher, IconSlotContainer
-- =====================================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

InfinityTools.RevCC = InfinityTools.RevCC or {}
local MCC = InfinityTools.RevCC

-- =====================================================================
-- SECTION 1: FontUtil
-- =====================================================================

local FontUtil_M = {}
MCC.FontUtil = FontUtil_M

--- Updates the cooldown frame's countdown text font size based on icon size
function FontUtil_M:UpdateCooldownFontSize(cd, iconSize, coefficient, fontScale)
    if not cd or not iconSize then
        return
    end

    coefficient = coefficient or 0.4
    fontScale = fontScale or 1.0

    local fontSize = math.floor(iconSize * coefficient * fontScale)

    if not cd.InfinityCCFontString then
        local numRegions = cd:GetNumRegions()
        for i = 1, numRegions do
            local region = select(i, cd:GetRegions())
            if region and region:GetObjectType() == "FontString" then
                cd.InfinityCCFontString = region
                break
            end
        end
    end

    local region = cd.InfinityCCFontString
    if region then
        local font, _, flags = region:GetFont()
        if font then
            region:SetFont(font, fontSize, flags)
        end
    end
end

-- =====================================================================
-- SECTION 2: WoWEx
-- =====================================================================

local WoWEx_M = {}
MCC.WoWEx = WoWEx_M

function WoWEx_M:IsAddOnEnabled(addonName)
    return C_AddOns.GetAddOnEnableState(addonName, UnitName("player")) == 2
end

function WoWEx_M:IsDandersEnabled()
    return WoWEx_M:IsAddOnEnabled("DandersFrames")
end

---Creates and populates a DurationObject from a start time and duration.
function WoWEx_M:CreateDuration(startTime, duration, modRate)
    local d = C_DurationUtil.CreateDuration()
    d:SetTimeFromStart(startTime, duration, modRate)
    return d
end

-- =====================================================================
-- SECTION 3: SlotDistribution
-- =====================================================================

local SlotDistribution_M = {}
MCC.SlotDistribution = SlotDistribution_M

---Calculate slot distribution across CC, Defensive, and Important categories.
function SlotDistribution_M.Calculate(containerCount, ccCount, defensiveCount, importantCount)
    local ccSlots, defensiveSlots, importantSlots = 0, 0, 0

    local activeCategories = 0
    if ccCount > 0 then
        activeCategories = activeCategories + 1
    end
    if defensiveCount > 0 then
        activeCategories = activeCategories + 1
    end
    if importantCount > 0 then
        activeCategories = activeCategories + 1
    end

    if activeCategories == 0 then
        return 0, 0, 0
    end

    if containerCount >= activeCategories then
        if ccCount > 0 then
            ccSlots = 1
        end
        if defensiveCount > 0 then
            defensiveSlots = 1
        end
        if importantCount > 0 then
            importantSlots = 1
        end

        local remaining = containerCount - activeCategories

        while remaining > 0 do
            local allocated = false

            if ccCount > ccSlots then
                ccSlots = ccSlots + 1
                remaining = remaining - 1
                allocated = true
            end
            if defensiveCount > defensiveSlots and remaining > 0 then
                defensiveSlots = defensiveSlots + 1
                remaining = remaining - 1
                allocated = true
            end
            if importantCount > importantSlots and remaining > 0 then
                importantSlots = importantSlots + 1
                remaining = remaining - 1
                allocated = true
            end

            if not allocated then
                break
            end
        end
    else
        local remaining = containerCount

        while remaining > 0 do
            local allocated = false

            if ccCount > ccSlots then
                ccSlots = ccSlots + 1
                remaining = remaining - 1
                allocated = true
            end
            if defensiveCount > defensiveSlots and remaining > 0 then
                defensiveSlots = defensiveSlots + 1
                remaining = remaining - 1
                allocated = true
            end
            if importantCount > importantSlots and remaining > 0 then
                importantSlots = importantSlots + 1
                remaining = remaining - 1
                allocated = true
            end

            if not allocated then
                break
            end
        end
    end

    return ccSlots, defensiveSlots, importantSlots
end

-- =====================================================================
-- SECTION 4: InstanceOptions
-- =====================================================================

local InstanceOptions_M = {}
MCC.InstanceOptions = InstanceOptions_M

local testIsRaid = nil

---Returns true if the current context is a raid/large group (>5 members).
function InstanceOptions_M:IsRaid()
    if testIsRaid ~= nil then
        return testIsRaid
    end
    return GetNumGroupMembers() > 5
end

function InstanceOptions_M:SetTestIsRaid(isRaid)
    testIsRaid = isRaid
end

-- =====================================================================
-- SECTION 5: UnitAuraWatcher
-- =====================================================================

local UnitAuraWatcher_M = {}
MCC.UnitAuraWatcher = UnitAuraWatcher_M

-- Dispel type color mapping
local dispelColours = {
    -- https://wago.tools/db2/SpellDispelType
    [0]  = DEBUFF_TYPE_NONE_COLOR,
    [1]  = DEBUFF_TYPE_MAGIC_COLOR,
    [2]  = DEBUFF_TYPE_CURSE_COLOR,
    [3]  = DEBUFF_TYPE_DISEASE_COLOR,
    [4]  = DEBUFF_TYPE_POISON_COLOR,
    [11] = DEBUFF_TYPE_BLEED_COLOR,
}
local dispelColorCurve

local issecretvalue = _G.issecretvalue or function() return false end
local UnitExists    = _G.UnitExists
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost

local function InitColourCurve()
    if dispelColorCurve then
        return
    end

    dispelColorCurve = C_CurveUtil.CreateColorCurve()
    dispelColorCurve:SetType(Enum.LuaCurveType.Step)

    for type, colour in pairs(dispelColours) do
        dispelColorCurve:AddPoint(type, colour)
    end
end

local function NotifyCallbacks(watcher)
    local callbacks = watcher.State.Callbacks

    if not callbacks or #callbacks == 0 then
        return
    end

    for _, callback in ipairs(callbacks) do
        callback(watcher)
    end
end

local function InterestedIn(watcher, updateInfo)
    if not updateInfo or updateInfo.isFullUpdate then
        return true
    end

    local state = watcher.State
    local unit = state.Unit
    local activeFilters = state.ActiveFilters

    if updateInfo.addedAuras then
        for _, aura in pairs(updateInfo.addedAuras) do
            local id = aura.auraInstanceID
            if id then
                for _, filter in ipairs(activeFilters) do
                    if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, filter) then
                        return true
                    end
                end
            end
        end
    end

    if updateInfo.updatedAuraInstanceIDs then
        for _, id in pairs(updateInfo.updatedAuraInstanceIDs) do
            if id then
                for _, filter in ipairs(activeFilters) do
                    if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, filter) then
                        return true
                    end
                end
            end
        end
    end

    if updateInfo.removedAuraInstanceIDs and next(updateInfo.removedAuraInstanceIDs) ~= nil then
        local ccState  = state.CcAuraState
        local defState = state.DefensiveState
        local impState = state.ImportantAuraState
        for _, id in pairs(updateInfo.removedAuraInstanceIDs) do
            for _, aura in ipairs(ccState) do
                if aura.AuraInstanceID == id then return true end
            end
            for _, aura in ipairs(defState) do
                if aura.AuraInstanceID == id then return true end
            end
            for _, aura in ipairs(impState) do
                if aura.AuraInstanceID == id then return true end
            end
        end
    end

    return false
end

local function WatcherFrameOnEvent(frame, event, ...)
    local watcher = frame.Watcher
    if not watcher then
        return
    end
    watcher:OnEvent(event, ...)
end

local Watcher = {}
Watcher.__index = Watcher

function Watcher:GetUnit()
    return self.State.Unit
end

function Watcher:RegisterCallback(callback)
    if not callback then
        return
    end
    self.State.Callbacks[#self.State.Callbacks + 1] = callback
end

function Watcher:IsEnabled()
    return self.State.Enabled
end

function Watcher:Enable()
    if self.State.Enabled then
        return
    end

    local frame = self.Frame
    if not frame then
        return
    end

    frame:RegisterUnitEvent("UNIT_AURA", self.State.Unit)

    if self.State.Events then
        for _, event in ipairs(self.State.Events) do
            frame:RegisterEvent(event)
        end
    end

    self.State.Enabled = true
end

function Watcher:Disable()
    if not self.State.Enabled then
        return
    end

    local frame = self.Frame
    if frame then
        frame:UnregisterAllEvents()
    end

    self.State.Enabled = false
end

function Watcher:ClearState(notify)
    local state = self.State
    state.CcAuraState = {}
    state.ImportantAuraState = {}
    state.DefensiveState = {}

    if notify then
        NotifyCallbacks(self)
    end
end

function Watcher:ForceFullUpdate()
    self:OnEvent("UNIT_AURA", self.State.Unit, { isFullUpdate = true })
end

function Watcher:Dispose()
    local frame = self.Frame
    if frame then
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
        frame.Watcher = nil
    end
    self.Frame = nil

    self.State.Callbacks = {}
    self:ClearState(false)
end

function Watcher:GetCcState()
    local unit = self.State.Unit
    if not unit or not UnitExists(unit) or UnitIsDeadOrGhost(unit) then
        return {}
    end
    return self.State.CcAuraState
end

function Watcher:GetImportantState()
    local unit = self.State.Unit
    if not unit or not UnitExists(unit) or UnitIsDeadOrGhost(unit) then
        return {}
    end
    return self.State.ImportantAuraState
end

function Watcher:GetDefensiveState()
    local unit = self.State.Unit
    if not unit or not UnitExists(unit) or UnitIsDeadOrGhost(unit) then
        return {}
    end
    return self.State.DefensiveState
end

local function IterateAuras(unit, filter, sortRule, sortDirection, callback)
    local auras = C_UnitAuras.GetUnitAuras(unit, filter, nil, sortRule, sortDirection)

    for _, auraData in ipairs(auras) do
        local durationInfo = C_UnitAuras.GetAuraDuration(unit, auraData.auraInstanceID)

        if durationInfo then
            local dispelColor = C_UnitAuras.GetAuraDispelTypeColor(unit, auraData.auraInstanceID, dispelColorCurve)
            callback(auraData, durationInfo, dispelColor)
        end
    end
end

function Watcher:RebuildStates()
    local unit = self.State.Unit

    if not unit then
        return
    end

    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then
        local state = self.State
        local hasState = next(state.CcAuraState) ~= nil
            or next(state.ImportantAuraState) ~= nil
            or next(state.DefensiveState) ~= nil
        if hasState then
            self:ClearState(true)
        end
        return
    end

    local interestedIn = self.State.InterestedIn
    local interestedInDefensives = not interestedIn or (interestedIn and interestedIn.Defensives)
    local interestedInCC = not interestedIn or (interestedIn and interestedIn.CC)
    local interestedInImportant = not interestedIn or (interestedIn and interestedIn.Important)

    local ccSpellData = {}
    local importantSpellData = {}
    local defensivesSpellData = {}
    local seen = {}

    local sortRule = self.State.SortRule
    local sortDirection = self.State.SortDirection

    if interestedInDefensives then
        IterateAuras(unit, "HELPFUL|BIG_DEFENSIVE", sortRule, sortDirection, function(auraData, durationInfo, dispelColor)
            local isDefensive = C_UnitAuras.AuraIsBigDefensive(auraData.spellId)

            if issecretvalue(isDefensive) or isDefensive then
                defensivesSpellData[#defensivesSpellData + 1] = {
                    IsDefensive = isDefensive,
                    SpellId = auraData.spellId,
                    SpellName = auraData.name,
                    SpellIcon = auraData.icon,
                    DurationObject = durationInfo,
                    DispelColor = dispelColor,
                    AuraInstanceID = auraData.auraInstanceID,
                }
            end

            seen[auraData.auraInstanceID] = true
        end)

        IterateAuras(unit, "HELPFUL|EXTERNAL_DEFENSIVE", sortRule, sortDirection, function(auraData, durationInfo, dispelColor)
            if not seen[auraData.auraInstanceID] then
                defensivesSpellData[#defensivesSpellData + 1] = {
                    IsDefensive = true,
                    SpellId = auraData.spellId,
                    SpellName = auraData.name,
                    SpellIcon = auraData.icon,
                    DurationObject = durationInfo,
                    DispelColor = dispelColor,
                    AuraInstanceID = auraData.auraInstanceID,
                }

                seen[auraData.auraInstanceID] = true
            end
        end)
    end

    if interestedInCC then
        IterateAuras(unit, "HARMFUL|CROWD_CONTROL", sortRule, sortDirection, function(auraData, durationInfo, dispelColor)
            local isCC = C_Spell.IsSpellCrowdControl(auraData.spellId)

            if issecretvalue(isCC) or isCC then
                ccSpellData[#ccSpellData + 1] = {
                    IsCC = isCC,
                    SpellId = auraData.spellId,
                    SpellName = auraData.name,
                    SpellIcon = auraData.icon,
                    DurationObject = durationInfo,
                    DispelColor = dispelColor,
                    AuraInstanceID = auraData.auraInstanceID,
                }
            end

            seen[auraData.auraInstanceID] = true
        end)
    end

    if interestedInImportant then
        local importantFilter = (interestedIn and interestedIn.ImportantFilter) or "HELPFUL|IMPORTANT"

        IterateAuras(unit, importantFilter, sortRule, sortDirection, function(auraData, durationInfo, dispelColor)
            if not seen[auraData.auraInstanceID] then
                local isImportant = C_Spell.IsSpellImportant(auraData.spellId)

                if issecretvalue(isImportant) or isImportant then
                    importantSpellData[#importantSpellData + 1] = {
                        IsImportant = isImportant,
                        SpellId = auraData.spellId,
                        SpellName = auraData.name,
                        SpellIcon = auraData.icon,
                        DurationObject = durationInfo,
                        DispelColor = dispelColor,
                        AuraInstanceID = auraData.auraInstanceID,
                    }
                end

                seen[auraData.auraInstanceID] = true
            end
        end)
    end

    if sortRule == Enum.UnitAuraSortRule.Unsorted then
        local reversed = sortDirection == Enum.UnitAuraSortDirection.Reverse
        local byInstanceId = reversed
            and function(a, b) return a.AuraInstanceID > b.AuraInstanceID end
            or  function(a, b) return a.AuraInstanceID < b.AuraInstanceID end
        table.sort(ccSpellData, byInstanceId)
        table.sort(importantSpellData, byInstanceId)
        table.sort(defensivesSpellData, byInstanceId)
    end

    local state = self.State
    state.CcAuraState = ccSpellData
    state.ImportantAuraState = importantSpellData
    state.DefensiveState = defensivesSpellData
end

function Watcher:OnEvent(event, ...)
    local state = self.State

    if event == "UNIT_AURA" then
        local unit, updateInfo = ...
        if unit and unit ~= state.Unit then
            return
        end
        if not InterestedIn(self, updateInfo) then
            return
        end
    elseif event == "ARENA_OPPONENT_UPDATE" then
        local unit = ...
        if unit ~= state.Unit then
            return
        end
    end

    if not state.Unit then
        return
    end

    self:RebuildStates()
    NotifyCallbacks(self)
end

---@param unit string
---@param events string[]?
---@param interestedIn table?
---@param sortRule number?
---@param sortDirection number?
function UnitAuraWatcher_M:New(unit, events, interestedIn, sortRule, sortDirection)
    if not unit then
        error("unit must not be nil")
    end

    -- Lazy-init the colour curve on first watcher creation
    InitColourCurve()

    local all = not interestedIn
    local activeFilters = {}
    if all or interestedIn.Defensives then
        activeFilters[#activeFilters + 1] = "HELPFUL|BIG_DEFENSIVE"
        activeFilters[#activeFilters + 1] = "HELPFUL|EXTERNAL_DEFENSIVE"
    end
    if all or interestedIn.CC then
        activeFilters[#activeFilters + 1] = "HARMFUL|CROWD_CONTROL"
    end
    if all or interestedIn.Important then
        activeFilters[#activeFilters + 1] = (interestedIn and interestedIn.ImportantFilter) or "HELPFUL|IMPORTANT"
    end

    local watcher = setmetatable({
        Frame = nil,
        State = {
            Unit = unit,
            Events = events,
            Enabled = false,
            Callbacks = {},
            CcAuraState = {},
            ImportantAuraState = {},
            DefensiveState = {},
            InterestedIn = interestedIn,
            ActiveFilters = activeFilters,
            SortRule = sortRule or Enum.UnitAuraSortRule.Unsorted,
            SortDirection = sortDirection or Enum.UnitAuraSortDirection.Normal,
        },
    }, Watcher)

    local frame = CreateFrame("Frame")
    frame.Watcher = watcher
    frame:SetScript("OnEvent", WatcherFrameOnEvent)

    watcher.Frame = frame
    watcher:Enable()

    watcher:ForceFullUpdate()

    return watcher
end

-- =====================================================================
-- SECTION 6: IconSlotContainer
-- =====================================================================

local LCG    = LibStub and LibStub("LibCustomGlow-1.0", true)
local Masque = LibStub and LibStub("Masque", true)

-- Use FontUtil from Section 1 (defined above in same file scope)
local fontUtil = MCC.FontUtil

local masqueReskinPending = {}
local layoutScratch = {}
local frameIdCounter = 0

local function NextFrameName(frameType)
    frameIdCounter = frameIdCounter + 1
    return "InfinityTools_MCC_" .. frameType .. "_" .. frameIdCounter
end

local IconSlotContainer_M = {}
IconSlotContainer_M.__index = IconSlotContainer_M
MCC.IconSlotContainer = IconSlotContainer_M

-- Fallback DB for IconSlotContainer (replaces mini:GetSavedVars())
local function GetDb()
    return { GlowType = "Proc Glow", DisableSwipe = false }
end

local function ScheduleMasqueReSkin(group)
    if not group or masqueReskinPending[group] then
        return
    end
    masqueReskinPending[group] = true
    C_Timer.After(0, function()
        masqueReskinPending[group] = nil
        group:ReSkin()
    end)
end

local function CreateLayer(parentFrame, level, iconSize, noBorder)
    local f = CreateFrame("Frame", NextFrameName("Layer"), parentFrame)
    f:SetAllPoints()

    if level then
        f:SetFrameLevel(level)
    end

    local icon = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    icon:SetAllPoints()

    local cd = CreateFrame("Cooldown", NextFrameName("Cooldown"), f, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(false)
    cd:SetDrawBling(false)
    cd:SetHideCountdownNumbers(false)
    cd:SetSwipeColor(0, 0, 0, 0.8)

    local border
    if not noBorder then
        border = f:CreateTexture(nil, "OVERLAY")
        border:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
        border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        border:Hide()
    end

    if iconSize then
        cd.DesiredIconSize = iconSize
        cd.FontScale = 1.0
        fontUtil:UpdateCooldownFontSize(cd, iconSize, nil, cd.FontScale)
    end

    return { Frame = f, Border = border, Icon = icon, Cooldown = cd }
end

local function EnsureContainer(slot, iconSize, group, noBorder)
    if slot.Container then
        return slot.Container
    end

    local slotLevel = slot.Frame:GetFrameLevel() or 0
    slot.Container = CreateLayer(slot.Frame, slotLevel + 1, iconSize, noBorder)

    if group then
        group:AddButton(slot.Container.Frame, {
            Icon = slot.Container.Icon,
            Cooldown = slot.Container.Cooldown,
        })
    end

    return slot.Container
end

local function EnsureExtraLayer(slot, layerIndex, iconSize)
    local extraIdx = layerIndex - 1
    if not slot.ExtraLayers then
        slot.ExtraLayers = {}
    end

    local slotLevel = slot.Frame:GetFrameLevel() or 0
    local baseLevel = slotLevel + 1

    for l = #slot.ExtraLayers + 1, extraIdx do
        slot.ExtraLayers[l] = CreateLayer(slot.Frame, baseLevel + l * 2, iconSize)
    end

    if slot.LastExtraBaseLevel ~= baseLevel then
        slot.LastExtraBaseLevel = baseLevel
        for l = 1, #slot.ExtraLayers do
            local el = slot.ExtraLayers[l]
            if el and el.Frame then
                el.Frame:SetFrameLevel(baseLevel + l * 2)
            end
        end
    end

    return slot.ExtraLayers[extraIdx]
end

local function ApplyAlpha(target, alpha)
    if type(alpha) == "number" then
        target:SetAlpha(alpha)
    else
        target:SetAlphaFromBoolean(alpha)
    end
end

local function EnsureFlipbookGlow(parent)
    if parent._FlipbookGlow then
        return parent._FlipbookGlow
    end

    local cg = CreateFrame("Frame", NextFrameName("FlipbookGlow"), parent)
    cg:SetFrameLevel(parent:GetFrameLevel() + 5)

    cg.Texture = cg:CreateTexture(nil, "OVERLAY")
    cg.Texture:SetTexture("Interface\\AddOns\\InfinityTools\\Media\\FlipbookWhite.tga")
    cg.Texture:SetAllPoints()
    cg.Texture:SetBlendMode("ADD")

    cg.Anim = cg:CreateAnimationGroup()
    cg.Anim:SetLooping("REPEAT")
    local flip = cg.Anim:CreateAnimation("FlipBook")
    flip:SetChildKey("Texture")
    flip:SetFlipBookRows(6)
    flip:SetFlipBookColumns(5)
    flip:SetFlipBookFrames(30)
    flip:SetDuration(1.0)
    cg.Anim:Play()

    parent:HookScript("OnSizeChanged", function(self, width)
        if self._FlipbookGlow then
            local padding = width / 3
            self._FlipbookGlow:SetPoint("TOPLEFT", self, "TOPLEFT", -padding, padding)
            self._FlipbookGlow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", padding, -padding)
        end
    end)

    local width = parent:GetWidth()
    local initPadding = (width and width > 0) and (width / 3) or 9
    cg:SetPoint("TOPLEFT", parent, "TOPLEFT", -initPadding, initPadding)
    cg:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", initPadding, -initPadding)

    cg:Hide()
    parent._FlipbookGlow = cg
    return cg
end

local function ClearLayerData(layer, glowFrame)
    if not layer then
        return
    end
    layer.Icon:SetTexture(nil)
    layer.Cooldown:Clear()
    if LCG then
        if glowFrame._ProcGlow and LCG.ProcGlow_Stop then
            LCG.ProcGlow_Stop(glowFrame)
        end
        if glowFrame._PixelGlow and LCG.PixelGlow_Stop then
            LCG.PixelGlow_Stop(glowFrame)
        end
        if glowFrame._AutoCastGlow and LCG.AutoCastGlow_Stop then
            LCG.AutoCastGlow_Stop(glowFrame)
        end
    end
    if glowFrame._FlipbookGlow then
        glowFrame._FlipbookGlow:Hide()
    end
end

local function UpdateGlow(layerFrame, options)
    local db = GetDb()
    local glowType = (db and db.GlowType) or "Proc Glow"

    if options.Glow then
        local hasProcGlow     = layerFrame._ProcGlow ~= nil
        local hasPixelGlow    = layerFrame._PixelGlow ~= nil
        local hasAutoCastGlow = layerFrame._AutoCastGlow ~= nil
        local hasCustomGlow   = layerFrame._FlipbookGlow ~= nil

        local colorChanged = false
        local newColorKey = nil

        if options.Color then
            newColorKey = string.format(
                "%.2f_%.2f_%.2f_%.2f",
                options.Color.r or 1,
                options.Color.g or 1,
                options.Color.b or 1,
                options.Color.a or 1
            )
        end

        if not newColorKey or not issecretvalue(newColorKey) then
            if layerFrame._GlowColorKey ~= newColorKey then
                colorChanged = true
                layerFrame._GlowColorKey = newColorKey
            end
        elseif newColorKey and issecretvalue(newColorKey) then
            colorChanged = true
        end

        local needsGlow = false
        if glowType == "Proc Glow" and (not hasProcGlow or colorChanged) then
            needsGlow = true
            if hasPixelGlow and LCG.PixelGlow_Stop then
                LCG.PixelGlow_Stop(layerFrame)
            end
            if hasAutoCastGlow and LCG.AutoCastGlow_Stop then
                LCG.AutoCastGlow_Stop(layerFrame)
            end
            if hasProcGlow and colorChanged and LCG.ProcGlow_Stop then
                LCG.ProcGlow_Stop(layerFrame)
            end
            if hasCustomGlow then
                layerFrame._FlipbookGlow:Hide()
            end
        elseif glowType == "Pixel Glow" and (not hasPixelGlow or colorChanged) then
            needsGlow = true
            if hasProcGlow and LCG.ProcGlow_Stop then
                LCG.ProcGlow_Stop(layerFrame)
            end
            if hasAutoCastGlow and LCG.AutoCastGlow_Stop then
                LCG.AutoCastGlow_Stop(layerFrame)
            end
            if hasPixelGlow and colorChanged and LCG.PixelGlow_Stop then
                LCG.PixelGlow_Stop(layerFrame)
            end
            if hasCustomGlow then
                layerFrame._FlipbookGlow:Hide()
            end
        elseif glowType == "Autocast Shine" and (not hasAutoCastGlow or colorChanged) then
            needsGlow = true
            if hasProcGlow and LCG.ProcGlow_Stop then
                LCG.ProcGlow_Stop(layerFrame)
            end
            if hasPixelGlow and LCG.PixelGlow_Stop then
                LCG.PixelGlow_Stop(layerFrame)
            end
            if hasAutoCastGlow and colorChanged and LCG.AutoCastGlow_Stop then
                LCG.AutoCastGlow_Stop(layerFrame)
            end
            if hasCustomGlow then
                layerFrame._FlipbookGlow:Hide()
            end
        elseif
            glowType == "Rotation Assist"
            and (not hasCustomGlow or colorChanged or not layerFrame._FlipbookGlow:IsShown())
        then
            needsGlow = true
            if hasProcGlow and LCG.ProcGlow_Stop then
                LCG.ProcGlow_Stop(layerFrame)
            end
            if hasPixelGlow and LCG.PixelGlow_Stop then
                LCG.PixelGlow_Stop(layerFrame)
            end
            if hasAutoCastGlow and LCG.AutoCastGlow_Stop then
                LCG.AutoCastGlow_Stop(layerFrame)
            end
        end

        if needsGlow then
            local glowOptions = { startAnim = false }

            if options.Color then
                glowOptions.color = { options.Color.r, options.Color.g, options.Color.b, options.Color.a }
            end

            if glowType == "Pixel Glow" and LCG and LCG.PixelGlow_Start then
                LCG.PixelGlow_Start(layerFrame, glowOptions.color)
            elseif glowType == "Autocast Shine" and LCG and LCG.AutoCastGlow_Start then
                LCG.AutoCastGlow_Start(layerFrame, glowOptions.color)
            elseif glowType == "Rotation Assist" then
                local cg = EnsureFlipbookGlow(layerFrame)
                if options.Color then
                    cg.Texture:SetVertexColor(
                        options.Color.r or 1,
                        options.Color.g or 1,
                        options.Color.b or 1,
                        options.Color.a or 1
                    )
                else
                    cg.Texture:SetVertexColor(1, 1, 1, 1)
                end
                cg:Show()
            else
                if LCG and LCG.ProcGlow_Start then
                    LCG.ProcGlow_Start(layerFrame, glowOptions)
                end
            end
        end

        local alpha = options.Alpha
        if glowType == "Proc Glow" then
            local procGlow = layerFrame._ProcGlow
            if procGlow then
                ApplyAlpha(procGlow, alpha)
            end
        elseif glowType == "Pixel Glow" then
            local pixelGlow = layerFrame._PixelGlow
            if pixelGlow then
                ApplyAlpha(pixelGlow, alpha)
            end
        elseif glowType == "Autocast Shine" then
            local autoCastGlow = layerFrame._AutoCastGlow
            if autoCastGlow then
                ApplyAlpha(autoCastGlow, alpha)
            end
        elseif glowType == "Rotation Assist" then
            if layerFrame._FlipbookGlow then
                ApplyAlpha(layerFrame._FlipbookGlow, alpha)
            end
        end

        if glowType == "Proc Glow" and layerFrame._ProcGlow and LCG and LCG.ProcGlow_Start then
            local glowOptions = { startAnim = false }
            if options.Color then
                glowOptions.color = { options.Color.r, options.Color.g, options.Color.b, options.Color.a }
            end
            LCG.ProcGlow_Start(layerFrame, glowOptions)
        end
    else
        if layerFrame._ProcGlow and LCG and LCG.ProcGlow_Stop then
            LCG.ProcGlow_Stop(layerFrame)
        end
        if layerFrame._PixelGlow and LCG and LCG.PixelGlow_Stop then
            LCG.PixelGlow_Stop(layerFrame)
        end
        if layerFrame._AutoCastGlow and LCG and LCG.AutoCastGlow_Stop then
            LCG.AutoCastGlow_Stop(layerFrame)
        end
        if layerFrame._FlipbookGlow then
            layerFrame._FlipbookGlow:Hide()
        end
        layerFrame._GlowColorKey = nil
    end
end

---Creates a new IconSlotContainer instance
function IconSlotContainer_M:New(parent, count, size, spacing, groupName, noBorder, moduleName)
    local instance = setmetatable({}, IconSlotContainer_M)

    count   = count or 3
    size    = size or 20
    spacing = spacing or 2

    instance.Frame = CreateFrame("Frame", NextFrameName("Container"), parent)
    instance.Frame:SetIgnoreParentScale(true)
    instance.Frame:SetIgnoreParentAlpha(true)
    instance.Slots = {}
    instance.Count = 0
    instance.Size = size
    instance.Spacing = spacing
    instance.NumRows = nil
    instance.RowAlignment = nil
    instance.InvertLayout = false
    instance.NoBorder = noBorder or false
    instance.Frame.InfinityCCModule = moduleName or nil
    instance.MasqueGroup = Masque and groupName and Masque:Group("InfinityTools", groupName) or nil

    instance:SetCount(count)

    return instance
end

function IconSlotContainer_M:Layout()
    local n = 0
    for i = 1, self.Count do
        if self.Slots[i] and self.Slots[i].IsUsed then
            n = n + 1
            layoutScratch[n] = i
        end
    end

    local numRows = (not self.GrowDown and self.NumRows and self.NumRows > 1) and self.NumRows or nil
    local sig = self.Size .. ":" .. (numRows or 1) .. ":" .. (self.RowAlignment or "C") .. ":" .. (self.OverflowRowAlignment or "C") .. ":" .. (self.InvertLayout and "1" or "0") .. ":" .. (self.GrowDown and "D" or "H") .. ":" .. table.concat(layoutScratch, ",", 1, n)
    if self.LayoutSignature == sig then
        return
    end
    self.LayoutSignature = sig

    for i = n + 1, #layoutScratch do
        layoutScratch[i] = nil
    end

    local usedCount = n

    if usedCount == 0 then
        self.Frame:SetSize(self.Size, self.Size)
    elseif numRows then
        local iconsPerRow = math.max(1, math.ceil(usedCount / numRows))
        local actualRows = math.ceil(usedCount / iconsPerRow)
        local rowWidth = iconsPerRow * self.Size + (iconsPerRow - 1) * self.Spacing
        local totalHeight = actualRows * self.Size + (actualRows - 1) * self.Spacing
        self.Frame:SetSize(rowWidth, totalHeight)
        self.Frame:SetAlpha(1)

        local row1Alignment = self.RowAlignment or "CENTER"
        local overflowAlignment = self.OverflowRowAlignment or row1Alignment

        for displayIndex = 1, usedCount do
            local slot = self.Slots[layoutScratch[displayIndex]]
            local rowIndex = math.floor((displayIndex - 1) / iconsPerRow)
            local rawCol = (displayIndex - 1) % iconsPerRow
            local colIndex = self.InvertLayout and (iconsPerRow - 1 - rawCol) or rawCol
            local rowIcons = (rowIndex == actualRows - 1) and (usedCount - (actualRows - 1) * iconsPerRow) or iconsPerRow

            local x
            if self.InvertLayout then
                x = colIndex * (self.Size + self.Spacing) - (rowWidth / 2) + (self.Size / 2)
            else
                local alignment = rowIndex == 0 and row1Alignment or overflowAlignment
                if alignment == "LEFT" then
                    x = colIndex * (self.Size + self.Spacing) - (rowWidth / 2) + (self.Size / 2)
                elseif alignment == "RIGHT" then
                    local shift = (iconsPerRow - rowIcons) * (self.Size + self.Spacing)
                    x = colIndex * (self.Size + self.Spacing) - (rowWidth / 2) + (self.Size / 2) + shift
                else
                    local thisRowWidth = rowIcons * self.Size + (rowIcons - 1) * self.Spacing
                    x = colIndex * (self.Size + self.Spacing) - (thisRowWidth / 2) + (self.Size / 2)
                end
            end
            local y = (totalHeight / 2) - (self.Size / 2) - rowIndex * (self.Size + self.Spacing)

            slot.Frame:ClearAllPoints()
            slot.Frame:SetPoint("CENTER", self.Frame, "CENTER", x, y)
            slot.Frame:SetSize(self.Size, self.Size)
            slot.Frame:Show()
        end
    elseif self.GrowDown then
        local totalHeight = usedCount * self.Size + (usedCount - 1) * self.Spacing
        self.Frame:SetSize(self.Size, totalHeight)
        self.Frame:SetAlpha(1)

        for displayIndex = 1, usedCount do
            local slot = self.Slots[layoutScratch[displayIndex]]
            local y = (totalHeight / 2) - (self.Size / 2) - (displayIndex - 1) * (self.Size + self.Spacing)
            slot.Frame:ClearAllPoints()
            slot.Frame:SetPoint("CENTER", self.Frame, "CENTER", 0, y)
            slot.Frame:SetSize(self.Size, self.Size)
            slot.Frame:Show()
        end
    else
        local totalWidth = usedCount * self.Size + (usedCount - 1) * self.Spacing
        self.Frame:SetSize(totalWidth, self.Size)
        self.Frame:SetAlpha(1)

        for displayIndex = 1, usedCount do
            local slot = self.Slots[layoutScratch[displayIndex]]
            local effIndex = self.InvertLayout and (usedCount - displayIndex + 1) or displayIndex
            local x = (effIndex - 1) * (self.Size + self.Spacing) - (totalWidth / 2) + (self.Size / 2)
            slot.Frame:ClearAllPoints()
            slot.Frame:SetPoint("CENTER", self.Frame, "CENTER", x, 0)
            slot.Frame:SetSize(self.Size, self.Size)
            slot.Frame:Show()
        end
    end

    for i = 1, self.Count do
        local slot = self.Slots[i]
        if slot and not slot.IsUsed then
            slot.Frame:Hide()
        end
    end

    for i = self.Count + 1, #self.Slots do
        local slot = self.Slots[i]
        if slot then
            slot.IsUsed = false
            slot.Frame:Hide()
        end
    end

    ScheduleMasqueReSkin(self.MasqueGroup)
end

function IconSlotContainer_M:SetSpacing(newSpacing)
    newSpacing = tonumber(newSpacing)
    if not newSpacing or newSpacing < 0 then
        return
    end
    if self.Spacing == newSpacing then
        return
    end
    self.Spacing = newSpacing
    self.LayoutSignature = nil
    self:Layout()
end

function IconSlotContainer_M:SetRows(numRows, alignment, invertLayout)
    numRows = (numRows and numRows > 1) and math.floor(numRows) or nil
    alignment = alignment or "CENTER"
    local overflowAlignment
    if alignment == "LEFT" then
        overflowAlignment = "RIGHT"
    elseif alignment == "RIGHT" then
        overflowAlignment = "LEFT"
    else
        overflowAlignment = alignment
    end
    invertLayout = invertLayout and true or false
    if self.NumRows == numRows and self.RowAlignment == alignment and self.OverflowRowAlignment == overflowAlignment and self.InvertLayout == invertLayout then
        return
    end
    self.NumRows = numRows
    self.RowAlignment = alignment
    self.OverflowRowAlignment = overflowAlignment
    self.InvertLayout = invertLayout
    self.LayoutSignature = nil
    self:Layout()
end

function IconSlotContainer_M:SetGrowDown(enabled)
    enabled = enabled and true or false
    if self.GrowDown == enabled then
        return
    end
    self.GrowDown = enabled
    self.LayoutSignature = nil
    self:Layout()
end

function IconSlotContainer_M:SetIconSize(newSize)
    newSize = tonumber(newSize)
    if not newSize or newSize <= 0 then
        return
    end
    if self.Size == newSize then
        return
    end

    self.Size = newSize

    for i = 1, self.Count do
        local slot = self.Slots[i]
        if slot and slot.Frame then
            slot.Frame:SetSize(self.Size, self.Size)

            local layer = slot.Container
            if layer and layer.Cooldown then
                layer.Cooldown.DesiredIconSize = self.Size
                local fs = layer.Cooldown.FontScale or 1.0
                fontUtil:UpdateCooldownFontSize(layer.Cooldown, self.Size, nil, fs)
            end

            if slot.ExtraLayers then
                for _, el in ipairs(slot.ExtraLayers) do
                    if el then
                        if el.Frame then
                            el.Frame:SetSize(self.Size, self.Size)
                        end
                        if el.Cooldown then
                            el.Cooldown.DesiredIconSize = self.Size
                            local fs = el.Cooldown.FontScale or 1.0
                            fontUtil:UpdateCooldownFontSize(el.Cooldown, self.Size, nil, fs)
                        end
                    end
                end
            end
        end
    end

    ScheduleMasqueReSkin(self.MasqueGroup)
    self:Layout()
end

function IconSlotContainer_M:SetCount(newCount)
    newCount = math.max(0, newCount or 0)
    if newCount == self.Count then
        return
    end

    if newCount < self.Count then
        for i = newCount + 1, #self.Slots do
            local slot = self.Slots[i]
            if slot then
                slot.IsUsed = false
                self:ClearSlot(i)
                slot.Frame:Hide()
            end
        end
    end

    self.Count = newCount

    for i = #self.Slots + 1, newCount do
        local slotFrame = CreateFrame(self.MasqueGroup and "Button" or "Frame", NextFrameName("Slot"), self.Frame)
        slotFrame:SetSize(self.Size, self.Size)
        slotFrame:EnableMouse(false)

        self.Slots[i] = {
            Frame = slotFrame,
            Container = nil,
            ExtraLayers = {},
            IsUsed = false,
        }
    end

    self:Layout()
end

function IconSlotContainer_M:SetSlot(slotIndex, options)
    if slotIndex < 1 or slotIndex > self.Count then
        return
    end

    if not options.Texture then
        return
    end

    local slot = self.Slots[slotIndex]

    if not slot then
        return
    end

    if not slot.IsUsed then
        slot.IsUsed = true
        self:Layout()
    end

    slot.SpellId = options.SpellId
    if options.SpellId then
        if not slot.MouseEnabled then
            slot.MouseEnabled = true
            slot.Frame:EnableMouse(true)
            slot.Frame:SetScript("OnEnter", function(f)
                if slot.SpellId then
                    GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
                    GameTooltip:SetSpellByID(slot.SpellId)
                    GameTooltip:Show()
                end
            end)
            slot.Frame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    elseif slot.MouseEnabled then
        slot.MouseEnabled = false
        slot.Frame:EnableMouse(false)
        slot.Frame:SetScript("OnEnter", nil)
        slot.Frame:SetScript("OnLeave", nil)
    end

    local layerIndex = options.Layer or 1
    local layer

    if layerIndex <= 1 then
        layer = EnsureContainer(slot, self.Size, self.MasqueGroup, self.NoBorder)
    else
        layer = EnsureExtraLayer(slot, layerIndex, self.Size)
    end

    local db = GetDb()
    layer.Icon:SetTexture(options.Texture)
    layer.Cooldown:SetReverse(options.ReverseCooldown)
    if options.DurationObject then
        layer.Cooldown:SetCooldownFromDurationObject(options.DurationObject)
        layer.Cooldown:SetDrawSwipe(not (db and db.DisableSwipe))
    else
        layer.Cooldown:Clear()
        layer.Cooldown:SetDrawSwipe(false)
    end

    ApplyAlpha(layer.Frame, options.Alpha)

    if options.Color and layer.Border then
        layer.Border:SetVertexColor(
            options.Color.r or 1,
            options.Color.g or 1,
            options.Color.b or 1,
            options.Color.a or 1
        )
        layer.Border:Show()
    elseif layer.Border then
        layer.Border:Hide()
    end

    if options.FontScale then
        layer.Cooldown.FontScale = options.FontScale
        fontUtil:UpdateCooldownFontSize(layer.Cooldown, self.Size, nil, options.FontScale)
    end

    UpdateGlow(layer.Frame, options)
end

function IconSlotContainer_M:ClearSlot(slotIndex)
    if slotIndex < 1 or slotIndex > #self.Slots then
        return
    end

    local slot = self.Slots[slotIndex]
    if not slot or not slot.Container then
        return
    end

    slot.SpellId = nil
    ClearLayerData(slot.Container, slot.Container.Frame)

    if slot.ExtraLayers then
        for _, el in ipairs(slot.ExtraLayers) do
            if el then
                ClearLayerData(el, el.Frame)
            end
        end
    end
end

function IconSlotContainer_M:SetSlotUnused(slotIndex)
    if slotIndex < 1 or slotIndex > self.Count then
        return
    end

    local slot = self.Slots[slotIndex]
    if not slot then
        return
    end

    if slot.IsUsed then
        slot.IsUsed = false
        self:ClearSlot(slotIndex)
        self:Layout()
    end
end

function IconSlotContainer_M:ResetAllSlots()
    local needsLayout = false
    for i = 1, self.Count do
        local slot = self.Slots[i]
        if slot and slot.IsUsed then
            slot.IsUsed = false
            self:ClearSlot(i)
            needsLayout = true
        end
    end
    if needsLayout then
        self:Layout()
    end
end

-- =====================================================================
-- SECTION 7: Frames — multi-addon unit frame discovery
-- Ported from MiniCC Core/Frames.lua by Jaliborc.
-- =====================================================================

local Frames_M = {}
MCC.Frames = Frames_M

local maxParty = MAX_PARTY_MEMBERS or 4
local maxRaid  = MAX_RAID_MEMBERS  or 40

local strataOrder = {
    "BACKGROUND", "LOW", "MEDIUM", "HIGH",
    "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP",
}
local strataIndex = {}
for i, v in ipairs(strataOrder) do strataIndex[v] = i end

---Returns the frame strata one level above the given strata, clamped at TOOLTIP.
function Frames_M:GetNextStrata(strata)
    return strataOrder[math.min((strataIndex[strata] or 1) + 1, #strataOrder)]
end

---Returns true if the frame is a Blizzard compact/party CUF that uses hooksecurefunc hooks.
function Frames_M:IsFriendlyCuf(frame)
    if not frame or (issecretvalue and issecretvalue(frame)) then return false end
    if frame.IsForbidden and frame:IsForbidden() then return false end
    local name = frame:GetName()
    if not name then return false end
    if name:find("CompactParty") or name:find("CompactRaid") then return true end
    if _G.PartyFrame and frame:GetParent() == _G.PartyFrame then return true end
    return false
end

---Show or hide overlay frame based on anchor visibility and excludePlayer.
function Frames_M:ShowHideFrame(frame, anchor, excludePlayer)
    if anchor.IsForbidden and anchor:IsForbidden() then frame:Hide(); return end
    local unit = anchor.unit or (anchor.GetAttribute and anchor:GetAttribute("unit"))
    if unit and unit ~= "" then
        if excludePlayer and _G.UnitIsUnit(unit, "player") then frame:Hide(); return end
    end
    if anchor:IsVisible() then
        frame:SetAlpha(1)
        frame:Show()
    else
        frame:Hide()
    end
end

---Blizzard compact party / raid frames.
function Frames_M:BlizzardFrames(visibleOnly)
    local frames = {}
    for i = 1, maxParty + 1 do
        local f = _G["CompactPartyFrameMember" .. i]
        if f and (f:IsVisible() or not visibleOnly) then frames[#frames + 1] = f end
    end
    for i = 1, maxRaid do
        local f = _G["CompactRaidFrame" .. i]
        if f and (f:IsVisible() or not visibleOnly) then frames[#frames + 1] = f end
    end
    return frames
end

---Blizzard standard (non-compact) party frames (TWW+).
function Frames_M:BlizzardPartyFrames(visibleOnly)
    if not _G.PartyFrame then return {} end
    local frames = {}
    for i = 1, maxParty + 1 do
        local f = _G.PartyFrame["MemberFrame" .. i]
        if f and (f:IsVisible() or not visibleOnly) then frames[#frames + 1] = f end
    end
    return frames
end

---ElvUI party/raid unit frames.
function Frames_M:ElvUIFrames(visibleOnly)
    if not _G.ElvUI then return {} end
    local ok, E = pcall(unpack, _G.ElvUI)
    if not ok or not E then return {} end
    local ok2, UF = pcall(E.GetModule, E, "UnitFrames")
    if not ok2 or not UF then return {} end
    local frames = {}
    for _ , group in pairs(UF.headers or {}) do
        local g = UF[group] or group
        if g and g.GetChildren then
            for _, child in ipairs({ g:GetChildren() }) do
                if not child.Health then
                    for _, sub in ipairs({ child:GetChildren() }) do
                        if sub.unit and (sub:IsVisible() or not visibleOnly) then
                            frames[#frames + 1] = sub
                        end
                    end
                elseif child.unit and (child:IsVisible() or not visibleOnly) then
                    frames[#frames + 1] = child
                end
            end
        end
    end
    return frames
end

---Grid2 unit frames.
function Frames_M:Grid2Frames(visibleOnly)
    if not _G.Grid2 or not _G.Grid2.GetUnitFrames then return {} end
    local frames = {}
    local ok, pfs = pcall(_G.Grid2.GetUnitFrames, _G.Grid2, "player")
    local pf = ok and pfs and next(pfs)
    if pf and (pf:IsVisible() or not visibleOnly) then frames[#frames + 1] = pf end
    for i = 1, maxParty do
        local ok2, mfs = pcall(_G.Grid2.GetUnitFrames, _G.Grid2, "party" .. i)
        local f = ok2 and mfs and next(mfs)
        if not f then break end
        if f:IsVisible() or not visibleOnly then frames[#frames + 1] = f end
    end
    for i = 1, maxRaid do
        local ok3, rfs = pcall(_G.Grid2.GetUnitFrames, _G.Grid2, "raid" .. i)
        local f = ok3 and rfs and next(rfs)
        if f and (f:IsVisible() or not visibleOnly) then frames[#frames + 1] = f end
    end
    return frames
end

---Cell party/raid unit frames.
function Frames_M:CellFrames(visibleOnly)
    if not _G.CellPartyFrameHeader and not _G.CellRaidFrameHeader0 then return {} end
    local frames = {}
    local headers = { _G.CellPartyFrameHeader, _G.CellSoloFrame }
    for i = 0, 8 do
        local h = _G["CellRaidFrameHeader" .. i]
        if h then headers[#headers + 1] = h end
    end
    for _, header in ipairs(headers) do
        if header then
            for _, child in ipairs({ header:GetChildren() }) do
                local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))
                if unit and unit ~= "" then
                    if (not child.IsForbidden or not child:IsForbidden())
                    and (child:IsVisible() or not visibleOnly) then
                        frames[#frames + 1] = child
                    end
                end
            end
        end
    end
    return frames
end

---Shadowed Unit Frames.
function Frames_M:ShadowedUFFrames(visibleOnly)
    if not _G.SUFUnitplayer and not _G.SUFHeaderpartyUnitButton1 and not _G.SUFHeaderraidUnitButton1 then
        return {}
    end
    local frames = {}
    local function Add(f)
        if not f then return end
        if f.IsForbidden and f:IsForbidden() then return end
        if (not visibleOnly) or f:IsVisible() then frames[#frames + 1] = f end
    end
    for _, u in ipairs({ "player", "pet", "target", "focus" }) do Add(_G["SUFUnit" .. u]) end
    for i = 1, maxParty do
        Add(_G["SUFHeaderpartyUnitButton" .. i])
        Add(_G["SUFUnitparty" .. i])
    end
    for i = 1, maxRaid do
        Add(_G["SUFHeaderraidUnitButton" .. i])
        Add(_G["SUFUnitraid" .. i])
    end
    return frames
end

---Plexus unit frames.
function Frames_M:PlexusFrames(visibleOnly)
    if not _G.PlexusLayoutHeader1 then return {} end
    local frames = {}
    local seen = {}
    local idx = 1
    while true do
        local header = _G["PlexusLayoutHeader" .. idx]
        if not header then break end
        for _, child in ipairs({ header:GetChildren() }) do
            local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))
            if unit and unit ~= "" and not seen[child] then
                if not (child.IsForbidden and child:IsForbidden()) then
                    if (not visibleOnly) or child:IsVisible() then
                        seen[child] = true
                        frames[#frames + 1] = child
                    end
                end
            end
        end
        idx = idx + 1
    end
    return frames
end

---TPerl party frames.
function Frames_M:TPerlFrames(visibleOnly)
    if not _G.TPerl_Party_SecureHeader then return {} end
    local frames = {}
    for _, child in ipairs({ _G.TPerl_Party_SecureHeader:GetChildren() }) do
        local unit = child.unit or (child.GetAttribute and child:GetAttribute("unit"))
        if unit and unit ~= "" then
            if (not child.IsForbidden or not child:IsForbidden())
            and (child:IsVisible() or not visibleOnly) then
                frames[#frames + 1] = child
            end
        end
    end
    return frames
end

---Returns ALL unit frames from every supported addon.
---@param visibleOnly boolean
---@return table
function Frames_M:GetAll(visibleOnly)
    local anchors = {}
    local isDanders = MCC.WoWEx:IsDandersEnabled()

    local lists = {
        not isDanders and Frames_M:BlizzardFrames(visibleOnly)      or {},
        not isDanders and Frames_M:BlizzardPartyFrames(visibleOnly)  or {},
        Frames_M:ElvUIFrames(visibleOnly),
        Frames_M:Grid2Frames(visibleOnly),
        Frames_M:CellFrames(visibleOnly),
        Frames_M:ShadowedUFFrames(visibleOnly),
        Frames_M:PlexusFrames(visibleOnly),
        Frames_M:TPerlFrames(visibleOnly),
    }

    -- Danders (dynamic frames API)
    if isDanders and _G.DandersFrames_GetAllFrames then
        local ok, result = pcall(_G.DandersFrames_GetAllFrames)
        if ok and result then lists[#lists + 1] = result end
    end

    for _, list in ipairs(lists) do
        for _, f in ipairs(list) do
            anchors[#anchors + 1] = f
        end
    end

    return anchors
end
