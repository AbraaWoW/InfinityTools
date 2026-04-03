---@diagnostic disable: undefined-global

InfinityBoss.Modules = InfinityBoss.Modules or {}
InfinityBoss.Modules.Boss = InfinityBoss.Modules.Boss or {}

local BossConfig = InfinityBoss.Modules.Boss
InfinityBoss.BossConfig = BossConfig

local DB_VERSION = 3

local SLOT_ORDER = {
    "raid_tank",
    "raid_dps",
    "raid_heal",
    "mplus_tank",
    "mplus_dps",
    "mplus_heal",
}

local SLOT_META = {
    raid_tank =  { scene = "raid",  role = "tank", label = "Raid Tank", short = "RaidTank" },
    raid_dps =   { scene = "raid",  role = "dps",  label = "Raid DPS",  short = "RaidDps" },
    raid_heal =  { scene = "raid",  role = "heal", label = "Raid Healer", short = "RaidHealer" },
    mplus_tank = { scene = "mplus", role = "tank", label = "M+ Tank", short = "MplusTank" },
    mplus_dps =  { scene = "mplus", role = "dps",  label = "M+ DPS",  short = "MplusDps" },
    mplus_heal = { scene = "mplus", role = "heal", label = "M+ Healer", short = "MplusHealer" },
}

local HIDDEN_AUTHOR_KEYS = {
    A = true,
    B = true,
    C = true,
}

local _sceneIndexCache = nil
local _sceneIndexSource = nil

local function DeepCopy(v)
    if type(v) ~= "table" then
        return v
    end
    local out = {}
    for k, x in pairs(v) do
        out[k] = DeepCopy(x)
    end
    return out
end

local function WipeTable(t)
    if type(t) ~= "table" then
        return
    end
    if wipe then
        wipe(t)
        return
    end
    for k in pairs(t) do
        t[k] = nil
    end
end

local function NormalizeRoleKey(role)
    local v = tostring(role or ""):lower()
    if v == "tank" then return "tank" end
    if v == "heal" or v == "healer" then return "heal" end
    if v == "dps" or v == "damage" or v == "damager" then return "dps" end
    return "dps"
end

local function NormalizeSceneKey(scene)
    local v = tostring(scene or ""):lower()
    if v == "raid" then
        return "raid"
    end
    return "mplus"
end

local function NormalizeSlotKey(slotKey)
    local key = tostring(slotKey or ""):lower()
    if SLOT_META[key] then
        return key
    end
    local compact = key:gsub("[%s%-_]+", "")
    for candidate, meta in pairs(SLOT_META) do
        local cmp = candidate:gsub("[%s%-_]+", "")
        if compact == cmp or compact == tostring(meta.short or ""):lower() then
            return candidate
        end
    end
    return nil
end

local function EnsureBossSceneOptions()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    local g = InfinityBossDB.ui.general
    if g.bossAlertsEnabledMplus == nil then
        g.bossAlertsEnabledMplus = true
    else
        g.bossAlertsEnabledMplus = (g.bossAlertsEnabledMplus == true)
    end
    if g.bossAlertsEnabledRaid == nil then
        g.bossAlertsEnabledRaid = true
    else
        g.bossAlertsEnabledRaid = (g.bossAlertsEnabledRaid == true)
    end
    return g
end

local function GetPresetRoot()
    local root = _G.InfinityBoss_AUTHOR_PRESETS
    if type(root) ~= "table" or type(root.slots) ~= "table" then
        return { slots = {} }
    end
    return root
end

local function GetFirstAuthorKey(slotKey)
    slotKey = NormalizeSlotKey(slotKey) or slotKey
    local slot = GetPresetRoot().slots[slotKey]
    if type(slot) ~= "table" then
        return nil
    end
    local keys = {}
    for key in pairs(slot) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys[1]
end

local function GetDefaultAuthorKey(slotKey)
    slotKey = NormalizeSlotKey(slotKey) or slotKey
    local slot = GetPresetRoot().slots[slotKey]
    if type(slot) == "table" and type(slot.PresetConfig) == "table" then
        return "PresetConfig"
    end
    return GetFirstAuthorKey(slotKey)
end

local function GetEventScene(eventID)
    local data = _G.InfinityBoss_ENCOUNTER_DATA
    if _sceneIndexCache and _sceneIndexSource == data then
        return _sceneIndexCache[tonumber(eventID)]
    end
    local out = {}
    if type(data) == "table" and type(data.maps) == "table" then
        for _, mapRow in pairs(data.maps) do
            if type(mapRow) == "table" and type(mapRow.bosses) == "table" then
                local cat = tostring(mapRow.category or "")
                local itype = tonumber(mapRow.instanceType)
                local scene = ((itype == 2) or cat:find("Raid") ~= nil) and "raid" or "mplus"
                for _, bossRow in pairs(mapRow.bosses) do
                    if type(bossRow) == "table" and type(bossRow.events) == "table" then
                        for rawEventID in pairs(bossRow.events) do
                            local eid = tonumber(rawEventID)
                            if eid then
                                out[eid] = scene
                            end
                        end
                    end
                end
            end
        end
    end
    _sceneIndexCache = out
    _sceneIndexSource = data
    return out[tonumber(eventID)]
end

local function GetCurrentRoleKey()
    local state = InfinityTools and InfinityTools.State
    return NormalizeRoleKey(state and state.RoleKey)
end

local function GetFactoryDefaultsRoot()
    local api = _G.InfinityBossData
    if type(api) == "table" and type(api.GetFactoryEventDefaults) == "function" then
        return api.GetFactoryEventDefaults()
    end
    return {}
end

local function GetFactoryEvent(eventID)
    local api = _G.InfinityBossData
    if type(api) == "table" and type(api.GetFactoryEventDefaults) == "function" then
        return api.GetFactoryEventDefaults(eventID)
    end
    local root = GetFactoryDefaultsRoot()
    return root[tonumber(eventID)]
end

local function TouchLegacyRoot(eventID)
    local api = _G.InfinityBossData
    if type(api) == "table" and type(api.TouchEventConfig) == "function" then
        api.TouchEventConfig(eventID)
    end
end

local function MergeOverride(dst, src)
    if type(src) ~= "table" then
        return dst
    end
    if type(dst) ~= "table" then
        dst = {}
    end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            MergeOverride(dst[k], v)
        else
            dst[k] = DeepCopy(v)
        end
    end
    return dst
end

local function BuildOverrideDelta(current, defaults)
    local currentType = type(current)
    local defaultType = type(defaults)

    if currentType ~= "table" then
        if defaults == nil or current ~= defaults then
            return current
        end
        return nil
    end

    local out = {}
    local hasAny = false
    for k, v in pairs(current) do
        local delta = BuildOverrideDelta(v, defaultType == "table" and defaults[k] or nil)
        if delta ~= nil then
            out[k] = delta
            hasAny = true
        end
    end

    if hasAny then
        return out
    end
    return nil
end

local function NormalizeStandaloneTriggerStorage(trigger)
    if type(trigger) ~= "table" then
        return nil
    end
    if type(trigger.label) == "string" and trigger.label == "" then
        trigger.label = nil
    end
    if type(trigger.customLSM) == "string" and trigger.customLSM == "" then
        trigger.customLSM = nil
    end
    if type(trigger.customPath) == "string" and trigger.customPath == "" then
        trigger.customPath = nil
    end
    if next(trigger) == nil then
        return nil
    end
    return trigger
end

local StripLegacyRoleFields

local function NormalizeEventOverrideRowForStorage(row)
    if type(row) ~= "table" then
        return nil
    end
    if type(row.centralText) == "string" and row.centralText == "" then
        row.centralText = nil
    end
    if type(row.preAlertText) == "string" and row.preAlertText == "" then
        row.preAlertText = nil
    end
    if type(row.timerBarRenameText) == "string" and row.timerBarRenameText == "" then
        row.timerBarRenameText = nil
    end
    if type(row.color) == "table" then
        if type(row.color.scheme) == "string" and row.color.scheme == "" then
            row.color.scheme = nil
        end
        if next(row.color) == nil then
            row.color = nil
        end
    end
    if type(row.triggers) == "table" then
        local normalized = {}
        for triggerKey, triggerCfg in pairs(row.triggers) do
            local kept = NormalizeStandaloneTriggerStorage(type(triggerCfg) == "table" and DeepCopy(triggerCfg) or nil)
            if kept then
                normalized[triggerKey] = kept
            end
        end
        row.triggers = next(normalized) and normalized or nil
    end
    if type(row.rules) == "table" then
        local cw = row.rules.castWindow
        if type(cw) == "table" and next(cw) == nil then
            row.rules.castWindow = nil
        end
        if next(row.rules) == nil then
            row.rules = nil
        end
    end
    if next(row) == nil then
        return nil
    end
    return row
end

local function IsLegacyRoleSnapshotRow(row)
    if type(row) ~= "table" then
        return false
    end
    local hasLegacyRole = row.enabledRoles ~= nil
        or row.roleTankEnabled ~= nil
        or row.roleHealEnabled ~= nil
        or row.roleDpsEnabled ~= nil
    if not hasLegacyRole then
        return false
    end
    if type(row.centralText) == "string" and row.centralText ~= "" then
        return false
    end
    if type(row.preAlertText) == "string" and row.preAlertText ~= "" then
        return false
    end
    if type(row.timerBarRenameText) == "string" and row.timerBarRenameText ~= "" then
        return false
    end
    if type(row.color) == "table" and next(row.color) ~= nil then
        return false
    end
    if type(row.rules) == "table" and next(row.rules) ~= nil then
        return false
    end
    if type(row.triggers) == "table" then
        for _, triggerCfg in pairs(row.triggers) do
            if type(triggerCfg) == "table" then
                if type(triggerCfg.label) == "string" and triggerCfg.label ~= "" then
                    return false
                end
                if type(triggerCfg.customLSM) == "string" and triggerCfg.customLSM ~= "" then
                    return false
                end
                if type(triggerCfg.customPath) == "string" and triggerCfg.customPath ~= "" then
                    return false
                end
            end
        end
    end
    return true
end

local function BuildDefaultSelection()
    local out = {}
    for _, slotKey in ipairs(SLOT_ORDER) do
        out[slotKey] = GetDefaultAuthorKey(slotKey)
    end
    return out
end

local function ResolveDefaultEditSlot(scene)
    local role = GetCurrentRoleKey()
    return NormalizeSlotKey(string.format("%s_%s", NormalizeSceneKey(scene), role))
end

local GetPresetEvents
local ResolveSlotKeyForEvent
local BuildBaseResolvedForSlotAuthor
local CompactOverrideForSlotAuthor

local function EnsureDB()
    InfinityBossDataDB = InfinityBossDataDB or {}
    InfinityBossDataDB.bossConfig = InfinityBossDataDB.bossConfig or {}
    local db = InfinityBossDataDB.bossConfig
    db.slotSelection = type(db.slotSelection) == "table" and db.slotSelection or {}
    db.userOverrides = type(db.userOverrides) == "table" and db.userOverrides or {}
    local oldVersion = tonumber(db.version) or 0
    for _, slotKey in ipairs(SLOT_ORDER) do
        local defaultAuthor = GetDefaultAuthorKey(slotKey)
        local currentAuthor = db.slotSelection[slotKey]
        local userSlot = type(db.userOverrides[slotKey]) == "table" and db.userOverrides[slotKey] or nil
        local hasUserAuthor = type(userSlot) == "table" and type(currentAuthor) == "string"
            and currentAuthor ~= "" and type(userSlot[currentAuthor]) == "table"
        if type(currentAuthor) ~= "string" or currentAuthor == "" then
            db.slotSelection[slotKey] = defaultAuthor
        elseif currentAuthor and not GetPresetEvents(slotKey, currentAuthor) and not hasUserAuthor and defaultAuthor then
            db.slotSelection[slotKey] = defaultAuthor
        end
        db.userOverrides[slotKey] = type(db.userOverrides[slotKey]) == "table" and db.userOverrides[slotKey] or {}
    end
    if oldVersion < DB_VERSION then
        for _, slotKey in ipairs(SLOT_ORDER) do
            local slotRoot = db.userOverrides[slotKey]
            if type(slotRoot) == "table" then
                for authorKey, authorRow in pairs(slotRoot) do
                    local events = type(authorRow) == "table" and authorRow.events or nil
                    if type(events) == "table" then
                        local toCheck = {}
                        for rawEventID in pairs(events) do
                            toCheck[#toCheck + 1] = rawEventID
                        end
                        for i = 1, #toCheck do
                            local rawEventID = toCheck[i]
                            local eid = tonumber(rawEventID)
                            local compacted = CompactOverrideForSlotAuthor(eid, events[rawEventID], slotKey, authorKey)
                            if type(compacted) == "table" then
                                events[eid] = compacted
                            else
                                events[rawEventID] = nil
                            end
                        end
                    end
                end
            end
        end
    end
    db.version = DB_VERSION
    db.editSlots = nil
    return db
end

local function EnsureAuthorOverrideRoot(slotKey, authorKey)
    local db = EnsureDB()
    slotKey = NormalizeSlotKey(slotKey) or slotKey
    authorKey = tostring(authorKey or db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey) or "")
    db.userOverrides[slotKey] = type(db.userOverrides[slotKey]) == "table" and db.userOverrides[slotKey] or {}
    db.userOverrides[slotKey][authorKey] = type(db.userOverrides[slotKey][authorKey]) == "table" and db.userOverrides[slotKey][authorKey] or {}
    db.userOverrides[slotKey][authorKey].events = type(db.userOverrides[slotKey][authorKey].events) == "table" and db.userOverrides[slotKey][authorKey].events or {}
    return db.userOverrides[slotKey][authorKey].events
end

local function GetAuthorOverrideRoot(slotKey, authorKey)
    local db = EnsureDB()
    slotKey = NormalizeSlotKey(slotKey) or slotKey
    authorKey = tostring(authorKey or db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey) or "")
    local slot = db.userOverrides[slotKey]
    local author = type(slot) == "table" and slot[authorKey] or nil
    local events = type(author) == "table" and author.events or nil
    return type(events) == "table" and events or nil
end

local function NormalizeExportEventRow(row)
    if type(row) ~= "table" then
        return nil
    end
    local normalized = NormalizeEventOverrideRowForStorage(DeepCopy(row))
    StripLegacyRoleFields(normalized)
    return normalized
end

GetPresetEvents = function(slotKey, authorKey)
    local presets = GetPresetRoot().slots
    slotKey = NormalizeSlotKey(slotKey) or slotKey
    local slot = type(presets) == "table" and presets[slotKey] or nil
    local preset = type(slot) == "table" and slot[tostring(authorKey or "")] or nil
    local events = type(preset) == "table" and preset.events or nil
    return type(events) == "table" and events or nil
end

StripLegacyRoleFields = function(row)
    if type(row) ~= "table" then
        return row
    end
    row.enabledRoles = nil
    row.roleTankEnabled = nil
    row.roleHealEnabled = nil
    row.roleDpsEnabled = nil
    return row
end

BuildBaseResolvedForSlotAuthor = function(eventID, slotKey, authorKey)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    slotKey = ResolveSlotKeyForEvent(eid, slotKey)
    local defaults = GetFactoryEvent(eid)
    local presetEvents = GetPresetEvents(slotKey, authorKey)
    local preset = type(presetEvents) == "table" and presetEvents[eid] or nil
    StripLegacyRoleFields(preset)
    if type(defaults) ~= "table" and type(preset) ~= "table" then
        return nil
    end
    local base = DeepCopy(defaults or {})
    MergeOverride(base, preset)
    StripLegacyRoleFields(base)
    return base
end

CompactOverrideForSlotAuthor = function(eventID, row, slotKey, authorKey)
    local eid = tonumber(eventID)
    if not eid or type(row) ~= "table" then
        return nil
    end
    if IsLegacyRoleSnapshotRow(row) then
        return nil
    end
    local normalized = NormalizeEventOverrideRowForStorage(DeepCopy(row))
    StripLegacyRoleFields(normalized)
    if type(normalized) ~= "table" then
        return nil
    end
    local base = BuildBaseResolvedForSlotAuthor(eid, slotKey, authorKey)
    local compacted = BuildOverrideDelta(normalized, base or {})
    if type(compacted) == "table" then
        StripLegacyRoleFields(compacted)
        return compacted
    end
    return nil
end

ResolveSlotKeyForEvent = function(eventID, slotKey)
    local normalized = NormalizeSlotKey(slotKey)
    if normalized then
        return normalized
    end
    local scene = GetEventScene(eventID)
    scene = NormalizeSceneKey(scene)
    return ResolveDefaultEditSlot(scene)
end

local function MigrateLegacyOnce()
    local db = EnsureDB()
    if db.legacyMigrated == true then
        return
    end
    InfinityBossDataDB = InfinityBossDataDB or {}
    local legacyRoot = type(InfinityBossDataDB.events) == "table" and InfinityBossDataDB.events or nil
    if type(legacyRoot) ~= "table" or next(legacyRoot) == nil then
        db.legacyMigrated = true
        return
    end
    local role = GetCurrentRoleKey()
    for rawEventID, row in pairs(legacyRoot) do
        local eventID = tonumber(rawEventID)
        local scene = eventID and GetEventScene(eventID) or nil
        if eventID and scene and type(row) == "table" then
            local slotKey = NormalizeSlotKey(string.format("%s_%s", scene, role))
            if slotKey then
                local authorKey = db.slotSelection[slotKey] or GetFirstAuthorKey(slotKey)
                local root = EnsureAuthorOverrideRoot(slotKey, authorKey)
                root[eventID] = CompactOverrideForSlotAuthor(eventID, row, slotKey, authorKey)
            end
        end
    end
    db.legacyMigrated = true
end

local function BuildResolvedForSlot(eventID, slotKey)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    slotKey = ResolveSlotKeyForEvent(eid, slotKey)
    local defaults = GetFactoryEvent(eid)
    local db = EnsureDB()
    local authorKey = db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey)
    local presetEvents = GetPresetEvents(slotKey, authorKey)
    local userEvents = GetAuthorOverrideRoot(slotKey, authorKey)
    local preset = type(presetEvents) == "table" and presetEvents[eid] or nil
    local user = type(userEvents) == "table" and userEvents[eid] or nil
    StripLegacyRoleFields(preset)
    StripLegacyRoleFields(user)
    if type(defaults) ~= "table" and type(preset) ~= "table" and type(user) ~= "table" then
        return nil
    end
    local resolved = DeepCopy(defaults or {})
    MergeOverride(resolved, preset)
    MergeOverride(resolved, user)
    StripLegacyRoleFields(resolved)
    return resolved
end

local function BuildPublishedRootForRole(roleKey)
    local root = {}
    local db = EnsureDB()
    local role = NormalizeRoleKey(roleKey)
    local factory = GetFactoryDefaultsRoot()
    for _, scene in ipairs({ "raid", "mplus" }) do
        local seen = {}
        local slotKey = NormalizeSlotKey(string.format("%s_%s", scene, role))
        local authorKey = db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey)
        local presetEvents = GetPresetEvents(slotKey, authorKey)
        local userEvents = GetAuthorOverrideRoot(slotKey, authorKey)
        for rawEventID in pairs(factory) do
            local eid = tonumber(rawEventID)
            if eid and GetEventScene(eid) == scene then
                seen[eid] = true
            end
        end
        if type(presetEvents) == "table" then
            for rawEventID in pairs(presetEvents) do
                local eid = tonumber(rawEventID)
                if eid and GetEventScene(eid) == scene then
                    seen[eid] = true
                end
            end
        end
        if type(userEvents) == "table" then
            for rawEventID in pairs(userEvents) do
                local eid = tonumber(rawEventID)
                if eid and GetEventScene(eid) == scene then
                    seen[eid] = true
                end
            end
        end
        for eid in pairs(seen) do
            if GetEventScene(eid) == scene then
                local resolved = BuildResolvedForSlot(eid, slotKey)
                if type(resolved) == "table" then
                    root[eid] = DeepCopy(resolved)
                end
            end
        end
    end
    return root
end

function BossConfig:Ensure()
    EnsureDB()
    MigrateLegacyOnce()
    return InfinityBossDataDB.bossConfig
end

function BossConfig:GetSlotKeys(scene)
    local out = {}
    local sceneKey = scene and NormalizeSceneKey(scene) or nil
    for _, slotKey in ipairs(SLOT_ORDER) do
        if not sceneKey or SLOT_META[slotKey].scene == sceneKey then
            out[#out + 1] = slotKey
        end
    end
    return out
end

function BossConfig:GetSlotLabel(slotKey)
    local meta = SLOT_META[NormalizeSlotKey(slotKey) or ""]
    return meta and meta.label or tostring(slotKey or "")
end

function BossConfig:GetSlotItems(scene)
    local out = {}
    for _, slotKey in ipairs(self:GetSlotKeys(scene)) do
        out[#out + 1] = { self:GetSlotLabel(slotKey), slotKey }
    end
    return out
end

function BossConfig:GetAuthorItems(slotKey)
    local db = self:Ensure()
    local normalized = NormalizeSlotKey(slotKey)
    local slot = GetPresetRoot().slots[normalized] or {}
    local seen = {}
    local items = {}
    for key, preset in pairs(slot) do
        if not HIDDEN_AUTHOR_KEYS[tostring(key or "")] then
            seen[key] = true
            items[#items + 1] = { tostring((type(preset) == "table" and (preset.name or preset.author)) or key), key }
        end
    end
    local userSlot = type(db.userOverrides) == "table" and db.userOverrides[normalized] or nil
    if type(userSlot) == "table" then
        for key, authorRow in pairs(userSlot) do
            local skey = tostring(key or "")
            if skey ~= "" and not seen[skey] and not HIDDEN_AUTHOR_KEYS[skey] then
                local hasEvents = type(authorRow) == "table" and type(authorRow.events) == "table" and next(authorRow.events) ~= nil
                if hasEvents then
                    seen[skey] = true
                    items[#items + 1] = { skey, skey }
                end
            end
        end
    end
    local selected = db.slotSelection[normalized]
    if selected and not seen[selected] and not HIDDEN_AUTHOR_KEYS[tostring(selected or "")] then
        items[#items + 1] = { tostring(selected), selected }
    end
    table.sort(items, function(a, b)
        return tostring(a[1]) < tostring(b[1])
    end)
    return items
end

function BossConfig:GetSelectedAuthor(slotKey)
    local db = self:Ensure()
    slotKey = NormalizeSlotKey(slotKey)
    return slotKey and (db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey)) or nil
end

function BossConfig:SetSelectedAuthor(slotKey, authorKey)
    local db = self:Ensure()
    slotKey = NormalizeSlotKey(slotKey)
    if not slotKey then
        return false, "invalid slot"
    end
    authorKey = tostring(authorKey or "")
    if authorKey == "" then
        return false, "invalid author"
    end
    db.slotSelection[slotKey] = authorKey
    EnsureAuthorOverrideRoot(slotKey, authorKey)
    self:PublishRuntimeSelection()
    return true
end

function BossConfig:GetOverrideRootForEvent(eventID, createIfMissing)
    local slotKey = ResolveSlotKeyForEvent(eventID)
    local authorKey = self:GetSelectedAuthor(slotKey)
    if createIfMissing == true then
        return EnsureAuthorOverrideRoot(slotKey, authorKey), slotKey, authorKey
    end
    return GetAuthorOverrideRoot(slotKey, authorKey), slotKey, authorKey
end

function BossConfig:GetResolvedEventConfig(eventID, slotKey)
    self:Ensure()
    return BuildResolvedForSlot(eventID, slotKey)
end

function BossConfig:CompactEventOverride(eventID, slotKey)
    local root, resolvedSlotKey, authorKey = self:GetOverrideRootForEvent(eventID, true)
    local eid = tonumber(eventID)
    if not eid then
        return nil
    end
    local row = root[eid]
    if type(row) ~= "table" then
        root[eid] = nil
        return nil
    end
    StripLegacyRoleFields(row)
    local compacted = CompactOverrideForSlotAuthor(eid, row, resolvedSlotKey or slotKey, authorKey)
    if type(compacted) == "table" then
        StripLegacyRoleFields(compacted)
        root[eid] = compacted
    else
        root[eid] = nil
    end
    return root[eid]
end

function BossConfig:GetRuntimeSlotForScene(scene)
    local role = GetCurrentRoleKey()
    return NormalizeSlotKey(string.format("%s_%s", NormalizeSceneKey(scene), role))
end

function BossConfig:IsSceneEnabled(scene)
    local g = EnsureBossSceneOptions()
    local sceneKey = NormalizeSceneKey(scene)
    if sceneKey == "raid" then
        return g.bossAlertsEnabledRaid ~= false
    end
    return g.bossAlertsEnabledMplus ~= false
end

function BossConfig:IsCurrentSceneEnabled()
    local _, instanceType = GetInstanceInfo()
    if instanceType == "raid" then
        return self:IsSceneEnabled("raid"), "raid"
    end
    if instanceType == "party" then
        return self:IsSceneEnabled("mplus"), "mplus"
    end
    return true, nil
end

function BossConfig:PublishRuntimeSelection(roleKey)
    self:Ensure()
    InfinityBossDataDB = InfinityBossDataDB or {}
    InfinityBossDataDB.events = InfinityBossDataDB.events or {}
    local legacyRoot = InfinityBossDataDB.events
    WipeTable(legacyRoot)
    local published = BuildPublishedRootForRole(roleKey or GetCurrentRoleKey())
    for eventID, row in pairs(published) do
        legacyRoot[eventID] = row
    end
    TouchLegacyRoot()
    return true
end

function BossConfig:ApplyPersistedChange(eventID)
    self:PublishRuntimeSelection()
    local encounterID = tonumber(eventID) and nil
    if eventID ~= nil and InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine and InfinityBoss.Voice.Engine.ApplyEventOverridesToAPI then
        InfinityBoss.Voice.Engine:ApplyEventOverridesToAPI()
    end
    return encounterID
end

function BossConfig:ExportScene(scene, includeSlots)
    local sceneKey = NormalizeSceneKey(scene)
    local db = self:Ensure()
    local out = {
        selections = {},
        slots = {},
    }
    local include = type(includeSlots) == "table" and includeSlots or nil
    for _, slotKey in ipairs(self:GetSlotKeys(sceneKey)) do
        if not include or include[slotKey] == true then
            local authorKey = db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey)
            local events = {}
            local seen = {}
            local defaultsRoot = GetFactoryDefaultsRoot()
            local presetEvents = GetPresetEvents(slotKey, authorKey)
            local userEvents = GetAuthorOverrideRoot(slotKey, authorKey)
            for rawEventID in pairs(defaultsRoot) do
                local eid = tonumber(rawEventID)
                if eid and GetEventScene(eid) == sceneKey then
                    seen[eid] = true
                end
            end
            if type(presetEvents) == "table" then
                for rawEventID in pairs(presetEvents) do
                    local eid = tonumber(rawEventID)
                    if eid and GetEventScene(eid) == sceneKey then
                        seen[eid] = true
                    end
                end
            end
            if type(userEvents) == "table" then
                for rawEventID in pairs(userEvents) do
                    local eid = tonumber(rawEventID)
                    if eid and GetEventScene(eid) == sceneKey then
                        seen[eid] = true
                    end
                end
            end
            for eid in pairs(seen) do
                local resolved = NormalizeExportEventRow(BuildResolvedForSlot(eid, slotKey))
                local defaults = GetFactoryEvent(eid)
                local delta = BuildOverrideDelta(resolved, defaults or {})
                if delta ~= nil then
                    events[eid] = delta
                end
            end
            out.selections[slotKey] = authorKey
            out.slots[slotKey] = {
                author = authorKey,
                events = events,
            }
        end
    end
    return out
end

function BossConfig:ImportScene(scene, sceneData, options)
    if type(sceneData) ~= "table" then
        return false, "invalid scene data"
    end
    options = type(options) == "table" and options or {}
    local sceneKey = NormalizeSceneKey(scene)
    local db = self:Ensure()
    local selections = type(sceneData.selections) == "table" and sceneData.selections or {}
    local slots = type(sceneData.slots) == "table" and sceneData.slots or {}
    local importedAuthorKey = tostring(options.authorKey or options.authorName or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local targetSlots = {}
    for _, slotKey in ipairs(self:GetSlotKeys(sceneKey)) do
        if selections[slotKey] ~= nil or slots[slotKey] ~= nil then
            targetSlots[#targetSlots + 1] = slotKey
        end
    end
    if #targetSlots == 0 then
        return false, "no slot data"
    end
    for _, slotKey in ipairs(targetSlots) do
        local authorKey = importedAuthorKey ~= "" and importedAuthorKey
            or tostring(selections[slotKey] or (type(slots[slotKey]) == "table" and slots[slotKey].author) or db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey) or "")
        db.slotSelection[slotKey] = authorKey
        local root = EnsureAuthorOverrideRoot(slotKey, authorKey)
        WipeTable(root)
        local srcEvents = type(slots[slotKey]) == "table" and type(slots[slotKey].events) == "table" and slots[slotKey].events or {}
        for eventID, row in pairs(srcEvents) do
            local eid = tonumber(eventID)
            if eid and GetEventScene(eid) == sceneKey then
                local compacted = CompactOverrideForSlotAuthor(eid, row, slotKey, authorKey)
                if type(compacted) == "table" then
                    root[eid] = compacted
                end
            end
        end
    end
    self:PublishRuntimeSelection()
    return true
end

function BossConfig:GetSelectionSummary()
    local db = self:Ensure()
    local out = {}
    for _, slotKey in ipairs(SLOT_ORDER) do
        out[#out + 1] = {
            slotKey = slotKey,
            label = self:GetSlotLabel(slotKey),
            author = db.slotSelection[slotKey] or GetDefaultAuthorKey(slotKey),
        }
    end
    return out
end

if InfinityTools and InfinityTools.WatchState then
    InfinityTools:WatchState("RoleKey", "InfinityBoss.BossConfig.RolePublish", function()
        BossConfig:PublishRuntimeSelection()
    end)
end

if InfinityTools and InfinityTools.RegisterEvent then
    InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", "InfinityBoss.BossConfig.Publish", function()
        BossConfig:PublishRuntimeSelection()
    end)
    InfinityTools:RegisterEvent("ZONE_CHANGED_NEW_AREA", "InfinityBoss.BossConfig.PublishZone", function()
        BossConfig:PublishRuntimeSelection()
    end)
    InfinityTools:RegisterEvent("ADDON_LOADED", "InfinityBoss.BossConfig.Init", function(_, addonName)
        if tostring(addonName or ""):lower() ~= "infinitytools" and tostring(addonName or ""):lower() ~= "infinityboss" then
            return
        end
        BossConfig:Ensure()
        BossConfig:PublishRuntimeSelection()
    end)
end
