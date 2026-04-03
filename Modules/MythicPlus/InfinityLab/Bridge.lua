local _, RRT_NS = ...

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

RRT = RRT or {}
RRT.InfinityLab = RRT.InfinityLab or {
    modules = {},
    state = {},
}
_G.RRTMythicToolsDB = _G.RRTMythicToolsDB or {}
_G.RRTMythicToolsDB.ModuleDB = RRT.InfinityLab.modules

local RRTMythicTools = _G.RRTMythicTools or {}
_G.RRTMythicTools = RRTMythicTools

RRTMythicTools.L = RRTMythicTools.L or setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})
RRTMythicTools.MAIN_FONT = RRTMythicTools.MAIN_FONT or STANDARD_TEXT_FONT
RRTMythicTools.ModuleLayouts = RRTMythicTools.ModuleLayouts or {}
RRTMythicTools._stateWatchers = RRTMythicTools._stateWatchers or {}
RRTMythicTools.State = RRTMythicTools.State or RRT.InfinityLab.state

function RRTMythicTools:RegisterModuleLayout(key, layout)
    self.ModuleLayouts[key] = layout
end

function RRTMythicTools:GetModuleDB(key, defaults)
    local modules = ensureTable(RRT.InfinityLab, "modules")
    modules[key] = copyDefaults(modules[key], defaults)
    return modules[key]
end

function RRTMythicTools:IsModuleEnabled(key)
    self:GetModuleDB(key, {})
    return true
end

function RRTMythicTools:WatchState(stateKey, token, callback)
    if type(stateKey) ~= "string" or type(token) ~= "string" or type(callback) ~= "function" then
        return
    end

    local bucket = ensureTable(self._stateWatchers, stateKey)
    bucket[token] = callback
end

function RRTMythicTools:TriggerCallbacks(stateKey, ...)
    local bucket = self._stateWatchers[stateKey]
    if not bucket then
        return
    end

    for _, callback in pairs(bucket) do
        local ok, err = pcall(callback, ...)
        if not ok then
            geterrorhandler()(err)
        end
    end
end

function RRTMythicTools:UpdateState(stateKey, value)
    self.State[stateKey] = value
    self:TriggerCallbacks(stateKey, value)
end

function RRTMythicTools:ReportReady()
end

function RRTMythicTools:RegisterHUD()
end

function RRTMythicTools:RegisterEditModeCallback()
end

function RRTMythicTools:OpenConfig()
    if RRT_NS and RRT_NS.ShowMainWindow then
        RRT_NS:ShowMainWindow()
    end
end

local eventFrame = _G.RRTInfinityLabEventFrame or CreateFrame("Frame", "RRTInfinityLabEventFrame")
_G.RRTInfinityLabEventFrame = eventFrame
eventFrame.callbacks = eventFrame.callbacks or {}

function RRTMythicTools:RegisterEvent(eventName, token, callback)
    if type(eventName) ~= "string" or type(token) ~= "string" or type(callback) ~= "function" then
        return
    end

    local bucket = ensureTable(eventFrame.callbacks, eventName)
    bucket[token] = callback

    if not eventName:match("^EX_") then
        eventFrame:RegisterEvent(eventName)
    end
end

function RRTMythicTools:UnregisterEvent(eventName, token)
    local bucket = eventFrame.callbacks[eventName]
    if not bucket then
        return
    end

    bucket[token] = nil
    if next(bucket) then
        return
    end

    eventFrame.callbacks[eventName] = nil
    if not eventName:match("^EX_") then
        eventFrame:UnregisterEvent(eventName)
    end
end

function RRTMythicTools:SendEvent(eventName, ...)
    local bucket = eventFrame.callbacks[eventName]
    if not bucket then
        return
    end

    for _, callback in pairs(bucket) do
        local ok, err = pcall(callback, eventName, ...)
        if not ok then
            geterrorhandler()(err)
        end
    end
end

eventFrame:SetScript("OnEvent", function(_, eventName, ...)
    RRTMythicTools:SendEvent(eventName, ...)
end)

local function updateRuntimeState()
    local inInstance, instanceType = IsInInstance()
    local difficultyID = select(3, GetInstanceInfo())
    local inMythicPlus = false
    if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
        inMythicPlus = (tonumber(C_ChallengeMode.GetActiveChallengeMapID()) or 0) > 0
    end

    RRTMythicTools:UpdateState("InInstance", inInstance)
    RRTMythicTools:UpdateState("InstanceType", instanceType)
    RRTMythicTools:UpdateState("IsInParty", IsInGroup() and not IsInRaid())
    RRTMythicTools:UpdateState("InMythicPlus", inMythicPlus)
    RRTMythicTools:UpdateState("DifficultyID", difficultyID)

    local versa = 0
    if GetCombatRatingBonus then
        versa = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE or 29) or 0
    end
    RRTMythicTools:UpdateState("PStat_Versa", versa)
end

RRTMythicTools:RegisterEvent("PLAYER_ENTERING_WORLD", "RRT_REVLAB_STATE", updateRuntimeState)
RRTMythicTools:RegisterEvent("ZONE_CHANGED_NEW_AREA", "RRT_REVLAB_STATE", updateRuntimeState)
RRTMythicTools:RegisterEvent("GROUP_ROSTER_UPDATE", "RRT_REVLAB_STATE", updateRuntimeState)
RRTMythicTools:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "RRT_REVLAB_STATE", updateRuntimeState)
RRTMythicTools:RegisterEvent("CHALLENGE_MODE_START", "RRT_REVLAB_STATE", updateRuntimeState)
RRTMythicTools:RegisterEvent("CHALLENGE_MODE_COMPLETED", "RRT_REVLAB_STATE", updateRuntimeState)
RRTMythicTools:RegisterEvent("CHALLENGE_MODE_RESET", "RRT_REVLAB_STATE", updateRuntimeState)

C_Timer.After(0, updateRuntimeState)
