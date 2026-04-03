-- =============================================================
-- [[ Player Position Marker >> RevTools.PlayerPosition ]]
-- =============================================================
local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end

local INFINITY_MODULE_KEY = "RevTools.PlayerPosition"

-- =============================================================
-- 1. Grid layout definition
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        { key = "head", type = "header", x = 1, y = 1, w = 50, h = 2, label = "Player Position Marker", labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 50, h = 2, label = "Prefer local PNG assets. If missing, automatically fall back to code-drawn shapes." },

        -- Basic
        { key = "div1", type = "divider", x = 1, y = 6, w = 50, h = 1 },
        { key = "enabled", type = "checkbox", x = 1, y = 8, w = 20, h = 2, label = "Enable Marker" },
        {
            key = "shapeType",
            type = "dropdown",
            x = 1,
            y = 13,
            w = 20,
            h = 2,
            label = "Shape Style",
            items = {
                { "Square", "SQUARE" },
                { "Cross", "CROSS" },
                { "Circle", "CIRCLE" },
                { "Ring", "RING" },
                { "Diamond", "DIAMOND" },
            }
        },

        { key = "scale", type = "slider", x = 21, y = 13, w = 19, h = 2, label = "Scale", min = 0.1, max = 1.5, step = 0.1 },
        { key = "color", type = "color", x = 18, y = 27, w = 12, h = 2, label = "Normal Color" },

        -- Offset
        { key = "offsetX", type = "slider", x = 1, y = 17, w = 20, h = 2, label = "X Offset", min = -500, max = 500, step = 1 },
        { key = "offsetY", type = "slider", x = 21, y = 17, w = 19, h = 2, label = "Y Offset", min = -500, max = 500, step = 1 },

        -- Range check
        { key = "div_range", type = "divider", x = 1, y = 22, w = 50, h = 1 },
        { key = "h_range", type = "subheader", x = 1, y = 20, w = 50, h = 2, label = "Range Check", labelSize = 20 },
        { key = "desc_range", type = "description", x = 1, y = 23, w = 50, h = 2, label = "Change icon color when out of range (blank = use spec preset automatically)" },

        { key = "rangeSpell", type = "input", x = 1, y = 27, w = 15, h = 2, label = "Range Spell (ID)", placeholder = "Default: spec preset" },
        { key = "rangeColor", type = "color", x = 33, y = 27, w = 12, h = 2, label = "Out-of-Range Color" },

        -- Display conditions
        { key = "div2", type = "divider", x = 1, y = 33, w = 50, h = 1 },
        { key = "h_vis", type = "subheader", x = 1, y = 31, w = 50, h = 2, label = "Display Conditions", labelSize = 20 },
        {
            key = "visibility",
            type = "multiselect",
            x = 1,
            y = 36,
            w = 25,
            h = 2,
            label = "Trigger Context",
            items = { "Show in Combat", "Show out of Combat", "Instances Only" }
        },

        -- Spec filter (Hardcoded Items List sorted by Class ID)
        { key = "h_specs", type = "subheader", x = 1, y = 40, w = 50, h = 2, label = "Spec Filter (only enabled for checked specs)" },
        {
            key = "enabledSpecs",
            type = "multiselect",
            x = 1,
            y = 44,
            w = 51,
            h = 2,
            label = "Enabled Specs",
            items = {
                "|cffC79C6EWarrior|r - Arms",
                "|cffC79C6EWarrior|r - Fury",
                "|cffC79C6EWarrior|r - Protection",
                "|cffF48CBAPaladin|r - Holy",
                "|cffF48CBAPaladin|r - Protection",
                "|cffF48CBAPaladin|r - Retribution",
                "|cffABD473Hunter|r - Beast Mastery",
                "|cffABD473Hunter|r - Marksmanship",
                "|cffABD473Hunter|r - Survival",
                "|cffFFF468Rogue|r - Assassination",
                "|cffFFF468Rogue|r - Outlaw",
                "|cffFFF468Rogue|r - Subtlety",
                "|cffFFFFFFPriest|r - Discipline",
                "|cffFFFFFFPriest|r - Holy",
                "|cffFFFFFFPriest|r - Shadow",
                "|cffC41E3ADeath Knight|r - Blood",
                "|cffC41E3ADeath Knight|r - Frost",
                "|cffC41E3ADeath Knight|r - Unholy",
                "|cff0070DDShaman|r - Elemental",
                "|cff0070DDShaman|r - Enhancement",
                "|cff0070DDShaman|r - Restoration",
                "|cff3FC7EBMage|r - Arcane",
                "|cff3FC7EBMage|r - Fire",
                "|cff3FC7EBMage|r - Frost",
                "|cff8788EEWarlock|r - Affliction",
                "|cff8788EEWarlock|r - Demonology",
                "|cff8788EEWarlock|r - Destruction",
                "|cff00FF98Monk|r - Brewmaster",
                "|cff00FF98Monk|r - Windwalker",
                "|cff00FF98Monk|r - Mistweaver",
                "|cffFF7C0ADruid|r - Balance",
                "|cffFF7C0ADruid|r - Feral",
                "|cffFF7C0ADruid|r - Guardian",
                "|cffFF7C0ADruid|r - Restoration",
                "|cffA330C9Demon Hunter|r - Havoc",
                "|cffA330C9Demon Hunter|r - Vengeance",
                "|cff33937FEvoker|r - Devastation",
                "|cff33937FEvoker|r - Preservation",
                "|cff33937FEvoker|r - Augmentation",
                "|cffA330C9Demon Hunter|r - Reaper" -- assumed third spec placeholder
            }
        },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =============================================================
-- 2. Data initialization
-- =============================================================
local MODULE_DEFAULTS = {
    enabled = false,
    shapeType = "CROSS",
    scale = 0.5,
    offsetX = 0,
    offsetY = 0,

    colorR = 0.15,
    colorG = 1,
    colorB = 0.25,
    colorA = 1,

    rangeSpell = "",
    rangeColorR = 1,
    rangeColorG = 0,
    rangeColorB = 0,
    rangeColorA = 1,

    visibility = { ["Show in Combat"] = true, ["Show out of Combat"] = true, ["Instances Only"] = true },

    -- Default: all specs selected
    enabledSpecs = {
        ["|cffC79C6EWarrior|r - Arms"] = true,
        ["|cffC79C6EWarrior|r - Fury"] = true,
        ["|cffC79C6EWarrior|r - Protection"] = true,
        ["|cffF48CBAPaladin|r - Holy"] = true,
        ["|cffF48CBAPaladin|r - Protection"] = true,
        ["|cffF48CBAPaladin|r - Retribution"] = true,
        ["|cffABD473Hunter|r - Beast Mastery"] = true,
        ["|cffABD473Hunter|r - Marksmanship"] = true,
        ["|cffABD473Hunter|r - Survival"] = true,
        ["|cffFFF468Rogue|r - Assassination"] = true,
        ["|cffFFF468Rogue|r - Outlaw"] = true,
        ["|cffFFF468Rogue|r - Subtlety"] = true,
        ["|cffFFFFFFPriest|r - Discipline"] = true,
        ["|cffFFFFFFPriest|r - Holy"] = true,
        ["|cffFFFFFFPriest|r - Shadow"] = true,
        ["|cffC41E3ADeath Knight|r - Blood"] = true,
        ["|cffC41E3ADeath Knight|r - Frost"] = true,
        ["|cffC41E3ADeath Knight|r - Unholy"] = true,
        ["|cff0070DDShaman|r - Elemental"] = true,
        ["|cff0070DDShaman|r - Enhancement"] = true,
        ["|cff0070DDShaman|r - Restoration"] = true,
        ["|cff3FC7EBMage|r - Arcane"] = true,
        ["|cff3FC7EBMage|r - Fire"] = true,
        ["|cff3FC7EBMage|r - Frost"] = true,
        ["|cff8788EEWarlock|r - Affliction"] = true,
        ["|cff8788EEWarlock|r - Demonology"] = true,
        ["|cff8788EEWarlock|r - Destruction"] = true,
        ["|cff00FF98Monk|r - Brewmaster"] = true,
        ["|cff00FF98Monk|r - Windwalker"] = true,
        ["|cff00FF98Monk|r - Mistweaver"] = true,
        ["|cffFF7C0ADruid|r - Balance"] = true,
        ["|cffFF7C0ADruid|r - Feral"] = true,
        ["|cffFF7C0ADruid|r - Guardian"] = true,
        ["|cffFF7C0ADruid|r - Restoration"] = true,
        ["|cffA330C9Demon Hunter|r - Havoc"] = true,
        ["|cffA330C9Demon Hunter|r - Vengeance"] = true,
        ["|cff33937FEvoker|r - Devastation"] = true,
        ["|cff33937FEvoker|r - Preservation"] = true,
        ["|cff33937FEvoker|r - Augmentation"] = true,
        ["|cffA330C9Demon Hunter|r - Reaper"] = true
    }
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =============================================================
-- 3. Core business logic
-- =============================================================
local IndicatorFrame = CreateFrame("Frame", "InfinityPlayerPositionIndicator", UIParent)
IndicatorFrame:SetFrameStrata("MEDIUM") -- [v1.1 Fix] Lower strata to avoid covering too many UI elements
IndicatorFrame:SetSize(64, 64)
IndicatorFrame:SetIgnoreParentAlpha(true)
InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, IndicatorFrame)
-- RegisterHUD internally forces EnableMouse(true); disable it afterward to allow click-through
IndicatorFrame:EnableMouse(false)
IndicatorFrame.textures = {}
IndicatorFrame:Hide()

local TEXTURE_PATHS = {
    ["SQUARE"] = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\PlayerPosition\\Square.png",
    ["CROSS"] = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\PlayerPosition\\Cross.png",
    ["CIRCLE"] = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\PlayerPosition\\Circle.png",
    ["RING"] = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\PlayerPosition\\Ring.png",
    ["DIAMOND"] = "Interface\\AddOns\\InfinityMythicPlus\\Textures\\PlayerPosition\\Diamond.png",
}

-- Get or create Texture
local function GetTex(idx)
    if not IndicatorFrame.textures[idx] then
        IndicatorFrame.textures[idx] = IndicatorFrame:CreateTexture(nil, "ARTWORK")
    end
    local t = IndicatorFrame.textures[idx]
    t:ClearAllPoints()
    t:SetTexCoord(0, 1, 0, 1)
    t:Show()
    t:SetRotation(0)
    return t
end

-- Draw shape
local function DrawShape(shape)
    for _, tex in ipairs(IndicatorFrame.textures) do tex:Hide() end
    local w, h = IndicatorFrame:GetSize()

    local path = TEXTURE_PATHS[shape]
    if path then
        local t = GetTex(1); t:SetAllPoints()
        if t:SetTexture(path) then return end -- Success
    end

    -- Fallback: Code Drawing
    if shape == "SQUARE" then
        local t = GetTex(1); t:SetAllPoints(); t:SetColorTexture(1, 1, 1, 1)
    elseif shape == "CROSS" then
        local thickness = 0.125
        local t1 = GetTex(1); t1:SetPoint("CENTER"); t1:SetSize(w * thickness, h); t1:SetColorTexture(1, 1, 1, 1)
        local t2 = GetTex(2); t2:SetPoint("CENTER"); t2:SetSize(w, h * thickness); t2:SetColorTexture(1, 1, 1, 1)
    elseif shape == "DIAMOND" then
        local t = GetTex(1); t:SetSize(w * 0.707, h * 0.707); t:SetPoint("CENTER"); t:SetColorTexture(1, 1, 1, 1); t
            :SetRotation(math.rad(45))
    else
        local t = GetTex(1); t:SetAllPoints(); t:SetColorTexture(1, 1, 1, 1)
    end
end

-- Get the currently active range-check spell
local function GetRangeSpell()
    -- 1. User-entered value takes priority
    local userSpell = MODULE_DB.rangeSpell
    if userSpell and userSpell ~= "" then
        -- Try number conversion
        local spellID = tonumber(userSpell)
        return spellID or userSpell
    end

    -- 2. Fall back to spec preset
    if InfinityTools.State and InfinityTools.DB_Static then
        local specID = InfinityTools.State.SpecID
        if specID and specID > 0 and InfinityTools.DB_Static.SpecByID then
            local specInfo = InfinityTools.DB_Static.SpecByID[specID]
            if specInfo and specInfo.RangeSpell then
                return specInfo.RangeSpell
            end
        end
    end

    return nil
end

-- Color update logic (Range Check)
local function UpdateColor()
    local r, g, b, a = MODULE_DB.colorR or 1, MODULE_DB.colorG or 1, MODULE_DB.colorB or 1, MODULE_DB.colorA or 1

    -- Range Check Logic
    local spell = GetRangeSpell()
    if spell and UnitExists("target") then
        local inRange = C_Spell.IsSpellInRange(spell, "target")
        if inRange == false then
            -- Out of Range
            r, g, b, a = MODULE_DB.rangeColorR or 1, MODULE_DB.rangeColorG or 0, MODULE_DB.rangeColorB or 0, MODULE_DB.rangeColorA or 1
        end
    end

    for _, t in ipairs(IndicatorFrame.textures) do
        if t:IsShown() then t:SetVertexColor(r, g, b, a) end
    end
end

-- OnUpdate Loop
local throttle = 0
IndicatorFrame:SetScript("OnUpdate", function(self, elapsed)
    throttle = throttle + elapsed
    if throttle > 0.1 then
        UpdateColor()
        throttle = 0
    end
end)

-- Visibility logic
local function UpdateIndicatorVisibility()
    if not MODULE_DB.enabled then
        IndicatorFrame:Hide(); return
    end

    local inInstance = InfinityTools.State.InInstance
    if MODULE_DB.visibility["Instances Only"] and not inInstance then
        IndicatorFrame:Hide(); return
    end

    -- Spec Check
    if InfinityTools.State.ClassID and InfinityTools.State.SpecID then
        local cName = InfinityTools.State.ClassName
        local sName = InfinityTools.State.SpecName
        local classInfo = nil
        if _G.InfinityDB and _G.InfinityDB.Classes then
            classInfo = _G.InfinityDB.Classes[InfinityTools.State.ClassID]
        end

        if classInfo and cName and sName then
            local colorHex = classInfo.colorHex or "FFFFFF"
            local entryName = string.format("|cff%s%s|r - %s", colorHex, classInfo.name, sName)

            -- Check if enabled in DB (Default true if nil, but defaults should handle it)
            if MODULE_DB.enabledSpecs and MODULE_DB.enabledSpecs[entryName] == false then
                IndicatorFrame:Hide(); return
            end
        end
    end

    local show = InfinityTools.State.InCombat and MODULE_DB.visibility["Show in Combat"] or MODULE_DB.visibility["Show out of Combat"]
    if show then IndicatorFrame:Show() else IndicatorFrame:Hide() end
end

-- Main Refresh
local function RefreshIndicator()
    IndicatorFrame:ClearAllPoints()
    IndicatorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.offsetX, MODULE_DB.offsetY)
    IndicatorFrame:SetScale(MODULE_DB.scale or 1)

    DrawShape(MODULE_DB.shapeType or "SQUARE")
    UpdateColor()
    UpdateIndicatorVisibility()
end

-- Events
InfinityTools:WatchState("InCombat", INFINITY_MODULE_KEY, UpdateIndicatorVisibility)
InfinityTools:WatchState("InInstance", INFINITY_MODULE_KEY, UpdateIndicatorVisibility)
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, RefreshIndicator)

-- Spec Change Event (Since we filter by spec)
InfinityTools:WatchState("SpecID", INFINITY_MODULE_KEY, UpdateIndicatorVisibility)

-- Init
C_Timer.After(1, function()
    RefreshIndicator()
    local current = GetRangeSpell() or "None"
    -- print("|cff00ff00[InfinityTools] PlayerPosition: Ready (RangeSpell: "..tostring(current)..")|r")
end)
InfinityTools:ReportReady(INFINITY_MODULE_KEY)
