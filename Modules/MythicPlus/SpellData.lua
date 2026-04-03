local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then return end

local MODULE_KEY = "RRTTools.SpellData"
local DEFAULTS   = { enabled = false }
Core:GetModuleDB(MODULE_KEY, DEFAULTS)

-- NOTE: dungeon names below are English approximations for Midnight S1 dungeons.
-- "Manaforge Omega" is confirmed. Others may need updating once in-game names are verified.

-- ============================================================
-- Tag spell lists (spell ID sets per mechanic)
-- ============================================================

local TAG_LISTS = {
    aoe = {
        152953,153757,154135,154159,156793,159381,244579,248831,249082,374352,377004,377009,
        377034,377383,377389,377912,385958,386173,386202,387523,388392,388537,388546,388822,
        388863,388923,388940,388957,388982,390912,390918,396716,439488,467068,468221,471643,
        472054,472672,472745,472758,473258,473647,473668,473776,473786,473864,
        1214081,1214874,1216042,1216454,1216459,1216643,1216822,1216848,1216963,1217021,
        1217087,1219491,1224903,1225135,1225193,1225796,1243900,1245046,1246446,1246666,
        1248219,1248229,1248879,1248980,1249014,1249479,1251767,1251811,1251813,1252406,
        1252414,1252437,1252438,1252548,1252621,1252628,1252690,1252704,1252733,1252875,
        1252883,1253026,1253272,1253368,1253416,1253448,1253510,1253538,1253700,1253840,
        1253950,1253978,1253986,1254332,1254460,1254569,1254595,1254679,1255377,1255472,
        1255503,1255922,1256047,1256247,1257103,1257105,1257124,1257126,1257160,1257164,
        1257509,1257512,1257524,1257613,1257701,1257780,1257782,1257895,1258205,1258220,
        1258464,1258684,1258802,1259202,1259274,1259359,1259777,1259887,1260648,1261546,
        1261808,1261847,1262088,1262335,1262429,1262441,1262509,1262522,1262523,1262527,
        1262750,1262900,1263000,1263297,1263399,1263523,1263528,1263542,1263671,1263735,
        1263766,1263785,1264040,1264048,1264246,1264336,1264354,1264461,1264532,1264569,
        1264693,1264951,1264989,1265420,1265421,1265426,1265463,1265832,1266001,1266003,
        1268916,1269081,1269183,1269469,1270085,1270349,1270356,1270618,1271479,1271623,
        1272433,1273356,1276485,1276632,1276648,1276973,1277339,1277343,1277557,1278754,
        1278967,1278986,1279517,1279995,1280065,1280119,1280330,1281396,1281636,1281637,
        1281874,1282272,1282663,1282664,1282679,1282791,1282950,1283357,1285450,1285509,
    },
    los = {
        152953,153757,153954,154135,156793,159381,159382,244579,244750,245742,246913,246943,
        248829,248830,248831,249082,374343,376997,377344,377383,377389,377912,377991,378003,
        385958,386202,387691,388392,388544,388546,388796,388822,388841,388863,388957,388958,
        388976,388982,388984,389054,389055,390297,390915,390938,390942,390944,439488,
        465904,466556,467068,467120,467620,468659,468962,468966,470963,471648,472081,472556,
        472736,473657,473663,473672,473794,473864,474345,
        1214874,1215087,1216135,1216250,1216419,1216449,1216592,1216637,1216819,1216848,
        1216860,1216985,1217010,1217087,1217795,1219551,1223847,1223936,1245046,1248015,
        1248138,1248327,1248689,1249027,1249645,1249801,1249815,1250708,1251554,1251598,
        1252054,1252076,1252204,1252218,1252436,1252437,1252438,1252621,1252690,1252883,
        1253224,1253270,1253367,1253416,1253446,1253448,1253510,1253519,1253683,1253707,
        1253739,1253909,1254010,1254301,1254306,1254329,1254336,1254355,1254566,1254595,
        1254669,1254670,1254671,1254676,1254678,1254686,1254687,1254689,1254690,1255187,
        1255377,1255434,1255462,1255765,1255922,1255964,1255966,1256008,1256015,1256059,
        1256561,1257100,1257124,1257126,1257155,1257328,1257546,1257595,1257716,1257781,
        1257920,1258152,1258217,1258431,1258434,1258436,1258437,1258681,1258798,1259132,
        1259182,1259188,1259226,1259255,1259359,1259631,1259651,1259677,1259772,1259882,
        1261299,1261315,1261806,1262029,1262441,1262508,1262509,1262510,1262523,1262526,
        1263282,1263292,1263297,1263399,1263406,1263440,1263529,1263538,1263542,1263756,
        1263766,1263775,1263783,1263785,1263892,1264027,1264036,1264196,1264286,1264327,
        1264354,1264363,1264670,1264678,1264693,1265419,1265421,1265463,1265561,1265689,
        1265977,1266003,1266381,1266745,1267207,1268733,1268916,1269283,1269470,1270079,
        1270356,1271066,1271074,1271317,1271678,1273356,1276948,1276973,1277339,1277340,
        1277451,1277557,1278950,1278963,1279627,1279667,1280065,1280326,1280330,1281636,
        1281657,1282478,1282663,1282664,1282665,1282679,1282722,1282944,1283335,1283901,
        1285445,1285450,1285508,
    },
    interrupt = {
        152953,154396,244750,248831,388392,388862,468962,468966,472724,473657,473663,473794,
        1216135,1216592,1216819,1248327,1250708,1254010,1254294,1254669,1255187,1255377,
        1256008,1256015,1257601,1257716,1258431,1258436,1258681,1258997,1259182,1259255,
        1262510,1262523,1262526,1262941,1263292,1263892,1264186,1264327,1264693,1266381,
        1269283,1271074,1271094,1271479,1277340,1278893,1279627,1282722,1285445,
    },
    noReflect = {
        154043,154132,154135,181089,244579,373326,374352,386181,386201,388866,390912,390918,
        396716,466091,466559,467621,468442,468924,470212,471038,471650,472118,472745,472777,
        472795,472888,473649,473776,473789,473795,473868,474496,474528,
        1215897,1216298,1216834,1224104,1224299,1224401,1224903,1225135,1225201,1225792,
        1225796,1243752,1243905,1244907,1246446,1248007,1248219,1248229,1248879,1248980,
        1249478,1249479,1249638,1249806,1249818,1249947,1249948,1249989,1250851,1251626,
        1251775,1251811,1251813,1251833,1252130,1252134,1252218,1252406,1252414,1252417,
        1252429,1252622,1252628,1252675,1252676,1252691,1252704,1252733,1252816,1252875,
        1252910,1253368,1253511,1253520,1253543,1253686,1253709,1253779,1253844,1253977,
        1253986,1254043,1254175,1254332,1254338,1254460,1254569,1254666,1254672,1254677,
        1254679,1254689,1255208,1255310,1255335,1255503,1256247,1256387,1256586,1257105,
        1257160,1257164,1257736,1257745,1257746,1257780,1257782,1257895,1257898,1257914,
        1258140,1258160,1258174,1258205,1258220,1258433,1258445,1258451,1258459,1258684,
        1258820,1258826,1258997,1259116,1259183,1259202,1259205,1259274,1259664,1259731,
        1259777,1259786,1259794,1259887,1260648,1260709,1261546,1261799,1262088,1262429,
        1262441,1262506,1262519,1262522,1262527,1262596,1262630,1262745,1262900,1263523,
        1263532,1263716,1263735,1264040,1264042,1264159,1264299,1264453,1264461,1264569,
        1264687,1264987,1264989,1265420,1265426,1265832,1265999,1266001,1266188,1266480,
        1266485,1266488,1266706,1267207,1267274,1269081,1269183,1269220,1269222,1269469,
        1270085,1270098,1270349,1271009,1271317,1271433,1271543,1271676,1271956,1276485,
        1276632,1276752,1277343,1277556,1277761,1278882,1279418,1279517,1279668,1279994,
        1279995,1280113,1280119,1281396,1281634,1281637,1281874,1282051,1282053,1282244,
        1282251,1282252,1282678,1282723,1282745,1282791,1282915,1282950,1283371,1283770,
        1284627,1284633,1285450,1285509,1287905,
    },
    alwaysHit = {
        181089,376997,390912,471038,472745,472795,472888,474496,474528,
        1215897,1216459,1225792,1249478,1249479,1251023,1251554,1251579,1251775,1252414,
        1252417,1252676,1252690,1252733,1252877,1253511,1253538,1253709,1253844,1253986,
        1254338,1254460,1256387,1257103,1258820,1262429,1262745,1264453,1264505,1265426,
        1265999,1266188,1266480,1271543,1279668,1279994,1280113,1284954,
    },
    noBlock    = { 1262517 },
    noDodge    = {
        376997,388544,466064,467621,472662,474065,474075,474496,
        1216985,1248007,1253519,1254380,1254475,1255208,1258439,1262517,1262582,1263484,
        1263492,1263494,1269220,1277799,1282791,
    },
    noParry    = {
        376997,388544,466064,467621,472662,474065,474075,474496,
        1216985,1248007,1253519,1254380,1254475,1255208,1258439,1262517,1262582,1269220,
        1277799,1282791,
    },
    shieldImmunity = {
        388923,1216253,1216825,1245068,1251567,1252417,1253519,1253765,1258434,1261921,1284958,
    },
    -- Dispels
    dispelBleed   = { 245742,377344,396716,468659,1216985,1253739,1266488 },
    dispelCurse   = { 1258434,1264186,1281636 },
    dispelDisease = { 1246666,1258459 },
    dispelEnrage  = { 377389,390938,1216459,1254678,1255765,1259132,1264036 },
    dispelMagic   = {
        388392,468966,1214038,1216298,1216860,1245068,1248689,1249815,1254175,1254306,
        1254670,1255187,1255434,1256008,1258437,1258448,1258826,1259255,1259731,1260709,
        1261921,1262526,1263783,1265561,1270079,1271623,1273356,1277557,1280330,1282055,
        1284627,
    },
    dispelPoison  = { 473795,1216825 },
    -- Crowd control
    ccSleep       = {},
    ccBleeding    = { 245742,377344,396716,468659,1216985,1253739,1266488 },
    ccDisoriented = { 390938,1255765 },
    ccEnraged     = {},
    ccFleeing     = { 1214038,1258997,1259794,1266381,1269631,1282055 },
    ccFrozen      = {},
    ccPolymorphed = { 468966,1256008 },
    ccRooted      = {},
    ccSnared      = { 1258437,1261921,1262509,1263766,1264186,1269283 },
    ccStunned     = { 152953,378011,468442,470212,474075 },
}

-- Build reverse lookup: spellID → set of tag keys
local _spellTagCache = {}
do
    for tagKey, list in pairs(TAG_LISTS) do
        for _, id in ipairs(list) do
            if not _spellTagCache[id] then _spellTagCache[id] = {} end
            _spellTagCache[id][tagKey] = true
        end
    end
end

-- ============================================================
-- Tag definitions (display metadata)
-- ============================================================

local TAG_DEFS = {
    aoe           = { icon = 4630449,  name = "AoE",                 category = 1 },
    los           = { icon = 1405818,  name = "LOS Avoidable",       category = 1 },
    noReflect     = { icon = 132361,   name = "Not Reflectable",     category = 1 },
    alwaysHit     = { icon = 132212,   name = "Always Hits",         category = 1 },
    noBlock       = { icon = 132110,   name = "Not Blockable",       category = 1 },
    noDodge       = { icon = 136047,   name = "Not Dodgeable",       category = 1 },
    noParry       = { icon = 132269,   name = "Not Parriable",       category = 1 },
    shieldImmunity= { icon = 132361,   name = "Shield: Damage Only", category = 1 },
    interrupt     = { icon = 136020,   name = "Interruptible",       category = 2 },
    dispelBleed   = { icon = 132200,   name = "Dispel: Bleed",       category = 2 },
    dispelCurse   = { icon = 136122,   name = "Dispel: Curse",       category = 2 },
    dispelDisease = { icon = 132099,   name = "Dispel: Disease",     category = 2 },
    dispelEnrage  = { icon = 132163,   name = "Dispel: Enrage",      category = 2 },
    dispelMagic   = { icon = 136116,   name = "Dispel: Magic",       category = 2 },
    dispelPoison  = { icon = 134200,   name = "Dispel: Poison",      category = 2 },
    ccSleep       = { icon = 136090,   name = "CC: Sleep",           category = 3 },
    ccBleeding    = { icon = 132200,   name = "CC: Bleeding",        category = 3 },
    ccDisoriented = { icon = 136175,   name = "CC: Disoriented",     category = 3 },
    ccEnraged     = { icon = 132163,   name = "CC: Enraged",         category = 3 },
    ccFleeing     = { icon = 132293,   name = "CC: Fleeing",         category = 3 },
    ccFrozen      = { icon = 135834,   name = "CC: Frozen",          category = 3 },
    ccPolymorphed = { icon = 136071,   name = "CC: Polymorphed",     category = 3 },
    ccRooted      = { icon = 135848,   name = "CC: Rooted",          category = 3 },
    ccSnared      = { icon = 136102,   name = "CC: Snared",          category = 3 },
    ccStunned     = { icon = 135860,   name = "CC: Stunned",         category = 3 },
}

-- ============================================================
-- NPC database
-- Key = English dungeon name (must match C_ChallengeMode.GetMapUIInfo result).
-- "Manaforge Omega" is confirmed. Others are approximate Midnight S1 names
-- and may require correction once verified in-game.
-- NPC type values: Humanoid, Beast, Aberration, Elemental, Dragonkin, Mechanical, Undead
-- level: 90=normal, 91=elite, 92=boss
-- ============================================================

local NPC_DB = {
    ["Council's Seat"] = {
        ["Grand Weave-Shadow"]      = { displayID=124089, npcID=122423, level=91, type="Humanoid",  spells={1262508,1264286} },
        ["Shadow Guard Warrior"]    = { displayID=124440, npcID=122403, level=90, type="Humanoid",  spells={1262517,1264036} },
        ["Shadow-wing Skate"]       = { displayID=78427,  npcID=125340, level=92, type="Beast",     spells={246943,248829,248830,248831} },
        ["Governor Nezal"]          = { displayID=78415,  npcID=122056, level=92, type="Humanoid",  spells={244750,246913,1263528,1263529,1263532,1263538,1263542} },
        ["Dread Soulspeaker"]       = { displayID=124412, npcID=122404, level=90, type="Humanoid",  spells={1262526,1262527} },
        ["Merciless Rift Hunter"]   = { displayID=75003,  npcID=122413, level=90, type="Humanoid",  spells={1262519,1277339,1277340} },
        ["Ascendant Zural"]         = { displayID=77871,  npcID=122313, level=92, type="Humanoid",  spells={244579,1263282,1263297,1263399,1263440,1263484,1263492,1263494,1268916} },
        ["Shadow War Elite"]        = { displayID=124453, npcID=122421, level=91, type="Humanoid",  spells={1269183,1280326} },
        ["Shadow Tendril"]          = { displayID=77103,  npcID=122827, level=90, type="Aberration",spells={249082,1268733} },
        ["Brutal Conqueror"]        = { displayID=75011,  npcID=124171, level=91, type="Humanoid",  spells={1262506,1262509,1277343} },
        ["Voidvein Annihilator"]    = { displayID=126552, npcID=252756, level=91, type="Mechanical",spells={1262335,1262429,1262441} },
        ["Saprish"]                 = { displayID=76771,  npcID=122316, level=92, type="Humanoid",  spells={246943,1263523,1280065} },
        ["Void Tendril"]            = { displayID=94382,  npcID=256424, level=90, type="Aberration",spells={1269081} },
        ["Rift Guardian"]           = { displayID=136883, npcID=122571, level=91, type="Aberration",spells={1264505,1264532,1264569,1280330} },
        ["Voracious Shadow-Fin"]    = { displayID=74902,  npcID=255320, level=90, type="Beast",     spells={1264670,1264678} },
        ["Hungry Shattered"]        = { displayID=75479,  npcID=122322, level=90, type="Humanoid",  spells={1269469,1269470} },
        ["Rula"]                    = { displayID=141808, npcID=124729, level=92, type="Unspecified",spells={1264159,1264196,1265419,1265420,1265421,1265426,1265463,1265689,1265999,1266001,1266003,1267207,1267274,1268598,1268646,1268647} },
        ["Dark Hexcaster"]          = { displayID=124411, npcID=122405, level=90, type="Humanoid",  spells={1262510,1262522,1262523} },
        ["Darktusk"]                = { displayID=76602,  npcID=122319, level=92, type="Beast",     spells={245742,246943} },
    },
    ["Aetherdine Academy"] = {
        ["Willful Textbook"]        = { displayID=109308, npcID=196044, level=90, type="Elemental", spells={387523,388392} },
        ["Krozz"]                   = { displayID=110805, npcID=191736, level=92, type="Beast",     spells={181089,376997,377004,377009,377034,1276752,1285508,1285509} },
        ["Echo of Dralorraszus"]    = { displayID=108925, npcID=190609, level=92, type="Dragonkin", spells={373326,374343,374352,388822,439488,1279418,1282251,1282252} },
        ["Lead Eagle"]              = { displayID=101438, npcID=192333, level=91, type="Beast",     spells={377383,377389,1276632} },
        ["Arcane Brigand"]          = { displayID=62384,  npcID=196694, level=90, type="Elemental", spells={389054,389055} },
        ["Guardian Sentinel"]       = { displayID=26385,  npcID=192680, level=91, type="Elemental", spells={377912,377991,378003,378011} },
        ["Wraith Invoker"]          = { displayID=109105, npcID=196202, level=90, type="Dragonkin", spells={1279627} },
        ["Vicious Predator"]        = { displayID=110795, npcID=196671, level=91, type="Beast",     spells={388940,388942,388957,388958,388976,388982,388984} },
        ["Malicious Lasher"]        = { displayID=104635, npcID=197219, level=91, type="Elemental", spells={390912,390915,390918,1282244} },
        ["Vixamus"]                 = { displayID=109099, npcID=194181, level=92, type="Elemental", spells={385958,386173,386181,386201,386202,387691,388537,388546,388651} },
        ["Spellbind Axe"]           = { displayID=23926,  npcID=196577, level=90, type="Elemental", spells={387523,388841,1270098} },
        ["Aetherdine Echo Knight"]  = { displayID=109104, npcID=196200, level=90, type="Dragonkin", spells={1270349,1270356} },
        ["Ancientthorn"]            = { displayID=109194, npcID=196482, level=92, type="Elemental", spells={388544,388623,388796,388923,390297,396716} },
        ["Enraged Glider"]          = { displayID=103762, npcID=197406, level=90, type="Beast",     spells={390938,390942,390944} },
        ["Corrupted Spelldevour"]   = { displayID=107525, npcID=196045, level=90, type="Elemental", spells={387523,388862,388863,388866} },
        ["Territory Eagle"]         = { displayID=34918,  npcID=192329, level=90, type="Beast",     spells={377344,377389} },
    },
    ["Conduit Nexus"] = {
        ["Conduit Stalker [DNT]"]   = { displayID=169,    npcID=250299, level=90, type="Unspecified",spells={1251579} },
        ["Lightborn Swarm"]         = { displayID=52309,  npcID=254932, level=90, type="Unspecified",spells={1263775,1282944} },
        ["Luminary"]                = { displayID=140804, npcID=254926, level=90, type="Elemental", spells={1263892,1277557} },
        ["Split Mirror"]            = { displayID=136110, npcID=251568, level=92, type="Humanoid",  spells={1255310,1257601,1269220,1269222,1271956} },
        ["Split Mirror (Alt)"]      = { displayID=140945, npcID=255179, level=91, type="Humanoid",  spells={1264429} },
        ["Kasrethir"]               = { displayID=131510, npcID=241539, level=92, type="Humanoid",  spells={1250553,1251626,1251767,1251772,1257509,1257512,1257524,1264040,1264042,1264048,1265894,1276485,1282915} },
        ["Cursed Void Summoner"]    = { displayID=131624, npcID=248706, level=90, type="Aberration",spells={1252218,1281636} },
        ["Node Tender"]             = { displayID=136884, npcID=249147, level=90, type="Elemental", spells={1252406,1252414,1252417} },
        ["Phase Crawler"]           = { displayID=130498, npcID=249456, level=91, type="Aberration",spells={1252054,1252076,1252204} },
        ["Nexus Conduit"]           = { displayID=140944, npcID=251325, level=91, type="Elemental", spells={1252621,1252628,1252690} },
        ["Resonant Keeper"]         = { displayID=139237, npcID=249785, level=90, type="Elemental", spells={1252875,1252883,1253026} },
        ["Echo Weave"]              = { displayID=136107, npcID=249457, level=90, type="Elemental", spells={1253224,1253270,1253367} },
    },
    ["Salhyr Mines"] = {
        ["Mine Overseer"]           = { displayID=126551, npcID=252754, level=91, type="Humanoid",  spells={1257100,1257103,1257105} },
        ["Ore Golem"]               = { displayID=126549, npcID=252751, level=90, type="Mechanical",spells={1257124,1257126,1257155} },
        ["Venomous Crawler"]        = { displayID=74888,  npcID=252759, level=90, type="Beast",     spells={1257160,1257164} },
        ["Detonation Engineer"]     = { displayID=124419, npcID=252753, level=91, type="Humanoid",  spells={1257328,1257509,1257512} },
        ["Salhyr Blademaster"]      = { displayID=124418, npcID=252752, level=91, type="Humanoid",  spells={1257524,1257546,1257595} },
        ["Cave Stalker"]            = { displayID=75006,  npcID=252757, level=90, type="Beast",     spells={1257613,1257701} },
        ["Slag Elemental"]          = { displayID=73337,  npcID=252760, level=90, type="Elemental", spells={1257716,1257780,1257782} },
        ["Forgemaster Gorvek"]      = { displayID=126550, npcID=252755, level=92, type="Humanoid",  spells={1257895,1257898,1257914,1258140,1258160,1258174,1258205,1258220} },
    },
    ["Mesaral Caverns"] = {
        ["Cave Lurker"]             = { displayID=76607,  npcID=255010, level=90, type="Beast",     spells={1258431,1258433,1258434} },
        ["Pale Crawler"]            = { displayID=75484,  npcID=255012, level=90, type="Beast",     spells={1258436,1258437,1258439} },
        ["Fungal Spewer"]           = { displayID=101063, npcID=255014, level=90, type="Elemental", spells={1258445,1258448,1258451} },
        ["Crystal Warden"]          = { displayID=131620, npcID=255016, level=91, type="Elemental", spells={1258459,1258464,1258681} },
        ["Mesaral Shaman"]          = { displayID=124427, npcID=255018, level=91, type="Humanoid",  spells={1258684,1258798,1258820} },
        ["Cavern Horror"]           = { displayID=75492,  npcID=255020, level=92, type="Aberration",spells={1258802,1258826,1258863} },
        ["Stone Sentinel"]          = { displayID=136882, npcID=255022, level=91, type="Elemental", spells={1258940,1258997,1259116} },
        ["Drillmaster Tharex"]      = { displayID=124425, npcID=255024, level=92, type="Humanoid",  spells={1259132,1259182,1259183,1259188,1259202,1259205,1259226,1259255} },
    },
    ["Sunspire"] = {
        ["Sunguard Sentinel"]       = { displayID=124451, npcID=257010, level=91, type="Humanoid",  spells={1259274,1259359,1259631} },
        ["Cloud Drifter"]           = { displayID=93717,  npcID=257012, level=90, type="Beast",     spells={1259651,1259664,1259677} },
        ["Storm Caller"]            = { displayID=124450, npcID=257014, level=91, type="Humanoid",  spells={1259731,1259772,1259777} },
        ["Peak Predator"]           = { displayID=101438, npcID=257016, level=90, type="Beast",     spells={1259786,1259794,1259882} },
        ["Ascendant Stormweaver"]   = { displayID=77879,  npcID=257018, level=91, type="Humanoid",  spells={1259887,1260648,1260709} },
        ["Apex Wyrm"]               = { displayID=136960, npcID=257020, level=92, type="Dragonkin", spells={1261299,1261315,1261546,1261799,1261806} },
        ["Stormcrest Protector"]    = { displayID=124452, npcID=257022, level=91, type="Humanoid",  spells={1261808,1261847,1262029} },
        ["High Commander Aerus"]    = { displayID=124449, npcID=257024, level=92, type="Humanoid",  spells={1262088,1262335,1262429,1262441} },
    },
    ["Windrunner's Spire"] = {
        ["Forsaken Marauder"]       = { displayID=32561,  npcID=258010, level=90, type="Undead",    spells={1262506,1262509,1262510} },
        ["Dark Ranger"]             = { displayID=32742,  npcID=258012, level=91, type="Undead",    spells={1262517,1262519,1262522} },
        ["Banshee Warden"]          = { displayID=95549,  npcID=258014, level=91, type="Undead",    spells={1262523,1262526,1262527} },
        ["Deathguard Captain"]      = { displayID=32562,  npcID=258016, level=91, type="Undead",    spells={1262596,1262630,1262745} },
        ["Void-touched Revenant"]   = { displayID=94380,  npcID=258018, level=90, type="Undead",    spells={1262750,1262900,1263000} },
        ["Forsaken Siege Engineer"] = { displayID=32557,  npcID=258020, level=90, type="Undead",    spells={1263282,1263292,1263297} },
        ["Sylvanas Windrunner"]     = { displayID=32744,  npcID=258022, level=92, type="Undead",    spells={1263399,1263406,1263440,1263484,1263492,1263494,1263523,1263528,1263529,1263532,1263538,1263542,1263671,1263716,1263735} },
    },
    ["Manaforge Omega"] = {
        ["Forge Tender"]            = { displayID=126548, npcID=254000, level=90, type="Mechanical",spells={1263756,1263766,1263775,1263783,1263785} },
        ["Arcane Construct"]        = { displayID=123802, npcID=254002, level=90, type="Mechanical",spells={1263892,1264027,1264036} },
        ["Mana-charged Elemental"]  = { displayID=73337,  npcID=254004, level=91, type="Elemental", spells={1264040,1264042,1264048,1264159} },
        ["Overloaded Sentinel"]     = { displayID=136883, npcID=254006, level=91, type="Mechanical",spells={1264196,1264246,1264286} },
        ["Nexus King"] = {
            displayID=126546, npcID=254008, level=92, type="Humanoid",
            spells={1264299,1264327,1264336,1264354,1264363,1264429,1264453,1264461,1264505,1264532,1264569},
        },
        ["Dimensius"] = {
            displayID=126544, npcID=254010, level=92, type="Aberration",
            spells={1264670,1264678,1264687,1264693,1264951,1264987,1264989,1265419,1265420,1265421,
                    1265426,1265463,1265561,1265689,1265832,1265977,1265999,1266001,1266003,1266188,
                    1266381,1266480,1266485,1266488,1266706,1267207,1267274},
        },
    },
}

-- Build a flat npcID → entry lookup for quick access
local _npcByID = {}
for dungeonName, npcs in pairs(NPC_DB) do
    for npcName, data in pairs(npcs) do
        _npcByID[data.npcID] = { dungeon = dungeonName, name = npcName, data = data }
    end
end

-- ============================================================
-- Module object
-- ============================================================

local SpellData    = RRT_NS.MythicSpellData or {}
RRT_NS.MythicSpellData = SpellData

SpellData.TagDefs  = TAG_DEFS
SpellData.NPCDatabase = NPC_DB

-- ---- Dungeon catalog (built at load time) ------------------

local function GetDungeonIcon(mapID)
    local InfinityDB = _G.InfinityDB
    if InfinityDB and InfinityDB.InstanceIconByMapID and InfinityDB.InstanceIconByMapID[mapID] then
        return InfinityDB.InstanceIconByMapID[mapID]
    end
    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local _, _, _, tex = C_ChallengeMode.GetMapUIInfo(mapID)
        if tex and tex > 0 then return tex end
    end
    return 134400
end

local function BuildDungeonCatalog()
    local list  = {}
    local known = {}
    local mapList = (C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapTable()) or {}

    for _, mapID in ipairs(mapList) do
        local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
        if mapName and mapName ~= "" then
            list[#list + 1] = { mapID = mapID, name = mapName, icon = GetDungeonIcon(mapID) }
            known[mapName] = true
        end
    end

    -- Include dungeons known by teleport data that weren't in the map table
    local InfinityDB = _G.InfinityDB
    for name, spellID in pairs(InfinityDB and InfinityDB.TeleportData or {}) do
        if not known[name] then
            list[#list + 1] = { mapID = 0, name = name, icon = GetDungeonIcon(0), teleportSpellID = spellID }
        end
    end

    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

SpellData.Dungeons = BuildDungeonCatalog()

-- ---- Interrupt catalog -------------------------------------

local function BuildInterruptCatalog()
    local InfinityDB = _G.InfinityDB
    if not InfinityDB or not InfinityDB.InterruptData then return {} end
    local rows = {}
    for specID, iData in pairs(InfinityDB.InterruptData) do
        local spec = InfinityDB.SpecByID and InfinityDB.SpecByID[specID]
        local info = C_Spell.GetSpellInfo(iData.id)
        rows[#rows + 1] = {
            specID    = specID,
            specName  = spec and spec.name or tostring(specID),
            classID   = spec and spec.classID or 0,
            spellID   = iData.id,
            spellName = info and info.name or ("Spell "..iData.id),
            spellIcon = info and info.iconID or 136071,
            cooldown  = iData.cd or 0,
        }
    end
    table.sort(rows, function(a, b)
        if a.specName ~= b.specName then return a.specName < b.specName end
        return a.spellID < b.spellID
    end)
    return rows
end

SpellData.Interrupts = BuildInterruptCatalog()

-- ---- Public API --------------------------------------------

function SpellData:GetDungeonList()
    return self.Dungeons
end

function SpellData:GetInterruptCatalog()
    return self.Interrupts
end

function SpellData:GetNPCsForDungeon(dungeonName)
    return NPC_DB[dungeonName] or {}
end

function SpellData:GetNPCByID(npcID)
    return _npcByID[npcID]
end

--- Returns a list of { tagKey, tagDef } for a given spell ID.
--- Tags are split into two categories:
---   category 1 = footer (MISC: AoE, LOS, reflect, etc.)
---   category 2+ = inline (interrupt, dispel, CC)
function SpellData:GetTagsForSpell(spellID)
    local tagSet = _spellTagCache[spellID]
    if not tagSet then return {}, {} end
    local inline, footer = {}, {}
    for tagKey in pairs(tagSet) do
        local def = TAG_DEFS[tagKey]
        if def then
            if def.category >= 2 then
                inline[#inline + 1] = { key = tagKey, def = def }
            else
                footer[#footer + 1] = { key = tagKey, def = def }
            end
        end
    end
    table.sort(inline, function(a, b) return a.def.category < b.def.category end)
    return inline, footer
end

--- Pre-request spell data for all spells in the NPC database.
function SpellData:RequestAllSpellData()
    for _, npcs in pairs(NPC_DB) do
        for _, npc in pairs(npcs) do
            for _, id in ipairs(npc.spells) do
                C_Spell.RequestLoadSpellData(id)
            end
        end
    end
end

--- Search across dungeons, NPCs, and interrupts.
function SpellData:Search(query)
    query = tostring(query or ""):lower()
    local results = {}

    if query == "" then
        for _, entry in ipairs(self.Dungeons) do
            results[#results + 1] = { kind = "dungeon", title = entry.name, icon = entry.icon, entry = entry }
        end
        for _, row in ipairs(self.Interrupts) do
            results[#results + 1] = { kind = "interrupt", title = row.spellName, subtitle = string.format("%s / %ds", row.specName, row.cooldown), icon = row.spellIcon, entry = row }
        end
        return results
    end

    for _, entry in ipairs(self.Dungeons) do
        if entry.name:lower():find(query, 1, true) then
            results[#results + 1] = { kind = "dungeon", title = entry.name, icon = entry.icon, entry = entry }
        end
        local npcs = NPC_DB[entry.name] or {}
        for npcName, npc in pairs(npcs) do
            if npcName:lower():find(query, 1, true) then
                results[#results + 1] = { kind = "npc", title = npcName, subtitle = entry.name, icon = 0, entry = { dungeon = entry.name, name = npcName, data = npc } }
            end
        end
    end

    for _, row in ipairs(self.Interrupts) do
        local hay = (row.spellName .. " " .. row.specName):lower()
        if hay:find(query, 1, true) then
            results[#results + 1] = { kind = "interrupt", title = row.spellName, subtitle = string.format("%s / %ds", row.specName, row.cooldown), icon = row.spellIcon, entry = row }
        end
    end

    return results
end

Core:ReportReady(MODULE_KEY)
