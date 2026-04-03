-- [[ Spell Encyclopedia Database (Spell Data) ]]
-- { Key = "RevMplusInfoSpellData", Name = "Spell Encyclopedia Database", Desc = "Stores all spell mechanic data. Used as the backend data source for SpellInfo.", Category = 2 },

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local InfinityState = InfinityTools.State

local INFINITY_MODULE_KEY = "RevMplusInfoSpellData"

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

InfinitySpellInfo = InfinitySpellInfo or {}

InfinitySpellInfo.DungeonAbbr = {
    ["Seat"]   = "Seat",
    ["Eco"]    = "Eco",
    ["Nexus"]  = "Nexus",
    ["Mold"]   = "Mold",
    ["Myza"]   = "Myza",
    ["Sky"]    = "Sky",
    ["Vortex"] = "Vortex",
    ["MGT"]    = "MGT",
}

InfinitySpellInfo.aoe_List = { 152953, 153757, 154135, 154159, 156793, 159381, 244579, 248831, 249082, 374352, 377004, 377009, 377034, 377383, 377389, 377912, 385958, 386173, 386202, 387523, 388392, 388537, 388546, 388822, 388863, 388923, 388940, 388957, 388982, 390912, 390918, 396716, 439488, 467068, 468221, 471643, 472054, 472672, 472745, 472758, 473258, 473647, 473668, 473776, 473786, 473864, 1214081, 1214874, 1216042, 1216454, 1216459, 1216643, 1216822, 1216848, 1216963, 1217021, 1217087, 1219491, 1224903, 1225135, 1225193, 1225796, 1243900, 1245046, 1246446, 1246666, 1248219, 1248229, 1248879, 1248980, 1249014, 1249479, 1251767, 1251811, 1251813, 1252406, 1252414, 1252437, 1252438, 1252548, 1252621, 1252628, 1252690, 1252704, 1252733, 1252875, 1252883, 1253026, 1253272, 1253368, 1253416, 1253448, 1253510, 1253538, 1253700, 1253840, 1253950, 1253978, 1253986, 1254332, 1254460, 1254569, 1254595, 1254679, 1255377, 1255472, 1255503, 1255922, 1256047, 1256247, 1257103, 1257105, 1257124, 1257126, 1257160, 1257164, 1257509, 1257512, 1257524, 1257613, 1257701, 1257780, 1257782, 1257895, 1258205, 1258220, 1258464, 1258684, 1258802, 1259202, 1259274, 1259359, 1259777, 1259887, 1260648, 1261546, 1261808, 1261847, 1262088, 1262335, 1262429, 1262441, 1262509, 1262522, 1262523, 1262527, 1262750, 1262900, 1263000, 1263297, 1263399, 1263523, 1263528, 1263542, 1263671, 1263735, 1263766, 1263785, 1264040, 1264048, 1264246, 1264336, 1264354, 1264461, 1264532, 1264569, 1264693, 1264951, 1264989, 1265420, 1265421, 1265426, 1265463, 1265832, 1266001, 1266003, 1268916, 1269081, 1269183, 1269469, 1270085, 1270349, 1270356, 1270618, 1271479, 1271623, 1272433, 1273356, 1276485, 1276632, 1276648, 1276973, 1277339, 1277343, 1277557, 1278754, 1278967, 1278986, 1279517, 1279995, 1280065, 1280119, 1280330, 1281396, 1281636, 1281637, 1281874, 1282272, 1282663, 1282664, 1282679, 1282791, 1282950, 1283357, 1285450, 1285509 }
InfinitySpellInfo.los_List = { 152953, 153757, 153954, 154135, 156793, 159381, 159382, 244579, 244750, 245742, 246913, 246943, 248829, 248830, 248831, 249082, 374343, 376997, 377344, 377383, 377389, 377912, 377991, 378003, 385958, 386202, 387691, 388392, 388544, 388546, 388796, 388822, 388841, 388863, 388957, 388958, 388976, 388982, 388984, 389054, 389055, 390297, 390915, 390938, 390942, 390944, 439488, 465904, 466556, 467068, 467120, 467620, 468659, 468962, 468966, 470963, 471648, 472081, 472556, 472736, 473657, 473663, 473672, 473794, 473864, 474345, 1214874, 1215087, 1216135, 1216250, 1216419, 1216449, 1216592, 1216637, 1216819, 1216848, 1216860, 1216985, 1217010, 1217087, 1217795, 1219551, 1223847, 1223936, 1245046, 1248015, 1248138, 1248327, 1248689, 1249027, 1249645, 1249801, 1249815, 1250708, 1251554, 1251598, 1252054, 1252076, 1252204, 1252218, 1252436, 1252437, 1252438, 1252621, 1252690, 1252883, 1253224, 1253270, 1253367, 1253416, 1253446, 1253448, 1253510, 1253519, 1253683, 1253707, 1253739, 1253909, 1254010, 1254301, 1254306, 1254329, 1254336, 1254355, 1254566, 1254595, 1254669, 1254670, 1254671, 1254676, 1254678, 1254686, 1254687, 1254689, 1254690, 1255187, 1255377, 1255434, 1255462, 1255765, 1255922, 1255964, 1255966, 1256008, 1256015, 1256059, 1256561, 1257100, 1257124, 1257126, 1257155, 1257328, 1257546, 1257595, 1257716, 1257781, 1257920, 1258152, 1258217, 1258431, 1258434, 1258436, 1258437, 1258681, 1258798, 1259132, 1259182, 1259188, 1259226, 1259255, 1259359, 1259631, 1259651, 1259677, 1259772, 1259882, 1261299, 1261315, 1261806, 1262029, 1262441, 1262508, 1262509, 1262510, 1262523, 1262526, 1263282, 1263292, 1263297, 1263399, 1263406, 1263440, 1263529, 1263538, 1263542, 1263756, 1263766, 1263775, 1263783, 1263785, 1263892, 1264027, 1264036, 1264196, 1264286, 1264327, 1264354, 1264363, 1264670, 1264678, 1264693, 1265419, 1265421, 1265463, 1265561, 1265689, 1265977, 1266003, 1266381, 1266745, 1267207, 1268733, 1268916, 1269283, 1269470, 1270079, 1270356, 1271066, 1271074, 1271317, 1271678, 1273356, 1276948, 1276973, 1277339, 1277340, 1277451, 1277557, 1278950, 1278963, 1279627, 1279667, 1280065, 1280326, 1280330, 1281636, 1281657, 1282478, 1282663, 1282664, 1282665, 1282679, 1282722, 1282944, 1283335, 1283901, 1285445, 1285450, 1285508 }
InfinitySpellInfo.interrupt_List = { 152953, 154396, 244750, 248831, 388392, 388862, 468962, 468966, 472724, 473657, 473663, 473794, 1216135, 1216592, 1216819, 1248327, 1250708, 1254010, 1254294, 1254669, 1255187, 1255377, 1256008, 1256015, 1257601, 1257716, 1258431, 1258436, 1258681, 1258997, 1259182, 1259255, 1262510, 1262523, 1262526, 1262941, 1263292, 1263892, 1264186, 1264327, 1264693, 1266381, 1269283, 1271074, 1271094, 1271479, 1277340, 1278893, 1279627, 1282722, 1285445 }
InfinitySpellInfo.noReflect_List = { 154043, 154132, 154135, 181089, 244579, 373326, 374352, 386181, 386201, 388866, 390912, 390918, 396716, 466091, 466559, 467621, 468442, 468924, 470212, 471038, 471650, 472118, 472745, 472777, 472795, 472888, 473649, 473776, 473789, 473795, 473868, 474496, 474528, 1215897, 1216298, 1216834, 1224104, 1224299, 1224401, 1224903, 1225135, 1225201, 1225792, 1225796, 1243752, 1243905, 1244907, 1246446, 1248007, 1248219, 1248229, 1248879, 1248980, 1249478, 1249479, 1249638, 1249806, 1249818, 1249947, 1249948, 1249989, 1250851, 1251626, 1251775, 1251811, 1251813, 1251833, 1252130, 1252134, 1252218, 1252406, 1252414, 1252417, 1252429, 1252622, 1252628, 1252675, 1252676, 1252691, 1252704, 1252733, 1252816, 1252875, 1252910, 1253368, 1253511, 1253520, 1253543, 1253686, 1253709, 1253779, 1253844, 1253977, 1253986, 1254043, 1254175, 1254332, 1254338, 1254460, 1254569, 1254666, 1254672, 1254677, 1254679, 1254689, 1255208, 1255310, 1255335, 1255503, 1256247, 1256387, 1256586, 1257105, 1257160, 1257164, 1257736, 1257745, 1257746, 1257780, 1257782, 1257895, 1257898, 1257914, 1258140, 1258160, 1258174, 1258205, 1258220, 1258433, 1258445, 1258451, 1258459, 1258684, 1258820, 1258826, 1258997, 1259116, 1259183, 1259202, 1259205, 1259274, 1259664, 1259731, 1259777, 1259786, 1259794, 1259887, 1260648, 1260709, 1261546, 1261799, 1262088, 1262429, 1262441, 1262506, 1262519, 1262522, 1262527, 1262596, 1262630, 1262745, 1262900, 1263523, 1263532, 1263716, 1263735, 1264040, 1264042, 1264159, 1264299, 1264453, 1264461, 1264569, 1264687, 1264987, 1264989, 1265420, 1265426, 1265832, 1265999, 1266001, 1266188, 1266480, 1266485, 1266488, 1266706, 1267207, 1267274, 1269081, 1269183, 1269220, 1269222, 1269469, 1270085, 1270098, 1270349, 1271009, 1271317, 1271433, 1271543, 1271676, 1271956, 1276485, 1276632, 1276752, 1277343, 1277556, 1277761, 1278882, 1279418, 1279517, 1279668, 1279994, 1279995, 1280113, 1280119, 1281396, 1281634, 1281637, 1281874, 1282051, 1282053, 1282244, 1282251, 1282252, 1282678, 1282723, 1282745, 1282791, 1282915, 1282950, 1283371, 1283770, 1284627, 1284633, 1285450, 1285509, 1287905 }
InfinitySpellInfo.alwaysHit_List = { 181089, 376997, 390912, 471038, 472745, 472795, 472888, 474496, 474528, 1215897, 1216459, 1225792, 1249478, 1249479, 1251023, 1251554, 1251579, 1251775, 1252414, 1252417, 1252676, 1252690, 1252733, 1252877, 1253511, 1253538, 1253709, 1253844, 1253986, 1254338, 1254460, 1256387, 1257103, 1258820, 1262429, 1262745, 1264453, 1264505, 1265426, 1265999, 1266188, 1266480, 1271543, 1279668, 1279994, 1280113, 1284954 }
InfinitySpellInfo.noBlock_List = { 1262517 }
InfinitySpellInfo.noDodge_List = { 376997, 388544, 466064, 467621, 472662, 474065, 474075, 474496, 1216985, 1248007, 1253519, 1254380, 1254475, 1255208, 1258439, 1262517, 1262582, 1263484, 1263492, 1263494, 1269220, 1277799, 1282791 }
InfinitySpellInfo.noParry_List = { 376997, 388544, 466064, 467621, 472662, 474065, 474075, 474496, 1216985, 1248007, 1253519, 1254380, 1254475, 1255208, 1258439, 1262517, 1262582, 1269220, 1277799, 1282791 }
InfinitySpellInfo.shieldImmunity_List = { 388923, 1216253, 1216825, 1245068, 1251567, 1252417, 1253519, 1253765, 1258434, 1261921, 1284958 }

InfinitySpellInfo.DispelBleed_List = { 245742, 377344, 396716, 468659, 1216985, 1253739, 1266488 }                                                                                     --Bleed
InfinitySpellInfo.DispelCurse_List = { 1258434, 1264186, 1281636 }                                                                                                                     --Curse
InfinitySpellInfo.DispelDisease_List = { 1246666, 1258459 }                                                                                                                            --Disease
InfinitySpellInfo.DispelEnrage_List = { 377389, 390938, 1216459, 1254678, 1255765, 1259132, 1264036 }                                                                                  --Enrage
InfinitySpellInfo.DispelMagic_List = { 388392, 468966, 1214038, 1216298, 1216860, 1245068, 1248689, 1249815, 1254175, 1254306, 1254670, 1255187, 1255434, 1256008, 1258437, 1258448, 1258826, 1259255, 1259731, 1260709, 1261921, 1262526, 1263783, 1265561, 1270079, 1271623, 1273356, 1277557, 1280330, 1282055, 1284627 } --Magic
InfinitySpellInfo.DispelPoison_List = { 473795, 1216825 }                                                                                                                              --Poison

InfinitySpellInfo.MechanicAsleep_List = { }                                        --Sleep
InfinitySpellInfo.MechanicBleeding_List = { 245742, 377344, 396716, 468659, 1216985, 1253739, 1266488 } --Bleed
InfinitySpellInfo.MechanicDisoriented_List = { 390938, 1255765 }                   --Disorient
InfinitySpellInfo.MechanicEnraged_List = { }                                       --Enrage
InfinitySpellInfo.MechanicFleeing_List = { 1214038, 1258997, 1259794, 1266381, 1269631, 1282055 } --Fear
InfinitySpellInfo.MechanicFrozen_List = { }                                        --Freeze
InfinitySpellInfo.MechanicPolymorphed_List = { 468966, 1256008 }                   --Polymorph
InfinitySpellInfo.MechanicRooted_List = { }                                        --Root
InfinitySpellInfo.MechanicSnared_List = { 1258437, 1261921, 1262509, 1263766, 1264186, 1269283 } --Snare
InfinitySpellInfo.MechanicStunned_List = { 152953, 378011, 468442, 470212, 474075 } --Stun


InfinitySpellInfo.TagDefs = {
    --MISC
    aoe                 = { icon = 4630449, name = "Area Damage", category = 1 },
    los                 = { icon = 1405818, name = "Line of Sight", category = 1 },
    interrupt           = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV17.png", name = "Interruptible", category = 2 },
    noReflect           = { icon = 132361, name = "Cannot Reflect", category = 1 },
    alwaysHit           = { icon = 132212, name = "Always Hits", category = 1 },
    noBlock             = { icon = 132110, name = "Cannot Block", category = 1 },
    noDodge             = { icon = 136047, name = "Cannot Dodge", category = 1 },
    noParry             = { icon = 132269, name = "Cannot Parry", category = 1 },
    shieldImmunity      = { icon = 132361, name = "Reflect Immune", category = 1 },

    --Dispel
    DispelBleed         = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV5.png", name = "Bleed", category = 2 },
    DispelCurse         = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV3.png", name = "Curse", category = 2 },
    DispelDisease       = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV6.png", name = "Disease", category = 2 },
    DispelEnrage        = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV7.png", name = "Enrage", category = 2 },
    DispelMagic         = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV9.png", name = "Magic", category = 2 },
    DispelPoison        = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV2.png", name = "Poison", category = 2 },

    --CC
    MechanicAsleep      = { icon = 136090, name = "Sleep", category = 3 },
    MechanicBleeding    = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV5.png", name = "Bleed", category = 3 },
    MechanicDisoriented = { icon = 136175, name = "Disorient", category = 3 },
    MechanicEnraged     = { icon = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV7.png", name = "Enrage", category = 3 },
    MechanicFrozen      = { icon = 135834, name = "Freeze", category = 3 },
    MechanicPolymorphed = { icon = 136071, name = "Polymorph", category = 3 },
    MechanicRooted      = { icon = 135848, name = "Root", category = 3 },
    MechanicSnared      = { icon = 136102, name = "Snare", category = 3 },
    MechanicStunned     = { icon = 135860, name = "Stun", category = 3 },
    MechanicFleeing     = { icon = 132293, name = "Fear", category = 3 },
}

InfinitySpellInfo.Database = {
    ["Seat"] = {
        [122423] = { displayID = 124089, npcID = 122423, level = 91, type = "Humanoid",    spells = { 1262508, 1264286 } },
        [122403] = { displayID = 124440, npcID = 122403, level = 90, type = "Humanoid",    spells = { 1262517, 1264036 } },
        [125340] = { displayID = 78427,  npcID = 125340, level = 92, type = "Beast",       spells = { 246943, 248829, 248830, 248831 } },
        [122056] = { displayID = 78415,  npcID = 122056, level = 92, type = "Humanoid",    spells = { 244750, 246913, 1263528, 1263529, 1263532, 1263538, 1263542 } },
        [122404] = { displayID = 124412, npcID = 122404, level = 90, type = "Humanoid",    spells = { 1262526, 1262527 } },
        [122413] = { displayID = 75003,  npcID = 122413, level = 90, type = "Humanoid",    spells = { 1262519, 1277339, 1277340 } },
        [122313] = { displayID = 77871,  npcID = 122313, level = 92, type = "Humanoid",    spells = { 244579, 1263282, 1263297, 1263399, 1263440, 1263484, 1263492, 1263494, 1268916 } },
        [122421] = { displayID = 124453, npcID = 122421, level = 91, type = "Humanoid",    spells = { 1269183, 1280326 } },
        [122827] = { displayID = 77103,  npcID = 122827, level = 90, type = "Aberration",  spells = { 249082, 1268733 } },
        [124171] = { displayID = 75011,  npcID = 124171, level = 91, type = "Humanoid",    spells = { 1262506, 1262509, 1277343 } },
        [252756] = { displayID = 126552, npcID = 252756, level = 91, type = "Mechanical",  spells = { 1262335, 1262429, 1262441 } },
        [122316] = { displayID = 76771,  npcID = 122316, level = 92, type = "Humanoid",    spells = { 246943, 1263523, 1280065 } },
        [256424] = { displayID = 94382,  npcID = 256424, level = 90, type = "Aberration",  spells = { 1269081 } },
        [122571] = { displayID = 136883, npcID = 122571, level = 91, type = "Aberration",  spells = { 1264505, 1264532, 1264569, 1280330 } },
        [255320] = { displayID = 74902,  npcID = 255320, level = 90, type = "Beast",       spells = { 1264670, 1264678 } },
        [122322] = { displayID = 75479,  npcID = 122322, level = 90, type = "Humanoid",    spells = { 1269469, 1269470 } },
        [124729] = { displayID = 141808, npcID = 124729, level = 92, type = "Unspecified", spells = { 1264159, 1264196, 1265419, 1265420, 1265421, 1265426, 1265463, 1265689, 1265999, 1266001, 1266003, 1267207, 1267274, 1268598, 1268646, 1268647 } },
        [122405] = { displayID = 124411, npcID = 122405, level = 90, type = "Humanoid",    spells = { 1262510, 1262522, 1262523 } },
        [122319] = { displayID = 76602,  npcID = 122319, level = 92, type = "Beast",       spells = { 245742, 246943 } },
    },
    ["Eco"] = {
        [196044] = { displayID = 109308, npcID = 196044, level = 90, type = "Elemental",   spells = { 387523, 388392 } },
        [191736] = { displayID = 110805, npcID = 191736, level = 92, type = "Beast",       spells = { 181089, 376997, 377004, 377009, 377034, 1276752, 1285508, 1285509 } },
        [190609] = { displayID = 108925, npcID = 190609, level = 92, type = "Dragonkin",   spells = { 373326, 374343, 374352, 388822, 439488, 1279418, 1282251, 1282252 } },
        [192333] = { displayID = 101438, npcID = 192333, level = 91, type = "Beast",       spells = { 377383, 377389, 1276632 } },
        [196694] = { displayID = 62384,  npcID = 196694, level = 90, type = "Elemental",   spells = { 389054, 389055 } },
        [192680] = { displayID = 26385,  npcID = 192680, level = 91, type = "Elemental",   spells = { 377912, 377991, 378003, 378011 } },
        [196202] = { displayID = 109105, npcID = 196202, level = 90, type = "Dragonkin",   spells = { 1279627 } },
        [196671] = { displayID = 110795, npcID = 196671, level = 91, type = "Beast",       spells = { 388940, 388942, 388957, 388958, 388976, 388982, 388984 } },
        [197219] = { displayID = 104635, npcID = 197219, level = 91, type = "Elemental",   spells = { 390912, 390915, 390918, 1282244 } },
        [194181] = { displayID = 109099, npcID = 194181, level = 92, type = "Elemental",   spells = { 385958, 386173, 386181, 386201, 386202, 387691, 388537, 388546, 388651 } },
        [196577] = { displayID = 23926,  npcID = 196577, level = 90, type = "Elemental",   spells = { 387523, 388841, 1270098 } },
        [196200] = { displayID = 109104, npcID = 196200, level = 90, type = "Dragonkin",   spells = { 1270349, 1270356 } },
        [196482] = { displayID = 109194, npcID = 196482, level = 92, type = "Elemental",   spells = { 388544, 388623, 388796, 388923, 390297, 396716 } },
        [197406] = { displayID = 103762, npcID = 197406, level = 90, type = "Beast",       spells = { 390938, 390942, 390944 } },
        [196045] = { displayID = 107525, npcID = 196045, level = 90, type = "Elemental",   spells = { 387523, 388862, 388863, 388866 } },
        [192329] = { displayID = 34918,  npcID = 192329, level = 90, type = "Beast",       spells = { 377344, 377389 } },
    },
    ["Nexus"] = {
        [250299] = { displayID = 169,    npcID = 250299, level = 90, type = "Unspecified", spells = { 1251579 } },
        [254932] = { displayID = 52309,  npcID = 254932, level = 90, type = "Unspecified", spells = { 1263775, 1282944 } },
        [254926] = { displayID = 140804, npcID = 254926, level = 90, type = "Elemental",   spells = { 1263892, 1277557 } },
        [251568] = { displayID = 136110, npcID = 251568, level = 92, type = "Humanoid",    spells = { 1255310, 1257601, 1269220, 1269222, 1271956 } },
        [255179] = { displayID = 140945, npcID = 255179, level = 91, type = "Humanoid",    spells = { 1264429 } },
        [241539] = { displayID = 131510, npcID = 241539, level = 92, type = "Humanoid",    spells = { 1250553, 1251626, 1251767, 1251772, 1257509, 1257512, 1257524, 1264040, 1264042, 1264048, 1265894, 1276485, 1282915 } },
        [248706] = { displayID = 131624, npcID = 248706, level = 90, type = "Aberration",  spells = { 1252218, 1281636 } },
        [248373] = { displayID = 131484, npcID = 248373, level = 91, type = "Humanoid",    spells = { 1249801, 1249806, 1257100, 1257103, 1257105 } },
        [251853] = { displayID = 137240, npcID = 251853, level = 90, type = "Aberration",  spells = { 1252218, 1258681, 1258684, 1281634, 1281637 } },
        [251031] = { displayID = 137240, npcID = 251031, level = 91, type = "Aberration",  spells = { 1282722, 1282723 } },
        [241643] = { displayID = 131485, npcID = 241643, level = 90, type = "Humanoid",    spells = { 1249645, 1252218, 1282745 } },
        [248506] = { displayID = 131531, npcID = 248506, level = 91, type = "Aberration",  spells = { 1252218, 1252436, 1252437, 1252438, 1252621, 1252622, 1252628 } },
        [251024] = { displayID = 131531, npcID = 251024, level = 91, type = "Aberration",  spells = { 1282663, 1282664, 1282665, 1282678, 1282679 } },
        [254459] = { displayID = 169,    npcID = 254459, level = 90, type = "Unspecified", spells = { 1262088 } },
        [241660] = { displayID = 131525, npcID = 241660, level = 91, type = "Aberration",  spells = { 1252062, 1252076, 1252134, 1254096, 1259359 } },
        [241542] = { displayID = 131511, npcID = 241542, level = 92, type = "Aberration",  spells = { 1247937, 1248007, 1249014, 1249027, 1252875, 1252883, 1254096, 1259359, 1271433 } },
        [254227] = { displayID = 131511, npcID = 254227, level = 92, type = "Aberration",  spells = { 1271388 } },
        [241644] = { displayID = 131625, npcID = 241644, level = 90, type = "Humanoid",    spells = { 1249815, 1249818, 1252218, 1277451, 1278882, 1285445, 1285450 } },
        [254485] = { displayID = 169,    npcID = 254485, level = 90, type = "Unspecified", spells = { 1262088, 1262630 } },
        [241642] = { displayID = 140945, npcID = 241642, level = 91, type = "Humanoid",    spells = { 1257701, 1257736, 1257745, 1257746, 1264354, 1281657 } },
        [259569] = { displayID = 137629, npcID = 259569, level = 90, type = "Unspecified", spells = { 1257126 } },
        [241546] = { displayID = 137705, npcID = 241546, level = 92, type = "Humanoid",    spells = { 1253855, 1253950, 1255208, 1255310, 1255335, 1255503, 1257595, 1257613, 1282791 } },
        [254928] = { displayID = 138559, npcID = 254928, level = 90, type = "Beast",       spells = { 1263783, 1263785 } },
        [248708] = { displayID = 131532, npcID = 248708, level = 90, type = "Humanoid",    spells = { 1271094 } },
        [248502] = { displayID = 131526, npcID = 248502, level = 91, type = "Aberration",  spells = { 1252406, 1252414, 1252417, 1252429 } },
        [241645] = { displayID = 131528, npcID = 241645, level = 90, type = "Aberration",  spells = { 1227020, 1252204, 1252218 } },
        [241647] = { displayID = 131487, npcID = 241647, level = 90, type = "Humanoid",    spells = { 1257124, 1269283, 1282950 } },
        [248501] = { displayID = 131529, npcID = 248501, level = 90, type = "Aberration",  spells = { 1252218 } },
        [248769] = { displayID = 141002, npcID = 248769, level = 90, type = "Elemental",   spells = { 1257268 } },
    },
    ["Mold"] = {
        [252551] = { displayID = 98697,  npcID = 252551, level = 90, type = "Undead",      spells = { 1258448 } },
        [252625] = { displayID = 137500, npcID = 252625, level = 92, type = "Undead",      spells = { 1264287, 1264299, 1264336, 1264453, 1264461 } },
        [252610] = { displayID = 137498, npcID = 252610, level = 91, type = "Humanoid",    spells = { 1258439, 1258445, 1278950, 1278963, 1278967 } },
        [252564] = { displayID = 140012, npcID = 252564, level = 91, type = "Elemental",   spells = { 1259188, 1259202, 1259205, 1259226, 1278754 } },
        [257190] = { displayID = 139964, npcID = 257190, level = 91, type = "Dragonkin",   spells = { 1271009, 1278986 } },
        [252602] = { displayID = 137464, npcID = 252602, level = 90, type = "Undead",      spells = { 1258451 } },
        [254691] = { displayID = 138341, npcID = 254691, level = 90, type = "Undead",      spells = { 1262941, 1263000 } },
        [252648] = { displayID = 137505, npcID = 252648, level = 92, type = "Humanoid",    spells = { 1262582, 1262596, 1263406, 1263671, 1263756, 1263766, 1276648 } },
        [252603] = { displayID = 137490, npcID = 252603, level = 90, type = "Undead",      spells = { 1258448, 1271479 } },
        [252567] = { displayID = 137462, npcID = 252567, level = 90, type = "Undead",      spells = { 1258431 } },
        [252565] = { displayID = 137460, npcID = 252565, level = 90, type = "Undead",      spells = { 1258435 } },
        [252563] = { displayID = 137459, npcID = 252563, level = 91, type = "Undead",      spells = { 1258798, 1258802, 1258820, 1258826, 1271074 } },
        [252635] = { displayID = 137504, npcID = 252635, level = 92, type = "Undead",      spells = { 1261299, 1261315, 1261546, 1261799, 1261806, 1261808, 1261847, 1261921, 1262029, 1272433 } },
        [252621] = { displayID = 137499, npcID = 252621, level = 92, type = "Undead",      spells = { 1264027, 1264246, 1264363, 1278893, 1279667, 1279668 } },
        [255037] = { displayID = 138601, npcID = 255037, level = 90, type = "Undead",      spells = { 1264186, 1271678 } },
        [252555] = { displayID = 137508, npcID = 252555, level = 90, type = "Undead",      spells = { 1259116, 1259132 } },
        [252558] = { displayID = 75103,  npcID = 252558, level = 90, type = "Undead",      spells = { 1258459 } },
        [252559] = { displayID = 25742,  npcID = 252559, level = 90, type = "Undead",      spells = { 1258464 } },
        [252606] = { displayID = 137853, npcID = 252606, level = 90, type = "Undead",      spells = { 1258997, 1271543 } },
        [252561] = { displayID = 137458, npcID = 252561, level = 90, type = "Undead",      spells = { 1258433, 1258434 } },
        [252653] = { displayID = 31154,  npcID = 252653, level = 92, type = "Undead",      spells = { 1262739, 1262745, 1262750, 1263716, 1276948, 1276973 } },
        [252566] = { displayID = 137461, npcID = 252566, level = 90, type = "Undead",      spells = { 1258436, 1258437 } },
    },
    ["Myza"] = {
        [249030] = { displayID = 124058, npcID = 249030, level = 91, type = "Undead",      spells = { 1257895, 1257898, 1259274, 1259631 } },
        [250443] = { displayID = 140143, npcID = 250443, level = 91, type = "Undead",      spells = { 1251775 } },
        [248685] = { displayID = 131690, npcID = 248685, level = 90, type = "Humanoid",    spells = { 1256008, 1256015 } },
        [247572] = { displayID = 130705, npcID = 247572, level = 92, type = "Beast",       spells = { 1243900, 1246666, 1249478, 1249479, 1249638, 1249947, 1249948, 1256247, 1256387 } },
        [253458] = { displayID = 131679, npcID = 253458, level = 91, type = "Humanoid",    spells = { 1259882, 1259887, 1262900 } },
        [248692] = { displayID = 125076, npcID = 248692, level = 90, type = "Undead",      spells = { 1257716, 1257914, 1257920 } },
        [251639] = { displayID = 140143, npcID = 251639, level = 90, type = "Undead",      spells = { 1254175 } },
        [253647] = { displayID = 140110, npcID = 253647, level = 90, type = "Undead",      spells = { 1259731 } },
        [249020] = { displayID = 142403, npcID = 249020, level = 90, type = "Beast",       spells = { 1256586, 1257780, 1257781, 1257782 } },
        [247570] = { displayID = 130699, npcID = 247570, level = 92, type = "Humanoid",    spells = { 1243752, 1249989, 1260648, 1260709, 1260731, 1266480, 1266485, 1266488 } },
        [254740] = { displayID = 131719, npcID = 254740, level = 90, type = "Humanoid",    spells = { 1263292, 1263336, 1265832 } },
        [251674] = { displayID = 137163, npcID = 251674, level = 91, type = "Undead",      spells = { 1254010, 1254043 } },
        [248686] = { displayID = 130882, npcID = 248686, level = 91, type = "Humanoid",    spells = { 1257088, 1257155, 1257160 } },
        [248605] = { displayID = 131550, npcID = 248605, level = 92, type = "Undead",      spells = { 1248879, 1248980, 1251023, 1251024, 1252675, 1252676, 1252704, 1253765, 1253779, 1253788, 1253844, 1253909, 1266188, 1279517 } },
        [242964] = { displayID = 131701, npcID = 242964, level = 90, type = "Humanoid",    spells = { 1255964, 1255966, 1266381 } },
        [253473] = { displayID = 114972, npcID = 253473, level = 90, type = "Beast",       spells = { 1259182, 1259183 } },
        [253701] = { displayID = 169,    npcID = 253701, level = 90, type = "Unspecified", spells = { 1259794 } },
        [248595] = { displayID = 131548, npcID = 248595, level = 92, type = "Humanoid",    spells = { 1250708, 1251204, 1251554, 1251567, 1251598, 1251811, 1251813, 1251833, 1252054, 1252130, 1263735, 1264987, 1264989, 1266706, 1277556 } },
        [253683] = { displayID = 138664, npcID = 253683, level = 91, type = "Humanoid",    spells = { 1259786, 1262241 } },
        [254233] = { displayID = 138234, npcID = 254233, level = 91, type = "Humanoid",    spells = { 1259772, 1259777 } },
        [249024] = { displayID = 125074, npcID = 249024, level = 91, type = "Undead",      spells = { 1259677, 1264327, 1271623 } },
        [249002] = { displayID = 169,    npcID = 249002, level = 90, type = "Undead",      spells = { 1257328 } },
        [251047] = { displayID = 137911, npcID = 251047, level = 90, type = "Unspecified", spells = { 1252777, 1252816 } },
        [249022] = { displayID = 71577,  npcID = 249022, level = 90, type = "Beast",       spells = { 1256561 } },
        [252886] = { displayID = 138434, npcID = 252886, level = 91, type = "Humanoid",    spells = { 1257164 } },
        [249036] = { displayID = 131722, npcID = 249036, level = 90, type = "Undead",      spells = { 1259255 } },
        [249025] = { displayID = 125072, npcID = 249025, level = 91, type = "Undead",      spells = { 1257546, 1259274, 1259651, 1259664 } },
        [248684] = { displayID = 131683, npcID = 248684, level = 90, type = "Humanoid",    spells = { 1255765, 1255966 } },
        [248690] = { displayID = 125075, npcID = 248690, level = 90, type = "Undead",      spells = { 1270079, 1270085 } },
        [248678] = { displayID = 100959, npcID = 248678, level = 91, type = "Beast",       spells = { 1256047, 1256059 } },
    },
    ["Sky"] = {
        [76227]  = { displayID = 54030,  npcID = 76227,  level = 90, type = "Elemental",   spells = { 1253367, 1253368, 1253416, 1253511 } },
        [75964]  = { displayID = 56015,  npcID = 75964,  level = 92, type = "Humanoid",    spells = { 153757, 156793, 1252690, 1252691, 1252733, 1255472, 1258140, 1258152, 1258160, 1281396 } },
        [79303]  = { displayID = 57282,  npcID = 79303,  level = 91, type = "Humanoid",    spells = { 1254380, 1254460, 1254475 } },
        [78933]  = { displayID = 137750, npcID = 78933,  level = 91, type = "Elemental",   spells = { 1254355, 1258217, 1258220 } },
        [251880] = { displayID = 11686,  npcID = 251880, level = 90, type = "Unspecified", spells = { 1254329, 1254332 } },
        [78932]  = { displayID = 60335,  npcID = 78932,  level = 90, type = "Humanoid",    spells = { 1255377 } },
        [76149]  = { displayID = 54173,  npcID = 76149,  level = 91, type = "Beast",       spells = { 1254566, 1254569, 1258174 } },
        [79093]  = { displayID = 58829,  npcID = 79093,  level = 90, type = "Beast",       spells = { 1254689, 1254690 } },
        [76154]  = { displayID = 56007,  npcID = 76154,  level = 90, type = "Humanoid",    spells = { 1254686, 1254687 } },
        [79466]  = { displayID = 57094,  npcID = 79466,  level = 90, type = "Humanoid",    spells = { 1254669 } },
        [76205]  = { displayID = 59454,  npcID = 76205,  level = 90, type = "Humanoid",    spells = { 1254670 } },
        [76087]  = { displayID = 56653,  npcID = 76087,  level = 91, type = "Mechanical",  spells = { 1253446, 1253448 } },
        [250992] = { displayID = 109236, npcID = 250992, level = 90, type = "Elemental",   spells = { 1254676, 1254677, 1254678, 1254679, 1255922 } },
        [79462]  = { displayID = 60333,  npcID = 79462,  level = 90, type = "Humanoid",    spells = { 152953, 1273356 } },
        [76142]  = { displayID = 56654,  npcID = 76142,  level = 90, type = "Mechanical",  spells = { 154159, 1281874, 1287905 } },
        [76141]  = { displayID = 54006,  npcID = 76141,  level = 92, type = "Mechanical",  spells = { 154110, 154113, 154132, 154135, 154149, 1252877, 1258205, 1283770 } },
        [76132]  = { displayID = 60336,  npcID = 76132,  level = 90, type = "Humanoid",    spells = { 1254666 } },
        [76266]  = { displayID = 56016,  npcID = 76266,  level = 92, type = "Humanoid",    spells = { 153954, 154396, 1253538, 1253840 } },
        [76143]  = { displayID = 125047, npcID = 76143,  level = 92, type = "Beast",       spells = { 159381, 159382, 1253510, 1253519, 1253520 } },
        [76285]  = { displayID = 21423,  npcID = 76285,  level = 92, type = "Mechanical",  spells = { 154043, 1253543 } },
        [79467]  = { displayID = 56022,  npcID = 79467,  level = 90, type = "Humanoid",    spells = { 1254671, 1254672 } },
    },
    ["Vortex"] = {
        [238049] = { displayID = 139555, npcID = 238049, level = 90, type = "Undead",      spells = { 1219224 } },
        [231626] = { displayID = 125201, npcID = 231626, level = 92, type = "Undead",      spells = { 472724, 472736, 474105, 1219491, 1219551 } },
        [232063] = { displayID = 131955, npcID = 232063, level = 91, type = "Beast",       spells = { 1216985, 1217010, 1217021 } },
        [232146] = { displayID = 136067, npcID = 232146, level = 91, type = "Undead",      spells = { 1216459, 1216592, 1270618 } },
        [232148] = { displayID = 142686, npcID = 232148, level = 90, type = "Undead",      spells = { 468659 } },
        [232147] = { displayID = 136066, npcID = 232147, level = 90, type = "Undead",      spells = { 1216637, 1216643 } },
        [232283] = { displayID = 70180,  npcID = 232283, level = 90, type = "Beast",       spells = { 1253739 } },
        [232446] = { displayID = 141117, npcID = 232446, level = 90, type = "Humanoid",    spells = { 467815 } },
        [232113] = { displayID = 136511, npcID = 232113, level = 91, type = "Undead",      spells = { 1216250, 1216253, 1253683, 1253686 } },
        [231629] = { displayID = 124335, npcID = 231629, level = 92, type = "Undead",      spells = { 472745, 472758, 472777, 472795, 472888, 474065, 474075, 1219551, 1282272 } },
        [231631] = { displayID = 122981, npcID = 231631, level = 92, type = "Undead",      spells = { 467620, 467621, 468221, 468924, 470963, 471038, 472043, 472053, 472054, 472081, 1214874, 1250851, 1253026, 1253270, 1253272, 1271676, 1283335, 1283357 } },
        [231636] = { displayID = 125199, npcID = 231636, level = 92, type = "Aberration",  spells = { 468429, 468442, 472556, 472662, 472672, 474528, 1216042, 1253977, 1253978, 1253986, 1283371 } },
        [232067] = { displayID = 140652, npcID = 232067, level = 90, type = "Beast",       spells = { 1216822, 1216825, 1216834 } },
        [232118] = { displayID = 100728, npcID = 232118, level = 90, type = "Unspecified", spells = { 467120, 470212, 472118 } },
        [238099] = { displayID = 140667, npcID = 238099, level = 90, type = "Elemental",   spells = { 1277761 } },
        [231606] = { displayID = 123453, npcID = 231606, level = 92, type = "Beast",       spells = { 465904, 466064, 466091, 466556, 466559, 467040, 1217795, 1252548 } },
        [232173] = { displayID = 124490, npcID = 232173, level = 90, type = "Undead",      spells = { 473644, 473647, 473649 } },
        [232070] = { displayID = 136509, npcID = 232070, level = 90, type = "Undead",      spells = { 1216135, 1216298, 1253700 } },
        [232171] = { displayID = 124494, npcID = 232171, level = 90, type = "Undead",      spells = { 473794, 473795, 473864, 473868 } },
        [232232] = { displayID = 114147, npcID = 232232, level = 90, type = "Undead",      spells = { 473640 } },
        [232122] = { displayID = 140454, npcID = 232122, level = 91, type = "Undead",      spells = { 471643, 471648, 471650 } },
        [232121] = { displayID = 88968,  npcID = 232121, level = 91, type = "Undead",      spells = { 1282478 } },
        [234673] = { displayID = 140631, npcID = 234673, level = 90, type = "Beast",       spells = { 1216834 } },
        [236894] = { displayID = 112489, npcID = 236894, level = 91, type = "Elemental",   spells = { 1216819, 1216963 } },
        [232175] = { displayID = 140702, npcID = 232175, level = 91, type = "Undead",      spells = { 473657, 473663, 473668, 473672 } },
        [232176] = { displayID = 140689, npcID = 232176, level = 91, type = "Undead",      spells = { 473776, 473786, 473789, 1277799 } },
        [232119] = { displayID = 139552, npcID = 232119, level = 90, type = "Undead",      spells = { 1216419, 1216449, 1216454 } },
        [232056] = { displayID = 140630, npcID = 232056, level = 90, type = "Beast",       spells = { 1216848, 1216860, 1266745 } },
        [232116] = { displayID = 139554, npcID = 232116, level = 90, type = "Undead",      spells = { 1216462 } },
    },
    ["MGT"] = {
        [255376] = { displayID = 127714, npcID = 255376, level = 90, type = "Aberration",  spells = { 1264951 } },
        [232106] = { displayID = 16217,  npcID = 232106, level = 90, type = "Beast",       spells = { 467068, 1254595 } },
        [231864] = { displayID = 131317, npcID = 231864, level = 92, type = "Unspecified", spells = { 1223847, 1223936, 1224104, 1224299, 1224401, 1253707, 1253709, 1284954, 1284958 } },
        [239636] = { displayID = 141672, npcID = 239636, level = 92, type = "Unspecified", spells = { 1223936, 1224104, 1224299, 1253707, 1253709, 1284954, 1284958 } },
        [234066] = { displayID = 136220, npcID = 234066, level = 91, type = "Aberration",  spells = { 1248138, 1248219, 1248229, 1264687 } },
        [241397] = { displayID = 98834,  npcID = 241397, level = 92, type = "Unspecified", spells = { 1248015 } },
        [234062] = { displayID = 137562, npcID = 234062, level = 91, type = "Mechanical",  spells = { 473258, 1282050, 1282051, 1282053, 1282055 } },
        [232369] = { displayID = 138454, npcID = 232369, level = 90, type = "Humanoid",    spells = { 468962, 468966, 1245046 } },
        [231861] = { displayID = 131334, npcID = 231861, level = 92, type = "Mechanical",  spells = { 474345, 474496, 1214038, 1214081, 1243905 } },
        [234068] = { displayID = 138102, npcID = 234068, level = 91, type = "Aberration",  spells = { 1217087, 1255462, 1265977 } },
        [234064] = { displayID = 93869,  npcID = 234064, level = 90, type = "Aberration",  spells = { 1248229, 1248327 } },
        [234486] = { displayID = 138455, npcID = 234486, level = 90, type = "Humanoid",    spells = { 1254306, 1255187 } },
        [234124] = { displayID = 138453, npcID = 234124, level = 90, type = "Humanoid",    spells = { 1252910, 1253224, 1265561 } },
        [251861] = { displayID = 138460, npcID = 251861, level = 91, type = "Humanoid",    spells = { 1254294, 1254301, 1254336, 1254338 } },
        [231863] = { displayID = 127739, npcID = 231863, level = 92, type = "Unspecified", spells = { 1224903, 1225015, 1225135, 1225193, 1225201, 1225205, 1225792, 1225796, 1246446, 1248689, 1271317 } },
        [240973] = { displayID = 127769, npcID = 240973, level = 91, type = "Humanoid",    spells = { 1244907, 1283901 } },
        [234069] = { displayID = 127714, npcID = 234069, level = 90, type = "Aberration",  spells = { 1255434 } },
        [249086] = { displayID = 92689,  npcID = 249086, level = 90, type = "Aberration",  spells = { 1245068, 1248229, 1264693 } },
        [234065] = { displayID = 60660,  npcID = 234065, level = 90, type = "Aberration",  spells = { 1227020 } },
        [257447] = { displayID = 60660,  npcID = 257447, level = 90, type = "Aberration",  spells = { 1227020 } },
        [231865] = { displayID = 132031, npcID = 231865, level = 92, type = "Aberration",  spells = { 1215087, 1215897, 1269631, 1271066, 1280113, 1280119, 1284627, 1284633 } },
        [259387] = { displayID = 141476, npcID = 259387, level = 90, type = "Elemental",   spells = { 1279994, 1279995 } },
    },
}



InfinitySpellInfo.DungeonList = { "Seat", "Eco", "Nexus", "Mold", "Myza", "Sky", "Vortex", "MGT" }

InfinityTools:ReportReady(INFINITY_MODULE_KEY)

