-- =====================================================================
-- [[ RevMplus.FriendlyCD — Friendly Cooldown Tracker ]]
-- Standalone detection engine (ported from MiniCC by Jaliborc).
-- Works in M+ and Raid without restriction.
-- Display modes: Bars, Icons, Attached to raid frames.
-- Frame support: Blizzard, ElvUI, Grid2, VuhDo, DandersFrames.
-- =====================================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local INFINITY_MODULE_KEY = "RevMplus.FriendlyCD"
local L = (InfinityTools and InfinityTools.L)
    or setmetatable({}, { __index = function(_, k) return k end })
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local UnitGUID          = _G.UnitGUID
local UnitName          = _G.UnitName
local UnitClass         = _G.UnitClass
local UnitExists        = _G.UnitExists
local UnitIsUnit        = _G.UnitIsUnit
local UnitCanAttack     = _G.UnitCanAttack
local UnitIsFeignDeath  = _G.UnitIsFeignDeath
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitInParty       = _G.UnitInParty
local UnitInRaid        = _G.UnitInRaid
local GetTime           = _G.GetTime
local CreateFrame       = _G.CreateFrame
local UIParent          = _G.UIParent
local C_Timer           = _G.C_Timer
local GetNumGroupMembers = _G.GetNumGroupMembers
local IsInRaid          = _G.IsInRaid
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local GetInspectSpecialization = _G.GetInspectSpecialization
local NotifyInspect     = _G.NotifyInspect
local C_UnitAuras       = _G.C_UnitAuras
local C_Spell           = _G.C_Spell
local C_ClassTalents    = _G.C_ClassTalents
local C_Traits          = _G.C_Traits
local issecretvalue     = _G.issecretvalue or function() return false end
local wipe              = _G.wipe
local math_abs          = math.abs

-- =====================================================================
-- SECTION 1: InfinityGrid layout registration
-- =====================================================================

local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 53, h = 2, label = "Friendly Cooldown Tracker", labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 53, h = 2, label = "Tracks friendly defensives and offensive cooldowns in M+ and Raid." },

        { key = "div_general", type = "divider", x = 1, y = 8, w = 53, h = 1 },
        { key = "sub_general", type = "subheader", x = 1, y = 7, w = 53, h = 1, label = "General", labelSize = 20 },
        { key = "enabled", type = "checkbox", x = 1, y = 9, w = 6, h = 2, label = L["Enable"] },
        { key = "showOffensive", type = "checkbox", x = 10, y = 9, w = 15, h = 2, label = "Show Offensive CDs" },
        { key = "showPlayer", type = "checkbox", x = 27, y = 9, w = 12, h = 2, label = "Track Self" },

        -- Bar Mode
        { key = "bar_header", type = "header", x = 1, y = 13, w = 53, h = 2, label = "Bar Mode", labelSize = 20 },
        { key = "barEnabled", type = "checkbox", x = 1, y = 16, w = 8, h = 2, label = "Enable" },
        { key = "barLocked", type = "checkbox", x = 12, y = 16, w = 8, h = 2, label = L["Lock Position"] },
        { key = "barPreview", type = "checkbox", x = 22, y = 16, w = 8, h = 2, label = L["Preview Mode"] },
        { key = "btn_reset_bar", type = "button", x = 33, y = 16, w = 14, h = 2, label = L["Reset Position"] },
        { key = "barWidth", type = "slider", x = 1, y = 19, w = 17, h = 2, label = "Bar Width", min = 100, max = 500 },
        { key = "barHeight", type = "slider", x = 20, y = 19, w = 15, h = 2, label = "Bar Height", min = 12, max = 48 },
        { key = "barSpacing", type = "slider", x = 1, y = 22, w = 17, h = 2, label = "Spacing", min = 0, max = 20 },
        { key = "barMaxBars", type = "slider", x = 20, y = 22, w = 15, h = 2, label = "Max Bars", min = 1, max = 40 },
        { key = "barGrowDown", type = "checkbox", x = 1, y = 25, w = 12, h = 2, label = "Grow Downward" },
        { key = "barUseClassColor", type = "checkbox", x = 15, y = 25, w = 12, h = 2, label = "Class Colors" },
        { key = "barShowIcon", type = "checkbox", x = 29, y = 25, w = 10, h = 2, label = "Show Icon" },
        { key = "barShowName", type = "checkbox", x = 1, y = 28, w = 10, h = 2, label = "Show Name" },
        { key = "barShowSpell", type = "checkbox", x = 13, y = 28, w = 14, h = 2, label = "Show Spell Name" },
        { key = "barShowTimer", type = "checkbox", x = 29, y = 28, w = 10, h = 2, label = "Show Timer" },

        -- Icon Mode
        { key = "icon_header", type = "header", x = 1, y = 33, w = 53, h = 2, label = "Icon Mode", labelSize = 20 },
        { key = "iconEnabled", type = "checkbox", x = 1, y = 36, w = 8, h = 2, label = "Enable" },
        { key = "iconLocked", type = "checkbox", x = 12, y = 36, w = 8, h = 2, label = L["Lock Position"] },
        { key = "iconPreview", type = "checkbox", x = 22, y = 36, w = 8, h = 2, label = L["Preview Mode"] },
        { key = "btn_reset_icon", type = "button", x = 33, y = 36, w = 14, h = 2, label = L["Reset Position"] },
        { key = "iconSize", type = "slider", x = 1, y = 39, w = 17, h = 2, label = "Icon Size", min = 16, max = 64 },
        { key = "iconCols", type = "slider", x = 20, y = 39, w = 15, h = 2, label = "Per Row", min = 1, max = 20 },
        { key = "iconSpacing", type = "slider", x = 37, y = 39, w = 14, h = 2, label = "Spacing", min = 0, max = 16 },
        { key = "iconShowName", type = "checkbox", x = 1, y = 42, w = 15, h = 2, label = "Show Player Name" },
        { key = "iconShowTimer", type = "checkbox", x = 18, y = 42, w = 12, h = 2, label = "Show Timer" },

        -- Attached Mode
        { key = "attach_header", type = "header", x = 1, y = 47, w = 53, h = 2, label = "Attached Mode (Raid Frames)", labelSize = 20 },
        { key = "attachEnabled", type = "checkbox", x = 1, y = 50, w = 10, h = 2, label = "Enable" },
        { key = "attachSide", type = "dropdown", x = 14, y = 50, w = 14, h = 2, label = "Position", items = "RIGHT,LEFT,ABOVE,BELOW" },
        { key = "attachIconSize", type = "slider", x = 30, y = 50, w = 17, h = 2, label = "Icon Size", min = 12, max = 48 },
        { key = "attachOffsetX", type = "slider", x = 1, y = 53, w = 17, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "attachOffsetY", type = "slider", x = 20, y = 53, w = 17, h = 2, label = "Offset Y", min = -100, max = 100 },
        { key = "attachSpacing", type = "slider", x = 39, y = 53, w = 14, h = 2, label = "Spacing", min = 0, max = 16 },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =====================================================================
-- SECTION 2: DB Defaults
-- =====================================================================

local MODULE_DEFAULTS = {
    enabled = false,
    showOffensive = false,
    showPlayer = true,

    barEnabled = true,
    barLocked = false,
    barPreview = false,
    barWidth = 240,
    barHeight = 22,
    barSpacing = 2,
    barMaxBars = 20,
    barGrowDown = true,
    barUseClassColor = true,
    barShowIcon = true,
    barShowName = true,
    barShowSpell = true,
    barShowTimer = true,
    barPos = { "CENTER", "UIParent", "CENTER", -400, 0 },

    iconEnabled = false,
    iconLocked = false,
    iconPreview = false,
    iconSize = 32,
    iconCols = 5,
    iconSpacing = 4,
    iconShowName = true,
    iconShowTimer = true,
    iconPos = { "CENTER", "UIParent", "CENTER", -400, 100 },

    attachEnabled = false,
    attachSide = "RIGHT",
    attachIconSize = 20,
    attachOffsetX = 2,
    attachOffsetY = 0,
    attachSpacing = 2,
}

local DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)
if not DB.enabled then return end

-- =====================================================================
-- SECTION 3: Rules (ported from MiniCC — Jaliborc)
-- =====================================================================

local Rules = {}

Rules.BySpec = {
    [65] = { -- Holy Paladin
        { BuffDuration = 12, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 31884, MinDuration = true, ExcludeIfTalent = 216331 }, -- Avenging Wrath
        { BuffDuration = 10, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 216331, MinDuration = true, RequiresTalent = 216331 }, -- Avenging Crusader
        { BuffDuration = 8, Cooldown = 300, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 }, -- Divine Shield
        { BuffDuration = 8, Cooldown = 60, BigDefensive = true, Important = true, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 498 }, -- Divine Protection
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 }, -- Blessing of Spellwarding
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 }, -- Blessing of Protection
        { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940 }, -- Blessing of Sacrifice
    },
    [66] = { -- Protection Paladin
        { BuffDuration = 25, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 31884, ExcludeIfTalent = 389539 }, -- Avenging Wrath
        { BuffDuration = 20, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 389539, RequiresTalent = 389539, ExcludeIfTalent = 31884 }, -- Sentinel
        { BuffDuration = 8, Cooldown = 300, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 }, -- Divine Shield
        { BuffDuration = 8, Cooldown = 90, BigDefensive = true, Important = true, ExternalDefensive = false, SpellId = 31850, RequiresEvidence = "Cast" }, -- Ardent Defender
        { BuffDuration = 8, Cooldown = 180, BigDefensive = true, Important = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 86659 }, -- Guardian of Ancient Kings
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 },
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 },
        { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940 },
    },
    [70] = { -- Retribution Paladin
        { BuffDuration = 24, Cooldown = 60, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 31884, ExcludeIfTalent = 458359 }, -- Avenging Wrath
        { BuffDuration = 8, Cooldown = 300, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 },
        { BuffDuration = 8, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = { "Cast", "Shield" }, SpellId = 403876 }, -- Divine Protection (Ret)
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 },
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 },
        { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940 },
    },
    [62] = { { BuffDuration = 15, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 365350 } }, -- Arcane Surge
    [63] = { { BuffDuration = 10, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 190319, MinDuration = true } }, -- Combustion
    [71] = { -- Arms Warrior
        { BuffDuration = 8, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 118038 }, -- Die by the Sword
        { BuffDuration = 20, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 107574, MinDuration = true, RequiresTalent = 107574 }, -- Avatar
    },
    [72] = { -- Fury Warrior
        { BuffDuration = 8, Cooldown = 108, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 184364, RequiresTalent = 184364 }, -- Enraged Regen
        { BuffDuration = 11, Cooldown = 108, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 184364, RequiresTalent = 184364 }, -- Enraged Regen +talent
        { BuffDuration = 20, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 107574, MinDuration = true, RequiresTalent = 107574 }, -- Avatar
    },
    [73] = { -- Protection Warrior
        { BuffDuration = 8, Cooldown = 180, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 871 }, -- Shield Wall
        { BuffDuration = 20, Cooldown = 90, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 107574, MinDuration = true, RequiresTalent = 107574 }, -- Avatar
    },
    [250] = { -- Blood DK
        { BuffDuration = 10, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 55233 }, -- Vampiric Blood
        { BuffDuration = 12, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 55233 },
        { BuffDuration = 14, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 55233 },
    },
    [251] = { { BuffDuration = 12, Cooldown = 45, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 51271 } }, -- Pillar of Frost
    [256] = { { BuffDuration = 8, Cooldown = 180, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 33206 } }, -- Pain Suppression
    [257] = { -- Holy Priest
        { BuffDuration = 10, Cooldown = 180, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 47788 }, -- Guardian Spirit
        { BuffDuration = 5, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 64843 }, -- Divine Hymn
    },
    [258] = { -- Shadow Priest
        { BuffDuration = 6, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 47585 }, -- Dispersion
        { BuffDuration = 20, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 228260 }, -- Voidform
    },
    [102] = { { BuffDuration = 20, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 102560 } }, -- Incarnation Balance
    [103] = { -- Feral Druid
        { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 106951, RequiresTalent = 106951, ExcludeIfTalent = 102543 }, -- Berserk
        { BuffDuration = 20, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 102543, RequiresTalent = 102543 }, -- Incarnation Feral
    },
    [104] = { { BuffDuration = 30, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 102558 } }, -- Incarnation Guardian
    [105] = { { BuffDuration = 12, Cooldown = 90, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 102342 } }, -- Ironbark
    [268] = { -- Brewmaster Monk
        { BuffDuration = 25, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 132578 }, -- Invoke Niuzao
        { BuffDuration = 15, Cooldown = 360, BigDefensive = true, Important = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 115203 }, -- Fortifying Brew
    },
    [270] = { { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 116849 } }, -- Life Cocoon
    [577] = { { BuffDuration = 10, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 198589 } }, -- Blur Havoc
    [581] = { -- Vengeance DH
        { BuffDuration = 12, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 204021 }, -- Fiery Brand
        { BuffDuration = 15, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 187827 }, -- Metamorphosis
        { BuffDuration = 20, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 187827 },
    },
    [1480] = { { BuffDuration = 10, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 198589 } }, -- Blur Devourer
    [254] = { -- MM Hunter
        { BuffDuration = 15, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 288613 }, -- Trueshot
        { BuffDuration = 17, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 288613 },
    },
    [255] = { -- Survival Hunter
        { BuffDuration = 8, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 1250646 }, -- Takedown
        { BuffDuration = 10, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 1250646 },
    },
    [261] = { -- Subtlety Rogue
        { BuffDuration = 16, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 121471 },
        { BuffDuration = 18, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 121471 },
        { BuffDuration = 20, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 121471 },
    },
    [1467] = { { BuffDuration = 18, Cooldown = 120, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 375087 } }, -- Dragonrage
    [1468] = { { BuffDuration = 8, Cooldown = 60, ExternalDefensive = true, BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 357170 } }, -- Time Dilation
    [1473] = { { BuffDuration = 13.4, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", MinDuration = true, SpellId = 363916 } }, -- Obsidian Scales Aug
    [262] = { -- Elemental Shaman
        { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114050, RequiresTalent = 114050 },
        { BuffDuration = 18, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114050, RequiresTalent = 114050 },
    },
    [263] = { -- Enhancement Shaman
        { BuffDuration = 8, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 384352, RequiresTalent = 384352, ExcludeIfTalent = { 114051, 378270 } }, -- Doomwinds
        { BuffDuration = 10, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 384352, RequiresTalent = 384352, ExcludeIfTalent = { 114051, 378270 } },
        { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114051, RequiresTalent = 114051 }, -- Ascendance
    },
    [264] = { { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114052, RequiresTalent = 114052 } }, -- Ascendance Resto
}

Rules.ByClass = {
    PALADIN = {
        { BuffDuration = 8, Cooldown = 300, BigDefensive = true, Important = true, ExternalDefensive = false, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 }, -- Divine Shield
        { BuffDuration = 8, Cooldown = 25, Important = true, ExternalDefensive = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1044 }, -- Blessing of Freedom
        { BuffDuration = 10, Cooldown = 45, ExternalDefensive = true, Important = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692 },
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, Important = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022, ExcludeIfTalent = 5692 },
    },
    WARRIOR = {},
    MAGE = {
        { BuffDuration = 10, Cooldown = 240, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, SpellId = 45438, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, ExcludeIfTalent = 414659 }, -- Ice Block
        { BuffDuration = 6, Cooldown = 240, BigDefensive = true, ExternalDefensive = false, Important = true, SpellId = 414659, RequiresEvidence = "Cast", RequiresTalent = 414659 }, -- Ice Cold
        { BuffDuration = 10, Cooldown = 50, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, SpellId = 342246, RequiresEvidence = "Cast" }, -- Alter Time
    },
    HUNTER = {
        { BuffDuration = 8, Cooldown = 180, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, SpellId = 186265, RequiresEvidence = { "Cast", "UnitFlags" } }, -- Aspect of the Turtle
        { BuffDuration = 6, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, MinDuration = true, SpellId = 264735, RequiresEvidence = "Cast" }, -- Survival of the Fittest
        { BuffDuration = 8, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, MinDuration = true, SpellId = 264735, RequiresEvidence = "Cast" },
    },
    DRUID = {
        { BuffDuration = 8, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 22812 }, -- Barkskin
        { BuffDuration = 12, Cooldown = 60, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 22812 },
    },
    ROGUE = {
        { BuffDuration = 10, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 5277 }, -- Evasion
        { BuffDuration = 5, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 31224 }, -- Cloak of Shadows
    },
    DEATHKNIGHT = {
        { BuffDuration = 5, Cooldown = 60, BigDefensive = true, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } }, -- AMS
        { BuffDuration = 7, Cooldown = 60, BigDefensive = true, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } },
        { BuffDuration = 8, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 48792 }, -- Icebound Fortitude
        { BuffDuration = 5, Cooldown = 60, BigDefensive = false, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } },
        { BuffDuration = 7, Cooldown = 60, BigDefensive = false, Important = true, ExternalDefensive = false, CanCancelEarly = true, SpellId = 48707, RequiresEvidence = { "Cast", "Shield" } },
    },
    DEMONHUNTER = {},
    MONK = {
        { BuffDuration = 15, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 115203 }, -- Fortifying Brew
    },
    SHAMAN = {
        { BuffDuration = 12, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 108271 }, -- Astral Shift
    },
    WARLOCK = {
        { BuffDuration = 8, Cooldown = 180, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 104773 }, -- Unending Resolve
        { BuffDuration = 3, Cooldown = 45, Important = true, BigDefensive = false, ExternalDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 212295, RequiresTalent = 3624 }, -- Nether Ward
    },
    PRIEST = {
        { BuffDuration = 10, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 19236 }, -- Desperate Prayer
    },
    EVOKER = {
        { BuffDuration = 12, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", MinDuration = true, SpellId = 363916 }, -- Obsidian Scales
    },
}

Rules.OffensiveSpellIds = {
    [375087] = true, [107574] = true, [121471] = true, [31884] = true, [216331] = true,
    [190319] = true, [288613] = true, [228260] = true, [102560] = true, [102543] = true,
    [106951] = true, [102558] = true, [1250646] = true, [384352] = true, [114051] = true,
    [114050] = true, [365350] = true, [51271] = true,
}

-- =====================================================================
-- SECTION 4: Spec cache + Inspect queue
-- =====================================================================

local specCache = {}      -- guid -> specId
local inspectQueue = {}   -- ordered list of unit tokens
local inspectInFlight = false
local INSPECT_TIMEOUT = 5

local function GetUnitSpec(unit)
    if not unit or not UnitExists(unit) then return 0 end
    if UnitIsUnit(unit, "player") then
        local idx = GetSpecialization and GetSpecialization()
        if not idx then return 0 end
        return (GetSpecializationInfo and select(1, GetSpecializationInfo(idx))) or 0
    end
    local guid = UnitGUID(unit)
    return (guid and specCache[guid]) or 0
end

local inspectFrame = CreateFrame("Frame")
local function PumpInspectQueue()
    if inspectInFlight or #inspectQueue == 0 then return end
    local unit = table.remove(inspectQueue, 1)
    if not UnitExists(unit) then
        PumpInspectQueue()
        return
    end
    inspectInFlight = true
    NotifyInspect(unit)
    C_Timer.After(INSPECT_TIMEOUT, function()
        inspectInFlight = false
        PumpInspectQueue()
    end)
end

local function QueueInspect(unit)
    if not UnitExists(unit) then return end
    for _, u in ipairs(inspectQueue) do
        if UnitIsUnit(u, unit) then return end
    end
    inspectQueue[#inspectQueue + 1] = unit
    PumpInspectQueue()
end

inspectFrame:RegisterEvent("INSPECT_READY")
inspectFrame:SetScript("OnEvent", function(_, event, guid)
    if event == "INSPECT_READY" then
        local specId = GetInspectSpecialization and GetInspectSpecialization() or 0
        if guid and specId and specId > 0 then
            specCache[guid] = specId
        end
        inspectInFlight = false
        PumpInspectQueue()
    end
end)

-- =====================================================================
-- SECTION 5: Player talent check
-- =====================================================================

local playerTalentCache = {}

local function RefreshPlayerTalents()
    wipe(playerTalentCache)
    if not C_ClassTalents or not C_ClassTalents.GetActiveConfigID then return end
    local configId = C_ClassTalents.GetActiveConfigID()
    if not configId then return end
    if not C_Traits or not C_Traits.GetConfig then return end
    local configInfo = C_Traits.GetConfig(configId)
    if not configInfo then return end
    for _, treeId in ipairs(configInfo.treeIDs or {}) do
        local nodes = C_Traits.GetTreeNodes and C_Traits.GetTreeNodes(treeId) or {}
        for _, nodeId in ipairs(nodes) do
            local node = C_Traits.GetNodeInfo and C_Traits.GetNodeInfo(configId, nodeId)
            if node and node.activeRank and node.activeRank > 0 then
                for _, entryId in ipairs(node.entryIDs or {}) do
                    local entryInfo = C_Traits.GetEntryInfo and C_Traits.GetEntryInfo(configId, entryId)
                    if entryInfo and entryInfo.definitionID then
                        local defInfo = C_Traits.GetDefinitionInfo and C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                        if defInfo and defInfo.spellID then
                            playerTalentCache[defInfo.spellID] = true
                        end
                    end
                end
            end
        end
    end
end

-- Returns true if the unit has the given talent spellId.
-- For non-player units, always returns nil (unconstrained — skip talent filtering).
local function UnitHasTalent(unit, talentId)
    if UnitIsUnit(unit, "player") then
        return playerTalentCache[talentId] == true
    end
    return nil -- nil = skip this check for others
end

-- =====================================================================
-- SECTION 6: AuraWatcher (port of MiniCC UnitAuraWatcher — Defensives+Important only)
-- =====================================================================

local function InterestedIn(watcher, updateInfo)
    if not updateInfo or updateInfo.isFullUpdate then return true end
    local state = watcher.State
    local unit = state.Unit
    if updateInfo.addedAuras then
        for _, aura in pairs(updateInfo.addedAuras) do
            local id = aura.auraInstanceID
            if id then
                if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|BIG_DEFENSIVE") then return true end
                if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|EXTERNAL_DEFENSIVE") then return true end
                if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|IMPORTANT") then return true end
            end
        end
    end
    if updateInfo.updatedAuraInstanceIDs then
        for _, id in pairs(updateInfo.updatedAuraInstanceIDs) do
            if id then
                if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|BIG_DEFENSIVE") then return true end
                if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|EXTERNAL_DEFENSIVE") then return true end
                if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|IMPORTANT") then return true end
            end
        end
    end
    if updateInfo.removedAuraInstanceIDs and next(updateInfo.removedAuraInstanceIDs) ~= nil then
        local defState = state.DefensiveState
        local impState = state.ImportantState
        for _, id in pairs(updateInfo.removedAuraInstanceIDs) do
            for _, aura in ipairs(defState) do if aura.AuraInstanceID == id then return true end end
            for _, aura in ipairs(impState) do if aura.AuraInstanceID == id then return true end end
        end
    end
    return false
end

local Watcher = {}
Watcher.__index = Watcher

function Watcher:Enable()
    if self.State.Enabled then return end
    self.Frame:RegisterUnitEvent("UNIT_AURA", self.State.Unit)
    self.State.Enabled = true
end

function Watcher:Disable()
    if not self.State.Enabled then return end
    self.Frame:UnregisterAllEvents()
    self.State.Enabled = false
end

function Watcher:ClearState(notify)
    self.State.DefensiveState = {}
    self.State.ImportantState = {}
    if notify and self.State.Callback then self.State.Callback(self) end
end

function Watcher:ForceFullUpdate()
    self:OnEvent("UNIT_AURA", self.State.Unit, { isFullUpdate = true })
end

function Watcher:Dispose()
    self.Frame:UnregisterAllEvents()
    self.Frame:SetScript("OnEvent", nil)
    self.Frame.Watcher = nil
    self.Frame = nil
    self.State.Callback = nil
    self:ClearState(false)
end

function Watcher:RebuildStates()
    local unit = self.State.Unit
    if not unit then return end
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then
        if next(self.State.DefensiveState) or next(self.State.ImportantState) then
            self:ClearState(true)
        end
        return
    end

    local defList = {}
    local impList = {}
    local seen = {}

    local function IterateAuras(filter, callback)
        local auras = C_UnitAuras.GetUnitAuras(unit, filter)
        for _, auraData in ipairs(auras or {}) do
            callback(auraData)
        end
    end

    IterateAuras("HELPFUL|BIG_DEFENSIVE", function(auraData)
        local isDefensive = C_UnitAuras.AuraIsBigDefensive(auraData.spellId)
        if issecretvalue(isDefensive) or isDefensive then
            defList[#defList + 1] = { SpellId = auraData.spellId, SpellName = auraData.name, SpellIcon = auraData.icon, AuraInstanceID = auraData.auraInstanceID }
        end
        seen[auraData.auraInstanceID] = true
    end)
    IterateAuras("HELPFUL|EXTERNAL_DEFENSIVE", function(auraData)
        if not seen[auraData.auraInstanceID] then
            defList[#defList + 1] = { SpellId = auraData.spellId, SpellName = auraData.name, SpellIcon = auraData.icon, AuraInstanceID = auraData.auraInstanceID }
            seen[auraData.auraInstanceID] = true
        end
    end)
    IterateAuras("HELPFUL|IMPORTANT", function(auraData)
        if not seen[auraData.auraInstanceID] then
            local isImportant = C_Spell.IsSpellImportant(auraData.spellId)
            if issecretvalue(isImportant) or isImportant then
                impList[#impList + 1] = { SpellId = auraData.spellId, SpellName = auraData.name, SpellIcon = auraData.icon, AuraInstanceID = auraData.auraInstanceID }
                seen[auraData.auraInstanceID] = true
            end
        end
    end)

    self.State.DefensiveState = defList
    self.State.ImportantState = impList
end

function Watcher:OnEvent(event, ...)
    if event == "UNIT_AURA" then
        local unit, updateInfo = ...
        if unit and unit ~= self.State.Unit then return end
        if not InterestedIn(self, updateInfo) then return end
    end
    if not self.State.Unit then return end
    self:RebuildStates()
    if self.State.Callback then self.State.Callback(self) end
end

local function NewWatcher(unit, callback)
    local watcher = setmetatable({
        Frame = nil,
        State = {
            Unit = unit,
            Enabled = false,
            Callback = callback,
            DefensiveState = {},
            ImportantState = {},
        }
    }, Watcher)
    local frame = CreateFrame("Frame")
    frame.Watcher = watcher
    frame:SetScript("OnEvent", function(f, event, ...) f.Watcher:OnEvent(event, ...) end)
    watcher.Frame = frame
    watcher:Enable()
    watcher:ForceFullUpdate()
    return watcher
end

-- =====================================================================
-- SECTION 7: Observer (port of MiniCC Observer)
-- =====================================================================

local Observer = {}
local observerWatched = {}      -- entry -> { Watcher, CastFrame }
local observerCallbacks = {}    -- aura-changed callbacks
local observerCastCallbacks = {}
local observerShieldCallbacks = {}
local observerFlagsCallbacks = {}
local observerDebuffCallbacks = {}
local candidateScratch = {}

local function FireAuraChanged(entry, watcher)
    local t = candidateScratch
    local n = 0
    for e in pairs(observerWatched) do n = n + 1; t[n] = e.Unit end
    for i = n + 1, #t do t[i] = nil end
    for _, fn in ipairs(observerCallbacks) do fn(entry, watcher, t) end
end

local function MakeCastFrame(entry)
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, event, ...)
        local u = entry.Unit
        if not u or UnitCanAttack("player", u) then return end
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            for _, fn in ipairs(observerCastCallbacks) do fn(u) end
        elseif event == "UNIT_FLAGS" then
            for _, fn in ipairs(observerFlagsCallbacks) do fn(u) end
        elseif event == "UNIT_AURA" then
            local _, updateInfo = ...
            for _, fn in ipairs(observerDebuffCallbacks) do fn(u, updateInfo) end
        end
    end)
    return frame
end

local function RegisterCastEvents(frame, unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
    frame:RegisterUnitEvent("UNIT_FLAGS", unit)
    frame:RegisterUnitEvent("UNIT_AURA", unit)
end

function Observer:Watch(entry)
    if observerWatched[entry] then return end
    local castFrame = MakeCastFrame(entry)
    RegisterCastEvents(castFrame, entry.Unit)
    local watcher = NewWatcher(entry.Unit, function(w) FireAuraChanged(entry, w) end)
    observerWatched[entry] = { Watcher = watcher, CastFrame = castFrame }
    FireAuraChanged(entry, watcher)
end

function Observer:Unwatch(entry)
    local state = observerWatched[entry]
    if not state then return end
    state.CastFrame:UnregisterAllEvents()
    state.Watcher:Dispose()
    observerWatched[entry] = nil
end

function Observer:Rewatch(entry)
    local state = observerWatched[entry]
    if not state then return end
    state.CastFrame:UnregisterAllEvents()
    RegisterCastEvents(state.CastFrame, entry.Unit)
    state.Watcher:Dispose()
    state.Watcher = NewWatcher(entry.Unit, function(w) FireAuraChanged(entry, w) end)
    FireAuraChanged(entry, state.Watcher)
end

function Observer:RegisterAuraChanged(fn) observerCallbacks[#observerCallbacks + 1] = fn end
function Observer:RegisterCast(fn) observerCastCallbacks[#observerCastCallbacks + 1] = fn end
function Observer:RegisterShield(fn) observerShieldCallbacks[#observerShieldCallbacks + 1] = fn end
function Observer:RegisterFlags(fn) observerFlagsCallbacks[#observerFlagsCallbacks + 1] = fn end
function Observer:RegisterDebuff(fn) observerDebuffCallbacks[#observerDebuffCallbacks + 1] = fn end

-- Global absorb frame (not per-unit)
do
    local absorbFrame = CreateFrame("Frame")
    absorbFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    absorbFrame:SetScript("OnEvent", function(_, _, unit)
        for _, fn in ipairs(observerShieldCallbacks) do fn(unit) end
    end)
end

-- =====================================================================
-- SECTION 8: Brain (port of MiniCC Brain — detection engine)
-- =====================================================================

local Brain = {}

local TOLERANCE = 0.5
local CAST_WINDOW = 0.15
local EVIDENCE_TOLERANCE = 0.15

local lastDebuffTime  = {}
local lastShieldTime  = {}
local lastCastTime    = {}
local lastFlagsTime   = {}
local lastFeignTime   = {}
local lastFeignState  = {}
local unitCanFeign    = {}
local brainCandidateScratch = {}

local cdCommittedCallback = nil
local cdDisplayCallback   = nil

local function BuildEvidenceSet(unit, detectionTime)
    local ev = nil
    if lastDebuffTime[unit] and math_abs(lastDebuffTime[unit] - detectionTime) <= EVIDENCE_TOLERANCE then ev = ev or {}; ev.Debuff = true end
    if lastShieldTime[unit] and math_abs(lastShieldTime[unit] - detectionTime) <= EVIDENCE_TOLERANCE then ev = ev or {}; ev.Shield = true end
    if lastFeignTime[unit] and math_abs(lastFeignTime[unit] - detectionTime) <= CAST_WINDOW then
        ev = ev or {}; ev.FeignDeath = true
    elseif lastFlagsTime[unit] and math_abs(lastFlagsTime[unit] - detectionTime) <= CAST_WINDOW then
        ev = ev or {}; ev.UnitFlags = true
    end
    if lastCastTime[unit] and math_abs(lastCastTime[unit] - detectionTime) <= CAST_WINDOW then ev = ev or {}; ev.Cast = true end
    return ev
end

local function AuraTypesSignature(at)
    return (at.BIG_DEFENSIVE and "B" or "") .. (at.EXTERNAL_DEFENSIVE and "E" or "") .. (at.IMPORTANT and "I" or "")
end

local function AuraTypeMatchesRule(auraTypes, rule)
    if rule.BigDefensive == true and not auraTypes.BIG_DEFENSIVE then return false end
    if rule.BigDefensive == false and auraTypes.BIG_DEFENSIVE then return false end
    if rule.ExternalDefensive == true and not auraTypes.EXTERNAL_DEFENSIVE then return false end
    if rule.ExternalDefensive == false and auraTypes.EXTERNAL_DEFENSIVE then return false end
    if rule.Important == true and not auraTypes.IMPORTANT then return false end
    return true
end

local function EvidenceMatchesReq(req, evidence)
    if req == nil then return true end
    if req == false then return not evidence or not next(evidence) end
    if type(req) == "string" then return evidence ~= nil and evidence[req] == true end
    if type(req) == "table" then
        if not evidence then return false end
        for _, k in ipairs(req) do if not evidence[k] then return false end end
        return true
    end
    return false
end

local function MatchRule(unit, auraTypes, measuredDuration, evidence, activeCooldowns)
    local _, classToken = UnitClass(unit)
    if not classToken then return nil end
    local specId = GetUnitSpec(unit)
    local isPlayer = UnitIsUnit(unit, "player")

    local function tryList(ruleList)
        if not ruleList then return nil end
        local fallback = nil
        for _, rule in ipairs(ruleList) do
            local matches = true
            -- RequiresTalent check
            if rule.RequiresTalent then
                local has = UnitHasTalent(unit, rule.RequiresTalent)
                if has == nil then
                    -- non-player: skip RequiresTalent check (treat as met)
                elseif not has then
                    matches = false
                end
            end
            -- ExcludeIfTalent check
            if matches and rule.ExcludeIfTalent then
                local excludeIds = type(rule.ExcludeIfTalent) == "table" and rule.ExcludeIfTalent or { rule.ExcludeIfTalent }
                for _, tid in ipairs(excludeIds) do
                    if UnitHasTalent(unit, tid) == true then
                        matches = false
                        break
                    end
                end
            end
            if matches then
                if not AuraTypeMatchesRule(auraTypes, rule) then matches = false end
            end
            if matches then
                if not EvidenceMatchesReq(rule.RequiresEvidence, evidence) then matches = false end
            end
            if matches then
                local expectedDuration = rule.BuffDuration
                local durationOk
                if rule.MinDuration then
                    durationOk = measuredDuration >= expectedDuration - TOLERANCE
                elseif rule.CanCancelEarly == true then
                    durationOk = measuredDuration <= expectedDuration + TOLERANCE
                else
                    durationOk = math_abs(measuredDuration - expectedDuration) <= TOLERANCE
                end
                if durationOk then
                    local alreadyOnCd = activeCooldowns and rule.SpellId and activeCooldowns[rule.SpellId]
                    if not alreadyOnCd then return rule end
                    if not fallback then fallback = rule end
                end
            end
        end
        return fallback
    end

    return tryList(specId and specId > 0 and Rules.BySpec[specId]) or tryList(Rules.ByClass[classToken])
end

local function BuildCurrentAuraIds(unit, watcher)
    local currentIds = {}
    for _, aura in ipairs(watcher.State.DefensiveState) do
        local id = aura.AuraInstanceID
        if id then
            local isExt = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|EXTERNAL_DEFENSIVE")
            local isImportant = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, id, "HELPFUL|IMPORTANT")
            local auraType = isExt and "EXTERNAL_DEFENSIVE" or "BIG_DEFENSIVE"
            local auraTypes = { [auraType] = true }
            if isImportant then auraTypes.IMPORTANT = true end
            currentIds[id] = { AuraTypes = auraTypes, SpellId = aura.SpellId, SpellIcon = aura.SpellIcon }
        end
    end
    for _, aura in ipairs(watcher.State.ImportantState) do
        local id = aura.AuraInstanceID
        if id then
            if currentIds[id] then
                currentIds[id].AuraTypes.IMPORTANT = true
            else
                currentIds[id] = { AuraTypes = { IMPORTANT = true }, SpellId = aura.SpellId, SpellIcon = aura.SpellIcon }
            end
        end
    end
    return currentIds
end

local function FindBestCandidate(entry, tracked, measuredDuration, candidateUnits)
    local rule, ruleUnit, bestTime = nil, entry.Unit, nil
    local isExternal = tracked.AuraTypes.EXTERNAL_DEFENSIVE

    local function consider(candidate, isTarget)
        local scratch = brainCandidateScratch
        scratch.Debuff = nil; scratch.Shield = nil; scratch.UnitFlags = nil; scratch.FeignDeath = nil; scratch.Cast = nil
        local hasEvidence = false
        if tracked.Evidence then
            for k, v in pairs(tracked.Evidence) do
                if k ~= "Cast" then scratch[k] = v; hasEvidence = true end
            end
        end
        local castTime = tracked.CastSnapshot[candidate]
        if castTime and math_abs(castTime - tracked.StartTime) <= CAST_WINDOW then
            scratch.Cast = true; hasEvidence = true
        end
        local ev = hasEvidence and scratch or nil
        local candidateRule = MatchRule(candidate, tracked.AuraTypes, measuredDuration, ev, entry.ActiveCooldowns)
        if not candidateRule then return end
        local isBetter = not rule
            or (castTime and (not bestTime or castTime > bestTime))
            or (not castTime and not bestTime and isExternal and not isTarget)
        if isBetter then rule, ruleUnit, bestTime = candidateRule, candidate, castTime end
    end

    consider(entry.Unit, true)
    for _, unit in ipairs(candidateUnits) do
        if unit ~= entry.Unit then consider(unit, false) end
    end
    return rule, ruleUnit
end

local function OnAuraRemoved(entry, tracked, now, candidateUnits)
    local measuredDuration = now - tracked.StartTime
    local rule, ruleUnit = FindBestCandidate(entry, tracked, measuredDuration, candidateUnits)
    if not rule then return false end

    local cdKey = rule.SpellId or ("CD_" .. tostring(rule.BuffDuration) .. "_" .. tostring(rule.Cooldown))
    local cdData = {
        StartTime = tracked.StartTime,
        Cooldown = rule.Cooldown,
        Remaining = rule.Cooldown - measuredDuration,
        SpellId = tracked.SpellId,
        SpellIcon = tracked.SpellIcon,
        IsOffensive = rule.SpellId ~= nil and Rules.OffensiveSpellIds[rule.SpellId] == true,
    }
    if cdCommittedCallback then cdCommittedCallback(ruleUnit, cdKey, cdData, entry) end
    return true
end

local function OnWatcherChanged(entry, watcher, candidateUnits)
    local now = GetTime()
    local trackedAuras = entry.TrackedAuras
    local currentIds = BuildCurrentAuraIds(entry.Unit, watcher)

    local unmatchedNewIds = {}
    for id in pairs(currentIds) do
        if not trackedAuras[id] then unmatchedNewIds[#unmatchedNewIds + 1] = id end
    end
    local newIdsBySignature = {}
    for _, id in ipairs(unmatchedNewIds) do
        local sig = AuraTypesSignature(currentIds[id].AuraTypes)
        newIdsBySignature[sig] = newIdsBySignature[sig] or {}
        newIdsBySignature[sig][#newIdsBySignature[sig] + 1] = id
    end

    local cooldownCommitted = false
    for id, tracked in pairs(trackedAuras) do
        if not currentIds[id] then
            local sig = AuraTypesSignature(tracked.AuraTypes)
            local candidates = newIdsBySignature[sig]
            if candidates and #candidates > 0 then
                local reassignedId = table.remove(candidates, 1)
                trackedAuras[reassignedId] = tracked
            else
                if OnAuraRemoved(entry, tracked, now, candidateUnits) then
                    cooldownCommitted = true
                end
            end
            trackedAuras[id] = nil
        end
    end

    for id, info in pairs(currentIds) do
        if not trackedAuras[id] then
            local evidence = BuildEvidenceSet(entry.Unit, now)
            local castSnapshot = {}
            for u, t in pairs(lastCastTime) do castSnapshot[u] = t end
            trackedAuras[id] = { StartTime = now, AuraTypes = info.AuraTypes, SpellId = info.SpellId, SpellIcon = info.SpellIcon, Evidence = evidence, CastSnapshot = castSnapshot }
            C_Timer.After(EVIDENCE_TOLERANCE, function()
                local tr = trackedAuras[id]
                if not tr then return end
                local ev = BuildEvidenceSet(entry.Unit, now)
                if ev then
                    tr.Evidence = tr.Evidence or {}
                    for k in pairs(ev) do tr.Evidence[k] = true end
                end
                for u, t in pairs(lastCastTime) do
                    if math_abs(t - now) <= CAST_WINDOW and not tr.CastSnapshot[u] then
                        tr.CastSnapshot[u] = t
                    end
                end
            end)
        end
    end

    if cdDisplayCallback and cooldownCommitted then cdDisplayCallback(entry) end
end

-- Wire Brain into Observer
Observer:RegisterAuraChanged(function(entry, watcher, candidateUnits) OnWatcherChanged(entry, watcher, candidateUnits) end)
Observer:RegisterCast(function(unit) local now = GetTime(); if lastCastTime[unit] ~= now then lastCastTime[unit] = now end end)
Observer:RegisterShield(function(unit) lastShieldTime[unit] = GetTime() end)
Observer:RegisterFlags(function(unit)
    local now = GetTime()
    local canFeign = unitCanFeign[unit]
    if canFeign == nil then local _, cls = UnitClass(unit); canFeign = cls == "HUNTER"; unitCanFeign[unit] = canFeign end
    local isFeign = canFeign and UnitIsFeignDeath(unit) or false
    if isFeign and not lastFeignState[unit] then lastFeignTime[unit] = now end
    lastFeignState[unit] = isFeign
    if not isFeign then lastFlagsTime[unit] = now end
end)
Observer:RegisterDebuff(function(unit, updateInfo)
    if updateInfo and not updateInfo.isFullUpdate and updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if aura.auraInstanceID and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, "HARMFUL") then
                lastDebuffTime[unit] = GetTime()
                break
            end
        end
    end
end)

-- =====================================================================
-- SECTION 9: Cooldown Store
-- =====================================================================

-- activeCDs[unit][cdKey] = { StartTime, Cooldown, Remaining, SpellId, SpellIcon, IsOffensive }
local activeCDs = {}
-- entry.ActiveCooldowns[spellId] = true
local watchEntries = {}  -- unit -> entry

local function GetSpellIcon(spellId)
    if not spellId then return nil end
    local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellId)
    return info and info.iconID
end

cdCommittedCallback = function(ruleUnit, cdKey, cdData, detectedEntry)
    if not DB.showOffensive and cdData.IsOffensive then return end
    activeCDs[ruleUnit] = activeCDs[ruleUnit] or {}
    -- Resolve icon
    if not cdData.SpellIcon and cdData.SpellId then
        cdData.SpellIcon = GetSpellIcon(cdData.SpellId)
    end
    local _, className = UnitClass(ruleUnit)
    cdData.UnitName = UnitName(ruleUnit) or ruleUnit
    cdData.Class = className
    activeCDs[ruleUnit][cdKey] = cdData
    -- Schedule removal
    local removeDelay = math.max(cdData.Cooldown - (GetTime() - cdData.StartTime), 0)
    C_Timer.After(removeDelay + 0.1, function()
        if activeCDs[ruleUnit] and activeCDs[ruleUnit][cdKey] == cdData then
            activeCDs[ruleUnit][cdKey] = nil
        end
    end)
end

cdDisplayCallback = function(entry)
    -- Trigger display refresh for the entry's unit
end

-- =====================================================================
-- SECTION 10: Frame detection (port of MiniCC Frames)
-- =====================================================================

local Frames = {}

function Frames:BlizzardFrames()
    local frames = {}
    for i = 1, 5 do
        local f = _G["CompactPartyFrameMember" .. i]
        if f and not f:IsForbidden() then frames[#frames + 1] = f end
    end
    for i = 1, 40 do
        local f = _G["CompactRaidFrame" .. i]
        if f and not f:IsForbidden() then frames[#frames + 1] = f end
    end
    if PartyFrame then
        for i = 1, 5 do
            local f = PartyFrame["MemberFrame" .. i]
            if f and not f:IsForbidden() then frames[#frames + 1] = f end
        end
    end
    return frames
end

function Frames:ElvUIFrames()
    if not ElvUI then return {} end
    local ok, E = pcall(function() return unpack(ElvUI) end)
    if not ok or not E then return {} end
    local okUF, UF = pcall(E.GetModule, E, "UnitFrames")
    if not okUF or not UF then return {} end
    local frames = {}
    for _ in pairs(UF.headers or {}) do
        local grpName = _
        local group = UF[grpName]
        if group and group.GetChildren then
            for _, child in ipairs({ group:GetChildren() }) do
                if not child.Health then
                    for _, sub in ipairs({ child:GetChildren() }) do
                        if sub.unit then frames[#frames + 1] = sub end
                    end
                elseif child.unit then
                    frames[#frames + 1] = child
                end
            end
        end
    end
    return frames
end

function Frames:Grid2Frames()
    if not Grid2 or not Grid2.GetUnitFrames then return {} end
    local frames = {}
    local function addUnit(u)
        local ok, fs = pcall(Grid2.GetUnitFrames, Grid2, u)
        local f = ok and fs and next(fs)
        if f then frames[#frames + 1] = f end
    end
    addUnit("player")
    for i = 1, 4 do addUnit("party" .. i) end
    for i = 1, 40 do addUnit("raid" .. i) end
    return frames
end

function Frames:VuhDoFrames()
    -- VuhDo frames are embedded in VUHDO_FRAMES[group][button]
    if not VUHDO_FRAMES then return {} end
    local frames = {}
    for _, group in pairs(VUHDO_FRAMES) do
        if type(group) == "table" then
            for _, btn in pairs(group) do
                if type(btn) == "table" and btn.unit then frames[#frames + 1] = btn end
            end
        end
    end
    return frames
end

function Frames:DandersFrames()
    local frames = {}
    if DandersFrames_GetAllFrames then
        local ok, result = pcall(DandersFrames_GetAllFrames)
        if ok and result then frames = result end
    end
    return frames
end

function Frames:GetAll()
    local all = {}
    local blizzard  = Frames:BlizzardFrames()
    local elvui     = Frames:ElvUIFrames()
    local grid2     = Frames:Grid2Frames()
    local vuhdo     = Frames:VuhDoFrames()
    local danders   = Frames:DandersFrames()
    for _, f in ipairs(blizzard) do all[#all + 1] = f end
    for _, f in ipairs(elvui)    do all[#all + 1] = f end
    for _, f in ipairs(grid2)    do all[#all + 1] = f end
    for _, f in ipairs(vuhdo)    do all[#all + 1] = f end
    for _, f in ipairs(danders)  do all[#all + 1] = f end
    return all
end

-- Returns the raid/party frame for the given unit token, or nil
function Frames:GetFrameForUnit(unit)
    if not unit then return nil end
    for _, f in ipairs(Frames:GetAll()) do
        if f.unit and UnitIsUnit(f.unit, unit) then return f end
    end
    return nil
end

-- =====================================================================
-- SECTION 11: Display — Shared helpers
-- =====================================================================

local function GetBarTexture()
    if LSM then
        local t = LSM:Fetch("statusbar", "Melli")
        if t then return t end
    end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

local function GetClassColor(classToken)
    if classToken then
        local c = C_ClassColor and C_ClassColor.GetClassColor(classToken)
        if c then return c.r, c.g, c.b end
    end
    return 0.6, 0.6, 0.6
end

local function FormatTime(remaining)
    if remaining >= 60 then
        return string.format("%dm", math.floor(remaining / 60))
    elseif remaining >= 10 then
        return string.format("%ds", math.floor(remaining))
    else
        return string.format("%.1f", remaining)
    end
end

-- =====================================================================
-- SECTION 12: Display — Bar Mode
-- =====================================================================

local barContainer = nil
local barPool = {}
local barActive = {}   -- ordered list of active bars

local function CreateBarWidget()
    local bar = CreateFrame("Frame", nil, barContainer)
    bar:SetHeight(DB.barHeight)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(GetBarTexture())
    bg:SetVertexColor(0, 0, 0, 0.5)
    bar.bg = bg
    local fill = bar:CreateTexture(nil, "BORDER")
    fill:SetTexture(GetBarTexture())
    fill:SetPoint("LEFT")
    fill:SetPoint("TOP")
    fill:SetPoint("BOTTOM")
    bar.fill = fill
    local icon = CreateFrame("Frame", nil, bar)
    icon:SetSize(DB.barHeight - 2, DB.barHeight - 2)
    icon:SetPoint("LEFT", bar, "LEFT", 1, 0)
    local iconTex = icon:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints()
    iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.tex = iconTex
    bar.icon = icon
    local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    nameText:SetPoint("RIGHT", bar, "RIGHT", -40, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetHeight(DB.barHeight)
    bar.nameText = nameText
    local timerText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    timerText:SetWidth(36)
    timerText:SetJustifyH("RIGHT")
    bar.timerText = timerText
    bar:Hide()
    return bar
end

local function InitBarContainer()
    if barContainer then return end
    barContainer = CreateFrame("Frame", "InfinityFCDBarContainer", UIParent)
    barContainer:SetSize(DB.barWidth, DB.barHeight)
    barContainer:SetClampedToScreen(true)
    barContainer:EnableMouse(not DB.barLocked)
    barContainer:SetMovable(not DB.barLocked)
    if not DB.barLocked then
        barContainer:RegisterForDrag("LeftButton")
        barContainer:SetScript("OnDragStart", function(f) f:StartMoving() end)
        barContainer:SetScript("OnDragStop", function(f)
            f:StopMovingOrSizing()
            local p, _, rp, x, y = f:GetPoint()
            DB.barPos = { p, "UIParent", rp, x, y }
        end)
    end
    local pos = DB.barPos
    if pos then
        barContainer:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5])
    else
        barContainer:SetPoint("CENTER", UIParent, "CENTER", -400, 0)
    end

    -- Reset button handler
    if InfinityTools.GetModuleDB then
        -- wired via settings button
    end
end

local function AcquireBar()
    local bar = table.remove(barPool)
    if not bar then bar = CreateBarWidget() end
    bar:Show()
    return bar
end

local function ReleaseBar(bar)
    bar:Hide()
    barPool[#barPool + 1] = bar
end

local function RebuildBars()
    if not barContainer then return end
    for _, bar in ipairs(barActive) do ReleaseBar(bar) end
    barActive = {}

    -- Collect all active CDs sorted by remaining time (descending = most recently used)
    local list = {}
    local now = GetTime()
    for unit, cds in pairs(activeCDs) do
        for cdKey, cdData in pairs(cds) do
            local elapsed = now - cdData.StartTime
            local remaining = cdData.Cooldown - elapsed
            if remaining > 0 then
                list[#list + 1] = {
                    unit = unit,
                    cdKey = cdKey,
                    data = cdData,
                    remaining = remaining,
                    elapsed = elapsed,
                }
            end
        end
    end
    table.sort(list, function(a, b) return a.elapsed < b.elapsed end) -- most recently used first

    local maxBars = DB.barMaxBars
    local count = math.min(#list, maxBars)
    local barH = DB.barHeight
    local spacing = DB.barSpacing
    local growDown = DB.barGrowDown
    local totalH = count * barH + math.max(0, count - 1) * spacing
    barContainer:SetHeight(math.max(totalH, 1))
    barContainer:SetWidth(DB.barWidth)

    for i = 1, count do
        local entry = list[i]
        local bar = AcquireBar()
        bar:SetWidth(DB.barWidth)
        bar:SetHeight(barH)
        bar:ClearAllPoints()
        local yOff = (i - 1) * (barH + spacing)
        if growDown then
            bar:SetPoint("TOPLEFT", barContainer, "TOPLEFT", 0, -yOff)
        else
            bar:SetPoint("BOTTOMLEFT", barContainer, "BOTTOMLEFT", 0, yOff)
        end

        local cd = entry.data
        local pct = entry.remaining / cd.Cooldown
        bar.fill:SetPoint("RIGHT", bar, "LEFT", DB.barWidth * (1 - pct), 0)

        local r, g, b = 0.5, 0.5, 0.5
        if DB.barUseClassColor and cd.Class then r, g, b = GetClassColor(cd.Class) end
        bar.fill:SetVertexColor(r, g, b, 1)

        if DB.barShowIcon and cd.SpellIcon then
            bar.icon:Show()
            bar.icon:SetSize(barH - 2, barH - 2)
            bar.icon.tex:SetTexture(cd.SpellIcon)
        else
            bar.icon:Hide()
        end

        local nameStr = ""
        if DB.barShowName and cd.UnitName then nameStr = cd.UnitName .. " " end
        if DB.barShowSpell and cd.SpellId then
            local si = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(cd.SpellId)
            if si then nameStr = nameStr .. si.name end
        end
        bar.nameText:SetText(nameStr)

        if DB.barShowTimer then
            bar.timerText:SetText(FormatTime(entry.remaining))
        else
            bar.timerText:SetText("")
        end

        barActive[#barActive + 1] = bar
    end
end

-- =====================================================================
-- SECTION 13: Display — Icon Mode
-- =====================================================================

local iconContainer = nil
local iconPool = {}
local iconActive = {}

local function CreateIconWidget()
    local ic = CreateFrame("Frame", nil, iconContainer)
    local sz = DB.iconSize
    ic:SetSize(sz, sz + (DB.iconShowName and 12 or 0) + (DB.iconShowTimer and 12 or 0))
    local tex = ic:CreateTexture(nil, "ARTWORK")
    tex:SetSize(sz, sz)
    tex:SetPoint("TOP")
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    ic.tex = tex
    -- Cooldown swipe
    local cd = CreateFrame("Cooldown", nil, ic, "CooldownFrameTemplate")
    cd:SetAllPoints(tex)
    cd:SetDrawEdge(false)
    ic.cooldown = cd
    local nameLabel = ic:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOP", tex, "BOTTOM", 0, 0)
    nameLabel:SetWidth(sz)
    nameLabel:SetJustifyH("CENTER")
    ic.nameLabel = nameLabel
    local timerLabel = ic:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timerLabel:SetPoint("TOP", nameLabel, "BOTTOM", 0, 0)
    timerLabel:SetWidth(sz)
    timerLabel:SetJustifyH("CENTER")
    ic.timerLabel = timerLabel
    ic:Hide()
    return ic
end

local function InitIconContainer()
    if iconContainer then return end
    iconContainer = CreateFrame("Frame", "InfinityFCDIconContainer", UIParent)
    iconContainer:SetSize(DB.iconSize, DB.iconSize)
    iconContainer:SetClampedToScreen(true)
    iconContainer:EnableMouse(not DB.iconLocked)
    iconContainer:SetMovable(not DB.iconLocked)
    if not DB.iconLocked then
        iconContainer:RegisterForDrag("LeftButton")
        iconContainer:SetScript("OnDragStart", function(f) f:StartMoving() end)
        iconContainer:SetScript("OnDragStop", function(f)
            f:StopMovingOrSizing()
            local p, _, rp, x, y = f:GetPoint()
            DB.iconPos = { p, "UIParent", rp, x, y }
        end)
    end
    local pos = DB.iconPos
    if pos then
        iconContainer:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5])
    else
        iconContainer:SetPoint("CENTER", UIParent, "CENTER", -400, 100)
    end
end

local function AcquireIcon()
    local ic = table.remove(iconPool)
    if not ic then ic = CreateIconWidget() end
    ic:Show()
    return ic
end

local function ReleaseIcon(ic)
    ic:Hide()
    iconPool[#iconPool + 1] = ic
end

local function RebuildIcons()
    if not iconContainer then return end
    for _, ic in ipairs(iconActive) do ReleaseIcon(ic) end
    iconActive = {}

    local list = {}
    local now = GetTime()
    for unit, cds in pairs(activeCDs) do
        for cdKey, cdData in pairs(cds) do
            local remaining = cdData.Cooldown - (now - cdData.StartTime)
            if remaining > 0 then
                list[#list + 1] = { data = cdData, remaining = remaining }
            end
        end
    end
    table.sort(list, function(a, b) return a.remaining < b.remaining end)

    local sz = DB.iconSize
    local cols = DB.iconCols
    local spacing = DB.iconSpacing
    local rowH = sz + (DB.iconShowName and 12 or 0) + (DB.iconShowTimer and 12 or 0) + spacing
    local colW = sz + spacing
    local rows = math.ceil(#list / cols)
    iconContainer:SetSize(cols * colW, rows * rowH)

    for i, entry in ipairs(list) do
        local ic = AcquireIcon()
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        ic:ClearAllPoints()
        ic:SetPoint("TOPLEFT", iconContainer, "TOPLEFT", col * colW, -row * rowH)
        ic.tex:SetTexture(entry.data.SpellIcon)
        -- Cooldown swipe
        if entry.data.Cooldown and entry.data.StartTime then
            ic.cooldown:SetCooldown(entry.data.StartTime, entry.data.Cooldown)
        end
        if DB.iconShowName then
            ic.nameLabel:SetText(entry.data.UnitName or "")
        else
            ic.nameLabel:SetText("")
        end
        if DB.iconShowTimer then
            ic.timerLabel:SetText(FormatTime(entry.remaining))
        else
            ic.timerLabel:SetText("")
        end
        iconActive[#iconActive + 1] = ic
    end
end

-- =====================================================================
-- SECTION 14: Display — Attached Mode
-- =====================================================================

-- attachedContainers[unit] = Frame (anchored to unit's raid frame)
local attachedContainers = {}
local attachedIconPools = {}

local function GetOrCreateAttachedContainer(unit)
    if attachedContainers[unit] then return attachedContainers[unit] end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetSize(DB.attachIconSize, DB.attachIconSize)
    f:SetFrameStrata("HIGH")
    attachedContainers[unit] = f
    return f
end

local function AnchorAttachedContainer(container, raidFrame)
    container:ClearAllPoints()
    local side = DB.attachSide or "RIGHT"
    local ox = DB.attachOffsetX or 2
    local oy = DB.attachOffsetY or 0
    if side == "RIGHT" then
        container:SetPoint("LEFT", raidFrame, "RIGHT", ox, oy)
    elseif side == "LEFT" then
        container:SetPoint("RIGHT", raidFrame, "LEFT", -ox, oy)
    elseif side == "ABOVE" then
        container:SetPoint("BOTTOM", raidFrame, "TOP", ox, oy)
    elseif side == "BELOW" then
        container:SetPoint("TOP", raidFrame, "BOTTOM", ox, -oy)
    end
    container:Show()
end

local function RebuildAttached()
    local now = GetTime()
    local iconSz = DB.attachIconSize
    local spacing = DB.attachSpacing

    for unit, container in pairs(attachedContainers) do
        -- Release existing icons
        for _, ic in ipairs(container.icons or {}) do
            ic:Hide()
        end
        container.icons = {}

        local raidFrame = Frames:GetFrameForUnit(unit)
        if raidFrame and raidFrame:IsVisible() then
            AnchorAttachedContainer(container, raidFrame)
        else
            container:Hide()
        end
    end

    -- Iterate active CDs per unit
    for unit, cds in pairs(activeCDs) do
        local list = {}
        for cdKey, cdData in pairs(cds) do
            local remaining = cdData.Cooldown - (now - cdData.StartTime)
            if remaining > 0 then list[#list + 1] = { data = cdData, remaining = remaining } end
        end

        if #list > 0 then
            local raidFrame = Frames:GetFrameForUnit(unit)
            if raidFrame and raidFrame:IsVisible() then
                local container = GetOrCreateAttachedContainer(unit)
                AnchorAttachedContainer(container, raidFrame)

                table.sort(list, function(a, b) return a.remaining < b.remaining end)

                local side = DB.attachSide or "RIGHT"
                local isVertical = side == "ABOVE" or side == "BELOW"
                local n = #list
                if isVertical then
                    container:SetSize(n * iconSz + math.max(0, n - 1) * spacing, iconSz)
                else
                    container:SetSize(iconSz, n * iconSz + math.max(0, n - 1) * spacing)
                end

                container.icons = container.icons or {}
                for i, entry in ipairs(list) do
                    local ic = container.icons[i]
                    if not ic then
                        ic = CreateFrame("Frame", nil, container)
                        ic:SetSize(iconSz, iconSz)
                        local tex = ic:CreateTexture(nil, "ARTWORK")
                        tex:SetAllPoints()
                        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                        ic.tex = tex
                        local cd = CreateFrame("Cooldown", nil, ic, "CooldownFrameTemplate")
                        cd:SetAllPoints()
                        cd:SetDrawEdge(false)
                        ic.cooldown = cd
                        container.icons[i] = ic
                    end
                    ic:Show()
                    ic:SetSize(iconSz, iconSz)
                    ic:ClearAllPoints()
                    if isVertical then
                        ic:SetPoint("LEFT", container, "LEFT", (i - 1) * (iconSz + spacing), 0)
                    else
                        ic:SetPoint("TOP", container, "TOP", 0, -(i - 1) * (iconSz + spacing))
                    end
                    ic.tex:SetTexture(entry.data.SpellIcon)
                    if entry.data.Cooldown and entry.data.StartTime then
                        ic.cooldown:SetCooldown(entry.data.StartTime, entry.data.Cooldown)
                    end
                end
            end
        end
    end
end

-- =====================================================================
-- SECTION 15: Module — Roster management
-- =====================================================================

local activeEntries = {}   -- unit -> entry

local function CreateEntry(unit)
    return {
        Unit = unit,
        TrackedAuras = {},
        ActiveCooldowns = activeCDs[unit] or {},
    }
end

local function BuildRoster()
    local newUnits = {}

    -- Always include player if desired
    if DB.showPlayer then
        newUnits["player"] = true
    end

    if IsInRaid() then
        local n = GetNumGroupMembers()
        for i = 1, n do
            newUnits["raid" .. i] = true
        end
    else
        local n = GetNumGroupMembers()
        for i = 1, n do
            newUnits["party" .. i] = true
        end
    end

    -- Remove entries no longer in group
    for unit, entry in pairs(activeEntries) do
        if not newUnits[unit] then
            Observer:Unwatch(entry)
            activeEntries[unit] = nil
        end
    end

    -- Add new entries
    for unit in pairs(newUnits) do
        if not activeEntries[unit] and UnitExists(unit) then
            local entry = CreateEntry(unit)
            activeEntries[unit] = entry
            Observer:Watch(entry)
            QueueInspect(unit)
        end
    end

    -- Update active cooldowns reference in entries
    for unit, entry in pairs(activeEntries) do
        entry.ActiveCooldowns = activeCDs[unit] or {}
    end
end

local function OnDisplayRefresh()
    -- Update timer texts on existing bars/icons without full rebuild for performance
    local now = GetTime()
    for _, bar in ipairs(barActive) do
        if bar.cdData then
            local remaining = bar.cdData.Cooldown - (now - bar.cdData.StartTime)
            if remaining < 0 then remaining = 0 end
            local pct = remaining / bar.cdData.Cooldown
            bar.fill:SetPoint("RIGHT", bar, "LEFT", DB.barWidth * (1 - pct), 0)
            if DB.barShowTimer then bar.timerText:SetText(FormatTime(remaining)) end
        end
    end
    for _, ic in ipairs(iconActive) do
        if ic.cdData and DB.iconShowTimer then
            local remaining = ic.cdData.Cooldown - (now - ic.cdData.StartTime)
            if remaining < 0 then remaining = 0 end
            ic.timerLabel:SetText(FormatTime(remaining))
        end
    end
end

-- =====================================================================
-- SECTION 16: Preview mode
-- =====================================================================

local function SetupPreview()
    -- Inject fake cooldowns for preview
    local fakeCDs = {
        { unit = "player", cdKey = 642, SpellId = 642, Cooldown = 300, StartTime = GetTime() - 10, UnitName = "Paladin", Class = "PALADIN" },
        { unit = "party1", cdKey = 871, SpellId = 871, Cooldown = 180, StartTime = GetTime() - 20, UnitName = "Warrior", Class = "WARRIOR" },
        { unit = "party2", cdKey = 186265, SpellId = 186265, Cooldown = 180, StartTime = GetTime() - 5, UnitName = "Hunter", Class = "HUNTER" },
        { unit = "party3", cdKey = 198589, SpellId = 198589, Cooldown = 60, StartTime = GetTime() - 30, UnitName = "DHunter", Class = "DEMONHUNTER" },
    }
    wipe(activeCDs)
    for _, fcd in ipairs(fakeCDs) do
        activeCDs[fcd.unit] = activeCDs[fcd.unit] or {}
        fcd.SpellIcon = GetSpellIcon(fcd.SpellId)
        activeCDs[fcd.unit][fcd.cdKey] = fcd
    end
end

local function ClearPreview()
    wipe(activeCDs)
end

-- =====================================================================
-- SECTION 17: Main event frame + update loop
-- =====================================================================

local eventFrame = CreateFrame("Frame")
local updateThrottle = 0
local UPDATE_INTERVAL = 0.1  -- refresh display every 100ms

eventFrame:SetScript("OnUpdate", function(_, elapsed)
    updateThrottle = updateThrottle + elapsed
    if updateThrottle < UPDATE_INTERVAL then return end
    updateThrottle = 0

    if DB.barEnabled and barContainer then
        RebuildBars()
    end
    if DB.iconEnabled and iconContainer then
        RebuildIcons()
    end
    if DB.attachEnabled then
        RebuildAttached()
    end
end)

eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("INSPECT_READY")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, BuildRoster)
    elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        RefreshPlayerTalents()
        -- Re-watch player entry to refresh spec
        local entry = activeEntries["player"]
        if entry then
            Observer:Rewatch(entry)
        end
    end
end)

-- Button handlers wired to settings panel
InfinityTools:RegisterModuleCallback(INFINITY_MODULE_KEY, "btn_reset_bar", function()
    if barContainer then
        barContainer:ClearAllPoints()
        barContainer:SetPoint("CENTER", UIParent, "CENTER", -400, 0)
        DB.barPos = { "CENTER", "UIParent", "CENTER", -400, 0 }
    end
end)

InfinityTools:RegisterModuleCallback(INFINITY_MODULE_KEY, "btn_reset_icon", function()
    if iconContainer then
        iconContainer:ClearAllPoints()
        iconContainer:SetPoint("CENTER", UIParent, "CENTER", -400, 100)
        DB.iconPos = { "CENTER", "UIParent", "CENTER", -400, 100 }
    end
end)

-- =====================================================================
-- SECTION 18: Initialization
-- =====================================================================

local function Init()
    RefreshPlayerTalents()

    -- Initialize display containers
    if DB.barEnabled then InitBarContainer() end
    if DB.iconEnabled then InitIconContainer() end

    -- Preview mode
    if DB.barPreview or DB.iconPreview then
        SetupPreview()
    end

    -- Build roster
    BuildRoster()

    -- Start the update loop
    eventFrame:Show()
end

-- Initialize on PLAYER_LOGIN (everything is available)
do
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function()
        initFrame:UnregisterAllEvents()
        Init()
    end)
end
