-- InfinityRaidTools --- Modules/InterruptTracker/InterruptTracker.lua
-- Interrupt Tracker (self-contained, no external addon dependency).
--
-- DB key : RRT.InterruptTracker (SavedVariable via global RRT)
-- Global : RRT_InterruptTracker  (reference for slash-commands / options)
-- Events : self-managed event frame

-- ---------------------------------------------------------------------------
-- SECTION 1 - Internal helpers
-- ---------------------------------------------------------------------------


local _Modules = {}
_Modules.registry = {}
function _Modules:Register(module)
    if module and module.key then self.registry[module.key] = module end
end
local Modules = _Modules

local _ModulesInternal = {}
local ModulesInternal = _ModulesInternal

local L = {}  -- all L[...] usages have 'or fallback' values

-- Helpers (from framework.lua) -------------------------------------------

local function trim(text)
    if type(hasanysecretvalues) == 'function' then
        local ok, hasSecret = pcall(hasanysecretvalues, text)
        if ok and hasSecret then return '' end
    end
    if type(text) ~= 'string' then return '' end
    return text:gsub('^%s+', ''):gsub('%s+$', '')
end

local function clampNumber(value, fallback, min, max)
    value = tonumber(value) or fallback
    if min and value < min then value = min end
    if max and value > max then value = max end
    return value
end

local function PA_Num(v)
    if v == nil then return 0 end
    local n = tonumber(tostring(v))
    if n == nil then return 0 end
    return n
end

local function IT_HasSecretValues(...)
    if type(hasanysecretvalues) == 'function' then
        local ok, hasSecret = pcall(hasanysecretvalues, ...)
        if ok and hasSecret then return true end
    end
    return false
end

local function IT_IsUsablePlainString(value)
    if type(value) ~= 'string' then return false end
    if IT_HasSecretValues(value) then return false end
    return value ~= ''
end

local function IT_IsUsablePlainBoolean(value)
    return type(value) == 'boolean' and not IT_HasSecretValues(value)
end

local function IT_IsUsablePlainNumber(value)
    if type(value) ~= 'number' then return false end
    if IT_HasSecretValues(value) then return false end
    return value == value and value > -math.huge and value < math.huge
end

local function IT_NormalizeSafeString(value)
    if not IT_IsUsablePlainString(value) then return nil end
    return value
end

local function IT_NormalizeSpellID(value)
    if IT_IsUsablePlainNumber(value) then
        local numeric = math.floor(value)
        return numeric > 0 and numeric or 0
    end
    if IT_IsUsablePlainString(value) then
        local numeric = tonumber(value)
        if type(numeric) == 'number' and numeric == numeric
            and numeric > 0 and numeric < math.huge then
            return math.floor(numeric)
        end
    end
    return 0
end

local function IT_SafeStringsEqual(left, right)
    local l = IT_NormalizeSafeString(left)
    local r = IT_NormalizeSafeString(right)
    return l ~= nil and r ~= nil and l == r
end

local IT_SafeUnitGUID = function(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if ok and IT_IsUsablePlainString(guid) then return guid end
    return nil
end

local function PA_CanSafelyInspectUnit(unit)
    if type(unit) ~= 'string' or unit == '' or not UnitExists(unit) then return false end
    if UnitIsConnected and not UnitIsConnected(unit) then return false end
    if type(CanInspect) ~= 'function' then return true end
    local ok, canInspect = pcall(CanInspect, unit, true)
    if not ok then ok, canInspect = pcall(CanInspect, unit) end
    return ok and canInspect and true or false
end

local function PA_ServerNow()
    if type(GetServerTime) == 'function' then return PA_Num(GetServerTime()) end
    if type(time) == 'function' then return PA_Num(time()) end
    return PA_Num(GetTime())
end

local function PA_PerfBegin()                       return nil, nil end
local function PA_PerfEnd()                         end
local function PA_CpuDiagCount()                    end
local function PA_CpuDiagRecordModuleEvent()        end
local function PA_CpuDiagRecordDispatcherEvent()    end
local function PA_CpuDiagRecordUnitCallback()       end
local function PA_CpuDiagRecordTrigger()            end

local function PA_CpuDiagApplyVisibility(_, frame, naturalVisible)
    if not frame then return false end
    if naturalVisible then frame:Show() else frame:Hide() end
    return naturalVisible and true or false
end

local function PA_CpuDiagIsFrameConsideredShown(_, frame)
    return frame and frame.IsShown and frame:IsShown() or false
end

local function PA_IsUiSurfaceGateEnabled()          return false end
local function PA_IsSuppressedUiSurfaceModule()     return false end

local function PA_HideTooltipIfOwnedBy(owner)
    if not GameTooltip or owner == nil then return end
    local cur = GameTooltip.GetOwner and GameTooltip:GetOwner() or nil
    if cur ~= nil and cur == owner then GameTooltip:Hide() end
end

_ModulesInternal.trim                             = trim
_ModulesInternal.clampNumber                      = clampNumber
_ModulesInternal.PA_Num                           = PA_Num
_ModulesInternal.IT_HasSecretValues               = IT_HasSecretValues
_ModulesInternal.IT_IsUsablePlainString           = IT_IsUsablePlainString
_ModulesInternal.IT_IsUsablePlainBoolean          = IT_IsUsablePlainBoolean
_ModulesInternal.IT_IsUsablePlainNumber           = IT_IsUsablePlainNumber
_ModulesInternal.IT_NormalizeSafeString           = IT_NormalizeSafeString
_ModulesInternal.IT_NormalizeSpellID              = IT_NormalizeSpellID
_ModulesInternal.IT_SafeStringsEqual              = IT_SafeStringsEqual
_ModulesInternal.IT_SafeUnitGUID                  = IT_SafeUnitGUID
_ModulesInternal.PA_CanSafelyInspectUnit          = PA_CanSafelyInspectUnit
_ModulesInternal.PA_ServerNow                     = PA_ServerNow
_ModulesInternal.PA_PerfBegin                     = PA_PerfBegin
_ModulesInternal.PA_PerfEnd                       = PA_PerfEnd
_ModulesInternal.PA_CpuDiagCount                  = PA_CpuDiagCount
_ModulesInternal.PA_CpuDiagRecordModuleEvent      = PA_CpuDiagRecordModuleEvent
_ModulesInternal.PA_CpuDiagRecordDispatcherEvent  = PA_CpuDiagRecordDispatcherEvent
_ModulesInternal.PA_CpuDiagRecordUnitCallback     = PA_CpuDiagRecordUnitCallback
_ModulesInternal.PA_CpuDiagRecordTrigger          = PA_CpuDiagRecordTrigger
_ModulesInternal.PA_CpuDiagApplyVisibility        = PA_CpuDiagApplyVisibility
_ModulesInternal.PA_CpuDiagIsFrameConsideredShown = PA_CpuDiagIsFrameConsideredShown
_ModulesInternal.PA_IsUiSurfaceGateEnabled        = PA_IsUiSurfaceGateEnabled
_ModulesInternal.PA_IsSuppressedUiSurfaceModule   = PA_IsSuppressedUiSurfaceModule
_ModulesInternal.PA_HideTooltipIfOwnedBy          = PA_HideTooltipIfOwnedBy

-- ---------------------------------------------------------------------------
-- SECTION 2 - Interrupt Tracker runtime
-- ---------------------------------------------------------------------------

local interruptRuntimeStringCache = nil
local interruptRuntimeStringCacheLocale = nil

local function GetInterruptRuntimeStrings()
    local localeCode = (GetLocale and GetLocale()) or "enUS"
    if interruptRuntimeStringCache and interruptRuntimeStringCacheLocale == localeCode then
        return interruptRuntimeStringCache
    end

    interruptRuntimeStringCacheLocale = localeCode
    interruptRuntimeStringCache = {
        grab = tostring(L["RUNTIME_DRAG_HANDLE_GRAB"] or "GRAB"),
        ready = tostring(L["COMMON_READY"] or "Ready"),
        title = tostring(L["RUNTIME_INTERRUPT_TITLE"] or "Interrupts"),
        whoClassUnknown = tostring(L["RUNTIME_INTERRUPT_WHO_CLASS_UNKNOWN"] or "class unknown"),
        whoInterruptUnknown = tostring(L["RUNTIME_INTERRUPT_WHO_INTERRUPT_UNKNOWN"] or "interrupt unknown"),
        whoNoParty = tostring(L["RUNTIME_INTERRUPT_WHO_NO_PARTY"] or "InfinityRaidTools: no current party to report."),
        whoSpecUnknown = tostring(L["RUNTIME_INTERRUPT_WHO_SPEC_UNKNOWN"] or "spec unknown"),
    }

    return interruptRuntimeStringCache
end

do

local IT_ACTIVE_DISPLAY_TICK = 0.05
local IT_CALM_DISPLAY_TICK = 0.10
local IT_ACTIVITY_CALM_THRESHOLD = 5.0
local IT_STRUCTURE_SAFETY_DEADLINE = 2.0
local IT_COALESCED_REFRESH_DELAY = 0.05
local IT_READY_THRESHOLD = 0.5
local IT_SORT_SNAP = 0.1
local IT_PREVIEW_MODEB_SORT_SNAP = 0.5
local IT_PREVIEW_MODEB_REORDER_THRESHOLD = 0.0
local IT_PREVIEW_MODEB_MIN_COOLDOWN_GAP = 1.5
local IT_PREVIEW_MODEB_PHASE_SPACING_MIN = 2.5
local IT_PREVIEW_MODEB_PHASE_SPACING_MAX = 4.5
local IT_ACTIVITY_CONFIRM_WINDOW = 30.0
local IT_OFFLINE_GRACE_WINDOW = 5.0
local IT_INSPECT_STEP_DELAY = 0.5
local IT_QUEUE_INSPECT_DELAY = 1.0
local IT_INSPECT_TIMEOUT = 4.0
local IT_INSPECT_READY_RETRY_DELAY = 0.10
local IT_INSPECT_READY_MAX_RETRIES = 3
local IT_INSPECT_REQUEUE_BACKOFF = 2.0
local IT_OWN_PET_RETRY_1 = 0.5
local IT_OWN_PET_RETRY_2 = 1.5
local IT_OWN_PET_RETRY_3 = 3.0
local IT_WARLOCK_SPELLS_RETRY_1 = 1.5
local IT_WARLOCK_SPELLS_RETRY_2 = 3.0
local IT_RECENT_CAST_KEEP = 1.0
local IT_OBSERVED_CAST_COALESCE_WINDOW = 1.0
local IT_FALLBACK_CONFIRM_MAX_DELTA = 1.5
local IT_PARTY_CREDIT_RESOLUTION_WINDOW = 0.20
local IT_PRIMARY_TARGET_CONFIRM_MAX_DELTA = 0.5
local IT_INTERRUPT_COUNT_DEDUPE_WINDOW = 1.5
local IT_MOB_INTERRUPT_DUPLICATE_WINDOW = 0.05
local IT_FULL_WIPE_WINDOW = 8.0
local IT_FULL_WIPE_RECOVERY_GRACE = 15.0
local IT_FULL_WIPE_COMBAT_RECENCY = 12.0
local IT_ICON_GLOW_DURATION = 0.45
local IT_ICON_GLOW_ALPHA = 1.00
local IT_ICON_GLOW_PAD = 28
local IT_PREVIEW_READY_HOLD = 0.6
local IT_PREVIEW_MODEB_READY_HOLD = 3.25
local IT_BAR_ACCENT_WIDTH = 6
local IT_BAR_ACCENT_ALPHA = 0.24
local IT_BAR_ACCENT_PULSE_ALPHA = 0.38
local IT_CLASS_ICON_TEXCOORD_INSET_X = 4 / 256
local IT_CLASS_ICON_TEXCOORD_INSET_TOP = 6 / 256
local IT_CLASS_ICON_TEXCOORD_INSET_BOTTOM = 4 / 256
local IT_ICON_SEPARATOR_THICKNESS = 2
local IT_ICON_SEPARATOR_VERTICAL_INSET = 1
local IT_FALLBACK_SEPARATOR = { 242 / 255, 201 / 255, 76 / 255, 1.0 }
local IT_ROW_GAP_DEFAULT = 4
local IT_ROW_GAP_MIN = 0
local IT_ROW_GAP_MAX = 32
local IT_SPACING_ARM = {
    ARM_LENGTH = 110,
    ARM_THICKNESS = 2,
    ARM_HIT_THICKNESS = 16,
    CENTER_SIZE = 8,
    DRAG_PIXELS_PER_STEP = 8,
    SHIFT_DRAG_MULT = 1.8,
    ALT_DRAG_MULT = 0.5,
    WHEEL_BASE_STEP = 2,
    WHEEL_SHIFT_STEP = 1,
    WHEEL_ALT_STEP = 4,
    CURSOR_Y = "Interface\\CURSOR\\UI-Cursor-SizeRight",
    CURSOR_GENERIC = "Interface\\CURSOR\\UI-Cursor-Move",
    TOOLTIP_DEBOUNCE = 0.10,
    UNLOCK_HINT_HOLD = 2.7,
    UNLOCK_HINT_FADE = 0.3,
    UNLOCK_HINT_FAST_FADE = 0.2,
    BOUNDARY_PULSE_AMPLITUDE = 3,
    BOUNDARY_PULSE_OUT_DURATION = 0.08,
    BOUNDARY_PULSE_IN_DURATION = 0.08,
    OFFSET_X = 18,
}
local IT_PREVIEW_MODEB_WINDOW_SIZE = 5
local IT_PREVIEW_MODEB_ROTATION_CYCLES = 2

local IT_PREVIEW_MODEB_POOL = {
    { name = "Yetw", class = "WARRIOR", specID = 72, specName = "Fury" },
    { name = "Artyrka", class = "MAGE", specID = 63, specName = "Fire" },
    { name = "Camp", class = "DRUID", specID = 104, specName = "Bear" },
    { name = "Shiftus", class = "SHAMAN", specID = 264, specName = "Restoration" },
    { name = "Goof", class = "WARRIOR", specID = 72, specName = "Fury" },
    { name = "Slynkz", class = "WARLOCK", specID = 267, specName = "Destruction" },
    { name = "Sittinbull", class = "SHAMAN", specID = 263, specName = "Enhancement" },
    { name = "Itzjay", class = "HUNTER", specID = 255, specName = "Survival" },
    { name = "Oleg", class = "PALADIN", specID = 65, specName = "Holy", previewUseClassIcon = true },
    { name = "Smz", class = "WARLOCK", specID = 267, specName = "Destruction" },
    { name = "Lucuris", class = "PRIEST", specID = 256, specName = "Discipline" },
    { name = "Gendisarray", class = "PALADIN", specID = 66, specName = "Protection" },
    { name = "Adaenp", class = "PALADIN", specID = 66, specName = "Protection" },
    { name = "Babyhoof", class = "DRUID", specID = 104, specName = "Bear" },
    { name = "Morrey", class = "MAGE", specID = 62, specName = "Arcane" },
    { name = "Toughclassf", class = "MAGE", specID = 63, specName = "Fire" },
    { name = "Deneroc", class = "DEATHKNIGHT", specID = 251, specName = "Frost" },
    { name = "Mainmise", class = "WARLOCK", specID = 265, specName = "Affliction" },
    { name = "Deva", class = "WARLOCK", specID = 266, specName = "Demonology" },
}

local IT_NEUTRAL_BAR = { 0.23, 0.56, 0.88, 0.92 }
local IT_BG_BAR = { 0.09, 0.10, 0.13, 0.88 }
local IT_ROW_BORDER = { 0.18, 0.21, 0.25, 0.70 }
local IT_MUTED_TEXT = { 0.72, 0.74, 0.78, 0.96 }
local IT_UNAVAILABLE_BAR = { 0.28, 0.29, 0.31, 0.94 }
local IT_UNAVAILABLE_BG = { 0.11, 0.12, 0.14, 0.92 }
local IT_UNAVAILABLE_TEXT = { 0.60, 0.62, 0.66, 0.98 }
local IT_AVAILABILITY_VISUALS = {
    staleBg = { 0.10, 0.11, 0.14, 0.90 },
    staleText = { 0.76, 0.78, 0.83, 0.98 },
    deadBar = { 0.46, 0.28, 0.28, 0.92 },
    deadBg = { 0.15, 0.09, 0.10, 0.92 },
    deadText = { 0.82, 0.70, 0.70, 0.98 },
    staleIconAlpha = 0.86,
    deadIconAlpha = 0.78,
    unavailableIconAlpha = 0.62,
    staleBarBlend = 0.42,
}

local IT_CLASS_COLORS = {
    WARRIOR     = { 0.78, 0.61, 0.43 },
    ROGUE       = { 1.00, 0.96, 0.41 },
    MAGE        = { 0.41, 0.80, 0.94 },
    SHAMAN      = { 0.00, 0.44, 0.87 },
    DRUID       = { 1.00, 0.49, 0.04 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    PALADIN     = { 0.96, 0.55, 0.73 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    MONK        = { 0.00, 1.00, 0.59 },
    PRIEST      = { 1.00, 1.00, 1.00 },
    HUNTER      = { 0.67, 0.83, 0.45 },
    WARLOCK     = { 0.58, 0.51, 0.79 },
    EVOKER      = { 0.20, 0.58, 0.50 },
}

local function IT_GetConfiguredRowBackgroundOpacity(db)
    return clampNumber(db and db.backgroundOpacity, IT_BG_BAR[4], 0, 1)
end

local function IT_GetConfiguredRowGap(db)
    return math.floor(clampNumber(db and db.rowGap, IT_ROW_GAP_DEFAULT, IT_ROW_GAP_MIN, IT_ROW_GAP_MAX))
end

local function IT_ApplyClassIconTexture(texture, classFile)
    if not texture or not classFile or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[classFile] then
        return false
    end
    local coords = CLASS_ICON_TCOORDS[classFile]
    texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    texture:SetTexCoord(
        coords[1] + IT_CLASS_ICON_TEXCOORD_INSET_X,
        coords[2] - IT_CLASS_ICON_TEXCOORD_INSET_X,
        coords[3] + IT_CLASS_ICON_TEXCOORD_INSET_TOP,
        coords[4] - IT_CLASS_ICON_TEXCOORD_INSET_BOTTOM
    )
    return true
end

local IT_INTERRUPTS = {
    [6552]    = { name = "Pummel", cd = 15, icon = 132938 },
    [1766]    = { name = "Kick", cd = 15, icon = 132219 },
    [2139]    = { name = "Counterspell", cd = 25, icon = 135856 },
    [57994]   = { name = "Wind Shear", cd = 12, icon = 136018 },
    [106839]  = { name = "Skull Bash", cd = 15, icon = 236946 },
    [78675]   = { name = "Solar Beam", cd = 60, icon = 252188 },
    [47528]   = { name = "Mind Freeze", cd = 15, icon = 237527 },
    [96231]   = { name = "Rebuke", cd = 15, icon = 523893 },
    [183752]  = { name = "Disrupt", cd = 15, icon = 1305153 },
    [116705]  = { name = "Spear Hand Strike", cd = 15, icon = 608940 },
    [15487]   = { name = "Silence", cd = 30, icon = 458230 },
    [147362]  = { name = "Counter Shot", cd = 24, icon = 249170 },
    [187707]  = { name = "Muzzle", cd = 15, icon = 1376045 },
    [19647]   = { name = "Spell Lock", cd = 24, icon = 136174 },
    [132409]  = { name = "Spell Lock", cd = 24, icon = 136174 },
    [119914]  = { name = "Axe Toss", cd = 30, iconSpellID = 89766, icon = 236316 },
    [1276467] = { name = "Fel Ravager", cd = 25, iconSpellID = 132409, icon = 136217 },
    [351338]  = { name = "Quell", cd = 20, icon = 4622469 },
}

local IT_INTERRUPTS_STR = {}
for spellID, data in pairs(IT_INTERRUPTS) do
    IT_INTERRUPTS_STR[tostring(spellID)] = data
end

local IT_CLASS_INTERRUPT_LIST = {
    WARRIOR     = { 6552 },
    ROGUE       = { 1766 },
    MAGE        = { 2139 },
    SHAMAN      = { 57994 },
    DRUID       = { 106839, 78675 },
    DEATHKNIGHT = { 47528 },
    PALADIN     = { 96231 },
    DEMONHUNTER = { 183752 },
    MONK        = { 116705 },
    PRIEST      = { 15487 },
    HUNTER      = { 147362, 187707 },
    WARLOCK     = { 19647, 132409, 119914 },
    EVOKER      = { 351338 },
}

local IT_CLASS_PRIMARY = {
    WARRIOR     = { id = 6552, cd = 15, name = "Pummel" },
    ROGUE       = { id = 1766, cd = 15, name = "Kick" },
    MAGE        = { id = 2139, cd = 25, name = "Counterspell" },
    SHAMAN      = { id = 57994, cd = 12, name = "Wind Shear" },
    DRUID       = { id = 106839, cd = 15, name = "Skull Bash" },
    DEATHKNIGHT = { id = 47528, cd = 15, name = "Mind Freeze" },
    PALADIN     = { id = 96231, cd = 15, name = "Rebuke" },
    DEMONHUNTER = { id = 183752, cd = 15, name = "Disrupt" },
    MONK        = { id = 116705, cd = 15, name = "Spear Hand Strike" },
    PRIEST      = { id = 15487, cd = 30, name = "Silence" },
    HUNTER      = { id = 147362, cd = 24, name = "Counter Shot" },
    WARLOCK     = { id = 19647, cd = 24, name = "Spell Lock" },
    EVOKER      = { id = 351338, cd = 20, name = "Quell" },
}

local IT_SPEC_OVERRIDE = {
    [102] = { id = 78675, cd = 60, name = "Solar Beam" },
    [255] = { id = 187707, cd = 15, name = "Muzzle" },
    [264] = { id = 57994, cd = 12, name = "Wind Shear" },
    [266] = { id = 119914, cd = 30, name = "Axe Toss", isPet = true, petSpellID = 89766, requiredFamily = "Felguard" },
}

local IT_SPEC_NO_INTERRUPT = {
    [65]  = true,
    [105] = true,
    [256] = true,
    [257] = true,
    [270] = true,
    [1468] = true,
}

local IT_PERMANENT_CD_TALENTS = {
    [391271] = { affects = 6552, pctReduction = 10, name = "Honed Reflexes" },
    [382297] = { affects = 2139, reduction = 5, name = "Quick Witted" },
}

local IT_ON_SUCCESS_TALENTS = {}

local IT_OWNER_CONFIRMED_TALENTS = {
    [202918] = { affects = 78675, reduction = 15, kind = "light_of_the_sun", name = "Light of the Sun" },
    [378848] = { affects = 47528, reduction = 3, kind = "coldthirst", name = "Coldthirst" },
}

local IT_PERMANENT_CD_TALENTS_STR = {}
local IT_ON_SUCCESS_TALENTS_STR = {}
local IT_OWNER_CONFIRMED_TALENTS_STR = {}
for talentID, data in pairs(IT_PERMANENT_CD_TALENTS) do
    IT_PERMANENT_CD_TALENTS_STR[tostring(talentID)] = data
end
for talentID, data in pairs(IT_ON_SUCCESS_TALENTS) do
    IT_ON_SUCCESS_TALENTS_STR[tostring(talentID)] = data
end
for talentID, data in pairs(IT_OWNER_CONFIRMED_TALENTS) do
    IT_OWNER_CONFIRMED_TALENTS_STR[tostring(talentID)] = data
end

local IT_OWNER_CONFIRMED_CONDITIONAL_SPELLS = {}

local IT_SPEC_EXTRA_KICKS = {
    [266] = {
        { id = 132409, cd = 24, name = "Spell Lock", iconSpellID = 132409, icon = "Interface\\Icons\\spell_shadow_summonfelhunter", talentCheck = 1276467 },
    },
}

local IT_SPEC_EXTRA_KICKS_STR = {}
local IT_SPEC_EXTRA_KICKS_BY_TALENT = {}
local IT_SPEC_EXTRA_KICKS_BY_TALENT_STR = {}
for specID, extraList in pairs(IT_SPEC_EXTRA_KICKS) do
    IT_SPEC_EXTRA_KICKS_STR[tostring(specID)] = extraList
    for _, extra in ipairs(extraList) do
        if extra.talentCheck ~= nil then
            IT_SPEC_EXTRA_KICKS_BY_TALENT[extra.talentCheck] = IT_SPEC_EXTRA_KICKS_BY_TALENT[extra.talentCheck] or {}
            IT_SPEC_EXTRA_KICKS_BY_TALENT[extra.talentCheck][#IT_SPEC_EXTRA_KICKS_BY_TALENT[extra.talentCheck] + 1] = {
                specID = specID,
                extra = extra,
            }
        end
    end
end
for talentID, extraList in pairs(IT_SPEC_EXTRA_KICKS_BY_TALENT) do
    IT_SPEC_EXTRA_KICKS_BY_TALENT_STR[tostring(talentID)] = extraList
end

local IT_SPELL_ALIASES = {
    [1276467] = 132409,
    [132409] = 19647,
}

local IT_HEALER_KEEPS_KICK = {
    SHAMAN = true,
}

local interruptPartyFrames = {}
local interruptPartyPetFrames = {}
local interruptPartyFallbackFrame = CreateFrame("Frame")
for i = 1, 4 do
    interruptPartyFrames[i] = CreateFrame("Frame")
    interruptPartyPetFrames[i] = CreateFrame("Frame")
end

local function IT_SafeToString(value)
    local ok, result = pcall(tostring, value)
    if ok and type(result) == "string" then
        return result
    end
    return nil
end

local function IT_TrySecretLookup(tbl, mirror, key)
    if type(tbl) ~= "table" then
        return nil
    end
    local ok, value = pcall(function()
        return tbl[key]
    end)
    if ok and value ~= nil then
        return value
    end
    local keyStr = IT_SafeToString(key)
    if keyStr and type(mirror) == "table" then
        return mirror[keyStr]
    end
    return nil
end

local function IT_GetSpecExtraKicks(specID)
    local extraList = IT_TrySecretLookup(IT_SPEC_EXTRA_KICKS, IT_SPEC_EXTRA_KICKS_STR, specID)
    if type(extraList) == "table" then
        return extraList
    end
    return nil
end

local function IT_GetExtraKicksForTalent(talentID)
    local extraList = IT_TrySecretLookup(IT_SPEC_EXTRA_KICKS_BY_TALENT, IT_SPEC_EXTRA_KICKS_BY_TALENT_STR, talentID)
    if type(extraList) == "table" then
        return extraList
    end
    return nil
end

local function IT_NormalizeName(name)
    if not IT_IsUsablePlainString(name) then
        return nil
    end
    local ok, shortName = pcall(Ambiguate, name, "short")
    local text = ok and shortName or name
    if not IT_IsUsablePlainString(text) then
        return nil
    end
    text = trim(text)
    if text == "" then
        return nil
    end
    return text
end

local function IT_NormalizeNameList(names)
    local normalized = {}
    local seen = {}
    for _, rawName in ipairs(type(names) == "table" and names or {}) do
        local name = IT_NormalizeName(rawName)
        if name and not seen[name] then
            normalized[#normalized + 1] = name
            seen[name] = true
        end
    end
    return normalized
end

local function IT_SerializeNameList(names)
    return table.concat(IT_NormalizeNameList(names), ",")
end

local function IT_SafeUnitClass(unit)
    local ok, _, classFile = pcall(UnitClass, unit)
    if ok then
        return classFile
    end
    return nil
end

local function IT_SafeUnitName(unit)
    local ok, name = pcall(UnitName, unit)
    if ok and not IT_HasSecretValues(name) then
        return IT_NormalizeName(name)
    end
    return nil
end

local function IT_IsHostileAttackableUnit(unit)
    if not unit or not UnitExists(unit) or not UnitCanAttack then
        return false
    end
    local ok, canAttack = pcall(UnitCanAttack, "player", unit)
    return ok and canAttack and true or false
end

local function IT_SafeSpellTexture(spellID)
    if not spellID or not C_Spell or not C_Spell.GetSpellTexture then
        return nil
    end
    local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
    if ok and texture then
        return texture
    end
    return nil
end

local function IT_SafeBaseCooldown(spellID)
    if not spellID then
        return nil
    end
    local ok, ms = pcall(GetSpellBaseCooldown, spellID)
    if ok and ms and tonumber(ms) and tonumber(ms) > 0 then
        return tonumber(ms) / 1000
    end
    return nil
end

local function IT_GetMediaTexturePath(value)
    -- Use LibSharedMedia if available (RRT ships with it)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local path = LSM:Fetch("statusbar", value, true)
        if path and path ~= "" then return path end
    end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

local function IT_GetAlertSoundChoice(value)
    if type(value) == "number" then
        return "kit", value
    end
    local asNum = tonumber(value)
    if asNum then
        return "kit", asNum
    end
    return nil, nil
end

local function IT_GetSpecName(specID)
    if not specID or specID <= 0 or not GetSpecializationInfoByID then
        return nil
    end
    local ok, _, specName = pcall(GetSpecializationInfoByID, specID)
    if ok and type(specName) == "string" and specName ~= "" then
        return specName
    end
    return nil
end

local function IT_GetClassColor(classFile)
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if color then
        return color.r, color.g, color.b
    end
    local fallback = IT_CLASS_COLORS[classFile]
    if fallback then
        return fallback[1], fallback[2], fallback[3]
    end
    return IT_NEUTRAL_BAR[1], IT_NEUTRAL_BAR[2], IT_NEUTRAL_BAR[3]
end

local function IT_GetLocalizedClassName(classFile)
    if type(classFile) ~= "string" or classFile == "" then
        return nil
    end
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile])
        or (LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[classFile])
        or classFile
end

local function IT_CopyColor(color)
    return {
        r = clampNumber(color and color.r, 1, 0, 1),
        g = clampNumber(color and color.g, 1, 0, 1),
        b = clampNumber(color and color.b, 1, 0, 1),
        a = clampNumber(color and color.a, 1, 0, 1),
    }
end

local function IT_IsSupportedDungeon()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "party" then
        return false
    end
    local _, _, _, _, maxPlayers = GetInstanceInfo()
    if maxPlayers and tonumber(maxPlayers) and tonumber(maxPlayers) > 5 then
        return false
    end
    return true
end

local function IT_GetContextKey()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "party" then
        return nil
    end
    local instanceName, _, difficultyID, _, maxPlayers, _, _, mapID = GetInstanceInfo()
    return table.concat({
        tostring(mapID or 0),
        tostring(difficultyID or 0),
        tostring(maxPlayers or 0),
        tostring(instanceName or ""),
    }, ":")
end

local function IT_IsChallengeModeActive()
    if C_PartyInfo and C_PartyInfo.IsChallengeModeActive then
        return not not C_PartyInfo.IsChallengeModeActive()
    end
    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
        return not not C_ChallengeMode.IsChallengeModeActive()
    end
    return false
end

local function IT_GetWholeCooldownValue(remaining)
    return math.max(0, math.ceil(math.max(0, tonumber(remaining) or 0)))
end

local function IT_FormatCooldown(remaining)
    return tostring(IT_GetWholeCooldownValue(remaining))
end

local function IT_IsReady(cdEnd, now)
    return ((tonumber(cdEnd) or 0) - now) <= IT_READY_THRESHOLD
end

local function IT_IsUnitRealDeadOrGhost(unit)
    if not unit or not UnitExists(unit) then
        return false
    end

    local isDead = (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)) and true or false
    if not isDead then
        return false
    end

    -- Hunters using Feign Death should not be treated like a real unavailable death state.
    if UnitIsFeignDeath and UnitIsFeignDeath(unit) then
        return false
    end

    return true
end

local function IT_SnapRemaining(value)
    local remaining = math.max(0, tonumber(value) or 0)
    return math.floor((remaining / IT_SORT_SNAP) + 0.5) * IT_SORT_SNAP
end

local function IT_SnapPreviewModeBRemaining(value)
    local remaining = math.max(0, tonumber(value) or 0)
    return math.floor((remaining / IT_PREVIEW_MODEB_SORT_SNAP) + 0.5) * IT_PREVIEW_MODEB_SORT_SNAP
end

local function IT_ApplyPreviewModeBCooldownGap(rows, now)
    if type(rows) ~= "table" or #rows < 2 then
        return rows
    end

    local coolingRows = {}
    for _, row in ipairs(rows) do
        if row and not row.previewReady then
            coolingRows[#coolingRows + 1] = row
        end
    end

    if #coolingRows < 2 then
        return rows
    end

    table.sort(coolingRows, function(a, b)
        local aRemaining = math.max(0, tonumber(a.previewRemaining) or 0)
        local bRemaining = math.max(0, tonumber(b.previewRemaining) or 0)
        if aRemaining ~= bRemaining then
            return aRemaining < bRemaining
        end
        return (tonumber(a.previewModeBSortIndex) or 999) < (tonumber(b.previewModeBSortIndex) or 999)
    end)

    local previousRemaining = nil
    for _, row in ipairs(coolingRows) do
        local remaining = math.max(0, tonumber(row.previewRemaining) or 0)
        local baseCd = math.max(1, tonumber(row.baseCd) or 15)
        if previousRemaining ~= nil then
            remaining = math.max(remaining, previousRemaining + IT_PREVIEW_MODEB_MIN_COOLDOWN_GAP)
        end
        remaining = math.min(baseCd, remaining)

        row.previewRemaining = remaining
        row.previewModeBSortRemaining = IT_SnapPreviewModeBRemaining(remaining)
        row.cdEnd = now + remaining
        previousRemaining = remaining
    end

    return rows
end

local function IT_GetPrimaryIcon(spellID)
    local data = spellID and IT_INTERRUPTS[spellID]
    if not data then
        return 134400
    end
    if data.iconSpellID then
        return IT_SafeSpellTexture(data.iconSpellID) or data.icon or 134400
    end
    return data.icon or 134400
end

local function IT_GetExtraKickIcon(extra)
    if not extra then
        return 134400
    end
    if extra.iconSpellID then
        return IT_SafeSpellTexture(extra.iconSpellID) or extra.icon or IT_GetPrimaryIcon(extra.id)
    end
    return extra.icon or IT_GetPrimaryIcon(extra.id)
end

local function IT_GetRowUseGlowTarget(row, member, db)
    if not row or not member or not db then
        return nil
    end
    if db.showSpellIcon and member.spellID and row.spellIcon and row.spellIcon:IsShown() then
        return row.spellIcon
    end
    if db.showClassIcon and member.class and row.classIcon and row.classIcon:IsShown() then
        return row.classIcon
    end
    return nil
end

local function IT_PositionRowUseGlow(row, target)
    local glow = row and row.spellIconGlow
    if not glow then
        return
    end
    if not target or not target.IsShown or not target:IsShown() then
        if glow.anim and glow.anim:IsPlaying() then
            glow.anim:Stop()
        end
        glow:SetAlpha(0)
        glow:Hide()
        return
    end

    local width = math.max(16, tonumber(target:GetWidth()) or 0)
    local height = math.max(16, tonumber(target:GetHeight()) or 0)
    glow:ClearAllPoints()
    glow:SetPoint("CENTER", target, "CENTER", 0, 0)
    glow:SetSize(width + IT_ICON_GLOW_PAD, height + IT_ICON_GLOW_PAD)
    glow:Show()
end

local IT_DYNAMIC_RENDER = {
    EPSILON = 0.001,
}

function IT_DYNAMIC_RENDER.NearlyEqual(left, right)
    return math.abs((tonumber(left) or 0) - (tonumber(right) or 0)) <= IT_DYNAMIC_RENDER.EPSILON
end

function IT_DYNAMIC_RENDER.SetTextIfChanged(fontString, state, key, value)
    local nextValue = tostring(value or "")
    if state[key] ~= nextValue then
        fontString:SetText(nextValue)
        state[key] = nextValue
    end
end

function IT_DYNAMIC_RENDER.SetWholeNumberTextIfChanged(fontString, state, key, numberValue)
    local normalized = IT_GetWholeCooldownValue(numberValue)
    if state[key .. "Number"] ~= normalized then
        local nextValue = tostring(normalized)
        fontString:SetText(nextValue)
        state[key .. "Number"] = normalized
        state[key] = nextValue
    end
end

function IT_DYNAMIC_RENDER.SetShownIfChanged(region, state, key, shown)
    local nextValue = shown and true or false
    if state[key] ~= nextValue then
        if nextValue then
            region:Show()
        else
            region:Hide()
        end
        state[key] = nextValue
    end
end

function IT_DYNAMIC_RENDER.SetAlphaIfChanged(region, state, key, value)
    if not IT_DYNAMIC_RENDER.NearlyEqual(state[key], value) then
        region:SetAlpha(value)
        state[key] = value
    end
end

function IT_DYNAMIC_RENDER.SetDesaturatedIfChanged(texture, state, key, value)
    local nextValue = value and true or false
    if state[key] ~= nextValue then
        texture:SetDesaturated(nextValue)
        state[key] = nextValue
    end
end

function IT_DYNAMIC_RENDER.SetColorCache(state, key, r, g, b, a)
    state[key .. "R"] = r
    state[key .. "G"] = g
    state[key .. "B"] = b
    state[key .. "A"] = a
end

function IT_DYNAMIC_RENDER.IsCachedColorEqual(state, key, r, g, b, a)
    return IT_DYNAMIC_RENDER.NearlyEqual(state[key .. "R"], r)
        and IT_DYNAMIC_RENDER.NearlyEqual(state[key .. "G"], g)
        and IT_DYNAMIC_RENDER.NearlyEqual(state[key .. "B"], b)
        and IT_DYNAMIC_RENDER.NearlyEqual(state[key .. "A"], a)
end

function IT_DYNAMIC_RENDER.SetTextColorIfChanged(fontString, state, key, r, g, b, a)
    if not IT_DYNAMIC_RENDER.IsCachedColorEqual(state, key, r, g, b, a) then
        fontString:SetTextColor(r, g, b, a)
        IT_DYNAMIC_RENDER.SetColorCache(state, key, r, g, b, a)
    end
end

function IT_DYNAMIC_RENDER.SetVertexColorIfChanged(texture, state, key, r, g, b, a)
    if not IT_DYNAMIC_RENDER.IsCachedColorEqual(state, key, r, g, b, a) then
        texture:SetVertexColor(r, g, b, a)
        IT_DYNAMIC_RENDER.SetColorCache(state, key, r, g, b, a)
    end
end

function IT_DYNAMIC_RENDER.SetStatusBarColorIfChanged(bar, state, key, r, g, b, a)
    if not IT_DYNAMIC_RENDER.IsCachedColorEqual(state, key, r, g, b, a) then
        bar:SetStatusBarColor(r, g, b, a)
        IT_DYNAMIC_RENDER.SetColorCache(state, key, r, g, b, a)
    end
end

function IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(bar, state, key, minValue, maxValue, value)
    if not IT_DYNAMIC_RENDER.NearlyEqual(state[key .. "Min"], minValue)
        or not IT_DYNAMIC_RENDER.NearlyEqual(state[key .. "Max"], maxValue) then
        bar:SetMinMaxValues(minValue, maxValue)
        state[key .. "Min"] = minValue
        state[key .. "Max"] = maxValue
    end
    if not IT_DYNAMIC_RENDER.NearlyEqual(state[key .. "Value"], value) then
        bar:SetValue(value)
        state[key .. "Value"] = value
    end
end

function IT_DYNAMIC_RENDER.PositionRowUseGlowIfChanged(row, state, target)
    if (not state.useGlowTargetInitialized) or state.useGlowTarget ~= target then
        IT_PositionRowUseGlow(row, target)
        state.useGlowTarget = target
        state.useGlowTargetInitialized = true
    end
end

local function IT_GetClassDefaultInterrupt(classFile)
    if not classFile then
        return nil
    end
    local kick = IT_CLASS_PRIMARY[classFile]
    if kick and kick.id then
        local spellData = IT_INTERRUPTS[kick.id] or IT_INTERRUPTS_STR[tostring(kick.id)]
        return {
            spellID = kick.id,
            baseCd = tonumber(kick.cd) or tonumber(spellData and spellData.cd) or 15,
            name = kick.name or (spellData and spellData.name) or "",
            icon = spellData and IT_GetPrimaryIcon(kick.id) or 134400,
        }
    end

    local fallbackList = IT_CLASS_INTERRUPT_LIST[classFile]
    local fallbackSpellID = type(fallbackList) == "table" and fallbackList[1] or nil
    local fallbackData = fallbackSpellID and (IT_INTERRUPTS[fallbackSpellID] or IT_INTERRUPTS_STR[tostring(fallbackSpellID)]) or nil
    if fallbackSpellID and fallbackData then
        return {
            spellID = fallbackSpellID,
            baseCd = tonumber(fallbackData.cd) or 15,
            name = fallbackData.name or "",
            icon = IT_GetPrimaryIcon(fallbackSpellID),
        }
    end

    return nil
end

local function IT_DebugTrace(enabled, ...)
    if not enabled then
        return
    end
    local parts = { ... }
    for index = 1, #parts do
        if IT_HasSecretValues(parts[index]) then
            parts[index] = "<secret>"
        else
            parts[index] = tostring(parts[index])
        end
    end
    print("PA IT DEBUG: " .. table.concat(parts, " "))
end

local IT_ResolveTrackedInterruptSpellID
local IT_ClassSupportsInterruptSpell

local function IT_SafeSpellName(spellID)
    local resolvedSpellID = IT_NormalizeSpellID(spellID)
    if resolvedSpellID <= 0 then
        return nil
    end
    if C_Spell and C_Spell.GetSpellName then
        local okName, name = pcall(C_Spell.GetSpellName, resolvedSpellID)
        if okName and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if GetSpellInfo then
        local okInfo, name = pcall(GetSpellInfo, resolvedSpellID)
        if okInfo and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

local IT_INTERRUPT_NAME_LOOKUP = nil

local function IT_NormalizeInterruptNameKey(name)
    local safeName = IT_NormalizeSafeString(name)
    if not safeName then
        return nil
    end
    safeName = trim(safeName)
    if safeName == "" then
        return nil
    end
    return string.lower(safeName)
end

local function IT_AddUniqueSpellID(list, spellID)
    local normalizedSpellID = IT_NormalizeSpellID(spellID)
    if normalizedSpellID <= 0 then
        return
    end
    for _, existingSpellID in ipairs(list) do
        if existingSpellID == normalizedSpellID then
            return
        end
    end
    list[#list + 1] = normalizedSpellID
end

local function IT_GetInterruptNameLookup()
    if IT_INTERRUPT_NAME_LOOKUP then
        return IT_INTERRUPT_NAME_LOOKUP
    end

    local lookup = {}
    local function addSpellName(name, spellID)
        local normalizedName = IT_NormalizeInterruptNameKey(name)
        local normalizedSpellID = IT_NormalizeSpellID(spellID)
        if not normalizedName or normalizedSpellID <= 0 then
            return
        end
        lookup[normalizedName] = lookup[normalizedName] or {}
        IT_AddUniqueSpellID(lookup[normalizedName], normalizedSpellID)
    end

    for spellID, data in pairs(IT_INTERRUPTS or {}) do
        local rawSpellID, resolvedSpellID = IT_ResolveTrackedInterruptSpellID(spellID)
        local canonicalSpellID = (rawSpellID > 0 and IT_INTERRUPTS[rawSpellID]) and rawSpellID or resolvedSpellID
        addSpellName(data and data.name, canonicalSpellID)
        addSpellName(IT_SafeSpellName(spellID), canonicalSpellID)
    end

    IT_INTERRUPT_NAME_LOOKUP = lookup
    return IT_INTERRUPT_NAME_LOOKUP
end

local function IT_ResolveObservedInterruptSpellIDFromName(name, member, ownerUnit)
    local normalizedName = IT_NormalizeInterruptNameKey(name)
    if not normalizedName then
        return nil
    end

    local candidates = IT_GetInterruptNameLookup()[normalizedName]
    if type(candidates) ~= "table" or #candidates == 0 then
        return nil
    end
    if #candidates == 1 then
        return candidates[1]
    end

    local filtered = {}
    local seen = {}
    local function addCandidate(candidateSpellID)
        local normalizedSpellID = IT_NormalizeSpellID(candidateSpellID)
        if normalizedSpellID <= 0 or seen[normalizedSpellID] then
            return
        end
        filtered[#filtered + 1] = normalizedSpellID
        seen[normalizedSpellID] = true
    end
    local function matchCandidate(value)
        local rawSpellID, resolvedSpellID = IT_ResolveTrackedInterruptSpellID(value)
        for _, candidateSpellID in ipairs(candidates) do
            if candidateSpellID == rawSpellID or candidateSpellID == resolvedSpellID then
                addCandidate(candidateSpellID)
            end
        end
    end

    if member then
        matchCandidate(member.spellID)
        for _, extraKick in ipairs(member.extraKicks or {}) do
            matchCandidate(extraKick.spellID)
        end
        local override = IT_SPEC_OVERRIDE[tonumber(member.specID) or 0]
        if override then
            matchCandidate(override.id)
        end
    end

    local classFile = (member and member.class) or (ownerUnit and IT_SafeUnitClass(ownerUnit)) or nil
    if classFile then
        local classMatches = {}
        local classSeen = {}
        for _, candidateSpellID in ipairs(candidates) do
            if IT_ClassSupportsInterruptSpell(classFile, candidateSpellID) and not classSeen[candidateSpellID] then
                classMatches[#classMatches + 1] = candidateSpellID
                classSeen[candidateSpellID] = true
            end
        end
        if #classMatches == 1 then
            return classMatches[1]
        end
        for _, candidateSpellID in ipairs(classMatches) do
            addCandidate(candidateSpellID)
        end
    end

    if #filtered == 1 then
        return filtered[1]
    end

    return nil
end

local function IT_ResolveObservedInterruptSpellIDFromPayload(payload, member, ownerUnit)
    local rawSpellID, resolvedSpellID, tracked = IT_ResolveTrackedInterruptSpellID(payload)
    if tracked then
        return (rawSpellID > 0 and IT_INTERRUPTS[rawSpellID]) and rawSpellID or resolvedSpellID, "spell_id"
    end

    local observedSpellID = IT_ResolveObservedInterruptSpellIDFromName(payload, member, ownerUnit)
    if observedSpellID then
        return observedSpellID, "spell_name"
    end

    return nil, nil
end

local function IT_ResolveObservedInterruptSpellIDFromEventArgs(source, ownerUnit, member, ...)
    local argCount = select("#", ...)
    if argCount <= 0 then
        return nil, nil
    end

    local startIndex = 1
    if source == "sent" and argCount >= 2 then
        startIndex = 2
    end

    for index = argCount, startIndex, -1 do
        local payload = select(index, ...)
        local observedSpellID, observedKind = IT_ResolveObservedInterruptSpellIDFromPayload(payload, member, ownerUnit)
        if observedSpellID then
            return observedSpellID, observedKind
        end
    end

    if source == "sent" and startIndex > 1 then
        local leadingSpellID = IT_ResolveObservedInterruptSpellIDFromName(select(1, ...), member, ownerUnit)
        if leadingSpellID then
            return leadingSpellID, "spell_name"
        end
    end

    return nil, nil
end

local function IT_FindMatchingExtraKick(member, spellID)
    if not member or type(member.extraKicks) ~= "table" then
        return nil
    end

    local rawSpellID, resolvedSpellID = IT_ResolveTrackedInterruptSpellID(spellID)
    for _, extraKick in ipairs(member.extraKicks) do
        local extraRawSpellID, extraResolvedSpellID = IT_ResolveTrackedInterruptSpellID(extraKick.spellID)
        if extraKick.spellID == spellID
            or extraKick.spellID == rawSpellID
            or extraKick.spellID == resolvedSpellID
            or extraRawSpellID == rawSpellID
            or extraRawSpellID == resolvedSpellID
            or extraResolvedSpellID == rawSpellID
            or extraResolvedSpellID == resolvedSpellID
        then
            return extraKick
        end
    end

    return nil
end

local function IT_GetCanonicalInterruptBaseCd(spellID, fallbackCd)
    local spellData = spellID and (IT_INTERRUPTS[spellID] or IT_INTERRUPTS_STR[tostring(spellID)]) or nil
    local canonical = tonumber(spellData and spellData.cd)
    if canonical and canonical > 0 then
        return canonical
    end
    canonical = tonumber(fallbackCd)
    if canonical and canonical > 0 then
        return canonical
    end
    canonical = IT_SafeBaseCooldown(spellID)
    if canonical and canonical > 0 then
        return canonical
    end
    return nil
end

local function IT_GetPreviewModeBPrimary(entry)
    if type(entry) ~= "table" then
        return nil
    end
    local override = entry.specID and IT_SPEC_OVERRIDE[tonumber(entry.specID) or 0] or nil
    local primary = override and {
        spellID = tonumber(override.id) or 0,
        baseCd = IT_GetCanonicalInterruptBaseCd(override.id, override.cd) or tonumber(override.cd) or 15,
        name = override.name or "",
        icon = IT_GetPrimaryIcon(override.id),
        isPetSpell = override.isPet and true or false,
        petSpellID = override.petSpellID or nil,
    } or IT_GetClassDefaultInterrupt(entry.class)
    if not primary or not primary.spellID then
        return nil
    end
    return primary
end

IT_ResolveTrackedInterruptSpellID = function(spellID)
    local rawSpellID = IT_NormalizeSpellID(spellID)
    if rawSpellID <= 0 then
        return rawSpellID, rawSpellID, false
    end
    local resolvedSpellID = IT_NormalizeSpellID(IT_SPELL_ALIASES[rawSpellID] or rawSpellID)
    if resolvedSpellID <= 0 then
        resolvedSpellID = rawSpellID
    end
    local tracked = IT_INTERRUPTS[rawSpellID]
        or IT_INTERRUPTS[resolvedSpellID]
        or IT_INTERRUPTS_STR[tostring(rawSpellID)]
        or IT_INTERRUPTS_STR[tostring(resolvedSpellID)]
    return rawSpellID, resolvedSpellID, tracked ~= nil
end

local function IT_GetObservedSpecOverride(spellID)
    local rawSpellID, resolvedSpellID = IT_ResolveTrackedInterruptSpellID(spellID)
    for specID, override in pairs(IT_SPEC_OVERRIDE or {}) do
        local overrideSpellID = tonumber(override and override.id) or 0
        if overrideSpellID > 0 and (overrideSpellID == rawSpellID or overrideSpellID == resolvedSpellID) then
            return specID, override
        end
    end
    return nil, nil
end

IT_ClassSupportsInterruptSpell = function(classFile, spellID)
    if not classFile then
        return false
    end
    local rawSpellID, resolvedSpellID = IT_ResolveTrackedInterruptSpellID(spellID)
    for _, candidateSpellID in ipairs(IT_CLASS_INTERRUPT_LIST[classFile] or {}) do
        local candidateRaw, candidateResolved = IT_ResolveTrackedInterruptSpellID(candidateSpellID)
        if candidateRaw == rawSpellID
            or candidateRaw == resolvedSpellID
            or candidateResolved == rawSpellID
            or candidateResolved == resolvedSpellID
        then
            return true
        end
    end
    return false
end

local InterruptTrackerShared = {}

function InterruptTrackerShared.GetDBRoot()
    RRT = RRT or {}
    RRT.InterruptTracker = RRT.InterruptTracker or {}
    return RRT.InterruptTracker
end

function InterruptTrackerShared.ApplyDefaultValues(db)
    db = type(db) == "table" and db or {}

    if db.locked == nil then db.locked = false end
    if db.x == nil then db.x = 0 end
    if db.y == nil then db.y = 0 end
    if db.width == nil then db.width = 220 end
    if db.rowHeight == nil then db.rowHeight = 22 end
    if db.rowGap == nil then db.rowGap = IT_ROW_GAP_DEFAULT end
    if db.fontPath == nil then db.fontPath = "" end
    if db.fontSize == nil then db.fontSize = 12 end
    if db.fontColor == nil then db.fontColor = { r = 1, g = 1, b = 1, a = 1 } end
    if db.backgroundOpacity == nil then db.backgroundOpacity = IT_BG_BAR[4] end
    if db.barTexture == nil then db.barTexture = "Overclock: Stormy Clean" end
    if db.useClassColors == nil then db.useClassColors = true end
    if db.showClassIcon == nil then db.showClassIcon = true end
    if db.showSpellIcon == nil then db.showSpellIcon = true end
    if db.alertSound == nil then db.alertSound = "" end
    if db.selfOnlyAlert == nil then db.selfOnlyAlert = false end
    if db.rotationEnabled == nil then db.rotationEnabled = true end
    if db.rightDisplay == nil then db.rightDisplay = "count" end
    if type(db.rotationOrder) ~= "table" then db.rotationOrder = {} end
    if db.rotationIndex == nil then db.rotationIndex = 1 end

    return db
end

function InterruptTrackerShared.NormalizeDB(db)
    db = InterruptTrackerShared.ApplyDefaultValues(db)

    db.locked = not not db.locked
    db.x = math.floor(tonumber(db.x) or 0)
    db.y = math.floor(tonumber(db.y) or 0)
    db.width = math.floor(clampNumber(db.width, 220, 160, 420))
    db.rowHeight = math.floor(clampNumber(db.rowHeight, 22, 18, 42))
    db.rowGap = IT_GetConfiguredRowGap(db)
    db.fontPath = trim(db.fontPath)
    db.fontSize = math.floor(clampNumber(db.fontSize, 12, 8, 24))
    db.fontColor = IT_CopyColor(db.fontColor)
    db.backgroundOpacity = IT_GetConfiguredRowBackgroundOpacity(db)
    db.barTexture = trim(tostring(db.barTexture or "Overclock: Stormy Clean"))
    if db.barTexture == "" then
        db.barTexture = "Overclock: Stormy Clean"
    end
    db.useClassColors = not not db.useClassColors
    db.showClassIcon = not not db.showClassIcon
    db.showSpellIcon = not not db.showSpellIcon
    db.alertSound = db.alertSound or ""
    db.selfOnlyAlert = not not db.selfOnlyAlert
    db.rotationEnabled = true
    db.rightDisplay = db.rightDisplay == "timer" and "timer" or "count"
    db.rotationOrder = IT_NormalizeNameList(db.rotationOrder)
    if db.rotationIndex < 1 then
        db.rotationIndex = 1
    end

    return db
end

function InterruptTrackerShared.EnsureDB()
    return InterruptTrackerShared.NormalizeDB(InterruptTrackerShared.GetDBRoot())
end

function InterruptTrackerShared.ResolveFont(db, globalFontPath, globalFontFlags)
    db = InterruptTrackerShared.ApplyDefaultValues(db)

    local path = trim(db.fontPath)
    local flags = "OUTLINE"
    if path == "" then
        path = trim(globalFontPath)
        if trim(globalFontFlags) ~= "" then
            flags = trim(globalFontFlags)
        end
    end
    if path == "" then
        path = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end
    return path, db.fontSize or 12, flags
end

local InterruptTracker = {
    key = "interruptTracker",
    _shared = InterruptTrackerShared,
    skipSharedAutoEvaluateVisibility = true,
}

-- DB / value helpers
function InterruptTracker:EnsureDB()
    return InterruptTrackerShared.EnsureDB()
end

function InterruptTracker:GetDB()
    return self:EnsureDB()
end

function InterruptTracker:IsEnabled()
    local db = self:GetDB()
    return db.enabled ~= false
end

function InterruptTracker:GetFont()
    return InterruptTrackerShared.ResolveFont(self:GetDB(), nil, nil)
end

function InterruptTracker:GetBarTexture()
    return IT_GetMediaTexturePath(self:GetDB().barTexture)
end

function InterruptTracker:IsTrackedPartyContext()
    if IsInRaid and IsInRaid() then
        return false
    end
    return (GetNumSubgroupMembers and (GetNumSubgroupMembers() or 0) > 0) and true or false
end

function InterruptTracker:IsSupportedLiveContext()
    return IT_IsSupportedDungeon() and self:IsTrackedPartyContext()
end

function InterruptTracker:IsActiveChallengeRun()
    return IT_IsChallengeModeActive() and true or false
end

function InterruptTracker:ShouldAllowPartyInspectRefresh()
    return self:IsEnabled()
        and self:IsSupportedLiveContext()
        and self:IsTrackedPartyContext()
        and not self:IsActiveChallengeRun()
        and not self:IsIdentityFrozen()
end

function InterruptTracker:IsPreviewMode()
    return self:IsEnabled() and self.unlocked and true or false
end

function InterruptTracker:GetCurrentContextKey()
    return IT_GetContextKey()
end

function InterruptTracker:ResetPreviewState()
    self.previewStartedAt = 0
    self.previewCycleOffsetByKey = {}
    if type(self.rowReadyState) == "table" then
        for key in pairs(self.rowReadyState) do
            if type(key) == "string" and string.find(key, "^preview:") then
                self.rowReadyState[key] = nil
            end
        end
    end
end

function InterruptTracker:EnsurePreviewState(now)
    if (tonumber(self.previewStartedAt) or 0) <= 0 then
        self.previewStartedAt = now or GetTime()
    end
    self.previewCycleOffsetByKey = self.previewCycleOffsetByKey or {}
end

function InterruptTracker:ResetDisplayStructureState()
    self._displayIdentityDirty = true
    self._displayStructureDirty = true
    self._displayDynamicDirty = true
    self._displayStructureDirtyReason = "reset"
    self._displayStructureSignature = nil
    self._displayAssignments = nil
    self._displayTickMemberState = nil
    self._displayRowCount = 0
    self._displayModeB = nil
    self._displayPreviewMode = nil
    self._visibleRowPulseTargets = {}
    self._displayNextSafetyAt = 0
    self._displaySafetyPending = true
end

function InterruptTracker:GetDisplayDirtyRank(kind)
    if kind == "identity" then
        return 3
    end
    if kind == "structure" then
        return 2
    end
    return 1
end

function InterruptTracker:MarkDisplayIdentityDirty(reason)
    self._displayIdentityDirty = true
    self._displayStructureDirty = true
    self._displayDynamicDirty = true
    self._displaySafetyPending = true
    self._displayNextSafetyAt = (self._displayNextSafetyAt and self._displayNextSafetyAt > 0) and self._displayNextSafetyAt or (GetTime() + IT_STRUCTURE_SAFETY_DEADLINE)
    if reason ~= nil then
        self._displayStructureDirtyReason = tostring(reason)
    end
end

function InterruptTracker:MarkDisplayStructureDirty(reason)
    self._displayStructureDirty = true
    self._displayDynamicDirty = true
    self._displaySafetyPending = true
    self._displayNextSafetyAt = (self._displayNextSafetyAt and self._displayNextSafetyAt > 0) and self._displayNextSafetyAt or (GetTime() + IT_STRUCTURE_SAFETY_DEADLINE)
    if reason ~= nil then
        self._displayStructureDirtyReason = tostring(reason)
    end
end

function InterruptTracker:MarkDisplayDynamicDirty()
    self._displayDynamicDirty = true
end

function InterruptTracker:ClearPendingDisplayRefresh()
    if self.pendingDisplayRefreshTimer then
        self.pendingDisplayRefreshTimer:Cancel()
        self.pendingDisplayRefreshTimer = nil
    end
    self.pendingDisplayRefreshKind = nil
    self.pendingDisplayRefreshReason = nil
    self.pendingDisplayRefreshAt = 0
end

function InterruptTracker:ApplyPendingDisplayDirty(kind, reason)
    if kind == "identity" then
        self:MarkDisplayIdentityDirty(reason)
    elseif kind == "structure" then
        self:MarkDisplayStructureDirty(reason)
    else
        self:MarkDisplayDynamicDirty()
    end
end

function InterruptTracker:ScheduleCoalescedDisplayRefresh(kind, reason, delaySeconds)
    local kindKey = kind == "identity" and "identity" or (kind == "structure" and "structure" or "dynamic")
    local now = GetTime()
    local delay = math.max(0, tonumber(delaySeconds) or IT_COALESCED_REFRESH_DELAY)
    local dueAt = now + delay
    self:ApplyPendingDisplayDirty(kindKey, reason)

    local currentRank = self:GetDisplayDirtyRank(self.pendingDisplayRefreshKind)
    local nextRank = self:GetDisplayDirtyRank(kindKey)
    if not self.pendingDisplayRefreshTimer then
        self.pendingDisplayRefreshKind = kindKey
        self.pendingDisplayRefreshReason = reason
        self.pendingDisplayRefreshAt = dueAt
        self.pendingDisplayRefreshTimer = C_Timer.NewTimer(delay, function()
            self.pendingDisplayRefreshTimer = nil
            self.pendingDisplayRefreshKind = nil
            self.pendingDisplayRefreshReason = nil
            self.pendingDisplayRefreshAt = 0
            self:EvaluateVisibility("coalesced")
        end)
        return
    end

    if nextRank > currentRank then
        self.pendingDisplayRefreshKind = kindKey
        self.pendingDisplayRefreshReason = reason
    end
    if dueAt < (tonumber(self.pendingDisplayRefreshAt) or 0) then
        self:ClearPendingDisplayRefresh()
        self.pendingDisplayRefreshKind = kindKey
        self.pendingDisplayRefreshReason = reason
        self.pendingDisplayRefreshAt = dueAt
        self.pendingDisplayRefreshTimer = C_Timer.NewTimer(delay, function()
            self.pendingDisplayRefreshTimer = nil
            self.pendingDisplayRefreshKind = nil
            self.pendingDisplayRefreshReason = nil
            self.pendingDisplayRefreshAt = 0
            self:EvaluateVisibility("coalesced")
        end)
    end
end

function InterruptTracker:RecordRelevantTrackerActivity(timestamp)
    self.lastRelevantTrackerActivityAt = tonumber(timestamp) or GetTime()
end

function InterruptTracker:CancelPendingPartyCreditPoolTimer()
    if self.pendingPartyCreditPoolTimer then
        self.pendingPartyCreditPoolTimer:Cancel()
        self.pendingPartyCreditPoolTimer = nil
    end
end

function InterruptTracker:ClearConsumedMobInterruptConfirmations()
    self.consumedMobInterruptConfirmations = {}
end

function InterruptTracker:ResetPendingPartyCreditRuntime()
    self:CancelPendingPartyCreditPoolTimer()
    self.pendingPartyCreditPool = nil
    self.pendingPartyCreditPoolId = 0
    self.nextPendingPartyCreditCandidateId = 0
    self:ClearConsumedMobInterruptConfirmations()
end

function InterruptTracker:PruneConsumedMobInterruptConfirmations(now)
    now = tonumber(now) or GetTime()
    for key, consumedAt in pairs(self.consumedMobInterruptConfirmations or {}) do
        if (now - (tonumber(consumedAt) or 0)) > IT_MOB_INTERRUPT_DUPLICATE_WINDOW then
            self.consumedMobInterruptConfirmations[key] = nil
        end
    end
end

function InterruptTracker:GetMobInterruptConfirmationKey(interruptedUnit, timestamp)
    local guid = interruptedUnit and IT_SafeUnitGUID(interruptedUnit) or nil
    if guid then
        return "guid:" .. guid
    end
    if type(interruptedUnit) == "string" and interruptedUnit ~= "" then
        return "unit:" .. interruptedUnit
    end
    return nil
end

function InterruptTracker:HasConsumedMobInterruptConfirmation(confirmKey, now)
    if not confirmKey then
        return false
    end
    now = tonumber(now) or GetTime()
    self:PruneConsumedMobInterruptConfirmations(now)
    local consumedAt = self.consumedMobInterruptConfirmations and self.consumedMobInterruptConfirmations[confirmKey] or nil
    return consumedAt ~= nil and (now - (tonumber(consumedAt) or 0)) <= IT_MOB_INTERRUPT_DUPLICATE_WINDOW
end

function InterruptTracker:MarkMobInterruptConfirmationConsumed(confirmKey, now)
    if not confirmKey then
        return false
    end
    now = tonumber(now) or GetTime()
    self.consumedMobInterruptConfirmations = self.consumedMobInterruptConfirmations or {}
    self:PruneConsumedMobInterruptConfirmations(now)
    if self:HasConsumedMobInterruptConfirmation(confirmKey, now) then
        return false
    end
    self.consumedMobInterruptConfirmations[confirmKey] = now
    self.lastHandledInterruptedGUID = confirmKey
    self.lastHandledInterruptedAt = now
    return true
end

function InterruptTracker:StartExtraKickCooldownUse(member, spellID, source, timestamp, refreshKind, refreshReason)
    if not member or not member.extraKicks then
        return false
    end
    local resolvedSpellID = IT_SPELL_ALIASES[spellID] or spellID
    local observedAt = tonumber(timestamp) or GetTime()
    for _, extra in ipairs(member.extraKicks) do
        if extra.spellID == spellID or extra.spellID == resolvedSpellID then
            extra.cdEnd = observedAt + (tonumber(extra.baseCd) or 0)
            self:MarkFullWipeRecoveryEvidence(member, observedAt)
            self:RecordRelevantTrackerActivity(observedAt)
            self:RequestDisplayRefresh(refreshKind or "structure", refreshReason or "confirmed-extra", PA_CpuDiagIsFrameConsideredShown("interrupt", self.frame))
            return extra
        end
    end
    return false
end

function InterruptTracker:CommitInterruptCredit(member, spellID, source, timestamp, refreshKind, refreshReason)
    if not member or not spellID then
        return false
    end
    local counted = self:TryCountInterrupt(member, spellID, source, tonumber(timestamp) or GetTime())
    if counted and refreshKind then
        self:RequestDisplayRefresh(refreshKind, refreshReason or "interrupt-credit", PA_CpuDiagIsFrameConsideredShown("interrupt", self.frame))
    end
    return counted
end

function InterruptTracker:StartPrimaryCooldownUse(member, cooldownSeconds, source, timestamp, refreshKind, refreshReason)
    if not member or not member.spellID then
        return false
    end
    local observedAt = tonumber(timestamp) or GetTime()
    local cooldown = tonumber(cooldownSeconds) or member.baseCd or tonumber((IT_INTERRUPTS[member.spellID] or {}).cd) or 15
    member.cdEnd = observedAt + cooldown
    member.pendingOnKickReduction = member.isSelf and (member.onKickReduction and true or false) or false
    if (not member.isSelf) and member.onKickReduction then
        member.cdEnd = math.max(observedAt, member.cdEnd - tonumber(member.onKickReduction or 0))
    end
    member.lastConfirmedAt = observedAt
    if member.isSelf then
        self.selfLastPrimaryCastAt = observedAt
        self:ClearOwnerInterruptPending()
    end
    self:MarkFullWipeRecoveryEvidence(member, observedAt)
    self:RecordRelevantTrackerActivity(observedAt)
    self:RequestDisplayRefresh(refreshKind or "structure", refreshReason or "confirmed-primary", PA_CpuDiagIsFrameConsideredShown("interrupt", self.frame))
    return true
end

function InterruptTracker:GetPendingPartyCreditCandidateName(candidate)
    return IT_NormalizeName(candidate and (candidate.name or (candidate.member and candidate.member.name)))
end

function InterruptTracker:GetPendingPartyCreditPoolActiveCandidates(pool)
    local active = {}
    for _, candidate in ipairs((pool and pool.candidates) or {}) do
        if candidate and not candidate.retired and not candidate.committed then
            active[#active + 1] = candidate
        end
    end
    return active
end

function InterruptTracker:SelectBestPendingPartyCreditCandidate(candidates)
    local best = nil
    for _, candidate in ipairs(candidates or {}) do
        if not best then
            best = candidate
        elseif (tonumber(candidate.observedAt) or 0) > (tonumber(best.observedAt) or 0) then
            best = candidate
        end
    end
    return best
end

function InterruptTracker:RemoveRecentPartyCastForCandidate(candidate)
    local candidateName = self:GetPendingPartyCreditCandidateName(candidate)
    if not candidateName then
        return
    end
    local record = self:GetRecentPartyCastRecord(candidateName)
    if not record then
        return
    end
    local candidateSpellID = IT_NormalizeSpellID(candidate and candidate.spellID)
    if candidateSpellID > 0 and record.spellID > 0 and not self:RecentPartyCastMatchesSpell(record, candidateSpellID) then
        return
    end
    local recordAt = tonumber(record.at) or 0
    local candidateAt = tonumber(candidate and candidate.observedAt) or 0
    if candidateAt > 0 and math.abs(recordAt - candidateAt) > IT_OBSERVED_CAST_COALESCE_WINDOW then
        return
    end
    if self.recentPartyCasts then
        self.recentPartyCasts[candidateName] = nil
    end
end

function InterruptTracker:FinalizePendingPartyCreditCandidate(candidate, shouldCredit, source, timestamp, refreshKind, refreshReason)
    if not candidate or candidate.retired or candidate.committed then
        return false
    end
    local finalizedAt = tonumber(timestamp) or GetTime()
    candidate.committed = true
    candidate.retired = true
    candidate.retiredAt = finalizedAt
    candidate.retiredReason = source or (shouldCredit and "credited" or "retired")
    if shouldCredit then
        candidate.credited = true
        self:CommitInterruptCredit(candidate.member, candidate.spellID, source or "party_pool", finalizedAt, refreshKind, refreshReason)
    end
    self:RemoveRecentPartyCastForCandidate(candidate)
    return true
end

function InterruptTracker:SchedulePendingPartyCreditPoolExpiry(pool)
    if not pool then
        return
    end
    self:CancelPendingPartyCreditPoolTimer()
    local delay = math.max(0, (tonumber(pool.closesAt) or GetTime()) - GetTime())
    local poolId = tonumber(pool.id) or 0
    self.pendingPartyCreditPoolTimer = C_Timer.NewTimer(delay, function()
        if not self.pendingPartyCreditPool or tonumber(self.pendingPartyCreditPool.id) ~= poolId then
            return
        end
        self.pendingPartyCreditPoolTimer = nil
        self:ResolveExpiredPendingPartyCreditPool(GetTime())
    end)
end

function InterruptTracker:EnsurePendingPartyCreditPool(now)
    now = tonumber(now) or GetTime()
    local pool = self.pendingPartyCreditPool
    if pool and now <= (tonumber(pool.closesAt) or 0) then
        for _, candidate in ipairs(pool.candidates or {}) do
            if candidate and not candidate.retired and not candidate.committed then
                return pool
            end
        end
    end

    self:CancelPendingPartyCreditPoolTimer()
    self.pendingPartyCreditPoolId = (tonumber(self.pendingPartyCreditPoolId) or 0) + 1
    pool = {
        id = self.pendingPartyCreditPoolId,
        openedAt = now,
        closesAt = now + IT_PARTY_CREDIT_RESOLUTION_WINDOW,
        candidates = {},
    }
    self.pendingPartyCreditPool = pool
    self:SchedulePendingPartyCreditPoolExpiry(pool)
    return pool
end

function InterruptTracker:AddPendingPartyCreditCandidate(member, spellID, source, timestamp, availabilityStarted)
    if not member or member.isSelf then
        return nil
    end
    local observedAt = tonumber(timestamp) or GetTime()
    self:ResolveExpiredPendingPartyCreditPool(observedAt)
    local pool = self:EnsurePendingPartyCreditPool(observedAt)
    local candidate = {
        id = (tonumber(self.nextPendingPartyCreditCandidateId) or 0) + 1,
        member = member,
        name = IT_NormalizeName(member.name),
        spellID = IT_NormalizeSpellID(spellID),
        source = IT_NormalizeSafeString(source) or "succeeded",
        observedAt = observedAt,
        availabilityStarted = availabilityStarted and true or false,
        credited = false,
        committed = false,
        retired = false,
    }
    self.nextPendingPartyCreditCandidateId = candidate.id
    pool.candidates[#pool.candidates + 1] = candidate
    return candidate
end

function InterruptTracker:ResolvePendingPartyCreditPoolConfirmation(interruptedUnit, now, shouldCredit, source, refreshKind, refreshReason)
    now = tonumber(now) or GetTime()
    self:ResolveExpiredPendingPartyCreditPool(now)
    local pool = self.pendingPartyCreditPool
    if not pool or now > (tonumber(pool.closesAt) or 0) then
        return false
    end
    local activeCandidates = self:GetPendingPartyCreditPoolActiveCandidates(pool)
    local bestCandidate = self:SelectBestPendingPartyCreditCandidate(activeCandidates)
    if not bestCandidate then
        return false
    end
    local finalized = self:FinalizePendingPartyCreditCandidate(bestCandidate, shouldCredit, source, now, refreshKind, refreshReason)
    if finalized and #self:GetPendingPartyCreditPoolActiveCandidates(pool) == 0 then
        self:CancelPendingPartyCreditPoolTimer()
        self.pendingPartyCreditPool = nil
    end
    return finalized
end

function InterruptTracker:ResolveExpiredPendingPartyCreditPool(now)
    now = tonumber(now) or GetTime()
    local pool = self.pendingPartyCreditPool
    if not pool or now < (tonumber(pool.closesAt) or 0) then
        return false
    end

    self:CancelPendingPartyCreditPoolTimer()
    local activeCandidates = self:GetPendingPartyCreditPoolActiveCandidates(pool)
    local bestCandidate = nil
    if #activeCandidates == 1 then
        bestCandidate = activeCandidates[1]
    elseif #activeCandidates > 1 then
        bestCandidate = self:SelectBestPendingPartyCreditCandidate(activeCandidates)
    end

    if bestCandidate then
        self:FinalizePendingPartyCreditCandidate(bestCandidate, true, "party_pool_expiry", now, "dynamic", "party-credit-expiry")
    end
    for _, candidate in ipairs(pool.candidates or {}) do
        if candidate and not candidate.retired and not candidate.committed then
            self:FinalizePendingPartyCreditCandidate(candidate, false, "party_pool_expired", now, nil, nil)
        end
    end
    self.pendingPartyCreditPool = nil
    return bestCandidate and true or false
end

function InterruptTracker:RetirePendingPartyCreditCandidatesForMissingRoster(current, now)
    local pool = self.pendingPartyCreditPool
    if not pool then
        return
    end
    now = tonumber(now) or GetTime()
    current = current or {}
    for _, candidate in ipairs(pool.candidates or {}) do
        local candidateName = self:GetPendingPartyCreditCandidateName(candidate)
        if candidateName and not current[candidateName] and not candidate.retired and not candidate.committed then
            self:FinalizePendingPartyCreditCandidate(candidate, false, "pool-roster-removed", now, nil, nil)
        end
    end
    if #self:GetPendingPartyCreditPoolActiveCandidates(pool) == 0 then
        self:CancelPendingPartyCreditPoolTimer()
        self.pendingPartyCreditPool = nil
    end
end

function InterruptTracker:IsIdentityFrozen()
    return self.identityFrozen and true or false
end

function InterruptTracker:SetIdentityFrozen(frozen)
    self.identityFrozen = frozen and true or false
end

function InterruptTracker:ClearRuntimeDisplayLifecycleState()
    self:ClearPendingDisplayRefresh()
    self.lastRelevantTrackerActivityAt = 0
    self.tickerRate = 0
    self._displayNextSafetyAt = 0
    self._displaySafetyPending = false
end

function InterruptTracker:GetDesiredTickerRate(now)
    if not (self.frame and PA_CpuDiagIsFrameConsideredShown("interrupt", self.frame)) then
        return nil
    end
    now = tonumber(now) or GetTime()
    local lastRelevantAt = tonumber(self.lastRelevantTrackerActivityAt) or 0
    if lastRelevantAt > 0 and (now - lastRelevantAt) < IT_ACTIVITY_CALM_THRESHOLD then
        return IT_ACTIVE_DISPLAY_TICK
    end
    return IT_CALM_DISPLAY_TICK
end

function InterruptTracker:ShouldRunStructuralDisplayPass(now)
    if self:IsPreviewMode() then
        return true
    end
    if self._displayIdentityDirty or self._displayStructureDirty then
        return true
    end
    if type(self._displayAssignments) ~= "table" then
        return true
    end
    return self._displaySafetyPending
        and (tonumber(self._displayNextSafetyAt) or 0) > 0
        and (tonumber(self._displayNextSafetyAt) or 0) <= (tonumber(now) or GetTime())
end

function InterruptTracker:NoteStructuralDisplayPass(now, viaSafetyNet)
    self._displayIdentityDirty = false
    self._displayStructureDirty = false
    self._displayDynamicDirty = false
    if viaSafetyNet then
        self._displayNextSafetyAt = 0
        self._displaySafetyPending = false
    else
        self._displayNextSafetyAt = (tonumber(now) or GetTime()) + IT_STRUCTURE_SAFETY_DEADLINE
        self._displaySafetyPending = true
    end
end

function InterruptTracker:NoteDynamicDisplayPass()
    self._displayDynamicDirty = false
end

function InterruptTracker:RequestDisplayRefresh(kind, reason, immediate)
    local resolvedKind = kind == "identity" and "identity" or (kind == "structure" and "structure" or "dynamic")
    self:ApplyPendingDisplayDirty(resolvedKind, reason)
    if immediate then
        self:ClearPendingDisplayRefresh()
        self:EvaluateVisibility(reason)
        return
    end
    self:ScheduleCoalescedDisplayRefresh(resolvedKind, reason)
end

function InterruptTracker:BuildDisplayStructureSignature(db, rowsData, modeB, previewMode)
    local parts = {
        previewMode and "preview" or "live",
        modeB and "modeB" or "modeA",
        tostring(math.floor(tonumber(db and db.width) or 0)),
        tostring(math.floor(tonumber(db and db.rowHeight) or 0)),
        tostring(math.floor(tonumber(self:GetRowGap()) or 0)),
        tostring((db and db.rightDisplay) == "timer" and "timer" or "count"),
        tostring(db and db.showClassIcon and 1 or 0),
        tostring(db and db.showSpellIcon and 1 or 0),
        tostring(#(rowsData or {})),
    }

    for index, member in ipairs(rowsData or {}) do
        parts[#parts + 1] = table.concat({
            tostring(index),
            member and member.isSelf and "self" or "party",
            tostring(IT_NormalizeName(member and member.name) or (member and member.name) or ""),
            tostring(member and member.class or ""),
            tostring(math.floor(tonumber(member and member.spellID) or 0)),
            tostring(math.floor(tonumber(member and member.baseCd) or 0)),
            tostring(member and member.previewUseClassIcon and 1 or 0),
        }, ":")
    end

    return table.concat(parts, "|")
end

function InterruptTracker:RefreshDisplayAssignmentMembers(rowsData, modeB)
    local assignments = self._displayAssignments
    local tickMemberState = self._displayTickMemberState
    if type(assignments) ~= "table" or #assignments ~= #(rowsData or {}) then
        return false
    end

    for index, assignment in ipairs(assignments) do
        local member = rowsData[index]
        if not assignment or not assignment.row or not member then
            return false
        end
        assignment.member = member
        assignment.modeB = modeB and true or false
        assignment.tickState = tickMemberState and tickMemberState[member] or nil
        assignment.row._displayMember = member
        assignment.row._displayModeB = modeB and true or false
    end

    return true
end

function InterruptTracker:ResetCounts()
    self.interruptCounts = {}
    self.recentCountedInterruptsByMember = {}
    self:ClearOwnerInterruptPending()
    self:ResetPendingPartyCreditRuntime()
    self:RequestDisplayRefresh("dynamic", "counts-reset", PA_CpuDiagIsFrameConsideredShown("interrupt", self.frame))
end

function InterruptTracker:UpdateRunContext()
    local newKey = self:GetCurrentContextKey()
    local activeRun = self:IsActiveChallengeRun()
    self.activeChallengeRun = activeRun and true or false
    if not activeRun and self:IsIdentityFrozen() then
        self:SetIdentityFrozen(false)
    end
    if self.contextKey ~= newKey then
        self.contextKey = newKey
        self:ResetAvailabilityGate(newKey)
        self:ResetFullWipeRecoveryState()
        self:ResetCounts()
    end
end

function InterruptTracker:ResetAvailabilityGate(newContextKey)
    self.availabilityArmed = false
    self.availabilityContextKey = newContextKey
end

function InterruptTracker:IsAnyTrackedPartyUnitInCombat()
    if UnitAffectingCombat and UnitExists("player") and UnitAffectingCombat("player") then
        return true
    end
    if not UnitAffectingCombat then
        return false
    end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitAffectingCombat(unit) then
            return true
        end
    end
    return false
end

function InterruptTracker:RefreshAvailabilityGate()
    local currentKey = self:GetCurrentContextKey()
    if not self:IsSupportedLiveContext() then
        self.availabilityArmed = false
        self.availabilityContextKey = nil
        return
    end
    if self.availabilityContextKey ~= currentKey then
        self:ResetAvailabilityGate(currentKey)
    end
    if self.availabilityArmed then
        return
    end
    if self:IsAnyTrackedPartyUnitInCombat() then
        self.availabilityArmed = true
    end
end

function InterruptTracker:ResetFullWipeRecoveryState()
    self.pendingFullWipeRecovery = false
    self.fullWipeRecoveryActive = false
    self.fullWipeRecoveryStartedAt = 0
    self.lastPartyCombatSeenAt = 0
    self.lastPlayerDeadOrGhost = IT_IsUnitRealDeadOrGhost("player")
    if self.selfState then
        self.selfState.lastDeathAt = 0
        self.selfState.lastDeadOrGhost = false
        self.selfState.fullWipeRecoverySeenAt = 0
    end
    for _, member in pairs(self.trackedMembers or {}) do
        member.lastDeathAt = 0
        member.lastDeadOrGhost = false
        member.fullWipeRecoverySeenAt = 0
    end
end

function InterruptTracker:GetTrackedAvailabilityMembers()
    local tracked = {}
    if self:MemberQualifiesForSeed(self.selfState) then
        tracked[#tracked + 1] = self.selfState
    end
    for _, member in pairs(self.trackedMembers or {}) do
        if self:MemberQualifiesForSeed(member) then
            tracked[#tracked + 1] = member
        end
    end
    return tracked
end

function InterruptTracker:GetResolvedTrackedWipeMembers()
    local tracked = self:GetTrackedAvailabilityMembers()

    if #tracked == 0 then
        return {}, false
    end

    local resolved = {}
    local seenUnits = {}
    local complete = true
    for _, member in ipairs(tracked) do
        local unit = self:GetMemberUnitToken(member)
        if unit and UnitExists(unit) and not seenUnits[unit] then
            resolved[#resolved + 1] = {
                member = member,
                unit = unit,
            }
            seenUnits[unit] = true
        else
            complete = false
        end
    end

    if #resolved ~= #tracked then
        complete = false
    end
    return resolved, complete
end

function InterruptTracker:MarkFullWipeRecoveryEvidence(member, now)
    if not self.fullWipeRecoveryActive or not member then
        return
    end
    member.fullWipeRecoverySeenAt = tonumber(now) or GetTime()
end

function InterruptTracker:ClearInterruptCountRecordsForMember(name, guid)
    self.recentCountedInterruptsByMember = self.recentCountedInterruptsByMember or {}
    local normalized = IT_NormalizeName(type(name) == "table" and name.name or name)
    local resolvedGUID = IT_NormalizeSafeString(guid)
    if not resolvedGUID and type(name) == "table" then
        resolvedGUID = self:GetMemberResolvedGUID(name)
    end
    if normalized then
        self.recentCountedInterruptsByMember["name:" .. normalized] = nil
    end
    if resolvedGUID then
        self.recentCountedInterruptsByMember["guid:" .. resolvedGUID] = nil
    end
end

function InterruptTracker:ClearFullWipeRecordsForMember(member)
    if not member then
        return
    end
    member.lastDeathAt = 0
    member.lastDeadOrGhost = false
    member.fullWipeRecoverySeenAt = 0
end

function InterruptTracker:MergeInterruptCountRecords(target, source)
    target = target or {}
    if type(source) ~= "table" then
        return target
    end
    for spellID, record in pairs(source) do
        local existing = target[spellID]
        if existing then
            existing.countedAt = math.max(tonumber(existing.countedAt) or 0, tonumber(record.countedAt) or 0)
            existing.lastSeenAt = math.max(tonumber(existing.lastSeenAt) or 0, tonumber(record.lastSeenAt) or tonumber(record.countedAt) or 0)
            if (tonumber(record.lastSeenAt) or tonumber(record.countedAt) or 0) >= (tonumber(existing.lastSeenAt) or 0) then
                existing.source = record.source or existing.source
            end
        else
            target[spellID] = {
                countedAt = tonumber(record.countedAt) or 0,
                lastSeenAt = tonumber(record.lastSeenAt) or tonumber(record.countedAt) or 0,
                source = record.source,
            }
        end
    end
    return target
end

function InterruptTracker:GetInterruptCountIdentityKey(member)
    if not member then
        return nil
    end
    local guid = self:GetMemberResolvedGUID(member)
    if guid then
        return "guid:" .. guid
    end
    local normalized = IT_NormalizeName(member.name)
    if normalized then
        return "name:" .. normalized
    end
    return nil
end

function InterruptTracker:TryCountInterrupt(member, resolvedSpellID, source, now)
    if not member or not member.name or not resolvedSpellID then
        return false
    end
    local db = self:GetDB()
    if db and db.rightDisplay == "timer" then
        return true
    end

    now = tonumber(now) or GetTime()
    self.recentCountedInterruptsByMember = self.recentCountedInterruptsByMember or {}

    local normalizedName = IT_NormalizeName(member.name)
    local guid = self:GetMemberResolvedGUID(member)
    local identityKey = self:GetInterruptCountIdentityKey(member)
    if not identityKey then
        return false
    end

    if guid and normalizedName then
        local guidKey = "guid:" .. guid
        local nameKey = "name:" .. normalizedName
        local nameRecords = self.recentCountedInterruptsByMember[nameKey]
        if nameRecords then
            self.recentCountedInterruptsByMember[guidKey] = self:MergeInterruptCountRecords(self.recentCountedInterruptsByMember[guidKey], nameRecords)
            self.recentCountedInterruptsByMember[nameKey] = nil
            identityKey = guidKey
        end
    end

    local spellKey = tonumber(resolvedSpellID) or resolvedSpellID
    local records = self.recentCountedInterruptsByMember[identityKey]
    if type(records) ~= "table" then
        records = {}
        self.recentCountedInterruptsByMember[identityKey] = records
    end

    local record = records[spellKey]

    if record and (now - (tonumber(record.countedAt) or 0)) <= IT_INTERRUPT_COUNT_DEDUPE_WINDOW then
        record.lastSeenAt = now
        if source then
            record.source = source
        end
        return false
    end

    records[spellKey] = {
        countedAt = now,
        lastSeenAt = now,
        source = source,
    }
    self:IncrementCount(member.name)
    return true
end

function InterruptTracker:RefreshFullWipeRecoveryState(now)
    now = tonumber(now) or GetTime()
    if not self:IsSupportedLiveContext() then
        self:ResetFullWipeRecoveryState()
        return
    end

    local playerDead = IT_IsUnitRealDeadOrGhost("player")
    local partyInCombat = self:IsAnyTrackedPartyUnitInCombat()
    if partyInCombat then
        self.lastPartyCombatSeenAt = now
    end
    if partyInCombat and (self.fullWipeRecoveryActive or self.pendingFullWipeRecovery) then
        self.fullWipeRecoveryActive = false
        self.pendingFullWipeRecovery = false
        self.fullWipeRecoveryStartedAt = 0
        for _, member in ipairs(self:GetTrackedAvailabilityMembers()) do
            member.fullWipeRecoverySeenAt = 0
        end
    end

    local resolvedMembers, complete = self:GetResolvedTrackedWipeMembers()
    local allDead = complete and #resolvedMembers > 0
    local earliestDeathAt, latestDeathAt = nil, nil
    local everyMemberHasDeath = complete and #resolvedMembers > 0

    for _, entry in ipairs(resolvedMembers) do
        local member = entry.member
        local isDead = IT_IsUnitRealDeadOrGhost(entry.unit)
        local previousDead = member.lastDeadOrGhost and true or false
        if isDead then
            if not previousDead then
                member.lastDeadOrGhost = true
                member.lastDeathAt = now
            elseif (tonumber(member.lastDeathAt) or 0) <= 0 then
                member.lastDeathAt = now
            end
        elseif previousDead then
            member.lastDeadOrGhost = false
        else
            member.lastDeadOrGhost = false
        end

        if not isDead then
            allDead = false
        end

        local deathAt = tonumber(member.lastDeathAt) or 0
        if deathAt <= 0 then
            everyMemberHasDeath = false
        else
            earliestDeathAt = earliestDeathAt and math.min(earliestDeathAt, deathAt) or deathAt
            latestDeathAt = latestDeathAt and math.max(latestDeathAt, deathAt) or deathAt
        end
    end

    if (not self.fullWipeRecoveryActive) and (not self.pendingFullWipeRecovery) and self.availabilityArmed and complete and allDead and everyMemberHasDeath and earliestDeathAt and latestDeathAt then
        local deathSpread = latestDeathAt - earliestDeathAt
        local combatAge = now - (tonumber(self.lastPartyCombatSeenAt) or 0)
        if deathSpread <= IT_FULL_WIPE_WINDOW and combatAge <= IT_FULL_WIPE_COMBAT_RECENCY then
            self.pendingFullWipeRecovery = true
        end
    end

    if self.pendingFullWipeRecovery and (not playerDead) and self.lastPlayerDeadOrGhost then
        self.pendingFullWipeRecovery = false
        self.fullWipeRecoveryActive = true
        self.fullWipeRecoveryStartedAt = now
        for _, member in ipairs(self:GetTrackedAvailabilityMembers()) do
            member.fullWipeRecoverySeenAt = 0
        end
        self.lastPlayerDeadOrGhost = false
    else
        self.lastPlayerDeadOrGhost = playerDead
    end
end

function InterruptTracker:GetCurrentRoster(includeSelf)
    local roster = {}
    if IsInRaid and IsInRaid() then
        return roster
    end
    if includeSelf and self:IsTrackedPartyContext() then
        roster[#roster + 1] = {
            name = IT_NormalizeName(UnitName("player")),
            unit = "player",
            guid = IT_SafeUnitGUID("player"),
            isSelf = true,
        }
    end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            roster[#roster + 1] = {
                name = IT_SafeUnitName(unit),
                unit = unit,
                petUnit = "partypet" .. i,
                guid = IT_SafeUnitGUID(unit),
                connected = (not UnitIsConnected) or UnitIsConnected(unit),
                isSelf = false,
            }
        end
    end
    return roster
end

function InterruptTracker:BuildUnitMap()
    self.memberUnits = {}
    for _, entry in ipairs(self:GetCurrentRoster(true)) do
        if entry.name then
            self.memberUnits[entry.name] = entry
        end
    end
end

function InterruptTracker:GetUnitForMember(name)
    name = IT_NormalizeName(name)
    if not self.memberUnits then
        self:BuildUnitMap()
    end
    return self.memberUnits and self.memberUnits[name] or nil
end

function InterruptTracker:FindMemberByName(name)
    name = IT_NormalizeName(name)
    if not name then
        return nil
    end
    if self.selfState and self.selfState.name == name then
        return self.selfState
    end
    return self.trackedMembers and self.trackedMembers[name] or nil
end

function InterruptTracker:GetMemberRecord(name, createIfMissing)
    name = IT_NormalizeName(name)
    if not name then
        return nil
    end
    if self.selfState and self.selfState.name == name then
        return self.selfState
    end
    self.trackedMembers = self.trackedMembers or {}
    if createIfMissing and not self.trackedMembers[name] then
        self.trackedMembers[name] = {
            name = name,
            isSelf = false,
            extraKicks = {},
            cdEnd = 0,
            onKickReduction = nil,
            hasLightOfTheSun = false,
            requiresPrimaryTargetConfirm = false,
            primaryTargetOnKickReduction = nil,
            hasColdthirst = false,
            requiresOwnerInterruptConfirm = false,
            ownerInterruptReduction = nil,
            lastAdjSpellID = nil,
            lastAdjIgnoreCastUntil = nil,
            lastActivityAt = 0,
            offlineSinceAt = nil,
            unitGUID = nil,
            lastDeathAt = 0,
            lastDeadOrGhost = false,
            fullWipeRecoverySeenAt = 0,
        }
    end
    return self.trackedMembers[name]
end

function InterruptTracker:EnsureMemberRecordFromUnit(unit, name)
    if not unit or not UnitExists(unit) then
        return nil
    end
    local normalizedName = IT_NormalizeName(name or IT_SafeUnitName(unit))
    if not normalizedName then
        return nil
    end
    local classFile = IT_SafeUnitClass(unit)
    if not classFile then
        return nil
    end
    local kick = IT_CLASS_PRIMARY[classFile]
    if (not kick) and type(IT_CLASS_INTERRUPT_LIST[classFile]) == "table" then
        local fallbackSpellID = IT_CLASS_INTERRUPT_LIST[classFile][1]
        local fallbackData = fallbackSpellID and IT_INTERRUPTS[fallbackSpellID] or nil
        if fallbackData then
            kick = {
                id = fallbackSpellID,
                cd = fallbackData.cd,
                name = fallbackData.name,
            }
        end
    end
    if not kick then
        return nil
    end
    local member = self:GetMemberRecord(normalizedName, true)
    member.class = classFile
    member.extraKicks = member.extraKicks or {}
    local unitGUID = IT_SafeUnitGUID(unit)
    if unitGUID then
        member.unitGUID = unitGUID
    end
    return member
end

function InterruptTracker:GetSpecNameForMember(member)
    return member and (member.specName or IT_GetSpecName(member.specID)) or nil
end

function InterruptTracker:GetPrimarySpellData(member)
    if not member or not member.spellID then
        return nil
    end
    return IT_INTERRUPTS[member.spellID] or IT_INTERRUPTS_STR[IT_SafeToString(member.spellID) or ""]
end

function InterruptTracker:GetMemberRemaining(member, now)
    if not member then
        return 0
    end
    return math.max(0, (tonumber(member.cdEnd) or 0) - (now or GetTime()))
end

function InterruptTracker:IsMemberReady(member, now)
    return IT_IsReady(member and member.cdEnd or 0, now or GetTime())
end

function InterruptTracker:GetDisplayColor(member)
    local db = self:GetDB()
    if db.useClassColors and member and member.class then
        local r, g, b = IT_GetClassColor(member.class)
        return r, g, b
    end
    return IT_NEUTRAL_BAR[1], IT_NEUTRAL_BAR[2], IT_NEUTRAL_BAR[3]
end

function InterruptTracker:GetSeparatorColor(member)
    if member and member.class then
        local r, g, b = IT_GetClassColor(member.class)
        return r, g, b, 1.0
    end
    return IT_FALLBACK_SEPARATOR[1], IT_FALLBACK_SEPARATOR[2], IT_FALLBACK_SEPARATOR[3], IT_FALLBACK_SEPARATOR[4]
end

function InterruptTracker:PlayAlertSoundFor(name)
    local db = self:GetDB()
    if trim(tostring(db.alertSound or "")) == "" then
        return
    end
    local normalized = IT_NormalizeName(name)
    if db.selfOnlyAlert and normalized ~= self.playerName then
        return
    end
    local kind, value = IT_GetAlertSoundChoice(db.alertSound)
    if kind == "file" and value then
        PlaySoundFile(value, "Master")
    elseif kind == "kit" and value then
        PlaySound(value, "Master")
    end
end

function InterruptTracker:IncrementCount(name)
    name = IT_NormalizeName(name)
    if not name then
        return
    end
    self.interruptCounts = self.interruptCounts or {}
    self.interruptCounts[name] = (tonumber(self.interruptCounts[name]) or 0) + 1
end

function InterruptTracker:GetCount(name)
    name = IT_NormalizeName(name)
    return math.floor(tonumber(self.interruptCounts and self.interruptCounts[name]) or 0)
end

function InterruptTracker:GetMemberUnitToken(member)
    if not member then
        return nil
    end
    if member.isSelf then
        return "player"
    end
    local rosterEntry = self:GetUnitForMember(member.name)
    return rosterEntry and rosterEntry.unit or nil
end

function InterruptTracker:GetMemberResolvedGUID(member)
    if not member then
        return nil
    end
    local guid = IT_NormalizeSafeString(member.unitGUID)
    if guid then
        member.unitGUID = guid
        return guid
    end
    local unit = self:GetMemberUnitToken(member)
    guid = unit and IT_SafeUnitGUID(unit) or nil
    if guid then
        member.unitGUID = guid
    end
    return guid
end

function InterruptTracker:GetTrackedMemberByUnitToken(unitToken)
    if not IT_IsUsablePlainString(unitToken) then
        return nil
    end
    for _, member in ipairs(self:GetTrackedAvailabilityMembers()) do
        if self:GetMemberUnitToken(member) == unitToken then
            return member
        end
    end
    return nil
end

function InterruptTracker:FindTrackedMemberBySafeName(name)
    if not IT_IsUsablePlainString(name) then
        return nil
    end
    local normalized = IT_NormalizeName(name)
    if not normalized then
        return nil
    end
    local member = self:FindMemberByName(normalized)
    if member and self:MemberQualifiesForSeed(member) then
        return member
    end
    return nil
end

function InterruptTracker:HandleTrackedMemberDeath(deadGUID, deadName, now)
    local member = nil
    if UnitTokenFromGUID and type(deadGUID) == "string" and not IT_HasSecretValues(deadGUID) then
        local ok, unitToken = pcall(UnitTokenFromGUID, deadGUID)
        if ok and IT_IsUsablePlainString(unitToken) then
            member = self:GetTrackedMemberByUnitToken(unitToken)
        end
    end
    if not member then
        member = self:FindTrackedMemberBySafeName(deadName)
    end
    if not member then
        return false
    end

    local deathAt = tonumber(member.lastDeathAt) or 0
    local alreadyDead = member.lastDeadOrGhost and true or false
    if not alreadyDead then
        member.lastDeathAt = tonumber(now) or GetTime()
    elseif deathAt <= 0 then
        member.lastDeathAt = tonumber(now) or GetTime()
    end
    member.lastDeadOrGhost = true
    return true
end

function InterruptTracker:ClearOwnerInterruptPending()
    self.pendingOwnerInterruptConfirm = nil
    self.lastHandledInterruptedGUID = nil
    self.lastHandledInterruptedAt = 0
end

function InterruptTracker:ExpireOwnerInterruptPending(now)
    local pending = self.pendingOwnerInterruptConfirm
    local currentTime = tonumber(now) or GetTime()
    if pending and (tonumber(pending.expiresAt) or 0) < currentTime then
        self.pendingOwnerInterruptConfirm = nil
    end
end

function InterruptTracker:ClearAdjGuard(member)
    if not member then
        return
    end
    member.lastAdjSpellID = nil
    member.lastAdjIgnoreCastUntil = nil
end

function InterruptTracker:ExpireAdjGuard(member, now)
    if not member then
        return
    end
    if member.lastAdjIgnoreCastUntil and (tonumber(member.lastAdjIgnoreCastUntil) or 0) <= (tonumber(now) or GetTime()) then
        self:ClearAdjGuard(member)
    end
end

function InterruptTracker:GetOwnerConfirmedReduction(member)
    if not member or not member.spellID then
        return nil
    end
    if member.spellID == 78675 and member.requiresPrimaryTargetConfirm and member.hasLightOfTheSun then
        return tonumber(member.primaryTargetOnKickReduction) or nil
    end
    if member.spellID == 47528 and member.requiresOwnerInterruptConfirm and member.hasColdthirst then
        return tonumber(member.ownerInterruptReduction) or nil
    end
    return nil
end

function InterruptTracker:ResolveStrictHostileCandidateGUID()
    return nil
end

function InterruptTracker:ArmOwnerInterruptPending(member, now)
    self:ClearOwnerInterruptPending()
end

function InterruptTracker:ApplyOwnerConfirmedReduction(member, reduction)
    if not member or not reduction then
        return
    end
    local now = GetTime()
    member.cdEnd = math.max(now, (tonumber(member.cdEnd) or now) - tonumber(reduction or 0))
end

function InterruptTracker:MaybeConfirmOwnerInterrupt(member, interruptedUnit, interruptedGUID, now)
    return false
end

function InterruptTracker:MarkMemberActivity(name, timestamp, allowCreate)
    local normalized = IT_NormalizeName(name)
    if not normalized or normalized == self.playerName then
        return
    end
    local member = self:GetMemberRecord(normalized, false)
    if not member then
        if allowCreate == false then
            return
        end
        local rosterEntry = self:GetUnitForMember(normalized)
        if not rosterEntry then
            return
        end
        member = self:GetMemberRecord(normalized, true)
        member.unitGUID = IT_NormalizeSafeString(rosterEntry.guid) or IT_NormalizeSafeString(member.unitGUID)
    end
    member.lastActivityAt = tonumber(timestamp) or GetTime()
    self:MarkFullWipeRecoveryEvidence(member, member.lastActivityAt)
end

function InterruptTracker:MemberQualifiesForSeed(member)
    return member and member.name and self:GetPrimarySpellData(member) and true or false
end

function InterruptTracker:CaptureSeedState(member)
    return {
        qualifies = self:MemberQualifiesForSeed(member),
        name = IT_NormalizeName(member and member.name),
        spellID = tonumber(member and member.spellID) or 0,
        baseCd = tonumber(member and member.baseCd) or 0,
    }
end

function InterruptTracker:DidSeedStateChange(beforeState, member)
    local afterState = self:CaptureSeedState(member)
    return beforeState.qualifies ~= afterState.qualifies
        or beforeState.name ~= afterState.name
        or beforeState.spellID ~= afterState.spellID
        or beforeState.baseCd ~= afterState.baseCd
end

function InterruptTracker:FillMemberAvailabilityState(member, now, outState)
    local state = outState or {}
    now = now or GetTime()
    if not member then
        state.bucket = "offline"
        state.visible = false
        state.connected = false
        state.isDead = false
        return state
    end

    if self:IsPreviewMode() then
        local previewBucket = member.previewAvailability or (member.isSelf and "confirmed" or "confirmed")
        local offlineSinceAt = tonumber(member.offlineSinceAt) or now
        state.bucket = previewBucket
        state.visible = previewBucket ~= "offline" or (now - offlineSinceAt) <= IT_OFFLINE_GRACE_WINDOW
        state.connected = previewBucket ~= "offline"
        state.isDead = previewBucket == "dead"
        return state
    end

    local unit = self:GetMemberUnitToken(member)
    if member.isSelf and (not unit or not UnitExists(unit)) then
        state.bucket = "confirmed"
        state.visible = true
        state.connected = true
        state.isDead = false
        return state
    end
    if not unit or not UnitExists(unit) then
        state.bucket = "offline"
        state.visible = false
        state.connected = false
        state.isDead = false
        return state
    end

    local connected = (not UnitIsConnected) or UnitIsConnected(unit)
    if not connected then
        member.offlineSinceAt = tonumber(member.offlineSinceAt) or now
        state.bucket = "offline"
        state.visible = (now - member.offlineSinceAt) <= IT_OFFLINE_GRACE_WINDOW
        state.connected = false
        state.isDead = false
        return state
    end

    member.offlineSinceAt = nil
    local isDead = IT_IsUnitRealDeadOrGhost(unit)
    if isDead then
        state.bucket = "dead"
        state.visible = true
        state.connected = true
        state.isDead = true
        return state
    end

    local classFile = member.class or IT_SafeUnitClass(unit)
    local isFeignDeath = classFile == "HUNTER" and UnitIsFeignDeath and UnitIsFeignDeath(unit) and true or false
    if isFeignDeath then
        state.bucket = "confirmed"
        state.visible = true
        state.connected = true
        state.isDead = false
        return state
    end

    if member.isSelf then
        state.bucket = "confirmed"
        state.visible = true
        state.connected = true
        state.isDead = false
        return state
    end

    if self.fullWipeRecoveryActive then
        local recoveryStartedAt = tonumber(self.fullWipeRecoveryStartedAt) or 0
        if recoveryStartedAt > 0 and (now - recoveryStartedAt) <= IT_FULL_WIPE_RECOVERY_GRACE then
            state.bucket = "confirmed"
            state.visible = true
            state.connected = true
            state.isDead = false
            return state
        end
        if (tonumber(member.fullWipeRecoverySeenAt) or 0) >= recoveryStartedAt then
            state.bucket = "confirmed"
            state.visible = true
            state.connected = true
            state.isDead = false
            return state
        end
        state.bucket = "stale"
        state.visible = true
        state.connected = true
        state.isDead = false
        return state
    end

    if member.lastDeadOrGhost and not isDead then
        member.lastDeadOrGhost = false
    end

    if not self.availabilityArmed then
        state.bucket = "confirmed"
        state.visible = true
        state.connected = true
        state.isDead = false
        return state
    end

    local lastActivityAt = tonumber(member.lastActivityAt) or 0
    local lastDeathAt = tonumber(member.lastDeathAt) or 0
    if lastDeathAt > lastActivityAt then
        state.bucket = "stale"
        state.visible = true
        state.connected = true
        state.isDead = false
        return state
    end
    local bucket = (lastActivityAt > 0 and (now - lastActivityAt) <= IT_ACTIVITY_CONFIRM_WINDOW) and "confirmed" or "stale"
    state.bucket = bucket
    state.visible = true
    state.connected = true
    state.isDead = false
    return state
end

function InterruptTracker:GetMemberAvailability(member, now)
    return self:FillMemberAvailabilityState(member, now, {})
end

function InterruptTracker:GetCurrentPrimaryOrder()
    local now = GetTime()
    local rows = {}
    if self:MemberQualifiesForSeed(self.selfState) then
        rows[#rows + 1] = self.selfState
    end
    for _, member in pairs(self.trackedMembers or {}) do
        if self:MemberQualifiesForSeed(member) then
            rows[#rows + 1] = member
        end
    end
    table.sort(rows, function(a, b)
        if a.isSelf ~= b.isSelf then
            return a.isSelf and true or false
        end
        if a.isSelf and b.isSelf then
            return tostring(a.name or "") < tostring(b.name or "")
        end
        local aReady = self:IsMemberReady(a, now)
        local bReady = self:IsMemberReady(b, now)
        if aReady ~= bReady then
            return aReady and true or false
        end
        if aReady and bReady then
            if (a.baseCd or 999) ~= (b.baseCd or 999) then
                return (a.baseCd or 999) < (b.baseCd or 999)
            end
        else
            local aRem = IT_SnapRemaining(self:GetMemberRemaining(a, now))
            local bRem = IT_SnapRemaining(self:GetMemberRemaining(b, now))
            if aRem ~= bRem then
                return aRem < bRem
            end
        end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return rows
end

-- Mode B seed order is local-only authority: finalized primary cooldown ascending, then normalized name.
function InterruptTracker:GetModeBSeedOrder()
    local members = {}
    if self:MemberQualifiesForSeed(self.selfState) then
        members[#members + 1] = self.selfState
    end
    for _, member in pairs(self.trackedMembers or {}) do
        if self:MemberQualifiesForSeed(member) then
            members[#members + 1] = member
        end
    end
    table.sort(members, function(a, b)
        local aCd = tonumber(a.baseCd) or 999
        local bCd = tonumber(b.baseCd) or 999
        if aCd ~= bCd then
            return aCd < bCd
        end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    local names = {}
    for _, member in ipairs(members) do
        names[#names + 1] = member.name
    end
    return IT_NormalizeNameList(names)
end

function InterruptTracker:ReseedModeBOrder()
    local db = self:GetDB()
    if not db.rotationEnabled then
        return false
    end

    local previousPayload = IT_SerializeNameList(db.rotationOrder)
    db.rotationOrder = self:GetModeBSeedOrder()
    db.rotationIndex = 1

    local payloadChanged = IT_SerializeNameList(db.rotationOrder) ~= previousPayload
    if payloadChanged then
        self:MarkDisplayStructureDirty("reseed")
    end
    return payloadChanged
end

function InterruptTracker:CopyInterruptEntry(member, source)
    if not member or not source then
        return
    end
    member.class = source.class or member.class
    member.specID = source.specID or member.specID
    member.specName = source.specName or member.specName
    member.spellID = source.spellID or member.spellID
    member.baseCd = source.baseCd or member.baseCd
    member.isPetSpell = source.isPetSpell and true or false
    member.petSpellID = source.petSpellID or member.petSpellID
    member.unitGUID = IT_NormalizeSafeString(source.unitGUID) or IT_NormalizeSafeString(member.unitGUID)
    member.icon = source.icon or member.icon
    member.onKickReduction = source.onKickReduction
    member.hasLightOfTheSun = source.hasLightOfTheSun and true or false
    member.requiresPrimaryTargetConfirm = source.requiresPrimaryTargetConfirm and true or false
    member.primaryTargetOnKickReduction = source.primaryTargetOnKickReduction
    member.hasColdthirst = source.hasColdthirst and true or false
    member.requiresOwnerInterruptConfirm = source.requiresOwnerInterruptConfirm and true or false
    member.ownerInterruptReduction = source.ownerInterruptReduction
    member.lastActivityAt = tonumber(source.lastActivityAt) or tonumber(member.lastActivityAt) or 0
    member.offlineSinceAt = source.offlineSinceAt or member.offlineSinceAt
    member.lastDeathAt = tonumber(source.lastDeathAt) or tonumber(member.lastDeathAt) or 0
    member.lastDeadOrGhost = source.lastDeadOrGhost and true or false
    member.fullWipeRecoverySeenAt = tonumber(source.fullWipeRecoverySeenAt) or tonumber(member.fullWipeRecoverySeenAt) or 0
    if type(source.extraKicks) == "table" then
        member.extraKicks = {}
        for _, extra in ipairs(source.extraKicks) do
            member.extraKicks[#member.extraKicks + 1] = {
                spellID = extra.spellID,
                baseCd = extra.baseCd,
                cdEnd = extra.cdEnd or 0,
                name = extra.name,
                icon = extra.icon or IT_GetPrimaryIcon(extra.spellID),
            }
        end
    end
end

function InterruptTracker:GetInspectKnownGoodTalentSnapshotKey(guid, specID)
    local normalizedGUID = IT_NormalizeSafeString(guid)
    local resolvedSpecID = tonumber(specID) or 0
    if not normalizedGUID or resolvedSpecID <= 0 then
        return nil
    end
    return normalizedGUID .. "::" .. tostring(resolvedSpecID)
end

function InterruptTracker:GetInspectKnownGoodTalentSnapshot(guid, specID)
    local snapshotKey = self:GetInspectKnownGoodTalentSnapshotKey(guid, specID)
    return snapshotKey and self.inspectKnownGoodTalentSnapshotsByKey and self.inspectKnownGoodTalentSnapshotsByKey[snapshotKey] or nil
end

function InterruptTracker:CreateTalentDerivedInterruptSnapshot(source)
    if not source then
        return nil
    end
    local snapshot = {
        spellID = IT_NormalizeSpellID(source.spellID),
        isPetSpell = source.isPetSpell and true or false,
        petSpellID = source.petSpellID,
        baseCd = tonumber(source.baseCd) or 0,
        onKickReduction = source.onKickReduction,
        hasLightOfTheSun = source.hasLightOfTheSun and true or false,
        requiresPrimaryTargetConfirm = source.requiresPrimaryTargetConfirm and true or false,
        primaryTargetOnKickReduction = source.primaryTargetOnKickReduction,
        hasColdthirst = source.hasColdthirst and true or false,
        requiresOwnerInterruptConfirm = source.requiresOwnerInterruptConfirm and true or false,
        ownerInterruptReduction = source.ownerInterruptReduction,
        extraKicks = {},
    }
    for _, extra in ipairs(source.extraKicks or {}) do
        snapshot.extraKicks[#snapshot.extraKicks + 1] = {
            spellID = extra.spellID,
            baseCd = extra.baseCd,
            name = extra.name,
            icon = extra.icon,
        }
    end
    return snapshot
end

function InterruptTracker:GetExistingExtraKickRuntimeCdEnd(source, spellID)
    local normalizedSpellID = IT_NormalizeSpellID(spellID)
    if normalizedSpellID <= 0 then
        return 0
    end
    for _, extra in ipairs(source or {}) do
        if IT_NormalizeSpellID(extra and extra.spellID) == normalizedSpellID then
            return tonumber(extra.cdEnd) or 0
        end
    end
    return 0
end

function InterruptTracker:ApplyTalentDerivedInterruptSnapshot(target, snapshot, runtimeSource)
    if not target then
        return
    end
    if not snapshot then
        return
    end
    if tonumber(snapshot.baseCd) and tonumber(snapshot.baseCd) > 0 then
        target.baseCd = tonumber(snapshot.baseCd)
    end
    target.onKickReduction = snapshot.onKickReduction
    target.hasLightOfTheSun = snapshot.hasLightOfTheSun and true or false
    target.requiresPrimaryTargetConfirm = snapshot.requiresPrimaryTargetConfirm and true or false
    target.primaryTargetOnKickReduction = snapshot.primaryTargetOnKickReduction
    target.hasColdthirst = snapshot.hasColdthirst and true or false
    target.requiresOwnerInterruptConfirm = snapshot.requiresOwnerInterruptConfirm and true or false
    target.ownerInterruptReduction = snapshot.ownerInterruptReduction
    target.extraKicks = {}
    for _, extra in ipairs(snapshot.extraKicks or {}) do
        target.extraKicks[#target.extraKicks + 1] = {
            spellID = extra.spellID,
            baseCd = extra.baseCd,
            cdEnd = self:GetExistingExtraKickRuntimeCdEnd(runtimeSource and runtimeSource.extraKicks, extra.spellID),
            name = extra.name,
            icon = extra.icon or IT_GetPrimaryIcon(extra.spellID),
        }
    end
end

function InterruptTracker:StoreInspectKnownGoodTalentSnapshot(name, guid, specID, source)
    local snapshotKey = self:GetInspectKnownGoodTalentSnapshotKey(guid, specID)
    name = IT_NormalizeName(name)
    if not snapshotKey or not name or not source then
        return nil
    end
    self.inspectKnownGoodTalentSnapshotsByKey = self.inspectKnownGoodTalentSnapshotsByKey or {}
    self.inspectKnownGoodTalentSnapshotKeyByName = self.inspectKnownGoodTalentSnapshotKeyByName or {}
    local previousKey = self.inspectKnownGoodTalentSnapshotKeyByName[name]
    if previousKey and previousKey ~= snapshotKey then
        self.inspectKnownGoodTalentSnapshotsByKey[previousKey] = nil
    end
    self.inspectKnownGoodTalentSnapshotsByKey[snapshotKey] = self:CreateTalentDerivedInterruptSnapshot(source)
    self.inspectKnownGoodTalentSnapshotKeyByName[name] = snapshotKey
    return snapshotKey
end

function InterruptTracker:ClearInspectKnownGoodTalentSnapshotForName(name)
    name = IT_NormalizeName(name)
    if not name then
        return
    end
    self.inspectKnownGoodTalentSnapshotKeyByName = self.inspectKnownGoodTalentSnapshotKeyByName or {}
    local snapshotKey = self.inspectKnownGoodTalentSnapshotKeyByName[name]
    if snapshotKey and self.inspectKnownGoodTalentSnapshotsByKey then
        self.inspectKnownGoodTalentSnapshotsByKey[snapshotKey] = nil
    end
    self.inspectKnownGoodTalentSnapshotKeyByName[name] = nil
end

function InterruptTracker:SetInspectBackoff(name, guid, untilAt)
    name = IT_NormalizeName(name)
    if not name then
        return
    end
    self.inspectBackoffByName = self.inspectBackoffByName or {}
    self.inspectBackoffByName[name] = {
        guid = IT_NormalizeSafeString(guid),
        untilAt = tonumber(untilAt) or 0,
    }
end

function InterruptTracker:ClearInspectBackoffForName(name)
    name = IT_NormalizeName(name)
    if not name or not self.inspectBackoffByName then
        return
    end
    self.inspectBackoffByName[name] = nil
end

function InterruptTracker:ClearInspectRefreshTrackingFor(name)
    if name then
        name = IT_NormalizeName(name)
        if not name then
            return
        end
        if self.inspectedPlayers then
            self.inspectedPlayers[name] = nil
        end
        self:ClearInspectBackoffForName(name)
        return
    end
    wipe(self.inspectedPlayers or {})
    wipe(self.inspectBackoffByName or {})
end

function InterruptTracker:IsInspectBackoffActive(name, guid, now)
    name = IT_NormalizeName(name)
    if not name then
        return false, 0
    end
    local entry = self.inspectBackoffByName and self.inspectBackoffByName[name] or nil
    if type(entry) ~= "table" then
        return false, 0
    end
    now = tonumber(now) or GetTime()
    local untilAt = tonumber(entry.untilAt) or 0
    local expectedGUID = IT_NormalizeSafeString(entry.guid)
    local currentGUID = IT_NormalizeSafeString(guid)
    if expectedGUID and currentGUID and not IT_SafeStringsEqual(expectedGUID, currentGUID) then
        self.inspectBackoffByName[name] = nil
        return false, 0
    end
    if untilAt > now then
        return true, untilAt
    end
    self.inspectBackoffByName[name] = nil
    return false, 0
end

function InterruptTracker:ClearInspectResolutionStateFor(name)
    if name then
        name = IT_NormalizeName(name)
        if not name then
            return
        end
        self:ClearInspectRefreshTrackingFor(name)
        self:ClearInspectKnownGoodTalentSnapshotForName(name)
        return
    end
    self:ClearInspectRefreshTrackingFor()
    wipe(self.inspectKnownGoodTalentSnapshotsByKey or {})
    wipe(self.inspectKnownGoodTalentSnapshotKeyByName or {})
end

function InterruptTracker:IsCanonicalPrimaryIdentityCompatible(left, right)
    if not left or not right then
        return false
    end
    local leftSpellID = IT_NormalizeSpellID(left.spellID)
    local rightSpellID = IT_NormalizeSpellID(right.spellID)
    if leftSpellID <= 0 or rightSpellID <= 0 or leftSpellID ~= rightSpellID then
        return false
    end
    if (left.isPetSpell and true or false) ~= (right.isPetSpell and true or false) then
        return false
    end
    return IT_NormalizeSpellID(left.petSpellID) == IT_NormalizeSpellID(right.petSpellID)
end

function InterruptTracker:GetCompatibleKnownGoodTalentSnapshot(member, working)
    if not member or not working then
        return nil
    end
    local resolvedGUID = IT_NormalizeSafeString(working.unitGUID) or IT_NormalizeSafeString(member.unitGUID)
    local resolvedSpecID = tonumber(working.specID) or tonumber(member.specID) or 0
    if not resolvedGUID or resolvedSpecID <= 0 then
        return nil
    end
    local snapshot = self:GetInspectKnownGoodTalentSnapshot(resolvedGUID, resolvedSpecID)
    if not snapshot then
        return nil
    end
    local identitySource = (IT_NormalizeSpellID(snapshot.spellID) > 0) and snapshot or member
    if not self:IsCanonicalPrimaryIdentityCompatible(identitySource, working) then
        local normalizedName = IT_NormalizeName(working.name or member.name)
        if normalizedName then
            self:ClearInspectResolutionStateFor(normalizedName)
        end
        return nil
    end
    return snapshot
end

function InterruptTracker:CommitInspectResolvedInterruptState(member, working, talentDataValid)
    if not member or not working then
        return false
    end
    local resolvedGUID = IT_NormalizeSafeString(working.unitGUID) or IT_NormalizeSafeString(member.unitGUID)
    local resolvedSpecID = tonumber(working.specID) or tonumber(member.specID) or 0
    local normalizedName = IT_NormalizeName(working.name or member.name)

    -- Same GUID + same specID is only a fallback heuristic for transient inspect misses.
    -- The stored talent snapshot can still be stale until a new valid inspect succeeds.
    if talentDataValid then
        self:CopyInterruptEntry(member, working)
        self:StoreInspectKnownGoodTalentSnapshot(normalizedName, resolvedGUID, resolvedSpecID, working)
        if normalizedName then
            self.inspectedPlayers[normalizedName] = resolvedGUID or true
            self:ClearInspectBackoffForName(normalizedName)
        end
        return true
    end

    local knownGoodSnapshot = self:GetCompatibleKnownGoodTalentSnapshot(member, working)
    if knownGoodSnapshot then
        self:ApplyTalentDerivedInterruptSnapshot(working, knownGoodSnapshot, member)
    end

    self:CopyInterruptEntry(member, working)
    if normalizedName then
        self.inspectedPlayers[normalizedName] = nil
    end
    return knownGoodSnapshot ~= nil
end

function InterruptTracker:ResolveSpecBasedCanonicalPrimary(member, specID, unit)
    local resolvedSpecID = tonumber(specID) or 0
    if resolvedSpecID <= 0 then
        return nil, "spec_missing"
    end
    local override = IT_SPEC_OVERRIDE[resolvedSpecID]
    if not override then
        return nil, "no_authoritative_primary"
    end

    local probe = {
        name = member and member.name,
        class = member and member.class,
    }
    if not self:ApplySpecOverride(probe, resolvedSpecID, unit) then
        return nil, "no_authoritative_primary"
    end

    local spellID = tonumber(probe.spellID) or 0
    if spellID <= 0 then
        return nil, "no_authoritative_primary"
    end

    local baseCd = IT_GetCanonicalInterruptBaseCd(spellID, probe.baseCd)
    if not baseCd or baseCd <= 0 then
        return nil, "no_authoritative_primary"
    end

    return {
        spellID = spellID,
        baseCd = baseCd,
        icon = probe.icon or IT_GetPrimaryIcon(spellID),
        specID = resolvedSpecID,
    }, nil
end

function InterruptTracker:ResetTalentDerivedInterruptFields(member)
    if not member then
        return
    end
    member.onKickReduction = nil
    member.hasLightOfTheSun = false
    member.requiresPrimaryTargetConfirm = false
    member.primaryTargetOnKickReduction = nil
    member.hasColdthirst = false
    member.requiresOwnerInterruptConfirm = false
    member.ownerInterruptReduction = nil
end

function InterruptTracker:CreateAutoRegisterWorkingState(member, name, classFile, kick, unit)
    if not (name and classFile and kick) then
        return nil
    end
    local working = {
        name = name,
        class = classFile,
        specID = member and member.specID or nil,
        specName = member and member.specName or nil,
        spellID = kick.id,
        baseCd = IT_GetCanonicalInterruptBaseCd(kick.id, kick.cd) or 15,
        cdEnd = tonumber(member and member.cdEnd) or 0,
        extraKicks = {},
        onKickReduction = nil,
        hasLightOfTheSun = false,
        requiresPrimaryTargetConfirm = false,
        primaryTargetOnKickReduction = nil,
        hasColdthirst = false,
        requiresOwnerInterruptConfirm = false,
        ownerInterruptReduction = nil,
        isPetSpell = false,
        petSpellID = nil,
        unitGUID = IT_NormalizeSafeString(IT_SafeUnitGUID(unit)) or IT_NormalizeSafeString(member and member.unitGUID),
        icon = IT_GetPrimaryIcon(kick.id),
        lastActivityAt = tonumber(member and member.lastActivityAt) or 0,
        offlineSinceAt = member and member.offlineSinceAt or nil,
        lastDeathAt = tonumber(member and member.lastDeathAt) or 0,
        lastDeadOrGhost = member and member.lastDeadOrGhost and true or false,
        fullWipeRecoverySeenAt = tonumber(member and member.fullWipeRecoverySeenAt) or 0,
    }
    self:ResetTalentDerivedInterruptFields(working)
    local resolvedSpecID = tonumber(working.specID) or 0
    if resolvedSpecID > 0 then
        working.specName = IT_GetSpecName(resolvedSpecID) or working.specName
        if not self:RebuildCanonicalPrimaryState(working, resolvedSpecID, unit) then
            working.spellID = kick.id
            working.baseCd = IT_GetCanonicalInterruptBaseCd(kick.id, kick.cd) or 15
            working.isPetSpell = false
            working.petSpellID = nil
            working.icon = IT_GetPrimaryIcon(kick.id)
        end
    end
    working.baseCd = IT_GetCanonicalInterruptBaseCd(working.spellID, working.baseCd) or tonumber(working.baseCd) or 15
    working.icon = working.icon or IT_GetPrimaryIcon(working.spellID)
    return working
end

function InterruptTracker:CommitAutoRegisterResolvedInterruptState(member, classFile, kick, unit)
    if not (member and classFile and kick) then
        return false
    end
    local working = self:CreateAutoRegisterWorkingState(member, member.name, classFile, kick, unit)
    if not working then
        return false
    end
    local knownGoodSnapshot = self:GetCompatibleKnownGoodTalentSnapshot(member, working)
    if knownGoodSnapshot then
        self:ApplyTalentDerivedInterruptSnapshot(working, knownGoodSnapshot, member)
    end
    self:CopyInterruptEntry(member, working)
    return knownGoodSnapshot ~= nil
end

function InterruptTracker:RebuildCanonicalPrimaryState(member, specID, unit)
    if not member then
        return false
    end

    local preferredSpellID = (unit == "player") and tonumber(member.spellID) or nil
    member.spellID = nil
    member.baseCd = nil
    member.isPetSpell = false
    member.petSpellID = nil
    member.icon = nil

    if specID and IT_SPEC_NO_INTERRUPT[specID] then
        return false
    end

    if preferredSpellID and (IT_INTERRUPTS[preferredSpellID] or IT_INTERRUPTS_STR[tostring(preferredSpellID)]) then
        member.spellID = preferredSpellID
        member.baseCd = IT_GetCanonicalInterruptBaseCd(preferredSpellID)
        member.icon = IT_GetPrimaryIcon(preferredSpellID)
        local override = specID and IT_SPEC_OVERRIDE[specID] or nil
        if override and override.id == preferredSpellID then
            if not self:ApplySpecOverride(member, specID, unit) then
                return false
            end
        end
    else
        local classDefault = IT_GetClassDefaultInterrupt(member.class)
        if classDefault then
            member.spellID = classDefault.spellID
            member.baseCd = IT_GetCanonicalInterruptBaseCd(classDefault.spellID, classDefault.baseCd)
            member.icon = classDefault.icon or IT_GetPrimaryIcon(classDefault.spellID)
        end

        if specID and not self:ApplySpecOverride(member, specID, unit) then
            return false
        end
    end

    if not member.spellID then
        return false
    end

    member.baseCd = IT_GetCanonicalInterruptBaseCd(member.spellID, member.baseCd) or 15
    member.icon = member.icon or IT_GetPrimaryIcon(member.spellID)
    return true
end

function InterruptTracker:ApplyMemberTalent(defSpellID, member, specID)
    local permanent = IT_TrySecretLookup(IT_PERMANENT_CD_TALENTS, IT_PERMANENT_CD_TALENTS_STR, defSpellID)
    if permanent and member.spellID == permanent.affects then
        if permanent.pctReduction then
            member.baseCd = math.max(1, math.floor(((member.baseCd or 15) * (1 - permanent.pctReduction / 100)) + 0.5))
        elseif permanent.reduction then
            member.baseCd = math.max(1, (member.baseCd or 15) - permanent.reduction)
        end
    end

    local ownerConfirmed = IT_TrySecretLookup(IT_OWNER_CONFIRMED_TALENTS, IT_OWNER_CONFIRMED_TALENTS_STR, defSpellID)
    if ownerConfirmed then
        if member.spellID == ownerConfirmed.affects then
            if ownerConfirmed.kind == "light_of_the_sun" then
                member.hasLightOfTheSun = true
            elseif ownerConfirmed.kind == "coldthirst" then
                member.hasColdthirst = true
            end
            member.requiresPrimaryTargetConfirm = false
            member.primaryTargetOnKickReduction = nil
            member.requiresOwnerInterruptConfirm = false
            member.ownerInterruptReduction = nil
            member.baseCd = math.max(1, (tonumber(member.baseCd) or 15) - (tonumber(ownerConfirmed.reduction) or 0))
        end
    else
        local onKick = IT_TrySecretLookup(IT_ON_SUCCESS_TALENTS, IT_ON_SUCCESS_TALENTS_STR, defSpellID)
        if onKick then
            member.onKickReduction = onKick.reduction
        end
    end

    local specExtraKicks = specID and IT_GetSpecExtraKicks(specID) or nil
    if specExtraKicks then
        member.extraKicks = member.extraKicks or {}
        local matchingExtras = IT_GetExtraKicksForTalent(defSpellID)
        if matchingExtras then
            for _, match in ipairs(matchingExtras) do
                if match.specID == specID then
                    local extra = match.extra
                    local found = false
                    for _, existing in ipairs(member.extraKicks) do
                        if existing.spellID == extra.id then
                            found = true
                            break
                        end
                    end
                    if not found then
                        local previousCdEnd = self:GetExistingExtraKickRuntimeCdEnd(member._previousExtraKicks or member.extraKicks, extra.id)
                        member.extraKicks[#member.extraKicks + 1] = {
                            spellID = extra.id,
                            baseCd = extra.cd,
                            cdEnd = previousCdEnd,
                            name = extra.name,
                            icon = IT_GetExtraKickIcon(extra),
                        }
                    end
                end
            end
        end
    end
end

function InterruptTracker:ApplySpecOverride(member, specID, unit)
    if specID and IT_SPEC_NO_INTERRUPT[specID] then
        return false
    end
    local override = specID and IT_SPEC_OVERRIDE[specID] or nil
    if not override then
        return true
    end
    local applyOverride = true
    if override.isPet then
        local petUnit = nil
        if unit == "player" then
            petUnit = "pet"
        else
            local roster = self:GetUnitForMember(member.name)
            petUnit = roster and roster.petUnit or nil
        end
        local family = petUnit and UnitExists(petUnit) and UnitCreatureFamily and UnitCreatureFamily(petUnit) or nil
        if override.requiredFamily and family ~= override.requiredFamily then
            applyOverride = false
        end
        if petUnit and not UnitExists(petUnit) then
            applyOverride = false
        end
    end
    if applyOverride then
        member.spellID = override.id
        member.baseCd = override.cd
        member.isPetSpell = override.isPet and true or false
        member.petSpellID = override.petSpellID
        member.icon = override.petSpellID and IT_SafeSpellTexture(override.petSpellID) or IT_GetPrimaryIcon(override.id)
    else
        member.spellID = 19647
        member.baseCd = (IT_INTERRUPTS[19647] and IT_INTERRUPTS[19647].cd) or 24
        member.isPetSpell = false
        member.petSpellID = nil
        member.icon = IT_GetPrimaryIcon(19647)
    end
    return true
end

function InterruptTracker:CollectInspectTalentSpellIDs()
    local talentSpellIDs = {}
    local hasValidInspectData = false
    if C_Traits and C_Traits.HasValidInspectData then
        local okValid, validInspectData = pcall(C_Traits.HasValidInspectData)
        hasValidInspectData = okValid and validInspectData and true or false
    end

    local hasReadableTraitTree = false
    if C_Traits and C_Traits.GetConfigInfo and C_Traits.GetTreeNodes then
        local okConfig, configInfo = pcall(C_Traits.GetConfigInfo, -1)
        if okConfig and configInfo and configInfo.treeIDs and configInfo.treeIDs[1] then
            local okNodes, nodeIDs = pcall(C_Traits.GetTreeNodes, configInfo.treeIDs[1])
            if okNodes and type(nodeIDs) == "table" and #nodeIDs > 0 then
                hasReadableTraitTree = true
                for _, nodeID in ipairs(nodeIDs) do
                    local okNode, nodeInfo = pcall(C_Traits.GetNodeInfo, -1, nodeID)
                    if okNode and nodeInfo and nodeInfo.activeEntry and nodeInfo.activeRank and nodeInfo.activeRank > 0 then
                        local entryID = nodeInfo.activeEntry.entryID
                        local okEntry, entryInfo = pcall(C_Traits.GetEntryInfo, -1, entryID)
                        if okEntry and entryInfo and entryInfo.definitionID then
                            local okDef, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
                            if okDef and defInfo and defInfo.spellID then
                                talentSpellIDs[#talentSpellIDs + 1] = defInfo.spellID
                            end
                        end
                    end
                end
            end
        end
    end

    return (hasValidInspectData or hasReadableTraitTree) and hasReadableTraitTree, talentSpellIDs
end

function InterruptTracker:ScanInspectTalentsInternal(unit)
    local result = {
        talentDataValid = false,
        committed = false,
    }
    local name = IT_SafeUnitName(unit)
    if not name then
        return result
    end
    local member = self:GetMemberRecord(name, false)
    if not member then
        member = self:EnsureMemberRecordFromUnit(unit, name)
    end
    if not member then
        return result
    end
    local beforeSeedState = self:CaptureSeedState(member)

    local working = {
        name = member.name,
        class = member.class,
        spellID = nil,
        baseCd = nil,
        cdEnd = member.cdEnd,
        extraKicks = {},
        _previousExtraKicks = member.extraKicks,
        onKickReduction = nil,
        hasLightOfTheSun = false,
        requiresPrimaryTargetConfirm = false,
        primaryTargetOnKickReduction = nil,
        hasColdthirst = false,
        requiresOwnerInterruptConfirm = false,
        ownerInterruptReduction = nil,
        isPetSpell = false,
        petSpellID = nil,
        unitGUID = IT_NormalizeSafeString(member.unitGUID) or IT_SafeUnitGUID(unit),
        icon = nil,
        lastActivityAt = member.lastActivityAt,
        offlineSinceAt = member.offlineSinceAt,
        lastDeathAt = member.lastDeathAt,
        lastDeadOrGhost = member.lastDeadOrGhost,
        fullWipeRecoverySeenAt = member.fullWipeRecoverySeenAt,
    }
    self:ResetTalentDerivedInterruptFields(working)

    local specID = GetInspectSpecialization and GetInspectSpecialization(unit) or 0
    local resolvedSpecID = (specID and specID > 0) and specID or member.specID
    if resolvedSpecID and resolvedSpecID > 0 then
        working.specID = resolvedSpecID
        working.specName = IT_GetSpecName(resolvedSpecID)
    end
    if not self:RebuildCanonicalPrimaryState(working, resolvedSpecID, unit) then
        if resolvedSpecID and IT_SPEC_NO_INTERRUPT[resolvedSpecID] then
            self.noInterruptPlayers[name] = working.unitGUID or true
            self:ClearInterruptCountRecordsForMember(name, working.unitGUID)
            self:ClearFullWipeRecordsForMember(member)
            self.trackedMembers[name] = nil
            self:ClearInspectResolutionStateFor(name)
            self.inspectedPlayers[name] = working.unitGUID or true
            if self:DidSeedStateChange(beforeSeedState, nil) then
                self:ReseedModeBOrder()
            end
            result.talentDataValid = true
            result.committed = true
            return result
        end
        return result
    end

    local talentDataValid, talentSpellIDs = self:CollectInspectTalentSpellIDs()
    if talentDataValid then
        for _, spellID in ipairs(talentSpellIDs) do
            self:ApplyMemberTalent(spellID, working, resolvedSpecID)
        end
    end

    self:CommitInspectResolvedInterruptState(member, working, talentDataValid)
    if self:DidSeedStateChange(beforeSeedState, member) then
        self:ReseedModeBOrder()
    end
    result.talentDataValid = talentDataValid
    result.committed = true
    return result
end

function InterruptTracker:CancelInspectReadyRetryTimer()
    if self.inspectReadyRetryTimer then
        self.inspectReadyRetryTimer:Cancel()
        self.inspectReadyRetryTimer = nil
    end
end

function InterruptTracker:CancelInspectTimeout()
    if self.inspectTimeoutTimer then
        self.inspectTimeoutTimer:Cancel()
        self.inspectTimeoutTimer = nil
    end
end

function InterruptTracker:CancelInspectDelayTimer()
    if self.inspectDelayTimer then
        self.inspectDelayTimer:Cancel()
        self.inspectDelayTimer = nil
    end
end

function InterruptTracker:CancelInspectStepTimer()
    if self.inspectStepTimer then
        self.inspectStepTimer:Cancel()
        self.inspectStepTimer = nil
    end
end

function InterruptTracker:IsInspectContextSafe()
    return not (InCombatLockdown and InCombatLockdown())
end

function InterruptTracker:ClearInspectSessionState()
    self:CancelInspectReadyRetryTimer()
    self:CancelInspectTimeout()
    if self.inspectBusy or self.inspectUnit or self.inspectTargetGUID or self.inspectTargetName then
        pcall(ClearInspectPlayer)
    end
    self.inspectBusy = false
    self.inspectUnit = nil
    self.inspectTargetGUID = nil
    self.inspectTargetName = nil
    self.inspectReadyRetryCount = 0
    self.inspectReadyRetryExpectedGUID = nil
end

function InterruptTracker:DoesInspectReadyMatchActiveTarget(inspectedGUID)
    if not self.inspectBusy or not self.inspectUnit then
        return false
    end

    local activeGUID = IT_NormalizeSafeString(self.inspectTargetGUID)
    local readyGUID = IT_NormalizeSafeString(inspectedGUID)
    if activeGUID and readyGUID then
        return IT_SafeStringsEqual(activeGUID, readyGUID)
    end
    if activeGUID and readyGUID == nil then
        local liveGUID = IT_SafeUnitGUID(self.inspectUnit)
        if liveGUID and IT_SafeStringsEqual(activeGUID, liveGUID) then
            return true
        end
    end

    local activeName = IT_NormalizeName(self.inspectTargetName)
    local liveName = IT_SafeUnitName(self.inspectUnit)
    if activeName and liveName then
        return IT_SafeStringsEqual(activeName, liveName)
    end

    return activeGUID == nil and activeName == nil
end

function InterruptTracker:CanContinueInspectReadyRetry(expectedGUID)
    if not self.inspectBusy or not self.inspectUnit or not UnitExists(self.inspectUnit) then
        return false
    end
    if not self:ShouldAllowPartyInspectRefresh() or self:IsIdentityFrozen() or self:IsActiveChallengeRun() then
        return false
    end
    local activeGUID = IT_NormalizeSafeString(self.inspectTargetGUID) or IT_SafeUnitGUID(self.inspectUnit)
    local targetGUID = IT_NormalizeSafeString(expectedGUID)
    if targetGUID and activeGUID and not IT_SafeStringsEqual(activeGUID, targetGUID) then
        return false
    end
    return true
end

function InterruptTracker:ScheduleInspectQueueStep(delaySeconds)
    self:CancelInspectStepTimer()
    if not self:ShouldAllowPartyInspectRefresh() then
        self:HardCancelInspectRefresh()
        return
    end
    local delay = tonumber(delaySeconds) or IT_INSPECT_STEP_DELAY
    if not (C_Timer and C_Timer.NewTimer) then
        self:ProcessInspectQueue()
        return
    end
    self.inspectStepTimer = C_Timer.NewTimer(delay, function()
        PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_inspect_step")
        local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
        self.inspectStepTimer = nil
        self:ProcessInspectQueue()
        PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
    end)
end

function InterruptTracker:AbortInspectSession(scheduleResume)
    self:ClearInspectSessionState()
    if scheduleResume then
        self:ScheduleInspectQueueStep()
    end
end

function InterruptTracker:HandleInspectTalentDataNotReady(expectedGUID)
    if (tonumber(self.inspectReadyRetryCount) or 0) < IT_INSPECT_READY_MAX_RETRIES then
        self.inspectReadyRetryCount = (tonumber(self.inspectReadyRetryCount) or 0) + 1
        local retryGUID = IT_NormalizeSafeString(expectedGUID) or IT_NormalizeSafeString(self.inspectTargetGUID)
        self.inspectReadyRetryExpectedGUID = retryGUID
        self:CancelInspectReadyRetryTimer()
        self.inspectReadyRetryTimer = C_Timer.NewTimer(IT_INSPECT_READY_RETRY_DELAY, function()
            self.inspectReadyRetryTimer = nil
            if not self:CanContinueInspectReadyRetry(retryGUID) then
                return
            end
            local retryResult = nil
            pcall(function()
                retryResult = self:ScanInspectTalentsInternal(self.inspectUnit)
            end)
            if retryResult and retryResult.talentDataValid then
                self:AbortInspectSession(true)
                return
            end
            self:HandleInspectTalentDataNotReady(retryGUID)
        end)
        return true
    end

    local targetName = IT_NormalizeName(self.inspectTargetName)
    if targetName then
        self:SetInspectBackoff(targetName, expectedGUID or self.inspectTargetGUID, GetTime() + IT_INSPECT_REQUEUE_BACKOFF)
    end
    self:AbortInspectSession(false)
    self:QueuePartyInspectDelayed(nil, IT_INSPECT_REQUEUE_BACKOFF)
    return false
end

function InterruptTracker:HardCancelInspectRefresh()
    self:CancelInspectDelayTimer()
    self:CancelInspectStepTimer()
    self.inspectQueue = {}
    self:AbortInspectSession(false)
end

function InterruptTracker:ResetInspectSessionFor(name)
    self:HardCancelInspectRefresh()
    self:ClearInspectRefreshTrackingFor(name)
end

function InterruptTracker:ArmInspectTimeout(expectedGUID, expectedName)
    self:CancelInspectTimeout()
    self.inspectTimeoutTimer = C_Timer.NewTimer(IT_INSPECT_TIMEOUT, function()
        local activeGUID = IT_NormalizeSafeString(self.inspectTargetGUID)
        local targetGUID = IT_NormalizeSafeString(expectedGUID)
        if targetGUID and activeGUID and not IT_SafeStringsEqual(activeGUID, targetGUID) then
            return
        end
        local activeName = IT_NormalizeName(self.inspectTargetName)
        local targetName = IT_NormalizeName(expectedName)
        if targetName and activeName and not IT_SafeStringsEqual(activeName, targetName) then
            return
        end
        self:AbortInspectSession(true)
    end)
end

function InterruptTracker:GetQueuedInspectIdentity(unit)
    if not (unit and UnitExists(unit)) then
        return nil, nil
    end
    if UnitIsConnected and not UnitIsConnected(unit) then
        return nil, nil
    end
    local name = IT_SafeUnitName(unit)
    if not name or self.inspectedPlayers[name] then
        return nil, nil
    end
    local guid = IT_SafeUnitGUID(unit)
    local backoffActive = self:IsInspectBackoffActive(name, guid, GetTime())
    if backoffActive then
        return nil, nil
    end
    return name, guid
end

function InterruptTracker:ProcessInspectQueue()
    if not self:ShouldAllowPartyInspectRefresh() then
        self:HardCancelInspectRefresh()
        return
    end
    if self.inspectBusy then
        return
    end
    if not self:IsInspectContextSafe() then
        return
    end
    while #self.inspectQueue > 0 do
        local unit = table.remove(self.inspectQueue, 1)
        local name, guid = self:GetQueuedInspectIdentity(unit)
        if name and PA_CanSafelyInspectUnit(unit) then
            self.inspectBusy = true
            self.inspectUnit = unit
            self.inspectTargetName = name
            self.inspectTargetGUID = guid
            self.inspectReadyRetryCount = 0
            self.inspectReadyRetryExpectedGUID = guid
            local ok = pcall(NotifyInspect, unit)
            if ok then
                self:ArmInspectTimeout(guid, name)
                return
            end
            self:AbortInspectSession(false)
        end
    end
end

function InterruptTracker:QueuePartyInspect(targetUnit)
    if not self:ShouldAllowPartyInspectRefresh() then
        self:HardCancelInspectRefresh()
        return
    end
    self:BuildUnitMap()
    local nextQueue = {}
    local seenNames = {}
    local seenGUIDs = {}

    local function queueUnit(unit)
        local name, guid = self:GetQueuedInspectIdentity(unit)
        if not name then
            return
        end
        if self.inspectTargetName and IT_SafeStringsEqual(self.inspectTargetName, name) then
            return
        end
        if guid and self.inspectTargetGUID and IT_SafeStringsEqual(self.inspectTargetGUID, guid) then
            return
        end
        if seenNames[name] or (guid and seenGUIDs[guid]) then
            return
        end
        nextQueue[#nextQueue + 1] = unit
        seenNames[name] = true
        if guid then
            seenGUIDs[guid] = true
        end
    end

    if targetUnit then
        queueUnit(targetUnit)
    else
        for i = 1, 4 do
            queueUnit("party" .. i)
        end
    end
    self.inspectQueue = nextQueue
    self:ProcessInspectQueue()
end

function InterruptTracker:QueuePartyInspectDelayed(targetUnit, delaySeconds)
    self:CancelInspectStepTimer()
    self:CancelInspectDelayTimer()
    if not self:ShouldAllowPartyInspectRefresh() then
        self:HardCancelInspectRefresh()
        return
    end
    local delay = tonumber(delaySeconds) or IT_QUEUE_INSPECT_DELAY
    self.inspectDelayTimer = C_Timer.NewTimer(delay, function()
        PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_inspect_delay")
        local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
        self.inspectDelayTimer = nil
        self:QueuePartyInspect(targetUnit)
        PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
    end)
end

function InterruptTracker:ResetInspectStateFor(name)
    self:ClearInspectResolutionStateFor(name)
end

function InterruptTracker:CleanupRosterState()
    self:BuildUnitMap()
    local current = {}
    for _, entry in ipairs(self:GetCurrentRoster(true)) do
        if entry.name then
            current[entry.name] = entry
        end
    end
    if not self:IsTrackedPartyContext() then
        wipe(self.trackedMembers or {})
        wipe(self.noInterruptPlayers or {})
        self:ClearInspectResolutionStateFor()
        wipe(self.recentPartyCasts or {})
        self:ResetPendingPartyCreditRuntime()
        self:ClearPendingOwnerPrimaryCast()
        if self.interruptCounts then
            wipe(self.interruptCounts)
        end
        if self.recentCountedInterruptsByMember then
            wipe(self.recentCountedInterruptsByMember)
        end
        self:ResetFullWipeRecoveryState()
        self:ClearOwnerInterruptPending()
        if self.rowReadyState then
            for name in pairs(self.rowReadyState) do
                if not self.selfState or self.selfState.name ~= name then
                    self.rowReadyState[name] = nil
                end
            end
        end
        self:HardCancelInspectRefresh()
        return
    end

    local rosterChanged = false
    for name in pairs(self.trackedMembers or {}) do
        local liveEntry = current[name]
        local member = self.trackedMembers[name]
        local guidMismatch = member and member.unitGUID and liveEntry and liveEntry.guid and not IT_SafeStringsEqual(member.unitGUID, liveEntry.guid)
        if (not liveEntry) or guidMismatch then
            if self:MemberQualifiesForSeed(member) then
                rosterChanged = true
            end
            self:ClearInterruptCountRecordsForMember(name, member and member.unitGUID or nil)
            self:ClearFullWipeRecordsForMember(member)
            self.trackedMembers[name] = nil
            self.recentPartyCasts[name] = nil
            self.noInterruptPlayers[name] = nil
            self:ClearInspectResolutionStateFor(name)
            if self.interruptCounts then
                self.interruptCounts[name] = nil
            end
        elseif liveEntry.guid and member and not IT_NormalizeSafeString(member.unitGUID) then
            member.unitGUID = IT_NormalizeSafeString(liveEntry.guid)
        end
    end
    for name, blockedValue in pairs(self.noInterruptPlayers or {}) do
        local liveEntry = current[name]
        if (not liveEntry) or (IT_NormalizeSafeString(blockedValue) and liveEntry.guid and not IT_SafeStringsEqual(blockedValue, liveEntry.guid)) then
            self.noInterruptPlayers[name] = nil
        end
    end
    for name, inspectedValue in pairs(self.inspectedPlayers or {}) do
        local liveEntry = current[name]
        if (not liveEntry) or (IT_NormalizeSafeString(inspectedValue) and liveEntry.guid and not IT_SafeStringsEqual(inspectedValue, liveEntry.guid)) then
            self:ClearInspectResolutionStateFor(name)
        end
    end
    for name in pairs(self.recentPartyCasts or {}) do
        if not current[name] then
            self.recentPartyCasts[name] = nil
        end
    end
    for name in pairs(self.rowReadyState or {}) do
        if not current[name] and (not self.selfState or self.selfState.name ~= name) then
            self.rowReadyState[name] = nil
        end
    end
    self:RetirePendingPartyCreditCandidatesForMissingRoster(current, GetTime())
    if self.inspectQueue and #self.inspectQueue > 0 then
        local nextQueue = {}
        for _, unit in ipairs(self.inspectQueue) do
            local queuedName = UnitExists(unit) and IT_SafeUnitName(unit) or nil
            local queuedGuid = UnitExists(unit) and IT_SafeUnitGUID(unit) or nil
            if queuedName and current[queuedName] and ((not queuedGuid) or (not current[queuedName].guid) or IT_SafeStringsEqual(current[queuedName].guid, queuedGuid)) then
                nextQueue[#nextQueue + 1] = unit
            end
        end
        self.inspectQueue = nextQueue
    end
    if self.inspectUnit then
        local inspectName = UnitExists(self.inspectUnit) and IT_SafeUnitName(self.inspectUnit) or nil
        local activeGuid = IT_NormalizeSafeString(self.inspectTargetGUID)
        local liveEntry = inspectName and current[inspectName] or nil
        if (not inspectName) or (not liveEntry) or (activeGuid and liveEntry.guid and not IT_SafeStringsEqual(activeGuid, liveEntry.guid)) then
            self:AbortInspectSession(true)
        end
    end
    if rosterChanged then
        self:ReseedModeBOrder()
    end
end

function InterruptTracker:AutoRegisterUnitByClass(unit, ignoreRoleFilter)
    if not unit or not UnitExists(unit) then
        return false
    end
    if unit ~= "player" and UnitIsConnected and not UnitIsConnected(unit) then
        return false
    end
    local name = IT_SafeUnitName(unit)
    local classFile = IT_SafeUnitClass(unit)
    if not name or not classFile then
        return false
    end
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) or "NONE"
    local kick = classFile and IT_CLASS_PRIMARY[classFile] or nil
    if (not kick) and classFile and type(IT_CLASS_INTERRUPT_LIST[classFile]) == "table" then
        local fallbackSpellID = IT_CLASS_INTERRUPT_LIST[classFile][1]
        local fallbackData = fallbackSpellID and IT_INTERRUPTS[fallbackSpellID] or nil
        if fallbackData then
            kick = {
                id = fallbackSpellID,
                cd = fallbackData.cd,
                name = fallbackData.name,
            }
        end
    end
    if not kick then
        return false
    end
    if (not ignoreRoleFilter) and role == "HEALER" and not IT_HEALER_KEEPS_KICK[classFile] then
        local previousMember = self.trackedMembers[name]
        if self:MemberQualifiesForSeed(previousMember) then
            self:ClearInterruptCountRecordsForMember(name, previousMember and previousMember.unitGUID or nil)
            self:ClearFullWipeRecordsForMember(previousMember)
            self.trackedMembers[name] = nil
            self.noInterruptPlayers[name] = IT_SafeUnitGUID(unit) or true
            self:ClearInspectResolutionStateFor(name)
            return true
        end
        self:ClearInterruptCountRecordsForMember(name, previousMember and previousMember.unitGUID or nil)
        self:ClearFullWipeRecordsForMember(previousMember)
        self.trackedMembers[name] = nil
        self.noInterruptPlayers[name] = IT_SafeUnitGUID(unit) or true
        self:ClearInspectResolutionStateFor(name)
        return false
    end
    if (not ignoreRoleFilter) and self.noInterruptPlayers[name] then
        return false
    end
    local member = self:GetMemberRecord(name, true)
    local beforeSeedState = self:CaptureSeedState(member)
    self:CommitAutoRegisterResolvedInterruptState(member, classFile, kick, unit)
    return self:DidSeedStateChange(beforeSeedState, member)
end

function InterruptTracker:AutoRegisterPartyByClass()
    self:BuildUnitMap()
    local seedChanged = false
    for i = 1, 4 do
        if self:AutoRegisterUnitByClass("party" .. i) then
            seedChanged = true
        end
    end
    self:CleanupRosterState()
    if seedChanged then
        self:ReseedModeBOrder()
    end
end

function InterruptTracker:ReadSelfTalentData(member, configID)
    if not configID then
        return
    end
    local okConfig, configInfo = pcall(C_Traits.GetConfigInfo, configID)
    if not okConfig or not configInfo or not configInfo.treeIDs or not configInfo.treeIDs[1] then
        return
    end
    local okNodes, nodeIDs = pcall(C_Traits.GetTreeNodes, configInfo.treeIDs[1])
    if not okNodes or type(nodeIDs) ~= "table" then
        return
    end
    for _, nodeID in ipairs(nodeIDs) do
        local okNode, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID)
        if okNode and nodeInfo and nodeInfo.activeEntry and nodeInfo.activeRank and nodeInfo.activeRank > 0 then
            local entryID = nodeInfo.activeEntry.entryID
            local okEntry, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
            if okEntry and entryInfo and entryInfo.definitionID then
                local okDef, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
                if okDef and defInfo and defInfo.spellID then
                    self:ApplyMemberTalent(defInfo.spellID, member, member.specID)
                end
            end
        end
    end
end

function InterruptTracker:DetectPetSpellAvailable(spellID, petSpellID)
    if not spellID then
        return false
    end
    if IsSpellKnown and IsSpellKnown(spellID, true) then
        return true
    end
    if petSpellID and IsSpellKnown and IsSpellKnown(petSpellID, true) then
        return true
    end
    if IsSpellKnown and IsSpellKnown(spellID) then
        return true
    end
    local okPlayerSpell, isKnown = pcall(IsPlayerSpell, spellID)
    if okPlayerSpell and isKnown then
        return true
    end
    if petSpellID and UnitExists("pet") then
        local okPetPlayer, petKnown = pcall(IsPlayerSpell, petSpellID)
        if okPetPlayer and petKnown then
            return true
        end
    end
    return false
end

function InterruptTracker:FindMyInterrupt()
    self.playerName = IT_NormalizeName(UnitName("player"))
    self.playerClass = select(2, UnitClass("player"))
    self:ClearOwnerInterruptPending()
    self:ClearPendingOwnerPrimaryCast()

    local oldState = self.selfState or {}
    local beforeSeedState = self:CaptureSeedState(oldState)
    local member = {
        name = self.playerName,
        class = self.playerClass,
        fromAddon = true,
        isSelf = true,
        extraKicks = {},
        cdEnd = oldState.cdEnd or 0,
        baseCd = nil,
        onKickReduction = nil,
        hasLightOfTheSun = false,
        requiresPrimaryTargetConfirm = false,
        primaryTargetOnKickReduction = nil,
        hasColdthirst = false,
        requiresOwnerInterruptConfirm = false,
        ownerInterruptReduction = nil,
        lastActivityAt = oldState.lastActivityAt or 0,
        offlineSinceAt = nil,
        unitGUID = IT_NormalizeSafeString(oldState.unitGUID) or IT_SafeUnitGUID("player"),
        lastDeathAt = tonumber(oldState.lastDeathAt) or 0,
        lastDeadOrGhost = oldState.lastDeadOrGhost and true or false,
        fullWipeRecoverySeenAt = tonumber(oldState.fullWipeRecoverySeenAt) or 0,
    }

    local specIndex = GetSpecialization and GetSpecialization() or nil
    local specID = specIndex and GetSpecializationInfo(specIndex) or nil
    member.specID = specID
    member.specName = IT_GetSpecName(specID)

    local override = specID and IT_SPEC_OVERRIDE[specID] or nil
    if override and override.isPet then
        local family = UnitExists("pet") and UnitCreatureFamily and UnitCreatureFamily("pet") or nil
        local available = self:DetectPetSpellAvailable(override.id, override.petSpellID)
        if available and (not override.requiredFamily or family == override.requiredFamily) then
            member.spellID = override.id
        end
    elseif override then
        member.spellID = override.id
    end

    local specExtraKicks = specID and IT_GetSpecExtraKicks(specID) or nil
    if specExtraKicks then
        for _, extra in ipairs(specExtraKicks) do
            local checkID = extra.talentCheck or extra.id
            local known = false
            if IsSpellKnown and IsSpellKnown(checkID, true) then
                known = true
            elseif extra.petSpellID and IsSpellKnown and IsSpellKnown(extra.petSpellID, true) then
                known = true
            elseif IsSpellKnown and IsSpellKnown(checkID) then
                known = true
            else
                local okKnown, playerKnown = pcall(IsPlayerSpell, checkID)
                known = okKnown and playerKnown or false
                if not known and extra.petSpellID and UnitExists("pet") then
                    local okPetKnown, petKnown = pcall(IsPlayerSpell, extra.petSpellID)
                    known = okPetKnown and petKnown or false
                end
            end
            if known then
                local oldCd = 0
                for _, oldExtra in ipairs(oldState.extraKicks or {}) do
                    if oldExtra.spellID == extra.id then
                        oldCd = oldExtra.cdEnd or 0
                        break
                    end
                end
                member.extraKicks[#member.extraKicks + 1] = {
                    spellID = extra.id,
                    baseCd = extra.cd,
                    cdEnd = oldCd,
                    name = extra.name,
                    icon = IT_GetExtraKickIcon(extra),
                }
            end
        end
    end

    local managedExtras = {}
    if specExtraKicks then
        for _, extra in ipairs(specExtraKicks) do
            managedExtras[extra.id] = true
        end
    end
    for _, spellID in ipairs(IT_CLASS_INTERRUPT_LIST[self.playerClass] or {}) do
        local known = (IsSpellKnown and (IsSpellKnown(spellID) or IsSpellKnown(spellID, true))) and true or false
        if not known then
            local okKnown, playerKnown = pcall(IsPlayerSpell, spellID)
            known = okKnown and playerKnown or false
        end
        if known then
            if not member.spellID then
                member.spellID = spellID
            elseif spellID ~= member.spellID and not managedExtras[spellID] then
                local existing = false
                for _, extra in ipairs(member.extraKicks) do
                    if extra.spellID == spellID then
                        existing = true
                        break
                    end
                end
                if not existing then
                    local data = IT_INTERRUPTS[spellID]
                    local oldCd = 0
                    for _, oldExtra in ipairs(oldState.extraKicks or {}) do
                        if oldExtra.spellID == spellID then
                            oldCd = oldExtra.cdEnd or 0
                            break
                        end
                    end
                    member.extraKicks[#member.extraKicks + 1] = {
                        spellID = spellID,
                        baseCd = data and data.cd or 15,
                        cdEnd = oldCd,
                        name = data and data.name or "Interrupt",
                        icon = IT_GetPrimaryIcon(spellID),
                    }
                end
            end
        end
    end

    if self:RebuildCanonicalPrimaryState(member, specID, "player") then
        if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
            local okConfig, configID = pcall(C_ClassTalents.GetActiveConfigID)
            if okConfig and configID then
                self:ReadSelfTalentData(member, configID)
            end
        end
    else
        member.spellID = nil
        member.baseCd = nil
        member.isPetSpell = false
        member.petSpellID = nil
        member.icon = nil
    end

    self.selfState = member
    self:CleanupRosterState()
    if self:DidSeedStateChange(beforeSeedState, member) then
        self:ReseedModeBOrder()
    end
end

function InterruptTracker:ApplyOnKickReduction(member)
    if not member or not member.onKickReduction then
        return
    end
    local now = GetTime()
    member.cdEnd = math.max(now, (tonumber(member.cdEnd) or now) - tonumber(member.onKickReduction or 0))
end

function InterruptTracker:ShouldIgnoreStaleNormalCastAfterAdj(member, spellID, cooldownSeconds, now)
    local resolvedSpellID = tonumber(spellID) or 0
    if not member or not IT_OWNER_CONFIRMED_CONDITIONAL_SPELLS[resolvedSpellID] then
        return false
    end
    self:ExpireAdjGuard(member, now)
    if member.lastAdjSpellID ~= resolvedSpellID then
        return false
    end
    if (tonumber(member.lastAdjIgnoreCastUntil) or 0) < (tonumber(now) or GetTime()) then
        return false
    end
    local proposedCdEnd = (tonumber(now) or GetTime()) + math.max(0, tonumber(cooldownSeconds) or 0)
    return proposedCdEnd > math.max(0, tonumber(member.cdEnd) or 0)
end

function InterruptTracker:HandleConfirmedExtraKick(member, spellID, source)
    local now = GetTime()
    local resolvedExtra = self:StartExtraKickCooldownUse(member, spellID, source or "local_detect", now, "structure", "confirmed-extra")
    if not resolvedExtra then
        return false
    end
    self:CommitInterruptCredit(member, resolvedExtra.spellID, source or "local_detect", now, nil, nil)
    return resolvedExtra
end

function InterruptTracker:NormalizeLocalSelfSpellcastEvent(event, ...)
    return nil
end

function InterruptTracker:DebugSolarBeamSelfEvent(member, eventInfo)
    return
end

function InterruptTracker:EmitSolarBeamSelfCastVerdict(member, spellID, validInterrupt, broadcastCalled, localHandleCalled, verdict, castGUID)
    return
end

function InterruptTracker:CancelPendingOwnerPrimaryCastExpiry()
    if self.pendingOwnerPrimaryCastExpiryTimer then
        self.pendingOwnerPrimaryCastExpiryTimer:Cancel()
        self.pendingOwnerPrimaryCastExpiryTimer = nil
    end
end

function InterruptTracker:ClearPendingOwnerPrimaryCast()
    self:CancelPendingOwnerPrimaryCastExpiry()
    self.pendingOwnerPrimaryCast = nil
    self.lastHandledOwnerPrimaryCastGUID = nil
    self.lastHandledOwnerPrimaryCastAt = 0
    self.lastOwnerPrimaryCastVerdictGUID = nil
    self.lastOwnerPrimaryCastVerdictAt = 0
end

function InterruptTracker:ExpirePendingOwnerPrimaryCast(now)
    self:ClearPendingOwnerPrimaryCast()
end

function InterruptTracker:HasHandledOwnerPrimaryCast(castGUID)
    return false
end

function InterruptTracker:MarkHandledOwnerPrimaryCast(castGUID)
    return
end

function InterruptTracker:ArmPendingOwnerPrimaryCast(member, eventInfo, now)
    return false
end

function InterruptTracker:InvalidatePendingOwnerPrimaryCast(member, castGUID, reason)
    return false
end

function InterruptTracker:HandleLocalPrimaryUseFromEvent(member, eventInfo)
    return false
end

function InterruptTracker:HandleConfirmedPrimaryUse(member, cooldownSeconds, source)
    local now = GetTime()
    if not self:StartPrimaryCooldownUse(member, cooldownSeconds, source or "local_detect", now, "structure", "confirmed-primary") then
        return false
    end
    self:CommitInterruptCredit(member, member.spellID, source or "local_detect", now, nil, nil)
    return true
end

function InterruptTracker:GetRecentPartyCastRecord(name)
    local normalizedName = IT_NormalizeName(name)
    if not normalizedName then
        return nil
    end

    local rawRecord = self.recentPartyCasts and self.recentPartyCasts[normalizedName] or nil
    if type(rawRecord) == "number" then
        return {
            at = tonumber(rawRecord) or 0,
            spellID = 0,
            source = "legacy",
            availabilityStarted = false,
            started = false,
        }
    end
    if type(rawRecord) ~= "table" then
        return nil
    end

    local availabilityStarted = rawRecord.availabilityStarted and true or rawRecord.started and true or false
    return {
        at = tonumber(rawRecord.at) or 0,
        spellID = IT_NormalizeSpellID(rawRecord.spellID),
        source = IT_NormalizeSafeString(rawRecord.source) or "fallback",
        availabilityStarted = availabilityStarted,
        started = availabilityStarted,
    }
end

function InterruptTracker:RecordRecentPartyCast(name, spellID, source, availabilityStarted, timestamp)
    local normalizedName = IT_NormalizeName(name)
    if not normalizedName then
        return nil
    end

    self.recentPartyCasts = self.recentPartyCasts or {}
    local existing = self:GetRecentPartyCastRecord(normalizedName) or {}
    local normalizedSpellID = IT_NormalizeSpellID(spellID)
    local record = {
        at = tonumber(timestamp) or GetTime(),
        spellID = normalizedSpellID > 0 and normalizedSpellID or (tonumber(existing.spellID) or 0),
        source = IT_NormalizeSafeString(source) or existing.source or "fallback",
        availabilityStarted = (availabilityStarted and true) or (existing.availabilityStarted and true) or false,
    }
    record.started = record.availabilityStarted
    self.recentPartyCasts[normalizedName] = record
    return record
end

function InterruptTracker:RecentPartyCastMatchesSpell(record, spellID)
    if type(record) ~= "table" then
        return false
    end

    local incomingRawSpellID, incomingResolvedSpellID, incomingTracked = IT_ResolveTrackedInterruptSpellID(spellID)
    local recordRawSpellID, recordResolvedSpellID, recordTracked = IT_ResolveTrackedInterruptSpellID(record.spellID)
    if not incomingTracked or not recordTracked then
        return false
    end

    return incomingRawSpellID == recordRawSpellID
        or incomingRawSpellID == recordResolvedSpellID
        or incomingResolvedSpellID == recordRawSpellID
        or incomingResolvedSpellID == recordResolvedSpellID
end

function InterruptTracker:ShouldCoalesceObservedPartyCast(name, spellID, source, now)
    local record = self:GetRecentPartyCastRecord(name)
    if not record or not record.availabilityStarted then
        return false
    end
    if ((tonumber(now) or GetTime()) - (tonumber(record.at) or 0)) > IT_OBSERVED_CAST_COALESCE_WINDOW then
        return false
    end
    return self:RecentPartyCastMatchesSpell(record, spellID)
end

function InterruptTracker:ShouldSuppressObservedCastRestart(member, spellID, now)
    local normalizedName = IT_NormalizeName(member and member.name)
    if not normalizedName then
        return false
    end

    local record = self:GetRecentPartyCastRecord(normalizedName)
    if not record or not record.availabilityStarted then
        return false
    end
    if ((tonumber(now) or GetTime()) - (tonumber(record.at) or 0)) > IT_OBSERVED_CAST_COALESCE_WINDOW then
        return false
    end
    return self:RecentPartyCastMatchesSpell(record, spellID)
end

function InterruptTracker:ShouldStoreFallbackPartyCast(ownerUnit, ownerName, now)
    if not ownerUnit or not UnitExists(ownerUnit) then
        return false
    end

    local normalizedName = IT_NormalizeName(ownerName or IT_SafeUnitName(ownerUnit))
    if not normalizedName or normalizedName == self.playerName then
        return false
    end

    if self.noInterruptPlayers and self.noInterruptPlayers[normalizedName] then
        return false
    end

    local member = self:GetMemberRecord(normalizedName, false)
    if not member then
        member = self:EnsureMemberRecordFromUnit(ownerUnit, normalizedName)
    end
    if not member then
        return false
    end

    local classFile = member.class or IT_SafeUnitClass(ownerUnit)
    if not classFile or type(IT_CLASS_INTERRUPT_LIST[classFile]) ~= "table" then
        return false
    end

    if member.spellID and not self:IsMemberReady(member, now) then
        for _, extraKick in ipairs(member.extraKicks or {}) do
            if IT_IsReady(extraKick.cdEnd or 0, now) then
                return true
            end
        end
        return false
    end

    return true
end

function InterruptTracker:HandleObservedPartyCastEvent(ownerUnit, castUnit, source, ...)
    if not ownerUnit or not UnitExists(ownerUnit) then
        return false
    end

    local ownerName = IT_SafeUnitName(ownerUnit)
    if not ownerName then
        return false
    end

    local member = self:GetMemberRecord(ownerName, false)
    if not member then
        member = self:EnsureMemberRecordFromUnit(ownerUnit, ownerName)
    end

    local observedSpellID = IT_ResolveObservedInterruptSpellIDFromEventArgs(source, ownerUnit, member, ...)
    local now = GetTime()
    if source == "sent" then
        if self:ShouldStoreFallbackPartyCast(ownerUnit, ownerName, now) then
            self:RecordRecentPartyCast(ownerName, observedSpellID, source, false, now)
            self:MarkMemberActivity(ownerName, now)
        end
        return false
    end

    if observedSpellID and source == "succeeded" then
        return self:HandleObservedPartyInterruptCast(ownerUnit, castUnit, observedSpellID, source)
    end

    if source == "succeeded" then
        if self:ShouldStoreFallbackPartyCast(ownerUnit, ownerName, now) then
            self:RecordRecentPartyCast(ownerName, nil, source, false, now)
            self:MarkMemberActivity(ownerName, now)
        end
    end

    return false
end

function InterruptTracker:HandleObservedPartyInterruptCast(ownerUnit, castUnit, spellID, source)
    if not ownerUnit or not UnitExists(ownerUnit) then
        return false
    end

    local ownerName = IT_SafeUnitName(ownerUnit)
    if not ownerName then
        return false
    end

    local rawSpellID, resolvedSpellID, trackedInterrupt = IT_ResolveTrackedInterruptSpellID(spellID)
    if not trackedInterrupt then
        return false
    end

    local now = GetTime()
    source = IT_NormalizeSafeString(source) or "succeeded"
    if source ~= "succeeded" then
        return false
    end
    self:MarkMemberActivity(ownerName, now)

    local member = self:GetMemberRecord(ownerName, false)
    if not member then
        member = self:EnsureMemberRecordFromUnit(ownerUnit, ownerName)
    end
    if not member then
        return false
    end

    local beforeSeedState = self:CaptureSeedState(member)
    local classFile = IT_SafeUnitClass(ownerUnit)
    if classFile then
        member.class = classFile
    end
    local ownerGUID = IT_SafeUnitGUID(ownerUnit)
    if ownerGUID then
        member.unitGUID = ownerGUID
    end

    local directSpellID = IT_INTERRUPTS[rawSpellID] and rawSpellID or resolvedSpellID
    local observedCooldown = IT_GetCanonicalInterruptBaseCd(directSpellID, tonumber((IT_INTERRUPTS[directSpellID] or {}).cd)) or 15

    if self:ShouldCoalesceObservedPartyCast(ownerName, directSpellID, source, now) then
        self:RecordRecentPartyCast(ownerName, directSpellID, source, true, now)
        if self:DidSeedStateChange(beforeSeedState, member) then
            self:ReseedModeBOrder()
        end
        return true
    end

    if member.spellID and (member.spellID == rawSpellID or member.spellID == resolvedSpellID) then
        local cooldown = IT_GetCanonicalInterruptBaseCd(member.spellID, member.baseCd or observedCooldown) or observedCooldown
        self:StartPrimaryCooldownUse(member, cooldown, "party_unit_cast", now, "structure", "party-succeeded-primary")
        self:RecordRecentPartyCast(ownerName, member.spellID, source, true, now)
        self:AddPendingPartyCreditCandidate(member, member.spellID, source, now, true)
        if self:DidSeedStateChange(beforeSeedState, member) then
            self:ReseedModeBOrder()
        end
        return true
    end

    local matchedExtra = self:StartExtraKickCooldownUse(member, directSpellID, "party_unit_cast", now, "structure", "party-succeeded-extra")
    if matchedExtra then
        self:RecordRecentPartyCast(ownerName, matchedExtra.spellID, source, true, now)
        self:AddPendingPartyCreditCandidate(member, matchedExtra.spellID, source, now, true)
        if self:DidSeedStateChange(beforeSeedState, member) then
            self:ReseedModeBOrder()
        end
        return true
    end

    local observedSpecID, observedOverride = IT_GetObservedSpecOverride(directSpellID)
    local inferredState = nil
    if observedOverride then
        local overrideSpellID = tonumber(observedOverride.id) or directSpellID
        inferredState = {
            specID = observedSpecID,
            specName = IT_GetSpecName(observedSpecID),
            spellID = overrideSpellID,
            baseCd = IT_GetCanonicalInterruptBaseCd(overrideSpellID, observedOverride.cd) or observedCooldown,
            icon = observedOverride.petSpellID and IT_SafeSpellTexture(observedOverride.petSpellID) or IT_GetPrimaryIcon(overrideSpellID),
            isPetSpell = observedOverride.isPet and true or false,
            petSpellID = observedOverride.petSpellID or nil,
        }
    elseif IT_ClassSupportsInterruptSpell(member.class, directSpellID) then
        inferredState = {
            specID = member.specID,
            specName = member.specName,
            spellID = directSpellID,
            baseCd = IT_GetCanonicalInterruptBaseCd(directSpellID, observedCooldown) or observedCooldown,
            icon = IT_GetPrimaryIcon(directSpellID),
            isPetSpell = (castUnit and castUnit ~= ownerUnit) and (member.isPetSpell and true or false) or false,
            petSpellID = (castUnit and castUnit ~= ownerUnit) and member.petSpellID or nil,
        }
    end

    local inferredChanged = false
    if inferredState then
        inferredChanged = (tonumber(member.specID) or 0) ~= (tonumber(inferredState.specID) or 0)
            or tostring(member.specName or "") ~= tostring(inferredState.specName or "")
            or (tonumber(member.spellID) or 0) ~= (tonumber(inferredState.spellID) or 0)
            or (tonumber(member.baseCd) or 0) ~= (tonumber(inferredState.baseCd) or 0)
            or (member.isPetSpell and true or false) ~= (inferredState.isPetSpell and true or false)
            or (tonumber(member.petSpellID) or 0) ~= (tonumber(inferredState.petSpellID) or 0)
            or tostring(member.icon or "") ~= tostring(inferredState.icon or "")
        if inferredChanged then
            member.specID = inferredState.specID
            member.specName = inferredState.specName
            member.spellID = inferredState.spellID
            member.baseCd = inferredState.baseCd
            member.icon = inferredState.icon
            member.isPetSpell = inferredState.isPetSpell and true or false
            member.petSpellID = inferredState.petSpellID or nil
            self:ResetTalentDerivedInterruptFields(member)
        end
    end

    if member.spellID and (member.spellID == rawSpellID or member.spellID == resolvedSpellID) then
        local cooldown = IT_GetCanonicalInterruptBaseCd(member.spellID, member.baseCd or observedCooldown) or observedCooldown
        self:StartPrimaryCooldownUse(member, cooldown, "party_unit_cast", now, "structure", "party-succeeded-primary")
        self:RecordRecentPartyCast(ownerName, member.spellID, source, true, now)
        self:AddPendingPartyCreditCandidate(member, member.spellID, source, now, true)
        if observedOverride and inferredChanged and self:ShouldAllowPartyInspectRefresh() then
            self:QueuePartyInspectDelayed(ownerUnit)
        end
        if self:DidSeedStateChange(beforeSeedState, member) then
            self:ReseedModeBOrder()
        end
        return true
    end

    self:RecordRecentPartyCast(ownerName, directSpellID, source, false, now)

    if self:DidSeedStateChange(beforeSeedState, member) then
        self:ReseedModeBOrder()
    end
    return false
end

function InterruptTracker:HandleMobInterrupted(interruptedUnit)
    local now = GetTime()
    self:ResolveExpiredPendingPartyCreditPool(now)
    self:ExpireOwnerInterruptPending(now)
    self:ClearOwnerInterruptPending()
    local confirmKey = self:GetMobInterruptConfirmationKey(interruptedUnit, now)
    if self:HasConsumedMobInterruptConfirmation(confirmKey, now) then
        return
    end

    local selfConsumed = false
    if self.selfState and self.selfState.pendingOnKickReduction and self.selfLastPrimaryCastAt and (now - self.selfLastPrimaryCastAt) < IT_FALLBACK_CONFIRM_MAX_DELTA then
        self:ApplyOnKickReduction(self.selfState)
        self.selfState.pendingOnKickReduction = false
        selfConsumed = true
    end
    if selfConsumed then
        self:ResolvePendingPartyCreditPoolConfirmation(interruptedUnit, now, false, "self-confirm-consumed", nil, nil)
        self:MarkMobInterruptConfirmationConsumed(confirmKey, now)
        self:RecordRelevantTrackerActivity(now)
        return
    end

    if self:ResolvePendingPartyCreditPoolConfirmation(interruptedUnit, now, true, "party_pool_confirm", "dynamic", "party-credit-confirm") then
        self:MarkMobInterruptConfirmationConsumed(confirmKey, now)
        self:RecordRelevantTrackerActivity(now)
        return
    end

    local bestName, bestDelta, bestRecord = nil, 999, nil
    for name in pairs(self.recentPartyCasts or {}) do
        local record = self:GetRecentPartyCastRecord(name)
        local delta = now - (tonumber(record and record.at) or 0)
        if delta > IT_RECENT_CAST_KEEP then
            self.recentPartyCasts[name] = nil
        elseif delta < bestDelta then
            bestDelta = delta
            bestName = name
            bestRecord = record
        end
    end

    if bestName and bestDelta < IT_FALLBACK_CONFIRM_MAX_DELTA then
        self.recentPartyCasts[bestName] = nil
        local member = self:GetMemberRecord(bestName, false)
        local roster = self:GetUnitForMember(bestName)
        if not member then
            if roster and roster.unit then
                local classFile = IT_SafeUnitClass(roster.unit)
                local kick = classFile and IT_CLASS_PRIMARY[classFile] or nil
                if kick then
                    member = self:GetMemberRecord(bestName, true)
                    member.class = classFile
                    member.spellID = kick.id
                    member.baseCd = IT_GetCanonicalInterruptBaseCd(kick.id, kick.cd) or 15
                    member.icon = IT_GetPrimaryIcon(kick.id)
                end
            end
        end

        if member and (not member.specID) and roster and roster.unit and self:ShouldAllowPartyInspectRefresh() then
            self:QueuePartyInspectDelayed(roster.unit)
        end

        local recentSpellID = IT_NormalizeSpellID(bestRecord and bestRecord.spellID)
        local recentAvailabilityStarted = bestRecord and bestRecord.availabilityStarted and true or false
        local handledFallback = false

        if member and member.pendingOnKickReduction then
            self:ApplyOnKickReduction(member)
            member.pendingOnKickReduction = false
        end

        if member and (not recentAvailabilityStarted) and recentSpellID > 0 and self:StartExtraKickCooldownUse(member, recentSpellID, "fallback_inferred", now, "structure", "mob-interrupt-fallback-extra") then
            self:CommitInterruptCredit(member, recentSpellID, "fallback_inferred", now, nil, nil)
            handledFallback = true
        elseif member and (not recentAvailabilityStarted) and member.spellID then
            self:StartPrimaryCooldownUse(member, member.baseCd or 15, "fallback_inferred", now, "structure", "mob-interrupt-fallback-primary")
            self:CommitInterruptCredit(member, member.spellID, "fallback_inferred", now, nil, nil)
            handledFallback = true
        elseif member and recentAvailabilityStarted and recentSpellID > 0 then
            handledFallback = self:CommitInterruptCredit(member, recentSpellID, "fallback_inferred", now, "dynamic", "mob-interrupt-credit")
        elseif member and member.spellID then
            handledFallback = recentAvailabilityStarted and self:CommitInterruptCredit(member, member.spellID, "fallback_inferred", now, "dynamic", "mob-interrupt-credit") or false
        end

        if handledFallback then
            self:MarkMobInterruptConfirmationConsumed(confirmKey, now)
            self:RecordRelevantTrackerActivity(now)
        end
    end
end

function InterruptTracker:RegisterPartyWatchers()
    self:BuildUnitMap()
    self.partyWatcherUnitActive = {}
    interruptPartyFallbackFrame:UnregisterAllEvents()
    interruptPartyFallbackFrame:SetScript("OnEvent", function(_, event, unit, ...)
        if type(unit) ~= "string" or not unit:match("^party%d$") then
            return
        end
        if self.partyWatcherUnitActive and self.partyWatcherUnitActive[unit] then
            return
        end
        PA_CpuDiagRecordUnitCallback(event)
        local perfStart, perfState = PA_PerfBegin("callback_class_unit_event")
        local source = event == "UNIT_SPELLCAST_SENT" and "sent" or "succeeded"
        self:HandleObservedPartyCastEvent(unit, unit, source, ...)
        PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
    end)
    interruptPartyFallbackFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
    interruptPartyFallbackFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    for i = 1, 4 do
        local ownerUnit = "party" .. i
        local petUnit = "partypet" .. i
        local observedOwnerUnit = ownerUnit
        local observedPetUnit = petUnit

        interruptPartyFrames[i]:UnregisterAllEvents()
        interruptPartyPetFrames[i]:UnregisterAllEvents()

        if UnitExists(observedOwnerUnit) then
            self.partyWatcherUnitActive[observedOwnerUnit] = true
            interruptPartyFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SENT", observedOwnerUnit)
            interruptPartyFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", observedOwnerUnit)
            interruptPartyFrames[i]:SetScript("OnEvent", function(_, event, unit, ...)
                PA_CpuDiagRecordUnitCallback(event)
                local perfStart, perfState = PA_PerfBegin("callback_class_unit_event")
                local source = event == "UNIT_SPELLCAST_SENT" and "sent" or "succeeded"
                self:HandleObservedPartyCastEvent(observedOwnerUnit, unit or observedOwnerUnit, source, ...)
                PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            end)
        else
            self.partyWatcherUnitActive[observedOwnerUnit] = nil
            interruptPartyFrames[i]:SetScript("OnEvent", nil)
        end

        if UnitExists(observedPetUnit) then
            interruptPartyPetFrames[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", observedPetUnit)
            interruptPartyPetFrames[i]:SetScript("OnEvent", function(_, event, unit, ...)
                PA_CpuDiagRecordUnitCallback(event)
                local perfStart, perfState = PA_PerfBegin("callback_class_unit_event")
                self:HandleObservedPartyCastEvent(observedOwnerUnit, unit or observedPetUnit, "succeeded", ...)
                PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            end)
        else
            interruptPartyPetFrames[i]:SetScript("OnEvent", nil)
        end
    end
    self.partyWatchersActive = true
    self.partyWatcherSignature = self:GetPartyWatcherSignature()
end

function InterruptTracker:RegisterMobInterruptWatchers()
    if not self.mobInterruptFrame then
        self.mobInterruptFrame = CreateFrame("Frame")
    end
    self.mobInterruptFrame:UnregisterAllEvents()
    self.mobInterruptFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target", "mouseover", "focus", "boss1", "boss2", "boss3", "boss4", "boss5")
    self.mobInterruptFrame:SetScript("OnEvent", function(_, _, unit)
        PA_CpuDiagRecordUnitCallback("UNIT_SPELLCAST_INTERRUPTED")
        local perfStart, perfState = PA_PerfBegin("callback_class_unit_event")
        self:HandleMobInterrupted(unit)
        PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
    end)

    self.nameplateFrames = self.nameplateFrames or {}
    if not self.nameplateFrame then
        self.nameplateFrame = CreateFrame("Frame")
    end
    self.nameplateFrame:UnregisterAllEvents()
    self.nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self.nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self.nameplateFrame:SetScript("OnEvent", function(_, event, unit)
        PA_CpuDiagRecordUnitCallback(event)
        local perfStart, perfState = PA_PerfBegin("callback_class_unit_event")
        if event == "NAME_PLATE_UNIT_ADDED" then
            if not self.nameplateFrames[unit] then
                self.nameplateFrames[unit] = CreateFrame("Frame")
            end
            local frame = self.nameplateFrames[unit]
            frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
            frame:SetScript("OnEvent", function(_, _, interruptedUnit)
                PA_CpuDiagRecordUnitCallback("UNIT_SPELLCAST_INTERRUPTED")
                local childPerfStart, childPerfState = PA_PerfBegin("callback_class_unit_event")
                self:HandleMobInterrupted(interruptedUnit or unit)
                PA_PerfEnd("callback_class_unit_event", childPerfStart, childPerfState)
            end)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            if self.nameplateFrames[unit] then
                self.nameplateFrames[unit]:UnregisterAllEvents()
            end
        end
        PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
    end)
    for index = 1, 40 do
        local unit = "nameplate" .. index
        if UnitExists(unit) then
            if not self.nameplateFrames[unit] then
                self.nameplateFrames[unit] = CreateFrame("Frame")
            end
            local frame = self.nameplateFrames[unit]
            frame:UnregisterAllEvents()
            frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
            frame:SetScript("OnEvent", function(_, _, interruptedUnit)
                PA_CpuDiagRecordUnitCallback("UNIT_SPELLCAST_INTERRUPTED")
                local childPerfStart, childPerfState = PA_PerfBegin("callback_class_unit_event")
                self:HandleMobInterrupted(interruptedUnit or unit)
                PA_PerfEnd("callback_class_unit_event", childPerfStart, childPerfState)
            end)
        end
    end
    self.mobWatchersActive = true
end

function InterruptTracker:RegisterSelfWatchers()
    if not self.selfCastFrame then
        self.selfCastFrame = CreateFrame("Frame")
    end
    self:ClearPendingOwnerPrimaryCast()
    self:ClearOwnerInterruptPending()
    self.selfCastFrame:UnregisterAllEvents()
    self.selfCastFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
    self.selfCastFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
        PA_CpuDiagRecordUnitCallback(event)
        local perfStart, perfState = PA_PerfBegin("callback_class_unit_event")
        if event ~= "UNIT_SPELLCAST_SUCCEEDED" then
            PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            return
        end
        local member = self.selfState
        if not member or not member.spellID then
            PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            return
        end

        local rawSpellID = IT_NormalizeSpellID(spellID)
        if rawSpellID <= 0 then
            PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            return
        end

        local _, resolvedSpellID, tracked = IT_ResolveTrackedInterruptSpellID(rawSpellID)
        if not tracked then
            PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            return
        end

        local now = GetTime()
        if resolvedSpellID == member.spellID or rawSpellID == member.spellID then
            local cooldown = member.baseCd or tonumber((IT_INTERRUPTS[member.spellID] or {}).cd) or 15
            self:HandleConfirmedPrimaryUse(member, cooldown, "local_detect")
            PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            return
        end

        local matchedExtra = self:HandleConfirmedExtraKick(member, resolvedSpellID, "local_detect")
        if matchedExtra then
            PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            return
        end

        if unit ~= "player" and unit ~= "pet" then
            PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
            return
        end

        local extraData = IT_INTERRUPTS[resolvedSpellID]
        if extraData and resolvedSpellID ~= member.spellID then
            member.extraKicks = member.extraKicks or {}
            member.extraKicks[#member.extraKicks + 1] = {
                spellID = resolvedSpellID,
                baseCd = extraData.cd,
                cdEnd = now + extraData.cd,
                name = extraData.name,
                icon = IT_GetPrimaryIcon(resolvedSpellID),
            }
            self:TryCountInterrupt(member, resolvedSpellID, "local_detect", now)
            self:MarkFullWipeRecoveryEvidence(member, now)
        end
        PA_PerfEnd("callback_class_unit_event", perfStart, perfState)
    end)
    self.selfWatchersActive = true
end

function InterruptTracker:GetPartyWatcherSignature()
    local parts = {}
    for index = 1, 4 do
        local ownerUnit = "party" .. index
        local petUnit = "partypet" .. index
        parts[#parts + 1] = IT_SafeUnitGUID(ownerUnit) or (UnitExists(ownerUnit) and ownerUnit or "")
        parts[#parts + 1] = IT_SafeUnitGUID(petUnit) or (UnitExists(petUnit) and petUnit or "")
    end
    return table.concat(parts, "|")
end

function InterruptTracker:UnregisterPartyWatchers()
    self.partyWatcherUnitActive = {}
    interruptPartyFallbackFrame:UnregisterAllEvents()
    interruptPartyFallbackFrame:SetScript("OnEvent", nil)
    for index = 1, 4 do
        interruptPartyFrames[index]:UnregisterAllEvents()
        interruptPartyFrames[index]:SetScript("OnEvent", nil)
        interruptPartyPetFrames[index]:UnregisterAllEvents()
        interruptPartyPetFrames[index]:SetScript("OnEvent", nil)
    end
    self.partyWatchersActive = false
    self.partyWatcherSignature = nil
end

function InterruptTracker:UnregisterMobInterruptWatchers()
    if self.mobInterruptFrame then
        self.mobInterruptFrame:UnregisterAllEvents()
        self.mobInterruptFrame:SetScript("OnEvent", nil)
    end
    if self.nameplateFrame then
        self.nameplateFrame:UnregisterAllEvents()
        self.nameplateFrame:SetScript("OnEvent", nil)
    end
    for _, frame in pairs(self.nameplateFrames or {}) do
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
    end
    self.mobWatchersActive = false
end

function InterruptTracker:UnregisterSelfWatchers()
    if self.selfCastFrame then
        self.selfCastFrame:UnregisterAllEvents()
        self.selfCastFrame:SetScript("OnEvent", nil)
    end
    self.selfWatchersActive = false
end

function InterruptTracker:ShouldKeepPartyWatchersActive()
    return self:IsEnabled() and (self:IsSupportedLiveContext() or self:IsActiveChallengeRun())
end

function InterruptTracker:ShouldKeepMobWatchersActive()
    return self:IsEnabled() and (self:IsSupportedLiveContext() or self:IsActiveChallengeRun())
end

function InterruptTracker:ReconcileWatcherState()
    if self:IsEnabled() then
        if not self.selfWatchersActive then
            self:RegisterSelfWatchers()
        end
    else
        self:UnregisterSelfWatchers()
    end

    if self:ShouldKeepPartyWatchersActive() then
        local nextSignature = self:GetPartyWatcherSignature()
        if (not self.partyWatchersActive) or self.partyWatcherSignature ~= nextSignature then
            self:RegisterPartyWatchers()
        end
    elseif not self:IsActiveChallengeRun() then
        self:UnregisterPartyWatchers()
    end

    if self:ShouldKeepMobWatchersActive() then
        if not self.mobWatchersActive then
            self:RegisterMobInterruptWatchers()
        end
    elseif not self:IsActiveChallengeRun() then
        self:UnregisterMobInterruptWatchers()
    end
end

function InterruptTracker:HandleInspectReady(inspectedGUID)
    if not self.inspectBusy or not self.inspectUnit then
        return
    end
    if not self:DoesInspectReadyMatchActiveTarget(inspectedGUID) then
        return
    end
    local unit = self.inspectUnit
    local expectedGUID = IT_NormalizeSafeString(self.inspectTargetGUID) or IT_SafeUnitGUID(unit)
    local scanResult = nil
    pcall(function()
        scanResult = self:ScanInspectTalentsInternal(unit)
    end)
    if scanResult and scanResult.talentDataValid then
        self:AbortInspectSession(true)
        return
    end
    self:HandleInspectTalentDataNotReady(expectedGUID)
end

function InterruptTracker:ApplyPosition()
    if not self.frame then
        return
    end
    local db = self:GetDB()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", tonumber(db.x) or 0, tonumber(db.y) or 0)
end

function InterruptTracker:ResetPositionToCenter()
    local db = self:GetDB()
    db.x = 0
    db.y = 0
    self:ApplyPosition()
    Modules:NotifyPositionChanged(self.key, db.x, db.y)
    self:EvaluateVisibility()
end

function InterruptTracker:PersistPosition()
    if not self.frame then
        return
    end
    local db = self:GetDB()
    local cx, cy = self.frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not cx or not cy or not ux or not uy then
        return
    end
    db.x = math.floor((cx - ux) + 0.5)
    db.y = math.floor((cy - uy) + 0.5)
    Modules:NotifyPositionChanged(self.key, db.x, db.y)
end

function InterruptTracker:NotifyDragPosition()
    if not self.frame then
        return
    end
    local cx, cy = self.frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if not cx or not cy or not ux or not uy then
        return
    end
    Modules:NotifyPositionChanged(self.key, math.floor((cx - ux) + 0.5), math.floor((cy - uy) + 0.5))
end

local function IT_SetSpacingArmCursor(cursorPath)
    if cursorPath and SetCursor then
        pcall(SetCursor, cursorPath)
        return
    end
    if ResetCursor then
        ResetCursor()
    end
end

local function IT_RowGapDragUnits(deltaPixels, pixelsPerStep)
    local px = tonumber(deltaPixels) or 0
    local perStep = math.max(1, tonumber(pixelsPerStep) or 1)
    local sign = px < 0 and -1 or 1
    local raw = math.abs(px) / perStep
    local units
    if raw <= 8 then
        units = raw
    elseif raw <= 20 then
        units = 8 + ((raw - 8) * 1.45)
    else
        units = 25.4 + ((raw - 20) * 1.95)
    end
    return sign * math.floor(units + 0.5)
end

function InterruptTracker:GetRowGap()
    return IT_GetConfiguredRowGap(self:GetDB())
end

function InterruptTracker:CreateSpacingHandle(parent)
    local host = parent or self.frame
    if not host then
        return nil
    end

    if self.spacingHandle and self.spacingHandle:GetParent() ~= host then
        self.spacingHandle:SetParent(host)
    end

    if self.spacingHandle then
        self.spacingHandle:ClearAllPoints()
        self.spacingHandle:SetPoint("RIGHT", host, "LEFT", -IT_SPACING_ARM.OFFSET_X, 0)
        self.spacingHandle:SetFrameStrata("HIGH")
        self.spacingHandle:SetFrameLevel((host:GetFrameLevel() or 1) + 30)
        return self.spacingHandle
    end

    local handle = CreateFrame("Frame", nil, host)
    handle:SetPoint("RIGHT", host, "LEFT", -IT_SPACING_ARM.OFFSET_X, 0)
    handle:SetSize(IT_SPACING_ARM.ARM_HIT_THICKNESS + 12, IT_SPACING_ARM.ARM_LENGTH + 12)
    handle:SetFrameStrata("HIGH")
    handle:SetFrameLevel((host:GetFrameLevel() or 1) + 30)
    handle:EnableMouse(true)
    handle:EnableMouseWheel(true)
    handle:Hide()

    local backing = handle:CreateTexture(nil, "BACKGROUND")
    backing:SetTexture("Interface\\Buttons\\WHITE8x8")
    backing:SetPoint("CENTER", handle, "CENTER", 0, 0)
    backing:SetSize(IT_SPACING_ARM.ARM_HIT_THICKNESS + 18, IT_SPACING_ARM.ARM_LENGTH + 18)
    backing:SetVertexColor(0, 0, 0, 0.28)
    if backing.SetMask then
        backing:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    end
    handle.backing = backing

    local arm = CreateFrame("Button", nil, handle)
    arm.axis = "y"
    arm:SetSize(IT_SPACING_ARM.ARM_HIT_THICKNESS, IT_SPACING_ARM.ARM_LENGTH)
    arm:SetPoint("CENTER", handle, "CENTER", 0, 0)
    arm:EnableMouse(true)

    arm.line = arm:CreateTexture(nil, "ARTWORK")
    arm.line:SetTexture("Interface\\Buttons\\WHITE8x8")
    arm.line:SetPoint("CENTER", arm, "CENTER", 0, 0)
    arm.line:SetSize(IT_SPACING_ARM.ARM_THICKNESS, IT_SPACING_ARM.ARM_LENGTH)

    arm.glow = arm:CreateTexture(nil, "OVERLAY")
    arm.glow:SetTexture("Interface\\Buttons\\WHITE8x8")
    arm.glow:SetPoint("CENTER", arm.line, "CENTER", 0, 0)
    arm.glow:SetSize(IT_SPACING_ARM.ARM_THICKNESS + 4, IT_SPACING_ARM.ARM_LENGTH + 4)
    arm.glow:SetBlendMode("ADD")
    arm.glow:SetVertexColor(1.0, 0.84, 0.1, 0)
    handle.yArm = arm

    local center = handle:CreateTexture(nil, "OVERLAY")
    center:SetTexture("Interface\\Buttons\\WHITE8x8")
    center:SetSize(IT_SPACING_ARM.CENTER_SIZE, IT_SPACING_ARM.CENTER_SIZE)
    center:SetPoint("CENTER", handle, "CENTER", 0, 0)
    center:SetVertexColor(1.0, 0.82, 0.0, 0.9)
    if center.SetMask then
        center:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    end
    handle.centerNode = center

    local unlockHint = CreateFrame("Frame", nil, handle, "BackdropTemplate")
    unlockHint:SetPoint("TOP", handle, "BOTTOM", 0, -8)
    unlockHint:SetSize(360, 18)
    if unlockHint.SetBackdrop then
        unlockHint:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        unlockHint:SetBackdropColor(0, 0, 0, 0.62)
        unlockHint:SetBackdropBorderColor(1, 1, 1, 0.06)
    end
    unlockHint.text = unlockHint:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    unlockHint.text:SetPoint("CENTER", unlockHint, "CENTER", 0, 0)
    unlockHint.text:SetText("")
    unlockHint.text:SetTextColor(0.76, 0.76, 0.76, 0.92)
    unlockHint:Hide()
    handle.unlockHint = unlockHint

    local function refreshVisual()
        local hot = handle._active or handle._hover
        if hot then
            arm.line:SetVertexColor(1.0, 0.84, 0.1, 0.95)
            arm.glow:SetVertexColor(1.0, 0.84, 0.1, 0.35)
        else
            arm.line:SetVertexColor(0.72, 0.72, 0.72, 0.35)
            arm.glow:SetVertexColor(1.0, 0.84, 0.1, 0)
        end
    end
    handle._refreshVisual = refreshVisual
    refreshVisual()

    local function showTip(anchor, line1, line2)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(anchor, "ANCHOR_TOP")
        GameTooltip:SetText(line1, 1, 0.82, 0, 1, true)
        if line2 and line2 ~= "" then
            GameTooltip:AddLine(line2, 0.85, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end

    local function applyTooltip(showing)
        if not showing then
            PA_HideTooltipIfOwnedBy(handle)
            return
        end
        showTip(handle, "Drag vertical to adjust Y spacing", "Scroll to adjust Y spacing (Shift fine / Alt coarse)")
    end

    local function requestTooltip(showing)
        handle._tooltipWanted = showing and true or false
        handle._tooltipDebounceToken = (handle._tooltipDebounceToken or 0) + 1
        local token = handle._tooltipDebounceToken
        if not (C_Timer and C_Timer.After) then
            applyTooltip(showing)
            return
        end
        C_Timer.After(IT_SPACING_ARM.TOOLTIP_DEBOUNCE, function()
            if self.spacingHandle ~= handle then
                return
            end
            if token ~= handle._tooltipDebounceToken then
                return
            end
            if handle._tooltipWanted ~= (showing and true or false) then
                return
            end
            applyTooltip(showing)
        end)
    end

    local function armEnter()
        handle._hover = true
        refreshVisual()
        IT_SetSpacingArmCursor(IT_SPACING_ARM.CURSOR_Y)
        requestTooltip(true)
    end

    local function armLeave()
        if not handle._active then
            handle._hover = false
            refreshVisual()
            IT_SetSpacingArmCursor(nil)
        end
        requestTooltip(false)
    end

    arm:SetScript("OnEnter", armEnter)
    arm:SetScript("OnLeave", armLeave)
    arm:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            self:BeginRowGapDrag()
        end
    end)
    arm:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            self:EndRowGapDrag()
        end
    end)

    handle:SetScript("OnMouseWheel", function(_, delta)
        if InCombatLockdown() then
            return
        end
        local step = IT_SPACING_ARM.WHEEL_BASE_STEP
        if IsAltKeyDown and IsAltKeyDown() then
            step = IT_SPACING_ARM.WHEEL_ALT_STEP
        elseif IsShiftKeyDown and IsShiftKeyDown() then
            step = IT_SPACING_ARM.WHEEL_SHIFT_STEP
        end
        if delta and delta ~= 0 then
            self:ApplyRowGapDelta(delta * step, "wheel")
        end
    end)
    handle:SetScript("OnEnter", function()
        if not handle._active then
            handle._hover = true
            refreshVisual()
            IT_SetSpacingArmCursor(IT_SPACING_ARM.CURSOR_GENERIC)
            requestTooltip(true)
        end
    end)
    handle:SetScript("OnLeave", function()
        if not handle._active then
            handle._hover = false
            refreshVisual()
            IT_SetSpacingArmCursor(nil)
            requestTooltip(false)
        end
    end)

    self.spacingHandle = handle
    return handle
end

function InterruptTracker:ShowSpacingUnlockHint()
    local handle = self.spacingHandle
    if not handle or not handle.unlockHint or not handle:IsShown() then
        return
    end
    self._spacingUnlockHintVisible = true
    handle.unlockHint:Hide()
end

function InterruptTracker:DismissSpacingUnlockHint(fadeDuration)
    local handle = self.spacingHandle
    if not handle or not handle.unlockHint then
        return
    end
    local hint = handle.unlockHint
    if not hint:IsShown() then
        self._spacingUnlockHintVisible = false
        return
    end

    self._spacingUnlockHintToken = (self._spacingUnlockHintToken or 0) + 1
    local token = self._spacingUnlockHintToken
    local fade = tonumber(fadeDuration) or IT_SPACING_ARM.UNLOCK_HINT_FAST_FADE
    if fade < 0 then
        fade = 0
    end
    if UIFrameFadeOut and fade > 0 then
        UIFrameFadeOut(hint, fade, hint:GetAlpha() or 1, 0)
        if C_Timer and C_Timer.After then
            C_Timer.After(fade, function()
                if self.spacingHandle ~= handle or not handle.unlockHint then
                    return
                end
                if token ~= self._spacingUnlockHintToken then
                    return
                end
                handle.unlockHint:Hide()
                self._spacingUnlockHintVisible = false
            end)
        else
            hint:Hide()
            self._spacingUnlockHintVisible = false
        end
    else
        hint:Hide()
        self._spacingUnlockHintVisible = false
    end
end

function InterruptTracker:PlayRowGapBoundaryPulse()
    local db = self:GetDB()
    if db.locked then
        return
    end

    local handle = self.spacingHandle
    if not handle or not handle:IsShown() then
        return
    end

    local targets = self._visibleRowPulseTargets
    if type(targets) ~= "table" or #targets == 0 then
        return
    end

    local centerY = 0
    local samples = 0
    for _, target in ipairs(targets) do
        if target and target:IsShown() and target._paSpacingPulseY ~= nil then
            centerY = centerY + (tonumber(target._paSpacingPulseY) or 0)
            samples = samples + 1
        end
    end
    if samples <= 0 then
        return
    end
    centerY = centerY / samples

    local function directionSign(value)
        if value > 0 then
            return 1
        elseif value < 0 then
            return -1
        end
        return 1
    end

    local token = (self._rowGapBoundaryPulseToken or 0) + 1
    self._rowGapBoundaryPulseToken = token

    for _, target in ipairs(targets) do
        if token ~= self._rowGapBoundaryPulseToken then
            return
        end
        if target and target:IsShown() then
            local lastY = tonumber(target._paSpacingPulseY)
            if lastY ~= nil then
                local dy = directionSign(lastY - centerY) * IT_SPACING_ARM.BOUNDARY_PULSE_AMPLITUDE
                if not target._paBoundaryPulseAG then
                    local ag = target:CreateAnimationGroup()
                    local out = ag:CreateAnimation("Translation")
                    out:SetOrder(1)
                    out:SetDuration(IT_SPACING_ARM.BOUNDARY_PULSE_OUT_DURATION)
                    if out.SetSmoothing then
                        out:SetSmoothing("OUT")
                    end

                    local back = ag:CreateAnimation("Translation")
                    back:SetOrder(2)
                    back:SetDuration(IT_SPACING_ARM.BOUNDARY_PULSE_IN_DURATION)
                    if back.SetSmoothing then
                        back:SetSmoothing("IN")
                    end

                    target._paBoundaryPulseAG = ag
                    target._paBoundaryPulseOut = out
                    target._paBoundaryPulseBack = back
                end

                local ag = target._paBoundaryPulseAG
                local out = target._paBoundaryPulseOut
                local back = target._paBoundaryPulseBack
                if ag and out and back then
                    if ag.IsPlaying and ag:IsPlaying() then
                        ag:Stop()
                    end
                    out:SetOffset(0, dy)
                    back:SetOffset(0, -dy)
                    ag:Play()
                end
            end
        end
    end
end

function InterruptTracker:ApplyRowGapDelta(delta, source)
    if InCombatLockdown() then
        return false
    end

    local db = self:GetDB()
    local currentGap = self:GetRowGap()
    local nextGap = math.floor(clampNumber(currentGap + (tonumber(delta) or 0), currentGap, IT_ROW_GAP_MIN, IT_ROW_GAP_MAX))
    local previousBoundary = self._rowGapBoundaryReached and true or false

    if nextGap == currentGap then
        local atBoundary = currentGap <= IT_ROW_GAP_MIN
        self._rowGapBoundaryReached = atBoundary
        if atBoundary and not previousBoundary then
            self:PlayRowGapBoundaryPulse()
        end
        return false
    end

    db.rowGap = nextGap
    self._rowGapLastSource = source or "unknown"
    self:MarkDisplayStructureDirty("row-gap")
    self:EvaluateVisibility("row-gap")

    local effectiveGap = self:GetRowGap()
    local atBoundary = effectiveGap <= IT_ROW_GAP_MIN
    self._rowGapBoundaryReached = atBoundary
    if atBoundary and not previousBoundary then
        self:PlayRowGapBoundaryPulse()
    end
    return true
end

function InterruptTracker:BeginRowGapDrag()
    if InCombatLockdown() then
        return
    end

    local db = self:GetDB()
    if db.locked then
        return
    end

    local handle = self:CreateSpacingHandle(self.frame)
    if not handle then
        return
    end

    self:DismissSpacingUnlockHint(IT_SPACING_ARM.UNLOCK_HINT_FAST_FADE)
    self:EndRowGapDrag()

    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if not scale or scale <= 0 then
        scale = 1
    end
    local _, cy = GetCursorPosition()
    if not cy then
        return
    end

    self._rowGapDrag = {
        startCursorY = cy / scale,
        startGap = self:GetRowGap(),
    }

    handle._active = true
    handle._hover = true
    if handle._refreshVisual then
        handle._refreshVisual()
    end
    IT_SetSpacingArmCursor(IT_SPACING_ARM.CURSOR_Y)
    PA_HideTooltipIfOwnedBy(handle)

    handle:SetScript("OnUpdate", function()
        local drag = self._rowGapDrag
        if not drag then
            handle:SetScript("OnUpdate", nil)
            return
        end
        if InCombatLockdown() then
            self:EndRowGapDrag()
            return
        end

        local uiScale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
        if not uiScale or uiScale <= 0 then
            uiScale = 1
        end
        local _, py = GetCursorPosition()
        if not py then
            return
        end
        py = py / uiScale

        local pixelsPerStep = IT_SPACING_ARM.DRAG_PIXELS_PER_STEP
        if IsShiftKeyDown and IsShiftKeyDown() then
            pixelsPerStep = pixelsPerStep * IT_SPACING_ARM.SHIFT_DRAG_MULT
        end
        if IsAltKeyDown and IsAltKeyDown() then
            pixelsPerStep = pixelsPerStep * IT_SPACING_ARM.ALT_DRAG_MULT
        end
        if pixelsPerStep < 1 then
            pixelsPerStep = 1
        end

        local units = IT_RowGapDragUnits(py - drag.startCursorY, pixelsPerStep)
        local targetGap = math.floor(clampNumber(drag.startGap + units, drag.startGap, IT_ROW_GAP_MIN, IT_ROW_GAP_MAX))
        local currentGap = self:GetRowGap()
        if targetGap ~= currentGap then
            self:ApplyRowGapDelta(targetGap - currentGap, "drag-y")
        end
    end)
end

function InterruptTracker:EndRowGapDrag()
    local handle = self.spacingHandle
    if handle then
        handle:SetScript("OnUpdate", nil)
        handle._active = nil
        if not handle:IsMouseOver() then
            handle._hover = nil
        end
        if handle._refreshVisual then
            handle._refreshVisual()
        end
        PA_HideTooltipIfOwnedBy(handle)
    end

    self._rowGapDrag = nil
    IT_SetSpacingArmCursor(nil)
end

function InterruptTracker:SetSpacingHandleEnabled(enable)
    local handle = self:CreateSpacingHandle(self.frame)
    if not handle then
        return
    end

    local shouldEnable = enable and true or false
    if shouldEnable and self.frame and self.frame.IsShown and not self.frame:IsShown() then
        shouldEnable = false
    end

    if shouldEnable then
        handle:Show()
        handle:EnableMouse(true)
        handle:EnableMouseWheel(true)
        if handle._refreshVisual then
            handle._refreshVisual()
        end
        if not self._spacingHintShownForUnlock then
            self._spacingHintShownForUnlock = true
            self:ShowSpacingUnlockHint()
        end
    else
        self:EndRowGapDrag()
        handle:EnableMouse(false)
        handle:EnableMouseWheel(false)
        handle:Hide()
        if handle.unlockHint then
            handle.unlockHint:Hide()
        end
        self._spacingUnlockHintVisible = false
        self._rowGapBoundaryReached = false
        if self:GetDB().locked then
            self._spacingHintShownForUnlock = false
        end
    end
end

function InterruptTracker:SetUnlocked(unlocked)
    local wasUnlocked = self.unlocked and true or false
    self.unlocked = not not unlocked
    if wasUnlocked ~= self.unlocked then
        self:MarkDisplayStructureDirty("unlock")
    end
    local db = self:GetDB()
    db.locked = not self.unlocked
    local effectiveUnlocked = self.unlocked and self:IsEnabled()
    local wasEffectiveUnlocked = wasUnlocked and self:IsEnabled()
    if self.dragHandle then
        self.dragHandle:SetShown(effectiveUnlocked)
        self.dragHandle:EnableMouse(effectiveUnlocked)
    end
    if self.topDragHandle then
        self.topDragHandle:SetShown(effectiveUnlocked)
        self.topDragHandle:EnableMouse(effectiveUnlocked)
    end
    if self.spacingHandle then
        self:SetSpacingHandleEnabled(effectiveUnlocked and self.frame and self.frame:IsShown())
    end
    if self.unlockLabel then
        self.unlockLabel:SetShown(effectiveUnlocked)
        if self.unlockLabel._blink then
            if effectiveUnlocked then
                self.unlockLabel._blink:Play()
            else
                self.unlockLabel._blink:Stop()
            end
        end
    end
    if effectiveUnlocked then
        if not wasUnlocked then
            self.previewStartedAt = GetTime()
            self.previewCycleOffsetByKey = {}
        end
    elseif wasEffectiveUnlocked then
        self:DismissSpacingUnlockHint(0)
        self:EndRowGapDrag()
        self:ResetPreviewState()
    end
end

function InterruptTracker:CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local bgOpacity = IT_GetConfiguredRowBackgroundOpacity(self:GetDB())
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    row:SetBackdropColor(IT_BG_BAR[1], IT_BG_BAR[2], IT_BG_BAR[3], bgOpacity)
    row:SetBackdropBorderColor(IT_ROW_BORDER[1], IT_ROW_BORDER[2], IT_ROW_BORDER[3], IT_ROW_BORDER[4])

    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetAllPoints(row)
    row.bar:SetFrameLevel(row:GetFrameLevel() + 1)
    row.bar:SetMinMaxValues(0, 1)
    row.bar:SetValue(1)
    row.bar:SetStatusBarTexture(self:GetBarTexture())
    if row.bar.SetReverseFill then
        row.bar:SetReverseFill(false)
    end
    row.barBg = row.bar:CreateTexture(nil, "BACKGROUND")
    row.barBg:SetAllPoints(row.bar)
    row.barBg:SetTexture(self:GetBarTexture())
    row.barBg:SetVertexColor(0.11, 0.12, 0.15, bgOpacity)
    row.barAccent = row.bar:CreateTexture(nil, "ARTWORK", nil, 1)
    row.barAccent:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.barAccent:SetBlendMode("ADD")
    if row.barAccent.SetGradientAlpha then
        row.barAccent:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.00, 1, 1, 1, IT_BAR_ACCENT_ALPHA)
    else
        row.barAccent:SetVertexColor(1, 1, 1, IT_BAR_ACCENT_ALPHA)
    end
    row.barAccent:Hide()
    row.barAccent.anim = row.barAccent:CreateAnimationGroup()
    local accentFade = row.barAccent.anim:CreateAnimation("Alpha")
    accentFade:SetOrder(1)
    accentFade:SetDuration(0.30)
    accentFade:SetFromAlpha(IT_BAR_ACCENT_PULSE_ALPHA)
    accentFade:SetToAlpha(0.0)
    row.barAccent.anim:SetScript("OnFinished", function(anim)
        local target = anim:GetParent()
        if target then
            target:Hide()
            target:SetAlpha(0)
        end
    end)

    row.content = CreateFrame("Frame", nil, row)
    row.content:SetAllPoints(row)
    row.content:SetFrameLevel(row.bar:GetFrameLevel() + 1)

    row.classIcon = row.content:CreateTexture(nil, "ARTWORK")
    row.spellIcon = row.content:CreateTexture(nil, "ARTWORK")
    row.iconSeparator = row.content:CreateTexture(nil, "ARTWORK")
    row.iconSeparator:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.iconSeparator:Hide()
    row.spellIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.spellIconGlow = row.content:CreateTexture(nil, "OVERLAY")
    row.spellIconGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    row.spellIconGlow:SetBlendMode("ADD")
    row.spellIconGlow:SetVertexColor(1, 1, 1, 0)
    row.spellIconGlow:Hide()
    row.spellIconGlow.anim = row.spellIconGlow:CreateAnimationGroup()
    local glow = row.spellIconGlow.anim:CreateAnimation("Alpha")
    glow:SetOrder(1)
    glow:SetDuration(IT_ICON_GLOW_DURATION)
    glow:SetFromAlpha(IT_ICON_GLOW_ALPHA)
    glow:SetToAlpha(0.0)

    row.nameText = row.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)
    row.cooldownText = row.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.cooldownText:SetJustifyH("RIGHT")
    row.badgeText = row.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.badgeText:SetJustifyH("RIGHT")
    row.countText = row.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.countText:SetJustifyH("RIGHT")

    row.extraIcons = {}
    for slot = 1, 3 do
        local texture = row.content:CreateTexture(nil, "ARTWORK")
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        texture:Hide()
        row.extraIcons[slot] = texture
    end
    row.extraMoreText = row.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.extraMoreText:SetJustifyH("RIGHT")
    row.extraMoreText:Hide()

    row.index = index
    row:Hide()
    return row
end

function InterruptTracker:BuildFrame()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(220, 100)
    frame:SetMovable(true)
    frame:SetUserPlaced(false)
    frame:SetClampedToScreen(false)
    frame:EnableMouse(false)
    frame:SetFrameStrata("MEDIUM")

    local function createHandle(anchorPoint, relativePoint, yOffset)
        local handle = CreateFrame("Button", nil, frame, "BackdropTemplate")
        handle:SetPoint(anchorPoint, frame, relativePoint, 0, yOffset)
        handle:SetWidth(140)
        handle:SetHeight(16)
        handle:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        handle:SetBackdropColor(0.0, 1.0, 0.0, 0.85)
        handle:SetBackdropBorderColor(0.0, 0.25, 0.0, 1.0)
        local glyph = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        glyph:SetPoint("CENTER", handle, "CENTER", 0, 0)
        glyph:SetText(GetInterruptRuntimeStrings().grab)
        glyph:SetTextColor(0, 0, 0, 1)
        handle:EnableMouse(false)
        handle:RegisterForDrag("LeftButton")
        handle:SetScript("OnDragStart", function()
            if not self.unlocked or InCombatLockdown() then
                return
            end
            frame:StartMoving()
            if not self._dragTicker then
                self._dragTicker = C_Timer.NewTicker(0.1, function()
                    self:NotifyDragPosition()
                end)
            end
        end)
        handle:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            if self._dragTicker then
                self._dragTicker:Cancel()
                self._dragTicker = nil
            end
            self:PersistPosition()
        end)
        return handle
    end

    self.topDragHandle = createHandle("BOTTOM", "TOP", 3)
    self.dragHandle = createHandle("TOP", "BOTTOM", -3)

    self.unlockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.unlockLabel:SetPoint("BOTTOM", frame, "TOP", 0, 22)
    self.unlockLabel:SetText(GetInterruptRuntimeStrings().title)
    self.unlockLabel:SetTextColor(1.0, 0.20, 0.20, 1.0)
    self.unlockLabel._blink = self.unlockLabel:CreateAnimationGroup()
    local fadeOut = self.unlockLabel._blink:CreateAnimation("Alpha")
    fadeOut:SetOrder(1)
    fadeOut:SetDuration(0.55)
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.30)
    local fadeIn = self.unlockLabel._blink:CreateAnimation("Alpha")
    fadeIn:SetOrder(2)
    fadeIn:SetDuration(0.55)
    fadeIn:SetFromAlpha(0.30)
    fadeIn:SetToAlpha(1.0)
    self.unlockLabel._blink:SetLooping("REPEAT")

    self.frame = frame
    self:CreateSpacingHandle(frame)
    self.selfRowHost = CreateFrame("Frame", nil, frame)
    self.selfRowHost:Hide()
    self.selfRow = self:CreateRow(self.selfRowHost, 0)
    self.selfRow:SetAllPoints(self.selfRowHost)
    self.rows = {}
    for index = 1, 5 do
        self.rows[index] = self:CreateRow(frame, index)
    end
end

function InterruptTracker:ApplyFonts()
    if not self.frame then
        return
    end
    local db = self:GetDB()
    local fontPath, fontSize, fontFlags = self:GetFont()
    local color = db.fontColor or { r = 1, g = 1, b = 1, a = 1 }
    local allRows = {}
    if self.selfRow then
        allRows[#allRows + 1] = self.selfRow
    end
    for _, row in ipairs(self.rows or {}) do
        allRows[#allRows + 1] = row
    end
    for _, row in ipairs(allRows) do
        row.nameText:SetFont(fontPath, fontSize, "OUTLINE")
        row.nameText:SetTextColor(color.r, color.g, color.b, color.a)
        row.nameText:SetShadowOffset(1, -1)
        row.nameText:SetShadowColor(0, 0, 0, 1)
        row.cooldownText:SetFont(fontPath, fontSize, fontFlags)
        row.cooldownText:SetTextColor(color.r, color.g, color.b, color.a)
        row.cooldownText:SetShadowOffset(1, -1)
        row.cooldownText:SetShadowColor(0, 0, 0, 1)
        row.badgeText:SetFont(fontPath, math.max(9, fontSize - 2), fontFlags)
        row.badgeText:SetTextColor(IT_MUTED_TEXT[1], IT_MUTED_TEXT[2], IT_MUTED_TEXT[3], IT_MUTED_TEXT[4])
        row.countText:SetFont(fontPath, fontSize, fontFlags)
        row.countText:SetTextColor(color.r, color.g, color.b, color.a)
        row.extraMoreText:SetFont(fontPath, math.max(8, fontSize - 3), fontFlags)
    end
end

function InterruptTracker:ApplyRowLayout(row, modeB)
    local db = self:GetDB()
    local width = db.width
    local rowHeight = db.rowHeight
    local iconSize = math.max(12, rowHeight - 4)
    local laneX = 0
    local barInset = 6

    row:SetSize(width, rowHeight)
    row.bar:ClearAllPoints()
    row.content:ClearAllPoints()
    row.classIcon:ClearAllPoints()
    row.spellIcon:ClearAllPoints()
    row.iconSeparator:ClearAllPoints()
    row.nameText:ClearAllPoints()
    row.cooldownText:ClearAllPoints()
    row.badgeText:ClearAllPoints()
    row.countText:ClearAllPoints()
    row.extraMoreText:ClearAllPoints()
    for _, extra in ipairs(row.extraIcons) do
        extra:ClearAllPoints()
    end

    local showClassIcon = db.showClassIcon
    local showSpellIcon = db.showSpellIcon
    local classIconGap = showSpellIcon and 0 or 6
    local spellIconGap = 6
    local separatorStartX, separatorWidth = nil, 0
    if showClassIcon then
        row.classIcon:SetPoint("LEFT", row, "LEFT", laneX, 0)
        row.classIcon:SetSize(iconSize, iconSize)
        laneX = laneX + iconSize + classIconGap
        if classIconGap > 0 then
            separatorStartX = laneX - classIconGap
            separatorWidth = classIconGap
        end
    end
    if showSpellIcon then
        row.spellIcon:SetPoint("LEFT", row, "LEFT", laneX, 0)
        row.spellIcon:SetSize(iconSize, iconSize)
        laneX = laneX + iconSize + spellIconGap
        if spellIconGap > 0 then
            separatorStartX = laneX - spellIconGap
            separatorWidth = spellIconGap
        end
    end
    local separatorThickness = math.min(IT_ICON_SEPARATOR_THICKNESS, separatorWidth or 0)
    row._iconSeparatorWidth = separatorThickness or 0
    if separatorStartX and separatorWidth > 0 then
        local separatorX = separatorStartX + math.floor(((separatorWidth - separatorThickness) * 0.5) + 0.5)
        row.iconSeparator:SetPoint("TOPLEFT", row, "TOPLEFT", separatorX, -IT_ICON_SEPARATOR_VERTICAL_INSET)
        row.iconSeparator:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", separatorX, IT_ICON_SEPARATOR_VERTICAL_INSET)
        row.iconSeparator:SetWidth(separatorThickness)
    else
        row.iconSeparator:SetWidth(0)
    end
    row.bar:SetPoint("TOPLEFT", row, "TOPLEFT", laneX, 0)
    row.bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    row.content:SetAllPoints(row.bar)

    if modeB then
        if db.rightDisplay == "timer" then
            row.countText:SetPoint("LEFT", row.content, "RIGHT", -48, 0)
            row.countText:SetPoint("RIGHT", row.content, "RIGHT", -barInset, 0)
        else
            row.countText:SetPoint("RIGHT", row.content, "RIGHT", -barInset, 0)
        end
        row.nameText:SetPoint("LEFT", row.content, "LEFT", barInset, 0)
        row.nameText:SetPoint("RIGHT", row.countText, "LEFT", -8, 0)
    else
        local iconEdge = -barInset
        for slot = #row.extraIcons, 1, -1 do
            local extra = row.extraIcons[slot]
            extra:SetPoint("RIGHT", row.content, "RIGHT", iconEdge, 0)
            extra:SetSize(math.max(10, iconSize - 6), math.max(10, iconSize - 6))
            iconEdge = iconEdge - (math.max(10, iconSize - 6) + 2)
        end
        row.extraMoreText:SetPoint("RIGHT", row.content, "RIGHT", -barInset, 0)
        row.cooldownText:SetPoint("RIGHT", row.content, "RIGHT", iconEdge, 0)
        row.nameText:SetPoint("LEFT", row.content, "LEFT", barInset, 0)
        row.nameText:SetPoint("RIGHT", row.cooldownText, "LEFT", -8, 0)
    end
end

function InterruptTracker:GetPreviewRows()
    local now = GetTime()
    self:EnsurePreviewState(now)

    local rows = {}
    local seenNames = {}
    local hasSelfRow = false
    local roster = self:GetCurrentRoster(true)
    local syntheticPool = {
        { name = IT_NormalizeName(UnitName("player")) or "You", class = self.playerClass or IT_SafeUnitClass("player") or "MAGE", isSelf = true },
        { name = "Shifta", class = "SHAMAN" },
        { name = "Hunterx", class = "HUNTER" },
        { name = "Spellpet", class = "WARLOCK" },
        { name = "Shieldbro", class = "WARRIOR" },
    }

    local function addPreviewRow(name, classFile, isSelf)
        local normalized = IT_NormalizeName(name)
        if not normalized or seenNames[normalized] then
            return false
        end
        local primary = IT_GetClassDefaultInterrupt(classFile)
        rows[#rows + 1] = {
            name = normalized,
            class = classFile,
            spellID = primary and primary.spellID or nil,
            baseCd = tonumber(primary and primary.baseCd) or 15,
            icon = primary and primary.icon or 134400,
            isSelf = isSelf and true or false,
            isPreview = true,
            previewAvailability = "confirmed",
            extraKicks = {},
        }
        seenNames[normalized] = true
        if isSelf then
            hasSelfRow = true
        end
        return true
    end

    for _, entry in ipairs(roster) do
        if #rows >= 5 then
            break
        end
        local classFile = entry.unit and IT_SafeUnitClass(entry.unit) or nil
        if entry.isSelf and not classFile then
            classFile = self.playerClass or IT_SafeUnitClass("player")
        end
        addPreviewRow(entry.name, classFile, entry.isSelf)
    end

    if not hasSelfRow and #rows < 5 then
        local syntheticSelf = syntheticPool[1]
        addPreviewRow(syntheticSelf.name, syntheticSelf.class, true)
    end

    for _, sample in ipairs(syntheticPool) do
        if #rows >= 5 then
            break
        end
        addPreviewRow(sample.name, sample.class, sample.isSelf and not hasSelfRow)
    end

    local fillerIndex = 1
    while #rows < 5 do
        local sample = syntheticPool[((fillerIndex - 1) % #syntheticPool) + 1]
        addPreviewRow(string.format("%s%d", tostring(sample.name or "Preview"), fillerIndex), sample.class, sample.isSelf and not hasSelfRow)
        fillerIndex = fillerIndex + 1
    end

    table.sort(rows, function(a, b)
        local aCd = tonumber(a.baseCd) or 999
        local bCd = tonumber(b.baseCd) or 999
        if aCd ~= bCd then
            return aCd < bCd
        end
        return tostring(IT_NormalizeName(a.name) or a.name or "") < tostring(IT_NormalizeName(b.name) or b.name or "")
    end)

    self.previewCycleOffsetByKey = self.previewCycleOffsetByKey or {}
    for index, row in ipairs(rows) do
        local baseCd = math.max(1, tonumber(row.baseCd) or 15)
        local previewKey = string.format("%s:%d", tostring(IT_NormalizeName(row.name) or row.name or ("preview" .. index)), index)
        local cycleLength = baseCd + IT_PREVIEW_READY_HOLD
        local offset = self.previewCycleOffsetByKey[previewKey]
        if offset == nil then
            offset = ((index - 1) * 0.85) + ((baseCd % 5) * 0.17)
            self.previewCycleOffsetByKey[previewKey] = offset
        end
        local phase = ((now - (tonumber(self.previewStartedAt) or now)) + offset) % cycleLength
        local previewReady = phase < IT_PREVIEW_READY_HOLD
        local previewRemaining = previewReady and 0 or math.max(0, baseCd - (phase - IT_PREVIEW_READY_HOLD))

        row.previewKey = previewKey
        row.previewReady = previewReady
        row.previewRemaining = previewRemaining
        row.previewModeBSortRemaining = IT_SnapPreviewModeBRemaining(previewRemaining)
        row.previewModeBSortIndex = index
        row.previewCountValue = index - 1
        row.cdEnd = previewReady and 0 or (now + previewRemaining)
    end

    return rows
end

function InterruptTracker:GetPreviewModeBRows()
    local now = GetTime()
    self:EnsurePreviewState(now)

    local pool = {}
    for _, entry in ipairs(IT_PREVIEW_MODEB_POOL) do
        local primary = IT_GetPreviewModeBPrimary(entry)
        if primary then
            pool[#pool + 1] = {
                name = entry.name,
                class = entry.class,
                specID = entry.specID,
                specName = entry.specName,
                spellID = primary.spellID,
                baseCd = tonumber(primary.baseCd) or 15,
                icon = primary.icon or IT_GetPrimaryIcon(primary.spellID),
                isSelf = false,
                isPreview = true,
                previewAvailability = "confirmed",
                previewUseClassIcon = entry.previewUseClassIcon and true or false,
                isPetSpell = primary.isPetSpell and true or false,
                petSpellID = primary.petSpellID,
                extraKicks = {},
            }
        end
    end

    if #pool == 0 then
        return {}
    end

    local windowGroups = {}
    local startIndex = 1
    while startIndex <= #pool do
        local group = { rows = {}, duration = 0, phaseSpacing = 3.0 }
        local maxBaseCd = 1
        for offset = 0, IT_PREVIEW_MODEB_WINDOW_SIZE - 1 do
            local index = ((startIndex + offset - 1) % #pool) + 1
            local row = pool[index]
            group.rows[#group.rows + 1] = row
            maxBaseCd = math.max(maxBaseCd, tonumber(row.baseCd) or 15)
        end
        group.phaseSpacing = math.max(
            IT_PREVIEW_MODEB_PHASE_SPACING_MIN,
            math.min(
                IT_PREVIEW_MODEB_PHASE_SPACING_MAX,
                (maxBaseCd + IT_PREVIEW_MODEB_READY_HOLD) / (IT_PREVIEW_MODEB_WINDOW_SIZE + 1)
            )
        )
        group.duration = math.max(1, (maxBaseCd + IT_PREVIEW_MODEB_READY_HOLD) * IT_PREVIEW_MODEB_ROTATION_CYCLES)
        windowGroups[#windowGroups + 1] = group
        startIndex = startIndex + IT_PREVIEW_MODEB_WINDOW_SIZE
    end

    local totalDuration = 0
    for _, group in ipairs(windowGroups) do
        totalDuration = totalDuration + (tonumber(group.duration) or 0)
    end
    local elapsed = math.max(0, now - (tonumber(self.previewStartedAt) or now))
    local windowElapsed = (totalDuration > 0) and (elapsed % totalDuration) or 0
    local activeGroup = windowGroups[1]
    local activeGroupIndex = 1
    for groupIndex, group in ipairs(windowGroups) do
        local duration = tonumber(group.duration) or 0
        if windowElapsed < duration then
            activeGroup = group
            activeGroupIndex = groupIndex
            break
        end
        windowElapsed = windowElapsed - duration
    end

    local previewWindowRound = (totalDuration > 0) and math.floor(elapsed / totalDuration) or 0
    local previewWindowKey = string.format("%d:%d", activeGroupIndex, previewWindowRound)
    self.previewCycleOffsetByKey = self.previewCycleOffsetByKey or {}
    local rows = {}
    for index, row in ipairs(activeGroup.rows or {}) do
        local previewKey = string.format("preview_modeb:%s:%d", tostring(IT_NormalizeName(row.name) or row.name or ("preview" .. index)), index)
        local baseCd = math.max(1, tonumber(row.baseCd) or 15)
        local cycleLength = math.max(1, baseCd + IT_PREVIEW_MODEB_READY_HOLD)
        local offset = self.previewCycleOffsetByKey[previewKey]
        if offset == nil then
            offset = ((index - 1) * (tonumber(activeGroup.phaseSpacing) or 3.0)) + ((baseCd % 5) * 0.11)
            self.previewCycleOffsetByKey[previewKey] = offset
        end
        local phase = (windowElapsed + offset) % cycleLength
        local previewReady = phase < IT_PREVIEW_MODEB_READY_HOLD
        local previewRemaining = previewReady and 0 or math.max(0, baseCd - (phase - IT_PREVIEW_MODEB_READY_HOLD))

        row.previewKey = previewKey
        row.previewReady = previewReady
        row.previewRemaining = previewRemaining
        row.previewModeBSortRemaining = IT_SnapPreviewModeBRemaining(previewRemaining)
        row.previewModeBSortIndex = index
        row.previewWindowKey = previewWindowKey
        row.previewCountValue = index - 1
        row.cdEnd = previewReady and 0 or (now + previewRemaining)
        rows[#rows + 1] = row
    end

    IT_ApplyPreviewModeBCooldownGap(rows, now)

    return rows
end

function InterruptTracker:ApplyPreviewModeBSwapHysteresis(sortedRows, now)
    return sortedRows
end

function InterruptTracker:BuildModeARows()
    local rows = self:IsPreviewMode() and self:GetPreviewRows() or self:GetCurrentPrimaryOrder()
    local now = GetTime()
    local confirmed = {}
    local stale = {}
    local dead = {}
    local unavailable = {}
    for _, member in ipairs(rows) do
        local availability = self:GetMemberAvailability(member, now)
        if member.isSelf then
            confirmed[#confirmed + 1] = member
        elseif availability.visible then
            if availability.bucket == "confirmed" then
                confirmed[#confirmed + 1] = member
            elseif availability.bucket == "stale" then
                stale[#stale + 1] = member
            elseif availability.bucket == "dead" then
                dead[#dead + 1] = member
            else
                unavailable[#unavailable + 1] = member
            end
        end
    end
    for _, member in ipairs(stale) do
        confirmed[#confirmed + 1] = member
    end
    for _, member in ipairs(dead) do
        confirmed[#confirmed + 1] = member
    end
    for _, member in ipairs(unavailable) do
        confirmed[#confirmed + 1] = member
    end
    return confirmed
end

function InterruptTracker:BuildModeBMemberTickState(member, previewMode, now)
    local isPreview = member and member.isPreview
    local availability = isPreview and {
        bucket = member.previewAvailability or "confirmed",
        visible = true,
        connected = true,
        isDead = false,
    } or self:GetMemberAvailability(member, now)
    local confirmed = availability.bucket == "confirmed"
    local trackable = confirmed or availability.bucket == "stale" or availability.bucket == "dead"
    local remaining = isPreview and math.max(0, tonumber(member.previewRemaining) or 0) or self:GetMemberRemaining(member, now)
    local ready = isPreview and (member.previewReady and true or false) or self:IsMemberReady(member, now)
    local displayGroup = availability.bucket == "confirmed" and (ready and 1 or 2)
        or (availability.bucket == "stale" and 3)
        or (availability.bucket == "dead" and 4)
        or 5

    return {
        availability = availability,
        available = confirmed,
        confirmed = confirmed,
        trackable = trackable,
        visible = availability.visible and true or false,
        ready = ready,
        remaining = remaining,
        displayGroup = displayGroup,
        sortRemaining = previewMode
            and (tonumber(member.previewModeBSortRemaining) or IT_SnapPreviewModeBRemaining(member.previewRemaining))
            or IT_SnapRemaining(remaining),
    }
end

function InterruptTracker:BuildModeBRows(perfState, now)
    local rows = {}
    local previewMode = self:IsPreviewMode()
    local collectStart, collectState = PA_PerfBegin("interrupt_ud_collect", perfState)
    if previewMode then
        rows = self:GetPreviewModeBRows()
    else
        local db = self:GetDB()
        for _, name in ipairs(db.rotationOrder or {}) do
            local member = self:FindMemberByName(name)
            if self:MemberQualifiesForSeed(member) then
                rows[#rows + 1] = member
            end
        end
    end

    now = now or GetTime()
    local visibleRows = {}
    local tickMemberState = {}
    for _, member in ipairs(rows) do
        local tickState = self:BuildModeBMemberTickState(member, previewMode, now)
        tickMemberState[member] = tickState
        if tickState.visible then
            if previewMode then
                member.previewModeBDisplayGroup = tickState.displayGroup
            end
            visibleRows[#visibleRows + 1] = member
        end
    end
    self._displayTickMemberState = tickMemberState
    PA_PerfEnd("interrupt_ud_collect", collectStart, collectState)

    -- Mode B display order is rebuilt only on structural refreshes.
    local sortStart, sortState = PA_PerfBegin("interrupt_ud_sort", perfState)
    table.sort(visibleRows, function(a, b)
        local aState = tickMemberState[a]
        local bState = tickMemberState[b]
        local aGroup = aState and aState.displayGroup or 5
        local bGroup = bState and bState.displayGroup or 5
        if aGroup ~= bGroup then
            return aGroup < bGroup
        end

        if aGroup == 2 then
            local aRemaining = aState and aState.sortRemaining or 0
            local bRemaining = bState and bState.sortRemaining or 0
            if aRemaining ~= bRemaining and ((not previewMode) or math.abs(aRemaining - bRemaining) > IT_PREVIEW_MODEB_REORDER_THRESHOLD) then
                return aRemaining < bRemaining
            end
            if previewMode then
                local aIndex = tonumber(a.previewModeBSortIndex) or 999
                local bIndex = tonumber(b.previewModeBSortIndex) or 999
                if aIndex ~= bIndex then
                    return aIndex < bIndex
                end
            end
        end

        local aCd = tonumber(a.baseCd) or 999
        local bCd = tonumber(b.baseCd) or 999
        if aCd ~= bCd then
            return aCd < bCd
        end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    if previewMode then
        visibleRows = self:ApplyPreviewModeBSwapHysteresis(visibleRows, now)
    end
    PA_PerfEnd("interrupt_ud_sort", sortStart, sortState)
    return visibleRows
end

function InterruptTracker:UpdateRowDynamicVisual(row, member, modeB, now, tickState)
    if not row or not member then
        return
    end

    local db = self:GetDB()
    local isPreview = member and member.isPreview
    local availability = tickState and tickState.availability
    if not availability then
        if isPreview then
            local previewAvailability = row._previewAvailabilityState or {}
            previewAvailability.bucket = member.previewAvailability or "confirmed"
            previewAvailability.visible = true
            previewAvailability.connected = true
            previewAvailability.isDead = false
            row._previewAvailabilityState = previewAvailability
            availability = previewAvailability
        else
            local liveAvailability = row._liveAvailabilityState or {}
            availability = self:FillMemberAvailabilityState(member, now, liveAvailability)
            row._liveAvailabilityState = availability
        end
    end
    local bucket = availability and availability.bucket or "offline"
    local confirmed = tickState and tickState.confirmed
    if confirmed == nil then
        confirmed = bucket == "confirmed"
    end
    local trackable = tickState and tickState.trackable
    if trackable == nil then
        trackable = confirmed or bucket == "stale" or bucket == "dead"
    end
    local remaining = tickState and tickState.remaining
    if remaining == nil then
        remaining = isPreview and math.max(0, tonumber(member.previewRemaining) or 0) or self:GetMemberRemaining(member, now)
    end
    local ready = tickState and tickState.ready
    if ready == nil then
        ready = isPreview and (member.previewReady and true or false) or self:IsMemberReady(member, now)
    end
    local fillR, fillG, fillB = self:GetDisplayColor(member)
    local primaryCd = tonumber(member.baseCd) or 15
    local fontColor = db.fontColor or { r = 1, g = 1, b = 1, a = 1 }
    local bgOpacity = IT_GetConfiguredRowBackgroundOpacity(db)
    local rightDisplay = db.rightDisplay == "timer" and "timer" or "count"
    local renderState = row._dynamicRenderState
    if type(renderState) ~= "table" then
        renderState = {}
        row._dynamicRenderState = renderState
    end
    local textColorR, textColorG, textColorB, textColorA = fontColor.r, fontColor.g, fontColor.b, fontColor.a
    local iconAlpha = 1.0
    local iconDesaturated = (modeB and not ready) and true or false
    local displayGroup = confirmed and (ready and 1 or 2)
        or (bucket == "stale" and 3)
        or (bucket == "dead" and 4)
        or 5
    local sortRemaining = displayGroup == 2 and (isPreview
        and (tonumber(member.previewModeBSortRemaining) or IT_SnapPreviewModeBRemaining(member.previewRemaining))
        or IT_SnapRemaining(remaining)) or 0

    if not trackable then
        IT_DYNAMIC_RENDER.SetStatusBarColorIfChanged(row.bar, renderState, "barColor", IT_UNAVAILABLE_BAR[1], IT_UNAVAILABLE_BAR[2], IT_UNAVAILABLE_BAR[3], IT_UNAVAILABLE_BAR[4])
        IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(row.bar, renderState, "barRange", 0, 1, 1)
        IT_DYNAMIC_RENDER.SetVertexColorIfChanged(row.barBg, renderState, "barBgColor", IT_UNAVAILABLE_BG[1], IT_UNAVAILABLE_BG[2], IT_UNAVAILABLE_BG[3], bgOpacity)
        textColorR, textColorG, textColorB, textColorA = IT_UNAVAILABLE_TEXT[1], IT_UNAVAILABLE_TEXT[2], IT_UNAVAILABLE_TEXT[3], IT_UNAVAILABLE_TEXT[4]
        iconAlpha = IT_AVAILABILITY_VISUALS.unavailableIconAlpha
        iconDesaturated = true
    elseif bucket == "dead" then
        IT_DYNAMIC_RENDER.SetStatusBarColorIfChanged(row.bar, renderState, "barColor", IT_AVAILABILITY_VISUALS.deadBar[1], IT_AVAILABILITY_VISUALS.deadBar[2], IT_AVAILABILITY_VISUALS.deadBar[3], IT_AVAILABILITY_VISUALS.deadBar[4])
        if ready or primaryCd <= 0 then
            IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(row.bar, renderState, "barRange", 0, 1, 1)
        else
            IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(row.bar, renderState, "barRange", 0, primaryCd, remaining)
        end
        IT_DYNAMIC_RENDER.SetVertexColorIfChanged(row.barBg, renderState, "barBgColor", IT_AVAILABILITY_VISUALS.deadBg[1], IT_AVAILABILITY_VISUALS.deadBg[2], IT_AVAILABILITY_VISUALS.deadBg[3], bgOpacity)
        textColorR, textColorG, textColorB, textColorA = IT_AVAILABILITY_VISUALS.deadText[1], IT_AVAILABILITY_VISUALS.deadText[2], IT_AVAILABILITY_VISUALS.deadText[3], IT_AVAILABILITY_VISUALS.deadText[4]
        iconAlpha = IT_AVAILABILITY_VISUALS.deadIconAlpha
        iconDesaturated = true
    elseif bucket == "stale" then
        local staleBlend = math.max(0, math.min(1, tonumber(IT_AVAILABILITY_VISUALS.staleBarBlend) or 0))
        local staleKeep = 1 - staleBlend
        local staleR = (fillR * staleKeep) + (IT_UNAVAILABLE_BAR[1] * staleBlend)
        local staleG = (fillG * staleKeep) + (IT_UNAVAILABLE_BAR[2] * staleBlend)
        local staleB = (fillB * staleKeep) + (IT_UNAVAILABLE_BAR[3] * staleBlend)
        IT_DYNAMIC_RENDER.SetStatusBarColorIfChanged(row.bar, renderState, "barColor", staleR, staleG, staleB, modeB and 0.84 or 0.70)
        if ready or primaryCd <= 0 then
            IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(row.bar, renderState, "barRange", 0, 1, 1)
        else
            IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(row.bar, renderState, "barRange", 0, primaryCd, remaining)
        end
        IT_DYNAMIC_RENDER.SetVertexColorIfChanged(row.barBg, renderState, "barBgColor", IT_AVAILABILITY_VISUALS.staleBg[1], IT_AVAILABILITY_VISUALS.staleBg[2], IT_AVAILABILITY_VISUALS.staleBg[3], bgOpacity)
        textColorR, textColorG, textColorB, textColorA = IT_AVAILABILITY_VISUALS.staleText[1], IT_AVAILABILITY_VISUALS.staleText[2], IT_AVAILABILITY_VISUALS.staleText[3], IT_AVAILABILITY_VISUALS.staleText[4]
        iconAlpha = IT_AVAILABILITY_VISUALS.staleIconAlpha
    else
        IT_DYNAMIC_RENDER.SetStatusBarColorIfChanged(row.bar, renderState, "barColor", fillR, fillG, fillB, modeB and 0.92 or 0.76)
        if ready or primaryCd <= 0 then
            IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(row.bar, renderState, "barRange", 0, 1, 1)
        else
            IT_DYNAMIC_RENDER.SetStatusBarRangeAndValueIfChanged(row.bar, renderState, "barRange", 0, primaryCd, remaining)
        end
        IT_DYNAMIC_RENDER.SetVertexColorIfChanged(row.barBg, renderState, "barBgColor", IT_BG_BAR[1], IT_BG_BAR[2], IT_BG_BAR[3], bgOpacity)
    end

    if row.barAccent then
        if row.barAccent.anim and row.barAccent.anim:IsPlaying() then
            row.barAccent.anim:Stop()
        end
        local accentShown = confirmed and not ready and primaryCd > 0
        IT_DYNAMIC_RENDER.SetShownIfChanged(row.barAccent, renderState, "barAccentShown", accentShown)
        IT_DYNAMIC_RENDER.SetAlphaIfChanged(row.barAccent, renderState, "barAccentAlpha", accentShown and IT_BAR_ACCENT_ALPHA or 0)
    end

    IT_DYNAMIC_RENDER.SetTextColorIfChanged(row.nameText, renderState, "nameColor",
        textColorR,
        textColorG,
        textColorB,
        textColorA
    )
    local separatorR, separatorG, separatorB, separatorA = self:GetSeparatorColor(member)
    IT_DYNAMIC_RENDER.SetVertexColorIfChanged(row.iconSeparator, renderState, "separatorColor", separatorR, separatorG, separatorB, separatorA)
    if modeB then
        if rightDisplay == "timer" then
            if not trackable then
                renderState.countTextNumber = nil
                IT_DYNAMIC_RENDER.SetTextIfChanged(row.countText, renderState, "countText", "-")
                IT_DYNAMIC_RENDER.SetTextColorIfChanged(row.countText, renderState, "countColor", IT_UNAVAILABLE_TEXT[1], IT_UNAVAILABLE_TEXT[2], IT_UNAVAILABLE_TEXT[3], IT_UNAVAILABLE_TEXT[4])
            elseif ready or remaining <= IT_READY_THRESHOLD then
                renderState.countTextNumber = nil
                IT_DYNAMIC_RENDER.SetTextIfChanged(row.countText, renderState, "countText", "")
                IT_DYNAMIC_RENDER.SetTextColorIfChanged(row.countText, renderState, "countColor", textColorR, textColorG, textColorB, textColorA)
            else
                IT_DYNAMIC_RENDER.SetWholeNumberTextIfChanged(row.countText, renderState, "countText", remaining)
                IT_DYNAMIC_RENDER.SetTextColorIfChanged(row.countText, renderState, "countColor", textColorR, textColorG, textColorB, textColorA)
            end
        else
            renderState.countTextNumber = nil
            IT_DYNAMIC_RENDER.SetTextIfChanged(row.countText, renderState, "countText", tostring(isPreview and (member.previewCountValue or 0) or self:GetCount(member.name)))
            IT_DYNAMIC_RENDER.SetTextColorIfChanged(row.countText, renderState, "countColor", textColorR, textColorG, textColorB, textColorA)
        end
    else
        renderState.countTextNumber = nil
        IT_DYNAMIC_RENDER.SetTextIfChanged(row.countText, renderState, "countText", "")
    end
    if confirmed and ready then
        local runtimeStrings = GetInterruptRuntimeStrings()
        renderState.cooldownTextNumber = nil
        IT_DYNAMIC_RENDER.SetTextIfChanged(row.cooldownText, renderState, "cooldownText", runtimeStrings.ready)
        IT_DYNAMIC_RENDER.SetTextColorIfChanged(row.cooldownText, renderState, "cooldownColor", 0.30, 1.00, 0.30, 1.00)
    else
        IT_DYNAMIC_RENDER.SetWholeNumberTextIfChanged(row.cooldownText, renderState, "cooldownText", remaining)
        IT_DYNAMIC_RENDER.SetTextColorIfChanged(row.cooldownText, renderState, "cooldownColor", textColorR, textColorG, textColorB, textColorA)
    end

    IT_DYNAMIC_RENDER.SetDesaturatedIfChanged(row.spellIcon, renderState, "spellIconDesaturated", iconDesaturated)
    IT_DYNAMIC_RENDER.SetAlphaIfChanged(row.spellIcon, renderState, "spellIconAlpha", iconAlpha)
    IT_DYNAMIC_RENDER.SetAlphaIfChanged(row.classIcon, renderState, "classIconAlpha", iconAlpha)
    local useGlowTarget = IT_GetRowUseGlowTarget(row, member, db)
    IT_DYNAMIC_RENDER.PositionRowUseGlowIfChanged(row, renderState, useGlowTarget)

    self.rowReadyState = self.rowReadyState or {}
    local readyKey = isPreview and member.previewKey and ("preview:" .. member.previewKey) or IT_NormalizeName(member.name)
    local previous = self.rowReadyState[readyKey]
    if previous == nil then
        self.rowReadyState[readyKey] = ready
    else
        if confirmed and ready and not previous then
            if not isPreview then
                self:PlayAlertSoundFor(member.name)
            end
        elseif confirmed and previous and not ready then
            if useGlowTarget and row.spellIconGlow and row.spellIconGlow.anim then
                IT_PositionRowUseGlow(row, useGlowTarget)
                if row.spellIconGlow.anim:IsPlaying() then
                    row.spellIconGlow.anim:Stop()
                end
                row.spellIconGlow:SetAlpha(0)
                row.spellIconGlow.anim:Play()
            end
        end
        self.rowReadyState[readyKey] = ready
    end

    local priorGroup = renderState.orderGroup
    local priorBucket = renderState.orderBucket
    local priorRemaining = renderState.orderRemaining
    renderState.orderGroup = displayGroup
    renderState.orderBucket = bucket
    renderState.orderRemaining = sortRemaining
    renderState.orderChanged = priorGroup ~= nil
        and (priorGroup ~= displayGroup or priorBucket ~= bucket or priorRemaining ~= sortRemaining)
end

function InterruptTracker:ApplyRowStaticVisual(row, member, modeB, now)
    local db = self:GetDB()
    row._dynamicRenderState = nil

    IT_ApplyClassIconTexture(row.classIcon, member.class)
    if modeB and member.previewUseClassIcon and member.class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[member.class] then
        IT_ApplyClassIconTexture(row.spellIcon, member.class)
    else
        row.spellIcon:SetTexture(member.icon or IT_GetPrimaryIcon(member.spellID))
        row.spellIcon:SetTexCoord(0, 1, 0, 1)
    end

    self:ApplyRowLayout(row, modeB)

    row.countText:SetShown(modeB)
    row.cooldownText:SetShown(not modeB)
    row.classIcon:SetShown(db.showClassIcon and member.class ~= nil)
    row.spellIcon:SetShown(db.showSpellIcon and member.spellID ~= nil)
    row.iconSeparator:SetShown((db.showClassIcon or db.showSpellIcon) and (tonumber(row._iconSeparatorWidth) or 0) > 0)
    row.badgeText:SetShown(false)
    row.badgeText:SetText("")
    row.nameText:SetText(member.name or "")

    row.bar:SetStatusBarTexture(self:GetBarTexture())
    row.barBg:SetTexture(self:GetBarTexture())
    row:SetBackdropColor(IT_BG_BAR[1], IT_BG_BAR[2], IT_BG_BAR[3], IT_GetConfiguredRowBackgroundOpacity(db))
    if row.bar.SetReverseFill then
        row.bar:SetReverseFill(false)
    end
    if row.barAccent then
        local statusTexture = row.bar.GetStatusBarTexture and row.bar:GetStatusBarTexture() or nil
        if statusTexture then
            row.barAccent:ClearAllPoints()
            row.barAccent:SetPoint("TOPRIGHT", statusTexture, "TOPRIGHT", 0, 0)
            row.barAccent:SetPoint("BOTTOMRIGHT", statusTexture, "BOTTOMRIGHT", 0, 0)
            row.barAccent:SetWidth(IT_BAR_ACCENT_WIDTH)
        end
    end

    for _, extra in ipairs(row.extraIcons) do
        extra:Hide()
    end
    row.extraMoreText:Hide()
    if not modeB then
        local currentTime = now or GetTime()
        local shown = 0
        for _, extra in ipairs(member.extraKicks or {}) do
            if shown < #row.extraIcons then
                shown = shown + 1
                local slot = row.extraIcons[shown]
                slot:SetTexture(extra.icon or IT_GetPrimaryIcon(extra.spellID))
                slot:SetDesaturated(not IT_IsReady(extra.cdEnd or 0, currentTime))
                slot:Show()
            end
        end
        if #(member.extraKicks or {}) > #row.extraIcons then
            row.extraMoreText:SetText("+" .. tostring(#(member.extraKicks or {}) - #row.extraIcons))
            row.extraMoreText:Show()
        end
    end

    row._displayMember = member
    row._displayModeB = modeB and true or false
end

function InterruptTracker:UpdateDisplayStructure(db, rowsData, modeB, previewMode, now, perfState, structureSignature)
    local rowHeight = db.rowHeight
    local rowGap = self:GetRowGap()
    local rowStride = rowHeight + rowGap
    local visible = 0
    local poolIndex = 0
    local assignments = {}
    local pulseTargets = {}
    local tickMemberState = self._displayTickMemberState

    local hideStart, hideState = PA_PerfBegin("interrupt_ud_hide_sweep", perfState)
    if self.selfRowHost then
        self.selfRowHost:Hide()
        self.selfRowHost._paSpacingPulseY = nil
    end
    if self.selfRow then
        self.selfRow:Hide()
        self.selfRow._displayMember = nil
    end
    for _, row in ipairs(self.rows or {}) do
        row:Hide()
        row._displayMember = nil
        row._paSpacingPulseY = nil
    end
    PA_PerfEnd("interrupt_ud_hide_sweep", hideStart, hideState)

    local anchorStart, anchorState = PA_PerfBegin("interrupt_ud_anchor", perfState)
    for _, member in ipairs(rowsData or {}) do
        local row = nil
        local pulseTarget = nil
        local rowOffsetY = -((visible) * rowStride)
        if member and member.isSelf and self.selfRow then
            row = self.selfRow
            if self.selfRowHost then
                self.selfRowHost:ClearAllPoints()
                self.selfRowHost:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, rowOffsetY)
                self.selfRowHost:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, rowOffsetY)
                self.selfRowHost:SetSize(db.width, rowHeight)
                self.selfRowHost._paSpacingPulseY = rowOffsetY
                self.selfRowHost:Show()
                pulseTarget = self.selfRowHost
            else
                pulseTarget = row
            end
        else
            poolIndex = poolIndex + 1
            row = self.rows and self.rows[poolIndex] or nil
            if row then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, rowOffsetY)
                row:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, rowOffsetY)
                row._paSpacingPulseY = rowOffsetY
                pulseTarget = row
            end
        end
        if row and member then
            visible = visible + 1
            row:Show()
            assignments[#assignments + 1] = {
                row = row,
                member = member,
                modeB = modeB and true or false,
                tickState = tickMemberState and tickMemberState[member] or nil,
            }
            pulseTargets[#pulseTargets + 1] = pulseTarget
        end
    end
    PA_PerfEnd("interrupt_ud_anchor", anchorStart, anchorState)

    local staticStart, staticState = PA_PerfBegin("interrupt_ud_row_static", perfState)
    for _, assignment in ipairs(assignments) do
        self:ApplyRowStaticVisual(assignment.row, assignment.member, assignment.modeB, now)
    end
    PA_PerfEnd("interrupt_ud_row_static", staticStart, staticState)

    local frameStart, frameState = PA_PerfBegin("interrupt_ud_frame", perfState)
    self._displayAssignments = assignments
    self._displayRowCount = visible
    self._displayModeB = modeB and true or false
    self._displayPreviewMode = previewMode and true or false
    self._displayStructureSignature = structureSignature
    self._displayStructureDirty = false
    self._visibleRowPulseTargets = pulseTargets

    if visible <= 0 then
        self.frame:SetSize(db.width, 1)
        PA_CpuDiagApplyVisibility("interrupt", self.frame, self.unlocked)
    else
        self.frame:SetSize(db.width, math.max(1, (visible * rowHeight) + math.max(0, visible - 1) * rowGap))
        PA_CpuDiagApplyVisibility("interrupt", self.frame, true)
    end
    self:SetUnlocked(not self:GetDB().locked)
    PA_PerfEnd("interrupt_ud_frame", frameStart, frameState)
end

function InterruptTracker:UpdateDisplayDynamic(now, perfState)
    local dynamicStart, dynamicState = PA_PerfBegin("interrupt_ud_dynamic", perfState)
    local assignments = self._displayAssignments
    if type(assignments) == "table" then
        for _, assignment in ipairs(assignments) do
            if assignment and assignment.row and assignment.member and assignment.row._displayMember == assignment.member then
                self:UpdateRowDynamicVisual(assignment.row, assignment.member, assignment.modeB and true or false, now, nil)
            elseif assignment and assignment.row then
                self:MarkDisplayStructureDirty("dynamic-repair")
            end
        end
    end
    PA_PerfEnd("interrupt_ud_dynamic", dynamicStart, dynamicState)
    self:NoteDynamicDisplayPass()
end

function InterruptTracker:ModeBOrderComesBefore(leftAssignment, rightAssignment)
    if not leftAssignment or not rightAssignment then
        return false
    end

    local leftState = leftAssignment.row and leftAssignment.row._dynamicRenderState or nil
    local rightState = rightAssignment.row and rightAssignment.row._dynamicRenderState or nil
    local leftGroup = leftState and tonumber(leftState.orderGroup) or 5
    local rightGroup = rightState and tonumber(rightState.orderGroup) or 5
    if leftGroup ~= rightGroup then
        return leftGroup < rightGroup
    end

    if leftGroup == 2 then
        local leftRemaining = leftState and tonumber(leftState.orderRemaining) or 0
        local rightRemaining = rightState and tonumber(rightState.orderRemaining) or 0
        if leftRemaining ~= rightRemaining then
            return leftRemaining < rightRemaining
        end
    end

    local leftCd = tonumber(leftAssignment.member and leftAssignment.member.baseCd) or 999
    local rightCd = tonumber(rightAssignment.member and rightAssignment.member.baseCd) or 999
    if leftCd ~= rightCd then
        return leftCd < rightCd
    end

    return tostring(leftAssignment.member and leftAssignment.member.name or "") < tostring(rightAssignment.member and rightAssignment.member.name or "")
end

function InterruptTracker:DynamicOrderNeedsStructuralRefresh()
    if self:IsPreviewMode() then
        return false
    end

    local assignments = self._displayAssignments
    if type(assignments) ~= "table" or #assignments < 2 then
        return false
    end

    for index = 1, (#assignments - 1) do
        local currentAssignment = assignments[index]
        local nextAssignment = assignments[index + 1]
        if currentAssignment and nextAssignment and not self:ModeBOrderComesBefore(currentAssignment, nextAssignment) then
            return true
        end
    end
    return false
end

function InterruptTracker:ApplyRowVisual(row, member, modeB, now)
    self:ApplyRowStaticVisual(row, member, modeB, now)
    self:UpdateRowDynamicVisual(row, member, modeB, now, nil)
end

function InterruptTracker:UpdateDisplay()
    PA_CpuDiagCount("interrupt_update_display")
    local perfStart, perfState = PA_PerfBegin("interrupt_update_display")
    local function finish(...)
        PA_PerfEnd("interrupt_update_display", perfStart, perfState)
        return ...
    end

    if PA_IsUiSurfaceGateEnabled() then
        if self.frame then
            self:StopTicker()
            self:HardCancelInspectRefresh()
            self:ClearRuntimeDisplayLifecycleState()
            self:ReconcileWatcherState()
            self:SetSpacingHandleEnabled(false)
            PA_CpuDiagApplyVisibility("interrupt", self.frame, false)
        end
        return finish()
    end

    if not self.frame then
        return finish()
    end
    if not self:IsEnabled() then
        self:MarkDisplayStructureDirty("module-disabled")
        self:StopTicker()
        self:HardCancelInspectRefresh()
        self:ClearRuntimeDisplayLifecycleState()
        self:ReconcileWatcherState()
        self:SetSpacingHandleEnabled(false)
        PA_CpuDiagApplyVisibility("interrupt", self.frame, false)
        return finish()
    end
    local previewMode = self:IsPreviewMode()
    local shouldShow = self:IsSupportedLiveContext() or previewMode
    if not shouldShow then
        self:MarkDisplayStructureDirty("visibility-hidden")
        self:StopTicker()
        self:HardCancelInspectRefresh()
        self:ClearRuntimeDisplayLifecycleState()
        self:ReconcileWatcherState()
        self:SetSpacingHandleEnabled(false)
        PA_CpuDiagApplyVisibility("interrupt", self.frame, false)
        return finish()
    end

    local now = GetTime()
    local prepareStart, prepareState = PA_PerfBegin("interrupt_ud_prepare", perfState)
    self:ExpireOwnerInterruptPending(now)
    if previewMode then
        self:EnsurePreviewState(now)
    else
        self:RefreshAvailabilityGate()
        self:RefreshFullWipeRecoveryState(now)
    end
    PA_PerfEnd("interrupt_ud_prepare", prepareStart, prepareState)

    local db = self:GetDB()

    local function runStructuralPass(viaSafetyNet)
        local rowsData = self:BuildModeBRows(perfState, now)

        local signatureStart, signatureState = PA_PerfBegin("interrupt_ud_signature", perfState)
        local structureSignature = self:BuildDisplayStructureSignature(db, rowsData, true, previewMode)
        PA_PerfEnd("interrupt_ud_signature", signatureStart, signatureState)

        local structureDirty = self._displayIdentityDirty
            or self._displayStructureDirty
            or self._displayStructureSignature ~= structureSignature
            or type(self._displayAssignments) ~= "table"

        if not structureDirty and not self:RefreshDisplayAssignmentMembers(rowsData, true) then
            structureDirty = true
        end

        if structureDirty then
            self:UpdateDisplayStructure(db, rowsData, true, previewMode, now, perfState, structureSignature)
        else
            self._displayStructureSignature = structureSignature
        end

        self:NoteStructuralDisplayPass(now, viaSafetyNet)
    end

    local function shouldUseSafetyNet()
        return (not previewMode)
            and (not self._displayIdentityDirty)
            and (not self._displayStructureDirty)
            and type(self._displayAssignments) == "table"
            and self._displaySafetyPending
            and (tonumber(self._displayNextSafetyAt) or 0) > 0
            and (tonumber(self._displayNextSafetyAt) or 0) <= now
    end

    local ranStructuralPass = false
    if self:ShouldRunStructuralDisplayPass(now) then
        runStructuralPass(shouldUseSafetyNet())
        ranStructuralPass = true
    end

    local structureDirtyBeforeDynamic = self._displayStructureDirty and true or false
    self:UpdateDisplayDynamic(now, perfState)
    if self:DynamicOrderNeedsStructuralRefresh() then
        self:MarkDisplayStructureDirty("dynamic-order")
    end

    if self._displayStructureDirty and (not structureDirtyBeforeDynamic or not ranStructuralPass) then
        runStructuralPass(false)
        self:UpdateDisplayDynamic(now, perfState)
    end
    return finish()
end

function InterruptTracker:StartTicker(now)
    if not self.frame then
        return
    end

    local desiredRate = self:GetDesiredTickerRate(now)
    if not desiredRate then
        self:StopTicker()
        return
    end

    if self.ticker and tonumber(self.tickerRate) == tonumber(desiredRate) then
        return
    end

    self:StopTicker()
    self.frame:SetScript("OnUpdate", nil)
    self.tickerRate = desiredRate
    self.ticker = C_Timer.NewTicker(desiredRate, function()
        pcall(function()
            self:UpdateDisplay()
            local currentNow = GetTime()
            local nextRate = self:GetDesiredTickerRate(currentNow)
            if tonumber(nextRate) ~= tonumber(self.tickerRate) then
                self:StartTicker(currentNow)
            end
        end)
    end)
end

function InterruptTracker:StopTicker()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    if self.frame then
        self.frame:SetScript("OnUpdate", nil)
    end
    self.tickerRate = 0
end

function InterruptTracker:EvaluateVisibility()
    PA_CpuDiagCount("interrupt_evaluate_visibility")
    local perfStart, perfState = PA_PerfBegin("interrupt_evaluate_visibility")
    if PA_IsUiSurfaceGateEnabled() then
        if self.frame then
            self:StopTicker()
            self:HardCancelInspectRefresh()
            self:ClearRuntimeDisplayLifecycleState()
            self:ReconcileWatcherState()
            self:SetSpacingHandleEnabled(false)
            PA_CpuDiagApplyVisibility("interrupt", self.frame, false)
        end
        PA_PerfEnd("interrupt_evaluate_visibility", perfStart, perfState)
        return
    end
    if not self.frame then
        PA_PerfEnd("interrupt_evaluate_visibility", perfStart, perfState)
        return
    end
    if not self:IsEnabled() then
        self:MarkDisplayStructureDirty("module-disabled")
        self:StopTicker()
        self:HardCancelInspectRefresh()
        self:ClearRuntimeDisplayLifecycleState()
        self:ReconcileWatcherState()
        self:SetSpacingHandleEnabled(false)
        PA_CpuDiagApplyVisibility("interrupt", self.frame, false)
        PA_PerfEnd("interrupt_evaluate_visibility", perfStart, perfState)
        return
    end
    self:ReconcileWatcherState()
    local shouldShow = self:IsSupportedLiveContext() or self:IsPreviewMode()
    local wasShown = PA_CpuDiagIsFrameConsideredShown("interrupt", self.frame)
    if shouldShow then
        if not wasShown then
            self:MarkDisplayStructureDirty("visibility")
        end
        PA_CpuDiagApplyVisibility("interrupt", self.frame, true)
        self:ApplyFonts()
        self:StartTicker(GetTime())
        self:UpdateDisplay()
    else
        if wasShown or self.ticker then
            self:MarkDisplayStructureDirty("visibility-hidden")
        end
        self:StopTicker()
        self:HardCancelInspectRefresh()
        self:ClearRuntimeDisplayLifecycleState()
        self:ReconcileWatcherState()
        self:SetSpacingHandleEnabled(false)
        PA_CpuDiagApplyVisibility("interrupt", self.frame, false)
    end
    if not self:ShouldAllowPartyInspectRefresh() then
        self:HardCancelInspectRefresh()
    end
    PA_PerfEnd("interrupt_evaluate_visibility", perfStart, perfState)
end

function InterruptTracker:ApplySettings()
    if not self.frame then
        return
    end
    self:MarkDisplayStructureDirty("settings")
    self:ApplyPosition()
    self:ReseedModeBOrder()
    if self.selfRow then
        self.selfRow.bar:SetStatusBarTexture(self:GetBarTexture())
        self.selfRow.barBg:SetTexture(self:GetBarTexture())
    end
    for _, row in ipairs(self.rows or {}) do
        row.bar:SetStatusBarTexture(self:GetBarTexture())
        row.barBg:SetTexture(self:GetBarTexture())
    end
    self:ApplyFonts()
    self:EvaluateVisibility()
end

function InterruptTracker:GetWhoReportLines()
    local runtimeStrings = GetInterruptRuntimeStrings()
    if not self:IsTrackedPartyContext() then
        return nil, runtimeStrings.whoNoParty
    end
    self:BuildUnitMap()
    local roster = self:GetCurrentRoster(true)
    if #roster == 0 then
        return nil, runtimeStrings.whoNoParty
    end
    local now = GetTime()
    local lines = {}
    for _, entry in ipairs(roster) do
        local member = self:FindMemberByName(entry.name)
        local classText = runtimeStrings.whoClassUnknown
        local specText = runtimeStrings.whoSpecUnknown
        local interruptText = runtimeStrings.whoInterruptUnknown
        local stateText = nil

        if entry.isSelf then
            classText = IT_GetLocalizedClassName(select(2, UnitClass("player"))) or classText
            local specIndex = GetSpecialization and GetSpecialization() or nil
            if specIndex and GetSpecializationInfo then
                local _, selfSpecName = GetSpecializationInfo(specIndex)
                if type(selfSpecName) == "string" and selfSpecName ~= "" then
                    specText = selfSpecName
                end
            end
        elseif entry.unit then
            classText = IT_GetLocalizedClassName(IT_SafeUnitClass(entry.unit)) or classText
        end

        if member then
            classText = IT_GetLocalizedClassName(member.class) or classText
            specText = self:GetSpecNameForMember(member) or runtimeStrings.whoSpecUnknown
            local spellData = self:GetPrimarySpellData(member)
            if spellData and spellData.name then
                interruptText = spellData.name
            end
            if member.spellID then
                if self:IsMemberReady(member, now) then
                    stateText = runtimeStrings.ready
                else
                    stateText = IT_FormatCooldown(self:GetMemberRemaining(member, now))
                end
            end
        end

        local line = string.format("%s - %s / %s - %s", entry.name or "?", classText, specText, interruptText)
        if stateText then
            line = line .. " - " .. stateText
        end
        lines[#lines + 1] = line
    end
    return lines, nil
end

function InterruptTracker:Initialize()
    if PA_IsUiSurfaceGateEnabled() then
        return
    end
    if self.frame then
        return
    end
    self:EnsureDB()
    self.trackedMembers = {}
    self.noInterruptPlayers = {}
    self.inspectedPlayers = {}
    self.inspectQueue = {}
    self.recentPartyCasts = {}
    self.interruptCounts = {}
    self.recentCountedInterruptsByMember = {}
    self.rowReadyState = {}
    self.memberUnits = {}
    self.inspectBusy = false
    self.inspectUnit = nil
    self.inspectTargetGUID = nil
    self.inspectTargetName = nil
    self.inspectTimeoutTimer = nil
    self.inspectStepTimer = nil
    self.inspectReadyRetryTimer = nil
    self.inspectReadyRetryCount = 0
    self.inspectReadyRetryExpectedGUID = nil
    self.inspectKnownGoodTalentSnapshotsByKey = {}
    self.inspectKnownGoodTalentSnapshotKeyByName = {}
    self.inspectBackoffByName = {}
    self.availabilityArmed = false
    self.availabilityContextKey = nil
    self.pendingFullWipeRecovery = false
    self.fullWipeRecoveryActive = false
    self.fullWipeRecoveryStartedAt = 0
    self.lastPartyCombatSeenAt = 0
    self.lastPlayerDeadOrGhost = IT_IsUnitRealDeadOrGhost("player")
    self.pendingOwnerInterruptConfirm = nil
    self.pendingOwnerPrimaryCast = nil
    self.pendingOwnerPrimaryCastExpiryTimer = nil
    self.lastHandledOwnerPrimaryCastGUID = nil
    self.lastHandledOwnerPrimaryCastAt = 0
    self.lastOwnerPrimaryCastVerdictGUID = nil
    self.lastOwnerPrimaryCastVerdictAt = 0
    self.lastHandledInterruptedGUID = nil
    self.lastHandledInterruptedAt = 0
    self.partyWatcherUnitActive = {}
    self.partyWatchersActive = false
    self.mobWatchersActive = false
    self.selfWatchersActive = false
    self.previewStartedAt = 0
    self.previewCycleOffsetByKey = {}
    self._visibleRowPulseTargets = {}
    self._rowGapBoundaryReached = false
    self._rowGapDrag = nil
    self._spacingUnlockHintVisible = false
    self._spacingHintShownForUnlock = false
    self:ResetDisplayStructureState()
    self:ClearRuntimeDisplayLifecycleState()
    self.pendingPartyCreditPool = nil
    self.pendingPartyCreditPoolTimer = nil
    self.pendingPartyCreditPoolId = 0
    self.nextPendingPartyCreditCandidateId = 0
    self.consumedMobInterruptConfirmations = {}

    self:BuildFrame()
    self:ReconcileWatcherState()
    self:FindMyInterrupt()
    self:ApplyPosition()
    self:ApplySettings()
    if self:ShouldAllowPartyInspectRefresh() then
        self:QueuePartyInspectDelayed()
    else
        self:HardCancelInspectRefresh()
    end
    self:SetUnlocked(not self:GetDB().locked)
end

-- Lifecycle / event dispatch
local function IT_HandleInterruptTrackerPlayerEnteringWorld(self)
    local preserveRunFreeze = self:IsIdentityFrozen() or (self.activeChallengeRun and true or false)
    self:UpdateRunContext()
    self:ResetPendingPartyCreditRuntime()
    self:ResetInspectSessionFor()
    if preserveRunFreeze and (not self:IsActiveChallengeRun()) and (not self:IsTrackedPartyContext()) then
        self:SetIdentityFrozen(true)
    end
    if self:IsTrackedPartyContext() then
        self:CleanupRosterState()
    end
    self:ReconcileWatcherState()
    self:FindMyInterrupt()
    self:AutoRegisterPartyByClass()
    if self:IsActiveChallengeRun() then
        self:HardCancelInspectRefresh()
    else
        C_Timer.After(2.0, function()
            PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_pew_queue")
            local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
            if self:IsActiveChallengeRun() then
                self:HardCancelInspectRefresh()
                PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
                return
            end
            self:CleanupRosterState()
            if self:ShouldAllowPartyInspectRefresh() then
                self:QueuePartyInspect()
            else
                self:HardCancelInspectRefresh()
            end
            PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
        end)
        C_Timer.After(3.0, function()
            PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_pew_local_refresh")
            local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
            if self:IsActiveChallengeRun() then
                PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
                return
            end
            self:CleanupRosterState()
            self:FindMyInterrupt()
            self:AutoRegisterPartyByClass()
            PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
        end)
    end
    self:RequestDisplayRefresh("identity", "player-entering-world", true)
end

local function IT_HandleInterruptTrackerRosterUpdate(self)
    self:CleanupRosterState()
    self:ReconcileWatcherState()
    self:AutoRegisterPartyByClass()
    if self:ShouldAllowPartyInspectRefresh() then
        self:QueuePartyInspectDelayed()
    else
        self:HardCancelInspectRefresh()
    end
    self:ScheduleCoalescedDisplayRefresh("identity", "roster-update")
end

local function IT_HandleInterruptTrackerSpecChanged(self, unit)
    if unit == "player" then
        self:FindMyInterrupt()
    else
        local changedName = IT_SafeUnitName(unit)
        if changedName then
            local seedChanged = false
            self:ResetInspectStateFor(changedName)
            self.noInterruptPlayers[changedName] = nil
            seedChanged = self:AutoRegisterUnitByClass(unit, true) and true or false
            if seedChanged then
                self:ReseedModeBOrder()
            end
            if self:ShouldAllowPartyInspectRefresh() then
                self:QueuePartyInspectDelayed(unit)
            else
                self:HardCancelInspectRefresh()
            end
        else
            self:ResetInspectStateFor()
            self:AutoRegisterPartyByClass()
            if self:ShouldAllowPartyInspectRefresh() then
                self:QueuePartyInspectDelayed()
            else
                self:HardCancelInspectRefresh()
            end
        end
    end
    self:ScheduleCoalescedDisplayRefresh("identity", "spec-change")
end

local function IT_HandleInterruptTrackerUnitPet(self, unit)
    if unit == "player" then
        self:FindMyInterrupt()
        C_Timer.After(IT_OWN_PET_RETRY_1, function()
            PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_unitpet_retry_1")
            local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
            self:FindMyInterrupt()
            PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
        end)
        C_Timer.After(IT_OWN_PET_RETRY_2, function()
            PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_unitpet_retry_2")
            local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
            self:FindMyInterrupt()
            PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
        end)
        C_Timer.After(IT_OWN_PET_RETRY_3, function()
            PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_unitpet_retry_3")
            local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
            self:FindMyInterrupt()
            PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
        end)
    else
        local changedName = IT_SafeUnitName(unit)
        if changedName then
            self:ResetInspectSessionFor(changedName)
            self.noInterruptPlayers[changedName] = nil
        end
        self:ReconcileWatcherState()
        self:AutoRegisterPartyByClass()
        if self:ShouldAllowPartyInspectRefresh() then
            self:QueuePartyInspectDelayed()
        else
            self:HardCancelInspectRefresh()
        end
    end
    self:ScheduleCoalescedDisplayRefresh("identity", "unit-pet")
end

local function IT_HandleInterruptTrackerSpellsChanged(self)
    self:FindMyInterrupt()
    if self.playerClass == "WARLOCK" then
        C_Timer.After(IT_WARLOCK_SPELLS_RETRY_1, function()
            PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_warlock_retry_1")
            local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
            self:FindMyInterrupt()
            PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
        end)
        C_Timer.After(IT_WARLOCK_SPELLS_RETRY_2, function()
            PA_CpuDiagCount("callback_class_delayed_timer", "interrupt_warlock_retry_2")
            local perfStart, perfState = PA_PerfBegin("callback_class_delayed_timer")
            self:FindMyInterrupt()
            PA_PerfEnd("callback_class_delayed_timer", perfStart, perfState)
        end)
    end
    self:ScheduleCoalescedDisplayRefresh("identity", "spells-changed")
end

local function IT_HandleInterruptTrackerInspectReady(self, inspectedGUID)
    self:HandleInspectReady(inspectedGUID)
    self:ScheduleCoalescedDisplayRefresh("identity", "inspect-ready")
end

local function IT_HandleInterruptTrackerCombatSafeResume(self)
    self:CleanupRosterState()
    if not self:ShouldAllowPartyInspectRefresh() then
        self:HardCancelInspectRefresh()
    elseif self.inspectQueue and #self.inspectQueue > 0 then
        self:ProcessInspectQueue()
    else
        self:QueuePartyInspectDelayed()
    end
    self:ScheduleCoalescedDisplayRefresh("identity", "combat-safe-resume")
end

local function IT_HandleInterruptTrackerRoleChanged(self)
    self:ResetInspectSessionFor()
    self:AutoRegisterPartyByClass()
    if self:ShouldAllowPartyInspectRefresh() then
        self:QueuePartyInspectDelayed()
    else
        self:HardCancelInspectRefresh()
    end
    self:ScheduleCoalescedDisplayRefresh("identity", "role-changed")
end

local function IT_HandleInterruptTrackerUnitDied(self, guid, name)
    if self:HandleTrackedMemberDeath(guid, name, GetTime()) then
        self:RequestDisplayRefresh("structure", "unit-died", true)
    end
end

local function IT_HandleInterruptTrackerChallengeModeStart(self)
    self:UpdateRunContext()
    self:SetIdentityFrozen(true)
    self:ResetCounts()
    self:ResetPendingPartyCreditRuntime()
    self:HardCancelInspectRefresh()
    self:ReconcileWatcherState()
    self:RequestDisplayRefresh("identity", "challenge-mode-start", true)
end

local function IT_HandleInterruptTrackerContextRefresh(self)
    self:UpdateRunContext()
    self:ResetPendingPartyCreditRuntime()
    self:ResetInspectSessionFor()
    self:ReconcileWatcherState()
    if self:ShouldAllowPartyInspectRefresh() then
        self:QueuePartyInspectDelayed()
    end
    self:RequestDisplayRefresh("identity", "context-refresh", true)
end

local IT_INTERRUPT_EVENT_HANDLERS = {
    PLAYER_ENTERING_WORLD = IT_HandleInterruptTrackerPlayerEnteringWorld,
    GROUP_ROSTER_UPDATE = IT_HandleInterruptTrackerRosterUpdate,
    PLAYER_SPECIALIZATION_CHANGED = IT_HandleInterruptTrackerSpecChanged,
    UNIT_PET = IT_HandleInterruptTrackerUnitPet,
    SPELLS_CHANGED = IT_HandleInterruptTrackerSpellsChanged,
    INSPECT_READY = IT_HandleInterruptTrackerInspectReady,
    PLAYER_REGEN_ENABLED = IT_HandleInterruptTrackerCombatSafeResume,
    ROLE_CHANGED_INFORM = IT_HandleInterruptTrackerRoleChanged,
    PLAYER_ROLES_ASSIGNED = IT_HandleInterruptTrackerRoleChanged,
    UNIT_DIED = IT_HandleInterruptTrackerUnitDied,
    CHALLENGE_MODE_START = IT_HandleInterruptTrackerChallengeModeStart,
    ZONE_CHANGED_NEW_AREA = IT_HandleInterruptTrackerContextRefresh,
    CHALLENGE_MODE_COMPLETED = IT_HandleInterruptTrackerContextRefresh,
    ENCOUNTER_START = IT_HandleInterruptTrackerContextRefresh,
    ENCOUNTER_END = IT_HandleInterruptTrackerContextRefresh,
}


function InterruptTracker:OnEvent(event, arg1, arg2, arg3, arg4)
    local handler = IT_INTERRUPT_EVENT_HANDLERS[event]
    if handler then
        handler(self, arg1, arg2, arg3, arg4)
    end
end

-- Register with RRT namespace -------------------------------------------------
Modules:Register(InterruptTracker)
RRT = RRT or {}
RRT_InterruptTracker = InterruptTracker  -- global shortcut for options/slash cmds

-- Self-managed event frame (replaces PA framework dispatcher) -----------------
local _itEventFrame = CreateFrame('Frame')
for _ev in pairs(IT_INTERRUPT_EVENT_HANDLERS) do
    _itEventFrame:RegisterEvent(_ev)
end

_itEventFrame:SetScript('OnEvent', function(_, event, ...)
    -- Lazy-initialize on first event (RRT SavedVariable available after ADDON_LOADED)
    if not InterruptTracker.frame then
        local ok, err = pcall(InterruptTracker.Initialize, InterruptTracker)
        if not ok then
            print('|cffff4444[RRT InterruptTracker]|r Initialize error: ' .. tostring(err))
            return
        end
    end
    local ok, err = pcall(InterruptTracker.OnEvent, InterruptTracker, event, ...)
    if not ok then
        print('|cffff4444[RRT InterruptTracker]|r Event error (' .. tostring(event) .. '): ' .. tostring(err))
    end
end)

end  -- do
