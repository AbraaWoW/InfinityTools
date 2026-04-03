---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossDisplay/RingProgress.lua
-- =============================================================

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

InfinityBoss.UI.RingProgress = InfinityBoss.UI.RingProgress or {}
local Ring = InfinityBoss.UI.RingProgress

local MODULE_KEY = "InfinityBoss.RingProgress"

local DEFAULTS = {
    enabled = false,
    style = "thin1", -- thin1 | thin2 | classic
    size = 170,
    alpha = 0.95,
    ringColorR = 0.1,
    ringColorG = 0.8,
    ringColorB = 1.0,
    ringColorA = 1.0,
    anchorX = 0,
    anchorY = 0,
}

local STYLE_TEXTURES = {
    thin1 = "Interface\\AddOns\\InfinityBoss\\InfinityBossDisplay\Textures\\RingWhiteThin1",
    thin2 = "Interface\\AddOns\\InfinityBoss\\InfinityBossDisplay\Textures\\RingWhiteThin2",
    classic = "Interface\\AddOns\\InfinityBoss\\InfinityBossDisplay\Textures\\RingWhite",
}

local frame
local cd
local editOverlay
local editLabel
local isEditMode = false
local editTicker = nil

local function SafeNum(v, def)
    local n = tonumber(v)
    if n == nil then
        return def
    end
    return n
end

local function Clamp01(v, def)
    local n = tonumber(v)
    if n == nil then
        n = tonumber(def)
    end
    if n == nil then
        n = 1
    end
    if n < 0 then n = 0 end
    if n > 1 then n = 1 end
    return n
end

local function SetClickThrough(obj)
    if not obj then return end
    obj:EnableMouse(false)
    if obj.SetMouseClickEnabled then
        pcall(obj.SetMouseClickEnabled, obj, false)
    end
    if obj.SetMouseMotionEnabled then
        pcall(obj.SetMouseMotionEnabled, obj, false)
    end
end

local function DB()
    if InfinityTools.GetModuleDB then
        local ok, mdb = pcall(InfinityTools.GetModuleDB, InfinityTools, MODULE_KEY, DEFAULTS)
        if ok and type(mdb) == "table" then
            return mdb
        end
    end

    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    InfinityBossDB.timer.ringProgress = InfinityBossDB.timer.ringProgress or {}
    local db = InfinityBossDB.timer.ringProgress
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then
            db[k] = v
        end
    end
    return db
end

local function GetTexturePath(style)
    style = tostring(style or ""):lower()
    return STYLE_TEXTURES[style] or STYLE_TEXTURES.thin1
end

local function GetConfiguredColor(db)
    return Clamp01(db.ringColorR, DEFAULTS.ringColorR),
           Clamp01(db.ringColorG, DEFAULTS.ringColorG),
           Clamp01(db.ringColorB, DEFAULTS.ringColorB)
end

local function ApplyVisuals()
    if not frame then return end
    local db = DB()
    local size = SafeNum(db.size, DEFAULTS.size)
    if size < 80 then size = 80 end
    if size > 360 then size = 360 end

    frame:SetSize(size, size)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", SafeNum(db.anchorX, 0), SafeNum(db.anchorY, 0))

    if cd and cd.SetSwipeTexture then
        cd:SetSwipeTexture(GetTexturePath(db.style))
    end
    if cd and cd.SetSwipeColor then
        local r, g, b = GetConfiguredColor(db)
        cd:SetSwipeColor(r, g, b, Clamp01(db.alpha, DEFAULTS.alpha))
    end
end

local function ClearCooldownBackgrounds()
    if not cd then return end
    local regionCount = cd:GetNumRegions() or 0
    for i = 1, regionCount do
        local region = select(i, cd:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local layer = region.GetDrawLayer and region:GetDrawLayer() or nil
            if region.SetBlendMode then
                region:SetBlendMode("ADD")
            end
            if layer == "BACKGROUND" and region.SetColorTexture then
                region:SetColorTexture(0, 0, 0, 0)
            end
        end
    end
end

local function Ensure()
    if frame then
        return
    end

    local db = DB()
    frame = CreateFrame("Frame", "InfinityBoss_RingProgress", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(false)
    SetClickThrough(frame)
    frame:Hide()

    editOverlay = frame:CreateTexture(nil, "ARTWORK")
    editOverlay:SetAllPoints()
    editOverlay:SetColorTexture(0, 0.8, 0, 0.18)
    editOverlay:Hide()

    editLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editLabel:SetPoint("TOP", frame, "TOP", 0, -4)
    editLabel:SetText("|cff00ff00[Ring Progress]|r")
    editLabel:Hide()

    frame:SetScript("OnMouseDown", function(self, button)
        if not InfinityTools.GlobalEditMode then return end
        if button == "LeftButton" then
            self.isMoving = true
            self:StartMoving()
        elseif button == "RightButton" then
            InfinityTools:OpenConfig(MODULE_KEY)
        end
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self.isMoving = false
            self:StopMovingOrSizing()
            local cx, cy = UIParent:GetCenter()
            local sx, sy = self:GetCenter()
            if sx and cx then
                local mdb = DB()
                mdb.anchorX = math.floor(sx - cx)
                mdb.anchorY = math.floor(sy - cy)
            end
        end
    end)

    InfinityTools:RegisterHUD(MODULE_KEY, frame)
    SetClickThrough(frame)

    cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cd:SetAllPoints()
    if cd.SetHideCountdownNumbers then
        cd:SetHideCountdownNumbers(true)
    end
    if cd.SetDrawBling then
        cd:SetDrawBling(false)
    end
    if cd.SetDrawEdge then
        cd:SetDrawEdge(false)
    end
    if cd.SetDrawSwipe then
        cd:SetDrawSwipe(true)
    end
    if cd.SetReverse then
        cd:SetReverse(true)
    end

    ApplyVisuals()
    ClearCooldownBackgrounds()

    if cd.SetSwipeColor then
        local r, g, b = GetConfiguredColor(db)
        cd:SetSwipeColor(r, g, b, Clamp01(db.alpha, DEFAULTS.alpha))
    end
end

local function ShowEditPreview()
    Ring:ShowEntry({
        duration = 3,
        endTime = GetTime() + 3,
    })
end

local function StopEditPreview()
    if editTicker then
        editTicker:Cancel()
        editTicker = nil
    end
end

local function SetEditMode(enabled)
    Ensure()
    isEditMode = (enabled == true)
    if isEditMode then
        frame:EnableMouse(true)
        if frame.SetMouseClickEnabled then pcall(frame.SetMouseClickEnabled, frame, true) end
        if frame.SetMouseMotionEnabled then pcall(frame.SetMouseMotionEnabled, frame, true) end
        if editOverlay then editOverlay:Show() end
        if editLabel then editLabel:Show() end

        ShowEditPreview()
        StopEditPreview()
        editTicker = C_Timer.NewTicker(2.9, function()
            if isEditMode then
                ShowEditPreview()
            end
        end)
    else
        SetClickThrough(frame)
        if editOverlay then editOverlay:Hide() end
        if editLabel then editLabel:Hide() end
        StopEditPreview()
        frame:Hide()
    end
end

InfinityTools:RegisterEditModeCallback(MODULE_KEY, SetEditMode)

function Ring:ShowEntry(entry, forcedRemaining)
    Ensure()
    local db = DB()
    if db.enabled == false then
        frame:Hide()
        return
    end
    if type(entry) ~= "table" then
        frame:Hide()
        return
    end

    local now = GetTime()
    local duration = math.max(0.1, SafeNum(entry.duration, 5))
    local remaining = SafeNum(forcedRemaining, nil)
    if remaining == nil then
        remaining = math.max(0, SafeNum(entry.endTime, now) - now)
    end
    if remaining <= 0 then
        if not isEditMode then
            frame:Hide()
        end
        return
    end

    local elapsed = math.max(0, duration - remaining)
    local startTime = now - elapsed

    local r, g, b = GetConfiguredColor(db)
    if cd.SetSwipeColor then
        cd:SetSwipeColor(r, g, b, Clamp01(db.alpha, DEFAULTS.alpha))
    end
    if cd.SetReverse then
        cd:SetReverse(true)
    end
    cd:SetCooldown(startTime, duration)
    frame:Show()
end

function Ring:Preview(seconds)
    local sec = SafeNum(seconds, 3)
    if sec < 0.2 then sec = 0.2 end
    self:ShowEntry({
        duration = sec,
        endTime = GetTime() + sec,
    })
    C_Timer.After(sec + 0.05, function()
        if not isEditMode then
            Ring:Hide()
        end
    end)
end

function Ring:Hide()
    if frame and not isEditMode then
        frame:Hide()
    end
end

function Ring:RefreshVisuals()
    if not frame then
        return
    end
    ApplyVisuals()
end

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", MODULE_KEY .. "_init", function()
    C_Timer.After(0.5, function()
        Ensure()
        Ring:RefreshVisuals()
    end)
end)
