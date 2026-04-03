-- [[ Mythic+ Icon Overlay ]]
-- { Key = "RevMplusInfo.MythicIcon", Name = "Mythic+ Icon Overlay", Desc = "Shows dungeon short names, best level, and score on challenge panel icons.", Category = 2 },

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end
local InfinityState = InfinityTools.State
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

-- 1. Module key
local INFINITY_MODULE_KEY = "RevMplusInfo.MythicIcon"

-- 2. Load guard
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local InfinityDB = _G.InfinityDB

-- Define map names and helpers before REGISTER_LAYOUT
local defaultMapNamesINFINITY = {
    [239] = "Seat",
    [556] = "Mold",
    [161] = "Sky",
    [402] = "Eco",
    [557] = "Vortex",
    [558] = "MGT",
    [560] = "Myza",
    [559] = "Nexus",
    -- 11.2
    [525] = "Gate",
    [499] = "Prior",
    [505] = "Dawn",
    [503] = "Echo",
    [542] = "EcoDome",
    [378] = "Amend",
    [392] = "Taz",
    [391] = "TazS",
}

local function INFINITY_GetSeasonMaps()
    local maps = C_ChallengeMode and C_ChallengeMode.GetMapTable()
    if maps and #maps > 0 then return maps end
    local list = {}
    for id in pairs(defaultMapNamesINFINITY) do table.insert(list, id) end
    table.sort(list)
    return list
end

local function INFINITY_GetBlizzMapName(mapID)
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    local fallback = defaultMapNamesINFINITY[mapID]
    return (name and name ~= "") and name or (fallback and L[fallback] or tostring(mapID))
end

-- 3. Default database values
local INFINITY_DEFAULTS = {
    displayOptions = {
        showBestLevel = true,
        showScore = true,
    },
    levelStyle = {
        a = 1,
        b = 1,
        font = nil,
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = true,
        size = 29,
        x = 0,
        y = -1,
    },
    mapNames = {
        [161] = "SR",
        [239] = "Seat",
        [378] = "HoA",
        [391] = "Streets",
        [392] = "Gambit",
        [402] = "AA",
        [499] = "Priory",
        [503] = "Echoes",
        [505] = "Dawn",
        [525] = "Flood",
        [542] = "Eco",
        [556] = "POS",
        [557] = "WS",
        [558] = "MT",
        [559] = "NPX",
        [560] = "MC",
    },
    nameStyle = {
        a = 1,
        b = 0.04,
        font = nil,
        g = 0.63,
        outline = "THICKOUTLINE",
        r = 1,
        shadow = true,
        size = 23,
        x = 1,
        y = 29,
    },
    scoreStyle = {
        a = 1,
        b = 0.87843143939972,
        font = nil,
        g = 1,
        outline = "OUTLINE",
        r = 0.80392163991928,
        shadow = false,
        size = 20,
        x = 0,
        y = -27,
    },
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)

-- =========================================================
-- Teleport click layer, migrated from the Tooltip module
-- =========================================================
local INFINITY_TeleportSpellMap = {
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

local function INFINITY_IsSpellKnownINFINITY(spellID)
    if not spellID or spellID <= 0 then
        return false
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown and Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player then
        return C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player)
    end
    return IsSpellKnown and IsSpellKnown(spellID) or false
end

local function INFINITY_GetTeleportSpellID(mapID)
    if mapID == 161 then
        local faction = UnitFactionGroup and UnitFactionGroup("player") or ""
        local prefer = (faction == "Horde") and 159898 or 1254557
        local fallback = (prefer == 159898) and 1254557 or 159898
        if INFINITY_IsSpellKnownINFINITY(prefer) then
            return prefer
        end
        if INFINITY_IsSpellKnownINFINITY(fallback) then
            return fallback
        end
        return prefer
    end
    return INFINITY_TeleportSpellMap[mapID]
end

local function INFINITY_GetTeleportClickLayer(frame)
    if not frame then return nil end
    if frame.__INFINITY_TeleportLayer then
        return frame.__INFINITY_TeleportLayer
    end

    local layer = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
    layer:SetAllPoints(frame)
    layer:SetFrameLevel(frame:GetFrameLevel() + 20)
    layer:RegisterForClicks("AnyUp", "AnyDown")
    layer:SetAlpha(0)
    layer:EnableMouse(true)

    layer:SetScript("OnEnter", function()
        local onEnter = frame:GetScript("OnEnter")
        if onEnter then onEnter(frame) end
    end)
    layer:SetScript("OnLeave", function()
        local onLeave = frame:GetScript("OnLeave")
        if onLeave then
            onLeave(frame)
        else
            GameTooltip:Hide()
        end
    end)

    frame.__INFINITY_TeleportLayer = layer
    return layer
end

local function INFINITY_UpdateTeleportClickLayer(frame, mapID)
    if not frame then return end

    if not mapID then
        if frame.__INFINITY_TeleportLayer then
            frame.__INFINITY_TeleportLayer:EnableMouse(false)
            frame.__INFINITY_TeleportLayer:Hide()
        end
        return
    end

    local spellID = INFINITY_GetTeleportSpellID(mapID)
    if not spellID or not INFINITY_IsSpellKnownINFINITY(spellID) then
        if frame.__INFINITY_TeleportLayer then
            frame.__INFINITY_TeleportLayer:EnableMouse(false)
            frame.__INFINITY_TeleportLayer:Hide()
        end
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        return
    end

    local layer = INFINITY_GetTeleportClickLayer(frame)
    layer:SetAttribute("type", "spell")
    layer:SetAttribute("spell", spellID)
    layer:EnableMouse(true)
    layer:Show()
end

-- =========================================================
-- [v4.2] Registration and configuration
-- =========================================================



-- 2. Grid layout
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 54, h = 2, label = L["Mythic Icon Overlays"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 54, h = 1, label = L["Overlays extra information on dungeon icons in the Mythic+ challenge panel."] },
        { key = "sub_disp", type = "subheader", x = 2, y = 6, w = 54, h = 1, label = L["Display Options"] },
        { key = "showBestLevel", type = "checkbox", x = 2, y = 8, w = 12, h = 2, label = L["Show Best Level (Center)"], parentKey = "displayOptions" },
        { key = "showScore", type = "checkbox", x = 16, y = 8, w = 13, h = 2, label = L["Show Dungeon Score (Bottom)"], parentKey = "displayOptions" },
        { key = "div1", type = "divider", x = 2, y = 14, w = 54, h = 1, label = "--[[ Function ]]" },
        { key = "sub_font", type = "subheader", x = 2, y = 12, w = 54, h = 2, label = L["Text Style"], labelSize = 20 },
        { key = "nameStyle", type = "fontgroup", x = 2, y = 16, w = 54, h = 18, label = L["Dungeon Name Style"], labelSize = 20 },
        { key = "levelStyle", type = "fontgroup", x = 2, y = 37, w = 54, h = 18, label = L["Best Level Style"], labelSize = 20 },
        { key = "scoreStyle", type = "fontgroup", x = 2, y = 57, w = 54, h = 18, label = L["Dungeon Score Style"], labelSize = 20 },
        { key = "div2", type = "divider", x = 2, y = 78, w = 54, h = 1, label = "--[[ Function ]]" },
        { key = "sub_maps", type = "subheader", x = 2, y = 76, w = 54, h = 2, label = L["Custom Short Names (leave blank for default)"], labelSize = 20 },
        { key = "161", type = "input", x = 8, y = 89, w = 8, h = 2, label = L["SR (161)"], parentKey = "mapNames", subKey = "161", labelPos = "left" },
        { key = "239", type = "input", x = 8, y = 86, w = 8, h = 2, label = L["SEAT (239)"], parentKey = "mapNames", subKey = "239", labelPos = "left" },
        { key = "378", type = "input", x = 22, y = 86, w = 8, h = 2, label = L["HoA (378)"], parentKey = "mapNames", subKey = "378", labelPos = "left" },
        { key = "391", type = "input", x = 22, y = 80, w = 8, h = 2, label = L["Streets (391)"], parentKey = "mapNames", subKey = "391", labelPos = "left" },
        { key = "392", type = "input", x = 22, y = 92, w = 8, h = 2, label = L["Gambit (392)"], parentKey = "mapNames", subKey = "392", labelPos = "left" },
        { key = "402", type = "input", x = 8, y = 80, w = 8, h = 2, label = L["AA (402)"], parentKey = "mapNames", subKey = "402", labelPos = "left" },
        { key = "499", type = "input", x = 22, y = 83, w = 8, h = 2, label = L["Priory (499)"], parentKey = "mapNames", subKey = "499", labelPos = "left" },
        { key = "503", type = "input", x = 22, y = 95, w = 8, h = 2, label = L["Echoes (503)"], parentKey = "mapNames", subKey = "503", labelPos = "left" },
        { key = "505", type = "input", x = 22, y = 89, w = 8, h = 2, label = L["Dawn (505)"], parentKey = "mapNames", subKey = "505", labelPos = "left" },
        { key = "525", type = "input", x = 22, y = 101, w = 8, h = 2, label = L["Floodgate (525)"], parentKey = "mapNames", subKey = "525", labelPos = "left" },
        { key = "542", type = "input", x = 22, y = 98, w = 8, h = 2, label = L["Eco (542)"], parentKey = "mapNames", subKey = "542", labelPos = "left" },
        { key = "556", type = "input", x = 8, y = 95, w = 8, h = 2, label = L["POS (556)"], parentKey = "mapNames", subKey = "556", labelPos = "left" },
        { key = "557", type = "input", x = 8, y = 83, w = 8, h = 2, label = L["WS (557)"], parentKey = "mapNames", subKey = "557", labelPos = "left" },
        { key = "558", type = "input", x = 8, y = 92, w = 8, h = 2, label = L["MT (558)"], parentKey = "mapNames", subKey = "558", labelPos = "left" },
        { key = "559", type = "input", x = 8, y = 101, w = 8, h = 2, label = L["NPX (559)"], parentKey = "mapNames", subKey = "559", labelPos = "left" },
        { key = "560", type = "input", x = 8, y = 98, w = 8, h = 2, label = L["MC (560)"], parentKey = "mapNames", subKey = "560", labelPos = "left" },
        { key = "divider_9070", type = "divider", x = 2, y = 7, w = 54, h = 1, label = "" },
    }



    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

-- 3. Register immediately
REGISTER_LAYOUT()

-- =========================================================
-- Core runtime logic
-- =========================================================

-- Forward declarations
local INFINITY_ApplyNames
local INFINITY_NudgeFontsOnce



local function INFINITY_IsAddOnLoaded(name) return C_AddOns.IsAddOnLoaded(name) end
local function INFINITY_LoadAddOn(name) return C_AddOns.LoadAddOn(name) end

local function INFINITY_BuildRatingLookup()
    local lookup = {}
    local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    if not summary or not summary.runs then return lookup end
    for _, run in ipairs(summary.runs) do
        lookup[run.challengeModeID] = { level = run.bestRunLevel or 0, score = run.mapScore or 0 }
    end
    return lookup
end

local ActiveOverlays = {}



local function UpdateText(fs, cfg, overlay, defaultY)
    -- 1. Check whether styling fields changed, field by field
    if fs._lastFont ~= cfg.font or fs._lastSize ~= cfg.size or fs._lastOutline ~= cfg.outline or fs._lastShadow ~= cfg.shadow then
        InfinityDB:ApplyFont(fs, cfg, true)
        fs._lastFont = cfg.font
        fs._lastSize = cfg.size
        fs._lastOutline = cfg.outline
        fs._lastShadow = cfg.shadow
    end

    -- 2. Check whether position changed
    local targetY = cfg.y or defaultY
    local targetX = cfg.x or 0
    if fs._lastX ~= targetX or fs._lastY ~= targetY then
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", overlay, "CENTER", targetX, targetY)
        fs._lastX = targetX
        fs._lastY = targetY
    end
end

-- Helper: apply position and font, extracted for live updates

local function UpdateOverlayArt(overlay, mapID, rating)
    if not overlay or not mapID then return end

    local name = MODULE_DB.mapNames[mapID] or INFINITY_GetBlizzMapName(mapID)
    if name == defaultMapNamesINFINITY[mapID] then
        name = L[name]
    end
    UpdateText(overlay.name, MODULE_DB.nameStyle, overlay, 7)
    if overlay.name:GetText() ~= name then
        overlay.name:SetText(name)
    end

    if MODULE_DB.displayOptions.showBestLevel then
        local best = rating[mapID] and rating[mapID].level or 0
        local bestStr = best > 0 and tostring(best) or ""

        UpdateText(overlay.level, MODULE_DB.levelStyle, overlay, -1)
        if overlay.level:GetText() ~= bestStr then overlay.level:SetText(bestStr) end

        local color = C_ChallengeMode.GetKeystoneLevelRarityColor(best)
        if color then overlay.level:SetTextColor(color.r, color.g, color.b) end
        overlay.level:Show()
    else
        overlay.level:Hide()
    end

    if MODULE_DB.displayOptions.showScore then
        local score = rating[mapID] and rating[mapID].score or 0
        local scoreStr = score > 0 and tostring(math.floor(score + 0.5)) or ""

        UpdateText(overlay.score, MODULE_DB.scoreStyle, overlay, -8)
        if overlay.score:GetText() ~= scoreStr then overlay.score:SetText(scoreStr) end

        local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(score)
        if color then overlay.score:SetTextColor(color.r, color.g, color.b) end
        overlay.score:Show()
    else
        overlay.score:Hide()
    end
end

-- FIXBW
local function INFINITY_IsBigWigsScoreFont(fs, icon)
    if not fs or not icon or not fs.IsObjectType or not fs:IsObjectType("FontString") then return false end
    if fs == icon.HighestLevel then return false end
    if fs:GetParent() ~= icon then return false end

    local point, relativeTo, relativePoint, x, y = fs:GetPoint(1)
    if point ~= "BOTTOM" or relativeTo ~= icon or relativePoint ~= "BOTTOM" then return false end

    x = x or 0
    y = y or 0
    if math.abs(x) > 0.1 or math.abs(y - 4) > 0.1 then return false end

    return true
end

local function INFINITY_SuppressBigWigsScore(icon)
    if not icon then return end
    if not INFINITY_IsAddOnLoaded("BigWigs") then return end

    local regions = { icon:GetRegions() }
    for i = 1, #regions do
        local region = regions[i]
        if INFINITY_IsBigWigsScoreFont(region, icon) then
            if not region.__INFINITY_FORCE_HIDDEN then
                region.__INFINITY_FORCE_HIDDEN = true
                hooksecurefunc(region, "Show", function(self) self:Hide() end)
            end
            region:SetText("")
            region:SetAlpha(0)
            region:Hide()
        end
    end
end

local function INFINITY_SuppressBigWigsAllIcons()
    if not INFINITY_IsAddOnLoaded("BigWigs") then return end
    if not ChallengesFrame or not ChallengesFrame:IsShown() then return end

    local icons = ChallengesFrame.DungeonIcons
    if not icons or #icons == 0 then return end

    for i = 1, #icons do
        INFINITY_SuppressBigWigsScore(icons[i])
    end
end

local function INFINITY_SuppressBigWigsBurst()
    -- After opening the frame, suppress BigWigs sounds at 0.01s, 0.03s, and 0.1s as a fallback
    if not INFINITY_IsAddOnLoaded("BigWigs") then return end
    if not ChallengesFrame or not ChallengesFrame:IsShown() then return end

    INFINITY_SuppressBigWigsAllIcons()
    C_Timer.After(0.01, INFINITY_SuppressBigWigsAllIcons)
    C_Timer.After(0.03, INFINITY_SuppressBigWigsAllIcons)
    C_Timer.After(0.1, INFINITY_SuppressBigWigsAllIcons)
end

local lastUpdateRate = 0
INFINITY_ApplyNames = function()
    -- Debounce to one update per 0.1s to avoid excessive hook-triggered refreshes
    local now = GetTime()
    if now - lastUpdateRate < 0.1 then return end
    lastUpdateRate = now

    if not ChallengesFrame or not ChallengesFrame:IsShown() then return end

    local icons = ChallengesFrame.DungeonIcons
    if not icons or #icons == 0 then return end

    -- Cache rating lookups so each icon does not query independently
    local rating = INFINITY_BuildRatingLookup()

    -- Ensure overlay count matches the icon list
    for i, frame in ipairs(icons) do
        local overlay = ActiveOverlays[i]

        -- Create or reset the overlay if missing or parent changed
        if not overlay or overlay:GetParent() ~= frame then
            if overlay then InfinityFactory:Release("MythicIconOverlay", overlay) end
            overlay = InfinityFactory:Acquire("MythicIconOverlay", frame)

            overlay:SetAllPoints(frame)
            -- Let mouse events pass through so the original icon tooltip still works
            overlay:EnableMouse(false)

            overlay:Show()
            ActiveOverlays[i] = overlay



            if frame.HighestLevel and not frame.HighestLevel.__INFINITY_HIDDEN then
                frame.HighestLevel:Hide()
                frame.HighestLevel:SetAlpha(0)
                hooksecurefunc(frame.HighestLevel, "Show", function(self) self:Hide() end)
                frame.HighestLevel.__INFINITY_HIDDEN = true
            end
        end


        if frame.mapID then
            INFINITY_SuppressBigWigsScore(frame)
            UpdateOverlayArt(overlay, frame.mapID, rating)
            INFINITY_UpdateTeleportClickLayer(frame, frame.mapID)
            if frame.Icon then
                frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            end
            overlay:Show()
        else
            INFINITY_UpdateTeleportClickLayer(frame, nil)
            overlay:Hide()
        end
    end


    for i = #icons + 1, #ActiveOverlays do
        InfinityFactory:Release("MythicIconOverlay", ActiveOverlays[i])
        ActiveOverlays[i] = nil
    end
end

_G.Infinity_RefreshMythicNamesINFINITY = INFINITY_ApplyNames

INFINITY_NudgeFontsOnce = function()
    INFINITY_ApplyNames()
end

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function()
    if _G.ChallengesFrame and _G.ChallengesFrame:IsShown() then
        INFINITY_ApplyNames()
    end
end)

------------------------------------------------------------
-- Events and hooks
------------------------------------------------------------
local function INFINITY_RefreshBurst()
    INFINITY_SuppressBigWigsBurst()
    INFINITY_ApplyNames()
    C_Timer.After(0.1, INFINITY_ApplyNames)
end

local function INFINITY_HookChallenges()
    if not ChallengesFrame then return end
    if ChallengesFrame.__INFINITY_HOOKED then
        INFINITY_RefreshBurst()
        return
    end
    ChallengesFrame.__INFINITY_HOOKED = true

    if type(ChallengesFrame.Update) == "function" then
        hooksecurefunc(ChallengesFrame, "Update", INFINITY_ApplyNames)
    end
    if type(_G.ChallengesFrame_Update) == "function" then
        hooksecurefunc("ChallengesFrame_Update", INFINITY_ApplyNames)
    end

    ChallengesFrame:HookScript("OnShow", INFINITY_RefreshBurst)
    INFINITY_RefreshBurst()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
eventFrame:RegisterEvent("CHALLENGE_MODE_LEADERS_UPDATE")
eventFrame:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ChallengesUI" then
        INFINITY_HookChallenges()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not INFINITY_IsAddOnLoaded("Blizzard_ChallengesUI") then
            INFINITY_LoadAddOn("Blizzard_ChallengesUI")
        end
        INFINITY_HookChallenges()
    else
        INFINITY_RefreshBurst()
    end
end)

if PVEFrame then
    PVEFrame:HookScript("OnShow", function()
        if not INFINITY_IsAddOnLoaded("Blizzard_ChallengesUI") then
            INFINITY_LoadAddOn("Blizzard_ChallengesUI")
        end
        INFINITY_HookChallenges()
        INFINITY_RefreshBurst()
    end)
end

if type(_G.PVEFrame_ShowFrame) == "function" then
    hooksecurefunc("PVEFrame_ShowFrame", function(frameType)
        if frameType == "ChallengesFrame" then
            if not INFINITY_IsAddOnLoaded("Blizzard_ChallengesUI") then
                INFINITY_LoadAddOn("Blizzard_ChallengesUI")
            end
            INFINITY_HookChallenges()
            INFINITY_RefreshBurst()
        end
    end)
end

-- Report module ready
InfinityTools:ReportReady(INFINITY_MODULE_KEY)
