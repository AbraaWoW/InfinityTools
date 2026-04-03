---@diagnostic disable: undefined-global, undefined-field

local MDTMod = InfinityBoss.MDT
MDTMod.Provider = MDTMod.Provider or {}

local Provider = MDTMod.Provider
local L = InfinityBoss.L or setmetatable({}, { __index = function(_, key) return key end })

local function IsUsablePreset(preset)
    return type(preset) == "table"
        and type(preset.value) == "table"
        and type(preset.value.pulls) == "table"
end

function Provider.GetMDT()
    local mdt = rawget(_G, "MDT")
    return type(mdt) == "table" and mdt or nil
end

function Provider.GetDB(mdt)
    if type(mdt) ~= "table" or type(mdt.GetDB) ~= "function" then
        return nil
    end
    local ok, db = pcall(function()
        return mdt:GetDB()
    end)
    if ok and type(db) == "table" then
        return db
    end
    return nil
end

function Provider.LocalizeText(mdt, text)
    text = tostring(text or "")
    if text == "" then
        return text
    end
    local localeTable = type(mdt) == "table" and type(mdt.L) == "table" and mdt.L or nil
    local localized = localeTable and localeTable[text] or nil
    if type(localized) == "string" and localized ~= "" then
        return localized
    end
    return text
end

function Provider.GetDungeonName(mdt, dungeonIdx)
    local name
    local englishName

    if type(mdt) == "table" and type(mdt.GetDungeonName) == "function" then
        local ok, result = pcall(function()
            return mdt:GetDungeonName(dungeonIdx)
        end)
        if ok and type(result) == "string" and result ~= "" then
            name = result
        end

        ok, result = pcall(function()
            return mdt:GetDungeonName(dungeonIdx, true)
        end)
        if ok and type(result) == "string" and result ~= "" then
            englishName = result
        end
    end

    if not name and type(mdt) == "table" and type(mdt.dungeonList) == "table" then
        name = mdt.dungeonList[dungeonIdx]
    end

    if not englishName and type(mdt) == "table" and type(mdt.mapInfo) == "table"
        and type(mdt.mapInfo[dungeonIdx]) == "table" then
        englishName = tostring(mdt.mapInfo[dungeonIdx].englishName or "")
        if englishName == "" then
            englishName = nil
        end
    end

    if type(name) == "string" and name ~= "" then
        return Provider.LocalizeText(mdt, name)
    end
    if type(englishName) == "string" and englishName ~= "" then
        return Provider.LocalizeText(mdt, englishName)
    end
    return string.format("MDT Dungeon #%s", tostring(dungeonIdx or "?"))
end

local function GetBestPresetForDungeon(db, dungeonIdx)
    local presets = type(db) == "table" and type(db.presets) == "table" and db.presets[dungeonIdx] or nil
    if type(presets) ~= "table" then
        return nil, nil, nil
    end

    local cur = tonumber(type(db.currentPreset) == "table" and db.currentPreset[dungeonIdx]) or 1
    if IsUsablePreset(presets[cur]) then
        return presets[cur], cur, presets
    end

    for idx, preset in ipairs(presets) do
        if IsUsablePreset(preset) then
            return preset, idx, presets
        end
    end
    return nil, nil, presets
end

local function CollectPreferredDungeonIndices(mdt, db)
    local out = {}
    local seen = {}
    local selectedListIndex = tonumber(type(db) == "table" and db.selectedDungeonList) or nil
    local selectedList = type(mdt) == "table"
        and type(mdt.dungeonSelectionToIndex) == "table"
        and selectedListIndex
        and mdt.dungeonSelectionToIndex[selectedListIndex]
        or nil

    if type(selectedList) == "table" and #selectedList > 0 then
        for _, dungeonIdx in ipairs(selectedList) do
            local idx = tonumber(dungeonIdx)
            if idx and not seen[idx] then
                out[#out + 1] = idx
                seen[idx] = true
            end
        end
        return out, true
    end

    if type(mdt) == "table" and type(mdt.dungeonList) == "table" then
        for dungeonIdx in pairs(mdt.dungeonList) do
            local idx = tonumber(dungeonIdx)
            if idx and not seen[idx] then
                out[#out + 1] = idx
                seen[idx] = true
            end
        end
        table.sort(out)
    end
    return out, false
end

local function BuildRouteRef(mdt, db, dungeonIdx, preset, presetIndex, presetCount)
    local pulls = (preset and preset.value and preset.value.pulls) or {}
    local currentPull = nil
    if type(mdt.GetCurrentPull) == "function" and preset == mdt:GetCurrentPreset() then
        local ok, value = pcall(function()
            return mdt:GetCurrentPull()
        end)
        if ok then
            currentPull = tonumber(value)
        end
    end
    if not currentPull then
        currentPull = tonumber(preset and preset.value and preset.value.currentPull)
    end

    local routeUID = tostring((preset and preset.uid) or "")
    local routeName = tostring((preset and preset.text) or string.format("Route %s", tostring(presetIndex or 1)))
    local totalForces = tonumber(type(mdt.dungeonTotalCount) == "table"
        and type(mdt.dungeonTotalCount[dungeonIdx]) == "table"
        and mdt.dungeonTotalCount[dungeonIdx].normal) or nil
    local mapID = tonumber(type(mdt.mapInfo) == "table"
        and type(mdt.mapInfo[dungeonIdx]) == "table"
        and mdt.mapInfo[dungeonIdx].mapID) or nil

    return {
        ok = true,
        mdt = mdt,
        db = db,
        preset = preset,
        presetIndex = tonumber(presetIndex) or 1,
        presetCount = tonumber(presetCount) or 1,
        routeUID = routeUID,
        routeName = routeName,
        dungeonIdx = tonumber(dungeonIdx),
        mapID = mapID,
        dungeonName = Provider.GetDungeonName(mdt, dungeonIdx),
        currentPull = currentPull,
        pulls = type(pulls) == "table" and pulls or {},
        enemyDB = type(mdt.dungeonEnemies) == "table" and mdt.dungeonEnemies[dungeonIdx] or nil,
        totalForces = totalForces,
    }
end

function Provider.GetPullImagePath(mapID, pullIndex, collectionKey)
    local folder = tonumber(mapID)
    local idx = tonumber(pullIndex)
    if not (folder and folder > 0 and idx and idx > 0) then
        return nil
    end
    local key = type(collectionKey) == "string" and collectionKey ~= "" and collectionKey or nil
    if key then
        return string.format("Interface\\AddOns\\InfinityBoss\\RouteCollections\\%s\\Images\\%d\\%d.jpg", key, folder, idx)
    end
    return string.format("Interface\\AddOns\\InfinityBoss\\Media\\MDTPulls\\%d\\%d.jpg", folder, idx)
end

function Provider.GetCurrentRouteRef()
    local mdt = Provider.GetMDT()
    if not mdt then
        return { ok = false, reason = "MythicDungeonTools (MDT) not detected." }
    end

    local preset
    if type(mdt.GetCurrentPreset) == "function" then
        local ok, value = pcall(function()
            return mdt:GetCurrentPreset()
        end)
        if ok and type(value) == "table" then
            preset = value
        end
    end
    if type(preset) ~= "table" then
        return { ok = false, reason = "Current MDT route is unavailable (no route selected)." }
    end

    local db = Provider.GetDB(mdt)
    if type(db) ~= "table" then
        return { ok = false, reason = "MDT database is unavailable." }
    end

    local dungeonIdx = tonumber((db and db.currentDungeonIdx) or (preset.value and preset.value.currentDungeonIdx))
    if not dungeonIdx then
        return { ok = false, reason = "No MDT dungeon selected." }
    end

    local presetIndex = tonumber(type(db.currentPreset) == "table" and db.currentPreset[dungeonIdx]) or 1
    local presetCount = type(db.presets) == "table" and type(db.presets[dungeonIdx]) == "table" and #db.presets[dungeonIdx] or 1
    return BuildRouteRef(mdt, db, dungeonIdx, preset, presetIndex, presetCount)
end

function Provider.GetRouteRefByDungeonIdx(dungeonIdx)
    local idx = tonumber(dungeonIdx)
    if not idx then
        return { ok = false, reason = "No MDT dungeon selected." }
    end

    local mdt = Provider.GetMDT()
    if not mdt then
        return { ok = false, reason = "MythicDungeonTools (MDT) not detected." }
    end

    local db = Provider.GetDB(mdt)
    if type(db) ~= "table" then
        return { ok = false, reason = "MDT database is unavailable." }
    end

    local preset, presetIndex, presets = GetBestPresetForDungeon(db, idx)
    if not preset then
        return { ok = false, reason = "This dungeon has no usable route.", dungeonIdx = idx }
    end

    return BuildRouteRef(mdt, db, idx, preset, presetIndex, type(presets) == "table" and #presets or 1)
end

function Provider.CollectDungeonRows()
    local out = {}
    local mdt = Provider.GetMDT()
    local db = Provider.GetDB(mdt)
    if type(mdt) ~= "table" or type(mdt.dungeonList) ~= "table" then
        return out
    end

    local indices, usedSelectedList = CollectPreferredDungeonIndices(mdt, db)
    for _, idx in ipairs(indices) do
        local hasRoute = false
        local presets = type(db) == "table" and type(db.presets) == "table" and db.presets[idx] or nil
        if type(presets) == "table" then
            for _, preset in ipairs(presets) do
                if IsUsablePreset(preset) then
                    hasRoute = true
                    break
                end
            end
        end

        out[#out + 1] = {
            mdtDungeonIdx = idx,
            name = Provider.GetDungeonName(mdt, idx),
            shortName = Provider.LocalizeText(mdt, type(mdt.mapInfo) == "table"
                and type(mdt.mapInfo[idx]) == "table"
                and mdt.mapInfo[idx].shortName or ""),
            mapID = tonumber(type(mdt.mapInfo) == "table"
                and type(mdt.mapInfo[idx]) == "table"
                and mdt.mapInfo[idx].mapID),
            hasRoute = hasRoute,
        }
    end

    if not usedSelectedList then
        table.sort(out, function(a, b)
            if (a.hasRoute == true) ~= (b.hasRoute == true) then
                return a.hasRoute == true
            end
            return tostring(a.name) < tostring(b.name)
        end)
    end
    return out
end

function Provider.GetSpellName(spellID)
    local sid = tonumber(spellID)
    if not sid then
        return nil
    end

    if C_Spell and type(C_Spell.GetSpellName) == "function" then
        local ok, name = pcall(C_Spell.GetSpellName, sid)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end

    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, sid)
        if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            return info.name
        end
    end

    if type(GetSpellInfo) == "function" then
        local ok, name = pcall(GetSpellInfo, sid)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
end

function Provider.GetSpellTexture(spellID)
    local sid = tonumber(spellID)
    if not sid then
        return nil
    end
    if C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        local ok, icon = pcall(C_Spell.GetSpellTexture, sid)
        if ok and tonumber(icon) then
            return tonumber(icon)
        end
    end
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, sid)
        if ok and type(info) == "table" and tonumber(info.iconID) then
            return tonumber(info.iconID)
        end
    end
    return nil
end

function Provider.GetCreatureDisplayID(enemyData)
    if type(enemyData) ~= "table" then
        return nil
    end
    local displayID = tonumber(enemyData.displayId)
        or tonumber(enemyData.displayID)
        or tonumber(enemyData.DISPLAYID)
    if displayID and displayID > 0 then
        return displayID
    end
    return nil
end

function Provider.SetCreaturePortrait(texture, displayID, fallbackTexture)
    if not texture then
        return false
    end

    local did = tonumber(displayID)
    if did and did > 0 and type(SetPortraitTextureFromCreatureDisplayID) == "function" then
        local ok = pcall(SetPortraitTextureFromCreatureDisplayID, texture, did)
        if ok then
            texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
            return true
        end
    end

    texture:SetTexture(fallbackTexture or 134400)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return false
end
