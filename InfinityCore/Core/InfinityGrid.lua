-- =========================================================
-- InfinityGrid.lua - visual grid layout engine (v4.2 enhanced)
-- =========================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then
    error("[InfinityGrid] Error: InfinityTools.lua must load before InfinityGrid.lua!")
end

-- Ensure the RevUI namespace exists (it may load before InfinityToolsUI.lua)
local RevUI = InfinityTools.UI or {}
InfinityTools.UI = RevUI

local Grid = {
    Cols = 50,
    CellSize = 0,
    Padding = 2,
    ActiveLayout = {},
    Widgets = {},
    IsLiveEditing = false,
    ContainerCols = setmetatable({}, { __mode = "k" }),
    ContainerStates = setmetatable({}, { __mode = "k" }),
    _effectiveCols = 50,
}

-- Mount in multiple locations for easier access
InfinityTools.Grid = Grid
RevUI.Grid = Grid
_G.InfinityGrid = Grid

local function NormalizeCols(cols)
    local n = tonumber(cols)
    if not n then return nil end
    n = math.floor(n)
    if n < 10 then n = 10 end
    if n > 200 then n = 200 end
    return n
end

local function GetContainerState(self, container)
    if not container then return nil end
    local state = self.ContainerStates[container]
    if not state then
        state = {
            widgets = {},
            widgetMap = {},
            layout = nil,
            config = nil,
            moduleKey = nil,
        }
        self.ContainerStates[container] = state
    end
    return state
end

local function ActivateContainerState(self, container, state)
    if not container or not state then return end
    self._activeContainer = container
    self.Widgets = state.widgets
    self.WidgetMap = state.widgetMap
    self.ActiveLayout = state.layout or {}
    self.LastConfig = state.config
    self.ModuleKey = state.moduleKey
end

function Grid:SetContainerCols(container, cols)
    if not container then return false end
    local n = NormalizeCols(cols)
    if not n then
        self.ContainerCols[container] = nil
        return false
    end
    self.ContainerCols[container] = n
    return true
end

function Grid:ClearContainerCols(container)
    if not container then return end
    self.ContainerCols[container] = nil
end

function Grid:GetContainerCols(container)
    if not container then return nil end
    return self.ContainerCols[container]
end

function Grid:UpdateMetrics(containerWidth, container)
    local cols = self:GetContainerCols(container) or self.Cols
    self._effectiveCols = cols
    self.CellSize = (containerWidth - 20) / cols
end

function Grid:GetPixelRect(x, y, w, h)
    local px = (x - 1) * self.CellSize + 10
    local py = -(y - 1) * self.CellSize - 10
    local pw = w * self.CellSize - self.Padding
    local ph = (h or 2) * self.CellSize - self.Padding
    return px, py, pw, ph
end

function Grid:GetGridPos(lx, ly)
    local gx = math.floor((lx - 5) / self.CellSize) + 1
    local gy = math.floor((math.abs(ly) - 5) / self.CellSize) + 1
    local cols = self._effectiveCols or self.Cols
    return math.max(1, math.min(gx, cols)), math.max(1, gy)
end

function Grid:IsAreaEmpty(x, y, w, h, excludeKey, layout)
    -- [v2.0] Support passing a specific layout subset (used for internal TableGroup layout checks)
    -- But since v2.0 uses absolute coordinates, global checks are still more correct
    -- This may still need adjustment for editor-specific logic
    local targetLayout = layout or self.ActiveLayout

    -- Recursive collision-check helper
    local function checkRecursive(items)
        for _, item in ipairs(items) do
            if item.key ~= excludeKey then
                -- Core rule: all widgets use absolute coordinates at runtime (item.x, item.y)
                -- So comparing coordinates directly is enough; hierarchy does not matter here
                if not (x + w <= item.x or x >= item.x + item.w or
                        y + (h or 2) <= item.y or y >= item.y + (item.h or 2)) then
                    return false
                end

                -- If this is a TableGroup, recursively check its child elements
                if item.children then
                    if not checkRecursive(item.children) then return false end
                end
            end
        end
        return true
    end

    if layout then
        -- If a subset was provided, only check that subset (usually for local reflow)
        return checkRecursive(layout)
    else
        -- By default, check all elements globally
        return checkRecursive(self.ActiveLayout)
    end
end

-- [Core] Forward-declare helpers for ValidateContext
local function GetConfigPath(config, path)
    if not config or not path then return config end
    local keys = { strsplit(".", path) }
    local curr = config
    for i = 1, #keys do
        local k = tonumber(keys[i]) or keys[i]
        if type(curr) ~= "table" then return nil end
        curr = curr[k]
    end
    return curr
end

-- [v2.0 New] Data validity checks
function Grid:ValidateContext(config, contextPath)
    if not contextPath or contextPath == "" then return true end
    local data = GetConfigPath(config, contextPath)
    return (data ~= nil)
end

-- [v2.0 New] Recursive rendering core
function Grid:RenderItems(container, items, contextPath, config, moduleKey)
    for _, item in ipairs(items) do
        -- 1. Compute the absolute data path for the current widget (scoped context)
        local currentPath = contextPath
        if item.parentKey then
            if currentPath then
                currentPath = currentPath .. "." .. item.parentKey
            else
                currentPath = item.parentKey
            end
        end

        -- 2. Data-validity circuit breaker
        -- If the current path is invalid (for example rows.5 was deleted), skip rendering or fall back
        if currentPath and not self:ValidateContext(config, currentPath) then

        else
            if item.type == "TableGroup" then
                -- [Logical container mode]
                -- Header/Label rendering (if present)
                if item.label then
                    -- The TableGroup itself exists as a Label/Header widget
                    self:CreateWidget(container, item, config, moduleKey, currentPath)
                end

                -- Recursively render child elements
                -- Key point: container stays unchanged (MainFrame) while a new ContextPath is passed down
                if item.children then
                    self:RenderItems(container, item.children, currentPath, config, moduleKey)
                end
            else
                -- [Regular widget]
                -- Use the computed absolute path for data binding
                -- Pass currentPath to CreateWidget; it will be used as fullKey
                self:CreateWidget(container, item, config, moduleKey, currentPath)
            end
        end
    end
end

function Grid:Render(container, layoutData, config, moduleKey, onFinished)
    if not container or not layoutData then return end

    if type(config) == "string" then
        moduleKey = config
        config = InfinityTools:GetModuleDB(moduleKey)
    end

    local state = GetContainerState(self, container)
    state.layout = layoutData
    state.config = config
    state.moduleKey = moduleKey
    ActivateContainerState(self, container, state)

    self:UpdateMetrics(container:GetWidth(), container)

    -- [v4.3.1] Only return old widgets for the current container, avoiding cross-panel cleanup
    local FrameFactory = _G.InfinityFactory
    for k, w in pairs(self.Widgets) do
        if FrameFactory and w._gridType then
            FrameFactory:ReleaseGridWidget(w)
        else
            -- Fallback: old logic
            w:Hide()
            w:SetParent(nil)
        end
    end
    table.wipe(self.Widgets)

    -- [v4.3 Fix] Clear the reverse index for the current container to avoid stale references
    table.wipe(self.WidgetMap)

    -- [v2.0] Start recursive rendering
    self:RenderItems(container, layoutData, nil, config, moduleKey)

    -- Compute the maximum height (requires recursive traversal of all elements)
    local maxH = 1
    local function findMaxH(items)
        for _, ele in ipairs(items) do
            if ele.y then
                maxH = math.max(maxH, ele.y + (ele.h or 2))
            end
            if ele.children then findMaxH(ele.children) end
        end
    end
    findMaxH(layoutData)

    container:SetHeight(maxH * self.CellSize + 80)

    if onFinished then onFinished() end
end

-- (GetConfigPath moved to top)

local function GetConfigValue(config, ele)
    if not config then return nil end

    local curr = config
    if ele.parentKey then
        curr = GetConfigPath(config, ele.parentKey)
    end

    if not curr or type(curr) ~= "table" then return nil end

    -- [Core] setKey has the highest priority and separates GridKey from DBKey
    if ele.setKey then
        local sk = tonumber(ele.setKey) or ele.setKey
        return curr[sk]
    end

    -- [v4.3.2 Fix] subKey has higher priority than ele.key
    -- Example: parentKey="current", subKey="iconSize" -> reads config.current.iconSize
    -- ele.key (for example "current_iconSize") is only used as the Grid widget identifier and is not part of the data path
    if ele.subKey then
        local sk = tonumber(ele.subKey) or ele.subKey
        return curr[sk]
    end

    local key = ele.key
    local numKey = tonumber(key)
    local finalKey = numKey or key

    return curr[finalKey]
end

-- [v4.3.1] Recursively find layout items
local function FindLayoutItem(items, key)
    for _, item in ipairs(items) do
        if item.key == key then return item end
        if item.children then
            local found = FindLayoutItem(item.children, key)
            if found then return found end
        end
    end
    return nil
end

local function BindTooltip(target, ele, enableMouse)
    if not target or not target.SetScript then
        return
    end
    if ele.tooltip or ele.spellID then
        if enableMouse and target.EnableMouse then
            target:EnableMouse(true)
        end
        target:SetScript("OnEnter", function(self)
            _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if ele.spellID then
                _G.GameTooltip:SetSpellByID(ele.spellID)
            elseif ele.tooltip then
                _G.GameTooltip:SetText(ele.tooltip, 1, 1, 1, 1, true)
            end
            _G.GameTooltip:Show()
        end)
        target:SetScript("OnLeave", function()
            _G.GameTooltip:Hide()
        end)
    else
        if enableMouse and target.EnableMouse then
            target:EnableMouse(false)
        end
        target:SetScript("OnEnter", nil)
        target:SetScript("OnLeave", nil)
    end
end


local function SetConfigValue(config, ele, val, moduleKey, fullKey)
    if not config then return end

    -- [Core] setKey has the highest priority (force global/local override)
    if ele.setKey then
        local sk = tonumber(ele.setKey) or ele.setKey
        config[sk] = val
        InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
            { key = ele.setKey, gridKey = ele.key, value = val, ts = GetTime() })
        return
    end

    -- Parse the path and assign the value
    local finalPath = fullKey
    if finalPath then
        local parts = { strsplit(".", finalPath) }
        local ptr = config
        for i = 1, #parts - 1 do
            local k = tonumber(parts[i]) or parts[i]
            if not ptr[k] then ptr[k] = {} end
            ptr = ptr[k]
        end
        local lastKey = tonumber(parts[#parts]) or parts[#parts]
        ptr[lastKey] = val
    else
        local fk = tonumber(ele.key) or ele.key
        config[fk] = val
    end

    -- Notify updates
    InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
        { key = ele.key, fullPath = fullKey, value = val, ts = GetTime() })
end

function Grid:CreateWidget(container, ele, config, moduleKey, contextPath)
    -- [v4.3.2] Build the full data path for the current widget
    -- Key point: when subKey exists, use subKey as the data key (ele.key is only the Grid widget identifier)
    local fullPath
    local dataKey = ele.subKey or ele.key -- subKey has higher priority than key

    if contextPath then
        fullPath = contextPath .. "." .. dataKey
    else
        if ele.parentKey then
            fullPath = ele.parentKey .. "." .. dataKey
        else
            fullPath = tostring(dataKey)
        end
    end

    local px, py, pw, ph = self:GetPixelRect(ele.x, ele.y, ele.w, ele.h)
    local widget

    -- [v4.3.2] Get value: setKey takes highest priority, then use the constructed fullPath
    local curVal
    if ele.setKey then
        curVal = config[ele.setKey]
    else
        curVal = GetConfigPath(config, fullPath)
    end

    -- Closure helper
    local function Setter(v)
        SetConfigValue(config, ele, v, moduleKey, fullPath)
    end

    -- ... (Create Logic) ...
    if ele.type == "header" then
        local text = ele.label
        if type(text) == "function" then text = text() end
        widget = RevUI:CreateHeader(container, text or "", pw)
    elseif ele.type == "subheader" then
        local text = ele.label
        if type(text) == "function" then text = text() end

        -- [v4.3.1] Acquire from pool
        local FrameFactory = _G.InfinityFactory
        if FrameFactory then
            widget = FrameFactory:Acquire("GridSubheader", container)
        else
            widget = CreateFrame("Frame", nil, container)
            widget.text = widget:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            widget.text:SetAllPoints()
            widget.text:SetJustifyH("LEFT")
        end
        widget.text:SetText(text or "")
        widget.labelText = widget.text -- Compatibility alias
    elseif ele.type == "divider" then
        -- [v4.3.1] Acquire from pool
        local FrameFactory = _G.InfinityFactory
        if FrameFactory then
            widget = FrameFactory:Acquire("GridDivider", container)
        else
            widget = CreateFrame("Frame", nil, container)
            local l = RevUI:CreateSeparator(widget, pw)
            l:SetPoint("CENTER")
            widget.line = l
        end
        -- Remove the incorrect SetBackdrop call; this widget should remain fully transparent
    elseif ele.type == "button" then
        widget = RevUI:CreateButton(container, pw, ph, ele.label, function()
            if ele.func then ele.func() end
            if ele.key and moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".ButtonClicked",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "picbutton" then
        local nTex, pTex = ele.iconNormal, ele.iconPushed
        if ele.atlas then
            nTex = ele.atlas .. "_Normal"; pTex = ele.atlas .. "_Pushed"
        end
        widget = RevUI:CreatePicButton(container, pw, ph, nTex, pTex, ele.iconHighlight, function()
            if ele.key and moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".ButtonClicked",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "checkbox" then
        widget = RevUI:CreateCheckbox(container, ele.label, curVal == true, function(v)
            Setter(v == true)
        end)
    elseif ele.type == "slider" then
        widget = RevUI:CreateSlider(container, pw, ele.label, ele.min or 0, ele.max or 100, curVal or 0, ele.step or 1,
            nil, Setter)
    elseif ele.type == "input" then
        widget = RevUI:CreateEditBox(container, curVal or "", pw, ph, ele.label, {
            onChanged = nil,
            onEnter = Setter,
            onEditFocusLost = Setter,
            labelPos = ele.labelPos,
            labelSize = ele.labelSize
        })
    elseif ele.type == "color" then
        local subConfig = config
        if contextPath then
            subConfig = GetConfigPath(config, contextPath) or config
        end
        widget = RevUI:CreateColorButton(container, ele.label, subConfig, ele.key, true, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "label" or ele.type == "description" then
        local text = ele.label
        if type(text) == "function" then text = text() end

        -- [v4.3.1] Acquire from pool
        local FrameFactory = _G.InfinityFactory
        if FrameFactory then
            widget = FrameFactory:Acquire("GridDescription", container)
        else
            widget = CreateFrame("Frame", nil, container)
            local fs = widget:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetAllPoints()
            fs:SetJustifyH("LEFT")
            widget.text = fs
        end

        widget.text:SetText(text or "")
        if ele.type == "description" then
            widget.text:SetTextColor(1, 1, 1, 1)
        end
        widget.labelText = widget.text -- Compatibility alias

        -- [v4.3.13] Support tooltips
        BindTooltip(widget, ele, true)
    elseif ele.type == "dropdown" then
        local rawItems = ele.items
        local itemsList = {}

        if type(rawItems) == "string" and rawItems:sub(1, 5) == "func:" then
            local funcPath = rawItems:match("func:(.+%(%))") or rawItems:sub(6)
            funcPath = funcPath:gsub("%(%)", "")
            local func = _G
            for part in string.gmatch(funcPath, "([^%.]+)") do
                if func then func = func[part] else break end
            end
            local dynamicData = (type(func) == "function" and func()) or "Run_Time_Generated"
            if type(dynamicData) == "table" then
                itemsList = dynamicData
            else
                for s in string.gmatch(dynamicData, "([^,]+)") do table.insert(itemsList, s) end
            end
        else
            if type(rawItems) == "table" then
                itemsList = rawItems
            elseif type(rawItems) == "string" then
                for s in string.gmatch(rawItems, "([^,]+)") do table.insert(itemsList, s) end
            end
        end

        widget = RevUI:CreateDropdown(container, pw, ele.label, itemsList, curVal, Setter)
    elseif ele.type == "multiselect" then
        local itemsList = {}
        -- (Complex items logic omitted for brevity, use existing)
        local rawItems = ele.items
        if type(rawItems) == "string" and rawItems:sub(1, 5) == "func:" then
            local funcPath = rawItems:match("func:(.+%(%))") or rawItems:sub(6)
            funcPath = funcPath:gsub("%(%)", "") -- clean ()
            local func = _G
            for part in string.gmatch(funcPath, "([^%.]+)") do
                if func then func = func[part] else break end
            end
            local dynamicStr = (type(func) == "function" and func()) or "Run_Time_Generated"
            for s in string.gmatch(dynamicStr, "([^,]+)") do table.insert(itemsList, s) end
        else
            if type(rawItems) == "table" then
                itemsList = rawItems
            elseif type(rawItems) == "string" then
                for s in string.gmatch(rawItems, "([^,]+)") do table.insert(itemsList, s) end
            end
        end

        if not curVal then
            SetConfigValue(config, ele, {}, moduleKey, fullPath); curVal = GetConfigPath(config, fullPath)
        end
        -- Multiselect callbacks are special: they do not need a direct value and instead trigger StateUpdate when internal state changes
        widget = RevUI:CreateMultiSelectDropdown(container, pw, ele.label, itemsList, curVal, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "itemconfig" then
        local itemID = tonumber(ele.itemID) or (curVal and curVal.id) or 0
        local widgetSize = ele.labelSize or ele.size or 18
        widget = RevUI:CreateItemConfig(container, pw, ph, itemID, curVal or { enabled = true, quantity = 1 },
            function(newDB, newItemID)
                if newItemID and ele.onDragUpdate then
                    ele.onDragUpdate(newItemID)
                else
                    Setter(newDB)
                end
            end,
            ele.canDelete
        )
        widget.moduleKey = moduleKey
        widget.elementKey = ele.key
        if widget.nameText then
            widget.nameText:SetFontObject("GameFontNormalLarge")
        end
        if widget.editBox then
            widget.editBox:SetFontObject("ChatFontNormal")
        end
    elseif ele.type == "lsm_font" then
        widget = RevUI:CreateLSMDropdown(container, "font", pw, ele.label, curVal, Setter)
    elseif ele.type == "lsm_sound" then
        widget = RevUI:CreateLSMSoundDropdown(container, pw, ele.label, curVal, Setter)
    elseif ele.type == "lsm_texture" then
        widget = RevUI:CreateLSMTextureDropdown(container, "statusbar", pw, ele.label, curVal, Setter)
    elseif ele.type == "lsm_border" then
        widget = RevUI:CreateLSMTextureDropdown(container, "border", pw, ele.label, curVal, Setter)
    elseif ele.type == "lsm_background" then
        widget = RevUI:CreateLSMTextureDropdown(container, "background", pw, ele.label, curVal, Setter)
    elseif ele.type == "fontgroup" then
        if not curVal then
            local defaultFontTable = { font = "Friz Quadrata TT", size = 14, r = 1, g = 1, b = 1, a = 1, outline = "", shadow = false, x = 0, y = 0 }
            Setter(defaultFontTable)
            curVal = defaultFontTable
        end
        widget = RevUI:CreateFontGroup(container, pw, ele.label, curVal, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "glow_settings" then
        local subConfig = config
        if contextPath then
            subConfig = GetConfigPath(config, contextPath) or config
        end
        widget = RevUI:CreateGlowSettings(container, pw, ele.label, subConfig, ele.key, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "icongroup" then
        local subConfig = config
        if contextPath then
            subConfig = GetConfigPath(config, contextPath) or config
        end
        widget = RevUI:CreateIconGroup(container, pw, ele.label, subConfig, ele.key, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "soundgroup" then
        local subConfig = config
        if contextPath then
            subConfig = GetConfigPath(config, contextPath) or config
        end
        widget = RevUI:CreateSoundGroup(container, pw, ele.label, subConfig, ele.key, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "timerBarGroup" or ele.type == "timerbargroup" then
        if not curVal then
            local defaultTimerTable = {
                width = 240,
                height = 24,
                texture = "Clean",
                barColorR = 1,
                barColorG = 0.7,
                barColorB = 0,
                barColorA = 1,
                barBgColorR = 0,
                barBgColorG = 0,
                barBgColorB = 0,
                barBgColorA = 0.5,
                showIcon = true,
                iconSide = "LEFT",
                iconSize = 24,
                iconOffsetX = -5,
                iconOffsetY = 0
            }
            Setter(defaultTimerTable)
            curVal = defaultTimerTable
        end
        widget = RevUI:CreateTimerBarGroup(container, pw, ele.label, curVal, nil, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    elseif ele.type == "voicegroup" or ele.type == "encounter_voice_group" then
        local subConfig = config
        if contextPath then
            subConfig = GetConfigPath(config, contextPath) or config
        end
        widget = RevUI:CreateVoiceGroup(container, pw, ele.label, subConfig, ele.key, function()
            if moduleKey then
                InfinityTools:UpdateState(moduleKey .. ".DatabaseChanged",
                    { key = ele.key, fullPath = fullPath, ts = GetTime() })
            end
        end)
    end

    if widget then
        widget:SetParent(container)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", container, "TOPLEFT", px, py)

        widget:SetSize(pw, ph)

        if ele.type == "checkbox" then
            if widget.EnableMouse then
                widget:EnableMouse(false)
            end
            widget:SetScript("OnEnter", nil)
            widget:SetScript("OnLeave", nil)
            if widget.checkbox then
                if widget.checkbox.EnableMouse then
                    widget.checkbox:EnableMouse(true)
                end
                widget.checkbox:SetScript("OnEnter", nil)
                widget.checkbox:SetScript("OnLeave", nil)
                widget.checkbox:SetScript("PreClick", nil)
                widget.checkbox:SetScript("PostClick", nil)
            end
        end

        widget:Show()
        -- [v4.3.1] Map to the pool type
        local FrameFactory = _G.InfinityFactory
        if FrameFactory and FrameFactory.GridTypeMap then
            widget._gridType = FrameFactory.GridTypeMap[ele.type] or ele.type
        else
            widget._gridType = ele.type
        end
        self.Widgets[ele.key] = widget

        -- [v2.0] Register reverse index
        -- Instead of storing only the key in the Widgets table, keep all metadata here
        -- Core reason: editor interactions (dragging) need to read this information
        if not self.WidgetMap then self.WidgetMap = {} end
        -- [v4.3 Fix] Remove the parentContainer reference to avoid memory leaks from cyclic references
        -- All widgets live under the same container, so storing it separately is unnecessary
        self.WidgetMap[widget] = {
            item = ele,     -- Layout item reference
            path = fullPath -- Full data path
        }

        RevUI:UpdateLabelStyle(widget, ele.labelSize, ele.labelPos)

        if self.IsLiveEditing then self:WrapWidgetForEdit(widget, ele.key, container) end
    end

    return widget
end

function Grid:ToggleLiveEdit(container)
    if container then
        local state = GetContainerState(self, container)
        ActivateContainerState(self, container, state)
    end
    self.IsLiveEditing = not self.IsLiveEditing
    self.LiveContainer = container

    if self.IsLiveEditing then
        if container then
            self._activeContainer = container
            self:UpdateMetrics(container:GetWidth(), container)
        end
        self:DrawEditorGrid(container)
        self:DrawRowGuides(container) -- Draw row guides

        for k, w in pairs(self.Widgets) do self:WrapWidgetForEdit(w, k, container) end
        self:ShowToolbar(); self:ShowPalette(); self:CreatePropertyPanel()

        print("|cff00ffff[InfinityGrid]|r Edit mode enabled. Click row numbers on the left to manage rows.")
    else
        if self.GridLines then for _, l in ipairs(self.GridLines) do l:Hide() end end
        if self.RowGuides then for _, b in ipairs(self.RowGuides) do b:Hide() end end -- Hide row guides

        -- Restore container state
        if container then
            container:EnableMouse(false)
            -- Clear scripts just in case
            if container.SetScript then
            end
        end

        for _, w in pairs(self.Widgets) do if w.dragOverlay then w.dragOverlay:Hide() end end
        if self.LiveToolbar then self.LiveToolbar:Hide() end
        if self.Palette then self.Palette:Hide() end
        if self.PropPanel then self.PropPanel:Hide() end
    end
end

function Grid:ShiftRows(startY, delta)
    for _, item in ipairs(self.ActiveLayout) do
        if item.y >= startY then
            item.y = item.y + delta
        end
    end
    -- Fix possible negative y values
    for _, item in ipairs(self.ActiveLayout) do
        if item.y < 1 then item.y = 1 end
    end
    self:Render(self.LiveContainer, self.ActiveLayout, self.LastConfig, self.ModuleKey)
end

function Grid:ShowRowContextMenu(row, x, y)
    if not self.ContextMenu then
        local cm = CreateFrame("Frame", "InfinityGridContextMenu", UIParent, "BackdropTemplate")
        cm:SetSize(140, 75)
        cm:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        cm:SetBackdropColor(0.05, 0.05, 0.1, 0.95)

        -- Keep a high frame level so it stays above any other frame
        cm:SetFrameStrata("TOOLTIP")
        cm:SetFrameLevel(9500)

        local function CreateMenuBtn(text, parent, yOff)
            local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            btn:SetSize(125, 26)
            btn:SetPoint("TOP", 0, yOff)
            btn:SetText(text)
            return btn
        end

        cm.InsertBtn = CreateMenuBtn("Insert Row", cm, -10)
        cm.InsertBtn:SetScript("OnClick", function()
            local targetRow = Grid.ContextMenu.targetRow
            Grid:ShiftRows(targetRow, 1)
            Grid.ContextMenu:Hide()
            if Grid.MenuCloser then Grid.MenuCloser:Hide() end
        end)

        cm.DeleteBtn = CreateMenuBtn("Delete Row", cm, -38)
        cm.DeleteBtn:SetScript("OnClick", function()
            local targetRow = Grid.ContextMenu.targetRow
            Grid:ShiftRows(targetRow + 1, -1)
            Grid.ContextMenu:Hide()
            if Grid.MenuCloser then Grid.MenuCloser:Hide() end
        end)

        self.ContextMenu = cm
    end

    self.ContextMenu.targetRow = row
    self.ContextMenu:ClearAllPoints()
    self.ContextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    self.ContextMenu:Show()

    if not self.MenuCloser then
        self.MenuCloser = CreateFrame("Button", nil, UIParent)
        self.MenuCloser:SetAllPoints()
        self.MenuCloser:SetFrameStrata("FULLSCREEN_DIALOG")
        self.MenuCloser:SetFrameLevel(9000)
        self.MenuCloser:SetScript("OnClick", function(f)
            f:Hide()
            Grid.ContextMenu:Hide()
        end)
    end
    self.MenuCloser:SetFrameLevel(9000)
    self.ContextMenu:SetFrameLevel(9500)

    self.MenuCloser:Show()
end

function Grid:WrapWidgetForEdit(widget, key, container)
    local drag = widget.dragOverlay or CreateFrame("Button", nil, widget, "BackdropTemplate")
    drag:SetAllPoints(); drag:SetFrameLevel(widget:GetFrameLevel() + 20); drag:EnableMouse(true)
    drag:RegisterForClicks("LeftButtonUp", "RightButtonUp"); drag:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); drag
        :SetBackdropColor(0, 0.5, 1, 0.15); drag:Show(); widget.dragOverlay = drag
    if widget.SetMovable then widget:SetMovable(true) end
    drag:SetScript("OnMouseDown",
        function(f, b)
            if b == "LeftButton" then
                widget:StartMoving(); widget.isDragging = true
            end
        end)
    drag:SetScript("OnMouseUp", function(f, b)
        if b == "RightButton" then
            Grid:ShowPropertyPanelFor(key); return
        end
        if widget.isDragging then
            widget:StopMovingOrSizing(); widget.isDragging = false
            local lx, ly = widget:GetLeft() - container:GetLeft(), widget:GetTop() - container:GetTop()
            local nx, ny = Grid:GetGridPos(lx + 2, ly - 2)

            -- [v2.0 Fix] Use the reverse index to find the LayoutItem instead of iterating ActiveLayout
            -- This allows even deeply nested TableGroup children to update position correctly
            if Grid.WidgetMap and Grid.WidgetMap[widget] then
                local meta = Grid.WidgetMap[widget]
                local item = meta.item

                -- Detect collisions
                -- Strictly speaking, IsAreaEmpty should check globally to prevent overlap
                if Grid:IsAreaEmpty(nx, ny, item.w, item.h, item.key) then -- Temporarily check globally here
                    item.x, item.y = nx, ny
                end

                -- Refresh
                Grid:Render(container, Grid.ActiveLayout, Grid.LastConfig, Grid.ModuleKey)
            end
        end
    end)

    -- [Resizer] Bottom-right resize handle
    if not drag.resizer then
        local r = CreateFrame("Button", nil, drag)
        r:SetSize(12, 12)
        r:SetPoint("BOTTOMRIGHT", 0, 0)
        local t = r:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints(); t:SetColorTexture(1, 1, 0, 0.5)
        r:SetScript("OnMouseDown", function()
            drag.isResizing = true
            r:SetScript("OnUpdate", function()
                local mx, my = GetCursorPosition()
                local s = widget:GetEffectiveScale()
                mx, my = mx / s, my / s
                local wx, wy = widget:GetLeft(), widget:GetTop()
                local newW = (mx - wx) + 5
                local newH = (wy - my) + 5

                -- [Fix] Resize the widget live to provide visual feedback
                widget:SetSize(math.max(10, newW), math.max(10, newH))

                -- Optional: show a tooltip with the current Grid size
                local gw = math.max(1, math.floor(newW / Grid.CellSize + 0.5))
                local gh = math.max(1, math.floor(newH / Grid.CellSize + 0.5))
                GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
                GameTooltip:SetText(string.format("W: %d  H: %d", gw, gh))
                GameTooltip:Show()
            end)
        end)
        drag.resizer = r
        r:SetScript("OnMouseUp", function()
            if drag.isResizing then
                drag.isResizing = false
                r:SetScript("OnUpdate", nil)
                GameTooltip:Hide()

                local mx, my = GetCursorPosition()
                local s = widget:GetEffectiveScale()
                mx, my = mx / s, my / s
                local wx, wy = widget:GetLeft(), widget:GetTop()

                -- Calculate new Width/Height in Grid Units
                local gw = math.max(1, math.floor(((mx - wx) + 10) / Grid.CellSize))
                local gh = math.max(1, math.floor(((wy - my) + 10) / Grid.CellSize))

                -- Update using Reverse Index
                if Grid.WidgetMap and Grid.WidgetMap[widget] then
                    local meta = Grid.WidgetMap[widget]
                    local item = meta.item
                    if Grid:IsAreaEmpty(item.x, item.y, gw, gh, item.key) then
                        item.w, item.h = gw, gh
                    end
                    Grid:Render(container, Grid.ActiveLayout, Grid.LastConfig, Grid.ModuleKey)
                end
            end
        end)
    end
    drag.resizer:Show()
end

-- [Added] Draw Excel-style row numbers on the left side
function Grid:DrawRowGuides(container)
    if not self.RowGuides then self.RowGuides = {} end
    -- Hide old ones first
    for _, b in ipairs(self.RowGuides) do b:Hide() end

    local rowsToDraw = 100 -- Draw 100 rows by default; extend if needed

    for i = 1, rowsToDraw do
        local btn = self.RowGuides[i]
        if not btn then
            -- Use a Button template; it supports OnClick natively and avoids error risk
            btn = CreateFrame("Button", nil, container, "BackdropTemplate")
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8) -- Dark gray background
            btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.3)
            btn:RegisterForClicks("RightButtonUp")   -- Right-click is enough here

            -- Row number text
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.text:SetPoint("CENTER", 0, 0)

            self.RowGuides[i] = btn
        end

        -- Update to match the current parent (container)
        btn:SetParent(container)
        btn:SetSize(20, self.CellSize) -- Slightly narrower to reduce occlusion
        -- Position: x = 0 (inside the left side of the canvas), y = the matching rows grid y
        -- Grid y formula: -(y-1)*CellSize - 10
        local py = -(i - 1) * self.CellSize - 10
        btn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, py)

        btn.text:SetText(i)

        -- Interaction logic
        btn:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                -- Open menu
                local mx, my = GetCursorPosition()
                local s = self:GetEffectiveScale()
                mx, my = mx / s, my / s
                Grid:ShowRowContextMenu(i, mx, my)
            end
        end)

        -- Mouse hover color-change effect
        btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0, 0.6, 1, 0.8) end)
        btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.2, 0.2, 0.8) end)

        btn:Show()
    end
end

-- [v4.3.2] Unified physical pixel line-width calculation (based on Blizzard source)
local function SetupLineThickness(line, pixelWidth)
    local scale = line:GetEffectiveScale()
    if _G.PixelUtil and _G.PixelUtil.GetNearestPixelSize then
        line:SetThickness(_G.PixelUtil.GetNearestPixelSize(pixelWidth, scale, pixelWidth))
    else
        line:SetThickness(pixelWidth)
    end
end

function Grid:DrawEditorGrid(canvas)
    if not self.GridLines then self.GridLines = {} end
    -- Clear old lines first (Line and Texture are different object types, so they must be fully reset)
    for _, l in ipairs(self.GridLines) do
        if l.Hide then l:Hide() end
    end

    local idx = 1
    local linePixelWidth = 1.2 -- Slightly thicker for visibility
    local gridAlpha = 0.15     -- More visible on dark backgrounds

    -- Draw vertical lines
    for i = 0, self.Cols do
        local l = self.GridLines[idx]
        if not l or (l.GetObjectType and l:GetObjectType() ~= "Line") then
            l = canvas:CreateLine(nil, "BACKGROUND")
            self.GridLines[idx] = l
        end

        l:SetColorTexture(1, 1, 1, gridAlpha)
        -- [Fix] Explicitly pass canvas as the anchor target to prevent coordinate drift
        l:SetStartPoint("TOPLEFT", canvas, 10 + i * self.CellSize, 0)
        l:SetEndPoint("BOTTOMLEFT", canvas, 10 + i * self.CellSize, -3000)
        SetupLineThickness(l, linePixelWidth)
        l:Show()
        idx = idx + 1
    end

    -- Draw horizontal lines
    for i = 0, 150 do
        local l = self.GridLines[idx]
        if not l or (l.GetObjectType and l:GetObjectType() ~= "Line") then
            l = canvas:CreateLine(nil, "BACKGROUND")
            self.GridLines[idx] = l
        end

        l:SetColorTexture(1, 1, 1, gridAlpha)
        -- [Fix] Explicitly pass canvas as the anchor target
        l:SetStartPoint("TOPLEFT", canvas, 0, -10 - i * self.CellSize)
        l:SetEndPoint("TOPRIGHT", canvas, 0, -10 - i * self.CellSize)
        SetupLineThickness(l, linePixelWidth)
        l:Show()
        idx = idx + 1
    end
end

function Grid:ShowToolbar()
    if self.LiveToolbar then
        self.LiveToolbar:Show(); return
    end
    local tb = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    tb:SetSize(500, 44)
    tb:SetPoint("TOP", 0, -10)
    tb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    tb:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    tb:SetFrameStrata("HIGH")

    local b1 = CreateFrame("Button", nil, tb, "UIPanelButtonTemplate")
    b1:SetSize(100, 28); b1:SetPoint("LEFT", 10, 0); b1:SetText("Export Layout")
    b1:SetScript("OnClick", function() Grid:ExportLayoutOnly() end)

    local b1b = CreateFrame("Button", nil, tb, "UIPanelButtonTemplate")
    b1b:SetSize(100, 28); b1b:SetPoint("LEFT", 115, 0); b1b:SetText("Export Defaults")
    b1b:SetScript("OnClick", function() Grid:ExportDefaultsOnly() end)

    local b2 = CreateFrame("Button", nil, tb, "UIPanelButtonTemplate")
    b2:SetSize(100, 28); b2:SetPoint("LEFT", 220, 0); b2:SetText("Save & Exit")
    b2:SetScript("OnClick", function() Grid:ToggleLiveEdit(Grid.LiveContainer) end)

    local b3 = CreateFrame("Button", nil, tb, "UIPanelButtonTemplate")
    b3:SetSize(100, 28); b3:SetPoint("LEFT", 325, 0); b3:SetText("Widget Library")
    b3:SetScript("OnClick",
        function() if Grid.Palette:IsShown() then Grid.Palette:Hide() else Grid.Palette:Show() end end)

    self.LiveToolbar = tb
end

function Grid:ShowPalette()
    if self.Palette then
        self.Palette:Show(); return
    end
    local p = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"); p:SetSize(160, 500); p:SetPoint("RIGHT", -20, 0); p
        :SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }); p
        :SetBackdropColor(0.1, 0.1, 0.1, 0.95); p:SetFrameStrata("HIGH"); p:EnableMouse(true); p:SetMovable(true); p
        :RegisterForDrag("LeftButton"); p:SetScript("OnDragStart", p.StartMoving); p:SetScript("OnDragStop",
        p.StopMovingOrSizing)
    local types = {
        { t = "checkbox", n = "Checkbox" }, { t = "button", n = "Button" }, { t = "slider", n = "Slider" }, { t = "input", n = "Input" },
        { t = "header", n = "Header" }, { t = "subheader", n = "Subheader" }, { t = "divider", n = "Divider" },
        { t = "label", n = "Label" }, { t = "description", n = "Description" }, { t = "color", n = "Color" },
        { t = "dropdown", n = "Dropdown" }, { t = "multiselect", n = "Multi-Select" },
        { t = "lsm_font", n = "LSM Font" }, { t = "lsm_sound", n = "LSM Sound" },
        { t = "lsm_texture", n = "LSM Texture" }, { t = "lsm_border", n = "LSM Border" }, { t = "lsm_background", n = "LSM Background" },
        { t = "fontgroup", n = "Font Group" }
    }
    local y = -15
    for _, i in ipairs(types) do
        local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate"); b:SetSize(140, 24); b:SetPoint("TOP", 0, y); b
            :SetText(i.n); b:SetScript("OnClick", function() Grid:AddNewWidget(i.t, Grid.LiveContainer) end)
        y = y - 28
    end
    self.Palette = p
end

function Grid:AddNewWidget(t, c)
    local k = t .. "_" .. math.random(1000, 9999); local w, h = 12, 2
    if t == "checkbox" then
        w, h = 2, 2
    elseif t:find("header") or t == "divider" then
        w, h = 47, 1
    elseif t == "fontgroup" then
        w, h =
            47, 10
    end
    local e = { key = k, type = t, x = 1, y = 1, w = w, h = h, label = "New Widget" }
    if t == "slider" then
        e.min = 0; e.max = 100
    elseif t:find("dropdown") or t == "multiselect" then
        e.items = "A,B,C"
    end
    for i = 1, 200 do
        if Grid:IsAreaEmpty(1, i, w, h) then
            e.y = i; table.insert(Grid.ActiveLayout, e); break
        end
    end
    Grid:Render(c, Grid.ActiveLayout, Grid.LastConfig, Grid.ModuleKey)
end

function Grid:CreatePropertyPanel()
    if self.PropPanel then return end
    local p = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"); p:SetSize(320, 680); p:SetPoint("LEFT", 20, 0); p
        :SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }); p
        :SetBackdropColor(0.05, 0.05, 0.1, 0.98); p:SetFrameStrata("DIALOG"); p:EnableMouse(true); p:SetMovable(true); p
        :RegisterForDrag("LeftButton"); p:SetScript("OnDragStart", p.StartMoving); p:SetScript("OnDragStop",
        p.StopMovingOrSizing)
    local function CI(l, y)
        local f = CreateFrame("Frame", nil, p); f:SetSize(280, 50); f:SetPoint("TOPLEFT", 20, y)
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); fs:SetPoint("TOPLEFT", 0, 0); fs
            :SetText(l)
        local eb = RevUI:CreateEditBox(f, "", 280, 26); eb:SetPoint("TOPLEFT", 0, -18); f.eb = eb; f.fs = fs; return f
    end

    -- [UI Polish] Reduce vertical spacing (from 60px -> 50px) to pull bottom content upward
    p.k = CI("Unique Key (Grid ID):", -40)
    p.sk = CI("DB Key (setKey, optional):", -90)
    p.l = CI("Display Label:", -140)
    p.w = CI("Width (1-50):", -190); p.h = CI("Height:", -240)
    p.i = CI("Options (comma-separated):", -290)
    p.min = CI("Slider Min:", -340); p.max = CI("Slider Max:", -390)

    -- [New] Label position and size (the whole block is now shifted upward by about 100px)
    p.lpos = CI("Label Pos (left / top...):", -440)
    p.lsize = CI("Label Size (10-30):", -490)

    -- [Core] Switch to real-time interaction mode: hide the input box
    p.lpos.eb:Hide(); p.lsize.eb:Hide()

    -- [New] Label size slider (applies in real time)
    p.lsize.slider = RevUI:CreateSlider(p.lsize, 260, nil, 10, 32, 16, 1, nil, function(v)
        local e = Grid.Cur
        if e then
            e.labelSize = v
            p.lsize.fs:SetText("Label Size: " .. v)
            if Grid.Widgets[e.key] then
                -- [Real-time] Update styling immediately
                RevUI:UpdateLabelStyle(Grid.Widgets[e.key], e.labelSize, e.labelPos)
            end
        end
    end)
    p.lsize.slider:SetPoint("TOPLEFT", 0, -20) -- Slightly align to the left

    -- Label-position toggle button (applies in real time)
    local function CreatePosBtn(txt, val, x)
        local b = CreateFrame("Button", nil, p.lpos, "UIPanelButtonTemplate")
        b:SetSize(60, 22)
        -- Place directly below the label
        b:SetPoint("TOPLEFT", x, -18)
        b:SetText(txt)
        b:SetScript("OnClick", function()
            local e = Grid.Cur
            if e then
                e.labelPos = val
                -- [Real-time] Update styling immediately
                if Grid.Widgets[e.key] then
                    RevUI:UpdateLabelStyle(Grid.Widgets[e.key], e.labelSize, e.labelPos)
                end
            end
        end)
        return b
    end
    p.lpos.b1 = CreatePosBtn("Left", "left", 0)
    p.lpos.b2 = CreatePosBtn("Top", "top", 70)
    p.lpos.b3 = CreatePosBtn("Right", "right", 140)
    p.lpos.b4 = CreatePosBtn("Default", nil, 210); p.lpos.b4:SetWidth(60)

    local s = CreateFrame("Button", nil, p, "UIPanelButtonTemplate"); s:SetSize(130, 32); s:SetPoint("BOTTOMLEFT", 20, 20); s
        :SetText("Save Settings"); s:SetScript("OnClick", function()
        local e = Grid.Cur; if e then
            e.key = p.k.eb:GetText();
            -- [New] Save setKey
            local sk = p.sk.eb:GetText()
            e.setKey = (sk ~= "" and sk) or nil

            -- [Fix] Convert escaped pipes from the UI back to normal pipes before storing
            e.label = p.l.eb:GetText():gsub("||", "|");
            e.w = tonumber(p.w.eb:GetText()) or e.w;
            e.h = tonumber(p.h.eb:GetText()) or e.h;
            if e.type == "slider" then
                e.min = tonumber(p.min.eb:GetText());
                e.max = tonumber(p.max.eb:GetText())
                -- [Revert] Remove step-saving logic
            end
            if p.i:IsShown() then
                local rawItems = p.i.eb:GetText():gsub("||", "|")
                if type(e.items) == "table" then
                    -- Table-style dropdown items are used for structured options; the property panel only displays them here and does not downgrade them to strings
                else
                    e.items = rawItems
                end
            end

            -- [Core] Label properties are already updated into e by live controls; do not overwrite them here from the hidden EditBox
        end
        p:Hide(); Grid:Render(Grid.LiveContainer, Grid.ActiveLayout, Grid.LastConfig, Grid.ModuleKey)
    end)


    local d = CreateFrame("Button", nil, p, "UIPanelButtonTemplate"); d:SetSize(130, 32); d:SetPoint("BOTTOMRIGHT", -20,
        20); d:SetText("|cffff0000Delete Widget|r"); d:SetScript("OnClick", function()
        for i, e in ipairs(Grid.ActiveLayout) do
            if e.key == Grid.Cur.key then
                table.remove(Grid.ActiveLayout, i); break
            end
        end
        p:Hide(); Grid:Render(Grid.LiveContainer, Grid.ActiveLayout, Grid.LastConfig, Grid.ModuleKey)
    end)
    self.PropPanel = p
end

function Grid:ShowPropertyPanelFor(key)
    if not self.IsLiveEditing then return end

    -- [v4.3.1] Recursive lookup with TableGroup child support
    local item = FindLayoutItem(self.ActiveLayout, key)
    if not item then
        print("[InfinityGrid] Error: widget config not found: " .. key); return
    end

    local panel = self.PropPanel
    if not panel then
        self:CreatePropertyPanel(); panel = self.PropPanel
    end
    Grid.Cur = item

    -- [Fix] Use double-pipe escaping to stop the UI engine from rendering icon markup directly inside the EditBox
    panel.k.eb:SetText(item.key or "")
    panel.sk.eb:SetText(item.setKey or item.subKey or "")
    panel.l.eb:SetText((item.label or ""):gsub("|", "||"))
    panel.w.eb:SetText(tostring(item.w or 10))
    panel.h.eb:SetText(tostring(item.h or 2))

    panel.i:Hide(); panel.min:Hide(); panel.max:Hide()
    if item.type:find("dropdown") or item.type == "multiselect" then
        panel.i:Show()
        local itemsText = ""
        if type(item.items) == "string" then
            itemsText = item.items
        elseif type(item.items) == "table" then
            local parts = {}
            for _, entry in ipairs(item.items) do
                if type(entry) == "table" then
                    local label = tostring(entry[1] or "")
                    local value = tostring(entry[2] or entry[1] or "")
                    if value ~= "" and value ~= label then
                        parts[#parts + 1] = label .. "=" .. value
                    else
                        parts[#parts + 1] = label
                    end
                else
                    parts[#parts + 1] = tostring(entry)
                end
            end
            itemsText = table.concat(parts, ", ")
        end
        panel.i.eb:SetText(itemsText:gsub("|", "||"))
    end
    if item.type == "slider" then
        panel.min:Show(); panel.max:Show()
        panel.min.eb:SetText(tostring(item.min or 0))
        panel.max.eb:SetText(tostring(item.max or 100))
    end

    -- [New] Backfill the state of live controls
    if panel.lsize and panel.lsize.slider then
        panel.lsize.slider:SetValue(item.labelSize or 16)
        panel.lsize.fs:SetText("Label Size: " .. (item.labelSize or 16))
    end
    -- The LabelPos button does not need state backfill; clicking it applies immediately

    panel:Raise()
    panel:Show()
end

function Grid:ExportLayout()
    local layoutStr = "local layout = {\n"
    local defaults = {}

    local replacements = self.ExportReplacements or {}

    -- Helper: format a value
    local function formatVal(val, keyName)
        if type(val) == "string" and replacements[val] then
            return ", " .. keyName .. " = " .. replacements[val]
        else
            return ", " .. keyName .. " = " .. string.format("%q", val)
        end
    end

    -- Recursive export core
    local function recursiveExport(items, indent, contextPath)
        local str = ""
        local pad = string.rep("    ", indent)

        for _, e in ipairs(items) do
            -- 1. Determine the data context for the current widget
            local itemScope = contextPath
            if e.parentKey then
                itemScope = itemScope and (itemScope .. "." .. e.parentKey) or e.parentKey
            end
            local fullPath = itemScope and (itemScope .. "." .. e.key) or tostring(e.key)

            -- 2. Build the exported property string
            local ex = ""
            if e.min then ex = ex .. ", min = " .. e.min end; if e.max then ex = ex .. ", max = " .. e.max end

            if e.items and e.items ~= "" then
                if replacements[e.items] then
                    ex = ex .. ", items = " .. replacements[e.items]
                elseif type(e.items) == "string" and e.items:sub(1, 5) == "func:" then
                    ex = ex .. ", items = " .. string.format("%q", e.items)
                elseif type(e.items) == "table" then
                    local function serializeTable(t)
                        local s = "{"
                        for k, v in ipairs(t) do
                            if type(v) == "table" then
                                s = s .. serializeTable(v)
                            else
                                s = s .. string.format("%q", v)
                            end
                            if k < #t then s = s .. ", " end
                        end
                        return s .. "}"
                    end
                    ex = ex .. ", items = " .. serializeTable(e.items)
                else
                    ex = ex .. ", items = " .. string.format("%q", e.items)
                end
            end

            if e.parentKey then ex = ex .. formatVal(e.parentKey, "parentKey") end
            if e.setKey then ex = ex .. formatVal(e.setKey, "setKey") end
            if e.subKey then ex = ex .. formatVal(e.subKey, "subKey") end
            if e.labelPos then ex = ex .. ", labelPos = " .. string.format("%q", e.labelPos) end
            if e.labelSize and e.labelSize ~= 16 then ex = ex .. ", labelSize = " .. e.labelSize end

            local labelStr = ""
            local exportLabel = e.baseLabel or e.label
            if type(exportLabel) == "string" then
                labelStr = string.format(", label = %q", exportLabel)
            elseif type(exportLabel) == "number" then
                labelStr = string.format(", label = %q", tostring(exportLabel))
            else
                labelStr = ", label = \"--[[ Function ]]\""
            end

            local keyExport = (type(e.key) == "number") and tostring(e.key) or string.format("%q", tostring(e.key))

            -- 3. Collect default values (core update: full collection and color handling)
            local function AddToDefaults(path, val)
                if val == nil then return end
                local pathKeys = { strsplit(".", tostring(path)) }
                local ptr = defaults
                for i = 1, #pathKeys - 1 do
                    local k = tonumber(pathKeys[i]) or pathKeys[i]
                    if not ptr[k] then ptr[k] = {} end
                    ptr = ptr[k]
                end
                local lastK = tonumber(pathKeys[#pathKeys]) or pathKeys[#pathKeys]
                ptr[lastK] = val
            end

            local keyStr = tostring(e.key)
            if keyStr and not keyStr:find("^header") and not keyStr:find("^divider") and e.type ~= "TableGroup" then
                -- Special handling for color widgets: export suffix format (xxxR, xxxG, xxxB, xxxA)
                if e.type == "color" then
                    local colorConfig = contextPath and GetConfigPath(self.LastConfig, contextPath) or self.LastConfig
                    if colorConfig then
                        local colorKey = tostring(e.key)
                        local basePath = contextPath and (contextPath .. ".") or ""
                        AddToDefaults(basePath .. colorKey .. "R", colorConfig[colorKey .. "R"] or 1)
                        AddToDefaults(basePath .. colorKey .. "G", colorConfig[colorKey .. "G"] or 1)
                        AddToDefaults(basePath .. colorKey .. "B", colorConfig[colorKey .. "B"] or 1)
                        AddToDefaults(basePath .. colorKey .. "A", colorConfig[colorKey .. "A"] or 1)
                    end
                else
                    AddToDefaults(e.setKey or fullPath,
                        (e.setKey and self.LastConfig[e.setKey]) or GetConfigPath(self.LastConfig, fullPath))
                end
            end

            -- 4. Handle recursion and dynamic-list completion
            if e.type == "TableGroup" then
                if e.children and #e.children > 0 then
                    -- Dynamic index probing: if the current path is rows.1, scan rows.2, 3... to complete the defaults table
                    local prefix, idx = tostring(e.parentKey):match("^(.-)%.(%d+)$")
                    if prefix and idx then
                        local collection = GetConfigPath(self.LastConfig, prefix)
                        if type(collection) == "table" then
                            for i in pairs(collection) do recursiveExport(e.children, indent + 1, prefix .. "." .. i) end
                        end
                    end
                    str = str ..
                        string.format(
                            "%s{ key = %s, type = %q, x = %d, y = %d, w = %d, h = %d%s%s, children = {\n%s%s} },\n",
                            pad, keyExport, e.type, e.x, e.y, e.w, e.h, labelStr, ex,
                            recursiveExport(e.children, indent + 1, itemScope), pad)
                end
            else
                str = str ..
                    string.format("%s{ key = %s, type = %q, x = %d, y = %d, w = %d, h = %d%s%s },\n", pad, keyExport,
                        e.type,
                        e.x, e.y, e.w, e.h, labelStr, ex)
            end
        end
        return str
    end

    layoutStr = layoutStr .. recursiveExport(self.ActiveLayout, 1, nil)
    layoutStr = layoutStr .. "}\n"

    -- Automatically add required top-level fields (such as pos)
    if self.LastConfig and self.LastConfig.pos and not defaults.pos then
        defaults.pos = self.LastConfig.pos
    end

    return layoutStr, defaults
end

-- Serialize a table into a Lua code string
local function serializeTable(t, indent)
    local s = "{\n"

    -- Detect whether this is a contiguous array
    local isArray = true
    local maxIndex = 0
    for k, _ in pairs(t) do
        if type(k) == "number" and k > 0 and math.floor(k) == k then
            if k > maxIndex then maxIndex = k end
        else
            isArray = false
            break
        end
    end
    if isArray and maxIndex > 0 then
        for i = 1, maxIndex do
            if t[i] == nil then
                isArray = false; break
            end
        end
    end

    if isArray and maxIndex > 0 then
        -- Contiguous array: use implicit indexes
        for i = 1, maxIndex do
            local v = t[i]
            s = s .. string.rep("    ", indent)
            if type(v) == "table" then
                s = s .. serializeTable(v, indent + 1) .. ",\n"
            elseif type(v) == "string" then
                s = s .. string.format("%q", v) .. ",\n"
            else
                s = s .. tostring(v) .. ",\n"
            end
        end
    else
        -- Non-contiguous table: use explicit keys
        local keys = {}
        for k in pairs(t) do table.insert(keys, k) end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

        for _, k in ipairs(keys) do
            local v = t[k]
            local keyStr
            if type(k) == "number" then
                keyStr = "[" .. k .. "]"
            elseif type(k) == "string" and k:match("^[%a_][%w_]*$") then
                keyStr = k
            else
                keyStr = "[" .. string.format("%q", k) .. "]"
            end
            s = s .. string.rep("    ", indent) .. keyStr .. " = "
            if type(v) == "table" then
                s = s .. serializeTable(v, indent + 1) .. ",\n"
            elseif type(v) == "string" then
                s = s .. string.format("%q", v) .. ",\n"
            else
                s = s .. tostring(v) .. ",\n"
            end
        end
    end
    return s .. string.rep("    ", indent - 1) .. "}"
end

-- Export layout only
function Grid:ExportLayoutOnly()
    local layoutStr, _ = self:ExportLayout()

    StaticPopupDialogs["INFINITY_EXPORT_LAYOUT"] = {
        text = "Copy layout code (paste at the end of the module):",
        button1 = "OK",
        hasEditBox = 1,
        OnShow = function(s)
            s.EditBox:SetText(layoutStr:gsub("|", "||"));
            s.EditBox:HighlightText()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopup_Show("INFINITY_EXPORT_LAYOUT")
end

-- Export defaults only
function Grid:ExportDefaultsOnly()
    local _, defaults = self:ExportLayout()

    local defaultsStr = "local MODULE_DEFAULTS = " .. serializeTable(defaults, 1)

    StaticPopupDialogs["INFINITY_EXPORT_DEFAULTS"] = {
        text = "Copy defaults code (paste near the start of the module):",
        button1 = "OK",
        hasEditBox = 1,
        OnShow = function(s)
            s.EditBox:SetText(defaultsStr:gsub("|", "||"));
            s.EditBox:HighlightText()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopup_Show("INFINITY_EXPORT_DEFAULTS")
end

-- [v4.3.4 Fix] Revert to simple lines
function Grid:DrawEditorGrid(container)
    if not self.GridLines then self.GridLines = {} end
    -- Show/Create Lines
    local w, h = container:GetSize()
    local step = self.CellSize or 20

    local lineIdx = 1

    -- Horizontal
    for y = 0, h, step do
        local line = self.GridLines[lineIdx]
        if not line then
            line = container:CreateLine()
            line:SetThickness(1)
            line:SetColorTexture(1, 1, 1, 0.1)
            table.insert(self.GridLines, line)
        end
        line:Show()
        line:SetStartPoint("TOPLEFT", 0, -y)
        line:SetEndPoint("TOPRIGHT", 0, -y)
        lineIdx = lineIdx + 1
    end

    -- Vertical
    for x = 0, w, step do
        local line = self.GridLines[lineIdx]
        if not line then
            line = container:CreateLine()
            line:SetThickness(1)
            line:SetColorTexture(1, 1, 1, 0.1)
            table.insert(self.GridLines, line)
        end
        line:Show()
        line:SetStartPoint("TOPLEFT", x, 0)
        line:SetEndPoint("BOTTOMLEFT", x, 0)
        lineIdx = lineIdx + 1
    end

    -- Hide unused
    for i = lineIdx, #self.GridLines do self.GridLines[i]:Hide() end
end

-- [v4.3.4 Fix] Revert to simple lines
function Grid:DrawEditorGrid(container)
    if not self.GridLines then self.GridLines = {} end
    -- Show/Create Lines
    local w, h = container:GetSize()
    local step = self.CellSize or 20

    local lineIdx = 1

    -- Horizontal
    for y = 0, h, step do
        local line = self.GridLines[lineIdx]
        if not line then
            line = container:CreateLine()
            line:SetThickness(1)
            line:SetColorTexture(1, 1, 1, 0.1)
            table.insert(self.GridLines, line)
        end
        line:Show()
        line:SetStartPoint("TOPLEFT", 0, -y)
        line:SetEndPoint("TOPRIGHT", 0, -y)
        lineIdx = lineIdx + 1
    end

    -- Vertical
    for x = 0, w, step do
        local line = self.GridLines[lineIdx]
        if not line then
            line = container:CreateLine()
            line:SetThickness(1)
            line:SetColorTexture(1, 1, 1, 0.1)
            table.insert(self.GridLines, line)
        end
        line:Show()
        line:SetStartPoint("TOPLEFT", x, 0)
        line:SetEndPoint("BOTTOMLEFT", x, 0)
        lineIdx = lineIdx + 1
    end

    -- Hide unused
    for i = lineIdx, #self.GridLines do self.GridLines[i]:Hide() end
end

function InfinityTools:ToggleDevMode()
    if not self.UI or not self.UI.ActivePageFrame then
        return
    end
    self.Grid:ToggleLiveEdit(self.UI.ActivePageFrame)
end

