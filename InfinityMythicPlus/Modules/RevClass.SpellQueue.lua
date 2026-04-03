-- =============================================================
-- [[ Global Spell Queue Window ]]
-- { Key = "RevTools.SpellQueue", Name = "Global Spell Queue Window", Desc = "Automatically adjusts SpellQueueWindow based on your current specialization.", Category = 5 },
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })
local InfinityState = InfinityTools.State

-- =============================================================
-- Part 1: Module key and load guard
-- =============================================================
local INFINITY_MODULE_KEY = "RevTools.SpellQueue"

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =============================================================
-- Part 2: Dependencies and database initialization
-- =============================================================
local InfinityDB = _G.InfinityDB
if not InfinityDB then return end

local INFINITY_DEFAULTS = {
    enabled = false,
    aiMode = false,
    globalFixed = 400,
    globalOffset = 0,
    specs = {},   -- Fixed mode: one fixed delay value per spec
    specsAI = {}, -- AI mode: one offset value per spec
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)


local function GetCurrentInfo()
    local s = InfinityState
    local curV = GetCVar("SpellQueueWindow") or "400"
    local cHex = "ffffff"
    if s.ClassID and InfinityDB.Classes[s.ClassID] then cHex = InfinityDB.Classes[s.ClassID].colorHex end
    local sIcon = (s.SpecID and InfinityDB.SpecByID[s.SpecID]) and InfinityDB.SpecByID[s.SpecID].icon or 0
    local iStr = sIcon > 0 and string.format("|T%d:14:14:0:0|t ", sIcon) or ""
    return string.format(L["Current: %s|cff%s%s - %s|r | System: |cffffd100%sms|r"], iStr, cHex, s.ClassName or L["Unknown"],
        s.SpecName or L["Unknown"], curV)
end

local function REGISTER_LAYOUT()
    -- Grid engine data
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 49, h = 2, label = L["Spell Queue Latency (SpellQueueWindow)"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 30, h = 2, label = L["AI mode: queue window = latency + offset. Fixed mode: queue window = configured value."] },
        { key = "live_status", type = "description", x = 2, y = 5, w = 49, h = 2, label = GetCurrentInfo() },
        { key = "ctrl_header", type = "subheader", x = 2, y = 7, w = 49, h = 2, label = L["Core Controls"], labelPos = "top" },
        { key = "enabled", type = "checkbox", x = 4, y = 11, w = 8, h = 2, label = L["Enable Feature"] },
        { key = "aiMode", type = "checkbox", x = 14, y = 11, w = 8, h = 2, label = "|cff00ffff" .. L["Enable AI Smart Mode"] .. "|r" },
        { key = "globalFixed", type = "input", x = 26, y = 11, w = 15, h = 2, label = L["Global Default Latency (Fixed)"], labelSize = 17 },
        { key = "h_plate_classes", type = "subheader", x = 2, y = 15, w = 49, h = 1, label = L["Plate Classes"] },
        { key = "250", type = "input", x = 9, y = 18, w = 9, h = 2, label = "|T135770:14:14:0:0|t |cffC41E3ABlood|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "251", type = "input", x = 25, y = 18, w = 9, h = 2, label = "|T135773:14:14:0:0|t |cffC41E3AFrost|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "252", type = "input", x = 42, y = 18, w = 9, h = 2, label = "|T135775:14:14:0:0|t |cffC41E3AUnholy|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "71", type = "input", x = 25, y = 20, w = 9, h = 2, label = "|T132355:14:14:0:0|t |cffC79C6EArms|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "72", type = "input", x = 42, y = 20, w = 9, h = 2, label = "|T132347:14:14:0:0|t |cffC79C6EFury|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "73", type = "input", x = 9, y = 20, w = 9, h = 2, label = "|T132341:14:14:0:0|t |cffC79C6EProtection|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "65", type = "input", x = 42, y = 22, w = 9, h = 2, label = "|T135920:14:14:0:0|t |cffF48CBAHoly|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "66", type = "input", x = 9, y = 22, w = 9, h = 2, label = "|T236264:14:14:0:0|t |cffF48CBAProtection|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "70", type = "input", x = 25, y = 22, w = 9, h = 2, label = "|T135873:14:14:0:0|t |cffF48CBARetribution|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "h_mail_classes", type = "subheader", x = 2, y = 27, w = 49, h = 1, label = L["Mail Classes"] },
        { key = "253", type = "input", x = 42, y = 32, w = 9, h = 2, label = "|T461112:14:14:0:0|t |cffABD473Beast Mastery|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "254", type = "input", x = 25, y = 32, w = 9, h = 2, label = "|T236179:14:14:0:0|t |cffABD473Marksmanship|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "255", type = "input", x = 9, y = 32, w = 9, h = 2, label = "|T461113:14:14:0:0|t |cffABD473Survival|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "262", type = "input", x = 9, y = 30, w = 9, h = 2, label = "|T136048:14:14:0:0|t |cff0070DDElemental|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "263", type = "input", x = 25, y = 30, w = 9, h = 2, label = "|T237581:14:14:0:0|t |cff0070DDEnhancement|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "264", type = "input", x = 42, y = 30, w = 9, h = 2, label = "|T136052:14:14:0:0|t |cff0070DDRestoration|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "1467", type = "input", x = 9, y = 34, w = 9, h = 2, label = "|T4511811:14:14:0:0|t |cff33937FDevastation|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "1468", type = "input", x = 42, y = 34, w = 9, h = 2, label = "|T4511812:14:14:0:0|t |cff33937FPreservation|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "1473", type = "input", x = 25, y = 34, w = 9, h = 2, label = "|T5198700:14:14:0:0|t |cff33937FAugmentation|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "h_leather_classes", type = "subheader", x = 2, y = 39, w = 49, h = 1, label = L["Leather Classes"] },
        { key = "577", type = "input", x = 25, y = 42, w = 9, h = 2, label = "|T1247264:14:14:0:0|t |cffA330C9Havoc|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "581", type = "input", x = 9, y = 42, w = 9, h = 2, label = "|T1247265:14:14:0:0|t |cffA330C9Vengeance|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "1480", type = "input", x = 42, y = 42, w = 9, h = 2, label = "|T7455385:14:14:0:0|t |cffA330C9Fel-Scythe|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "259", type = "input", x = 25, y = 44, w = 9, h = 2, label = "|T236270:14:14:0:0|t |cffFFF468Assassination|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "260", type = "input", x = 9, y = 44, w = 9, h = 2, label = "|T236286:14:14:0:0|t |cffFFF468Outlaw|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "261", type = "input", x = 42, y = 44, w = 9, h = 2, label = "|T132320:14:14:0:0|t |cffFFF468Subtlety|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "268", type = "input", x = 9, y = 46, w = 9, h = 2, label = "|T608951:14:14:0:0|t |cff00FF98Brewmaster|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "269", type = "input", x = 25, y = 46, w = 9, h = 2, label = "|T608953:14:14:0:0|t |cff00FF98Windwalker|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "270", type = "input", x = 42, y = 46, w = 9, h = 2, label = "|T608952:14:14:0:0|t |cff00FF98Mistweaver|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "102", type = "input", x = 33, y = 48, w = 6, h = 2, label = "|T136096:14:14:0:0|t |cffFF7C0ABalance|r", parentKey = "specs", labelPos = "left" },
        { key = "103", type = "input", x = 21, y = 48, w = 6, h = 2, label = "|T132115:14:14:0:0|t |cffFF7C0AFeral|r", parentKey = "specs", labelPos = "left" },
        { key = "104", type = "input", x = 9, y = 48, w = 6, h = 2, label = "|T132276:14:14:0:0|t |cffFF7C0AGuardian|r", parentKey = "specs", labelPos = "left" },
        { key = "105", type = "input", x = 45, y = 48, w = 6, h = 2, label = "|T136041:14:14:0:0|t |cffFF7C0ARestoration|r", parentKey = "specs", labelPos = "left" },
        { key = "h_cloth_classes", type = "subheader", x = 2, y = 53, w = 49, h = 1, label = L["Cloth Classes"] },
        { key = 62, type = "input", x = 42, y = 56, w = 9, h = 2, label = "|T135932:14:14:0:0|t |cff3FC7EBArcane|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = 63, type = "input", x = 25, y = 56, w = 9, h = 2, label = "|T135810:14:14:0:0|t |cff3FC7EBFire|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = 64, type = "input", x = 9, y = 56, w = 9, h = 2, label = "|T135846:14:14:0:0|t |cff3FC7EBFrost|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = 265, type = "input", x = 25, y = 58, w = 9, h = 2, label = "|T136145:14:14:0:0|t |cff8788EEAffliction|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "266", type = "input", x = 42, y = 58, w = 9, h = 2, label = "|T136172:14:14:0:0|t |cff8788EEDemonology|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = 267, type = "input", x = 9, y = 58, w = 9, h = 2, label = "|T136186:14:14:0:0|t |cff8788EEDestruction|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = 256, type = "input", x = 9, y = 60, w = 9, h = 2, label = "|T135940:14:14:0:0|t |cffFFFFFFDiscipline|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = 257, type = "input", x = 25, y = 60, w = 9, h = 2, label = "|T237542:14:14:0:0|t |cffFFFFFFHoly|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = 258, type = "input", x = 42, y = 60, w = 9, h = 2, label = "|T136207:14:14:0:0|t |cffFFFFFFShadow|r", parentKey = "specs", labelPos = "left", labelSize = 18 },
        { key = "divider_9437", type = "divider", x = 2, y = 9, w = 49, h = 1, label = "" },
        { key = "divider_4513", type = "divider", x = 2, y = 16, w = 49, h = 1, label = "" },
        { key = "divider_6806", type = "divider", x = 2, y = 28, w = 49, h = 1, label = "" },
        { key = "divider_8842", type = "divider", x = 2, y = 40, w = 49, h = 1, label = "" },
        { key = "divider_5635", type = "divider", x = 2, y = 54, w = 49, h = 1, label = "" },
    }






    -- 3. Logic adaptation area, updated before registration for AI-mode dependent fields
    -- Use local Lua logic to swap parentKey without changing the static layout structure
    local targetStorage = MODULE_DB.aiMode and "specsAI" or "specs"
    local suffix = MODULE_DB.aiMode and " |cff00ffff(AI)|r" or ""

    for i = 1, #layout do
        local item = layout[i]

        -- Global default value switch
        -- Force-correct parentKey based on aiMode regardless of whether the layout currently says globalFixed or globalOffset
        if item.key == "globalFixed" or item.key == "globalOffset" then
            if MODULE_DB.aiMode then
                item.key = "globalOffset"
                item.baseLabel = item.baseLabel or item.label
                item.label = L["Global Latency Offset |cff00ffff(AI)|r"]
            else
                item.key = "globalFixed"
                item.baseLabel = item.baseLabel or item.label
                item.label = L["Global Default Latency (Fixed)"]
            end
        end

        -- Handle all spec-specific input boxes
        if item.parentKey == "specs" or item.parentKey == "specsAI" then
            item.parentKey = targetStorage
            -- Append the AI suffix dynamically
            if MODULE_DB.aiMode then
                item.baseLabel = item.baseLabel or item.label
                if item.label and not item.label:find("AI") then
                    item.label = suffix .. item.label
                end
            else
                -- Restore the original label if baseLabel exists
                if item.baseLabel then item.label = item.baseLabel end
            end
        end
    end

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

local function ApplySpellQueue()
    if not MODULE_DB.enabled then return end

    local state = InfinityState
    local specID = state.SpecID
    if not specID or specID == 0 then return end

    local storage = MODULE_DB.aiMode and MODULE_DB.specsAI or MODULE_DB.specs
    -- Read the split global values
    local defaultVal = MODULE_DB.aiMode and MODULE_DB.globalOffset or MODULE_DB.globalFixed
    local val = storage[specID] or defaultVal or 400

    local finalVal = tonumber(val) or 400

    if MODULE_DB.aiMode then
        local _, _, _, lagWorld = GetNetStats()
        lagWorld = lagWorld or 0
        if lagWorld < 300 then
            finalVal = lagWorld + finalVal
        end
    end

    finalVal = math.max(0, math.min(400, finalVal))
    SetCVar("SpellQueueWindow", finalVal)
end

-- =============================================================
-- Part 4: Events and state subscriptions
-- =============================================================
-- Watch database changes from the options UI
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(changeInfo)
    local key = type(changeInfo) == "table" and changeInfo.key or changeInfo
    if key == "aiMode" then
        if MODULE_DB.aiMode then
            print("|cff00ffff[Infinity]|r " .. L["Switched to AI mode (queue window = latency + offset)"])
        else
            print("|cff00ff00[Infinity]|r " .. L["Switched to fixed manual mode (queue window = fixed value)"])
        end
    end
    ApplySpellQueue()

    -- Update only the status text to avoid resetting the scroll position
    if InfinityTools.Grid and InfinityTools.Grid.Widgets then
        local w = InfinityTools.Grid.Widgets["live_status"]
        if w and w.text then w.text:SetText(GetCurrentInfo()) end
    end

    -- Only do a full refresh when AI mode toggles because the layout structure changes
    if key == "aiMode" then
        REGISTER_LAYOUT()
        if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() and InfinityTools.UI.CurrentModule == INFINITY_MODULE_KEY then
            InfinityTools.UI:RefreshContent()
        end
    end
end)

-- Watch talent/class changes from the core framework
local function OnIdentityChanged()
    REGISTER_LAYOUT() -- Rebuild the layout so status text updates
    ApplySpellQueue()

    -- Refresh the UI if this module is currently open
    if InfinityTools.UI and InfinityTools.UI.MainFrame and InfinityTools.UI.MainFrame:IsShown() and InfinityTools.UI.CurrentModule == INFINITY_MODULE_KEY then
        InfinityTools.UI:RefreshContent()
    end
end

InfinityTools:WatchState("SpecID", INFINITY_MODULE_KEY, OnIdentityChanged)
InfinityTools:WatchState("ClassName", INFINITY_MODULE_KEY, OnIdentityChanged)
InfinityTools:WatchState("SpecName", INFINITY_MODULE_KEY, OnIdentityChanged)

-- =============================================================
-- Part 5: Initialization and ready report
-- =============================================================
C_Timer.After(2, ApplySpellQueue)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)

-- =============================================================
-- Part 6: Initial layout registration
-- =============================================================
REGISTER_LAYOUT()

