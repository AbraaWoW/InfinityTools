---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossDisplay/Countdown.lua
--
--
-- =============================================================

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end

InfinityBoss.UI.Countdown = InfinityBoss.UI.Countdown or {}
local Countdown  = InfinityBoss.UI.Countdown
local MODULE_KEY = "InfinityBoss.Countdown"

-- =============================================================
-- =============================================================
local function DB()
    if InfinityTools.GetModuleDB then
        local ok, mdb = pcall(InfinityTools.GetModuleDB, InfinityTools, MODULE_KEY)
        if ok and type(mdb) == "table" then return mdb end
    end
    local db = _G.InfinityBossDB
    return db and db.timer and db.timer.countdown
end

local function SafeNum(v, def) return tonumber(v) or def end

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
    enabled       = false,
    showIcon      = true,
    iconSize      = 24,
    showDecimal   = true,
    labelTemplate = " %s %t",
    preSecs       = 5,
    anchorX       = 15,
    anchorY       = 75,
    font_label = {
        font="Default", size=22, outline="OUTLINE",
        r=1, g=1, b=1, a=1,
        shadow=true, shadowX=2, shadowY=-2, x=0, y=0,
    },
    font_cd = {
        font="Default", size=22, outline="OUTLINE",
        r=1, g=1, b=1, a=1,
        shadow=true, shadowX=2, shadowY=-2, x=0, y=0,
    },
}

local function NormalizeColorTable(c)
    if type(c) ~= "table" then return nil end
    local r, g, b, a
    if type(c.GetRGB) == "function" then
        local ok, rr, gg, bb = pcall(c.GetRGB, c)
        if ok then
            r, g, b = rr, gg, bb
        end
        a = c.a
    else
        r, g, b, a = c.r, c.g, c.b, c.a
    end
    if tonumber(r) and tonumber(g) and tonumber(b) then
        return {
            r = tonumber(r),
            g = tonumber(g),
            b = tonumber(b),
            a = tonumber(a) or 1,
        }
    end
    return nil
end

local function ResolveCountdownTextColor(timer)
    if type(timer) ~= "table" then return nil end

    local c = NormalizeColorTable(timer.flashTextColor)
    if c then return c end

    c = NormalizeColorTable(timer.eventColor)
    if c then return c end

    return nil
end

-- =============================================================
-- =============================================================
local function ApplyFont(fs, fontDB, defSize)
    if not fs or not fontDB then return end
    local StaticDB = InfinityTools.DB_Static
    if StaticDB and StaticDB.ApplyFont then
        StaticDB:ApplyFont(fs, fontDB)
        return
    end
    local LSM  = LibStub and LibStub("LibSharedMedia-3.0", true)
    local path = (LSM and fontDB.font and fontDB.font ~= "Default")
                 and LSM:Fetch("font", fontDB.font)
                 or (InfinityTools.MAIN_FONT or STANDARD_TEXT_FONT)
    fs:SetFont(path, SafeNum(fontDB.size, defSize or 46), fontDB.outline or "OUTLINE")
    fs:SetTextColor(SafeNum(fontDB.r,1), SafeNum(fontDB.g,1), SafeNum(fontDB.b,1), SafeNum(fontDB.a,1))
    if fontDB.shadow then
        fs:SetShadowOffset(SafeNum(fontDB.shadowX,2), SafeNum(fontDB.shadowY,-2))
        fs:SetShadowColor(0,0,0,1)
    else
        fs:SetShadowOffset(0,0)
    end
end

-- =============================================================
-- =============================================================
local anchorFrame  = nil
local updater      = nil
local isPreviewing = false

local rows         = {}
local _entries     = {}
local _entrySeq    = 0
local _cdGap       = 6
local STACK_GAP    = 4
local STACK_MAX    = 6

local function EstimateTextWidth(fontDB, defSize, text)
    local size = SafeNum(fontDB and fontDB.size, defSize or 22)
    local s = tostring(text or "")
    local units = 0
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local b = ch:byte() or 0
        if ch == " " then
            units = units + 0.38
        elseif b < 128 then
            if ch:match("[%d]") then
                units = units + 0.68
            elseif ch:match("[%a]") then
                units = units + 0.66
            elseif ch:match("[%.,:;!%-+/%)]") then
                units = units + 0.50
            else
                units = units + 0.62
            end
        else
            units = units + 1.05
        end
    end
    if units <= 0 then
        units = 1
    end
    return math.ceil(units * size + math.max(10, size * 0.8))
end

local function SyncRing(entry, forcedRemaining)
    local ring = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.RingProgress
    if not ring then return end
    if type(entry) == "table" then
        if ring.ShowEntry then
            ring:ShowEntry(entry, forcedRemaining)
        end
    elseif ring.Hide then
        ring:Hide()
    end
end

local function GetRowHeight(db)
    local showIco = db.showIcon ~= false
    local icoSize = showIco and SafeNum(db.iconSize, 48) or 0
    local labelSize = SafeNum((db.font_label or FALLBACK_DB.font_label).size, 46)
    local cdSize = SafeNum((db.font_cd or FALLBACK_DB.font_cd).size, 60)
    local textH = math.max(labelSize, cdSize) + 6
    return math.max(36, icoSize, textH)
end

local function EnsureRow(index)
    local row = rows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, anchorFrame)
    row:SetSize(800, 80)
    SetClickThrough(row)

    row.iconTex = row:CreateTexture(nil, "ARTWORK")
    row.iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.labelFS = row:CreateFontString(nil, "OVERLAY")
    row.labelFS:SetJustifyH("LEFT")
    row.labelFS:SetJustifyV("MIDDLE")

    row.cdFS = row:CreateFontString(nil, "OVERLAY")
    row.cdFS:SetJustifyH("LEFT")
    row.cdFS:SetJustifyV("MIDDLE")
    row.cdFS:SetWordWrap(false)
    if row.cdFS.SetNonSpaceWrap then
        row.cdFS:SetNonSpaceWrap(false)
    end

    row._showIcon = true
    row._labelY = 0
    row._cdY = 0
    row._pairOffsetX = 0
    row._numCache = nil
    row._sufCache = nil
    row._labelWidthKey = nil
    row._labelWidth = 0
    row._cdReserveKey = nil
    row._cdReserveW = 0
    row._cdMaxSeenW = 0

    rows[index] = row
    return row
end

local function ApplyRowStyle(row, db)
    if not row then return end
    ApplyFont(row.labelFS, db.font_label or FALLBACK_DB.font_label, 46)
    ApplyFont(row.cdFS,    db.font_cd    or FALLBACK_DB.font_cd,    60)

    local lf = db.font_label or FALLBACK_DB.font_label
    local cf = db.font_cd or FALLBACK_DB.font_cd

    local showIco = db.showIcon ~= false
    local icoSize = SafeNum(db.iconSize, 48)
    row.iconTex:SetSize(icoSize, icoSize)
    row.iconTex:SetShown(showIco)
    row._showIcon = showIco
    row._labelY = SafeNum(lf.y, 0)
    row._cdY = SafeNum(cf.y, 0)
    row._pairOffsetX = math.floor((SafeNum(lf.x, 0) + SafeNum(cf.x, 0)) * 0.5)
    row._cdMaxSeenW = 0

    row.labelFS:ClearAllPoints()
    row.labelFS:SetPoint("LEFT", row, "CENTER", row._pairOffsetX, row._labelY)
    row.cdFS:ClearAllPoints()
    row.cdFS:SetPoint("LEFT", row, "CENTER", row._pairOffsetX + _cdGap, row._cdY)
end

local function ApplyRowColor(row, db, entryColor)
    if not row then return end
    if entryColor then
        row.labelFS:SetTextColor(entryColor.r, entryColor.g, entryColor.b, entryColor.a or 1)
        row.cdFS:SetTextColor(entryColor.r, entryColor.g, entryColor.b, entryColor.a or 1)
        return
    end
    local lf = db.font_label or FALLBACK_DB.font_label
    local cf = db.font_cd or FALLBACK_DB.font_cd
    row.labelFS:SetTextColor(SafeNum(lf.r, 1), SafeNum(lf.g, 1), SafeNum(lf.b, 1), SafeNum(lf.a, 1))
    row.cdFS:SetTextColor(SafeNum(cf.r, 1), SafeNum(cf.g, 1), SafeNum(cf.b, 1), SafeNum(cf.a, 1))
end

local function HideUnusedRows(startIndex)
    for i = startIndex, #rows do
        local row = rows[i]
        if row then row:Hide() end
    end
end

local function RenderStack(forcedRemaining)
    if not anchorFrame then return end
    local db = DB() or FALLBACK_DB
    local count = #_entries
    if count <= 0 then
        HideUnusedRows(1)
        SyncRing(nil, nil)
        if not isPreviewing then
            anchorFrame:Hide()
            if updater then updater:Hide() end
        end
        return
    end

    local rowH = GetRowHeight(db)
    local totalH = rowH * count + STACK_GAP * math.max(0, count - 1)
    anchorFrame:SetHeight(totalH)

    local now = GetTime()
    for i = 1, count do
        local entry = _entries[i]
        local row = EnsureRow(i)
        row:SetSize(800, rowH)
        ApplyRowStyle(row, db)
        row.iconTex:SetTexture(entry.iconID or 136197)
        ApplyRowColor(row, db, entry.color)
        row.labelFS:SetText(entry.pre or "")

        local remaining = forcedRemaining or math.max(0, (entry.endTime or now) - now)
        local numStr = db.showDecimal and string.format("%.1f", remaining) or tostring(math.ceil(remaining))
        if row._numCache ~= numStr or row._sufCache ~= entry.suf then
            row.cdFS:SetText(numStr .. (entry.suf or ""))
            row._numCache = numStr
            row._sufCache = entry.suf
        end

        local labelWidthKey = tostring(entry.pre or "")
        if row._labelWidthKey ~= labelWidthKey then
            row._labelWidth = EstimateTextWidth(db.font_label or FALLBACK_DB.font_label, 46, entry.pre or "")
            row._labelWidthKey = labelWidthKey
        end

        local reserveText = db.showDecimal and ("8888.8" .. (entry.suf or "")) or ("8888" .. (entry.suf or ""))
        local reserveKey = reserveText
        if row._cdReserveKey ~= reserveKey then
            row._cdReserveW = EstimateTextWidth(db.font_cd or FALLBACK_DB.font_cd, 60, reserveText)
            row._cdReserveKey = reserveKey
        end

        local labelW = row._labelWidth or 0
        local actualCdW = EstimateTextWidth(db.font_cd or FALLBACK_DB.font_cd, 60, numStr .. (entry.suf or ""))
        local cdW = math.max(row._cdReserveW or 0, actualCdW)
        local totalW = labelW + _cdGap + cdW
        local leftX = -0.5 * totalW + (row._pairOffsetX or 0)

        row.labelFS:ClearAllPoints()
        row.labelFS:SetPoint("LEFT", row, "CENTER", leftX, row._labelY or 0)
        row.cdFS:ClearAllPoints()
        row.cdFS:SetPoint("LEFT", row, "CENTER", leftX + labelW + _cdGap, row._cdY or 0)
        row.cdFS:SetWidth(cdW)

        if row._showIcon then
            row.iconTex:ClearAllPoints()
            row.iconTex:SetPoint("RIGHT", row.labelFS, "LEFT", -6, 0)
        end

        row:ClearAllPoints()
        row:SetPoint("CENTER", anchorFrame, "CENTER", 0, (count - i) * (rowH + STACK_GAP))
        row:Show()
    end

    HideUnusedRows(count + 1)
    anchorFrame:Show()
    SyncRing(_entries[1], forcedRemaining)
end

-- =============================================================
-- =============================================================
local function CreateFrames()
    if anchorFrame then return end
    local db = DB() or FALLBACK_DB

    anchorFrame = CreateFrame("Frame", "InfinityBoss_CountdownAnchor", UIParent, "BackdropTemplate")
    anchorFrame:SetSize(800, 80)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER",
        SafeNum(db.anchorX, 15), SafeNum(db.anchorY, 75))
    anchorFrame:SetMovable(true)
    anchorFrame:SetClampedToScreen(false)
    anchorFrame:SetFrameStrata("DIALOG")
    SetClickThrough(anchorFrame)
    anchorFrame:Hide()

    local editOverlay = anchorFrame:CreateTexture(nil, "ARTWORK")
    editOverlay:SetAllPoints()
    editOverlay:SetColorTexture(0, 0.8, 0, 0.18)
    editOverlay:Hide()
    anchorFrame.EditOverlay = editOverlay

    local editLabel = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    editLabel:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", -4, -4)
    editLabel:SetText("|cff00ff00[Countdown]|r")
    editLabel:Hide()
    anchorFrame.EditLabel = editLabel

    anchorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and InfinityTools.GlobalEditMode then
            self.isMoving = true; self:StartMoving()
        elseif button == "RightButton" and InfinityTools.GlobalEditMode then
            InfinityTools:OpenConfig(MODULE_KEY)
        end
    end)
    anchorFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self.isMoving = false; self:StopMovingOrSizing()
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

    updater = CreateFrame("Frame", nil, UIParent)
    updater:Hide()
    SetClickThrough(updater)
    updater:SetScript("OnUpdate", function()
        if isPreviewing then return end
        local now = GetTime()
        for i = #_entries, 1, -1 do
            if (_entries[i].endTime or 0) <= now then
                table.remove(_entries, i)
            end
        end
        RenderStack(nil)
    end)
end

-- =============================================================
-- =============================================================
local function SplitTemplate(template, spellName)
    if not template or template == "" then return spellName or "", "" end
    local s = template:gsub("%%s", spellName or "")
    local pre, suf = s:match("^(.-)%%t(.*)$")
    if pre then return pre, suf end
    return s, ""
end

-- =============================================================
-- =============================================================
local function StopAll()
    if updater then updater:Hide() end
    for i = #_entries, 1, -1 do
        _entries[i] = nil
    end
    HideUnusedRows(1)
    SyncRing(nil, nil)
    if anchorFrame then anchorFrame:Hide() end
end

-- =============================================================
-- =============================================================
local function SetEditMode(enabled)
    if not anchorFrame then CreateFrames() end
    local db = DB() or FALLBACK_DB

    if enabled then
        anchorFrame:EnableMouse(true)
        if anchorFrame.EditOverlay then anchorFrame.EditOverlay:Show() end
        if anchorFrame.EditLabel   then anchorFrame.EditLabel:Show()   end
        isPreviewing = true
        local tmpl = (type(db.labelTemplate)=="string" and db.labelTemplate~="") and db.labelTemplate or FALLBACK_DB.labelTemplate
        local pre, suf = SplitTemplate(tmpl, "Tank Buster")
        _entries[1] = {
            id = 0,
            startTime = GetTime(),
            duration = 5,
            endTime = GetTime() + 999,
            pre = pre,
            suf = suf,
            iconID = 136197,
            color = nil,
        }
        for i = #_entries, 2, -1 do
            _entries[i] = nil
        end
        RenderStack(3)
        if updater then updater:Hide() end
    else
        SetClickThrough(anchorFrame)
        if anchorFrame.EditOverlay then anchorFrame.EditOverlay:Hide() end
        if anchorFrame.EditLabel   then anchorFrame.EditLabel:Hide()   end
        isPreviewing = false
        StopAll()
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
        SafeNum(db.anchorX, 15), SafeNum(db.anchorY, 75))
    if isPreviewing then
        RenderStack(3)
    else
        RenderStack(nil)
    end
end

-- =============================================================
-- =============================================================
function Countdown:Show(timer)
    local db = DB() or FALLBACK_DB
    if db.enabled == false then return end
    if not anchorFrame then CreateFrames() end
    if isPreviewing then return end

    local spellName = timer and timer.displayName or nil
    local iconID    = nil
    if timer and timer.spellID then
        local info = C_Spell.GetSpellInfo(timer.spellID)
        if info then
            if not spellName then
                spellName = info.name
            end
            iconID = info.iconID
        end
    end
    if (not iconID) and timer and timer.iconFileID then
        iconID = tonumber(timer.iconFileID)
    end
    if not spellName then
        spellName = ""
    end

    local tmpl = (type(db.labelTemplate)=="string" and db.labelTemplate~="") and db.labelTemplate or FALLBACK_DB.labelTemplate
    local pre, suf = SplitTemplate(tmpl, spellName)
    local mechanicColor = ResolveCountdownTextColor(timer)

    _entrySeq = _entrySeq + 1
    local duration = 5.0
    local now = GetTime()
    table.insert(_entries, 1, {
        id = _entrySeq,
        startTime = now,
        duration = duration,
        endTime = now + duration,
        pre = pre,
        suf = suf,
        iconID = iconID or 136197,
        color = mechanicColor,
    })
    while #_entries > STACK_MAX do
        table.remove(_entries, #_entries)
    end

    RenderStack(nil)
    if updater then updater:Show() end
end

function Countdown:Stop()
    StopAll()
end

function Countdown:RefreshVisuals()
    if not anchorFrame then return end
    RefreshStyle()
    if isPreviewing then
        if updater then updater:Hide() end
    elseif #_entries > 0 then
        if updater then updater:Show() end
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
