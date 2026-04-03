-- [[ Mythic+ Damage Calculator ]]
-- { Key = "RevMplus.MythicDamage", Name = "Mythic+ Damage Calculator", Desc = "Calculates actual spell damage from key level scaling.", Category = 2 },

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })
local InfinityState = InfinityTools.State

-- 1. Module key
local INFINITY_MODULE_KEY = "RevMplus.MythicDamage"

-- 2. Load guard
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- 3. Database initialization
local INFINITY_DEFAULTS = {
    mythicLevel = 10,
    useColoredNumbers = true,
    abbreviateNumbers = true,
    damageColorR = 0.01,
    damageColorG = 1,
    damageColorB = 0.79,
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)

-- =========================================================
-- Core logic, defined before layout registration
-- =========================================================
local InfinityMythicDamage = { MODULE_DB = MODULE_DB }
_G.InfinityMythicDamage = InfinityMythicDamage

local SEASON_BASE_FACTORS = { [34] = 1.7660680614 }
local function GetBaseFactor() return SEASON_BASE_FACTORS[C_SeasonInfo.GetCurrentDisplaySeasonID()] or 1 end

local EXCLUDE_UNITS = { ["%"] = true }

local function FormatLargeNumber(v)
    if v >= 100000000 then
        return string.format(L["%.2fB"], v / 100000000)
    elseif v >= 10000 then
        return string.format(L["%dW"], math.floor(v / 10000))
    else
        return tostring(math.floor(v))
    end
end

function InfinityMythicDamage.GetCurrentMultiplier()
    local level = MODULE_DB.mythicLevel or 0
    local data = _G.InfinityDB and _G.InfinityDB.MythicDamageData
    if not data then return 1 end

    local baseMulti = data.LevelMultipliers[level] or (level >= 25 and data.LevelMultipliers[25] or 1)

    -- Apply the extra scaling only above level 10000
    if level >= 10000 then
        baseMulti = baseMulti * 1.2
    end

    -- Final multiplier including the season base factor
    local finalMulti = baseMulti * GetBaseFactor()
    -- Clamp to 1 when the calculated multiplier is too low
    return finalMulti > 1 and finalMulti or 1
end

function InfinityMythicDamage.ProcessDamageText(text, multiplier)
    if not text or not multiplier or multiplier <= 1 then return text end

    local db = _G.InfinityToolsDB and _G.InfinityToolsDB.ModuleDB and _G.InfinityToolsDB.ModuleDB["RevMplus.MythicDamage"] or MODULE_DB
    local r, g, b = db.damageColorR or 1, db.damageColorG or 0.82, db.damageColorB or 0
    local useColor = db.useColoredNumbers
    local abbreviate = db.abbreviateNumbers

    local hex = string.format("%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))

    -- Spell tooltip numbers already include Versatility, so remove it before applying key scaling
    local versa = (InfinityState and InfinityState.PStat_Versa) or 0
    local correctedMultiplier = multiplier / (1 + versa / 100)

    -- Replace numeric values found in the text
    return text:gsub("([%d,，%.]+)(%%?)", function(numStr, percent)
        if percent == "%" then return numStr .. percent end

        local value = tonumber(numStr:gsub("[,，]", ""), 10)
        if not value or value < 10 then return numStr end

        -- Skip this number if the next character is a blacklisted unit suffix
        local pos = text:find(numStr, 1, true)
        if pos then
            local nextChar = text:sub(pos + #numStr, pos + #numStr + 2)
            if EXCLUDE_UNITS[nextChar] then
                return numStr
            end
        end

        local nv = math.floor(value * correctedMultiplier)
        local f = abbreviate and FormatLargeNumber(nv) or
            tostring(nv):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")

        return useColor and ("|cff" .. hex .. f .. "|r") or f
    end)
end

-- =========================================================
-- [v4.2] Registration and configuration
-- =========================================================

-- 1. Grid layout
local function REGISTER_LAYOUT()
    local level = MODULE_DB.mythicLevel or 10
    local multi = InfinityMythicDamage and InfinityMythicDamage.GetCurrentMultiplier and InfinityMythicDamage.GetCurrentMultiplier() or 1
    local seasonID = C_SeasonInfo.GetCurrentDisplaySeasonID()
    local descLabel = string.format(L["Current Level: |cffffd100%d|r\nSeason Coefficient (ID:%d): |cffffd100%.2f|r\nFinal Multiplier: |cff00ff00%.2f|r\n\nWhen enabled, spell description numbers are adjusted in real time by this multiplier."],
        level, seasonID, 1.76, multi
    )

    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 53, h = 2, label = L["Mythic Damage Calc"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 53, h = 2, label = L["Spell description values scale with keystone level."] },
        { key = "ctrl_h", type = "subheader", x = 2, y = 7, w = 52, h = 1, label = L["Core Settings"], labelSize = 20 },
        { key = "divider_3221", type = "divider", x = 2, y = 8, w = 53, h = 1, label = L["Components"] },
        { key = "useColoredNumbers", type = "checkbox", x = 2, y = 10, w = 10, h = 2, label = L["Color Numbers"] },
        { key = "mythicLevel", type = "slider", x = 2, y = 14, w = 14, h = 2, label = L["Simulated Level (0-30)"], min = 0, max = 30 },
        { key = "damageColor", type = "color", x = 17, y = 14, w = 12, h = 2, label = L["Damage Number Color"] },
        { key = "openSpellInfo", type = "button", x = 30, y = 14, w = 12, h = 2, label = L["M+ Mob Spells"] },
        { key = "abbreviateNumbers", type = "checkbox", x = 17, y = 10, w = 10, h = 2, label = L["Shorten Numbers (W/B)"] },
        {
            key = "info",
            type = "description",
            x = 2,
            y = 19,
            w = 53,
            h = 6,
            label = "|cff888888" .. L["Note: levels above 10 already include the 1.2x base modifier outside Tyrannical/Fortified.\nThis setting directly affects MDT enhancements and spell detail displays."] .. "|r"
        },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

-- 3. Register immediately
REGISTER_LAYOUT()

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function()
    -- Rebuild the layout so preview text updates
    REGISTER_LAYOUT()

    -- Do not call RefreshContent here: it would create a loop
    -- (Setter -> DBChanged -> Refresh -> Render -> Setter).
    -- Widgets already updated their own visuals.
    -- if InfinityTools.UI and InfinityTools.UI.CurrentModule == INFINITY_MODULE_KEY then
    --     InfinityTools.UI:RefreshContent()
    -- end
    -- Refresh external consumers
    if _G.InfinitySpellInfo and _G.InfinitySpellInfo.RefreshRightPanel then _G.InfinitySpellInfo:RefreshRightPanel() end
end)

-- Button click handler
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(data)
    if data.key == "openSpellInfo" then
        if _G.InfinitySpellInfo and _G.InfinitySpellInfo.ToggleFrame then _G.InfinitySpellInfo:ToggleFrame() end
    end
end)

-- Report module ready
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

