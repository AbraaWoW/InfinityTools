local _, RRT_NS = ... -- Internal namespace
_G["RRTAPI"] = {}
RRT_NS.specs = {}
RRT_NS.LCG = LibStub("LibCustomGlow-1.0")
RRT_NS.LGF = LibStub("LibGetFrame-1.0")
RRT_NS.RRTFrame = CreateFrame("Frame", nil, UIParent)
RRT_NS.RRTFrame:SetAllPoints(UIParent)
RRT_NS.RRTFrame:SetFrameStrata("BACKGROUND")

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

function RRT_NS:InitLDB()
    if LDB then
        local databroker = LDB:NewDataObject("RRT", {
            type = "launcher",
            label = "Infinity Raid Tools",
            icon = [[Interface\AddOns\InfinityTools\Media\logo.png]],
            showInCompartment = true,
            OnClick = function(self, button)
                if button == "LeftButton" then
                    RRT_NS.RRTUI:ToggleOptions()
                elseif button == "RightButton" then
                    if RRT_NS.ToggleGlobalEditMode then
                        RRT_NS:ToggleGlobalEditMode()
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Infinity Raid Tools", 0.73, 0.4, 1)
                tooltip:AddLine("|cFFCFCFCFLeft click|r: Show/Hide Options Window")
                tooltip:AddLine("|cFFCFCFCFRight click|r: Toggle Edit Mode")
            end
        })

        if (databroker and not LDBIcon:IsRegistered("RRT")) then
            LDBIcon:Register("RRT", databroker, RRT.Settings["Minimap"])
            LDBIcon:AddButtonToCompartment("RRT")
        end

        self.databroker = databroker
    end
end


RRT_NS.EncounterAlertStart = {}
RRT_NS.EncounterAlertStop = {}
RRT_NS.ShowWarningAlert = {}
RRT_NS.ShowBossWhisperAlert = {}
RRT_NS.AddAssignments = {}
RRT_NS.DetectPhaseChange = {}
