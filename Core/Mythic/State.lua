local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

Core.State = Core.State or {
    InCombat = false,
    InInstance = false,
    InstanceType = "none",
    InstanceID = 0,
    MapID = 0,
    DifficultyID = 0,
    InMythicPlus = false,
    IsInParty = false,
    IsInRaid = false,
    IsBossEncounter = false,
    EncounterID = 0,
    ClassID = 0,
    ClassName = "Unknown",
    SpecID = 0,
    SpecName = "Unknown",
    RoleKey = "unknown",
    RoleName = "Unknown",
    Level = 0,
    PlayerName = "",
    RealmName = "",
    DevMode = false,
    PStat_Str = 0,
    PStat_Agi = 0,
    PStat_Sta = 0,
    PStat_Int = 0,
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
    InterruptReady = true,
}

local function triggerStateCallbacks(key, newValue, oldValue)
    local bucket = Core._stateWatchers[key]
    if not bucket then
        return
    end

    for _, callback in pairs(bucket) do
        local ok, err = pcall(callback, newValue, oldValue)
        if not ok then
            Core:LogError("WatchState:" .. key, err)
            geterrorhandler()(err)
        end
    end
end

function Core:UpdateState(key, newValue)
    local oldValue = self.State[key]
    if oldValue == newValue then
        return
    end

    self.State[key] = newValue
    triggerStateCallbacks(key, newValue, oldValue)
end

local function updateIdentityState()
    local className, _, classID = UnitClass("player")
    local specIndex = GetSpecialization()
    local specID, specName = 0, "Unknown"
    if specIndex then
        specID, specName = GetSpecializationInfo(specIndex)
    end

    local roleKey = "unknown"
    if Core.DB_Static and Core.DB_Static.GetSpecRoleKey then
        roleKey = Core.DB_Static:GetSpecRoleKey(specID) or roleKey
    end

    local roleName = roleKey
    if roleKey == "tank" then
        roleName = "Tank"
    elseif roleKey == "heal" then
        roleName = "Healer"
    elseif roleKey == "dps" then
        roleName = "DPS"
    end

    Core:UpdateState("ClassID", classID or 0)
    Core:UpdateState("ClassName", className or "Unknown")
    Core:UpdateState("SpecID", specID or 0)
    Core:UpdateState("SpecName", specName or "Unknown")
    Core:UpdateState("RoleKey", roleKey)
    Core:UpdateState("RoleName", roleName)
    Core:UpdateState("Level", UnitLevel("player") or 0)
    Core:UpdateState("PlayerName", UnitName("player") or "")
    Core:UpdateState("RealmName", GetRealmName() or "")
end

local function updateEnvironmentState()
    local inInstance, instanceType = IsInInstance()
    local _, _, difficultyID, _, _, _, _, instanceMapID = GetInstanceInfo()
    local activeMapID = 0
    if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
        activeMapID = tonumber(C_ChallengeMode.GetActiveChallengeMapID()) or 0
    end

    Core:UpdateState("InInstance", inInstance and true or false)
    Core:UpdateState("InstanceType", instanceType or "none")
    Core:UpdateState("DifficultyID", difficultyID or 0)
    Core:UpdateState("InstanceID", instanceMapID or 0)
    Core:UpdateState("MapID", C_Map.GetBestMapForUnit and (C_Map.GetBestMapForUnit("player") or 0) or 0)
    Core:UpdateState("InMythicPlus", activeMapID > 0)
    Core:UpdateState("IsInParty", IsInGroup() and not IsInRaid())
    Core:UpdateState("IsInRaid", IsInRaid() and true or false)
end

local function updateCombatState()
    Core:UpdateState("InCombat", UnitAffectingCombat("player") and true or false)
end

local function updateStatState()
    Core:UpdateState("PStat_Str", select(2, UnitStat("player", 1)) or 0)
    Core:UpdateState("PStat_Agi", select(2, UnitStat("player", 2)) or 0)
    Core:UpdateState("PStat_Sta", select(2, UnitStat("player", 3)) or 0)
    Core:UpdateState("PStat_Int", select(2, UnitStat("player", 4)) or 0)
    Core:UpdateState("PStat_Crit", GetCritChance() or 0)
    Core:UpdateState("PStat_Haste", GetHaste() or 0)
    Core:UpdateState("PStat_Mastery", GetMasteryEffect and (GetMasteryEffect() or 0) or 0)
    Core:UpdateState("PStat_Versa", GetCombatRatingBonus and (GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE or 29) or 0) or 0)
    Core:UpdateState("PStat_Leech", GetLifesteal and (GetLifesteal() or 0) or 0)
    Core:UpdateState("PStat_Avoidance", GetAvoidance and (GetAvoidance() or 0) or 0)
    Core:UpdateState("PStat_Speed", GetUnitSpeed("player") or 0)
    Core:UpdateState("PStat_Armor", select(2, UnitArmor("player")) or 0)
    Core:UpdateState("PStat_Dodge", GetDodgeChance and (GetDodgeChance() or 0) or 0)
    Core:UpdateState("PStat_Parry", GetParryChance and (GetParryChance() or 0) or 0)
    Core:UpdateState("PStat_Block", GetBlockChance and (GetBlockChance() or 0) or 0)
    Core:UpdateState("PStat_MaxHealth", UnitHealthMax("player") or 0)
    Core:UpdateState("PStat_Movement", GetUnitSpeed("player") or 0)

    local _, equippedItemLevel = GetAverageItemLevel()
    Core:UpdateState("PStat_EquippedItemLevel", equippedItemLevel or 0)
end

local function updateAllState()
    updateIdentityState()
    updateEnvironmentState()
    updateCombatState()
    updateStatState()
end

Core:RegisterEvent("PLAYER_ENTERING_WORLD", "RRT_MYTHIC_STATE", updateAllState)
Core:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "RRT_MYTHIC_STATE", updateAllState)
Core:RegisterEvent("GROUP_ROSTER_UPDATE", "RRT_MYTHIC_STATE", updateAllState)
Core:RegisterEvent("ZONE_CHANGED_NEW_AREA", "RRT_MYTHIC_STATE", updateAllState)
Core:RegisterEvent("PLAYER_REGEN_DISABLED", "RRT_MYTHIC_STATE", updateCombatState)
Core:RegisterEvent("PLAYER_REGEN_ENABLED", "RRT_MYTHIC_STATE", updateCombatState)
Core:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "RRT_MYTHIC_STATE", updateStatState)
Core:RegisterEvent("UNIT_STATS", "RRT_MYTHIC_STATE", function(_, unit)
    if unit == "player" then
        updateStatState()
    end
end)
Core:RegisterEvent("CHALLENGE_MODE_START", "RRT_MYTHIC_STATE", updateEnvironmentState)
Core:RegisterEvent("CHALLENGE_MODE_COMPLETED", "RRT_MYTHIC_STATE", updateEnvironmentState)
Core:RegisterEvent("CHALLENGE_MODE_RESET", "RRT_MYTHIC_STATE", updateEnvironmentState)
Core:RegisterEvent("ENCOUNTER_START", "RRT_MYTHIC_STATE", function(_, encounterID)
    Core:UpdateState("IsBossEncounter", true)
    Core:UpdateState("EncounterID", tonumber(encounterID) or 0)
end)
Core:RegisterEvent("ENCOUNTER_END", "RRT_MYTHIC_STATE", function()
    Core:UpdateState("IsBossEncounter", false)
    Core:UpdateState("EncounterID", 0)
end)

C_Timer.After(0, updateAllState)
