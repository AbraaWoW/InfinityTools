---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossDisplay/FlashText.lua
--
--   InfinityBoss.UI.FlashText:Show(timer, text, duration)
--   InfinityBoss.UI.FlashText:RefreshVisuals()
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

InfinityBoss.UI.FlashText = InfinityBoss.UI.FlashText or {}
local FlashText  = InfinityBoss.UI.FlashText
local MODULE_KEY = "InfinityBoss.FlashText"

-- =============================================================
-- DB
-- =============================================================
local function DB()
    if InfinityTools.GetModuleDB then
        local ok, mdb = pcall(InfinityTools.GetModuleDB, InfinityTools, MODULE_KEY)
        if ok and type(mdb) == "table" then return mdb end
    end
    local db = _G.InfinityBossDB
    return db and db.timer and db.timer.flashText
end

local function SafeNum(v, def)
    return tonumber(v) or def
end

local function SetClickThrough(frame)
    if not frame then return end
    frame:EnableMouse(false)
    if frame.SetMouseClickEnabled then
        pcall(frame.SetMouseClickEnabled, frame, false)
    end
    if frame.SetMouseMotionEnabled then
        pcall(frame.SetMouseMotionEnabled, frame, false)
    end
end

local FALLBACK_DB = {
    enabled      = false,
    anchorX      = 0,
    anchorY      = 105,
    flashDuration = 2.5,
    font_flash = {
        font    = "Default",
        size    = 46,
        outline = "OUTLINE",
        r = 1.0, g = 1.0, b = 1.0, a = 1.0,
        shadow  = true,
        shadowX = 2,
        shadowY = -2,
        x = 0, y = 0,
    },
}

-- =============================================================
-- =============================================================
local anchorFrame  = nil
local textFrame    = nil
local isPreviewing = false

local _dir      = 0
local _elapsed  = 0
local _holdTime = 0
local _updateFrame = nil
local _holdTimer   = nil

local FADE_IN_TIME  = 0.20
local FADE_OUT_TIME = 0.45

-- =============================================================
-- =============================================================
local function ApplyFont(fs, fontDB)
    if not fs or not fontDB then return end
    local StaticDB = InfinityTools.DB_Static
    if StaticDB and StaticDB.ApplyFont then
        StaticDB:ApplyFont(fs, fontDB)
        return
    end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local path = (LSM and fontDB.font and fontDB.font ~= "Default")
                 and LSM:Fetch("font", fontDB.font)
                 or (InfinityTools.MAIN_FONT or STANDARD_TEXT_FONT)
    local size    = SafeNum(fontDB.size, 46)
    local outline = fontDB.outline or "OUTLINE"
    fs:SetFont(path, size, outline)
    fs:SetTextColor(
        SafeNum(fontDB.r, 1),
        SafeNum(fontDB.g, 1),
        SafeNum(fontDB.b, 1),
        SafeNum(fontDB.a, 1)
    )
    if fontDB.shadow then
        fs:SetShadowOffset(SafeNum(fontDB.shadowX, 2), SafeNum(fontDB.shadowY, -2))
        fs:SetShadowColor(0, 0, 0, 1)
    else
        fs:SetShadowOffset(0, 0)
    end
end

-- =============================================================
-- =============================================================
local function CreateFrames()
    if anchorFrame then return end
    local db = DB() or FALLBACK_DB
    local x = SafeNum(db.anchorX, 0)
    local y = SafeNum(db.anchorY, 105)

    anchorFrame = CreateFrame("Frame", "InfinityBoss_FlashTextAnchor", UIParent, "BackdropTemplate")
    anchorFrame:SetSize(600, 80)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(false)
    anchorFrame:SetFrameStrata("DIALOG")
    SetClickThrough(anchorFrame)

    local editOverlay = anchorFrame:CreateTexture(nil, "ARTWORK")
    editOverlay:SetAllPoints()
    editOverlay:SetColorTexture(0, 0.8, 0, 0.20)
    editOverlay:Hide()
    anchorFrame.EditOverlay = editOverlay

    local editLabel = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editLabel:SetPoint("TOP", anchorFrame, "TOP", 0, -4)
    editLabel:SetText("|cff00ff00[Flash Text]|r")
    editLabel:Hide()
    anchorFrame.EditLabel = editLabel

    anchorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and InfinityTools.GlobalEditMode then
            self.isMoving = true
            self:StartMoving()
        elseif button == "RightButton" and InfinityTools.GlobalEditMode then
            InfinityTools:OpenConfig(MODULE_KEY)
        end
    end)
    anchorFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self.isMoving = false
            self:StopMovingOrSizing()
            local cx, cy = UIParent:GetCenter()
            local sx, sy = self:GetCenter()
            if sx and cx then
                local ddb = DB()
                if ddb then
                    ddb.anchorX = math.floor(sx - cx)
                    ddb.anchorY = math.floor(sy - cy)
                end
            end
        end
    end)

    InfinityTools:RegisterHUD(MODULE_KEY, anchorFrame)
    SetClickThrough(anchorFrame)

    textFrame = CreateFrame("Frame", nil, anchorFrame)
    textFrame:SetAllPoints(anchorFrame)
    textFrame:SetFrameStrata("DIALOG")
    SetClickThrough(textFrame)

    local fs = textFrame:CreateFontString(nil, "OVERLAY")
    fs:SetAllPoints()
    fs:SetJustifyH("CENTER")
    fs:SetJustifyV("MIDDLE")
    textFrame.Text = fs
    textFrame:SetAlpha(0)
    textFrame:Hide()

    ApplyFont(fs, db.font_flash or FALLBACK_DB.font_flash)

    _updateFrame = CreateFrame("Frame", nil, anchorFrame)
    _updateFrame:Hide()
    SetClickThrough(_updateFrame)
    _updateFrame:SetScript("OnUpdate", function(_, elapsed)
        if _dir == 0 then return end
        _elapsed = _elapsed + elapsed
        if _dir == 1 then
            local a = math.min(1, _elapsed / FADE_IN_TIME)
            textFrame:SetAlpha(a)
            if a >= 1 then
                _dir = 0
                _elapsed = 0
                local db2 = DB() or FALLBACK_DB
                local dur  = SafeNum(db2.flashDuration, 2.5)
                local hold = math.max(0.05, dur - FADE_IN_TIME - FADE_OUT_TIME)
                if _holdTimer then _holdTimer:Cancel() end
                _holdTimer = C_Timer.NewTimer(hold, function()
                    if textFrame:IsShown() and not isPreviewing then
                        _dir = -1
                        _elapsed = 0
                    end
                end)
            end
        elseif _dir == -1 then
            local a = math.max(0, 1 - _elapsed / FADE_OUT_TIME)
            textFrame:SetAlpha(a)
            if a <= 0 then
                _dir = 0
                textFrame:Hide()
                _updateFrame:Hide()
                if textFrame.Text then textFrame.Text:SetText("") end
            end
        end
    end)
end

-- =============================================================
-- =============================================================
local function StopFlash()
    _dir = 0
    if _holdTimer then _holdTimer:Cancel(); _holdTimer = nil end
    if textFrame then
        textFrame:SetAlpha(0)
        textFrame:Hide()
        if textFrame.Text then textFrame.Text:SetText("") end
    end
    if _updateFrame then _updateFrame:Hide() end
end

-- =============================================================
-- =============================================================
local function SetEditMode(enabled)
    if not anchorFrame then CreateFrames() end
    if enabled then
        anchorFrame:EnableMouse(true)
        if anchorFrame.EditOverlay then anchorFrame.EditOverlay:Show() end
        if anchorFrame.EditLabel   then anchorFrame.EditLabel:Show()   end
        isPreviewing = true
        StopFlash()
        if textFrame then
            if textFrame.Text then textFrame.Text:SetText("Spell Name Example") end
            textFrame:SetAlpha(0.9)
            textFrame:Show()
        end
    else
        SetClickThrough(anchorFrame)
        if anchorFrame.EditOverlay then anchorFrame.EditOverlay:Hide() end
        if anchorFrame.EditLabel   then anchorFrame.EditLabel:Hide()   end
        isPreviewing = false
        StopFlash()
    end
end

InfinityTools:RegisterEditModeCallback(MODULE_KEY, SetEditMode)

-- =============================================================
-- =============================================================
local function RefreshStyle()
    if not anchorFrame then return end
    local db = DB() or FALLBACK_DB
    anchorFrame:ClearAllPoints()
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER",
        SafeNum(db.anchorX, 0), SafeNum(db.anchorY, 105))
    if textFrame and textFrame.Text then
        ApplyFont(textFrame.Text, db.font_flash or FALLBACK_DB.font_flash)
    end
end

-- =============================================================
-- =============================================================
function FlashText:Show(timer, text, duration)
    local db = DB() or FALLBACK_DB
    if db.enabled == false then return end
    if not anchorFrame then CreateFrames() end
    if isPreviewing then return end

    StopFlash()

    if textFrame and textFrame.Text then
        ApplyFont(textFrame.Text, db.font_flash or FALLBACK_DB.font_flash)
        if type(timer) == "table" and type(timer.flashTextColor) == "table" then
            local c = timer.flashTextColor
            local r = tonumber(c.r)
            local g = tonumber(c.g)
            local b = tonumber(c.b)
            if r and g and b then
                textFrame.Text:SetTextColor(r, g, b, tonumber(c.a) or 1)
            end
        end
    end

    if textFrame and textFrame.Text then
        textFrame.Text:SetText(text or "")
    end
    if duration then
        local db2 = DB() or FALLBACK_DB
        db2._overrideDuration = duration
    end
    textFrame:SetAlpha(0)
    textFrame:Show()
    _dir     = 1
    _elapsed = 0
    if _updateFrame then _updateFrame:Show() end
end

function FlashText:Stop()
    StopFlash()
end

function FlashText:RefreshVisuals()
    RefreshStyle()
    if isPreviewing and textFrame then
        textFrame:SetAlpha(0.9)
        textFrame:Show()
    end
end

-- =============================================================
-- =============================================================
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", MODULE_KEY .. "_init", function()
    C_Timer.After(0.5, function()
        CreateFrames()
        RefreshStyle()
    end)
end)

