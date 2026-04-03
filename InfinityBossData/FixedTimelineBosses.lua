---@diagnostic disable: undefined-global
-- =============================================================
-- InfinityBossData/FixedTimelineBosses.lua
--
--
-- =============================================================

local TRIGGER_TIME = "TIME"
local TRIGGER_AI = "AI"
local TRIGGER_BLZ = "BLZ"

local function NormalizeTrigger(v)
    local t = tostring(v or ""):upper()
    if t == TRIGGER_TIME or t == TRIGGER_AI or t == TRIGGER_BLZ then
        return t
    end
    return TRIGGER_BLZ
end

-- encounterID -> { trigger = TIME|AI|BLZ, durationRules = { {time,eventID}, ... }? }
local encounterTriggers = {
    [2065] = { trigger = TRIGGER_TIME }, -- The Ascendant Zulal
    [2066] = { trigger = TRIGGER_TIME }, -- Saprish
    [2067] = {
        trigger = TRIGGER_AI, -- Overseer Nezar
        durationRules = {
            { time = 6,  eventID = 376, sync = true },
            { time = 26, eventID = 246, sync = true },
            { time = 45, eventID = 247, sync = true },
            { time = 4,  eventID = 244, sync = true },
            { time = 12, eventID = 245, sync = true },

            { time = 4,  eventID = 244 },
            { time = 18, eventID = 376 },
            { time = 12, eventID = 244 },
            { time = 2,  eventID = 244 },
            { time = 14, eventID = 244 },
            { time = 6,  eventID = 244 },
        },
    },
    [2068] = { trigger = TRIGGER_BLZ },  -- Rula

    [1999] = { trigger = TRIGGER_TIME }, -- Forge-Lord Gavust
    [2000] = { trigger = TRIGGER_TIME }, -- Plague-Lord Tyranus
    [2001] = { trigger = TRIGGER_TIME }, -- Ikk and Korik

    [1698] = { trigger = TRIGGER_TIME }, -- Lanjit
    [1699] = {
        trigger = TRIGGER_AI,            -- Alacanas
        durationRules = {
            { time = 5,  eventID = 302 },
            { time = 6,  eventID = 303 },
            { time = 10, eventID = 302 },
            { time = 15, eventID = 302 },
            { time = 24, eventID = 303 },
            { time = 50, eventID = 304 },
        },
    },
    [1700] = {
        trigger = TRIGGER_AI,            -- Ruklan
        durationRules = {
            { time = 5,  eventID = 306, sync = true },
            { time = 12, eventID = 305, sync = true },
            { time = 38, eventID = 308, sync = true },
            { time = 12, eventID = 306 },
            { time = 21, eventID = 305 },
        },
    },
    [1701] = { trigger = TRIGGER_TIME }, -- High Sage Virix

    [2562] = { trigger = TRIGGER_TIME }, -- Veksamus
    [2563] = {
        trigger = TRIGGER_TIME,          -- Ancient Treant
        durationRules = {
            { time = 9,  eventID = 282 },
            { time = 30, eventID = 283 },
            { time = 18, eventID = 284 },
            { time = 54, eventID = 285 },
            { time = 28, eventID = 282 },
            { time = 33, eventID = 284 },
        },
    },
    [2564] = {
        trigger = TRIGGER_AI, -- Krolz
        durationRules = {
            { time = 5,  eventID = 278 },
            { time = 14, eventID = 279 },
            { time = 20, eventID = 280 },
        },
    },
    [2565] = {
        trigger = TRIGGER_AI,            -- Echo of Dracurgosa
        durationRules = {
            { time = 7,  eventID = 293 },
            { time = 9,  eventID = 294 },
            { time = 10, eventID = 293 },
            { time = 12, eventID = 294 },
            { time = 14, eventID = 295 },
            { time = 28, eventID = 296 },
        },
    },

    [3212] = { trigger = TRIGGER_TIME }, -- Mrokin and Nekrax
    [3213] = {
        trigger = TRIGGER_AI,            -- Vodaza
        durationRules = {
            { time = 3,      eventID = 16, sync = true },
            { time = 70,     eventID = 20, sync = true },
            { time = 14.166, eventID = 19, sync = true },
            { time = 25.333, eventID = 17, sync = true },

            { time = 33.5, eventID = 16, sequenceGroup = "3213_post_sync_33_5", sequenceOrder = 1 },
            { time = 33.5, eventID = 19, sequenceGroup = "3213_post_sync_33_5", sequenceOrder = 2 },
            { time = 33.5, eventID = 17, sequenceGroup = "3213_post_sync_33_5", sequenceOrder = 3 },
        },
    },
    [3214] = { trigger = TRIGGER_TIME }, -- Laktul, Soul-Vessel

    [3328] = {
        trigger = TRIGGER_AI,            -- Chief Engineer Kaslesor
        durationRules = {
            { time = 1,  eventID = 108 },
            { time = 5,  eventID = 107 },
            { time = 10, eventID = 172 },
            { time = 11, eventID = 108 },
            { time = 12, eventID = 107 },
            { time = 13, eventID = 172 },
            { time = 38, eventID = 106 },
        },
        eventActions = {
            [106] = { clearActiveSnapshotAfter = 2 },
        },
    },
    [3332] = { trigger = TRIGGER_BLZ }, -- Core Guardian Nasara
    [3333] = {
        trigger = TRIGGER_BLZ,           -- Losaksen
        durationRules = {
            { time = 2,  eventID = 111 },
            { time = 11, eventID = 109 },

            { time = 24, eventID = 112 },
            { time = 26, eventID = 111 },
            { time = 25, eventID = 109 },
            { time = 10, eventID = 112 },
            { time = 52, eventID = 110 },
        },
        eventActions = {
            [110] = { clearActiveSnapshotAfter = 2 },
        },
    },

    [3056] = { trigger = TRIGGER_TIME }, -- Cinderdawn
    [3057] = {
        trigger = TRIGGER_AI,            -- Forsaken Duo
        durationRules = {
            { time = 8,      eventID = 28 },
            { time = 17.333, eventID = 25 },
            { time = 22.666, eventID = 26 },
            { time = 27.333, eventID = 28 },
            { time = 48,     eventID = 27 },
        },
    },
    [3058] = { trigger = TRIGGER_BLZ },  -- Commander Koruko
    [3059] = {
        trigger = TRIGGER_AI,            -- Sleepless Heart
        durationRules = {
            { time = 9,    eventID = 23 },
            { time = 11,   eventID = 23 },
            { time = 21,   eventID = 24 },
            { time = 23.5, eventID = 538 },
            { time = 24,   eventID = 21 },
            { time = 39,   eventID = 22 },
            { time = 53,   eventID = 21 },
        },
    },

    [3071] = { trigger = TRIGGER_TIME }, -- Arcane Colossus Custus
    [3072] = { trigger = TRIGGER_TIME }, -- Ceranael Sunlash
    [3073] = { trigger = TRIGGER_BLZ },  -- Gimelrus
    [3074] = { trigger = TRIGGER_TIME }, -- Dijantreous

}

local fixedSet = {}
local durationRules = {}

for encounterID, row in pairs(encounterTriggers) do
    if type(row) == "table" then
        row.trigger = NormalizeTrigger(row.trigger)
        if row.trigger == TRIGGER_TIME then
            fixedSet[encounterID] = true
        end
        if type(row.durationRules) == "table" and #row.durationRules > 0 then
            durationRules[encounterID] = row.durationRules
            durationRules[tostring(encounterID)] = row.durationRules
        end
    else
        local t = NormalizeTrigger(row)
        encounterTriggers[encounterID] = { trigger = t }
        if t == TRIGGER_TIME then
            fixedSet[encounterID] = true
        end
    end
end

_G.InfinityBoss_FIXED_TIMELINE_ENCOUNTERS = fixedSet
_G.InfinityBoss_DURATION_EVENT_RULES = durationRules
_G.InfinityBoss_ENCOUNTER_TRIGGERS = encounterTriggers

_G.InfinityBossData = _G.InfinityBossData or {}

function _G.InfinityBossData.GetEncounterTriggerConfig()
    return _G.InfinityBoss_ENCOUNTER_TRIGGERS
end

function _G.InfinityBossData.GetEncounterTrigger(encounterID)
    local id = tonumber(encounterID) or encounterID
    local row = encounterTriggers[id]
    if row == nil then
        row = encounterTriggers[tostring(id)]
    end
    if type(row) == "table" then
        return NormalizeTrigger(row.trigger)
    end
    return NormalizeTrigger(row)
end

return encounterTriggers
