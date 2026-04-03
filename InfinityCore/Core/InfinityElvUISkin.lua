-- =============================================================
-- InfinityTools ElvUI skin integration
-- When ElvUI is detected, automatically apply ElvUI styling to all frames.
--
-- Core concept:
--   ElvUI injects methods such as SetTemplate/CreateBackdrop through Toolkit.lua
--   into metatable.__index for all Frame types, so any frame
--   object can call methods such as frame:SetTemplate("Transparent") directly.
--   Skins Handle functions (such as HandleButton) live on the E.Skins module.
--
-- [v5.1.0] 2026-02-17 rewrite based on an ElvUI source audit
--   Audit reference: ElvUI/Game/Shared/General/Toolkit.lua (SetTemplate definition)
--             ElvUI/Game/Shared/Modules/Skins/Skins.lua (Handle* definitions)
-- =============================================================

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

local ElvUISkin = {}
InfinityTools.ElvUISkin = ElvUISkin

-- =============================================
-- ElvUI engine reference (delayed initialization)
-- =============================================
local E                  -- ElvUI engine object
local S                  -- ElvUI Skins module
local elvuiReady = false -- Whether ElvUI is fully initialized

-- Initialize ElvUI references
-- Must only be called after ElvUI has finished initializing.
local function InitElvUI()
    if elvuiReady then return true end

    local elvui = _G.ElvUI
    if not elvui then return false end

    E = elvui[1]
    if not E then return false end

    -- Check whether ElvUI has finished initializing (E.initialized is set in Core.lua)
    if not E.initialized then return false end

    -- Get the Skins module reference
    S = E:GetModule("Skins", true) -- true = silent mode, no error

    elvuiReady = true
    return true
end

-- =============================================
-- Core skin methods
-- =============================================

--- Apply ElvUI SetTemplate styling to a frame
-- ElvUI SetTemplate is a frame method (injected into the metatable), not a method on E
-- Signature: frame:SetTemplate(template, glossTex, ignoreUpdates, forcePixelMode, ...)
-- @param frame Frame target frame
-- @param template string|nil template type: "Default"/"Transparent"/"ClassColor"/"NoBackdrop" (default: "Transparent")
-- @param glossTex boolean|nil whether to use the gloss texture
function ElvUISkin:ApplyBackdrop(frame, template, glossTex)
    if not frame then return false end
    if not InitElvUI() then return false end

    template = template or "Transparent"

    -- Correct call: frame:SetTemplate() is a frame method
    if frame.SetTemplate then
        frame:SetTemplate(template, glossTex)
        return true
    end

    return false
end

--- Create an ElvUI-style backdrop for a frame (border + shadow)
-- This goes beyond SetTemplate by creating an embedded background layer
-- @param frame Frame target frame
-- @param template string|nil template type
-- @param glossTex boolean|nil whether to use the gloss texture
function ElvUISkin:CreateBackdrop(frame, template, glossTex)
    if not frame then return false end
    if not InitElvUI() then return false end

    template = template or "Transparent"

    if frame.CreateBackdrop then
        frame:CreateBackdrop(template, glossTex)
        return true
    end

    return false
end

--- Apply ElvUI border color
-- @param frame Frame target frame
-- @param r number|nil red component (0-1); if omitted, use the ElvUI default border color
-- @param g number|nil green component
-- @param b number|nil blue component
-- @param a number|nil alpha
function ElvUISkin:ApplyBorder(frame, r, g, b, a)
    if not frame then return false end
    if not InitElvUI() then return false end

    if frame.SetBackdropBorderColor then
        local bc = E.media.bordercolor
        frame:SetBackdropBorderColor(
            r or (bc and bc[1]) or 0.1,
            g or (bc and bc[2]) or 0.1,
            b or (bc and bc[3]) or 0.1,
            a or 1
        )
        return true
    end

    return false
end

--- Create a frame with ElvUI styling (wraps CreateFrame + SetTemplate)
-- @param frameType string frame type ("Frame", "Button", etc.)
-- @param name string|nil frame name
-- @param parent Frame|nil parent frame
-- @param inherits string|nil inherited template
-- @param elvuiTemplate string|nil ElvUI template type
function ElvUISkin:CreateFrame(frameType, name, parent, inherits, elvuiTemplate)
    local frame = CreateFrame(frameType, name, parent or UIParent, inherits)

    if InitElvUI() then
        -- Correct call: frame:SetTemplate() is a frame method
        if frame.SetTemplate then
            frame:SetTemplate(elvuiTemplate or "Transparent")
        end
    else
        -- Fallback: use a native backdrop when ElvUI is not loaded
        if not frame.SetBackdrop then
            _G.Mixin(frame, _G.BackdropTemplateMixin)
        end
        frame:SetBackdrop({
            bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
            edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end

    return frame
end

--- Apply an ElvUI skin to an existing frame
-- @param frame Frame existing frame
-- @param elvuiTemplate string|nil ElvUI template type
function ElvUISkin:SkinFrame(frame, elvuiTemplate)
    if not frame then return false end
    if not InitElvUI() then return false end

    if frame.SetTemplate then
        frame:SetTemplate(elvuiTemplate or "Transparent")
        return true
    end

    return false
end

-- =============================================
-- ElvUI Skins Handle wrappers
-- =============================================

--- Apply ElvUI button styling
-- Source: Skins.lua:996 - S:HandleButton(button, strip, isDecline, noStyle, ...)
function ElvUISkin:SkinButton(button)
    if not button then return false end
    if not InitElvUI() then return false end

    if S and S.HandleButton then
        S:HandleButton(button)
        return true
    end

    return false
end

--- Apply ElvUI slider styling
-- Source: Skins.lua:1806 - S:HandleSliderFrame(frame, template, frameLevel)
function ElvUISkin:SkinSlider(slider)
    if not slider then return false end
    if not InitElvUI() then return false end

    if S and S.HandleSliderFrame then
        S:HandleSliderFrame(slider)
        return true
    end

    return false
end

--- Apply ElvUI edit box styling
-- Source: Skins.lua:1405 - S:HandleEditBox(frame, template)
function ElvUISkin:SkinEditBox(editbox)
    if not editbox then return false end
    if not InitElvUI() then return false end

    if S and S.HandleEditBox then
        S:HandleEditBox(editbox)
        return true
    end

    return false
end

--- Apply ElvUI checkbox styling
-- Source: Skins.lua:1533 - S:HandleCheckBox(frame, noBackdrop, noReplaceTextures, ...)
function ElvUISkin:SkinCheckBox(checkbox)
    if not checkbox then return false end
    if not InitElvUI() then return false end

    if S and S.HandleCheckBox then
        S:HandleCheckBox(checkbox)
        return true
    end

    return false
end

--- Apply ElvUI close-button styling
-- Source: Skins.lua:1705 - S:HandleCloseButton(f, point, x, y)
function ElvUISkin:SkinCloseButton(button)
    if not button then return false end
    if not InitElvUI() then return false end

    if S and S.HandleCloseButton then
        S:HandleCloseButton(button)
        return true
    end

    return false
end

--- Apply ElvUI status-bar styling
-- Source: Skins.lua:1496 - S:HandleStatusBar(frame, color, template)
function ElvUISkin:SkinStatusBar(statusbar, color)
    if not statusbar then return false end
    if not InitElvUI() then return false end

    if S and S.HandleStatusBar then
        S:HandleStatusBar(statusbar, color)
        return true
    end

    return false
end

--- Apply ElvUI tab styling
-- Source: Skins.lua:1259 - S:HandleTab(tab, noBackdrop, template)
function ElvUISkin:SkinTab(tab)
    if not tab then return false end
    if not InitElvUI() then return false end

    if S and S.HandleTab then
        S:HandleTab(tab)
        return true
    end

    return false
end

--- Apply ElvUI scrollbar styling
-- Source: Skins.lua:1102 - S:HandleScrollBar(frame, thumbY, thumbX, template)
function ElvUISkin:SkinScrollBar(scrollbar)
    if not scrollbar then return false end
    if not InitElvUI() then return false end

    if S and S.HandleScrollBar then
        S:HandleScrollBar(scrollbar)
        return true
    end

    return false
end

--- Apply ElvUI trimmed scrollbar styling
-- Source: Skins.lua:1212 - S:HandleTrimScrollBar(frame, ignoreUpdates)
-- Applies to modern scrollbars such as MinimalScrollBar / WowTrimScrollBar
function ElvUISkin:SkinTrimScrollBar(scrollbar, ignoreUpdates)
    if not scrollbar then return false end
    if not InitElvUI() then return false end

    if S and S.HandleTrimScrollBar then
        S:HandleTrimScrollBar(scrollbar, ignoreUpdates)
        return true
    end

    return false
end

-- =============================================
-- Media lookup
-- =============================================

--- Get ElvUI media assets and return defaults as a fallback
-- E.media (lowercase) = runtime dynamic values
--    E.Media (uppercase) = static asset-path table
function ElvUISkin:GetMedia()
    if not InitElvUI() then
        return {
            normFont = "Fonts\\FRIZQT__.TTF",
            blankTex = [[Interface\Buttons\WHITE8X8]],
            bordercolor = { 0.1, 0.1, 0.1 },
            backdropcolor = { 0.05, 0.05, 0.05 },
        }
    end

    return {
        normFont = E.media.normFont or "Fonts\\FRIZQT__.TTF",
        blankTex = E.media.blankTex or [[Interface\Buttons\WHITE8X8]],
        bordercolor = E.media.bordercolor or { 0.1, 0.1, 0.1 },
        backdropcolor = E.media.backdropcolor or { 0.05, 0.05, 0.05 },
        backdropfadecolor = E.media.backdropfadecolor or { 0.05, 0.05, 0.05, 0.85 },
        normTex = E.media.normTex,
        glossTex = E.media.glossTex,
        borderwidth = E.Border or 1,
        spacing = E.Spacing or 1,
    }
end

--- Check whether ElvUI is loaded and fully initialized
function ElvUISkin:IsElvUILoaded()
    return InitElvUI()
end

--- Get the ElvUI color scheme
function ElvUISkin:GetColors()
    if not InitElvUI() then
        return {
            class = { r = 0.3, g = 0.3, b = 0.3 },
            border = { r = 0.1, g = 0.1, b = 0.1 },
            backdrop = { r = 0.05, g = 0.05, b = 0.05 },
        }
    end

    local classColor = E:ClassColor(E.myclass, true)

    return {
        class = classColor or { r = 0.3, g = 0.3, b = 0.3 },
        border = E.media.bordercolor or { r = 0.1, g = 0.1, b = 0.1 },
        backdrop = E.media.backdropcolor or { r = 0.05, g = 0.05, b = 0.05 },
    }
end

-- =============================================
-- Initialization: wait until ElvUI is fully ready before hooking the panel
-- =============================================
-- Use PLAYER_ENTERING_WORLD instead of PLAYER_LOGIN
-- Because ElvUI only runs Initialize() during PLAYER_LOGIN
-- PLAYER_ENTERING_WORLD fires later, at which point ElvUI is guaranteed to be initialized

-- =============================================
-- [Core] Proactively hook the InfinityTools settings panel
-- =============================================
-- Defining helper functions alone is not enough; the panel creation flow must be hooked proactively,
-- so SetTemplate / Handle* methods are called automatically after UI components are created.

local skinApplied = false -- Prevent re-skinning the main panel
local exBossModernScrollHooked = false

local function HideInfinityBossScrollFallback(scrollbar)
    if not scrollbar then return end

    local track = scrollbar.Track or (scrollbar.GetTrack and scrollbar:GetTrack()) or nil
    if track then
        if track._exFallbackLine then track._exFallbackLine:Hide() end
        if track._exFallbackGlow then track._exFallbackGlow:Hide() end
    end

    local thumb = (track and track.Thumb) or (scrollbar.GetThumb and scrollbar:GetThumb()) or nil
    if thumb and thumb._exFallbackBody then
        thumb._exFallbackBody:Hide()
    end
end

local function SkinModernTrimScrollBar(scrollbar)
    if not scrollbar or not InitElvUI() or not S or not S.HandleTrimScrollBar then
        return false
    end

    local hasTrimParts = (scrollbar.Back or scrollbar.Forward or scrollbar.Track)
        and (scrollbar.GetThumb or (scrollbar.Track and scrollbar.Track.Thumb))
    if not hasTrimParts then
        return false
    end

    pcall(function()
        S:HandleTrimScrollBar(scrollbar)
        HideInfinityBossScrollFallback(scrollbar)
        scrollbar._elvuiTrimSkinned = true
    end)
    return true
end

local function ScanAndSkinModernScrollBars(frame, visited)
    if not frame then return end
    visited = visited or {}
    if visited[frame] then return end
    visited[frame] = true

    if frame._exModernScrollBar then
        SkinModernTrimScrollBar(frame._exModernScrollBar)
    end

    if frame.Track and (frame.GetThumb or frame.Track.Thumb) and (frame.Back or frame.Forward) then
        SkinModernTrimScrollBar(frame)
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        ScanAndSkinModernScrollBars(child, visited)
    end
end

local function HookInfinityBossScrollBars()
    if exBossModernScrollHooked or not InitElvUI() then
        return
    end

    local exBoss = _G.InfinityBoss
    local ui = exBoss and exBoss.UI
    local panel = ui and ui.Panel
    if not ui or type(ui.ApplyModernScrollBarSkin) ~= "function" then
        return
    end

    hooksecurefunc(ui, "ApplyModernScrollBarSkin", function(scrollFrame)
        if scrollFrame and scrollFrame._exModernScrollBar then
            SkinModernTrimScrollBar(scrollFrame._exModernScrollBar)
        end
    end)

    if panel then
        if type(panel.Toggle) == "function" then
            hooksecurefunc(panel, "Toggle", function()
                C_Timer.After(0.05, function()
                    if panel._frame and panel._frame:IsShown() then
                        ScanAndSkinModernScrollBars(panel._frame)
                    end
                end)
            end)
        end

        if type(panel.Show) == "function" then
            hooksecurefunc(panel, "Show", function()
                C_Timer.After(0.05, function()
                    if panel._frame and panel._frame:IsShown() then
                        ScanAndSkinModernScrollBars(panel._frame)
                    end
                end)
            end)
        end

        if type(panel.SetTab) == "function" then
            hooksecurefunc(panel, "SetTab", function()
                C_Timer.After(0.05, function()
                    if panel._frame and panel._frame:IsShown() then
                        ScanAndSkinModernScrollBars(panel._frame)
                    end
                end)
            end)
        end
    end

    exBossModernScrollHooked = true

    if panel and panel._frame and panel._frame:IsShown() then
        ScanAndSkinModernScrollBars(panel._frame)
    end
end

--- Apply the ElvUI skin to the main settings panel frame
local function SkinMainPanel()
    if skinApplied then return end

    local RevUI = InfinityTools.UI
    if not RevUI or not RevUI.MainFrame then return end
    if not InitElvUI() then return end

    local f = RevUI.MainFrame
    skinApplied = true

    -- 1. Main window: replace the manual Backdrop with the ElvUI transparent template
    if f.SetTemplate then
        f:SetTemplate("Transparent")
        f:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    end

    -- 2. Close button (UIPanelCloseButton child frame)
    if S and S.HandleCloseButton then
        if f.CloseButton then
            -- [Fix] Use the stored reference directly to avoid failures in WoW 12.x
            -- caused by UIPanelCloseButton atlas textures breaking texture-name matching
            pcall(function() S:HandleCloseButton(f.CloseButton) end)
        else
            -- Fallback: iterate over child frames (compatible with older versions)
            for _, child in ipairs({ f:GetChildren() }) do
                if child:GetObjectType() == "Button" and child:IsObjectType("Button") then
                    local regions = { child:GetRegions() }
                    for _, region in ipairs(regions) do
                        if region:GetObjectType() == "Texture" then
                            local tex = region:GetTexture()
                            if tex and type(tex) == "string" and tex:find("CloseButton") then
                                S:HandleCloseButton(child)
                                break
                            end
                        end
                    end
                    if not child.IsSkinned and child:GetWidth() == 32 and child:GetHeight() == 32 then
                        pcall(function() S:HandleCloseButton(child) end)
                    end
                end
            end
        end
    end

    -- 3. Scrollbar skinning
    if S and S.HandleScrollBar then
        local scrollbars = {
            _G["InfinitySidebarScrollScrollBar"],
            _G["InfinityCommonScrollScrollBar"],
            _G["InfinityModuleGridScrollScrollBar"],
        }
        for _, sb in ipairs(scrollbars) do
            if sb and not sb.backdrop then
                pcall(function() S:HandleScrollBar(sb) end)
            end
        end
    end

    -- 4. Sidebar panel and right-side panel frames
    if RevUI.SidebarFrame then
        local sidebar = RevUI.SidebarFrame:GetParent()
        if sidebar and sidebar.SetTemplate and not sidebar._elvuiSkinned then
            sidebar._elvuiSkinned = true
        end
    end
    if RevUI.RightPanel and RevUI.RightPanel.SetTemplate and not RevUI.RightPanel._elvuiSkinned then
        RevUI.RightPanel:SetTemplate("Transparent")
        RevUI.RightPanel:SetBackdropColor(0.05, 0.05, 0.05, 0.5)
        RevUI.RightPanel._elvuiSkinned = true
    end
end

--- Delay scrollbar skinning (module-settings scrollbars may be created after the main panel)
local function SkinScrollBarsDeferred()
    if not InitElvUI() or not S or not S.HandleScrollBar then return end
    local scrollbars = {
        _G["InfinitySidebarScrollScrollBar"],
        _G["InfinityCommonScrollScrollBar"],
        _G["InfinityModuleGridScrollScrollBar"],
    }
    for _, sb in ipairs(scrollbars) do
        if sb and not sb.backdrop then
            pcall(function() S:HandleScrollBar(sb) end)
        end
    end
end

--- Hook RevUI factory methods so skins are applied automatically after widgets are created.
-- Use a wrapper pattern for local functions instead of hooksecurefunc because the return value is needed.
local function HookRevUI()
    local RevUI = InfinityTools.UI
    if not RevUI then return end

    -- -------------------------------------------------------
    -- Hook CreateActionButton: purple primary button -> ElvUI Default template
    -- -------------------------------------------------------
    if RevUI.CreateActionButton then
        local origCreateActionButton = RevUI.CreateActionButton
        RevUI.CreateActionButton = function(self, parent, text, onClick)
            local btn = origCreateActionButton(self, parent, text, onClick)
            if btn and InitElvUI() and btn.SetTemplate then
                btn:SetTemplate("Default", true)
                btn:SetBackdropColor(0.64, 0.19, 0.79, 0.6)
                btn:HookScript("OnEnter", function(b)
                    b:SetBackdropColor(0.74, 0.29, 0.89, 0.8)
                end)
                btn:HookScript("OnLeave", function(b)
                    b:SetBackdropColor(0.64, 0.19, 0.79, 0.6)
                end)
            end
            return btn
        end
    end

    -- -------------------------------------------------------
    -- Hook CreateSmallButton: bottom small button -> ElvUI Default template
    -- -------------------------------------------------------
    if RevUI.CreateSmallButton then
        local origCreateSmallButton = RevUI.CreateSmallButton
        RevUI.CreateSmallButton = function(self, parent, text, onClick)
            local btn = origCreateSmallButton(self, parent, text, onClick)
            if btn and InitElvUI() and btn.SetTemplate then
                btn:SetTemplate("Default")
            end
            return btn
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateSlider: content-area slider -> ElvUI StepSlider skin
    -- MinimalSliderWithSteppersTemplate uses S:HandleStepSlider()
    -- Audit reference: Skins.lua:1843 HandleStepSlider / SettingsPanel.lua
    --
    -- [v5.1.3 Fix] HandleStepSlider is designed for Blizzards native 250x40 size,
    --   but InfinityTools GridSlider pool rows are only 20px tall, which causes:
    --   1) backdrop (TOPLEFT(10,-10)/BOTTOMRIGHT(-10,10)) height = 0px -> the track becomes invisible
    --   2) Thumb (20x30) exceeds the 20px frame -> severe visual proportion issues
    --   Fix: after calling HandleStepSlider, force the backdrop to 10px and center it,
    --   then shrink the Thumb so it matches the smaller slider height.
    -- -------------------------------------------------------
    if RevUI.CreateSlider then
        local origCreateSlider = RevUI.CreateSlider
        RevUI.CreateSlider = function(self, parent, width, label, minVal, maxVal, curVal, step, formatter, onValueChanged)
            local slider = origCreateSlider(self, parent, width, label, minVal, maxVal, curVal, step, formatter, onValueChanged)
            if slider and InitElvUI() and not slider._elvuiSkinned then
                slider._elvuiSkinned = true
                pcall(function()
                    if S and S.HandleStepSlider then
                        S:HandleStepSlider(slider, true)

                        local innerSlider = slider.Slider
                        if innerSlider then
                            -- Fix 1: force the track backdrop height to 10px and center it
                            -- Blizzard native 40px frame -> 20px backdrop; InfinityTools 20px -> 0px
                            if innerSlider.backdrop then
                                innerSlider.backdrop:ClearAllPoints()
                                innerSlider.backdrop:SetHeight(10)
                                innerSlider.backdrop:SetPoint("LEFT", innerSlider, "LEFT", 10, 0)
                                innerSlider.backdrop:SetPoint("RIGHT", innerSlider, "RIGHT", -10, 0)
                            end

                            -- Fix 2: shrink the Thumb to match the 20px-tall slider
                            -- Blizzard native Thumb = 20x30 for a 40px frame
                            -- InfinityTools scales it down proportionally to 12x18 for a 20px frame
                            local thumb = innerSlider.Thumb
                            if thumb then
                                thumb:SetSize(12, 18)
                            end

                            -- Fix 3: the barStep progress bar must also match the new backdrop size
                            if innerSlider.barStep and innerSlider.backdrop then
                                innerSlider.barStep:ClearAllPoints()
                                innerSlider.barStep:SetPoint("TOPLEFT", innerSlider.backdrop, E.mult, -E.mult)
                                innerSlider.barStep:SetPoint("BOTTOMLEFT", innerSlider.backdrop, E.mult, E.mult)
                                if thumb then
                                    innerSlider.barStep:SetPoint("RIGHT", thumb, "CENTER")
                                end
                            end
                        end
                    elseif S and S.HandleSliderFrame and slider.Slider then
                        S:HandleSliderFrame(slider.Slider)
                    end
                end)
            end
            return slider
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook all dropdown factories: WowStyle1DropdownTemplate -> ElvUI skin
    -- Do not use HandleButton(strip=true) because StripTextures destroys the Arrow texture
    -- Use manual SetTemplate + create an ElvUI-style arrow instead
    -- Audit reference: Skins.lua:1438 HandleDropDownBox / SettingsPanel.lua:35
    -- -------------------------------------------------------
    local dropdownFactories = {
        "CreateDropdown",
        "CreateLSMDropdown",
        "CreateLSMTextureDropdown",
        "CreateLSMSoundDropdown",
        "CreateMultiSelectDropdown",
    }
    for _, funcName in ipairs(dropdownFactories) do
        if RevUI[funcName] then
            local origFunc = RevUI[funcName]
            RevUI[funcName] = function(self, ...)
                local dropdown = origFunc(self, ...)
                if dropdown and InitElvUI() and not dropdown._elvuiSkinned then
                    dropdown._elvuiSkinned = true
                    pcall(function()
                        -- 1. Hide Blizzards native background textures (but keep Arrow and Text)
                        if dropdown.NormalTexture then dropdown.NormalTexture:SetAlpha(0) end
                        if dropdown.HighlightTexture then dropdown.HighlightTexture:SetAlpha(0) end
                        if dropdown.PushedTexture then dropdown.PushedTexture:SetAlpha(0) end
                        -- Lightweight StripTextures variant: only hide background-like textures
                        for _, region in ipairs({ dropdown:GetRegions() }) do
                            if region:IsObjectType("Texture") then
                                local name = region:GetDebugName() or ""
                                -- Keep Arrow + Text related textures
                                if region ~= dropdown.Arrow and not name:find("Arrow") then
                                    local drawLayer = region:GetDrawLayer()
                                    if drawLayer == "BACKGROUND" or drawLayer == "BORDER" then
                                        region:SetAlpha(0)
                                    end
                                end
                            end
                        end

                        -- 2. Apply the ElvUI template backdrop
                        dropdown:SetTemplate("Default")

                        -- 3. Hide the original arrow and create an ElvUI-style arrow (downward triangle)
                        if dropdown.Arrow then
                            dropdown.Arrow:SetAlpha(0)
                        end

                        if not dropdown._elvuiArrow then
                            local arrow = dropdown:CreateTexture(nil, "ARTWORK")
                            arrow:SetTexture(E.Media.Textures.ArrowUp)
                            arrow:SetRotation(3.14159)  -- 180 degrees = down
                            arrow:SetSize(14, 14)
                            arrow:SetPoint("RIGHT", dropdown, "RIGHT", -3, 0)
                            arrow:SetVertexColor(1, 0.82, 0, 0.8)  -- ElvUI gold
                            dropdown._elvuiArrow = arrow
                        end

                        -- 4. Hover/leave effects
                        dropdown:HookScript("OnEnter", function(self)
                            if self._elvuiArrow then
                                self._elvuiArrow:SetVertexColor(1, 1, 1, 1)
                            end
                        end)
                        dropdown:HookScript("OnLeave", function(self)
                            if self._elvuiArrow then
                                self._elvuiArrow:SetVertexColor(1, 0.82, 0, 0.8)
                            end
                        end)
                    end)
                end
                return dropdown
            end
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateButton: generic content-area button -> ElvUI button skin
    -- SharedButtonLargeTemplate uses S:HandleButton(btn, strip)
    -- Audit reference: Skins.lua:996 HandleButton
    -- -------------------------------------------------------
    if RevUI.CreateButton then
        local origCreateButton = RevUI.CreateButton
        RevUI.CreateButton = function(self, parent, width, height, text, onClick)
            local btn = origCreateButton(self, parent, width, height, text, onClick)
            if btn and InitElvUI() and not btn.IsSkinned then
                if S and S.HandleButton then
                    pcall(function() S:HandleButton(btn, true) end)
                end
            end
            return btn
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateCheckbox: checkbox -> ElvUI checkbox skin
    -- MinimalCheckboxTemplate uses S:HandleCheckBox(checkbox)
    -- Audit reference: Skins.lua:1533 HandleCheckBox
    -- -------------------------------------------------------
    if RevUI.CreateCheckbox then
        local origCreateCheckbox = RevUI.CreateCheckbox
        RevUI.CreateCheckbox = function(self, parent, text, initialValue, onClick)
            local container = origCreateCheckbox(self, parent, text, initialValue, onClick)
            if container and container.checkbox and InitElvUI() then
                if not container.checkbox.IsSkinned and S and S.HandleCheckBox then
                    pcall(function() S:HandleCheckBox(container.checkbox) end)
                end
            end
            return container
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateEditBox: input box -> ElvUI input-box skin
    -- The pooled path returns the EditBox itself; the legacy path returns a Frame container
    -- Audit reference: Skins.lua:1405 HandleEditBox
    -- -------------------------------------------------------
    if RevUI.CreateEditBox then
        local origCreateEditBox = RevUI.CreateEditBox
        RevUI.CreateEditBox = function(self, parent, text, w, h, labelText, options)
            local container = origCreateEditBox(self, parent, text, w, h, labelText, options)
            if container and InitElvUI() then
                -- Pooled path: container.editBox == container (the EditBox itself)
                -- Legacy path: container.editBox is the EditBox inside the ScrollFrame
                local editbox = container.editBox or container
                if editbox and not editbox._elvuiSkinned then
                    editbox._elvuiSkinned = true
                    if editbox.SetTemplate then
                        editbox:SetTemplate("Default")
                        editbox:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
                    end
                end
            end
            return container
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateColorButton: color picker button -> ElvUI template
    -- Use BackdropTemplate and call SetTemplate directly
    -- -------------------------------------------------------
    if RevUI.CreateColorButton then
        local origCreateColorButton = RevUI.CreateColorButton
        RevUI.CreateColorButton = function(self, parent, label, db, key, hasAlpha, onUpdate)
            local btn = origCreateColorButton(self, parent, label, db, key, hasAlpha, onUpdate)
            if btn and InitElvUI() and not btn._elvuiSkinned then
                btn._elvuiSkinned = true
                if btn.SetTemplate then
                    btn:SetTemplate("Transparent")
                end
            end
            return btn
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateSegmentedControl: segmented control -> ElvUI template
    -- -------------------------------------------------------
    if RevUI.CreateSegmentedControl then
        local origCreateSegmentedControl = RevUI.CreateSegmentedControl
        RevUI.CreateSegmentedControl = function(self, parent, width, items, currentValue, onChange)
            local container = origCreateSegmentedControl(self, parent, width, items, currentValue, onChange)
            if container and InitElvUI() and not container._elvuiSkinned then
                container._elvuiSkinned = true
                if container.SetTemplate then
                    container:SetTemplate("Default")
                end
            end
            return container
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateSidebarItemBase: sidebar navigation item -> lightweight skin
    -- Do not use HandleButton so the custom gradient/glacier-blue look is preserved
    -- -------------------------------------------------------
    if RevUI.CreateSidebarItemBase then
        local origCreateSidebarItemBase = RevUI.CreateSidebarItemBase
        RevUI.CreateSidebarItemBase = function(self, parent)
            local btn = origCreateSidebarItemBase(self, parent)
            if btn and InitElvUI() and not btn._elvuiSkinned then
                btn._elvuiSkinned = true
                -- Lightweight skin: only apply ElvUI borders and keep the original visual design
                if btn.SetTemplate then
                    btn:SetTemplate("Transparent")
                    btn:SetBackdropColor(0, 0, 0, 0)
                    btn:SetBackdropBorderColor(0, 0, 0, 0)
                end
            end
            return btn
        end
    end

    -- -------------------------------------------------------
    -- [NEW] Hook CreateCategoryHeaderBase: sidebar category header -> lightweight skin
    -- -------------------------------------------------------
    if RevUI.CreateCategoryHeaderBase then
        local origCreateCategoryHeaderBase = RevUI.CreateCategoryHeaderBase
        RevUI.CreateCategoryHeaderBase = function(self, parent)
            local btn = origCreateCategoryHeaderBase(self, parent)
            if btn and InitElvUI() and not btn._elvuiSkinned then
                btn._elvuiSkinned = true
                if btn.SetTemplate then
                    btn:SetTemplate("Transparent")
                    btn:SetBackdropColor(0.1, 0.1, 0.12, 0.4)
                    btn:SetBackdropBorderColor(0, 0, 0, 0)
                end
            end
            return btn
        end
    end

    -- -------------------------------------------------------
    -- Hook CreateMainFrame: skin the panel immediately after creation
    -- -------------------------------------------------------
    if RevUI.CreateMainFrame then
        hooksecurefunc(RevUI, "CreateMainFrame", function()
            SkinMainPanel()
        end)
    end

    -- -------------------------------------------------------
    -- Hook Toggle: fallback to ensure the panel is skinned the first time it is shown
    -- -------------------------------------------------------
    if RevUI.Toggle then
        hooksecurefunc(RevUI, "Toggle", function()
            if RevUI.MainFrame and not skinApplied then
                SkinMainPanel()
            end
            -- Delay skinning of scrollbars that may be created later
            SkinScrollBarsDeferred()
        end)
    end

    -- -------------------------------------------------------
    -- Hook ShowModuleSettingsPage: skin the scrollbar after the module settings page is created
    -- -------------------------------------------------------
    if RevUI.ShowModuleSettingsPage then
        hooksecurefunc(RevUI, "ShowModuleSettingsPage", function()
            -- Delay by one frame and wait until the ScrollFrame is fully created
            C_Timer.After(0.05, SkinScrollBarsDeferred)
        end)
    end
end

--- Initialization entry point
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        if InitElvUI() then
            -- print("|cff00ff00[InfinityTools]|r ElvUI detected, ElvUI skin integration enabled")
            HookRevUI()
            HookInfinityBossScrollBars()
            -- If the panel already exists (rare case), skin it directly
            if InfinityTools.UI and InfinityTools.UI.MainFrame then
                SkinMainPanel()
            end
        end
    elseif event == "ADDON_LOADED" then
        if InitElvUI() then
            HookInfinityBossScrollBars()
            if exBossModernScrollHooked then
                self:UnregisterEvent("ADDON_LOADED")
            end
        end
    end
end)
