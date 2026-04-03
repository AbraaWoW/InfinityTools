local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

local MODULE_KEY = "RRTTools.MDTIconHook"
local DEFAULTS = {
    enabled = false,
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local hooked = false

local function TryHookMDT()
    if hooked or not DB.enabled then
        return
    end

    local mdt = _G.MDT or _G.MythicDungeonTools or _G.MDTGuide
    if not mdt then
        return
    end

    local mainFrame = _G.MDTMainFrame or _G.MythicDungeonToolsFrame or mdt.main_frame
    if not mainFrame then
        return
    end

    local button = CreateFrame("Button", "RRTMDTOpenSpellGuide", mainFrame, "UIPanelButtonTemplate")
    button:SetSize(110, 22)
    button:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -40, -8)
    button:SetText("RRT Spell Guide")
    button:SetScript("OnClick", function()
        if RRT_NS.MythicSpellInfo then
            RRT_NS.MythicSpellInfo:ToggleWindow()
        end
    end)
    hooked = true
end

Core:RegisterEvent("PLAYER_ENTERING_WORLD", MODULE_KEY, TryHookMDT)
Core:RegisterEvent("ADDON_LOADED", MODULE_KEY, function(_, addonName)
    if addonName == "MythicDungeonTools" or addonName == "MDT" then
        TryHookMDT()
    end
end)

RRT_NS.MDTIconHook = {
    RefreshDisplay = function()
        DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
        TryHookMDT()
    end,
}
