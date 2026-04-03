local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
local SpellData = RRT_NS.MythicSpellData
local InfinityDB = _G.InfinityDB
if not Core then return end

local MODULE_KEY = "RRTTools.Tooltip"
local DEFAULTS = {
    enabled = false,
    showTeleportInfo = true,
    showInterruptInfo = true,
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local hooked = false

local function BuildInterruptUsage(spellID)
    if not SpellData or not SpellData.GetInterruptCatalog then return nil end
    local users = {}
    for _, row in ipairs(SpellData:GetInterruptCatalog()) do
        if row.spellID == spellID then
            users[#users + 1] = row.specName
        end
    end
    if #users == 0 then
        return nil
    end
    table.sort(users)
    return "Interrupt users: " .. table.concat(users, ", ")
end

local function AppendTooltipData(tooltip, spellID)
    if not DB.enabled or not tooltip then
        return
    end

    spellID = tonumber(spellID) or 0
    if spellID <= 0 then
        return
    end

    if DB.showTeleportInfo and InfinityDB and InfinityDB.SpellToDungeonName then
        local dungeonName = InfinityDB.SpellToDungeonName[spellID]
        if dungeonName then
            tooltip:AddLine("Mythic+ teleport: " .. dungeonName, 0.4, 0.85, 1)
        end
    end

    if DB.showInterruptInfo and SpellData and SpellData.GetInterruptCatalog then
        local usage = BuildInterruptUsage(spellID)
        if usage then
            tooltip:AddLine(usage, 1, 0.82, 0.2)
        end
    end
end

local function InstallHooks()
    if hooked then
        return
    end
    hooked = true

    if GameTooltip and GameTooltip.SetSpellByID then
        hooksecurefunc(GameTooltip, "SetSpellByID", function(tooltip, spellID)
            AppendTooltipData(tooltip, spellID)
        end)
    end

    if GameTooltip and GameTooltip.SetHyperlink then
        hooksecurefunc(GameTooltip, "SetHyperlink", function(tooltip, link)
            if type(link) ~= "string" then
                return
            end
            local spellID = link:match("spell:(%d+)")
            if spellID then
                AppendTooltipData(tooltip, spellID)
            end
        end)
    end
end

InstallHooks()

RRT_NS.MythicTooltip = {
    RefreshDisplay = function()
        DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
    end,
}
