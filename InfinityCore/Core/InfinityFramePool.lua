-- [[ InfinityFramePool.lua ]]




local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local FrameFactory = {}
_G.InfinityFactory = FrameFactory

-- Pool storage
FrameFactory.Pools = {}

-- Active object tracker used by DevMonitor for frame addresses
-- Structure: { [poolType] = { [frame] = true } }
FrameFactory.ActiveTracker = {}

-------------------------------------------------------
-- Helper: standard reset function
-------------------------------------------------------
local function StandardReset(pool, frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(UIParent)
    frame:SetAlpha(1)
    frame:SetScale(1)

    -- Prevent stale behavior
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)

    -- [Fix] Only buttons have OnClick, so check the object type first.
    if frame.IsObjectType and frame:IsObjectType("Button") then
        frame:SetScript("OnClick", nil)
        frame:SetScript("PreClick", nil)
        frame:SetScript("PostClick", nil)
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnMouseUp", nil)
        if frame.Enable then
            frame:Enable()
        end
        if frame.RegisterForClicks then
            frame:RegisterForClicks("LeftButtonUp")
        end
    end

    -- Clear button text when available
    if frame.SetText then
        frame:SetText("")
    end

    if frame.EnableMouse then
        frame:EnableMouse(false)
    end

    -- Reset text cells when present
    if frame.cells then
        for _, fs in ipairs(frame.cells) do
            fs:SetText("")
            fs:SetTextColor(1, 1, 1, 1)
            fs:ClearAllPoints()
            fs:SetAlpha(1)
        end
    end

    if frame.icon then
        frame.icon:SetTexture(nil)
        frame.icon:SetDesaturated(false)
        frame.icon:SetAlpha(1)
    end

    if frame.name then frame.name:SetText("") end
    if frame.title then frame.title:SetText("") end
    if frame.value then frame.value:SetText("") end
    if frame.level then frame.level:SetText("") end
    if frame.score then frame.score:SetText("") end
    if frame.text and frame.text.SetText then frame.text:SetText("") end
    if frame.label and frame.label.SetText then frame.label:SetText("") end
    if frame.labelText and frame.labelText.SetText then frame.labelText:SetText("") end

    -- [GridCheckbox] Fully clear child checkbox state/scripts to avoid pooled leftovers.
    if frame.checkbox then
        if frame.checkbox.SetScript then
            frame.checkbox:SetScript("OnClick", nil)
            frame.checkbox:SetScript("OnEnter", nil)
            frame.checkbox:SetScript("OnLeave", nil)
            frame.checkbox:SetScript("PreClick", nil)
            frame.checkbox:SetScript("PostClick", nil)
            frame.checkbox:SetScript("OnShow", nil)
            frame.checkbox:SetScript("OnHide", nil)
        end
        if frame.checkbox.HookScript then
            -- HookScript hooks cannot be removed, so do not use HookScript on checkbox anymore.
        end
        if frame.checkbox.SetChecked then
            frame.checkbox:SetChecked(false)
        end
        if frame.checkbox.Enable then
            frame.checkbox:Enable()
        end
        if frame.checkbox.EnableMouse then
            frame.checkbox:EnableMouse(true)
        end
        if frame.checkbox.ClearAllPoints then
            frame.checkbox:ClearAllPoints()
            frame.checkbox:SetPoint("LEFT", frame, "LEFT", 0, 0)
        end
    end

    if frame.label and frame.label.ClearAllPoints and frame.checkbox then
        frame.label:ClearAllPoints()
        frame.label:SetPoint("LEFT", frame.checkbox, "RIGHT", 6, 0)
    end

    -- [v4.3.2 Fix] Clear temporary Dropdown/LSMDropdown fields to avoid config/closure leaks.
    frame._currentValue = nil
    frame._onSelect = nil
    frame._items = nil
    frame._selectedValue = nil
    -- Do not clear _mediaType: SetupMenu depends on it and CreateLSMDropdown resets it.

    -- [v4.3.12] Clear Slider callbacks but keep _sliderInit as the initialization marker.
    frame._onValueChanged = nil
    frame._formatter = nil

    -- [v4.3.13] Clear Multiselect state to avoid stale data after class/spec changes.
    frame._options = nil
    frame._selections = nil
    frame._onUpdate = nil
end

-------------------------------------------------------
-- API: initialize a pool type
-------------------------------------------------------
-- type: pool type key, e.g. "StandardRow"
-- frameType: base widget type, e.g. "Frame" or "Button"
-- template: inherited Blizzard template
-- customInit: initialization callback executed when a frame is created for the first time
function FrameFactory:InitPool(type, frameType, template, customInit)
    if self.Pools[type] then return end

    local pool = CreateFramePool(frameType or "Frame", UIParent, template, StandardReset)
    pool.customInit = customInit
    self.Pools[type] = pool
end

-------------------------------------------------------
-- API: Acquire
-------------------------------------------------------
function FrameFactory:Acquire(type, parent)
    local pool = self.Pools[type]
    if not pool then
        -- Lazily create a default pool if it was not initialized.
        self:InitPool(type, "Frame")
        pool = self.Pools[type]
    end

    local frame, isNew = pool:Acquire()



    -- [v4.3.1] Mark this frame as pool-owned
    frame._fromPool = type

    -- Run custom initialization only on the first creation.
    if isNew and pool.customInit then
        local ok, err = pcall(pool.customInit, frame)
        if not ok then
            print(string.format("|cffff0000[InfinityFactory] Init error [%s]: %s|r", tostring(type), tostring(err)))
        end
    end

    if parent then
        frame:SetParent(parent)
    end

    -- Track active objects for DevMonitor frame address display.
    if not FrameFactory.ActiveTracker[type] then
        FrameFactory.ActiveTracker[type] = {}
    end
    FrameFactory.ActiveTracker[type][frame] = true

    frame:Show()
    return frame, isNew
end

-------------------------------------------------------
-- API: Release
-------------------------------------------------------
function FrameFactory:Release(type, frame)
    -- [v4.3.1] Only pool-owned frames can be released.
    -- Check _fromPool first to avoid Blizzard pool errors.
    if not frame._fromPool then
        -- Not from this pool, so just hide it.
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent(nil)
        return
    end

    local poolType = frame._fromPool
    local pool = self.Pools[poolType]
    if pool then
        frame._fromPool = nil -- Clear marker
        -- Remove active tracking
        if FrameFactory.ActiveTracker[poolType] then
            FrameFactory.ActiveTracker[poolType][frame] = nil
        end
        pool:Release(frame)
    else
        -- Pool missing, fallback to Hide()
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent(nil)
    end
end

-------------------------------------------------------
-- API: debug helper for active object count
-------------------------------------------------------
function FrameFactory:GetActiveCount(type)
    local pool = self.Pools[type]
    return pool and pool:GetNumActive() or 0
end

-------------------------------------------------------
-- Presets: standard components
-------------------------------------------------------

-- 0. Base plain frame
FrameFactory:InitPool("SimpleFrame", "Frame", "BackdropTemplate", function(f)
end)

-- 1. StandardRow: row with a background and 5 text cells
FrameFactory:InitPool("StandardRow", "Frame", nil, function(f)
    f:SetSize(720, 25)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    f.cells = {}
    for i = 1, 5 do
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        table.insert(f.cells, fs)
    end
end)

-- 2. StandardIcon: bordered icon tile
FrameFactory:InitPool("StandardIcon", "Frame", nil, function(f)
    f:SetSize(32, 32)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints()
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.border = f:CreateTexture(nil, "OVERLAY")
    f.border:SetAllPoints()
    f.border:SetTexture("Interface\\Buttons\\UI-EmptySlot-White")
    f.border:SetVertexColor(0.3, 0.3, 0.3, 0.8)
end)

-- 3. StandardButton
FrameFactory:InitPool("StandardButton", "Button", "UIPanelButtonTemplate", function(f)
    f:SetSize(80, 22)
end)

-- 4. IconTextCard
FrameFactory:InitPool("IconTextCard", "Frame", "BackdropTemplate", function(f)
    f:SetSize(130, 65)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(1, 1, 1, 0.05)
    f:SetBackdropBorderColor(1, 1, 1, 0.25)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(45, 45)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon:SetPoint("LEFT", 0, -5)
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetPoint("TOP", 3, -6)
    f.value = f:CreateFontString(nil, "OVERLAY")
    f.value:SetPoint("TOP", 2, -27)
end)

-- 5. StatRow for Mythic+ summary
FrameFactory:InitPool("StatRow", "Frame", "BackdropTemplate", function(f)
    f:SetSize(800, 45)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetSize(40, 40)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon:SetPoint("LEFT", 10, 0)
    f.name = f:CreateFontString(nil, "OVERLAY")
    f.name:SetPoint("LEFT", 57, 0)
    f.cells = {}
    for i = 1, 10 do
        local fs = f:CreateFontString(nil, "OVERLAY")
        table.insert(f.cells, fs)
    end
end)

-- 6. RunRow for Mythic+ history rows: icon + name + item level
FrameFactory:InitPool("RunRow", "Frame", "BackdropTemplate", function(f)
    f:SetSize(300, 40)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(1, 1, 1, 0.03)
    f:SetBackdropBorderColor(1, 1, 1, 0.25)
    f.icon = f:CreateTexture(nil, "OVERLAY")
    f.icon:SetSize(30, 30)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon:SetPoint("LEFT", 6, 0)
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetPoint("LEFT", 40, 0)
    f.ilvl = f:CreateFontString(nil, "OVERLAY")
    f.ilvl:SetPoint("RIGHT", -8, 0)
end)

-- 7. MythicIconOverlay
FrameFactory:InitPool("MythicIconOverlay", "Frame", nil, function(f)
    f:SetSize(100, 100)
    f.name = f:CreateFontString(nil, "OVERLAY")
    f.level = f:CreateFontString(nil, "OVERLAY")
    f.score = f:CreateFontString(nil, "OVERLAY")
end)

-------------------------------------------------------
-- [v4.3.1] Grid engine widget pools
-- Pooled reusable UI widgets for the settings panel
-------------------------------------------------------

-- Grid widget reset function
local function ResetGridWidget(pool, frame)
    StandardReset(pool, frame)
    -- Clear Grid-specific fields
    frame._gridType = nil
    frame._gridKey = nil
    frame._moduleKey = nil
    -- Clear all event scripts
    if frame.SetScript then
        frame:SetScript("OnValueChanged", nil)
        frame:SetScript("OnTextChanged", nil)
        frame:SetScript("OnEditFocusLost", nil)
        frame:SetScript("OnEnterPressed", nil)
    end
end

-- 8. GridCheckbox container, matching RevUI:CreateCheckbox
FrameFactory:InitPool("GridCheckbox", "Frame", nil, function(f)
    f:SetSize(200, 28)

    -- Create CheckButton using Blizzard's modern template
    local cb = CreateFrame("CheckButton", nil, f, "MinimalCheckboxTemplate")
    cb:SetSize(28, 28)
    cb:SetPoint("LEFT", f, "LEFT", 0, 0)
    -- The template already provides modern checkbox atlas textures, no manual SetTexture needed.
    f.checkbox = cb

    -- Create label
    local label = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    f.label = label

    -- Compatibility methods
    function f:SetChecked(v) self.checkbox:SetChecked(v) end

    function f:GetChecked() return self.checkbox:GetChecked() end

    f._gridType = "GridCheckbox"
end)

-- 9. GridButton
-- 9. GridButton - general button
FrameFactory:InitPool("GridButton", "Button", "SharedButtonLargeTemplate", function(f)
    f:SetSize(120, 32)
    f._gridType = "GridButton"
end)

-- 10. GridSlider, matching RevUI:CreateSlider
FrameFactory:InitPool("GridSlider", "Slider", "MinimalSliderWithSteppersTemplate", function(f)
    f:SetSize(180, 20)

    -- Value text at the top right
    f.ValueText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    f.ValueText:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -2, 1)
    f.ValueText:SetJustifyH("RIGHT")

    -- Title at the top left
    f.Title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    f.Title:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 1)
    f.Title:SetPoint("RIGHT", f.ValueText, "LEFT", -5, 0)
    f.Title:SetJustifyH("LEFT")
    f.Title:SetWordWrap(false)

    f.labelText = f.Title -- Compatibility alias
    f._gridType = "GridSlider"
end)

-- 11. GridDropdown, matching RevUI:CreateDropdown
FrameFactory:InitPool("GridDropdown", "DropdownButton", "WowStyle1DropdownTemplate", function(f)
    f:SetSize(180, 30)
    f.labelText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    f.labelText:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2)
    f._gridType = "GridDropdown"

    -- [Fix] The original TOPLEFT y=-8 anchor places text too high in compact Grid rows.
    -- Center Text vertically and keep Blizzard's original Arrow y=-3 offset.
    if f.Text then
        f.Text:ClearAllPoints()
        f.Text:SetPoint("LEFT", 8, 0)
        f.Text:SetPoint("RIGHT", f.Arrow, "LEFT", -2, 0)
    end
    if f.Arrow then
        f.Arrow:ClearAllPoints()
        f.Arrow:SetPoint("RIGHT", -2, -3)
    end
end)

-- 12. GridInput
FrameFactory:InitPool("GridInput", "EditBox", "BackdropTemplate", function(f)
    f:SetSize(180, 28)
    f:SetAutoFocus(false)
    f:SetFontObject(GameFontHighlight)

    -- Use the shared addon tooltip style
    local RevUI = _G.InfinityTools.UI
    if RevUI and RevUI.TooltipBackdrop then
        f:SetBackdrop(RevUI.TooltipBackdrop)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
    end
    f:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.6)

    f:SetTextInsets(10, 10, 0, 0)
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.label:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2)
    f._gridType = "GridInput"
end)

-- 13. GridHeader, matching RevUI:CreateHeader
FrameFactory:InitPool("GridHeader", "Frame", nil, function(f)
    f:SetSize(550, 40)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 0, -5)
    title:SetTextColor(1, 0.82, 0)
    f.Title = title
    f.text = title -- Backward compatibility

    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    line:SetPoint("RIGHT", 0, 0)
    line:SetHeight(1)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))
    f.Line = line

    f._gridType = "GridHeader"
end)

-- 14. GridSubheader
FrameFactory:InitPool("GridSubheader", "Frame", nil, function(f)
    f:SetSize(400, 24)
    f.text = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    f.text:SetAllPoints()
    f.text:SetJustifyH("LEFT")
    f._gridType = "GridSubheader"
end)

-- 15. GridDivider
FrameFactory:InitPool("GridDivider", "Frame", nil, function(f)
    -- [Fix] Make the container backdrop fully transparent
    if f.SetBackdrop then f:SetBackdrop(nil) end
    f:SetSize(400, 20) -- Keep logical height, visual line stays 1px

    -- Draw the divider with the Line API for physical-pixel alignment
    local line = f:CreateLine(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.4)
    line:SetStartPoint("LEFT", f, 0, 0)
    line:SetEndPoint("RIGHT", f, 0, 0)

    -- Keep thickness aligned in real time
    local scale = line:GetEffectiveScale() or 1
    if _G.PixelUtil and _G.PixelUtil.GetNearestPixelSize then
        line:SetThickness(_G.PixelUtil.GetNearestPixelSize(1.1, scale, 1.1))
    else
        line:SetThickness(1.1)
    end

    f.line = line
    f._gridType = "GridDivider"
end)

-- 16. GridDescription
FrameFactory:InitPool("GridDescription", "Frame", nil, function(f)
    f:SetSize(400, 40)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("TOPLEFT")
    f.text:SetJustifyH("LEFT")
    f.text:SetJustifyV("TOP")
    f._gridType = "GridDescription"
end)

-- 17. GridColorButton
FrameFactory:InitPool("GridColorButton", "Button", "BackdropTemplate", function(f)
    f:SetSize(28, 28)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2
    })
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    f.swatch = f:CreateTexture(nil, "ARTWORK")
    f.swatch:SetPoint("TOPLEFT", 3, -3)
    f.swatch:SetPoint("BOTTOMRIGHT", -3, 3)
    f.swatch:SetColorTexture(1, 1, 1, 1)
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.label:SetPoint("LEFT", f, "RIGHT", 6, 0)
    f._gridType = "GridColorButton"
end)

-- 18. GridMultiselect
FrameFactory:InitPool("GridMultiselect", "Frame", "BackdropTemplate", function(f)
    f:SetSize(200, 80)
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.label:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2)
    f.checkboxes = {} -- Child checkboxes are created dynamically
    f._gridType = "GridMultiselect"
end)

-- 19. GridTableGroup container for parentKey bindings
FrameFactory:InitPool("GridTableGroup", "Frame", nil, function(f)
    f:SetSize(1, 1) -- Invisible container
    f._gridType = "GridTableGroup"
end)

-- 20. GridFontGroup: pooled outer container, children are created by CreateFontGroup
-- This pool reuses the full FontGroup container, but child widgets still need first-time initialization.
FrameFactory:InitPool("GridFontGroup", "Frame", "BackdropTemplate", function(f)
    f:SetSize(750, 280)
    f._gridType = "GridFontGroup"
    -- Child widgets are created inside RevUI:CreateFontGroup and use their own pools.
end)

-- 21. GridLSMDropdown - LSM texture selector
FrameFactory:InitPool("GridLSMDropdown", "DropdownButton", "WowStyle1DropdownTemplate", function(f)
    f:SetSize(180, 30)
    f.labelText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    f.labelText:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2)
    f._gridType = "GridLSMDropdown"
end)

-------------------------------------------------------
-- [v4.3.1] Grid pool type map
-------------------------------------------------------
FrameFactory.GridTypeMap = {
    checkbox = "GridCheckbox",
    button = "GridButton",
    slider = "GridSlider",
    dropdown = "GridDropdown",
    input = "GridInput",
    header = "GridHeader",
    subheader = "GridSubheader",
    divider = "GridDivider",
    description = "GridDescription",
    color = "GridColorButton",
    colorbutton = "GridColorButton",
    multiselect = "GridMultiselect",
    TableGroup = "GridTableGroup",
    fontgroup = "GridFontGroup",
    lsm_font = "GridLSMDropdown",
    lsm_texture = "GridLSMDropdown",
    lsm_background = "GridLSMDropdown",
    lsm_border = "GridLSMDropdown",
    lsm_sound = "GridLSMDropdown",
    lsm_statusbar = "GridLSMDropdown",
}

-------------------------------------------------------
-- [v4.3.1] Grid helper: acquire a widget
-------------------------------------------------------
function FrameFactory:AcquireGridWidget(gridType, parent)
    local poolType = self.GridTypeMap[gridType]
    if not poolType then
        -- Unknown type, fallback to SimpleFrame
        poolType = "SimpleFrame"
    end
    local frame, isNew = self:Acquire(poolType, parent)
    frame._gridType = poolType
    return frame, isNew
end

-------------------------------------------------------
-- [v4.3.1] Grid helper: release a widget
-------------------------------------------------------
function FrameFactory:ReleaseGridWidget(frame)
    if frame and frame._gridType then
        self:Release(frame._gridType, frame)
    else
        -- Fallback: hide
        if frame then
            frame:Hide()
            frame:SetParent(nil)
        end
    end
end

