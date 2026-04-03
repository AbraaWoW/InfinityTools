-- =============================================================
-- [[ Party CD Tracker — Heal / Defensive / CC / Mobility ]]
-- Supports up to 4 independent display groups.
-- Each group has its own frame, categories, and drag handle.
-- Integrated with InfinityTools Global Edit Mode.
--
-- Detection method (priority order):
--   1. UNIT_SPELLCAST_SUCCEEDED (player self, direct — never secret)
--      + AceComm broadcast to group so teammates track the CD too.
--   2. AceComm receive from teammates with this addon.
--   3. UNIT_AURA fallback for players without this addon
--      (covers ~65% of spells that apply a visible aura).
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or
    setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevMplusInfo.ImportantSpellTracker"
local MAX_GROUPS           = 4
local COMM_PREFIX          = "RRT_CDT"

local GROUP_KEYS = {
    INFINITY_MODULE_KEY,
    INFINITY_MODULE_KEY .. ".Group2",
    INFINITY_MODULE_KEY .. ".Group3",
    INFINITY_MODULE_KEY .. ".Group4",
}
local GROUP_LABELS = {
    "Party CD Tracker",
    "Party CD Tracker — Group 2",
    "Party CD Tracker — Group 3",
    "Party CD Tracker — Group 4",
}

-- AceComm (loaded globally by InfinityRaidTools via Libs/AceComm-3.0)
local AceComm = LibStub and LibStub("AceComm-3.0", true)

local PartySpec             = InfinityTools.PartySpec
local C_Spell               = _G.C_Spell
local C_UnitAuras           = _G.C_UnitAuras
local LSM                   = LibStub and LibStub("LibSharedMedia-3.0", true)
local UnitGUID              = _G.UnitGUID
local UnitName              = _G.UnitName
local UnitClass             = _G.UnitClass
local UnitExists            = _G.UnitExists
local GetTime               = _G.GetTime
local CreateFrame           = _G.CreateFrame
local UIParent              = _G.UIParent
local C_Timer               = _G.C_Timer
local wipe                  = _G.wipe
local GetSpecialization     = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local C_ClassColor          = _G.C_ClassColor
local IsInRaid              = _G.IsInRaid
local IsInGroup             = _G.IsInGroup
local GetNumGroupMembers    = _G.GetNumGroupMembers

-- =============================================================
-- Grid Layout Registration (runs even when module disabled)
-- =============================================================
local function RegisterGroupLayout(key, label)
    local layout = {
        { key = "header",        type = "header",       x = 1,  y = 1,  w = 53, h = 2,  label = label,           labelSize = 25 },
        { key = "desc",          type = "description",  x = 1,  y = 4,  w = 53, h = 2,  label = "Independent CD tracking frame. Each group can display different categories at different screen positions." },
        { key = "div0",          type = "divider",      x = 1,  y = 7,  w = 53, h = 1,  label = "" },
        { key = "sub_gen",       type = "subheader",    x = 1,  y = 8,  w = 53, h = 1,  label = "General",       labelSize = 20 },
        { key = "enabled",       type = "checkbox",     x = 1,  y = 10, w = 6,  h = 2,  label = "Enable" },
        { key = "locked",        type = "checkbox",     x = 10, y = 10, w = 8,  h = 2,  label = "Lock Position" },
        { key = "preview",       type = "checkbox",     x = 20, y = 10, w = 8,  h = 2,  label = "Preview Mode" },
        { key = "btn_reset",     type = "button",       x = 30, y = 10, w = 14, h = 2,  label = "Reset Position" },
        { key = "posX",          type = "slider",       x = 1,  y = 14, w = 14, h = 2,  label = "Position X",    min = -1000, max = 1000 },
        { key = "posY",          type = "slider",       x = 17, y = 14, w = 14, h = 2,  label = "Position Y",    min = -1000, max = 1000 },
        { key = "div1",          type = "divider",      x = 1,  y = 17, w = 53, h = 1,  label = "" },
        { key = "sub_cat",       type = "subheader",    x = 1,  y = 18, w = 53, h = 1,  label = "Categories",    labelSize = 20 },
        { key = "showHeal",      type = "checkbox",     x = 1,  y = 20, w = 12, h = 2,  label = "Heal CDs" },
        { key = "showDef",       type = "checkbox",     x = 15, y = 20, w = 12, h = 2,  label = "Defensives" },
        { key = "showCC",        type = "checkbox",     x = 29, y = 20, w = 10, h = 2,  label = "CC" },
        { key = "showMove",      type = "checkbox",     x = 41, y = 20, w = 10, h = 2,  label = "Mobility" },
        { key = "div2",          type = "divider",      x = 1,  y = 23, w = 53, h = 1,  label = "" },
        { key = "sub_bar",       type = "subheader",    x = 1,  y = 24, w = 53, h = 1,  label = "Bar Settings",  labelSize = 20 },
        { key = "maxBars",       type = "slider",       x = 1,  y = 26, w = 14, h = 2,  label = "Max Bars",      min = 1, max = 30 },
        { key = "spacing",       type = "slider",       x = 17, y = 26, w = 14, h = 2,  label = "Spacing",       min = 0, max = 20 },
        { key = "growDir",       type = "dropdown",     x = 33, y = 26, w = 15, h = 2,  label = "Grow Direction",items = "Down,Up" },
        { key = "useClassColor", type = "checkbox",     x = 1,  y = 29, w = 16, h = 2,  label = "Use Class Colors" },
        { key = "showName",      type = "checkbox",     x = 19, y = 29, w = 14, h = 2,  label = "Show Player Name" },
        { key = "showTimer",     type = "checkbox",     x = 35, y = 29, w = 14, h = 2,  label = "Show Timer" },
        { key = "showReadyText", type = "checkbox",     x = 1,  y = 32, w = 16, h = 2,  label = "Show 'Ready' Text" },
        { key = "timerGroup",    type = "timerBarGroup",x = 1,  y = 35, w = 53, h = 26, label = "Bar Appearance",labelSize = 20 },
    }
    InfinityTools:RegisterModuleLayout(key, layout)
end

for i = 1, MAX_GROUPS do
    RegisterGroupLayout(GROUP_KEYS[i], GROUP_LABELS[i])
end

-- At least one group must be enabled for the module to load
local anyGroupEnabled = false
for i = 1, MAX_GROUPS do
    if InfinityTools:IsModuleEnabled(GROUP_KEYS[i]) then
        anyGroupEnabled = true
        break
    end
end
if not anyGroupEnabled then return end

-- =============================================================
-- Defaults per group
-- =============================================================
local function GroupDefaults(idx)
    return {
        enabled       = idx == 1,
        locked        = true,
        preview       = false,
        posX          = (idx - 1) * 260,
        posY          = 0,
        maxBars       = 20,
        spacing       = 2,
        growDir       = "Down",
        useClassColor = true,
        showName      = true,
        showTimer     = true,
        showReadyText = false,
        showHeal      = true,
        showDef       = true,
        showCC        = idx == 1,
        showMove      = false,
        timerGroup    = {
            barBgColorR = 0,   barBgColorG = 0,   barBgColorB = 0,   barBgColorA = 0.55,
            barColorR   = 0.2, barColorG   = 0.8, barColorB   = 0.2, barColorA   = 1,
            height      = 22,  width       = 210,
            iconSize    = 22,  iconSide    = "LEFT",
            iconOffsetX = -1,  iconOffsetY = 0,
            showIcon    = true, texture    = "Melli",
        },
    }
end

-- =============================================================
-- ███████╗██████╗ ███████╗██╗     ██╗         ██████╗  █████╗ ████████╗ █████╗
-- ██╔════╝██╔══██╗██╔════╝██║     ██║         ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
-- ███████╗██████╔╝█████╗  ██║     ██║         ██║  ██║███████║   ██║   ███████║
-- ╚════██║██╔═══╝ ██╔══╝  ██║     ██║         ██║  ██║██╔══██║   ██║   ██╔══██║
-- ███████║██║     ███████╗███████╗███████╗    ██████╔╝██║  ██║   ██║   ██║  ██║
-- ╚══════╝╚═╝     ╚══════╝╚══════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
--
-- HOW TO UPDATE THIS LIST:
--   AddSpell( {specID, ...}, { id=spellID, aura=auraID_or_nil, cd=seconds, cat="heal|def|cc|move", name="DisplayName" })
--   specID list: https://wowpedia.fandom.com/wiki/SpecializationID
--   aura: the buff/debuff spell ID that appears on the player when the spell is active.
--         Set to nil if the spell applies no visible aura (COMM will still track it for addon users).
--   cd:   base cooldown in seconds. 0 = no cooldown (CC toggle spells).
--   cat:  "heal" | "def" | "cc" | "move"
-- =============================================================
local CD_DATA     = {}   -- [specID] = { entry, ... }
local SPELL_BY_ID = {}   -- [spellID] = entry  (used for COMM receive + UNIT_SPELLCAST_SUCCEEDED)

local function AddSpell(specs, entry)
    for _, spec in ipairs(specs) do
        CD_DATA[spec] = CD_DATA[spec] or {}
        table.insert(CD_DATA[spec], entry)
    end
    if not SPELL_BY_ID[entry.id] then
        SPELL_BY_ID[entry.id] = entry
    end
end

-- ===================== HEAL CDs =====================
--  Spec IDs: Druid(Resto)=105, Paladin(Holy)=65, Priest(Holy)=257, Priest(Disc)=256,
--            Shaman(Resto)=264, Monk(MW)=270, Evoker(Preserv)=1468
AddSpell({105},             { id=740,    aura=740,    cd=180, cat="heal", name="Tranquility" })
AddSpell({105},             { id=197721, aura=197721, cd=90,  cat="heal", name="Flourish" })
AddSpell({105},             { id=391528, aura=nil,    cd=120, cat="heal", name="Convoke" })
AddSpell({65},              { id=31821,  aura=31821,  cd=180, cat="heal", name="Aura Mastery" })
AddSpell({65},              { id=375576, aura=nil,    cd=60,  cat="heal", name="Divine Toll" })
AddSpell({65},              { id=200183, aura=200183, cd=120, cat="heal", name="Apotheosis" })
AddSpell({257},             { id=64843,  aura=64843,  cd=180, cat="heal", name="Divine Hymn" })
AddSpell({257},             { id=265202, aura=265202, cd=300, cat="heal", name="Salvation" })
AddSpell({256},             { id=62618,  aura=148065, cd=180, cat="heal", name="PW: Barrier" })
AddSpell({256},             { id=246287, aura=246287, cd=90,  cat="heal", name="Evangelism" })
AddSpell({264},             { id=108280, aura=nil,    cd=180, cat="heal", name="Healing Tide Totem" })
AddSpell({264},             { id=114052, aura=114052, cd=180, cat="heal", name="Ascendance" })
AddSpell({270},             { id=115310, aura=nil,    cd=180, cat="heal", name="Revival" })
AddSpell({270},             { id=325197, aura=nil,    cd=180, cat="heal", name="Invoke Chi-Ji" })
AddSpell({1468},            { id=363534, aura=nil,    cd=240, cat="heal", name="Rewind" })
AddSpell({1468},            { id=359816, aura=359816, cd=120, cat="heal", name="Dream Flight" })
AddSpell({1468},            { id=370537, aura=nil,    cd=90,  cat="heal", name="Stasis" })

-- ===================== DEFENSIVES =====================
--  Paladin: Holy=65 Prot=66 Ret=70 | Warrior: Arms=71 Fury=72 Prot=73
--  DK: Blood=250 Frost=251 Unholy=252 | DH: Havoc=577 Vengeance=581
--  Druid: Balance=102 Feral=103 Guardian=104 Resto=105
--  Hunter: BM=253 MM=254 SV=255 | Mage: Arcane=62 Fire=63 Frost=64
--  Monk: BM=268 WW=269 MW=270 | Priest: Disc=256 Holy=257 Shadow=258
--  Rogue: Sin=259 Out=260 Sub=261 | Shaman: Ele=262 Enh=263 Resto=264
--  Warlock: Aff=265 Demo=266 Dest=267 | Evoker: Dev=1467 Pres=1468 Aug=1473
AddSpell({65,66,70},        { id=642,    aura=642,    cd=300, cat="def", name="Divine Shield" })
AddSpell({65,66,70},        { id=1022,   aura=1022,   cd=300, cat="def", name="Blessing of Prot." })
AddSpell({65,66,70},        { id=6940,   aura=6940,   cd=120, cat="def", name="Blessing of Sacrifice" })
AddSpell({65,66,70},        { id=633,    aura=nil,    cd=600, cat="def", name="Lay on Hands" })
AddSpell({71,72,73},        { id=871,    aura=871,    cd=240, cat="def", name="Shield Wall" })
AddSpell({71,72,73},        { id=97462,  aura=97462,  cd=180, cat="def", name="Rallying Cry" })
AddSpell({71,72},           { id=118038, aura=118038, cd=120, cat="def", name="Die by the Sword" })
AddSpell({250,251,252},     { id=48792,  aura=48792,  cd=180, cat="def", name="Icebound Fortitude" })
AddSpell({250,251,252},     { id=48707,  aura=48707,  cd=60,  cat="def", name="Anti-Magic Shell" })
AddSpell({250},             { id=55233,  aura=55233,  cd=90,  cat="def", name="Vampiric Blood" })
AddSpell({250,251,252},     { id=51052,  aura=nil,    cd=120, cat="def", name="Anti-Magic Zone" })
AddSpell({577,581},         { id=196718, aura=nil,    cd=180, cat="def", name="Darkness" })
AddSpell({577,581},         { id=212800, aura=212800, cd=60,  cat="def", name="Blur" })
AddSpell({581},             { id=203720, aura=203720, cd=20,  cat="def", name="Demon Spikes" })
AddSpell({102,103,104,105}, { id=22812,  aura=22812,  cd=60,  cat="def", name="Barkskin" })
AddSpell({103,104},         { id=61336,  aura=61336,  cd=180, cat="def", name="Survival Instincts" })
AddSpell({253,254,255},     { id=109304, aura=nil,    cd=120, cat="def", name="Exhilaration" })
AddSpell({255},             { id=264735, aura=264735, cd=180, cat="def", name="Surv. of the Fittest" })
AddSpell({62,63,64},        { id=45438,  aura=45438,  cd=240, cat="def", name="Ice Block" })
AddSpell({62,63,64},        { id=235450, aura=235450, cd=25,  cat="def", name="Prismatic Barrier" })
AddSpell({268,269,270},     { id=115203, aura=115203, cd=420, cat="def", name="Fortifying Brew" })
AddSpell({268,269},         { id=122470, aura=122470, cd=90,  cat="def", name="Touch of Karma" })
AddSpell({258},             { id=47585,  aura=47585,  cd=120, cat="def", name="Dispersion" })
AddSpell({257},             { id=47788,  aura=47788,  cd=180, cat="def", name="Guardian Spirit" })
AddSpell({259,260,261},     { id=5277,   aura=5277,   cd=120, cat="def", name="Evasion" })
AddSpell({259,260,261},     { id=31224,  aura=31224,  cd=60,  cat="def", name="Cloak of Shadows" })
AddSpell({262,263,264},     { id=108271, aura=108271, cd=90,  cat="def", name="Astral Shift" })
AddSpell({265,266,267},     { id=104773, aura=104773, cd=180, cat="def", name="Unending Resolve" })
AddSpell({1467,1468,1473},  { id=374348, aura=374348, cd=90,  cat="def", name="Obsidian Scales" })

-- ===================== CC =====================
AddSpell({62,63,64},        { id=122,    aura=nil,    cd=0,   cat="cc", name="Polymorph" })
AddSpell({64},              { id=113724, aura=82691,  cd=45,  cat="cc", name="Ring of Frost" })
AddSpell({63},              { id=31661,  aura=31661,  cd=20,  cat="cc", name="Dragon's Breath" })
AddSpell({262,263,264},     { id=51514,  aura=51514,  cd=30,  cat="cc", name="Hex" })
AddSpell({268,269,270},     { id=115078, aura=115078, cd=15,  cat="cc", name="Paralysis" })
AddSpell({268,269,270},     { id=119381, aura=119381, cd=60,  cat="cc", name="Leg Sweep" })
AddSpell({577,581},         { id=202137, aura=204490, cd=60,  cat="cc", name="Sigil of Silence" })
AddSpell({577,581},         { id=202138, aura=202138, cd=60,  cat="cc", name="Sigil of Chains" })
AddSpell({253,254,255},     { id=187650, aura=3355,   cd=30,  cat="cc", name="Freezing Trap" })
AddSpell({259,260,261},     { id=2094,   aura=2094,   cd=120, cat="cc", name="Blind" })
AddSpell({259,260,261},     { id=408,    aura=408,    cd=20,  cat="cc", name="Kidney Shot" })
AddSpell({102,103,104,105}, { id=33786,  aura=33786,  cd=0,   cat="cc", name="Cyclone" })
AddSpell({102,103,104},     { id=339,    aura=339,    cd=0,   cat="cc", name="Ent. Roots" })
AddSpell({256,257},         { id=9484,   aura=9484,   cd=0,   cat="cc", name="Shackle Undead" })
AddSpell({265,266,267},     { id=5782,   aura=5782,   cd=40,  cat="cc", name="Fear" })
AddSpell({71,72,73},        { id=107570, aura=107570, cd=30,  cat="cc", name="Storm Bolt" })
AddSpell({250,251,252},     { id=47476,  aura=47476,  cd=60,  cat="cc", name="Strangulate" })
AddSpell({1467,1468,1473},  { id=370783, aura=370783, cd=30,  cat="cc", name="Oppressing Roar" })
AddSpell({66,73},           { id=853,    aura=853,    cd=60,  cat="cc", name="Hammer of Justice" })

-- ===================== MOBILITY =====================
AddSpell({62,63,64},        { id=212653, aura=nil,    cd=25,  cat="move", name="Shimmer" })
AddSpell({253,254,255},     { id=781,    aura=nil,    cd=20,  cat="move", name="Disengage" })
AddSpell({65,66,70},        { id=190784, aura=190784, cd=45,  cat="move", name="Divine Steed" })
AddSpell({268,269,270},     { id=109132, aura=nil,    cd=20,  cat="move", name="Roll" })
AddSpell({269,270},         { id=101545, aura=nil,    cd=25,  cat="move", name="Flying Serpent Kick" })
AddSpell({577,581},         { id=195072, aura=nil,    cd=10,  cat="move", name="Fel Rush" })
AddSpell({577,581},         { id=198793, aura=nil,    cd=25,  cat="move", name="Vengeful Retreat" })
AddSpell({250,251,252},     { id=48265,  aura=nil,    cd=45,  cat="move", name="Death's Advance" })
AddSpell({252},             { id=212552, aura=nil,    cd=60,  cat="move", name="Wraith Walk" })
AddSpell({262,263},         { id=192063, aura=nil,    cd=30,  cat="move", name="Gust of Wind" })
AddSpell({1467,1468,1473},  { id=358267, aura=nil,    cd=35,  cat="move", name="Hover" })
AddSpell({71,72,73},        { id=100,    aura=nil,    cd=20,  cat="move", name="Charge" })
AddSpell({259,260,261},     { id=36554,  aura=nil,    cd=30,  cat="move", name="Shadowstep" })

-- =============================================================
-- Category colors
-- =============================================================
local CAT_COLOR = {
    heal = { 0.2, 1.0, 0.45 },
    def  = { 1.0, 0.75, 0.1 },
    cc   = { 0.7, 0.2,  1.0 },
    move = { 0.2, 0.75, 1.0 },
}

local HANDLE_H = 20

-- =============================================================
-- Group state table
-- =============================================================
local GROUPS = {}

-- =============================================================
-- Helpers
-- =============================================================
local function IsCatEnabled(db, cat)
    if cat == "heal" then return db.showHeal ~= false end
    if cat == "def"  then return db.showDef  ~= false end
    if cat == "cc"   then return db.showCC   ~= false end
    if cat == "move" then return db.showMove ~= false end
    return false
end

-- =============================================================
-- Raid Inspect — spec detection for raid members
-- PartySync is intentionally disabled in raids (AddOnMessageLockdown).
-- This local system uses NotifyInspect, which IS allowed in raids.
-- M+ / party path → unchanged (PartySpec / PartySync).
-- =============================================================
local RaidSpecCache  = {}   -- [guid] = specID
local RaidUnitByGuid = {}   -- [guid] = unitToken
local RaidQueue      = {}   -- FIFO of unit tokens to inspect
local RaidQueued     = {}   -- [guid] = true (dedup)
local raidActiveGUID = nil
local raidInspTimer  = nil
local RAID_TIMEOUT   = 1.5
local RAID_INTERVAL  = 0.25

local function RaidClearActive()
    raidActiveGUID = nil
    if raidInspTimer then raidInspTimer:Cancel(); raidInspTimer = nil end
    if _G.ClearInspectPlayer then _G.ClearInspectPlayer() end
end

local function RaidPumpQueue()
    if raidActiveGUID then return end
    while #RaidQueue > 0 do
        local unit = table.remove(RaidQueue, 1)
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then
                RaidQueued[guid] = nil
                if _G.CanInspect and _G.CanInspect(unit) then
                    raidActiveGUID = guid
                    _G.NotifyInspect(unit)
                    raidInspTimer = C_Timer.NewTimer(RAID_TIMEOUT, function()
                        RaidClearActive()
                        RaidPumpQueue()
                    end)
                    return
                end
            end
        end
    end
end

local function RaidQueueUnit(unit)
    if not UnitExists(unit) or _G.UnitIsUnit(unit, "player") then return end
    local guid = UnitGUID(unit)
    if not guid or RaidQueued[guid] then return end
    if RaidSpecCache[guid] and RaidSpecCache[guid] > 0 then return end
    RaidQueued[guid] = true
    RaidQueue[#RaidQueue + 1] = unit
    RaidPumpQueue()
end

local function RaidRebuildRoster()
    if not IsInRaid() then return end
    wipe(RaidUnitByGuid)
    wipe(RaidQueue)
    wipe(RaidQueued)
    RaidClearActive()
    for i = 1, GetNumGroupMembers() do
        local unit = "raid" .. i
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then
                RaidUnitByGuid[guid] = unit
                RaidQueueUnit(unit)
            end
        end
    end
end

local function GetUnitSpecID(unit)
    local specID = 0
    if PartySpec then specID = PartySpec:GetSpec(unit) or 0 end
    if specID == 0 and unit == "player" then
        local id = GetSpecializationInfo(GetSpecialization() or 1)
        specID = id or 0
    end
    -- Raid fallback: use local inspect cache (PartySync is disabled in raids)
    if specID == 0 and IsInRaid() then
        local guid = UnitGUID(unit)
        if guid then specID = RaidSpecCache[guid] or 0 end
    end
    return specID
end

-- Resolve AceComm sender name → GUID (handles cross-realm "Name-Realm" format)
local function GetGUIDByName(name)
    local shortName = name:match("^([^%-]+)") or name
    local units = { "player" }
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do units[#units + 1] = "raid" .. i end
    else
        for i = 1, 4 do units[#units + 1] = "party" .. i end
    end
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local n = UnitName(unit) or ""
            if n == shortName or n == name then
                return UnitGUID(unit)
            end
        end
    end
    return nil
end

-- =============================================================
-- AceComm — broadcast own CD cast to group, receive from others
-- =============================================================
local function BroadcastCD(spellID)
    if not AceComm then return end
    local msg = "CD:" .. spellID
    local ok, err = pcall(function()
        if IsInRaid() then
            AceComm:SendCommMessage(COMM_PREFIX, msg, "RAID")
        elseif IsInGroup() then
            AceComm:SendCommMessage(COMM_PREFIX, msg, "PARTY")
        end
    end)
    -- silently ignore errors (not in group, throttled, etc.)
end

-- Called when we receive a COMM from a teammate
local function OnCDCommReceived(guid, spellID)
    for i = 1, MAX_GROUPS do
        local g = GROUPS[i]
        if g and g.db.enabled and not g.isPreviewing then
            if g.activeBars[guid] and g.activeBars[guid][spellID] then
                -- Only trigger if not already on cooldown (avoids UNIT_AURA double-trigger)
                local data = g.activeBars[guid][spellID]
                if not data.startTime then
                    -- forward-declared; defined below
                    TriggerCooldown(g, guid, spellID)
                end
            end
        end
    end
end

-- Register COMM receiver once (after GROUPS are built below).
-- We use a closure-style forward call so TriggerCooldown is defined by then.
local commRegistered = false
local function EnsureCommRegistered()
    if commRegistered or not AceComm then return end
    commRegistered = true
    pcall(function()
        AceComm:RegisterComm(COMM_PREFIX, function(_, msg, _, sender)
            -- WoW addon messages are NOT delivered to self on PARTY/RAID channels,
            -- so no need to filter sender == player.
            local spellIDStr = msg and msg:match("^CD:(%d+)$")
            if not spellIDStr then return end
            local spellID = tonumber(spellIDStr)
            if not spellID then return end

            -- Only track spells we know about
            if not SPELL_BY_ID[spellID] then return end

            local guid = GetGUIDByName(sender)
            if not guid then return end

            OnCDCommReceived(guid, spellID)
        end)
    end)
end

-- =============================================================
-- Bar visuals
-- =============================================================
local function ApplyBarSettings(bar, db)
    if not bar then return end
    local tg = db.timerGroup or {}
    local w  = tg.width  or 210
    local h  = tg.height or 22
    bar:SetSize(w, h)

    if bar.BG then
        bar.BG:SetColorTexture(
            tg.barBgColorR or 0, tg.barBgColorG or 0,
            tg.barBgColorB or 0, tg.barBgColorA or 0.55)
    end
    if bar.Bar then
        local tex = LSM and LSM:Fetch("statusbar", tg.texture or "Melli")
            or "Interface\AddOns\InfinityCore\Textures\bars\\rv1"
        bar.Bar:SetStatusBarTexture(tex)
    end
    local iconSize = tg.iconSize or 22
    if bar.Icon then
        bar.Icon:SetSize(iconSize, iconSize)
        bar.Icon:ClearAllPoints()
        local side = tg.iconSide or "LEFT"
        if side == "LEFT" then
            bar.Icon:SetPoint("RIGHT", bar, "LEFT", tg.iconOffsetX or -1, tg.iconOffsetY or 0)
        else
            bar.Icon:SetPoint("LEFT", bar, "RIGHT", tg.iconOffsetX or 1, tg.iconOffsetY or 0)
        end
        bar.Icon:SetShown(tg.showIcon ~= false)
    end
    if bar.CatStripe then
        bar.CatStripe:SetHeight(h)
    end
end

-- =============================================================
-- Bar pool (per group)
-- =============================================================
local function AcquireBar(g)
    local bar = table.remove(g.barPool)
    if not bar then
        local fontPath = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"
        bar = CreateFrame("Frame", nil, g.anchor)
        bar:SetSize(210, 22)

        bar.BG = bar:CreateTexture(nil, "BACKGROUND")
        bar.BG:SetAllPoints()

        bar.Bar = CreateFrame("StatusBar", nil, bar)
        bar.Bar:SetAllPoints()
        bar.Bar:SetMinMaxValues(0, 1)
        bar.Bar:SetValue(1)

        bar.CatStripe = bar:CreateTexture(nil, "OVERLAY")
        bar.CatStripe:SetSize(3, 22)
        bar.CatStripe:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)

        bar.Icon = CreateFrame("Frame", nil, bar)
        bar.Icon:SetSize(22, 22)
        bar.Icon:SetPoint("RIGHT", bar, "LEFT", -1, 0)
        bar.IconTex = bar.Icon:CreateTexture(nil, "ARTWORK")
        bar.IconTex:SetAllPoints(bar.Icon)
        bar.IconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        bar.NameText = bar.Bar:CreateFontString(nil, "OVERLAY")
        bar.NameText:SetFont(fontPath, 11, "OUTLINE")
        bar.NameText:SetPoint("LEFT", bar.Bar, "LEFT", 6, 0)
        bar.NameText:SetJustifyH("LEFT")
        bar.NameText:SetTextColor(1, 1, 1, 1)

        bar.TimerText = bar.Bar:CreateFontString(nil, "OVERLAY")
        bar.TimerText:SetFont(fontPath, 11, "OUTLINE")
        bar.TimerText:SetPoint("RIGHT", bar.Bar, "RIGHT", -4, 0)
        bar.TimerText:SetJustifyH("RIGHT")
        bar.TimerText:SetTextColor(1, 1, 1, 1)
    end

    bar:Show()
    return bar
end

local function ReleaseBar(g, bar)
    if not bar then return end
    bar:Hide()
    bar:SetScript("OnUpdate", nil)
    bar._lastDisplayed  = nil
    bar._lastSortUpdate = nil
    table.insert(g.barPool, bar)
end

-- =============================================================
-- Trigger cooldown on a bar  (forward-declared above)
-- =============================================================
function TriggerCooldown(g, guid, spellID)
    local playerBars = g.activeBars[guid]
    if not playerBars then return end
    local data = playerBars[spellID]
    if not data then return end

    local db    = g.db
    local bar   = data.bar
    local entry = data.entry
    local cdDur = entry.cd

    if cdDur <= 0 then
        bar.Bar:SetValue(0)
        if bar.TimerText then bar.TimerText:SetText("") end
        C_Timer.After(0.6, function()
            if bar and bar:IsShown() and not data.startTime then
                bar.Bar:SetValue(1)
            end
        end)
        return
    end

    data.startTime = GetTime()
    bar.Bar:SetValue(0)

    bar:SetScript("OnUpdate", function(self)
        local elapsed   = GetTime() - data.startTime
        local remaining = cdDur - elapsed

        if remaining > 0 then
            self.Bar:SetValue(elapsed / cdDur)
            if self.TimerText and db.showTimer then
                local displayVal
                if remaining > 6 then
                    displayVal = math.floor(remaining)
                    if displayVal ~= self._lastDisplayed then
                        self._lastDisplayed = displayVal
                        self.TimerText:SetText(tostring(displayVal))
                    end
                else
                    displayVal = math.floor(remaining * 10)
                    if displayVal ~= self._lastDisplayed then
                        self._lastDisplayed = displayVal
                        self.TimerText:SetText(string.format("%.1f", remaining))
                    end
                end
            end
        else
            data.startTime = nil
            self.Bar:SetValue(1)
            self._lastDisplayed = nil
            if self.TimerText then
                self.TimerText:SetText(db.showReadyText and "Ready" or "")
            end
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- =============================================================
-- ReLayout: sort and position all bars for a group
-- =============================================================
local CAT_ORDER = { "heal", "def", "cc", "move" }

local function GroupReLayout(g)
    if not g.anchor then return end
    local db = g.db

    wipe(g.usedBarsList)
    for _, cat in ipairs(CAT_ORDER) do
        if IsCatEnabled(db, cat) then
            for guid, spells in pairs(g.activeBars) do
                for spellID, data in pairs(spells) do
                    if data.entry.cat == cat then
                        table.insert(g.usedBarsList, data)
                    end
                end
            end
        end
    end

    local tg      = db.timerGroup or {}
    local barH    = tg.height or 22
    local spacing = db.spacing or 2
    local maxBars = db.maxBars or 20
    local growDir = db.growDir or "Down"
    local shown   = 0

    for _, data in ipairs(g.usedBarsList) do
        local bar = data.bar
        if shown < maxBars then
            bar:ClearAllPoints()
            local offset = shown * (barH + spacing)
            if growDir == "Down" then
                bar:SetPoint("TOPLEFT", g.anchor, "BOTTOMLEFT", 0, -offset)
            else
                bar:SetPoint("BOTTOMLEFT", g.anchor, "TOPLEFT", 0, offset)
            end
            bar:Show()
            shown = shown + 1
        else
            bar:Hide()
        end
    end
end

-- =============================================================
-- Bar color
-- =============================================================
local function SetBarColor(bar, unit, entry, db)
    local tg = db.timerGroup or {}
    if db.useClassColor then
        local _, classTag = UnitClass(unit)
        if classTag then
            local cc = C_ClassColor.GetClassColor(classTag)
            if cc then
                bar.Bar:SetStatusBarColor(cc.r, cc.g, cc.b, 1)
                return
            end
        end
    end
    local col = CAT_COLOR[entry.cat] or { 0.5, 0.5, 0.5 }
    bar.Bar:SetStatusBarColor(col[1], col[2], col[3], 1)
end

-- =============================================================
-- Build/update bars for a single unit within a group
-- =============================================================
local function UpdateGroupUnitBars(g, guid, unit, specID)
    local db = g.db
    g.activeBars[guid] = g.activeBars[guid] or {}
    local spellList = (specID and specID > 0) and CD_DATA[specID] or {}

    local validSpells = {}
    for _, entry in ipairs(spellList) do
        if IsCatEnabled(db, entry.cat) then
            validSpells[entry.id] = entry
        end
    end

    -- Release stale bars
    for spellID, data in pairs(g.activeBars[guid]) do
        if not validSpells[spellID] then
            ReleaseBar(g, data.bar)
            g.activeBars[guid][spellID] = nil
        end
    end

    -- Acquire new bars
    for spellID, entry in pairs(validSpells) do
        if not g.activeBars[guid][spellID] then
            local bar = AcquireBar(g)
            ApplyBarSettings(bar, db)

            if spellID > 0 then
                local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
                if ok and info and info.iconID then
                    bar.IconTex:SetTexture(info.iconID)
                else
                    bar.IconTex:SetTexture(134400)
                end
            end

            if bar.NameText then
                local pName = UnitName(unit) or unit
                bar.NameText:SetText(pName or "")
            end

            local col = CAT_COLOR[entry.cat] or { 0.5, 0.5, 0.5 }
            bar.CatStripe:SetColorTexture(col[1], col[2], col[3], 0.9)
            SetBarColor(bar, unit, entry, db)

            if bar.TimerText then bar.TimerText:SetText("") end

            g.activeBars[guid][spellID] = {
                bar       = bar,
                entry     = entry,
                startTime = nil,
                unit      = unit,
            }
        else
            local data = g.activeBars[guid][spellID]
            data.unit  = unit
            SetBarColor(data.bar, unit, entry, db)
            local pName = UnitName(unit) or unit
            if data.bar.NameText then
                data.bar.NameText:SetText(pName or "")
            end
        end
    end
end

-- =============================================================
-- Full layout update for a group
-- =============================================================
local function UpdateGroupLayout(g)
    if not g.db.enabled or not g.anchor then return end
    if g.isPreviewing then return end

    local currentGuids = {}
    local units = { "player" }
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do table.insert(units, "raid" .. i) end
    else
        for i = 1, 4 do table.insert(units, "party" .. i) end
    end

    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then currentGuids[guid] = unit end
        end
    end

    for guid in pairs(g.activeBars) do
        if not currentGuids[guid] then
            for _, data in pairs(g.activeBars[guid]) do
                ReleaseBar(g, data.bar)
            end
            g.activeBars[guid] = nil
        end
    end

    for guid, unit in pairs(currentGuids) do
        local specID = GetUnitSpecID(unit)
        UpdateGroupUnitBars(g, guid, unit, specID)
    end

    GroupReLayout(g)
end

-- =============================================================
-- Move handle & lock management
-- =============================================================
local function UpdateGroupLock(g)
    local db = g.db
    if not g.anchor then return end

    local unlocked = not db.locked
    g.anchor:EnableMouse(unlocked)
    if g.anchor.bg    then g.anchor.bg:SetShown(unlocked)    end
    if g.anchor.label then g.anchor.label:SetShown(unlocked) end
end

-- =============================================================
-- Create anchor + drag handle for a group
-- =============================================================
local function CreateGroupAnchor(g)
    if g.anchor then return end
    local db       = g.db
    local gid      = g.gid
    local tg       = db.timerGroup or {}
    local barW     = tg.width or 210
    local fontPath = InfinityTools.MAIN_FONT or "Fonts\\FRIZQT__.TTF"

    local anchor = CreateFrame("Frame", "RRT_CDTracker_Anchor_" .. gid, UIParent)
    anchor:SetSize(barW, HANDLE_H)
    anchor:SetPoint("CENTER", UIParent, "CENTER", db.posX or 0, db.posY or 0)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    g.anchor = anchor

    local bg = anchor:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 1, 0, 0.5)
    bg:SetShown(not db.locked)
    anchor.bg = bg

    local label = anchor:CreateFontString(nil, "OVERLAY")
    label:SetFont(fontPath, 11, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetText("CD Tracker — Group " .. gid)
    label:SetTextColor(1, 1, 1, 1)
    label:SetShown(not db.locked)
    anchor.label = label

    InfinityTools:RegisterHUD(g.moduleKey, anchor)

    anchor:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not db.locked then
            self.isMoving = true
            self:StartMoving()
        end
    end)
    anchor:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self.isMoving = false
            self:StopMovingOrSizing()
            local fx, fy = self:GetCenter()
            local ux, uy = UIParent:GetCenter()
            if fx and ux then
                db.posX = math.floor(fx - ux + 0.5)
                db.posY = math.floor(fy - uy + 0.5)
            end
            InfinityTools:UpdateState(g.moduleKey .. ".DatabaseChanged", { key = "pos" })
        end
    end)

    UpdateGroupLock(g)
end

-- =============================================================
-- Preview mode per group
-- =============================================================
local PREVIEW_EXAMPLES = {
    heal = { name="Divine Hymn",   icon=237542, cd=180, player="Anaztia"   },
    def  = { name="Rallying Cry",  icon=132351, cd=180, player="Gorlathos" },
    cc   = { name="Ring of Frost", icon=135848, cd=45,  player="Melliren"  },
    move = { name="Disengage",     icon=132294, cd=20,  player="Vharynn"   },
}

local function ClearGroupPreview(g)
    for _, bar in ipairs(g.previewBars) do
        ReleaseBar(g, bar)
    end
    wipe(g.previewBars)
    g.isPreviewing = false
end

local function StartGroupPreview(g)
    ClearGroupPreview(g)
    g.isPreviewing = true
    local db = g.db

    local tg      = db.timerGroup or {}
    local barH    = tg.height or 22
    local spacing = db.spacing or 2
    local growDir = db.growDir or "Down"
    local shown   = 0

    for _, cat in ipairs(CAT_ORDER) do
        if IsCatEnabled(db, cat) then
            local ex = PREVIEW_EXAMPLES[cat]
            if ex then
                local bar = AcquireBar(g)
                ApplyBarSettings(bar, db)

                bar.IconTex:SetTexture(ex.icon)
                if bar.NameText then
                    bar.NameText:SetText(ex.player)
                end

                local col = CAT_COLOR[cat] or { 0.5, 0.5, 0.5 }
                bar.CatStripe:SetColorTexture(col[1], col[2], col[3], 0.9)
                bar.Bar:SetStatusBarColor(col[1], col[2], col[3], 0.9)

                bar.Bar:SetValue(0.5)
                if bar.TimerText and db.showTimer then
                    bar.TimerText:SetText(tostring(math.floor(ex.cd * 0.5)))
                end

                bar:ClearAllPoints()
                local offset = shown * (barH + spacing)
                if growDir == "Down" then
                    bar:SetPoint("TOPLEFT", g.anchor, "BOTTOMLEFT", 0, -offset)
                else
                    bar:SetPoint("BOTTOMLEFT", g.anchor, "TOPLEFT", 0, offset)
                end
                bar:Show()

                table.insert(g.previewBars, bar)
                shown = shown + 1
            end
        end
    end
end

-- =============================================================
-- Init: create GROUPS entries and load DBs
-- =============================================================
for i = 1, MAX_GROUPS do
    if InfinityTools:IsModuleEnabled(GROUP_KEYS[i]) then
        GROUPS[i] = {
            gid          = i,
            moduleKey    = GROUP_KEYS[i],
            db           = InfinityTools:GetModuleDB(GROUP_KEYS[i], GroupDefaults(i)),
            anchor       = nil,
            activeBars   = {},
            usedBarsList = {},
            barPool      = {},
            isPreviewing = false,
            previewBars  = {},
        }
    end
end

-- Register AceComm receiver now that GROUPS and TriggerCooldown are defined
EnsureCommRegistered()

-- =============================================================
-- Settings callbacks (per group)
-- =============================================================
local function SetupGroupCallbacks(g)
    local moduleKey = g.moduleKey
    local db        = g.db

    InfinityTools:WatchState(moduleKey .. ".DatabaseChanged", moduleKey, function(info)
        if not info or not info.key then return end
        local key = info.key

        if key == "posX" or key == "posY" then
            if g.anchor then
                g.anchor:ClearAllPoints()
                g.anchor:SetPoint("CENTER", UIParent, "CENTER", db.posX or 0, db.posY or 0)
            end

        elseif key == "enabled" then
            if db.enabled then
                if not g.anchor then CreateGroupAnchor(g) end
                UpdateGroupLayout(g)
            else
                for guid, spells in pairs(g.activeBars) do
                    for _, data in pairs(spells) do data.bar:Hide() end
                end
            end

        elseif key == "preview" then
            if db.preview then
                if not g.anchor then CreateGroupAnchor(g) end
                StartGroupPreview(g)
            else
                ClearGroupPreview(g)
                UpdateGroupLayout(g)
            end

        elseif key == "locked" then
            UpdateGroupLock(g)

        elseif key == "showHeal" or key == "showDef" or key == "showCC" or key == "showMove" then
            if g.isPreviewing then
                StartGroupPreview(g)
            else
                UpdateGroupLayout(g)
            end

        elseif key == "timerGroup" or key == "spacing" or key == "growDir" or
               key == "maxBars"   or key == "useClassColor" or
               key == "showName"  or key == "showTimer" or key == "showReadyText" then
            for guid, spells in pairs(g.activeBars) do
                for spellID, data in pairs(spells) do
                    ApplyBarSettings(data.bar, db)
                    SetBarColor(data.bar, data.unit, data.entry, db)
                    if data.bar.NameText then
                        local pName = UnitName(data.unit) or data.unit
                        data.bar.NameText:SetText(db.showName and (pName or "") or "")
                    end
                end
            end
            if g.anchor then
                local tg = db.timerGroup or {}
                g.anchor:SetWidth(tg.width or 210)
            end
            if g.isPreviewing then
                StartGroupPreview(g)
            else
                GroupReLayout(g)
            end
        end
    end)

    InfinityTools:WatchState(moduleKey .. ".ButtonClicked", moduleKey, function(info)
        if not info then return end
        if info.key == "btn_reset" then
            db.posX = 0
            db.posY = 0
            if g.anchor then
                g.anchor:ClearAllPoints()
                g.anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        end
    end)
end

for i = 1, MAX_GROUPS do
    if GROUPS[i] then
        SetupGroupCallbacks(GROUPS[i])
    end
end

-- =============================================================
-- Detection 1: UNIT_SPELLCAST_SUCCEEDED
--   Player self only — spell IDs are never secret for the caster.
--   Broadcasts via AceComm so teammates with the addon track our CD.
-- =============================================================
InfinityTools:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", INFINITY_MODULE_KEY, function(_, unit, _, rawSpellID)
    if unit ~= "player" then return end

    -- rawSpellID is safe (never secret for self)
    local spellID = rawSpellID
    if not spellID or spellID == 0 then return end

    -- Only act on tracked spells
    if not SPELL_BY_ID[spellID] then return end

    local guid = UnitGUID("player")
    if not guid then return end

    -- Trigger bars locally
    for i = 1, MAX_GROUPS do
        local g = GROUPS[i]
        if g and g.db.enabled and not g.isPreviewing then
            if g.activeBars[guid] and g.activeBars[guid][spellID] then
                TriggerCooldown(g, guid, spellID)
            end
        end
    end

    -- Broadcast to group so teammates see our cooldown
    BroadcastCD(spellID)
end)

-- =============================================================
-- Detection 2 (fallback): UNIT_AURA
--   Covers players WITHOUT this addon for spells that apply a buff.
--   For players WITH the addon, COMM already handled the trigger, so
--   the startTime guard below prevents double-triggering.
-- =============================================================
local lastAuras = {}  -- [guid .. "_" .. auraID] = true

InfinityTools:RegisterEvent("UNIT_AURA", INFINITY_MODULE_KEY, function(_, unit)
    if not (unit == "player" or unit:find("^party%d") or unit:find("^raid%d")) then return end

    local guid = UnitGUID(unit)
    if not guid then return end

    for i = 1, MAX_GROUPS do
        local g = GROUPS[i]
        if g and g.db.enabled and not g.isPreviewing then
            local playerBars = g.activeBars[guid]
            if playerBars then
                for spellID, data in pairs(playerBars) do
                    local entry = data.entry
                    if entry.aura then
                        local present = false
                        if unit == "player" then
                            local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, entry.aura)
                            present = ok and aura ~= nil
                        else
                            -- GetAuraDataBySpellID is safe — entry.aura is our own constant, not secret
                            local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellID, unit, entry.aura)
                            present = ok and aura ~= nil
                        end

                        local key = guid .. "_" .. entry.aura
                        if present and not lastAuras[key] then
                            lastAuras[key] = true
                            -- Only trigger if not already on cooldown (COMM may have been faster)
                            if not data.startTime then
                                TriggerCooldown(g, guid, spellID)
                            end
                        elseif not present then
                            lastAuras[key] = nil
                        end
                    end
                end
            end
        end
    end
end)

-- =============================================================
-- Roster / spec events
-- =============================================================
InfinityTools:RegisterEvent("INFINITY_PARTY_SPEC_UPDATED", INFINITY_MODULE_KEY, function()
    for i = 1, MAX_GROUPS do
        local g = GROUPS[i]
        if g and not g.isPreviewing then UpdateGroupLayout(g) end
    end
end)

InfinityTools:RegisterEvent("GROUP_ROSTER_UPDATE", INFINITY_MODULE_KEY, function()
    if IsInRaid() then
        RaidRebuildRoster()
    end
    for i = 1, MAX_GROUPS do
        local g = GROUPS[i]
        if g and not g.isPreviewing then UpdateGroupLayout(g) end
    end
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    for i = 1, MAX_GROUPS do
        local g = GROUPS[i]
        if g then
            g.db.preview = false
            g.isPreviewing = false
        end
    end
    C_Timer.After(1, function()
        if IsInRaid() then RaidRebuildRoster() end
        for i = 1, MAX_GROUPS do
            local g = GROUPS[i]
            if g and g.db.enabled then
                CreateGroupAnchor(g)
                UpdateGroupLayout(g)
            end
        end
    end)
end)

-- Raid: lit la spec dès que l'inspect est prêt, met à jour les barres
InfinityTools:RegisterEvent("INSPECT_READY", INFINITY_MODULE_KEY, function(_, guid)
    if not IsInRaid() or guid ~= raidActiveGUID then return end
    local unit = RaidUnitByGuid[guid]
    if unit and UnitExists(unit) then
        local specID = _G.GetInspectSpecialization and _G.GetInspectSpecialization(unit)
        if specID and specID > 0 then
            RaidSpecCache[guid] = specID
            for i = 1, MAX_GROUPS do
                local g = GROUPS[i]
                if g and g.db.enabled and not g.isPreviewing then
                    UpdateGroupUnitBars(g, guid, unit, specID)
                    GroupReLayout(g)
                end
            end
        end
    end
    RaidClearActive()
    C_Timer.After(RAID_INTERVAL, RaidPumpQueue)
end)

-- =============================================================
-- Global Edit Mode — unlocks ALL groups simultaneously
-- =============================================================
InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    for i = 1, MAX_GROUPS do
        local g = GROUPS[i]
        if g and g.db.enabled then
            if not g.anchor then CreateGroupAnchor(g) end
            g.db.locked = not enabled
            UpdateGroupLock(g)
            if enabled then
                g.db.preview = true
                StartGroupPreview(g)
            else
                g.db.preview = false
                ClearGroupPreview(g)
                UpdateGroupLayout(g)
            end
        end
    end
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)

