---@diagnostic disable: undefined-global, undefined-field, need-check-nil

InfinityBoss = InfinityBoss or {}
InfinityBoss.Condition = InfinityBoss.Condition or {}

local Runtime = InfinityBoss.Condition.Runtime or {}
InfinityBoss.Condition.Runtime = Runtime

local UPDATE_INTERVAL = 0.05

local frame = CreateFrame("Frame")
Runtime._elapsed = 0
Runtime._ringShown = false
Runtime._lastMatch = nil

local function GlobalDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.conditions = InfinityBossDB.conditions or {}
    if InfinityBossDB.conditions.enabled == nil then
        InfinityBossDB.conditions.enabled = false
    end
    return InfinityBossDB.conditions
end

local function GetEventConfigRoot()
    local api = _G.InfinityBossData
    if type(api) == "table" and type(api.GetEventOverrideRoot) == "function" then
        local ok, root = pcall(api.GetEventOverrideRoot)
        if ok and type(root) == "table" then
            return root
        end
    end
    return {}
end

local function EnsureCastWindowRule(eventID)
    local root = GetEventConfigRoot()
    root[eventID] = root[eventID] or {}
    root[eventID].rules = root[eventID].rules or {}
    root[eventID].rules.castWindow = root[eventID].rules.castWindow or {
        enabled = false,
        windowBefore = 2,
        windowAfter = 2,
        ringEnabled = true,
    }
    return root[eventID].rules.castWindow
end

local function GetCastWindowRule(eventID)
    local root = GetEventConfigRoot()
    local row = root[eventID]
    local rules = row and row.rules
    local rule = rules and rules.castWindow
    if type(rule) ~= "table" then
        return nil
    end
    return rule
end

local function SafeNum(v, def)
    local n = tonumber(v)
    if n == nil then
        return def
    end
    return n
end

local function SafeMsToSeconds(v)
    local n = tonumber(v)
    if n ~= nil then
        return n / 1000
    end
    local ok, out = pcall(function()
        return v / 1000
    end)
    if ok and type(out) == "number" then
        return out
    end
    return nil
end

local function GetBossCast()
    local now = GetTime()
    local best = nil

    for i = 1, 5 do
        local unit = "boss" .. i
        if UnitExists(unit) then
            local name, displayName, _, startMs, endMs, _, _, notInterruptible, spellID = UnitCastingInfo(unit)
            local castKind = "cast"
            if not name then
                name, displayName, _, startMs, endMs, _, notInterruptible, spellID = UnitChannelInfo(unit)
                castKind = "channel"
            end

            if name and startMs and endMs then
                local startTime = SafeMsToSeconds(startMs)
                local endTime = SafeMsToSeconds(endMs)
                if startTime and endTime then
                local remaining = math.max(0, endTime - now)
                local duration = math.max(0.1, endTime - startTime)
                local row = {
                    unit = unit,
                    castKind = castKind,
                    name = displayName or name,
                    spellID = tonumber(spellID),
                    interruptible = not notInterruptible and false or true,
                    startTime = startTime,
                    endTime = endTime,
                    duration = duration,
                    remaining = remaining,
                }

                    if not best or row.endTime < best.endTime then
                        best = row
                    end
                end
            end
        end
    end

    return best
end

local function FindBestMatch(now, bossCast)
    local scheduler = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
    if type(scheduler) ~= "table" then
        return nil
    end

    local timers = scheduler.GetActiveTimers and scheduler:GetActiveTimers() or scheduler._active
    if type(timers) ~= "table" then
        return nil
    end

    local best = nil
    for _, timer in pairs(timers) do
        local eventID = tonumber(timer and timer.eventID)
        if eventID then
            local rule = GetCastWindowRule(eventID)
            if type(rule) == "table" and rule.enabled == true and rule.ringEnabled ~= false then
                local before = math.max(0, SafeNum(rule.windowBefore, 2))
                local after = math.max(0, SafeNum(rule.windowAfter, 2))
                local castTime = SafeNum(timer.castTime, nil)
                if castTime then
                    local delta = now - castTime
                    if delta >= -before and delta <= after then
                        local dist = math.abs(delta)
                        if not best or dist < best.distance then
                            best = {
                                eventID = eventID,
                                timer = timer,
                                rule = rule,
                                bossCast = bossCast,
                                distance = dist,
                                delta = delta,
                            }
                        end
                    end
                end
            end
        end
    end
    return best
end

local function ShowRingForMatch(match)
    local ring = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.RingProgress
    if not (ring and ring.ShowEntry) then
        return
    end

    local cast = match.bossCast
    ring:ShowEntry({
        duration = cast.duration,
        endTime = cast.endTime,
    }, cast.remaining)

    Runtime._ringShown = true
    Runtime._lastMatch = {
        eventID = match.eventID,
        eventName = match.timer and match.timer.displayName,
        castName = cast.name,
        castRemaining = cast.remaining,
        delta = match.delta,
    }
end

local function HideRingIfOwned()
    if Runtime._ringShown then
        local ring = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.RingProgress
        if ring and ring.Hide then
            ring:Hide()
        end
        Runtime._ringShown = false
    end
    Runtime._lastMatch = nil
end

local function Tick()
    local gdb = GlobalDB()
    if gdb.enabled == false then
        HideRingIfOwned()
        return
    end

    local bossCast = GetBossCast()
    if not bossCast then
        HideRingIfOwned()
        return
    end

    local now = GetTime()
    local match = FindBestMatch(now, bossCast)
    if match then
        ShowRingForMatch(match)
    else
        HideRingIfOwned()
    end
end

function Runtime:GetLastMatch()
    return self._lastMatch
end

function Runtime:GetOrCreateRule(eventID)
    eventID = tonumber(eventID)
    if not eventID then
        return nil
    end
    return EnsureCastWindowRule(eventID)
end

frame:SetScript("OnUpdate", function(_, elapsed)
    Runtime._elapsed = Runtime._elapsed + elapsed
    if Runtime._elapsed < UPDATE_INTERVAL then
        return
    end
    Runtime._elapsed = 0
    Tick()
end)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ENCOUNTER_END")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "ENCOUNTER_END" then
        HideRingIfOwned()
    end
end)
