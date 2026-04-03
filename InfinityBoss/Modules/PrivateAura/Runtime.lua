---@diagnostic disable: undefined-global

InfinityBoss.PrivateAura = InfinityBoss.PrivateAura or {}
local PrivateAura = InfinityBoss.PrivateAura

local InfinityTools = _G.InfinityTools
if not InfinityTools then
    return
end

local MODULE_KEY = "InfinityBoss.PrivateAuraOptions"
local MODULE_DEFAULTS = {
    entries = {},
}

local ENTRY_DEFAULTS = {
    enabled = false,
    sourceType = "pack",
    label = "",
    customLSM = "",
    customPath = "",
}

local activeSoundIDs = {}
local currentEncounterID = nil

local function NormalizeSourceType(value)
    local sourceType = tostring(value or "pack"):lower()
    if sourceType ~= "lsm" and sourceType ~= "file" then
        sourceType = "pack"
    end
    return sourceType
end

local function EnsureConfigShape(cfg)
    cfg = type(cfg) == "table" and cfg or {}
    if cfg.enabled == nil then
        cfg.enabled = ENTRY_DEFAULTS.enabled
    else
        cfg.enabled = cfg.enabled == true
    end
    cfg.sourceType = NormalizeSourceType(cfg.sourceType or ENTRY_DEFAULTS.sourceType)
    if type(cfg.label) ~= "string" then
        cfg.label = ENTRY_DEFAULTS.label
    end
    if type(cfg.customLSM) ~= "string" then
        cfg.customLSM = ENTRY_DEFAULTS.customLSM
    end
    if type(cfg.customPath) ~= "string" then
        cfg.customPath = ENTRY_DEFAULTS.customPath
    end
    return cfg
end

local function GetSettingsRoot()
    local root = InfinityTools:GetModuleDB(MODULE_KEY, MODULE_DEFAULTS)
    root.entries = type(root.entries) == "table" and root.entries or {}
    return root
end

local function GetConfigByKey(key, createIfMissing)
    if type(key) ~= "string" or key == "" then
        return nil
    end
    local root = GetSettingsRoot()
    local row = root.entries[key]
    if row == nil and createIfMissing then
        row = {}
        root.entries[key] = row
    end
    if row then
        return EnsureConfigShape(row)
    end
    return nil
end

local function ResolveSoundInfo(cfg)
    local engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    if not engine or type(engine.ResolveStandaloneSound) ~= "function" then
        return nil
    end
    return engine:ResolveStandaloneSound(cfg, { triggerIndex = 0 })
end

local function RemoveAllRegisteredSounds()
    if not (C_UnitAuras and C_UnitAuras.RemovePrivateAuraAppliedSound) then
        wipe(activeSoundIDs)
        return
    end
    for i = 1, #activeSoundIDs do
        local soundID = activeSoundIDs[i]
        if soundID then
            pcall(C_UnitAuras.RemovePrivateAuraAppliedSound, soundID)
        end
    end
    wipe(activeSoundIDs)
end

local function AddRegisteredSound(file, spellID, channel)
    if not (C_UnitAuras and C_UnitAuras.AddPrivateAuraAppliedSound) then
        return nil, "api unavailable"
    end
    if type(file) ~= "string" or file == "" then
        return nil, "empty file"
    end
    local payload = {
        unitToken = "player",
        spellID = tonumber(spellID),
        soundFileName = file,
        outputChannel = tostring(channel or "Master"),
    }
    local ok, soundID = pcall(C_UnitAuras.AddPrivateAuraAppliedSound, payload)
    if ok and soundID then
        activeSoundIDs[#activeSoundIDs + 1] = soundID
        return soundID
    end
    return nil, soundID
end

local function BuildRaidKey(encounterID, spellID)
    return "pa:raid:" .. tostring(encounterID) .. ":" .. tostring(spellID)
end

local function BuildMplusBossKey(dungeonName, bossName, spellID)
    return "pa:mplus:boss:" .. tostring(dungeonName or "unknown") .. ":" .. tostring(bossName or "unknown") .. ":" .. tostring(spellID)
end

local function CollectRaidRows(encounterID)
    local out = {}
    local row = PrivateAura:GetRaidBoss(encounterID)
    if type(row) ~= "table" or type(row.spells) ~= "table" then
        return out
    end
    for spellID, spellRow in pairs(row.spells) do
        local sid = tonumber(spellID)
        if sid and type(spellRow) == "table" then
            out[#out + 1] = {
                key = BuildRaidKey(encounterID, sid),
                spellID = sid,
            }
        end
    end
    table.sort(out, function(a, b) return (a.spellID or 0) < (b.spellID or 0) end)
    return out
end

local function CollectMplusRows()
    local out = {}
    local instanceName = GetInstanceInfo and select(1, GetInstanceInfo()) or nil
    if type(instanceName) ~= "string" or instanceName == "" then
        return out
    end
    local row = PrivateAura:GetMplusDungeon(instanceName)
    if type(row) ~= "table" or type(row.spells) ~= "table" then
        return out
    end
    for spellID, spellRow in pairs(row.spells) do
        local sid = tonumber(spellID)
        if sid and type(spellRow) == "table" then
            local bosses = type(spellRow.bosses) == "table" and spellRow.bosses or {}
            local chosenBoss = tostring(bosses[1] or "")
            out[#out + 1] = {
                key = BuildMplusBossKey(row.dungeon or instanceName, chosenBoss, sid),
                spellID = sid,
                dungeon = row.dungeon or instanceName,
                boss = chosenBoss,
                bosses = bosses,
            }
        end
    end
    table.sort(out, function(a, b) return (a.spellID or 0) < (b.spellID or 0) end)
    return out
end

local function ApplyRows(rows)
    RemoveAllRegisteredSounds()
    for i = 1, #rows do
        local row = rows[i]
        local cfg = GetConfigByKey(row.key, false)
        cfg = EnsureConfigShape(cfg)
        if cfg.enabled ~= false then
            local soundInfo = ResolveSoundInfo(cfg)
            if soundInfo and soundInfo.file and soundInfo.file ~= "" then
                AddRegisteredSound(soundInfo.file, row.spellID, soundInfo.channel)
            end
        end
    end
end

function PrivateAura:RefreshActiveRegistrations()
    local instanceType = GetInstanceInfo and select(2, GetInstanceInfo()) or nil
    if instanceType == "raid" and currentEncounterID then
        ApplyRows(CollectRaidRows(currentEncounterID))
        return
    end
    if instanceType == "party" then
        ApplyRows(CollectMplusRows())
        return
    end
    RemoveAllRegisteredSounds()
end

function PrivateAura:ClearActiveRegistrations()
    RemoveAllRegisteredSounds()
end

InfinityTools:RegisterEvent("ENCOUNTER_START", "InfinityBoss_PrivateAura_EncStart", function(_, encounterID)
    currentEncounterID = tonumber(encounterID)
    PrivateAura:RefreshActiveRegistrations()
end)

InfinityTools:RegisterEvent("ENCOUNTER_END", "InfinityBoss_PrivateAura_EncEnd", function()
    currentEncounterID = nil
    PrivateAura:RefreshActiveRegistrations()
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", "InfinityBoss_PrivateAura_PEW", function()
    PrivateAura:RefreshActiveRegistrations()
end)

InfinityTools:RegisterEvent("ZONE_CHANGED_NEW_AREA", "InfinityBoss_PrivateAura_Zone", function()
    PrivateAura:RefreshActiveRegistrations()
end)

InfinityTools:WatchState(MODULE_KEY .. ".DatabaseChanged", "InfinityBoss_PrivateAura_ConfigChanged", function()
    PrivateAura:RefreshActiveRegistrations()
end)
