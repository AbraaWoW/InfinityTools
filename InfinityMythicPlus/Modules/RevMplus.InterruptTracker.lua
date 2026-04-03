-- =============================================================
-- [[ Teammate Interrupt Tracker (Bar Style) ]]
-- { Key = "RevMplus.InterruptTracker", Name = "Interrupt Tracker (Bars)", Desc = "Tracks teammate interrupt cooldowns in real time (bar style).", Category = 2 },
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevMplus.InterruptTracker"
local PartySpec = InfinityTools.PartySpec
local InfinityDB = _G.InfinityDB
local C_Spell = _G.C_Spell
local LSM = LibStub("LibSharedMedia-3.0")

-- Frequently used global function references
local UnitGUID = _G.UnitGUID
local UnitName = _G.UnitName
local UnitClass = _G.UnitClass
local UnitExists = _G.UnitExists
local GetTime = _G.GetTime
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local C_Timer = _G.C_Timer
local wipe = _G.wipe
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local C_ClassColor = _G.C_ClassColor
local GetInstanceInfo = _G.GetInstanceInfo
local C_ChallengeMode = _G.C_ChallengeMode
local IsInRaid = _G.IsInRaid
local GetNumGroupMembers = _G.GetNumGroupMembers

-- Use InfinityDB.InterruptData
local SPEC_INTERRUPT_DB = InfinityDB.InterruptData

-- =============================================================
-- Grid layout
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 53, h = 2, label = L["Interrupt Tracker (Bars)"], labelSize = 25 },
        { key = "desc", type = "description", x = 1, y = 4, w = 53, h = 2, label = L["Tracks teammate interrupt cooldowns in real time (bar style)."] },
        { key = "div1", type = "divider", x = 1, y = 8, w = 53, h = 1, label = "--[[ Function ]]" },
        { key = "subheader_func", type = "subheader", x = 1, y = 7, w = 53, h = 1, label = L["General Settings"], labelSize = 20 },
        { key = "enabled", type = "checkbox", x = 1, y = 9, w = 6, h = 2, label = L["Enable"] },
        { key = "locked", type = "checkbox", x = 10, y = 9, w = 8, h = 2, label = L["Lock Position"] },
        { key = "preview", type = "checkbox", x = 20, y = 9, w = 8, h = 2, label = L["Preview Mode"] },
        { key = "btn_reset_pos", type = "button", x = 30, y = 9, w = 14, h = 2, label = L["Reset Position"] },
        { key = "posX", type = "slider", x = 19, y = 13, w = 14, h = 2, label = L["Overall Horizontal Position"], min = -1000, max = 1000 },
        { key = "posY", type = "slider", x = 36, y = 13, w = 14, h = 2, label = L["Overall Vertical Position"], min = -1000, max = 1000 },
        { key = "color_header", type = "header", x = 1, y = 29, w = 48, h = 2, label = L["Bars"], labelSize = 20 },
        { key = "spacing", type = "slider", x = 1, y = 34, w = 17, h = 2, label = L["Vertical Spacing"], min = 0, max = 50 },
        { key = "growDirection", type = "dropdown", x = 21, y = 34, w = 15, h = 2, label = L["Grow Direction"], items = "Down,Up" },
        { key = "maxBars", type = "slider", x = 1, y = 37, w = 17, h = 2, label = L["Max Visible Bars"], min = 1, max = 15 },
        { key = "useClassColorBar", type = "checkbox", x = 21, y = 37, w = 15, h = 2, label = L["Use Class Colors"] },
        { key = "timerGroup", type = "timerBarGroup", x = 1, y = 40, w = 53, h = 26, label = L["Bar Appearance"], labelSize = 20 },
        { key = "font_name_header", type = "header", x = 1, y = 67, w = 53, h = 3, label = L["Player Name"], labelSize = 20 },
        { key = "showPlayerName", type = "checkbox", x = 1, y = 72, w = 15, h = 2, label = L["Show Player Name"] },
        { key = "nameAlign", type = "dropdown", x = 18, y = 72, w = 15, h = 2, label = L["Name Alignment"], items = "LEFT,CENTER,RIGHT" },
        { key = "useClassColorName", type = "checkbox", x = 35, y = 72, w = 15, h = 2, label = L["Use Class Colors"] },
        { key = "font_name", type = "fontgroup", x = 1, y = 74, w = 53, h = 17, label = L["Player Name Text"], labelSize = 20 },
        { key = "font_timer_header", type = "header", x = 1, y = 94, w = 53, h = 2, label = L["Cooldown Time Settings"], labelSize = 20 },
        { key = "showTimer", type = "checkbox", x = 1, y = 98, w = 15, h = 2, label = L["Show Remaining Time"] },
        { key = "showReadyText", type = "checkbox", x = 18, y = 98, w = 15, h = 2, label = L["Show Ready When Cooldown Ends"] },
        { key = "readyText", type = "input", x = 35, y = 98, w = 15, h = 2, label = L["Ready Text"] },
        { key = "font_timer", type = "fontgroup", x = 1, y = 100, w = 53, h = 18, label = L["Time Text Settings"], labelSize = 20 },
        { key = "sort_header", type = "header", x = 1, y = 120, w = 53, h = 2, label = L["Sort Priority"], labelSize = 20 },
        { key = "sort_desc", type = "description", x = 1, y = 123, w = 53, h = 2, label = L["When cooldown is ready, sort by role priority. While cooling down, sort by remaining time (shorter first)."] },
        { key = "sortPriorityTank", type = "slider", x = 1, y = 126, w = 15, h = 2, label = L["Tank Priority"], min = 1, max = 3 },
        { key = "sortPriorityHealer", type = "slider", x = 19, y = 126, w = 15, h = 2, label = L["Healer Priority"], min = 1, max = 3 },
        { key = "sortPriorityDPS", type = "slider", x = 36, y = 126, w = 15, h = 2, label = L["DPS Priority"], min = 1, max = 3 },
        { key = "sortMeleeDPSFirst", type = "checkbox", x = 1, y = 129, w = 20, h = 2, label = L["Melee DPS before Ranged DPS"] },
        { key = "attach_header", type = "header", x = 1, y = 16, w = 49, h = 2, label = L["Attach to Party Frames"], labelSize = 20 },
        { key = "attach_desc", type = "description", x = 1, y = 19, w = 49, h = 1, label = L["Attach the interrupt bars above or below the party frame group."] },
        { key = "attachToRaidFrame", type = "checkbox", x = 1, y = 21, w = 15, h = 2, label = L["Enable Party Frame Attach"] },
        { key = "attachFrame", type = "dropdown", x = 36, y = 21, w = 14, h = 2, label = L["Target Frame"], items = "None,DandersFrames,NDui,ElvUI,EQO Party Frames,Grid2,Blizzard Party Frames" },
        { key = "attachPoint", type = "dropdown", x = 1, y = 25, w = 15, h = 2, label = L["Attach to Target Frame"], items = "Above,Below" },
        { key = "attachOffsetX", type = "slider", x = 19, y = 25, w = 15, h = 2, label = L["Horizontal Offset"], min = -150, max = 150 },
        { key = "attachOffsetY", type = "slider", x = 36, y = 25, w = 15, h = 2, label = L["Vertical Offset"], min = -150, max = 150 },
        { key = "attachAutoWidth", type = "checkbox", x = 19, y = 21, w = 9, h = 2, label = L["Auto Width"] },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end
local MODULE_DEFAULTS = {
    enabled = false,
    font_name = {
        a = 1,
        align = "LEFT",
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = true,
        shadowX = 1.6000003814697,
        shadowY = -0.69999885559082,
        size = 16,
        x = 2,
        y = 0,
    },
    font_timer = {
        a = 1,
        b = 1,
        font = "Default",
        g = 1,
        outline = "OUTLINE",
        r = 1,
        shadow = false,
        shadowX = 1,
        shadowY = -1,
        size = 14,
        x = 0,
        y = 0,
    },
    growDirection = "Down",
    locked = true,
    maxBars = 5,
    nameAlign = "LEFT",
    pos = {
        "CENTER",
        "UIParent",
        "CENTER",
        0,
        -200,
    },
    posX = -592,
    posY = -52,
    preview = true,
    readyText = "Ready",
    showPlayerName = true,
    showReadyText = false,
    showTimer = true,
    spacing = 1,
    timerGroup = {
        barBgColor = {
            a = 0.6,
            b = 0.1,
            g = 0.1,
            r = 0.1,
        },
        barBgColorA = 0.5,
        barBgColorB = 0,
        barBgColorG = 0,
        barBgColorR = 0,
        barColor = {
            a = 1,
            b = 0.5,
            g = 0.5,
            r = 0.5,
        },
        barColorA = 1,
        barColorB = 0.2,
        barColorG = 0.8,
        barColorR = 0.2,
        height = 24,
        iconOffsetX = -1,
        iconOffsetY = 0,
        iconSide = "LEFT",
        iconSize = 23,
        showIcon = true,
        texture = "Melli",
        width = 150,
    },
    useClassColorBar = true,
    useClassColorName = false,
    sortPriorityTank = 1, -- Tanks first
    sortPriorityHealer = 2, -- Healers second
    sortPriorityDPS = 3, -- DPS last
    sortMeleeDPSFirst = false, -- Do not prioritize melee DPS by default
    -- Party frame attachment
    attachToRaidFrame = false, -- Enable party frame attach mode
    attachFrame = "None", -- Target frame (None/DandersFrames/NDui/ElvUI/EQO Party Frames/Grid2)
    attachPoint = "Above", -- Attach point: Above/Below
    attachOffsetX = 0, -- Horizontal offset
    attachOffsetY = 2, -- Vertical offset
    attachAutoWidth = true, -- Auto width matching party unit frame width
    _attachFrameSetByUser = false, -- Internal flag: user manually selected the target frame
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =============================================================
-- Auto-detect loaded party frame addons (only when the user has not selected one manually)
-- =============================================================
--- Delayed auto-detection: run on first module use because addon frames may not exist yet.
local attachFrameAutoDetectDone = false
local function AutoDetectAttachFrame()
    if attachFrameAutoDetectDone then return end
    attachFrameAutoDetectDone = true
    -- Do not override a user-selected frame
    if MODULE_DB._attachFrameSetByUser then return end
    -- Detection priority: DandersFrames > NDui > ElvUI > EQO Party Frames > Grid2 > Blizzard Party Frames
    if _G.DandersFrames and _G.DandersFrames.Api then
        MODULE_DB.attachFrame = "DandersFrames"
    elseif _G.oUF_Party or (_G.NDui and C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("NDui")) then
        MODULE_DB.attachFrame = "NDui"
    elseif _G.ElvUI or (_G.ElvUF_PartyGroup1) then
        MODULE_DB.attachFrame = "ElvUI"
    elseif _G.EQOLUFPartyHeaderUnitButton1 or _G.EQOLUFPartyHeader then
        MODULE_DB.attachFrame = "EQO Party Frames"
    elseif (_G.Grid2 and _G.Grid2.GetUnitFrames) or _G.Grid2LayoutFrame or _G.Grid2LayoutHeader1UnitButton1 then
        MODULE_DB.attachFrame = "Grid2"
    elseif _G.CompactPartyFrame then
        MODULE_DB.attachFrame = "Blizzard Party Frames"
    end
end

-- =============================================================
-- UI frame system
-- =============================================================
local anchorFrame = nil
local activeBars = {}   -- [guid] = { bar, spellID, cd, startTime }
local usedBarsList = {} -- Ordered list used for layout
local previewBars = {}  -- Preview mode bars
local isPreviewing = false
local InfinityFactory = _G.InfinityFactory

-- Forward declarations to avoid load-order nil errors
local UpdateLayout, ReLayout, RefreshAll, TogglePreview, CreateAnchor

local function GetUnitSpecID(unit)
    local specID = 0
    if PartySpec then
        specID = PartySpec:GetSpec(unit)
    end

    if specID == 0 and unit == "player" then
        specID = GetSpecializationInfo(GetSpecialization() or 1)
    end

    return specID or 0
end

local function GetUnitInterruptSpellData(unit)
    local specID = GetUnitSpecID(unit)
    if specID == 0 then return nil, 0 end
    return SPEC_INTERRUPT_DB[specID], specID
end

-- =============================================================
-- Environment check: only active in a party inside 5-player instances
-- =============================================================
local isValidEnvironment = nil

--- Check whether the current environment is valid (party + 5-player instance)
local function CheckEnvironment()
    local state = InfinityTools.State
    local inParty = state.IsInParty or false
    local instanceType = state.InstanceType or "none"

    -- Must be in a party and in a "party" instance type
    local shouldEnable = inParty and instanceType == "party"

    if shouldEnable ~= isValidEnvironment then
        isValidEnvironment = shouldEnable

        if not shouldEnable then
            -- Invalid environment: hide all UI
            if anchorFrame then
                anchorFrame:Hide()
            end
            for guid, data in pairs(activeBars) do
                if data.bar then
                    data.bar:Hide()
                end
            end
        else
            -- Valid environment: restore display
            if MODULE_DB.enabled then
                UpdateLayout()
            end
        end
    end

    return shouldEnable
end

-- =============================================================
-- Party frame attachment with support for DandersFrames / NDui / ElvUI / EQO Party Frames / Grid2 / Blizzard Party Frames
-- =============================================================
local DandersFramesApi = nil    -- Lazy-loaded to avoid addon load-order issues
local hookedAttachFrames = {}   -- Frames already hooked on OnSizeChanged
local lastAttachUnitWidth = nil -- Last known unit frame width

--- Get the DandersFrames API reference lazily.
local function GetDandersFramesApi()
    if DandersFramesApi then return DandersFramesApi end
    if _G.DandersFrames and _G.DandersFrames.Api then
        DandersFramesApi = _G.DandersFrames.Api
    end
    return DandersFramesApi
end

--- Check whether a given party frame addon is loaded.
--- @param addonName string "DandersFrames"|"NDui"|"ElvUI"|"EQO Party Frames"|"Grid2"|"Blizzard Party Frames"
--- @return boolean
local function IsAddonAvailable(addonName)
    if addonName == "DandersFrames" then
        return GetDandersFramesApi() ~= nil
    elseif addonName == "NDui" then
        return _G["oUF_Party"] ~= nil
    elseif addonName == "ElvUI" then
        return _G["ElvUF_PartyGroup1"] ~= nil
    elseif addonName == "EQO Party Frames" then
        return _G["EQOLUFPartyHeader"] ~= nil or _G["EQOLUFPartyHeaderUnitButton1"] ~= nil
    elseif addonName == "Grid2" then
        return _G["Grid2LayoutFrame"] ~= nil or (_G.Grid2 and _G.Grid2.GetUnitFrames ~= nil)
    elseif addonName == "Blizzard Party Frames" then
        return _G["CompactPartyFrame"] ~= nil
    end
    return false
end

--- Collect EQO party unit frames.
--- @param includeHidden boolean|nil true = include hidden frames
--- @return table
local function CollectEQOPartyUnitFrames(includeHidden)
    local frames = {}
    for i = 1, 5 do
        local frame = _G["EQOLUFPartyHeaderUnitButton" .. i]
        if frame and (includeHidden or frame:IsVisible()) then
            frames[#frames + 1] = frame
        end
    end
    return frames
end

--- Collect Grid2 party unit frames.
--- Prefer Grid2 API; fall back to the frame naming pattern if unavailable:
--- Grid2LayoutHeaderNUnitButtonM
--- @param includeHidden boolean|nil true = include hidden frames
--- @return table
local function CollectGrid2PartyUnitFrames(includeHidden)
    local frames, seen = {}, {}
    local function Push(frame)
        if not frame or seen[frame] then return end
        if includeHidden or frame:IsVisible() then
            seen[frame] = true
            frames[#frames + 1] = frame
        end
    end

    local grid2 = _G.Grid2
    if grid2 and grid2.GetUnitFrames then
        local testUnits = { "player", "party1", "party2", "party3", "party4" }
        for _, unit in ipairs(testUnits) do
            local unitFrames = grid2:GetUnitFrames(unit)
            if type(unitFrames) == "table" then
                for frame in pairs(unitFrames) do
                    Push(frame)
                end
            end
        end
    end

    if #frames == 0 then
        for headerIndex = 1, 8 do
            for unitIndex = 1, 5 do
                Push(_G["Grid2LayoutHeader" .. headerIndex .. "UnitButton" .. unitIndex])
            end
        end
    end

    return frames
end

--- Check whether attach mode is available (addon loaded and party size <= 5).
local function IsAttachModeAvailable()
    if not MODULE_DB.attachToRaidFrame then return false end
    local frameName = MODULE_DB.attachFrame
    if not frameName or frameName == "None" then return false end

    -- Disable attach mode in raids
    if IsInRaid and IsInRaid() then return false end

    return IsAddonAvailable(frameName)
end

--- Get the party header frame for the selected addon.
--- @return Frame|nil Party header frame
local function GetAttachTargetFrame()
    local frameName = MODULE_DB.attachFrame
    if frameName == "DandersFrames" then
        return _G["DandersPartyHeader"]
    elseif frameName == "NDui" then
        return _G["oUF_Party"]
    elseif frameName == "ElvUI" then
        return _G["ElvUF_PartyGroup1"]
    elseif frameName == "EQO Party Frames" then
        return _G["EQOLUFPartyHeader"] or _G["EQOLUFPartyHeaderUnitButton1"]
    elseif frameName == "Grid2" then
        local unitFrames = CollectGrid2PartyUnitFrames(false)
        if unitFrames[1] and unitFrames[1].GetParent then
            return unitFrames[1]:GetParent()
        end
        return _G["Grid2LayoutFrame"]
    elseif frameName == "Blizzard Party Frames" then
        return _G["CompactPartyFrame"]
    end
    return nil
end

--- Get the first visible unit frame from the selected party frame addon.
--- @return Frame|nil First visible unit frame
local function GetFirstVisibleUnitFrame()
    local frameName = MODULE_DB.attachFrame
    if frameName == "DandersFrames" then
        local api = GetDandersFramesApi()
        if not api or not api.GetFrameForUnit then return nil end
        local testUnits = { "player", "party1", "party2", "party3", "party4" }
        for _, unit in ipairs(testUnits) do
            local frame = api.GetFrameForUnit(unit, "party")
            if frame and frame:IsVisible() then
                return frame
            end
        end
    elseif frameName == "NDui" then
        local header = _G["oUF_Party"]
        if not header then return nil end
        for i = 1, 5 do
            local child = header:GetAttribute("child" .. i)
            if child and child:IsVisible() then
                return child
            end
        end
    elseif frameName == "ElvUI" then
        local header = _G["ElvUF_PartyGroup1"]
        if not header then return nil end
        for i = 1, 5 do
            local child = header:GetAttribute("child" .. i)
            if child and child:IsVisible() then
                return child
            end
        end
    elseif frameName == "EQO Party Frames" then
        local frames = CollectEQOPartyUnitFrames(false)
        return frames[1]
    elseif frameName == "Grid2" then
        local frames = CollectGrid2PartyUnitFrames(false)
        return frames[1]
    elseif frameName == "Blizzard Party Frames" then
        for i = 1, 5 do
            local child = _G["CompactPartyFrameMember" .. i]
            if child and child:IsVisible() then
                return child
            end
        end
    end
    return nil
end

--- Get the width of the first visible party unit frame for auto-width mode.
--- @return number|nil Unit frame width
local function GetAttachFrameUnitWidth()
    local frame = GetFirstVisibleUnitFrame()
    if not frame then return nil end
    local width = frame:GetWidth()
    -- DandersFrames unit width includes the border, so subtract it
    if MODULE_DB.attachFrame == "DandersFrames" then
        local dfObj = _G.DandersFrames
        local dfDB = dfObj and dfObj.GetDB and dfObj:GetDB()
        if dfDB and dfDB.showFrameBorder then
            width = width - 2 * (dfDB.borderSize or 1)
        end
    end
    return width
end

--- Get the visually lowest visible party child frame for "Below" attachment.
--- oUF headers may sort children by role, so child indices do not always match screen order.
--- Compare actual screen positions instead.
--- @return Frame|nil Lowest visible child frame
local function GetLastVisiblePartyChild()
    local frameName = MODULE_DB.attachFrame
    local children = {}

    if frameName == "Blizzard Party Frames" then
        for i = 1, 5 do
            local child = _G["CompactPartyFrameMember" .. i]
            if child and child:IsVisible() then
                children[#children + 1] = child
            end
        end
    elseif frameName == "DandersFrames" then
        local header = _G["DandersPartyHeader"]
        if header then
            for i = 1, 5 do
                local child = header:GetAttribute("child" .. i)
                if child and child:IsVisible() then
                    children[#children + 1] = child
                end
            end
        end
    elseif frameName == "NDui" then
        local header = _G["oUF_Party"]
        if header then
            for i = 1, 5 do
                local child = header:GetAttribute("child" .. i)
                if child and child:IsVisible() then
                    children[#children + 1] = child
                end
            end
        end
    elseif frameName == "ElvUI" then
        local header = _G["ElvUF_PartyGroup1"]
        if header then
            for i = 1, 5 do
                local child = header:GetAttribute("child" .. i)
                if child and child:IsVisible() then
                    children[#children + 1] = child
                end
            end
        end
    elseif frameName == "EQO Party Frames" then
        children = CollectEQOPartyUnitFrames(false)
    elseif frameName == "Grid2" then
        children = CollectGrid2PartyUnitFrames(false)
    end

    if #children == 0 then return nil end
    if #children == 1 then return children[1] end

    -- Find the lowest child by screen Y position
    local bottomMost = children[1]
    local bottomMostY = select(2, bottomMost:GetCenter()) or 0
    for i = 2, #children do
        local cy = select(2, children[i]:GetCenter()) or 0
        if cy < bottomMostY then
            bottomMostY = cy
            bottomMost = children[i]
        end
    end
    return bottomMost
end

--- Hook party unit frame OnSizeChanged so auto-width reacts in real time.
--- Lazy-loaded and only active when attach mode + auto-width are enabled.
local function HookAttachFramesSizeChanged()
    local frameName = MODULE_DB.attachFrame
    if not frameName or frameName == "None" then return end

    -- Collect frames to hook
    local frameList = {}
    if frameName == "DandersFrames" then
        local api = GetDandersFramesApi()
        if api and api.GetFrameForUnit then
            local testUnits = { "player", "party1", "party2", "party3", "party4" }
            for _, unit in ipairs(testUnits) do
                local frame = api.GetFrameForUnit(unit, "party")
                if frame then table.insert(frameList, frame) end
            end
        end
    elseif frameName == "NDui" then
        local header = _G["oUF_Party"]
        if header then
            for i = 1, 5 do
                local child = header:GetAttribute("child" .. i)
                if child then table.insert(frameList, child) end
            end
        end
    elseif frameName == "ElvUI" then
        local header = _G["ElvUF_PartyGroup1"]
        if header then
            for i = 1, 5 do
                local child = header:GetAttribute("child" .. i)
                if child then table.insert(frameList, child) end
            end
        end
    elseif frameName == "EQO Party Frames" then
        frameList = CollectEQOPartyUnitFrames(true)
    elseif frameName == "Grid2" then
        frameList = CollectGrid2PartyUnitFrames(true)
    elseif frameName == "Blizzard Party Frames" then
        for i = 1, 5 do
            local child = _G["CompactPartyFrameMember" .. i]
            if child then table.insert(frameList, child) end
        end
    end

    -- Hook each frame's OnSizeChanged once
    for _, frame in ipairs(frameList) do
        if not hookedAttachFrames[frame] then
            hookedAttachFrames[frame] = true
            frame:HookScript("OnSizeChanged", function(self, w, h)
                if not IsAttachModeAvailable() or not MODULE_DB.attachAutoWidth then return end
                local roundedW = math.floor(w + 0.5)
                if lastAttachUnitWidth and lastAttachUnitWidth == roundedW then return end
                lastAttachUnitWidth = roundedW
                C_Timer.After(0, function()
                    if ReLayout then ReLayout() end
                end)
            end)
        end
    end
end

-- Create the anchor frame
CreateAnchor = function()
    if anchorFrame then return end
    anchorFrame = CreateFrame("Frame", "InfinityInterruptTrackerAnchor", UIParent)
    anchorFrame:SetSize(200, 20)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX, MODULE_DB.posY)
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(true)
    anchorFrame:RegisterForDrag("LeftButton")

    anchorFrame.bg = anchorFrame:CreateTexture(nil, "BACKGROUND")
    anchorFrame.bg:SetAllPoints()
    anchorFrame.bg:SetColorTexture(0, 0.5, 0, 0.5)

    anchorFrame.label = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFrame.label:SetPoint("CENTER")
    anchorFrame.label:SetText(L["Interrupt Tracker Anchor"])
    anchorFrame.bg:Hide()
    anchorFrame.label:Hide()

    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, anchorFrame)

    anchorFrame:SetScript("OnDragStart", function(self)
        if not MODULE_DB.locked then
            self:StartMoving()
        end
    end)

    anchorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = UIParent:GetCenter()
        local sx, sy = self:GetCenter()
        if sx and cx then
            MODULE_DB.posX = math.floor(sx - cx)
            MODULE_DB.posY = math.floor(sy - cy)

            -- Do not refresh the full options panel here; the grid engine syncs slider values automatically
        end
    end)
end

-- Initialize the bar frame structure
local function InitCastBarStructure(bar)
    bar:SetClampedToScreen(true)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bar.bg = bg

    bar.Text = bar:CreateFontString(nil, "OVERLAY")
    bar.TargetNameText = bar:CreateFontString(nil, "OVERLAY")
    bar.TimerText = bar:CreateFontString(nil, "OVERLAY")
    bar.Icon = bar:CreateTexture(nil, "OVERLAY")
end

-- Initialize the frame pool
if InfinityFactory then
    InfinityFactory:InitPool("InfinityInterruptBar", "StatusBar", "BackdropTemplate", InitCastBarStructure)
end

-- Acquire a bar
local function AcquireBar()
    if not InfinityFactory then return end
    local bar = InfinityFactory:Acquire("InfinityInterruptBar", anchorFrame)
    bar._isPreview = nil
    return bar
end

-- Release a bar
local function ReleaseBar(bar)
    if not InfinityFactory or not bar then return end
    bar:SetScript("OnUpdate", nil)
    InfinityFactory:Release("InfinityInterruptBar", bar)
end

-- Apply bar visuals
local function UpdateBarVisuals(bar)
    local db = MODULE_DB
    local group = db.timerGroup or {}

    -- Size
    bar:SetSize(group.width or 200, group.height or 20)

    -- Texture (fallback to Solid if LSM does not have the selected one)
    local tex = LSM:Fetch("statusbar", group.texture or "Melli")
    if not tex then tex = LSM:Fetch("statusbar", "Solid") or "Interface\\Buttons\\WHITE8X8" end
    if bar.bg then
        bar.bg:SetTexture(tex)
        bar.bg:SetVertexColor(
            group.barBgColorR or 0,
            group.barBgColorG or 0,
            group.barBgColorB or 0,
            group.barBgColorA or 0.5
        )
    end
    bar:SetStatusBarTexture(tex)

    -- Use the configured bar color unless class colors are enabled
    if not db.useClassColorBar then
        bar:SetStatusBarColor(
            group.barColorR or 0.2,
            group.barColorG or 0.8,
            group.barColorB or 0.2,
            group.barColorA or 1
        )
    else
        -- Class color (StatusBar)
        local class
        if bar._isPreview then
            class = bar._previewClass
        elseif bar.unit then
            _, class = UnitClass(bar.unit)
        end
        if class then
            local color = C_ClassColor.GetClassColor(class)
            if color then
                bar:SetStatusBarColor(color.r, color.g, color.b, 1)
            end
        end
    end

    -- Apply border styling above the status bar
    local edgeTex = group.showBorder and group.borderTexture and group.borderTexture ~= "None" and
        LSM:Fetch("border", group.borderTexture) or nil
    if edgeTex then
        if not bar.BorderFrame then
            bar.BorderFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            bar.BorderFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
        end
        local edgeSize = group.borderSize or 12
        local pad = group.borderPadding or 0
        bar.BorderFrame:ClearAllPoints()
        bar.BorderFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", -pad, pad)
        bar.BorderFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", pad, -pad)
        bar.BorderFrame:SetBackdrop({
            edgeFile = edgeTex,
            edgeSize = edgeSize,
        })
        local br, bg, bb, ba = group.borderColorR or 1, group.borderColorG or 1, group.borderColorB or 1,
            group.borderColorA or 1
        bar.BorderFrame:SetBackdropBorderColor(br, bg, bb, ba)
        bar.BorderFrame:Show()
    else
        if bar.BorderFrame then
            bar.BorderFrame:Hide()
        end
    end

    -- Apply font settings
    local StaticDB = InfinityTools.DB_Static

    -- Player name text
    if bar.Text then
        StaticDB:ApplyFont(bar.Text, db.font_name)
        bar.Text:ClearAllPoints()
        bar.Text:SetPoint(db.nameAlign, bar, db.nameAlign, db.font_name.x, db.font_name.y)
        bar.Text:SetJustifyH(db.nameAlign)
        bar.Text:SetShown(db.showPlayerName)

        -- Class color (text)
        if db.useClassColorName then
            local class
            if bar._isPreview then
                class = bar._previewClass
            elseif bar.unit then
                _, class = UnitClass(bar.unit)
            end
            if class then
                local color = C_ClassColor.GetClassColor(class)
                if color then
                    bar.Text:SetTextColor(color.r, color.g, color.b, 1)
                end
            end
        end
    end

    -- Cooldown text anchored to the right
    if bar.TimerText then
        StaticDB:ApplyFont(bar.TimerText, db.font_timer)
        bar.TimerText:ClearAllPoints()
        bar.TimerText:SetPoint("RIGHT", bar, "RIGHT", db.font_timer.x, db.font_timer.y)
        bar.TimerText:SetJustifyH("RIGHT")
        bar.TimerText:SetShown(db.showTimer)
    end

    -- Target name text is unused in this module
    if bar.TargetNameText then
        bar.TargetNameText:Hide()
    end

    -- Spell icon
    if bar.Icon then
        bar.Icon:SetSize(group.iconSize or 20, group.iconSize or 20)
        bar.Icon:ClearAllPoints()
        local side = group.iconSide or "LEFT"
        if side == "LEFT" then
            bar.Icon:SetPoint("RIGHT", bar, "LEFT", group.iconOffsetX or 0, group.iconOffsetY or 0)
        else
            bar.Icon:SetPoint("LEFT", bar, "RIGHT", group.iconOffsetX or 0, group.iconOffsetY or 0)
        end
        bar.Icon:SetShown(group.showIcon)
        bar.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-- Get role-based priority for a specialization
local function GetSpecPriority(unit)
    if not unit or not UnitExists(unit) then return 999 end

    local specID = GetUnitSpecID(unit)
    if not specID or specID == 0 then return 999 end

    local specData = SPEC_INTERRUPT_DB[specID]
    if not specData then return 999 end

    local role = specData.role or "DAMAGER"
    local db = MODULE_DB

    -- Base priority from role
    local basePriority =
        role == "TANK" and (db.sortPriorityTank or 1) or
        role == "HEALER" and (db.sortPriorityHealer or 2) or
        (db.sortPriorityDPS or 3)

    -- Optional melee DPS boost
    if role == "DAMAGER" and db.sortMeleeDPSFirst then
        -- Melee specialization IDs
        local meleeSpecs = {
            -- Warrior: Arms, Fury
            [71] = true,
            [72] = true,
            -- Paladin: Retribution
            [70] = true,
            -- Hunter: no melee spec here
            -- Rogue: all specs are melee
            [259] = true,
            [260] = true,
            [261] = true,
            -- Priest: no melee spec
            -- Shaman: Enhancement
            [263] = true,
            -- Mage: no melee spec
            -- Warlock: no melee spec
            -- Monk: Brewmaster, Windwalker
            [268] = true,
            [269] = true,
            -- Druid: Feral
            [103] = true,
            -- Demon Hunter: all specs are melee
            [577] = true,
            [581] = true,
            -- Death Knight: all specs are melee
            [250] = true,
            [251] = true,
            [252] = true,
        }

        if meleeSpecs[specID] then
            basePriority = basePriority - 0.5 -- Slightly boost melee priority
        end
    end

    return basePriority
end

-- Sort ready bars by role priority and cooling bars by remaining time
local function SortBars()
    if isPreviewing then return end

    -- Convert activeBars into a sortable list
    local sortList = {}
    for guid, data in pairs(activeBars) do
        table.insert(sortList, { guid = guid, data = data })
    end

    -- Sort rules
    table.sort(sortList, function(a, b)
        local aReady = (a.data.startTime == 0 or GetTime() - a.data.startTime >= a.data.cd)
        local bReady = (b.data.startTime == 0 or GetTime() - b.data.startTime >= b.data.cd)

        -- Ready bars go before cooling bars
        if aReady and not bReady then
            return true
        elseif not aReady and bReady then
            return false
        end

        -- If both are cooling down, shorter remaining time goes first
        if not aReady and not bReady then
            local aRemaining = a.data.cd - (GetTime() - a.data.startTime)
            local bRemaining = b.data.cd - (GetTime() - b.data.startTime)
            return aRemaining < bRemaining
        end

        -- If both are ready, sort by role priority
        if aReady and bReady then
            local aPriority = GetSpecPriority(a.data.unit)
            local bPriority = GetSpecPriority(b.data.unit)

            if aPriority ~= bPriority then
                return aPriority < bPriority -- Lower numeric priority goes first
            end
        end

        -- Stable fallback by GUID
        return a.guid < b.guid
    end)

    -- Rebuild usedBarsList
    wipe(usedBarsList)
    for _, item in ipairs(sortList) do
        table.insert(usedBarsList, item.data.bar)
    end
end

-- Re-layout all bars. Bars always stack on anchorFrame; attach mode only moves the anchor.
ReLayout = function()
    if not anchorFrame then return end

    -- Sort first
    if not isPreviewing then
        SortBars()
    end

    local group = MODULE_DB.timerGroup or {}
    local height = group.height or 20
    local spacing = MODULE_DB.spacing or 2
    local list = isPreviewing and previewBars or usedBarsList
    local growUp = (MODULE_DB.growDirection == "Up")
    local maxLimit = MODULE_DB.maxBars or 5
    local barWidth = group.width or 200
    local totalHeight = height

    local attachMode = IsAttachModeAvailable()
    local iconCenterShift = 0 -- Horizontal center compensation for icon width in attach mode

    -- Auto-width in attach mode: match the party unit frame width.
    -- Target: icon + bar width = unit frame width, centered as a group.
    if attachMode and MODULE_DB.attachAutoWidth then
        local unitWidth = GetAttachFrameUnitWidth()
        if unitWidth then
            if group.showIcon then
                local iconSize = group.iconSize or 20
                local iconOffX = group.iconOffsetX or 0
                local side = group.iconSide or "LEFT"
                -- Icon occupied width = icon size + spacing to the bar
                -- LEFT: Icon.RIGHT = bar.LEFT + iconOffsetX => occupied = iconSize - iconOffsetX
                -- RIGHT: Icon.LEFT = bar.RIGHT + iconOffsetX => occupied = iconSize + iconOffsetX
                local iconOccupied
                if side == "LEFT" then
                    iconOccupied = iconSize - iconOffX
                else
                    iconOccupied = iconSize + iconOffX
                end
                if iconOccupied < 0 then iconOccupied = 0 end

                barWidth = unitWidth - iconOccupied
                if barWidth < 20 then barWidth = 20 end -- Minimum width guard

                -- Compute the anchor shift needed to center icon+bar as one visual group
                -- LEFT icon shifts the visual center right, so move the anchor right
                -- RIGHT icon shifts it left, so move the anchor left
                if side == "LEFT" then
                    iconCenterShift = iconOccupied / 2
                else
                    iconCenterShift = -iconOccupied / 2
                end
            else
                barWidth = unitWidth
            end
        end
        -- Hook size changes lazily so width updates in real time
        HookAttachFramesSizeChanged()
    end

    -- Anchor frame keeps one-bar height and acts only as a positioning reference
    anchorFrame:SetSize(barWidth, height)

    -- Shared bar stacking logic for standalone and attach modes
    local visibleCount = 0
    for i, bar in ipairs(list) do
        if i <= maxLimit then
            visibleCount = visibleCount + 1
            bar:SetParent(anchorFrame)
            bar:Show()
            bar:EnableMouse(false)
            bar:ClearAllPoints()

            -- Override bar width in attach auto-width mode
            if attachMode and MODULE_DB.attachAutoWidth then
                bar:SetWidth(barWidth)
            end

            if growUp then
                -- Grow up: bar 1 starts at anchor BOTTOM
                bar:SetPoint("BOTTOM", anchorFrame, "BOTTOM", 0, (i - 1) * (height + spacing))
            else
                -- Grow down: bar 1 starts at anchor TOP
                bar:SetPoint("TOP", anchorFrame, "TOP", 0, -(i - 1) * (height + spacing))
            end
        else
            bar:Hide()
        end
    end

    totalHeight = math.max(height, visibleCount > 0 and (visibleCount * height + (visibleCount - 1) * spacing) or height)

    if not attachMode and anchorFrame.bg then
        anchorFrame.bg:ClearAllPoints()
        anchorFrame.bg:SetSize(barWidth, totalHeight)
        anchorFrame.label:ClearAllPoints()
        anchorFrame.label:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)

        if growUp then
            anchorFrame.bg:SetPoint("BOTTOM", anchorFrame, "BOTTOM")
            anchorFrame:SetHitRectInsets(0, 0, -(totalHeight - height), 0)
        else
            anchorFrame.bg:SetPoint("TOP", anchorFrame, "TOP")
            anchorFrame:SetHitRectInsets(0, 0, 0, -(totalHeight - height))
        end
    else
        anchorFrame:SetHitRectInsets(0, 0, 0, 0)
    end

    -- Attach mode: anchor to the selected party frame
    if attachMode then
        local attachAbove = (MODULE_DB.attachPoint ~= "Below")
        local offsetX = (MODULE_DB.attachOffsetX or 0) + iconCenterShift
        local offsetY = MODULE_DB.attachOffsetY or 2

        -- Compute total stack height for offset math
        local totalExtent = visibleCount > 0
            and (visibleCount * height + (visibleCount - 1) * spacing)
            or height

        if attachAbove then
            -- Attach above: bottom of the stack touches the target top
            local target = GetAttachTargetFrame()
            if target then
                anchorFrame:ClearAllPoints()
                if growUp then
                    -- Grow up: bar 1 is at BOTTOM, direct anchor
                    anchorFrame:SetPoint("BOTTOM", target, "TOP", offsetX, offsetY)
                else
                    -- Grow down: bar 1 is at TOP, offset the whole stack upward
                    -- barN.BOTTOM = anchor.TOP - totalExtent
                    -- Need barN.BOTTOM = target.TOP + offsetY
                    -- → anchor.BOTTOM = target.TOP + offsetY + totalExtent - height
                    anchorFrame:SetPoint("BOTTOM", target, "TOP", offsetX, offsetY + totalExtent - height)
                end
                anchorFrame:Show()
                anchorFrame:EnableMouse(false)
                anchorFrame.bg:Hide()
                anchorFrame.label:Hide()
            end
        else
            -- Attach below: top of the stack touches the target bottom
            local lastChild = GetLastVisiblePartyChild()
            local target = lastChild or GetAttachTargetFrame()
            if target then
                local anchorPoint = lastChild and "BOTTOM" or "TOP"
                anchorFrame:ClearAllPoints()
                if growUp then
                    -- Grow up: barN is at the top, shift the whole stack down by total height
                    -- offsetY is positive upward, so keep a positive sign here
                    anchorFrame:SetPoint("TOP", target, anchorPoint, offsetX, offsetY - totalExtent + height)
                else
                    -- Grow down: bar 1 is at TOP, direct anchor
                    -- offsetY is positive upward, so keep a positive sign here
                    anchorFrame:SetPoint("TOP", target, anchorPoint, offsetX, offsetY)
                end
                anchorFrame:Show()
                anchorFrame:EnableMouse(false)
                anchorFrame.bg:Hide()
                anchorFrame.label:Hide()
            end
        end
    end
end

-- Refresh all bars
RefreshAll = function()
    if isPreviewing then
        TogglePreview(false)
        TogglePreview(true)
    else
        for guid, data in pairs(activeBars) do
            if data.bar then
                UpdateBarVisuals(data.bar)
            end
        end
    end
    ReLayout()

    -- In standalone mode, keep anchor state here; in attach mode, ReLayout manages anchor placement
    if not IsAttachModeAvailable() and anchorFrame then
        anchorFrame:ClearAllPoints()
        anchorFrame:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX or 0, MODULE_DB.posY or 0)

        if MODULE_DB.locked then
            anchorFrame:EnableMouse(false)
            anchorFrame.bg:Hide()
            anchorFrame.label:Hide()
        else
            anchorFrame:EnableMouse(true)
            anchorFrame.bg:Show()
            anchorFrame.label:Show()
        end
    end
end

-- Preview mode with 3 ready bars and 2 cooling bars across 5 classes
TogglePreview = function(enable)
    isPreviewing = enable

    if enable then
        -- Create the anchor in preview mode regardless of environment
        if not anchorFrame then
            CreateAnchor()
        end

        -- Enable dragging in preview mode for standalone mode only
        if not IsAttachModeAvailable() and anchorFrame then
            anchorFrame:Show()
            anchorFrame:EnableMouse(true)
            anchorFrame.bg:Show()
            anchorFrame.label:Show()
        end

        -- Hide and clear real bars
        for guid, data in pairs(activeBars) do
            if data.bar then
                data.bar:Hide()
            end
        end
        wipe(activeBars)
        wipe(usedBarsList)
        wipe(previewBars)

        -- Player class
        local playerName = UnitName("player")
        local _, playerClass = UnitClass("player")
        local playerColor = C_ClassColor.GetClassColor(playerClass)

        -- Four preset classes for the other preview bars
        local previewClasses = {
            { name = "Warrior", class = "WARRIOR" },
            { name = "Mage", class = "MAGE" },
            { name = "Hunter", class = "HUNTER" },
            { name = "Paladin", class = "PALADIN" },
        }

        -- Create 5 preview bars
        for i = 1, 5 do
            local bar = AcquireBar()
            bar._isPreview = true
            UpdateBarVisuals(bar)

            -- Mock spell icons
            local previewSpells = { 1766, 2139, 106839, 183752, 187707 }
            local spellInfo = C_Spell.GetSpellInfo(previewSpells[i] or 1766)
            if spellInfo then
                bar.Icon:SetTexture(spellInfo.iconID)
            else
                bar.Icon:SetTexture(136197)
            end

            -- Player name and class color
            if bar.Text and MODULE_DB.showPlayerName then
                local displayName, classColor
                if i == 1 then
                    -- First bar uses the real player
                    displayName = playerName
                    classColor = playerColor
                else
                    -- Other bars use preset classes
                    local classData = previewClasses[i - 1]
                    displayName = classData.name
                    classColor = C_ClassColor.GetClassColor(classData.class)
                end

                bar._previewClass = (i == 1) and playerClass or previewClasses[i - 1].class
                bar.Text:SetText(displayName)
                bar.Text:Show()
            end

            -- Re-apply visuals after setting preview class metadata
            UpdateBarVisuals(bar)

            -- First 3 bars are ready, last 2 are cooling down
            if i <= 3 then
                -- Ready state
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(1)
                if bar.TimerText and MODULE_DB.showTimer then
                    if MODULE_DB.showReadyText then
                        bar.TimerText:SetText(MODULE_DB.readyText or "Ready")
                    else
                        bar.TimerText:SetText("")
                    end
                end
            else
                -- Cooling state
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(0)

                local cdTime = (i == 4) and 15 or 8
                local startTime = GetTime()

                -- Animate cooldown progress
                bar:SetScript("OnUpdate", function(self)
                    local elapsed = GetTime() - startTime
                    local remaining = cdTime - elapsed

                    if remaining > 0 then
                        self:SetValue(elapsed / cdTime)

                        if self.TimerText and MODULE_DB.showTimer then
                            -- Adjust display precision by remaining time
                            local displayVal
                            if remaining > 6 then
                                -- >6s: integer seconds
                                displayVal = math.floor(remaining)
                                if displayVal ~= self._lastDisplayed then
                                    self._lastDisplayed = displayVal
                                    self.TimerText:SetText(string.format("%d", displayVal))
                                end
                            else
                                -- <=6s: one decimal
                                displayVal = math.floor(remaining * 10)
                                if displayVal ~= self._lastDisplayed then
                                    self._lastDisplayed = displayVal
                                    self.TimerText:SetText(string.format("%.1f", remaining))
                                end
                            end
                        end
                    else
                        self:SetValue(1)
                        if self.TimerText and MODULE_DB.showTimer then
                            if MODULE_DB.showReadyText then
                                self.TimerText:SetText(MODULE_DB.readyText or "Ready")
                            else
                                self.TimerText:SetText("")
                            end
                        end
                        self._lastDisplayed = nil
                        self:SetScript("OnUpdate", nil)
                    end
                end)
            end

            table.insert(previewBars, bar)
        end
    else
        -- Exit preview
        for _, bar in ipairs(previewBars) do
            bar:Hide()
            bar:SetScript("OnUpdate", nil)
            ReleaseBar(bar)
        end
        wipe(previewBars)

        -- Restore lock state when leaving preview
        if anchorFrame then
            if MODULE_DB.locked then
                anchorFrame:EnableMouse(false)
                anchorFrame.bg:Hide()
                anchorFrame.label:Hide()
            else
                anchorFrame:EnableMouse(true)
                anchorFrame.bg:Show()
            end
        end
        -- Refresh real data immediately after preview so bars reappear after leaving edit mode
        UpdateLayout()
    end

    ReLayout()
end

-- Update interrupt bar layout incrementally while preserving cooldown state
UpdateLayout = function()
    -- Only active in a party inside 5-player instances
    if not CheckEnvironment() then
        return
    end

    -- Auto-detect a party frame addon on first use
    AutoDetectAttachFrame()

    if not MODULE_DB.enabled then
        if anchorFrame then
            anchorFrame:Hide()
        end
        return
    end

    if not anchorFrame then
        CreateAnchor()
    end

    -- Hide anchor in attach mode, show it in standalone mode
    if IsAttachModeAvailable() then
        anchorFrame:Hide()
    else
        anchorFrame:Show()
    end

    -- In preview mode, keep running layout logic
    if isPreviewing then
        ReLayout()
        return
    end

    -- Incremental update: only process changes

    local currentGuids = {}
    local units = { "player" }
    for i = 1, 4 do
        table.insert(units, "party" .. i)
    end

    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then
                currentGuids[guid] = unit
            end
        end
    end

    -- Remove bars for players who left
    for guid, data in pairs(activeBars) do
        if not currentGuids[guid] then
            -- Player left the party
            if data.bar then
                ReleaseBar(data.bar)
            end
            activeBars[guid] = nil
        end
    end

    -- Add bars for new players
    for guid, unit in pairs(currentGuids) do
        if not activeBars[guid] then
            -- New player, create a bar
            local spellData = GetUnitInterruptSpellData(unit)

            if spellData and spellData.id and spellData.id > 0 then
                local bar = AcquireBar()
                UpdateBarVisuals(bar)

                -- Spell icon
                local spellInfo = C_Spell.GetSpellInfo(spellData.id)
                if spellInfo then
                    bar.Icon:SetTexture(spellInfo.iconID)
                else
                    bar.Icon:SetTexture(134400)
                end

                -- Player name
                if bar.Text and MODULE_DB.showPlayerName then
                    bar.Text:SetText(UnitName(unit))
                    bar.Text:Show()
                end

                -- Re-apply visuals after assigning bar.unit
                bar.unit = unit
                UpdateBarVisuals(bar)

                -- Ready state
                bar:SetMinMaxValues(0, 1)
                bar:SetValue(1)
                if bar.TimerText and MODULE_DB.showTimer then
                    if MODULE_DB.showReadyText then
                        bar.TimerText:SetText(MODULE_DB.readyText or "Ready")
                    else
                        bar.TimerText:SetText("")
                    end
                end

                activeBars[guid] = {
                    bar = bar,
                    spellID = spellData.id,
                    cd = spellData.cd,
                    startTime = 0,
                    unit = unit
                }
            end
        end
    end

    ReLayout()
    RefreshAll()
end

-- =============================================================
-- Core interrupt detection logic
-- =============================================================

local pendingEvents = {
    interrupts = {}, -- { [targetUnit] = { time, interruptedBy } }
    casts = {},      -- { [casterUnit] = { time, spellID } }
}
local processingScheduled = false
local TIME_WINDOW = 0.050 -- 50 ms window for latency and cross-realm event jitter

-- =============================================================
-- Mythic+ interrupt statistics
-- =============================================================
local interruptStats = {} -- { [guid] = count }
local isInMythicPlus = false
local C_DamageMeter = _G.C_DamageMeter
local UnitNameFromGUID = _G.UnitNameFromGUID
local IsInGroup = _G.IsInGroup
local GetNumSubgroupMembers = _G.GetNumSubgroupMembers

-- Reset interrupt statistics
local function ResetInterruptStats()
    wipe(interruptStats)
end

-- Record one interrupt
local function RecordInterrupt(guid)
    if not isInMythicPlus then return end
    if not guid then return end

    interruptStats[guid] = (interruptStats[guid] or 0) + 1
end

-- Print module-side interrupt statistics
local function PrintCustomInterruptStats()
    if not next(interruptStats) then
        return
    end

    -- Sort by count descending
    local sortedStats = {}
    for guid, count in pairs(interruptStats) do
        table.insert(sortedStats, { guid = guid, count = count })
    end

    table.sort(sortedStats, function(a, b) return a.count > b.count end)

    -- Print results
    for _, data in ipairs(sortedStats) do
        local nameEX, serverEX = UnitNameFromGUID(data.guid)
        if nameEX then
            if serverEX and serverEX ~= "" then
                print(string.format("|cffffffff%s-%s|r: |cff00ff00%d|r", nameEX, serverEX, data.count))
            else
                print(string.format("|cffffffff%s|r: |cff00ff00%d|r", nameEX, data.count))
            end
        else
            print(string.format("|cffaaaaaa%s|r: |cff00ff00%d|r", data.guid, data.count))
        end
    end
end

-- Print Blizzard's built-in interrupt statistics
local function PrintBlizzardInterruptStats()
    local sessionTypeEX = 0 -- Overall
    local meterTypeEX = 5   -- Interrupts

    if not C_DamageMeter then
        print("|cffff0000[Built-in Stats]|r C_DamageMeter unavailable")
        return
    end

    local totalBySourceEX = {}

    local unitsEX = { "player" }
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            table.insert(unitsEX, "raid" .. i)
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            table.insert(unitsEX, "party" .. i)
        end
    end

    for _, unitEX in ipairs(unitsEX) do
        local guidEX = UnitGUID(unitEX)
        if guidEX then
            local sessionSourceEX = C_DamageMeter.GetCombatSessionSourceFromType(sessionTypeEX, meterTypeEX, guidEX)

            if sessionSourceEX and sessionSourceEX.combatSpells then
                local totalEX = 0

                for _, spellEX in ipairs(sessionSourceEX.combatSpells) do
                    totalEX = totalEX + (spellEX.totalAmount or 0)
                end

                totalBySourceEX[guidEX] = totalEX
            end
        end
    end

    print("|cff00ffff===== Built-in Stats: Interrupt Count =====|r")

    if not next(totalBySourceEX) then
        print("|cffaaaaaa(No data)|r")
        return
    end

    -- Sort by count descending
    local sortedStats = {}
    for guid, count in pairs(totalBySourceEX) do
        table.insert(sortedStats, { guid = guid, count = count })
    end

    table.sort(sortedStats, function(a, b) return a.count > b.count end)

    for _, data in ipairs(sortedStats) do
        local nameEX, serverEX = UnitNameFromGUID(data.guid)
        if nameEX then
            if serverEX and serverEX ~= "" then
                print(string.format("|cffffffff%s-%s|r: |cff00ff00%d|r", nameEX, serverEX, data.count))
            else
                print(string.format("|cffffffff%s|r: |cff00ff00%d|r", nameEX, data.count))
            end
        else
            print(string.format("|cffaaaaaa%s|r: |cff00ff00%d|r", data.guid, data.count))
        end
    end
end

-- Print the full interrupt report
local function PrintInterruptReport()
    print(" ")
    print("|cffff00ff================================================|r")
    print("|cffff00ff          Interrupt Report                     |r")
    print("|cffff00ff================================================|r")
    print(" ")

    -- Module-side stats
    PrintCustomInterruptStats()
    print(" ")

    -- Built-in stats
    PrintBlizzardInterruptStats()
    print(" ")
    print("|cffff00ff================================================|r")
end

-- Trigger cooldown
local function TriggerCooldown(unit)
    local guid = UnitGUID(unit)
    if not guid or not activeBars[guid] then return end

    local data = activeBars[guid]
    local bar = data.bar
    local cdDuration = data.cd

    -- Record interrupt count
    RecordInterrupt(guid)

    -- Start cooldown animation
    data.startTime = GetTime()
    bar:SetValue(0)

    -- Re-sort immediately
    ReLayout()

    bar:SetScript("OnUpdate", function(self)
        local elapsed = GetTime() - data.startTime
        local remaining = cdDuration - elapsed

        if remaining > 0 then
            self:SetValue(elapsed / cdDuration)

            if self.TimerText and MODULE_DB.showTimer then
                -- Adjust display precision by remaining time
                local displayVal
                if remaining > 6 then
                    -- >6s: integer seconds
                    displayVal = math.floor(remaining)
                    if displayVal ~= self._lastDisplayed then
                        self._lastDisplayed = displayVal
                        self.TimerText:SetText(string.format("%d", displayVal))
                    end
                else
                    -- <=6s: one decimal
                    displayVal = math.floor(remaining * 10)
                    if displayVal ~= self._lastDisplayed then
                        self._lastDisplayed = displayVal
                        self.TimerText:SetText(string.format("%.1f", remaining))
                    end
                end
            end

            -- Re-sort once per second while cooling down
            local lastUpdate = self._lastSortUpdate or 0
            if elapsed - lastUpdate >= 1.0 then
                self._lastSortUpdate = elapsed
                ReLayout()
            end
        else
            self:SetValue(1)
            if self.TimerText and MODULE_DB.showTimer then
                if MODULE_DB.showReadyText then
                    self.TimerText:SetText(MODULE_DB.readyText or "Ready")
                else
                    self.TimerText:SetText("")
                end
            end
            self._lastDisplayed = nil
            self:SetScript("OnUpdate", nil)

            -- Cooldown ended, re-sort
            ReLayout()
        end
    end)
end

local function ResolveCasterByInterruptSource(targetUnit)
    local interruptData = pendingEvents.interrupts[targetUnit]
    if not interruptData then
        return nil, math.huge
    end

    local interruptTime = interruptData.time
    local interruptedBy = interruptData.interruptedBy
    if not interruptedBy then
        return nil, math.huge
    end

    -- On 12.0+, interruptedBy / UnitNameFromGUID may return secret values.
    -- Only use this to confirm that a resolvable interrupter exists; do not compare names.
    local ok, interruptName = pcall(UnitNameFromGUID, interruptedBy)
    if not ok or not interruptName then
        return nil, math.huge
    end

    local bestMatch = nil
    local bestTimeDiff = math.huge

    for unit, data in pairs(pendingEvents.casts) do
        local timeDiff = math.abs(interruptTime - data.time)
        if timeDiff <= TIME_WINDOW and timeDiff < bestTimeDiff then
            bestMatch = unit
            bestTimeDiff = timeDiff
        end
    end

    return bestMatch, bestTimeDiff
end

-- Process aggregated events
local function ProcessPendingEvents()
    processingScheduled = false

    -- Optional debug logs
    local debugEnabled = _G.ExIT_Debug or false

    -- Check 1: there must be exactly one interrupt event (multiple often means AoE CC)
    local interruptCount = 0
    local targetUnit = nil
    for unit, _ in pairs(pendingEvents.interrupts) do
        interruptCount = interruptCount + 1
        targetUnit = unit
    end

    if interruptCount == 0 then
        -- No interrupt events
        wipe(pendingEvents.interrupts)
        wipe(pendingEvents.casts)
        return
    end

    -- Debug output only when an interrupt happened
    if debugEnabled then
        print("========================================")

        -- Print all cast events
        for unit, data in pairs(pendingEvents.casts) do
            print(string.format("[Player Cast] %s (%.6f)", unit, data.time))
        end

        -- Print the interrupt event
        local interruptTime = pendingEvents.interrupts[targetUnit].time
        print(string.format("|cffff0000[Spell Interrupted]|r %s (%.6f)", targetUnit, interruptTime))
    end

    if interruptCount > 1 then
        -- Multiple interrupted nameplates usually means AoE CC, ignore all events
        if debugEnabled then
            print("|cffff8800Result: Crowd Control|r")
        end
        wipe(pendingEvents.interrupts)
        wipe(pendingEvents.casts)
        return
    end

    -- interruptCount == 1 here
    local interruptTime = pendingEvents.interrupts[targetUnit].time

    -- Check 3: confirm interruptedBy resolves, then match the closest recent cast event.
    local caster, bestTimeDiff = ResolveCasterByInterruptSource(targetUnit)

    -- Legacy fallback kept for reference: pure timing-based matching (unused)
    --[[
    local bestMatch = nil
    local bestLegacyTimeDiff = math.huge

    for unit, data in pairs(pendingEvents.casts) do
        local timeDiff = math.abs(interruptTime - data.time)
        if timeDiff <= TIME_WINDOW and timeDiff < bestLegacyTimeDiff then
            bestMatch = unit
            bestLegacyTimeDiff = timeDiff
        end
    end

    caster = bestMatch
    bestTimeDiff = bestLegacyTimeDiff
    ]]

    if caster then
        -- Matched a caster, trigger cooldown
        if debugEnabled then
            -- print(string.format("|cff00ff00Result: Interrupt Matched|r time delta: %.2fms", bestTimeDiff * 1000))
        end
        TriggerCooldown(caster)
    else
        -- No caster matched
        if debugEnabled then
            -- print("|cffff0000Result: Failed (no matching cast found)|r")
        end
    end

    -- Clear event caches
    wipe(pendingEvents.interrupts)
    wipe(pendingEvents.casts)
end

-- Schedule processing after a short delay so delayed network events can arrive
local function ScheduleProcessing()
    if processingScheduled then return end
    processingScheduled = true


    C_Timer.After(0.03, ProcessPendingEvents)
end

-- Record successful casts.
-- Player: compare spellID directly and trigger cooldown immediately.
-- Party members: still use timing-based matching because their cast events may be incomplete/secret-wrapped.
InfinityTools:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", INFINITY_MODULE_KEY, function(_, unit, _, spellID)
    if not MODULE_DB.enabled or isPreviewing or not isValidEnvironment then return end
    if not (unit == "player" or string.find(unit, "party")) then return end

    if unit == "player" then
        local spellData = GetUnitInterruptSpellData("player")
        if spellData and spellData.id and spellID == spellData.id then
            TriggerCooldown("player")
        end
        return
    end

    local arriveTime = GetTime()
    pendingEvents.casts[unit] = { time = arriveTime }
    ScheduleProcessing()
end)

-- Record an interrupt event
InfinityTools:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", INFINITY_MODULE_KEY, function(_, unit, castGUID, spellID, interruptedBy, castBarID)
    if not MODULE_DB.enabled or isPreviewing or not isValidEnvironment then return end
    if not string.find(unit, "nameplate") then return end

    local arriveTime = GetTime()
    pendingEvents.interrupts[unit] = {
        time = arriveTime,
        interruptedBy = interruptedBy,
    }
    ScheduleProcessing()
end)

-- =============================================================
-- Event handling
-- =============================================================
InfinityTools:RegisterEvent("INFINITY_PARTY_SPEC_UPDATED", INFINITY_MODULE_KEY, function()
    if not isPreviewing then
        UpdateLayout()
    end
end)

InfinityTools:RegisterEvent("GROUP_ROSTER_UPDATE", INFINITY_MODULE_KEY, function()
    if not isPreviewing then
        UpdateLayout()
    end
end)

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    MODULE_DB.preview = false
    C_Timer.After(1, function()
        CreateAnchor()
        UpdateLayout()
    end)
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "preview" then
        TogglePreview(MODULE_DB.preview)
    elseif info.key == "enabled" then
        if MODULE_DB.enabled then
            CreateAnchor()
            UpdateLayout()
        else
            if anchorFrame then
                anchorFrame:Hide()
            end
        end
    elseif info.key == "attachToRaidFrame" or info.key == "attachFrame" or info.key == "attachPoint"
        or info.key == "attachAutoWidth" then
        -- Mark attach frame as user-selected so auto-detection does not override it
        if info.key == "attachFrame" then
            MODULE_DB._attachFrameSetByUser = true
        end
        -- Rebuild all bars when attach mode changes
        for guid, data in pairs(activeBars) do
            if data.bar then
                data.bar:SetParent(anchorFrame or UIParent)
                ReleaseBar(data.bar)
            end
        end
        wipe(activeBars)
        wipe(usedBarsList)
        if isPreviewing then
            TogglePreview(false)
            TogglePreview(true)
        else
            UpdateLayout()
        end
    else
        if isPreviewing then
            TogglePreview(false)
            TogglePreview(true)
        else
            RefreshAll()
        end
    end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if info.key == "btn_reset_pos" then
        MODULE_DB.posX = 0
        MODULE_DB.posY = -200
        if anchorFrame then
            anchorFrame:ClearAllPoints()
            anchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        end
        RefreshAll()
    end
end)

-- =============================================================
-- Global edit mode support
-- =============================================================
-- Register the global edit mode callback
InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    if enabled then
        -- Enable edit mode: unlock position + preview
        MODULE_DB.locked = false
        MODULE_DB.preview = true
        TogglePreview(true)
        RefreshAll()
    else
        -- Disable edit mode: lock position + close preview
        MODULE_DB.locked = true
        MODULE_DB.preview = false
        TogglePreview(false)
        RefreshAll()
    end
end)

-- =============================================================
-- Mythic+ event listeners
-- =============================================================

-- Mythic+ started
InfinityTools:RegisterEvent("CHALLENGE_MODE_START", INFINITY_MODULE_KEY, function()
    isInMythicPlus = true
    ResetInterruptStats()
end)

-- Mythic+ completed
InfinityTools:RegisterEvent("CHALLENGE_MODE_COMPLETED", INFINITY_MODULE_KEY, function()
    if isInMythicPlus then
        -- print("|cff00ff00[Interrupt Stats]|r Mythic+ completed, data saved")
    end
end)

-- Mythic+ reset
InfinityTools:RegisterEvent("CHALLENGE_MODE_RESET", INFINITY_MODULE_KEY, function()
    if isInMythicPlus then
        -- print("|cffff8800[Interrupt Stats]|r Mythic+ reset")
    end
    isInMythicPlus = false
end)

-- Entering world (also fires on reload)
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY .. "_EnterWorld", function()
    -- Check whether we are currently in Mythic+
    local _, instanceType = GetInstanceInfo()
    local isMythicPlusInstance = (instanceType == "party" and C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo())

    -- Only update the stats state flag here
    if isMythicPlusInstance then
        isInMythicPlus = true
    else
        isInMythicPlus = false
    end

    -- Re-check environment and update UI
    CheckEnvironment()
end)

-- =============================================================
-- State watchers: auto-enable/disable when environment changes
-- =============================================================
-- Party state changed
InfinityTools:WatchState("IsInParty", INFINITY_MODULE_KEY .. "_PartyWatch", function()
    CheckEnvironment()
end)

-- Instance type changed
InfinityTools:WatchState("InstanceType", INFINITY_MODULE_KEY .. "_InstanceWatch", function()
    CheckEnvironment()
end)

-- =============================================================
-- Slash command registration
-- =============================================================

-- Register /extest
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

