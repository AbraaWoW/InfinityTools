-- InfinityDB.lua - global shared database
-- Provides static data such as classes and specializations, reducing API calls and serving all modules.

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

-- Create the global database table
local InfinityDB = {}
_G.InfinityDB = InfinityDB

-------------------------------------------------------
-- Class data
-------------------------------------------------------
InfinityDB.Classes = {
    [1]  = { id = 1, name = "Warrior", nameEN = "WARRIOR", colorHex = "C79C6E", colorRGB = { 198, 155, 109 }, icon = 626003 },
    [2]  = { id = 2, name = "Paladin", nameEN = "PALADIN", colorHex = "F48CBA", colorRGB = { 244, 140, 186 }, icon = 626000 },
    [3]  = { id = 3, name = "Hunter", nameEN = "HUNTER", colorHex = "ABD473", colorRGB = { 170, 211, 114 }, icon = 626008 },
    [4]  = { id = 4, name = "Rogue", nameEN = "ROGUE", colorHex = "FFF468", colorRGB = { 255, 244, 104 }, icon = 626005 },
    [5]  = { id = 5, name = "Priest", nameEN = "PRIEST", colorHex = "FFFFFF", colorRGB = { 255, 255, 255 }, icon = 626004 },
    [6]  = { id = 6, name = "Death Knight", nameEN = "DEATHKNIGHT", colorHex = "C41E3A", colorRGB = { 196, 30, 58 }, icon = 135771 },
    [7]  = { id = 7, name = "Shaman", nameEN = "SHAMAN", colorHex = "0070DD", colorRGB = { 0, 112, 221 }, icon = 626006 },
    [8]  = { id = 8, name = "Mage", nameEN = "MAGE", colorHex = "3FC7EB", colorRGB = { 63, 199, 235 }, icon = 626001 },
    [9]  = { id = 9, name = "Warlock", nameEN = "WARLOCK", colorHex = "8788EE", colorRGB = { 135, 136, 238 }, icon = 626007 },
    [10] = { id = 10, name = "Monk", nameEN = "MONK", colorHex = "00FF98", colorRGB = { 0, 255, 152 }, icon = 626002 },
    [11] = { id = 11, name = "Druid", nameEN = "DRUID", colorHex = "FF7C0A", colorRGB = { 255, 124, 10 }, icon = 625999 },
    [12] = { id = 12, name = "Demon Hunter", nameEN = "DEMONHUNTER", colorHex = "A330C9", colorRGB = { 163, 48, 201 }, icon = 1260827 },
    [13] = { id = 13, name = "Evoker", nameEN = "EVOKER", colorHex = "33937F", colorRGB = { 51, 147, 127 }, icon = 4574311 },
}

-------------------------------------------------------
-- Specialization data
-------------------------------------------------------
InfinityDB.Specs = {
    -- Mage (8) - Intellect
    { id = 62, name = "Arcane", classID = 8, icon = 135932, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 30451 },
    { id = 63, name = "Fire", classID = 8, icon = 135810, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 133 },
    { id = 64, name = "Frost", classID = 8, icon = 135846, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 30455 },

    -- Paladin (2) - Strength/Intellect
    { id = 65, name = "Holy", classID = 2, icon = 135920, role = "HEALER", primaryStat = "Intellect", RangeSpell = 275773 },
    { id = 66, name = "Protection", classID = 2, icon = 236264, role = "TANK", primaryStat = "Strength", RangeSpell = 96231 },
    { id = 70, name = "Retribution", classID = 2, icon = 135873, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 383328 },

    -- Warrior (1) - Strength
    { id = 71, name = "Arms", classID = 1, icon = 132355, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 12294 },
    { id = 72, name = "Fury", classID = 1, icon = 132347, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 23881 },
    { id = 73, name = "Protection", classID = 1, icon = 132341, role = "TANK", primaryStat = "Strength", RangeSpell = 23922 },

    -- Druid (11) - Agility/Intellect
    { id = 102, name = "Balance", classID = 11, icon = 136096, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 8921 },
    { id = 103, name = "Feral", classID = 11, icon = 132115, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 22568 },
    { id = 104, name = "Guardian", classID = 11, icon = 132276, role = "TANK", primaryStat = "Agility", RangeSpell = 33917 },
    { id = 105, name = "Restoration", classID = 11, icon = 136041, role = "HEALER", primaryStat = "Intellect", RangeSpell = 8921 },

    -- Death Knight (6) - Strength
    { id = 250, name = "Blood", classID = 6, icon = 135770, role = "TANK", primaryStat = "Strength", RangeSpell = 49998 },
    { id = 251, name = "Frost", classID = 6, icon = 135773, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 49998 },
    { id = 252, name = "Unholy", classID = 6, icon = 135775, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 49998 },

    -- Hunter (3) - Agility
    { id = 253, name = "Beast Mastery", classID = 3, icon = 461112, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 187707 },
    { id = 254, name = "Marksmanship", classID = 3, icon = 236179, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 147362 },
    { id = 255, name = "Survival", classID = 3, icon = 461113, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 147362 },

    -- Priest (5) - Intellect
    { id = 256, name = "Discipline", classID = 5, icon = 135940, role = "HEALER", primaryStat = "Intellect", RangeSpell = 585 },
    { id = 257, name = "Holy", classID = 5, icon = 237542, role = "HEALER", primaryStat = "Intellect", RangeSpell = 585 },
    { id = 258, name = "Shadow", classID = 5, icon = 136207, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 8902 },

    -- Rogue (4) - Agility
    { id = 259, name = "Assassination", classID = 4, icon = 236270, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 1766 },
    { id = 260, name = "Outlaw", classID = 4, icon = 236286, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 1766 },
    { id = 261, name = "Subtlety", classID = 4, icon = 132320, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 1766 },

    -- Shaman (7) - Agility/Intellect
    { id = 262, name = "Elemental", classID = 7, icon = 136048, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 188196 },
    { id = 263, name = "Enhancement", classID = 7, icon = 237581, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 60103 },
    { id = 264, name = "Restoration", classID = 7, icon = 136052, role = "HEALER", primaryStat = "Intellect", RangeSpell = 188196 },

    -- Warlock (9) - Intellect
    { id = 265, name = "Affliction", classID = 9, icon = 136145, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 686 },
    { id = 266, name = "Demonology", classID = 9, icon = 136172, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 105174 },
    { id = 267, name = "Destruction", classID = 9, icon = 136186, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 116858 },

    -- Monk (10) - Agility
    { id = 268, name = "Brewmaster", classID = 10, icon = 608951, role = "TANK", primaryStat = "Agility", RangeSpell = 100780 },
    { id = 269, name = "Windwalker", classID = 10, icon = 608953, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 100780 },
    { id = 270, name = "Mistweaver", classID = 10, icon = 608952, role = "HEALER", primaryStat = "Intellect", RangeSpell = 100780 },

    -- Demon Hunter (12) - Agility
    { id = 577, name = "Havoc", classID = 12, icon = 1247264, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 162794 },
    { id = 581, name = "Vengeance", classID = 12, icon = 1247265, role = "TANK", primaryStat = "Agility", RangeSpell = 263642 },
    { id = 1480, name = "Fel-Scarred", classID = 12, icon = 7455385, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 473662 },

    -- Evoker (13) - Intellect
    { id = 1467, name = "Devastation", classID = 13, icon = 4511811, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 362969 },
    { id = 1468, name = "Preservation", classID = 13, icon = 4511812, role = "HEALER", primaryStat = "Intellect", RangeSpell = 362969 },
    { id = 1473, name = "Augmentation", classID = 13, icon = 5198700, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 395160 },
}

-------------------------------------------------------
-- Fast lookup tables (index tables)
-------------------------------------------------------

-- SpecID -> spec data
InfinityDB.SpecByID = {}
-- SpecID -> role key (tank/heal/dps)
InfinityDB.SpecRoleKeyByID = {}
-- Spec lists grouped by role
InfinityDB.SpecsByRole = {
    tank = {},
    heal = {},
    dps = {},
}
-- ClassID -> spec list
InfinityDB.SpecsByClassID = {}
for _, spec in ipairs(InfinityDB.Specs) do
    InfinityDB.SpecByID[spec.id] = spec

    local roleKey
    if spec.role == "TANK" then
        roleKey = "tank"
    elseif spec.role == "HEALER" then
        roleKey = "heal"
    elseif spec.role == "DAMAGER" or spec.role == "DPS" then
        roleKey = "dps"
    end
    InfinityDB.SpecRoleKeyByID[spec.id] = roleKey

    if roleKey and InfinityDB.SpecsByRole[roleKey] then
        table.insert(InfinityDB.SpecsByRole[roleKey], spec)
    end

    if spec.classID then
        InfinityDB.SpecsByClassID[spec.classID] = InfinityDB.SpecsByClassID[spec.classID] or {}
        table.insert(InfinityDB.SpecsByClassID[spec.classID], spec)
    end
end

-- Tank spec list
InfinityDB.TankSpecs = {
    [66] = true,  -- Paladin-Protection
    [73] = true,  -- Warrior-Protection
    [104] = true, -- Druid-Guardian
    [250] = true, -- Death Knight-Blood
    [268] = true, -- Monk-Brewmaster
    [581] = true, -- Demon Hunter-Vengeance
}

-- Healer spec list
InfinityDB.HealerSpecs = {
    [65] = true,   -- Paladin-Holy
    [105] = true,  -- Druid-Restoration
    [256] = true,  -- Priest-Discipline
    [257] = true,  -- Priest-Holy
    [264] = true,  -- Shaman-Restoration
    [270] = true,  -- Monk-Mistweaver
    [1468] = true, -- Evoker-Preservation
}

-- Class order (common order: DK, Warrior, Paladin, Hunter, Shaman, Evoker, Rogue, DH, Monk, Druid, Mage, Warlock, Priest)
InfinityDB.ClassOrder = { 6, 1, 2, 3, 7, 13, 4, 12, 10, 11, 8, 9, 5 }

-------------------------------------------------------
-- Global interrupt spell data for all classes (used by RevMplus.InterruptTracker and others)
-- [SpecID] = { id = SpellID, cd = BaseSeconds }
-- Only includes core interrupt spells (Kick/Counterspell/etc.). Specs without an interrupt use id=0.
-------------------------------------------------------
InfinityDB.InterruptData = {
    -- Death Knight
    [250] = { id = 47528, cd = 12 }, -- Blood: Mind Freeze
    [251] = { id = 47528, cd = 12 }, -- Frost: Mind Freeze
    [252] = { id = 47528, cd = 12 }, -- Unholy: Mind Freeze

    -- Demon Hunter
    [577] = { id = 183752, cd = 15 }, -- Havoc: Consume Magic
    [581] = { id = 183752, cd = 15 }, -- Vengeance: Consume Magic
    [1480] = { id = 183752, cd = 15 },
    -- Druid
    [102] = { id = 0, cd = 0 },       -- Balance: Solar Beam (not enabled)
    [103] = { id = 106839, cd = 15 }, -- Feral: Skull Bash
    [104] = { id = 106839, cd = 15 }, -- Guardian: Skull Bash
    [105] = { id = 0, cd = 0 },       -- Restoration: none

    -- Evoker
    [1467] = { id = 351338, cd = 20 }, -- Devastation: Quell
    [1468] = { id = 0, cd = 0 },       -- Preservation: none
    [1473] = { id = 351338, cd = 18 }, -- Augmentation: Quell

    -- Hunter
    [253] = { id = 147362, cd = 24 }, -- Beast Mastery: Counter Shot
    [254] = { id = 147362, cd = 24 }, -- Marksmanship: Counter Shot
    [255] = { id = 187707, cd = 15 }, -- Survival: Muzzle

    -- Mage
    [62] = { id = 2139, cd = 20 }, -- Arcane: Counterspell
    [63] = { id = 2139, cd = 20 }, -- Fire: Counterspell
    [64] = { id = 2139, cd = 20 }, -- Frost: Counterspell

    -- Monk
    [268] = { id = 116705, cd = 15 }, -- Brewmaster: Spear Hand Strike
    [269] = { id = 116705, cd = 15 }, -- Windwalker: Spear Hand Strike
    [270] = { id = 0, cd = 0 },       -- Mistweaver: none

    -- Paladin
    [66] = { id = 96231, cd = 15 }, -- Protection: Rebuke
    [70] = { id = 96231, cd = 15 }, -- Retribution: Rebuke
    [65] = { id = 0, cd = 0 },      -- Holy: none

    -- Priest
    [258] = { id = 15487, cd = 30 }, -- Shadow: Silence
    [256] = { id = 0, cd = 0 },      -- Discipline: none
    [257] = { id = 0, cd = 0 },      -- Holy: none

    -- Rogue
    [259] = { id = 1766, cd = 15 }, -- Assassination: Kick
    [260] = { id = 1766, cd = 15 }, -- Outlaw: Kick
    [261] = { id = 1766, cd = 15 }, -- Subtlety: Kick

    -- Shaman
    [262] = { id = 57994, cd = 12 }, -- Elemental: Wind Shear
    [263] = { id = 57994, cd = 12 }, -- Enhancement: Wind Shear
    [264] = { id = 57994, cd = 30 }, -- Restoration: Wind Shear

    -- Warlock
    [265] = { id = 19647, cd = 24 }, -- Affliction: Spell Lock
    [266] = { id = 19647, cd = 30 }, -- Demonology: Spell Lock
    [267] = { id = 19647, cd = 24 }, -- Destruction: Spell Lock

    -- Warrior
    [71] = { id = 6552, cd = 15 }, -- Arms: Pummel
    [72] = { id = 6552, cd = 15 }, -- Fury: Pummel
    [73] = { id = 6552, cd = 15 }, -- Protection: Pummel
}

-------------------------------------------------------
-- Teleport data (Mythic+ / instances)
-------------------------------------------------------
InfinityDB.TeleportData = {
    -- 3.0
    ["The MOTHERLODE!!"] = 1254555,
    -- 4.0
    ["Grim Batol"] = 445424,
    ["The Vortex Pinnacle"] = 410080,
    ["Throne of the Tides"] = 424142,
    -- 5.0
    ["Scholomance"] = 131232,
    ["Temple of the Jade Serpent"] = 131204,
    ["Stormstout Brewery"] = 131205,
    ["Shado-Pan Monastery"] = 131206,
    ["Mogu'shan Palace"] = 131222,
    ["Gate of the Setting Sun"] = 131225,
    ["Siege of Niuzao Temple"] = 131228,
    ["Scarlet Monastery"] = 131229,
    ["Scarlet Halls"] = 131231,
    -- 6.0
    ["Auchindoun"] = 159897,
    ["Skyreach"] = 1254557,
    ["Shadowmoon Burial Grounds"] = 159899,
    ["Everbloom"] = 159901,
    ["Upper Blackrock Spire"] = 159902,
    ["Bloodmaul Slag Mines"] = 159895,
    ["Grimrail Depot"] = 159900,
    ["Iron Docks"] = 159896,
    -- 7.0
    ["Return to Karazhan"] = 373262,
    ["Court of Stars"] = 393766,
    ["Halls of Valor"] = 393764,
    ["Black Rook Hold"] = 424153,
    ["Darkheart Thicket"] = 424163,
    ["Neltharion's Lair"] = 410078,
    ["Seat of the Triumvirate"] = 1254551,
    -- 8.0
    ["Operation: Mechagon"] = 373274,
    ["Freehold"] = 410071,
    ["The Underrot"] = 410074,
    ["Waycrest Manor"] = 424167,
    ["Atal'Dazar"] = 424187,
    ["Siege of Boralus"] = 445418,
    ["The MOTHERLODE!! (old)"] = 467553,
    -- 9.0
    ["Plaguefall"] = 354462,
    ["The Necrotic Wake"] = 354463,
    ["Mists of Tirna Scithe"] = 354464,
    ["Halls of Atonement"] = 354465,
    ["Spires of Ascension"] = 354466,
    ["Theater of Pain"] = 354467,
    ["De Other Side"] = 354468,
    ["Sanguine Depths"] = 354469,
    ["Tazavesh, the Veiled Market"] = 367416,
    ["Castle Nathria"] = 373190,
    ["Sanctum of Domination"] = 373191,
    ["Sepulcher of the First Ones"] = 373192,
    -- 10.0
    ["Uldaman: Legacy of Tyr"] = 393222,
    ["Ruby Life Pools"] = 393256,
    ["The Nokhud Offensive"] = 393262,
    ["Brackenhide Hollow"] = 393267,
    ["Algeth'ar Academy"] = 393273,
    ["Neltharus"] = 393276,
    ["The Azure Vault"] = 393279,
    ["Halls of Infusion"] = 393283,
    ["Dawn of the Infinite"] = 424197,
    ["Dawn of the Infinite: Galakrond's Fall"] = 432254,
    ["Aberrus, the Shadowed Crucible"] = 432257,
    ["Amirdrassil, the Dream's Hope"] = 432258,
    -- 11.0
    ["The Rookery"] = 445443,
    ["The Stonevault"] = 445269,
    ["Priory of the Sacred Flame"] = 445444,
    ["City of Threads"] = 445416,
    ["Cinderbrew Meadery"] = 445440,
    ["Darkflame Cleft"] = 445441,
    ["The Dawnbreaker"] = 445414,
    ["Ara-Kara, City of Echoes"] = 445417,
    ["Operation: Floodgate"] = 1216786,
    ["Liberation of Undermine"] = 1226482,
    ["Eco-Dome Al'dani"] = 1237215,
    ["The MOTHERLODE!!: Omega"] = 1239155,
    -- 12.0
    ["The Vortex Pinnacle (TWW)"] = 1254400,
    ["Magisters' Terrace"] = 1254572,
    ["Myza's Oasis"] = 1254559,
    ["The Nexus-King's Rest"] = 1254563,
}

-------------------------------------------------------
-- Instance icon mapping (mapID -> iconFileID)
-- Rule: if the same mapID appears multiple times, the later entry overrides the earlier one.
-------------------------------------------------------
InfinityDB.InstanceIconSource = {
    { "Rift of Aln", 2939, 7570496 },
    { "The Darkening Night", 2930, 7644019 },
    { "Void Scar Arena", 2923, 7479112 },
    { "The Nexus-King's Rest", 2915, 7570495 },
    { "March of the Sunwalkers", 2913, 7480127 },
    { "Shadow Spire", 2912, 7507136 },
    { "Myza's Oasis", 2874, 7478535 },
    { "Glimmerfall Valley", 2859, 7478534 },
    { "Eco-Dome Al'dani", 2830, 7074037 },
    { "Nallorak's Cave", 2825, 7478536 },
    { "Conspiracy Trail", 2813, 7467179 },
    { "Magisters' Terrace", 2811, 7467178 },
    { "The MOTHERLODE!!: Omega", 2810, 7049159 },
    { "The Vortex Pinnacle (TWW)", 2805, 7464936 },
    { "Blackrock Abyss", 2792, 136326 },
    { "Khaz Algar", 2774, 5917061 },
    { "Operation: Floodgate", 2773, 6422372 },
    { "Liberation of Undermine", 2769, 6422371 },
    { "City of Threads", 2669, 5912509 },
    { "The Dawnbreaker", 2662, 5912513 },
    { "Cinderbrew Meadery", 2661, 5912508 },
    { "Ara-Kara, City of Echoes", 2660, 5912507 },
    { "Nerub-ar Palace", 2657, 5912511 },
    { "The Stonevault", 2652, 5912515 },
    { "Darkflame Cleft", 2651, 5912510 },
    { "Priory of the Sacred Flame", 2649, 5912512 },
    { "The Rookery", 2648, 5912514 },
    { "Dawn of the Infinite", 2579, 5221804 },
    { "Dragon Isles", 2574, 4746637 },
    { "Aberrus, the Shadowed Crucible", 2569, 5149415 },
    { "Shadowlands", 2559, 3850571 },
    { "Amirdrassil, the Dream's Hope", 2549, 5409263 },
    { "Halls of Infusion", 2527, 4746638 },
    { "Algeth'ar Academy", 2526, 4746641 },
    { "Dawn of the Infinite: Galakrond's Fall", 2522, 4746643 },
    { "Ruby Life Pools", 2521, 4746639 },
    { "Brackenhide Hollow", 2520, 4746635 },
    { "Neltharus", 2519, 4746640 },
    { "The Nokhud Offensive", 2516, 4746636 },
    { "The Azure Vault", 2515, 4746634 },
    { "Sepulcher of the First Ones", 2481, 4423750 },
    { "Uldaman: Legacy of Tyr", 2451, 4746642 },
    { "Sanctum of Domination", 2450, 4181530 },
    { "Tazavesh, the Veiled Market", 2441, 4181531 },
    { "Castle Nathria", 2296, 3759926 },
    { "Theater of Pain", 2293, 3759934 },
    { "De Other Side", 2291, 3759935 },
    { "Mists of Tirna Scithe", 2290, 3759929 },
    { "The Necrotic Wake", 2289, 3759931 },
    { "Halls of Atonement", 2287, 3759928 },
    { "Plaguefall", 2286, 3759930 },
    { "Spires of Ascension", 2285, 3759933 },
    { "Sanguine Depths", 2284, 3759932 },
    { "Ny'alotha, the Waking City", 2217, 3221466 },
    { "The Eternal Palace", 2164, 3025335 },
    { "Operation: Mechagon", 2097, 3025336 },
    { "Crucible of Storms", 2096, 2498195 },
    { "Battle of Dazar'alor", 2070, 2482693 },
    { "Temple of Sethraliss", 1877, 2178734 },
    { "Shrine of the Storm", 1864, 2178732 },
    { "Waycrest Manor", 1862, 2178742 },
    { "Azsuna", 1861, 2178738 },
    { "Azeroth", 1861, 2178743 },
    { "The Underrot", 1841, 2178736 },
    { "Siege of Boralus", 1822, 2178733 },
    { "Tol Dagor", 1771, 2178737 },
    { "Atal'Dazar", 1763, 1778896 },
    { "Kings' Rest", 1762, 2178730 },
    { "Freehold", 1754, 1778897 },
    { "Seat of the Triumvirate", 1753, 1718526 },
    { "Antorus, the Burning Throne", 1712, 1718524 },
    { "Cathedral of Eternal Night", 1677, 1616925 },
    { "Tomb of Sargeras", 1676, 1616207 },
    { "Return to Karazhan", 1651, 1537287 },
    { "Trial of Valor", 1648, 1537288 },
    { "The MOTHERLODE!! (old)", 1594, 2178735 },
    { "Court of Stars", 1571, 1498160 },
    { "Vault of the Wardens", 1544, 1498159 },
    { "The Emerald Nightmare", 1530, 1450577 },
    { "Broken Isles", 1520, 1411866 },
    { "Invasion Point", 1520, 1718525 },
    { "Emerald Nightmare", 1520, 1452699 },
    { "The Arcway", 1516, 1411869 },
    { "Black Rook Hold", 1501, 1411865 },
    { "Halls of the Guardian", 1493, 1411870 },
    { "Maw of Souls", 1492, 1411868 },
    { "Halls of Valor", 1477, 1498162 },
    { "Darkheart Thicket", 1466, 1411867 },
    { "Neltharion's Lair", 1458, 1450576 },
    { "Eye of Azshara", 1456, 1498161 },
    { "Hellfire Citadel", 1448, 136340 },
    { "Upper Blackrock Spire", 1358, 1042065 },
    { "Everbloom", 1279, 1060551 },
    { "Draenor", 1228, 1042060 },
    { "Highmaul", 1228, 1042062 },
    { "Skyreach", 1209, 1042064 },
    { "Grimrail Depot", 1208, 1042061 },
    { "Blackrock Foundry", 1205, 1042058 },
    { "Iron Docks", 1195, 1060552 },
    { "Auchindoun", 1182, 1042057 },
    { "Shadowmoon Burial Grounds", 1176, 1042063 },
    { "Bloodmaul Slag Mines", 1175, 1042059 },
    { "The MOTHERLODE!!", 658, 336391 },
}

InfinityDB.InstanceIconByMapID = {}
for _, row in ipairs(InfinityDB.InstanceIconSource) do
    local mapID = tonumber(row[2])
    local icon = tonumber(row[3])
    if mapID and icon then
        InfinityDB.InstanceIconByMapID[mapID] = icon
    end
end

-------------------------------------------------------
-- Mythic+ data (difficulty / level scaling)
-------------------------------------------------------
InfinityDB.MythicDamageData = {
    -- Base damage bonus; the level-based bonus is not shown here
    LevelMultipliers = {
        [1]  = 1.00,
        [2]  = 1.07000005245,
        [3]  = 1.13999998569,
        [4]  = 1.23000001907,
        [5]  = 1.30999994278,
        [6]  = 1.39999997616,
        [7]  = 1.5,
        [8]  = 1.61000001431,
        [9]  = 1.72000002861,
        [10] = 1.84000003338,
        [11] = 2.01999998093,
        [12] = 2.22000002861,
        [13] = 2.45000004768,
        [14] = 2.69000005722,
        [15] = 2.96000003815,
        [16] = 3.25999999046,
        [17] = 3.57999992371,
        [18] = 3.94000005722,
        [19] = 4.32999992371,
        [20] = 4.76999998093,
        [21] = 5.25,
        [22] = 5.76999998093,
        [23] = 6.34999990463,
        [24] = 6.98000001907,
        [25] = 7.67999982834,
    }
}

-- Quick lookup: SpellID -> dungeon name
InfinityDB.SpellToDungeonName = {}
for name, id in pairs(InfinityDB.TeleportData) do
    InfinityDB.SpellToDungeonName[id] = name
end

-------------------------------------------------------
-- Utility functions
-------------------------------------------------------

-- Get full spec info
function InfinityDB:GetSpecInfo(specID)
    return self.SpecByID[specID]
end

-- Get spec role sort priority: 1=tank, 2=dps, 3=healer
function InfinityDB:GetSpecRolePriority(specID)
    local info = self:GetSpecInfo(specID)
    if not info then return 99 end
    if info.role == "TANK" then
        return 1
    elseif info.role == "DAMAGER" or info.role == "DPS" then
        return 2
    elseif info.role == "HEALER" then
        return 3
    end
    return 4
end

-- Get spec role key (tank/heal/dps)
function InfinityDB:GetSpecRoleKey(specID)
    return self.SpecRoleKeyByID[specID]
end

-- Get spec list for a given role (returns reference table, read-only)
function InfinityDB:GetSpecsByRole(roleKey)
    roleKey = tostring(roleKey or ""):lower()
    if roleKey == "healer" then roleKey = "heal" end
    if roleKey == "damage" or roleKey == "damager" then roleKey = "dps" end
    return self.SpecsByRole[roleKey]
end

-- Get colored class name
function InfinityDB:GetColoredClassName(classID)
    local info = self.Classes[classID]
    if not info then return "Unknown" end
    return string.format("|cff%s%s|r", info.colorHex, info.name)
end

-- Get class color (returns RGB in 0-1 range)
function InfinityDB:GetClassColorRGB(classID)
    local info = self.Classes[classID]
    if info and info.colorRGB then
        return info.colorRGB[1] / 255, info.colorRGB[2] / 255, info.colorRGB[3] / 255
    end
    return 1, 1, 1
end

-- Get the primary stat name for the current player's spec
function InfinityDB:GetPlayerPrimaryStat()
    local specID = GetSpecializationInfo(GetSpecialization() or 1)
    if specID and self.SpecByID[specID] then
        return self.SpecByID[specID].primaryStat or "Unknown"
    end
    return "Unknown"
end

-------------------------------------------------------
-- Generic UI widget factory (text settings)
-------------------------------------------------------

local LMS = LibStub("LibSharedMedia-3.0", true)


-- Apply config to a FontString
-- config object should contain: font, size, outline, r, g, b, shadow, shadowX, shadowY, shadowColor
function InfinityDB:ApplyFont(fs, config)
    if not fs or not config then return end

    -- [v4.3.2 Fix] Prefer using config.font to fetch the font path from LSM
    local fontPath
    if config.font and LMS then
        fontPath = LMS:Fetch("font", config.font)
    end
    -- Fallback: use default font
    if not fontPath then
        fontPath = InfinityTools.MAIN_FONT
    end

    local size = config.size or 14
    local outline = config.outline or "OUTLINE"

    -- Apply font
    fs:SetFont(fontPath, size, outline)

    -- 2. Handle color
    fs:SetTextColor(config.r or 1, config.g or 1, config.b or 1, config.a or 1)

    -- 3. Handle shadow
    if config.shadow then
        fs:SetShadowOffset(config.shadowX or 1, config.shadowY or -1)
        local sc = config.shadowColor or { 0, 0, 0, 1 }
        fs:SetShadowColor(sc[1] or 0, sc[2] or 0, sc[3] or 0, sc[4] or 1)
    else
        fs:SetShadowOffset(0, 0)
    end
end

-------------------------------------------------------
-- Export to InfinityTools
-------------------------------------------------------
InfinityTools.DB_Static = InfinityDB

