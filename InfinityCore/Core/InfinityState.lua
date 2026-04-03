--[[
    InfinityState.lua - State Management System

    Responsibilities:
    1. State table maintenance (InCombat, SpecID, PStat_*, etc.)
    2. State subscription and callbacks (WatchState / UpdateState)
    3. Delta monitoring (WatchStateDelta) - used to detect BUFFs via stat changes
    4. Player stat collection (PStat_* series)
    5. Class/spec info collection

    Available built-in State keys:
    - InCombat (boolean)
    - InInstance (boolean)
    - InstanceType (string)
    - InstanceID (number)
    - MapID (number)
    - MapGroup (number, equals MapID when there is no group)
    - DifficultyID (number)
    - InMythicPlus (boolean)
    - AuraSecretsActive (boolean)
    - ClassID (number)
    - ClassName (string)
    - SpecID (number)
    - SpecName (string)
    - RoleKey (string: tank/heal/dps/unknown)
    - RoleName (string)
    - DevMode (boolean)
    - PStat_Str, PStat_Agi, PStat_Sta, PStat_Int (primary stats)
    - PStat_Major (smart primary stat)
    - PStat_Crit, PStat_Haste, PStat_Mastery, PStat_Versa (secondary stats %)
    - PStat_Leech, PStat_Avoidance, PStat_Speed (tertiary stats)
    - PStat_Armor, PStat_Dodge, PStat_Parry, PStat_Block (defensive stats)
    - PStat_EquippedItemLevel, PStat_MaxHealth, PStat_Movement, PStat_Durability
--]]

local InfinityTools = _G.InfinityTools
if not InfinityTools then
    error("[InfinityState] InfinityTools core not loaded! Check .toc load order.")
    return
end

--=======================================================================
--========================== STATE TABLE DEFINITION ====================
--=======================================================================

InfinityTools.State = {
    -- Core state
    InCombat = false,
    InInstance = false,
    InstanceType = "none",
    InstanceID = 0,
    MapID = 0,
    MapGroup = 0,
    DifficultyID = 0,
    InMythicPlus = false,
    IsInParty = false,
    IsInRaid = false,
    AuraSecretsActive = false,
    -- Boss encounter state
    IsBossEncounter = false,
    EncounterID = 0,

    -- Identity state
    ClassID = 0,
    ClassName = "Unknown",
    SpecID = 0,
    SpecName = "Unknown",
    RoleKey = "unknown",
    RoleName = "Unknown Role",
    Level = 0,
    PlayerName = "",
    RealmName = "",

    -- Developer mode
    DevMode = false,

    -- Player stats (PStat_*)
    PStat_Str = 0,
    PStat_Agi = 0,
    PStat_Sta = 0,
    PStat_Int = 0,
    PStat_Major = 0,
    PStat_Crit = 0,
    PStat_Haste = 0,
    PStat_Mastery = 0,
    PStat_Versa = 0,
    PStat_Leech = 0,
    PStat_Avoidance = 0,
    PStat_Speed = 0,
    PStat_Armor = 0,
    PStat_Dodge = 0,
    PStat_Parry = 0,
    PStat_Block = 0,
    PStat_EquippedItemLevel = 0,
    PStat_MaxHealth = 0,
    PStat_Movement = 0,
    PStat_Durability = 100,

    -- Interrupt spell state
    InterruptReady = true,
}


InfinityTools.StateCallbacks = {}

-- ENCOUNTER_START is not replayed after /reload; cache the last boss encounter info for reload recovery
local INFINITY_STATE_DB = InfinityTools:GetModuleDB("InfinityState", {
    encounter = {
        inProgress = false,
        id = 0,
        instanceID = 0,
        ts = 0,
    },
})

local function SetEncounterState(isInProgress, encounterID)
    local id = isInProgress and (tonumber(encounterID) or 0) or 0
    local instanceID = tonumber((select(8, GetInstanceInfo()))) or 0

    InfinityTools:UpdateState("IsBossEncounter", isInProgress and true or false)
    InfinityTools:UpdateState("EncounterID", id)

    local e = INFINITY_STATE_DB.encounter or {}
    INFINITY_STATE_DB.encounter = e
    e.inProgress = isInProgress and true or false
    e.id = id
    e.instanceID = instanceID
    e.ts = (GetServerTime and GetServerTime()) or time()
end

local function QueryCurrentEncounterID()
    local id = 0

    if C_EncounterJournal and type(C_EncounterJournal.GetCurrentEncounterInfo) == "function" then
        local ok, a, b, c = pcall(C_EncounterJournal.GetCurrentEncounterInfo)
        if ok then
            -- Common return values: name, description, encounterID, ...
            id = tonumber(c) or 0
            if id <= 0 and type(a) == "table" then
                id = tonumber(a.encounterID or a.id) or 0
            end
        end
    end

    if id <= 0 and type(EJ_GetCurrentEncounterInfo) == "function" then
        local ok, a, b, c = pcall(EJ_GetCurrentEncounterInfo)
        if ok then
            id = tonumber(c) or tonumber(a) or 0
        end
    end

    if id > 0 then return id end
    return 0
end

--=======================================================================
--========================== STATE SUBSCRIPTION SYSTEM ================
--=======================================================================

--- Subscribe to state changes
--- @param key string State key name
--- @param owner string Module identifier
--- @param func function Callback function: func(newValue, oldValue)
function InfinityTools:WatchState(key, owner, func)
    if not self.StateCallbacks[key] then
        self.StateCallbacks[key] = {}
    end
    self.StateCallbacks[key][owner] = func
end

--- Unsubscribe from state changes
--- @param key string State key name
--- @param owner string Module identifier
function InfinityTools:UnwatchState(key, owner)
    if self.StateCallbacks[key] then
        self.StateCallbacks[key][owner] = nil
    end
end

--- Update a state value (triggers callbacks and delta checks)
--- @param key string State key name
--- @param newValue any New value
function InfinityTools:UpdateState(key, newValue)
    local oldValue = self.State[key]

    -- Skip if value is unchanged
    if oldValue == newValue then return end

    self.State[key] = newValue

    -- 1. Trigger regular callbacks
    self:TriggerCallbacks(key, newValue, oldValue)

    -- 2. Check delta subscriptions (numeric types only)
    if type(newValue) == "number" and type(oldValue) == "number" then
        local delta = newValue - oldValue

        -- [Refactor] Support custom delta calculation logic (e.g. multiplicative haste calculation)
        if self.DeltaCalculators and self.DeltaCalculators[key] then
            delta = self.DeltaCalculators[key](newValue, oldValue)
        end

        self:CheckDeltaWatchers(key, delta, newValue, oldValue)
    end
end

-- =======================================================================
-- Custom delta calculators (solve delta identification for multiplicative stats)
-- =======================================================================
InfinityTools.DeltaCalculators = {
    ["PStat_Haste"] = function(newVal, oldVal)
        -- Haste in WoW is multiplicative: (1+H_new) = (1+H_old) * (1+Buff)
        -- Buff gain = (1+H_new)/(1+H_old) - 1
        if newVal >= oldVal then
            -- Buff gained
            return ((100 + newVal) / (100 + oldVal) - 1) * 100
        else
            -- Buff faded
            -- Use the inverse ratio so the absolute delta on fade matches the gain delta
            return -(((100 + oldVal) / (100 + newVal) - 1) * 100)
        end
    end
}

--- Trigger state callbacks
function InfinityTools:TriggerCallbacks(key, newValue, oldValue)
    local callbacks = self.StateCallbacks[key]
    if not callbacks then return end

    for owner, func in pairs(callbacks) do
        local ok, err = pcall(func, newValue, oldValue)
        if not ok then
            local source = string.format("State[%s][%s]", key, tostring(owner))
            if self.LogError then self:LogError(source, err) end
            print(string.format("|cffff0000[InfinityState] callback error [%s][%s]: %s|r",
                key, tostring(owner), tostring(err)))
        end
    end
end

--- Performance benchmark: measure the time cost of the current stat collection logic
function InfinityTools:TestStatePerformance()
    local startTime = debugprofilestop()
    local count = 1000

    for i = 1, count do
        local _, str = UnitStat("player", 1)
        local _, agi = UnitStat("player", 2)
        local _, sta = UnitStat("player", 3)
        local _, int = UnitStat("player", 4)
        local _ = math.max(str, agi, int)
        local _ = GetSpellCritChance()
        local _ = GetHaste()
        local _ = GetMasteryEffect()
        local _ = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
        local _ = GetLifesteal()
        local _ = GetAvoidance()
        local _ = GetSpeed()
        local _, armor = UnitArmor("player")
        local _ = GetDodgeChance()
        local _ = GetParryChance()
        local _ = GetBlockChance()
        local _, ilvl = GetAverageItemLevel()
        local _ = UnitHealthMax("player")
    end

    local duration = debugprofilestop() - startTime
    print(string.format("|cff00ffff[InfinityState]|r 1000x stat collection: %.4fms total, %.6fms avg", duration, duration / count))
end

--=======================================================================
--========================== DELTA MONITORING SYSTEM ==================
--=======================================================================
-- Used to detect BUFF triggers via stat delta changes (M+ in 12.0 does not allow direct BUFF monitoring)

InfinityTools.DeltaWatchers = {}     -- { [state] = { [owner] = config } }
InfinityTools.DeltaMinThreshold = {} -- { [state] = minimum 'min' value among all subscriptions }

--- Register a delta watcher
--- @param state string State key name (e.g. "PStat_Crit")
--- @param owner string Module identifier
--- @param config table|number Config table { min, max, onTrigger, onFade } or a minimum threshold (number)
--- @param onTrigger function (required when config is a number) Trigger callback
--- @param onFade function (optional when config is a number) Fade callback
function InfinityTools:WatchStateDelta(state, owner, config, arg4, arg5, arg6)
    -- [Refactor] Enhanced calling modes:
    -- 1. Minimal number mode: (state, owner, 30, callback)
    -- 2. Flat custom mode: (state, owner, 30, 0.05, callback) -> pass threshold and margin directly
    -- 3. Table custom mode: (state, owner, {30, 0.05}, callback)
    -- 4. Original standard mode: (state, owner, {min, max, ...})

    local threshold, margin, onTrigger, onFade

    if type(config) == "number" then
        threshold = config
        -- Determine whether the fourth argument is a margin (number) or a callback (function)
        if type(arg4) == "number" then
            margin = arg4
            onTrigger = arg5
            onFade = arg6
        else
            margin = 0.1 -- default 10%
            onTrigger = arg4
            onFade = arg5
        end
    elseif type(config) == "table" and config[1] and not config.min then
        threshold = config[1]
        margin = config[2] or 0.1
        onTrigger = arg4
        onFade = arg5
    end

    -- If a simplified mode was matched, build a standard config table
    if threshold then
        config = {
            min = threshold * (1 - margin),
            max = threshold * (1 + margin) * 2,
            onTrigger = onTrigger,
            onFade = onFade
        }
    end

    if type(config) ~= "table" or not config.min or not config.max then
        error("InfinityTools:WatchStateDelta: config must include min and max", 2)
    end

    if not self.DeltaWatchers[state] then
        self.DeltaWatchers[state] = {}
    end
    self.DeltaWatchers[state][owner] = config

    -- Update the minimum threshold cache
    self:UpdateDeltaMinThreshold(state)

    InfinityDebug("Delta watch registered: %s [%s] range %.1f-%.1f", state, owner, config.min, config.max)
end

--- Unregister a delta watcher
--- @param state string State key name
--- @param owner string Module identifier
function InfinityTools:UnwatchStateDelta(state, owner)
    if self.DeltaWatchers[state] then
        self.DeltaWatchers[state][owner] = nil

        -- Check whether any subscribers remain
        local count = 0
        for _ in pairs(self.DeltaWatchers[state]) do count = count + 1 end

        if count == 0 then
            self.DeltaWatchers[state] = nil
            self.DeltaMinThreshold[state] = nil
        else
            self:UpdateDeltaMinThreshold(state)
        end
    end
end

--- Update the minimum threshold cache for a given state key
function InfinityTools:UpdateDeltaMinThreshold(state)
    local watchers = self.DeltaWatchers[state]
    if not watchers then
        self.DeltaMinThreshold[state] = nil
        return
    end

    local minVal = math.huge
    for _, config in pairs(watchers) do
        if config.min < minVal then
            minVal = config.min
        end
    end
    self.DeltaMinThreshold[state] = minVal
end

--- Check delta subscriptions and fire callbacks
function InfinityTools:CheckDeltaWatchers(key, delta, newVal, oldVal)
    local watchers = self.DeltaWatchers[key]
    if not watchers then return end

    local absDelta = math.abs(delta)
    local minThreshold = self.DeltaMinThreshold[key]

    -- ⚡ First-level filter: arithmetic delta too small, skip immediately
    if minThreshold and absDelta < minThreshold then
        return
    end

    -- ⚡ Second-level processing: if a logical calculator is defined (e.g. haste), compute the logical delta once
    local logicalDelta = delta
    if self.DeltaCalculators and self.DeltaCalculators[key] then
        logicalDelta = self.DeltaCalculators[key](newVal, oldVal)
        absDelta = math.abs(logicalDelta) -- re-evaluate absolute value

        -- Apply minimum threshold filter again (against the logical value)
        if minThreshold and absDelta < minThreshold then
            return
        end
    end

    -- Iterate specific subscriptions (logicalDelta is now final; no need to recalculate)
    for owner, config in pairs(watchers) do
        if logicalDelta > 0 and logicalDelta >= config.min and logicalDelta <= config.max then
            -- Positive delta triggered (BUFF gained)
            if config.onTrigger then
                local ok, err = pcall(config.onTrigger, logicalDelta, newVal, oldVal)
                if not ok then
                    print(string.format("|cffff0000[InfinityState] Delta callback error [%s][%s]: %s|r",
                        key, owner, tostring(err)))
                end
            end
        elseif logicalDelta < 0 and (-logicalDelta) >= config.min and (-logicalDelta) <= config.max then
            -- Negative delta triggered (BUFF faded)
            if config.onFade then
                local ok, err = pcall(config.onFade, logicalDelta, newVal, oldVal)
                if not ok then
                    print(string.format("|cffff0000[InfinityState] Delta Fade callback error [%s][%s]: %s|r",
                        key, owner, tostring(err)))
                end
            end
        end
    end
end

--=======================================================================
--========================== STATE COLLECTION INITIALIZATION ===========
--=======================================================================

local function InitializeStateMonitors()
    local OWNER = "InfinityState"

    local function NormalizeRoleKey(role)
        local r = tostring(role or ""):lower()
        if r == "tank" then return "tank" end
        if r == "heal" or r == "healer" then return "heal" end
        if r == "dps" or r == "damage" or r == "damager" then return "dps" end
        return "unknown"
    end

    local function RoleNameFromKey(roleKey)
        if roleKey == "tank" then return "Tank" end
        if roleKey == "heal" then return "Healer" end
        if roleKey == "dps" then return "DPS" end
        return "Unknown Role"
    end

    local function ResolveRoleFromSpec(specID, specIndex)
        local roleKey = "unknown"

        if _G.InfinityDB and type(_G.InfinityDB.GetSpecRoleKey) == "function" then
            roleKey = NormalizeRoleKey(_G.InfinityDB:GetSpecRoleKey(specID))
        elseif _G.InfinityDB and type(_G.InfinityDB.SpecRoleKeyByID) == "table" then
            roleKey = NormalizeRoleKey(_G.InfinityDB.SpecRoleKeyByID[specID])
        end

        -- Fallback: still resolve from current spec only, do not read group role
        if roleKey == "unknown" and type(GetSpecializationRole) == "function" and specIndex and specIndex > 0 then
            roleKey = NormalizeRoleKey(GetSpecializationRole(specIndex))
        end

        return roleKey, RoleNameFromKey(roleKey)
    end

    local function IsMythicPlusContext(inInstance, instanceType, difficultyID)
        if not inInstance or instanceType ~= "party" then
            return false
        end

        local diff = tonumber(difficultyID) or 0
        if diff == 8 then
            return true
        end

        if C_ChallengeMode and type(C_ChallengeMode.GetActiveChallengeMapID) == "function" then
            local mapID = tonumber(C_ChallengeMode.GetActiveChallengeMapID()) or 0
            if mapID > 0 then
                return true
            end
        end

        return false
    end

    local function GetPlayerMapState(unitToken)
        local token = unitToken or "player"
        local mapID = 0
        local mapGroup = 0

        if C_Map and type(C_Map.GetBestMapForUnit) == "function" then
            mapID = tonumber(C_Map.GetBestMapForUnit(token)) or 0
        end

        if mapID > 0 and C_Map and type(C_Map.GetMapGroupID) == "function" then
            local ok, groupID = pcall(C_Map.GetMapGroupID, mapID)
            if ok then
                mapGroup = tonumber(groupID) or 0
            end
        end

        -- Smart fallback: use MapID when MapGroup is unavailable
        if mapGroup <= 0 then
            mapGroup = mapID
        end

        return mapID, mapGroup
    end

    local function UpdateSecretState()
        local auraSecretsActive = false

        if _G.C_Secrets and type(_G.C_Secrets.ShouldAurasBeSecret) == "function" then
            local ok, value = pcall(_G.C_Secrets.ShouldAurasBeSecret)
            if ok then
                auraSecretsActive = value and true or false
            end
        end

        InfinityTools:UpdateState("AuraSecretsActive", auraSecretsActive)
    end

    --===================================================================
    -- 1. Base state listeners (combat / instance / talent)
    --===================================================================

    local function UpdateBaseState(event, ...)
        if event == "PLAYER_REGEN_DISABLED" then
            InfinityTools:UpdateState("InCombat", true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            InfinityTools:UpdateState("InCombat", false)
        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA"
            or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS"
            or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_DIFFICULTY_CHANGED"
            or event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_RESET"
            or event == "CHALLENGE_MODE_COMPLETED" then
            local inInstance, instanceType = IsInInstance()
            local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
            local mapID, mapGroup = GetPlayerMapState("player")

            local oldIT = InfinityTools.State.InstanceType
            local oldIID = InfinityTools.State.InstanceID
            local oldDI = InfinityTools.State.DifficultyID
            local oldII = InfinityTools.State.InInstance
            local oldMapID = InfinityTools.State.MapID
            local oldMapGroup = InfinityTools.State.MapGroup
            local oldIMP = InfinityTools.State.InMythicPlus
            local oldIP = InfinityTools.State.IsInParty
            local oldIR = InfinityTools.State.IsInRaid

            local inGroup = IsInGroup()
            local inRaid = IsInRaid()
            local inMythicPlus = IsMythicPlusContext(inInstance, instanceType, difficultyID)

            InfinityTools:UpdateState("InInstance", inInstance)
            InfinityTools:UpdateState("InstanceType", instanceType)
            InfinityTools:UpdateState("InstanceID", instanceID or 0)
            InfinityTools:UpdateState("MapID", mapID)
            InfinityTools:UpdateState("MapGroup", mapGroup)
            InfinityTools:UpdateState("DifficultyID", difficultyID)
            InfinityTools:UpdateState("InMythicPlus", inMythicPlus)
            InfinityTools:UpdateState("IsInParty", inGroup)
            InfinityTools:UpdateState("IsInRaid", inRaid)
            UpdateSecretState()

            -- Fire change callbacks
            if inInstance ~= oldII then InfinityTools:TriggerCallbacks("InInstance", inInstance, oldII) end
            if instanceType ~= oldIT then InfinityTools:TriggerCallbacks("InstanceType", instanceType, oldIT) end
            if (instanceID or 0) ~= (oldIID or 0) then
                InfinityTools:TriggerCallbacks("InstanceID", instanceID or 0,
                    oldIID or 0)
            end
            if mapID ~= oldMapID then InfinityTools:TriggerCallbacks("MapID", mapID, oldMapID) end
            if mapGroup ~= oldMapGroup then InfinityTools:TriggerCallbacks("MapGroup", mapGroup, oldMapGroup) end
            if difficultyID ~= oldDI then InfinityTools:TriggerCallbacks("DifficultyID", difficultyID, oldDI) end
            if inMythicPlus ~= oldIMP then InfinityTools:TriggerCallbacks("InMythicPlus", inMythicPlus, oldIMP) end
            if inGroup ~= oldIP then InfinityTools:TriggerCallbacks("IsInParty", inGroup, oldIP) end
            if inRaid ~= oldIR then InfinityTools:TriggerCallbacks("IsInRaid", inRaid, oldIR) end
        end
    end

    InfinityTools:RegisterEvent("PLAYER_REGEN_DISABLED", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("PLAYER_REGEN_ENABLED", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("ZONE_CHANGED_NEW_AREA", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("ZONE_CHANGED", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("ZONE_CHANGED_INDOORS", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("GROUP_ROSTER_UPDATE", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("PLAYER_DIFFICULTY_CHANGED", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("CHALLENGE_MODE_START", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("CHALLENGE_MODE_RESET", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("CHALLENGE_MODE_COMPLETED", OWNER, UpdateBaseState)
    InfinityTools:RegisterEvent("SCENARIO_UPDATE", OWNER, UpdateBaseState)

    --===================================================================
    -- 2. Class/spec collection (with retry mechanism)
    --===================================================================
    local MAX_SPEC_RETRIES = 20
    local isSpecRetrying = false

    local function UpdateSpecInfo(retryCount)
        -- (original logic preserved)...
        if type(retryCount) ~= "number" then retryCount = 0 end -- compatibility with event call

        local _, classEN, classID = UnitClass("player")
        local specIndex = GetSpecialization()
        local specID = (specIndex and specIndex > 0) and GetSpecializationInfo(specIndex) or 0

        local isComplete = (classID and classID > 0) and (specID and specID > 0)

        if not isComplete then
            if retryCount < MAX_SPEC_RETRIES then
                if retryCount == 0 and isSpecRetrying then return end
                isSpecRetrying = true
                C_Timer.After(2, function() UpdateSpecInfo(retryCount + 1) end)
            else
                isSpecRetrying = false
            end
        else
            isSpecRetrying = false
        end

        -- Get names from InfinityDB
        local specName = "Unknown"
        local className = "Unknown"

        if classID and _G.InfinityDB and _G.InfinityDB.Classes[classID] then
            className = _G.InfinityDB.Classes[classID].name
        end
        if specID and specID > 0 and _G.InfinityDB and _G.InfinityDB.SpecByID[specID] then
            specName = _G.InfinityDB.SpecByID[specID].name
        end

        local roleKey, roleName = ResolveRoleFromSpec(specID, specIndex)

        InfinityTools:UpdateState("ClassID", classID or 0)
        InfinityTools:UpdateState("ClassName", className)
        InfinityTools:UpdateState("SpecID", specID or 0)
        InfinityTools:UpdateState("SpecName", specName)
        InfinityTools:UpdateState("RoleKey", roleKey)
        InfinityTools:UpdateState("RoleName", roleName)
        InfinityTools:UpdateState("Level", UnitLevel("player") or 0)
        InfinityTools:UpdateState("PlayerName", UnitName("player") or "")
        InfinityTools:UpdateState("RealmName", GetRealmName() or "")

        if isComplete and retryCount > 0 then
            InfinityDebug("Spec info loaded: %s (%s)", className, specName)
        end
    end

    InfinityTools:RegisterEvent("PLAYER_TALENT_UPDATE", OWNER, UpdateSpecInfo)
    InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", OWNER .. "_Spec", UpdateSpecInfo)
    InfinityTools:RegisterEvent("PLAYER_LEVEL_UP", OWNER, function(_, newLevel)
        InfinityTools:UpdateState("Level", newLevel or UnitLevel("player") or 0)
    end)

    --===================================================================
    -- 3. Player stat collection (PStat_*)
    --===================================================================
    -- Future plan: use more granular event bindings per stat (e.g. dodge event only updates dodge)
    -- Requires extensive testing, so full refresh is used for now in the short term

    -- Fine-grained stat collection logic (segmented updates; player UNIT_AURA does a full refresh to cover stat Buffs)
    local function UpdateDurabilityStat()
        local totalCurrent = 0
        local totalMax = 0

        -- Only count equipped slots that have durability; output the overall durability percentage
        for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
            local current, maxValue = GetInventoryItemDurability(slot)
            if current and maxValue and maxValue > 0 then
                totalCurrent = totalCurrent + current
                totalMax = totalMax + maxValue
            end
        end

        local durability = 100
        if totalMax > 0 then
            durability = (totalCurrent / totalMax) * 100
        end

        InfinityTools:UpdateState("PStat_Durability", durability)
    end

    -- In some versions item level updates after PLAYER_EQUIPMENT_CHANGED; add a delayed re-sample pass
    local function UpdateEquippedItemLevel(event)
        local function Sample()
            local _, ilvl = GetAverageItemLevel()
            if type(ilvl) == "number" and ilvl > 0 then
                InfinityTools:UpdateState("PStat_EquippedItemLevel", ilvl)
            end
        end

        Sample()

        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED" then
            local retryDelays = { 0.10, 0.35, 0.80 }
            for _, delay in ipairs(retryDelays) do
                C_Timer.After(delay, Sample)
            end
        end
    end

    local function UpdatePlayerStats(event, unit)
        -- Only filter by unit for UNIT_* events; other events may pass a slot number or other non-unit value as the second argument
        if (event == "UNIT_STATS" or event == "UNIT_MAXHEALTH" or event == "UNIT_AURA") and unit and unit ~= "player" then
            return
        end

        if event == "MASTERY_UPDATE" then
            InfinityTools:UpdateState("PStat_Mastery", GetMasteryEffect())
        elseif event == "COMBAT_RATING_UPDATE" then
            InfinityTools:UpdateState("PStat_Versa",
                GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE))
            InfinityTools:UpdateState("PStat_Crit", GetSpellCritChance())
            InfinityTools:UpdateState("PStat_Haste", GetHaste())
        elseif event == "UNIT_STATS" then
            local _, str = UnitStat("player", 1)
            local _, agi = UnitStat("player", 2)
            local _, sta = UnitStat("player", 3)
            local _, int = UnitStat("player", 4)
            InfinityTools:UpdateState("PStat_Str", str)
            InfinityTools:UpdateState("PStat_Agi", agi)
            InfinityTools:UpdateState("PStat_Sta", sta)
            InfinityTools:UpdateState("PStat_Int", int)
            InfinityTools:UpdateState("PStat_Major", math.max(str, agi, int))
        elseif event == "UNIT_MAXHEALTH" then
            InfinityTools:UpdateState("PStat_MaxHealth", UnitHealthMax("player"))
        elseif event == "AVOIDANCE_UPDATE" then
            InfinityTools:UpdateState("PStat_Avoidance", GetAvoidance())
        elseif event == "LIFESTEAL_UPDATE" then
            InfinityTools:UpdateState("PStat_Leech", GetLifesteal())
        elseif event == "UPDATE_INVENTORY_DURABILITY" then
            UpdateDurabilityStat()
        else
            -- Full refresh (PEW, equipment change, player UNIT_AURA, etc.)
            local _, str = UnitStat("player", 1)
            local _, agi = UnitStat("player", 2)
            local _, sta = UnitStat("player", 3)
            local _, int = UnitStat("player", 4)
            InfinityTools:UpdateState("PStat_Str", str)
            InfinityTools:UpdateState("PStat_Agi", agi)
            InfinityTools:UpdateState("PStat_Sta", sta)
            InfinityTools:UpdateState("PStat_Int", int)
            InfinityTools:UpdateState("PStat_Major", math.max(str, agi, int))

            InfinityTools:UpdateState("PStat_Crit", GetSpellCritChance())
            InfinityTools:UpdateState("PStat_Haste", GetHaste())
            InfinityTools:UpdateState("PStat_Mastery", GetMasteryEffect())
            InfinityTools:UpdateState("PStat_Versa",
                GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE))
            InfinityTools:UpdateState("PStat_Leech", GetLifesteal())
            InfinityTools:UpdateState("PStat_Avoidance", GetAvoidance())
            InfinityTools:UpdateState("PStat_Speed", GetSpeed())

            local _, armor = UnitArmor("player")
            InfinityTools:UpdateState("PStat_Armor", armor)
            InfinityTools:UpdateState("PStat_Dodge", GetDodgeChance())
            InfinityTools:UpdateState("PStat_Parry", GetParryChance())
            InfinityTools:UpdateState("PStat_Block", GetBlockChance())

            UpdateEquippedItemLevel(event)
            InfinityTools:UpdateState("PStat_MaxHealth", UnitHealthMax("player"))
            UpdateDurabilityStat()
        end
    end

    -- Movement speed ticker (updates once per second, event-free to reduce overhead)
    C_Timer.NewTicker(1, function()
        local _, runSpeed = GetUnitSpeed("player")
        InfinityTools:UpdateState("PStat_Movement", (runSpeed / 7) * 100)
    end)

    local statEvents = {
        "COMBAT_RATING_UPDATE", "AVOIDANCE_UPDATE", "LIFESTEAL_UPDATE", "MASTERY_UPDATE",
        "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED", "UNIT_STATS", "UNIT_MAXHEALTH", "UNIT_AURA",
        "UPDATE_INVENTORY_DURABILITY", "TRAIT_CONFIG_UPDATED", "PLAYER_AVG_ITEM_LEVEL_UPDATE"
    }
    for _, e in ipairs(statEvents) do
        InfinityTools:RegisterEvent(e, OWNER, UpdatePlayerStats)
    end

    --===================================================================
    -- 3.5 Player interrupt spell state monitoring
    --===================================================================
    InfinityTools:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", OWNER .. "_Interrupt", function(event, unit, castID, spellID)
        if unit ~= "player" then return end

        -- Get current spec
        local specIndex = GetSpecialization()
        local specID = (specIndex and specIndex > 0) and GetSpecializationInfo(specIndex) or 0

        if _G.InfinityDB and _G.InfinityDB.InterruptData and _G.InfinityDB.InterruptData[specID] then
            local interruptID = _G.InfinityDB.InterruptData[specID].id
            local cdDuration = _G.InfinityDB.InterruptData[specID].cd
            if interruptID > 0 and spellID == interruptID then
                if cdDuration and cdDuration > 0 then
                    -- Perfectly avoids the "Secret Number" comparison error caused by the 12.0 API
                    -- protecting duration/startTime; force-use the fixed CD values pre-stored in the player database
                    InfinityTools:UpdateState("InterruptStartTime", GetTime())
                    InfinityTools:UpdateState("InterruptDuration", cdDuration)
                    InfinityTools:UpdateState("InterruptReady", false)

                    C_Timer.After(cdDuration, function()
                        InfinityTools:UpdateState("InterruptReady", true)
                    end)
                end
            end
        end
    end)

    --===================================================================
    -- 4. Boss encounter monitoring (Encounter Tracking)
    --===================================================================
    InfinityTools:RegisterEvent("ENCOUNTER_START", OWNER, function(event, encounterID)
        local id = encounterID or 0
        SetEncounterState(true, id)
        InfinityDebug("Entered boss encounter: %d", id)
    end)

    InfinityTools:RegisterEvent("ENCOUNTER_END", OWNER, function(event)
        SetEncounterState(false, 0)
        InfinityDebug("Left boss encounter")
    end)

    --===================================================================
    -- 5. Initial synchronization
    --===================================================================
    InfinityTools:UpdateState("InCombat", InCombatLockdown())

    local inInstance, instanceType = IsInInstance()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    local mapID, mapGroup = GetPlayerMapState("player")
    local inMythicPlus = IsMythicPlusContext(inInstance, instanceType, difficultyID)
    InfinityTools:UpdateState("InInstance", inInstance)
    InfinityTools:UpdateState("InstanceType", instanceType)
    InfinityTools:UpdateState("InstanceID", instanceID or 0)
    InfinityTools:UpdateState("MapID", mapID)
    InfinityTools:UpdateState("MapGroup", mapGroup)
    InfinityTools:UpdateState("DifficultyID", difficultyID)
    InfinityTools:UpdateState("InMythicPlus", inMythicPlus)
    InfinityTools:UpdateState("IsInParty", IsInGroup())
    InfinityTools:UpdateState("IsInRaid", IsInRaid())
    UpdateSecretState()

    -- Restore boss encounter state on reload: if /reload happens mid-encounter, restore the last EncounterID
    do
        local inProgress = (type(IsEncounterInProgress) == "function") and IsEncounterInProgress() or false
        local currentInstanceID = tonumber((select(8, GetInstanceInfo()))) or 0
        local cached = INFINITY_STATE_DB.encounter or {}
        local cachedID = tonumber(cached.id) or 0
        local cachedInstanceID = tonumber(cached.instanceID) or 0
        local liveEncounterID = QueryCurrentEncounterID()

        if inProgress and liveEncounterID > 0 then
            SetEncounterState(true, liveEncounterID)
            InfinityDebug("Restored encounter state (live): encounterID=%d", liveEncounterID)
        elseif inProgress and cachedID > 0 and (cachedInstanceID == 0 or currentInstanceID == 0 or cachedInstanceID == currentInstanceID) then
            SetEncounterState(true, cachedID)
            InfinityDebug("Restored encounter state (reload): encounterID=%d", cachedID)
        elseif inProgress then
            -- Confirmed in a boss encounter, but no reliable encounterID available
            SetEncounterState(true, 0)
            InfinityDebug("Boss encounter in progress, could not restore EncounterID")
        else
            SetEncounterState(false, 0)
        end
    end

    -- Force a full update pass
    UpdateSpecInfo()
    UpdatePlayerStats()

    -- Additional delayed check to prevent stale data at login
    C_Timer.After(2, function()
        UpdateSpecInfo()
        UpdatePlayerStats()
        InfinityDebug("Secondary state sync complete")
    end)

    InfinityDebug("InfinityState initialized")
end

-- Delayed initialization (ensure InfinityTools core is fully loaded)
C_Timer.After(0.5, InitializeStateMonitors)
