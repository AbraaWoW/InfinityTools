-- =============================================================
-- [[ InfinityTools Core Component: Important Spell Database (InfinityCDDB) ]]
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

-- [SpellID] = { class, talents, cooldown, enUS_name }
InfinityTools.CDDB = {
    --------------------------------------------------------------------------------
    -- Warrior (updated 0208)
    --------------------------------------------------------------------------------
    [871] = { class = 1, talents = { 73 }, cooldown = 60, enUS_name = "Shield Wall" },
    [107574] = { class = 1, talents = { 71, 72, 73 }, cooldown = 90, enUS_name = "Avatar" },
    [118038] = { class = 1, talents = { 71 }, cooldown = 120, enUS_name = "Die by the Sword" },
    [184364] = { class = 1, talents = { 72, }, cooldown = 120, enUS_name = "Enraged Regeneration" },
    [389722] = { class = 1, talents = { 72 }, cooldown = 90, enUS_name = "Recklessness" },

    --------------------------------------------------------------------------------
    -- Paladin (updated 0208)
    --------------------------------------------------------------------------------
    [498] = { class = 2, talents = { 65, 70 }, cooldown = 60, enUS_name = "Divine Protection" },
    [31850] = { class = 2, talents = { 66 }, cooldown = 90, enUS_name = "Ardent Defender" },
    [31884] = { class = 2, talents = { 65, 66, 70 }, cooldown = 120, enUS_name = "Avenging Wrath" },
    [216331] = { class = 2, talents = { 65 }, cooldown = 60, enUS_name = "Avenging Crusader" },
    [231895] = { class = 2, talents = { 0 }, cooldown = 120, enUS_name = "Avenging Wrath" },
    [389539] = { class = 2, talents = { 66 }, cooldown = 60, enUS_name = "Sentinel" },
    [403876] = { class = 2, talents = { 65, 70 }, cooldown = 60, enUS_name = "Divine Protection" },
    [454351] = { class = 2, talents = { 70, }, cooldown = 30, enUS_name = "Avenging Wrath" }, -- passive
    [454373] = { class = 2, talents = { 0 }, cooldown = 0, enUS_name = "Avenging Wrath" },
    [1261559] = { class = 2, talents = { 0 }, cooldown = 60, enUS_name = "Divine Protection" },

    --------------------------------------------------------------------------------
    -- Hunter (updated 0208)
    --------------------------------------------------------------------------------
    [109304] = { class = 3, talents = { 253, 254, 255 }, cooldown = 120, enUS_name = "Exhilaration" },
    [264735] = { class = 3, talents = { 253, 254, 255 }, cooldown = 2, enUS_name = "Survival of the Fittest" },
    [266779] = { class = 3, talents = { 0 }, cooldown = 120, enUS_name = "Coordinated Assault" },
    [288613] = { class = 3, talents = { 254 }, cooldown = 120, enUS_name = "Trueshot" },
    [359844] = { class = 3, talents = { 0 }, cooldown = 120, enUS_name = "Call of the Wild" },
    [360952] = { class = 3, talents = { 0 }, cooldown = 120, enUS_name = "Coordinated Assault" },
    [377572] = { class = 3, talents = { 0 }, cooldown = 0, enUS_name = "Coordinated Assault" },
    [389654] = { class = 3, talents = { 0 }, cooldown = 0, enUS_name = "Master Handler" },
    [389660] = { class = 3, talents = { 0 }, cooldown = 0, enUS_name = "Snake Bite" },
    [1250646] = { class = 3, talents = { 255 }, cooldown = 90, enUS_name = "Takedown" },
    [1251703] = { class = 3, talents = { 255 }, cooldown = 0, enUS_name = "Takedown" },

    --------------------------------------------------------------------------------
    -- Rogue
    --------------------------------------------------------------------------------
    [5277] = { class = 4, talents = { 259, 260, 261 }, cooldown = 120, enUS_name = "Evasion" },
    [13750] = { class = 4, talents = { 260 }, cooldown = 180, enUS_name = "Adrenaline Rush" },
    [79140] = { class = 4, talents = { 0 }, cooldown = 120, enUS_name = "Vendetta" },
    [121471] = { class = 4, talents = { 261 }, cooldown = 90, enUS_name = "Shadow Blades" },
    [185311] = { class = 4, talents = { 259, 260, 261 }, cooldown = 30, enUS_name = "Crimson Vial" },
    [360194] = { class = 4, talents = { 259 }, cooldown = 120, enUS_name = "Deathmark" },
    [361175] = { class = 4, talents = { 0 }, cooldown = 180, enUS_name = "Midnight" },

    --------------------------------------------------------------------------------
    -- Priest (updated 0208)
    --------------------------------------------------------------------------------
    [19236] = { class = 5, talents = { 256, 257, 258 }, cooldown = 90, enUS_name = "Desperate Prayer" },
    [64843] = { class = 5, talents = { 257 }, cooldown = 180, enUS_name = "Divine Hymn" },
    [194249] = { class = 5, talents = { 258 }, cooldown = 120, enUS_name = "Voidform" },
    [228260] = { class = 5, talents = { 258 }, cooldown = 120, enUS_name = "Voidform" },
    [391109] = { class = 5, talents = { 0 }, cooldown = 60, enUS_name = "Dark Ascension" },
    [408558] = { class = 5, talents = { 0 }, cooldown = 0, enUS_name = "Phase Shift" },
    [1246965] = { class = 5, talents = { 0 }, cooldown = 0, enUS_name = "Psychic Shroud" },

    --------------------------------------------------------------------------------
    -- Death Knight (updated 0208)
    --------------------------------------------------------------------------------
    [48707] = { class = 6, talents = { 250, 251, 252 }, cooldown = 60, enUS_name = "Anti-Magic Shell" },
    [48792] = { class = 6, talents = { 250, 251, 252 }, cooldown = 120, enUS_name = "Icebound Fortitude" },
    [49028] = { class = 6, talents = { 250 }, cooldown = 120, enUS_name = "Dancing Rune Weapon" },
    [51271] = { class = 6, talents = { 251 }, cooldown = 45, enUS_name = "Pillar of Frost" },
    [55233] = { class = 6, talents = { 250 }, cooldown = 90, enUS_name = "Vampiric Blood" },
    [275699] = { class = 6, talents = { 252 }, cooldown = 45, enUS_name = "Apocalypse" },

    --------------------------------------------------------------------------------
    -- Shaman (updated 0208; note: check Elemental Storm/Fire Elemental)
    --------------------------------------------------------------------------------
    [8178] = { class = 7, talents = { 0 }, cooldown = 0, enUS_name = "Grounding Totem" },
    [51533] = { class = 7, talents = { 263 }, cooldown = 90, enUS_name = "Feral Spirit" },
    [108271] = { class = 7, talents = { 262, 263, 264 }, cooldown = 120, enUS_name = "Astral Shift" },
    [108280] = { class = 7, talents = { 264 }, cooldown = 120, enUS_name = "Healing Tide Totem" },
    [192249] = { class = 7, talents = { 262 }, cooldown = 5, enUS_name = "Storm Elemental" },
    [198067] = { class = 7, talents = { 262 }, cooldown = 5, enUS_name = "Fire Elemental" },

    --------------------------------------------------------------------------------
    -- Mage (updated 0208)
    --------------------------------------------------------------------------------
    [118] = { class = 8, talents = { 0 }, cooldown = 60, enUS_name = "Polymorph" },
    [12472] = { class = 8, talents = { 64 }, cooldown = 120, enUS_name = "Icy Veins" },
    [55342] = { class = 8, talents = { 62, 63, 64 }, cooldown = 120, enUS_name = "Mirror Image" },
    [110909] = { class = 8, talents = { 62, 63, 64 }, cooldown = 60, enUS_name = "Alter Time" },
    [190319] = { class = 8, talents = { 63 }, cooldown = 120, enUS_name = "Combustion" },
    [198144] = { class = 8, talents = { 64 }, cooldown = 60, enUS_name = "Ice Form" },
    [365350] = { class = 8, talents = { 62 }, cooldown = 90, enUS_name = "Arcane Surge" },
    [365362] = { class = 8, talents = { 62 }, cooldown = 90, enUS_name = "Arcane Surge" },

    --------------------------------------------------------------------------------
    -- Warlock (updated 0208)
    --------------------------------------------------------------------------------
    [104773] = { class = 9, talents = { 265, 266, 267 }, cooldown = 180, enUS_name = "Unending Resolve" },
    [205180] = { class = 9, talents = { 265 }, cooldown = 120, enUS_name = "Summon Darkglare" },
    [265187] = { class = 9, talents = { 266 }, cooldown = 60, enUS_name = "Summon Demonic Tyrant" },
    [335235] = { class = 9, talents = { 267 }, cooldown = 120, enUS_name = "Summon Infernal" },
    [367679] = { class = 9, talents = { 0 }, cooldown = 0, enUS_name = "Summon Blasphemy" },
    [387278] = { class = 9, talents = { 265 }, cooldown = 180, enUS_name = "Summon Darkglare" },

    --------------------------------------------------------------------------------
    -- Monk (updated 0208)
    --------------------------------------------------------------------------------
    [115203] = { class = 10, talents = { 268 }, cooldown = 360, enUS_name = "Fortifying Brew" },
    [115310] = { class = 10, talents = { 0 }, cooldown = 120, enUS_name = "Revival" },
    [132578] = { class = 10, talents = { 268 }, cooldown = 120, enUS_name = "Invoke Niuzao, the Black Ox" },
    [137639] = { class = 10, talents = { 269 }, cooldown = 16, enUS_name = "Storm, Earth, and Fire" },
    [243435] = { class = 10, talents = { 268, 269, 270 }, cooldown = 420, enUS_name = "Fortifying Brew" },
    [297850] = { class = 10, talents = { 70 }, cooldown = 120, enUS_name = "Revival" },
    [388615] = { class = 10, talents = { 270 }, cooldown = 120, enUS_name = "Restoral" },
    [395267] = { class = 10, talents = { 268 }, cooldown = 180, enUS_name = "Invoke Niuzao, the Black Ox" },

    --------------------------------------------------------------------------------
    -- Druid (updated 0208)
    --------------------------------------------------------------------------------
    [22812] = { class = 11, talents = { 102, 103, 104, 105 }, cooldown = 60, enUS_name = "Barkskin" },
    [50334] = { class = 11, talents = { 0 }, cooldown = 180, enUS_name = "Berserk" },
    [102543] = { class = 11, talents = { 103 }, cooldown = 180, enUS_name = "Incarnation: Avatar of Ashamane" },
    [102558] = { class = 11, talents = { 104 }, cooldown = 180, enUS_name = "Incarnation: Guardian of Ursoc" },
    [102560] = { class = 11, talents = { 102 }, cooldown = 120, enUS_name = "Incarnation: Chosen of Elune" },
    [106951] = { class = 11, talents = { 103 }, cooldown = 180, enUS_name = "Berserk" },
    [194223] = { class = 11, talents = { 102 }, cooldown = 120, enUS_name = "Celestial Alignment" },
    [383410] = { class = 11, talents = { 102 }, cooldown = 120, enUS_name = "Celestial Alignment" },
    [390414] = { class = 11, talents = { 102 }, cooldown = 120, enUS_name = "Incarnation: Chosen of Elune" },
    [1236574] = { class = 11, talents = { 105 }, cooldown = 180, enUS_name = "Tranquility" },

    --------------------------------------------------------------------------------
    -- Demon Hunter (updated 0208)
    --------------------------------------------------------------------------------
    [187827] = { class = 12, talents = { 581 }, cooldown = 120, enUS_name = "Metamorphosis" },
    [191427] = { class = 12, talents = { 577 }, cooldown = 120, enUS_name = "Metamorphosis" },
    [198589] = { class = 12, talents = { 577, 1480 }, cooldown = 60, enUS_name = "Blur" },
    [204021] = { class = 12, talents = { 581 }, cooldown = 60, enUS_name = "Fiery Brand" },
    [212800] = { class = 12, talents = { 0 }, cooldown = 60, enUS_name = "Blur" },
    [1217605] = { class = 12, talents = { 1480 }, cooldown = 0, enUS_name = "Void Metamorphosis" },

    --------------------------------------------------------------------------------
    -- Evoker
    --------------------------------------------------------------------------------
    [363916] = { class = 13, talents = { 1467, 1468, 1473 }, cooldown = 120, enUS_name = "Obsidian Scales" },
    [375087] = { class = 13, talents = { 1467 }, cooldown = 120, enUS_name = "Dragonrage" },
    [378464] = { class = 13, talents = { 0 }, cooldown = 90, enUS_name = "Nullifying Shroud" },
    [443069] = { class = 13, talents = { 0 }, cooldown = 120, enUS_name = "Well of Flame" },
}

-- ==================== Query Interface ====================
function InfinityTools:GetSpellCD(spellID)
    local data = self.CDDB[spellID]
    return data and data.cooldown or 0
end

function InfinityTools:GetSpellName(spellID)
    local data = self.CDDB[spellID]
    if not data then return nil end
    return data.enUS_name
end

function InfinityTools:GetSpellsByClass(classID)
    local result = {}
    for spellID, data in pairs(self.CDDB) do
        if data.class == classID then
            result[spellID] = data
        end
    end
    return result
end


