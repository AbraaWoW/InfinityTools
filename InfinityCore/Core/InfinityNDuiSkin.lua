-- =============================================================
-- InfinityTools NDui skin integration
-- When NDui is detected, automatically apply NDui styling to all frames.
--
-- Core approach:
--   NDui exposes its namespace through _G["NDui"] = ns, where ns[1] = the B object.
--   The B object provides all UI skinning functions (B:CreateBD, B:Reskin, B:SetBD, etc.).
--   Unlike ElvUI, NDui skinning helpers are static utility calls rather than frame methods.
--   NDui's ns[4] = DB object stores media resources (textures, fonts, colors, etc.).
--
-- Audit basis:
--   NDui/Init.lua (global export _G["NDui"] = ns)
--   NDui/Core/Functions.lua (skinning helpers such as B:CreateBD, B:SetBD, B:Reskin)
--   NDui/Core/Database.lua (media paths such as DB.bdTex, DB.normTex, DB.closeTex)
--
-- [v1.0.0] 2026-02-27 Written from an NDui source audit.
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

-- Mutual exclusion: if the ElvUI skin is loaded, do not enable the NDui skin.
-- ElvUI and NDui are not expected to be installed together, but keep the guard anyway.
if InfinityTools.ElvUISkin and InfinityTools.ElvUISkin:IsElvUILoaded() then return end

local NDuiSkin = {}
InfinityTools.NDuiSkin = NDuiSkin

-- =============================================
-- NDui engine references (lazy initialization)
-- =============================================
local B              -- NDui base module (B = ns[1], hosts UI helpers)
local C              -- NDui config table (C = ns[2])
local DB             -- NDui database (DB = ns[4], includes media paths)
local nduiReady = false  -- Whether NDui is fully initialized

--- Initialize NDui references
-- NDui finishes initialization during PLAYER_LOGIN (see Init.lua and B:RegisterEvent("PLAYER_LOGIN", ...)).
-- This function must therefore run after PLAYER_LOGIN.
local function InitNDui()
    if nduiReady then return true end

    local ndui = _G.NDui
    if not ndui then return false end

    B = ndui[1]
    if not B then return false end

    C = ndui[2]
    DB = ndui[4]

    if not DB then return false end

-- Validate that the B object exposes the core skinning functions.
    if not B.CreateBD then return false end

-- Validate that B.Modules has been populated (set inside the PLAYER_LOGIN callback in Init.lua).
-- If Modules is still missing, NDui has not finished initializing yet.
    if not B.Modules then return false end

    nduiReady = true
    return true
end

-- =============================================
-- Core skinning methods
-- =============================================

--- Apply an NDui-style backdrop to a frame (background + border)
-- Equivalent to ElvUISkin:ApplyBackdrop -> NDui B:CreateBD
-- NDui B:CreateBD signature: B:CreateBD(alpha)
--   - Sets a semi-transparent black backdrop background
--   - Border color is controlled by C.db["Skins"]["GreyBD"]
--   - If alpha is omitted, C.db["Skins"]["SkinAlpha"] is used
-- @param frame Frame Target frame.
-- @param alpha number|nil Background alpha (0-1); when omitted, NDui's default is used.
function NDuiSkin:ApplyBackdrop(frame, alpha)
    if not frame then return false end
    if not InitNDui() then return false end

-- NDui's CreateBD is invoked statically through the B object.
-- Internally it calls frame:SetBackdrop + SetBackdropColor + SetBackdropBorderColor.
    pcall(B.CreateBD, frame, alpha)
    return true
end

--- Create a backdrop with shadow using NDui styling (SetBD = CreateBDFrame + CreateSD + CreateTex)
-- Equivalent to ElvUISkin:CreateBackdrop -> NDui B:SetBD
-- B:SetBD is NDui's most complete frame styling helper:
--   1. CreateBDFrame: create the background frame
--   2. CreateSD: create the shadow
--   3. CreateTex: create the background texture
-- @param frame Frame Target frame.
-- @param alpha number|nil Background alpha.
function NDuiSkin:CreateBackdrop(frame, alpha)
    if not frame then return false end
    if not InitNDui() then return false end

    local bg = nil
    pcall(function()
        bg = B.SetBD(frame, alpha)
    end)
    return bg ~= nil, bg
end

--- Create an NDui-style background frame (without shadow)
-- B:CreateBDFrame signature: B:CreateBDFrame(alpha, gradient)
-- @param frame Frame Target frame.
-- @param alpha number|nil Background alpha.
-- @param gradient boolean|nil Whether to add the gradient texture.
function NDuiSkin:CreateBDFrame(frame, alpha, gradient)
    if not frame then return nil end
    if not InitNDui() then return nil end

    local bg = nil
    pcall(function()
        bg = B.CreateBDFrame(frame, alpha, gradient)
    end)
    return bg
end

--- Apply NDui border coloring
-- NDui border color is controlled by C.db["Skins"]["GreyBD"]:
--   true: semi-transparent white (1,1,1,0.2)
--   false: solid black (0,0,0,1)
-- @param frame Frame Target frame.
-- @param r number|nil Red component when overriding the default color.
-- @param g number|nil Green component.
-- @param b number|nil Blue component.
-- @param a number|nil Alpha component.
function NDuiSkin:ApplyBorder(frame, r, g, b, a)
    if not frame then return false end
    if not InitNDui() then return false end

    if frame.SetBackdropBorderColor then
        if r then
            frame:SetBackdropBorderColor(r, g or 0, b or 0, a or 1)
        else
-- Use NDui's default border color logic.
            B.SetBorderColor(frame)
        end
        return true
    end

    return false
end

--- Create a frame with NDui styling (wrapper around CreateFrame + SetBD)
-- Equivalent to ElvUISkin:CreateFrame
-- @param frameType string Frame type ("Frame", "Button", etc.).
-- @param name string|nil Frame name.
-- @param parent Frame|nil Parent frame.
-- @param inherits string|nil Inherited template.
function NDuiSkin:CreateFrame(frameType, name, parent, inherits)
    local frame = CreateFrame(frameType, name, parent or UIParent, inherits)

    if InitNDui() then
        pcall(function()
            B.SetBD(frame)
        end)
    else
-- Fallback: use a native backdrop when NDui is not loaded.
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

--- Apply NDui skinning to an existing frame
-- Equivalent to ElvUISkin:SkinFrame
-- @param frame Frame Existing frame.
function NDuiSkin:SkinFrame(frame)
    if not frame then return false end
    if not InitNDui() then return false end

    pcall(function()
        B.SetBD(frame)
    end)
    return true
end

-- =============================================
-- NDui component skin wrappers
-- =============================================

--- Apply NDui button styling
-- Source: Functions.lua:939 - B:Reskin(noHighlight, override)
-- Behavior: remove native textures -> create BDFrame -> add hover effect
-- @param button Button Target button.
-- @param noHighlight boolean|nil Whether to disable the highlight effect.
function NDuiSkin:SkinButton(button, noHighlight)
    if not button then return false end
    if not InitNDui() then return false end

    pcall(B.Reskin, button, noHighlight)
    return true
end

--- Apply NDui slider styling
-- Source: Functions.lua:1355 - B:ReskinSlider(vertical)
-- Behavior: strip textures -> create BDFrame -> style the thumb -> add a progress bar
-- @param slider Slider Target slider.
-- @param vertical boolean|nil Whether the slider is vertical.
function NDuiSkin:SkinSlider(slider, vertical)
    if not slider then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinSlider, slider, vertical)
    return true
end

--- Apply NDui edit box styling
-- Source: Functions.lua:1192 - B:ReskinEditBox(height, width)
-- Behavior: hide the native border -> create BDFrame -> optionally resize
-- @param editbox EditBox Target edit box.
-- @param height number|nil Explicit height.
-- @param width number|nil Explicit width.
function NDuiSkin:SkinEditBox(editbox, height, width)
    if not editbox then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinEditBox, editbox, height, width)
    return true
end

--- Apply NDui checkbox styling
-- Source: Functions.lua:1316 - B:ReskinCheck(forceSaturation)
-- Behavior: strip native textures -> create BDFrame -> custom checked mark -> class-color highlight
-- @param checkbox CheckButton Target checkbox.
-- @param forceSaturation boolean|nil Whether to force saturation.
function NDuiSkin:SkinCheckBox(checkbox, forceSaturation)
    if not checkbox then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinCheck, checkbox, forceSaturation)
    return true
end

--- Apply NDui close button styling
-- Source: Functions.lua:1161 - B:ReskinClose(parent, xOffset, yOffset, override)
-- Behavior: strip textures -> create BDFrame -> draw the X icon -> hover effect
-- @param button Button Target close button.
-- @param parent Frame|nil Parent frame used for positioning.
function NDuiSkin:SkinCloseButton(button, parent)
    if not button then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinClose, button, parent)
    return true
end

--- Apply NDui status bar styling
-- Source: Functions.lua:836 - B:CreateSB(spark, r, g, b)
-- Behavior: set the StatusBar texture + color -> SetBD -> optional Spark effect
-- @param statusbar StatusBar Target status bar.
-- @param spark boolean|nil Whether to add the Spark effect.
-- @param r number|nil Red component; defaults to the class color when omitted.
-- @param g number|nil Green component.
-- @param b number|nil Blue component.
function NDuiSkin:SkinStatusBar(statusbar, spark, r, g, b)
    if not statusbar then return false end
    if not InitNDui() then return false end

    pcall(B.CreateSB, statusbar, spark, r, g, b)
    return true
end

--- Apply NDui tab styling
-- Source: Functions.lua:969 - B:ReskinTab()
-- Behavior: hide the background layer -> create BDFrame -> add highlight effect
-- @param tab Button Target tab button.
function NDuiSkin:SkinTab(tab)
    if not tab then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinTab, tab)
    return true
end

--- Apply NDui scrollbar styling
-- Source: Functions.lua:1072 - B:ReskinScroll()
-- Behavior: strip textures -> style the thumb -> arrow buttons
-- @param scrollbar ScrollBar Target scrollbar.
function NDuiSkin:SkinScrollBar(scrollbar)
    if not scrollbar then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinScroll, scrollbar)
    return true
end

--- Apply NDui WowTrimScrollBar styling
-- Source: Functions.lua:1092 - B:ReskinTrimScroll(noTaint)
-- Behavior: compact scrollbar skin for the newer TrimScrollBar widget
-- @param scrollbar Frame Target TrimScrollBar.
-- @param noTaint boolean|nil Whether to avoid taint.
function NDuiSkin:SkinTrimScrollBar(scrollbar, noTaint)
    if not scrollbar then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinTrimScroll, scrollbar, noTaint)
    return true
end

--- Apply NDui dropdown styling
-- Source: Functions.lua:1110 - B:ReskinDropDown()
-- Behavior: strip textures -> create BDFrame -> add a down arrow
-- @param dropdown Frame Target dropdown widget.
function NDuiSkin:SkinDropDown(dropdown)
    if not dropdown then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinDropDown, dropdown)
    return true
end

--- Apply NDui arrow button styling
-- Source: Functions.lua:1228 - B:ReskinArrow(direction)
-- @param button Button Target arrow button.
-- @param direction string Direction: "up"/"down"/"left"/"right".
function NDuiSkin:SkinArrow(button, direction)
    if not button then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinArrow, button, direction)
    return true
end

--- Apply NDui color swatch styling
-- Source: Functions.lua:1301 - B:ReskinColorSwatch()
function NDuiSkin:SkinColorSwatch(swatch)
    if not swatch then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinColorSwatch, swatch)
    return true
end

--- Apply NDui StepperSlider styling
-- Source: Functions.lua:1396 - B:ReskinStepperSlider(minimal)
-- Note: this is the slider with left/right step arrows (MinimalSliderWithSteppersTemplate).
-- @param slider Frame Target StepperSlider.
-- @param minimal boolean|nil Whether to use minimal mode.
function NDuiSkin:SkinStepperSlider(slider, minimal)
    if not slider then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinStepperSlider, slider, minimal)
    return true
end

--- Apply NDui menu button styling
-- Source: Functions.lua:955 - B:ReskinMenuButton()
-- Behavior: strip textures -> SetBD -> custom hover/click effects (class-color highlight)
-- @param button Button Target menu button.
function NDuiSkin:SkinMenuButton(button)
    if not button then return false end
    if not InitNDui() then return false end

    pcall(B.ReskinMenuButton, button)
    return true
end

--- Apply NDui portrait frame styling
-- Source: Functions.lua:1538 - B:ReskinPortraitFrame()
-- Behavior: strip textures -> SetBD -> hide the portrait -> style the close button
-- @param frame Frame Target portrait frame.
function NDuiSkin:SkinPortraitFrame(frame)
    if not frame then return false end
    if not InitNDui() then return false end

    local bg = nil
    pcall(function()
        bg = B.ReskinPortraitFrame(frame)
    end)
    return bg ~= nil, bg
end

--- Remove Blizzard native textures from a frame
-- Source: Functions.lua:414 - B:StripTextures(kill)
-- @param frame Frame Target frame.
-- @param kill boolean|number|nil Removal mode (true=HideObject, 0=SetAlpha(0), nil=clear textures).
function NDuiSkin:StripTextures(frame, kill)
    if not frame then return false end
    if not InitNDui() then return false end

    pcall(B.StripTextures, frame, kill)
    return true
end

--- Create a shadow effect
-- Source: Functions.lua:590 - B:CreateSD(size, override)
-- @param frame Frame Target frame.
-- @param size number|nil Shadow size (default 5).
-- @param override boolean|nil Whether to ignore the global shadow toggle.
function NDuiSkin:CreateShadow(frame, size, override)
    if not frame then return nil end
    if not InitNDui() then return nil end

    local shadow = nil
    pcall(function()
        shadow = B.CreateSD(frame, size, override)
    end)
    return shadow
end

-- =============================================
-- Media resource helpers
-- =============================================

--- Get an NDui media resource, with default fallback values
-- NDui media paths are stored on the DB (ns[4]) object.
function NDuiSkin:GetMedia()
    if not InitNDui() then
        return {
            normFont = STANDARD_TEXT_FONT,
            blankTex = [[Interface\ChatFrame\ChatFrameBackground]],
            normTex = [[Interface\ChatFrame\ChatFrameBackground]],
            bordercolor = { 0, 0, 0 },
            backdropcolor = { 0, 0, 0, 0.5 },
        }
    end

    return {
        normFont = DB.Font and DB.Font[1] or STANDARD_TEXT_FONT,
        fontSize = DB.Font and DB.Font[2] or 12,
        fontFlags = DB.Font and DB.Font[3] or "OUTLINE",
        blankTex = DB.bdTex or [[Interface\ChatFrame\ChatFrameBackground]],
        normTex = DB.normTex,
        flatTex = DB.flatTex,
        gradTex = DB.gradTex,
        bgTex = DB.bgTex,
        glowTex = DB.glowTex,
        sparkTex = DB.sparkTex,
        closeTex = DB.closeTex,
        arrowTex = DB.ArrowUp,
    }
end

--- Check whether NDui is loaded and fully initialized
function NDuiSkin:IsNDuiLoaded()
    return InitNDui()
end

--- Get the NDui color scheme
-- NDui uses class colors as its theme colors (DB.r, DB.g, DB.b).
function NDuiSkin:GetColors()
    if not InitNDui() then
        return {
            class = { r = 0.3, g = 0.3, b = 0.3 },
            border = { r = 0, g = 0, b = 0 },
            backdrop = { r = 0, g = 0, b = 0 },
        }
    end

    return {
        class = { r = DB.r or 0.3, g = DB.g or 0.3, b = DB.b or 0.3 },
        border = { r = 0, g = 0, b = 0 },
        backdrop = { r = 0, g = 0, b = 0, a = C and C.db and C.db["Skins"] and C.db["Skins"]["SkinAlpha"] or 0.5 },
    }
end

--- Get NDui's mult value (pixel scaling multiplier)
-- NDui uses C.mult to control pixel precision.
function NDuiSkin:GetMult()
    if not InitNDui() then return 1 end
    return C and C.mult or 1
end

-- =============================================
-- [Core] Proactively hook the InfinityTools settings panel
-- =============================================

local skinApplied = false -- Prevent re-skinning the main panel

--- Apply NDui skinning to the main settings panel frame
local function SkinMainPanel()
    if skinApplied then return end

    local RevUI = InfinityTools.UI
    if not RevUI or not RevUI.MainFrame then return end
    if not InitNDui() then return end

    local f = RevUI.MainFrame
    skinApplied = true

-- 1. Main window: use NDui CreateBD directly on f to set the backdrop.
-- Do not use B.SetBD(f): SetBD creates a child background frame, while f's own BackdropTemplate
-- would still keep the original opaque black background, causing an unwanted double-layered result.
-- Correct approach: call B.CreateBD(f) directly to replace f's own backdrop,
-- and leave alpha unset so it uses NDui's global SkinAlpha value, matching native NDui panels.
    pcall(function()
        B.CreateBD(f)        -- Apply NDui backdrop directly on f, using SkinAlpha
        B.CreateSD(f, nil, true)  -- Add shadow, override=true ignores the global shadow toggle
        B.CreateTex(f)       -- Add background texture if BgTex is enabled
    end)

-- 2. Close button
    pcall(function()
        if f.CloseButton then
-- [Fix] Use the stored reference directly to avoid failures on WoW 12.x where
-- the UIPanelCloseButton atlas texture no longer matches texture-name based lookups.
            B.ReskinClose(f.CloseButton)
        else
-- Fallback: scan child frames for compatibility with older versions.
            for _, child in ipairs({ f:GetChildren() }) do
                if child:GetObjectType() == "Button" and child:IsObjectType("Button") then
                    local regions = { child:GetRegions() }
                    for _, region in ipairs(regions) do
                        if region:GetObjectType() == "Texture" then
                            local tex = region:GetTexture()
                            if tex and type(tex) == "string" and tex:find("CloseButton") then
                                B.ReskinClose(child)
                                break
                            end
                        end
                    end
                    if not child._nduiSkinned and child:GetWidth() == 32 and child:GetHeight() == 32 then
                        pcall(function()
                            B.ReskinClose(child)
                            child._nduiSkinned = true
                        end)
                    end
                end
            end
        end
    end)

-- 3. Scrollbar skinning
    pcall(function()
        local scrollbars = {
            _G["InfinitySidebarScrollScrollBar"],
            _G["InfinityCommonScrollScrollBar"],
            _G["InfinityModuleGridScrollScrollBar"],
        }
        for _, sb in ipairs(scrollbars) do
            if sb and not sb._nduiSkinned then
                sb._nduiSkinned = true
                pcall(B.ReskinScroll, sb)
            end
        end
    end)

-- 4. Right-side panel frame
    if RevUI.RightPanel and not RevUI.RightPanel._nduiSkinned then
        pcall(function()
-- Use low opacity so it matches the transparent main panel style.
            B.CreateBD(RevUI.RightPanel, 0.15)
            RevUI.RightPanel._nduiSkinned = true
        end)
    end
end

--- Delay skinning of scrollbars (module page scrollbars may be created after the main panel)
local function SkinScrollBarsDeferred()
    if not InitNDui() then return end

    pcall(function()
        local scrollbars = {
            _G["InfinitySidebarScrollScrollBar"],
            _G["InfinityCommonScrollScrollBar"],
            _G["InfinityModuleGridScrollScrollBar"],
        }
        for _, sb in ipairs(scrollbars) do
            if sb and not sb._nduiSkinned then
                sb._nduiSkinned = true
                pcall(B.ReskinScroll, sb)
            end
        end
    end)
end

--- Hook RevUI factory methods so newly created widgets receive NDui skinning automatically
local function HookRevUI()
    local RevUI = InfinityTools.UI
    if not RevUI then return end

    -- -------------------------------------------------------
-- Hook CreateActionButton: large purple buttons -> NDui Reskin + class-color tone
    -- -------------------------------------------------------
    if RevUI.CreateActionButton then
        local origCreateActionButton = RevUI.CreateActionButton
        RevUI.CreateActionButton = function(self, parent, text, onClick)
            local btn = origCreateActionButton(self, parent, text, onClick)
            if btn and InitNDui() and not btn._nduiSkinned then
                btn._nduiSkinned = true
                pcall(function()
                    B.Reskin(btn)
-- Keep the original purple theme by overriding NDui's default effect.
                    if btn.__bg and btn.__bg.SetBackdropColor then
                        btn.__bg:SetBackdropColor(0.64, 0.19, 0.79, 0.3)
                    end
                end)
            end
            return btn
        end
    end

    -- -------------------------------------------------------
-- Hook CreateSmallButton: bottom small buttons -> NDui Reskin
    -- -------------------------------------------------------
    if RevUI.CreateSmallButton then
        local origCreateSmallButton = RevUI.CreateSmallButton
        RevUI.CreateSmallButton = function(self, parent, text, onClick)
            local btn = origCreateSmallButton(self, parent, text, onClick)
            if btn and InitNDui() and not btn._nduiSkinned then
                btn._nduiSkinned = true
                pcall(B.Reskin, btn)
            end
            return btn
        end
    end

    -- -------------------------------------------------------
-- Hook CreateSlider: sliders -> NDui ReskinStepperSlider
-- NDui provides a dedicated ReskinStepperSlider for MinimalSliderWithSteppersTemplate.
    --
-- [v1.0.2 Fix] Use the same fix strategy as the ElvUI skin (InfinityElvUISkin.lua v5.1.3):
--   ReskinStepperSlider is designed around Blizzard's native 250x40 size, while InfinityTools's
--   GridSlider is only 20px tall, which caused the following problems:
--   1) bg (TOPLEFT(10,-offset)/BOTTOMRIGHT(-10,offset), offset=10) height becomes
--      20-10-10 = 0px -> the track is invisible
--   2) Thumb SetSize(20,30) exceeds a 20px-high frame -> the visual proportions are badly distorted
--   Fix: after calling ReskinStepperSlider, find bg and force it to a centered 10px height,
--   while also shrinking the thumb to 12x18 (the bar anchors follow thumb:CENTER automatically).
    -- -------------------------------------------------------
    if RevUI.CreateSlider then
        local origCreateSlider = RevUI.CreateSlider
        RevUI.CreateSlider = function(self, parent, width, label, minVal, maxVal, curVal, step, formatter, onValueChanged)
            local slider = origCreateSlider(self, parent, width, label, minVal, maxVal, curVal, step, formatter, onValueChanged)
            if slider and InitNDui() and not slider._nduiSkinned then
                slider._nduiSkinned = true
                pcall(function()
                    if slider.Back and slider.Forward and slider.Slider then
                        B.ReskinStepperSlider(slider, true)

                        local innerSlider = slider.Slider

-- Fix 1: correct the track bg height to 10px and center it.
-- ReskinStepperSlider creates a BDFrame child on slider.Slider for the track.
-- Find that bg frame and correct its anchors.
                        local trackBg = nil
                        for _, child in ipairs({ innerSlider:GetChildren() }) do
                            if child.SetBackdrop and child.GetBackdrop and child:GetBackdrop() then
                                trackBg = child
                            end
                        end
                        if trackBg then
                            trackBg:ClearAllPoints()
                            trackBg:SetHeight(10)
                            trackBg:SetPoint("LEFT", innerSlider, "LEFT", 10, 0)
                            trackBg:SetPoint("RIGHT", innerSlider, "RIGHT", -10, 0)
                        end

-- Fix 2: shrink the thumb to match a 20px-high slider.
-- NDui sets the Thumb to 20x30 for a 40px-high frame; scale it down proportionally to 12x18 here.
-- The bar inside trackBg (TOPLEFT/BOTTOMLEFT/RIGHT -> thumb:CENTER) follows automatically.
                        local thumb = innerSlider.Thumb
                        if thumb then
                            thumb:SetSize(12, 18)
                        end
                    elseif slider.Slider then
                        B.ReskinSlider(slider.Slider)
                    else
                        B.ReskinSlider(slider)
                    end
                end)
            end
            return slider
        end
    end

    -- -------------------------------------------------------
-- Hook all dropdown factory helpers
-- NDui uses B:ReskinDropDown for WowStyle1DropdownTemplate.
-- InfinityTools dropdowns may be custom, so use SetBD + arrow styling instead.
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
                if dropdown and InitNDui() and not dropdown._nduiSkinned then
                    dropdown._nduiSkinned = true
                    pcall(function()
-- 1. Remove Blizzard's native background textures
                        if dropdown.NormalTexture then dropdown.NormalTexture:SetAlpha(0) end
                        if dropdown.HighlightTexture then dropdown.HighlightTexture:SetAlpha(0) end
                        if dropdown.PushedTexture then dropdown.PushedTexture:SetAlpha(0) end
                        for _, region in ipairs({ dropdown:GetRegions() }) do
                            if region:IsObjectType("Texture") then
                                local name = region:GetDebugName() or ""
                                if region ~= dropdown.Arrow and not name:find("Arrow") then
                                    local drawLayer = region:GetDrawLayer()
                                    if drawLayer == "BACKGROUND" or drawLayer == "BORDER" then
                                        region:SetAlpha(0)
                                    end
                                end
                            end
                        end

-- 2. Apply the NDui background (CreateBDFrame instead of SetBD to avoid shadow overflow)
                        local bg = B.CreateBDFrame(dropdown, 0, true)
                        bg:SetAllPoints()
                        dropdown.__bg = bg

-- 3. Replace the arrow with an NDui-style one
                        if dropdown.Arrow then
                            dropdown.Arrow:SetAlpha(0)
                        end
                        local arrow = dropdown:CreateTexture(nil, "ARTWORK")
                        arrow:SetSize(18, 18)
                        arrow:SetPoint("RIGHT", dropdown, "RIGHT", -3, 0)
                        B.SetupArrow(arrow, "down")
                        dropdown.__texture = arrow

-- 4. Hover effect (class color)
                        dropdown:HookScript("OnEnter", B.Texture_OnEnter)
                        dropdown:HookScript("OnLeave", B.Texture_OnLeave)
                    end)
                end
                return dropdown
            end
        end
    end

    -- -------------------------------------------------------
-- Hook CreateButton: general content-area buttons -> NDui Reskin
    -- -------------------------------------------------------
    if RevUI.CreateButton then
        local origCreateButton = RevUI.CreateButton
        RevUI.CreateButton = function(self, parent, width, height, text, onClick)
            local btn = origCreateButton(self, parent, width, height, text, onClick)
            if btn and InitNDui() and not btn._nduiSkinned then
                btn._nduiSkinned = true
                pcall(B.Reskin, btn)
            end
            return btn
        end
    end

    -- -------------------------------------------------------
-- Hook CreateCheckbox: checkboxes -> NDui ReskinCheck
    -- -------------------------------------------------------
    if RevUI.CreateCheckbox then
        local origCreateCheckbox = RevUI.CreateCheckbox
        RevUI.CreateCheckbox = function(self, parent, text, initialValue, onClick)
            local container = origCreateCheckbox(self, parent, text, initialValue, onClick)
            if container and container.checkbox and InitNDui() and not container.checkbox._nduiSkinned then
                container.checkbox._nduiSkinned = true
                pcall(B.ReskinCheck, container.checkbox)
            end
            return container
        end
    end

    -- -------------------------------------------------------
-- Hook CreateEditBox: edit boxes -> NDui-style styling
-- Use B.CreateBDFrame(editbox, 0, true) to match NDui's native ReskinEditBox behavior:
--   1. Create a child BDFrame as the background (alpha=0 black base + gradient texture -> visible dark background)
--   2. On focus, highlight the border with the class color; on blur, restore the default
-- [Fix] The older version used B.CreateBD(editbox, 0) directly on the editbox,
-- which made the background fully transparent with a black/gray border (depending on GreyBD), leaving the field barely visible.
    -- -------------------------------------------------------
    if RevUI.CreateEditBox then
        local origCreateEditBox = RevUI.CreateEditBox
        RevUI.CreateEditBox = function(self, parent, text, w, h, labelText, options)
            local container = origCreateEditBox(self, parent, text, w, h, labelText, options)
            if container and InitNDui() then
                local editbox = container.editBox or container
                if editbox and not editbox._nduiSkinned then
                    editbox._nduiSkinned = true
                    pcall(function()
-- Hide the editbox's own BackdropTemplate background to avoid double layering.
                        if editbox.SetBackdrop then
                            editbox:SetBackdrop(nil)
                        end

-- Use CreateBDFrame to create a gradient background frame, matching NDui ReskinEditBox.
                        local bg = B.CreateBDFrame(editbox, 0, true)
                        bg:SetPoint("TOPLEFT", editbox, "TOPLEFT", -2, 0)
                        bg:SetPoint("BOTTOMRIGHT", editbox, "BOTTOMRIGHT", 0, 0)
                        editbox.__bg = bg

-- Add focus highlight behavior (class-color border).
                        local cr, cg, cb = DB.r, DB.g, DB.b
                        editbox:HookScript("OnEditFocusGained", function(self)
                            if self.__bg then
                                self.__bg:SetBackdropBorderColor(cr, cg, cb, 1)
                            end
                        end)
                        editbox:HookScript("OnEditFocusLost", function(self)
                            if self.__bg then
                                B.SetBorderColor(self.__bg)
                            end
                        end)
                    end)
                end
            end
            return container
        end
    end

    -- -------------------------------------------------------
-- Hook CreateColorButton: color picker buttons -> NDui CreateBD
    -- -------------------------------------------------------
    if RevUI.CreateColorButton then
        local origCreateColorButton = RevUI.CreateColorButton
        RevUI.CreateColorButton = function(self, parent, label, db, key, hasAlpha, onUpdate)
            local btn = origCreateColorButton(self, parent, label, db, key, hasAlpha, onUpdate)
            if btn and InitNDui() and not btn._nduiSkinned then
                btn._nduiSkinned = true
                pcall(function()
                    B.CreateBD(btn, 1)
                end)
            end
            return btn
        end
    end

    -- -------------------------------------------------------
-- Hook CreateSegmentedControl: segmented controls -> NDui CreateBDFrame
    -- -------------------------------------------------------
    if RevUI.CreateSegmentedControl then
        local origCreateSegmentedControl = RevUI.CreateSegmentedControl
        RevUI.CreateSegmentedControl = function(self, parent, width, items, currentValue, onChange)
            local container = origCreateSegmentedControl(self, parent, width, items, currentValue, onChange)
            if container and InitNDui() and not container._nduiSkinned then
                container._nduiSkinned = true
                pcall(function()
                    B.CreateBD(container, 0)
                end)
            end
            return container
        end
    end

    -- -------------------------------------------------------
-- Hook CreateSidebarItemBase: sidebar navigation items -> light NDui skinning
-- Preserve the original visual design and only add a subtle NDui-style border.
    -- -------------------------------------------------------
    if RevUI.CreateSidebarItemBase then
        local origCreateSidebarItemBase = RevUI.CreateSidebarItemBase
        RevUI.CreateSidebarItemBase = function(self, parent)
            local btn = origCreateSidebarItemBase(self, parent)
            if btn and InitNDui() and not btn._nduiSkinned then
                btn._nduiSkinned = true
-- Light skin: only add an NDui background frame, keeping the original gradient/glacier-blue effect.
                pcall(function()
                    local bg = B.CreateBDFrame(btn, 0)
                    bg:SetAllPoints()
-- Keep the border hidden by default to preserve the original look.
                    bg:SetBackdropBorderColor(0, 0, 0, 0)
                    btn.__nduiBg = bg
                end)
            end
            return btn
        end
    end

    -- -------------------------------------------------------
-- Hook CreateCategoryHeaderBase: sidebar category headers -> light NDui skinning
    -- -------------------------------------------------------
    if RevUI.CreateCategoryHeaderBase then
        local origCreateCategoryHeaderBase = RevUI.CreateCategoryHeaderBase
        RevUI.CreateCategoryHeaderBase = function(self, parent)
            local btn = origCreateCategoryHeaderBase(self, parent)
            if btn and InitNDui() and not btn._nduiSkinned then
                btn._nduiSkinned = true
                pcall(function()
                    local bg = B.CreateBDFrame(btn, 0)
                    bg:SetAllPoints()
                    bg:SetBackdropColor(0.1, 0.1, 0.12, 0.3)
                    bg:SetBackdropBorderColor(0, 0, 0, 0)
                    btn.__nduiBg = bg
                end)
            end
            return btn
        end
    end

    -- -------------------------------------------------------
-- Hook CreateMainFrame: skin immediately after panel creation
    -- -------------------------------------------------------
    if RevUI.CreateMainFrame then
        hooksecurefunc(RevUI, "CreateMainFrame", function()
            SkinMainPanel()
        end)
    end

    -- -------------------------------------------------------
-- Hook Toggle: fallback to ensure the panel is skinned on first display
    -- -------------------------------------------------------
    if RevUI.Toggle then
        hooksecurefunc(RevUI, "Toggle", function()
            if RevUI.MainFrame and not skinApplied then
                SkinMainPanel()
            end
-- Delay skinning of scrollbars that may be created later.
            SkinScrollBarsDeferred()
        end)
    end

    -- -------------------------------------------------------
-- Hook ShowModuleSettingsPage: skin the scrollbar after the module settings page is created
    -- -------------------------------------------------------
    if RevUI.ShowModuleSettingsPage then
        hooksecurefunc(RevUI, "ShowModuleSettingsPage", function()
            C_Timer.After(0.05, SkinScrollBarsDeferred)
        end)
    end
end

-- =============================================
-- Initialization entry point
-- =============================================
-- NDui completes OnLogin during PLAYER_LOGIN.
-- Use PLAYER_ENTERING_WORLD to ensure this runs after NDui.

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")

-- Check mutual exclusion again: if ElvUI is ready, abort NDui skinning.
        if InfinityTools.ElvUISkin and InfinityTools.ElvUISkin:IsElvUILoaded() then
            InfinityTools.NDuiSkin = nil
            return
        end

        if InitNDui() then
-- print("|cff00ff00[InfinityTools]|r NDui detected, NDui skin integration enabled")
            HookRevUI()
-- If the panel already exists (rare case), skin it immediately.
            if InfinityTools.UI and InfinityTools.UI.MainFrame then
                SkinMainPanel()
            end
        end
    end
end)

