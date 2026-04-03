---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossDisplay/BunBar/View.lua
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local BunBar                = InfinityBoss.UI.BunBar
local LSM                   = LibStub and LibStub("LibSharedMedia-3.0", true)

local MODULE_KEY            = "InfinityBoss.BunBar"
local POOL_TYPE             = "InfinityBoss_BunBarNode"
local TEXT_UPDATE_INTERVAL  = 0.05
local POSITION_SMOOTH_TIME  = 0.10
local ACTIVE_WINDOW_SECS    = 20
local QUEUE_HIDE_SECS       = 30
local SUDDEN_INTRO_OFFSET_X = 28
local SUDDEN_INTRO_DURATION = 0.45
local QUEUE_INTRO_OFFSET_Y  = 22
local QUEUE_INTRO_DURATION  = 0.22
local OUTRO_DURATION        = 0.20
local OUTRO_FADE_DURATION   = 0.20
local OUTRO_SCALE_TO        = 1.35
local FIVE_SEC_MARK_REMAIN  = 5
local PREVIEW_PREFIX        = "__rboss_bun_preview_"
local TEST_PREFIX           = "__rboss_bun_test_"
local LEGACY_EVENT_KEY      = "encounter" .. "EventID"

local function Factory()
    return _G.InfinityFactory
end

local function DB()
    if InfinityTools and InfinityTools.GetModuleDB then
        local ok, mdb = pcall(InfinityTools.GetModuleDB, InfinityTools, MODULE_KEY)
        if ok and type(mdb) == "table" then
            if mdb.layoutMode ~= "Single" then mdb.layoutMode = "Single" end
            if mdb.axis ~= "Vertical" then mdb.axis = "Vertical" end
            mdb.maxTracks = 1
            if mdb.moveDir ~= "Up" and mdb.moveDir ~= "Down" then
                mdb.moveDir = "Down"
            end
            return mdb
        end
    end
    local db = _G.InfinityBossDB
    local bdb = db and db.timer and db.timer.bunBar
    if type(bdb) == "table" then
        if bdb.layoutMode ~= "Single" then bdb.layoutMode = "Single" end
        if bdb.axis ~= "Vertical" then bdb.axis = "Vertical" end
        bdb.maxTracks = 1
        if bdb.moveDir ~= "Up" and bdb.moveDir ~= "Down" then
            bdb.moveDir = "Down"
        end
    end
    return bdb
end

local function SafeNum(v, def)
    local n = tonumber(v)
    if not n then return def end
    return n
end

local function Clamp01(v, def)
    local n = tonumber(v)
    if n == nil then n = tonumber(def) end
    if n == nil then n = 1 end
    if n < 0 then return 0 end
    if n > 1 then return 1 end
    return n
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

local function Saturate(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

local function EaseOutCubic(t)
    t = Saturate(t)
    if EasingUtil and EasingUtil.OutCubic then
        return EasingUtil.OutCubic(t)
    end
    local inv = 1 - t
    return 1 - (inv * inv * inv)
end

local function EaseInCubic(t)
    t = Saturate(t)
    if EasingUtil and EasingUtil.InCubic then
        return EasingUtil.InCubic(t)
    end
    return t * t * t
end

local function FallbackDB()
    return {
        enabled     = false,
        anchorX     = -755,
        anchorY     = 120,
        width       = 420,
        iconSize    = 39,
        trackHeight = 49,
        maxTracks   = 1,
        layoutMode  = "Single",
        axis        = "Vertical",
        moveDir     = "Down",
        showIcon    = true,
        showName    = true,
        showTimer   = true,
        hideExternalBossModBars = false,
        font_name   = {
            font = "Default",
            size = 14,
            r = 1, g = 1, b = 1, a = 1,
            outline = "OUTLINE",
            shadow = false,
            shadowX = 1, shadowY = -1,
            side = "RIGHT",
            x = 8, y = 0,
        },
        font_time   = {
            font = "Default",
            size = 14,
            r = 1, g = 1, b = 1, a = 1,
            outline = "OUTLINE",
            shadow = false,
            shadowX = 1, shadowY = -1,
            x = 0, y = 0,
        },
        axisLineWidth = 1,
        axisLineColorR = 1.0,
        axisLineColorG = 1.0,
        axisLineColorB = 1.0,
        axisLineColorA = 0.20,
        fiveSecLineWidth = 2,
        fiveSecLineColorR = 1.0,
        fiveSecLineColorG = 0.90,
        fiveSecLineColorB = 0.35,
        fiveSecLineColorA = 0.85,
        showBg      = true,
        showBorder  = false,
        bgSettings  = {
            texture       = "Solid",
            bgColorR      = 0.05098039656877518,
            bgColorG      = 0.05882353335618973,
            bgColorB      = 0.0784313753247261,
            bgColorA      = 0.6949490904808044,
            borderTexture = "Blizzard Dialog",
            borderColorR  = 0.9372549653053284,
            borderColorG  = 1.0,
            borderColorB  = 0.9137255549430847,
            borderColorA  = 0.3499999940395355,
            edgeSize      = 1,
            inset         = 0,
        },
        colors      = {
            [1] = { r = 1.0, g = 0.2, b = 0.2, a = 1.0 },
            [2] = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },
            [3] = { r = 0.6, g = 0.6, b = 0.6, a = 0.6 },
        },
    }
end

local DEFAULT_FONT_NAME = {
    font = "Default",
    size = 14,
    r = 1, g = 1, b = 1, a = 1,
    outline = "OUTLINE",
    shadow = false,
    shadowX = 1, shadowY = -1,
    side = "RIGHT",
    x = 8, y = 0,
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

local anchorFrame = nil
local activeNodes = {}     -- [timerID] = frame
local nodeList = {}
local syntheticTimers = {} -- [timerID] = timer
local previewIDs = {}      -- [timerID] = true
local testIDs = {}         -- [timerID] = true
local isPreviewing = false
local _textElapsed = 0
local _sortDirty = false
local _testSeed = 0
local _updateFrame = nil
local _runtimeConfig = nil

local function InvalidateRuntimeConfig()
    _runtimeConfig = nil
end

local function GetRuntimeConfig()
    if _runtimeConfig then
        return _runtimeConfig
    end
    local db = DB() or FallbackDB()
    _runtimeConfig = {
        timelineLen = math.max(120, SafeNum(db.width, 420)),
        moveDir = db.moveDir or "Down",
        iconSize = math.max(10, SafeNum(db.iconSize, 39)),
        trackHeight = math.max(16, SafeNum(db.trackHeight, 49)),
        showName = (db.showName ~= false),
        showTimer = (db.showTimer ~= false),
    }
    return _runtimeConfig
end


local function ShouldShowAnchor()
    if isPreviewing then
        return true
    end
    if InfinityTools and InfinityTools.GlobalEditMode then
        return true
    end
    return next(activeNodes) ~= nil
end

local function RefreshAnchorVisibility()
    if not anchorFrame then return end
    local show = ShouldShowAnchor()
    if show then
        anchorFrame:Show()
        if _updateFrame then
            _updateFrame:Show()
        end
    else
        if _updateFrame then
            _updateFrame:Hide()
        end
        anchorFrame:Hide()
    end
end

local function FormatTime(secs)
    if secs >= 60 then
        return string.format("%d:%02d", math.floor(secs / 60), math.floor(secs % 60))
    end
    return string.format("%d", math.max(0, math.ceil(secs)))
end

local function UpdateTimeTextBounds(node, text, iconSize, fontSize)
    if not (node and node.TimeText) then return end
    local baseWidth = math.max((iconSize or 0) - 4, 10)
    local size = tonumber(fontSize) or DEFAULT_FONT_TIME.size
    local charCount = math.max(2, tostring(text or ""):len())
    local width = math.max(baseWidth, math.ceil(charCount * size * 0.95 + math.max(10, size * 0.8)))
    local height = math.max(10, math.floor(math.max((iconSize or 0) * 0.42, size * 1.15)))
    node.TimeText:SetWidth(width)
    if node.TimeBG then
        node.TimeBG:SetSize(width, height)
    end
end

local function RecommendSpacingSeconds(db)
    local iconSize = math.max(10, SafeNum(db and db.iconSize, 39))
    local timelineLen = math.max(120, SafeNum(db and db.width, 420))
    local needPixels = iconSize + 2
    return math.max(0.5, (needPixels * ACTIVE_WINDOW_SECS) / timelineLen)
end

local function InitNodeStructure(node)
    node:SetSize(36, 36)
    SetClickThrough(node)

    local bg = node:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.45)
    node.IconBG = bg

    local icon = node:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    node.Icon = icon

    local nameText = node:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    node.NameText = nameText

    local timeBG = node:CreateTexture(nil, "OVERLAY")
    timeBG:SetColorTexture(0, 0, 0, 0.55)
    node.TimeBG = timeBG

    local timeText = node:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetJustifyH("CENTER")
    timeText:SetWordWrap(false)
    if timeText.SetNonSpaceWrap then
        timeText:SetNonSpaceWrap(false)
    end
    node.TimeText = timeText
end

local function StartOutro(node)
    if not node or node._outroEnd then return end
    local now = GetTime()
    local startX = node._displayX
    local startY = node._displayY
    if (startX == nil or startY == nil) and node.GetPoint then
        local _p, _r, _rp, ox, oy = node:GetPoint(1)
        if ox and oy then
            startX = startX or ox
            startY = startY or (-oy)
        end
    end
    if not startX then startX = 0 end
    if not startY then startY = 0 end

    node._outroStart = now
    node._outroEnd = now + OUTRO_DURATION
    node._outroFromX = startX
    node._outroFromY = startY
    node._introKind = nil
    node._introStart = nil
    node._introEnd = nil
    node._introFromX = nil
    node._introFromY = nil
end

local function UpdateOutro(node, now)
    if not node or not node._outroEnd then return false end
    if now >= node._outroEnd then
        return true
    end
    local elapsed = math.max(0, now - (node._outroStart or now))

    local alphaProgress = Saturate(elapsed / math.max(0.01, OUTRO_FADE_DURATION))
    local alphaValue = 1 - EaseInCubic(alphaProgress)
    node:SetAlpha(alphaValue)

    local scaleProgress = Saturate(elapsed / math.max(0.01, OUTRO_DURATION))
    local scaleValue = 1 + (OUTRO_SCALE_TO - 1) * EaseOutCubic(scaleProgress)
    local baseX = node._outroFromX or node._displayX or 0
    local baseY = node._outroFromY or node._displayY or 0
    local safeScale = (scaleValue > 0.001) and scaleValue or 0.001
    node._displayX = baseX
    node._displayY = baseY
    node:SetScale(scaleValue)
    if anchorFrame then
        node:ClearAllPoints()
        node:SetPoint("CENTER", anchorFrame, "TOPLEFT", baseX / safeScale, -(baseY / safeScale))
    end
    node:Show()
    return false
end

do
    local fac = Factory()
    if fac then
        fac:InitPool(POOL_TYPE, "Frame", nil, InitNodeStructure)
    end
end

local function GetRuntimeTimer(timerID)
    local sched = InfinityBoss.Timeline.Scheduler
    local active = sched and sched._active and sched._active[timerID]
    if active then return active end
    return syntheticTimers[timerID]
end

local function FetchLSM(mediaType, key, fallbackPath)
    if key == "None" or key == "" then
        return nil
    end
    if LSM and key then
        local path = LSM:Fetch(mediaType, key, true)
        if path then
            return path
        end
    end
    return fallbackPath
end

local function ApplyAnchorSkin()
    if not anchorFrame then return end
    local db = DB() or FallbackDB()
    local conf = db.bgSettings or {}
    local inset = math.max(0, SafeNum(conf.inset, 2))

    anchorFrame:SetBackdrop({
        bgFile = (db.showBg ~= false) and FetchLSM("background", conf.texture, "Interface\\Buttons\\WHITE8X8") or nil,
        edgeFile = (db.showBorder ~= false) and
        FetchLSM("border", conf.borderTexture, "Interface\\Tooltips\\UI-Tooltip-Border") or nil,
        edgeSize = math.max(1, SafeNum(conf.edgeSize, 8)),
        insets = { left = inset, right = inset, top = inset, bottom = inset },
    })

    local r = SafeNum(conf.bgColorR, 0.05)
    local g = SafeNum(conf.bgColorG, 0.06)
    local b = SafeNum(conf.bgColorB, 0.08)
    local a = SafeNum(conf.bgColorA, 0.55)
    local br = SafeNum(conf.borderColorR, 1)
    local bg = SafeNum(conf.borderColorG, 1)
    local bb = SafeNum(conf.borderColorB, 1)
    local ba = SafeNum(conf.borderColorA, 0.35)
    anchorFrame:SetBackdropColor(r, g, b, (db.showBg ~= false) and a or 0)
    anchorFrame:SetBackdropBorderColor(br, bg, bb, (db.showBorder ~= false) and ba or 0)
end

local function UpdateAnchorVisuals()
    if not anchorFrame then return end
    local db = DB() or FallbackDB()

    local timelineLen = math.max(120, SafeNum(db.width, 420))
    local trackHeight = math.max(16, SafeNum(db.trackHeight, 49))
    local trackCount = 1
    local crossLen = trackHeight * trackCount

    ApplyAnchorSkin()

    anchorFrame:SetSize(crossLen, timelineLen)
    if anchorFrame.AxisLine then
        local axisWidth = math.max(1, SafeNum(db.axisLineWidth, 1))
        local axisR = Clamp01(db.axisLineColorR, 1.0)
        local axisG = Clamp01(db.axisLineColorG, 1.0)
        local axisB = Clamp01(db.axisLineColorB, 1.0)
        local axisA = Clamp01(db.axisLineColorA, 0.20)
        anchorFrame.AxisLine:ClearAllPoints()
        anchorFrame.AxisLine:SetPoint("TOP", anchorFrame, "TOPLEFT", crossLen * 0.5, 0)
        anchorFrame.AxisLine:SetSize(axisWidth, timelineLen)
        anchorFrame.AxisLine:SetColorTexture(axisR, axisG, axisB, axisA)
    end

    if anchorFrame.FiveSecLine then
        local fiveWidth = math.max(1, SafeNum(db.fiveSecLineWidth, 2))
        local fiveR = Clamp01(db.fiveSecLineColorR, 1.0)
        local fiveG = Clamp01(db.fiveSecLineColorG, 0.90)
        local fiveB = Clamp01(db.fiveSecLineColorB, 0.35)
        local fiveA = Clamp01(db.fiveSecLineColorA, 0.85)
        local remain = math.max(0, math.min(ACTIVE_WINDOW_SECS, FIVE_SEC_MARK_REMAIN))
        local moveDir = db.moveDir or "Down"
        local y
        if moveDir == "Down" then
            y = timelineLen * (1 - (remain / ACTIVE_WINDOW_SECS))
        else
            y = timelineLen * (remain / ACTIVE_WINDOW_SECS)
        end
        anchorFrame.FiveSecLine:ClearAllPoints()
        anchorFrame.FiveSecLine:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, -y)
        anchorFrame.FiveSecLine:SetSize(crossLen, fiveWidth)
        anchorFrame.FiveSecLine:SetColorTexture(fiveR, fiveG, fiveB, fiveA)
        anchorFrame.FiveSecLine:Show()
    end

    InvalidateRuntimeConfig()
end

local function UpdateNodeVisuals(node, priority)
    local db = DB() or FallbackDB()
    local axis = db.axis or "Vertical"
    local iconSize = math.max(10, SafeNum(db.iconSize, 39))
    local col = db.colors and db.colors[priority or 2] or nil
    local staticDB = InfinityTools and InfinityTools.DB_Static
    if not col then col = { r = 1, g = 0.8, b = 0, a = 1 } end

    local overrideColor = nil
    if node and type(node._eventColor) == "table"
        and tonumber(node._eventColor.r) and tonumber(node._eventColor.g) and tonumber(node._eventColor.b) then
        overrideColor = { r = node._eventColor.r, g = node._eventColor.g, b = node._eventColor.b }
    elseif node and node._eventID and C_EncounterEvents and C_EncounterEvents.GetEventColor then
        local ok, c = pcall(C_EncounterEvents.GetEventColor, node._eventID)
        if ok and c then
            local r, g, b = SafeExtractRGB(c)
            if tonumber(r) and tonumber(g) and tonumber(b) then
                overrideColor = { r = r, g = g, b = b }
            end
        end
    end

    local colorR = overrideColor and overrideColor.r or (col.r or 1)
    local colorG = overrideColor and overrideColor.g or (col.g or 1)
    local colorB = overrideColor and overrideColor.b or (col.b or 1)

    node:SetSize(iconSize + 4, iconSize + 4)

    if node.IconBG then
        node.IconBG:ClearAllPoints()
        node.IconBG:SetPoint("CENTER", node, "CENTER", 0, 0)
        node.IconBG:SetSize(iconSize, iconSize)
        node.IconBG:SetVertexColor(colorR, colorG, colorB, (col.a or 1) * 0.85)
    end

    if node.Icon then
        node.Icon:ClearAllPoints()
        node.Icon:SetPoint("CENTER", node, "CENTER", 0, 0)
        node.Icon:SetSize(iconSize - 2, iconSize - 2)
        node.Icon:SetShown(db.showIcon ~= false)
    end

    if node.TimeBG then
        node.TimeBG:ClearAllPoints()
        node.TimeBG:SetPoint("BOTTOM", node.Icon, "BOTTOM", 0, 1)
        node.TimeBG:SetSize(iconSize - 4, math.max(10, math.floor(iconSize * 0.42)))
        node.TimeBG:SetShown(false)
    end

    if node.NameText then
        local nameFont = (type(db.font_name) == "table") and db.font_name or DEFAULT_FONT_NAME
        local side = tostring(nameFont.side or DEFAULT_FONT_NAME.side or "RIGHT"):upper()
        if staticDB and staticDB.ApplyFont then
            staticDB:ApplyFont(node.NameText, nameFont)
        end
        node.NameText:ClearAllPoints()
        local nx = SafeNum(nameFont.x, DEFAULT_FONT_NAME.x)
        local ny = SafeNum(nameFont.y, DEFAULT_FONT_NAME.y)
        if side == "LEFT" then
            node.NameText:SetJustifyH("RIGHT")
            node.NameText:SetPoint("RIGHT", node.Icon, "LEFT", nx, ny)
            node.NameText:SetPoint("LEFT", node.Icon, "LEFT", -200 + nx, ny)
        else
            node.NameText:SetJustifyH("LEFT")
            node.NameText:SetPoint("LEFT", node.Icon, "RIGHT", nx, ny)
            node.NameText:SetPoint("RIGHT", node.Icon, "RIGHT", 200 + nx, ny)
        end
        node.NameText:SetShown((db.showName ~= false) and axis == "Vertical")
        if type(node._timerTextColor) == "table"
            and tonumber(node._timerTextColor.r)
            and tonumber(node._timerTextColor.g)
            and tonumber(node._timerTextColor.b) then
            node.NameText:SetTextColor(
                node._timerTextColor.r,
                node._timerTextColor.g,
                node._timerTextColor.b,
                tonumber(node._timerTextColor.a) or 1
            )
        end
    end

    if node.TimeText then
        local timeFont = (type(db.font_time) == "table") and db.font_time or DEFAULT_FONT_TIME
        if staticDB and staticDB.ApplyFont then
            staticDB:ApplyFont(node.TimeText, timeFont)
        end
        node.TimeText:ClearAllPoints()
        local tx = SafeNum(timeFont.x, DEFAULT_FONT_TIME.x)
        local ty = SafeNum(timeFont.y, DEFAULT_FONT_TIME.y)
        node.TimeText:SetPoint("CENTER", node.Icon, "CENTER", tx, ty)
        UpdateTimeTextBounds(node, node.TimeText:GetText(), iconSize, SafeNum(timeFont.size, DEFAULT_FONT_TIME.size))
        node.TimeText:SetShown(db.showTimer ~= false)
    end
end

local function AcquireNode(timerID, priority)
    local fac = Factory()
    if not fac or not anchorFrame then return nil end
    local node = fac:Acquire(POOL_TYPE, anchorFrame)
    node._timerID = timerID
    node._priority = priority or 2
    node._trackIndex = nil
    node._castTime = 0
    node._duration = 30
    node._eventID = nil
    node._eventColor = nil
    node._timerTextColor = nil
    node._mode = nil
    node._isMovingNow = false
    node._wasMoving = false
    node._isQueuedNow = false
    node._wasQueued = false
    node._introKind = nil
    node._introStart = nil
    node._introEnd = nil
    node._introFromX = nil
    node._introFromY = nil
    node._outroStart = nil
    node._outroEnd = nil
    node._outroFromX = nil
    node._outroFromY = nil
    node._displayX = nil
    node._displayY = nil
    node:SetAlpha(1)
    node:SetScale(1)
    SetClickThrough(node)
    UpdateNodeVisuals(node, node._priority)
    activeNodes[timerID] = node
    table.insert(nodeList, node)
    _sortDirty = true
    return node
end

local function ReleaseNode(timerID)
    local node = activeNodes[timerID]
    if not node then return end

    activeNodes[timerID] = nil
    syntheticTimers[timerID] = nil
    previewIDs[timerID] = nil
    testIDs[timerID] = nil

    for i, n in ipairs(nodeList) do
        if n == node then
            table.remove(nodeList, i)
            break
        end
    end

    node:Hide()
    node._mode = nil
    node._timerTextColor = nil
    node._trackIndex = nil
    node._isMovingNow = nil
    node._wasMoving = nil
    node._isQueuedNow = nil
    node._wasQueued = nil
    node._introKind = nil
    node._introStart = nil
    node._introEnd = nil
    node._introFromX = nil
    node._introFromY = nil
    node._outroStart = nil
    node._outroEnd = nil
    node._outroFromX = nil
    node._outroFromY = nil
    node._displayX = nil
    node._displayY = nil
    node:SetAlpha(1)
    node:SetScale(1)
    if node.NameText then node.NameText:SetText("") end
    if node.TimeText then node.TimeText:SetText("") end
    if node.Icon then node.Icon:SetTexture(nil) end

    local fac = Factory()
    if fac then
        fac:Release(POOL_TYPE, node)
    end
    _sortDirty = true
    RefreshAnchorVisibility()
end

local _sortBuf = {}
local function RebuildTrackOrder()
    local now = GetTime()

    wipe(_sortBuf)
    for _, node in ipairs(nodeList) do
        table.insert(_sortBuf, node)
    end
    table.sort(_sortBuf, function(a, b)
        return (a._castTime - now) < (b._castTime - now)
    end)

    for _, node in ipairs(_sortBuf) do
        node._trackIndex = 1
    end
    _sortDirty = false
end

local function CreateAnchor()
    if anchorFrame then return end

    local db = DB() or FallbackDB()
    local x = SafeNum(db.anchorX, -755)
    local y = SafeNum(db.anchorY, 120)

    anchorFrame = CreateFrame("Frame", "InfinityBoss_BunBarAnchor", UIParent, "BackdropTemplate")
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

    local label = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 4, -4)
    label:SetText("|cff00ff00[Bun Bars]|r")
    label:Hide()
    anchorFrame.label = label

    local axisLine = anchorFrame:CreateTexture(nil, "ARTWORK")
    axisLine:SetColorTexture(1, 1, 1, 0.20)
    anchorFrame.AxisLine = axisLine

    local fiveSecLine = anchorFrame:CreateTexture(nil, "OVERLAY")
    fiveSecLine:SetColorTexture(1.0, 0.90, 0.35, 0.85)
    anchorFrame.FiveSecLine = fiveSecLine

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
            if sx == nil or sy == nil then
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
    UpdateAnchorVisuals()
    _updateFrame:SetParent(anchorFrame)
    RefreshAnchorVisibility()
end

local function CreatePreviewTimers()
    local db = DB() or FallbackDB()
    local count = 8
    local spacingSec = RecommendSpacingSeconds(db)
    local now = GetTime()

    for id in pairs(previewIDs) do
        ReleaseNode(id)
    end

    for i = 1, count do
        local id = PREVIEW_PREFIX .. tostring(i)
        local dur = 7 + i * 2
        local timer = {
            id = id,
            barPriority = ((i - 1) % 3) + 1,
            castTime = now + i * spacingSec,
            duration = dur,
            displayName = "Preview Spell " .. i,
            spellID = 136197,
            _mode = "preview",
        }
        syntheticTimers[id] = timer
        previewIDs[id] = true
        BunBar:AddTimer(timer)
    end
end

local function SetPreviewEnabled(enabled)
    if not anchorFrame then CreateAnchor() end
    enabled = not not enabled

    if enabled == isPreviewing then
        if enabled then
            CreatePreviewTimers()
        end
        return
    end

    isPreviewing = enabled
    if enabled then
        local canMove = InfinityTools and InfinityTools.GlobalEditMode
        if canMove then
            anchorFrame:EnableMouse(true)
            if anchorFrame.EditOverlay then anchorFrame.EditOverlay:Show() end
            if anchorFrame.label then anchorFrame.label:Show() end
        else
            SetClickThrough(anchorFrame)
            if anchorFrame.EditOverlay then anchorFrame.EditOverlay:Hide() end
            if anchorFrame.label then anchorFrame.label:Hide() end
        end
        CreatePreviewTimers()
    else
        for id in pairs(previewIDs) do
            ReleaseNode(id)
        end
        SetClickThrough(anchorFrame)
        if anchorFrame.EditOverlay then anchorFrame.EditOverlay:Hide() end
        if anchorFrame.label then anchorFrame.label:Hide() end
    end
    RefreshAnchorVisibility()
end

local function CreateTestBars(count)
    if not anchorFrame then CreateAnchor() end
    if isPreviewing then SetPreviewEnabled(false) end
    count = math.max(1, math.min(tonumber(count) or 5, 5))

    local now = GetTime()
    local preset = { 5, 10, 15, 20, 25 }
    for i = 1, count do
        _testSeed = _testSeed + 1
        local id = TEST_PREFIX .. tostring(_testSeed)
        local rem = preset[i] or (i * 5)
        local dur = math.max(rem + 6, 10)
        local timer = {
            id = id,
            barPriority = ((i - 1) % 3) + 1,
            castTime = now + rem,
            duration = dur,
            displayName = "Test Spell " .. i,
            spellID = 136197,
            _mode = "test",
        }
        syntheticTimers[id] = timer
        testIDs[id] = true
        BunBar:AddTimer(timer)
    end
end

local function ClearTestBars()
    for id in pairs(testIDs) do
        ReleaseNode(id)
    end
end

local _movingBuf = {}
local _queueBuf = {}
local _releaseBuf = {}

local function ApplyPlacement(node, targetX, targetY, remaining, introKind, isQueue, now, elapsed, cfg, updateText,
                              timelineLen, iconSize)
    if not node then return end

    if introKind == "sudden" then
        node._displayX = targetX + SUDDEN_INTRO_OFFSET_X
        node._displayY = targetY
        node._introKind = "sudden"
        node._introFromX = node._displayX
        node._introFromY = node._displayY
        node._introStart = now
        node._introEnd = now + SUDDEN_INTRO_DURATION
    elseif introKind == "queue" then
        node._displayX = targetX
        node._displayY = targetY - QUEUE_INTRO_OFFSET_Y
        node._introKind = "queue"
        node._introFromX = node._displayX
        node._introFromY = node._displayY
        node._introStart = now
        node._introEnd = now + QUEUE_INTRO_DURATION
    elseif node._displayX == nil or node._displayY == nil then
        node._displayX = targetX
        node._displayY = targetY
    elseif node._introEnd and now < node._introEnd then
        local span = math.max(0.01, node._introEnd - (node._introStart or (node._introEnd - 0.01)))
        local t = (now - (node._introStart or (node._introEnd - span))) / span
        local ease = EaseOutCubic(t)
        local fromX = node._introFromX or targetX
        local fromY = node._introFromY or targetY
        if node._introKind == "sudden" then
            node._displayX = fromX + (targetX - fromX) * ease
            node._displayY = targetY
        elseif node._introKind == "queue" then
            node._displayX = targetX
            node._displayY = fromY + (targetY - fromY) * ease
        else
            node._displayX = fromX + (targetX - fromX) * ease
            node._displayY = fromY + (targetY - fromY) * ease
        end
    else
        if node._introEnd and now >= node._introEnd then
            node._introKind = nil
            node._introStart = nil
            node._introEnd = nil
            node._introFromX = nil
            node._introFromY = nil
        end
        local lerpAlpha = 1
        if POSITION_SMOOTH_TIME > 0 then
            lerpAlpha = 1 - math.exp(-elapsed / POSITION_SMOOTH_TIME)
            if lerpAlpha < 0 then lerpAlpha = 0 end
            if lerpAlpha > 1 then lerpAlpha = 1 end
        end
        node._displayX = node._displayX + (targetX - node._displayX) * lerpAlpha
        node._displayY = node._displayY + (targetY - node._displayY) * lerpAlpha
    end

    node:ClearAllPoints()
    node:SetPoint("CENTER", anchorFrame, "TOPLEFT", node._displayX, -node._displayY)

    if node.NameText then
        node.NameText:SetShown(cfg.showName)
    end
    if node.TimeText then
        node.TimeText:SetShown(cfg.showTimer)
    end
    if node.TimeBG then
        node.TimeBG:SetShown(false)
    end

    local iconHalf = iconSize * 0.5
    local dy = node._displayY or targetY
    local outOfRange = (not isQueue) and (dy > timelineLen + iconHalf + 2 or dy < -iconHalf - 2)
    if outOfRange then
        node:Hide()
    else
        node:SetAlpha(1)
        node:SetScale(1)
        node:Show()
    end
    if updateText and node.TimeText and node.TimeText:IsShown() then
        local txt = FormatTime(remaining)
        local db = DB() or FallbackDB()
        local timeFont = (type(db.font_time) == "table") and db.font_time or DEFAULT_FONT_TIME
        node.TimeText:SetText(txt)
        UpdateTimeTextBounds(node, txt, iconSize, SafeNum(timeFont.size, DEFAULT_FONT_TIME.size))
    end
end

local function RuntimeTick(elapsed, nowOverride)
    if not anchorFrame then return end

    _textElapsed = _textElapsed + elapsed
    local updateText = false
    if _textElapsed >= TEXT_UPDATE_INTERVAL then
        _textElapsed = 0
        updateText = true
    end

    if _sortDirty then
        RebuildTrackOrder()
    end

    local cfg = GetRuntimeConfig()
    local timelineLen = cfg.timelineLen
    local moveDir = cfg.moveDir
    local iconSize = cfg.iconSize
    local trackHeight = cfg.trackHeight
    local now = nowOverride or GetTime()
    local minIconGap = iconSize + 2
    wipe(_movingBuf)
    wipe(_queueBuf)
    wipe(_releaseBuf)

    for _, node in pairs(activeNodes) do
        node._wasMoving = node._isMovingNow
        node._isMovingNow = false
        node._wasQueued = node._isQueuedNow
        node._isQueuedNow = false
    end

    for timerID, node in pairs(activeNodes) do
        if node._outroEnd then
            if UpdateOutro(node, now) then
                table.insert(_releaseBuf, timerID)
            end
        else
            local timer = GetRuntimeTimer(timerID)
            if not timer then
                StartOutro(node)
                if UpdateOutro(node, now) then
                    table.insert(_releaseBuf, timerID)
                end
            else
                local remaining = timer.castTime - now
                if remaining <= 0 then
                    if timer._mode == "preview" then
                        timer.castTime = now + math.max(5, timer.duration or 8)
                        remaining = timer.castTime - now
                    elseif timer._mode == "test" then
                        StartOutro(node)
                        if UpdateOutro(node, now) then
                            table.insert(_releaseBuf, timerID)
                        end
                        remaining = 0
                    else
                        remaining = 0
                    end
                end

                if node._outroEnd then
                elseif remaining > QUEUE_HIDE_SECS then
                    node:Hide()
                    node._displayX = nil
                    node._displayY = nil
                    node._introKind = nil
                    node._introStart = nil
                    node._introEnd = nil
                    node._introFromX = nil
                    node._introFromY = nil
                elseif remaining > ACTIVE_WINDOW_SECS then
                    node._isQueuedNow = true
                    node._introKind = nil
                    node._introStart = nil
                    node._introEnd = nil
                    node._introFromX = nil
                    node._introFromY = nil
                    node._rtRemaining = remaining
                    table.insert(_queueBuf, node)
                elseif node._trackIndex then
                    node._isMovingNow = true
                    local y = 0
                    local progress = remaining / ACTIVE_WINDOW_SECS
                    if moveDir == "Down" then
                        y = timelineLen * (1 - progress)
                    else
                        y = timelineLen * progress
                    end
                    node._rtRemaining = remaining
                    node._rtTargetY = y
                    node._rtIntroKind = (node._wasQueued and "queue") or ((not node._wasMoving) and "sudden") or nil
                    table.insert(_movingBuf, node)
                else
                    node:Hide()
                end
            end
        end
    end

    if #_movingBuf > 1 then
        table.sort(_movingBuf, function(a, b)
            return (a._rtTargetY or 0) < (b._rtTargetY or 0)
        end)
    end

    if #_movingBuf > 1 then
        for i = 2, #_movingBuf do
            local prev = _movingBuf[i - 1]
            local cur = _movingBuf[i]
            local prevY = prev and prev._rtTargetY or 0
            local curY = cur and cur._rtTargetY or 0
            if curY - prevY < minIconGap then
                cur._rtTargetY = prevY + minIconGap
            end
        end
    end

    if #_queueBuf > 1 then
        table.sort(_queueBuf, function(a, b)
            return (a._rtRemaining or 0) < (b._rtRemaining or 0)
        end)
    end

    if #_queueBuf > 0 then
        local queueEdge = (moveDir == "Down") and 0 or timelineLen
        local queueSign = (moveDir == "Down") and -1 or 1
        for i, node in ipairs(_queueBuf) do
            ApplyPlacement(
                node,
                trackHeight * 0.5,
                queueEdge + queueSign * (i * minIconGap),
                node._rtRemaining or 0,
                nil,
                true,
                now,
                elapsed,
                cfg,
                updateText,
                timelineLen,
                iconSize
            )
        end
    end

    for _, node in ipairs(_movingBuf) do
        ApplyPlacement(
            node,
            trackHeight * 0.5,
            node._rtTargetY or 0,
            node._rtRemaining or 0,
            node._rtIntroKind,
            false,
            now,
            elapsed,
            cfg,
            updateText,
            timelineLen,
            iconSize
        )
    end

    if #_releaseBuf > 0 then
        for _, id in ipairs(_releaseBuf) do
            ReleaseNode(id)
        end
    end
end

_updateFrame = CreateFrame("Frame")
_updateFrame:Hide()
SetClickThrough(_updateFrame)
_updateFrame:SetScript("OnUpdate", function(_, elapsed)
    RuntimeTick(elapsed)
end)

local function SetEditMode(enabled)
    SetPreviewEnabled(enabled)
    RefreshAnchorVisibility()
end

InfinityTools:RegisterEditModeCallback(MODULE_KEY, SetEditMode)

function BunBar:AddTimer(timer)
    local db = DB()
    if db and db.enabled == false then return end
    if not anchorFrame then CreateAnchor() end
    RefreshAnchorVisibility()
    if activeNodes[timer.id] then return end

    local node = AcquireNode(timer.id, timer.barPriority)
    if not node then return end

    node._castTime = timer.castTime
    node._duration = math.max(1, timer.duration or 30)
    node._eventID = ResolveTimerEventID(timer)
    node._eventColor = timer.eventColor
    node._timerTextColor = timer.timerTextColor
    node._mode = timer._mode

    local spellInfo = timer.spellID and C_Spell.GetSpellInfo(timer.spellID) or nil
    if node.Icon then
        node.Icon:SetTexture((spellInfo and spellInfo.iconID) or timer.iconFileID or 136197)
    end
    local name = timer.displayName or (spellInfo and spellInfo.name) or "???"
    if node.NameText then node.NameText:SetText(name) end

    UpdateNodeVisuals(node, timer.barPriority)
    _sortDirty = true
    RefreshAnchorVisibility()
end

function BunBar:OnCast(timer)
    local node = activeNodes[timer.id]
    if node then
        StartOutro(node)
    else
        ReleaseNode(timer.id)
    end
end

function BunBar:OnPreAlert(timer)
end

function BunBar:ReleaseAll()
    isPreviewing = false
    local ids = {}
    for id in pairs(activeNodes) do
        table.insert(ids, id)
    end
    for _, id in ipairs(ids) do
        ReleaseNode(id)
    end
    syntheticTimers = {}
    previewIDs = {}
    testIDs = {}
    RefreshAnchorVisibility()
end

function BunBar:RefreshVisuals()
    local db = DB() or FallbackDB()
    if anchorFrame then
        local x = SafeNum(db.anchorX, -755)
        local y = SafeNum(db.anchorY, 120)
        anchorFrame:ClearAllPoints()
        anchorFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
    end
    UpdateAnchorVisuals()
    for _, node in pairs(activeNodes) do
        UpdateNodeVisuals(node, node._priority)
    end
    _sortDirty = true
    if isPreviewing then
        CreatePreviewTimers()
    end
    InvalidateRuntimeConfig()
    RefreshAnchorVisibility()
end

function BunBar:SetPreviewEnabled(enabled)
    SetPreviewEnabled(enabled)
end

function BunBar:TogglePreview()
    SetPreviewEnabled(not isPreviewing)
end

function BunBar:CreateTestBars(count)
    CreateTestBars(count)
end

function BunBar:ClearTestBars()
    ClearTestBars()
end

function BunBar:OnRuntimeTick(elapsed, now)
    RuntimeTick(elapsed, now)
end

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", MODULE_KEY .. "_init", function()
    C_Timer.After(0.5, function()
        CreateAnchor()
        UpdateAnchorVisuals()
    end)
end)

BunBar._active = activeNodes

