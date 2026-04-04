---@diagnostic disable: undefined-global

local MDTMod = InfinityBoss.MDT
MDTMod.Runtime = MDTMod.Runtime or {}

local Runtime = MDTMod.Runtime
local Provider = MDTMod.Provider
local Snapshot = MDTMod.Snapshot
local Progress = MDTMod.Progress
local Notes   = MDTMod.Notes
local Presets = MDTMod.Presets

local listeners = {}
local eventFrame = nil
local currentState = nil
local INSTANCE_ID_TO_CHALLENGE_MAP = {
    [1753] = 239,
    [658]  = 556,
    [1209] = 161,
    [2526] = 402,
    [2805] = 557,
    [2811] = 558,
    [2874] = 560,
    [2915] = 559,
}

local function NotifyListeners()
    for key, callback in pairs(listeners) do
        pcall(callback, currentState)
    end
end

local function GetDB()
    return MDTMod.EnsureDB()
end

local function GetPlayerInstanceID()
    local exwind = rawget(_G, "InfinityTools")
    local state = exwind and exwind.State
    local instanceID = tonumber(state and state.InstanceID) or 0
    if instanceID > 0 then
        return instanceID
    end
    return nil
end

local function ResolveDungeonIdxByInstanceID(instanceID)
    local playerInstanceID = tonumber(instanceID)
    if not playerInstanceID or playerInstanceID <= 0 then
        return nil
    end

    local targetMapID = INSTANCE_ID_TO_CHALLENGE_MAP[playerInstanceID]
    if not targetMapID or targetMapID <= 0 then
        return nil
    end

    local mdt = Provider.GetMDT()
    if type(mdt) ~= "table" or type(mdt.mapInfo) ~= "table" then
        return nil
    end

    for dungeonIdx, info in pairs(mdt.mapInfo) do
        if tonumber(type(info) == "table" and info.mapID) == targetMapID then
            return tonumber(dungeonIdx)
        end
    end
    return nil
end

local function SyncSelectedDungeonIdxToPlayerMap()
    local db = GetDB()
    local playerInstanceID = GetPlayerInstanceID()
    local dungeonIdx = ResolveDungeonIdxByInstanceID(playerInstanceID)
    if dungeonIdx and tonumber(db.selectedDungeonIdx) ~= dungeonIdx then
        db.selectedDungeonIdx = dungeonIdx
    end
end

local function SelectRouteRef()
    local db = GetDB()
    SyncSelectedDungeonIdxToPlayerMap()
    if tonumber(db.selectedDungeonIdx) then
        local byDungeon = Provider.GetRouteRefByDungeonIdx(db.selectedDungeonIdx)
        if byDungeon and byDungeon.ok then
            return byDungeon
        end
    end

    local current = Provider.GetCurrentRouteRef()
    if current and current.ok and tonumber(current.dungeonIdx) then
        db.selectedDungeonIdx = tonumber(current.dungeonIdx)
    end
    return current
end

local function GetBuiltinRouteKey(routeRef, snapshot)
    local db = GetDB()
    local imp = type(db.import) == "table" and db.import or {}
    local collectionKey = type(imp.selectedCollectionKey) == "string" and imp.selectedCollectionKey or ""
    if collectionKey == "" then
        collectionKey = type(imp.collectionKey) == "string" and imp.collectionKey or ""
    end
    if collectionKey ~= "" and type(snapshot) == "table" and tonumber(snapshot.mapID) and Presets and type(Presets.GetRouteKeyByCollectionAndMapID) == "function" then
        local routeKey = Presets.GetRouteKeyByCollectionAndMapID(collectionKey, snapshot.mapID)
        if type(routeKey) == "string" and routeKey ~= "" then
            return routeKey
        end
    end

    local routeUID = type(routeRef) == "table" and tostring(routeRef.routeUID or "") or ""
    local importedUIDs = type(imp.importedUIDs) == "table" and imp.importedUIDs or nil
    if routeUID ~= "" and importedUIDs then
        for routeKey, uid in pairs(importedUIDs) do
            if tostring(uid or "") == routeUID and tostring(routeKey or "") ~= "" then
                return tostring(routeKey)
            end
        end
    end
    local key = type(imp.selectedBuiltinKey) == "string" and imp.selectedBuiltinKey or ""
    return key ~= "" and key or nil
end

local function GetPullNote(routeKey, pullIndex, routeRef, snapshot)
    local db = GetDB()
    db.notes = db.notes or {}
    local routeNotes = db.notes[routeKey]
    if type(routeNotes) == "table" then
        local userNote = routeNotes[tonumber(pullIndex)]
        if userNote ~= nil then
            return tostring(userNote)
        end
    end
    if Notes and type(Notes.Get) == "function" then
        local builtinKey = GetBuiltinRouteKey(routeRef, snapshot)
        if builtinKey then
            return Notes.Get(builtinKey, pullIndex)
        end
    end
    return ""
end

local function GetCollectionKey()
    local db = GetDB()
    local key = type(db.import) == "table" and type(db.import.selectedCollectionKey) == "string" and db.import.selectedCollectionKey or nil
    if not key or key == "" then
        key = type(db.import) == "table" and type(db.import.collectionKey) == "string" and db.import.collectionKey or nil
    end
    return (key and key ~= "") and key or nil
end

local function BuildState()
    local db = GetDB()
    local routeRef = SelectRouteRef()
    if not routeRef or routeRef.ok ~= true then
        return {
            ok = false,
            reason = routeRef and routeRef.reason or "MDT unavailable",
            routeRef = routeRef,
        }
    end

    local snapshot = Snapshot.Build(routeRef)
    if not snapshot or type(snapshot.pulls) ~= "table" or #snapshot.pulls == 0 then
        return {
            ok = false,
            reason = "MDT route has no pulls",
            routeRef = routeRef,
            snapshot = snapshot,
        }
    end

    local progressInfo = Progress.GetLiveEnemyForcesInfo()
    local mode = (db.followMode == "manual") and "manual" or "auto"
    local previousIndex = currentState and currentState.currentPullIndex or nil
    local currentPullIndex
    if mode == "auto" and progressInfo and tonumber(progressInfo.current) then
        currentPullIndex = Progress.ResolvePullIndex(
            snapshot,
            progressInfo.current,
            tonumber(previousIndex) or tonumber(db.manualPullIndex)
        )
        if currentPullIndex then
            db.manualPullIndex = currentPullIndex
        end
    end
    if not currentPullIndex then
        currentPullIndex = tonumber(db.manualPullIndex) or tonumber(previousIndex) or tonumber(snapshot.currentPullFromMDT) or 1
    end
    currentPullIndex = MDTMod.Clamp(currentPullIndex, 1, #snapshot.pulls)
    if mode == "manual" then
        db.manualPullIndex = currentPullIndex
    end

    local nextPullIndex = nil
    if currentPullIndex < #snapshot.pulls then
        nextPullIndex = currentPullIndex + 1
    end

    local currentPull = snapshot.pulls[currentPullIndex]
    local nextPull = nextPullIndex and snapshot.pulls[nextPullIndex] or nil
    local currentNote = GetPullNote(snapshot.routeKey, currentPullIndex, routeRef, snapshot)
    local nextNote = nextPullIndex and GetPullNote(snapshot.routeKey, nextPullIndex, routeRef, snapshot) or ""

    return {
        ok = true,
        mode = mode,
        routeRef = routeRef,
        snapshot = snapshot,
        collectionKey = GetCollectionKey(),
        currentPullIndex = currentPullIndex,
        nextPullIndex = nextPullIndex,
        currentPull = currentPull,
        nextPull = nextPull,
        currentNote = currentNote,
        nextNote = nextNote,
        progress = progressInfo,
    }
end

local function StateSignature(state)
    if type(state) ~= "table" or state.ok ~= true then
        return tostring(state and state.reason or "nil")
    end
    local progress = state.progress and string.format("%.2f", tonumber(state.progress.percent) or 0) or "nil"
    return table.concat({
        tostring(state.snapshot and state.snapshot.routeKey or ""),
        tostring(state.mode or ""),
        tostring(state.currentPullIndex or ""),
        tostring(state.nextPullIndex or ""),
        progress,
        tostring(state.currentNote or ""),
        tostring(state.nextNote or ""),
    }, "|")
end

function Runtime.Refresh(force)
    if force ~= true and currentState and currentState._signature == StateSignature(currentState) then
        -- intentionally continue, state may still need route refresh
    end

    local nextState = BuildState()
    nextState._signature = StateSignature(nextState)
    local changed = (not currentState) or currentState._signature ~= nextState._signature
    currentState = nextState
    if changed or force == true then
        NotifyListeners()
    end
    return currentState
end

function Runtime.GetState()
    if not currentState then
        return Runtime.Refresh(true)
    end
    return currentState
end

function Runtime.RegisterListener(key, callback)
    if type(key) ~= "string" or type(callback) ~= "function" then
        return
    end
    listeners[key] = callback
end

function Runtime.UnregisterListener(key)
    listeners[key] = nil
end

function Runtime.SetSelectedDungeonIdx(dungeonIdx)
    local db = GetDB()
    local idx = tonumber(dungeonIdx)
    if idx then
        db.selectedDungeonIdx = idx
    else
        db.selectedDungeonIdx = nil
    end
    return Runtime.Refresh(true)
end

function Runtime.SetManualPullIndex(pullIndex)
    local db = GetDB()
    local state = Runtime.GetState()
    local pullCount = state and state.ok and state.snapshot and #state.snapshot.pulls or nil
    if not pullCount or pullCount <= 0 then
        return Runtime.Refresh(true)
    end
    db.manualPullIndex = MDTMod.Clamp(tonumber(pullIndex) or 1, 1, pullCount)
    return Runtime.Refresh(true)
end

function Runtime.StepManualPullIndex(delta)
    local state = Runtime.GetState()
    if not (state and state.ok and state.snapshot and type(state.snapshot.pulls) == "table") then
        return Runtime.Refresh(true)
    end
    local current = tonumber(state.currentPullIndex) or 1
    return Runtime.SetManualPullIndex(current + (tonumber(delta) or 0))
end

function Runtime.GetFollowMode()
    local db = GetDB()
    return (db.followMode == "manual") and "manual" or "auto"
end

function Runtime.SetFollowMode(mode)
    local db = GetDB()
    if mode == "manual" then
        db.followMode = "manual"
        if currentState and currentState.ok then
            db.manualPullIndex = tonumber(currentState.currentPullIndex) or db.manualPullIndex
        end
    else
        db.followMode = "auto"
    end
    return Runtime.Refresh(true)
end

function Runtime.ToggleFollowMode()
    if Runtime.GetFollowMode() == "manual" then
        return Runtime.SetFollowMode("auto")
    end
    return Runtime.SetFollowMode("manual")
end

function Runtime.SetSimulationEnabled(enabled)
    return Runtime.Refresh(true)
end

function Runtime.SetSimulationPercent(percent)
    return Runtime.Refresh(true)
end

function Runtime.SetSimulationPullIndex(pullIndex)
    return Runtime.Refresh(true)
end

function Runtime.GetDisplaySettings()
    local db = GetDB()
    db.general = type(db.general) == "table" and db.general or {}
    if db.general.showCasters == nil then
        db.general.showCasters = true
    end
    return db.general
end

function Runtime.ShouldShowEnemy(enemy)
    if type(enemy) ~= "table" then
        return false
    end
    local settings = Runtime.GetDisplaySettings()
    local showCasters = settings.showCasters ~= false and enemy.hasInterruptible == true
    return showCasters
end

function Runtime.SetDisplayOption(key, enabled)
    local settings = Runtime.GetDisplaySettings()
    if key == "showCasters" then
        settings[key] = enabled == true
    end
    return Runtime.Refresh(true)
end

function Runtime.GetPullNote(routeKey, pullIndex)
    local state = Runtime.GetState()
    return GetPullNote(routeKey, pullIndex, state and state.routeRef or nil, state and state.snapshot or nil)
end

function Runtime.SetPullNote(routeKey, pullIndex, text)
    local db = GetDB()
    db.notes = db.notes or {}
    routeKey = tostring(routeKey or "")
    if routeKey == "" then
        return
    end
    local idx = tonumber(pullIndex)
    if not idx then
        return
    end

    local routeNotes = db.notes[routeKey]
    if type(routeNotes) ~= "table" then
        routeNotes = {}
        db.notes[routeKey] = routeNotes
    end

    text = MDTMod.NormalizeText(text)
    if text == "" then
        routeNotes[idx] = nil
        if not next(routeNotes) then
            db.notes[routeKey] = nil
        end
    else
        routeNotes[idx] = text
    end
    Runtime.Refresh(true)
end

function Runtime.GetCurrentRouteRef()
    local state = Runtime.GetState()
    return state and state.routeRef or nil
end

local function OnEvent(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "MythicDungeonTools" and addonName ~= "InfinityBoss" then
        return
    end
    Runtime.Refresh(true)
end

local function EnsureEventFrame()
    if eventFrame then
        return
    end
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("CHALLENGE_MODE_START")
    eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    eventFrame:RegisterEvent("SCENARIO_UPDATE")
    eventFrame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
    eventFrame:SetScript("OnEvent", OnEvent)
end

EnsureEventFrame()
Runtime.Refresh(true)
OnEvent(nil, "PLAYER_ENTERING_WORLD")
