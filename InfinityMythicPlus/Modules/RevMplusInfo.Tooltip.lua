-- [[ Mythic+ Tooltip Enhancements ]]
-- { Key = "RevMplusInfo.Tooltip", Name = "Mythic+ Tooltip Enhancements", Desc = "Shows best run details, party info, and teleport cooldowns on challenge panel icons.", Category = 2 },

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end
local InfinityState = InfinityTools.State
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

-- 1. Module key
local INFINITY_MODULE_KEY = "RevMplusInfo.Tooltip"

-- 2. Load guard
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- 3. Database initialization
local INFINITY_DEFAULTS = {
    enabled = false,
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)

-- =========================================================
-- [v4.2] Registration and configuration
-- =========================================================



-- 2. Grid layout
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 53, h = 2, label = L["M+ Info Tooltips"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 53, h = 3, label = L["Shows detailed run history, party specs, and dungeon teleport cooldown when hovering dungeon icons in the PVE challenge panel."] },
        { key = "enabled", type = "checkbox", x = 2, y = 7, w = 13, h = 1, label = L["Enable Tooltip Enhancements"] },
        { key = "divider_8437", type = "divider", x = 2, y = 11, w = 53, h = 1, label = "" },
    }


    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

-- 3. Register immediately
REGISTER_LAYOUT()

-- 5. Runtime logic (internal prefix: EXMYTOOLTIP)
local EXMYTOOLTIP = {}

-- Use the global shared database
local InfinityDB = _G.InfinityDB
if not InfinityDB then
    print("|cffff0000[RevMplusInfo.Tooltip]|r " .. L["Error: shared database not loaded!"])
    return
end

-- Constants
EXMYTOOLTIP.SpellMap = {
    [239] = 1254551,
    [556] = 1254555,
    [161] = 1254557,
    [402] = 393273,
    [557] = 1254400,
    [558] = 1254572,
    [560] = 1254559,
    [559] = 1254563,
    [525] = 1216786,
    [499] = 445444,
    [505] = 445414,
    [503] = 445417,
    [542] = 1237215,
    [378] = 354465,
    [392] = 367416,
    [391] = 367416,
}

-- 161 Heavenreach Pinnacle: Alliance=1254557, Horde=159898
function EXMYTOOLTIP.GetTeleportSpellID(mapID)
    if mapID == 161 then
        local function IsKnown(id)
            if C_SpellBook and C_SpellBook.IsSpellKnown then
                return C_SpellBook.IsSpellKnown(id, Enum.SpellBookSpellBank.Player)
            end
            return IsSpellKnown and IsSpellKnown(id)
        end

        local faction = UnitFactionGroup and UnitFactionGroup("player") or ""
        local prefer = (faction == "Horde") and 159898 or 1254557
        local fallback = (prefer == 159898) and 1254557 or 159898

        if IsKnown(prefer) then
            return prefer
        end
        if IsKnown(fallback) then
            return fallback
        end
        return prefer
    end
    return EXMYTOOLTIP.SpellMap[mapID]
end

-- Helpers
function EXMYTOOLTIP.GetSpecPriority(specID)
    return InfinityDB:GetSpecRolePriority(specID)
end

function EXMYTOOLTIP.FormatTime(sec)
    if sec >= 3600 then
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        return string.format(L["%dh %dm"], h, m)
    elseif sec >= 60 then
        local m = math.floor(sec / 60)
        local s = math.floor(sec % 60)
        return string.format(L["%dm %ds"], m, s)
    else
        return string.format(L["%ds"], math.floor(sec))
    end
end

function EXMYTOOLTIP.RequestData()
    C_MythicPlus.RequestCurrentAffixes()
    C_MythicPlus.RequestMapInfo()
    C_MythicPlus.RequestRewards()
end

-- Core logic: update tooltip content
function EXMYTOOLTIP.UpdateTooltip(self)
    if not MODULE_DB.enabled then return end

    local mapID = self.mapID
    if not mapID and self:GetParent() and self:GetParent().mapID then
        mapID = self:GetParent().mapID
        self = self:GetParent()
    end

    if not mapID then return end

    local offset = 8
    local dungeonName, _, baseTimeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
    local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapID)

    local activeKeystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
    local timeLimit = baseTimeLimit or 0
    local dungeonIconStr = texture and string.format("|T%d:18:18:0:0|t ", texture) or ""

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    if intimeInfo then
        GameTooltip:AddLine(dungeonIconStr .. dungeonName, 1, 1, 1)

        local scoreColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(intimeInfo.dungeonScore)
        if scoreColor then
            GameTooltip:AddLine(L["Score: "] .. "|c" .. scoreColor:GenerateHexColor() .. intimeInfo.dungeonScore .. "|r")
        else
            GameTooltip:AddLine(L["Score: "] .. intimeInfo.dungeonScore)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Best Run"], 1, 0.75, 0)
        GameTooltip:AddLine(L["Level "] .. intimeInfo.level, 1, 1, 1)

        local completionTimeFormatted = string.format("%02d:%02d", math.floor(intimeInfo.durationSec / 60),
            intimeInfo.durationSec % 60)
        local remainingTime = timeLimit - intimeInfo.durationSec
        local remainingTimeFormatted
        if remainingTime >= 0 then
            remainingTimeFormatted = string.format(L["%02d:%02d left"], math.floor(remainingTime / 60), remainingTime % 60)
        else
            remainingTimeFormatted = string.format(L["%02d:%02d over"], math.abs(math.floor(remainingTime / 60)),
                math.abs(remainingTime % 60))
        end
        GameTooltip:AddLine(L["Time "] .. completionTimeFormatted .. " (" .. remainingTimeFormatted .. ")", 1, 1, 1)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffebca3f" .. L["Party Members"] .. "|r", 1, 0.75, 0)

        local sortedMembers = {}
        if intimeInfo.members then
            for _, member in ipairs(intimeInfo.members) do
                table.insert(sortedMembers, member)
            end
            table.sort(sortedMembers, function(a, b)
                local pA = EXMYTOOLTIP.GetSpecPriority(a.specID)
                local pB = EXMYTOOLTIP.GetSpecPriority(b.specID)
                if pA ~= pB then return pA < pB else return a.specID < b.specID end
            end)
        end

        for _, member in ipairs(sortedMembers) do
            local classInfo = InfinityDB.Classes[member.classID]
            local hex = classInfo and classInfo.colorHex or "ffffff"
            local _, _, _, specIcon = GetSpecializationInfoForSpecID(member.specID)
            local iconStr = specIcon and string.format("|T%d:17:17:0:0|t ", specIcon) or ""
            GameTooltip:AddLine(string.format("%s|cff%s%s|r", iconStr, hex, member.name or L["Unknown"]))
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Dungeon Timer: "] .. string.format("%02d:%02d", math.floor(timeLimit / 60), timeLimit % 60), 1, 1, 1)

        local completionDate = intimeInfo.completionDate
        if completionDate then
            local adjustedYear, adjustedMonth, adjustedDay = completionDate.year + 2000, completionDate.month + 1,
                completionDate.day + 1
            local adjustedHour, adjustedMinute = completionDate.hour + offset, completionDate.minute
            if adjustedHour >= 24 then
                adjustedHour = adjustedHour - 24
                adjustedDay = adjustedDay + 1
            end
            GameTooltip:AddLine(
                string.format(L["Completed: %02d/%02d/%02d %02d:%02d"], adjustedYear % 100, adjustedMonth, adjustedDay,
                    adjustedHour, adjustedMinute), 1, 1, 1)
        end
    else
        GameTooltip:AddLine(dungeonIconStr .. (dungeonName or L["Unknown Dungeon"]), 1, 1, 1)
        GameTooltip:AddLine(L["No run recorded this season"], 1, 0.5, 0.5)
    end

    -- Teleport logic
    local spellID = EXMYTOOLTIP.GetTeleportSpellID(mapID)
    if spellID and C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player) then
        -- Allow reading teleport cooldown during Mythic+ runs too
        local cd = C_Spell.GetSpellCooldown(spellID)
        if cd and cd.duration > 0 and cd.startTime > 0 then
            local remain = (cd.startTime + cd.duration) - GetTime()
            if remain > 0 then
                GameTooltip:AddLine(L["Teleport cooldown: "] .. EXMYTOOLTIP.FormatTime(remain), 1, 0.3, 0.3)
            else
                GameTooltip:AddLine(L["Teleport Ready"], 0, 1, 0)
            end
        else
            GameTooltip:AddLine(L["Teleport Ready"], 0, 1, 0)
        end
    end

    -- Font styling code was removed intentionally
    GameTooltip:Show()
end

-- Hook challenge panel icons
function EXMYTOOLTIP.HookDungeonIcons()
    if not ChallengesFrame or not ChallengesFrame.DungeonIcons then return end
    for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
        if not icon.INFINITY_Hooked then
            icon:HookScript("OnEnter", function(self) EXMYTOOLTIP.UpdateTooltip(self) end)
            icon:HookScript("OnLeave", function() GameTooltip:Hide() end)
            icon.INFINITY_Hooked = true
        end
    end
end

-- Initialize listeners
EXMYTOOLTIP.Frame = CreateFrame("Frame")
EXMYTOOLTIP.Frame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
EXMYTOOLTIP.Frame:SetScript("OnEvent", function() EXMYTOOLTIP.HookDungeonIcons() end)

-- Request data when the PVE frame is shown
if PVEFrame then
    PVEFrame:HookScript("OnShow", function() EXMYTOOLTIP.RequestData() end)
end

-- Periodically retry hooks for delayed UI loading
C_Timer.NewTicker(5, function() EXMYTOOLTIP.HookDungeonIcons() end)

-- Initial delayed setup
C_Timer.After(5, function()
    EXMYTOOLTIP.RequestData()
    EXMYTOOLTIP.HookDungeonIcons()
end)

-- Report module ready
InfinityTools:ReportReady(INFINITY_MODULE_KEY)
