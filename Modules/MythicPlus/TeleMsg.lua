local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
local InfinityDB = _G.InfinityDB
if not Core or not InfinityDB then
    return
end

local MODULE_KEY = "RRTTools.TeleMsg"
local DEFAULTS = {
    enabled = false,
    channel = "PARTY",
    message = "Teleporting to %s.",
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local lastSpellID = 0
local lastMessageTime = 0

local function GetOutputChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end
    if IsInRaid() then
        return "RAID"
    end
    return DB.channel or "PARTY"
end

local function HandleTeleport(_, _, _, _, spellID)
    if not DB.enabled then
        return
    end

    local dungeonName = InfinityDB.SpellToDungeonName and InfinityDB.SpellToDungeonName[spellID]
    if not dungeonName then
        return
    end

    local now = GetTime()
    if lastSpellID == spellID and (now - lastMessageTime) < 2 then
        return
    end

    lastSpellID = spellID
    lastMessageTime = now
    SendChatMessage(string.format(DB.message or DEFAULTS.message, dungeonName), GetOutputChannel())
end

Core:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", MODULE_KEY, HandleTeleport)

RRT_NS.MythicTeleMsg = {
    RefreshDisplay = function()
        DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
    end,
}
