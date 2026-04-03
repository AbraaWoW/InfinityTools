---@diagnostic disable: undefined-global, undefined-field

local MDTMod = InfinityBoss.MDT
MDTMod.Snapshot = MDTMod.Snapshot or {}

local Snapshot = MDTMod.Snapshot
local Provider = MDTMod.Provider

local function CountClones(clones)
    local count = 0
    if type(clones) == "table" then
        for _ in pairs(clones) do
            count = count + 1
        end
    end
    return count > 0 and count or 1
end

local function SortEnemyKeys(pull)
    local out = {}
    for enemyIdx in pairs(pull or {}) do
        local idx = tonumber(enemyIdx)
        if idx then
            out[#out + 1] = idx
        end
    end
    table.sort(out)
    return out
end

local function CollectInterruptibleSpells(enemyData)
    local out = {}
    if type(enemyData) ~= "table" or type(enemyData.spells) ~= "table" then
        return out
    end
    for spellID, spellData in pairs(enemyData.spells) do
        if type(spellData) == "table" and spellData.interruptible then
            local sid = tonumber(spellID)
            if sid and sid > 0 then
                out[#out + 1] = sid
            end
        end
    end
    table.sort(out)
    return out
end

local function ResolveEnemyIcon(enemyData, interruptibleSpells)
    if type(interruptibleSpells) == "table" and interruptibleSpells[1] then
        local icon = Provider.GetSpellTexture(interruptibleSpells[1])
        if icon then
            return icon
        end
    end

    local spellIcon = tonumber(type(enemyData) == "table" and enemyData.SPELLICON)
    if spellIcon then
        local icon = Provider.GetSpellTexture(spellIcon)
        if icon then
            return icon
        end
    end

    if type(enemyData) == "table" and type(enemyData.spells) == "table" then
        for spellID in pairs(enemyData.spells) do
            local icon = Provider.GetSpellTexture(spellID)
            if icon then
                return icon
            end
        end
    end

    return 134400
end

local function BuildEnemyEntry(enemyIdx, clones, enemyData, mdt)
    local cloneCount = CountClones(clones)
    local interruptibleSpells = CollectInterruptibleSpells(enemyData)
    local rawName = type(enemyData) == "table" and tostring(enemyData.name or ("enemyIdx " .. tostring(enemyIdx))) or ("enemyIdx " .. tostring(enemyIdx))
    local name = Provider.LocalizeText(mdt, rawName)

    return {
        enemyIdx = enemyIdx,
        npcID = type(enemyData) == "table" and tonumber(enemyData.id) or nil,
        displayID = Provider.GetCreatureDisplayID(enemyData),
        name = name,
        count = cloneCount,
        forces = (type(enemyData) == "table" and tonumber(enemyData.count) or 0) * cloneCount,
        unitForces = type(enemyData) == "table" and tonumber(enemyData.count) or 0,
        level = type(enemyData) == "table" and tonumber(enemyData.level) or nil,
        isElite91 = (type(enemyData) == "table" and tonumber(enemyData.level) or 0) == 91,
        hasInterruptible = #interruptibleSpells > 0,
        interruptibleSpells = interruptibleSpells,
        icon = ResolveEnemyIcon(enemyData, interruptibleSpells),
    }
end

function Snapshot.FormatCasterSummaryLines(pull)
    local out = {}
    if type(pull) ~= "table" or type(pull.casterGroups) ~= "table" then
        return out
    end

    local keys = {}
    for name in pairs(pull.casterGroups) do
        keys[#keys + 1] = name
    end
    table.sort(keys)

    for _, name in ipairs(keys) do
        out[#out + 1] = string.format("%s x%d", tostring(name), tonumber(pull.casterGroups[name]) or 0)
    end
    return out
end

function Snapshot.Build(routeRef)
    if type(routeRef) ~= "table" or routeRef.ok ~= true then
        return nil
    end

    local routeUID = tostring(routeRef.routeUID or "")
    local routeKey = table.concat({
        tostring(routeRef.dungeonIdx or 0),
        tostring(routeRef.presetIndex or 0),
        routeUID ~= "" and routeUID or tostring(routeRef.routeName or ""),
    }, ":")

    local snapshot = {
        routeKey = routeKey,
        routeUID = routeUID,
        dungeonIdx = tonumber(routeRef.dungeonIdx),
        mapID = tonumber(routeRef.mapID),
        dungeonName = tostring(routeRef.dungeonName or ""),
        routeName = tostring(routeRef.routeName or ""),
        presetIndex = tonumber(routeRef.presetIndex) or 1,
        presetCount = tonumber(routeRef.presetCount) or 1,
        currentPullFromMDT = tonumber(routeRef.currentPull),
        totalForces = tonumber(routeRef.totalForces) or 0,
        pulls = {},
    }

    local cumulative = 0
    local enemyDB = type(routeRef.enemyDB) == "table" and routeRef.enemyDB or {}
    local mdt = routeRef.mdt

    for pullIndex, pull in ipairs(routeRef.pulls or {}) do
        local entry = {
            index = pullIndex,
            enemies = {},
            enemyKinds = 0,
            unitCount = 0,
            totalForces = 0,
            cumulativeFrom = cumulative,
            cumulativeTo = cumulative,
            casterGroups = {},
        }

        local enemyKeys = SortEnemyKeys(pull)
        for _, enemyIdx in ipairs(enemyKeys) do
            local enemyEntry = BuildEnemyEntry(enemyIdx, pull[enemyIdx] or pull[tostring(enemyIdx)], enemyDB[enemyIdx], mdt)
            entry.enemies[#entry.enemies + 1] = enemyEntry
            entry.enemyKinds = entry.enemyKinds + 1
            entry.unitCount = entry.unitCount + (enemyEntry.count or 0)
            entry.totalForces = entry.totalForces + (enemyEntry.forces or 0)
            if enemyEntry.hasInterruptible then
                entry.casterGroups[enemyEntry.name] = (entry.casterGroups[enemyEntry.name] or 0) + enemyEntry.count
            end
        end

        table.sort(entry.enemies, function(a, b)
            if (a.isElite91 == true) ~= (b.isElite91 == true) then
                return a.isElite91 == true
            end
            if (a.hasInterruptible == true) ~= (b.hasInterruptible == true) then
                return a.hasInterruptible == true
            end
            return tostring(a.name) < tostring(b.name)
        end)

        cumulative = cumulative + entry.totalForces
        entry.cumulativeTo = cumulative
        entry.casterSummaryLines = Snapshot.FormatCasterSummaryLines(entry)
        snapshot.pulls[pullIndex] = entry
    end

    if snapshot.totalForces <= 0 and cumulative > 0 then
        snapshot.totalForces = cumulative
    end

    return snapshot
end
