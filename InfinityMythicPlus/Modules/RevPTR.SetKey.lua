-- [[ BETA Keystone Setter ]]
-- { Key = "RevPTR.SetKey", Name = "BETA Keystone Setter", Desc = "Quickly set keystone level/map and display your current keystone.", Category = 3 },

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

-- 1. Module key
local INFINITY_MODULE_KEY = "RevPTR.SetKey"

-- Beta-only module
if not IsBetaBuild() then return end

-- 2. Load guard
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local FIXED_WIDTH = 280
local mainFrame
local InfinityDB = _G.InfinityDB

-- 3. Data initialization
local MODULE_DEFAULTS = {
    current = {
        a = 1,
        b = 1,
        current_iconSize = 75,
        g = 0,
        groupX = -2,
        groupY = -1,
        iconSize = 34,
        iconX = 10,
        iconY = -17,
        outline = "THICKOUTLINE",
        r = 0.83,
        shadow = false,
        shadowX = 1,
        shadowY = -1,
        size = 30,
        x = 6,
        y = -9,
    },
    enabled = false,
    iconsX = 21,
    iconsY = -52,
    level = {
        a = 1,
        b = 0.92,
        g = 1,
        groupX = -13,
        groupY = 4,
        iconSize = 40,
        level_groupX = 62,
        level_groupY = -25,
        level_iconSize = 73,
        level_spacingX = 72,
        level_spacingY = 62,
        outline = "THICKOUTLINE",
        r = 0.91,
        shadow = false,
        shadowX = 1,
        shadowY = -1,
        size = 32,
        spacingX = 47,
        spacingY = 44,
        x = 0,
        y = 0,
    },
    map = {
        a = 1,
        b = 0.26274511218071,
        g = 0.74901962280273,
        groupX = -12,
        groupY = -1,
        iconSize = 48,
        map_groupX = 46,
        map_groupY = -62,
        map_iconSize = 68,
        map_spacingX = 126,
        map_spacingY = 130,
        outline = "THICKOUTLINE",
        r = 1,
        shadow = true,
        shadowX = 1,
        shadowY = -1,
        size = 20,
        spacingX = 60,
        spacingY = 58,
        x = 2,
        y = 12,
    },
    offsetX = -6,
    offsetY = 0,
    side = "LEFT",
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =============================================================
-- Part 1: Grid layout
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 47, h = 2, label = L["BETA Keystone Panel"] },
        { key = "desc", type = "description", x = 1, y = 3, w = 47, h = 1, label = L["A quick keystone setup panel attached to the left side of the PVE frame."] },
        { key = "enabled", type = "checkbox", x = 1, y = 5, w = 12, h = 2, label = L["Enable Module"] },
        { key = "side", type = "select", x = 14, y = 5, w = 12, h = 2, label = L["Attach Side"], options = { ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"] } },
        { key = "offsetX", type = "slider", x = 1, y = 10, w = 15, h = 2, label = L["Global X Offset"], min = -100, max = 100, step = 1 },
        { key = "offsetY", type = "slider", x = 18, y = 10, w = 15, h = 2, label = L["Global Y Offset"], min = -500, max = 500, step = 5 },

        { key = "sub_global", type = "subheader", x = 1, y = 13, w = 47, h = 1, label = L["Icon Group Offset (adjust this instead of moving the frame)"] },
        { key = "iconsX", type = "slider", x = 1, y = 15, w = 15, h = 2, label = L["Icon Group X"], min = -100, max = 100, step = 1 },
        { key = "iconsY", type = "slider", x = 18, y = 15, w = 15, h = 2, label = L["Icon Group Y"], min = -100, max = 100, step = 1 },

        { key = "sub_cur", type = "subheader", x = 1, y = 18, w = 47, h = 1, label = L["Current Keystone"] },
        { key = "groupX", type = "slider", x = 1, y = 20, w = 15, h = 2, label = L["Module X"], min = -100, max = 100, parentKey = "current" },
        { key = "groupY", type = "slider", x = 18, y = 20, w = 15, h = 2, label = L["Module Y"], min = -100, max = 100, parentKey = "current" },
        { key = "iconSize", type = "slider", x = 1, y = 23, w = 15, h = 2, label = L["Icon Size"], min = 16, max = 64, parentKey = "current" },
        { key = "current", type = "fontgroup", x = 1, y = 26, w = 47, h = 18, label = L["Current Text Style"] },

        { key = "sub_level", type = "subheader", x = 1, y = 45, w = 47, h = 1, label = L["Level Buttons"] },
        { key = "groupX", type = "slider", x = 1, y = 47, w = 15, h = 2, label = L["Module X"], min = -100, max = 100, parentKey = "level" },
        { key = "groupY", type = "slider", x = 18, y = 47, w = 15, h = 2, label = L["Module Y"], min = -100, max = 100, parentKey = "level" },
        { key = "iconSize", type = "slider", x = 1, y = 50, w = 15, h = 2, label = L["Button Size"], min = 20, max = 80, parentKey = "level" },
        { key = "spacingX", type = "slider", x = 18, y = 50, w = 15, h = 2, label = L["Horizontal Spacing"], min = 20, max = 100, parentKey = "level" },
        { key = "level", type = "fontgroup", x = 1, y = 53, w = 47, h = 18, label = L["Number Font Style"] },

        { key = "sub_map", type = "subheader", x = 1, y = 72, w = 47, h = 1, label = L["Map Buttons"] },
        { key = "groupX", type = "slider", x = 1, y = 74, w = 15, h = 2, label = L["Module X"], min = -100, max = 100, parentKey = "map" },
        { key = "groupY", type = "slider", x = 18, y = 74, w = 15, h = 2, label = L["Module Y"], min = -100, max = 100, parentKey = "map" },
        { key = "iconSize", type = "slider", x = 1, y = 77, w = 15, h = 2, label = L["Button Size"], min = 20, max = 100, parentKey = "map" },
        { key = "spacingX", type = "slider", x = 18, y = 77, w = 15, h = 2, label = L["Horizontal Spacing"], min = 20, max = 120, parentKey = "map" },
        { key = "spacingY", type = "slider", x = 1, y = 80, w = 15, h = 2, label = L["Vertical Spacing"], min = 20, max = 120, parentKey = "map" },
        { key = "map", type = "fontgroup", x = 1, y = 83, w = 47, h = 18, label = L["Dungeon Font Style"] },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

-- =============================================================
-- Part 2: Skin and widget helpers
-- =============================================================

local function ApplyElvUISkin(frame)
    if not frame then return false end
    local Skin = InfinityTools.ElvUISkin
    if not Skin or not Skin:IsElvUILoaded() then return false end

    Skin:SkinFrame(frame, "Transparent")
    local E = _G.ElvUI and _G.ElvUI[1]
    local S = E and E:GetModule("Skins", true)
    if S and S.CreateShadowModule then
        _G.pcall(S.CreateShadowModule, S, frame)
    end
    if frame.CloseButton then Skin:SkinCloseButton(frame.CloseButton) end
    return true
end

-- NDui skin application
local function ApplyNDuiSkin(frame)
    if not frame then return false end
    local NDuiSkin = InfinityTools.NDuiSkin
    if not NDuiSkin or not NDuiSkin:IsNDuiLoaded() then return false end

    local NDui = _G.NDui
    if not NDui then return false end
    local B = NDui[1] -- NDui core helper table
    if not B then return false end

    local ok = pcall(function()
        -- Apply NDui backdrop directly to this frame, using SkinAlpha opacity.
        B.CreateBD(frame)
        -- Add shadow.
        B.CreateSD(frame, nil, true)
        -- Add background texture.
        B.CreateTex(frame)
        -- Reskin the close button while keeping the x icon.
        if frame.CloseButton then
            B.ReskinClose(frame.CloseButton)
        end
    end)
    return ok
end

-- =============================================================
-- Part 3: Core behavior (position and display updates)
-- =============================================================

local function UpdatePosition()
    if not mainFrame or not mainFrame:IsShown() then return end

    local anchorFrame = _G.PVEFrame
    mainFrame:ClearAllPoints()

    local side = MODULE_DB.side or "LEFT"
    local offX = MODULE_DB.offsetX or (side == "LEFT" and -2 or 2)
    local offY = MODULE_DB.offsetY or 0

    if side == "LEFT" then
        mainFrame:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", offX, offY)
        mainFrame:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMLEFT", offX, offY)
    else
        mainFrame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", offX, offY)
        mainFrame:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMRIGHT", offX, offY)
    end
    mainFrame:SetWidth(FIXED_WIDTH)
end

local function UpdateCurrentKeystone()
    if not mainFrame then return end
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()

    local db = MODULE_DB.current
    InfinityDB:ApplyFont(mainFrame.currentText, db)
    mainFrame.currentIcon:SetSize(db.iconSize, db.iconSize)
    mainFrame.currentIcon:SetPoint("LEFT", mainFrame, "TOPLEFT", db.iconX + MODULE_DB.iconsX + db.groupX,
        db.iconY + 15 + MODULE_DB.iconsY + db.groupY) -- Shift upward
    mainFrame.currentText:SetPoint("LEFT", mainFrame.currentIcon, "RIGHT", db.x, db.y)

    if mapID and level and mapID > 0 and level > 0 then
        local name, _, _, textureID = C_ChallengeMode.GetMapUIInfo(mapID)
        mainFrame.currentText:SetText(string.format("%s(%d)", name or "??", level))
        mainFrame.currentIcon:SetTexture(textureID or 463531)
    else
        mainFrame.currentText:SetText("|cff888888" .. L["Create Keystone"] .. "|r")
        mainFrame.currentIcon:SetTexture(463531)
    end
end

local function RebuildButtons()
    if not mainFrame then return end

    -- Level buttons
    local keystoneLevels = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
    local dbL = MODULE_DB.level
    local keystoneItemIDs = { 166381, 166380, 166379, 166378, 166377, 159694, 159695, 159696, 159697, 159698 }
    for i, b in ipairs(mainFrame.levelBtns) do
        local row = (i <= 5) and 0 or 1
        local col = (i - 1) % 5
        b:SetSize(dbL.iconSize, dbL.iconSize)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 20 + col * dbL.spacingX + dbL.groupX + MODULE_DB.iconsX,
            -50 - row * dbL.spacingY + dbL.groupY + MODULE_DB.iconsY)

        InfinityDB:ApplyFont(b.txt, dbL)
        b.txt:SetPoint("CENTER", b, "CENTER", dbL.x, dbL.y)
        b.txt:SetText(keystoneLevels[i])
        b:SetAttribute("macrotext", "/use item:" .. keystoneItemIDs[i] .. "\n/use item:151086")
    end

    -- Map buttons
    local dbM = MODULE_DB.map
    local mapData = {
        { name = L["SEAT"], cmID = 239, itemID = 159691 },
        { name = L["POS"], cmID = 556, itemID = 253009 },
        { name = L["SR"], cmID = 161, itemID = 201333 },
        { name = L["AA"], cmID = 402, itemID = 201344 },
        { name = L["WS"], cmID = 557, itemID = 252658 },
        { name = L["MT"], cmID = 558, itemID = 253012 },
        { name = L["MC"], cmID = 560, itemID = 252951 },
        { name = L["NPX"], cmID = 559, itemID = 253010 },
    }
    for i, b in ipairs(mainFrame.mapBtns) do
        local row = math.floor((i - 1) / 4)
        local col = (i - 1) % 4
        b:SetSize(dbM.iconSize, dbM.iconSize)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 18 + col * dbM.spacingX + dbM.groupX + MODULE_DB.iconsX,
            -150 - row * dbM.spacingY + dbM.groupY + MODULE_DB.iconsY)

        local _, _, _, tex = C_ChallengeMode.GetMapUIInfo(mapData[i].cmID)
        b:SetNormalTexture(tex or 463531)
        if b:GetNormalTexture() then b:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92) end

        InfinityDB:ApplyFont(b.txt, dbM)
        b.txt:SetPoint("CENTER", b, "CENTER", dbM.x, dbM.y)
        b.txt:SetText(mapData[i].name)
        b:SetAttribute("macrotext", "/use item:" .. mapData[i].itemID .. "\n/use item:151086")
    end

    UpdateCurrentKeystone()
end

-- =============================================================
-- Part 4: Frame creation
-- =============================================================

local function CreateMainFrame()
    if mainFrame then return end

    local Skin = InfinityTools.ElvUISkin
    local isElv = Skin and Skin:IsElvUILoaded()
    local NDuiSkin = InfinityTools.NDuiSkin
    local isNDui = NDuiSkin and NDuiSkin:IsNDuiLoaded()

    if isElv then
        mainFrame = _G.CreateFrame("Frame", "RevPTR_SetKey_SidePanel", _G.UIParent)
        mainFrame:SetSize(FIXED_WIDTH, 480)
        local title = mainFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
        title:SetPoint("TOP", 0, -8)
        title:SetTextColor(1, 0.82, 0)
        title:SetText(L["BETA Keystone Panel"])  -- TODO: missing key: L["BETA Keystone Panel"]
        mainFrame.TitleText = title
        local close = _G.CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
        mainFrame.CloseButton = close
        ApplyElvUISkin(mainFrame)
    elseif isNDui then
        -- [NDui mode] Create a plain frame and style it with NDui.
        mainFrame = _G.CreateFrame("Frame", "RevPTR_SetKey_SidePanel", _G.UIParent, "BackdropTemplate")
        mainFrame:SetSize(FIXED_WIDTH, 480)
        local title = mainFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
        title:SetPoint("TOP", 0, -8)
        title:SetTextColor(1, 0.82, 0)
        title:SetText(L["BETA Keystone Panel"])  -- TODO: missing key: L["BETA Keystone Panel"]
        mainFrame.TitleText = title
        local close = _G.CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
        mainFrame.CloseButton = close
        ApplyNDuiSkin(mainFrame)
    else
        mainFrame = _G.CreateFrame("Frame", "RevPTR_SetKey_SidePanel", _G.UIParent, "DefaultPanelTemplate")
        mainFrame:SetSize(FIXED_WIDTH, 480)
        if mainFrame.TitleText then
            mainFrame.TitleText:SetText(L["BETA Keystone Panel"])  -- TODO: missing key: L["BETA Keystone Panel"]
            mainFrame.TitleText:SetFont(InfinityTools.MAIN_FONT, 14, "OUTLINE")
        end
    end

    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetToplevel(true)

    -- 1. Current keystone display
    mainFrame.currentIcon = mainFrame:CreateTexture(nil, "ARTWORK")
    mainFrame.currentIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    mainFrame.currentText = mainFrame:CreateFontString(nil, "OVERLAY")

    -- 2. Level button group
    mainFrame.levelBtns = {}
    local keystoneItemIDs = { 166381, 166380, 166379, 166378, 166377, 159694, 159695, 159696, 159697, 159698 }
    for i = 1, 10 do
        local b = _G.CreateFrame("Button", nil, mainFrame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
        b:RegisterForClicks("AnyUp", "AnyDown")
        b:SetAttribute("type", "macro")
        b:SetAttribute("macrotext", "/use item:" .. keystoneItemIDs[i] .. "\n/use item:151086")
        b:SetNormalTexture(463531)
        if b:GetNormalTexture() then b:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        b.txt = b:CreateFontString(nil, "OVERLAY")
        table.insert(mainFrame.levelBtns, b)
    end

    -- 3. Map button group
    mainFrame.mapBtns = {}
    local mapData = {
        { name = L["SEAT"], cmID = 239, itemID = 159691 },
        { name = L["POS"], cmID = 556, itemID = 253009 },
        { name = L["SR"], cmID = 161, itemID = 201333 },
        { name = L["AA"], cmID = 402, itemID = 201344 },
        { name = L["WS"], cmID = 557, itemID = 252658 },
        { name = L["MT"], cmID = 558, itemID = 253012 },
        { name = L["MC"], cmID = 560, itemID = 252951 },
        { name = L["NPX"], cmID = 559, itemID = 253010 },
    }
    for i, data in ipairs(mapData) do
        local b = _G.CreateFrame("Button", nil, mainFrame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
        b:RegisterForClicks("AnyUp", "AnyDown")
        b:SetAttribute("type", "macro")
        b:SetAttribute("macrotext", "/use item:" .. data.itemID .. "\n/use item:151086")
        b.txt = b:CreateFontString(nil, "OVERLAY")
        b.data = data
        table.insert(mainFrame.mapBtns, b)
    end

    mainFrame:Hide()

    -- Decide whether the panel should be shown.
    local function ShouldShow()
        if not MODULE_DB.enabled then return false end
        if not _G.PVEFrame or not _G.PVEFrame:IsShown() then return false end

        -- 1: GroupFinder (LFG), 2: PVP, 3: Challenges (PVE/Mythic+)
        -- Show the beta keystone panel only on the Challenges tab.
        local activeTab = _G.PanelTemplates_GetSelectedTab(_G.PVEFrame)
        return (activeTab == 3)
    end

    local function UpdateVisibility()
        if not mainFrame then return end
        if ShouldShow() then
            mainFrame:Show()
            UpdatePosition()
            RebuildButtons()
        else
            mainFrame:Hide()
        end
    end

    local function HookPVE()
        if not _G.PVEFrame then return end

        -- Hook show/hide scripts.
        _G.PVEFrame:HookScript("OnShow", function()
            _G.C_Timer.After(0.1, UpdateVisibility)
        end)
        _G.PVEFrame:HookScript("OnHide", function()
            if mainFrame then mainFrame:Hide() end
        end)

        -- Hook tab switches.
        if _G.PVEFrame_ShowFrame then
            _G.hooksecurefunc("PVEFrame_ShowFrame", UpdateVisibility)
        end

        -- Initial visibility check.
        UpdateVisibility()
    end

    if _G.PVEFrame then
        HookPVE()
    else
        InfinityTools:RegisterEvent("ADDON_LOADED", INFINITY_MODULE_KEY, function(_, n)
            if n == "Blizzard_GroupFinder" then HookPVE() end
        end)
    end
end

-- =============================================================
-- Part 5: Event/state handling
-- =============================================================

local function OnDataUpdate()
    if mainFrame and mainFrame:IsShown() then _G.C_Timer.After(0.2, RebuildButtons) end
end

InfinityTools:RegisterEvent("ITEM_CHANGED", INFINITY_MODULE_KEY, OnDataUpdate)
InfinityTools:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE", INFINITY_MODULE_KEY, OnDataUpdate)
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    if mainFrame then RebuildButtons() end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function()
    if not MODULE_DB.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end
    if not mainFrame then CreateMainFrame() end
    UpdatePosition()
    RebuildButtons()
end)

_G.C_Timer.After(1.5, function()
    if MODULE_DB.enabled then CreateMainFrame() end
end)

InfinityTools:ReportReady(INFINITY_MODULE_KEY)
