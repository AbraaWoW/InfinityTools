---@diagnostic disable: undefined-global
-- =============================================================
-- InfinityBossEngine/Dispatcher.lua
-- =============================================================

InfinityBoss.Timeline.Dispatcher = InfinityBoss.Timeline.Dispatcher or {}
local Dispatcher = InfinityBoss.Timeline.Dispatcher
local TIMELINE_HINT_EVENT = "InfinityBoss_TIMELINE_HINT"

local function NormalizeBarDisplayMode(mode)
    local m = tostring(mode or ""):lower()
    if m == "timer" or m == "bun" or m == "both" or m == "none" then
        return m
    end
    return "bun"
end

local function GetBarDisplayMode()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.ui = InfinityBossDB.ui or {}
    InfinityBossDB.ui.general = InfinityBossDB.ui.general or {}
    local g = InfinityBossDB.ui.general
    g.barDisplayMode = NormalizeBarDisplayMode(g.barDisplayMode)
    return g.barDisplayMode
end

local function IsTimerBarEnabledByGlobal()
    local mode = GetBarDisplayMode()
    return mode == "both" or mode == "timer"
end

local function IsBunBarEnabledByGlobal()
    local mode = GetBarDisplayMode()
    return mode == "both" or mode == "bun"
end

local function ResolveSafeTimerName(timer)
    if type(timer) ~= "table" then
        return "Unknown Spell"
    end

    local spellID = tonumber(timer.spellID)
    local eventID = tonumber(timer.timelineEventID)

    if timer.timelineManaged or timer.source == "blizzard" then
        if type(timer.displayName) == "string" then
            return timer.displayName
        end
        if spellID then
            return "Spell " .. tostring(spellID)
        end
        if eventID then
            return "Timeline Event " .. tostring(eventID)
        end
        return "Timeline Event"
    end

    if type(timer.displayName) == "string" then
        return timer.displayName
    end
    if spellID then
        return "Spell " .. tostring(spellID)
    end
    if eventID then
        return "Timeline Event " .. tostring(eventID)
    end
    return "Unknown Spell"
end

local function ResolveTimerEventID(timer)
    if type(timer) ~= "table" then
        return nil
    end
    local eventID = tonumber(timer.eventID)
    if eventID then
        return eventID
    end
    return tonumber(timer.timelineEventID)
end

local function BuildTimelineHintPayload(timer, thresholdSecs)
    local now = GetTime()
    local scheduledAt = tonumber(timer and timer.castTime) or now
    local scheduler = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler or nil
    local encounterID = scheduler and scheduler._encounterID or nil
    return {
        hintType = "remaining_threshold",
        threshold = tonumber(thresholdSecs) or 0,
        remaining = math.max(0, scheduledAt - now),
        fireAt = now,
        scheduledAt = scheduledAt,
        timerID = tonumber(timer and timer.id),
        encounterID = tonumber(encounterID) or encounterID,
        eventID = ResolveTimerEventID(timer),
        spellID = tonumber(timer and timer.spellID) or nil,
        source = timer and timer.source or nil,
        displayName = ResolveSafeTimerName(timer),
    }
end

local function FormatText(template, timer)
    if template == nil then return nil end
    if type(template) ~= "string" then
        template = tostring(template)
    end

    local isTimeline = timer and (timer.timelineManaged or timer.source == "blizzard")
    local hasNameToken = template:find("{name}", 1, true) ~= nil
    if isTimeline and hasNameToken then
        return ResolveSafeTimerName(timer) or "Timeline Event"
    end

    local out = template
    if hasNameToken then
        out = out:gsub("{name}", ResolveSafeTimerName(timer))
    end

    local remaining = (timer and timer.castTime) and math.max(0, timer.castTime - GetTime()) or 0
    if out:find("{time}", 1, true) then
        out = out:gsub("{time}", string.format("%.1f", remaining))
    end
    return out
end

local function BuildPreAlertCountdownTimer(timer)
    if type(timer) ~= "table" then
        return timer
    end

    local txt = FormatText(timer.preAlertText, timer)
    if type(txt) ~= "string" or txt == "" then
        return timer
    end

    local t = {}
    for k, v in pairs(timer) do
        t[k] = v
    end
    t.displayName = txt
    t.flashTextColor = timer.flashTextColor
    t.eventColor = timer.eventColor
    return t
end

local function ResolveCentralDisplayText(timer)
    if type(timer) ~= "table" then
        return nil
    end
    local text = timer.screenText
    if type(text) == "string" then
        return text
    end
    text = timer.displayName
    if type(text) == "string" then
        return text
    end
    return nil
end

function Dispatcher:OnPreAlert(timer)
    if not timer or timer.disabled then return end
    if timer.preAlertEnabled == false then return end
    if InfinityBoss.UI.Countdown and InfinityBoss.UI.Countdown.Show then
        InfinityBoss.UI.Countdown:Show(BuildPreAlertCountdownTimer(timer))
    end
end

function Dispatcher:OnCentral(timer)
    if not timer or timer.disabled then return end
    if timer.centralEnabled == false then return end
    local text = ResolveCentralDisplayText(timer)
    if not text then return end
    if InfinityBoss.UI.FlashText and InfinityBoss.UI.FlashText.Show then
        InfinityBoss.UI.FlashText:Show(timer, FormatText(text, timer), 1.5)
    end
end

function Dispatcher:OnCast(timer)
    if not timer or timer.disabled then return end
    if timer.showBunBar and IsBunBarEnabledByGlobal() and InfinityBoss.UI.BunBar and InfinityBoss.UI.BunBar.OnCast then
        InfinityBoss.UI.BunBar:OnCast(timer)
    end
    if timer.showTimerBar and IsTimerBarEnabledByGlobal() and InfinityBoss.UI.TimerBar and InfinityBoss.UI.TimerBar.OnCast then
        InfinityBoss.UI.TimerBar:OnCast(timer)
    end
    local text = ResolveCentralDisplayText(timer)
    if timer.centralEnabled ~= false and timer.centralFired ~= true and text and InfinityBoss.UI.FlashText and InfinityBoss.UI.FlashText.Show then
        InfinityBoss.UI.FlashText:Show(timer, FormatText(text, timer), 1.5)
    end
end

function Dispatcher:OnTimelineHint(timer, thresholdSecs)
    if not timer or timer.disabled then return end
    if not InfinityTools or type(InfinityTools.SendEvent) ~= "function" then return end
    local payload = BuildTimelineHintPayload(timer, thresholdSecs)
    -- print(string.format(
    --     "|cff33ff99[InfinityBoss Hint]|r eventID=%s spellID=%s threshold=%s remaining=%.2f name=%s",
    --     tostring(payload.eventID or "nil"),
    --     tostring(payload.spellID or "nil"),
    --     tostring(payload.threshold or "nil"),
    --     tonumber(payload.remaining) or 0,
    -- ))
    InfinityTools:SendEvent(TIMELINE_HINT_EVENT, payload)
end
