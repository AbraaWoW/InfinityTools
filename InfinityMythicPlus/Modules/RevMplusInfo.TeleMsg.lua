-- [[ Teleport Announcer ]]
-- { Key = "RevMplusInfo.TeleMsg", Name = "Teleport Announcer", Desc = "Automatically sends a party message when casting dungeon teleport spells.", Category = 2 },

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local InfinityState = InfinityTools.State
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

-- 1. Module key
local INFINITY_MODULE_KEY = "RevMplusInfo.TeleMsg"

-- 2. Load guard
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local InfinityDB = _G.InfinityDB
if not InfinityDB then return end

-- 3. Default database values
local INFINITY_DEFAULTS = {
    teleportShoutText = "Casting %link, preparing to teleport to \"%name\".",
    shoutTiming = "Cast Success", -- shout timing: cast start / cast success
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)
local DEFAULT_MSG = INFINITY_DEFAULTS.teleportShoutText
local DUNGEON_TRANSLATIONS = {}
local TIMING_CAST_START = "Cast Start"
local TIMING_CAST_SUCCESS = "Cast Success"

-- =========================================================
-- [v4.2] Registration and configuration
-- =========================================================

-- Grid layout
local function REGISTER_LAYOUT()
    -- Precompute the preview string outside the layout table
    local fmt = MODULE_DB.teleportShoutText or DEFAULT_MSG
    local link = "|cff71d5ff|Hspell:444222|h[" .. L["??: ????"] .. "]|h|r"
    local name = L["????"]
    local out = fmt:gsub("%%link", link):gsub("%%name", name)

    local _, classFilename = UnitClass("player")
    local color = C_ClassColor.GetClassColor(classFilename or "WARRIOR")
    local playerColored = "|c" ..
        ((color and color.GenerateHexColor) and color:GenerateHexColor() or "ffffff") .. UnitName("player") .. "|r"

    local previewText = "\n|cffffd100Preview:|r\n|cffaaaaff[Party] [" .. playerColored .. "]: " .. out .. "|r"

    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 49, h = 3, label = L["Teleport Announce"], labelSize = 25 },
        {
            key = "descInfo",
            type = "description",
            x = 2,
            y = 4,
            w = 49,
            h = 4,
            label = L["|cffffd100Variables:|r\n  |cff00ff00%link|r = spell link\n  |cff00ff00%name|r = dungeon name"],
            labelSize = 18
        },
        { key = "divider_1705", type = "divider", x = 2, y = 8, w = 49, h = 1 },
        {
            key = "shoutTiming",
            type = "dropdown",
            x = 2,
            y = 10,
            w = 20,
            h = 2,
            label = L["Announce Timing"],
            items = "Cast Start,Cast Success"
        },
        { key = "teleportShoutText", type = "input", x = 2, y = 13, w = 49, h = 2, label = L["Custom Message"] },
        {
            key = "previewLabel",
            type = "description",
            x = 2,
            y = 15,
            w = 49,
            h = 6,
            label = previewText,
            labelSize = 18
        },
        { key = "reset", type = "button", x = 2, y = 21, w = 15, h = 2, label = L["Reset Message"] },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

-- 3. Register immediately
REGISTER_LAYOUT()

-- =========================================================
-- Runtime logic
-- =========================================================

-- Shared announce handler for cast-start and cast-success events
local function HandleSpellCast(unit, spellID)
    if unit ~= "player" then return end
    local dungeonName = InfinityDB.SpellToDungeonName[spellID]
    -- Heavenreach Pinnacle: Alliance/Horde teleport spell compatibility
    if not dungeonName and (spellID == 159898 or spellID == 1254557) then
        dungeonName = "Skyreach"
    end
    if not dungeonName then return end
    dungeonName = DUNGEON_TRANSLATIONS[dungeonName] or L[dungeonName] or dungeonName

    local spellLink = C_Spell.GetSpellLink(spellID)
    if not spellLink then return end

    local msgFormat = MODULE_DB.teleportShoutText or DEFAULT_MSG
    local message = msgFormat:gsub("%%link", spellLink):gsub("%%name", dungeonName)
    SendChatMessage(message, "PARTY")
end

local function OnSpellStart(event, unit, _, spellID)
    HandleSpellCast(unit, spellID)
end

local function OnSpellSucceeded(event, unit, _, spellID)
    HandleSpellCast(unit, spellID)
end

-- Register the event selected by current settings and unregister the other one
local function UpdateTelemsgEvent()
    local timing = MODULE_DB.shoutTiming or INFINITY_DEFAULTS.shoutTiming
    if timing == TIMING_CAST_START then
        InfinityTools:RegisterEvent("UNIT_SPELLCAST_START", INFINITY_MODULE_KEY, OnSpellStart)
        InfinityTools:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED", INFINITY_MODULE_KEY)
    else
        -- Default: announce on successful cast
        InfinityTools:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", INFINITY_MODULE_KEY, OnSpellSucceeded)
        InfinityTools:UnregisterEvent("UNIT_SPELLCAST_START", INFINITY_MODULE_KEY)
    end
end

-- 4. Bind events and UI callbacks
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(data)
    if data.key == "reset" then
        MODULE_DB.teleportShoutText = DEFAULT_MSG
        InfinityTools:UpdateState(INFINITY_MODULE_KEY .. ".DatabaseChanged", "reset")
    end
end)

-- Watch DB changes: refresh preview and re-register events
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function()
    -- Rebuild the static layout so preview text updates
    REGISTER_LAYOUT()
    -- Refresh the panel if this module is currently open
    if InfinityTools.UI and InfinityTools.UI.CurrentModule == INFINITY_MODULE_KEY then
        InfinityTools.UI:RefreshContent()
    end
    -- Re-register the selected announce timing event
    if not InfinityState.InInstance then
        UpdateTelemsgEvent()
    end
end)

-- Smart lifecycle: listen outside instances, unregister inside instances
InfinityTools:WatchState("InInstance", INFINITY_MODULE_KEY, function(inInstance)
    if inInstance then
        InfinityTools:UnregisterEvent("UNIT_SPELLCAST_START", INFINITY_MODULE_KEY)
        InfinityTools:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED", INFINITY_MODULE_KEY)
    else
        UpdateTelemsgEvent()
    end
end)

-- Initial state check
if not InfinityState.InInstance then
    UpdateTelemsgEvent()
end

-- Report module ready
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

