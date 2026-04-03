local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

local InfinityDB = _G.InfinityDB or {}
_G.InfinityDB = InfinityDB

InfinityDB.Classes = {
    [1] = { id = 1, name = "Warrior", nameEN = "WARRIOR", colorHex = "C79C6E", colorRGB = { 198, 155, 109 }, icon = 626003 },
    [2] = { id = 2, name = "Paladin", nameEN = "PALADIN", colorHex = "F58CBA", colorRGB = { 245, 140, 186 }, icon = 626000 },
    [3] = { id = 3, name = "Hunter", nameEN = "HUNTER", colorHex = "ABD473", colorRGB = { 171, 212, 115 }, icon = 626008 },
    [4] = { id = 4, name = "Rogue", nameEN = "ROGUE", colorHex = "FFF468", colorRGB = { 255, 244, 104 }, icon = 626005 },
    [5] = { id = 5, name = "Priest", nameEN = "PRIEST", colorHex = "FFFFFF", colorRGB = { 255, 255, 255 }, icon = 626004 },
    [6] = { id = 6, name = "Death Knight", nameEN = "DEATHKNIGHT", colorHex = "C41E3A", colorRGB = { 196, 30, 58 }, icon = 135771 },
    [7] = { id = 7, name = "Shaman", nameEN = "SHAMAN", colorHex = "0070DD", colorRGB = { 0, 112, 221 }, icon = 626006 },
    [8] = { id = 8, name = "Mage", nameEN = "MAGE", colorHex = "3FC7EB", colorRGB = { 63, 199, 235 }, icon = 626001 },
    [9] = { id = 9, name = "Warlock", nameEN = "WARLOCK", colorHex = "8788EE", colorRGB = { 135, 136, 238 }, icon = 626007 },
    [10] = { id = 10, name = "Monk", nameEN = "MONK", colorHex = "00FF98", colorRGB = { 0, 255, 152 }, icon = 626002 },
    [11] = { id = 11, name = "Druid", nameEN = "DRUID", colorHex = "FF7C0A", colorRGB = { 255, 124, 10 }, icon = 625999 },
    [12] = { id = 12, name = "Demon Hunter", nameEN = "DEMONHUNTER", colorHex = "A330C9", colorRGB = { 163, 48, 201 }, icon = 1260827 },
    [13] = { id = 13, name = "Evoker", nameEN = "EVOKER", colorHex = "33937F", colorRGB = { 51, 147, 127 }, icon = 4574311 },
}

InfinityDB.Specs = {
    { id = 62, name = "Arcane", classID = 8, icon = 135932, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 30451 },
    { id = 63, name = "Fire", classID = 8, icon = 135810, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 133 },
    { id = 64, name = "Frost", classID = 8, icon = 135846, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 30455 },
    { id = 65, name = "Holy", classID = 2, icon = 135920, role = "HEALER", primaryStat = "Intellect", RangeSpell = 275773 },
    { id = 66, name = "Protection", classID = 2, icon = 236264, role = "TANK", primaryStat = "Strength", RangeSpell = 96231 },
    { id = 70, name = "Retribution", classID = 2, icon = 135873, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 383328 },
    { id = 71, name = "Arms", classID = 1, icon = 132355, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 12294 },
    { id = 72, name = "Fury", classID = 1, icon = 132347, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 23881 },
    { id = 73, name = "Protection", classID = 1, icon = 132341, role = "TANK", primaryStat = "Strength", RangeSpell = 23922 },
    { id = 102, name = "Balance", classID = 11, icon = 136096, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 8921 },
    { id = 103, name = "Feral", classID = 11, icon = 132115, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 22568 },
    { id = 104, name = "Guardian", classID = 11, icon = 132276, role = "TANK", primaryStat = "Agility", RangeSpell = 33917 },
    { id = 105, name = "Restoration", classID = 11, icon = 136041, role = "HEALER", primaryStat = "Intellect", RangeSpell = 8921 },
    { id = 250, name = "Blood", classID = 6, icon = 135770, role = "TANK", primaryStat = "Strength", RangeSpell = 49998 },
    { id = 251, name = "Frost", classID = 6, icon = 135773, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 49998 },
    { id = 252, name = "Unholy", classID = 6, icon = 135775, role = "DAMAGER", primaryStat = "Strength", RangeSpell = 49998 },
    { id = 253, name = "Beast Mastery", classID = 3, icon = 461112, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 187707 },
    { id = 254, name = "Marksmanship", classID = 3, icon = 236179, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 147362 },
    { id = 255, name = "Survival", classID = 3, icon = 461113, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 147362 },
    { id = 256, name = "Discipline", classID = 5, icon = 135940, role = "HEALER", primaryStat = "Intellect", RangeSpell = 585 },
    { id = 257, name = "Holy", classID = 5, icon = 237542, role = "HEALER", primaryStat = "Intellect", RangeSpell = 585 },
    { id = 258, name = "Shadow", classID = 5, icon = 136207, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 8092 },
    { id = 259, name = "Assassination", classID = 4, icon = 236270, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 1766 },
    { id = 260, name = "Outlaw", classID = 4, icon = 236286, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 1766 },
    { id = 261, name = "Subtlety", classID = 4, icon = 132320, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 1766 },
    { id = 262, name = "Elemental", classID = 7, icon = 136048, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 188196 },
    { id = 263, name = "Enhancement", classID = 7, icon = 237581, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 60103 },
    { id = 264, name = "Restoration", classID = 7, icon = 136052, role = "HEALER", primaryStat = "Intellect", RangeSpell = 188196 },
    { id = 265, name = "Affliction", classID = 9, icon = 136145, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 686 },
    { id = 266, name = "Demonology", classID = 9, icon = 136172, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 105174 },
    { id = 267, name = "Destruction", classID = 9, icon = 136186, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 116858 },
    { id = 268, name = "Brewmaster", classID = 10, icon = 608951, role = "TANK", primaryStat = "Agility", RangeSpell = 100780 },
    { id = 269, name = "Windwalker", classID = 10, icon = 608953, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 100780 },
    { id = 270, name = "Mistweaver", classID = 10, icon = 608952, role = "HEALER", primaryStat = "Intellect", RangeSpell = 100780 },
    { id = 577, name = "Havoc", classID = 12, icon = 1247264, role = "DAMAGER", primaryStat = "Agility", RangeSpell = 162794 },
    { id = 581, name = "Vengeance", classID = 12, icon = 1247265, role = "TANK", primaryStat = "Agility", RangeSpell = 263642 },
    { id = 1467, name = "Devastation", classID = 13, icon = 4511811, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 362969 },
    { id = 1468, name = "Preservation", classID = 13, icon = 4511812, role = "HEALER", primaryStat = "Intellect", RangeSpell = 362969 },
    { id = 1473, name = "Augmentation", classID = 13, icon = 5198700, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 395160 },
    { id = 1480, name = "Aldrachi Reaver", classID = 12, icon = 7455385, role = "DAMAGER", primaryStat = "Intellect", RangeSpell = 473662 },
}

InfinityDB.SpecByID = {}
InfinityDB.SpecRoleKeyByID = {}
InfinityDB.SpecsByRole = { tank = {}, heal = {}, dps = {} }
InfinityDB.SpecsByClassID = {}

for _, spec in ipairs(InfinityDB.Specs) do
    InfinityDB.SpecByID[spec.id] = spec
    local roleKey = "dps"
    if spec.role == "TANK" then
        roleKey = "tank"
    elseif spec.role == "HEALER" then
        roleKey = "heal"
    end
    InfinityDB.SpecRoleKeyByID[spec.id] = roleKey
    table.insert(InfinityDB.SpecsByRole[roleKey], spec)
    InfinityDB.SpecsByClassID[spec.classID] = InfinityDB.SpecsByClassID[spec.classID] or {}
    table.insert(InfinityDB.SpecsByClassID[spec.classID], spec)
end

InfinityDB.PlayerSpellDB = {
    [47528] = { category = "interrupt", cd = 15, class = "DEATHKNIGHT", spec = 0 },
    [48792] = { category = "defensive", cd = 120, class = "DEATHKNIGHT", spec = 0 },
    [48707] = { category = "defensive", cd = 40, class = "DEATHKNIGHT", spec = 0 },
    [51052] = { category = "defensive", cd = 120, class = "DEATHKNIGHT", spec = 0 },
    [49028] = { category = "offensive", cd = 45, class = "DEATHKNIGHT", spec = 250 },
    [55233] = { category = "defensive", cd = 90, class = "DEATHKNIGHT", spec = 250 },
    [51271] = { category = "offensive", cd = 60, class = "DEATHKNIGHT", spec = 251 },
    [279302] = { category = "offensive", cd = 180, class = "DEATHKNIGHT", spec = 251 },
    [42650] = { category = "offensive", cd = 180, class = "DEATHKNIGHT", spec = 252 },
    [63560] = { category = "offensive", cd = 45, class = "DEATHKNIGHT", spec = 252 },
    [383269] = { category = "cc", cd = 120, class = "DEATHKNIGHT", spec = 0 },
    [221562] = { category = "cc", cd = 45, class = "DEATHKNIGHT", spec = 0 },
    [207167] = { category = "cc", cd = 60, class = "DEATHKNIGHT", spec = 251 },
    [49576] = { category = "cc", cd = 25, class = "DEATHKNIGHT", spec = 0 },
    [183752] = { category = "interrupt", cd = 15, class = "DEMONHUNTER", spec = 0 },
    [198589] = { category = "defensive", cd = 60, class = "DEMONHUNTER", spec = 577 },
    [196718] = { category = "defensive", cd = 180, class = "DEMONHUNTER", spec = 0 },
    [212800] = { category = "defensive", cd = 180, class = "DEMONHUNTER", spec = 577 },
    [191427] = { category = "offensive", cd = 120, class = "DEMONHUNTER", spec = 577 },
    [187827] = { category = "defensive", cd = 120, class = "DEMONHUNTER", spec = 581 },
    [204021] = { category = "defensive", cd = 60, class = "DEMONHUNTER", spec = 581 },
    [212084] = { category = "offensive", cd = 60, class = "DEMONHUNTER", spec = 581 },
    [179057] = { category = "cc", cd = 60, class = "DEMONHUNTER", spec = 0 },
    [218352] = { category = "cc", cd = 45, class = "DEMONHUNTER", spec = 0 },
    [106839] = { category = "interrupt", cd = 15, class = "DRUID", spec = 0 },
    [78675] = { category = "interrupt", cd = 60, class = "DRUID", spec = 102 },
    [22812] = { category = "defensive", cd = 60, class = "DRUID", spec = 0 },
    [61336] = { category = "defensive", cd = 180, class = "DRUID", spec = 104 },
    [102342] = { category = "defensive", cd = 90, class = "DRUID", spec = 105 },
    [102558] = { category = "offensive", cd = 180, class = "DRUID", spec = 104 },
    [102560] = { category = "offensive", cd = 180, class = "DRUID", spec = 102 },
    [323764] = { category = "offensive", cd = 60, class = "DRUID", spec = 0 },
    [5211] = { category = "cc", cd = 60, class = "DRUID", spec = 0 },
    [132469] = { category = "cc", cd = 30, class = "DRUID", spec = 0 },
    [102793] = { category = "cc", cd = 60, class = "DRUID", spec = 0 },
    [99] = { category = "cc", cd = 30, class = "DRUID", spec = 0 },
    [351338] = { category = "interrupt", cd = 40, class = "EVOKER", spec = { 1467, 1473 } },
    [363916] = { category = "defensive", cd = 90, class = "EVOKER", spec = 0 },
    [374227] = { category = "defensive", cd = 120, class = "EVOKER", spec = 0 },
    [363534] = { category = "defensive", cd = 180, class = "EVOKER", spec = 1468 },
    [370537] = { category = "defensive", cd = 90, class = "EVOKER", spec = 1468 },
    [357170] = { category = "defensive", cd = 60, class = "EVOKER", spec = 1468 },
    [375087] = { category = "offensive", cd = 120, class = "EVOKER", spec = 1467 },
    [403631] = { category = "offensive", cd = 120, class = "EVOKER", spec = 1473 },
    [358385] = { category = "cc", cd = 90, class = "EVOKER", spec = 0 },
    [357210] = { category = "cc", cd = 120, class = "EVOKER", spec = 0 },
    [361500] = { category = "cc", cd = 45, class = "EVOKER", spec = 0 },
    [357214] = { category = "cc", cd = 45, class = "EVOKER", spec = 0 },
    [372048] = { category = "cc", cd = 120, class = "EVOKER", spec = 0 },
    [147362] = { category = "interrupt", cd = 24, class = "HUNTER", spec = 0 },
    [186265] = { category = "defensive", cd = 180, class = "HUNTER", spec = 0 },
    [264735] = { category = "defensive", cd = 180, class = "HUNTER", spec = 0 },
    [109304] = { category = "defensive", cd = 120, class = "HUNTER", spec = 0 },
    [288613] = { category = "offensive", cd = 120, class = "HUNTER", spec = 254 },
    [19577] = { category = "cc", cd = 60, class = "HUNTER", spec = 0 },
    [3355] = { category = "cc", cd = 30, class = "HUNTER", spec = 0 },
    [109248] = { category = "cc", cd = 45, class = "HUNTER", spec = 0 },
    [2139] = { category = "interrupt", cd = 20, class = "MAGE", spec = 0 },
    [414658] = { category = "defensive", cd = 180, class = "MAGE", spec = 0 },
    [45438] = { category = "defensive", cd = 240, class = "MAGE", spec = 0 },
    [342245] = { category = "defensive", cd = 50, class = "MAGE", spec = 0 },
    [235450] = { category = "defensive", cd = 24, class = "MAGE", spec = 62 },
    [235313] = { category = "defensive", cd = 24, class = "MAGE", spec = 63 },
    [11426] = { category = "defensive", cd = 24, class = "MAGE", spec = 64 },
    [365350] = { category = "offensive", cd = 120, class = "MAGE", spec = 62 },
    [190319] = { category = "offensive", cd = 60, class = "MAGE", spec = 63 },
    [205021] = { category = "offensive", cd = 60, class = "MAGE", spec = 64 },
    [31661] = { category = "cc", cd = 40, class = "MAGE", spec = 63 },
    [113724] = { category = "cc", cd = 45, class = "MAGE", spec = { 62, 64 } },
    [157980] = { category = "cc", cd = 40, class = "MAGE", spec = 62 },
    [116705] = { category = "interrupt", cd = 15, class = "MONK", spec = { 268, 269 } },
    [115203] = { category = "defensive", cd = 240, class = "MONK", spec = 0 },
    [122470] = { category = "defensive", cd = 90, class = "MONK", spec = 269 },
    [119582] = { category = "defensive", cd = 15, class = "MONK", spec = 268 },
    [322507] = { category = "defensive", cd = 45, class = "MONK", spec = 268 },
    [1241059] = { category = "defensive", cd = 45, class = "MONK", spec = 268 },
    [137639] = { category = "offensive", cd = 90, class = "MONK", spec = 269 },
    [119381] = { category = "cc", cd = 45, class = "MONK", spec = 0 },
    [116844] = { category = "cc", cd = 45, class = "MONK", spec = 0 },
    [96231] = { category = "interrupt", cd = 15, class = "PALADIN", spec = { 66, 70 } },
    [642] = { category = "defensive", cd = 300, class = "PALADIN", spec = 0 },
    [1022] = { category = "defensive", cd = 300, class = "PALADIN", spec = 0 },
    [6940] = { category = "defensive", cd = 120, class = "PALADIN", spec = 0 },
    [31821] = { category = "defensive", cd = 180, class = "PALADIN", spec = 65 },
    [31884] = { category = "offensive", cd = 120, class = "PALADIN", spec = 0 },
    [853] = { category = "cc", cd = 60, class = "PALADIN", spec = 0 },
    [115750] = { category = "cc", cd = 90, class = "PALADIN", spec = 0 },
    [15487] = { category = "interrupt", cd = 45, class = "PRIEST", spec = 258 },
    [33206] = { category = "defensive", cd = 180, class = "PRIEST", spec = 256 },
    [62618] = { category = "defensive", cd = 180, class = "PRIEST", spec = 256 },
    [47788] = { category = "defensive", cd = 180, class = "PRIEST", spec = 257 },
    [10060] = { category = "offensive", cd = 120, class = "PRIEST", spec = 0 },
    [8122] = { category = "cc", cd = 30, class = "PRIEST", spec = 0 },
    [64044] = { category = "cc", cd = 45, class = "PRIEST", spec = 258 },
    [1766] = { category = "interrupt", cd = 15, class = "ROGUE", spec = 0 },
    [31224] = { category = "defensive", cd = 120, class = "ROGUE", spec = 0 },
    [5277] = { category = "defensive", cd = 120, class = "ROGUE", spec = 0 },
    [1856] = { category = "defensive", cd = 120, class = "ROGUE", spec = 0 },
    [121471] = { category = "offensive", cd = 120, class = "ROGUE", spec = 261 },
    [2094] = { category = "cc", cd = 120, class = "ROGUE", spec = 0 },
    [408] = { category = "cc", cd = 20, class = "ROGUE", spec = 0 },
    [57994] = { category = "interrupt", cd = { [262] = 12, [263] = 12, [264] = 30, default = 12 }, class = "SHAMAN", spec = { 262, 263, 264 } },
    [108271] = { category = "defensive", cd = 90, class = "SHAMAN", spec = 0 },
    [98008] = { category = "defensive", cd = 180, class = "SHAMAN", spec = 264 },
    [198838] = { category = "defensive", cd = 60, class = "SHAMAN", spec = 264 },
    [114050] = { category = "offensive", cd = 120, class = "SHAMAN", spec = 262 },
    [192058] = { category = "cc", cd = 60, class = "SHAMAN", spec = 0 },
    [51514] = { category = "cc", cd = 30, class = "SHAMAN", spec = 0 },
    [19647] = { category = "interrupt", cd = 24, class = "WARLOCK", spec = 0 },
    [89766] = { category = "interrupt", cd = 30, class = "WARLOCK", spec = 266 },
    [108416] = { category = "defensive", cd = 45, class = "WARLOCK", spec = 0 },
    [104773] = { category = "defensive", cd = 180, class = "WARLOCK", spec = 0 },
    [265187] = { category = "offensive", cd = 60, class = "WARLOCK", spec = 266 },
    [1122] = { category = "offensive", cd = 120, class = "WARLOCK", spec = 267 },
    [18540] = { category = "offensive", cd = 120, class = "WARLOCK", spec = 0 },
    [30283] = { category = "cc", cd = 60, class = "WARLOCK", spec = 0 },
    [6789] = { category = "cc", cd = 45, class = "WARLOCK", spec = 0 },
    [5484] = { category = "cc", cd = 40, class = "WARLOCK", spec = 0 },
    [205179] = { category = "cc", cd = 120, class = "WARLOCK", spec = 0 },
    [6552] = { category = "interrupt", cd = 15, class = "WARRIOR", spec = 0 },
    [871] = { category = "defensive", cd = 180, class = "WARRIOR", spec = 73 },
    [118038] = { category = "defensive", cd = 180, class = "WARRIOR", spec = 71 },
    [184364] = { category = "defensive", cd = 120, class = "WARRIOR", spec = 72 },
    [23920] = { category = "defensive", cd = 25, class = "WARRIOR", spec = 0 },
    [107574] = { category = "offensive", cd = 90, class = "WARRIOR", spec = 0 },
    [1719] = { category = "offensive", cd = 90, class = "WARRIOR", spec = 72 },
    [107570] = { category = "cc", cd = 30, class = "WARRIOR", spec = 0 },
    [5246] = { category = "cc", cd = 90, class = "WARRIOR", spec = 0 },
    [46968] = { category = "cc", cd = 40, class = "WARRIOR", spec = 0 },
}

InfinityDB.SpellAliases = {
    [132409] = 19647,
    [119898] = 19647,
    [119910] = 19647,
    [171138] = 19647,
    [171140] = 19647,
    [212619] = 19647,
    [119914] = 89766,
    [455395] = 63560,
    [106951] = 102558,
    [194223] = 102560,
}

InfinityDB.InterruptBaseByClass = {
    DEATHKNIGHT = 47528,
    DEMONHUNTER = 183752,
    DRUID = 106839,
    EVOKER = 351338,
    HUNTER = 147362,
    MAGE = 2139,
    MONK = 116705,
    PALADIN = 96231,
    PRIEST = 15487,
    ROGUE = 1766,
    SHAMAN = 57994,
    WARLOCK = 19647,
    WARRIOR = 6552,
}

local function SpellMatchesSpec(spellSpec, specID)
    if spellSpec == 0 or spellSpec == nil then
        return true
    end
    if type(spellSpec) == "table" then
        for _, value in ipairs(spellSpec) do
            if value == specID then
                return true
            end
        end
        return false
    end
    return spellSpec == specID
end

local function ResolveSpellCooldown(spellInfo, specID)
    local cd = spellInfo and spellInfo.cd
    if type(cd) == "table" then
        return cd[specID] or cd.default or 15
    end
    return cd or 15
end

InfinityDB.InterruptData = {}
for _, spec in ipairs(InfinityDB.Specs) do
    local classInfo = InfinityDB.Classes[spec.classID]
    local baseSpellID = classInfo and InfinityDB.InterruptBaseByClass[classInfo.nameEN]
    if baseSpellID then
        local spellInfo = InfinityDB.PlayerSpellDB[baseSpellID]
        local selectedSpellID = baseSpellID
        local selectedSpellInfo = spellInfo

        for spellID, info in pairs(InfinityDB.PlayerSpellDB) do
            if info.category == "interrupt" and info.class == classInfo.nameEN and SpellMatchesSpec(info.spec, spec.id) then
                selectedSpellID = spellID
                selectedSpellInfo = info
                break
            end
        end

        if selectedSpellInfo then
            InfinityDB.InterruptData[spec.id] = {
                id = selectedSpellID,
                cd = ResolveSpellCooldown(selectedSpellInfo, spec.id),
            }
        end
    end
end

InfinityDB.TeleportData = {
    ["Ara-Kara, City of Echoes"] = 445417,
    ["Cinderbrew Meadery"] = 445440,
    ["City of Threads"] = 445416,
    ["Darkflame Cleft"] = 445441,
    ["Operation: Floodgate"] = 1216786,
    ["Priory of the Sacred Flame"] = 445444,
    ["Siege of Boralus"] = 445418,
    ["The Dawnbreaker"] = 445414,
    ["The Stonevault"] = 445443,
    ["Operation: Mechagon"] = 1237215,
    ["Manaforge Omega"] = 1239155,
    ["Liberation of Undermine"] = 1226482,
}

InfinityDB.InstanceIconByMapID = {
    [161] = 1042064,
    [378] = 3759928,
    [391] = 367416,
    [392] = 367416,
    [402] = 4746641,
    [499] = 445444,
    [503] = 5912507,
    [505] = 5912513,
    [525] = 6422372,
    [542] = 1237215,
    [556] = 336391,
    [557] = 7464936,
    [558] = 7467178,
    [559] = 1254563,
    [560] = 7478535,
}

InfinityDB.SpellToDungeonName = {}
for dungeonName, spellID in pairs(InfinityDB.TeleportData) do
    InfinityDB.SpellToDungeonName[spellID] = dungeonName
end

InfinityDB.MythicDamageData = {
    LevelMultipliers = {
        [1] = 1.00, [2] = 1.07, [3] = 1.14, [4] = 1.23, [5] = 1.31,
        [6] = 1.40, [7] = 1.50, [8] = 1.61, [9] = 1.72, [10] = 1.84,
        [11] = 2.02, [12] = 2.22, [13] = 2.45, [14] = 2.69, [15] = 2.96,
        [16] = 3.26, [17] = 3.58, [18] = 3.94, [19] = 4.33, [20] = 4.77,
        [21] = 5.25, [22] = 5.77, [23] = 6.35, [24] = 6.98, [25] = 7.68,
    },
}

function InfinityDB:GetSpecInfo(specID)
    return self.SpecByID[specID]
end

function InfinityDB:GetSpecRoleKey(specID)
    return self.SpecRoleKeyByID[specID]
end

function InfinityDB:GetSpecsByRole(roleKey)
    roleKey = tostring(roleKey or ""):lower()
    if roleKey == "healer" then
        roleKey = "heal"
    elseif roleKey == "damage" or roleKey == "damager" then
        roleKey = "dps"
    end
    return self.SpecsByRole[roleKey] or {}
end

function InfinityDB:GetClassColorRGB(classID)
    local info = self.Classes[classID]
    if not info or not info.colorRGB then
        return 1, 1, 1
    end
    return info.colorRGB[1] / 255, info.colorRGB[2] / 255, info.colorRGB[3] / 255
end

function InfinityDB:ApplyFont(fontString, config)
    if not fontString or not config then
        return
    end

    local lsm = LibStub("LibSharedMedia-3.0", true)
    local fontPath = config.font and lsm and lsm:Fetch("font", config.font)
    fontPath = fontPath or Core.MAIN_FONT or STANDARD_TEXT_FONT

    fontString:SetFont(fontPath, config.size or 14, config.outline or "OUTLINE")
    fontString:SetTextColor(config.r or 1, config.g or 1, config.b or 1, config.a or 1)

    if config.shadow then
        fontString:SetShadowOffset(config.shadowX or 1, config.shadowY or -1)
        local shadowColor = config.shadowColor or { 0, 0, 0, 1 }
        fontString:SetShadowColor(shadowColor[1] or 0, shadowColor[2] or 0, shadowColor[3] or 0, shadowColor[4] or 1)
    else
        fontString:SetShadowOffset(0, 0)
    end
end

Core.DB_Static = InfinityDB
