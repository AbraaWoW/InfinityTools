-- =========================================================
-- InfinityGUI.lua
-- Wrap LibSharedMedia (LSM) with native WoW UI widgets.
-- =========================================================

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

-- Ensure the RevUI namespace exists (this file may load before InfinityToolsUI.lua).
local RevUI = InfinityTools.UI or {}
InfinityTools.UI = RevUI
_G.InfinityToolsUI = RevUI

-- Accent color for EditBox focus borders — synced with RRT UI Appearance
local INFINITY_GUI_ACCENT = { 0.733, 0.4, 1.0, 1 }
_G.RRT = _G.RRT or {}
_G.RRT.GlobalThemeCallbacks = _G.RRT.GlobalThemeCallbacks or {}
table.insert(_G.RRT.GlobalThemeCallbacks, function(r, g, b)
    INFINITY_GUI_ACCENT[1], INFINITY_GUI_ACCENT[2], INFINITY_GUI_ACCENT[3] = r, g, b
end)

local LSM = LibStub("LibSharedMedia-3.0")
local L = InfinityTools.L

-- [Core] Strictly follow the rule: only use the game's default font paths, no hardcoded font references.
local defaultFontPath, defaultFontSize, defaultFontFlags = _G.GameFontHighlight:GetFont()


-- [Style] Shared tooltip-style backdrop definition.
RevUI.TooltipBackdrop = {
    bgFile = "Interface\\Buttons\\WHITE8X8", -- Use a solid-color background so color can be controlled in code.
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 20,
    edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function ForEachFrameRegionRecursive(frame, callback)
    if not frame then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        callback(region)
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        ForEachFrameRegionRecursive(child, callback)
    end
end

local function SetMenuButtonTextAlpha(button, alpha)
    ForEachFrameRegionRecursive(button, function(region)
        if region and region.SetText and region.SetAlpha and region ~= (button.lsmFontPreview and button.lsmFontPreview.fs) then
            region:SetAlpha(alpha)
        end
    end)
end

-- [Helper] Shared cleanup helper to prevent UI taint.
local function CleanDropdownButton(button)
    if button.playBtn then
        button.playBtn:Hide()
    end
    if button.lsmFontPreview then
        button.lsmFontPreview:Hide()
        if button.lsmFontPreview.fs then
            button.lsmFontPreview.fs:SetText("")
            pcall(button.lsmFontPreview.fs.SetFont, button.lsmFontPreview.fs, defaultFontPath, defaultFontSize, defaultFontFlags)
        end
    end
    SetMenuButtonTextAlpha(button, 1)
end

local function CompactDropdownText(text, maxChars)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|T.-|t", "")
    maxChars = maxChars or 22
    if #text > maxChars then
        text = text:sub(1, maxChars - 2) .. ".."
    end
    return text
end

local function SetupDropdownLabel(dropdown, width, label)
    dropdown:SetWidth(width)
    if dropdown.EnableMouse then
        dropdown:EnableMouse(true)
    end
    if dropdown.Text and dropdown.Arrow then
        dropdown.Text:ClearAllPoints()
        dropdown.Text:SetPoint("LEFT", 8, 0)
        dropdown.Text:SetPoint("RIGHT", dropdown.Arrow, "LEFT", -2, 0)
        dropdown.Arrow:ClearAllPoints()
        dropdown.Arrow:SetPoint("RIGHT", -2, -3)
    end
    if dropdown.labelText then
        dropdown.labelText:SetText(CompactDropdownText(label or "", 24))
        dropdown.labelText:SetWidth(width)
        dropdown.labelText:SetWordWrap(false)
    end
    if dropdown.Text then
        dropdown.Text:SetWordWrap(false)
        dropdown.Text:SetText(CompactDropdownText(dropdown.Text:GetText(), 22))
    end
end

-- =========================================================
-- [Core] Shared label-style refresh helper (used by the InfinityGrid editor).
-- =========================================================
function RevUI:UpdateLabelStyle(widget, size, pos)
    if not widget then return end

    -- 1. Find the Label object (different widgets store it in different places, so scan them all).
    local label = widget.labelText or widget.label or widget.Title
    if not label or not label.SetFont then return end

    -- Keep a reference for later reuse.
    widget._exLabel = label

    -- 2. [Fix v4.3.4] Restore SetFont with MAIN_FONT after CJK detection.
    local fontSize = tonumber(size) or 16
    local fontPath = InfinityTools.MAIN_FONT

    label:SetFont(fontPath, fontSize, "OUTLINE")

    -- [v4.3.1] Cascade updates to child media.
    if widget.SetFont then
        if widget:GetObjectType() == "EditBox" then
            widget:SetFontObject("ChatFontNormal") -- Special handling for edit boxes.
        else
            widget:SetFont(fontPath, fontSize, "OUTLINE")
        end
    end
    if widget.nameText then -- Dedicated support for item config widgets.
        widget.nameText:SetFontObject("GameFontNormalLarge")
    end

    -- [Fix] Unify detection logic so pooled name fields are supported too (GridCheckbox, GridSlider, etc.).
    local gType = widget._gridType and widget._gridType:lower() or ""

    -- 3. Preserve position for special widgets (FontGroup/Header, etc.): change fonts only, do not move them.
    if gType:find("fontgroup") or gType:find("header") or gType:find("soundgroup")
        or gType:find("description") then
        return
    end

    -- 4. Special handling for Checkbox/Slider widgets.

    -- Checkbox uses a [Box] [Label] structure, so it needs explicit handling.
    if gType == "checkbox" or gType == "gridcheckbox" then
        label:ClearAllPoints()
        if pos == "left" then
            label:SetPoint("RIGHT", widget.checkbox, "LEFT", -5, 0)
            label:SetJustifyH("RIGHT")
        elseif pos == "top" then
            label:SetPoint("BOTTOMLEFT", widget.checkbox, "TOPLEFT", 0, 2)
            label:SetJustifyH("LEFT")
        else -- right (Default)
            label:SetPoint("LEFT", widget.checkbox, "RIGHT", 6, 0)
            label:SetJustifyH("LEFT")
        end
        return
    end

    -- [Fix] For sliders, keep the Title from overlapping ValueText.
    if gType == "slider" or gType == "gridslider" then
        label:ClearAllPoints()
        if pos == "left" then
            label:SetPoint("RIGHT", widget, "LEFT", -5, 0)
            label:SetJustifyH("RIGHT")
        else -- top (Default)
            label:SetPoint("BOTTOMLEFT", widget, "TOPLEFT", 0, 1)
            if widget.ValueText then
                label:SetPoint("RIGHT", widget.ValueText, "LEFT", -5, 0)
            end
            label:SetJustifyH("LEFT")
            label:SetWordWrap(false)
        end
        return
    end

    -- [Fix] Do not modify positions for specific grouped widgets.
    if gType == "fontgroup" or gType == "gridfontgroup" or gType == "header" or gType == "gridheader"
        or gType == "soundgroup" or gType == "subheader" or gType == "gridsubheader" or gType == "icongroup" or gType == "glow_settings"
        or gType == "description" or gType == "griddescription" then
        return
    end

    -- Generic handling (Input, Dropdown, Button, etc.).
    if not pos then pos = "top" end
    label:ClearAllPoints()

    if pos == "left" then
        label:SetPoint("RIGHT", widget, "LEFT", -5, 0)
        label:SetJustifyH("RIGHT")
    elseif pos == "right" then
        label:SetPoint("LEFT", widget, "RIGHT", 5, 0)
        label:SetJustifyH("LEFT")
    else -- top
        label:SetPoint("BOTTOMLEFT", widget, "TOPLEFT", 0, 3)
        label:SetJustifyH("LEFT")
    end
end

-- =========================================================
-- 0. Generic single-select dropdown - [v4.3.1] pooling support.
-- items format: { "Option 1", "Option 2" } or { {"Display Text", "ActualValue"}, ... }
-- =========================================================
function RevUI:CreateDropdown(parent, width, label, items, currentValue, onSelect)
    local FrameFactory = _G.InfinityFactory
    local dropdown

    if FrameFactory then
        -- Reuse from pool.
        dropdown = FrameFactory:Acquire("GridDropdown", parent)
    else
        -- Fallback: legacy creation path.
        dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dropdown.labelText = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        dropdown.labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
        if dropdown.Text then
            dropdown.Text:ClearAllPoints()
            dropdown.Text:SetPoint("LEFT", 8, 0)
            dropdown.Text:SetPoint("RIGHT", dropdown.Arrow, "LEFT", -2, 0)
        end
        if dropdown.Arrow then
            dropdown.Arrow:ClearAllPoints()
            dropdown.Arrow:SetPoint("RIGHT", -2, 0)
        end
    end

    SetupDropdownLabel(dropdown, width, label)

    -- [v4.3.2 Fix] Attach state to self so SetupMenu closures do not capture stale references and leak memory.
    dropdown._currentValue = currentValue
    dropdown._onSelect = onSelect
    dropdown._items = items

    -- [Fix] Recursively find the display text for the selected value.
    local function GetEntry(val, list)
        for _, item in ipairs(list or items) do
            if type(item) == "table" then
                if item.isMenu then
                    local found, v = GetEntry(val, item.menu)
                    if found ~= L["Select..."] then return found, v end
                elseif item[2] == val or (tonumber(item[2]) and tonumber(item[2]) == tonumber(val)) then
                    return item[1], item[2]
                end
            else
                if item == val or (tonumber(item) and tonumber(item) == tonumber(val)) then return item, item end
            end
        end
        return L["Select..."], nil
    end

    local initialText = GetEntry(currentValue)
    dropdown:SetText(CompactDropdownText(initialText, 22))

    -- [Fix] Build the menu using self references.
    dropdown:SetupMenu(function(self, rootDescription)
        rootDescription:SetScrollMode(400)

        local function BuildMenu(rootDesc, list)
            if not list then return end -- [Fix] Guard against nil during pooled initialization windows.
            for _, item in ipairs(list) do
                if type(item) == "table" and item.isMenu then
                    local subMenu = rootDesc:CreateButton(item.text, function() end)
                    BuildMenu(subMenu, item.menu)
                else
                    local text, value
                    if type(item) == "table" then
                        text, value = item[1], item[2]
                    else
                        text, value = item, item
                    end

                    rootDesc:CreateRadio(text,
                        function()
                            -- [Fix] Resolve self._currentValue dynamically inside the closure, otherwise state can deadlock.
                            return (self._currentValue == value) or (tostring(self._currentValue) == tostring(value))
                        end,
                        function()
                            self._currentValue = value
                            self:SetText(CompactDropdownText(text, 22))
                            if self._onSelect then self._onSelect(value, text) end
                        end
                    ):AddInitializer(function(button, description, menu)
                        CleanDropdownButton(button)
                    end)
                end
            end
        end

        BuildMenu(rootDescription, self._items)
    end)

    return dropdown
end

-- =========================================================
-- 1. Font dropdown (LSM Font) - [v4.3.1] pooling support.
-- =========================================================
function RevUI:CreateLSMDropdown(parent, mediaType, width, label, currentValue, onSelect)
    -- [Fix] Compatibility handling.
    if type(currentValue) == "function" and onSelect == nil then
        onSelect = currentValue
        currentValue = nil
    end

    local FrameFactory = _G.InfinityFactory
    local dropdown

    if FrameFactory then
        -- Reuse the GridLSMDropdown pool.
        dropdown = FrameFactory:Acquire("GridLSMDropdown", parent)
    else
        -- Fallback.
        dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dropdown.labelText = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        dropdown.labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
    end

    SetupDropdownLabel(dropdown, width, label)

    -- [v4.3.2 Fix] Attach state to self.
    dropdown._selectedValue = currentValue or LSM:GetDefault(mediaType)
    dropdown._onSelect = onSelect
    dropdown._mediaType = mediaType

    dropdown:SetText(CompactDropdownText(dropdown._selectedValue, 22))

    dropdown:SetupMenu(function(self, rootDescription)
        if not self._mediaType then return end -- [Fix] Guard against nil when reused.
        rootDescription:CreateTitle(L["Select "] .. (self._mediaType == "font" and L["Font"] or self._mediaType))  -- TODO: missing key: L["Select "]
        if rootDescription.SetScrollMode then rootDescription:SetScrollMode(400) end

        local list = LSM:HashTable(self._mediaType)
        local sortedKeys = LSM:List(self._mediaType)

        for _, key in ipairs(sortedKeys) do
            local path = list[key]
            -- Use self properties instead of captured closure variables.
            local btn = rootDescription:CreateRadio(key, function() return self._selectedValue == key end, function()
                self._selectedValue = key
                self:SetText(CompactDropdownText(key, 22))
                if self._onSelect then self._onSelect(key, path) end
            end)

            if self._mediaType == "font" then
                btn:AddInitializer(function(button, description, menu)
                    CleanDropdownButton(button)
                end)
            end
        end
    end)
    return dropdown
end

-- =========================================================
-- 2. Texture dropdown (LSM Texture/Border/Background/Statusbar) - [v4.3.1] pooling support.
-- =========================================================
function RevUI:CreateLSMTextureDropdown(parent, mediaType, width, label, currentValue, onSelect)
    -- [Fix] Compatibility handling.
    if type(currentValue) == "function" and onSelect == nil then
        onSelect = currentValue
        currentValue = nil
    end

    local FrameFactory = _G.InfinityFactory
    local dropdown

    if FrameFactory then
        -- Reuse the GridLSMDropdown pool.
        dropdown = FrameFactory:Acquire("GridLSMDropdown", parent)
    else
        -- Fallback.
        dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dropdown.labelText = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        dropdown.labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
    end

    SetupDropdownLabel(dropdown, width, label)

    local selectedValue = currentValue or LSM:GetDefault(mediaType)
    -- If the selected key does not exist in LSM (for example SharedMedia is not installed), fall back to "Solid".
    if selectedValue and not LSM:HashTable(mediaType)[selectedValue] then
        selectedValue = LSM:HashTable(mediaType)["Solid"] and "Solid" or LSM:GetDefault(mediaType)
    end
    dropdown:SetText(CompactDropdownText(selectedValue or "None", 22))

    dropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateTitle(L["Select Texture"])
        if rootDescription.SetScrollMode then rootDescription:SetScrollMode(400) end

        local list = LSM:HashTable(mediaType)
        local sortedKeys = LSM:List(mediaType)

        for _, key in ipairs(sortedKeys) do
            local path = list[key]
            local shortKey = #key > 24 and (string.sub(key, 1, 23) .. "..") or key

            local displayText = shortKey
            if path then
                if mediaType == "statusbar" then
                    displayText = string.format("|T%s:14:100:0:0:64:64:5:59:5:59|t %s", path, shortKey)
                elseif mediaType == "background" then
                    displayText = string.format("|T%s:20:20:0:0:64:64:5:59:5:59|t %s", path, shortKey)
                elseif mediaType == "border" then
                    -- Border textures usually need the full image; do not crop them.
                    displayText = string.format("|T%s:14:100|t %s", path, shortKey)
                else
                    displayText = string.format("|T%s:16:16:0:0:64:64:5:59:5:59|t %s", path, shortKey)
                end
            end

            local btn = rootDescription:CreateRadio(displayText,
                function() return selectedValue == key end,
                function()
                    selectedValue = key
                    dropdown:SetText(CompactDropdownText(key, 22))
                    if onSelect then onSelect(key, path) end
                end
            )

            btn:AddInitializer(function(button, description, menu)
                CleanDropdownButton(button)
            end)
        end
    end)

    return dropdown
end

-- =========================================================
-- 3. Sound dropdown (LSM Sound with Groups)
-- =========================================================
function RevUI:CreateLSMSoundDropdown(parent, width, label, currentValue, onSelect)
    -- [Fix] Compatibility handling: if the 4th argument is a function, treat it as a legacy call where onSelect was passed in currentValue's slot.
    if type(currentValue) == "function" and onSelect == nil then
        onSelect = currentValue
        currentValue = nil
    end

    local FrameFactory = _G.InfinityFactory
    local dropdown
    if FrameFactory then
        dropdown = FrameFactory:Acquire("GridLSMDropdown", parent)
    else
        dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dropdown.labelText = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        dropdown.labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
    end
    SetupDropdownLabel(dropdown, width, label)

    -- [Pooling] Store state on self to avoid creating a new closure chain on every render.
    dropdown._selectedValue = type(currentValue) == "string" and currentValue or LSM:GetDefault("sound")
    dropdown._onSelect = onSelect

    dropdown:SetText(CompactDropdownText(dropdown._selectedValue or "None", 22))

    dropdown:SetupMenu(function(self, rootDescription)
        rootDescription:CreateTitle(L["Select Sound"])
        if rootDescription.SetScrollMode then rootDescription:SetScrollMode(400) end

        local list = LSM:HashTable("sound")
        local keys = LSM:List("sound")

        -- Grouping logic.
        local exKeys = {}
        local otherKeys = {}
        for _, key in ipairs(keys) do
            if key:find("^%(EX%)") then
                table.insert(exKeys, key)
            else
                table.insert(otherKeys, key)
            end
        end

        local function AddSoundToMenu(targetDescription, key, path)
            local shortKey = #key > 50 and (string.sub(key, 1, 49) .. ".") or key
            local btn = targetDescription:CreateRadio(shortKey,
                function() return self._selectedValue == key end,
                function()
                    self._selectedValue = key
                    self:SetText(CompactDropdownText(key, 22))
                    if self._onSelect then self._onSelect(key, path) end
                end
            )

            btn:AddInitializer(function(button, description, menu)
                CleanDropdownButton(button)
                if not button.playBtn then
                    button.playBtn = MenuTemplates.AttachBasicButton(button, 16, 16)
                    button.playBtn:SetPoint("RIGHT", -5, 0)
                    button.playBtn.tex = button.playBtn:AttachTexture()
                    button.playBtn.tex:SetAllPoints()
                    button.playBtn.tex:SetTexture("Interface\\Common\\VoiceChat-Speaker")
                    button.playBtn.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Standard crop.
                end
                local playBtn = button.playBtn
                local tex = playBtn.tex
                playBtn:Show()
                tex:SetAllPoints()
                tex:SetTexture("Interface\\Common\\VoiceChat-Speaker")
                tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Standard crop.
                tex:SetVertexColor(0.8, 0.8, 0.8)
                playBtn:SetScript("OnEnter", function(self) tex:SetVertexColor(1, 1, 1) end)
                playBtn:SetScript("OnLeave", function(self) tex:SetVertexColor(0.8, 0.8, 0.8) end)
                MenuTemplates.SetUtilityButtonClickHandler(playBtn, function()
                    if path then PlaySoundFile(path, "Master") end
                end)
            end)
        end

        if #exKeys > 0 then
            local submenu = rootDescription:CreateButton(L["INFINITY Sounds"])
            for _, key in ipairs(exKeys) do
                AddSoundToMenu(submenu, key, list[key])
            end
            rootDescription:CreateDivider()
        end

        for _, key in ipairs(otherKeys) do
            AddSoundToMenu(rootDescription, key, list[key])
        end
    end)

    return dropdown
end

-- =========================================================
-- 4. Multi-select dropdown
-- =========================================================
function RevUI:CreateMultiSelectDropdown(parent, width, label, options, selections, onUpdate)
    local FrameFactory = _G.InfinityFactory
    local dropdown

    if FrameFactory then
        -- Reuse the GridDropdown pool (it already contains DropdownButton + Label).
        dropdown = FrameFactory:Acquire("GridDropdown", parent)
    else
        -- Fallback.
        dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dropdown.labelText = dropdown:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        dropdown.labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
    end

    SetupDropdownLabel(dropdown, width, label)

    -- [v4.3.2] Attach state to self to avoid closure leaks.
    dropdown._options = options
    dropdown._selections = selections
    dropdown._onUpdate = onUpdate

    -- [Fix] Rename to RefreshSelectionDisplay to avoid colliding with a Blizzard internal method and causing a stack overflow.
    function dropdown:RefreshSelectionDisplay()
        local selectedKeys = {}
        for _, key in ipairs(self._options) do
            if self._selections[key] then table.insert(selectedKeys, key) end
        end
        local display = L["None selected"]
        if #selectedKeys > 0 then
            if #selectedKeys <= 2 then
                display = table.concat(selectedKeys, ", ")
            else
                display = string.format(L["%d selected"], #selectedKeys)  -- TODO: missing key: L["%d selected"]
            end
        end
        self:SetText(CompactDropdownText(display, 22))
        if self._onUpdate then self._onUpdate(self._selections) end
    end

    dropdown:RefreshSelectionDisplay()

    dropdown:SetupMenu(function(self, rootDescription)
        rootDescription:SetScrollMode(400)
        rootDescription:CreateTitle(label)

        if not self._options then return end

        for _, key in ipairs(self._options) do
            rootDescription:CreateCheckbox(key,
                function() return self._selections[key] == true end,
                function()
                    self._selections[key] = not self._selections[key]
                    self:RefreshSelectionDisplay()
                    return MenuResponse.Refresh
                end
            ):AddInitializer(function(button, description, menu)
                CleanDropdownButton(button)
            end)
        end
        rootDescription:CreateDivider()
        rootDescription:CreateButton(L["Clear All"], function()
            for k in pairs(self._selections) do self._selections[k] = nil end
            self:RefreshSelectionDisplay()
            return MenuResponse.Refresh
        end)
    end)

    -- Backward compatibility with the old API.
    dropdown.dropdown = dropdown

    return dropdown
end

-- =========================================================
-- 5. Generic button - [v4.3.1] pooling support.
-- =========================================================
function RevUI:CreateButton(parent, width, height, text, onClick)
    local FrameFactory = _G.InfinityFactory
    local btn

    if FrameFactory then
        -- Reuse from pool.
        btn = FrameFactory:Acquire("GridButton", parent)
        -- Clear the previous OnClick handler.
        btn:SetScript("OnClick", nil)
        btn:SetScript("PreClick", nil)
        btn:SetScript("PostClick", nil)
        btn:SetScript("OnMouseDown", nil)
        btn:SetScript("OnMouseUp", nil)
    else
        -- Fallback.
        btn = CreateFrame("Button", nil, parent, "SharedButtonLargeTemplate")
    end

    btn:SetSize(width or 120, height or 32)
    if btn.EnableMouse then
        btn:EnableMouse(true)
    end
    if btn.Enable then
        btn:Enable()
    end
    if btn.RegisterForClicks then
        btn:RegisterForClicks("LeftButtonUp")
    end
    btn:SetText(text)

    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    return btn
end

-- =========================================================
-- 5b. Icon button (PicButton) - supports Normal/Pushed/Highlight textures.
-- =========================================================
function RevUI:CreatePicButton(parent, width, height, normalTex, pushedTex, highlightTex, onClick, noCrop)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 32, height or 32)

    local crop = (not noCrop) and { 0.08, 0.92, 0.08, 0.92 } or { 0, 1, 0, 1 }

    -- 1. Normal-state texture
    if normalTex then
        local n = btn:CreateTexture(nil, "ARTWORK")
        n:SetTexture(normalTex)
        n:SetAllPoints()
        n:SetTexCoord(unpack(crop))
        btn:SetNormalTexture(n)
        btn.Normal = n
    end

    -- 2. Pressed-state texture
    if pushedTex then
        local p = btn:CreateTexture(nil, "ARTWORK")
        p:SetTexture(pushedTex)
        p:SetAllPoints()
        p:SetTexCoord(unpack(crop))
        btn:SetPushedTexture(p)
        btn.Pushed = p
    else
        -- ...
        -- Auto-generate the pressed effect: slightly shrink and offset the texture.
        btn:SetPushedTextOffset(1, -1)
        if btn.Normal then
            -- If no Pushed texture exists, darken the Normal texture while pressed.
            btn:GetPushedTexture():SetVertexColor(0.7, 0.7, 0.7)
        end
    end

    -- 3. Highlight (hover) texture
    if highlightTex then
        local h = btn:CreateTexture(nil, "HIGHLIGHT")
        h:SetTexture(highlightTex)
        h:SetAllPoints()
        h:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        btn:SetHighlightTexture(h)
    else
        -- Auto-generate the highlight effect: semi-transparent white glow.
        local h = btn:CreateTexture(nil, "HIGHLIGHT")
        h:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        h:SetAllPoints()
        h:SetBlendMode("ADD")
        btn:SetHighlightTexture(h)
    end

    if onClick then btn:SetScript("OnClick", onClick) end
    return btn
end

-- =========================================================
-- 6. Generic checkbox - [v4.3.1] pooling support.
-- =========================================================
function RevUI:CreateCheckbox(parent, text, initialValue, onClick)
    local FrameFactory = _G.InfinityFactory
    local container

    if FrameFactory then
        -- Reuse from pool (checkbox and label are already pre-created there).
        container = FrameFactory:Acquire("GridCheckbox", parent)
    else
        -- Fallback: legacy creation path.
        container = CreateFrame("Frame", nil, parent)
        container:SetSize(200, 28)

        local cb = CreateFrame("CheckButton", nil, container, "MinimalCheckboxTemplate")
        cb:SetSize(28, 28)
        cb:SetPoint("LEFT", container, "LEFT", 0, 0)
        -- Remove old hardcoded textures and rely on the modern atlas provided by the template.
        container.checkbox = cb

        local label = container:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        container.label = label

        function container:SetChecked(v) self.checkbox:SetChecked(v) end

        function container:GetChecked() return self.checkbox:GetChecked() end
    end

    -- Set the current value.
    container:SetSize(200, 28)
    container.checkbox:SetChecked(initialValue)
    container.label:SetText(text or "")
    if container.EnableMouse then
        container:EnableMouse(false)
    end
    container:SetScript("OnEnter", nil)
    container:SetScript("OnLeave", nil)
    if container.checkbox.EnableMouse then
        container.checkbox:EnableMouse(true)
    end
    container.checkbox:SetScript("OnEnter", nil)
    container.checkbox:SetScript("OnLeave", nil)
    container.checkbox:SetScript("PreClick", nil)
    container.checkbox:SetScript("PostClick", nil)

    -- Set the callback.
    container.checkbox:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        if onClick then onClick(self:GetChecked() == true) end
    end)

    return container
end

-- =========================================================
-- 7. Generic slider - [v4.3.13] pooling support.
-- =========================================================
function RevUI:CreateSlider(parent, width, label, minVal, maxVal, curVal, step, formatter, onValueChanged)
    local FrameFactory = _G.InfinityFactory
    local slider

    if FrameFactory then
        slider = FrameFactory:Acquire("GridSlider", parent)
    else
        slider = CreateFrame("Slider", nil, parent, "MinimalSliderWithSteppersTemplate")
    end

    slider:SetWidth(width or 200)
    if slider.EnableMouse then
        slider:EnableMouse(true)
    end

    -- [Pooling] Store the callback on the slider itself.
    slider._onValueChanged = onValueChanged

    -- [v4.3.15 Fix] Smart formatting: if decimal steps are enabled, automatically show the matching precision.
    local precision = 0
    if step and step < 1 then
        if step >= 0.1 then
            precision = 1
        elseif step >= 0.01 then
            precision = 2
        else
            precision = 3
        end
    end

    slider._formatter = (type(formatter) == "function") and formatter or function(v)
        if precision > 0 then
            return string.format("%." .. precision .. "f", v)
        else
            return math.floor(v + 0.5) -- Round in integer mode.
        end
    end

    -- Pooled sliders may already have ValueText/Title; only recreate them if missing to avoid ghosted overlapping text while dragging.
    if not slider.ValueText then
        slider.ValueText = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        slider.ValueText:SetFontObject("GameFontNormal")
        slider.ValueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", -2, 1)
        slider.ValueText:SetJustifyH("RIGHT")
    end
    if not slider.Title then
        slider.Title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        slider.Title:SetFontObject("GameFontNormal")
        slider.Title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 1)
        slider.Title:SetJustifyH("LEFT")
        slider.Title:SetWordWrap(false)
    end
    slider.Title:ClearAllPoints()
    slider.Title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 1)
    slider.Title:SetPoint("RIGHT", slider.ValueText, "LEFT", -5, 0)
    slider.labelText = slider.Title

    -- Register the callback only once on first init.
    if not slider._sliderInit then
        -- [v4.3.13 Fix] Pass slider as the owner.
        -- CallbackRegistryMixin TriggerEvent invokes callbacks as callback(owner, value).
        -- So the first parameter s is the slider itself.
        slider:RegisterCallback("OnValueChanged", function(s, value)
            if s._onValueChanged then s._onValueChanged(value) end
            if s.ValueText and s._formatter then
                s.ValueText:SetText(s._formatter(value))
            end
        end, slider)
        slider._sliderInit = true
    end

    -- Update on every call: title, displayed value, and slider position.
    if slider.Title then slider.Title:SetText(label or "") end
    if slider.ValueText then slider.ValueText:SetText(slider._formatter(curVal)) end

    if slider.Init then
        slider:Init(curVal, minVal, maxVal, (maxVal - minVal) / (step or 1))
    end

    return slider
end

-- =========================================================
-- 8. Generic separator
-- =========================================================
function RevUI:CreateSeparator(parent, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetSize(width or 200, 1)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    -- Use a gradient so the line looks more polished.
    line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.3), CreateColor(1, 1, 1, 0.05))
    return line
end

-- =========================================================
-- 9. Section header (Header with Line) - [v4.3.1] pooling support.
-- =========================================================
function RevUI:CreateHeader(parent, text, width)
    local FrameFactory = _G.InfinityFactory
    local container

    if FrameFactory then
        -- Reuse from pool (title and line are already pre-created there).
        container = FrameFactory:Acquire("GridHeader", parent)
    else
        -- Fallback: legacy creation path.
        container = CreateFrame("Frame", nil, parent)
        container:SetSize(width or 550, 40)

        local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        title:SetPoint("TOPLEFT", 0, -5)
        title:SetTextColor(1, 0.82, 0)
        container.Title = title

        local line = container:CreateTexture(nil, "ARTWORK")
        line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
        line:SetPoint("RIGHT", 0, 0)
        line:SetHeight(1)
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))
        container.Line = line
    end

    container:SetSize(width or 550, 40)
    container.Title:SetText(text or "")

    return container
end

-- =========================================================
-- 10. Font settings group
-- Pass a db table (must contain .font, .size, .outline) and the full group is created automatically.
-- =========================================================
-- =========================================================
-- 11. Color button
-- =========================================================
function RevUI:CreateColorButton(parent, label, db, key, hasAlpha, onUpdate)
    local FrameFactory = _G.InfinityFactory
    local btn

    if FrameFactory then
        btn = FrameFactory:Acquire("GridColorButton", parent)
    else
        btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        if not btn.swatch then
            btn.swatch = btn:CreateTexture(nil, "OVERLAY")
            btn.swatch:SetTexture("Interface\\Buttons\\WHITE8X8")
        end
        if not btn.labelText then
            local txt = btn:CreateFontString(nil, "OVERLAY")
            txt:SetFontObject("GameFontHighlight")
            btn.labelText = txt
        end
    end

    -- 1. Main container
    btn:SetSize(225, 36)
    if btn.EnableMouse then
        btn:EnableMouse(true)
    end

    -- 2. Apply tooltip-style background and border
    btn:SetBackdrop(RevUI.TooltipBackdrop)
    btn:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

    -- 3. Left preview swatch
    local swatch = btn.swatch
    if swatch then
        swatch:ClearAllPoints()
        swatch:SetSize(16, 16)
        swatch:SetPoint("LEFT", btn, "LEFT", 10, 0)
        swatch:SetTexture("Interface\\Buttons\\WHITE8X8")
    end

    if not btn.swatchBorder then
        btn.swatchBorder = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        btn.swatchBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    end
    btn.swatchBorder:ClearAllPoints()
    btn.swatchBorder:SetPoint("TOPLEFT", swatch, -1, 1)
    btn.swatchBorder:SetPoint("BOTTOMRIGHT", swatch, 1, -1)
    btn.swatchBorder:SetBackdropBorderColor(0, 0, 0, 0.8)

    -- 4. Text label
    if not btn.labelText then
        btn.labelText = btn.label
    end
    if not btn.labelText then
        btn.labelText = btn:CreateFontString(nil, "OVERLAY")
        btn.labelText:SetFontObject("GameFontHighlight")
    end
    local text = btn.labelText
    text:SetFontObject("GameFontHighlight")
    text:ClearAllPoints()
    text:SetPoint("LEFT", swatch, "RIGHT", 10, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetText(label or "")

    -- [Key] Store properties so pooled reuse can refresh them later.
    btn._currentDb = db
    btn._currentKey = key
    btn._currentOnUpdate = onUpdate
    btn._hasAlpha = hasAlpha

    if not btn.UpdateColor then
        function btn:UpdateColor(nr, ng, nb, na)
            local r, g, b, a
            if type(nr) == "number" then
                r, g, b, a = nr, ng, nb, na
            else
                local d, k = self._currentDb, self._currentKey
                if not d then return end
                if not k or k == "" then
                    r, g, b, a = d.r or 1, d.g or 1, d.b or 1, d.a or 1
                else
                    r, g, b, a = d[k .. "R"] or 1, d[k .. "G"] or 1, d[k .. "B"] or 1, d[k .. "A"] or 1
                end
            end
            if self.swatch then
                self.swatch:SetVertexColor(r, g, b, a)
            end
            self:SetBackdropColor(r * 0.2, g * 0.2, b * 0.2, 0.75)
            self:SetBackdropBorderColor(r, g, b, 0.4)
        end
    end

    btn:UpdateColor()

    btn:SetScript("OnClick", function(self)
        local d, k = self._currentDb, self._currentKey
        if type(d) ~= "table" then return end

        local function GetDBColor()
            if not k or k == "" then
                return d.r or 1, d.g or 1, d.b or 1, d.a or 1
            else
                return d[k .. "R"] or 1, d[k .. "G"] or 1, d[k .. "B"] or 1, d[k .. "A"] or 1
            end
        end

        local function SetDBColor(r, g, b, a)
            if not k or k == "" then
                d.r, d.g, d.b, d.a = r, g, b, a
            else
                d[k .. "R"], d[k .. "G"], d[k .. "B"], d[k .. "A"] = r, g, b, a
            end
        end

        local currR, currG, currB, currA = GetDBColor()
        local info = {
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = self._hasAlpha and ColorPickerFrame:GetColorAlpha() or 1
                SetDBColor(r, g, b, a)
                self:UpdateColor()
                if self._currentOnUpdate then self._currentOnUpdate(d) end
            end,
            opacityFunc = self._hasAlpha and function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                SetDBColor(r, g, b, a)
                self:UpdateColor()
                if self._currentOnUpdate then self._currentOnUpdate(d) end
            end or nil,
            cancelFunc = function(prev)
                SetDBColor(prev.r, prev.g, prev.b, prev.a or prev.opacity or 1)
                self:UpdateColor()
                if self._currentOnUpdate then self._currentOnUpdate(d) end
            end,
            hasOpacity = self._hasAlpha,
            opacity = self._hasAlpha and currA or 1,
            r = currR,
            g = currG,
            b = currB,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)
    return btn
end

-- =========================================================
-- 10. Font settings group (fully wrapped version) - [v4.3.1] pooling support.
-- =========================================================
function RevUI:CreateFontGroup(parent, width, label, db, onUpdate)
    local FrameFactory = _G.InfinityFactory
    local group
    local groupWidth = width or 750
    local groupHeight = 280

    local function getDb() return group and group._currentDb end
    local function getOnUpdate() return group and group._currentOnUpdate end

    if FrameFactory then
        -- Reuse from pool.
        group = FrameFactory:Acquire("GridFontGroup", parent)
        group:SetSize(groupWidth, groupHeight)

        -- Refresh the title when reusing.
        if group.labelText then
            group.labelText:SetText(label or "")
        end

        -- Refresh values and callbacks for all child widgets when reusing.
        if group._initialized then
            group._currentDb = db
            group._currentOnUpdate = onUpdate

            -- [Key] Synchronize sub-widget properties too, so pooled reuse does not keep references to old row data.

            -- 1. Refresh the color button
            if group.colorBtn and group.colorBtn.UpdateColor then
                group.colorBtn._currentDb = db
                group.colorBtn._currentOnUpdate = onUpdate
                group.colorBtn:UpdateColor()
            end

            -- 2. Refresh the sliders (Init internally triggers callbacks bound to getDb()).
            if group.sizeSlider and group.sizeSlider.Init then
                group.sizeSlider._onValueChanged = function(v)
                    getDb().size = v; if getOnUpdate() then getOnUpdate()(getDb()) end
                end
                group.sizeSlider:Init(db.size or 14, 4, 100, 96)
            end
            if group.xSlider and group.xSlider.Init then
                group.xSlider._onValueChanged = function(v)
                    getDb().x = v; if getOnUpdate() then getOnUpdate()(getDb()) end
                end
                group.xSlider:Init(db.x or 0, -200, 200, 400)
            end
            if group.ySlider and group.ySlider.Init then
                group.ySlider._onValueChanged = function(v)
                    getDb().y = v; if getOnUpdate() then getOnUpdate()(getDb()) end
                end
                group.ySlider:Init(db.y or 0, -200, 200, 400)
            end
            if group.sxSlider and group.sxSlider.Init then
                group.sxSlider._onValueChanged = function(v)
                    getDb().shadowX = v; if getOnUpdate() then getOnUpdate()(getDb()) end
                end
                group.sxSlider:Init(db.shadowX or 1, -20, 20, 400)
            end
            if group.sySlider and group.sySlider.Init then
                group.sySlider._onValueChanged = function(v)
                    getDb().shadowY = v; if getOnUpdate() then getOnUpdate()(getDb()) end
                end
                group.sySlider:Init(db.shadowY or -1, -20, 20, 400)
            end

            -- 3. Refresh the checkboxes
            if group.shadowCheck then
                group.shadowCheck.checkbox:SetScript("OnClick", function(self)
                    getDb().shadow = self:GetChecked()
                    if getOnUpdate() then getOnUpdate()(getDb()) end
                end)
                group.shadowCheck.checkbox:SetChecked(db.shadow)
            end

            if group.fontDropdown then
                group.fontDropdown._mediaType = "font"
                -- [Key] Refresh both _selectedValue and the visible display text.
                group.fontDropdown._selectedValue = db.font or LSM:GetDefault("font")
                group.fontDropdown._onSelect = function(key)
                    getDb().font = key; if getOnUpdate() then getOnUpdate()(getDb()) end
                end
                group.fontDropdown:SetText(db.font or "Default")
            end

            if group.outlineDropdown then
                group.outlineDropdown._currentValue = db.outline or "OUTLINE"
                group.outlineDropdown._onSelect = function(val)
                    getDb().outline = val; if getOnUpdate() then getOnUpdate()(getDb()) end
                end
                local outlineText = ({ [""] = "None", ["OUTLINE"] = "Thin", ["THICKOUTLINE"] = "Thick", ["MONOCHROME"] = "Mono" })
                    [db.outline or "OUTLINE"] or "Thin"
                group.outlineDropdown:SetText(outlineText)
            end

            return group
        end
    else
        -- Fallback: legacy creation path.
        group = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    end

    group:SetSize(groupWidth, groupHeight)

    -- Box appearance (tooltip style)
    group:SetBackdrop(RevUI.TooltipBackdrop)
    group:SetBackdropColor(0, 0, 0, 0.6)
    group:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

    -- Title area
    local header = CreateFrame("Frame", nil, group)
    header:SetSize(groupWidth, 40)
    header:SetPoint("TOPLEFT")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", 15, 0)
    title:SetText(label or "")
    title:SetTextColor(1, 0.82, 0)
    group.labelText = title

    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", 10, 5)
    line:SetPoint("BOTTOMRIGHT", -10, 5)
    line:SetHeight(1)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))

    local content = CreateFrame("Frame", nil, group)
    content:SetSize(groupWidth, groupHeight - 40)
    content:SetPoint("TOPLEFT", 0, -40)
    group.content = content

    local col1, col2, col3 = 15, 275, 535
    local row1, row2, row3 = -25, -95, -165
    local itemW = 225

    -- Store db and onUpdate references so callbacks can be refreshed on reuse.
    group._currentDb = db
    group._currentOnUpdate = onUpdate

    -- [First row]
    local colorBtn = self:CreateColorButton(content, "Color", db, "", true, function()
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    colorBtn:SetPoint("TOPLEFT", col1, row1)
    group.colorBtn = colorBtn

    local sizeSlider = self:CreateSlider(content, itemW, "Size", 4, 100, db.size or 14, 1, nil, function(v)
        getDb().size = v
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    sizeSlider:SetPoint("TOPLEFT", col2, row1)
    group.sizeSlider = sizeSlider

    local shadowCheck = self:CreateCheckbox(content, "Shadow", db.shadow, function(checked)
        getDb().shadow = checked
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    shadowCheck:SetPoint("TOPLEFT", col3, row1 - 5)
    group.shadowCheck = shadowCheck

    -- [Second row]
    local fontDropdown = self:CreateLSMDropdown(content, "font", itemW, "Font", function(key)
        getDb().font = key
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    fontDropdown:SetPoint("TOPLEFT", col1, row2)
    -- [Key] Keep _selectedValue synchronized so radio-button state stays correct.
    if db.font then
        fontDropdown._selectedValue = db.font
        fontDropdown:SetText(db.font)
    end
    group.fontDropdown = fontDropdown

    local xSlider = self:CreateSlider(content, itemW, "X Off", -200, 200, db.x or 0, 1, nil, function(v)
        getDb().x = v
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    xSlider:SetPoint("TOPLEFT", col2, row2)
    group.xSlider = xSlider

    local sxSlider = self:CreateSlider(content, itemW, "Shadow X", -20, 20, db.shadowX or 1, 0.1, nil, function(v)
        getDb().shadowX = v
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    sxSlider:SetPoint("TOPLEFT", col3, row2)
    group.sxSlider = sxSlider

    -- [Third row]
    local outlineItems = { { "None", "" }, { "Thin", "OUTLINE" }, { "Thick", "THICKOUTLINE" }, { "Mono", "MONOCHROME" } }
    local outlineDropdown = self:CreateDropdown(content, itemW, "Outline", outlineItems, db.outline or "OUTLINE",
        function(val)
            getDb().outline = val
            local cb = getOnUpdate()
            if cb then cb(getDb()) end
        end)
    outlineDropdown:SetPoint("TOPLEFT", col1, row3)
    group.outlineDropdown = outlineDropdown

    local ySlider = self:CreateSlider(content, itemW, "Y Off", -200, 200, db.y or 0, 1, nil, function(v)
        getDb().y = v
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    ySlider:SetPoint("TOPLEFT", col2, row3)
    group.ySlider = ySlider

    local sySlider = self:CreateSlider(content, itemW, "Shadow Y", -20, 20, db.shadowY or -1, 0.1, nil, function(v)
        getDb().shadowY = v
        local cb = getOnUpdate()
        if cb then cb(getDb()) end
    end)
    sySlider:SetPoint("TOPLEFT", col3, row3)
    group.sySlider = sySlider

    -- Mark as initialized.
    group._initialized = true

    return group
end

-- =========================================================
-- 12. Sound settings group
-- =========================================================
function RevUI:CreateSoundGroup(parent, width, label, db, key, onUpdate)
    local LSM = LibStub("LibSharedMedia-3.0")
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local groupWidth = width or 750
    local groupHeight = 180

    container:SetSize(groupWidth, groupHeight)
    container:SetBackdrop(RevUI.TooltipBackdrop)
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

    local header = CreateFrame("Frame", nil, container)
    header:SetSize(groupWidth, 40)
    header:SetPoint("TOPLEFT")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", 15, 0)
    title:SetText(label or L["Sound Settings"])
    title:SetTextColor(0, 0.8, 1)
    container.labelText = title

    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", 10, 5)
    line:SetPoint("BOTTOMRIGHT", -10, 5)
    line:SetHeight(1)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))

    local content = CreateFrame("Frame", nil, container)
    content:SetSize(groupWidth, groupHeight - 40)
    content:SetPoint("TOPLEFT", 0, -40)

    local col1, col2 = 15, 385
    local row1, row2 = -25, -95
    local itemW = 350

    local sKey = key .. "Sound"
    local cKey = key .. "Channel"
    local useKey = key .. "UseCustom"
    local pathKey = key .. "CustomPath"

    -- 1. LSM sound picker
    local soundDropdown = RevUI:CreateLSMSoundDropdown(content, itemW, L["Select Sound (LSM)"], db[sKey] or "None", function(val)
        db[sKey] = val
        if onUpdate then onUpdate() end
    end)
    soundDropdown:SetPoint("TOPLEFT", col1, row1 - 10)

    -- 2. Sound channel picker
    local channels = {
        { L["Master"], "Master" },  -- TODO: missing key: L["Master"]
        { L["SFX"], "SFX" },  -- TODO: missing key: L["SFX"]
        { L["Ambience"], "Ambience" },  -- TODO: missing key: L["Ambience"]
        { L["Music"], "Music" },  -- TODO: missing key: L["Music"]
        { L["Dialog"], "Dialog" },  -- TODO: missing key: L["Dialog"]
    }
    local channelDropdown = RevUI:CreateDropdown(content, 180, L["Channel"], channels, db[cKey] or "Master", function(val)  -- TODO: missing key: L["Channel"]
        db[cKey] = val
        if onUpdate then onUpdate() end
    end)
    channelDropdown:SetPoint("TOPLEFT", col2, row1 - 10)

    -- 3. Custom sound toggle and input
    local cbCustom = RevUI:CreateCheckbox(content, L["Use Custom Path"], db[useKey], function(c)
        db[useKey] = c
        if onUpdate then onUpdate() end
    end)
    cbCustom:SetPoint("TOPLEFT", col1, row2 - 10)

    local inputCustom = RevUI:CreateEditBox(
        content,
        db[pathKey] or "",
        groupWidth - 200,
        32,
        "",
        {
            onEnter = function(v)
                db[pathKey] = v
                if onUpdate then onUpdate() end
            end,
            onEditFocusLost = function(v)
                db[pathKey] = v
                if onUpdate then onUpdate() end
            end,
            placeholder = L["Example: Interface\\AddOns\\MySound\\test.ogg"]  -- TODO: missing key: L["Example: Interface\\AddOns\\MySound\\test.ogg"]
        }
    )
    inputCustom:SetPoint("LEFT", cbCustom, "RIGHT", 5, 0)

    return container
end

-- =========================================================
-- [v4.4] Encounter Voice Group (pooled sound settings group)
-- =========================================================
if _G.InfinityFactory and not _G.InfinityFactory.Pools["GridVoiceGroup"] then
    _G.InfinityFactory:InitPool("GridVoiceGroup", "Frame", "BackdropTemplate", function(f)
        f:SetSize(750, 220)
        f._gridType = "GridVoiceGroup"
    end)
    if _G.InfinityFactory.GridTypeMap then
        _G.InfinityFactory.GridTypeMap["voicegroup"] = "GridVoiceGroup"
        _G.InfinityFactory.GridTypeMap["encounter_voice_group"] = "GridVoiceGroup"
    end
end

function RevUI:CreateVoiceGroup(parent, width, labelText, db, key, onUpdate)
    local w = width or 750
    local h = 170

    local FrameFactory = _G.InfinityFactory
    local container

    if FrameFactory then
        container = FrameFactory:Acquire("GridVoiceGroup", parent)
        container:SetSize(w, h)
    else
        container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        container:SetSize(w, h)
    end

    container:SetBackdrop(nil)

    if not container._initialized then
        container.header = CreateFrame("Frame", nil, container)
        container.header:SetSize(w, 1)
        container.header:SetPoint("TOPLEFT")
        container.header:Hide()

        container.title = container.header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        container.title:SetPoint("LEFT", 15, 0)
        container.title:SetTextColor(0, 0.8, 1)

        local line = container.header:CreateTexture(nil, "ARTWORK")
        line:SetPoint("BOTTOMLEFT", 10, 5)
        line:SetPoint("BOTTOMRIGHT", -10, 5)
        line:SetHeight(1)
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))

        container.content = CreateFrame("Frame", nil, container)
        container.content:SetSize(w, h)
        container.content:SetPoint("TOPLEFT", 0, 0)

        container.rows = {}

        local triggerNames = {
            [0] = L["Text Alert"],
            [1] = L["Cast Start"],
            [2] = L["5s Early"]
        }

        local channels = {
            { "Master",   "Master" },
            { "SFX",      "SFX" },
            { "Ambience", "Ambience" },
            { "Music",    "Music" },
            { "Dialog",   "Dialog" },
        }

        local sources = {
            { L["Voice Pack"], "pack" },
            { L["LSM Sound"], "lsm" },
            { L["Custom Path"], "file" }
        }

        local packOptions = {}
        if _G.EXBV_LABELS and type(_G.EXBV_LABELS) == "table" then
            for _, label in ipairs(_G.EXBV_LABELS) do
                if type(label) == "string" and label ~= "" then
                    table.insert(packOptions, { label, label })
                end
            end
        end
        if #packOptions == 0 then
            table.insert(packOptions, { L["Alert"], "Notice" })
        end

        local rowY = -15
        for i = 0, 2 do
            local row = CreateFrame("Frame", nil, container.content)
            row:SetSize(w, 45)
            row:SetPoint("TOPLEFT", 0, rowY)
            rowY = rowY - 50

            local w_chk = 110
            local w_src = 120
            local w_chan = 110
            local w_vol = 140
            local w_dyn = math.max(160, w - w_chk - w_src - w_chan - w_vol - 60)

            local off_chk = -2
            local off_src = off_chk + w_chk
            local off_dyn = off_src + w_src + 15
            local off_chan = off_dyn + w_dyn + 15
            local off_vol = off_chan + w_chan + 15

            local chk = RevUI:CreateCheckbox(row, triggerNames[i], false, function(checked)
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.enabled = checked end
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)
            chk:SetPoint("LEFT", off_chk, 0)

            local srcDrop = RevUI:CreateDropdown(row, w_src, L["Source"], sources, "pack", function(val)
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.sourceType = val end
                row.UpdateDynamicArea(rDb)
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)
            srcDrop:SetPoint("LEFT", off_src, 0)

            local dynArea = CreateFrame("Frame", nil, row)
            dynArea:SetSize(w_dyn, 30)
            dynArea:SetPoint("LEFT", off_dyn, 0)

            local packDrop = RevUI:CreateDropdown(dynArea, w_dyn, "", packOptions, "Notice", function(val)
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.label = val end
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)
            packDrop:SetPoint("LEFT", 0, 0)

            local lsmDrop = RevUI:CreateLSMSoundDropdown(dynArea, w_dyn, "sound", "None", function(val)
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.customLSM = val end
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)
            lsmDrop:SetPoint("LEFT", 0, 0)

            local fileInput = RevUI:CreateEditBox(dynArea, "", w_dyn, 30, "", {})
            fileInput:SetPoint("LEFT", 0, 0)
            fileInput:SetScript("OnEditFocusLost", function(self)
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.customPath = self:GetText() end
                if self:GetText() == "" then self.placeholder:Show() end
                self:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)
            fileInput:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.customPath = self:GetText() end
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)

            row.UpdateDynamicArea = function(t)
                local rDb = t or
                    (container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i])
                if not rDb then return end
                packDrop:Hide()
                lsmDrop:Hide()
                fileInput:Hide()
                if rDb.sourceType == "pack" then
                    packDrop:Show()
                elseif rDb.sourceType == "lsm" then
                    lsmDrop:Show()
                else
                    fileInput:Show()
                end
            end

            local chanDrop = RevUI:CreateDropdown(row, w_chan, L["Channel"], channels, "Master", function(val)
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.channel = val end
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)
            chanDrop:SetPoint("LEFT", off_chan, 0)

            local volSlider = RevUI:CreateSlider(row, w_vol, L["Volume"], 0, 1, 1, 0.1, nil, function(v)
                local rDb = container._currentDb and container._currentDb.triggers and container._currentDb.triggers[i]
                if rDb then rDb.volume = v end
                if container._currentOnUpdate then container._currentOnUpdate(container._currentDb) end
            end)
            volSlider:SetPoint("LEFT", off_vol, 0)

            row.chk = chk
            row.srcDrop = srcDrop
            row.packDrop = packDrop
            row.lsmDrop = lsmDrop
            row.fileInput = fileInput
            row.chanDrop = chanDrop
            row.volSlider = volSlider

            container.rows[i] = row
        end

        container._initialized = true
    end

    container.title:SetText(labelText or L["Voice Settings"])

    if type(db) ~= "table" then return container end
    db.triggers = type(db.triggers) == "table" and db.triggers or {}

    container._currentDb = db
    container._currentOnUpdate = onUpdate

    for i = 0, 2 do
        local r = container.rows[i]
        local t = db.triggers[i]
        if type(t) ~= "table" then
            t = {}
            db.triggers[i] = t
        end

        if not t.sourceType then t.sourceType = "pack" end
        if not t.channel then t.channel = "Master" end
        if not t.volume then t.volume = 1 end

        -- Apply values to Checkbox
        r.chk:SetChecked(t.enabled == true)

        -- Apply values to Source Dropdown
        r.srcDrop._currentValue = t.sourceType
        r.srcDrop:SetText(t.sourceType == "pack" and L["Voice Pack"] or (t.sourceType == "lsm" and L["LSM Sound"] or L["Custom Path"]))

        -- Apply values to Pack Dropdown
        r.packDrop._currentValue = t.label or "Notice"
        r.packDrop:SetText(t.label or "Notice")

        -- Apply values to LSM Dropdown
        r.lsmDrop._selectedValue = t.customLSM or "None"
        r.lsmDrop:SetText(t.customLSM or "None")

        -- Apply values to File Input
        r.fileInput:SetText(t.customPath or "")
        r.fileInput.placeholder:SetText(L["Path..."])
        if t.customPath and t.customPath ~= "" then
            r.fileInput.placeholder:Hide()
        else
            r.fileInput.placeholder:Show()
        end

        -- Apply values to Channel Dropdown
        r.chanDrop._currentValue = t.channel
        r.chanDrop:SetText(t.channel)

        -- Apply values to Volume Slider
        if r.volSlider.Init then r.volSlider:Init(t.volume, 0, 1, 10) end
        if r.volSlider.ValueText then r.volSlider.ValueText:SetText(string.format("%.1f", t.volume)) end

        -- Finally refresh Dynamic Area Visibility
        if r.UpdateDynamicArea then r.UpdateDynamicArea(t) end
    end

    container:Show()
    return container
end

-- =========================================================
-- 13. Edit boxes and multi-line text boxes
-- Options: .bgColor, .borderColor, .textColor
-- =========================================================
function RevUI:CreateEditBox(parent, text, w, h, labelText, options)
    local isMultiLine = h > 40
    options = options or {}

    local FrameFactory = _G.InfinityFactory

    -- [v4.3.2] Single-line mode uses the pooled path.
    if FrameFactory and not isMultiLine then
        local container = FrameFactory:Acquire("GridInput", parent)

        -- Clear old callbacks.
        container:SetScript("OnTextChanged", nil)
        container:SetScript("OnEditFocusLost", nil)
        container:SetScript("OnEnterPressed", nil)

        -- Backward compatibility with the old API.
        container.editBox = container

        -- Base configuration
        container:SetSize(w or 180, h or 28)
        if container.EnableMouse then
            container:EnableMouse(true)
        end
        container:SetAutoFocus(false)
        container:SetText(text or "")

        -- Label configuration
        if labelText then
            local label = container.label
            label:Show()
            label:SetText(labelText)
            label:ClearAllPoints()

            if options.labelPos == "left" then
                label:SetPoint("RIGHT", container, "LEFT", -5, 0)
                label:SetJustifyH("RIGHT")
            else
                label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 3)
                label:SetJustifyH("LEFT")
            end

            -- Font size (correct the default value).
            local font, _, flags = label:GetFont()
            local size = (options.labelSize and tonumber(options.labelSize)) or 14
            label:SetFont(font, size, flags)
        else
            container.label:Hide()
        end

        -- Placeholder
        if not container.placeholder then
            container.placeholder = container:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            container.placeholder:SetPoint("LEFT", 3, 0)
        end
        container.placeholder:SetText(options.placeholder or "")

        local function UpdatePlaceholder()
            if container:GetText() == "" then container.placeholder:Show() else container.placeholder:Hide() end
        end
        UpdatePlaceholder()

        -- Callback logic
        container:SetScript("OnTextChanged", function(self, userInput)
            UpdatePlaceholder()
            if options.onChanged then options.onChanged(self:GetText(), userInput) end
        end)

        container:SetScript("OnEditFocusGained", function(self)
            self:SetBackdropBorderColor(unpack(INFINITY_GUI_ACCENT))
        end)

        container:SetScript("OnEditFocusLost", function(self)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            UpdatePlaceholder()
            if options.onEditFocusLost then options.onEditFocusLost(self:GetText()) end
        end)

        container:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            if options.onEnter then options.onEnter(self:GetText()) end
        end)

        container:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        return container
    end

    -- =========================================================
    -- Multi-line mode or no-factory mode (legacy path)
    -- =========================================================

    -- 1. Main container (tooltip style)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(w, h)
    container:SetBackdrop(RevUI.TooltipBackdrop)
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Simplified label logic.
    if labelText then
        local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        if options.labelPos == "left" then
            label:SetPoint("RIGHT", container, "LEFT", -5, 0)
            label:SetJustifyH("RIGHT")
        else
            label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 3)
        end
        local font, _, flags = label:GetFont()
        local size = (options.labelSize and tonumber(options.labelSize)) or 14
        label:SetFont(font, size, flags)
        label:SetText(labelText)
        container.label = label
    end

    -- Multi-line specific logic: ScrollFrame
    local eb
    local sf = CreateFrame("ScrollFrame", nil, container)
    sf:SetPoint("TOPLEFT", 5, -5)
    sf:SetPoint("BOTTOMRIGHT", -5, 5)

    -- [Fix] Use a container Frame as ScrollChild and place the EditBox inside it.
    -- This gives more precise control over EditBox behavior and avoids odd ScrollFrame constraints on the EditBox.
    local scrollContent = CreateFrame("Frame", nil, sf)
    scrollContent:SetSize(w - 20, 2000) -- Give it a very large height so scrolling is always available.
    sf:SetScrollChild(scrollContent)

    eb = CreateFrame("EditBox", nil, scrollContent)
    eb:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
    eb:SetPoint("TOPRIGHT", scrollContent, "TOPRIGHT", 0, 0)
    eb:SetHeight(2000) -- Make the EditBox equally tall.
    eb:SetMultiLine(true)
    eb:SetTextInsets(4, 4, 4, 4)
    eb:SetJustifyH("LEFT")
    eb:SetJustifyV("TOP") -- Must stay top-aligned.

    -- Auto-scroll logic
    eb:SetScript("OnCursorChanged", function(self, x, y, width, height)
        local vs = sf:GetVerticalScroll()
        local h = sf:GetHeight()
        -- y is a negative value relative to the top of the EditBox.
        local cursorY = -y

        if cursorY < vs then
            sf:SetVerticalScroll(cursorY)
        elseif (cursorY + height) > (vs + h) then
            sf:SetVerticalScroll(cursorY + height - h)
        end
    end)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local new = current - (delta * 20)
        self:SetVerticalScroll(math.max(0, math.min(new, self:GetVerticalScrollRange())))
    end)
    container.scrollFrame = sf

    -- [Fix] Add a click shield so clicking anywhere in the container focuses the EditBox.
    sf:SetScript("OnMouseDown", function() eb:SetFocus() end)

    -- [Fix] Prevent the multi-line edit box from swallowing the mouse wheel: forward scroll input to the parent.
    sf:SetScript("OnMouseWheel", function(self, delta)
        local parentScroll = RevUI.RightScrollFrame
        if parentScroll and parentScroll:IsShown() then
            local current = parentScroll:GetVerticalScroll()
            parentScroll:SetVerticalScroll(current - (delta * 25))
        end
    end)

    eb:SetAutoFocus(false)
    eb:SetText(text or "")
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(8, 8, 8, 8) -- Add padding so the field breathes a bit more.

    -- [Fix] Refresh height to match content so scrollbar logic keeps working.
    eb:SetScript("OnTextChanged", function(self, userInput)
        -- Auto-expand height: use the larger of the visible height and content height.
        local contentH = self:GetNumLetters() * 15 -- Rough estimate, or keep a fixed large height instead.
        -- Better option: avoid auto-resizing and rely only on ScrollFrame. Keep SetSize(..., h) for click behavior.
        if options.onChanged then options.onChanged(self:GetText(), userInput) end
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function() container:SetBackdropBorderColor(unpack(INFINITY_GUI_ACCENT)) end)
    eb:SetScript("OnEditFocusLost", function(self)
        container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        if options.onEditFocusLost then options.onEditFocusLost(self:GetText()) end
    end)

    container.editBox = eb
    function container:GetText() return self.editBox:GetText() end

    function container:SetText(t) self.editBox:SetText(t or "") end

    return container
end

-- =========================================================
-- 14. Interactive preview canvas
-- =========================================================
function RevUI:CreatePreviewCanvas(parent, width, height, elementsData, callbacks)
    local canvas = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    canvas:SetSize(width, height)

    -- Canvas background (grid or dark background)
    canvas:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    canvas:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    canvas:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    -- Grid guide lines (alignment aid)
    local gridLine = canvas:CreateTexture(nil, "BACKGROUND")
    gridLine:SetAllPoints()
    gridLine:SetColorTexture(1, 1, 1, 0.05)

    local centerLineH = canvas:CreateTexture(nil, "ARTWORK")
    centerLineH:SetHeight(1)
    centerLineH:SetPoint("LEFT"); centerLineH:SetPoint("RIGHT")
    centerLineH:SetPoint("CENTER")
    centerLineH:SetColorTexture(1, 1, 1, 0.2)

    local centerLineV = canvas:CreateTexture(nil, "ARTWORK")
    centerLineV:SetWidth(1)
    centerLineV:SetPoint("TOP"); centerLineV:SetPoint("BOTTOM")
    centerLineV:SetPoint("CENTER")
    centerLineV:SetColorTexture(1, 1, 1, 0.2)

    canvas.elements = {}
    canvas.selectedKey = nil

    local onSelect = callbacks and callbacks.onSelect
    local onMove = callbacks and callbacks.onMove

    -- Internal helper: create/update child elements
    function canvas:UpdateElements(dataMap)
        -- 1. Hide all old elements
        for _, el in pairs(self.elements) do el:Hide() end

        -- 2. Walk the data and create/show elements
        for key, data in pairs(dataMap) do
            if data.enabled then
                local el = self.elements[key]
                if not el then
                    el = CreateFrame("Button", nil, self, "BackdropTemplate")
                    el:SetSize(100, 24) -- Default base size.
                    el:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Buttons\\WHITE8X8",
                        edgeSize = 1,
                    })

                    el.text = el:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    el.text:SetPoint("CENTER")

                    -- Drag handling
                    el:SetMovable(true)
                    el:RegisterForDrag("LeftButton")
                    el:SetScript("OnDragStart", function(s)
                        if self.selectedKey ~= key then self:Select(key) end
                        s:StartMoving()
                    end)
                    el:SetScript("OnDragStop", function(s)
                        s:StopMovingOrSizing()
                        local cx, cy = self:GetCenter()
                        local ex, ey = s:GetCenter()

                        if not cx or not ex then return end

                        -- Compute relative coordinates (relative to the canvas center).
                        local relX = ex - cx
                        local relY = ey - cy

                        -- Snap logic (simple rounding).
                        relX = math.floor(relX + 0.5)
                        relY = math.floor(relY + 0.5)

                        s:ClearAllPoints()
                        s:SetPoint("CENTER", self, "CENTER", relX, relY)

                        if onMove then onMove(key, relX, relY) end
                    end)

                    -- Click selection
                    el:SetScript("OnClick", function() self:Select(key) end)

                    self.elements[key] = el
                end

                -- Refresh style and position
                el:Show()
                el.text:SetText(data.label or key)
                el:ClearAllPoints()
                el:SetPoint("CENTER", self, "CENTER", data.x or 0, data.y or 0)

                -- Update appearance based on selection state
                if self.selectedKey == key then
                    el:SetBackdropColor(0, 0.5, 1, 0.6)
                    el:SetBackdropBorderColor(1, 1, 1, 1)
                else
                    el:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
                    el:SetBackdropBorderColor(0, 0, 0, 0)
                end
            end
        end
    end

    function canvas:Select(key)
        self.selectedKey = key
        -- Refresh appearance
        for k, el in pairs(self.elements) do
            if k == key then
                el:SetBackdropColor(0, 0.5, 1, 0.6)
                el:SetBackdropBorderColor(1, 1, 1, 1)
            else
                el:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
                el:SetBackdropBorderColor(0, 0, 0, 0)
            end
        end
        if onSelect then onSelect(key) end
    end

    function canvas:ClearSelection()
        self:Select(nil)
    end

    if elementsData then
        canvas:UpdateElements(elementsData)
    end

    return canvas
end

-- =========================================================
-- 15. Segmented control / tabs
-- items: { {label, value}, ... }
-- =========================================================
function RevUI:CreateSegmentedControl(parent, width, items, currentValue, onChange)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local height = 32
    container:SetSize(width, height)

    -- Capsule background
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    container:SetBackdropColor(0.1, 0.1, 0.1, 1)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    container.buttons = {}

    local numItems = #items
    local btnWidth = (width - 4) / numItems

    for i, item in ipairs(items) do
        local label, value = item[1], item[2]

        local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
        btn:SetSize(btnWidth, height - 4)
        btn:SetPoint("LEFT", container, "LEFT", 2 + (i - 1) * btnWidth, 0)

        -- Selected-state background
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        btn:SetBackdropColor(0, 0, 0, 0) -- Transparent by default.

        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("CENTER")
        text:SetText(label)
        btn.text = text

        btn:SetScript("OnClick", function()
            if currentValue == value then return end
            currentValue = value
            container:Refresh()
            if onChange then onChange(value) end
        end)

        btn.value = value
        container.buttons[i] = btn
    end

    -- Divider line
    for i = 1, numItems - 1 do
        local line = container:CreateTexture(nil, "OVERLAY")
        line:SetSize(1, height - 8)
        line:SetPoint("LEFT", container, "LEFT", 2 + i * btnWidth, 0)
        line:SetColorTexture(0.3, 0.3, 0.3, 1)
    end

    function container:Refresh()
        for _, btn in ipairs(self.buttons) do
            if btn.value == currentValue then
                -- Selected style: highlighted background + bright text
                btn:SetBackdropColor(0.2, 0.4, 0.8, 0.9)
                btn.text:SetTextColor(1, 1, 1)
            else
                -- Unselected style: transparent background + gray text
                btn:SetBackdropColor(0, 0, 0, 0)
                btn.text:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end

    container:Refresh()

    return container
end

-- =========================================================
-- 16. Item config widget
-- Contains: Checkbox + Icon + ItemName + Input(Count) + DeleteBtn
-- Supports item drag-and-drop (OnReceiveDrag).
-- =========================================================
function RevUI:CreateItemConfig(parent, width, height, itemID, db, onChange, onDelete)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local w = width or 320
    local h = height or 40
    container:SetSize(w, h)

    -- Background
    container:SetBackdrop(RevUI.TooltipBackdrop)
    container:SetBackdropColor(0, 0, 0, 0.4)
    container:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5)

    -- 1. Checkbox (enabled/disabled)
    local cb = CreateFrame("CheckButton", nil, container, "MinimalCheckboxTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT", 5, 0)
    cb:SetChecked(db.enabled)
    cb:SetScript("OnClick", function(self)
        db.enabled = self:GetChecked()
        if onChange then onChange(db) end
    end)
    container.checkbox = cb

    -- 2. Item icon
    local iconBtn = CreateFrame("Button", nil, container)
    iconBtn:SetSize(h - 10, h - 10)
    iconBtn:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    local icon = iconBtn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    container.icon = icon

    -- 3. Item name
    local name = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("LEFT", iconBtn, "RIGHT", 8, 0)
    name:SetWidth(w - 140)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    container.nameText = name

    -- Wrapped tooltip logic
    local function ShowTooltip(self)
        if itemID and itemID > 0 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)
            GameTooltip:Show()
        end
    end
    local function HideTooltip() GameTooltip:Hide() end

    -- Item loading logic
    local function UpdateItem(id)
        if not id or id == 0 then
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            name:SetText(L["Drag a consumable here to add"])
            name:SetTextColor(0.5, 0.5, 0.5)
            return
        end
        local itemName, _, quality, _, _, _, _, _, _, texture = C_Item.GetItemInfo(id)
        if itemName then
            icon:SetTexture(texture)
            name:SetText(itemName)
            local r, g, b = GetItemQualityColor(quality or 1)
            name:SetTextColor(r, g, b)
        else
            C_Item.RequestLoadItemDataByID(id)
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            name:SetText(L["Loading..."])  -- TODO: missing key: L["Loading..."]
            C_Timer.After(0.5, function() UpdateItem(id) end)
        end
    end

    -- Event dispatch logic
    local function HandleNewItemID(newID)
        local moduleKey = container.moduleKey
        local elementKey = container.elementKey
        if moduleKey and elementKey then
            InfinityTools:UpdateState(moduleKey .. ".ItemConfigUpdate", { key = elementKey, itemID = newID })
        end
        if onChange then onChange(db, newID) end
    end

    -- Bind interactions to the container so tooltip and drop targets have a larger hit area.
    container:EnableMouse(true)
    container:SetScript("OnEnter", ShowTooltip)
    container:SetScript("OnLeave", HideTooltip)

    container:SetScript("OnReceiveDrag", function()
        local infoType, info1 = GetCursorInfo()
        local id
        if infoType == "item" then
            id = tonumber(info1)
        elseif infoType == "merchant" then
            id = GetMerchantItemID(info1)
        end

        if id then
            ClearCursor()
            UpdateItem(id)
            HandleNewItemID(id)
        end
    end)

    -- Also let the icon button support those interactions because it sits above the container.
    iconBtn:SetScript("OnEnter", ShowTooltip)
    iconBtn:SetScript("OnLeave", HideTooltip)
    iconBtn:RegisterForClicks("LeftButtonUp")
    iconBtn:SetScript("OnClick", function()
        local infoType, info1 = GetCursorInfo()
        local id
        if infoType == "item" then
            id = tonumber(info1)
        elseif infoType == "merchant" then
            id = GetMerchantItemID(info1)
        end

        if id then
            ClearCursor()
            UpdateItem(id)
            HandleNewItemID(id)
        end
    end)

    -- 4. Input box
    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(40, 24)
    editBox:SetPoint("RIGHT", -35, 0)
    editBox:SetBackdrop(RevUI.TooltipBackdrop)
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetText(tostring(db.quantity or 1))
    editBox:SetScript("OnEnterPressed", function(self)
        db.quantity = tonumber(self:GetText()) or 1
        self:ClearFocus()
        if onChange then onChange(db) end
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        db.quantity = tonumber(self:GetText()) or 1
        if onChange then onChange(db) end
    end)
    container.editBox = editBox

    local qtyLabel = container:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    qtyLabel:SetPoint("RIGHT", editBox, "LEFT", -5, 0)
    qtyLabel:SetText(L["Qty"])

    -- 5. Modified delete button
    local delBtn = CreateFrame("Button", nil, container)
    delBtn:SetSize(20, 20)
    delBtn:SetPoint("RIGHT", -5, 0)
    delBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    delBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
    delBtn:SetScript("OnClick", function()
        local moduleKey = container.moduleKey
        local elementKey = container.elementKey
        if moduleKey and elementKey then
            InfinityTools:UpdateState(moduleKey .. ".ItemConfigDelete", { key = elementKey })
        end
        if onDelete and type(onDelete) == "function" then onDelete() end
    end)
    container.delBtn = delBtn
    -- Support either a boolean flag or a callback function.
    if not onDelete then delBtn:Hide() end

    UpdateItem(itemID)
    return container
end

-- =========================================================
-- 12. Glow settings group
-- =========================================================
function RevUI:CreateGlowSettings(parent, width, label, db, key, onUpdate)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local groupWidth = width or 750
    local groupHeight = 280

    container:SetSize(groupWidth, groupHeight)

    -- Box appearance
    container:SetBackdrop(RevUI.TooltipBackdrop)
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

    -- Title area
    local header = CreateFrame("Frame", nil, container)
    header:SetSize(groupWidth, 40)
    header:SetPoint("TOPLEFT")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", 15, 0)
    title:SetText(label or L["Glow Style"])
    title:SetTextColor(1, 0.82, 0)
    container.labelText = title

    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", 10, 5)
    line:SetPoint("BOTTOMRIGHT", -10, 5)
    line:SetHeight(1)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))

    -- Content container
    local content = CreateFrame("Frame", nil, container)
    content:SetSize(groupWidth, groupHeight - 40)
    content:SetPoint("TOPLEFT", 0, -40)

    -- Layout coordinates
    local col1, col2, col3 = 15, 275, 535
    local row1, row2, row3 = -25, -95, -165
    local itemW = 225

    local enableKey = key .. "Enabled"
    if db[enableKey] == nil then db[enableKey] = true end

    local cb = RevUI:CreateCheckbox(content, L["Enable Glow"], db[enableKey], function(checked)
        db[enableKey] = checked
        if onUpdate then onUpdate() end
    end)
    -- Note: CreateCheckbox returns a container, not a plain Button.
    cb:SetPoint("TOPLEFT", col1, row1 - 5)


    -- 1. Style picker (Style Dropdown)
    local styleKey = key .. "Style"
    local styles = {
        { L["Classic"], "Action Button Glow" },
        { L["Pixel"], "Pixel Glow" },
        { L["AutoCast"], "Autocast Shine" },
        { L["Proc"], "Proc Glow" },
    }

    local styleDropdown = RevUI:CreateDropdown(content, itemW, L["Style"], styles, db[styleKey] or "Action Button Glow",
        function(val)
            db[styleKey] = val
            container:RefreshLayout()
            if onUpdate then onUpdate() end
        end)
    styleDropdown:SetPoint("TOPLEFT", col2, row1 - 10)

    -- 2. Color picker
    local colorBtn = RevUI:CreateColorButton(content, L["Glow Color"], db, key .. "Color", true, function()
        if onUpdate then onUpdate() end
    end)
    -- Color button matches generic button height
    colorBtn:SetPoint("TOPLEFT", col3, row1 - 10)

    -- 3. Sliders
    local sliders = {}
    local function CreateGlowSlider(sLabel, sKey, min, max, step, def)
        local itemKey = key .. sKey
        local s = RevUI:CreateSlider(content, itemW, sLabel, min, max, db[itemKey] or def, step, nil, function(v)
            db[itemKey] = v
            if onUpdate then onUpdate() end
        end)
        return s
    end

    sliders.Frequency = CreateGlowSlider(L["Frequency"], "Frequency", 0.1, 5, 0.1, 0.25)
    sliders.Lines = CreateGlowSlider(L["Lines"], "Lines", 1, 30, 1, 8)
    sliders.Scale = CreateGlowSlider(L["Scale"], "Scale", 0.5, 3, 0.1, 1)  -- TODO: missing key: L["Scale"]
    sliders.Offset = CreateGlowSlider(L["Offset"], "Offset", -50, 50, 1, 0)
    if db[key .. "Offset"] == nil then db[key .. "Offset"] = 0 end

    container.Sliders = sliders

    function container:RefreshLayout()
        local style = db[styleKey] or "Action Button Glow"

        if style == "Proc Glow" then colorBtn:Hide() else colorBtn:Show() end

        for _, s in pairs(sliders) do s:Hide() end

        -- Row 2 placement
        if style == "Action Button Glow" then
            sliders.Frequency:Show(); sliders.Frequency.Title:SetText(L["Blink Speed"]); sliders.Frequency:SetPoint("TOPLEFT", col1,
                row2)
        elseif style == "Pixel Glow" then
            sliders.Frequency:Show(); sliders.Frequency.Title:SetText(L["Flow Speed"]); sliders.Frequency:SetPoint("TOPLEFT", col1,
                row2)
            sliders.Lines:Show(); sliders.Lines.Title:SetText(L["Line Count"]); sliders.Lines:SetPoint("TOPLEFT", col2, row2)
            sliders.Scale:Show(); sliders.Scale.Title:SetText(L["Line Width"]); sliders.Scale:SetPoint("TOPLEFT", col3, row2)
        elseif style == "Autocast Shine" then
            sliders.Frequency:Show(); sliders.Frequency.Title:SetText(L["Blink Speed"]); sliders.Frequency:SetPoint("TOPLEFT", col1,
                row2)
            sliders.Lines:Show(); sliders.Lines.Title:SetText(L["Particles"]); sliders.Lines:SetPoint("TOPLEFT", col2, row2)
            sliders.Scale:Show(); sliders.Scale.Title:SetText(L["Particle Size"]); sliders.Scale:SetPoint("TOPLEFT", col3, row2)
        end

        -- Row 3 placement (Offset)
        if style ~= "Proc Glow" then
            sliders.Offset:Show(); sliders.Offset:SetPoint("TOPLEFT", col1, row3)
        end
    end

    container:RefreshLayout()
    return container
end

-- =========================================================
-- 17. Icon settings group
-- =========================================================
function RevUI:CreateIconGroup(parent, width, label, db, key, onUpdate)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local groupWidth = width or 750
    local groupHeight = 280

    -- [Key Fix] Fetch the nested subtable and initialize it if missing.
    if key and not db[key] then db[key] = {} end
    local iconDb = key and db[key] or db

    container:SetSize(groupWidth, groupHeight)

    -- Box appearance
    container:SetBackdrop(RevUI.TooltipBackdrop)
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

    -- Title area
    local header = CreateFrame("Frame", nil, container)
    header:SetSize(groupWidth, 40)
    header:SetPoint("TOPLEFT")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", 15, 0)
    title:SetText(label or L["Icon Settings"])
    title:SetTextColor(1, 0.82, 0)
    container.labelText = title

    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", 10, 5)
    line:SetPoint("BOTTOMRIGHT", -10, 5)
    line:SetHeight(1)
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))

    -- Content container
    local content = CreateFrame("Frame", nil, container)
    content:SetSize(groupWidth, groupHeight - 40)
    content:SetPoint("TOPLEFT", 0, -40)

    -- Layout coordinates
    local col1, col2, col3 = 15, 275, 535
    local row1, row2, row3 = -25, -95, -165
    local itemW = 225

    -- Row 1: IconID Input, Show Checkbox, Reverse Checkbox

    -- 1. Show icon (Checkbox) -> Col 1
    local cbShow = RevUI:CreateCheckbox(content, L["Show Icon"], iconDb.showIcon, function(c)
        iconDb.showIcon = c
        if onUpdate then onUpdate() end
    end)
    cbShow:SetPoint("TOPLEFT", col1, row1 - 5)

    -- 2. Icon ID (IconID Input) -> Col 2
    local inputIcon = RevUI:CreateEditBox(
        content,
        tostring(iconDb.iconID or ""),
        itemW,
        32,
        L["Icon ID (optional)"],
        {
            onEnter = function(v)
                iconDb.iconID = tonumber(v) or nil
                if onUpdate then onUpdate() end
            end,
            onEditFocusLost = function(v)
                iconDb.iconID = tonumber(v) or nil
                if onUpdate then onUpdate() end
            end,
            labelPos = "top"
        }
    )
    inputIcon:SetPoint("TOPLEFT", col2, row1 - 10)

    -- 3. Reverse countdown (Checkbox) -> Col 3
    local cbRev = RevUI:CreateCheckbox(content, L["Reverse CD"], iconDb.reverse, function(c)
        iconDb.reverse = c
        if onUpdate then onUpdate() end
    end)
    cbRev:SetPoint("TOPLEFT", col3, row1 - 5)

    -- Row 2: Width, Height

    -- 4. Width (Slider) -> Col 1
    local sWidth = RevUI:CreateSlider(content, itemW, L["Width"], 10, 300, iconDb.width or 64, 1, nil, function(v)  -- TODO: missing key: L["Width"]
        iconDb.width = v
        if onUpdate then onUpdate() end
    end)
    sWidth:SetPoint("TOPLEFT", col1, row2)

    -- 5. Height (Slider) -> Col 2
    local sHeight = RevUI:CreateSlider(content, itemW, L["Height"], 10, 300, iconDb.height or 64, 1, nil, function(v)  -- TODO: missing key: L["Height"]
        iconDb.height = v
        if onUpdate then onUpdate() end
    end)
    sHeight:SetPoint("TOPLEFT", col2, row2)

    -- Row 3: X, Y Offset
    -- 6. X offset (Slider) -> Col 1
    local sPosX = RevUI:CreateSlider(content, itemW, L["Horizontal Offset (X)"], -1000, 1000, iconDb.x or 0, 1, nil, function(v)
        iconDb.x = v
        if onUpdate then onUpdate() end
    end)
    sPosX:SetPoint("TOPLEFT", col1, row3)

    -- 7. Y offset (Slider) -> Col 2
    local sPosY = RevUI:CreateSlider(content, itemW, L["Vertical Offset (Y)"], -1000, 1000, iconDb.y or 0, 1, nil, function(v)
        iconDb.y = v
        if onUpdate then onUpdate() end
    end)
    sPosY:SetPoint("TOPLEFT", col2, row3)

    return container
end

-- =========================================================
-- 18. Timer bar settings group
-- [User Request] Wrap a full settings group covering size, texture, color, and icon.
-- =========================================================
function RevUI:CreateTimerBarGroup(parent, width, label, db, key, onUpdate)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    local groupWidth = width or 750
    local groupHeight = 440 -- [Style] Increased height to accommodate border settings and separators.

    container:SetSize(groupWidth, groupHeight)
    container:SetBackdrop(RevUI.TooltipBackdrop)
    container:SetBackdropColor(0, 0, 0, 0.6)
    container:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

    -- Header
    local header = CreateFrame("Frame", nil, container)
    header:SetSize(groupWidth, 40); header:SetPoint("TOPLEFT")
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("LEFT", 15, 0); title:SetText(label or L["Timer Bar Settings"]); title:SetTextColor(1, 0.82, 0)
    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", 10, 5); line:SetPoint("BOTTOMRIGHT", -10, 5)
    line:SetHeight(1); line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.5), CreateColor(1, 1, 1, 0.05))

    local content = CreateFrame("Frame", nil, container)
    content:SetSize(groupWidth, groupHeight - 40); content:SetPoint("TOPLEFT", 0, -40)

    local col1, col2, col3 = 15, 275, 535
    -- [Style] Add a border row and adjust vertical spacing.
    local row1, row2 = -25, -75
    local div1 = -120
    local row3, row4 = -140, -190
    local div2 = -235
    local row5, row6 = -255, -305
    local itemW = 220

    local function AddDivider(y, text)
        local d = content:CreateTexture(nil, "ARTWORK")
        d:SetPoint("TOPLEFT", 10, y)
        d:SetPoint("TOPRIGHT", -10, y)
        d:SetHeight(1)
        d:SetTexture("Interface\\Buttons\\WHITE8X8")
        d:SetColorTexture(1, 1, 1, 0.1)
        if text then
            local t = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            t:SetPoint("BOTTOMLEFT", d, "TOPLEFT", 5, 2)
            t:SetText(text)
        end
    end

    -- Helper for Slider
    local function AddSlider(lbl, k, min, max, step, c, r, def)
        local val = db[k]
        if val == nil then val = def or min end
        local s = RevUI:CreateSlider(content, itemW, lbl, min, max, val, step, nil, function(v)
            db[k] = v; if onUpdate then onUpdate() end
        end)
        s:SetPoint("TOPLEFT", c, r)
    end

    -- Row 1: Width, Height
    AddSlider(L["Width"], "width", 50, 500, 1, col1, row1, 200)
    AddSlider(L["Height"], "height", 10, 100, 1, col2, row1, 20)

    -- Row 2: Texture, FG, BG
    -- If db.texture does not exist in LSM (for example SharedMedia is missing), correct it to "Solid" and notify the module immediately.
    if db.texture and not LSM:HashTable("statusbar")[db.texture] then
        db.texture = LSM:HashTable("statusbar")["Solid"] and "Solid" or LSM:GetDefault("statusbar")
        if onUpdate then onUpdate() end
    end
    local texDrop = RevUI:CreateLSMTextureDropdown(content, "statusbar", itemW, L["Texture"], db.texture, function(k)
        db.texture = k; if onUpdate then onUpdate() end
    end)
    texDrop:SetPoint("TOPLEFT", col1, row2)

    local fgBtn = RevUI:CreateColorButton(content, L["Foreground"], db, "barColor", true, onUpdate)
    fgBtn:SetPoint("TOPLEFT", col2, row2)

    local bgBtn = RevUI:CreateColorButton(content, L["Background"], db, "barBgColor", true, onUpdate)
    bgBtn:SetPoint("TOPLEFT", col3, row2)

    AddDivider(div1, L["Border"])

    -- Row 3: Border settings
    local cbShowBorder = RevUI:CreateCheckbox(content, L["Enable Border"], db.showBorder, function(v)
        db.showBorder = v; if onUpdate then onUpdate() end
    end)
    cbShowBorder:SetPoint("TOPLEFT", col1, row3)

    local borderDrop = RevUI:CreateLSMTextureDropdown(content, "border", itemW, L["Border Texture"], db.borderTexture or "None",
        function(k)
            db.borderTexture = k; if onUpdate then onUpdate() end
        end)
    borderDrop:SetPoint("TOPLEFT", col2, row3)

    local borderBtn = RevUI:CreateColorButton(content, L["Border Color"], db, "borderColor", true, onUpdate)
    borderBtn:SetPoint("TOPLEFT", col3, row3)

    -- Row 4: Border Size and Padding
    AddSlider(L["Border Size"], "borderSize", 1, 32, 1, col1, row4, 12)
    AddSlider(L["Padding"], "borderPadding", -16, 16, 1, col2, row4, 0)

    AddDivider(div2, L["Icon Settings"])

    -- Row 5: Icon Show, Side, Size
    local cbShow = RevUI:CreateCheckbox(content, L["Show Icon"], db.showIcon, function(v)
        db.showIcon = v; if onUpdate then onUpdate() end
    end)
    cbShow:SetPoint("TOPLEFT", col1, row5)

    local sideOpts = { { L["Left"], "LEFT" }, { L["Right"], "RIGHT" } }  -- TODO: missing key: L["Left"]
    local sideDrop = RevUI:CreateDropdown(content, itemW, L["Icon Side"], sideOpts, db.iconSide or "LEFT", function(v)
        db.iconSide = v; if onUpdate then onUpdate() end
    end)
    sideDrop:SetPoint("TOPLEFT", col2, row5)
    if sideDrop.Label then sideDrop.Label:SetJustifyH("CENTER") end

    AddSlider(L["Icon Size"], "iconSize", 8, 100, 1, col3, row5, 30)

    -- Row 6: Offset X, Y
    AddSlider(L["Icon X"], "iconOffsetX", -100, 100, 1, col1, row6, 0)
    AddSlider(L["Icon Y"], "iconOffsetY", -100, 100, 1, col2, row6, 0)

    return container
end
