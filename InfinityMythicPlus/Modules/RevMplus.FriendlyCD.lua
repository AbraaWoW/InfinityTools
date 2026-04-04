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
        { key = "showOffensive", type = "checkbox", x = 10, y = 9, w = 15, h = 2, label = "Show Offensive CDs" },
        { key = "showPlayer", type = "checkbox", x = 27, y = 9, w = 12, h = 2, label = "Track Self" },
        { key = "autoSwitchMode", type = "checkbox", x = 1, y = 11, w = 45, h = 2, label = "Auto-switch mode on group change (Party → Attached, Raid → Bars)" },

        -- Bar Mode
        { key = "bar_header", type = "header", x = 1, y = 13, w = 53, h = 2, label = "Bar Mode", labelSize = 20 },
        { key = "barEnabled", type = "checkbox", x = 1, y = 16, w = 8, h = 2, label = "Enable" },
        { key = "barLocked", type = "checkbox", x = 12, y = 16, w = 8, h = 2, label = L["Lock Position"] },
        { key = "barPreview", type = "checkbox", x = 22, y = 16, w = 8, h = 2, label = L["Preview Mode"] },
        { key = "barWidth", type = "slider", x = 1, y = 19, w = 17, h = 2, label = "Bar Width", min = 100, max = 500 },
        { key = "barHeight", type = "slider", x = 20, y = 19, w = 15, h = 2, label = "Bar Height", min = 12, max = 48 },
        { key = "barSpacing", type = "slider", x = 1, y = 22, w = 17, h = 2, label = "Spacing", min = 0, max = 20 },
        { key = "barMaxBars", type = "slider", x = 20, y = 22, w = 15, h = 2, label = "Max Bars", min = 1, max = 40 },
        { key = "barGrowDown", type = "checkbox", x = 1, y = 25, w = 12, h = 2, label = "Grow Downward" },
        { key = "barUseClassColor", type = "checkbox", x = 15, y = 25, w = 12, h = 2, label = "Class Colors" },
        { key = "barShowIcon", type = "checkbox", x = 29, y = 25, w = 10, h = 2, label = "Show Icon" },
        { key = "barShowName", type = "checkbox", x = 1, y = 28, w = 10, h = 2, label = "Show Name" },
        { key = "barShowTimer", type = "checkbox", x = 29, y = 28, w = 10, h = 2, label = "Show Timer" },
        { key = "bar_win_header", type = "subheader", x = 1, y = 31, w = 53, h = 1, label = "Windows", labelSize = 16 },
        { key = "barExtEnabled", type = "checkbox", x = 1, y = 33, w = 18, h = 2, label = "External Defensive" },
        { key = "btn_reset_bar_ext", type = "button", x = 22, y = 33, w = 14, h = 2, label = L["Reset Position"] },
        { key = "barBigEnabled", type = "checkbox", x = 1, y = 36, w = 18, h = 2, label = "Big Defensive" },
        { key = "btn_reset_bar_big", type = "button", x = 22, y = 36, w = 14, h = 2, label = L["Reset Position"] },
        { key = "barImpEnabled", type = "checkbox", x = 1, y = 39, w = 18, h = 2, label = "Important" },
        { key = "btn_reset_bar_imp", type = "button", x = 22, y = 39, w = 14, h = 2, label = L["Reset Position"] },
        { key = "barOffEnabled", type = "checkbox", x = 1, y = 42, w = 18, h = 2, label = "Offensive" },
        { key = "btn_reset_bar_off", type = "button", x = 22, y = 42, w = 14, h = 2, label = L["Reset Position"] },

        -- Icon Mode
        { key = "icon_header", type = "header", x = 1, y = 46, w = 53, h = 2, label = "Icon Mode", labelSize = 20 },
        { key = "iconEnabled", type = "checkbox", x = 1, y = 49, w = 8, h = 2, label = "Enable" },
        { key = "iconLocked", type = "checkbox", x = 12, y = 49, w = 8, h = 2, label = L["Lock Position"] },
        { key = "iconPreview", type = "checkbox", x = 22, y = 49, w = 8, h = 2, label = L["Preview Mode"] },
        { key = "btn_reset_icon", type = "button", x = 33, y = 49, w = 14, h = 2, label = L["Reset Position"] },
        { key = "iconSize", type = "slider", x = 1, y = 52, w = 17, h = 2, label = "Icon Size", min = 16, max = 64 },
        { key = "iconCols", type = "slider", x = 20, y = 52, w = 15, h = 2, label = "Per Row", min = 1, max = 20 },
        { key = "iconSpacing", type = "slider", x = 37, y = 52, w = 14, h = 2, label = "Spacing", min = 0, max = 16 },
        { key = "iconShowName", type = "checkbox", x = 1, y = 55, w = 15, h = 2, label = "Show Player Name" },
        { key = "iconShowTimer", type = "checkbox", x = 18, y = 55, w = 12, h = 2, label = "Show Timer" },

        -- Attached Mode
        { key = "attach_header", type = "header", x = 1, y = 60, w = 53, h = 2, label = "Attached Mode (Raid Frames)", labelSize = 20 },
        { key = "attachEnabled", type = "checkbox", x = 1, y = 63, w = 10, h = 2, label = "Enable" },
        { key = "attachSide", type = "dropdown", x = 14, y = 63, w = 14, h = 2, label = "Position", items = "RIGHT,LEFT,TOP,DOWN" },
        { key = "attachIconSize", type = "slider", x = 30, y = 63, w = 17, h = 2, label = "Icon Size", min = 12, max = 48 },
        { key = "attachOffsetX", type = "slider", x = 1, y = 66, w = 17, h = 2, label = "Offset X", min = -100, max = 100 },
        { key = "attachOffsetY", type = "slider", x = 20, y = 66, w = 17, h = 2, label = "Offset Y", min = -100, max = 100 },
        { key = "attachSpacing", type = "slider", x = 39, y = 66, w = 14, h = 2, label = "Spacing", min = 0, max = 16 },
        { key = "attachCols", type = "slider", x = 1, y = 69, w = 17, h = 2, label = "Per Row", min = 1, max = 8 },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =====================================================================
-- SECTION 2: DB Defaults
-- =====================================================================

local MODULE_DEFAULTS = {
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
    barShowTimer = true,
    barExtEnabled = true,
    barBigEnabled = true,
    barImpEnabled = true,
    barOffEnabled = false,
    barExtPos = { "CENTER", "UIParent", "CENTER", -500,  150 },
    barBigPos = { "CENTER", "UIParent", "CENTER", -500,   50 },
    barImpPos = { "CENTER", "UIParent", "CENTER", -500,  -50 },
    barOffPos = { "CENTER", "UIParent", "CENTER", -500, -150 },

    iconEnabled = false,
    iconLocked = false,
    iconPreview = false,
    iconSize = 32,
    iconCols = 5,
    iconSpacing = 4,
    iconShowName = true,
    iconShowTimer = true,
    iconPos = { "CENTER", "UIParent", "CENTER", -400, 100 },

    autoSwitchMode = true,

    attachEnabled = false,
    attachSide = "RIGHT",
    attachIconSize = 20,
    attachOffsetX = 2,
    attachOffsetY = 0,
    attachSpacing = 2,
    attachCols = 5,
}

local DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =====================================================================
-- SECTION 3: Rules (ported from MiniCC — Jaliborc)
-- =====================================================================

local Rules = {}

Rules.BySpec = {
    [65] = { -- Holy Paladin
        { BuffDuration = 12, Cooldown = 120, Important = true,  BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 31884, MinDuration = true, ExcludeIfTalent = 216331 }, -- Avenging Wrath
        { BuffDuration = 10, Cooldown = 60,  Important = true,  BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 216331, MinDuration = true, RequiresTalent = 216331 }, -- Avenging Crusader
        { BuffDuration = 8,  Cooldown = 300, BigDefensive = true,  ExternalDefensive = false, Important = true,  RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 }, -- Divine Shield
        { BuffDuration = 8,  Cooldown = 60,  BigDefensive = true,  Important = true,  ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 498 }, -- Divine Protection
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692, DirectCast = true }, -- Blessing of Spellwarding
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022,   ExcludeIfTalent = 5692, DirectCast = true }, -- Blessing of Protection
        { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true,  BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940,   DirectCast = true }, -- Blessing of Sacrifice
        { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true,  BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 31884,  DirectCast = true }, -- Avenging Wrath (external)
        { BuffDuration = 8,  Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 31821,  ExcludeIfTalent = 392911, DirectCast = true }, -- Aura Mastery
        { BuffDuration = 8,  Cooldown = 150, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 31821,  RequiresTalent = 392911,  DirectCast = true }, -- Aura Mastery (Unwavering Spirit)
    },
    [66] = { -- Protection Paladin
        { BuffDuration = 25, Cooldown = 120, Important = true,  ExternalDefensive = false, BigDefensive = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 31884, ExcludeIfTalent = 389539 }, -- Avenging Wrath
        { BuffDuration = 20, Cooldown = 120, Important = true,  ExternalDefensive = false, BigDefensive = false, MinDuration = true, RequiresEvidence = "Cast", SpellId = 389539, RequiresTalent = 389539, ExcludeIfTalent = 31884 }, -- Sentinel
        { BuffDuration = 8,  Cooldown = 300, BigDefensive = true,  ExternalDefensive = false, Important = true,  RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 }, -- Divine Shield
        { BuffDuration = 8,  Cooldown = 90,  BigDefensive = true,  Important = true,  ExternalDefensive = false, SpellId = 31850, RequiresEvidence = "Cast" }, -- Ardent Defender
        { BuffDuration = 8,  Cooldown = 180, BigDefensive = true,  Important = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 86659 }, -- Guardian of Ancient Kings
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692, DirectCast = true },
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022,   ExcludeIfTalent = 5692, DirectCast = true },
        { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true,  BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940,   DirectCast = true },
    },
    [70] = { -- Retribution Paladin
        { BuffDuration = 24, Cooldown = 60,  Important = true,  ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 31884, ExcludeIfTalent = 458359 }, -- Avenging Wrath
        { BuffDuration = 8,  Cooldown = 300, BigDefensive = true,  ExternalDefensive = false, Important = true,  RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 },
        { BuffDuration = 8,  Cooldown = 90,  Important = true,  ExternalDefensive = false, BigDefensive = false, RequiresEvidence = { "Cast", "Shield" }, SpellId = 403876 }, -- Divine Protection (Ret)
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692, DirectCast = true },
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022,   ExcludeIfTalent = 5692, DirectCast = true },
        { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true,  BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 6940,   DirectCast = true },
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
    [257] = { -- Holy Priest
        { BuffDuration = 10,  Cooldown = 180, ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 47788, ExcludeIfTalent = 200209, DirectCast = true }, -- Guardian Spirit
        { BuffDuration = 10,  Cooldown = 70,  ExternalDefensive = true,  BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 47788, RequiresTalent = 200209,  DirectCast = true }, -- Guardian Spirit (Guardian Angel)
        { BuffDuration = 20, Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 200183, DirectCast = true }, -- Apotheosis
        { BuffDuration = 5,   Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 64843, ExcludeIfTalent = 419110, DirectCast = true }, -- Divine Hymn
        { BuffDuration = 5,   Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true,  CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 64843, RequiresTalent = 419110,  DirectCast = true }, -- Divine Hymn (Seraphic Crescendo)
    },
    [258] = { -- Shadow Priest
        { BuffDuration = 6, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = true, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 47585 }, -- Dispersion
        { BuffDuration = 20, Cooldown = 120, Important = true, ExternalDefensive = false, BigDefensive = false, RequiresEvidence = "Cast", SpellId = 228260 }, -- Voidform
    },
    [259] = { -- Discipline Priest
        { BuffDuration = 0,  Cooldown = 90,  ExternalDefensive = false, BigDefensive = false, Important = true,  CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 472433, DirectCast = true }, -- Evangelism
        { BuffDuration = 1,  Cooldown = 240, ExternalDefensive = false, BigDefensive = false, Important = true,  CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 421453, DirectCast = true }, -- Ultimate Penitence
        { BuffDuration = 10, Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 62618,  DirectCast = true }, -- Power Word: Barrier
        { BuffDuration = 8,  Cooldown = 180, ExternalDefensive = true,  BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 33206,  DirectCast = true }, -- Pain Suppression
    },
    [102] = { { BuffDuration = 20, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 102560 } }, -- Incarnation Balance
    [103] = { -- Feral Druid
        { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 106951, RequiresTalent = 106951, ExcludeIfTalent = 102543 }, -- Berserk
        { BuffDuration = 20, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 102543, RequiresTalent = 102543 }, -- Incarnation Feral
    },
    [104] = { { BuffDuration = 30, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 102558 } }, -- Incarnation Guardian
    [105] = { -- Restoration Druid
        { BuffDuration = 12, Cooldown = 90,  ExternalDefensive = true,  BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 102342, DirectCast = true }, -- Ironbark
        { BuffDuration = 8,  Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 740, ExcludeIfTalent = 197073, DirectCast = true }, -- Tranquility
        { BuffDuration = 8,  Cooldown = 150, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 740, RequiresTalent = 197073,  DirectCast = true }, -- Tranquility (Inner Peace)
        { BuffDuration = 4,  Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 391528, ExcludeIfTalent = 393371, DirectCast = true }, -- Convoke the Spirits
        { BuffDuration = 3,  Cooldown = 60,  ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 391528, RequiresTalent = 393371,  DirectCast = true }, -- Convoke the Spirits (Cenarius' Guidance)
        { BuffDuration = 30, Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 33891, ExcludeIfTalent = 393371, DirectCast = true }, -- Incarnation: Tree of Life
        { BuffDuration = 30, Cooldown = 150, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 33891, RequiresTalent = 393371,  DirectCast = true }, -- Incarnation: Tree of Life (Cenarius' Guidance)
    },
    [268] = { -- Brewmaster Monk
        { BuffDuration = 25, Cooldown = 100, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 132578, DirectCast = true }, -- Invoke Niuzao
        { BuffDuration = 15, Cooldown = 420, BigDefensive = true, Important = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 115203 }, -- Fortifying Brew
        { BuffDuration = 15, Cooldown = 45, BigDefensive = true, Important = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 1241059, DirectCast = true }, -- Celestial Infusion
    },
    [269] = { -- Mistweaver Monk
        { BuffDuration = 1,  Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 115310, ExcludeIfTalent = 388551, DirectCast = true }, -- Revival
        { BuffDuration = 1,  Cooldown = 150, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 115310, RequiresTalent = 388551, DirectCast = true },  -- Revival (Uplifted Spirits)
        { BuffDuration = 12,  Cooldown = 60, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 322118, ExcludeIfTalent = 388212, DirectCast = true }, -- Invoke Yu'lon, the Jade Serpent
        { BuffDuration = 12,  Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 322118, RequiresTalent = 388212, DirectCast = true },  -- Invoke Yu'lon, the Jade Serpent (Gift of the Celestials)
        { BuffDuration = 12,  Cooldown = 60, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 325197, ExcludeIfTalent = 388212, DirectCast = true }, -- Invoke Chi-Ji, the Red Crane
        { BuffDuration = 12,  Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 325197, RequiresTalent = 388212, DirectCast = true },  -- Invoke Chi-Ji, the Red Crane (Gift of the Celestials)
    },
    [270] = { { BuffDuration = 12, Cooldown = 120, ExternalDefensive = true, BigDefensive = false, Important = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 116849, DirectCast = true } }, -- Life Cocoon
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
    [1467] = { -- Devastation Evoker
        { BuffDuration = 18, Cooldown = 120, Important = true,  BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 375087 }, -- Dragonrage
        { BuffDuration = 20, Cooldown = 120, Important = true,  BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", MinDuration = true, SpellId = 375087, RequiresTalent = 406732 }, -- Dragonrage (Tyranny)
    },
    [1468] = { -- Preservation Evoker
        { BuffDuration = 8,  Cooldown = 60,  ExternalDefensive = true,  BigDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 357170, DirectCast = true }, -- Time Dilation
        { BuffDuration = 2,  Cooldown = 240, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 363534, DirectCast = true }, -- Rewind
        { BuffDuration = 2,  Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 363534, RequiresTalent = 370979, DirectCast = true }, -- Rewind (Temporal Compression)
        { BuffDuration = 15, Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 359816, DirectCast = true }, -- Dream Flight
        { BuffDuration = 15, Cooldown = 90,  ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, SpellId = 370537, DirectCast = true }, -- Stasis
    },
    [1473] = { -- Augmentation Evoker
        { BuffDuration = 13.4, Cooldown = 90,  BigDefensive = true,  ExternalDefensive = false, Important = true,  RequiresEvidence = "Cast", MinDuration = true, SpellId = 363916 }, -- Obsidian Scales
        { BuffDuration = 6,    Cooldown = 120, BigDefensive = false, ExternalDefensive = false, Important = true,  RequiresEvidence = "Cast", MinDuration = true, SpellId = 403631 }, -- Breath of Eons
    },
    [262] = { -- Elemental Shaman
        { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114050, RequiresTalent = 114050 },
        { BuffDuration = 18, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114050, RequiresTalent = 114050 },
    },
    [263] = { -- Enhancement Shaman
        { BuffDuration = 8, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 384352, RequiresTalent = 384352, ExcludeIfTalent = { 114051, 378270 } }, -- Doomwinds
        { BuffDuration = 10, Cooldown = 60, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 384352, RequiresTalent = 384352, ExcludeIfTalent = { 114051, 378270 } },
        { BuffDuration = 15, Cooldown = 180, Important = true, BigDefensive = false, ExternalDefensive = false, RequiresEvidence = "Cast", SpellId = 114051, RequiresTalent = 114051 }, -- Ascendance
    },
    [264] = { -- restoration Shaman
        { BuffDuration = 6, Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 98008, DirectCast = true }, -- Spirit Link Totem
        { BuffDuration = 10,  Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 108280, ExcludeIfTalent = 462440, DirectCast = true }, -- Healing Tide Totem
        { BuffDuration = 10,  Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 108280, RequiresTalent = 462440, DirectCast = true },  -- Healing Tide Totem (First Ascendant)
        { BuffDuration = 15,  Cooldown = 180, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 114052, ExcludeIfTalent = 462440, DirectCast = true }, -- Ascendance
        { BuffDuration = 15,  Cooldown = 120, ExternalDefensive = false, BigDefensive = false, Important = true,  RequiresEvidence = "Cast", SpellId = 114052, RequiresTalent = 462440, DirectCast = true },  -- Ascendance (First Ascendant)
    },
}
Rules.ByClass = {
    PALADIN = {
        { BuffDuration = 8, Cooldown = 300, BigDefensive = true, Important = true, ExternalDefensive = false, RequiresEvidence = { "Cast", "Debuff", "UnitFlags" }, CanCancelEarly = true, SpellId = 642 }, -- Divine Shield
        { BuffDuration = 8, Cooldown = 25, Important = true, ExternalDefensive = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1044 }, -- Blessing of Freedom
        { BuffDuration = 10, Cooldown = 45,  ExternalDefensive = true, Important = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 204018, RequiresTalent = 5692,  DirectCast = true },
        { BuffDuration = 10, Cooldown = 300, ExternalDefensive = true, Important = false, BigDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 1022,   ExcludeIfTalent = 5692, DirectCast = true },
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
        { BuffDuration = 12, Cooldown = 120, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 108271, DirectCast = true }, -- Astral Shift
        { BuffDuration = 12, Cooldown = 90, Important = true, BigDefensive = false, ExternalDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 108271, RequiresTalent = 381647, DirectCast = true }, -- Astral Shift (Planes Traveler)
    },
    WARLOCK = {
        { BuffDuration = 8, Cooldown = 180, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", SpellId = 104773 }, -- Unending Resolve
        { BuffDuration = 3, Cooldown = 45, Important = true, BigDefensive = false, ExternalDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 212295, RequiresTalent = 3624 }, -- Nether Ward
    },
    PRIEST = {
        { BuffDuration = 10, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = false, RequiresEvidence = "Cast", SpellId = 19236, DirectCast = true }, -- Desperate Prayer
        { BuffDuration = 10, Cooldown = 70, Important = true, BigDefensive = false, ExternalDefensive = false, CanCancelEarly = true, RequiresEvidence = "Cast", SpellId = 19236, RequiresTalent = 238100, DirectCast = true }, -- Desperate Prayer (Angel's Mercy)
    },
    EVOKER = {
        { BuffDuration = 12, Cooldown = 90, BigDefensive = true, ExternalDefensive = false, Important = true, RequiresEvidence = "Cast", MinDuration = true, SpellId = 363916 }, -- Obsidian Scales
    },
}

Rules.OffensiveSpellIds = {
    [375087] = true, [107574] = true, [121471] = true, [31884] = true, [216331] = true,
    [190319] = true, [288613] = true, [228260] = true, [102560] = true, [102543] = true,
    [106951] = true, [102558] = true, [1250646] = true, [384352] = true, [114051] = true,
    [114050] = true, [365350] = true, [51271] = true, [403631] = true,
}

-- Lookup for spells detected via CLEU SPELL_CAST_SUCCESS instead of the aura filter system.
-- Populated from all rules where DirectCast = true.
-- directCastRules[spellId] = rule
-- directCastRules[spellId] = { rule, rule, ... }
-- Multiple variants can share a SpellId (e.g. Divine Hymn 180s base vs 120s with Seraphic Crescendo).
-- RequiresTalent variants are sorted BEFORE ExcludeIfTalent variants so that when talent state is
-- unknown (nil), we prefer the talent variant (the more common case) over the base cooldown.
local directCastRules = {}
do
    local function scanList(list)
        if not list then return end
        for _, rule in ipairs(list) do
            if rule.DirectCast and rule.SpellId then
                directCastRules[rule.SpellId] = directCastRules[rule.SpellId] or {}
                local bucket = directCastRules[rule.SpellId]
                -- RequiresTalent rules go first so they are evaluated before ExcludeIfTalent fallbacks.
                if rule.RequiresTalent then
                    table.insert(bucket, 1, rule)
                else
                    bucket[#bucket + 1] = rule
                end
            end
        end
    end
    for _, list in pairs(Rules.BySpec)  do scanList(list) end
    for _, list in pairs(Rules.ByClass) do scanList(list) end
end

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

-- playerTalentCache[spellId] = rank  (rank > 0 = talent active)
-- Populated via talent export string decode — same method as MiniCC (proven reliable).
local playerTalentCache = {}

-- Builds nodeId_choiceIndex → { spellId, maxRank } map for the given spec.
-- Uses VIEW_TRAIT_CONFIG_ID so all nodes are visible regardless of current loadout.
local _talentMapCache = {}
local function BuildTalentToSpellMap(specId)
    if _talentMapCache[specId] then return _talentMapCache[specId] end
    if not (C_ClassTalents and C_Traits and Constants and Constants.TraitConsts) then return nil end
    local configId = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID
    C_ClassTalents.InitializeViewLoadout(specId, 100)
    C_ClassTalents.ViewLoadout({})
    local configInfo = C_Traits.GetConfigInfo(configId)
    if not configInfo then return nil end
    local map = {}
    for _, treeId in ipairs(configInfo.treeIDs) do
        for _, nodeId in ipairs(C_Traits.GetTreeNodes(treeId)) do
            local node = C_Traits.GetNodeInfo(configId, nodeId)
            if node and node.ID ~= 0 then
                for choiceIndex, entryId in ipairs(node.entryIDs) do
                    local entryInfo = C_Traits.GetEntryInfo(configId, entryId)
                    if entryInfo and entryInfo.definitionID then
                        local defInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                        if defInfo and defInfo.spellID then
                            map[node.ID .. "_" .. choiceIndex] = { spellId = defInfo.spellID, maxRank = node.maxRanks }
                        end
                    end
                end
            end
        end
    end
    _talentMapCache[specId] = map
    return map
end

-- Decodes one talent record from the bit stream.
local function DecodeTalentRecord(stream)
    local function readbool() return stream:ExtractValue(1) == 1 end
    local selected = readbool()
    local purchased, rank, choiceIndex = nil, nil, 1
    if selected then
        purchased = readbool()
        if purchased then
            if readbool() then rank = stream:ExtractValue(6) end  -- notMaxRank → read rank
            if readbool() then choiceIndex = stream:ExtractValue(2) + 1 end  -- choiceNode
        end
    end
    return selected, purchased, rank, choiceIndex
end

local function RefreshPlayerTalents()
    wipe(playerTalentCache)
    if not (C_Traits and C_Traits.GenerateImportString and C_ClassTalents) then return end
    if not (ImportDataStreamMixin and CreateAndInitFromMixin) then return end
    local configId = C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
    if not configId then return end
    local specIdx = GetSpecialization and GetSpecialization()
    if not specIdx then return end
    local specId = GetSpecializationInfo and select(1, GetSpecializationInfo(specIdx))
    if not specId then return end
    local talentString = C_Traits.GenerateImportString(configId)
    if not talentString or talentString == "" then return end
    -- Version check (MiniCC requires version 2)
    if C_Traits.GetLoadoutSerializationVersion and C_Traits.GetLoadoutSerializationVersion() ~= 2 then return end
    local talentMap = BuildTalentToSpellMap(specId)
    if not talentMap then return end
    local traitTree = C_ClassTalents.GetTraitTreeForSpec and C_ClassTalents.GetTraitTreeForSpec(specId)
    if not traitTree then return end
    local stream = CreateAndInitFromMixin(ImportDataStreamMixin, talentString)
    local version = stream:ExtractValue(8)
    if version ~= 2 then return end
    stream:ExtractValue(16)   -- specId (skip)
    stream:ExtractValue(128)  -- treeHash (skip)
    for _, nodeId in ipairs(C_Traits.GetTreeNodes(traitTree)) do
        local selected, purchased, rank, choiceIndex = DecodeTalentRecord(stream)
        if selected and purchased then
            local entry = talentMap[nodeId .. "_" .. choiceIndex]
            if entry and entry.spellId then
                playerTalentCache[entry.spellId] = rank or entry.maxRank or 1
            end
        end
    end
end

-- Ported from MiniCC Talents.lua — assumed talent ranks for non-inspected players.
-- Used as fallback when no real talent data is available for a group member.
-- { [talentSpellId] = rank } — rank > 0 means assumed present.
local ClassDefaultTalentRanks = {
    DEATHKNIGHT = { [205727] = 1 }, -- Anti-Magic Barrier: AMS -20s (nearly universal)
    HUNTER      = { [1258485] = 1 }, -- Improved Aspect of the Turtle: -30s (nearly universal)
    MAGE        = { [382424] = 2, [1265517] = 1 }, -- Winter's Protection r2, Permafrost Bauble
    MONK        = { [388813] = 1 }, -- Expeditious Fortification: Fortifying Brew CDR
    PALADIN     = { [114154] = 1 }, -- Unbreakable Spirit: Bubble/DP -30%
    SHAMAN      = { [381647] = 1 }, -- Planes Traveler: Astral Shift -30s
    WARRIOR     = { [107574] = 1, [184364] = 1 }, -- Avatar, Enraged Regen
}
local SpecDefaultTalentRanks = {
    [65]   = { [384820] = 1, [216331] = 1 }, -- Holy Paladin: BoSac -15s, Avenging Crusader
    [66]   = { [384820] = 1 }, -- Prot Paladin: BoSac -60s
    [70]   = { [458359] = 1, [384820] = 1 }, -- Ret Paladin: Radiant Glory, BoSac -60s
    [72]   = { [383468] = 1 }, -- Fury Warrior: Invigorating Fury
    [102]  = { [468743] = 1 }, -- Balance Druid: Whirling Stars -60s
    [103]  = { [102543] = 1, [391174] = 1, [391548] = 1 }, -- Feral Druid
    [105]  = { [382552] = 1 }, -- Resto Druid: Improved Ironbark -20s
    [254]  = { [260404] = 1 }, -- MM Hunter: Calling the Shots -30s
    [63]   = { [1254194] = 1 }, -- Fire Mage: Kindling -60s
    [257]  = { [419110] = 1 }, -- Holy Priest: Seraphic Crescendo (Divine Hymn -60s)
    [258]  = { [288733] = 1 }, -- Shadow Priest: Intangibility (Dispersion -30s)
    [262]  = { [114050] = 1, [462440] = 1, [462443] = 1 }, -- Ele Shaman: Ascendance
    [263]  = { [384352] = 1, [384444] = 1 }, -- Enh Shaman: Doomwinds, Thorim's Invocation
    [264]  = { [114052] = 1, [462440] = 1 }, -- Resto Shaman: Ascendance
    [270]  = { [202424] = 1 }, -- Mistweaver: Chrysalis (Life Cocoon -45s)
    [1468] = { [376204] = 1 }, -- Preservation Evoker: Just in Time -10s
}

-- Returns true/false/nil for a talent.
-- Player: exact check from talent cache.
-- Others: check class/spec defaults (nearly-universal assumptions); nil if unknown.
local function UnitHasTalent(unit, talentId)
    if UnitIsUnit(unit, "player") then
        return (playerTalentCache[talentId] or 0) > 0
    end
    local _, classToken = UnitClass(unit)
    local specId = GetUnitSpec(unit)
    local classDef = classToken and ClassDefaultTalentRanks[classToken]
    local specDef  = specId and SpecDefaultTalentRanks[specId]
    if (classDef and (classDef[talentId] or 0) > 0) or (specDef and (specDef[talentId] or 0) > 0) then
        return true  -- assumed present (nearly universal default)
    end
    return nil  -- unknown, skip talent check
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
local observerDirectCastCallbacks = {}  -- fn(unit, spellId) — for DirectCast spells not trackable via auras
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
            local _, _, spellId = ...
            for _, fn in ipairs(observerCastCallbacks) do fn(u) end
            if spellId and next(observerDirectCastCallbacks) then
                for _, fn in ipairs(observerDirectCastCallbacks) do fn(u, spellId) end
            end
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
function Observer:RegisterDirectCast(fn) observerDirectCastCallbacks[#observerDirectCastCallbacks + 1] = fn end
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
-- DirectCast: spells not detectable via aura filters (IsSpellImportant = false, not BIG/EXTERNAL_DEFENSIVE).
-- Detected via UNIT_SPELLCAST_SUCCEEDED (already registered per unit by the Observer).
-- Only uses variables declared before this point: directCastRules, Rules, cdCommittedCallback (forward-declared).
Observer:RegisterDirectCast(function(unit, spellId)
    local ok, variants = pcall(function() return directCastRules[spellId] end)
    if not ok or not variants then return end
    -- Pick the first variant whose talent requirements match this unit.
    local rule = nil
    for _, v in ipairs(variants) do
        local ok = true
        if v.RequiresTalent then
            local has = UnitHasTalent(unit, v.RequiresTalent)
            if has == false then ok = false end
        end
        if ok and v.ExcludeIfTalent then
            local excl = type(v.ExcludeIfTalent) == "table" and v.ExcludeIfTalent or { v.ExcludeIfTalent }
            for _, tid in ipairs(excl) do
                if UnitHasTalent(unit, tid) == true then ok = false; break end
            end
        end
        if ok then rule = v; break end
    end
    if not rule then return end
    local now = GetTime()
    -- SpellIcon left nil — cdCommittedCallback resolves it internally via GetSpellIcon.
    local cdData = {
        StartTime   = now,
        Cooldown    = rule.Cooldown,
        Remaining   = rule.Cooldown,
        SpellId     = rule.SpellId,
        IsOffensive = Rules.OffensiveSpellIds[rule.SpellId] == true,
    }
    cdCommittedCallback(unit, rule.SpellId, cdData, nil)
end)

-- =====================================================================
-- SECTION 9: Cooldown Store
-- =====================================================================

-- activeCDs[unit][cdKey] = { StartTime, Cooldown, Remaining, SpellId, SpellIcon, IsOffensive }
local activeCDs = {}
-- entry.ActiveCooldowns[spellId] = true
local watchEntries = {}  -- unit -> entry

-- Static abilities cache: unit -> { specId, result[] }
-- result[i] = { SpellId, IsOffensive }
local staticAbilitiesCache = {}

-- Returns the ordered list of unique spells tracked for a unit's spec/class.
-- When the spell is not on CD the icon shows at full brightness (no swipe).
local function GetStaticAbilities(unit)
    local _, classToken = UnitClass(unit)
    if not classToken then return {} end
    local specId = GetUnitSpec(unit) or 0

    local cached = staticAbilitiesCache[unit]
    if cached and cached.specId == specId then return cached.result end

    -- Category priority: ext=4, big=3, imp=2, off=1
    -- A spell with multiple rules (same SpellId) gets the highest-priority category.
    local CAT_PRIO = { ext = 4, big = 3, imp = 2, off = 1 }
    local seen   = {}   -- spellId -> index in result
    local result = {}
    local isPlayer = UnitIsUnit(unit, "player")

    local function addRules(ruleList)
        if not ruleList then return end
        for _, rule in ipairs(ruleList) do
            if rule.SpellId then
                local ok = true
                if isPlayer then
                    if rule.RequiresTalent then
                        local has = UnitHasTalent(unit, rule.RequiresTalent)
                        if has == false then ok = false end
                    end
                    if ok and rule.ExcludeIfTalent then
                        local excl = type(rule.ExcludeIfTalent) == "table" and rule.ExcludeIfTalent or { rule.ExcludeIfTalent }
                        for _, tid in ipairs(excl) do
                            if UnitHasTalent(unit, tid) == true then ok = false; break end
                        end
                    end
                end
                if ok then
                    local isOff = Rules.OffensiveSpellIds and Rules.OffensiveSpellIds[rule.SpellId] == true
                    local cat
                    if isOff then cat = "off"
                    elseif rule.ExternalDefensive then cat = "ext"
                    elseif rule.BigDefensive then cat = "big"
                    else cat = "imp"
                    end
                    local idx = seen[rule.SpellId]
                    if idx then
                        -- Update category if this rule has higher priority
                        local existing = result[idx]
                        if CAT_PRIO[cat] > CAT_PRIO[existing.Category] then
                            existing.Category = cat
                            existing.IsOffensive = isOff
                        end
                    else
                        seen[rule.SpellId] = #result + 1
                        result[#result + 1] = {
                            SpellId = rule.SpellId,
                            IsOffensive = isOff,
                            Category = cat,
                        }
                    end
                end
            end
        end
    end

    addRules(specId > 0 and Rules.BySpec[specId])
    addRules(Rules.ByClass[classToken])

    staticAbilitiesCache[unit] = { specId = specId, result = result }
    return result
end

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

-- GetAttribute is a protected call on secure frames and cannot be called
-- during combat lockdown from non-secure code (causes ADDON_ACTION_FORBIDDEN).
local function SafeGetUnit(frame)
    if not frame or not frame.GetAttribute then return nil end
    local ok, val = pcall(frame.GetAttribute, frame, "unit")
    return ok and val or nil
end

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

function Frames:ShadowedUFFrames()
    local frames = {}
    if not SUFUnitplayer and not SUFHeaderpartyUnitButton1 and not SUFHeaderraidUnitButton1 then
        return frames
    end
    local function Add(f)
        if f and not (f.IsForbidden and f:IsForbidden()) then frames[#frames + 1] = f end
    end
    Add(SUFUnitplayer)
    for i = 1, 4 do
        Add(_G["SUFHeaderpartyUnitButton" .. i])
        Add(_G["SUFUnitparty" .. i])
    end
    for i = 1, 40 do
        Add(_G["SUFHeaderraidUnitButton" .. i])
        Add(_G["SUFUnitraidunit" .. i])
    end
    return frames
end

function Frames:PlexusFrames()
    local frames = {}
    if not PlexusLayoutHeader1 then return frames end
    local seen = {}
    local headerIndex = 1
    while true do
        local header = _G["PlexusLayoutHeader" .. headerIndex]
        if not header then break end
        for _, child in ipairs({ header:GetChildren() }) do
            local unit = child.unit or SafeGetUnit(child)
            if unit and unit ~= "" and not seen[child] then
                if not (child.IsForbidden and child:IsForbidden()) then
                    seen[child] = true
                    frames[#frames + 1] = child
                end
            end
        end
        headerIndex = headerIndex + 1
    end
    return frames
end

function Frames:CellFrames()
    local frames = {}
    if not CellPartyFrameHeader and not CellRaidFrameHeader0 then return frames end
    local headers = { CellPartyFrameHeader, CellSoloFrame }
    for i = 0, 8 do
        local h = _G["CellRaidFrameHeader" .. i]
        if h then headers[#headers + 1] = h end
    end
    for _, header in ipairs(headers) do
        if header then
            for _, child in ipairs({ header:GetChildren() }) do
                local unit = child.unit or SafeGetUnit(child)
                if unit and unit ~= "" then
                    if not (child.IsForbidden and child:IsForbidden()) then
                        frames[#frames + 1] = child
                    end
                end
            end
        end
    end
    return frames
end

function Frames:IsBlizzardPartyFrame(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return false end
    local name = frame:GetName()
    if name and name:find("CompactPartyFrame") then return true end
    if PartyFrame and frame:GetParent() == PartyFrame then return true end
    return false
end

-- Returns true for any Blizzard compact/standard CUF (used to gate hooksecurefunc)
function Frames:IsFriendlyCuf(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return false end
    local name = frame:GetName()
    if not name then return false end
    if name:find("CompactParty") or name:find("CompactRaid") then return true end
    if PartyFrame and frame:GetParent() == PartyFrame then return true end
    return false
end

-- Returns the frame strata one level above the given strata, clamped at TOOLTIP
local _strataOrder = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local _strataIndex = {}
for i, v in ipairs(_strataOrder) do _strataIndex[v] = i end
function Frames:GetNextStrata(strata)
    return _strataOrder[math.min((_strataIndex[strata] or 1) + 1, #_strataOrder)]
end

function Frames:GetAll()
    local all = {}
    local blizzard  = Frames:BlizzardFrames()
    local elvui     = Frames:ElvUIFrames()
    local grid2     = Frames:Grid2Frames()
    local vuhdo     = Frames:VuhDoFrames()
    local danders   = Frames:DandersFrames()
    local suf       = Frames:ShadowedUFFrames()
    local plexus    = Frames:PlexusFrames()
    local cell      = Frames:CellFrames()
    for _, f in ipairs(blizzard) do all[#all + 1] = f end
    for _, f in ipairs(elvui)    do all[#all + 1] = f end
    for _, f in ipairs(grid2)    do all[#all + 1] = f end
    for _, f in ipairs(vuhdo)    do all[#all + 1] = f end
    for _, f in ipairs(danders)  do all[#all + 1] = f end
    for _, f in ipairs(suf)      do all[#all + 1] = f end
    for _, f in ipairs(plexus)   do all[#all + 1] = f end
    for _, f in ipairs(cell)     do all[#all + 1] = f end
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

local BAR_CATS       = { "ext", "big", "imp", "off" }
local BAR_CAT_POSKEY = { ext = "barExtPos", big = "barBigPos", imp = "barImpPos", off = "barOffPos" }
local BAR_CAT_ENKEY  = { ext = "barExtEnabled", big = "barBigEnabled", imp = "barImpEnabled", off = "barOffEnabled" }
local BAR_CAT_DEFPOS = {
    ext = { "CENTER", "UIParent", "CENTER", -500,  150 },
    big = { "CENTER", "UIParent", "CENTER", -500,   50 },
    imp = { "CENTER", "UIParent", "CENTER", -500,  -50 },
    off = { "CENTER", "UIParent", "CENTER", -500, -150 },
}
local barContainers = { ext = nil, big = nil, imp = nil, off = nil }
local barPools      = { ext = {},  big = {},  imp = {},  off = {}  }
local barActives    = { ext = {},  big = {},  imp = {},  off = {}  }

local function CreateBarWidget(container)
    local bar = CreateFrame("Frame", nil, container)
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
    nameText:SetPoint("RIGHT", bar, "RIGHT", -56, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetJustifyV("MIDDLE")
    nameText:SetHeight(DB.barHeight)
    bar.nameText = nameText
    local timerText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    timerText:SetWidth(52)
    timerText:SetHeight(DB.barHeight)
    timerText:SetJustifyH("RIGHT")
    timerText:SetJustifyV("MIDDLE")
    bar.timerText = timerText
    bar:Hide()
    return bar
end

local function InitBarContainers()
    if InCombatLockdown() then return end
    for _, cat in ipairs(BAR_CATS) do
        if DB[BAR_CAT_ENKEY[cat]] and not barContainers[cat] then
            local c = CreateFrame("Frame", "InfinityFCDBarContainer_" .. cat, UIParent)
            c:SetSize(DB.barWidth, 1)
            c:SetClampedToScreen(true)
            c:EnableMouse(not DB.barLocked)
            c:SetMovable(not DB.barLocked)
            if not DB.barLocked then
                c:RegisterForDrag("LeftButton")
                c:SetScript("OnDragStart", function(f) f:StartMoving() end)
                local posKey = BAR_CAT_POSKEY[cat]
                c:SetScript("OnDragStop", function(f)
                    f:StopMovingOrSizing()
                    local p, _, rp, x, y = f:GetPoint()
                    DB[posKey] = { p, "UIParent", rp, x, y }
                end)
            end
            local pos = DB[BAR_CAT_POSKEY[cat]] or BAR_CAT_DEFPOS[cat]
            c:SetPoint(pos[1], _G[pos[2]] or UIParent, pos[3], pos[4], pos[5])
            barContainers[cat] = c
        end
    end
end

local function AcquireBar(cat)
    local bar = table.remove(barPools[cat])
    if not bar then bar = CreateBarWidget(barContainers[cat]) end
    bar:Show()
    return bar
end

local function ReleaseBar(cat, bar)
    bar:Hide()
    barPools[cat][#barPools[cat] + 1] = bar
end

-- Returns a flat list of { unit, spellId, tex, onCD, remaining, startTime, cooldown, unitName, class }
-- for all tracked abilities across all current group members.
-- When a spell is available (not on CD) it is still included so Bar/Icon modes show the full
-- ability roster — same behaviour as Attached mode.
local function BuildAbilityLists()
    local lists    = { ext = {}, big = {}, imp = {}, off = {} }
    local now      = GetTime()
    local isPreview = DB.barPreview or DB.iconPreview

    -- ---- Build unit list (forward-safe; no reference to activeEntries) ----
    local units    = {}
    local unitsSeen = {}
    local function AddUnit(u)
        if not unitsSeen[u] then
            unitsSeen[u] = true
            units[#units + 1] = u
        end
    end

    if DB.showPlayer then AddUnit("player") end
    if IsInRaid() then
        local n = GetNumGroupMembers()
        for i = 1, n do AddUnit("raid" .. i) end
    else
        local n = GetNumGroupMembers()
        for i = 1, n do AddUnit("party" .. i) end
    end
    -- Preview: also pull any fake units injected into activeCDs
    if isPreview then
        for previewUnit in pairs(activeCDs) do AddUnit(previewUnit) end
    end

    -- ---- Per-unit ability list ----
    for _, unit in ipairs(units) do
        local realUnit = UnitExists(unit)

        if realUnit then
            -- Normal path: real unit in the world
            local unitName = UnitName(unit) or unit
            local _, class = UnitClass(unit)
            local cds      = activeCDs[unit] or {}
            -- activeCDs may key by a different token (e.g. party1 vs raid1)
            for u, data in pairs(activeCDs) do
                if u ~= unit and UnitIsUnit(u, unit) then
                    cds = data
                    break
                end
            end

            local staticAbils = GetStaticAbilities(unit)
            local shownSpells = {}
            for _, ability in ipairs(staticAbils) do
                if DB.showOffensive or not ability.IsOffensive then
                    local tex = C_Spell.GetSpellTexture(ability.SpellId)
                    if tex then
                        shownSpells[ability.SpellId] = true
                        local cd        = cds[ability.SpellId]
                        local onCD      = false
                        local remaining = 0
                        local startTime = nil
                        local cooldown  = nil
                        if cd then
                            remaining = cd.Cooldown - (now - cd.StartTime)
                            if remaining > 0 then
                                onCD      = true
                                startTime = cd.StartTime
                                cooldown  = cd.Cooldown
                            end
                        end
                        local cat = ability.Category or "imp"
                        local sublist = lists[cat]
                        sublist[#sublist + 1] = {
                            unit      = unit,
                            spellId   = ability.SpellId,
                            tex       = tex,
                            onCD      = onCD,
                            remaining = remaining,
                            startTime = startTime,
                            cooldown  = cooldown,
                            unitName  = unitName,
                            class     = class,
                        }
                    end
                end
            end
            -- Also show CDs from DirectCast spells not covered by static abilities
            -- (happens when spec is unknown at cast time — e.g. inspect not yet done)
            for cdKey, cd in pairs(cds) do
                if type(cdKey) == "number" and not shownSpells[cdKey] then
                    if DB.showOffensive or not (Rules.OffensiveSpellIds and Rules.OffensiveSpellIds[cdKey]) then
                        local remaining = cd.Cooldown - (now - cd.StartTime)
                        if remaining > 0 then
                            local tex = C_Spell.GetSpellTexture(cdKey)
                            if tex then
                                lists["imp"][#lists["imp"] + 1] = {
                                    unit=unit, spellId=cdKey, tex=tex,
                                    onCD=true, remaining=remaining,
                                    startTime=cd.StartTime, cooldown=cd.Cooldown,
                                    unitName=unitName, class=class,
                                }
                            end
                        end
                    end
                end
            end

        elseif isPreview and activeCDs[unit] then
            -- Preview path: fake unit injected by SetupPreview; show its injected CDs
            for spellId, cd in pairs(activeCDs[unit]) do
                local tex = C_Spell.GetSpellTexture(spellId)
                if tex then
                    local remaining = cd.Cooldown - (now - cd.StartTime)
                    local onCD      = remaining > 0
                    local cat       = cd.Category or "imp"
                    local sublist   = lists[cat]
                    sublist[#sublist + 1] = {
                        unit      = unit,
                        spellId   = spellId,
                        tex       = tex,
                        onCD      = onCD,
                        remaining = onCD and remaining or 0,
                        startTime = onCD and cd.StartTime or nil,
                        cooldown  = onCD and cd.Cooldown or nil,
                        unitName  = cd.UnitName or unit,
                        class     = cd.Class or nil,
                    }
                end
            end
        end
    end

    -- Sort each sub-list: available first, then soonest back
    local sortFn = function(a, b)
        if a.onCD ~= b.onCD then return not a.onCD end
        return a.remaining < b.remaining
    end
    for _, sublist in pairs(lists) do table.sort(sublist, sortFn) end

    return lists
end

-- Flat list for Icon mode: shows ALL abilities regardless of offensive filter
local function BuildAbilityList()
    local list      = {}
    local now       = GetTime()
    local isPreview = DB.barPreview or DB.iconPreview

    local units, unitsSeen = {}, {}
    local function AddUnit(u)
        if not unitsSeen[u] then unitsSeen[u] = true; units[#units+1] = u end
    end
    if DB.showPlayer then AddUnit("player") end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do AddUnit("raid"..i) end
    else
        for i = 1, GetNumGroupMembers() do AddUnit("party"..i) end
    end
    if isPreview then
        for previewUnit in pairs(activeCDs) do AddUnit(previewUnit) end
    end

    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local unitName = UnitName(unit) or unit
            local _, class = UnitClass(unit)
            local cds = activeCDs[unit] or {}
            for u, data in pairs(activeCDs) do
                if u ~= unit and UnitIsUnit(u, unit) then cds = data; break end
            end
            local shownSpells = {}
            for _, ability in ipairs(GetStaticAbilities(unit)) do
                local tex = C_Spell.GetSpellTexture(ability.SpellId)
                if tex then
                    shownSpells[ability.SpellId] = true
                    local cd = cds[ability.SpellId]
                    local onCD, remaining, startTime, cooldown = false, 0, nil, nil
                    if cd then
                        remaining = cd.Cooldown - (now - cd.StartTime)
                        if remaining > 0 then
                            onCD = true; startTime = cd.StartTime; cooldown = cd.Cooldown
                        end
                    end
                    list[#list+1] = {
                        unit=unit, spellId=ability.SpellId, tex=tex,
                        onCD=onCD, remaining=remaining, startTime=startTime,
                        cooldown=cooldown, unitName=unitName, class=class,
                    }
                end
            end
            -- Also show CDs from DirectCast spells not covered by static abilities
            -- (happens when spec is unknown at cast time — e.g. inspect not yet done)
            for cdKey, cd in pairs(cds) do
                if type(cdKey) == "number" and not shownSpells[cdKey] then
                    local remaining = cd.Cooldown - (now - cd.StartTime)
                    if remaining > 0 then
                        local tex = C_Spell.GetSpellTexture(cdKey)
                        if tex then
                            list[#list+1] = {
                                unit=unit, spellId=cdKey, tex=tex,
                                onCD=true, remaining=remaining,
                                startTime=cd.StartTime, cooldown=cd.Cooldown,
                                unitName=unitName, class=class,
                            }
                        end
                    end
                end
            end
        elseif isPreview and activeCDs[unit] then
            for spellId, cd in pairs(activeCDs[unit]) do
                local tex = C_Spell.GetSpellTexture(spellId)
                if tex then
                    local remaining = cd.Cooldown - (now - cd.StartTime)
                    local onCD = remaining > 0
                    list[#list+1] = {
                        unit=unit, spellId=spellId, tex=tex,
                        onCD=onCD, remaining=onCD and remaining or 0,
                        startTime=onCD and cd.StartTime or nil,
                        cooldown=onCD and cd.Cooldown or nil,
                        unitName=cd.UnitName or unit, class=cd.Class or nil,
                    }
                end
            end
        end
    end

    table.sort(list, function(a, b)
        if a.onCD ~= b.onCD then return not a.onCD end
        return a.remaining < b.remaining
    end)
    return list
end

local function RebuildBarsForCat(cat, container, list)
    local active  = barActives[cat]
    for _, bar in ipairs(active) do ReleaseBar(cat, bar) end
    barActives[cat] = {}
    active = barActives[cat]

    local maxBars  = DB.barMaxBars
    local count    = math.min(#list, maxBars)
    local barH     = DB.barHeight
    local spacing  = DB.barSpacing
    local growDown = DB.barGrowDown
    local totalH   = count * barH + math.max(0, count - 1) * spacing
    container:SetHeight(math.max(totalH, 1))
    container:SetWidth(DB.barWidth)

    for i = 1, count do
        local entry = list[i]
        local bar   = AcquireBar(cat)
        bar:SetWidth(DB.barWidth)
        bar:SetHeight(barH)
        bar:ClearAllPoints()
        local yOff = (i - 1) * (barH + spacing)
        if growDown then
            bar:SetPoint("TOPLEFT",    container, "TOPLEFT",    0, -yOff)
        else
            bar:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0,  yOff)
        end

        local r, g, b = 0.5, 0.5, 0.5
        if DB.barUseClassColor and entry.class then r, g, b = GetClassColor(entry.class) end

        if entry.onCD then
            local pct = entry.remaining / entry.cooldown
            bar.fill:SetPoint("RIGHT", bar, "LEFT", DB.barWidth * (1 - pct), 0)
            bar.fill:SetVertexColor(r, g, b, 1)
        else
            bar.fill:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
            bar.fill:SetVertexColor(r * 0.55, g * 0.55, b * 0.55, 0.6)
        end

        if DB.barShowIcon then
            bar.icon:Show()
            bar.icon:SetSize(barH - 2, barH - 2)
            bar.icon.tex:SetTexture(entry.tex)
        else
            bar.icon:Hide()
        end

        local nameStr = ""
        if DB.barShowName and entry.unitName then nameStr = entry.unitName .. " " end
        bar.nameText:SetText(nameStr)

        if DB.barShowTimer then
            if entry.onCD then
                bar.timerText:SetText(FormatTime(entry.remaining))
            else
                bar.timerText:SetText("Ready")
            end
        else
            bar.timerText:SetText("")
        end

        active[#active + 1] = bar
    end
end

local function RebuildBars()
    local anyContainer = false
    for _, cat in ipairs(BAR_CATS) do
        if barContainers[cat] then anyContainer = true; break end
    end
    if not anyContainer then return end

    local lists = BuildAbilityLists()
    for _, cat in ipairs(BAR_CATS) do
        local container = barContainers[cat]
        if container then
            RebuildBarsForCat(cat, container, lists[cat])
        end
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

    local list    = BuildAbilityList()
    local sz      = DB.iconSize
    local cols    = DB.iconCols
    local spacing = DB.iconSpacing
    local rowH    = sz + (DB.iconShowName and 12 or 0) + (DB.iconShowTimer and 12 or 0) + spacing
    local colW    = sz + spacing
    local rows    = math.max(1, math.ceil(#list / cols))
    iconContainer:SetSize(cols * colW, rows * rowH)

    for i, entry in ipairs(list) do
        local ic  = AcquireIcon()
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        ic:ClearAllPoints()
        ic:SetPoint("TOPLEFT", iconContainer, "TOPLEFT", col * colW, -row * rowH)
        ic.tex:SetTexture(entry.tex)

        if entry.onCD and entry.startTime and entry.cooldown then
            ic.cooldown:SetCooldown(entry.startTime, entry.cooldown)
        else
            ic.cooldown:SetCooldown(0, 0)   -- no swipe when available
        end

        ic.nameLabel:SetText(DB.iconShowName and entry.unitName or "")

        if DB.iconShowTimer then
            ic.timerLabel:SetText(entry.onCD and FormatTime(entry.remaining) or "Ready")
        else
            ic.timerLabel:SetText("")
        end

        iconActive[#iconActive + 1] = ic
    end
end

-- =====================================================================
-- SECTION 14: Display — Attached Mode
-- =====================================================================
-- Architecture mirrors MiniCC exactly: keyed by FRAME OBJECT, not unit string.
-- This avoids the unreliable unit→frame reverse-lookup entirely.
-- attachedByFrame[anchorFrame] = { container = Frame, unit = string }
-- =====================================================================

local attachedByFrame = {}

-- Returns the active CD table for a unit, handling party1↔raid1 equivalence.
local function GetCDsForUnit(unit)
    if activeCDs[unit] then return activeCDs[unit] end
    for u, data in pairs(activeCDs) do
        if UnitIsUnit(u, unit) then return data end
    end
    return {}
end

-- Creates (or updates) an attached entry for a given anchor frame.
local function EnsureFrameEntry(anchor, unitHint)
    if not anchor then return end
    if anchor.IsForbidden and anchor:IsForbidden() then return end

    local unit = unitHint
                 or anchor.unit
                 or SafeGetUnit(anchor)
    if not unit or unit == "" then return end
    if UnitCanAttack("player", unit) then return end  -- skip enemy frames

    local existing = attachedByFrame[anchor]
    if existing then
        existing.unit = unit   -- unit can change when roster sorts
        return
    end

    local container = CreateFrame("Frame", nil, UIParent)
    container:SetSize(DB.attachIconSize, DB.attachIconSize)
    container:Hide()
    container.icons = {}
    attachedByFrame[anchor] = { container = container, unit = unit }
end

-- Scans all known frame providers and ensures every visible frame has an entry.
local function EnsureAllFrameEntries()
    if InCombatLockdown() then return end
    for _, f in ipairs(Frames:GetAll()) do
        EnsureFrameEntry(f)
    end
end

local function AnchorAttachedContainer(container, anchor)
    container:ClearAllPoints()
    local side = DB.attachSide or "RIGHT"
    -- Migrate legacy values saved before the rename
    if side == "ABOVE" then side = "TOP"  end
    if side == "BELOW" then side = "DOWN" end
    local ox = DB.attachOffsetX or 2
    local oy = DB.attachOffsetY or 0
    if side == "RIGHT" then
        container:SetPoint("LEFT", anchor, "RIGHT", ox, oy)
    elseif side == "LEFT" then
        container:SetPoint("RIGHT", anchor, "LEFT", -ox, oy)
    elseif side == "TOP" then
        container:SetPoint("BOTTOM", anchor, "TOP", ox, oy)
    elseif side == "DOWN" then
        container:SetPoint("TOP", anchor, "BOTTOM", ox, -oy)
    end
    -- Blizzard party frames clip their children — bump strata so icons render on top.
    local strata = Frames:IsBlizzardPartyFrame(anchor)
        and Frames:GetNextStrata(anchor:GetFrameStrata())
        or anchor:GetFrameStrata()
    container:SetFrameStrata(strata)
    container:SetFrameLevel(anchor:GetFrameLevel() + 10)
    container:Show()
end

-- Renders one icon slot inside a container frame, reusing existing child frames.
-- row/col are 0-based.
local function SetAttachedIconSlot(container, i, slot, iconSz, row, col, spacing)
    local ic = container.icons[i]
    if not ic then
        ic = CreateFrame("Frame", nil, container)
        ic:SetSize(iconSz, iconSz)
        local texObj = ic:CreateTexture(nil, "ARTWORK")
        texObj:SetAllPoints()
        texObj:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        ic.tex = texObj
        local cdFrame = CreateFrame("Cooldown", nil, ic, "CooldownFrameTemplate")
        cdFrame:SetAllPoints()
        cdFrame:SetDrawEdge(false)
        ic.cooldown = cdFrame
        container.icons[i] = ic
    end
    ic:Show()
    ic:SetSize(iconSz, iconSz)
    ic:ClearAllPoints()
    ic:SetPoint("TOPLEFT", container, "TOPLEFT",
        col * (iconSz + spacing),
        -row * (iconSz + spacing))
    ic.tex:SetTexture(slot.tex)
    if slot.startTime and slot.cooldown then
        ic.cooldown:SetCooldown(slot.startTime, slot.cooldown)
    else
        ic.cooldown:SetCooldown(0, 0)  -- available — no swipe
    end
end

local function RebuildAttached()
    if InCombatLockdown() then return end
    local now     = GetTime()
    local iconSz  = DB.attachIconSize
    local spacing = DB.attachSpacing
    local side    = DB.attachSide or "RIGHT"
    local perRow  = math.max(1, DB.attachCols or 5)

    -- Make sure every currently-visible frame has an entry
    EnsureAllFrameEntries()

    for anchor, entry in pairs(attachedByFrame) do
        local container = entry.container

        -- Refresh unit in case Blizzard reassigned it (roster sort)
        local unit = anchor.unit
                     or SafeGetUnit(anchor)
                     or entry.unit
        entry.unit = unit

        -- Hide if the anchor frame itself isn't visible or has no unit
        if not unit or unit == ""
        or not UnitExists(unit)
        or (anchor.IsVisible and not anchor:IsVisible()) then
            container:Hide()
        else
            -- Build slot list: every tracked ability for this unit
            local staticAbils = GetStaticAbilities(unit)
            local cds         = GetCDsForUnit(unit)
            local list        = {}

            local shownSpells = {}
            for _, ability in ipairs(staticAbils) do
                if DB.showOffensive or not ability.IsOffensive then
                    local tex = C_Spell.GetSpellTexture(ability.SpellId)
                    if tex then
                        shownSpells[ability.SpellId] = true
                        local cd   = cds[ability.SpellId]
                        local onCD = cd and now < (cd.StartTime + cd.Cooldown)
                        list[#list + 1] = {
                            tex       = tex,
                            startTime = onCD and cd.StartTime or nil,
                            cooldown  = onCD and cd.Cooldown  or nil,
                        }
                    end
                end
            end
            -- Also show CDs from DirectCast spells not covered by static abilities
            for cdKey, cd in pairs(cds) do
                if type(cdKey) == "number" and not shownSpells[cdKey] then
                    if DB.showOffensive or not (Rules.OffensiveSpellIds and Rules.OffensiveSpellIds[cdKey]) then
                        local onCD = now < (cd.StartTime + cd.Cooldown)
                        if onCD then
                            local tex = C_Spell.GetSpellTexture(cdKey)
                            if tex then
                                list[#list + 1] = {
                                    tex       = tex,
                                    startTime = cd.StartTime,
                                    cooldown  = cd.Cooldown,
                                }
                            end
                        end
                    end
                end
            end

            local n = #list
            if n == 0 then
                container:Hide()
            else
                AnchorAttachedContainer(container, anchor)

                -- Simple grid: fill left→right, wrap down every `perRow` icons.
                -- col = (i-1) % perRow
                -- row = floor((i-1) / perRow)
                local numCols = math.min(n, perRow)
                local numRows = math.ceil(n / perRow)
                local w = numCols * iconSz + math.max(0, numCols - 1) * spacing
                local h = numRows * iconSz + math.max(0, numRows - 1) * spacing
                container:SetSize(w, h)

                for i, slot in ipairs(list) do
                    local idx = i - 1
                    local row = math.floor(idx / perRow)
                    local col = idx % perRow
                    SetAttachedIconSlot(container, i, slot, iconSz, row, col, spacing)
                end
                for i = n + 1, #container.icons do
                    container.icons[i]:Hide()
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
    for _, cat in ipairs(BAR_CATS) do
        for _, bar in ipairs(barActives[cat]) do
            if bar.cdData then
                local remaining = bar.cdData.Cooldown - (now - bar.cdData.StartTime)
                if remaining < 0 then remaining = 0 end
                local pct = remaining / bar.cdData.Cooldown
                bar.fill:SetPoint("RIGHT", bar, "LEFT", DB.barWidth * (1 - pct), 0)
                if DB.barShowTimer then bar.timerText:SetText(FormatTime(remaining)) end
            end
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

    if DB.barEnabled then
        RebuildBars()
    end
    if DB.iconEnabled and iconContainer then
        RebuildIcons()
    end
    if DB.attachEnabled then
        RebuildAttached()
    end
end)

local ApplyAutoMode  -- forward declaration (defined after SetModuleWidget)

eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("INSPECT_READY")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        wipe(staticAbilitiesCache)  -- roster changed → recompute per-unit ability lists
        C_Timer.After(0.5, function()
            if ApplyAutoMode then ApplyAutoMode() end
            BuildRoster()
            if DB.attachEnabled then EnsureAllFrameEntries() end
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended: rebuild frames that were skipped during lockdown
        if DB.attachEnabled then
            EnsureAllFrameEntries()
            RebuildAttached()
        end
        if DB.barEnabled then
            InitBarContainers()
        end
    elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        staticAbilitiesCache["player"] = nil
        RefreshPlayerTalents()
        local entry = activeEntries["player"]
        if entry then Observer:Rewatch(entry) end
    elseif event == "INSPECT_READY" then
        local guid = ...
        for unit in pairs(activeEntries) do
            if UnitGUID(unit) == guid then
                staticAbilitiesCache[unit] = nil
                break
            end
        end
    end
end)

-- Button handlers wired to settings panel
for _, cat in ipairs(BAR_CATS) do
    local btnKey = "btn_reset_bar_" .. cat
    local defPos = BAR_CAT_DEFPOS[cat]
    local posKey = BAR_CAT_POSKEY[cat]
    InfinityTools:RegisterModuleCallback(INFINITY_MODULE_KEY, btnKey, function()
        local c = barContainers[cat]
        if c then
            c:ClearAllPoints()
            c:SetPoint(defPos[1], _G[defPos[2]] or UIParent, defPos[3], defPos[4], defPos[5])
            DB[posKey] = { unpack(defPos) }
        end
    end)
end

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

local _hookedCUF = false
local function Init()
    -- Migrate legacy attachSide values (ABOVE→TOP, BELOW→DOWN)
    if DB.attachSide == "ABOVE" then DB.attachSide = "TOP"  end
    if DB.attachSide == "BELOW" then DB.attachSide = "DOWN" end

    RefreshPlayerTalents()

    -- Initialize display containers
    if DB.barEnabled then InitBarContainers() end
    if DB.iconEnabled then InitIconContainer() end

    -- Preview mode
    if DB.barPreview or DB.iconPreview then
        SetupPreview()
    end

    -- Build roster (bar/icon mode)
    BuildRoster()

    -- Attached mode: scan all frame providers immediately
    if DB.attachEnabled then
        EnsureAllFrameEntries()
    end

    -- Hook Blizzard CUF so we get notified when a frame gets a new unit assigned.
    -- This fires when the group forms, sorts, or changes — we just update the entry.
    if not _hookedCUF then
        _hookedCUF = true

        if CompactUnitFrame_SetUnit then
            hooksecurefunc("CompactUnitFrame_SetUnit", function(frame, unit)
                if not Frames:IsFriendlyCuf(frame) then return end
                if not DB.attachEnabled then return end
                EnsureFrameEntry(frame, unit)
            end)
        end

        if CompactUnitFrame_UpdateVisible then
            hooksecurefunc("CompactUnitFrame_UpdateVisible", function(frame)
                if not Frames:IsFriendlyCuf(frame) then return end
                local entry = attachedByFrame[frame]
                if not entry then return end
                if not DB.attachEnabled or not frame:IsShown() then
                    entry.container:Hide()
                end
            end)
        end
    end

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

-- =====================================================================
-- SECTION 19: Live settings listener
-- =====================================================================

-- Updates a checkbox widget in the InfinityGrid UI for this module, if the panel is currently rendered.
local function SetModuleWidget(widgetKey, value)
    local grid = _G.InfinityGrid
    if not grid or not grid.ContainerStates then return end
    for _, state in pairs(grid.ContainerStates) do
        if state.moduleKey == INFINITY_MODULE_KEY then
            local w = state.widgets and state.widgets[widgetKey]
            if w and w.SetChecked then w:SetChecked(value) end
        end
    end
end

-- =====================================================================
-- Auto-switch mode on group type transition
-- =====================================================================
do
    local lastGroupType = nil

    local function GetGroupType()
        if IsInRaid() then return "raid" end
        if GetNumGroupMembers() > 0 then return "party" end
        return "none"
    end

    local function ActivateBarMode()
        DB.barEnabled   = true
        DB.iconEnabled  = false
        DB.attachEnabled = false
        SetModuleWidget("barEnabled",    true)
        SetModuleWidget("iconEnabled",   false)
        SetModuleWidget("attachEnabled", false)
        if iconContainer then iconContainer:Hide() end
        for _, entry in pairs(attachedByFrame) do entry.container:Hide() end
        InitBarContainers()
        for _, cat in ipairs(BAR_CATS) do
            if barContainers[cat] then barContainers[cat]:Show() end
        end
    end

    local function ActivateAttachMode()
        DB.attachEnabled = true
        DB.barEnabled    = false
        DB.iconEnabled   = false
        SetModuleWidget("attachEnabled", true)
        SetModuleWidget("barEnabled",    false)
        SetModuleWidget("iconEnabled",   false)
        for _, cat in ipairs(BAR_CATS) do
            if barContainers[cat] then barContainers[cat]:Hide() end
        end
        if iconContainer then iconContainer:Hide() end
        EnsureAllFrameEntries()
        RebuildAttached()
    end

    ApplyAutoMode = function()
        if not DB.autoSwitchMode then return end
        local groupType = GetGroupType()
        if groupType == lastGroupType then return end
        lastGroupType = groupType
        if groupType == "raid" then
            ActivateBarMode()
        elseif groupType == "party" then
            ActivateAttachMode()
        end
        -- "none" (solo): no auto-switch, keep current mode
    end
end

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    local key = info.key

    if key == "barEnabled" then
        if DB.barEnabled then
            -- Disable the other two modes
            DB.iconEnabled = false
            DB.attachEnabled = false
            SetModuleWidget("iconEnabled", false)
            SetModuleWidget("attachEnabled", false)
            if iconContainer then iconContainer:Hide() end
            for _, entry in pairs(attachedByFrame) do entry.container:Hide() end
            InitBarContainers()
            for _, cat in ipairs(BAR_CATS) do
                if barContainers[cat] then barContainers[cat]:Show() end
            end
        else
            for _, cat in ipairs(BAR_CATS) do
                if barContainers[cat] then barContainers[cat]:Hide() end
            end
        end

    elseif key == "barExtEnabled" or key == "barBigEnabled" or key == "barImpEnabled" or key == "barOffEnabled" then
        local cat = key == "barExtEnabled" and "ext" or key == "barBigEnabled" and "big"
                 or key == "barImpEnabled" and "imp" or "off"
        if DB[key] then
            InitBarContainers()
            if barContainers[cat] then barContainers[cat]:Show() end
        else
            if barContainers[cat] then barContainers[cat]:Hide() end
        end

    elseif key == "iconEnabled" then
        if DB.iconEnabled then
            -- Disable the other two modes
            DB.barEnabled = false
            DB.attachEnabled = false
            SetModuleWidget("barEnabled", false)
            SetModuleWidget("attachEnabled", false)
            for _, cat in ipairs(BAR_CATS) do
                if barContainers[cat] then barContainers[cat]:Hide() end
            end
            for _, entry in pairs(attachedByFrame) do entry.container:Hide() end
            InitIconContainer()
            if iconContainer then iconContainer:Show() end
        else
            if iconContainer then iconContainer:Hide() end
        end

    elseif key == "barPreview" then
        if DB.barPreview then
            InitBarContainers()
            SetupPreview()
        else
            if not DB.iconPreview then ClearPreview() end
        end

    elseif key == "iconPreview" then
        if DB.iconPreview then
            InitIconContainer()
            SetupPreview()
        else
            if not DB.barPreview then ClearPreview() end
        end

    elseif key == "barWidth" or key == "barHeight" then
        for _, cat in ipairs(BAR_CATS) do
            if barContainers[cat] then barContainers[cat]:SetWidth(DB.barWidth) end
        end

    elseif key == "barExtPos" or key == "barBigPos" or key == "barImpPos" or key == "barOffPos" then
        local cat = key == "barExtPos" and "ext" or key == "barBigPos" and "big"
                 or key == "barImpPos" and "imp" or "off"
        local c = barContainers[cat]
        if c then
            local pos = DB[key]
            c:ClearAllPoints()
            c:SetPoint(pos[1], _G[pos[2]] or UIParent, pos[3], pos[4], pos[5])
        end

    elseif key == "iconPos" then
        if iconContainer then
            iconContainer:ClearAllPoints()
            iconContainer:SetPoint(DB.iconPos[1], _G[DB.iconPos[2]] or UIParent, DB.iconPos[3], DB.iconPos[4], DB.iconPos[5])
        end

    elseif key == "attachEnabled" then
        if DB.attachEnabled then
            -- Disable the other two modes
            DB.barEnabled = false
            DB.iconEnabled = false
            SetModuleWidget("barEnabled", false)
            SetModuleWidget("iconEnabled", false)
            for _, cat in ipairs(BAR_CATS) do
                if barContainers[cat] then barContainers[cat]:Hide() end
            end
            if iconContainer then iconContainer:Hide() end
            EnsureAllFrameEntries()
            RebuildAttached()
        else
            for _, entry in pairs(attachedByFrame) do
                entry.container:Hide()
            end
        end

    elseif key == "attachSide" or key == "attachOffsetX" or key == "attachOffsetY"
    or key == "attachIconSize" or key == "attachSpacing" or key == "attachCols" then
        if DB.attachEnabled then RebuildAttached() end
    end
end)

-- =====================================================================
-- SECTION 19: Debug slash command /fcd
-- =====================================================================

InfinityTools:RegisterChatCommand("fcd", function(arg)
    local p = function(msg) InfinityTools:Print("[FriendlyCD] " .. msg) end

    -- /fcd preview : injects realistic fake CDs for current group
    if arg == "preview" then
        wipe(activeCDs)
        local previewSpells = {
            { spellId = 64843,  cooldown = 180, label = "Divine Hymn"      },
            { spellId = 47788,  cooldown = 180, label = "Guardian Spirit"  },
            { spellId = 200183, cooldown = 120, label = "Apotheosis"       },
            { spellId = 19236,  cooldown = 90,  label = "Desperate Prayer" },
        }
        local now = GetTime()
        local units = {}
        if DB.showPlayer then units[#units+1] = "player" end
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do units[#units+1] = "raid"..i end
        else
            for i = 1, GetNumGroupMembers() do units[#units+1] = "party"..i end
        end
        for i, unit in ipairs(units) do
            local spell = previewSpells[i]
            if spell and UnitExists(unit) then
                activeCDs[unit] = activeCDs[unit] or {}
                local _, cls = UnitClass(unit)
                activeCDs[unit][spell.spellId] = {
                    StartTime = now - math.random(5, 60),
                    Cooldown  = spell.cooldown,
                    SpellId   = spell.spellId,
                    SpellIcon = GetSpellIcon and GetSpellIcon(spell.spellId),
                    UnitName  = UnitName(unit) or unit,
                    Class     = cls,
                    IsOffensive = false,
                }
            end
        end
        p("Preview injecté pour " .. #units .. " unité(s). Tape /fcd clear pour effacer.")
        return
    end

    -- /fcd clear : efface le preview
    if arg == "clear" then
        wipe(activeCDs)
        p("Preview effacé.")
        return
    end

    -- /fcd (sans argument) : dump l'état du tracker
    p("=== État du Friendly CD Tracker ===")
    p("Mode : bar=" .. tostring(DB.barEnabled) .. "  icon=" .. tostring(DB.iconEnabled) .. "  attach=" .. tostring(DB.attachEnabled))

    -- Containers bar
    for _, cat in ipairs(BAR_CATS) do
        local c = barContainers[cat]
        if c then
            p("  Container '" .. cat .. "' : " .. (c:IsShown() and "visible" or "caché"))
        else
            p("  Container '" .. cat .. "' : non créé")
        end
    end

    -- Groupe
    local numMembers = GetNumGroupMembers()
    p("Groupe : " .. numMembers .. " membre(s)" .. (IsInRaid() and " [RAID]" or " [PARTY]"))

    local function specName(id)
        if not id or id == 0 then return "inconnu (inspect en cours?)" end
        local ok, name = pcall(function() return select(2, GetSpecializationInfoByID(id)) end)
        return (ok and name) or tostring(id)
    end

    if DB.showPlayer then
        local guid = UnitGUID("player")
        local specId = GetUnitSpec("player")
        local _, cls = UnitClass("player")
        p("  [player] " .. (UnitName("player") or "?") .. " — " .. (cls or "?") .. " — spec: " .. specName(specId))
        local abils = GetStaticAbilities("player")
        p("    → " .. #abils .. " sort(s) trackés en statique")
    end

    local tokens = IsInRaid() and "raid" or "party"
    for i = 1, numMembers do
        local unit = tokens .. i
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            local specId = GetUnitSpec(unit)
            local _, cls = UnitClass(unit)
            local abils = GetStaticAbilities(unit)
            local cdCount = 0
            if activeCDs[unit] then for _ in pairs(activeCDs[unit]) do cdCount = cdCount + 1 end end
            p("  [" .. unit .. "] " .. (UnitName(unit) or "?") .. " — " .. (cls or "?") .. " — spec: " .. specName(specId))
            p("    → " .. #abils .. " sort(s) statiques | " .. cdCount .. " CD(s) actif(s)")
        end
    end

    p("Tape /fcd preview pour injecter des CDs de test, /fcd clear pour effacer.")
end)
