local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

-- Only active on PTR/Beta (mirrors RevPTR.SetKey.lua detection logic)
if not _G.IsBetaBuild() then return end

local INFINITY_MODULE_KEY = "RevPTR.MiniTools"
-- Check whether the module is registered and enabled in the engine
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- Default config
local INFINITY_DEFAULTS = {
    blockFeedback = true,
    autoLearnProf = true,
}
local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)

-- ========================================================================
-- [Layout Registration] Grid settings UI
-- ========================================================================
local function RegisterLayout()
    local layout = {
        { key = "header", type = "header", x = 2, y = 2, w = 53, h = 2, label = L["PTR Toolbox"], labelSize = 25 },  -- TODO: missing key: L["PTR Toolbox"]
        { key = "blockFeedback", type = "checkbox", x = 2, y = 6, w = 2, h = 2, label = L["Disable PTR feedback popups (Tooltip Issue Reporter)"] },
        { key = "autoLearnProf", type = "checkbox", x = 2, y = 10, w = 2, h = 2, label = L["Enable one-click profession spec learning"] },
        { key = "desc", type = "description", x = 2, y = 14, w = 53, h = 4, label = L["|cff808080* These features only work on Beta/PTR. The one-click learn button appears on the profession specialization page.|r"] },
    }
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

RegisterLayout()

-- ========================================================================
-- 1. [BlockFeedback] Block PTR feedback popups
-- ========================================================================
local function Init_BlockFeedback()
    if not MODULE_DB.blockFeedback then return end

    local function RunDisableLogic()
        if _G.PTR_IssueReporter then
            if _G.PTR_IssueReporter.HookIntoTooltip then _G.PTR_IssueReporter.HookIntoTooltip = function() end end
            if _G.PTR_IssueReporter.TriggerEvent then _G.PTR_IssueReporter.TriggerEvent = function() end end
            _G.PTR_IssueReporter.InitializePTRTooltips = function() end

            if _G.TooltipDataProcessor and _G.TooltipDataProcessor.AddTooltipPostCall then
                for tooltipType in pairs(_G.Enum.TooltipDataType) do
                    pcall(function() _G.TooltipDataProcessor.RemoveTooltipPostCall(tooltipType) end)
                end
            end

            _G.hooksecurefunc(_G.GameTooltip, "SetUnitAura", function() end)
            _G.hooksecurefunc(_G.GameTooltip, "SetSpellByID", function() end)
            _G.hooksecurefunc(_G.GameTooltip, "SetCurrencyToken", function() end)
            _G.hooksecurefunc(_G.GameTooltip, "SetItemByID", function() end)
        else
            _G.C_Timer.After(1, RunDisableLogic)
        end
    end
    RunDisableLogic()
end

-- ========================================================================
-- 2. [AutoLearnProf] One-click learn all profession specializations
-- ========================================================================
local function Init_AutoLearnProf()
    if not MODULE_DB.autoLearnProf then return end

    local function AutoLearnAll(frame)
        local professionID = frame.professionInfo and frame.professionInfo.professionID
        if not professionID then return end

        local configID = _G.C_ProfSpecs.GetConfigIDForSkillLine(professionID)
        local traitTreeIDs = _G.C_ProfSpecs.GetSpecTabIDsForSkillLine(professionID)
        if not configID or configID == 0 then return end

        local changed = true
        local iterations = 0
        while changed and iterations < 40 do
            changed = false
            iterations = iterations + 1

            for _, treeID in _G.ipairs(traitTreeIDs) do
                local tabState = _G.C_ProfSpecs.GetStateForTab(treeID, configID)
                if tabState == _G.Enum.ProfessionsSpecTabState.Unlockable then
                    local tabInfo = _G.C_ProfSpecs.GetTabInfo(treeID)
                    if tabInfo and tabInfo.rootNodeID then
                        _G.C_Traits.PurchaseRank(configID, tabInfo.rootNodeID)
                        changed = true
                    end
                end

                local nodeIDs = _G.C_Traits.GetTreeNodes(treeID)
                for _, nodeID in _G.ipairs(nodeIDs) do
                    local nodeInfo = _G.C_Traits.GetNodeInfo(configID, nodeID)
                    if nodeInfo then
                        if nodeInfo.type == _G.Enum.TraitNodeType.Selection then
                            if #nodeInfo.entryIDs > 0 and (not nodeInfo.activeEntry or nodeInfo.activeEntry.entryID == 0) then
                                _G.C_Traits.SetSelection(configID, nodeID, nodeInfo.entryIDs[1])
                                changed = true
                                nodeInfo = _G.C_Traits.GetNodeInfo(configID, nodeID)
                            end
                        end

                        while nodeInfo and nodeInfo.canPurchaseRank do
                            if _G.C_Traits.PurchaseRank(configID, nodeID) then
                                changed = true
                                nodeInfo = _G.C_Traits.GetNodeInfo(configID, nodeID)
                            else
                                break
                            end
                        end
                    end
                end
            end
        end

        if iterations > 1 then
            _G.C_Traits.CommitConfig(configID)
            print("|cff00ff00[InfinityTools] " .. L["Profession specialization points maxed out (PTR mode)."] .. "|r")
        else
            print("|cffffff00[InfinityTools] " .. L["No available specialization points to spend."] .. "|r")
        end
    end

    local function CreateLearnButton()
        local pFrame = _G.ProfessionsFrame
        if not pFrame or not pFrame.SpecPage or not pFrame.SpecPage.ApplyButton then return end
        if _G.InfinityProfAutoLearnBtn then return end

        local btn = _G.CreateFrame("Button", "InfinityProfAutoLearnBtn", pFrame.SpecPage, "MagicButtonTemplate")
        btn:SetSize(120, 24)
        btn:SetPoint("RIGHT", pFrame.SpecPage.ApplyButton, "LEFT", -10, 0)
        btn:SetText(L["Learn All"])
        btn:SetFrameLevel(pFrame.SpecPage.ApplyButton:GetFrameLevel() + 5)

        btn:SetScript("OnClick", function()
            if pFrame.SpecPage:IsVisible() then
                AutoLearnAll(pFrame.SpecPage)
                if pFrame.SpecPage.TreePreview then
                    pFrame.SpecPage.TreePreview:Hide()
                end
            end
        end)

        local function UpdateBtnVisibility()
            local isVisible = (pFrame.SpecPage and pFrame.SpecPage:IsVisible())
            if isVisible then btn:Show() else btn:Hide() end
        end

        pFrame:HookScript("OnShow", UpdateBtnVisibility)
        if pFrame.SpecPage then
            pFrame.SpecPage:HookScript("OnShow", UpdateBtnVisibility)
        end
        _G.hooksecurefunc(pFrame, "SetTab", function()
            _G.C_Timer.After(0.1, UpdateBtnVisibility)
        end)
        UpdateBtnVisibility()
    end

    if _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
        CreateLearnButton()
    else
        InfinityTools:RegisterEvent("ADDON_LOADED", "RevPTR_Mini_ProfLearn", function(_, addon)
            if addon == "Blizzard_Professions" then
                CreateLearnButton()
            end
        end)
    end
end

-- ========================================================================
-- Initialization
-- ========================================================================
Init_BlockFeedback()
Init_AutoLearnProf()

-- Report load status
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

