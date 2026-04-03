-- [[ Raid Marker Panel ]]
-- { Key = "RevTools.RaidMarkerPanel", Name = "Raid Marker Panel", Desc = "Unified panel for raid target markers and world markers.", Category = 1 },
local ondev = false
if ondev then
    return
end


local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end

local INFINITY_MODULE_KEY = "RevTools.RaidMarkerPanel"

-- =============================================================
-- Part 1: Grid layout registration (must run first)
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 50, h = 2, label = "Raid Marker Panel", labelSize = 24 },
        { key = "desc", type = "description", x = 2, y = 4, w = 50, h = 2, label = "Left-click to place or toggle, right-click to clear one marker. Supports target markers and world markers. Command: /exmarker" },
        { key = "showPanel", type = "checkbox", x = 2, y = 7, w = 14, h = 2, label = "Show Panel" },
        { key = "lockPanel", type = "checkbox", x = 17, y = 7, w = 14, h = 2, label = "Lock Position" },
        { key = "scale", type = "slider", x = 2, y = 10, w = 18, h = 2, label = "Panel Scale", min = 0.6, max = 1.8, step = 0.05 },
        { key = "btn_toggle", type = "button", x = 22, y = 10, w = 12, h = 2, label = "Toggle Display" },
        { key = "btn_reset_pos", type = "button", x = 35, y = 10, w = 12, h = 2, label = "Reset Position" },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end

REGISTER_LAYOUT()

-- If the module is disabled, keep only the config entry
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =============================================================
-- Part 2: Database and constants
-- =============================================================
local MODULE_DEFAULTS = {
    showPanel = true,
    lockPanel = false,
    scale = 1,
    posX = 0,
    posY = 0,
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

local PANEL_WIDTH = 340
local PANEL_HEIGHT = 214
local BTN_SIZE = 28
local BTN_GAP = 4

local Panel = nil
local PendingShowState = nil
local UnitButtons = {}
local WorldButtons = {}
local UnitClearBtn = nil
local UnitClearAllBtn = nil
local WorldClearAllBtn = nil

local RAID_ICON_COORDS = {
    [1] = { 0.00, 0.25, 0.00, 0.25 },
    [2] = { 0.25, 0.50, 0.00, 0.25 },
    [3] = { 0.50, 0.75, 0.00, 0.25 },
    [4] = { 0.75, 1.00, 0.00, 0.25 },
    [5] = { 0.00, 0.25, 0.25, 0.50 },
    [6] = { 0.25, 0.50, 0.25, 0.50 },
    [7] = { 0.50, 0.75, 0.25, 0.50 },
    [8] = { 0.75, 1.00, 0.25, 0.50 },
}

-- =============================================================
-- Part 3: Shared helpers
-- =============================================================
local function SetRaidIcon(texture, index)
    if not texture then return end

    -- Some environments do not render SetRaidTargetIconTexture reliably on custom textures.
    -- Force the classic atlas path for stable marker icons.
    texture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    local coord = RAID_ICON_COORDS[index] or RAID_ICON_COORDS[1]
    texture:SetTexCoord(coord[1], coord[2], coord[3], coord[4])
end

local function SavePanelPosition()
    if not Panel then return end

    local cx, cy = Panel:GetCenter()
    local sw, sh = UIParent:GetSize()
    if not cx or not cy or not sw or not sh then return end

    MODULE_DB.posX = cx - (sw / 2)
    MODULE_DB.posY = cy - (sh / 2)
end

local function ApplyPanelPosition()
    if not Panel then return end
    Panel:ClearAllPoints()
    Panel:SetPoint("CENTER", UIParent, "CENTER", MODULE_DB.posX or 0, MODULE_DB.posY or 0)
end

local function ApplyPanelScale()
    if not Panel then return end
    local s = tonumber(MODULE_DB.scale) or 1
    if s < 0.6 then s = 0.6 end
    if s > 1.8 then s = 1.8 end
    MODULE_DB.scale = s
    Panel:SetScale(s)
end

local function CanPlayerMark()
    if IsInRaid() then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end

    -- Match Blizzard behavior: allow operations outside raid contexts by default
    return true
end

local function GetRestrictionReason()
    local restrictedAPI = _G.C_RestrictedActions
    local restrictType = _G.Enum and _G.Enum.AddOnRestrictionType
    if not restrictedAPI or not restrictedAPI.IsRestrictionActive or not restrictType then
        return nil
    end

    -- [12.0] Prefer showing restriction types that directly affect addon behavior
    if restrictedAPI.IsRestrictionActive(restrictType.Encounter) then
        return "Restricted during boss encounters"
    end
    if restrictedAPI.IsRestrictionActive(restrictType.ChallengeMode) then
        return "Restricted in Mythic+"
    end
    if restrictedAPI.IsRestrictionActive(restrictType.PvPMatch) then
        return "Restricted in PvP matches"
    end
    if restrictedAPI.IsRestrictionActive(restrictType.Map) then
        return "Restricted on this instance map"
    end
    if restrictedAPI.IsRestrictionActive(restrictType.Combat) then
        return "Restricted in combat"
    end
    return nil
end

local function SetButtonState(btn, isEnabled, isActive)
    if not btn then return end


    if btn.inputBlocker then
        btn.inputBlocker:SetShown(not isEnabled)
    end
    if not btn.bg then return end

    if not isEnabled then
        btn.bg:SetColorTexture(0.10, 0.10, 0.10, 0.95)
    else
        btn.bg:SetColorTexture(0.16, 0.16, 0.16, 0.95)
    end

    if btn.activeOverlay then
        if isEnabled and isActive then
            btn.activeOverlay:SetAlpha(1)
        else
            btn.activeOverlay:SetAlpha(0)
        end
    end

    if btn.icon then
        btn.icon:SetDesaturated(not isEnabled)
        btn.icon:SetAlpha(isEnabled and 1 or 0.45)
    end

    if btn.textFS then
        if isEnabled then
            btn.textFS:SetTextColor(1.0, 0.82, 0)
        else
            btn.textFS:SetTextColor(0.45, 0.45, 0.45)
        end
    end
end

local function UpdatePanelVisualState()
    if not Panel then return end

    local canMarkByRole = CanPlayerMark()
    local restrictionReason = GetRestrictionReason()
    local canMark = canMarkByRole and not restrictionReason
    local canMarkTarget = canMark and CanBeRaidTarget("target")

    for marker = 1, 8 do
        local unitBtn = UnitButtons[marker]

        SetButtonState(unitBtn, canMarkTarget, false)
    end

    SetButtonState(UnitClearBtn, canMarkTarget, false)
    SetButtonState(UnitClearAllBtn, canMark, false)

    for marker = 1, 8 do
        local worldBtn = WorldButtons[marker]
        SetButtonState(worldBtn, canMark, false)
        if worldBtn and worldBtn.activeOverlay then
            if canMark and worldBtn.activeOverlay.SetAlphaFromBoolean then
                worldBtn.activeOverlay:SetAlphaFromBoolean(IsRaidMarkerActive(marker), 1, 0)
            else
                worldBtn.activeOverlay:SetAlpha(0)
            end
        end
    end

    SetButtonState(WorldClearAllBtn, canMark, false)

    if Panel.DragHint then
        if MODULE_DB.lockPanel then
            Panel.DragHint:SetText("Panel locked")
            Panel.DragHint:SetTextColor(0.7, 0.7, 0.7)
        else
            Panel.DragHint:SetText("Hold left-click to drag")
            Panel.DragHint:SetTextColor(0.2, 1.0, 0.2)
        end
    end

    if Panel.PermissionHint then
        if restrictionReason then
            Panel.PermissionHint:SetText("Unavailable right now: " .. restrictionReason)
            Panel.PermissionHint:SetTextColor(1.0, 0.3, 0.3)
        elseif IsInRaid() and not canMarkByRole then
            Panel.PermissionHint:SetText("You need leader or assistant permissions in the current group")
            Panel.PermissionHint:SetTextColor(1.0, 0.3, 0.3)
        else
            Panel.PermissionHint:SetText("Left-click to set or toggle, right-click to clear one")
            Panel.PermissionHint:SetTextColor(0.8, 0.8, 0.8)
        end
    end
end

local function ApplyPanelVisibility()
    if not Panel then return end

    local shouldShow = MODULE_DB.showPanel and true or false
    if InCombatLockdown() then
        PendingShowState = shouldShow
        return
    end

    PendingShowState = nil
    Panel:SetShown(shouldShow)
end

local function TogglePanelVisibility()
    MODULE_DB.showPanel = not MODULE_DB.showPanel
    ApplyPanelVisibility()
end

-- =============================================================
-- Part 4: UI creation
-- =============================================================
local function CreateMarkerButton(parent, x, y, marker, mode)
    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate,BackdropTemplate")
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropBorderColor(0, 0, 0, 1)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.16, 0.16, 0.16, 0.95)

    btn.activeOverlay = btn:CreateTexture(nil, "BORDER")
    btn.activeOverlay:SetAllPoints(btn.bg)
    btn.activeOverlay:SetColorTexture(0.08, 0.45, 0.08, 0.95)
    btn.activeOverlay:SetAlpha(0)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(BTN_SIZE - 8, BTN_SIZE - 8)
    btn.icon:SetPoint("CENTER")
    SetRaidIcon(btn.icon, marker)

    btn.inputBlocker = CreateFrame("Button", nil, btn)
    btn.inputBlocker:SetAllPoints(btn)
    btn.inputBlocker:SetFrameLevel(btn:GetFrameLevel() + 8)
    btn.inputBlocker:RegisterForClicks("AnyUp", "AnyDown")
    btn.inputBlocker:SetScript("OnClick", function() end)
    btn.inputBlocker:Hide()

    if mode == "unit" then
        btn:SetAttribute("type1", "raidtarget")
        -- Match Blizzard UI: left-click always sets
        btn:SetAttribute("action1", "set")
        btn:SetAttribute("marker1", marker)
        btn:SetAttribute("unit", "target")

        btn:SetAttribute("type2", "raidtarget")
        btn:SetAttribute("action2", "clear")
        btn:SetAttribute("unit2", "target")
    else
        btn:SetAttribute("type1", "worldmarker")
        -- Match Blizzard UI: left-click places, right-click clears
        btn:SetAttribute("action1", "set")
        btn:SetAttribute("marker1", marker)

        btn:SetAttribute("type2", "worldmarker")
        btn:SetAttribute("action2", "clear")
        btn:SetAttribute("marker2", marker)
    end

    btn:HookScript("PostClick", function()
        C_Timer.After(0, UpdatePanelVisualState)
    end)

    return btn
end

local function CreateTextActionButton(parent, x, y, text)
    local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate,BackdropTemplate")
    btn:SetSize(BTN_SIZE * 2 + BTN_GAP, BTN_SIZE)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropBorderColor(0, 0, 0, 1)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.16, 0.16, 0.16, 0.95)

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    fs:SetTextColor(1.0, 0.82, 0)
    btn.textFS = fs

    btn.inputBlocker = CreateFrame("Button", nil, btn)
    btn.inputBlocker:SetAllPoints(btn)
    btn.inputBlocker:SetFrameLevel(btn:GetFrameLevel() + 8)
    btn.inputBlocker:RegisterForClicks("AnyUp", "AnyDown")
    btn.inputBlocker:SetScript("OnClick", function() end)
    btn.inputBlocker:Hide()

    btn:HookScript("PostClick", function()
        C_Timer.After(0, UpdatePanelVisualState)
    end)

    return btn
end

local function CreateMainPanel()
    if Panel then return end

    Panel = CreateFrame("Frame", "InfinityRaidMarkerPanel", UIParent, "BackdropTemplate")
    Panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    Panel:SetFrameStrata("MEDIUM")
    Panel:SetClampedToScreen(true)
    Panel:SetMovable(true)
    Panel:EnableMouse(true)
    Panel:RegisterForDrag("LeftButton")
    Panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    Panel:SetBackdropColor(0.04, 0.04, 0.04, 0.92)

    Panel:SetScript("OnDragStart", function(self)
        if MODULE_DB.lockPanel then return end
        if InCombatLockdown() then return end
        self:StartMoving()
    end)

    Panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePanelPosition()
    end)

    local title = Panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Raid Marker Panel")

    Panel.DragHint = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Panel.DragHint:SetPoint("TOP", title, "BOTTOM", 0, -4)
    Panel.DragHint:SetText("")

    Panel.PermissionHint = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    Panel.PermissionHint:SetPoint("BOTTOM", 0, 10)
    Panel.PermissionHint:SetText("")

    local closeBtn = CreateFrame("Button", nil, Panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        MODULE_DB.showPanel = false
        ApplyPanelVisibility()
    end)

    local unitTitle = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    unitTitle:SetPoint("TOPLEFT", 12, -48)
    unitTitle:SetText("Target Markers")

    local worldTitle = Panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    worldTitle:SetPoint("TOPLEFT", 12, -126)
    worldTitle:SetText("World Markers")

    local unitArea = CreateFrame("Frame", nil, Panel)
    unitArea:SetSize(PANEL_WIDTH - 24, 64)
    unitArea:SetPoint("TOPLEFT", 12, -64)

    local worldArea = CreateFrame("Frame", nil, Panel)
    worldArea:SetSize(PANEL_WIDTH - 24, 64)
    worldArea:SetPoint("TOPLEFT", 12, -142)

    for marker = 1, 8 do
        local x = (marker - 1) * (BTN_SIZE + BTN_GAP)
        UnitButtons[marker] = CreateMarkerButton(unitArea, x, 0, marker, "unit")
    end

    for marker = 1, 8 do
        local x = (marker - 1) * (BTN_SIZE + BTN_GAP)
        WorldButtons[marker] = CreateMarkerButton(worldArea, x, 0, marker, "world")
    end

    local extraX = 8 * (BTN_SIZE + BTN_GAP) + 4
    UnitClearBtn = CreateTextActionButton(unitArea, extraX, 0, "Clear Target")
    UnitClearBtn:SetAttribute("type1", "raidtarget")
    UnitClearBtn:SetAttribute("action1", "clear")
    UnitClearBtn:SetAttribute("unit", "target")

    UnitClearAllBtn = CreateTextActionButton(unitArea, extraX, -(BTN_SIZE + BTN_GAP), "Clear All")
    UnitClearAllBtn:SetAttribute("type1", "raidtarget")
    UnitClearAllBtn:SetAttribute("action1", "clear-all")

    WorldClearAllBtn = CreateTextActionButton(worldArea, extraX, 0, "Clear World")
    WorldClearAllBtn:SetAttribute("type1", "worldmarker")
    WorldClearAllBtn:SetAttribute("action1", "clear")

    ApplyPanelPosition()
    ApplyPanelScale()
    ApplyPanelVisibility()
    UpdatePanelVisualState()
end

-- =============================================================
-- Part 5: Events and state
-- =============================================================
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    CreateMainPanel()
    ApplyPanelPosition()
    ApplyPanelScale()
    ApplyPanelVisibility()
    UpdatePanelVisualState()
end)

InfinityTools:RegisterEvent("RAID_TARGET_UPDATE", INFINITY_MODULE_KEY, function()
    UpdatePanelVisualState()
end)

InfinityTools:RegisterEvent("PLAYER_TARGET_CHANGED", INFINITY_MODULE_KEY, function()
    UpdatePanelVisualState()
end)

InfinityTools:RegisterEvent("GROUP_ROSTER_UPDATE", INFINITY_MODULE_KEY, function()
    UpdatePanelVisualState()
end)

InfinityTools:RegisterEvent("PARTY_LEADER_CHANGED", INFINITY_MODULE_KEY, function()
    UpdatePanelVisualState()
end)

InfinityTools:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED", INFINITY_MODULE_KEY, function()
    UpdatePanelVisualState()
end)

InfinityTools:RegisterEvent("PLAYER_REGEN_ENABLED", INFINITY_MODULE_KEY, function()
    if PendingShowState ~= nil then
        ApplyPanelVisibility()
    end
    UpdatePanelVisualState()
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "btn_toggle" then
        TogglePanelVisibility()
    elseif info.key == "btn_reset_pos" then
        MODULE_DB.posX = 0
        MODULE_DB.posY = 0
        CreateMainPanel()
        ApplyPanelPosition()
    end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "showPanel" then
        ApplyPanelVisibility()
    elseif info.key == "lockPanel" then
        UpdatePanelVisualState()
    elseif info.key == "scale" then
        ApplyPanelScale()
    end
end)

InfinityTools:RegisterChatCommand("exmarker", function()
    CreateMainPanel()
    TogglePanelVisibility()
end)

-- Initialization
CreateMainPanel()
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

