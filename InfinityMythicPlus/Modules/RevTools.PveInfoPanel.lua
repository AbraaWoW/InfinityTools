-- =============================================================
-- [[ PVE Info Extension Panel ]]
-- { Key = "RevTools.PveInfoPanel", Name = "PVE Info Panel", Desc = "Displays an extra info panel attached to the side of the dungeon finder (PVEFrame).", Category = 4 },
-- =============================================================

local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevTools.PveInfoPanel"

-- =============================================================
-- Part 1: Grid Layout Definition
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 47, h = 2, label = L["Weekly Mythic+ Info"] },
        { key = "desc", type = "description", x = 1, y = 3, w = 47, h = 1, label = L["Automatically attaches an info panel to the side of the PVE frame."] },
        { key = "enabled", type = "checkbox", x = 1, y = 5, w = 12, h = 2, label = L["Enable Module"] },
        { key = "side", type = "select", x = 15, y = 5, w = 12, h = 2, label = L["Attach Side"], options = { ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"] } },
        { key = "offsetX", type = "slider", x = 1, y = 10, w = 15, h = 2, label = L["Horizontal Offset (X)"], min = -100, max = 100, step = 1 },
        { key = "offsetY", type = "slider", x = 18, y = 10, w = 15, h = 2, label = L["Vertical Offset (Y)"], min = -500, max = 500, step = 5 },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, { enabled = false, side = "RIGHT", offsetX = 2, offsetY = 0 })
local mainFrame
local FIXED_WIDTH = 260

-- =============================================================
-- Part 2: Helper Components (Badge-style UI widgets)
-- =============================================================

local function CreateSectionTitle(parent, text, yOfs)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(FIXED_WIDTH - 15, 14)
    container:SetPoint("TOP", parent, "TOP", 0, yOfs)
    local label = container:CreateFontString(nil, "OVERLAY")
    label:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
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

    -- Prevent ElvUI global scan from skinning this button
    btn.IsSkinned = true
    btn.noBackdrop = true

    local icon = btn:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetTexture("Interface\AddOns\InfinityCore\Textures\" .. texture)
    icon:SetVertexColor(0.85, 0.85, 0.85)
    btn.icon = icon
    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
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
-- Part 3: Core Features (Data Processing)
-- =============================================================

local function UpdatePosition()
    if not mainFrame or not mainFrame:IsShown() then return end

    local offX, offY = 2, 0 -- Default offset
    mainFrame:ClearAllPoints()

    -- [WindUI / Wind Toolbox attachment logic]
    local anchorFrame = _G.PVEFrame

    -- Detect ElvUI_WindTools
    local wt = _G.WindTools and _G.WindTools[1]
    if wt and wt.GetModule then
        local ll = wt:GetModule("LFGList", true)
        if ll and ll.RightPanel and ll.RightPanel:IsShown() then
            anchorFrame = ll.RightPanel
        end
    end

    -- Fallback compatibility (if the user has another addon named WindUI)
    if anchorFrame == _G.PVEFrame then
        if _G.WindUI_PveFrame and _G.WindUI_PveFrame:IsShown() then
            anchorFrame = _G.WindUI_PveFrame
        elseif _G.WindUI_MainFrame and _G.WindUI_MainFrame:IsShown() then
            anchorFrame = _G.WindUI_MainFrame
        end
    end

    mainFrame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", offX, offY)
    mainFrame:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMRIGHT", offX, offY)
    mainFrame:SetWidth(FIXED_WIDTH)
end

-- [Linked Hook] Ensure that when Wind Toolbox refreshes its panel, we also sync position
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
    local ID_TO_NAME = {
        --12.0 S1
        [239] = "Seat",
        [556] = "Mold",
        [161] = "Sky",
        [402] = "Eco",
        [557] = "Vortex",
        [558] = "MGT",
        [560] = "Myza",
        [559] = "Nexus",
        --11.2 S3
        [525] = "Flood",
        [499] = "Priory",
        [505] = "Dawn",
        [503] = "Echo",
        [542] = "Mecha",
        [378] = "Atonement",
        [392] = "Theater",
        [391] = "Streets"
    }

    -- Get this week's run results
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



    -- 2. Upper section
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

    -- 2. Lower section
    local lower = ""
    for _, id in ipairs(mapTable) do
        local _, _, _, icon = _G.C_ChallengeMode.GetMapUIInfo(id)
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
        local nameOverlay = string.format("|cffffd100%s|r", ID_TO_NAME[id] or "?")
        lower = lower .. string.format("%s %s (%s)\n", iconMarkup, nameOverlay, runsStr)
    end
    mainFrame.lowerDisplay:SetText(lower:gsub("\n$", ""))
end

-- Centralized skin application logic
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

-- NDui skin application logic
local function ApplyNDuiSkin(frame)
    if not frame then return false end
    local NDuiSkin = InfinityTools.NDuiSkin
    if not NDuiSkin or not NDuiSkin:IsNDuiLoaded() then return false end

    local NDui = _G.NDui
    if not NDui then return false end
    local B = NDui[1] -- NDui core function library
    if not B then return false end

    local ok = pcall(function()
        -- Apply NDui Backdrop directly to the frame (using SkinAlpha opacity)
        B.CreateBD(frame)
        -- Add shadow
        B.CreateSD(frame, nil, true)
        -- Add background texture
        B.CreateTex(frame)
        -- Skin the close button (must use ReskinClose instead of Reskin to preserve the × icon)
        if frame.CloseButton then
            B.ReskinClose(frame.CloseButton)
        end
    end)
    return ok
end

local function CreateMainFrame()
    if mainFrame then return end

    local Skin = InfinityTools.ElvUISkin
    local isElv = Skin and Skin:IsElvUILoaded()
    local NDuiSkin = InfinityTools.NDuiSkin
    local isNDui = NDuiSkin and NDuiSkin:IsNDuiLoaded()

    if isElv then
        -- [ElvUI mode]: create a clean window, build all components manually
        mainFrame = CreateFrame("Frame", "RevPveInfoPanel_Final", UIParent)
        mainFrame:SetSize(FIXED_WIDTH, 540)

        local title = mainFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(InfinityTools.MAIN_FONT, 16, "OUTLINE")
        title:SetPoint("TOP", 0, -8)
        title:SetTextColor(1, 0.82, 0)
        mainFrame.TitleText = title

        local close = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
        mainFrame.CloseButton = close

        ApplyElvUISkin(mainFrame)
    elseif isNDui then
        -- [NDui mode]: create a clean window and apply NDui styling
        mainFrame = CreateFrame("Frame", "RevPveInfoPanel_Final", UIParent, "BackdropTemplate")
        mainFrame:SetSize(FIXED_WIDTH, 540)

        local title = mainFrame:CreateFontString(nil, "OVERLAY")
        title:SetFont(InfinityTools.MAIN_FONT, 16, "OUTLINE")
        title:SetPoint("TOP", 0, -8)
        title:SetTextColor(1, 0.82, 0)
        mainFrame.TitleText = title

        local close = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
        mainFrame.CloseButton = close

        ApplyNDuiSkin(mainFrame)
    else
        -- [Blizzard mode]: use the native template directly; no skin modifications
        mainFrame = CreateFrame("Frame", "RevPveInfoPanel_Final", UIParent, "DefaultPanelTemplate")
        mainFrame:SetSize(FIXED_WIDTH, 540)
    end

    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetToplevel(true)

    -- Ensure the title text is set
    if mainFrame.TitleText then mainFrame.TitleText:SetText(L["Weekly Mythic+ Info"]) end

    -- Top buttons: fixed positions; only swap “Stats” and “Season”
    mainFrame.infoBtn = CreateHeaderIcon(mainFrame, "RevInfo.png", -75, L["Spells"],
        function() if SlashCmdList["EXSP"] then SlashCmdList["EXSP"]() end end)
    mainFrame.vaultBtn = CreateHeaderIcon(mainFrame, "RevVault.png", 0, L["Mythic+"],
        function() if SlashCmdList["EXMPLUS"] then SlashCmdList["EXMPLUS"]() end end)
    mainFrame.statBtn = CreateHeaderIcon(mainFrame, "RevTotal.png", 75, L["History"],
        function() if _G.EXMYRUN then _G.EXMYRUN:ToggleWindow() end end)

    -- Section 1 (Great Vault summary): shifted down to clear the icons
    CreateSectionTitle(mainFrame, L["Great Vault Summary"], -75)
    local d1 = mainFrame:CreateFontString(nil, "OVERLAY")
    d1:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
    d1:SetPoint("TOPLEFT", 15, -92)
    d1:SetJustifyH("LEFT")
    d1:SetSpacing(2)
    mainFrame.upperDisplay = d1

    -- Section 2 (DaMi M+ details): floated down by corresponding height
    CreateSectionTitle(mainFrame, L["This Week's M+ Details"], -251)
    local d2 = mainFrame:CreateFontString(nil, "OVERLAY")
    d2:SetFont(InfinityTools.MAIN_FONT, 15, "OUTLINE")
    d2:SetPoint("TOPLEFT", 15, -267)
    d2:SetJustifyH("LEFT")
    d2:SetSpacing(1)
    mainFrame.lowerDisplay = d2

    mainFrame:Hide()
    -- Decide whether the panel should be shown
    local function ShouldShow()
        if not MODULE_DB.enabled then return false end
        if not _G.PVEFrame or not _G.PVEFrame:IsShown() then return false end

        -- 1: GroupFinder (LFG), 2: PVP, 3: Challenges (PVE/Mythic+)
        -- Per user requirement: only show when the PVE (M+/Challenges) tab is active
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
        if _G.RevMRH_LaunchButton then _G.RevMRH_LaunchButton:Hide() end
        if _G.RevMRH_SpellInfoButton then _G.RevMRH_SpellInfoButton:Hide() end

        -- Hook show/hide scripts
        _G.PVEFrame:HookScript("OnShow", function()
            _G.C_Timer.After(0.1, UpdateVisibility)
        end)
        _G.PVEFrame:HookScript("OnHide", function()
            if mainFrame then mainFrame:Hide() end
        end)

        -- Hook Blizzard's tab switch function
        if _G.PVEFrame_ShowFrame then
            _G.hooksecurefunc("PVEFrame_ShowFrame", UpdateVisibility)
        end

        -- Initial visibility check
        UpdateVisibility()
    end
    if _G.PVEFrame then
        HookPVE()
        HookWindUI()
    else
        InfinityTools:RegisterEvent("ADDON_LOADED", INFINITY_MODULE_KEY,
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
        UpdateStats()
    end
end

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function()
    if not MODULE_DB.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end
    if not mainFrame then CreateMainFrame() end
    RefreshPanelDisplay()
end)

InfinityTools:RegisterEvent("ITEM_CHANGED", INFINITY_MODULE_KEY, RefreshPanelDisplay)
InfinityTools:RegisterEvent("BAG_UPDATE_DELAYED", INFINITY_MODULE_KEY, RefreshPanelDisplay)
InfinityTools:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE", INFINITY_MODULE_KEY, RefreshPanelDisplay)
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    _G.C_Timer.After(0.3, function()
        if mainFrame then
            RefreshPanelDisplay()
        end
    end)
end)

C_Timer.After(1, function() if MODULE_DB.enabled then CreateMainFrame() end end)
InfinityTools:ReportReady(INFINITY_MODULE_KEY)
