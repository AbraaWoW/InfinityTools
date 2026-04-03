-- =============================================================
-- Comment translated to English
-- Comment translated to English
-- =============================================================

local RRTToolsCore = _G.RRTToolsCore
local InfinityDB = _G.InfinityDB
local RRT_NS = _G.RRT_NS or {}
_G.RRT_NS = RRT_NS
if not RRTToolsCore then return end

local RRT_MODULE_KEY = "RRTTools.PveInfoPanel"

-- =============================================================
-- Comment translated to English
-- =============================================================
local function RRT_RegisterLayout()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 47, h = 2, label = "Weekly M+ Info Panel" },
        { key = "desc", type = "description", x = 1, y = 3, w = 47, h = 1, label = "Attaches to the side of the PVE frame and shows weekly Mythic+ stats." },
        { key = "enabled", type = "checkbox", x = 1, y = 5, w = 12, h = 2, label = "Enable" },
        { key = "side", type = "select", x = 15, y = 5, w = 12, h = 2, label = "Side", options = { ["LEFT"] = "Left", ["RIGHT"] = "Right" } },
        { key = "offsetX", type = "slider", x = 1, y = 10, w = 15, h = 2, label = "Offset X", min = -100, max = 100, step = 1 },
        { key = "offsetY", type = "slider", x = 18, y = 10, w = 15, h = 2, label = "Offset Y", min = -500, max = 500, step = 5 },
    }
    RRTToolsCore:RegisterModuleLayout(RRT_MODULE_KEY, layout)
end
RRT_RegisterLayout()

if not RRTToolsCore:IsModuleEnabled(RRT_MODULE_KEY) then return end

local RRT_DB = RRTToolsCore:GetModuleDB(RRT_MODULE_KEY, { enabled = false, side = "RIGHT", offsetX = 2, offsetY = 0 })
local mainFrame
local FIXED_WIDTH = 260

-- =============================================================
-- Comment translated to English
-- =============================================================

local function CreateSectionTitle(parent, text, yOfs)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(FIXED_WIDTH - 15, 14)
    container:SetPoint("TOP", parent, "TOP", 0, yOfs)
    local label = container:CreateFontString(nil, "OVERLAY")
    label:SetFont(RRTToolsCore.MAIN_FONT, 15, "OUTLINE")
    label:SetText(text)
    label:SetTextColor(1, 0.8, 0, 0.95)
    label:SetPoint("CENTER", 0, 0)
    local leftLine = container:CreateTexture(nil, "ARTWORK")
    leftLine:SetHeight(1)
    leftLine:SetPoint("LEFT", 0, 0)
    leftLine:SetPoint("RIGHT", label, "LEFT", -8, 0)
    leftLine:SetColorTexture(1, 0.8, 0, 0.2)
    local rightLine = container:CreateTexture(nil, "ARTWORK")
    rightLine:SetHeight(1)
    rightLine:SetPoint("RIGHT", 0, 0)
    rightLine:SetPoint("LEFT", label, "RIGHT", 8, 0)
    rightLine:SetColorTexture(1, 0.8, 0, 0.2)
    return container
end

local function CreateHeaderIcon(parent, texture, xOfs, labelText, clickFunc)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(50, 50)
    btn:SetPoint("CENTER", parent, "TOP", xOfs, -47)

-- Comment translated to English
    btn.IsSkinned = true
    btn.noBackdrop = true

    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\AddOns\\InfinityTools\\Media\\RRTToolsAssets\\CoreTextures\\" .. texture)
    icon:SetVertexColor(0.85, 0.85, 0.85)
    btn.icon = icon
    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(RRTToolsCore.MAIN_FONT, 15, "OUTLINE")
    label:SetPoint("BOTTOM", icon, "BOTTOM", 0, 1)
    label:SetText(labelText)
    label:SetTextColor(1, 0.8, 0)
    btn:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(1, 1, 1)
        self:SetScale(1.05)
    end)
    btn:SetScript("OnLeave", function(self)
        self.icon:SetVertexColor(0.85, 0.85, 0.85)
        self:SetScale(1.0)
    end)
    btn:SetScript("OnClick", clickFunc)
    return btn
end

-- =============================================================
-- Comment translated to English
-- =============================================================

local function UpdatePosition()
    if not mainFrame or not mainFrame:IsShown() then return end

    local offX = tonumber(RRT_DB.offsetX) or 2
    local offY = tonumber(RRT_DB.offsetY) or 0
    mainFrame:ClearAllPoints()

-- Comment translated to English
    local anchorFrame = _G.PVEFrame

-- Comment translated to English
    local wt = _G.WindTools and _G.WindTools[1]
    if wt and wt.GetModule then
        local ll = wt:GetModule("LFGList", true)
        if ll and ll.RightPanel and ll.RightPanel:IsShown() then
            anchorFrame = ll.RightPanel
        end
    end

-- Comment translated to English
    if anchorFrame == _G.PVEFrame then
        if _G.WindUI_PveFrame and _G.WindUI_PveFrame:IsShown() then
            anchorFrame = _G.WindUI_PveFrame
        elseif _G.WindUI_MainFrame and _G.WindUI_MainFrame:IsShown() then
            anchorFrame = _G.WindUI_MainFrame
        end
    end

    if (RRT_DB.side or "RIGHT") == "LEFT" then
        mainFrame:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", offX, offY)
        mainFrame:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMLEFT", offX, offY)
    else
        mainFrame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", offX, offY)
        mainFrame:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMRIGHT", offX, offY)
    end
    mainFrame:SetWidth(FIXED_WIDTH)
end

-- Comment translated to English
local function HookWindUI()
    local wt = _G.WindTools and _G.WindTools[1]
    if wt and wt.GetModule then
        local ll = wt:GetModule("LFGList", true)
        if ll and ll.UpdateRightPanel then
            _G.hooksecurefunc(ll, "UpdateRightPanel", function()
                _G.C_Timer.After(0.05, UpdatePosition)
            end)
        end
    end
end

local function UpdateStats()
    if not mainFrame or not mainFrame:IsShown() then return end

    -- Fetch this week's run history
    local wRuns = _G.C_MythicPlus.GetRunHistory(false, true, true) or {}
    table.sort(wRuns, function(a, b) return a.level > b.level end)

    local mapTable = _G.C_ChallengeMode.GetMapTable() or {}
    local aggregatedData = {}
    for _, id in ipairs(mapTable) do aggregatedData[id] = { highest = 0, runs = {} } end

    for _, run in ipairs(wRuns) do
        local id = run.mapChallengeModeID
        if aggregatedData[id] then
            if run.level > aggregatedData[id].highest then aggregatedData[id].highest = run.level end
            table.insert(aggregatedData[id].runs, { level = run.level, timed = run.completed })
        end
    end



    -- Upper section: top 8 runs this week
    local upper = ""
    for i = 1, 8 do
        local run = wRuns[i]
        if run then
            local name, _, _, icon = _G.C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
            local hex = "ffffffff"
            local mix = _G.C_ChallengeMode.GetKeystoneLevelRarityColor(run.level)
            if mix then hex = mix:GenerateHexColor() or "ffffffff" end

            upper = upper .. string.format("%s |cffffffff+%d|r |c%s%s|r\n",
                _G.CreateSimpleTextureMarkup(icon or 136116, 14, 14), run.level, hex, name or "??")
        else
            upper = upper .. "|cff444444-|r\n"
        end
    end
    mainFrame.upperDisplay:SetText(upper:gsub("\n$", ""))

    -- Lower section: all dungeons with run details
    local lower = ""
    for _, id in ipairs(mapTable) do
        local dungeonName, _, _, icon = _G.C_ChallengeMode.GetMapUIInfo(id)
        local data = aggregatedData[id]
        local runsStr = ""
        if data and #data.runs > 0 then
            table.sort(data.runs, function(a, b) return b.level < a.level end)
            for _, r in ipairs(data.runs) do
                runsStr = runsStr .. (r.timed and "|cff00ff00" or "|cffff0000") .. r.level .. "|r "
            end
        else
            runsStr = "|cff888888-|r"
        end
        local iconMarkup = _G.CreateSimpleTextureMarkup(icon or 136116, 14, 14)
        local nameOverlay = string.format("|cffffd100%s|r", dungeonName or "?")
        lower = lower .. string.format("%s %s (%s)\n", iconMarkup, nameOverlay, runsStr)
    end
    mainFrame.lowerDisplay:SetText(lower:gsub("\n$", ""))
end

-- Comment translated to English
local function ApplyElvUISkin(frame)
    if not frame then return false end
    local Skin = RRTToolsCore.ElvUISkin
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

-- Comment translated to English
local function ApplyNDuiSkin(frame)
    if not frame then return false end
    local NDuiSkin = RRTToolsCore.NDuiSkin
    if not NDuiSkin or not NDuiSkin:IsNDuiLoaded() then return false end

    local NDui = _G.NDui
    if not NDui then return false end
    local B = NDui[1] -- Comment translated to English
    if not B then return false end

    local ok = pcall(function()
-- Comment translated to English
        B.CreateBD(frame)
-- Comment translated to English
        B.CreateSD(frame, nil, true)
-- Comment translated to English
        B.CreateTex(frame)
-- Comment translated to English
        if frame.CloseButton then
            B.ReskinClose(frame.CloseButton)
        end
    end)
    return ok
end

local function CreateMainFrame()
    if mainFrame then return end

    local Skin = RRTToolsCore.ElvUISkin
    local isElv = Skin and Skin:IsElvUILoaded()
    local NDuiSkin = RRTToolsCore.NDuiSkin
    local isNDui = NDuiSkin and NDuiSkin:IsNDuiLoaded()

    if isElv then
-- Comment translated to English
        mainFrame = CreateFrame("Frame", "ExPveInfoPanel_Final", UIParent)
        mainFrame:SetSize(FIXED_WIDTH, 540)

        local title = mainFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(RRTToolsCore.MAIN_FONT, 16, "OUTLINE")
        title:SetPoint("TOP", 0, -8)
        title:SetTextColor(1, 0.82, 0)
        mainFrame.TitleText = title

        local close = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
        mainFrame.CloseButton = close

        ApplyElvUISkin(mainFrame)
    elseif isNDui then
-- Comment translated to English
        mainFrame = CreateFrame("Frame", "ExPveInfoPanel_Final", UIParent, "BackdropTemplate")
        mainFrame:SetSize(FIXED_WIDTH, 540)

        local title = mainFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(RRTToolsCore.MAIN_FONT, 16, "OUTLINE")
        title:SetPoint("TOP", 0, -8)
        title:SetTextColor(1, 0.82, 0)
        mainFrame.TitleText = title

        local close = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
        mainFrame.CloseButton = close

        ApplyNDuiSkin(mainFrame)
    else
-- Comment translated to English
        mainFrame = CreateFrame("Frame", "ExPveInfoPanel_Final", UIParent, "DefaultPanelTemplate")
        mainFrame:SetSize(FIXED_WIDTH, 540)
    end

    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetToplevel(true)

    -- Title
    if mainFrame.TitleText then mainFrame.TitleText:SetText(“Weekly M+ Info”) end

    -- Section 1: Top runs this week
    CreateSectionTitle(mainFrame, “Top Runs This Week”, -28)
    local d1 = mainFrame:CreateFontString(nil, “OVERLAY”)
    d1:SetFont(RRTToolsCore.MAIN_FONT, 15, “OUTLINE”)
    d1:SetPoint(“TOPLEFT”, 15, -45)
    d1:SetJustifyH(“LEFT”)
    d1:SetSpacing(2)
    mainFrame.upperDisplay = d1

    -- Section 2: All dungeons detail
    CreateSectionTitle(mainFrame, “Dungeon Details”, -205)
    local d2 = mainFrame:CreateFontString(nil, “OVERLAY”)
    d2:SetFont(RRTToolsCore.MAIN_FONT, 15, “OUTLINE”)
    d2:SetPoint(“TOPLEFT”, 15, -222)
    d2:SetJustifyH(“LEFT”)
    d2:SetSpacing(1)
    mainFrame.lowerDisplay = d2

    mainFrame:Hide()
-- Comment translated to English
    local function ShouldShow()
        if not RRT_DB.enabled then return false end
        if not _G.PVEFrame or not _G.PVEFrame:IsShown() then return false end

        -- 1: GroupFinder (LFG), 2: PVP, 3: Challenges (Mythic+)
        local activeTab = _G.PanelTemplates_GetSelectedTab(_G.PVEFrame)
        if activeTab == 3 then
            return true
        end
        return false
    end

    local function UpdateVisibility()
        if not mainFrame then return end
        if ShouldShow() then
            mainFrame:Show()
            UpdatePosition()
            UpdateStats()
        else
            mainFrame:Hide()
        end
    end

    local function HookPVE()
        if not _G.PVEFrame then return end
        if _G.EXMRH_LaunchButton then _G.EXMRH_LaunchButton:Hide() end
        if _G.EXMRH_SpellInfoButton then _G.EXMRH_SpellInfoButton:Hide() end

-- Comment translated to English
        _G.PVEFrame:HookScript("OnShow", function()
            _G.C_Timer.After(0.1, UpdateVisibility)
        end)
        _G.PVEFrame:HookScript("OnHide", function()
            if mainFrame then mainFrame:Hide() end
        end)

-- Comment translated to English
        if _G.PVEFrame_ShowFrame then
            _G.hooksecurefunc("PVEFrame_ShowFrame", UpdateVisibility)
        end

-- Comment translated to English
        UpdateVisibility()
    end
    if _G.PVEFrame then
        HookPVE()
        HookWindUI()
    else
        RRTToolsCore:RegisterEvent("ADDON_LOADED", RRT_MODULE_KEY,
            function(_, n)
                if n == "Blizzard_GroupFinder" then
                    HookPVE()
                    HookWindUI()
                end
            end)
    end
end

local function RefreshPanelDisplay()
    if mainFrame and mainFrame:IsShown() then
        UpdatePosition()
        UpdateStats()
    end
end

local Module = RRT_NS.PveInfoPanel or {}
RRT_NS.PveInfoPanel = Module

function Module:RefreshDisplay()
    if not mainFrame and RRT_DB.enabled then
        CreateMainFrame()
    end
    if not mainFrame then
        return
    end
    if not RRT_DB.enabled then
        mainFrame:Hide()
        return
    end
    if mainFrame:IsShown() then
        UpdatePosition()
        UpdateStats()
    end
end

RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".DatabaseChanged", RRT_MODULE_KEY, function()
    if not RRT_DB.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end
    if not mainFrame then CreateMainFrame() end
    RefreshPanelDisplay()
end)

RRTToolsCore:RegisterEvent("ITEM_CHANGED", RRT_MODULE_KEY, RefreshPanelDisplay)
RRTToolsCore:RegisterEvent("BAG_UPDATE_DELAYED", RRT_MODULE_KEY, RefreshPanelDisplay)
RRTToolsCore:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE", RRT_MODULE_KEY, RefreshPanelDisplay)
RRTToolsCore:RegisterEvent("PLAYER_ENTERING_WORLD", RRT_MODULE_KEY, function()
    _G.C_Timer.After(0.3, function()
        if mainFrame then
            RefreshPanelDisplay()
        end
    end)
end)

C_Timer.After(1, function() if RRT_DB.enabled then CreateMainFrame() end end)
RRTToolsCore:ReportReady(RRT_MODULE_KEY)

