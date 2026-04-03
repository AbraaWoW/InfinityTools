---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossDisplay/TimerBar/View.lua
--
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local TimerBar      = InfinityBoss.UI.TimerBar
local LSM           = LibStub and LibStub("LibSharedMedia-3.0", true)
local function Factory()
    return _G.InfinityFactory
end

local POOL_TYPE         = "InfinityBoss_TimerBar"
local TEXT_UPDATE_INTERVAL = 0.05
local MODULE_KEY        = "InfinityBoss.TimerBar"
local TEST_PREFIX       = "__rboss_test_"
local LEGACY_EVENT_KEY  = "encounter" .. "EventID"

local anchorFrame  = nil
local activeBars   = {}      -- [timerID] = StatusBar frame
local barList      = {}
local previewBars  = {}
local isPreviewing = false
local _textElapsed = 0
local _sortDirty   = false
local _testSeed    = 0
local testTimers   = {}      -- [timerID] = { castTime, duration }
local CreateAnchor = nil
local _runtimeCache = nil

-- =============================================================
-- =============================================================
local function DB()
    if InfinityTools and InfinityTools.GetModuleDB then
        local ok, mdb = pcall(InfinityTools.GetModuleDB, InfinityTools, MODULE_KEY)
        if ok and type(mdb) == "table" then
            return mdb
        end
    end
    local db = _G.InfinityBossDB
    return db and db.timer and db.timer.timerBar
end

local function SafeNum(v, def)
    local n = tonumber(v)
    if not n then return def end
    return n
end

local DEFAULT_PRIORITY_COLORS = {
    [1] = { r = 1.0, g = 0.2, b = 0.2, a = 1.0 },
    [2] = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
    [3] = { r = 0.6, g = 0.6, b = 0.6, a = 0.6 },
}

local DEFAULT_STYLE = {
    width = 200,
    height = 25,
    texture = "Melli",
    barColorR = 1.0,
    barColorG = 0.7,
    barColorB = 0.0,
    barColorA = 1.0,
    barBgColorR = 0.0,
    barBgColorG = 0.0,
    barBgColorB = 0.0,
    barBgColorA = 0.5,
    showBorder = true,
    borderTexture = "Blizzard Tooltip",
    borderColorR = 1.0,
    borderColorG = 1.0,
    borderColorB = 1.0,
    borderColorA = 1.0,
    borderSize = 10,
    borderPadding = 2,
    showIcon = true,
    iconSide = "LEFT",
    iconSize = 26,
    iconOffsetX = -2,
    iconOffsetY = 0,
}

local DEFAULT_FONT_NAME = {
    font = "Default",
    size = 14,
    r = 1, g = 1, b = 1, a = 1,
    outline = "OUTLINE",
    shadow = false,
    shadowX = 1, shadowY = -1,
    x = 4, y = 0,
}

local DEFAULT_FONT_TIME = {
    font = "Default",
    size = 14,
    r = 1, g = 1, b = 1, a = 1,
    outline = "OUTLINE",
    shadow = false,
    shadowX = 1, shadowY = -1,
    x = 0, y = 0,
}

local function GetStyleDB(db)
    if type(db) == "table" and type(db.timerBarGroup) == "table" then
        return db.timerBarGroup
    end
    return db
end

local function ResolveStyle(db)
    local src = GetStyleDB(db)
    if type(src) ~= "table" then
        return DEFAULT_STYLE
    end

    local style = {}
    for k, v in pairs(DEFAULT_STYLE) do
        if src[k] ~= nil then
            style[k] = src[k]
        else
            style[k] = v
        end
    end
    return style
end

local function Clamp01(v)
    if v <= 0 then return 0 end
    if v >= 1 then return 1 end
    return v
end

local function ResolveFillMode(db)
    local mode = tostring(db and db.fillMode or "RTL_FADE")
    if mode == "LTR_FILL" or mode == "LTR_FADE" or mode == "RTL_FILL" or mode == "RTL_FADE" then
        return mode
    end
    return "RTL_FADE"
end

local function InvalidateRuntimeCache()
    _runtimeCache = nil
end

local function GetRuntimeCache()
    if _runtimeCache then
        return _runtimeCache
    end
    local db = DB() or {}
    local style = ResolveStyle(db)
    local h = SafeNum(style.height, DEFAULT_STYLE.height)
    if h < 8 then h = 8 end
    local spacing = SafeNum(db and db.spacing, 3)
    if spacing < 0 then spacing = 0 end
    local maxBars = SafeNum(db and db.maxBars, 10)
    if maxBars < 1 then maxBars = 1 end
    _runtimeCache = {
        fillMode = ResolveFillMode(db),
        height = h,
        spacing = spacing,
        growDir = (db and db.growDir) or "DOWN",
        maxBars = maxBars,
    }
    return _runtimeCache
end


local function IsFillIncreasing(fillMode)
    return fillMode == "LTR_FILL" or fillMode == "RTL_FILL"
end

local function IsReverseFill(fillMode)
    return fillMode == "LTR_FADE" or fillMode == "RTL_FILL"
end

local function ApplyBarProgress(bar, remaining, duration, fillMode)
    if not bar then return end
    local d = math.max(1, tonumber(duration) or 1)
    local rem = math.max(0, tonumber(remaining) or 0)
    local ratio = rem / d
    if IsFillIncreasing(fillMode) then
        ratio = 1 - ratio
    end
    bar:SetValue(Clamp01(ratio))
end

local function ResolveColor(style, key, fallback)
    local def = fallback or { r = 1, g = 1, b = 1, a = 1 }
    if type(style) ~= "table" then
        return def.r, def.g, def.b, def.a
    end
    local r = tonumber(style[key .. "R"])
    local g = tonumber(style[key .. "G"])
    local b = tonumber(style[key .. "B"])
    local a = tonumber(style[key .. "A"])
    if r and g and b then
        return r, g, b, a or def.a
    end
    local t = style[key]
    if type(t) == "table" then
        r = tonumber(t.r)
        g = tonumber(t.g)
        b = tonumber(t.b)
        a = tonumber(t.a)
        if r and g and b then
            return r, g, b, a or def.a
        end
    end
    return def.r, def.g, def.b, def.a
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

local function ResolveTimerEventID(timer)
    if type(timer) ~= "table" then return nil end
    local eventID = tonumber(timer.eventID)
    if eventID then return eventID end
    return tonumber(rawget(timer, LEGACY_EVENT_KEY))
end

local function SafeExtractRGB(c)
    if type(c) ~= "table" then return nil end
    local r = tonumber(c.r)
    local g = tonumber(c.g)
    local b = tonumber(c.b)
    if r and g and b then
        return r, g, b
    end
    if type(c.GetRGB) == "function" then
        local ok, rr, gg, bb = pcall(c.GetRGB, c)
        if ok and tonumber(rr) and tonumber(gg) and tonumber(bb) then
            return tonumber(rr), tonumber(gg), tonumber(bb)
        end
    end
    return nil
end

-- =============================================================
-- =============================================================
local function InitBarStructure(bar)
    SetClickThrough(bar)
    bar:SetClampedToScreen(true)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetFillStyle(Enum.StatusBarFillStyle.Standard)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bar.BG = bg

    local icon = bar:CreateTexture(nil, "OVERLAY")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    bar.Icon = icon

    local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    bar.NameText = nameText

    local timeText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetJustifyH("RIGHT")
    bar.TimeText = timeText
end

do
    local fac = Factory()
    if fac then
        fac:InitPool(POOL_TYPE, "StatusBar", nil, InitBarStructure)
    end
end

-- =============================================================
-- =============================================================
local function UpdateBarVisuals(bar, priority)
    local db = DB() or {}
    local style = ResolveStyle(db)
    local fillMode = ResolveFillMode(db)
    local staticDB = InfinityTools and InfinityTools.DB_Static

    local w = SafeNum(style.width, DEFAULT_STYLE.width)
    local h = SafeNum(style.height, DEFAULT_STYLE.height)
    if w < 80 then w = 80 end
    if h < 8 then h = 8 end
    bar:SetSize(w, h)

    local texName = style.texture or DEFAULT_STYLE.texture
    local tex = (LSM and LSM:Fetch("statusbar", texName))
                or "Interface\\Buttons\\WHITE8X8"
    bar:SetStatusBarTexture(tex)
    if bar.SetReverseFill then
        bar:SetReverseFill(IsReverseFill(fillMode))
    end

    if bar.BG then
        bar.BG:SetTexture(tex)
        local bgr, bgg, bgb, bga = ResolveColor(style, "barBgColor", {
            r = DEFAULT_STYLE.barBgColorR,
            g = DEFAULT_STYLE.barBgColorG,
            b = DEFAULT_STYLE.barBgColorB,
            a = DEFAULT_STYLE.barBgColorA,
        })
        bar.BG:SetVertexColor(bgr, bgg, bgb, bga)
    end

    local fallbackCol = DEFAULT_PRIORITY_COLORS[priority or 2] or DEFAULT_PRIORITY_COLORS[2]
    local r, g, b, a = ResolveColor(style, "barColor", fallbackCol)

    local overrideColor = nil
    if bar and type(bar._eventColor) == "table"
        and tonumber(bar._eventColor.r) and tonumber(bar._eventColor.g) and tonumber(bar._eventColor.b) then
        overrideColor = { r = bar._eventColor.r, g = bar._eventColor.g, b = bar._eventColor.b }
    elseif bar and bar._eventID and C_EncounterEvents and C_EncounterEvents.GetEventColor then
        local ok, c = pcall(C_EncounterEvents.GetEventColor, bar._eventID)
        if ok and c then
            local r, g, b = SafeExtractRGB(c)
            if tonumber(r) and tonumber(g) and tonumber(b) then
                overrideColor = { r = r, g = g, b = b }
            end
        end
    end

    if overrideColor then
        bar:SetStatusBarColor(overrideColor.r, overrideColor.g, overrideColor.b, a)
    else
        bar:SetStatusBarColor(r, g, b, a)
    end

    local edgeTex = nil
    if style.showBorder and style.borderTexture and style.borderTexture ~= "None" then
        edgeTex = LSM and LSM:Fetch("border", style.borderTexture) or nil
    end
    if edgeTex then
        if not bar.BorderFrame then
            bar.BorderFrame = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            bar.BorderFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
        end
        local edgeSize = SafeNum(style.borderSize, DEFAULT_STYLE.borderSize)
        local pad = SafeNum(style.borderPadding, DEFAULT_STYLE.borderPadding)
        bar.BorderFrame:ClearAllPoints()
        bar.BorderFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", -pad, pad)
        bar.BorderFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", pad, -pad)
        bar.BorderFrame:SetBackdrop({
            edgeFile = edgeTex,
            edgeSize = edgeSize,
        })
        local br, bg, bb, ba = ResolveColor(style, "borderColor", {
            r = DEFAULT_STYLE.borderColorR,
            g = DEFAULT_STYLE.borderColorG,
            b = DEFAULT_STYLE.borderColorB,
            a = DEFAULT_STYLE.borderColorA,
        })
        bar.BorderFrame:SetBackdropBorderColor(br, bg, bb, ba)
        bar.BorderFrame:Show()
    elseif bar.BorderFrame then
        bar.BorderFrame:Hide()
    end

    if bar.Icon then
        local iconSize = SafeNum(style.iconSize, h)
        if iconSize < 8 then iconSize = 8 end
        bar.Icon:SetSize(iconSize, iconSize)
        bar.Icon:ClearAllPoints()
        local side = tostring(style.iconSide or DEFAULT_STYLE.iconSide):upper()
        local ox = SafeNum(style.iconOffsetX, DEFAULT_STYLE.iconOffsetX)
        local oy = SafeNum(style.iconOffsetY, DEFAULT_STYLE.iconOffsetY)
        if side == "RIGHT" then
            bar.Icon:SetPoint("LEFT", bar, "RIGHT", ox, oy)
        else
            bar.Icon:SetPoint("RIGHT", bar, "LEFT", ox, oy)
        end
        bar.Icon:SetShown(style.showIcon ~= false)
    end

    if bar.NameText then
        local nameFont = (type(db.font_name) == "table") and db.font_name or DEFAULT_FONT_NAME
        if staticDB and staticDB.ApplyFont then
            staticDB:ApplyFont(bar.NameText, nameFont)
        end
        bar.NameText:ClearAllPoints()
        local nx = SafeNum(nameFont.x, DEFAULT_FONT_NAME.x)
        local ny = SafeNum(nameFont.y, DEFAULT_FONT_NAME.y)
        bar.NameText:SetPoint("LEFT",  bar, "LEFT",   nx, ny)
        bar.NameText:SetPoint("RIGHT", bar, "CENTER", -8, ny)
        bar.NameText:SetShown(db.showName ~= false)
        if type(bar._timerTextColor) == "table" and tonumber(bar._timerTextColor.r) and tonumber(bar._timerTextColor.g) and tonumber(bar._timerTextColor.b) then
            bar.NameText:SetTextColor(bar._timerTextColor.r, bar._timerTextColor.g, bar._timerTextColor.b, tonumber(bar._timerTextColor.a) or 1)
        end
    end

    if bar.TimeText then
        local timeFont = (type(db.font_time) == "table") and db.font_time or DEFAULT_FONT_TIME
        if staticDB and staticDB.ApplyFont then
            staticDB:ApplyFont(bar.TimeText, timeFont)
        end
        bar.TimeText:ClearAllPoints()
        local tx = SafeNum(timeFont.x, DEFAULT_FONT_TIME.x)
        local ty = SafeNum(timeFont.y, DEFAULT_FONT_TIME.y)
        bar.TimeText:SetPoint("RIGHT", bar, "RIGHT", -4 + tx, ty)
        bar.TimeText:SetShown(db.showTimer ~= false)
        if type(bar._timerTextColor) == "table" and tonumber(bar._timerTextColor.r) and tonumber(bar._timerTextColor.g) and tonumber(bar._timerTextColor.b) then
            bar.TimeText:SetTextColor(bar._timerTextColor.r, bar._timerTextColor.g, bar._timerTextColor.b, tonumber(bar._timerTextColor.a) or 1)
        end
    end
end

-- =============================================================
-- Acquire / Release
-- =============================================================
local function AcquireBar(timerID, priority)
    local fac = Factory()
    if not fac or not anchorFrame then return nil end
    local bar = fac:Acquire(POOL_TYPE, anchorFrame)
    bar._timerID   = timerID
    bar._priority  = priority or 2
    bar._castTime  = 0
    bar._duration  = 30
    bar._eventID = nil
    bar._eventColor = nil
    bar._timerTextColor = nil
    bar._isPreview = nil
    bar._isTest    = nil
    SetClickThrough(bar)
    UpdateBarVisuals(bar, priority)
    activeBars[timerID] = bar
    table.insert(barList, bar)
    _sortDirty = true
    return bar
end

local function ReleaseBar(timerID)
    local bar = activeBars[timerID]
    if not bar then return end
    testTimers[timerID] = nil
    activeBars[timerID] = nil
    for i, b in ipairs(barList) do
        if b == bar then table.remove(barList, i); break end
    end
    bar:Hide()
    bar._isPreview = nil
    bar._isTest = nil
    if bar.NameText then bar.NameText:SetText("") end
    if bar.TimeText then bar.TimeText:SetText("") end
    if bar.Icon then bar.Icon:SetTexture(nil) end
    bar:SetScript("OnUpdate", nil)
    local fac = Factory()
    if fac then fac:Release(POOL_TYPE, bar) end
    _sortDirty = true
end

-- =============================================================
-- =============================================================
local _sortBuf = {}
local function ReLayout(nowOverride)
    if not anchorFrame then return end
    local cache   = GetRuntimeCache()
    local h       = cache.height
    local spacing = cache.spacing
    local growDir = cache.growDir
    local maxBars = cache.maxBars
    local now     = nowOverride or GetTime()

    wipe(_sortBuf)
    local list = isPreviewing and previewBars or barList
    for _, bar in ipairs(list) do table.insert(_sortBuf, bar) end

    table.sort(_sortBuf, function(a, b)
        return (a._castTime - now) < (b._castTime - now)
    end)

    for i, bar in ipairs(_sortBuf) do
        bar:ClearAllPoints()
        if i > maxBars then
            bar:Hide()
        else
            bar:Show()
            local offset = (i - 1) * (h + spacing)
            if growDir == "DOWN" then
                bar:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, -offset)
            else
                bar:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMLEFT", 0, offset)
            end
        end
    end
    _sortDirty = false
end

-- =============================================================
-- =============================================================
local function FormatTime(secs)
    if secs >= 60 then
        return string.format("%d:%02d", math.floor(secs / 60), math.floor(secs % 60))
    elseif secs >= 10 then
        return string.format("%.0f", secs)
    else
        return string.format("%.1f", secs)
    end
end

-- =============================================================
-- =============================================================
local function RuntimeTick(elapsed, nowOverride)
    local now = nowOverride or GetTime()
    if _sortDirty then ReLayout(now) end
    if isPreviewing then return end

    _textElapsed = _textElapsed + elapsed
    local updateText = false
    if _textElapsed >= TEXT_UPDATE_INTERVAL then
        _textElapsed = 0
        updateText = true
    end

    local fillMode = GetRuntimeCache().fillMode
    local toRelease = nil

    for timerID, bar in pairs(activeBars) do
        local active = InfinityBoss.Timeline.Scheduler
                       and InfinityBoss.Timeline.Scheduler._active
                       and InfinityBoss.Timeline.Scheduler._active[timerID]
        if not active then
            active = testTimers[timerID]
        end
        if active then
            local remaining = math.max(0, active.castTime - now)
            local duration  = math.max(1, active.timerBarDuration or active.duration or 30)
            ApplyBarProgress(bar, remaining, duration, fillMode)
            if updateText and bar.TimeText and bar.TimeText:IsShown() then
                bar.TimeText:SetText(FormatTime(remaining))
            end
            if remaining <= 0 and testTimers[timerID] then
                if not toRelease then toRelease = {} end
                table.insert(toRelease, timerID)
            end
        else
            if not toRelease then toRelease = {} end
            table.insert(toRelease, timerID)
        end
    end

    if toRelease then
        for _, id in ipairs(toRelease) do ReleaseBar(id) end
    end
end

local _updateFrame = CreateFrame("Frame")
_updateFrame:Hide()
_updateFrame:SetScript("OnUpdate", function(_, elapsed)
    RuntimeTick(elapsed)
end)
TimerBar._updateFrame = _updateFrame

-- =============================================================
-- =============================================================
local function ClearPreviewBars()
    local fac = Factory()
    for i = #previewBars, 1, -1 do
        local bar = previewBars[i]
        bar:Hide()
        bar._isPreview = nil
        if fac then fac:Release(POOL_TYPE, bar) end
        table.remove(previewBars, i)
    end
end

local function ShowPreview()
    ClearPreviewBars()
    local db    = DB()
    local fac   = Factory()
    if not fac then
        return
    end
    local count = SafeNum(db and db.maxBars, 5)
    local fillMode = ResolveFillMode(db)
    if count < 1 then count = 1 end
    if count > 8 then count = 8 end
    local now   = GetTime()
    for i = 1, count do
        if not fac or not anchorFrame then break end
        local bar = fac:Acquire(POOL_TYPE, anchorFrame)
        SetClickThrough(bar)
        bar._isPreview = true
        bar._priority  = ((i - 1) % 3) + 1
        bar._castTime  = now + (count - i + 1) * 5
        bar._duration  = count * 5
        UpdateBarVisuals(bar, bar._priority)
        local remain = (count - i + 1) * 5
        ApplyBarProgress(bar, remain, count * 5, fillMode)
        if bar.NameText then bar.NameText:SetText("Spell Example " .. i) end
        if bar.TimeText  then bar.TimeText:SetText(string.format("%ds", (count - i + 1) * 5)) end
        if bar.Icon      then bar.Icon:SetTexture(136197) end
        table.insert(previewBars, bar)
    end
    ReLayout()
end

local function SetPreviewEnabled(enabled)
    if not anchorFrame then CreateAnchor() end
    enabled = not not enabled
    if enabled == isPreviewing then
        if enabled then
            ShowPreview()
        end
        return
    end

    isPreviewing = enabled
    if enabled then
        for _, bar in pairs(activeBars) do
            bar:Hide()
        end
        ShowPreview()
    else
        ClearPreviewBars()
        for _, bar in pairs(activeBars) do
            bar:Show()
        end
        ReLayout()
    end
end

local function CreateTestBars(count)
    if not anchorFrame then CreateAnchor() end
    if isPreviewing then
        SetPreviewEnabled(false)
    end
    if not Factory() then
        return
    end

    count = math.max(1, math.min(tonumber(count) or 5, 12))
    local now = GetTime()
    for i = 1, count do
        _testSeed = _testSeed + 1
        local timerID   = TEST_PREFIX .. tostring(_testSeed)
        local remaining = 3 + i * 3
        local duration  = math.max(remaining + 6, 12)
        local prio      = ((i - 1) % 3) + 1

        testTimers[timerID] = {
            castTime = now + remaining,
            duration = duration,
        }

        TimerBar:AddTimer({
            id          = timerID,
            barPriority = prio,
            castTime    = now + remaining,
            duration    = duration,
            displayName = "Test Spell " .. i,
            spellID     = 136197,
        })

        local bar = activeBars[timerID]
        if bar then
            bar._isTest = true
        end
    end
    _sortDirty = true
end

local function ClearTestBars()
    local toRelease = {}
    for timerID in pairs(testTimers) do
        table.insert(toRelease, timerID)
    end
    for _, timerID in ipairs(toRelease) do
        testTimers[timerID] = nil
        ReleaseBar(timerID)
    end
end

-- =============================================================
-- =============================================================
CreateAnchor = function()
    if anchorFrame then return end
    local db = DB()
    local style = ResolveStyle(db)
    local x  = SafeNum(db and db.anchorX, -535)
    local y  = SafeNum(db and db.anchorY, -5)
    local w  = SafeNum(style.width, DEFAULT_STYLE.width)
    if w < 80 then w = 80 end

    anchorFrame = CreateFrame("Frame", "InfinityBoss_TimerBarAnchor", UIParent)
    anchorFrame:SetSize(w, 20)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(false)
    anchorFrame:SetFrameStrata("DIALOG")
    SetClickThrough(anchorFrame)

    local bg = anchorFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0.8, 0, 0.4)
    bg:Hide()
    anchorFrame.bg = bg

    local label = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText("|cff00ff00[Timer Bars]|r")
    label:Hide()
    anchorFrame.label = label

    anchorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
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
            if not sx or not sy then
                local l = self:GetLeft()
                local b = self:GetBottom()
                if l and b then
                    sx = l + self:GetWidth() * 0.5
                    sy = b + self:GetHeight() * 0.5
                end
            end
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

    _updateFrame:SetParent(anchorFrame)
    SetClickThrough(_updateFrame)
    _updateFrame:Show()
end

-- =============================================================
-- =============================================================
local function SetEditMode(enabled)
    if not anchorFrame then CreateAnchor() end
    if enabled then
        anchorFrame:EnableMouse(true)
        anchorFrame.bg:Show()
        anchorFrame.label:Show()
        SetPreviewEnabled(true)
    else
        SetClickThrough(anchorFrame)
        anchorFrame.bg:Hide()
        anchorFrame.label:Hide()
        SetPreviewEnabled(false)
    end
end

InfinityTools:RegisterEditModeCallback(MODULE_KEY, SetEditMode)

-- =============================================================
-- =============================================================
function TimerBar:AddTimer(timer)
    if not anchorFrame then CreateAnchor() end
    if activeBars[timer.id] then return end

    local bar = AcquireBar(timer.id, timer.barPriority)
    if not bar then return end

    bar._castTime = timer.castTime
    bar._duration = math.max(1, timer.duration or 30)
    bar._eventID = ResolveTimerEventID(timer)
    bar._eventColor = timer.eventColor
    bar._timerTextColor = timer.timerTextColor
    UpdateBarVisuals(bar, timer.barPriority)

    if bar.Icon and timer.spellID then
        local info = C_Spell.GetSpellInfo(timer.spellID)
        if info and info.iconID then
            bar.Icon:SetTexture(info.iconID)
        elseif timer.iconFileID then
            bar.Icon:SetTexture(timer.iconFileID)
        end
    elseif bar.Icon and timer.iconFileID then
        bar.Icon:SetTexture(timer.iconFileID)
    end

    local name = timer.timerBarName or timer.displayName
    if not name and timer.spellID then
        local info = C_Spell.GetSpellInfo(timer.spellID)
        name = info and info.name
    end
    if bar.NameText then bar.NameText:SetText(name or "???") end
    ApplyBarProgress(
        bar,
        math.max(0, timer.castTime - GetTime()),
        math.max(1, timer.duration or 30),
        GetRuntimeCache().fillMode
    )

    bar:Show()
    _sortDirty = true
end

function TimerBar:OnPreAlert(timer)
end

function TimerBar:OnCast(timer)
    ReleaseBar(timer.id)
end

function TimerBar:ReleaseAll()
    ClearTestBars()
    for timerID in pairs(activeBars) do
        ReleaseBar(timerID)
    end
end

function TimerBar:RefreshVisuals()
    local db = DB() or {}
    local style = ResolveStyle(db)
    InvalidateRuntimeCache()
    for _, bar in pairs(activeBars) do
        UpdateBarVisuals(bar, bar._priority)
    end
    if isPreviewing then
        ShowPreview()
    else
        ReLayout()
    end
    if anchorFrame and db.anchorX ~= nil then
        local x = SafeNum(db.anchorX, -535)
        local y = SafeNum(db.anchorY, -5)
        local w = SafeNum(style.width, DEFAULT_STYLE.width)
        if w < 80 then w = 80 end
        anchorFrame:ClearAllPoints()
        anchorFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
        anchorFrame:SetWidth(w)
    end
end

function TimerBar:SetPreviewEnabled(enabled)
    SetPreviewEnabled(enabled)
end

function TimerBar:TogglePreview()
    SetPreviewEnabled(not isPreviewing)
end

function TimerBar:CreateTestBars(count)
    CreateTestBars(count)
end

function TimerBar:ClearTestBars()
    ClearTestBars()
end

-- =============================================================
-- =============================================================
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", MODULE_KEY .. "_init", function()
    C_Timer.After(0.5, function()
        CreateAnchor()
    end)
end)

function TimerBar:OnRuntimeTick(elapsed, now)
    RuntimeTick(elapsed, now)
end

TimerBar._active = activeBars

