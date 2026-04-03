---@diagnostic disable: undefined-global

local MDTMod = InfinityBoss.MDT
MDTMod.ImportPreset = MDTMod.ImportPreset or {}

local ImportPreset = MDTMod.ImportPreset
local Presets      = MDTMod.Presets
local Provider     = MDTMod.Provider
local Runtime      = MDTMod.Runtime
local L = InfinityBoss.L or setmetatable({}, { __index = function(_, k) return k end })


local function GetMDTDB()
    local mdt = Provider.GetMDT()
    return Provider.GetDB(mdt)
end

local function FindByUID(mdtDB, uid)
    if not (uid and uid ~= "" and type(mdtDB.presets) == "table") then return nil end
    for dungeonIdx, presets in pairs(mdtDB.presets) do
        if type(presets) == "table" then
            for presetIndex, preset in pairs(presets) do
                if type(preset) == "table" and preset.uid == uid then
                    return tonumber(dungeonIdx), tonumber(presetIndex)
                end
            end
        end
    end
end

-- ── InfinityBoss import db ──────────────────────────────────────────────────────────

local function GetImportDB()
    local db = MDTMod.EnsureDB()
    db.import = type(db.import) == "table" and db.import or {}
    db.import.importedUIDs     = type(db.import.importedUIDs) == "table" and db.import.importedUIDs or {}
    db.import.selectedCollectionKey = db.import.selectedCollectionKey or ""
    return db.import
end

local function FindCollection(collectionKey)
    local cols = Presets.GetAllCollections and Presets.GetAllCollections() or {}
    for _, c in ipairs(cols) do
        if c.key == collectionKey then
            return c
        end
    end
end

local function FindImportedRouteForCollection(mdtDB, impDB, col, preferredDungeonIdx)
    local fallbackDungeonIdx, fallbackPresetIndex, fallbackRouteKey
    local wantedDungeonIdx = tonumber(preferredDungeonIdx)

    for _, route in ipairs(col.routes or {}) do
        local routeKey = tostring(route.key or "")
        local uid = impDB.importedUIDs[routeKey]
        local dungeonIdx, presetIndex = FindByUID(mdtDB, uid)
        if dungeonIdx and presetIndex then
            if wantedDungeonIdx and tonumber(dungeonIdx) == wantedDungeonIdx then
                return dungeonIdx, presetIndex, routeKey
            end
            if not fallbackDungeonIdx then
                fallbackDungeonIdx, fallbackPresetIndex, fallbackRouteKey = dungeonIdx, presetIndex, routeKey
            end
        end
    end

    return fallbackDungeonIdx, fallbackPresetIndex, fallbackRouteKey
end


local function WritePresetToDB(mdtDB, preset)
    local mdt    = Provider.GetMDT()
    local dungeonIdx = tonumber(preset.value and preset.value.currentDungeonIdx)
    if not dungeonIdx then return nil end

    mdtDB.presets[dungeonIdx] = mdtDB.presets[dungeonIdx] or {}

    if preset.uid and preset.uid ~= "" then
        for idx, existing in pairs(mdtDB.presets[dungeonIdx]) do
            if type(existing) == "table" and existing.uid == preset.uid then
                return existing.uid, tonumber(idx)
            end
        end
    end

    local count = 0
    for _ in pairs(mdtDB.presets[dungeonIdx]) do count = count + 1 end
    local lastSlot = mdtDB.presets[dungeonIdx][count]
    if lastSlot and type(lastSlot) == "table" then
        mdtDB.presets[dungeonIdx][count + 1] = lastSlot
    end

    preset.uid = nil
    if type(mdt.SetUniqueID) == "function" then
        pcall(function() mdt:SetUniqueID(preset) end)
    end
    mdtDB.presets[dungeonIdx][count] = preset
    return preset.uid, count
end

local function FindByText(mdtDB, text)
    local wanted = tostring(text or "")
    if wanted == "" or type(mdtDB.presets) ~= "table" then
        return nil
    end
    for dungeonIdx, presets in pairs(mdtDB.presets) do
        if type(presets) == "table" then
            for presetIndex, preset in pairs(presets) do
                if type(preset) == "table" and tostring(preset.text or "") == wanted then
                    return tonumber(dungeonIdx), tonumber(presetIndex)
                end
            end
        end
    end
end

local function ReplacePresetAt(mdtDB, dungeonIdx, presetIndex, preset)
    dungeonIdx = tonumber(dungeonIdx)
    presetIndex = tonumber(presetIndex)
    if not (dungeonIdx and presetIndex and type(mdtDB.presets) == "table" and type(mdtDB.presets[dungeonIdx]) == "table") then
        return WritePresetToDB(mdtDB, preset)
    end

    local mdt = Provider.GetMDT()
    local existing = mdtDB.presets[dungeonIdx][presetIndex]
    if type(existing) ~= "table" then
        return WritePresetToDB(mdtDB, preset)
    end

    if type(mdt.DeepCopy) == "function" then
        preset = mdt:DeepCopy(preset)
    end
    if existing.uid and existing.uid ~= "" then
        preset.uid = existing.uid
    else
        preset.uid = nil
        if type(mdt.SetUniqueID) == "function" then
            pcall(function() mdt:SetUniqueID(preset) end)
        end
    end

    mdtDB.presets[dungeonIdx][presetIndex] = preset
    return preset.uid, presetIndex
end

local function SwitchMDTDB(mdtDB, dungeonIdx, presetIndex)
    local mdt = Provider.GetMDT()
    mdtDB.currentDungeonIdx = dungeonIdx
    mdtDB.currentPreset = type(mdtDB.currentPreset) == "table" and mdtDB.currentPreset or {}

    if mdt then
        pcall(function()
            if type(mdt.SetDungeonList) == "function" then
                mdt:SetDungeonList(nil, dungeonIdx)
            end
            if type(mdt.UpdateDungeonDropDown) == "function" then
                mdt:UpdateDungeonDropDown()
            end
            if type(mdt.UpdateToDungeon) == "function" then
                mdt:UpdateToDungeon(dungeonIdx, true)
            end
        end)
    end

    mdtDB.currentDungeonIdx = dungeonIdx
    mdtDB.currentPreset[dungeonIdx] = presetIndex

    if mdt then
        pcall(function()
            if type(mdt.UpdatePresetDropDown) == "function" then
                mdt:UpdatePresetDropDown()
            end
            if type(mdt.UpdateMap) == "function" then
                mdt:UpdateMap()
            end
        end)
    end
end


function ImportPreset.SelectCollection(collectionKey)
    local impDB = GetImportDB()
    local col = FindCollection(collectionKey)
    if not (col and type(col.routes) == "table" and col.routes[1]) then
        return false, "No importable MDT preset was found."
    end

    impDB.selectedCollectionKey = collectionKey
    impDB.collectionKey = collectionKey
    local db = MDTMod.EnsureDB()
    local mdtDB = GetMDTDB()
    local preferredDungeonIdx = tonumber(db.selectedDungeonIdx)
    if not preferredDungeonIdx and mdtDB then
        preferredDungeonIdx = tonumber(mdtDB.currentDungeonIdx)
    end

    if mdtDB then
        local dungeonIdx, presetIndex, routeKey = FindImportedRouteForCollection(mdtDB, impDB, col, preferredDungeonIdx)
        if dungeonIdx and presetIndex then
            SwitchMDTDB(mdtDB, dungeonIdx, presetIndex)
            db.selectedDungeonIdx = tonumber(dungeonIdx)
            db.import = impDB
            db.import.collectionKey = collectionKey
            impDB.selectedBuiltinKey = tostring(routeKey or col.routes[1].key or "")
            Runtime.Refresh(true)
            return true, string.format("Switched route collection: %s", tostring(col.label or collectionKey))
        end
    end

    if col.routes[1] then
        impDB.selectedBuiltinKey = col.routes[1].key
    end
    db.import = impDB
    Runtime.Refresh(true)
    return true, string.format("Selected route collection: %s (not yet imported)", tostring(col.label or collectionKey))
end

function ImportPreset.GetSelectedCollectionKey()
    local impDB = GetImportDB()
    if impDB.selectedCollectionKey and impDB.selectedCollectionKey ~= "" then
        return impDB.selectedCollectionKey
    end
    local cols = Presets.GetAllCollections and Presets.GetAllCollections() or {}
    return cols[1] and cols[1].key or ""
end

function ImportPreset.SwitchCollection(collectionKey)
    if InCombatLockdown and InCombatLockdown() then
        return false, "Cannot import MDT route during combat."
    end

    local mdt = Provider.GetMDT()
    if not mdt then
        return false, "MythicDungeonTools (MDT) not detected."
    end
    if type(mdt.StringToTable) ~= "function" or type(mdt.ValidateImportPreset) ~= "function" then
        return false, "MDT import API is unavailable."
    end

    local col = FindCollection(collectionKey)
    if not (col and type(col.routes) == "table" and #col.routes > 0) then
        return false, "No importable MDT preset was found."
    end

    local mdtDB = GetMDTDB()
    if not mdtDB then return false, "MDT import API is unavailable." end

    local impDB = GetImportDB()

    local firstDungeonIdx, firstPresetIndex
    for i, route in ipairs(col.routes) do
        local def = Presets.GetByKey(route.key)
        if def then
            local okDecode, preset = pcall(function()
                return mdt:StringToTable(def.importString, true)
            end)
            if okDecode and type(preset) == "table" then
                local okValidate, valid = pcall(function()
                    return mdt:ValidateImportPreset(preset)
                end)
                if okValidate and valid == true then
                    preset.text = tostring(route.label or def.label or preset.text or def.key)

                    local oldUID = impDB.importedUIDs[def.key]
                    local existDungeonIdx, existIndex = FindByUID(mdtDB, oldUID)
                    if not (existDungeonIdx and existIndex) then
                        existDungeonIdx, existIndex = FindByText(mdtDB, preset.text)
                    end

                    local finalUID, finalIndex
                    if existDungeonIdx and existIndex then
                        finalUID, finalIndex = ReplacePresetAt(mdtDB, existDungeonIdx, existIndex, preset)
                    else
                        preset.uid = nil
                        finalUID, finalIndex = WritePresetToDB(mdtDB, preset)
                    end

                    if finalUID then
                        impDB.importedUIDs[def.key] = finalUID
                    end
                    local finalDungeonIdx = tonumber(preset.value and preset.value.currentDungeonIdx) or existDungeonIdx
                    if finalDungeonIdx and finalIndex then
                        mdtDB.currentPreset = type(mdtDB.currentPreset) == "table" and mdtDB.currentPreset or {}
                        mdtDB.currentPreset[finalDungeonIdx] = tonumber(finalIndex)
                    end
                    if i == 1 then
                        firstDungeonIdx = finalDungeonIdx
                        firstPresetIndex = finalIndex or existIndex
                    end
                end
            end
        end
    end

    local db = MDTMod.EnsureDB()
    if firstDungeonIdx and firstPresetIndex then
        SwitchMDTDB(mdtDB, firstDungeonIdx, firstPresetIndex)
        db.selectedDungeonIdx = tonumber(firstDungeonIdx)
    end

    impDB.selectedCollectionKey = collectionKey
    db.import = impDB
    db.import.collectionKey = collectionKey
    if col.routes[1] then
        impDB.selectedBuiltinKey = col.routes[1].key
    end

    Runtime.Refresh(true)
    return true, string.format("Imported MDT route: %s", tostring(col.label or collectionKey))
end

function ImportPreset.GetSelectedBuiltinKey()
    return GetImportDB().selectedBuiltinKey or ""
end

function ImportPreset.SetSelectedBuiltinKey(key)
    GetImportDB().selectedBuiltinKey = key or ""
end

function ImportPreset.GetBuiltinItems()
    local items = {}
    for _, def in ipairs(Presets.GetAll() or {}) do
        items[#items + 1] = { tostring(def.label or def.key), def.key }
    end
    return items
end


local autoImportFrame = CreateFrame("Frame")
autoImportFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
autoImportFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    local impDB = GetImportDB()
    if not impDB.selectedCollectionKey or impDB.selectedCollectionKey == "" then
        local cols = Presets.GetAllCollections and Presets.GetAllCollections() or {}
        if cols[1] then
            ImportPreset.SelectCollection(cols[1].key)
        end
    end
end)
