local _, RRT_NS = ...

RRT = RRT or {}
RRT.MythicCore = RRT.MythicCore or {}

local function ensureTable(root, key)
    root[key] = root[key] or {}
    return root[key]
end

local function copyDefaults(target, defaults)
    if type(defaults) ~= "table" then
        return target
    end

    target = target or {}
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = copyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

local Core = _G.RRTMythicTools or {}
_G.RRTMythicTools = Core
RRT_NS.Mythic = Core

Core.name = "Infinity Mythic Core"
Core.VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("InfinityTools", "Version")) or "DEV-Build"
Core.GridEngineVersion = "1.0.0"
Core.L = Core.L or setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

local localization = {
    ["Chat Channel Bar"] = "Chat Channel Bar",
    ["Chat Bar"] = "Chat Bar",
    ["Chat Bar - Drag this frame to move"] = "Chat Bar - Drag this frame to move",
    ["Channel not found: "] = "Channel not found: ",
    ["Command failed: "] = "Command failed: ",
    ["Quick channel bar with customizable labels, colors, and commands."] = "Quick channel bar with customizable labels, colors, and commands.",
    ["Basic Settings"] = "Basic Settings",
    ["Lock Position"] = "Lock Position",
    ["Reset Position"] = "Reset Position",
    ["Font Size"] = "Font Size",
    ["Button Spacing"] = "Button Spacing",
    ["Button Size"] = "Button Size",
    ["Outline"] = "Outline",
    ["Anchor Target"] = "Anchor Target",
    ["None"] = "None",
    ["Channel Settings"] = "Channel Settings",
    ["World"] = "World",
    ["Color"] = "Color",
    ["Label"] = "Label",
    ["Command"] = "Command",
    ["W"] = "W",
    ["Say"] = "Say",
    ["S"] = "S",
    ["Yell"] = "Yell",
    ["Y"] = "Y",
    ["Party"] = "Party",
    ["P"] = "P",
    ["Guild"] = "Guild",
    ["G"] = "G",
    ["Instance"] = "Instance",
    ["I"] = "I",
    ["Raid"] = "Raid",
    ["R"] = "R",
    ["Roll"] = "Roll",
    ["Roll"] = "Roll",
    ["Ready"] = "Ready",
    ["RC"] = "RC",
    ["Pull"] = "Pull",
    ["Pull"] = "Pull",
    ["Custom 1"] = "Custom 1",
    ["Custom 2"] = "Custom 2",
    ["Custom 3"] = "Custom 3",
    ["C1"] = "C1",
    ["C2"] = "C2",
    ["C3"] = "C3",
    ["This Week's Mythic+ Info"] = "This Week's Mythic+ Info",
    ["Attach an info panel next to the PVE frame."] = "Attach an info panel next to the PVE frame.",
    ["Spells"] = "Spells",
    ["Keys"] = "Keys",
    ["Records"] = "Records",
    ["Great Vault This Week"] = "Great Vault This Week",
    ["This Week's Dungeon Details"] = "This Week's Dungeon Details",
    ["Enable Module"] = "Enable Module",
    ["Attach Side"] = "Attach Side",
    ["Left"] = "Left",
    ["Right"] = "Right",
    ["Horizontal Offset (X)"] = "Horizontal Offset (X)",
    ["Vertical Offset (Y)"] = "Vertical Offset (Y)",
    ["Preview Mode"] = "Preview Mode",
    ["Player Text Settings"] = "Player Text Settings",
    ["Party Name Settings"] = "Party Name Settings",
    ["Party Keystone Settings"] = "Party Keystone Settings",
    ["No Cache"] = "No Cache",
    ["Waiting for Sync"] = "Waiting for Sync",
    ["Hidden"] = "Hidden",
    ["No Keystone"] = "No Keystone",
    ["Party Member"] = "Party Member",
    ["Player"] = "Player",
    ["1. Combat Timer"] = "1. Combat Timer",
    ["Enable Timer"] = "Enable Timer",
    ["Reset on Boss"] = "Reset on Boss",
    ["Hide Out of Combat"] = "Hide Out of Combat",
    ["Pause Out of Combat"] = "Pause Out of Combat",
    ["Lock"] = "Lock",
    ["Prefix Text (Left)"] = "Prefix Text (Left)",
    ["Suffix Text (Right)"] = "Suffix Text (Right)",
    ["Font Style Settings"] = "Font Style Settings",
    ["2. Battle Resurrection"] = "2. Battle Resurrection",
    ["Enable Brez Tracking"] = "Enable Brez Tracking",
    ["Brez Timer Text (Center)"] = "Brez Timer Text (Center)",
    ["Brez Charges Text (Bottom Right)"] = "Brez Charges Text (Bottom Right)",
    ["Brez Icon Size/Position"] = "Brez Icon Size/Position",
    ["3. Mythic+ Keystone"] = "3. Mythic+ Keystone",
    ["Auto Insert Keystone When Panel Opens"] = "Auto Insert Keystone When Panel Opens",
    ["Party Keystones"] = "Party Keystones",
}

for key, value in pairs(localization) do
    Core.L[key] = value
end

do
    local fontPath = select(1, GameFontHighlight:GetFont())
    Core.MAIN_FONT = fontPath or STANDARD_TEXT_FONT
end

Core.ModuleList = Core.ModuleList or {
    { Key = "RRTTools.MDTIconHook", Name = "MDT Icon Hook", Desc = "Replace MDT enemy portraits with spell icons.", Category = 2 },
    { Key = "RRTTools.TeleMsg", Name = "Teleport Message", Desc = "Teleport chat message helpers.", Category = 2 },
    { Key = "RRTTools.Tooltip", Name = "Tooltip", Desc = "Mythic+ tooltip enhancements.", Category = 2, HideCfg = true },
    { Key = "RRTTools.MythicDashboard", Name = "Mythic Dashboard", Desc = "Mythic+ statistics dashboard.", Category = 2, HideCfg = true },
    { Key = "RRTTools.SpellData", Name = "Spell Data", Desc = "Internal spell data.", Category = 2, HideCfg = true },
    { Key = "RRTTools.NoMoveSkillAlert", Name = "No Move Skill Alert", Desc = "Warn when your movement spell is on cooldown.", Category = 3 },
    { Key = "RRTTools.FocusCast", Name = "Focus Cast", Desc = "Show a native focus cast bar.", Category = 3 },
    { Key = "RRTTools.SpellEffectAlpha", Name = "Spell Effect Alpha", Desc = "Control spell activation overlay opacity by spec.", Category = 3 },
    { Key = "RRTTools.CastSequence", Name = "Cast Sequence", Desc = "Track your recent casts as an icon sequence.", Category = 3 },
    { Key = "RRTTools.SpellAlert", Name = "Spell Alert", Desc = "Show alerts for configured successful spell casts.", Category = 3 },
    { Key = "RRTTools.SetKey", Name = "Set Key", Desc = "Beta keystone helper attached to the PVE frame.", Category = 2 },
}

Core.ModuleIndexByKey = Core.ModuleIndexByKey or {}
for index, meta in ipairs(Core.ModuleList) do
    Core.ModuleIndexByKey[meta.Key] = index
end

local db = RRT.MythicCore
db.DBVersion = db.DBVersion or 1
db.ModuleDB = db.ModuleDB or {}
db.LoadByKey = db.LoadByKey or {}
db.LoadKeys = db.LoadKeys or {}
db.Minimap = db.Minimap or { hide = false }

Core.LegacyModuleKeyMap = Core.LegacyModuleKeyMap or {
    ["ExM+Info.MDTIconHook"] = "RRTTools.MDTIconHook",
    ["ExM+Info.TeleMsg"] = "RRTTools.TeleMsg",
    ["ExM+Info.Tooltip"] = "RRTTools.Tooltip",
    ["ExM+InfoMythicFrame"] = "RRTTools.MythicDashboard",
    ["ExM+InfoSpellData"] = "RRTTools.SpellData",
    ["ExClass.NoMoveSkillAlert"] = "RRTTools.NoMoveSkillAlert",
    ["ExClass.FocusCast"] = "RRTTools.FocusCast",
    ["ExClass.SpellEffectAlpha"] = "RRTTools.SpellEffectAlpha",
    ["ExTools.CastSequence"] = "RRTTools.CastSequence",
    ["ExTools.SpellAlert"] = "RRTTools.SpellAlert",
    ["ExPTR.SetKey"] = "RRTTools.SetKey",
}

for legacyKey, newKey in pairs(Core.LegacyModuleKeyMap) do
    if db.ModuleDB[legacyKey] and not db.ModuleDB[newKey] then
        db.ModuleDB[newKey] = db.ModuleDB[legacyKey]
    end
    if db.LoadByKey[legacyKey] ~= nil and db.LoadByKey[newKey] == nil then
        db.LoadByKey[newKey] = db.LoadByKey[legacyKey]
    end
end

for index, meta in ipairs(Core.ModuleList) do
    db.LoadKeys[index] = meta.Key
    if db.LoadByKey[meta.Key] == nil then
        db.LoadByKey[meta.Key] = true
    end
end

Core.DB = db
Core.ModuleStatus = Core.ModuleStatus or {}
Core.RegisteredLayouts = Core.RegisteredLayouts or {}
Core.HUDs = Core.HUDs or {}
Core.EditModeCallbacks = Core.EditModeCallbacks or {}
Core.GlobalEditMode = Core.GlobalEditMode or false
Core.ErrorLog = Core.ErrorLog or {}
Core._stateWatchers = Core._stateWatchers or {}
Core._eventCallbacks = Core._eventCallbacks or {}

function Core:Print(msg, ...)
    local output = select("#", ...) > 0 and string.format(msg, ...) or tostring(msg)
    print("|cFFBB66FFRRT Mythic|r " .. output)
end

function Core:LogError(source, message)
    local entry = {
        time = date("%H:%M:%S"),
        source = tostring(source or "Unknown"),
        message = tostring(message or "Unknown error"),
    }
    table.insert(self.ErrorLog, 1, entry)
    while #self.ErrorLog > 20 do
        table.remove(self.ErrorLog)
    end
end

function Core:ReportReady(moduleKey)
    if type(moduleKey) == "string" and moduleKey ~= "" then
        self.ModuleStatus[moduleKey] = "ready"
    end
end

function Core:RegisterModuleLayout(moduleKey, layoutData)
    if type(moduleKey) == "string" and type(layoutData) == "table" then
        self.RegisteredLayouts[moduleKey] = layoutData
    end
end

function Core:IsModuleEnabled(moduleKey)
    if type(moduleKey) ~= "string" or moduleKey == "" then
        return false
    end
    if self.DB.LoadByKey[moduleKey] == nil then
        self.DB.LoadByKey[moduleKey] = true
    end
    return self.DB.LoadByKey[moduleKey] == true
end

function Core:GetModuleDB(moduleKey, defaults)
    if type(moduleKey) ~= "string" or moduleKey == "" then
        error("GetModuleDB: moduleKey must be a non-empty string", 2)
    end
    self.DB.ModuleDB[moduleKey] = copyDefaults(self.DB.ModuleDB[moduleKey], defaults)
    return self.DB.ModuleDB[moduleKey]
end

function Core:WatchState(stateKey, owner, callback)
    if type(stateKey) ~= "string" or type(owner) ~= "string" or type(callback) ~= "function" then
        return
    end
    local bucket = ensureTable(self._stateWatchers, stateKey)
    bucket[owner] = callback
end

function Core:UnwatchState(stateKey, owner)
    local bucket = self._stateWatchers[stateKey]
    if bucket then
        bucket[owner] = nil
    end
end

function Core:RegisterHUD(moduleKey, frame)
    if not frame then
        return
    end

    frame:EnableMouse(true)
    frame:HookScript("OnMouseDown", function(_, button)
        if button == "RightButton" and self.GlobalEditMode then
            self:OpenConfig(moduleKey)
        end
    end)

    table.insert(self.HUDs, { key = moduleKey, frame = frame })
end

function Core:RegisterEditModeCallback(moduleKey, callback)
    if type(moduleKey) == "string" and type(callback) == "function" then
        self.EditModeCallbacks[moduleKey] = callback
    end
end

function Core:UnregisterEditModeCallback(moduleKey)
    self.EditModeCallbacks[moduleKey] = nil
end

function Core:ToggleGlobalEditMode(forceState)
    if forceState == nil then
        self.GlobalEditMode = not self.GlobalEditMode
    else
        self.GlobalEditMode = forceState and true or false
    end

    for _, callback in pairs(self.EditModeCallbacks) do
        local ok, err = pcall(callback, self.GlobalEditMode)
        if not ok then
            self:LogError("EditMode", err)
        end
    end
end

function Core:OpenConfig()
    if RRT_NS and RRT_NS.RRTUI and RRT_NS.RRTUI.ToggleOptions then
        RRT_NS.RRTUI:ToggleOptions()
    end
end

_G.RRTMythicCoreEventFrame = nil
local eventFrame = CreateFrame("Frame")
local eventBootstrapFrame = CreateFrame("Frame")
local staticBlizzardEvents = {
    "ADDON_LOADED",
    "ADDON_RESTRICTION_STATE_CHANGED",
    "BAG_UPDATE_DELAYED",
    "CHALLENGE_MODE_COMPLETED",
    "CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN",
    "CHALLENGE_MODE_KEYSTONE_SLOTTED",
    "CHALLENGE_MODE_MAPS_UPDATE",
    "CHALLENGE_MODE_RESET",
    "CHALLENGE_MODE_START",
    "ENCOUNTER_END",
    "ENCOUNTER_START",
    "GROUP_ROSTER_UPDATE",
    "ITEM_CHANGED",
    "MERCHANT_SHOW",
    "PARTY_LEADER_CHANGED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_EQUIPMENT_CHANGED",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_SPECIALIZATION_CHANGED",
    "PLAYER_TARGET_CHANGED",
    "RAID_TARGET_UPDATE",
    "SPELL_UPDATE_CHARGES",
    "UNIT_FLAGS",
    "UNIT_AURA",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_STATS",
    "ZONE_CHANGED_NEW_AREA",
}

local function isInternalEvent(eventName)
    return eventName:match("^EX_") or eventName:match("^RRT_")
end

local staticEventsRegistered = false
local staticEventRegistrationBlocked = false

local function registerStaticBlizzardEvents()
    if staticEventsRegistered or staticEventRegistrationBlocked then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        staticEventRegistrationBlocked = true
        eventBootstrapFrame:SetScript("OnUpdate", nil)
        return
    end

    for i = 1, #staticBlizzardEvents do
        eventFrame:RegisterEvent(staticBlizzardEvents[i])
    end
    staticEventsRegistered = true
    eventBootstrapFrame:SetScript("OnUpdate", nil)
end

do
    local elapsed = 0
    eventBootstrapFrame:SetScript("OnUpdate", function(_, dt)
        if staticEventsRegistered or staticEventRegistrationBlocked then
            eventBootstrapFrame:SetScript("OnUpdate", nil)
            return
        end

        elapsed = elapsed + (dt or 0)
        if elapsed < 0.2 then
            return
        end
        elapsed = 0
        registerStaticBlizzardEvents()
    end)
end

function Core:RegisterEvent(eventName, owner, callback)
    if type(eventName) ~= "string" or type(owner) ~= "string" or type(callback) ~= "function" then
        return
    end

    local bucket = ensureTable(self._eventCallbacks, eventName)
    bucket[owner] = callback
end

function Core:UnregisterEvent(eventName, owner)
    local bucket = self._eventCallbacks[eventName]
    if not bucket then
        return
    end

    bucket[owner] = nil
    if next(bucket) then
        return
    end

    self._eventCallbacks[eventName] = nil
end

function Core:SendEvent(eventName, ...)
    local bucket = self._eventCallbacks[eventName]
    if not bucket then
        return
    end

    for _, callback in pairs(bucket) do
        local ok, err = pcall(callback, eventName, ...)
        if not ok then
            self:LogError("Event:" .. eventName, err)
            geterrorhandler()(err)
        end
    end
end

eventFrame:SetScript("OnEvent", function(_, eventName, ...)
    Core:SendEvent(eventName, ...)
end)

-- Re-initialize Core.DB from restored SavedVariables after ADDON_LOADED.
-- At Lua file execution time, SavedVariables are not yet loaded, so RRT.MythicCore
-- is a fresh empty table. This frame catches ADDON_LOADED (when SavedVars are restored)
-- and re-points Core.DB to the real persisted data.
do
    local _dbInitFrame = CreateFrame("Frame")
    _dbInitFrame:RegisterEvent("ADDON_LOADED")
    _dbInitFrame:SetScript("OnEvent", function(self, _, addonName)
        if addonName ~= "InfinityTools" then return end
        self:UnregisterEvent("ADDON_LOADED")

        -- Ensure the SavedVariable root and MythicCore sub-table both exist,
        -- then unconditionally re-point Core.DB to the (now-restored) persisted table.
        _G.RRT = _G.RRT or {}
        _G.RRT.MythicCore = _G.RRT.MythicCore or {}
        local restoredDB = _G.RRT.MythicCore
        restoredDB.DBVersion  = restoredDB.DBVersion  or 1
        restoredDB.ModuleDB   = restoredDB.ModuleDB   or {}
        restoredDB.LoadByKey  = restoredDB.LoadByKey  or {}
        restoredDB.LoadKeys   = restoredDB.LoadKeys   or {}
        restoredDB.Minimap    = restoredDB.Minimap    or { hide = false }

        for legacyKey, newKey in pairs(Core.LegacyModuleKeyMap) do
            if restoredDB.ModuleDB[legacyKey] and not restoredDB.ModuleDB[newKey] then
                restoredDB.ModuleDB[newKey] = restoredDB.ModuleDB[legacyKey]
            end
            if restoredDB.LoadByKey[legacyKey] ~= nil and restoredDB.LoadByKey[newKey] == nil then
                restoredDB.LoadByKey[newKey] = restoredDB.LoadByKey[legacyKey]
            end
        end
        for index, meta in ipairs(Core.ModuleList) do
            restoredDB.LoadKeys[index] = meta.Key
            if restoredDB.LoadByKey[meta.Key] == nil then
                restoredDB.LoadByKey[meta.Key] = true
            end
        end

        Core.DB = restoredDB
    end)
end
